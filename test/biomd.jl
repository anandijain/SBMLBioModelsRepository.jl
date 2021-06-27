# get the dataset
# df = biomodels(;curl_meta=true, verbose=false)

println("BIOMD DATASET TESTING")
biomd_fns = get_biomd_fns(;ode=true)
fn = biomd_fns[1]
@test length(biomd_fns) == 984
@test readSBML(fn) isa SBML.Model

now_fmtd = Dates.format(now(), dateformat"yyyy-mm-dd\THH-MM-SS")
biomd_df = lower_fns(biomd_fns[1:50]; write_fn="biomd_odes_lowered_$(now_fmtd).csv", verbose=true)
sort!(biomd_df, [:n_dvs, :n_ps], rev=true)
@show biomd_df
@info nrow(filter(retcode => x-> x==5)) "good ones"
