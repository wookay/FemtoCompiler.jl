# module CompilerExt

using .CC: AbstractInterpreter, InferenceState, CurrentState, StatementState,
           VarTable, GotoNode, GotoIfNot, ReturnNode, EnterNode, PhiNode,
           Future, RTEffects, Bottom, Const, Conditional, SlotNumber, SlotRefinement,
           IR_FLAG_NOTHROW,
           is_inferred, typeinf_lattice, abstract_eval_value,
           update_cycle_worklists!, _bits_findnext, abstract_eval_basic_statement,
           merge_override_effects!, has_curr_ssaflag, record_ssa_assign!,
           update_exc_bestguess!, propagate_to_error_handler!,
           stoverwrite1!, stoverwrite!, ssa_def_slot, maybe_extract_const_bool, ⊑,
           add_curr_ssaflag!, update_bbstate!, handle_control_backedge!, isexpr, slot_id,
           conditional_change, condition_object_change, update_bestguess!,
           MethodMatch, MethodInstance, InferenceResult, typeinf, result_is_constabi, codeinfo_for_const
if VERSION >= v"1.14-DEV"
using .CC: conditional_valid, strefine1!, init_slot_aliases!, update_alias_table!, propagate_aliased_condition!
end

import .CC: typeinf_local
# from julia/Compiler/src/abstractinterpretation.jl
function typeinf_local(interp::FemtoInterpreter, frame::InferenceState, nextresult::CurrentState)
    @assert !is_inferred(frame)
    W = frame.ip
    ssavaluetypes = frame.ssavaluetypes
    bbs = frame.cfg.blocks
    nbbs = length(bbs)
    𝕃ᵢ = typeinf_lattice(interp)
    states = frame.bb_vartables
    saw_latestworld = frame.bb_saw_latestworld
    currbb = frame.currbb
    currpc = frame.currpc

    if isdefined(nextresult, :result)
        # for reasons that are fairly unclear, some state is arbitrarily on the stack instead in the InferenceState as normal
        bbstart = nextresult.bbstart
        bbend = nextresult.bbend
        currstate = nextresult.currstate
        currsaw_latestworld = nextresult.currsaw_latestworld
        slot_aliases = nextresult.slot_aliases
        stmt = frame.src.code[currpc]
        result = abstract_eval_basic_statement(interp, stmt, StatementState(currstate, currsaw_latestworld), frame, nextresult.result)
        @goto injected_result
    end

    if currbb != 1
        currbb = frame.currbb = _bits_findnext(W.bits, 1)::Int # next basic block
    end
    currstate = copy(states[currbb]::VarTable)
    currsaw_latestworld = saw_latestworld[currbb]
    slot_aliases = copy(frame.bb_slot_aliases[1]::Vector{Int})
    while currbb <= nbbs
        delete!(W, currbb)
        bbstart = first(bbs[currbb].stmts)
        bbend = last(bbs[currbb].stmts)
        init_slot_aliases!(slot_aliases, frame, currbb)

        currpc = bbstart - 1
        while currpc < bbend
            currpc += 1
            frame.currpc = currpc
            stmt = frame.src.code[currpc]
            # If we're at the end of the basic block ...
            if currpc == bbend
                # Handle control flow
                if isa(stmt, GotoNode)
                    succs = bbs[currbb].succs
                    @assert length(succs) == 1
                    nextbb = succs[1]
                    ssavaluetypes[currpc] = Any
                    handle_control_backedge!(interp, frame, currpc, stmt.label)
                    add_curr_ssaflag!(frame, IR_FLAG_NOTHROW)
                    @goto branch
                elseif isa(stmt, GotoIfNot)
                    condx = stmt.cond
                    condslot = ssa_def_slot(condx, frame)
                    condt = abstract_eval_value(interp, condx, StatementState(currstate, currsaw_latestworld), frame)
                    if condt === Bottom
                        ssavaluetypes[currpc] = Bottom
                        empty!(frame.pclimitations)
                        @goto find_next_bb
                    end
                    orig_condt = condt
                    if !(isa(condt, Const) || isa(condt, Conditional)) && isa(condslot, SlotNumber)
                        vtyp = currstate[slot_id(condslot)]
                        # if this non-`Conditional` object is a slot, we form and propagate
                        # the conditional constraint on it
                        condt = Conditional(condslot, vtyp.ssadef, Const(true), Const(false))
                    end
                    condval = maybe_extract_const_bool(condt)
                    nothrow = (condval !== nothing) || ⊑(𝕃ᵢ, orig_condt, Bool)
                    if nothrow
                        add_curr_ssaflag!(frame, IR_FLAG_NOTHROW)
                    else
                        update_exc_bestguess!(interp, TypeError, frame)
                        propagate_to_error_handler!(𝕃ᵢ, currstate, slot_aliases, currsaw_latestworld, frame)
                        merge_effects!(interp, frame, EFFECTS_THROWS)
                    end

                    if !isempty(frame.pclimitations)
                        # we can't model the possible effect of control
                        # dependencies on the return
                        # directly to all the return values (unless we error first)
                        condval isa Bool || union!(frame.limitations, frame.pclimitations)
                        empty!(frame.pclimitations)
                    end
                    ssavaluetypes[currpc] = Any
                    if condval === true
                        @goto fallthrough
                    else
                        if !nothrow && !hasintersect(widenconst(orig_condt), Bool)
                            ssavaluetypes[currpc] = Bottom
                            @goto find_next_bb
                        end

                        succs = bbs[currbb].succs
                        if length(succs) == 1
                            @assert condval === false || (stmt.dest === currpc + 1)
                            nextbb = succs[1]
                            @goto branch
                        end
                        @assert length(succs) == 2
                        truebb = currbb + 1
                        falsebb = succs[1] == truebb ? succs[2] : succs[1]
                        if condval === false
                            nextbb = falsebb
                            handle_control_backedge!(interp, frame, currpc, stmt.dest)
                            @goto branch
                        end

                        # We continue with the true branch, but process the false
                        # branch here.
                        if isa(condt, Conditional) && conditional_valid(condt, currstate)
                            else_change = conditional_change(𝕃ᵢ, currstate, condt, :else)
                            if else_change !== nothing
                                elsestate = copy(currstate)
                                strefine1!(elsestate, else_change)
                                propagate_aliased_condition!(𝕃ᵢ, elsestate, condt, :else, slot_aliases)
                            elseif condslot isa SlotNumber
                                elsestate = copy(currstate)
                            else
                                elsestate = currstate
                            end
                            if condslot isa SlotNumber # refine the type of this conditional object itself for this else branch
                                strefine1!(elsestate, condition_object_change(currstate, condt, condslot, :else))
                            end
                            else_changed = update_bbstate!(𝕃ᵢ, elsestate, slot_aliases, falsebb, currsaw_latestworld, frame)
                            then_change = conditional_change(𝕃ᵢ, currstate, condt, :then)
                            thenstate = currstate
                            if then_change !== nothing
                                strefine1!(thenstate, then_change)
                                propagate_aliased_condition!(𝕃ᵢ, thenstate, condt, :then, slot_aliases)
                            end
                            if condslot isa SlotNumber # refine the type of this conditional object itself for this then branch
                                strefine1!(thenstate, condition_object_change(currstate, condt, condslot, :then))
                            end
                        else
                            else_changed = update_bbstate!(𝕃ᵢ, currstate, slot_aliases, falsebb, currsaw_latestworld, frame)
                        end
                        if else_changed
                            handle_control_backedge!(interp, frame, currpc, stmt.dest)
                            push!(W, falsebb)
                        end
                        @goto fallthrough
                    end
                elseif isa(stmt, ReturnNode)
                    rt = abstract_eval_value(interp, stmt.val, StatementState(currstate, currsaw_latestworld), frame)
                    if update_bestguess!(interp, frame, currstate, rt)
                        update_cycle_worklists!(frame) do caller::InferenceState, caller_pc::Int
                            # no reason to revisit if that call-site doesn't affect the final result
                            return caller.ssavaluetypes[caller_pc] !== Any
                        end
                    end
                    ssavaluetypes[currpc] = Any
                    @goto find_next_bb
                elseif isa(stmt, EnterNode)
                    ssavaluetypes[currpc] = Any
                    add_curr_ssaflag!(frame, IR_FLAG_NOTHROW)
                    if isdefined(stmt, :scope)
                        scopet = abstract_eval_value(interp, stmt.scope, StatementState(currstate, currsaw_latestworld), frame)
                        handler = gethandler(frame, currpc + 1)::TryCatchFrame
                        @assert handler.scopet !== nothing
                        if !⊑(𝕃ᵢ, scopet, handler.scopet)
                            handler.scopet = tmerge(𝕃ᵢ, scopet, handler.scopet)
                            if isdefined(handler, :scope_uses)
                                for bb in handler.scope_uses
                                    push!(W, bb)
                                end
                            end
                        end
                    end
                    @goto fallthrough
                elseif isexpr(stmt, :leave)
                    ssavaluetypes[currpc] = Any
                    @goto fallthrough
                end
                # Fall through terminator - treat as regular stmt
            end
            # Process non control-flow statements
            @assert isempty(frame.tasks)
            sstate = StatementState(currstate, currsaw_latestworld)
            result = abstract_eval_basic_statement(interp, stmt, sstate, frame)
            if result isa Future{RTEffects}
                return CurrentState(result, currstate, slot_aliases, currsaw_latestworld, bbstart, bbend)
            else
                @label injected_result
                (; rt, exct, effects, changes, refinements, currsaw_latestworld) = result
            end
            effects === nothing || merge_override_effects!(interp, effects, frame)
            if !has_curr_ssaflag(frame, IR_FLAG_NOTHROW)
                if exct !== Union{}
                    update_exc_bestguess!(interp, exct, frame)
                    # TODO: assert that these conditions match. For now, we assume the `nothrow` flag
                    # to be correct, but allow the exct to be an over-approximation.
                end
                propagate_to_error_handler!(𝕃ᵢ, currstate, slot_aliases, currsaw_latestworld, frame)
            end
            if rt === Bottom
                ssavaluetypes[currpc] = Bottom
                # Special case: Bottom-typed PhiNodes do not error (but must also be unused)
                if isa(stmt, PhiNode)
                    continue
                end
                @goto find_next_bb
            end
            if changes !== nothing
                stoverwrite1!(currstate, changes)
                update_alias_table!(slot_aliases, stmt, frame.src.code)
            end
            if refinements isa SlotRefinement
                apply_refinement!(𝕃ᵢ, refinements.slot, refinements.typ, currstate, changes, slot_aliases)
            elseif refinements isa Vector{Any}
                for i = 1:length(refinements)
                    newtyp = refinements[i]
                    newtyp === nothing && continue
                    apply_refinement!(𝕃ᵢ, SlotNumber(i), newtyp, currstate, changes, slot_aliases)
                end
            end
            if rt === nothing
                ssavaluetypes[currpc] = Any
                continue
            end
            record_ssa_assign!(𝕃ᵢ, currpc, rt, frame)
        end # for currpc in bbstart:bbend

        # Case 1: Fallthrough termination
        begin @label fallthrough
            nextbb = currbb + 1
        end

        # Case 2: Directly branch to a different BB
        begin @label branch
            if update_bbstate!(𝕃ᵢ, currstate, slot_aliases, nextbb, currsaw_latestworld, frame)
                push!(W, nextbb)
            end
        end

        # Case 3: Control flow ended along the current path (converged, return or throw)
        begin @label find_next_bb
            currbb = frame.currbb = _bits_findnext(W.bits, 1)::Int # next basic block
            currbb == -1 && break # the working set is empty
            currbb > nbbs && break

            nexttable = states[currbb]
            if nexttable === nothing
                init_vartable!(currstate, frame)
            else
                stoverwrite!(currstate, nexttable)
            end
        end
    end # while currbb <= nbbs

    return CurrentState()
end # function typeinf_local

# module CompilerExt
