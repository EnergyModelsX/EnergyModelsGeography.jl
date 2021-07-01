using Revise
import EnergyModelsBase; const EMB = EnergyModelsBase
using TimeStructures
using JuMP
using GLPK

## Run with several areas and Geography package
import Geography; const GEO = Geography

m, data = GEO.run_model("", GLPK.Optimizer)

𝒯ᴵⁿᵛ = strategic_periods(data[:T])
𝒯 = data[:T]
𝒩 = data[:nodes]
𝒩ⁿᵒᵗ = EMB.node_not_av(𝒩)
av = 𝒩[findall(x -> isa(x,EMB.Availability), 𝒩)]
areas = data[:areas]
ℒᵗʳᵃⁿˢ = data[:transmission]
𝒫 = data[:products]

CH4 = data[:products][1]
CO2 = data[:products][4]

emissions_CO2 = [value.(m[:emissions_strategic])[t_inv, CO2] for t_inv ∈ 𝒯ᴵⁿᵛ]

# Flow in to availability nodes in each area
flow_in = [[value.(m[:flow_in])[a.an, t, 𝒫[1]] for t ∈ 𝒯] for a ∈ areas]

# Flow out from availability nodes in each area
flow_out = [[value.(m[:flow_out])[a.an, t, 𝒫[1]] for t ∈ 𝒯] for a ∈ areas]

trans = Dict((l.id, p.id) => [value.(m[:trans_out])[l, t, p] - value.(m[:trans_in])[l, t, p] for t ∈ 𝒯] for l ∈ ℒᵗʳᵃⁿˢ, p ∈ 𝒫)

## Plot map - not finished

using PlotlyJS, DataFrames, CSV
function maps1()
    marker = attr(size=[20, 30, 15, 10],
                  color=[10, 20, 40, 50],
                  cmin=0,
                  cmax=50,
                  colorscale="Greens",
                  colorbar=attr(title="Some rate",
                                ticksuffix="%",
                                showticksuffix="last"),
                  line_color="black")
    trace = scattergeo(;mode="markers+lines", lat=[i.lat for i in data[:areas]], lon=[i.lon for i in data[:areas]],
                        marker=marker, name="Europe Data")
    layout = Layout(geo_scope="europe", geo_resolution=50, width=500, height=550,
                    margin=attr(l=0, r=0, t=10, b=0))
    plot(trace, layout)
end
maps1()