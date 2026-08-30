# module FemtoCompiler

# irutils.jl - FemtoCompiler.code_typed1
precompile(Tuple{typeof(FemtoCompiler.code_typed1), Function, Tuple{typeof(DataType), typeof(DataType)}})
precompile(Tuple{typeof(Core.kwcall), NamedTuple{(:interp,), Tuple{FemtoCompiler.FemtoInterpreter}}, typeof(FemtoCompiler.code_typed1), Function, Tuple{typeof(DataType), typeof(DataType)}})

# overlay_plus.jl - FemtoCompiler.OverlayPlus
if VERSION >= v"1.14.0-DEV.3067"
precompile(Tuple{typeof(Base.Compiler._findall_matches), FemtoCompiler.FemtoInterpreter, Type{Tuple{typeof(OverlayPlus.overlay_plus), Int, Int}}})
end # if

# module FemtoCompiler
