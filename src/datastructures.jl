
struct GeoAvailability <: EMB.Availability
    id
    input::Dict{EMB.Resource, Real}
    output::Dict{EMB.Resource, Real}
end

# Nodes
struct Area
	id
    name
	lon::Real
	lat::Real
	an::EMB.Availability
end
Base.show(io::IO, a::Area) = print(io, "$(a.name)")

abstract type TransmissionMode end 
Base.show(io::IO, t::TransmissionMode) = print(io, "$(t.name)")

struct RefDynamic <: TransmissionMode # E.g. Trucks, ships etc.
    name::String
    resource::EMB.Resource
    capacity::Real
    loss:: Real
    directions::Int # 1: Unidirectional or 2: Bidirectional
    #formulation::EMB.Formulation # linear/non-linear etc.
end
struct RefStatic <: TransmissionMode # E.g. overhead power lines, pipelines etc.
    name::String
    resource::EMB.Resource
    capacity::Real
    loss::Real
    directions::Int
    #formulation::EMB.Formulation
end

# Transmission
struct Transmission
    from::Area
    to::Area
    modes::Array{TransmissionMode}
    #distance::Float
end
Base.show(io::IO, t::Transmission) = print(io, "$(t.from)-$(t.to)")

function trans_sub(ℒ, a::Area)
    return [ℒ[findall(x -> x.from == a, ℒ)],
            ℒ[findall(x -> x.to   == a, ℒ)]]
end
function corridor_modes(l)
    return [m for m in l.modes]
end
function mode_resources(l)
    return unique([m.resource for m in l.modes])
end
function trans_resources(ℒ)
    res = []
    for l in ℒ
        append!(res, mode_resources(l))
    end
    return unique(res)
end
function import_resources(ℒ, a::Area)
    l_from = ℒ[findall(x -> x.from == a, ℒ)]
    return trans_resources(l_from)
end
function export_resources(ℒ, a::Area)
    l_to = ℒ[findall(x -> x.to == a, ℒ)]
    return trans_resources(l_to)
end

function exchange_resources(ℒ, a::Area)
    l_exch = vcat(import_resources(ℒ, a), export_resources(ℒ, a))
    return unique(l_exch)
end

function modes_of_dir(l, dir::Int)
    return l.modes[findall(x -> x.directions == dir, l.modes)]
end
#function trans_res(l::Transmission)
#    return intersect(keys(l.to.an.input), keys(l.from.an.output))
#end

# Map example (go.Scattermapbox at bottom of page)
# https://plotly.com/python/hover-text-and-formatting/