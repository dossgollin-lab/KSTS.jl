import Base.@kwdef

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
    function WindSolarData(;
        wind=zeros(3, 2), solar=zeros(3, 2), lat=zeros(2), lon=zeros(2)
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
function ngrids(W::WindSolarData)
    return length(W.longitude)
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