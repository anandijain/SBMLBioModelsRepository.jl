function lower_one(fn, df; verbose=false)
    expected_errs = ["SBML files with rules are not supported", "Model contains no reactions."]
    k = 0
    n_dvs = 0
    n_ps = 0
    time = 0.0
    diffeq_retcode = :nothing
    err = ""
    try
        ml = SBML.readSBML(fn, doc -> begin
                set_level_and_version(3, 2)(doc)
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
        sol = solve(prob, TRBDF2(), dtmax=0.5; force_dtmin=false, unstable_check=unstable_check = (dt,u,p,t) -> any(isnan, u))
        diffeq_retcode = sol.retcode
        if diffeq_retcode == :Success
            k = 5
            time = @belapsed solve($prob, Rosenbrock23())
        end
    catch e
        err = string(e)
        if sum([occursin(e, err) for e in expected_errs]) > 0
            err = "Expected error: "*err
        end
        if length(err) > 1000 # cutoff since I got ArgumentError: row size (9088174) too large 
            err = err[1:1000]
        end
    finally
        push!(df, (fn, k, n_dvs, n_ps, time, err, diffeq_retcode))
        verbose && @info("$(basename(fn)) done with a code $k and error msg: $err")
    end
end

function lower_fns(fns; verbose=false, write_fn=nothing)
    df = DataFrame(file=String[], retcode=Int[], n_dvs=Int[], n_ps=Int[], time = Float64[], error=String[], diffeq_retcode=Symbol[])
    for fn in fns 
        lower_one(fn, df; verbose=verbose)
    end
    write_fn !== nothing && CSV.write(joinpath(logdir, write_fn), df)
    df
end
