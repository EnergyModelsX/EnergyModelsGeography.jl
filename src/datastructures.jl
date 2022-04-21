
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


"""
This TransmissionMode allows for altering the transported Resource. A usage of this could
be by defining a subtype struct of Resource with the field 'pressure'. This PipelineMode
can then take SomeSubtype<:Resource with pressure p1 at the inlet, and pressure p2 at 
the outlet.

This type also supports consuming resources proportionally to the volume of transported 
Resource (at the inlet). This could be used for modeling the Power needed for operating 
the pipeline.
"""
Base.@kwdef struct PipelineMode <: TransmissionMode
    Name::String

    Inlet::EMB.Resource     # the resource accepted at the inlet
    Outlet::EMB.Resource    # the resource at the outlet
    Consuming::EMB.Resource # the Resource consumed by operating the pipeline
    Consumption_rate::Real  # consumed volume / inlet volume (per operatioanl period)

    Trans_cap::Real
    Trans_loss::Real

    # TODO remove below field? Should not be relevant for fluid pipeline.
    Directions::Int = 1     # 1: Unidirectional or 2: Bidirectional

end


# Transmission
struct Transmission
    From::Area
    To::Area
    Modes::Array{TransmissionMode}
    Data::Array{Dict{String, EMB.Data}}
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


trans_mode_import(tm::TransmissionMode) = [tm.Resource]
trans_mode_import(tm::PipelineMode) = [tm.Outlet]

trans_mode_export(tm::TransmissionMode) = [tm.Resource]
trans_mode_export(tm::PipelineMode) = [tm.Inlet, tm.Consuming]


function filter_transmission_modes(ℒ, a::Area, filter_method)
    resources = []
    for l in ℒ
        for transmission_mode in l.Modes
            append!(resources, filter_method(transmission_mode))
        end
    end
    return unique(resources)
end


""" The resources imported into the area.
"""
function import_resources(ℒ, a::Area)
    ℒᵗᵒ = ℒ[findall(x -> x.To == a, ℒ)]
    return filter_transmission_modes(ℒᵗᵒ, a, trans_mode_import)
end


""" The resources exported from the area.
"""
function export_resources(ℒ, a::Area)
    ℒᶠʳᵒᵐ = ℒ[findall(x -> x.From == a, ℒ)]
    return filter_transmission_modes(ℒᶠʳᵒᵐ , a, trans_mode_export)
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