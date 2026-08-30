using Jive
@If VERSION >= v"1.14.0-DEV.3067" module OverlayPlus # FemtoCompiler
# julia commit 5b4ff799b2
# support docstrings on overlay method definitions

using Base.Experimental: @MethodTable, @overlay
using ..FemtoCompiler: CC, FemtoInterpreter

@MethodTable OVERLAY_PLUS_MT

function overlay_plus end
overlay_plus(x, y) = :default

@overlay OVERLAY_PLUS_MT overlay_plus(x::Int, y::Int) = :overlay_value

function overlay_with_doc_1 end
overlay_with_doc_1(x, y) = :default

@overlay OVERLAY_PLUS_MT begin
    """
    overlay doc 1
    """
    overlay_with_doc_1(x::Int, y::Int) = :overlay_value
end # @overlay OVERLAY_PLUS_MT

CC.method_table(interp::FemtoInterpreter) = CC.OverlayMethodTable(CC.get_inference_world(interp), OVERLAY_PLUS_MT)

end # module FemtoCompiler.OverlayPlus
