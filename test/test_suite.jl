# include("lower.jl")
# sbml_test_suite()

println("****SBML TEST SUITE TESTING****")
f(x) = ODESystem(readSBML(x))
suite_fns = get_sbml_suite_fns()
fn = suite_fns[1]
@test isfile(fn)
@test readSBML(fn) isa SBML.Model
# (good, bad) = goodbad(f, suite_fns)
# @info bad[1]
# @test length(bad) == 646 # regression test 
# @test sum(length.([good, bad])) == 1664

now_fmtd = Dates.format(now(), dateformat"yyyy-mm-dd\THH-MM-SS")
suite_df = lower_fns(suite_fns[1:100]; write_fn="test_suite_$(now_fmtd).csv", verbose=true)
# suite_df = lower_fns_threaded(suite_fns; write_folder="logs/suite/", write_fn="test_suite_$(now_fmtd).csv", verbose=true)
@show suite_df
@info nrow(filter(retcode => x-> x==5)) "good ones"

# @btime lower_fns($suite_fns[1:50]; write=false) # 176.973 s (253344211 allocations: 17.69 GiB)
# @btime serial_lower_fns($suite_fns[1:50]; write=false)
# @show bad
# @time test_sbml(suite_fns)
"""
dir = "data/sbml-test-suite/semantic/00001/"
"""
function verify_case(dir;verbose=false)
    try 
        fns = readdir(dir;join=true)
        model_fn = filter(endswith("l2v3.xml"), fns)[1]
        settings = setup_settings_txt(filter(endswith("settings.txt"), fns)[1])
        results = CSV.read(filter(endswith("results.csv"), fns)[1], DataFrame)
        sys = ODESystem(SBML.readSBML(model_fn))
        ts = LinRange(settings["start"], settings["duration"], settings["steps"])
        prob = ODEProblem(sys, Pair[], (settings["start"], Float64(settings["duration"])); saveat=ts)
        sol = solve(prob, CVODE_BDF(); abstol=settings["absolute"], reltol=settings["relative"])
        solm = Array(sol)'
        m = Matrix(results[1:end-1, 2:end])
        # res = isapprox(solm, m; atol=1e-2)
        res = isapprox(solm, m; atol=1e-2)
        if !res
            diff = m .- solm
            # @show(diff)
            @info "atol: $(maximum(diff))"
        end
        dir => res
    catch e
        dir => e 
    end
end

function verify_all(;verbose=true)
    ds = filter(isdir, readdir(joinpath(@__DIR__, "../data/sbml-test-suite/semantic/"); join=true))
    res = []
    for dir in ds[1:20]
        ret = verify_case(dir; verbose=verbose)
        verbose && @info ret 
        push!(res, ret)
    end
    @info res 
    res # ideally we `@test all(last.(res))`
end

# @test verify_all()
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
