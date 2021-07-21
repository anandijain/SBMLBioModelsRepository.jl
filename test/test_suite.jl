# clone test_suite repo
sbml_test_suite()

case_range = 1:100
println("****SBML TEST SUITE TESTING****")
suite_fns = get_sbml_suite_fns()[case_range]
fn = suite_fns[1]

@test isfile(fn)
@test readSBML(fn, doc -> begin
        set_level_and_version(3, 2)(doc)
        convert_simplify_math(doc)
    end) isa SBML.Model

now_fmtd = Dates.format(now(), dateformat"yyyy-mm-dd\THH-MM-SS")
suite_df = lower_fns(suite_fns; write_fn="test_suite_$(now_fmtd).csv", verbose=true)

num_good = nrow(filter(:retcode => x-> x==5, suite_df)) 
@info "suite num_good: $num_good / $(last(case_range)-first(case_range))"

ds = filter(isdir, readdir(joinpath(datadir, "sbml-test-suite", "semantic"); join=true))[case_range]
df = verify_all(ds)
CSV.write(joinpath(logdir, "suite_verified_$(now_fmtd).csv"), df)
