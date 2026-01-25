module FemtoCompiler

include("types.jl")
include("reflection.jl")
if VERSION >= v"1.12"
    include("abstractinterpretation.jl")
    include("typeinfer.jl")
end

end # module FemtoCompiler
