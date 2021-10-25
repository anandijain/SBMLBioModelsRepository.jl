# clone test_suite repo
sbml_test_suite()

case_range = 0001:1664  # max: 1664
println("****SBML TEST SUITE TESTING****")
suite_fns = get_sbml_suite_fns()[case_range]
fn = suite_fns[1]

@test isfile(fn)
@test readSBML(fn, doc -> begin
        set_level_and_version(3, 2)(doc)
        convert_simplify_math(doc)
    end) isa SBML.Model

now_fmtd = Dates.format(now(), dateformat"yyyy-mm-dd\THH-MM-SS")
const log_subdir = joinpath(logdir, now_fmtd)
mkdir(log_subdir)
# @Anand: I don't think we still need this. What do you think??
# suite_df = lower_fns(suite_fns; write_fn=joinpath(log_subdir, "test_suite.csv"), verbose=true)

ds = filter(isdir, readdir(joinpath(datadir, "sbml-test-suite", "semantic"); join=true))[case_range]
df = verify_all(ds, plot_dir=log_subdir)

num_good = nrow(filter(:diffeq_retcode => x-> x==5, df)) 
@info "suite num_good: $num_good / $(last(case_range)-first(case_range))"
CSV.write(joinpath(log_subdir, "suite_verified.csv"), df)
