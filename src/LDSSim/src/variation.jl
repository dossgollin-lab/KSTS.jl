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

# seasonal maps
function selected_window(t, windowdays, years)
    bound = windowdays + 1
    half_window = Int(ceil(windowdays / 2))
    if t < 29
        selected = zeros(Int64, 1, bound * years + (half_window - t))
        selected[1:(t + bound)] = (1:(t + bound))
    else
        selected = zeros(Int64, 1, bound * years)
        selected[1:bound] = ((t - half_window):(t + half_window))
    end

    for y in 1:(years - 1)
        window = ((t - half_window):(t + half_window)) .+ y * 365
        selected[(y * bound):(y * bound + windowdays)] = collect(window)
    end
    if t < 29
        selected[(bound * years):(bound * years + (half_window - t))] =
            ((t - half_window):0) .+ years * 365
    end
    return vec(selected)
end

season = selected_window(10, 30, 40)

mean_map(wind[season, :], lat, lon)
