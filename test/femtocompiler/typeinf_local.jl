using Jive
@If VERSION >= v"1.12" module test_femtocompiler_typeinf_local

using Test
using Core: CodeInfo, ReturnNode
using Core: Compiler as CC
using Base.Experimental: @MethodTable, @overlay
using FemtoCompiler: FemtoCompiler, FemtoInterpreter

@MethodTable OVERLAY_PLUS_MT
function overlay_plus end
overlay_plus(x, y) = :default
@overlay OVERLAY_PLUS_MT overlay_plus(x::Int, y::Int) = :overlay

CC.method_table(interp::FemtoInterpreter) = CC.OverlayMethodTable(CC.get_inference_world(interp), OVERLAY_PLUS_MT)

# from julia/Compiler/test/irutils.jl
code_typed1(args...; kwargs...) = first(only(FemtoCompiler.femto_code_typed(args...; kwargs...)))::CodeInfo
f = overlay_plus

let src = code_typed1(f, (Int, Int))
    line = src.code[end]
    @test line == ReturnNode(:(:default))
end

interp = FemtoInterpreter()
let src = code_typed1( f, (Int, Int); interp)
    line = src.code[end]
    if VERSION >= v"1.12"
        @test line == ReturnNode(:(:overlay))
    end
end

end # module test_femtocompiler_typeinf_local
