using Base: @kwdef
using StatsBase: Weights, sample

@kwdef struct KSTSSim
    wind::Matrix{<:Real}
    solar::Matrix{<:Real}
    lat::Vector{<:Real}
    lon::Vector{<:Real}
end

function simulate(fit::KSTSFit; N, t0)
    t = t0
    t_archive = zeros(Int, N)
    for n in 1:N
        transition_probs = Weights(fit.𝐏[t, :])
        t = sample(1:size(fit.𝐃)[1], transition_probs)
        t_archive[n] = t
    end
    sim_data = fit.𝐃[t_archive, :]
    n_grid = Int(size(sim_data, 2) / 2)
    return KSTSSim(;
        lat=fit.lat,
        lon=fit.lon,
        solar=sim_data[:, 1:n_grid],
        wind=sim_data[:, (n_grid + 1):(2 * n_grid)],
    )
end
