using PlotlyJS, DataFrames, CSV


function mean_map(data, titlemap)
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
        lat=input.lat,
        lon=input.lon,
        marker=marker,
        name="Mean Data",
    )
    layout = Layout(; title = titlemap ,geo=marker, fitbounds="locations")
    return PlotlyJS.plot(trace, layout)
end
mean_map(input.wind, "Mean Production - Wind")
mean_map(input.solar, "Mean Production - Solar")



