using Jive
@If VERSION >= v"1.12" module test_femtocompiler_reflection

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
#= Base.print_statement_costs(stdout, tt)
+(x::T, y::T) where T<:Union{Int128, Int16, Int32, Int64, Int8, UInt128, UInt16, UInt32, UInt64, UInt8} @ Base int.jl:87
 1 1 ─ %1 = intrinsic Base.add_int(_2, _3)::Int64
 0 └──      return %1
=#
buf1 = IOBuffer()
Base.print_statement_costs(buf1, tt; interp)
buf2 = IOBuffer()
Base.print_statement_costs(buf2, tt)
@test take!(buf1) == take!(buf2)

end # module test_femtocompiler_reflection
