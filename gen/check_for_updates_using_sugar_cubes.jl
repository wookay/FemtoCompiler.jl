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
    print(stdout, " ", basename(src_path))
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
