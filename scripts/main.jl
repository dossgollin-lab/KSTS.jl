# load the local package
using Revise # see https://timholy.github.io/Revise.jl/stable/user_reference/
using LDSSim

# load standard packages
using CSV
using DataFrames
using DrWatson
using DelimitedFiles
using StatsBase
using Dates

# here is a function to read in the raw data as a `WindSolarData` object
function get_default_inputs(; N=missing)
    grid_locs = CSV.read(datadir("raw", "ERCOT_0_5_deg_lat_lon_index_key.csv"), DataFrame)
    wind = readdlm(datadir("raw", "ERCOT_Wind_Power_Daily.txt"); skipstart=1)[:, 2:end]
    solar = readdlm(datadir("raw", "ERCOT_Solar_Rad_Daily.txt"); skipstart=1)[:, 2:end]
    lon = grid_locs[:, :lon]
    lat = grid_locs[:, :lat]
    sdate = Dates.Date(1970, 1, 1) # TODO: This is made up
    edate = sdate + Dates.Day(size(wind, 1) - 1)
    t = collect(sdate:Dates.Day(1):edate)
    if ismissing(N)
        N = size(wind, 1)
    end
    return WindSolarData(;
        wind=wind[1:N, :], solar=solar[1:N, :], lon=lon, lat=lat, t=t[1:N]
    )
end

N = 1000
input = get_default_inputs()

K = 20 # number of nearest neighbors
fname = datadir("processed", "saved_fit_$(N)_$(K).jld2") # where to save / store the fitted model

# this function will try to load the fit -- if it doesn't work, it will run and then save
# it is *not* sophisticated at all so if you change the inputs, set overwrite to `true`.
my_fit = LDSSim.get_cache_fit(input, K, fname; overwrite=false)

# simulate from the fitted model -- iterate 48 times for 48 realizations
# TODO: probably a better way to do this
my_sims = [simulate(my_fit; N=14610, t0=10) for i in 1:48]

