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
    f = x -> ODESystem(readSBML(x))
    goodbad(f, models)
end

function lower_one(fn, df; verbose=false)
    k = 0
    n_dvs = 0
    n_ps = 0
    time = 0.0
    err = ""
    try
        ml = readSBML(fn)
        k = 1
        sys = ODESystem(ml)
        n_dvs = length(states(sys))
        n_ps = length(parameters(sys))
        k = 2
        prob  = ODEProblem(ml, (0, 1000.0))
        k = 3
        sol = solve(prob, TRBDF2(), dtmax=0.5; force_dtmin=true, unstable_check=unstable_check = (dt,u,p,t) -> any(isnan, u))
        k = 4
        time = @belapsed solve($prob, Rosenbrock23())
        k = 5
    catch e
        verbose && @info fn => e
        err = string(e)
        if length(err) > 1000 # cutoff since I got ArgumentError: row size (9088174) too large 
            err = err[1:1000]
        end
    finally
        push!(df, (fn, k, n_dvs, n_ps, time, err))
        verbose && printstyled("$fn done with a code $k\n"; color=:green)
    end
end

function lower_fns(fns; write_fn=nothing)
    df = DataFrame(file=String[], retcode=Int[], n_dvs=Int[], n_ps=Int[], time = Float64[], error=String[])
    # @sync Threads.@threads 
    for fn in fns 
        lower_one(fn, df)
    end
    write_fn !== nothing && CSV.write("logs/$(write_fn)", df)
    df
end
