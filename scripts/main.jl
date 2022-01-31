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
function get_default_inputs(start_date; N=missing)
    grid_locs = CSV.read(datadir("raw", "ERCOT_0_5_deg_lat_lon_index_key.csv"), DataFrame)
    wind = readdlm(datadir("raw", "ERCOT_Wind_Power_Daily.txt"); skipstart=1)[:, 2:end]
    solar = readdlm(datadir("raw", "ERCOT_Solar_Rad_Daily.txt"); skipstart=1)[:, 2:end]
    lon = grid_locs[:, :lon]
    lat = grid_locs[:, :lat]
    DOY = DOY(start_date, wind)
    if ismissing(N)
        N = length(lon)
    end
    return WindSolarData( ;wind=wind[1:N, :], solar=solar[1:N, :], lon=lon, lat=lat, DOY = DOY)
end


N = 250
start_date = "1970-01-01"; # can maybe extrapolate from data
input = get_default_inputs(start_date; N=N)

WindSolarData.DOY

K = 50 # number of nearest neighbors
fname = datadir("processed", "saved_fit_$(N)_$(K).jld2") # where to save / store the fitted model

# this function will try to load the fit -- if it doesn't work, it will run and then save
# it is *not* sophisticated at all so if you change the inputs, set overwrite to `true`.
# TODO: what is windowsize?
my_fit = LDSSim.get_cache_fit(input, K, fname; overwrite=true)

# how to simulate
nsim = 48
global t = 10 # starting time step
t_archive = []
for _ in 1:nsim
    transition_probs = Weights(my_fit.𝐏[t, :])
    t = sample(1:size(my_fit.𝐃)[1], transition_probs)
    push!(t_archive, t)
end
my_fit.𝐃[t_archive, :]

