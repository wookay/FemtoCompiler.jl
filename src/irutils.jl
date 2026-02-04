# module FemtoCompiler

using .CC: CodeInfo

function code_typed1(f::Function, types::Tuple; interp::Union{Nothing,FemtoInterpreter} = nothing)::CodeInfo
    first(only(Base.code_typed(f, types; interp)))
end

# module FemtoCompiler
