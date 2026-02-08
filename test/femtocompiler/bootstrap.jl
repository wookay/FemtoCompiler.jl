using Jive
@If VERSION >= v"1.12" module test_femtocompiler_bootstrap

using Test
using FemtoCompiler: bootstrap

bootstrap(stdout)

end # module test_femtocompiler_bootstrap
