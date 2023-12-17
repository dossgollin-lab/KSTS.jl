# TODO: develop some diagnostic plots
using Plots
site1 = sim_data[:, 1]
plot(site1)
plot(sim_data)

monthlyavg = [sum(site1[x:(x + 29)]) / 30 for x in collect(1:30:335)]
plot(monthlyavg)
