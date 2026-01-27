# module CompilerExt

precompile(CC.typeinf_local, (FemtoInterpreter, InferenceState, CurrentState))

precompile(CC.typeinf_edge, (FemtoInterpreter, Method, Any, SimpleVector, AbsIntState, Bool, Bool))
precompile(CC.typeinf_frame, (FemtoInterpreter, MethodMatch, Bool))
precompile(CC.typeinf_frame, (FemtoInterpreter, Method, Any, SimpleVector, Bool))
precompile(CC.typeinf_frame, (FemtoInterpreter, MethodInstance, Bool))

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

# module CompilerExt
