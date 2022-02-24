const expected_errs =
    ["SBML files with rules are not supported",
        "Model contains no reactions.",
        "are not yet implemented.",
        "Please make reaction irreversible or rearrange kineticLaw to the form `term1 - term2`."]

function lower_one(fn; verbose = false)
    k = 0
    n_dvs = 0
    n_ps = 0
    time = 0.0
    diffeq_retcode = :nothing
    expected_err = false
    err = ""
    try
        SBMLToolkit.checksupport(fn)
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
        prob = ODEProblem(sys, Pair[], (0, 1.0))
        k = 4
        sol = solve(prob, TRBDF2(), dtmax = 0.5; force_dtmin = false, unstable_check = unstable_check = (dt, u, p, t) -> any(isnan, u))
        diffeq_retcode = sol.retcode
        if diffeq_retcode == :Success
            k = 5
            time = @belapsed solve($prob, Rosenbrock23())
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
        return (fn, k, n_dvs, n_ps, time, err, expected_err, diffeq_retcode)
    end
end

function lower_fns(fns; verbose = false, write_fn = nothing)
    df = DataFrame(file = String[], retcode = Int[], n_dvs = Int[], n_ps = Int[], time = Float64[], error = String[], expected_error = Bool[], diffeq_retcode = Symbol[])
    for fn in fns
        row = lower_one(fn; verbose = verbose)
        push!(df, row)
    end
    write_fn !== nothing && CSV.write(joinpath(logdir, write_fn), df)
    df
end
