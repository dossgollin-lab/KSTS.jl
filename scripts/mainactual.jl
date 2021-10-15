using CSV
using DataFrames
using DelimitedFiles
using Dates
using Noise
using DelayEmbeddings
using StatsBase
using Distributions


function get_input_data()
    grid_locs = CSV.read("data/ERCOT_0_5_deg_lat_lon_index_key.csv", DataFrame)
    solar_radiation = readdlm("data/ERCOT_Solar_Rad_Daily.txt")
    wind_speed = readdlm("data/ERCOT_Wind_Power_Daily.txt")
    return grid_locs, solar_radiation, wind_speed
end


n = 5 * 365 # 5 years of data
p = 217

grid_locs, ssrd, WP = get_input_data()

WP_indexed = WP[2:n+1, 2:p]

ssrd_indexed = ssrd[2:n+1, 2:p]

#Concatenate the fields
Fld = hcat(WP_indexed, ssrd_indexed)

###Data Parameters
n_site = size(ssrd_indexed, 2)        #Number of Sites 
ngrids = size(Fld, 2)         #Number of grids (Grids = Sites x Fields)
N_valid = size(Fld, 1)        #Number of Time Steps

###Embeddings/State Space Parameters
max_embd = 2  #Max Value of Lagged Embedding
sel_lags = [1, 2] #Individual Lags Selected
n_lags = length(sel_lags) #Number of Lags
w = [1, 0] #Scaling Weights

###KSTS Algorithm Functions###

###Function 1 
#Objective - Moving Window Indices - Returns the day/hour index of interest.
###Inputs
#   1. Current Day-of-Year (curr)
#   2. Max value of Day-of-Year (max)
#   3. Moving Window Size (window)
###Output
#   1. All DOYs in the moving window

function close_ind(curr, max, window)
    if ((curr - window) < 1)
        indx = [last(1:max, (1 + abs(curr - window))), 1:(curr+window)]
    elseif ((curr + window) > max)
        indx = [((curr-window):max), (1:((curr+window)-max))]
    else
        indx = [(curr-window):(curr+window)]
    end
    return indx
end

###Function 2 
#Objective - Compute the K-Nearest Neighbors for each site
###Inputs
#   1. Current Feature Vector (x)
#   2. All historic Feature Vectors (xtest)
#   3. Number of Neighbors (nneib)
#   4. Scaling Weights (weights)
###Outputs
#   1. Indices corresponding to the k-nearest neighbors

function knn_sim_index(x, xtest, nneib, w)
    d = zeros(size(xtest, 2), size(x, 1))
    for i in (1:size(x, 2))
        d[:, i] = w[i] * (x[:, i] - xtest[:, i])^2
    end
    sumd = sum(d, 1)
    sorted_data = sortperm(sumd, alg = QuickSort)
    yknn = sorted_data[1:nneib]
    return yknn
end

# Add noise to data
function jitter(x)
    z = findmax(collect(skipmissing(x)))[1] - findmin(collect(skipmissing(x)))[1]
    a = z / 50
    if a == 0
        x = x .+ rand.()
        return x
    else
        x = x .+ rand.(Uniform(-a, a))
        return x
    end
end

# use days in window
function selected_days(days, sel_days)
    indexx = BitArray(undef, 1, length(days))
    if length(sel_days) > 1
        sel_days = vcat(sel_days[1], sel_days[2])
    end
    for i = 1:length(days)
        indexx[i] = (days[i] in sel_days)
    end
    return indexx
end

###Function 3 
#Objective - KSTS Simulator

###Input
#   1. Concatenated Data (Fld)
#   2. Number of Grid Points (ngrids)
#   3. Record Length (N_valid)
#   4. Number of Nearest Neighbors (nneib)
#   5. Scaling Weights (weights)
#   6. Record Start Date (start_date)
#   7. Moving Window Size (day_mv)
#   8. Maximum Embedding (max_embd)
#   9. Selected Embedding Lags (sel_lags)
#   10. Number of selected lags  (n_lags)

###Output
#   1. A single KSTS Simulation Realization

#Knn with embeddings without climate 

function ksts(
    Fld,
    ngrids,
    N_valid,
    nneib,
    w,
    start_date,
    day_mv,
    max_embd,
    sel_lags,
    n_lags,
)
    st_date = Date(start_date, dateformat"m-d-y")
    end_date = st_date + Dates.Day(N_valid)
    dr = st_date:Day(1):end_date
    time_stamp = collect(dr)
    day_index = [Dates.day(i) for i in time_stamp]
    
    #Setting up Storage for Simulations
    Xnew = zeros(N_valid, ngrids)
    for i = 1:max_embd
        Xnew[i, :] = jitter(Fld[i, :])
    end
    
    #Creating the feature Vector/state space
    X = zeros(Float64, N_valid - max_embd, n_lags, ngrids)
    Y = zeros(Float64, N_valid - max_embd, 1, ngrids)
    
    #Get Lagged Structure Upto Max Embedding
    for i = 1:ngrids
        str = parse.(Float64, string.(Fld[:, i]))

        x_fld = embed(str, max_embd + 1, 1)
        x_fld1 = Matrix(x_fld)
        x_fld2 = reverse(x_fld1, dims = 2)
        X[:, :, i] = x_fld2[:, sel_lags.+1]
        Y[:, :, i] = x_fld2[:, 1]
    end
    
    #Starting the Simulator
    for i = (max_embd+1):N_valid
        
        # store the indices to hold the nearest neighbors
        # nn_index[time, neighbor order] gives the index of the day that is the nth closest?
        nn_index = zeros(1, nneib, ngrids)

        day = day_index[i]
        sel_days = close_ind(day, 366, day_mv)
        
        #Subset to the moving window
        indx = day_index
        indx[i] = 999
        days = last(indx, length(indx) - (max_embd + 1))
        sel_days = collect([i for i in sel_days])

        ## X_t to return the days that are within the selected window.
        indexx = selected_days(days, sel_days)

        ## can only index booleans with same dimension
        X_t = X[indexx, :, :]
        Y_t = Y[indexx, :, :]

        for j in ngrids
            #Setting the Test Parameters
            sel_pars = j - sel_lags
            xtest = Xnew[sel_pars, j]
            #Running the KNN Algorithm
            nn_index[:, :, j] = knn_sim_index(X_t[:, :, j], xtest, nneib, w)
        end

        #Computing the Resampling Probability
        un_index = unique(nn_index)
        un_prob = zeros(1, length(un_index))

        # nn_index  <-  matrix(unlist(nn_index), nrow=nneib)

        for k = 1:length(un_index)
            temp = mod(findall(nn_index .== un_index[k]), nneib)
            for l = 1:length(temp)
                if temp[l] == 0
                    temp[l] = 1 / nneib
                else
                    temp[l] = 1 / temp[l]
                end
            end
            un_prob[k] = sum(temp)
        end
        pj = vcat(un_prob, un_index)
        thresh = mapslices(x -> last(sort!(x), nneib + 1)[1], pj, dims = 1)[1]
        pjidx = findall(pj[1, :] .> thresh, pj)
        pj = pj[:, pjidx]
        pj[1, :] = pj[1, :] ./ sum(pj[1, :])
        ns = sample(pj[2, :], [pj[1, :]])

        Xnew[i, :] = Y_t[ns, :]
    end
    n_site = ngrids / 2
    WPnew = Xnew[:, 1:n_site]
    SSnew = Xnew[:, (n_site+1):size(Xnew, 2)]

    return Dict(WPnew => WPnew, SSnew => SSnew)
end


#Run the Simulator

###Simulation Hyper-Parameters###
nneib = 50
nsim = 48

ksts(Fld, ngrids, N_valid, nneib, w, "01-01-1970", 30, max_embd, sel_lags, n_lags)






