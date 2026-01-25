using Jive
@If VERSION >= v"1.12" module test_femtocompiler_reflection

using Test
using FemtoCompiler: FemtoInterpreter
using Core: Compiler as CC
using .CC: typename, MethodInstance, InferenceResult, typeinf_lattice, Const, InferenceState, CodeInfo, CurrentState

f = +
types = (Int, Int)

m = methods(f, types)
mi::MethodInstance = m[1].specializations[1]
interp = FemtoInterpreter()
result = InferenceResult(mi, typeinf_lattice(interp))
@test result.argtypes == [Const(+), Int, Int]
frame = InferenceState(result, #=cache_mode=#:local, interp)
@test frame.src isa CodeInfo
nextresult1 = CurrentState()
nextresult2 = Base.invoke_interp_compiler(interp, :typeinf_local, interp, frame, nextresult1)
@test nextresult2 isa CurrentState

end # module test_femtocompiler_reflection
