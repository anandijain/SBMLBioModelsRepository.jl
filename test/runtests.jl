using SBMLBioModelsRepository
using Pkg, Test
Pkg.add(url="https://github.com/paulflang/SBML.jl/", rev="pl/mk-species-units")
using SBML  
using ModelingToolkit, OrdinaryDiffEq, CSV, DataFrames, BenchmarkTools
using Base.Threads, Glob

!isdir("logs/") && mkdir("logs/")

@testset "SBMLBioModelsRepository.jl" begin
    @testset "biomd" begin include("biomd.jl") end
    # @testset "test_suite" begin include("test_suite.jl") end
end
