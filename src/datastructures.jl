
""" A geography `Availability` node. for substituion of the general `Availability` node.

# Fields
- **`id`** is the name/identifier of the node.\n
- **`Input::Dict{Resource, Real}`** are the input `Resource`s with conversion value `Real`.
The latter are not relevant but included for consistency with other formulations.\n
- **`Output::Dict{Resource, Real}`** are the generated `Resource`s with conversion value `Real`.
The latter are not relevant but included for consistency with other formulations.\n

"""
struct GeoAvailability <: EMB.Availability
    id
    Input::Dict{EMB.Resource, Real}
    Output::Dict{EMB.Resource, Real}
end


""" Declaration of the general type for areas."""
abstract type Area end

""" A reference `Area`.

# Fields
- **`id`** is the name/identifier of the area.\n
- **`Name`** is the name of the area.\n
- **`Lon::Real`** is the longitudinal position of the area.\n
- **`Lat::Real`** is the latitudinal position of the area.\n
- **`An::Availability`** is the `Availability` node routing different resources within an area.

"""
struct RefArea <: Area
	id
    Name
	Lon::Real
	Lat::Real
	An::EMB.Availability
end
Base.show(io::IO, a::Area) = print(io, "$(a.Name)")


""" An `Area` with limited exchange based on local load.

# Fields
- **`id`** is the name/identifier of the area.\n
- **`Name`** is the name of the area.\n
- **`Lon::Real`** is the longitudinal position of the area.\n
- **`Lat::Real`** is the latitudinal position of the area.\n
- **`An::Availability`** is the `Availability` node routing different resources within an area.
- **`ExchangeLimit::Dict{EMB.Resource, Real}`** is the amount of a resource that can be exchanged with other areas
"""
struct LimitedExchangeArea <: Area
    id
    Name
    Lon::Real
    Lat::Real
    An::EMB.Availability
    Exchange_limit::Dict{EMB.Resource,StrategicFixedProfile}
end

""" Declaration of the general type for transmission mode transporting resources between areas."""
abstract type TransmissionMode end 
Base.show(io::IO, t::TransmissionMode) = print(io, "$(t.Name)")

""" A reference dynamic `TransmissionMode`.

Generic representation of dynamic transmission modes, using for example truck, ship or railway transport.

# Fields
- **`Name::String`** is the name/identifyer of the transmission mode.\n
- **`Resource::Resource`** is the resource that is transported.\n
- **`Trans_cap::TimeProfile`** is the capacity of the transmission mode.\n
- **`Trans_loss::TimeProfile`** is the loss of the transported resource during transmission, modelled as a ratio.\n
- **`Directions`** is the number of directions the resource can be transported, 1 is unidirectional (A->B) or 2 id bidirectional (A<->B).
"""
struct RefDynamic <: TransmissionMode # E.g. Trucks, ships etc.
    Name::String
    Resource::EMB.Resource
    Trans_cap::TimeProfile
    Trans_loss:: TimeProfile
    Directions::Int # 1: Unidirectional or 2: Bidirectional
    #formulation::EMB.Formulation # linear/non-linear etc.
end

""" A reference static `TransmissionMode`.

Generic representation of static transmission modes, such as overhead power lines or pipelines.

# Fields
- **`Name::String`** is the name/identifyer of the transmission mode.\n
- **`Resource::Resource`** is the resource that is transported.\n
- **`Trans_cap::Real`** is the capacity of the transmission mode.\n
- **`Trans_loss::Real`** is the loss of the transported resource during transmission, modelled as a ratio.\n
- **`Directions`** is the number of directions the resource can be transported, 1 is unidirectional (A->B) or 2 id bidirectional (A<->B).
"""
struct RefStatic <: TransmissionMode # E.g. overhead power lines, pipelines etc.
    Name::String
    Resource::EMB.Resource
    Trans_cap::TimeProfile
    Trans_loss::TimeProfile
    Directions::Int
    #formulation::EMB.Formulation
end


""" `TransmissionMode` mode for additional variable potential."""
abstract type PipeMode <: TransmissionMode end

"""
This `TransmissionMode` allows for altering the transported `Resource`.
    
A usage of this could e.g. be by defining a subtype struct of Resource with the field 
'pressure'. This PipelineMode can then take `SomeSubtype<:Resource` with pressure p₁ at the 
inlet, and pressure p₂ at the outlet.

This type also supports consuming resources proportionally to the volume of transported 
`Resource` (at the inlet). This could be used for modeling the power needed for operating 
the pipeline.

# Fields
- **`Name::String`** is the identifier used in printed output.\n
- **`Inlet::Resource`** is the `Resource` going into transmission.\n
- **`Outlet::Resource`** is the `Resource` going out of the outlet of the transmission.\n
- **`Consuming::Resource`** is the `Resource` the transmission consumes by operating.\n
- **`Consumption_rate::Real`** the rate of which the resource `Pipeline.Consuming` is consumed, as
    a ratio of the volume of the resource going into the inlet. I.e.:

        `Consumption_rate` = consumed volume / inlet volume (per operational period)\n
- **`Trans_cap::Real`** is the capacity of the transmission mode.\n
- **`Trans_loss::Real`** is the loss of the transported resource during transmission, modelled as a ratio.\n
- **`Directions`** specifies that the pipeline is Unidirectional (1) by default.\n
"""
Base.@kwdef struct PipeSimple <: PipeMode
    Name::String

    Inlet::EMB.Resource
    Outlet::EMB.Resource
    Consuming::EMB.Resource
    Consumption_rate::TimeProfile
    Trans_cap::TimeProfile
    Trans_loss::TimeProfile
    # TODO remove below field? Should not be relevant for fluid pipeline.
    Directions::Int = 1     # 1: Unidirectional or 2: Bidirectional
end


""" A `Transmission` corridor.

A geographic corridor where `TransmissionModes` are used to transport resources.

# Fields
**`From::Area`** is the area resources are trasported from.\n
**`To::Area`** is the area resources are trasported to.\n
**`Modes::Array{TransmissionMode}`** is the transmission modes that are available.\n
**`Data::Array{Dict{String, Data}}`** is the additional data (e.g. for investments).
"""
struct Transmission
    From::Area
    To::Area
    Modes::Array{TransmissionMode}
    Data::Dict{String, Union{EMB.Data,Dict{TransmissionMode,EMB.Data}}}
    #distance::Float
end
Base.show(io::IO, t::Transmission) = print(io, "$(t.From)-$(t.To)")

"""
    trans_sub(ℒ, a::Area)

Return connected transmission corridors for a given area.
"""
function trans_sub(ℒ, a::Area)
    return [ℒ[findall(x -> x.From == a, ℒ)],
            ℒ[findall(x -> x.To   == a, ℒ)]]
end

"""
    corridor_modes(l)

Return an array of the transmission modes for a transmission corridor l.
"""
function corridor_modes(l)
    return [m for m in l.Modes]
end


trans_mode_import(tm::TransmissionMode) = [tm.Resource]
trans_mode_import(tm::PipeMode) = [tm.Outlet]

trans_mode_export(tm::TransmissionMode) = [tm.Resource]
trans_mode_export(tm::PipeMode) = [tm.Inlet, tm.Consuming]

"""
    filter_transmission_modes(ℒ, filter_method)

Return the resources transported/consumed by the transmission corridors in ℒ.
"""
function filter_transmission_modes(ℒ, filter_method)
    resources = []
    for l in ℒ
        for transmission_mode in l.Modes
            append!(resources, filter_method(transmission_mode))
        end
    end
    return unique(resources)
end


""" 
    import_resources(ℒ, a::Area)

Return the resources imported into area a on the transmission corridors in ℒ.
"""
function import_resources(ℒ, a::Area)
    ℒᵗᵒ = ℒ[findall(x -> x.To == a, ℒ)]
    return filter_transmission_modes(ℒᵗᵒ, trans_mode_import)
end


""" 
    export_resources(ℒ, a::Area)

Return the resources exported from area a on the transmission corridors in ℒ.
"""
function export_resources(ℒ, a::Area)
    ℒᶠʳᵒᵐ = ℒ[findall(x -> x.From == a, ℒ)]
    return filter_transmission_modes(ℒᶠʳᵒᵐ , trans_mode_export)
end

""" 
    exchange_resources(ℒ, a::Area)

Return the resources exchanged (import and export) from area a on the transmission corridors in ℒ.
"""
function exchange_resources(ℒ, a::Area)
    l_exch = vcat(import_resources(ℒ, a), export_resources(ℒ, a))
    return unique(l_exch)
end

""" 
    modes_of_dir(l, dir::Int)

Return the transmission modes of dir directions for transmission corridor l.
"""
function modes_of_dir(l, dir::Int)
    return l.Modes[findall(x -> x.Directions == dir, l.Modes)]
end


#function trans_res(l::Transmission)
#    return intersect(keys(l.To.An.Input), keys(l.From.An.Output))
#end