using Jive
@If VERSION >= v"1.14.0-DEV.3067" module test_femtocompiler_typeinf_overlay_plus

using Test
using Core: ReturnNode
using Core: Compiler as CC
using Base: MethodInstance
using FemtoCompiler: FemtoCompiler, FemtoInterpreter, OverlayPlus, code_typed1

f = OverlayPlus.overlay_plus
@test f(1, 2) === :default

let src = code_typed1(f, (Int, Int))
    node = src.code[end]
    @test node == ReturnNode(QuoteNode(:default))
end

interp = FemtoInterpreter()
mi::MethodInstance = Base.method_instance(f, (Int, Int))
ci::Core.CodeInstance = get(CC.code_cache(interp), mi, nothing)
@test invoke(f, ci, 1, 2) === :default

let src = code_typed1(f, (Int, Int); interp)
    node = src.code[end]
    if VERSION >= v"1.12"
        @test node == ReturnNode(QuoteNode(:overlay_value))
    end
end

# from julia/test/precompile.jl
ms = Base._methods_by_ftype(Tuple{typeof(f), Int, Int}, OverlayPlus.OVERLAY_PLUS_MT, 1, Base.get_world_counter())
match = only(ms)
@test match isa Core.MethodMatch
inst = Base.specialize_method(match)
@test inst isa MethodInstance
@test inst.dispatch_status == 0x00
method = match.method
@test method isa Method
@test method.dispatch_status == 0x03
@test method.sig == Tuple{typeof(f), Int, Int}
@test only(Base.specializations(method)) === inst

list = methods(f, (Int, Int))
@test list isa Base.MethodList
method2 = only(list)
@test method2 isa Method
@test method2.dispatch_status == 0x03
@test method2.sig == Tuple{typeof(f), Any, Any}
inst2 = only(Base.specializations(method2))
@test inst2.dispatch_status == 0x00

# from julia/base/docs/Docs.jl
mt = OverlayPlus.OVERLAY_PLUS_MT
expr = Expr(:overlay, mt, f)
@test Base.Docs.astname(expr, false) === f
binding = Base.Docs.Binding(OverlayPlus, :overlay_with_doc_1)
@test Base.Docs._doc(binding).text == Core.svec("overlay doc 1\n")

@test QuoteNode(:default) === :(:default)

end # module test_femtocompiler_typeinf_overlay_plus


@If VERSION >= v"1.14.0-DEV.1826" module test_femtocompiler_typeinf_plus

using Test
using Core: Compiler as CC
using Base: MethodInstance
using FemtoCompiler: FemtoInterpreter

f = +
types = (Int, Int)

interp = FemtoInterpreter()
𝕃ᵢ = CC.typeinf_lattice(interp)
@test 𝕃ᵢ isa CC.InferenceLattice

mi::MethodInstance = Base.method_instance(f, types)
@test CC.typeinf_type(interp, mi) === Int

frame = CC.typeinf_frame(interp, mi, #=run_optimizer=# false)
@test frame isa CC.InferenceState

result = CC.InferenceResult(mi, 𝕃ᵢ)
@test result.argtypes == [CC.Const(+), Int, Int]

frame = CC.InferenceState(result, #=cache_mode=# :no, interp)
@test CC.is_inferred(frame) === false
@test CC.typeinf(interp, frame)::Bool
@test CC.is_inferred(frame) === true

result = CC.InferenceResult(mi, 𝕃ᵢ)
frame = CC.InferenceState(result, #=cache_mode=# :no, interp)
nextresult1 = CC.CurrentState()
@test CC.is_inferred(frame) === false
nextresult2 = CC.typeinf_local(interp, frame, nextresult1)
@test nextresult2 isa CC.CurrentState

end # module test_femtocompiler_typeinf_plus
