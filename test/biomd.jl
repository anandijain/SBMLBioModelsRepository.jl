N = 100
# get the dataset
df = biomodels(; curl_meta = true, verbose = false, limit = N)

println("BIOMD DATASET TESTING")
biomd_fns = get_biomd_fns()
fn = biomd_fns[1]
@test readSBML(fn) isa SBML.Model

now_fmtd = Dates.format(now(), dateformat"yyyy-mm-dd\THH-MM-SS")
biomd_df = lower_fns(biomd_fns; write_fn = "biomd_odes_lowered_$(now_fmtd).csv", verbose = true)
sort!(biomd_df, [:n_dvs, :n_ps], rev = true)
@show biomd_df

num_good = nrow(filter(:retcode => x -> x == 5, biomd_df))
@info "biomd num_good: $num_good / $N"
