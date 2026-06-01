using Jive
@If VERSION >= v"1.14-DEV" module test_femtocompiler_bootstrap

using Test
using FemtoCompiler: bootstrap

bootstrap(stdout)

end # module test_femtocompiler_bootstrap
