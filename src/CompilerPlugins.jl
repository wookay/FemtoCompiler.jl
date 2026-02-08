module CompilerPlugins # FemtoCompiler

using Core.Compiler: Compiler as CC
using .CC: MethodInstance, CodeInstance

# from julia/base/optimized_generics.jl
import Core.OptimizedGenerics.CompilerPlugins: typeinf, typeinf_edge

"""
    typeinf(owner, mi, source_mode)::CodeInstance

Return a `CodeInstance` for the given `mi` whose valid results include at
the least current tls world and satisfies the requirements of `source_mode`.
"""
function typeinf(owner, mi::MethodInstance, source_mode::UInt8)::CodeInstance
end

"""
    typeinf_edge(owner, mi, parent_frame, world, abi_mode)::CodeInstance
"""
function typeinf_edge(owner, mi::MethodInstance, parent_frame, world, abi_mode)::CodeInstance
end

end # module FemtoCompiler.CompilerPlugins
