import Base.@kwdef
using Dates

"""
This holds the input data that is needed
Shouldn't need much updating

Wind and solar indexed [time, site]
lon, lat indexed [site]
"""
struct WindSolarData
    wind::Matrix{<:Real}
    solar::Matrix{<:Real}
    lat::Vector{<:Real}
    lon::Vector{<:Real}
    doy::Vector{<:Int}
end
function WindSolarData(;
    wind::Matrix{<:Real},
    solar::Matrix{<:Real},
    lat::Vector{<:Real},
    lon::Vector{<:Real},
    t::Vector{<:Int},
)
    @assert size(wind) == size(solar) "wind and solar must be same size"
    @assert size(lat) == size(lon) "longitude and latitude must be same size"
    @assert size(wind)[2] == size(lat)[1] "must be same number of grid cells and lon/lat info"
    @assert size(wind)[1] == size(t)
    return WindSolarData(wind, solar, lat, lon, t)
end
function WindSolarData(;
    wind::Matrix{<:Real},
    solar::Matrix{<:Real},
    lat::Vector{<:Real},
    lon::Vector{<:Real},
    t::Vector{<:Dates.Date},
)
    doy = Dates.dayofyear.(t)
    return WindSolarData(wind, solar, lat, lon, doy)
end

"""
return the number of grid cells in the input data
"""
function ngrids(W::WindSolarData)
    return length(W.lon)
end

"""
This holds the fit
What should it contain?
"""
@kwdef struct KSTSFit
    𝐃::Matrix{<:Real}
    𝐏::Matrix{<:Real}
    lon::Vector{<:Real}
    lat::Vector{<:Real}
    M::Integer
    K::Integer
end
