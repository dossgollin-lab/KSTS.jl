# define starting data
using Random: Random
using StatsBase

Random.seed!(1234)

"""
Create synthetic time series for analysis
p: number of sites
n: lenght of record (time)
"""
function make_synthetic_X(p, n, nmax)
    X = Float64.(rand(1:nmax, n, p))
    return X
end

"""
Create a state space D 
X: the observed data 
M: the maximum lag to use
"""
function define_state_space(X::Matrix{Float64}, M::Int64)
    n, p = size(X)
    D = zeros(p, n - M)
    for i in (1:p)
        for t in ((M + 1):n)
            D[i, t - M] = (X[t - 1, i])
        end
    end
    return D
end

"""
compute k nearest neighbors for each site
D: the state space
tᵢ: the current time index
k: the number of nearest neighbors to use
"""
function compute_knn(D::Matrix{Float64}, tᵢ::Int, k::Int)
    nsites, ntimes = size(D)
    τ = zeros(Int64, nsites, ntimes - 1)
    for i in 1:p
        r = (D[i, tᵢ] .- D[i, 1:end .!= tᵢ]) .^ 2 # remove last time step from state space
        τ[i, :] = sortperm(r)
    end
    return τ[:, 1:k]
end

"""
compute resampling probability
k: the number of nearest neighbors to use
"""
function compute_resample_prob(k::Int)
    sumj = sum([1 / ki for ki in 1:k])
    pj = [(1 / h) / sumj for h in 1:k]
    return pj
end

# step four - Define matrix T
"""
define matrix T
p: number of sites
n: lenght of record (time)
τ: k nearest neighbors 
pj: resampling probability
"""
function define_matrix_T(p::Int, n::Int, τ, pj)
    T = zeros(k, n)
    for j in 1:k
        for i in τ[:, j]
            T[findall(τ[:, j] .== i), i] .= pj[j][1] # TODO is there a faster way?
        end
    end
    return T
end

# compute similarity matrix
"""
compute similarity matrix
T: uncollapsed(?) similarity matrix
k: number of nearest neighbors
"""
function similarity_matrix(T, k)
    sim = vec(sum(T; dims=1))
    ordersim = last(sortperm(sim; alg=QuickSort), k)
    return sim,ordersim
end
# step five - curtail largest k values
"""
ordersim: ordered similarity matrix
"""
function resample(ordersim, sim)
    sumq = sum(sim[ordersim])
    prob = [sim[i] / sumq for i in ordersim]
    return t = sample(ordersim, Weights(prob))
end


"""
Initialize hyper-Parameters
p: number of sites
n: number of time steps
M: number of lags
tᵢ: current time step
k: number of nearest neighbors
nsim: length of simulation
time_series: stochastic projected time series
"""

p = 400
n = 100
M = 1
tᵢ = 1
k = 20
nsim = 20
time_series = zeros(1,nsim)
nmax = 100

for i in 1:nsim
    time_series[i] = tᵢ
    X = make_synthetic_X(p, n, nmax)
    D = define_state_space(X, M)
    τ = compute_knn(D, tᵢ, k)
    pj = compute_resample_prob(k)
    T = define_matrix_T(p, n, τ, pj) ## something going on here
    sim,ordersim = similarity_matrix(T, k)
    tᵢ = resample(ordersim, sim)
end

time_series
