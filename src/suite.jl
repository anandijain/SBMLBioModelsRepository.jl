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

"""
dir = "data/sbml-test-suite/semantic/00001/"
"""
function verify_case(dir;verbose=false)
    res = false
    atol = 0
    time = 0.0
    err = ""
    try 
        fns = readdir(dir;join=true)
        model_fn = filter(endswith("l2v3.xml"), fns)[1]
        case_no = basename(dirname(model_fn))
        settings = setup_settings_txt(filter(endswith("settings.txt"), fns)[1])
        results = CSV.read(filter(endswith("results.csv"), fns)[1], DataFrame)

        SBMLToolkit.checksupport(fn)
        ml = SBML.readSBML(model_fn, doc -> begin
            set_level_and_version(3, 2)(doc)
            convert_simplify_math(doc)
            end)
        rs = ReactionSystem(ml)
        sys = ODESystem(ml)
        statenames = [string(s.f.name) for s in sys.states]
        
        ts = LinRange(settings["start"], settings["duration"], settings["steps"])
        prob = ODEProblem(sys, Pair[], (settings["start"], Float64(settings["duration"])); saveat=ts)
        sol = solve(prob, CVODE_BDF(); abstol=settings["absolute"], reltol=settings["relative"])
        solm = Array(sol)'
        m = Matrix(results[1:end-1, 2:end])[:, sortperm(sortperm(statenames))]
        res = isapprox(solm, m; atol=1e-2)
        if verbose && !isapprox(solm, m; atol=1e-9, rtol=3e-2)
            open(joinpath(logdir, case_no*".txt"), "w") do file
                write(file, "Reactions:\n")
                write(file, repr(rs.eqs)*"\n")
                write(file, "ODEs:\n")
                write(file, repr(sys.eqs)*"\n")
            end
            plt = plot(solm)
            plt = plot!(m, linestyle=:dot)
            savefig(joinpath(logdir, case_no*".png"))
        end
        diff = m .- solm
        atol = maximum(diff)
        return [dir, res, atol, err]
    catch e
        err = string(e)
        return [dir, res, atol, err]
    end
end

function verify_all(;verbose=true)
    df = DataFrame(dir=String[], retcode=Bool[], atol=Float64[], error=String[])
    ds = filter(isdir, readdir(joinpath(datadir, "sbml-test-suite", "semantic"); join=true))[1:200]
    for dir in ds
        ret = verify_case(dir; verbose=verbose)
        verbose && @info ret 
        push!(df, ret)
    end
    verbose && print(df)
    df
end
