module OverlayPlus # FemtoCompiler

using Base.Experimental: @MethodTable, @overlay
using ..FemtoCompiler: CC, FemtoInterpreter

@MethodTable OVERLAY_PLUS_MT

function overlay_plus end
overlay_plus(x, y) = :default

@overlay OVERLAY_PLUS_MT overlay_plus(x::Int, y::Int) = :overlay

CC.method_table(interp::FemtoInterpreter) = CC.OverlayMethodTable(CC.get_inference_world(interp), OVERLAY_PLUS_MT)

end # module FemtoCompiler.OverlayPlus
