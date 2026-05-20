using Jive
# julia commit 6c7ebe0e41
@If VERSION >= v"1.14.0-DEV.1833" module test_femtocompiler_reflection

using Test
using FemtoCompiler: FemtoCompiler, FemtoInterpreter
using Core: Compiler as CC
using .CC: MethodInstance, InferenceResult, typeinf_lattice, Const, InferenceState, CodeInfo, CurrentState

interp = FemtoInterpreter()

f = +
types = (Int, Int)

𝕃ᵢ = typeinf_lattice(interp)
mi::MethodInstance = Base.method_instance(f, types)
result = InferenceResult(mi, 𝕃ᵢ)
@test result.argtypes == [Const(+), Int, Int]
frame = InferenceState(result, #=cache_mode=#:no, interp)
@test frame.src isa CodeInfo
nextresult1 = CurrentState()
nextresult2 = Base.invoke_interp_compiler(interp, :typeinf_local, interp, frame, nextresult1)
@test nextresult2 isa CurrentState

tt = Base.signature_type(f, types)
# Base.print_statement_costs(stdout, tt)
#=
+(x::Int64, y::Int64) @ Base essentials.jl:1226
 1 1 ─ %1 = intrinsic Base.add_int(_2, _3)::Int64
 0 └──      return %1
=#

maxcost = FemtoCompiler.code_statement_costs(f, types; interp)
@test maxcost == 1

end # module test_femtocompiler_reflection
