"""
Normalize a vector of weights/probabilities so that they sum to one

$(SIGNATURES)
"""
function normalize(w::Vector{<:Real})
    return w ./ sum(w)
end

"""
Get the index that are valid given a particular time step

$(SIGNATURES)

`t` is the current time step
`windowdays` is the total window size
`years` is the number of years in the data
"""
function selected_window(t, windowdays, years)
    bound = windowdays + 1
    half_window = Int(ceil(windowdays / 2))
    if t < 29
        selected = zeros(1, bound * years + (half_window - t))
        selected[1:(t + bound)] = (1:(t + bound))
    else
        selected = zeros(1, bound * years)
        selected[1:bound] = ((t - half_window):(t + half_window))
    end

    for y in 1:(years - 1)
        window = ((t - half_window):(t + half_window)) .+ y * 365
        selected[(y * bound):(y * bound + windowdays)] = collect(window)
    end
    if t < 29
        selected[(bound * years):(bound * years + (half_window - t))] =
            ((t - half_window):0) .+ years * 365
    end
    return vec(selected)
end
