# module FemtoCompiler

using Base: default_tt, code_typed_opaque_closure, signature_type

# from julia/base/reflection.jl
# code_typed
function code_typed(@nospecialize(f), @nospecialize(types=default_tt(f)); kwargs...)
    if isa(f, Core.OpaqueClosure)
        return code_typed_opaque_closure(f, types; kwargs...)
    end
    tt = signature_type(f, types)
    return Base.code_typed_by_type(tt; kwargs...)
end

using Base: invoke_default_compiler, IRShow, to_tuple_type, invoke_interp_compiler, raise_match_failure, remove_linenums!
import Base: code_typed_by_type
# from julia/base/reflection.jl
# code_typed_by_type
function code_typed_by_type(@nospecialize(tt::Type);
                            optimize::Bool=true,
                            debuginfo::Symbol=:default,
                            world::UInt=get_world_counter(),
                            interp::FemtoInterpreter=nothing)
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
        code = invoke_interp_compiler(passed_interp, :typeinf_code, interp, match, optimize)
        if code === nothing
            push!(asts, match.method => Any)
        else
            debuginfo === :none && remove_linenums!(code)
            push!(asts, code => code.rettype)
        end
    end
    return asts
end

# module FemtoCompiler
