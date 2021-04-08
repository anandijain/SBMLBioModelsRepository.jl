using SBMLBioModelsRepository
using CSV, DataFrames
using Test

# test we get all biomodels sbml files
# biomodels() # don't run all the time
# datadir = joinpath(@__DIR__, "../data/")
# @test ispath(datadir)

# fns = readdir(joinpath(datadir, "biomd/"))
# biomd_df = CSV.read(joinpath(datadir, "sbml_biomodels.csv"), DataFrame)

# @test length(fns) == nrow(biomd_df) # 2216

# test suite stuff
sbml_test_suite()
suite_fns = get_sbml_suite_fns()
@test isfile(suite_fns[1])
@show suite_fns
