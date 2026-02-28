using Jive
@If VERSION >= v"1.12" module test_femtocompiler_typeinf

using Test
using Core: CodeInfo, ReturnNode
using Core: Compiler as CC
using Base: MethodInstance
using FemtoCompiler: FemtoCompiler, FemtoInterpreter, OverlayPlus, code_typed1

f = OverlayPlus.overlay_plus

let src = code_typed1(f, (Int, Int))
    line = src.code[end]
    @test line == ReturnNode(:(:default))
end

interp = FemtoInterpreter()
let src = code_typed1(f, (Int, Int); interp)
    line = src.code[end]
    if VERSION >= v"1.12"
        @test line == ReturnNode(:(:overlay))
    end
end


f = +
types = (Int, Int)

𝕃ᵢ = CC.typeinf_lattice(interp)
@test 𝕃ᵢ isa CC.InferenceLattice

mi::MethodInstance = Base.method_instance(f, types)
@test CC.typeinf_type(interp, mi) === Int

frame = CC.typeinf_frame(interp, mi, #=run_optimizer=#false)
@test frame isa CC.InferenceState

result = CC.InferenceResult(mi, 𝕃ᵢ)
@test result.argtypes == [CC.Const(+), Int, Int]

frame = CC.InferenceState(result, #=cache_mode=#:no, interp)
@test CC.is_inferred(frame) === false
@test CC.typeinf(interp, frame)::Bool
@test CC.is_inferred(frame) === true

result = CC.InferenceResult(mi, 𝕃ᵢ)
frame = CC.InferenceState(result, #=cache_mode=#:no, interp)
nextresult1 = CC.CurrentState()
@test CC.is_inferred(frame) === false
nextresult2 = CC.typeinf_local(interp, frame, nextresult1)
@test nextresult2 isa CC.CurrentState

end # module test_femtocompiler_typeinf
