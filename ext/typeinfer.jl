# module CompilerExt

using .CC: SimpleVector, AbsIntState,
           MethodMatch, MethodInstance, InferenceResult, typeinf, result_is_constabi, codeinfo_for_const,
           OptimizationState, optimize, get_inference_world, specialize_method, CACHE_MODE_GLOBAL, is_stmt_inline,
           get_curr_ssaflag, code_cache, CodeInstance, may_optimize, is_inlineable, CACHE_MODE_LOCAL,
           return_cached_result, InferenceParams, add_remark!, Future, MethodCallResult, Effects, is_cached,
           frame_parent, resolve_call_cycle!, _time_ns, engine_reserve, engine_reject, typeinf_lattice, InferenceState,
           assign_parentchild!, update_valid_age!, adjust_effects, effects_for_cycle,
           refine_exception_type, add_cycle_backedge!
if VERSION >= v"1.14.0-DEV.60"
using .CC: ci_get_source, _schedule_edge_infer_task!, use_const_api
end

# from julia/Compiler/src/typeinfer.jl
import .CC: typeinf_edge
function typeinf_edge(interp::FemtoInterpreter, method::Method, @nospecialize(atype), sparams::SimpleVector, caller::AbsIntState, edgecycle::Bool, edgelimited::Bool)
    mi = specialize_method(method, atype, sparams)
    cache_mode = CACHE_MODE_GLOBAL # cache edge targets globally by default
    force_inline = is_stmt_inline(get_curr_ssaflag(caller))
    edge_ci = nothing
    let code = get(code_cache(interp), mi, nothing)
        codeinst = code
        if code isa InferenceResult
            inferred = code.src
            codeinst = code.ci
        elseif code isa CodeInstance # return existing rettype if the code is already inferred
            inferred = @atomic :monotonic code.inferred
        else
            inferred = nothing
        end
        if codeinst isa CodeInstance
            need_inlineable_code = may_optimize(interp) && (force_inline || is_inlineable(inferred) || use_const_api(codeinst))
            if need_inlineable_code
                src = ci_get_source(interp, codeinst, inferred)
                if src === nothing
                    # Re-infer to get the appropriate source representation
                    cache_mode = CACHE_MODE_LOCAL
                    edge_ci = codeinst
                else # no reinference needed
                    @assert codeinst.def === mi "MethodInstance for cached edge does not match"
                    return return_cached_result(interp, method, code, src, caller, edgecycle, edgelimited)
                end
            else # no reinference needed
                @assert codeinst.def === mi "MethodInstance for cached edge does not match"
                return return_cached_result(interp, method, code, nothing, caller, edgecycle, edgelimited)
            end
        end
    end
    if !InferenceParams(interp).force_enable_inference && ccall(:jl_get_module_infer, Cint, (Any,), method.module) == 0
        add_remark!(interp, caller, "[typeinf_edge] Inference is disabled for the target module")
        return Future(MethodCallResult(interp, caller, method, Any, Any, Effects(), nothing, edgecycle, edgelimited))
    end
    if !is_cached(caller) && frame_parent(caller) === nothing
        # this caller exists to return to the user
        # (if we asked resolve_call_cycle!, it might instead detect that there is a cycle that it can't merge)
        frame = false
    else
        frame = resolve_call_cycle!(interp, mi, caller)
    end
    if frame === false
        # completely new, but check again after reserving in the engine
        if cache_mode == CACHE_MODE_GLOBAL
            reserve_start = _time_ns() # subtract engine_reserve (thread-synchronization) time from callers to avoid double-counting
            ci_from_engine = engine_reserve(interp, mi)
            caller.time_paused += (_time_ns() - reserve_start)
            code = get(code_cache(interp), mi, nothing)
            codeinst = code
            if code isa InferenceResult
                inferred = code.src
                codeinst = code.ci
            elseif code isa CodeInstance # return existing rettype if the code is already inferred
                inferred = @atomic :monotonic code.inferred
            else
                inferred = nothing
            end
            if codeinst isa CodeInstance # return existing rettype if the code is already inferred
                engine_reject(interp, ci_from_engine)
                ci_from_engine = nothing
                need_inlineable_code = may_optimize(interp) && (force_inline || is_inlineable(inferred) || use_const_api(codeinst))
                if need_inlineable_code
                    src = ci_get_source(interp, codeinst, inferred)
                    if src === nothing
                        cache_mode = CACHE_MODE_LOCAL
                        edge_ci = codeinst
                    else
                        @assert codeinst.def === mi "MethodInstance for cached edge does not match"
                        return return_cached_result(interp, method, code, src, caller, edgecycle, edgelimited)
                    end
                else
                    @assert codeinst.def === mi "MethodInstance for cached edge does not match"
                    return return_cached_result(interp, method, code, nothing, caller, edgecycle, edgelimited)
                end
            end
        else
            ci_from_engine = nothing
        end
        result = InferenceResult(mi, typeinf_lattice(interp))
        result.ci = if ci_from_engine !== nothing
                ci_from_engine
            else
                ccall(:jl_new_codeinst_uninit, Any, (Any, Any), mi, cache_owner(interp))::CodeInstance
            end
        frame = InferenceState(result, cache_mode, interp) # always use the cache for edge targets
        if frame === nothing
            add_remark!(interp, caller, "[typeinf_edge] Failed to retrieve source")
            # can't get the source for this, so we know nothing
            if ci_from_engine !== nothing
                engine_reject(interp, ci_from_engine)
            end
            return Future(MethodCallResult(interp, caller, method, Any, Any, Effects(), nothing, edgecycle, edgelimited))
        end
        assign_parentchild!(frame, caller)
        # the actual inference task for this edge is going to be scheduled within `typeinf_local` via the callstack queue
        # while splitting off the rest of the work for this caller into a separate workq thunk
        return _schedule_edge_infer_task!(caller, frame, result, method, edge_ci, edgecycle, edgelimited)
    elseif frame === true
        # unresolvable cycle
        add_remark!(interp, caller, "[typeinf_edge] Unresolvable cycle")
        return Future(MethodCallResult(interp, caller, method, Any, Any, Effects(), nothing, edgecycle, edgelimited))
    end
    # return the current knowledge about this cycle
    frame = frame::InferenceState
    update_valid_age!(caller, get_inference_world(interp), frame.valid_worlds)
    effects = adjust_effects(effects_for_cycle(frame.ipo_effects), method)
    bestguess = frame.bestguess
    exc_bestguess = refine_exception_type(frame.exc_bestguess, effects)
    add_cycle_backedge!(caller, frame)
    result = frame.result
    return Future(MethodCallResult(interp, caller, method, bestguess, exc_bestguess, effects, isdefined(result, :ci) ? result.ci : nothing, edgecycle, edgelimited))
end

# from julia/Compiler/src/typeinfer.jl
if VERSION >= v"1.13.0-DEV.483" # julia commit 3864b18af6
using .CC: ir_to_codeinf!
import .CC: typeinf_frame
typeinf_frame(interp::FemtoInterpreter, match::MethodMatch, run_optimizer::Bool) =
    typeinf_frame(interp, specialize_method(match), run_optimizer)
typeinf_frame(interp::FemtoInterpreter, method::Method, @nospecialize(atype), sparams::SimpleVector,
              run_optimizer::Bool) =
    typeinf_frame(interp, specialize_method(method, atype, sparams), run_optimizer)
function typeinf_frame(interp::FemtoInterpreter, mi::MethodInstance, run_optimizer::Bool)
    result = InferenceResult(mi, typeinf_lattice(interp))
    frame = InferenceState(result, #=cache_mode=#:no, interp)
    frame === nothing && return nothing
    typeinf(interp, frame)
    is_inferred(frame) || return nothing
    if run_optimizer
        if result_is_constabi(interp, frame.result)
            rt = frame.result.result::Const
            src = codeinfo_for_const(interp, frame.linfo, frame.valid_worlds, Core.svec(frame.edges...), rt.val)
        else
            opt = OptimizationState(frame, interp)
            optimize(interp, opt, frame.result)
            src = ir_to_codeinf!(opt, frame, Core.svec(opt.inlining.edges...))
        end
        result.src = frame.src = src
    end
    return frame
end # function typeinf_frame
end # if VERSION >= v"1.13.0-DEV.483"

# module CompilerExt
