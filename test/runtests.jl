using SBMLBioModelsRepository
using Pkg, Test
Pkg.add(url="https://github.com/paulflang/SBML.jl/", rev="pl/mk-species-units")
Pkg.develop(url="https://github.com/paulflang/SBML.jl/")
using SBML
using ModelingToolkit, OrdinaryDiffEq, CSV, DataFrames, BenchmarkTools, Sundials
using Base.Threads, Glob, Dates

!isdir("logs/") && mkdir("logs/")

@testset "SBMLBioModelsRepository.jl" begin
    include("lower.jl")
    @testset "test_suite" begin include("test_suite.jl") end
    @testset "biomd" begin include("biomd.jl") end
end
