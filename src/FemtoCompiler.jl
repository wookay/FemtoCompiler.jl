module FemtoCompiler

using JuliaCore # CompilerExt

using Core.Compiler: Compiler as CC
include("types.jl")

if VERSION >= v"1.12"
include("irutils.jl")
include("bootstrap.jl")
include("OverlayPlus.jl")
Base.generating_output() && include("precompile.jl")
end # if

end # module FemtoCompiler
