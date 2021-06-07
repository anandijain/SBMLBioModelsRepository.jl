"takes a json biomd metadata file and converts to DF"
function jsonfn_to_df(fn)
    json = read(fn, String);
    json = JSON3.read(json)
    haskey(json, :models) ? DataFrame(jsontable(json.models)) : missing
end

"curls the json files of all the "
function curl_biomd_metadata(meta_dir="$(datadir)/biomd_ode_meta")
    !ispath(meta_dir) && mkpath(meta_dir)
    offsets = 0:100:2200
    # "https://www.ebi.ac.uk/biomodels/search?query=&offset=0&numResults=10"
    sbml_query = "sbml"
    sbml_ode_query = "*%3A*%20AND%20modellingapproach%3A%22Ordinary%20differential%20equation%20model%22&domain=biomodels"
    urls = .*("https://www.ebi.ac.uk/biomodels/search?query=", sbml_ode_query,"&offset=", string.(offsets), "&numResults=100&format=json")
    # @sync for i in 1:length(urls) 
    @sync for i in 1:10 
        # Downloads.download(urls[i], "$(meta_dir)/sbml_$(i).json")
        @async run(`curl $(urls[i]) -o "$(meta_dir)/sbml_$(i).json"`)
    end
end

function biomd_metadata(meta_dir="$(datadir)/biomd_meta"; curl_meta=false)
    curl_meta && curl_biomd_metadata(meta_dir)
    fns = readdir(meta_dir; join=true)
    dfs = filter(!ismissing, jsonfn_to_df.(fns))
    vcat(dfs...)
end

"this downloads the xmls directly, without needing zip "
function curl_biomd_xmls(ids; verbose=false)
    base = "https://www.ebi.ac.uk/biomodels/model/download/"
    @sync Threads.@threads for id in ids
        verbose && @info("downloading $id")
        url = "$(base)$(id)?filename=$(id)_url.xml"
        fn = "$(datadir)/biomd/$(id).xml"
        # Downloads.download(url, fn)
        run(`curl $(url) -o "$(fn)"`)
    end
end

function biomodels(
    meta_dir="$(datadir)/biomd_meta",
    # zips_dir="$(datadir)/biomd_zips/",
    biomd_dir="$(datadir)/biomd/"; # the xml files are put here
    curl_meta=false,
    limit=nothing, # still gets all the metadata, just limits for curling zips
    verbose=true
    )
    verbose && @info("in biomodels()")

    mkpath.([meta_dir,
        # zips_dir,
        biomd_dir])
        
    df = biomd_metadata(meta_dir; curl_meta=curl_meta)
    verbose && display(df)
    CSV.write("$(datadir)/sbml_biomodels.csv", df)
    limit === nothing ? curl_biomd_xmls(df.id; verbose=verbose) : curl_biomd_xmls(df.id[1:limit]; verbose=verbose)
    df 
end

###################################################
# I think below is all garbage 
"uses the BioModels IDs and the download REST API"
function biomd_zip_urls(ids)
    base = "https://www.ebi.ac.uk/biomodels/search/download?models="
    N = 100 # api limits 100 at a time
    chunks = Iterators.partition(ids, N)
    qs = join.(chunks, ",") 
    base .* qs  
end

"""
takes the metadata dataframe from `biomd_metadata()`.

should probably do this async
"""
function curl_biomd_zips(urls, zips_dir="$(datadir)/biomd_zips/")
    for i in 1:length(urls) # @threads seems to not work
        run(`curl -X GET "$(urls[i])" -H "accept: application/zip" -o $(zips_dir)$i.zip`)
    end 
    return urls
end

"needs unzip in shell path"
function unzip_biomd(zips_dir, unzip_dir)
    mkpath(unzip_dir)
    zips = readdir(zips_dir; join=true)
    for fn in zips
        run(`unzip $fn -d $(unzip_dir)`) 
    end
    unzip_dir
end


# "to delete i guess"
# function grab_extract_biomd_zips()
#     urls = limit === nothing ? biomd_zip_urls(df.id) : biomd_zip_urls(df.id[1:limit])
#     curl_biomd_zips(urls, zips_dir)
#     unzip_biomd(zips_dir, unzip_dir)
# end

function ab()
    ids = df.id
    ms = []
    @sync for id in ids 
        @async try 
            m = readSBML("data/biomd/$id.xml")
            push!(ms, id => m)
        catch e
            @info e
        end
    end
    @show length(ms)
    df[first.(ms) .== df.id, :]
    filter(x -> x.id ∈ good, df)
end

function get_biomd_fns(;ode=true)
    if ode
        biomd_odes = CSV.read("../data/SBML_ODEs_biomd.csv", DataFrame) # fix for CI
        ids = biomd_odes.id
        biomd_fns = .*("../data/biomd/", ids, ".xml")
        size = 0
        sizemap = map(fn->fn=>stat(fn).size, biomd_fns) # ~200 MB
        sort!(sizemap, by=x->last.(x), rev=true)
        first.(sizemap)
    else
        biomd_dir = joinpath(datadir, "biomd/")
        readdir(biomd_dir; join=true)
    end
end