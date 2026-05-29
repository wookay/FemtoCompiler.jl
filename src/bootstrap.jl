# module FemtoCompiler

using .CC: MethodInstance, IRCode, InliningState, OptimizationState, InferenceResult, InferenceState, SimpleVector, MethodMatch,
           T_FFUNC_VAL, T_IFUNC, SOURCE_MODE_ABI, SOURCE_MODE_NOT_REQUIRED, TRIM_NO,
           ssa_inlining_pass!, optimize, typeinf_ext, compact!, get_world_counter, _methods_by_ftype, unwraptv,
           specialize_method, typeinf_ext_toplevel, isa_compileable_sig, typename, sub_float
using .CC: typeinf, typeinf_edge

# from julia/Compiler/src/bootstrap.jl
# function bootstrap!()
function bootstrap(io::IO)
    # global bootstrapping_compiler = true #
    let time() = ccall(:jl_clock_now, Float64, ())
        println(io, "Compiling the femto compiler. This may take several minutes ...") #

        ssa_inlining_pass!_tt = Tuple{typeof(ssa_inlining_pass!), IRCode, InliningState{NativeInterpreter}, Bool}
        optimize_tt = Tuple{typeof(optimize), NativeInterpreter, OptimizationState{NativeInterpreter}, InferenceResult}
        typeinf_ext_tt = Tuple{typeof(typeinf_ext), NativeInterpreter, MethodInstance, UInt8}
        typeinf_tt = Tuple{typeof(typeinf), NativeInterpreter, InferenceState{NativeInterpreter}}
        typeinf_edge_tt = Tuple{typeof(typeinf_edge), NativeInterpreter, Method, Any, SimpleVector, InferenceState{NativeInterpreter}, Bool, Bool}
        fs = Any[
            # we first create caches for the optimizer, because they contain many loop constructions
            # and they're better to not run in interpreter even during bootstrapping
            compact!, ssa_inlining_pass!_tt, optimize_tt,
            # then we create caches for inference entries
            typeinf_ext_tt, typeinf_tt, typeinf_edge_tt,
        ]
        # tfuncs can't be inferred from the inference entries above, so here we infer them manually
        for x in T_FFUNC_VAL
            push!(fs, x[3])
        end
        for i = 1:length(T_IFUNC)
            if isassigned(T_IFUNC, i)
                x = T_IFUNC[i]
                push!(fs, x[3])
            else
                println(stderr, "WARNING: tfunc missing for ", reinterpret(IntrinsicFunction, Int32(i)))
            end
        end
        starttime = time()
        world = get_world_counter()
        for f in fs
            if isa(f, DataType) && f.name === typename(Tuple)
                tt = f
            else
                tt = Tuple{typeof(f), Vararg{Any}}
            end
            matches = _methods_by_ftype(tt, 10, world)::Vector
            if isempty(matches)
                println(stderr, "WARNING: no matching method found for `", tt, "`")
            else
                for m in matches
                    # remove any TypeVars from the intersection
                    m = m::MethodMatch
                    params = Any[m.spec_types.parameters...]
                    for i = 1:length(params)
                        params[i] = unwraptv(params[i])
                    end
                    mi = specialize_method(m.method, Tuple{params...}, m.sparams)
                    #isa_compileable_sig(mi) || println(stderr, "WARNING: inferring `", mi, "` which isn't expected to be called.")
                    typeinf_ext_toplevel(mi, world, isa_compileable_sig(mi) ? SOURCE_MODE_ABI : SOURCE_MODE_NOT_REQUIRED, TRIM_NO)
                end
            end
        end
        endtime = time()
        println(io, "Base.Compiler ──── ", sub_float(endtime,starttime), " seconds") #
    end
    # activate_codegen!() #
    # global bootstrapping_compiler = false #
    nothing
end

# module FemtoCompiler
