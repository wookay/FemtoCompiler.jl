module CompilerExt

using FemtoCompiler: FemtoInterpreter

using Core.Compiler: Compiler as CC
include("newinterp.jl")
if VERSION >= v"1.12"
    include("abstractinterpretation.jl")
    include("typeinfer.jl")
    include("precompile.jl")
end

end # module CompilerExt
