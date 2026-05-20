# module FemtoCompiler

using .CC: CodeInfo

function code_typed1(f::Function, types::Tuple; interp::Union{Nothing,AbstractInterpreter} = nothing)::CodeInfo
    first(only(Base.code_typed(f, types; interp)))
end

# from julia/base/reflection.jl
# function print_statement_costs(io::IO, @nospecialize(tt::Type);
#                                world::UInt=get_world_counter(),
#                                interp=nothing)
using Base: invoke_default_compiler, to_tuple_type, invoke_interp_compiler, raise_match_failure
function code_statement_costs(f::Function, types::Tuple; interp::Union{Nothing,AbstractInterpreter} = nothing)::Union{Nothing, Int}
    tt = Base.signature_type(f, types)
    world = Base.get_world_counter()
    passed_interp = interp
    interp = passed_interp === nothing ? invoke_default_compiler(:_default_interp, world) : interp
    tt = to_tuple_type(tt)
    world == typemax(UInt) && error("code reflection cannot be used from generated functions")
    matches = invoke_interp_compiler(passed_interp, :_findall_matches, interp, tt)
    matches === nothing && raise_match_failure(:code_statement_costs, tt)
    cst = Int[]
    for match in matches.matches
        match = match::Core.MethodMatch
        code = invoke_interp_compiler(passed_interp, :typeinf_code, interp, match, true)
        if code === nothing
        else
            empty!(cst)
            resize!(cst, length(code.code))
            maxcost = invoke_interp_compiler(passed_interp, :statement_costs!, interp, cst, code.code, code, match)
            return maxcost
        end
    end
    return nothing
end

# module FemtoCompiler
