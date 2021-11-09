# define starting data
using Random: Random
using StatsBase

Random.seed!(1234)

"""
Create synthetic time series for analysis
p: number of sites
n: lenght of record (time)
"""
function make_synthetic_X(; p=3, n=7)
    X = Float64.(rand(1:10, n, p))
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
    τ = zeros(Int64, nsites, ntimes)
    for i in 1:p
        r = (D[i, tᵢ] .- D[i, :]) .^ 2
        τ[i, :] = sortperm(r; alg=QuickSort)
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
function define_matrix_T(p::Int,n::Int,τ, pj)
T = zeros(p, n)
for j in 1:p
    for i in τ[:, j]
        T[findall(τ[:, j] .== i), i] .= pj[j][1] # TODO is there a faster way?
    end
    return T
end
end

# compute similarity matrix
"""
compute similarity matrix
T: uncollapsed(?) similarity matrix
k: number of nearest neighbors
"""
function similarity_matrix(T,k)
    sim = vec(sum(T; dims=1))
    ordersim = last(sortperm(sim; alg=QuickSort), k)
    return ordersim
end
# step five - curtail largest k values
"""
ordersim: ordered similarity matrix
"""
function resample(ordersim)
    sumq = sum(sim[ordersim])
    prob = [sim[i] / sumq for i in ordersim]
    return t = sample(ordersim, Weights(prob))
end

p = 3
n = 7
M = 1
tᵢ = 1
k = 3
X = make_synthetic_X(; p=p, n=n)
D = define_state_space(X, M)
τ = compute_knn(D, tᵢ, k)
pj = compute_resample_prob(k)
T = define_matrix_T(p, n, τ, pj)
ordersim = similarity_matrix(T,k)
t = resample(ordersim)
