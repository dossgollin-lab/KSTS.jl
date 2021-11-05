# define starting data
import Random
using StatsBase

Random.seed!(1234)

function make_synthetic_X()
    p = 3 # number of sites
    n = 7 # lenght of record (time)
    X = Float64.(rand(1:10, n, p))
    k = 3 # number of neighbors)
    return X
end

# step one - create state space D
function define_state_space(X::Matrix{Float64}, M::Int64)
    n, p = size(X)
    D = zeros(p, n - M)
    for i in (1:p)
        for t in (M+1:n)
            D[i, t-M] = (X[t-1, i])
        end
    end
    return D
end

# step two - compute k nearest neighbors for each site
function compute_knn(D::Matrix{Float64}, ti::Int, k::Int)
    nsites, ntimes = size(D)
    tau = zeros(Float64, nsites, ntimes)
    for i = 1:p
        r = (D[i, ti] .- D[i, :]) .^ 2
        tau[i, :] = sortperm(r, alg = QuickSort)
    end
    tau = Int.(tau[:, 1:k])
    return tau
end

X = make_synthetic_X()
D = define_state_space(X, 1)
tau = compute_knn(D, 1)


# step three - compute resampling probability
sumj = sum([1 / ki for ki = 1:k])
pj = [(1 / h) / sumj for h = 1:k]

# step four - Define matrix T
T = zeros(p, n)
for j = 1:p
    for i in tau[:, j]
        T[findall(tau[:, j] .== i), i] .= pj[j][1] # TODO is there a faster way?
    end
end

# compute similarity matrix
sim = vec(sum(T, dims = 1))
ordersim = last(sortperm(sim, alg = QuickSort), k)

# step five - curtail largest k values
sumq = sum(sim[ordersim])
prob = [sim[i] / sumq for i in ordersim]

# step five - resample from curtailed similarity matrix S
t = sample(ordersim, Weights(prob))
