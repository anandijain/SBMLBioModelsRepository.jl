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
