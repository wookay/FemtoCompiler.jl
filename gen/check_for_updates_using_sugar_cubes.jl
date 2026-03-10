# https://github.com/wookay/SugarCubes.jl
#
# ~/.julia/dev/SugarCubes main✔   ln -s  JULIA_SOURCE_PATH  sources
#
# see also https://github.com/wookay/SugarCubes.jl/blob/main/test/sugarcubes/femtocompier_typeinf_edge.jl

using Test
using Pkg # Pkg.devdir
using SugarCubes: code_block_with, has_diff

function checks_has_diff(src_path::String,
                         src_signature::Expr,
                         dest_path::String,
                         dest_signature::Expr)
    printstyled(stdout, "checks_has_diff", color = :cyan)
    print(stdout, " ", basename(src_path), " ")
    printstyled(stdout, src_signature.args[1].args[1], color = :blue)
    src_filepath = normpath(Pkg.devdir(), src_path)
    dest_filepath = normpath(Pkg.devdir(), dest_path)
    @test isfile(src_filepath)
    @test isfile(dest_filepath)
    src_block = code_block_with(; filepath = src_filepath, signature = src_signature)
    dest_block = code_block_with(; filepath = dest_filepath, signature = dest_signature)
    @test has_diff(src_block, dest_block) === false
    println(stdout)
end

checks_has_diff(
    "SugarCubes/sources/Compiler/src/abstractinterpretation.jl",
    :(function typeinf_local(interp::AbstractInterpreter, frame::InferenceState, nextresult::CurrentState) end),
    "FemtoCompiler/ext/abstractinterpretation.jl",
    :(function typeinf_local(interp::FemtoInterpreter, frame::InferenceState, nextresult::CurrentState) end)
)

checks_has_diff(
    "SugarCubes/sources/Compiler/src/typeinfer.jl",
    :(function typeinf_edge(interp::AbstractInterpreter, method::Method, @nospecialize(atype), sparams::SimpleVector, caller::AbsIntState, edgecycle::Bool, edgelimited::Bool) end),
    "FemtoCompiler/ext/typeinfer.jl",
    :(function typeinf_edge(interp::FemtoInterpreter, method::Method, @nospecialize(atype), sparams::SimpleVector, caller::AbsIntState, edgecycle::Bool, edgelimited::Bool) end)
)

checks_has_diff(
    "SugarCubes/sources/Compiler/src/typeinfer.jl",
    :(function typeinf_frame(interp::AbstractInterpreter, mi::MethodInstance, run_optimizer::Bool) end),
    "FemtoCompiler/ext/typeinfer.jl",
    :(if VERSION >= v"1.13.0-DEV.483" function typeinf_frame(interp::FemtoInterpreter, mi::MethodInstance, run_optimizer::Bool) end end)
)
