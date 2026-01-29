module test_femtocompiler_detect_closure_boxes

using Test
using FemtoCompiler

if VERSION >= v"1.14.0-DEV.1629"
@test isempty(Test.detect_closure_boxes(FemtoCompiler))
end

end # module test_femtocompiler_detect_closure_boxes
