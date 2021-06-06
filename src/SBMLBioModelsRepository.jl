"""this is used to download the data from biomd and the sbml-test-suite"""
module SBMLBioModelsRepository

const datadir = joinpath(@__DIR__, "../data")

# function __init__()
# using Pkg
# Pkg.add(url="https://github.com/paulflang/SBML.jl/", rev="pl/mk-species-units")
# end

using CSV, DataFrames, JSON3, JSONTables, Glob
using Base.Threads, Base.Iterators, Downloads

# using SBML
using ModelingToolkit, OrdinaryDiffEq, CSV, DataFrames, BenchmarkTools

# include("lower.jl")
include("biomd.jl")
include("suite.jl")

# "do it for me" functions
export sbml_test_suite, biomodels

export curl_biomd_xmls
export curl_biomd_metadata, biomd_metadata, curl_biomd_zips, biomd_zip_urls, unzip_biomd
export get_sbml_suite_fns, jsonfn_to_df, get_biomd_fns
export datadir
# export goodbad, test_suite, lower_one, lower_fns

end
