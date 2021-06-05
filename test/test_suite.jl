include("lower.jl")
sbml_test_suite()
suite_fns = get_sbml_suite_fns()
fn = suite_fns[1]
@test isfile(fn)
@info fn

println("****SBML TEST SUITE TESTING****")
f(x) = ODESystem(readSBML(x))
suite_fns = get_sbml_suite_fns()
fn = suite_fns[1]
@test isfile(fn)
@test readSBML(fn) isa SBML.Model
(good, bad) = goodbad(f, suite_fns)
@info bad[1]
@test length(bad) == 646 # regression test 
@test sum(length.([good, bad])) == 1664

suite_df = lower_fns(suite_fns; write_fn="test_suite.csv")
@show suite_df

@btime lower_fns($suite_fns[1:50]; write=false) # 176.973 s (253344211 allocations: 17.69 GiB)
@btime serial_lower_fns($suite_fns[1:50]; write=false)
@show bad
@time test_sbml(suite_fns)


"""
writes the good ones to files. works but needs refactor

outdir = "../SBMLBioModelsRepository/data/sbml-test-suite-mtk/"
"""
function process_good(outdir = "../SBMLBioModelsRepository/data/sbml-test-suite-mtk/")
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
