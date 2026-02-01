# module CompilerExt

using .CC: method_table

# from julia/Compiler/src/reflection_interface.jl
function Base.Compiler._findall_matches(interp::FemtoInterpreter, @nospecialize(tt))
    findall(tt, method_table(interp))
end

# module CompilerExt
