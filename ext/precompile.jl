# module CompilerExt

# ext/abstractinterpretation.jl
precompile(CC.typeinf_local, (FemtoInterpreter, InferenceState, CurrentState))

# ext/typeinfer.jl
precompile(CC.typeinf_edge, (FemtoInterpreter, Method, Any, SimpleVector, AbsIntState, Bool, Bool))
precompile(CC.typeinf_frame, (FemtoInterpreter, MethodMatch, Bool))
precompile(CC.typeinf_frame, (FemtoInterpreter, Method, Any, SimpleVector, Bool))
precompile(CC.typeinf_frame, (FemtoInterpreter, MethodInstance, Bool))

# ext/newinterp.jl
precompile(CC.InferenceParams, (FemtoInterpreter,))
precompile(CC.OptimizationParams, (FemtoInterpreter,))
precompile(CC.get_inference_world, (FemtoInterpreter,))
precompile(CC.get_inference_cache, (FemtoInterpreter,))
precompile(CC.cache_owner, (FemtoInterpreter,))
if VERSION >= v"1.13.0-DEV.81" # julia commit 9d2e9ed8a2
precompile(CC.codegen_cache, (FemtoInterpreter,))
end
precompile(CC.infer_compilation_signature, (FemtoInterpreter,))
precompile(CC.code_cache, (FemtoInterpreter, WorldRange))

# Base
precompile(Base.invoke_interp_compiler, (FemtoInterpreter, Symbol, FemtoInterpreter, Vararg{Any}))

# CC
precompile(CC._findall_matches, (FemtoInterpreter, Any))
precompile(CC.typeinf_code, (FemtoInterpreter, MethodMatch, Bool))
precompile(CC.typeinf_type, (FemtoInterpreter, MethodInstance))
precompile(CC.doworkloop, (FemtoInterpreter, CC.InferenceState))
precompile(CC.finish_nocycle, (FemtoInterpreter, CC.InferenceState, UInt64))
if VERSION >= v"1.13.0-DEV.483" # julia commit 3864b18af6
precompile(CC.compute_inlining_cost, (FemtoInterpreter, CC.InferenceResult, CC.OptimizationResult))
end
precompile(CC.statement_costs!, (FemtoInterpreter, Array{Int, 1}, Array{Any, 1}, Core.CodeInfo, Core.MethodMatch))

# module CompilerExt
