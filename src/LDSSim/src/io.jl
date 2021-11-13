using JLD2
using DrWatson

function get_cache_fit(W::WindSolarData, K::Integer, fname; overwrite::Bool = false)
    try
        @assert !overwrite # if overwrite is true, this will force us to load
        @assert isfile(fname)
        fit_model = load(fname, "fit_model")
        return fit_model
    catch err
        fit_model = fit(W, K)
        wsave(fname, Dict("fit_model" => fit_model))
        return fit_model
    end
end

