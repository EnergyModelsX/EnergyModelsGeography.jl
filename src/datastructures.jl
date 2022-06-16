
struct GeoAvailability <: EMB.Availability
    id
    Input::Dict{EMB.Resource, Real}
    Output::Dict{EMB.Resource, Real}
end

# Nodes
struct Area
	id
    Name
	Lon::Real
	Lat::Real
	An::EMB.Availability
end
Base.show(io::IO, a::Area) = print(io, "$(a.Name)")

abstract type TransmissionMode end 
Base.show(io::IO, t::TransmissionMode) = print(io, "$(t.Name)")

struct RefDynamic <: TransmissionMode # E.g. Trucks, ships etc.
    Name::String
    Resource::EMB.Resource
    Trans_cap::Real
    Trans_loss:: Real
    Directions::Int # 1: Unidirectional or 2: Bidirectional
    #formulation::EMB.Formulation # linear/non-linear etc.
end
struct RefStatic <: TransmissionMode # E.g. overhead power lines, pipelines etc.
    Name::String
    Resource::EMB.Resource
    Trans_cap::Real
    Trans_loss::Real
    Directions::Int
    #formulation::EMB.Formulation
end

# Transmission
struct Transmission
    From::Area
    To::Area
    Modes::Array{TransmissionMode}
    Data::Dict{String, Union{EMB.Data,Dict(TransmissionMode,EMB.Data)}}
    #distance::Float
end
Base.show(io::IO, t::Transmission) = print(io, "$(t.From)-$(t.To)")

function trans_sub(ℒ, a::Area)
    return [ℒ[findall(x -> x.From == a, ℒ)],
            ℒ[findall(x -> x.To   == a, ℒ)]]
end
function corridor_modes(l)
    return [m for m in l.Modes]
end
function mode_resources(l)
    return unique([m.Resource for m in l.Modes])
end
function trans_resources(ℒ)
    res = []
    for l in ℒ
        append!(res, mode_resources(l))
    end
    return unique(res)
end
function import_resources(ℒ, a::Area)
    l_from = ℒ[findall(x -> x.From == a, ℒ)]
    return trans_resources(l_from)
end
function export_resources(ℒ, a::Area)
    l_to = ℒ[findall(x -> x.To == a, ℒ)]
    return trans_resources(l_to)
end

function exchange_resources(ℒ, a::Area)
    l_exch = vcat(import_resources(ℒ, a), export_resources(ℒ, a))
    return unique(l_exch)
end

function modes_of_dir(l, dir::Int)
    return l.Modes[findall(x -> x.Directions == dir, l.Modes)]
end
#function trans_res(l::Transmission)
#    return intersect(keys(l.To.An.Input), keys(l.From.An.Output))
#end

# Map example (go.Scattermapbox at bottom of page)
# https://plotly.com/python/hover-text-and-formatting/