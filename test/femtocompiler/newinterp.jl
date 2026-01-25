module test_femtocompiler_newinterp

using Test
using Core.Compiler: Compiler as CC
using .CC: cache_owner, code_cache
using .CC: NativeInterpreter
using FemtoCompiler: FemtoInterpreter

native_interp = NativeInterpreter()
femto_interp = FemtoInterpreter()

@test cache_owner(native_interp) === nothing
# @info cache_owner(femto_interp)

@test code_cache(native_interp) isa CC.OverlayCodeCache{CC.InternalCodeCache}
@test code_cache(femto_interp) isa CC.OverlayCodeCache{CC.InternalCodeCache}

end # module test_femtocompiler_newinterp
