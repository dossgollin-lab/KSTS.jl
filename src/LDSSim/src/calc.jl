"""
Define the state space D with multiple time embeddings

$(SIGNATURES)

where `X` is the observed data indexed [time, field]
and `M` is the maximum lag to use.

Returns the lagged embedding space `D` of shape (N-M, P).
This is a pre-processing step that only needs to be run once on input the dataset.
"""
function define_lagged_state_space(𝐗::Matrix{<:Real}, M::Integer)
    N, P = size(𝐗) # by definition!
    𝐃 = zeros(N - M, P)
    for p = 1:P
        for n = (M+1):N
            𝐃[n-M, p] = 𝐗[n-1, p]
        end
    end
    return 𝐃
end

"""
Compute the indices of the `K` nearest neighbors, separately for each location, from a given time step

$(SIGNATURES)

where `𝐃` is the state space,
`n` is the index of the current state (ie, time), and
`K` is the number of nearest neighbors to use.

This function returns a matrix τ, of dimension (P, K), where τ[p, k] gives the index of the kth closest observation to that at time n, at site p.
"""
function compute_timestep_neighbors(𝐃::Matrix{<:Real}, n::Integer, K::Integer)
    ND, P = size(𝐃) # recall that D has (N-M) rows
    τ = zeros(Integer, P, K)
    for p = 1:P
        r = (𝐃[n, p] .- 𝐃[:, p]) .^ 2
        r[n] = Inf # don't let a time step be its own nearest neighbor
        τ[p, :] = sortperm(r)[1:K]
    end
    return τ
end

"""
Compute the space-time similarity matrix

$(SIGNATURES)

where `D` is the lag-embedded data and 
`τ` gives the indices of the `k` nearest neighbors.
The resulting matrix 𝐓[n, p] gives the probability of going from the current state to
each other state calculated separately at each site.
"""
function space_time_similarity(N::Integer, τ::Matrix{<:Real})
    P, K = size(τ) # we can infer this

    # resampling probabilities depend on the rank of the closeness, not the distance
    probs = normalize([1 / k for k = 1:K])

    # initialize
    𝐓 = zeros(N, P)

    # populate 𝐓 based on τ
    for p = 1:P
        for k = 1:K
            𝐓[τ[p, k], p] = probs[k]
        end
    end
    return 𝐓
end

"""
Compute the probability of going from time step n to all other time steps

$(SIGNATURES)

This function returns a vector of length (N-M) indicating the probability of transitioning from state n to all other states.
"""
function compute_transition_probs(𝐃::Matrix{<:Real}, n::Integer, K::Integer)
    ND = size(𝐃)[1]
    τ = compute_timestep_neighbors(𝐃, n, K)
    𝐓 = space_time_similarity(ND, τ)
    transition_probs = normalize(sum(𝐓, dims = 2)[:])
    return transition_probs
end

"""
Get the KSTS fit

$(SIGNATURES)

where `W` is a valid `WindSolarData` object and `K` specifies the number of nearest neighbors to use
when fitting.
This function returns a `KSTSFit` object, which stores
    (1) the input data after accounting for lags,
    (2) the transition probabilities between each state,
    (3) the longitudes and latitudes associated with each site,
    and (4) the parameters used for the fit (M, K).
"""
function fit(W::WindSolarData, K::Integer)::KSTSFit

    M = 1 # TODO: need to implement more lags! I have some ideas.

    # digest the input data
    𝐗 = hcat(W.solar, W.wind) # TODO: should these be scaled in advance? Let's talk to Yash
    N, P = size(𝐗)

    # define the state space
    𝐃 = define_lagged_state_space(𝐗, M)
    ND = size(𝐃)[1]

    # initialze the big transitoin probability matrix
    𝐏 = zeros(ND, ND)

    for n in ProgressBar(1:ND)
        𝐏[n, :] .= compute_transition_probs(𝐃, n, K)
    end

    return KSTSFit(𝐃 = 𝐃, 𝐏 = 𝐏, lon = W.lon, lat = W.lat, M = M, K = K)
end
