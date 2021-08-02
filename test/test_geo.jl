using DataFrames: Statistics
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

Power = 𝒫[3]

# Flow in to availability nodes in each area
flow_in = Dict(a => [value.(m[:flow_in])[a.an, t, Power] for t ∈ 𝒯] for a ∈ areas)
println("Power generation")
println(flow_in, "\n")

# Flow out from availability nodes in each area
flow_out = [[value.(m[:flow_out])[a.an, t, Power] for t ∈ 𝒯] for a ∈ areas]

trans = Dict()
for l ∈ ℒᵗʳᵃⁿˢ
    for cm ∈ l.modes
        trans[l, cm.name] =  [value.(m[:trans_out])[l, t, cm] for t ∈ 𝒯]
    end
end
println("Power flow")
println(trans)

#trans = Dict((l, cm.name) => [value.(m[:trans_out])[l, t, cm] for t ∈ 𝒯] for l ∈ ℒᵗʳᵃⁿˢ, cm ∈ l.modes)

## Plot map - areas and transmission

using PlotlyJS, DataFrames, CSV
function system_map()
    marker = attr(size=20,
                  color=10)
    layout = Layout(geo_scope="europe", geo_resolution=50, width=500, height=550,
                    margin=attr(l=0, r=0, t=10, b=0))

    nodes = scattergeo(;mode="markers", lat=[i.lat for i in data[:areas]], lon=[i.lon for i in data[:areas]],
                        marker=marker, name="Areas", text = [i.name for i in data[:areas]])

    linestyle = attr(line= attr(width = 2.0, dash="dash"))
    lines = []
    for l in data[:transmission]
        line = scattergeo(;mode="lines", lat=[l.from.lat, l.to.lat], lon=[l.from.lon, l.to.lon],
                        marker=linestyle, width=2.0,  name=join([cm.name for cm ∈ l.modes]))
        lines = vcat(lines, [line])
    end
    plot(Array{GenericTrace}(vcat(nodes, lines)), layout)
end

system_map()

## Plot map with sizing for resource
import Statistics

function resource_map_avg(m, resource, times, lines; line_scale = 10, node_scale = 20)

    layout = Layout(geo_scope="europe", geo_resolution=50, width=500, height=550,
                    margin=attr(l=0, r=0, t=10, b=0), title=attr(text=resource.id, y=0.9))
    # Production data
    time_values = Dict(a.name => [value.(m[:flow_in])[a.an, t, 𝒫[3]] for t ∈ 𝒯] for a ∈ areas)
    mean_values = Dict(k=> round(Statistics.mean(v), digits=2) for (k, v) in time_values)
    scale = node_scale/maximum(values(mean_values))
    nodes = scattergeo(;lat=[i.lat for i in data[:areas]], lon=[i.lon for i in data[:areas]],
                       mode="markers", marker=attr(size=[mean_values[i.name]*scale for i in data[:areas]], color=10),
                       name="Areas", text = [join([i.name, ": ", mean_values[i.name]]) for i in data[:areas]])

    # Transmission data
    trans = Dict()
    for l ∈ lines
        trans[l] = zeros(length(times))
        for cm in l.modes
            if cm.resource == resource
                trans[l] += [value.(m[:trans_out])[l, t, cm] for t ∈ times]
            end
        end
    end
    println(trans)
    mean_values = Dict(k=> round(Statistics.mean(v), digits=2) for (k, v) in trans)
    scale = line_scale/maximum(values(mean_values))
    lines = []
    for l in data[:transmission]
        line = scattergeo(;lat=[l.from.lat, l.to.lat], lon=[l.from.lon, l.to.lon],
                          mode="lines", line = attr(width=mean_values[l]*scale),
                          text =  mean_values[l], name=join([cm.name for cm ∈ l.modes]))
        lines = vcat(lines, [line])
    end
    plot(Array{GenericTrace}(vcat(nodes, lines)), layout)

end
resource_map_avg(m, 𝒫[3], 𝒯, ℒᵗʳᵃⁿˢ)