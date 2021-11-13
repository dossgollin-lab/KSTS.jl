"""
Normalize a vector of weights/probabilities so that they sum to one

$(SIGNATURES)
"""
function normalize(w::Vector{<:Real})
    return w ./ sum(w)
end