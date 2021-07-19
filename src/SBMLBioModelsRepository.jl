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

# "do it for me" functions
export sbml_test_suite, biomodels

export curl_biomd_xmls
export curl_biomd_metadata, biomd_metadata, curl_biomd_zips, biomd_zip_urls, unzip_biomd
export get_sbml_suite_fns, jsonfn_to_df, get_biomd_fns
export setup_settings_txt, verify_case, verify_all
export datadir, logdir
export lower_one, lower_fns

end
