using Plots
using PlotlyJS

input = get_default_inputs()

# plot correlation of wind and solar

corrs_input = [corspearman(input.solar[:, i], input.wind[:, i]) for i in 1:n_points]
histogram(corrs; xlabel="Spearman Correlation", normalize=true, label="Reanalysis Data")
vline!([0]; linewidth=4, color=:black, label=false)


function corrmap(datasolar, datawind, titlemap)
    n_points = size(datawind, 2)
    corrs_input = [corspearman(datasolar[:, i], datawind[:, i]) for i in 1:n_points]
    marker = attr(;
        scope="usa",
        color=corrs,
        cmin=minimum(corrs),
        cmax=maximum(corrs),
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
        name="Corr",
    )
    layout = Layout(; title = titlemap, geo=marker, fitbounds="locations")
    return PlotlyJS.plot(trace, layout)
end

corrmap(input.solar, input.wind, "Wind and Solar Correlation - Reanalysis Data")


# probability density function- wind
agg_daily_wind = sum(input.wind, dims = 2)
histogram(agg_daily_wind, title = "Daily generation potential of reanalysis data - Wind")
    
# 48 realizations of wind
allwind = hcat([sum(my_sims[i].wind, dims=2) for i in 1:48]...)
histogram(vec(allwind))

# turn into matrix
#w = reduce(hcat, allwind)
C = vcat(allwind...)
#C = reshape(w, 14610, 216, :)
#meanKSTSwind = mean(C, dims = 3)
#agg_daily_KSTSwind = sum(C, dims=2) |> vec
histogram(sum(C, dims=2),  title = "Daily generation potential of simulated data - Wind")



# probability density function - solar
agg_daily_solar = sum(input.solar, dims = 2)
histogram(agg_daily_solar, title = "Daily generation potential of reanalysis data - Solar")
allsolar = [my_sims[i].solar for i in 1:48]
    # turn into matrix
w = reduce(hcat, allsolar)
C = reshape(w, 14610, 216, :)
meanKSTSsolar = mean(C, dims = 3)
agg_daily_KSTSsolar = reduce(vcat, sum(meanKSTSsolar, dims = 2))
histogram(agg_daily_KSTSsolar, title =  "Daily generation potential of simulated data - Solar")

corrmap(agg_daily_KSTSsolar, agg_daily_KSTSwind, "Wind and Solar Correlation - KSTS Simulation")