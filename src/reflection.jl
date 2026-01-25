# module FemtoCompiler

using Base: get_world_counter, typename, IRShow, to_tuple_type, remove_linenums!

if VERSION >= v"1.12.0-DEV.1571" # julia commit cd7250da83

using Base: invoke_default_compiler, raise_match_failure
import Base: invoke_interp_compiler
# from julia/base/reflection.jl
# invoke_interp_compiler
function invoke_interp_compiler(interp::FemtoInterpreter, fname::Symbol, args...)
    if interp === nothing
        return invoke_default_compiler(fname, args...)
    else
        T = typeof(interp)
        while true
            Tname = typename(T).name
            Tname === :Any && error("Expected AbstractInterpreter")
            Tname === :AbstractInterpreter && break
            T = supertype(T)
        end
        return getglobal(typename(T).module, fname)(args...)
    end
end

# from julia/base/reflection.jl
# code_typed_by_type
function _code_typed_by_type(@nospecialize(tt::Type);
                            optimize::Bool=true,
                            debuginfo::Symbol=:default,
                            world::UInt=get_world_counter(),
                            interp::Union{Nothing,FemtoInterpreter}=nothing)
    passed_interp = interp
    interp = passed_interp === nothing ? invoke_default_compiler(:_default_interp, world) : interp
    (ccall(:jl_is_in_pure_context, Bool, ()) || world == typemax(UInt)) &&
        error("code reflection cannot be used from generated functions")
    if @isdefined(IRShow)
        debuginfo = IRShow.debuginfo(debuginfo)
    elseif debuginfo === :default
        debuginfo = :source
    end
    if debuginfo !== :source && debuginfo !== :none
        throw(ArgumentError("'debuginfo' must be either :source or :none"))
    end
    tt = to_tuple_type(tt)
    matches = invoke_interp_compiler(passed_interp, :_findall_matches, interp, tt)
    matches === nothing && raise_match_failure(:code_typed, tt)
    asts = []
    for match in matches.matches
        match = match::Core.MethodMatch
        fname = :typeinf_code
        code = invoke_interp_compiler(passed_interp, fname, interp, match, optimize)
        if code === nothing
            push!(asts, match.method => Any)
        else
            debuginfo === :none && remove_linenums!(code)
            push!(asts, code => code.rettype)
        end
    end
    return asts
end # function _code_typed_by_type

# FemtoCompiler.femto_code_typed
using Base: default_tt, code_typed_opaque_closure, signature_type
# from julia/base/reflection.jl
# code_typed
function femto_code_typed(@nospecialize(f), @nospecialize(types=default_tt(f)); kwargs...)
    if isa(f, Core.OpaqueClosure)
        return code_typed_opaque_closure(f, types; kwargs...)
    end
    tt = signature_type(f, types)
    return _code_typed_by_type(tt; kwargs...)
end # function femto_code_typed

end # if VERSION >= v"1.12.0-DEV.1571"

# module FemtoCompiler
