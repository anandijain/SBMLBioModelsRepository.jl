include("lower.jl")
# get the dataset
# df = biomodels(;curl_meta=true, verbose=false)

# biomd_odes = CSV.read("../data/SBML_ODEs_biomd.csv", DataFrame) # fix for CI
# ids = biomd_odes.id
# biomd_fns = .*("../data/biomd/", ids, ".xml")
# size = 0
# sizemap = map(fn->fn=>stat(fn).size, biomd_fns) # ~200 MB
# sort!(sizemap, by=x->last.(x), rev=true)

# biomd_dir = joinpath(datadir, "biomd/")
# biomd_fns = readdir(biomd_dir; join=true)

# (good, bad) = goodbad(f, first.(sizemap)[1:100])
# @test sum(length.([good, bad])) == 2226

println("BIOMD DATASET TESTING")
biomd_dir = joinpath(datadir, "biomd/")
@show biomd_dir
@test ispath(biomd_dir)
biomd_fns = readdir(biomd_dir; join=true)
fn = biomd_fns[1]
@test length(biomd_fns) == 984
@test readSBML(fn) isa SBML.Model
(good, bad) = goodbad(x->ODESystem(readSBML(x)), biomd_fns[1:100])
(good, bad) = goodbad(x->ODESystem(readSBML(x)), biomd_fns)
@info length(good), length(bad)
biomd_df = lower_fns(biomd_fns; write_fn="biomd_odes_lowered.csv")
@show biomd_df
