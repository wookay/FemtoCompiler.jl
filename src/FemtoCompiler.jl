module FemtoCompiler

using JuliaCore # CompilerExt

using Core.Compiler: Compiler as CC
include("types.jl")
include("irutils.jl")

if VERSION >= v"1.12"
include("bootstrap.jl")
include("OverlayPlus.jl")
include("precompile.jl")
end # if

end # module FemtoCompiler
