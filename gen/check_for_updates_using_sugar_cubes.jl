# https://github.com/wookay/SugarCubes.jl
#
# ~/.julia/dev/SugarCubes main✔   ln -s  JULIA_SOURCE_PATH  sources

using Test
using Pkg # Pkg.devdir
using SugarCubes: code_block_with, has_diff

src_path = normpath(Pkg.devdir(), "SugarCubes/sources/Compiler/src/abstractinterpretation.jl")
@test isfile(src_path)
src_signature = :(function typeinf_local(interp::AbstractInterpreter, frame::InferenceState, nextresult::CurrentState) end)
src_block = code_block_with(; filepath = src_path, signature = src_signature)

dest_path = normpath(Pkg.devdir(), "FemtoCompiler/ext/abstractinterpretation.jl")
@test isfile(dest_path)
dest_signature = :(function typeinf_local(interp::FemtoInterpreter, frame::InferenceState, nextresult::CurrentState) end)
dest_block = code_block_with(; filepath = dest_path, signature = dest_signature)

@test has_diff(src_block, dest_block) === false
