module FemtoCompiler

# from julia/Compiler/test/newinterp.jl
include("newinterp.jl")
@newinterp FemtoInterpreter

if VERSION >= v"1.12"
    include("abstractinterpretation.jl")
    include("typeinfer.jl")
    include("reflection.jl")
end

end # module FemtoCompiler
