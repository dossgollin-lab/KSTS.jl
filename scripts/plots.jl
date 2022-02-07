using Plots

input = get_default_inputs()

# plot correlation of wind and solar
n_points = size(input.wind, 2)
corrs = [corspearman(input.solar[:, i], input.wind[:, i]) for i in 1:n_points]
histogram(corrs; xlabel="Spearman Correlation", normalize=true, label="Reanalysis Data")
vline!([0]; linewidth=4, color=:black, label=false)
