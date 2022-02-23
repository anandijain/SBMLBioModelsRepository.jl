# clone test_suite repo
sbml_test_suite()

N = 100
println("****SBML TEST SUITE TESTING****")
suite_fns = get_sbml_suite_fns()[1:N]
fn = suite_fns[1]

@test isfile(fn)
@test readSBML(fn, doc -> begin
    set_level_and_version(3, 2)(doc)
    convert_simplify_math(doc)
end) isa SBML.Model

now_fmtd = Dates.format(now(), dateformat"yyyy-mm-dd\THH-MM-SS")
suite_df = lower_fns(suite_fns; write_fn = "test_suite_$(now_fmtd).csv", verbose = true)

num_good = nrow(filter(:retcode => x -> x == 5, suite_df))
@info "suite num_good: $num_good / $N"

ds = filter(isdir, readdir(joinpath(datadir, "sbml-test-suite", "semantic"); join = true))[1:N]
df = verify_all(ds)
CSV.write(joinpath(logdir, "suite_verified_$(now_fmtd).csv"), df)
using SBMLBioModelsRepository
SBMLBioModelsRepository.
pipeline(`grep -R -l '<listOfRules ' `, `sort`)

using SBMLBioModelsRepository
using Pkg, Test
using SBML, SBMLToolkit
using ModelingToolkit, OrdinaryDiffEq, CSV, DataFrames, BenchmarkTools, Sundials
using Base.Threads, Glob, Dates
res = verify_case("/Users/anand/.julia/dev/SBMLBioModelsRepository.jl/data/sbml-test-suite/semantic/00030"; verbose = true)