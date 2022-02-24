"takes a json biomd metadata file and converts to DF"
function jsonfn_to_df(fn)
    json = read(fn, String)
    json = JSON3.read(json)
    haskey(json, :models) && !isempty(json.models) ? DataFrame(jsontable(json.models)) : missing
end

function req_files(url)
    io = IOBuffer()
    Downloads.request(url; output = io, headers = ["accept" => "application/json"])
    JSON3.read(String(take!(io)))
end

"more robust, since not all of the biomodels format like `ID_url.xml`"
function download_biomodel(model_id; path = "$(datadir)/biomd2/", verbose = false)
    model_files_url = "https://www.ebi.ac.uk/biomodels/model/files/$(model_id)"
    body = req_files(model_files_url)
    haskey(body, "errorMessage") && error(repr(body))
    fn = replace(body.main[1]["name"], " " => "+")
    download_url = "https://www.ebi.ac.uk/biomodels/model/download/$(model_id)?filename=$(fn)"
    verbose && @info(model_id, fn, download_url)
    filepath = joinpath(path, fn)
    if !isfile(filepath)
        try
            Downloads.download(download_url, filepath; headers = ["accept" => "application/octet-stream"])
        catch e
            verbose && @info "$model_id failed, probably cuz of some percent encoding thing. `curl` might not have this issue. $e"
        end
    end
    (model_id, filepath)
end

# "https://www.ebi.ac.uk/biomodels/search?query=&offset=0&numResults=10"
"curls the json files"
function curl_biomd_metadata(query, meta_dir = "$(datadir)/biomd_ode_meta")
    !isdir(meta_dir) && mkdir(meta_dir)
    offsets = 0:100:2200 # ideally uses a while loop 
    urls = .*("https://www.ebi.ac.uk/biomodels/search?query=", query, "&offset=", string.(offsets), "&numResults=100&format=json")
    @sync for i in 1:length(offsets)
        @async run(`curl $(urls[i]) -o "$(meta_dir)/sbml_$(i).json"`)
    end
    read_biomd_metadf(meta_dir)
end

"returns a dataframe with metadata about the biomodels"
function read_biomd_metadf(meta_dir)
    fns = readdir(meta_dir; join = true)
    dfs = filter(!ismissing, jsonfn_to_df.(fns))
    vcat(dfs...)
end

"this downloads the xmls in serial. 
exists because biomodels starts denying requests with `@async`"
function curl_biomd_xmls(ids, path; verbose = false)
    for id in ids
        download_biomodel(id; path = path, verbose = verbose)
    end
end

"download using `@async`.  @threads is bugged"
function async_curl_biomd_xmls(ids, path; verbose = false)
    @sync for id in ids
        @async download_biomodel(id; path = path, verbose = verbose)
    end
end

"creates a metadata dataframe from queries to the biomodels api and then downloads the actual models"
function biomodels(
    meta_dir = "$(datadir)/biomd_meta",
    biomd_dir = "$(datadir)/biomd/"; # the xml files are put here
    odes_only = false,
    curl_meta = false,
    limit = nothing, # still gets all the metadata, just limits for curling zips
    verbose = true
)

    verbose && @info("in biomodels()")
    mkpath.([meta_dir, biomd_dir])
    query = odes_only ? "*%3A*%20AND%20modellingapproach%3A%22Ordinary%20differential%20equation%20model%22&domain=biomodels" : "sbml"
    df = curl_meta ? curl_biomd_metadata(query, meta_dir) : read_biomd_metadf(meta_dir)
    verbose && display(df)
    curl_meta && CSV.write("$(datadir)/sbml_biomodels.csv", df)
    if limit === nothing
        async_curl_biomd_xmls(df.id, biomd_dir; verbose = verbose)
    else
        async_curl_biomd_xmls(df.id[1:limit], biomd_dir; verbose = verbose)
    end
    df
end

function get_biomd_fns(; biomd_dir = "biomd/")
    readdir(joinpath(datadir, biomd_dir); join = true)
end
