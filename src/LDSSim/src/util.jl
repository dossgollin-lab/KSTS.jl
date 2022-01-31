"""
Normalize a vector of weights/probabilities so that they sum to one

$(SIGNATURES)
"""
function normalize(w::Vector{<:Real})
    return w ./ sum(w)
end

"""
DOY index for WindSolarData struct

$(SIGNATURES)

`start_date` is the date of first daily energy input
"""
function DOY(start_date, wind)
    startdate = Date(start_date, DateFormat("y-m-d"));
    enddate = startdate + Dates.Day(length(wind))
    dr = collect(startdate:Day(1):enddate)
    return [Dates.dayofyear(i) for i in dr]
end

"""
Data inputs in current time step window

$(SIGNATURES)

`t` is the current time step
"""
function seasonal_window(t, windowsize)
    # convert t to DOY from WindSolarData?
    window = ((doy - windowsize/2):(doy + windowsize/2)) .% 365
    # find t where DOY == window 
end
