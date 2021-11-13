using Revise # see https://timholy.github.io/Revise.jl/stable/user_reference/

# standard packages
using CSV
using DataFrames
using DrWatson
using DelimitedFiles

# the machinery is in a local package
using LDSSim

# here is a function to read in the raw data as a `WindSolarData` object
function get_default_inputs()
    grid_locs = CSV.read(datadir("raw", "ERCOT_0_5_deg_lat_lon_index_key.csv"), DataFrame)
    wind = readdlm(datadir("raw", "ERCOT_Wind_Power_Daily.txt"); skipstart=1)[:, 2:end]
    solar = readdlm(datadir("raw", "ERCOT_Solar_Rad_Daily.txt"); skipstart=1)[:, 2:end]
    lon = grid_locs[:, :lon]
    lat = grid_locs[:, :lat]
    return WindSolarData(; wind=wind, solar=solar, lon=lon, lat=lat)
end

# get the raw data as a `WindSolarData` format
input = get_default_inputs()

𝐗 = hcat(input.wind, input.solar)

# Fit the model (PLACEHOLDER VALUES!)
fit = fit_ksts(input; n_neighbors=10, n_lags=3, max_window=3, max_embedding=3)

# simulate steps from the model (PLACEHOLDER VALUES)
seqs = [simulate_ksts(fit) for _ in 1:10]

# add visualizations / calibration checks later
