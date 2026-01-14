module FemtoCompiler

# from julia/Compiler/test/newinterp.jl
include("newinterp.jl")
@newinterp FemtoInterpreter

if VERSION >= v"1.12"
    include("typeinf_local.jl")
end

end # module FemtoCompiler
