function goodbad(f, xs)
    good = []
    bad = []
    for x in xs
        try
            push!(good, x => f(x))
        catch e
            push!(bad, x => e)
        end
    end
    (good, bad)
end

"""
naive tester to separate the ones that lower and those that dont
"""
function test_suite()
    models = semantic()
    f = x -> ODESystem(readSBML(x, doc -> begin
                set_level_and_version(3, 1)(doc)
                convert_simplify_math(doc)
            end))
    goodbad(f, models)
end

function lower_one(fn, df; verbose=false)
    expected_errs = ["SBML files with rules are not supported", "Model contains no reactions."]
    k = 0
    n_dvs = 0
    n_ps = 0
    time = 0.0
    err = ""
    try
        ml = SBML.readSBML(fn, doc -> begin
                set_level_and_version(3, 1)(doc)
                convert_simplify_math(doc)
                end)
        k = 1
        rs = ReactionSystem(ml)
        k = 2
        sys = ODESystem(ml)
        n_dvs = length(states(sys))
        n_ps = length(parameters(sys))
        k = 3
        prob  = ODEProblem(sys, Pair[], (0, 1.))
        k = 4
        sol = solve(prob, TRBDF2(), dtmax=0.5; force_dtmin=true, unstable_check=unstable_check = (dt,u,p,t) -> any(isnan, u))
        time = @belapsed solve($prob, Rosenbrock23())
        k = 5
    catch e
        err = string(e)
        if sum([occursin(e, err) for e in expected_errs]) > 0
            err = "Expected error: "*err
        end
        if length(err) > 1000 # cutoff since I got ArgumentError: row size (9088174) too large 
            err = err[1:1000]
        end
    finally
        push!(df, (fn, k, n_dvs, n_ps, time, err))
        verbose && @info("$(basename(fn)) done with a code $k and error msg: $err")
    end
end

function lower_fns(fns; verbose=false, write_fn=nothing)
    df = DataFrame(file=String[], retcode=Int[], n_dvs=Int[], n_ps=Int[], time = Float64[], error=String[])
    # @sync Threads.@threads
    for fn in fns 
        lower_one(fn, df; verbose=verbose)
        if endswith(dirname(fn), "00")  # Write intermediate output
            write_fn !== nothing && CSV.write(joinpath(logdir, write_fn), df)
        end 
    end
    write_fn !== nothing && CSV.write(joinpath(logdir, write_fn), df)
    df
end

# function lower_one_threaded(fn, write_folder; verbose=false)
#     df = DataFrame(file=String[], retcode=Int[], n_dvs=Int[], n_ps=Int[], time = Float64[], error=String[])
#     expected_errs = ["SBML files with rules are not supported", 
#                     "Cannot separate bidirectional kineticLaw",
#                     "Model contains no reactions."]
#     k = 0
#     n_dvs = 0
#     n_ps = 0
#     time = 0.0
#     err = ""
#     try
#         ml = readSBML(fn;conversion_options=CONVERSION_OPTIONS)
#         k = 1
#         rs = SBML.ReactionSystem(ml)
#         k = 2
#         sys = SBML.ODESystem(ml)
#         n_dvs = length(states(sys))
#         n_ps = length(parameters(sys))
#         k = 3
#         prob  = SBML.ODEProblem(ml, (0, 1.))
#         k = 4
#         sol = solve(prob, TRBDF2(), dtmax=0.5; force_dtmin=true, unstable_check=unstable_check = (dt,u,p,t) -> any(isnan, u))
#         time = @belapsed solve($prob, Rosenbrock23())
#         k = 5
#     catch e
#         err = string(e)
#         if sum([occursin(e, err) for e in expected_errs]) > 0
#             err = "Expected error: "*err
#         end
#         if length(err) > 1000 # cutoff since I got ArgumentError: row size (9088174) too large 
#             err = err[1:1000]
#         end
#     finally
#         push!(df, (fn, k, n_dvs, n_ps, time, err))
#         writefn = splitext(basename(fn))[1] * ".csv"
#         outfn = joinpath(write_folder, writefn)
#         verbose && @info("$(basename(fn)) done with a code $k and error msg: $err")
#         CSV.write(outfn, df)
#     end
# end

# """
# this one writes each row to a unique file based on splitext(fn)[1]
# """
# function lower_fns_threaded(fns; verbose=false, write_folder=nothing, write_fn=nothing)
#     mkpath(write_folder)
#     @sync Threads.@threads for fn in fns
#         lower_one_threaded(fn, write_folder; verbose=verbose)
#     end
#     df = reduce(vcat, CSV.read.(readdir(write_folder; join=true), DataFrame))
#     rm(write_folder; recursive=true)
#     write_fn !== nothing && CSV.write(joinpath("logs", write_fn), df)
#     df
# end
