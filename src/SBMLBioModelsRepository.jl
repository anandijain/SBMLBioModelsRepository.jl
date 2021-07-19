"""this is used to download the data from biomd and the sbml-test-suite"""
module SBMLBioModelsRepository

const datadir = joinpath(@__DIR__, "..", "data")
const logdir = joinpath(@__DIR__, "..", "test", "logs")

using CSV, DataFrames, JSON3, JSONTables, Glob
using Base.Threads, Base.Iterators, Downloads

using ModelingToolkit, OrdinaryDiffEq, Sundials
using CSV, DataFrames, BenchmarkTools
using SBML, SBMLToolkit
using Plots

include("lower.jl")
include("biomd.jl")
include("suite.jl")

export jsonfn_to_df, curl_biomd_xmls, curl_biomd_metadata, read_biomd_metadf, biomodels
export sbml_test_suite, get_sbml_suite_fns, setup_settings_txt, verify_case, verify_all, verify_plot
export datadir, logdir
export lower_one, lower_fns

end
