module test_femtocompiler_typeinf_local

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
code_typed1(args...; kwargs...) = first(only(FemtoCompiler.code_typed(args...; kwargs...)))::CodeInfo

f = overlay_plus
interp = FemtoInterpreter()
let src = invokelatest(code_typed1, f, (Int, Int); interp, optimize=false, debuginfo=:source)
    line = src.code[end]
    if VERSION >= v"1.12"
        @test line == ReturnNode(:(:overlay))
    end
end

# optimize=false, debuginfo=:source
# #= 4290.6 ms =# precompile(Tuple{typeof(Base.Compiler.typeinf_code), FemtoCompiler.FemtoInterpreter, Core.MethodMatch, Bool}) # recompile

# optimize=false, debuginfo=:default
# #= 4521.9 ms =# precompile(Tuple{typeof(Base.Compiler.typeinf_code), FemtoCompiler.FemtoInterpreter, Core.MethodMatch, Bool}) # recompile

# optimize=true, debuginfo=:source
# #= 4544.6 ms =# precompile(Tuple{typeof(Base.Compiler.typeinf_code), FemtoCompiler.FemtoInterpreter, Core.MethodMatch, Bool}) # recompile

# optimize=true, debuginfo=:default
# #= 4597.0 ms =# precompile(Tuple{typeof(Base.Compiler.typeinf_code), FemtoCompiler.FemtoInterpreter, Core.MethodMatch, Bool}) # recompile

# optimize=true, debuginfo=:none
# #= 4612.6 ms =# precompile(Tuple{typeof(Base.Compiler.typeinf_code), FemtoCompiler.FemtoInterpreter, Core.MethodMatch, Bool}) # recompile

# optimize=false, debuginfo=:none
# #= 4623.5 ms =# precompile(Tuple{typeof(Base.Compiler.typeinf_code), FemtoCompiler.FemtoInterpreter, Core.MethodMatch, Bool}) # recompile

let src = invokelatest(code_typed1, f, (Int, Int))
    line = src.code[end]
    @test line == ReturnNode(:(:default))
end

end # module test_femtocompiler_typeinf_local
