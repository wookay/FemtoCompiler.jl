# module CompilerExt

using .CC: WorldRange

# from julia/Compiler/src/types.jl
# NativeInterpreter
CC.InferenceParams(interp::FemtoInterpreter) = CC.InferenceParams(interp.native)
CC.OptimizationParams(interp::FemtoInterpreter) = CC.OptimizationParams(interp.native)
CC.get_inference_world(interp::FemtoInterpreter) = CC.get_inference_world(interp.native)
CC.get_inference_cache(interp::FemtoInterpreter) = CC.get_inference_cache(interp.native)

function CC.cache_owner(interp::FemtoInterpreter)
    # @info :cache_owner interp.cache_owner
    CC.cache_owner(interp.native)
end

if VERSION >= v"1.13.0-DEV.81" # julia commit 9d2e9ed8a2
CC.codegen_cache(interp::FemtoInterpreter) = CC.codegen_cache(interp.native)
end

CC.infer_compilation_signature(interp::FemtoInterpreter) = CC.infer_compilation_signature(interp.native)

CC.code_cache(interp::FemtoInterpreter, extended_range::WorldRange) = CC.code_cache(interp.native, extended_range)

# module CompilerExt
