# set this up to use the local package
using Revise
using LDSSim

# import other packages
using Distributions
using DocStringExtensions
using DrWatson
using NearestNeighbors
using Random: Random
using StatsBase

# use this for consistent results
Random.seed!(1234)

"""
Create synthetic high-dimensional data set for analysis

$(SIGNATURES)

where 
`n` is the number of time steps to create,
`p` is the number of sites, 
and data is drawn from  the univariate distribution `d`
"""
function make_synthetic_X(n::Integer, p::Integer, d::T) where {T<:UnivariateDistribution}
    X = float.(rand(1:nmax, n, p))
    return X
end

"""
Create a state space D 

$(SIGNATURES)

where `X` is the observed data indexed [time, field]
and `M` is the maximum lag to use.

Returns the lagged embedding space `D` indexed [time, field]
"""
function define_state_space(X::Matrix{<:Real}, M::Integer)
    n, p = size(X)
    D = zeros(n - M, p)
    for i ∈ (1:p)
        for t ∈ ((M+1):n)
            D[t-M, i] = (X[t-1, i])
        end
    end
    return D
end

"""
Compute the `k` nearest neighbors for each site

$(SIGNATURES)

where `D` is the state space,
`tᵢ` is the current time index, and
`k` is the number of nearest neighbors to use
"""
function compute_knn(D::Matrix{<:Real}, tᵢ::Integer, k::Integer)
    ntimes, nsites = size(D)
    τ = zeros(Integer, ntimes - 1, nsites)
    for i = 1:nsites
        r = (D[tᵢ, i] .- D[1:end.!=tᵢ, i]) .^ 2 # remove last time step from state space
        τ[:, i] = sortperm(r)
    end
    return τ[:, 1:k]
end

"""
Compute the resampling probabilities

$(SIGNATURES)

where `k` the number of nearest neighbors to use.

# Details

Regardless of the distance, the K nearest neighbors are sampled with probability
proportional to
1/1, 1/2, 1/3, ..., 1/K.
"""
function compute_resample_probs(k::Integer)
    p = [(1 / kᵢ) for kᵢ = 1:k]
    return p ./ sum(p)
end

# step four - Define matrix T
"""
# TODO: a summary sentence here

$(SIGNATURES)
where `D` is the lag-embedded data and 
`τ` gives the indices of the `k` nearest neighbors
"""
function define_matrix_T(D, τ) # TODO: this needs a clearer name
    ntimes, nsites = size(D)
    k = size(τ)[2]
    pⱼ = compute_resample_probs(k)
    T = zeros(ntimes, nsites)
    for j = 1:k
        for i in τ[:, j]
            T[findall(τ[:, j] .== i), j] .= pⱼ[j][1] # TODO is there a faster way?
        end
    end
    return T
end

"""
Compute the similarity matrix

$(SIGNATURES)

where `T` gives the 'uncollapsed' similarity matrix and
`k` gives the number of nearest neighbors
"""
function similarity_matrix(T, k)
    sim = vec(sum(T, dims = 1))
    ordersim = last(sortperm(sim; alg = QuickSort), k)
    return sim, ordersim
end

"""
Get transition probs
"""
function get_next_probs(n::Integer, ordersim::Vector{<:Integer}, sim::Vector{<:Real})
    probs = zeros(n)
    for i in ordersim
        probs[i] = sim[i]
    end
    return probs ./ sum(probs)
end

function compute_transition_probs(D::Matrix{<:Real}, tᵢ::Integer, k::Integer)
    τ = compute_knn(D, tᵢ, k)
    T = define_matrix_T(D, τ)
    sim, ordersim = similarity_matrix(T, k)
    transition_probs = get_next_probs(n, ordersim, sim)
end


function fit(X::Matrix{<:Real}, M::Integer, k::Integer)

    # define the state space
    D = define_state_space(X, M)

    # initialze the big transitoin probability matrix
    P = zeros(n, n)

    # now fit the model
    for tᵢ = 1:n
        @show tᵢ
        P[tᵢ, :] .= compute_transition_probs(D, tᵢ, k)
    end

    return P
end

function main()
    # create synthetic data
    n = 10 # number of time steps
    p = 4 # number of sites
    d = Normal(0, 1) # the distribution that X is drawn from
    X = make_synthetic_X(n, p, d)

    # fit the model
    M = 1 # number of lags
    k = 3 # number of nearest neighbors
    P = fit(X, M, k)
end

main()

## TODO: add in seasonal window
## Generalize for more lags
