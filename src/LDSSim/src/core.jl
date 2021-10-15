import Base.@kwdef

const F = Float64 # float data
const R = Int64 # integer data

"""
This holds the input data that is needed
Shouldn't need much updating

Wind and solar indexed [time, site]
lon, lat indexed [site]
"""
struct WindSolarData
    wind::Matrix{F}
    solar::Matrix{F}
    lat::Vector{F}
    lon::Vector{F}
    function WindSolarData(;
        wind = zeros(3, 2),
        solar = zeros(3, 2),
        lat = zeros(2),
        lon = zeros(2),
    )
        @assert size(wind) == size(solar) "wind and solar must be same size"
        @assert size(lat) == size(lon) "longitude and latitude must be same size"
        @assert size(wind)[2] == size(lat)[1] "must be same number of grid cells and lon/lat info"
        return new(wind, solar, lat, lon)
    end
end

"""
return the number of grid cells in the input data
"""
function ngrids(wsd::WindSolarData)::R
    return length(wsd.longitude)
end

"""
This holds the fit
What should it contain?
"""
@kwdef struct KSTSFit
    x::F = 0.0   # placeholder
end

"""
This function fits the 

    kwargs:
    n_neighbors: ___
    n_lags: ___
    mws: moving window size
    maxem: maximum embedding
    (what else is strictly required?)
"""
function fit_ksts(
    wsd::WindSolarData;
    n_neighbors::R,
    n_lags::R,
    max_window::R,
    max_embedding::R,
)::KSTSFit
    return KSTSFit() # placeholder
end


"""
This holds a sequences that you would create once you have your fitted object.
What should it contain?
"""
@kwdef struct KSTSSequence
    x::F = 0.0 # placeholder
end

"""
Use your fitted model to create a synthetic time series

We will have some kwargs
"""
function simulate_ksts(fit::KSTSFit)::KSTSSequence
    return KSTSSequence() # placeholder
end
