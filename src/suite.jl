const algo = Dict("00862" => Rodas4,
                  "00863" => Rodas4,
                  "00864" => Rodas4,
                  "00882" => Rodas4)

"""
requires git

returns location of all the models (every version), and the

for a particular version just do 

    `filter(x->occursin("l1v2", x), fns)`
"""
function sbml_test_suite(repo_path=joinpath(datadir, "sbml-test-suite"))
    isdir(repo_path) && return nothing
    run(`git clone "https://github.com/anandijain/sbml-test-suite" $(repo_path)`)
end

function get_sbml_suite_fns(repo_path=joinpath(datadir, "sbml-test-suite"); sfx="l3v2.xml")
    ds = filter(isdir, readdir(joinpath(repo_path, "semantic"); join=true))
    fns = reduce(vcat, glob.("*.xml", ds))
    # fs = map(x -> splitdir(x)[end], fns)
    sfx !==nothing && filter!(endswith(sfx), fns) # latest level and version
    fns
end

function setup_settings_txt(fn)
    ls = readlines(fn)
    spls = split.(ls, ": ")
    filter!(x->length(x) == 2, spls)
    Dict(map(x -> x[1] => Meta.parse(x[2]), spls))
end

function get_casedir(case_no::String)
    joinpath(datadir, "sbml-test-suite", "semantic", case_no)
end

function to_concentrations(sol, rn, ia)
    volumes = [1.]
    sol_df = DataFrame(sol)
    for sn[1:end-3] in names(sol_df)[2:end]
        if sn in rn  # haskey(ml.species, sn[1:end-3])  # PL I think lets do if sn in names(results)
            spec = ml.species[sn[1:end-3]]
            comp = ml.compartments[spec.compartment]
            ic = spec.initial_concentration
            isnothing(ic) || haskey(ia, sn[1:end-3]) ? push!(volumes, 1.) : push!(volumes, comp.size)
        end
    end
    sol_df./Array(volumes)'
end

"""
dir = "data/sbml-test-suite/semantic/00001/"
"""
function verify_case(dir; verbose=false,plot_dir=nothing,check_sim=true)
    k = 0
    n_dvs = 0
    n_ps = 0
    time = 0.0
    diffeq_retcode = :nothing
    expected_err = false
    
    res = false
    atol = 0
    err = ""
    try
        fns = readdir(dir;join=true)
        model_fn = filter(endswith("l3v2.xml"), fns)[1]
        case_no = basename(dirname(model_fn))
        settings = setup_settings_txt(filter(endswith("settings.txt"), fns)[1])
        results = CSV.read(filter(endswith("results.csv"), fns)[1], DataFrame)
        SBMLToolkit.checksupport(model_fn)
        occursin("spatial_dimensions=0", read(model_fn, String)) && throw(error("spatial_dimensions=0"))
        ml = SBML.readSBML(model_fn, doc -> begin
            set_level_and_version(3, 2)(doc)
            convert_simplify_math(doc)
        end)
        ia = readSBML(model_fn, doc -> begin
                set_level_and_version(3, 2)(doc)
            end)
        ia = ia.initial_assignments
        k = 1

        rs = ReactionSystem(ml)
        k = 2

        sys = convert(ODESystem, rs; include_zero_odes = true, combinatoric_ratelaws=false)  # @anand: This should work now thanks to defauls. Saves a bit of time.
        if length(ml.events) > 0
            sys = ODESystem(ml)
        end
        n_dvs = length(states(sys))
        n_ps = length(parameters(sys))
        k = 3
        
        ssys = structural_simplify(sys)
        k = 4
        
        ts = results[:, 1]  # LinRange(settings["start"], settings["duration"], settings["steps"]+1)
        prob = ODEProblem(ssys, Pair[], (settings["start"], Float64(settings["duration"])); saveat=ts)  #, check_length=false)
        k = 5
    
        if check_sim
            case_no in keys(algo) ? algo[case_no] : CVODE_BDF
            sol = solve(prob, Rodas4(); abstol=settings["absolute"], reltol=settings["relative"])
            diffeq_retcode = sol.retcode
            if diffeq_retcode == :Success
                k = 6
                time = @belapsed solve($prob, Rosenbrock23())  # @Anand: do we need this, does this cost a lot of time?
            end
            sol_df = to_concentrations(sol, names(results), ia)
            idx = [sol.t[i] in results[:, 1] ? true : false for i in 1:length(sol.t)]
            sol_df = sol_df[idx, :]
            CSV.write(joinpath(plot_dir, "SBMLTk_"*case_no*".csv"), sol_df)
            cols = names(sol_df)[2:end]
            cols = [c for c in cols if c[1:end-3] in names(results)]
            res_df = results[:, [c[1:end-3] for c in cols]]
            solm = Matrix(sol_df[:, cols])
            resm = Matrix(res_df)
            res = isapprox(solm, resm; atol=1e-9, rtol=3e-2)
            atol = maximum(solm .- resm)
            !isnothing(plot_dir) && !res && verify_plot(case_no, rs, solm, resm, plot_dir, ts)
        end
    catch e
        err = string(e)
        if sum([occursin(e, err) for e in expected_errs]) > 0
            expected_err = true
        end
        if length(err) > 1000 # cutoff since I got ArgumentError: row size (9088174) too large 
            err = err[1:1000]
        end
    finally
        verbose && @info("$(basename(fn)) done with a code $k and error msg: $err")
        return (dir, expected_err, res, atol, err, k, n_dvs, n_ps, time, diffeq_retcode)
    end
end

function verify_all(ds;verbose=true, plot_dir=nothing)
    df = DataFrame(dir=String[], expected_err=Bool[], res=Bool[], atol=Float64[],
                   error=String[], k=Int64[], n_dvs=Int64[], n_ps=Int64[],
                   time=Float64[], diffeq_retcode=Symbol[])
    for dir in ds
        ret = verify_case(dir; plot_dir=plot_dir)
        verbose && @info ret 
        push!(df, ret)
    end
    verbose && print(df)
    df
end

"plots the difference between the suites' reported solution and DiffEq's sol"
function verify_plot(case_no, rs, solm, resm, plot_dir, ts)
    sys = convert(ODESystem, rs; combinatoric_ratelaws=false)
    open(joinpath(plot_dir, case_no*".txt"), "w") do file
        write(file, "Reactions:\n")
        write(file, repr(equations(rs))*"\n")
        write(file, "ODEs:\n")
        write(file, repr(equations(sys))*"\n")
    end
    plt = plot(ts, solm)
    plt = plot!(ts, resm, linestyle=:dot)
    savefig(joinpath(plot_dir, case_no*".png"))
end
