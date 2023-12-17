using Plots
using PlotlyJS
using Statistics
using StatsPlots

input = get_default_inputs()

# probability density function- wind
agg_daily_wind = sum(input.wind; dims=2)
Plots.histogram(
    agg_daily_wind;
    nbins=100,
    title="Daily generation potential of reanalysis data - Wind",
    legend=false,
)

allwind = hcat([sum(my_sims[i].wind; dims=2) for i in 1:48]...)
Plots.histogram(
    vec(allwind);
    nbins=100,
    title="Daily generation potential of simulated data - Wind",
    legend=false,
)

# probability density function - solar
agg_daily_solar = sum(input.solar; dims=2)
Plots.histogram(
    agg_daily_solar;
    nbins=100,
    title="Daily generation potential of reanalysis data - Solar",
    legend=false,
)

allsolar = hcat([sum(my_sims[i].solar; dims=2) for i in 1:48]...)
Plots.histogram(
    vec(allsolar);
    nbins=100,
    title="Daily generation potential of simulated data - Solar",
    legend=false,
)

# Mean, sd, min, max
x = rand(1:216, 15)
means = vcat([mean(my_sims[i].wind[:, x]; dims=1) for i in 1:48]...)
stds = vcat([std(my_sims[i].wind[:, x]; dims=1) for i in 1:48]...)
mins = vcat([minimum(my_sims[i].wind[:, x]; dims=1) for i in 1:48]...)
maxs = vcat([maximum(my_sims[i].wind[:, x]; dims=1) for i in 1:48]...)
p1 = boxplot(means; title="Mean - Wind")
p2 = boxplot(stds; title="Stan Dev - Wind")
p3 = boxplot(mins; title="Maximum - Wind")
p4 = boxplot(maxs; title="Minimum - Wind")
Plots.plot(p1, p2, p3, p4; layout=(2, 2), legend=false)

x = rand(1:216, 15)
means = vcat([mean(my_sims[i].solar[:, x]; dims=1) for i in 1:48]...)
stds = vcat([std(my_sims[i].solar[:, x]; dims=1) for i in 1:48]...)
mins = vcat([minimum(my_sims[i].solar[:, x]; dims=1) for i in 1:48]...)
maxs = vcat([maximum(my_sims[i].solar[:, x]; dims=1) for i in 1:48]...)
p1 = boxplot(means; title="Mean - Solar")
p2 = boxplot(stds; title="Stan Dev - Solar")
p3 = boxplot(mins; title="Minimum - Solar")
p4 = boxplot(maxs; title="Maximum - Solar")
Plots.plot(p1, p2, p3, p4; layout=(2, 2), legend=false)

# Cross correlation with fields
corr = [cor(my_sims[i].wind[:, j], my_sims[i].solar[:, j]) for j in 1:216 for i in 1:48]
corrsKSTS = median(reshape(corr, 48, :); dims=1)
corrsinput = [cor(input.solar[:, i], input.wind[:, i]) for i in 1:216]
difference = vec(corrsKSTS .- corrsinput)

corr1 = [cor(my_sims[1].wind[:, i], my_sims[1].solar[:, i]) for i in 1:216]
correlationmap(corr1, "K")

function correlationmap(corrs, titlemap)
    marker = attr(;
        scope="usa",
        color=corrsinput,
        cmin=minimum(corrs),
        cmax=maximum(corrs),
        colorscale="Purples",
        colorbar=attr(; title="Corr"),
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
    layout = Layout(; title=titlemap, geo=marker, fitbounds="locations")
    return PlotlyJS.plot(trace, layout)
end

p1 = correlationmap(corrsinput, "A")
p2 = correlationmap(vec(corrsKSTS), "B")
p3 = correlationmap(difference, "C")
# why is the difference not zero?

# cross- correlation matrix for 40 sites
function cross_correlation(corrs, inputdata, titlemap)
    corrsKSTS = dropdims(median(reshape(corrs, 40, 40, :); dims=3); dims=3)
    corrsinput = cor(inputdata[:, x])
    return Plots.scatter(corrsKSTS, corrsinput; legend=false, title=titlemap)
end
x = rand(1:216, 40)
corrsolar = hcat([cor(my_sims[i].solar[:, x]) for i in 1:48]...)
corrwind = hcat([cor(my_sims[i].wind[:, x]) for i in 1:48]...)
cross_correlation(corrsolar, input.solar, "Cross Site Correlation - Solar")
cross_correlation(corrwind, input.wind, "Cross Site Correlation - Wind")

# Auto-correlation factors
function autocorrelation_plots(maxlags)
    acfplots = []
    for lag in 1:maxlags
        lag1input = autocor(input.solar, [lag])
        lag1 = vcat([autocor(my_sims[i].solar, [lag]) for i in 1:48]...)
        lag1sim = median(lag1; dims=1)
        p1 = Plots.scatter(lag1input, lag1sim; title="lag $lag", legend=false)
        push!(acfplots, p1)
        lag = lag + 1
    end
    return Plots.plot(acfplots...)
end

autocorrelation_plots(8)
