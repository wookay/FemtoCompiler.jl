# check_for_updates_using_sugar_cubes.jl
#
# ~/.julia/dev/FemtoCompiler main✔   ln -s  JULIA_SOURCE_PATH  sources

using Test
using SugarCubes: code_block_with, has_diff
# https://github.com/wookay/SugarCubes.jl

function check_the_code_block_diff(src_path::String,
                                   src_signature::Expr,
                                   dest_path::String,
                                   dest_signature::Expr ;
                                   skip_lines = (src = Int[], dest = Int[]))
    printstyled(stdout, "✔ ", color = :blue)
    print(stdout, " ", basename(src_path), " ")
    src_filepath = normpath(@__DIR__, "..", src_path)
    dest_filepath = normpath(@__DIR__, "..", dest_path)
    @test isfile(src_filepath)
    @test isfile(dest_filepath)
    src_block = code_block_with(; filepath = src_filepath, signature = src_signature)
    (depth, kind, sig) = src_block.signature.layers[end]
    printstyled(stdout, sig.args[1], color = :cyan)
    dest_block = code_block_with(; filepath = dest_filepath, signature = dest_signature)
    @test has_diff(src_block, dest_block; skip_lines) === false
    println(stdout)
end

check_the_code_block_diff(
    "ext/abstractinterpretation.jl",
    :(function typeinf_local(interp::FemtoInterpreter, frame::InferenceState, nextresult::CurrentState) end),
    "sources/Compiler/src/abstractinterpretation.jl",
    :(function typeinf_local(interp::AbstractInterpreter, frame::InferenceState, nextresult::CurrentState) end)
)

check_the_code_block_diff(
    "ext/typeinfer.jl",
    :(function typeinf_edge(interp::FemtoInterpreter, method::Method, @nospecialize(atype), sparams::SimpleVector, caller::AbsIntState, edgecycle::Bool, edgelimited::Bool) end),
    "sources/Compiler/src/typeinfer.jl",
    :(function typeinf_edge(interp::AbstractInterpreter, method::Method, @nospecialize(atype), sparams::SimpleVector, caller::AbsIntState, edgecycle::Bool, edgelimited::Bool) end)
)

check_the_code_block_diff(
    "ext/typeinfer.jl",
    :(if VERSION >= v"1.13.0-DEV.483" function typeinf_frame(interp::FemtoInterpreter, mi::MethodInstance, run_optimizer::Bool) end end),
    "sources/Compiler/src/typeinfer.jl",
    :(function typeinf_frame(interp::AbstractInterpreter, mi::MethodInstance, run_optimizer::Bool) end)
)

check_the_code_block_diff(
    "src/bootstrap.jl",
    :(function bootstrap(io::IO) end),
    "sources/Compiler/src/bootstrap.jl",
    :(function bootstrap!() end) ;
    skip_lines = (src = vcat(1, 3, -5, -3:-2), dest = vcat(1, 3, -5, -3:-2))
)

check_the_code_block_diff(
    "src/irutils.jl",
    :(function code_statement_costs(f::Function, types::Tuple; interp::Union{Nothing, AbstractInterpreter} = nothing)::Union{Nothing, Int} end),
    "sources/base/reflection.jl",
    :(function print_statement_costs(io::IO, @nospecialize(tt::Type); world::UInt=get_world_counter(), interp=nothing) end) ;
    skip_lines = (src = vcat(1:2, 8, 12, 15, 20:26, 28, -1), dest = vcat(6, 10, 13, 18:23, 25))
)
