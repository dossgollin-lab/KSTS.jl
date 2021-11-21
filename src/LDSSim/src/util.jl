"""
Normalize a vector of weights/probabilities so that they sum to one

$(SIGNATURES)
"""
function normalize(w::Vector{<:Real})
    return w ./ sum(w)
end

using BenchmarkTools




# +-30 days around current day every 12 months
function selected_window(t, windowdays, years)
    
    if t < 29
        selected = zeros(1,(windowdays+1)*years+(windowdays/2-t))
        selected[1:t+(windowdays+1)] = (1:t+(windowdays+1))
    else
        selected = zeros(1,(windowdays+1)*years)
        selected[1:(windowdays+1)] = (t-windowdays/2:t+windowdays/2)
    end 

    for y in 1:years-1
        window = (t-windowdays/2:t+windowdays/2) .+ y*365
        selected[y*(windowdays+1):y*(windowdays+1)+windowdays] = collect(window)
    end
    if t<29
        selected[(windowdays+1)*years: (windowdays+1)*years + (windowdays/2-t)] = (t-windowdays/2:0) .+ years*365
    end
    return vec(selected)
end

