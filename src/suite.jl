"""
requires git

returns location of all the models (every version), and the

for a particular version just do 

    `filter(x->occursin("l1v2", x), fns)`
"""
function sbml_test_suite(repo_path="$(datadir)/sbml-test-suite/")
    isdir(repo_path) && return nothing
    run(`git clone "https://github.com/anandijain/sbml-test-suite" $(repo_path)`)
end

function get_sbml_suite_fns(repo_path="$(datadir)/sbml-test-suite/"; sfx="l3v2.xml")
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

function verify_case(dir)
    fns = readdir(dir;join=true)
    model_fn = filter(endswith("l2v3.xml"), fns)[1]
    settings = setup_settings_txt(filter(endswith("settings.txt"), fns)[1])
    results = CSV.read(filter(endswith("results.csv"), fns)[1], DataFrame)
    sys = ODESystem(readSBML(model_fn))
    ts = LinRange(settings["start"], settings["duration"], settings["steps"])
    prob = ODEProblem(sys, Pair[], (settings["start"], Float64(settings["duration"])); saveat=ts)
    sol = solve(prob, Tsit5())
    solm = Array(sol)'
    m = Matrix(results[1:end-1, 2:end])
    isapprox(solm, m; atol=1e-5)
end

function verify_all()
    ds = filter(isdir, readdir(joinpath(@__DIR__, "../data/sbml-test-suite/semantic/"); join=true))
    verify_case.(ds[1:20]) # pmap or sth 
end
