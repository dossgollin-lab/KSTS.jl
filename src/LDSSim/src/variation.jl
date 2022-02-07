using PlotlyJS, DataFrames, CSV

wind = readdlm(datadir("raw", "ERCOT_Wind_Power_Daily.txt"); skipstart=1)[:, 2:end]
solar = readdlm(datadir("raw", "ERCOT_Solar_Rad_Daily.txt"); skipstart=1)[:, 2:end]
grid_locs = CSV.read(datadir("raw", "ERCOT_0_5_deg_lat_lon_index_key.csv"), DataFrame)
lon = grid_locs[:, :lon]
lat = grid_locs[:, :lat]

function mean_map(data, lat, lon)
    means = vec(mean(data; dims=1))
    marker = attr(;
        scope="usa",
        color=means,
        cmin=minimum(means),
        cmax=maximum(means),
        colorscale="Purples",
        colorbar=attr(; title="Mean"),
        line_color="black",
    )
    trace = scattergeo(;
        mode="markers",
        locationmode=["USA-states"],
        lat=lat,
        lon=lon,
        marker=marker,
        name="Mean Data",
    )
    layout = Layout(; geo=marker, fitbounds="locations")
    return plot(trace, layout)
end
mean_map(wind, lat, lon)
mean_map(solar, lat, lon)


mean_map(sim_data[:,1:216], lat, lon)
# seasonal maps


