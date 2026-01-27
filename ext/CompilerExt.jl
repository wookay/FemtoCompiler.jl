module CompilerExt

using FemtoCompiler: FemtoInterpreter

using Core.Compiler: Compiler as CC
include("newinterp.jl")
if VERSION >= v"1.12"
    include("abstractinterpretation.jl")
    include("typeinfer.jl")
end
include("precompile.jl")

end # module CompilerExt
