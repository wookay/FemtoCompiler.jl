# module FemtoCompiler

using .CC: AbstractInterpreter, NativeInterpreter

# from julia/Compiler/src/types.jl
# NativeInterpreter
struct FemtoInterpreter <: AbstractInterpreter
    native::NativeInterpreter
    cache_owner::Union{Nothing}
    function FemtoInterpreter()
        native = NativeInterpreter()
        cache_owner = nothing
        new(native, cache_owner)
    end
end

# module FemtoCompiler
