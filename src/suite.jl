"""
requires git

returns location of all the models (every version), and the

for a particular version just do 

    `filter(x->occursin("l1v2", x), fns)`
"""
function sbml_test_suite(repo_path = joinpath(datadir, "sbml-test-suite"))
    isdir(repo_path) && return nothing
    run(`git clone "https://github.com/anandijain/sbml-test-suite" $(repo_path)`)
end

function get_sbml_suite_fns(repo_path = joinpath(datadir, "sbml-test-suite"); sfx = "l3v2.xml")
    ds = filter(isdir, readdir(joinpath(repo_path, "semantic"); join = true))
    fns = reduce(vcat, glob.("*.xml", ds))
    # fs = map(x -> splitdir(x)[end], fns)
    sfx !== nothing && filter!(endswith(sfx), fns) # latest level and version
    fns
end

function setup_settings_txt(fn)
    ls = readlines(fn)
    spls = split.(ls, ": ")
    filter!(x -> length(x) == 2, spls)
    Dict(map(x -> x[1] => Meta.parse(x[2]), spls))
end

"""
dir = "data/sbml-test-suite/semantic/00001/"
"""
function verify_case(dir; saveplot = false)
    res = false
    atol = 0
    err = ""
    try
        fns = readdir(dir; join = true)
        model_fn = filter(endswith("l3v2.xml"), fns)[1]
        case_no = basename(dirname(model_fn))
        settings = setup_settings_txt(filter(endswith("settings.txt"), fns)[1])
        results = CSV.read(filter(endswith("results.csv"), fns)[1], DataFrame)

        ml = SBML.readSBML(model_fn, doc -> begin
            set_level_and_version(3, 2)(doc)
            convert_simplify_math(doc)
        end)
        rs = ReactionSystem(ml)
        sys = ODESystem(ml)
        sts = states(sys)
        ssys = structural_simplify(sys)

        # ts = LinRange(settings["start"], settings["duration"], settings["steps"] + 1)
        ts = results.time
        prob = ODEProblem(ssys, Pair[], (settings["start"], Float64(settings["duration"])); saveat = ts)
        sol = solve(prob, CVODE_BDF(); abstol = settings["absolute"], reltol = settings["relative"])

        # matching the solution array to dataframe ordering 
        syms = Symbol.(names(results)[2:end])
        iv = first(@variables t)
        symsyms = mapreduce(sym -> @variables($sym(iv)), vcat, syms)
        solm = Array(sol(ts; idxs = symsyms))'

        m = Matrix(results[1:end, 2:end])
        res = isapprox(solm, m; atol = 1e-9, rtol = 3e-2)
        diff = m .- solm
        atol = maximum(diff)
        saveplot && !res && verify_plot(case_no, rs, solm, m)
        return [dir, res, atol, err]
    catch e
        err = string(e)
        return [dir, res, atol, err]
    end
end

function verify_all(ds; verbose = true, saveplot = false)
    df = DataFrame(dir = String[], retcode = Bool[], atol = Float64[], error = String[])
    for dir in ds
        ret = verify_case(dir; saveplot = saveplot)
        verbose && @info ret
        push!(df, ret)
    end
    verbose && print(df)
    df
end

"plots the difference between the suites' reported solution and DiffEq's sol"
function verify_plot(case_no, rs, solm, m)
    sys = convert(ODESystem, rs)
    open(joinpath(logdir, case_no * ".txt"), "w") do file
        write(file, "Reactions:\n")
        write(file, repr(equations(rs)) * "\n")
        write(file, "ODEs:\n")
        write(file, repr(equations(sys)) * "\n")
    end
    plt = plot(solm)
    plt = plot!(m, linestyle = :dot)
    savefig(joinpath(logdir, case_no * ".png"))
end
