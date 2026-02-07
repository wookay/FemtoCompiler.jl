# module CompilerExt

### FemtoInterpreter

# FemtoInterpreter - ext/newinterp.jl
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

# FemtoInterpreter - ext/abstractinterpretation.jl
precompile(CC.typeinf_local, (FemtoInterpreter, InferenceState, CurrentState))

# FemtoInterpreter - ext/typeinfer.jl
precompile(CC.typeinf_edge, (FemtoInterpreter, Method, Any, SimpleVector, AbsIntState, Bool, Bool))
precompile(CC.typeinf_frame, (FemtoInterpreter, MethodMatch, Bool))
precompile(CC.typeinf_frame, (FemtoInterpreter, Method, Any, SimpleVector, Bool))
precompile(CC.typeinf_frame, (FemtoInterpreter, MethodInstance, Bool))

# FemtoInterpreter - Core
#=  186.1 ms =# precompile(Tuple{typeof(Core.kwcall), NamedTuple{(:interp,), Tuple{FemtoCompiler.FemtoInterpreter}}, typeof(Base.print_statement_costs), Base.GenericIOBuffer{Memory{UInt8}}, Type})
#=    6.4 ms =# precompile(Tuple{Type{FemtoCompiler.FemtoInterpreter}})

# FemtoInterpreter - Base
precompile(Base.invoke_interp_compiler, (FemtoInterpreter, Symbol, FemtoInterpreter, Vararg{Any}))

# FemtoInterpreter - CC
#=    6.7 ms =# precompile(Tuple{typeof(Base.Compiler._findall_matches), FemtoCompiler.FemtoInterpreter, Any}) # recompile
#= 2949.7 ms =# precompile(Tuple{typeof(Base.Compiler.typeinf_code), FemtoCompiler.FemtoInterpreter, Core.MethodMatch, Bool})
#=   71.7 ms =# precompile(Tuple{typeof(Base.Compiler.finish_nocycle), FemtoCompiler.FemtoInterpreter, Base.Compiler.InferenceState, UInt64})
precompile(CC.typeinf_type, (FemtoInterpreter, MethodInstance))
precompile(CC.doworkloop, (FemtoInterpreter, CC.InferenceState))
if VERSION >= v"1.13.0-DEV.483" # julia commit 3864b18af6
precompile(CC.compute_inlining_cost, (FemtoInterpreter, CC.InferenceResult, CC.OptimizationResult))
end
precompile(CC.statement_costs!, (FemtoInterpreter, Array{Int, 1}, Array{Any, 1}, Core.CodeInfo, Core.MethodMatch))

### CC.NativeInterpreter
precompile(Tuple{typeof(CC.typeinf_local), CC.NativeInterpreter, CC.InferenceState, CC.CurrentState})
precompile(Tuple{typeof(CC.typeinf_type), CC.NativeInterpreter, Core.MethodMatch})
precompile(Tuple{typeof(CC._infer_effects), CC.NativeInterpreter, Any, Bool})
#=   44.2 ms =# precompile(Tuple{typeof(Base.Compiler.typeinf_code), Base.Compiler.NativeInterpreter, Core.MethodMatch, Bool})
#=    6.2 ms =# precompile(Tuple{typeof(Base.Compiler._findall_matches), Base.Compiler.NativeInterpreter, Any}) # recompile
if VERSION >= v"1.13.0-DEV.483" # julia commit 3864b18af6
#=    5.0 ms =# precompile(Tuple{typeof(Base.Compiler.compute_inlining_cost), Base.Compiler.NativeInterpreter, Base.Compiler.InferenceResult, Base.Compiler.OptimizationResult})
end
#=   18.0 ms =# precompile(Tuple{typeof(Base.Compiler.statement_costs!), Base.Compiler.NativeInterpreter, Array{Int64, 1}, Array{Any, 1}, Core.CodeInfo, Core.MethodMatch})
#=    4.9 ms =# precompile(Tuple{typeof(Base.invoke_interp_compiler), Nothing, Symbol, Base.Compiler.NativeInterpreter, Vararg{Any}})
#=    4.9 ms =# precompile(Tuple{typeof(Base.invoke_default_compiler), Symbol, Base.Compiler.NativeInterpreter, Vararg{Any}})

# Base
#=    4.8 ms =# precompile(Tuple{typeof(Base.findall), Type, Base.Compiler.CachedMethodTable{Base.Compiler.InternalMethodTable}})
#=   28.6 ms =# precompile(Tuple{typeof(Base.print_statement_costs), Base.GenericIOBuffer{Memory{UInt8}}, Type})

# module CompilerExt
