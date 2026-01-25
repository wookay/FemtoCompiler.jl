module FemtoCompiler

if VERSION >= v"1.12"
    include("types.jl")
    include("abstractinterpretation.jl")
    include("typeinfer.jl")
    include("reflection.jl")
end

end # module FemtoCompiler
