module FemtoCompiler

include("types.jl")
if VERSION >= v"1.12"
    include("abstractinterpretation.jl")
end

end # module FemtoCompiler
