# set this up to use the local package
using Revise
using LDSSim

# import other packages
using Distributions
using DocStringExtensions
using DrWatson
using ProgressBars
using Random
using StatsBase

# A WORD ON NOTATION
# constants are capital; N = 10, M = 3, etc
# indices are lowercase: [_ for n in 1:N]
# matrices are uppercase capital: 𝐗, 𝐃, etc (type `\bfX` or `\bfD`)

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

"""
Normalize a vector of weights/probabilities so that they sum to one

$(SIGNATURES)
"""
function normalize(w::Vector{<:Real})
    return w ./ sum(w)
end

"""
Create a synthetic data set for analysis

$(SIGNATURES)

where 
`N` is the number of time steps to create,
`P` is the number of sites, 
and data is drawn from  the univariate distribution `𝒟` (default is unit Normal).
"""
function make_synthetic_X(
    N::Integer, P::Integer, 𝒟::T; seed=1234
) where {T<:UnivariateDistribution}
    Random.seed!(seed)
    X = float.(rand(𝒟, N, P))
    return X
end
function make_synthetic_X(N::Integer, P::Integer)
    𝒟 = Normal()
    return make_synthetic_X(N, P, 𝒟)
end

"""
Define the state space D with multiple time embeddings

$(SIGNATURES)

where `X` is the observed data indexed [time, field]
and `M` is the maximum lag to use.

Returns the lagged embedding space `D` indexed [time, field].
This is a pre-processing step that only needs to be run once on the data set.
"""
function define_lagged_state_space(𝐗::Matrix{<:Real}, M::Integer)
    N, P = size(𝐗) # by definition!
    𝐃 = zeros(N - M, P)
    for p in 1:P
        for n in (M + 1):N
            𝐃[n - M, p] = 𝐗[n - 1, p]
        end
    end
    return 𝐃
end

"""
Compute the indices of the `K` nearest neighbors, separately for each location, from a given time step

$(SIGNATURES)

where `𝐃` is the state space,
`tᵢ` is the current time index, and
`K` is the number of nearest neighbors to use

Returns τ, of dimension (P, K), where τ[p, k] gives the index of the kth closest observation to that
at time tᵢ, at site p.
"""
function compute_timestep_neighbors(𝐃::Matrix{<:Real}, tᵢ::Integer, K::Integer)
    ND, P = size(𝐃) # recall that D has (N-M) rows
    τ = zeros(Integer, P, K)
    for p in 1:P
        r = (𝐃[tᵢ, p] .- 𝐃[:, p]) .^ 2
        r[tᵢ] = Inf # don't let a time step be its own nearest neighbor
        τ[p, :] = sortperm(r)[1:K]
    end
    return τ
end

# step four - Define matrix T
"""
# TODO: a summary sentence here

$(SIGNATURES)
where `D` is the lag-embedded data and 
`τ` gives the indices of the `k` nearest neighbors
"""
function space_time_similarity(N::Integer, τ::Matrix{<:Real})
    P, K = size(τ) # we can infer this

    # resampling probabilities depend on the rank of the closeness, not the distance
    probs = normalize([1 / k for k in 1:K])

    # initialize
    𝐓 = zeros(N, P)

    # populate 𝐓 based on τ
    for p in 1:P
        for k in 1:K
            𝐓[τ[p, k], p] = probs[k]
        end
    end
    return 𝐓
end

"""
Compute the probability of going from time step tᵢ to all other time steps

$(SIGNATURES)
"""
function compute_transition_probs(𝐃::Matrix{<:Real}, tᵢ::Integer, K::Integer)
    ND = size(𝐃)[1]
    τ = compute_timestep_neighbors(𝐃, tᵢ, K)
    𝐓 = space_time_similarity(ND, τ)
    transition_probs = sum(𝐓; dims=2)[:]
    return transition_probs
end

function fit(𝐗::Matrix{<:Real}, M::Integer, K::Integer)
    N, P = size(𝐗)

    # define the state space
    𝐃 = define_lagged_state_space(𝐗, M)
    ND = size(𝐃)[1]

    # initialze the big transitoin probability matrix
    𝐏 = zeros(ND, ND)

    for t in ProgressBar(1:ND)
        𝐏[t, :] .= compute_transition_probs(𝐃, t, K)
        @show t
    end

    return P
end

function main()

    # get the raw data as a `WindSolarData` format
    input = get_default_inputs()

    # concat
    𝐗 = hcat(input.wind, input.solar)

    # fit
    M = 1 # number of lags
    K = 3 # number of nearest neighbors
    𝐏 = fit(𝐗, M, K)

    return 𝐏
end

main()

## TODO: add in seasonal window
## Generalize for more lags
