# module FemtoCompiler

using Core.Compiler: Compiler as CC
using .CC: AbstractInterpreter, NativeInterpreter

struct FemtoCacheOwner
end

# from julia/Compiler/src/types.jl
# NativeInterpreter
struct FemtoInterpreter <: AbstractInterpreter
    native::NativeInterpreter
    cache_owner::FemtoCacheOwner
    function FemtoInterpreter()
        native = NativeInterpreter()
        cache_owner = FemtoCacheOwner()
        new(native, cache_owner)
    end
end

CC.InferenceParams(interp::FemtoInterpreter) = InferenceParams(interp.native)
CC.OptimizationParams(interp::FemtoInterpreter) = OptimizationParams(interp.native)
CC.get_inference_world(interp::FemtoInterpreter) = get_inference_world(interp.native)
CC.get_inference_cache(interp::FemtoInterpreter) = get_inference_cache(interp.native)
function CC.cache_owner(interp::FemtoInterpreter)
    @info :cache_owner cache_owner
    cache_owner(interp.native)
end
CC.codegen_cache(interp::FemtoInterpreter) = codegen_cache(interp.native)
CC.infer_compilation_signature(interp::FemtoInterpreter) = infer_compilation_signature(interp.native)
using .CC: WorldRange
CC.code_cache(interp::FemtoInterpreter, extended_range::WorldRange) = code_cache(interp.native, extended_range)

# module FemtoCompiler
