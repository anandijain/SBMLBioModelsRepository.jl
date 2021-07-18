"takes a json biomd metadata file and converts to DF"
function jsonfn_to_df(fn)
    json = read(fn, String);
    json = JSON3.read(json)
    haskey(json, :models) ? DataFrame(jsontable(json.models)) : missing
end

# "https://www.ebi.ac.uk/biomodels/search?query=&offset=0&numResults=10"
"curls the json files"
function curl_biomd_metadata(query, meta_dir="$(datadir)/biomd_ode_meta")
    offsets = 0:100:2200 # ideally uses a while loop 
    urls = .*("https://www.ebi.ac.uk/biomodels/search?query=", query,"&offset=", string.(offsets), "&numResults=100&format=json")
    @sync for i in 1:length(offsets)
        @async run(`curl $(urls[i]) -o "$(meta_dir)/sbml_$(i).json"`)
    end
end

"returns a dataframe with metadata about the biomodels"
function read_biomd_metadf(meta_dir)
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
        run(`curl $(url) -o "$(fn)"`)
    end
end

"creates a metadata dataframe from queries to the biomodels api and then downloads the actual models"
function biomodels(
    meta_dir="$(datadir)/biomd_meta",
    biomd_dir="$(datadir)/biomd/"; # the xml files are put here
    odes_only=false,
    curl_meta=false,
    limit=nothing, # still gets all the metadata, just limits for curling zips
    verbose=true
    )

    verbose && @info("in biomodels()")    
    mkpath.([meta_dir, biomd_dir])
    query = odes_only ? "*%3A*%20AND%20modellingapproach%3A%22Ordinary%20differential%20equation%20model%22&domain=biomodels" : "sbml"
    df = curl_meta ? curl_biomd_metadata(query, meta_dir) : read_biomd_metadf(meta_dir)
    verbose && display(df)
    CSV.write("$(datadir)/sbml_biomodels.csv", df)
    limit === nothing ? curl_biomd_xmls(df.id; verbose=verbose) : curl_biomd_xmls(df.id[1:limit]; verbose=verbose)
    df 
end

function get_biomd_fns()
    readdir(joinpath(datadir, "biomd/"); join=true)
end