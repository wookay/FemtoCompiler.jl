module test_femtocompiler_typeinf_local

using Test
using Core: CodeInfo, ReturnNode
using Core: Compiler as CC
using Base.Experimental: @MethodTable, @overlay
using FemtoCompiler: FemtoInterpreter

using .CC: code_typed

@MethodTable OVERLAY_PLUS_MT
function overlay_plus end
overlay_plus(x, y) = :default
@overlay OVERLAY_PLUS_MT overlay_plus(x::Int, y::Int) = :overlay

CC.method_table(interp::FemtoInterpreter) = CC.OverlayMethodTable(CC.get_inference_world(interp), OVERLAY_PLUS_MT)

# from julia/Compiler/test/irutils.jl
code_typed1(args...; kwargs...) = first(only(code_typed(args...; kwargs...)))::CodeInfo

f = overlay_plus
interp = FemtoInterpreter()
let src = code_typed1(f, (Int, Int); interp)
    line = src.code[end]
    @test line == ReturnNode(:(:overlay))
end

let src = code_typed1(f, (Int, Int))
    line = src.code[end]
    @test line == ReturnNode(:(:default))
end

end # module test_femtocompiler_typeinf_local
