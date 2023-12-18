using DataFrames: Statistics
using Revise
import EnergyModelsBase; const EMB = EnergyModelsBase
using TimeStructures
using JuMP
using HiGHS
using PlotlyJS, DataFrames, CSV
import Statistics

## Run with Geography package and several areas
import EnergyModelsGeography; const EMG = EnergyModelsGeography

# Create and run the model
m, case = EMG.run_model("", HiGHS.Optimizer)

# Extract the indiviudal data from the model
𝒯       = case[:T]
𝒯ᴵⁿᵛ    = strategic_periods(𝒯)
𝒩       = case[:nodes]
𝒩ⁿᵒᵗ    = EMB.node_not_av(𝒩)
av      = 𝒩[findall(x -> isa(x, EMB.Availability), 𝒩)]
𝒜       = case[:areas]
ℒᵗʳᵃⁿˢ  = case[:transmission]
𝒫       = case[:products]

CH4     = 𝒫[1]
Power   = 𝒫[3]
CO2     = 𝒫[4]

# Calculatie the CO2 emissions
emissions_CO2 = [value.(m[:emissions_strategic])[t_inv, CO2] for t_inv ∈ 𝒯ᴵⁿᵛ]

# Flow in to availability nodes in each area
flow_in = Dict(a => [value.(m[:flow_in])[availability_node(a), t, Power] for t ∈ 𝒯] for a ∈ 𝒜)
println("Power generation")
println(flow_in, "\n")

# Flow out from availability nodes in each area
flow_out = [[value.(m[:flow_out])[availability_node(a), t, Power] for t ∈ 𝒯] for a ∈ 𝒜]

trans = Dict()
for l ∈ ℒᵗʳᵃⁿˢ
    for cm ∈ modes(l)
        trans[l, tm.id] =  [value.(m[:trans_out])[cm, t] for t ∈ 𝒯]
    end
end

trans_in = Dict()
for l ∈ ℒᵗʳᵃⁿˢ
    for cm ∈ modes(l)
        trans_in[l, tm.id] =  [value.(m[:trans_in])[cm, t] for t ∈ 𝒯]
    end
end

trans_loss = Dict()
for l ∈ ℒᵗʳᵃⁿˢ
    for cm ∈ modes(l)
        trans_loss[l, tm.id] =  [value.(m[:trans_loss])[cm, t] for t ∈ 𝒯]
    end
end

trace=[]
for (k, v) ∈ trans
    global trace
    print(string(k[1]))
    tr = scatter(; y=v, mode="lines", name=join([string(k[1]), "<br>", k[2], " transmission"]))
    trace = vcat(trace, tr)
    tr = scatter(; y=trans_loss[k], mode="lines", name=join([string(k[1]), "<br>", k[2], " loss"]))
    trace = vcat(trace, tr)
end
plot(Array{GenericTrace}(trace))

trace=[]
k = collect(keys(trans))[1]
tr = scatter(; y=trans[k], mode="lines", name=join([string(k[1]), "<br>", k[2], " trans out"]))
trace = vcat(trace, tr)
tr = scatter(; y=trans_in[k], mode="lines", name=join([string(k[1]), "<br>", k[2], " trans in"]))
trace = vcat(trace, tr)
tr = scatter(; y=trans_loss[k], mode="lines", name=join([string(k[1]), "<br>", k[2], " loss"]))
trace = vcat(trace, tr)
plot(Array{GenericTrace}(trace))

exch = Dict()
for a ∈ 𝒜
    for cm ∈ EMG.exchange_resources(ℒᵗʳᵃⁿˢ, a)
        exch[a, cm] =  [value.(m[:area_exchange])[a, t, cm] for t ∈ 𝒯]
    end
end
println("Exchange")
println(exch)

## Plot map - areas and transmission

function system_map()
    marker = attr(size=20,
                  color=10)
    layout = Layout(geo=attr(scope="europe", resolution=50, fitbounds="locations",
                             showland=true, landcolor="lightgrey", showocean=true, oceancolor="lightblue"),
                    width=500, height=550, margin=attr(l=0, r=0, t=10, b=0))

    nodes = scattergeo(mode="markers", lat=[a.lat for a ∈ 𝒜], lon=[a.lon for a ∈ 𝒜],
                        marker=marker, name="Areas", text = [name(a) for a ∈ 𝒜])

    linestyle = attr(line= attr(width = 2.0, dash="dash"))
    lines = []
    for l ∈ case[:transmission]
        line = scattergeo(;mode="lines", lat=[l.from.lat, l.to.lat], lon=[l.from.lon, l.to.lon],
                        marker=linestyle, width=2.0,  name=join([tm.id for cm ∈ modes(l)]))
        lines = vcat(lines, [line])
    end
    plot(Array{GenericTrace}(vcat(nodes, lines)), layout)
end

system_map()

## Plot map with sizing for resource

function resource_map_avg(m, resource, times, lines; line_scale = 10, node_scale = 20)

    layout = Layout(geo=attr(scope="europe", resolution=50, fitbounds="locations",
                            showland=true, landcolor="lightgrey", showocean=true, oceancolor="lightblue"),
                    width=500, height=550, margin=attr(l=0, r=0, t=10, b=0),
                    title=attr(text=resource.id, y=0.9))

    # Production data
    time_values = Dict(name(a) => [value.(m[:flow_in])[availability_node(a), t, 𝒫[3]] for t ∈ 𝒯] for a ∈ areas)
    mean_values = Dict(k => round(Statistics.mean(v), digits=2) for (k, v) ∈ time_values)
    scale = node_scale/maximum(values(mean_values))
    nodes = scattergeo(;lat=[a.lat for a ∈ 𝒜], lon=[a.lon for a ∈ 𝒜],
                       mode="markers", marker=attr(size=[mean_values[name(a)]*scale for a ∈ 𝒜], color=10),
                       name="Areas", text = [join([name(a), ": ", mean_values[name(a)]]) for a ∈ 𝒜])

    # Transmission data
    trans = Dict()
    for l ∈ lines
        trans[l] = zeros(length(times))
        for cm ∈ modes(l)
            if cm.Resource == resource
                trans[l] += [value.(m[:trans_out])[cm, t] for t ∈ times]
            end
        end
    end
    println(trans)
    mean_values = Dict(k=> round(Statistics.mean(v), digits=2) for (k, v) ∈ trans)
    scale = line_scale/maximum(values(mean_values))
    lines = []
    for l ∈ case[:transmission]
        line = scattergeo(;lat=[l.from.lat, l.to.lat], lon=[l.from.lon, l.to.lon],
                          mode="lines", line = attr(width=mean_values[l]*scale),
                          text =  mean_values[l], name=join([tm.id for cm ∈ modes(l)]))
        lines = vcat(lines, [line])
    end
    plot(Array{GenericTrace}(vcat(nodes, lines)), layout)

end
resource_map_avg(m, 𝒫[3], 𝒯, ℒᵗʳᵃⁿˢ)
