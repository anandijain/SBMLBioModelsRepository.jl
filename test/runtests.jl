using SBMLBioModelsRepository
using Pkg, Test
using SBML, SBMLToolkit
using ModelingToolkit, OrdinaryDiffEq, CSV, DataFrames, BenchmarkTools, Sundials
using Base.Threads, Glob, Dates

!isdir("logs/") && mkdir("logs/")

@testset "SBMLBioModelsRepository.jl" begin
    @testset "test_suite" begin include("test_suite.jl") end
    # @testset "biomd" begin include("biomd.jl") end
end
