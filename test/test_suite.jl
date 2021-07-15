using SBMLBioModelsRepository
using CSV
using Test
using Dates

sbml_test_suite()

println("****SBML TEST SUITE TESTING****")
suite_fns = get_sbml_suite_fns()
fn = suite_fns[1]

@test isfile(fn)
SBMLToolkit.checksupport(fn)
@test readSBML(fn, doc -> begin
        set_level_and_version(3, 2)(doc)
        convert_simplify_math(doc)
    end) isa SBMLToolkit.SBML.Model

now_fmtd = Dates.format(now(), dateformat"yyyy-mm-dd\THH-MM-SS")
suite_df = lower_fns(suite_fns; write_fn="test_suite_$(now_fmtd).csv", verbose=true)
@show suite_df
@info nrow(filter(suite_df, :retcode => x -> x == 5)) "num good ones"

rm(logdir, recursive=true)
mkdir(logdir)
df = verify_all()
CSV.write(joinpath(logdir, "suite_verified.csv"), df)

"""
writes the good ones to files. works but needs refactor

outdir = "../SBMLBioModelsRepository/data/sbml-test-suite-mtk/"
"""
function process_good(outdir = joinpath("..", "SBMLBioModelsRepository", "data", "sbml-test-suite-mtk"))
    for p in g 
        fn, sys = first(p), last(p)
        fn = basename(fn)
        fn, ext = splitext(fn)
        
        if write 
            outfn = joinpath(outdir, "$(fn).jl")
            open(outfn, "w") do io 
                write(io, sys)
            end
        end
    end
end
