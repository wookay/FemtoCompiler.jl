# module FemtoCompiler

using Core: Compiler as CC
using .CC: specialize_method, MethodMatch, Method, SimpleVector, MethodInstance
using Base: normalize_typevars, is_nospecializeinfer, get_nospecializeinfer_sig

# from julia/Compiler/src/typeinfer.jl
# typeinf_code
function femto_typeinf_code(interp::FemtoInterpreter, match::MethodMatch, run_optimizer::Bool)
    frame_src = femto_typeinf_code(interp, specialize_method(match), run_optimizer)
    return frame_src
end
function femto_typeinf_code(interp::FemtoInterpreter, method::Method, @nospecialize(atype), sparams::SimpleVector, run_optimizer::Bool)
    frame_src = femto_typeinf_code(interp, specialize_method(method, atype, sparams), run_optimizer)
    return frame_src
end
function femto_typeinf_code(interp::FemtoInterpreter, mi::MethodInstance, run_optimizer::Bool)
    frame = _typeinf_frame(interp, mi, run_optimizer)
    frame === nothing && return nothing
    return frame.src
end


if VERSION >= v"1.14.0-DEV.60" # julia commit 998cb27e4c83364a38378841c88c954ac1e7eb59
using .CC: InferenceResult, InferenceState, Const, OptimizationState,
           typeinf_lattice, typeinf, is_inferred, result_is_constabi, codeinfo_for_const, optimize, ir_to_codeinf!
# from julia/Compiler/src/typeinfer.jl
# typeinf_frame
function _typeinf_frame(interp::FemtoInterpreter, match::MethodMatch, run_optimizer::Bool)
    frame = _typeinf_frame(interp, specialize_method(match), run_optimizer)
    return frame
end
function _typeinf_frame(interp::FemtoInterpreter, method::Method, @nospecialize(atype), sparams::SimpleVector, run_optimizer::Bool)
    frame = _typeinf_frame(interp, specialize_method(method, atype, sparams), run_optimizer)
    return frame
end
function _typeinf_frame(interp::FemtoInterpreter, mi::MethodInstance, run_optimizer::Bool)
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
    # @info :_typeinf_frame interp mi run_optimizer frame
    return frame
end
end # if VERSION >= v"1.14.0-DEV.60"

#=
pkgid = Base.PkgId(Base.UUID("92d42091-2d14-46a9-a897-febf9702e17e"), "FemtoCompiler")
precompiled = Base.Precompilation.precompilepkgs([pkgid])
=#

# module FemtoCompiler
