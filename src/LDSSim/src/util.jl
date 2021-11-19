"""
Normalize a vector of weights/probabilities so that they sum to one

$(SIGNATURES)
"""
function normalize(w::Vector{<:Real})
    return w ./ sum(w)
end


# +-30 days around current day every 12 months
function season_window()
    selected = zeros(6,61)
    for y in 0:5
        window = (n-30:n+30) .+ y*365
        selected[y+1,:] = collect(window)
    end
    return selected
end