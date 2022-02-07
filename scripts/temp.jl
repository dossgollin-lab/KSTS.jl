
function seasonal_window(doy::Int, windowsize::Int)
    Δt = Int(floor((windowsize - 1) / 2))
    doy_i = doy - Δt
    doy_f = doy + Δt
    window = ((doy_i:doy_f) .+ 365) .% 365 .-1
    return window
end

windo = seasonal_window(10, 60)


doy = 10
windowsize = 60

Δt = Int(floor((windowsize - 1) / 2))
doy_i = doy - Δt
doy_f = doy + Δt
window = ((doy_i:doy_f) .+ 365) .% 365 .-1

findall(dayz == window)

A = [1, 2, 3, 7, 10, 11, 10]
B = [2, 5, 6]

findlast(A)

deleteat!(A, last(A,2))

findall(A in B)
map(x -> x in [1,2,4,5,8,9,10,11] ,[1,3,5,7,9,4])
[x in B  for x = A]

y = unique(rand(1:10,10))
z = dayz[dayz .∈ Ref(window)]

findall(dayz .∈ Ref(window))

sdate = Dates.Date(1970, 1, 1)
edate = sdate + Dates.Day(50)
t = collect(sdate:Dates.Day(1):edate)
doy = Dates.dayofyear.(t)


n = 10
windowsize = 60
doy_idx = seasonal_window(n, windowsize) # where idx == w.t
idx = findall(DOY .∈ Ref(doy_idx))