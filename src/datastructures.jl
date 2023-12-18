
"""
    GeoAvailability <: EMB.Availability

A geography `Availability` node for substituion of the general `Availability` node.
A `GeoAvailability` is required if transmission should be included between individual
`Area`s due to a changed mass balance.

# Fields
- **`id`** is the name/identifier of the node.\n
- **`input::Array{<:Resource}`** are the input `Resource`s with conversion value `Real`.
The latter are not relevant but included for consistency with other formulations.\n
- **`output::Array{<:Resource}`** are the generated `Resource`s with conversion value `Real`.
The latter are not relevant but included for consistency with other formulations.\n

"""
struct GeoAvailability <: EMB.Availability
    id
    input::Array{Resource}
    output::Array{Resource}
end
GeoAvailability(id, 𝒫::Array{Resource}) = GeoAvailability(id, 𝒫, 𝒫)

""" Declaration of the general type for areas."""
abstract type Area end

"""
    RefArea <: Area

A `RefArea` is an area representation with no additional constraints on energy/mass exchange.

# Fields
- **`id`** is the name/identifier of the area.\n
- **`name`** is the name of the area.\n
- **`lon::Real`** is the longitudinal position of the area.\n
- **`lat::Real`** is the latitudinal position of the area.\n
- **`node::Availability`** is the `Availability` node routing different resources within an area.

"""
struct RefArea <: Area
    id
    name
    lon::Real
    lat::Real
    node::EMB.Availability
end
Base.show(io::IO, a::Area) = print(io, "$(a.name)")


"""
    LimitedExchangeArea <: Area

A `LimitedExchangeArea` is an area in which the export is limited in each individual
operational period for the provided resources. This can be necessary when an area is
coupled with multiple other areas and the total export capacity should be restricted.

# Fields
- **`id`** is the name/identifier of the area.\n
- **`name`** is the name of the area.\n
- **`lon::Real`** is the longitudinal position of the area.\n
- **`lat::Real`** is the latitudinal position of the area.\n
- **`node::Availability`** is the `Availability` node routing different resources within an area.
- **`limit::Dict{EMB.Resource, TimeProfile}`** is the amount of a resource that can be exchanged with other areas
"""
struct LimitedExchangeArea <: Area
    id
    name
    lon::Real
    lat::Real
    node::EMB.Availability
    limit::Dict{EMB.Resource, TimeProfile}
end

"""
    name(a::Area)

Returns the name of area `a`.
"""
name(a::Area) = a.name

"""
    availability_node(a::Area)

Returns the availability node of an `Area` `a`.
"""
availability_node(a::Area) = a.node

"""
    limit_resources(a::LimitedExchangeArea)

Returns the limited resources of a `LimitedExchangeArea` `a`. All other resources are
considered unlimited.
"""
limit_resources(a::LimitedExchangeArea) = collect(keys(a.exchange_limit))

"""
    exchange_limit(a::LimitedExchangeArea)

Returns the limits of the exchange resources in area `a`.
"""
exchange_limit(a::LimitedExchangeArea) = a.exchange_limit
"""
    exchange_limit(a::LimitedExchangeArea, p::Resource)

Returns the limit of exchange resource `p` in area `a` a `TimeProfile`.
"""
exchange_limit(a::LimitedExchangeArea, p::Resource) =
    haskey(a.exchange_limit, p) ? a.exchange_limit[p] : FixedProfile(0)
"""
    exchange_limit(a::LimitedExchangeArea, p::Resource, t)

Returns the limit of exchange resource `p` in area `a` at time period `t`.
"""
exchange_limit(a::LimitedExchangeArea, p::Resource, t) =
    haskey(a.exchange_limit, p) ? a.exchange_limit[p][t] : 0


""" Declaration of the general type for transmission mode transporting resources between areas."""
abstract type TransmissionMode end
Base.show(io::IO, t::TransmissionMode) = print(io, "$(t.id)")

""" A reference dynamic `TransmissionMode`.

Generic representation of dynamic transmission modes, using for example truck, ship or railway transport.

# Fields
- **`id::String`** is the name/identifyer of the transmission mode.\n
- **`resource::Resource`** is the resource that is transported.\n
- **`trans_cap::TimeProfile`** is the capacity of the transmission mode.\n
- **`trans_loss::TimeProfile`** is the loss of the transported resource during transmission, modelled as a ratio.\n
- **`opex_var::TimeProfile`** is the variational operational costs per energy unit transported.\n
- **`opex_fixed::TimeProfile`** is the fixed operational costs per installed capacity.\n
- **`directions`** is the number of directions the resource can be transported, 1 is unidirectional (A->B) or 2 id bidirectional (A<->B).\n
- **`data::Dict{String, Data}`** is the additional data (e.g. for investments).
"""
struct RefDynamic <: TransmissionMode # E.g. Trucks, ships etc.
    id::String
    resource::EMB.Resource
    trans_cap::TimeProfile
    trans_loss::TimeProfile
    opex_var::TimeProfile
    opex_fixed::TimeProfile
    directions::Int # 1: Unidirectional or 2: Bidirectional
    #formulation::EMB.Formulation # linear/non-linear etc.
    data::Array{Data}
end

""" A reference static `TransmissionMode`.

Generic representation of static transmission modes, such as overhead power lines or pipelines.

# Fields
- **`id::String`** is the name/identifyer of the transmission mode.\n
- **`resource::Resource`** is the resource that is transported.\n
- **`trans_cap::Real`** is the capacity of the transmission mode.\n
- **`trans_loss::Real`** is the loss of the transported resource during transmission, modelled as a ratio.\n
- **`opex_var::TimeProfile`** is the variational operational costs per energy unit transported.\n
- **`opex_fixed::TimeProfile`** is the fixed operational costs per installed capacity.\n
- **`directions`** is the number of directions the resource can be transported, 1 is unidirectional (A->B) or 2 id bidirectional (A<->B).\n
- **`data::Dict{String, Data}`** is the additional data (e.g. for investments).
"""
struct RefStatic <: TransmissionMode # E.g. overhead power lines, pipelines etc.
    id::String
    resource::EMB.Resource
    trans_cap::TimeProfile
    trans_loss::TimeProfile
    opex_var::TimeProfile
    opex_fixed::TimeProfile
    directions::Int
    #formulation::EMB.Formulation
    data::Array{Data}
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
- **`id::String`** is the identifier used in printed output.\n
- **`inlet::Resource`** is the `Resource` going into transmission.\n
- **`outlet::Resource`** is the `Resource` going out of the outlet of the transmission.\n
- **`consuming::Resource`** is the `Resource` the transmission consumes by operating.\n
- **`consumption_rate::Real`** the rate of which the resource `Pipeline.consuming` is consumed, as
    a ratio of the volume of the resource going into the inlet. I.e.:

        `consumption_rate` = consumed volume / inlet volume (per operational period)\n
- **`trans_cap::Real`** is the capacity of the transmission mode.\n
- **`trans_loss::Real`** is the loss of the transported resource during transmission, modelled as a ratio.\n
- **`opex_var::TimeProfile`** is the variational operational costs per energy unit transported.\n
- **`opex_fixed::TimeProfile`** is the fixed operational costs per installed capacity.\n
- **`directions`** specifies that the pipeline is Unidirectional (1) by default.\n
- **`data::Dict{String, Data}`** is the additional data (e.g. for investments).
"""
Base.@kwdef struct PipeSimple <: PipeMode
    id::String

    inlet::EMB.Resource
    outlet::EMB.Resource
    consuming::EMB.Resource
    consumption_rate::TimeProfile
    trans_cap::TimeProfile
    trans_loss::TimeProfile
    opex_var::TimeProfile
    opex_fixed::TimeProfile
    # TODO remove below field? Should not be relevant for fluid pipeline.
    directions::Int = 1     # 1: Unidirectional only for pipeline
    data::Array{Data}
end


"""
    PipeLinepackSimple <: TransmissionMode
Pipeline model with linepacking implemented as simple storage function.

# Fields (additional to `PipeSimple`)
- **`energy_share::Float64`**  - is the storage energy capacity relative to pipeline capacity.\n
- **`Level_share_init::Float64`**  - is the initial storage level. \n
- **`data::Dict{String, Data}`** is the additional data (e.g. for investments).
"""
Base.@kwdef struct PipeLinepackSimple <: PipeMode
    id::String
    inlet::EMB.Resource
    outlet::EMB.Resource
    consuming::EMB.Resource
    consumption_rate::TimeProfile
    trans_cap::TimeProfile
    trans_loss::TimeProfile
    opex_var::TimeProfile
    opex_fixed::TimeProfile
    energy_share::Float64 # Storage energy capacity relative to pipeline capacity
    directions::Int = 1     # 1: Unidirectional only for pipeline
    data::Array{Data}
end


""" A `Transmission` corridor.

A geographic corridor where `TransmissionModes` are used to transport resources.

# Fields
- **`from::Area`** is the area resources are transported from.\n
- **`to::Area`** is the area resources are transported to.\n
- **`modes::Array{TransmissionMode}`** is the transmission modes that are available.\n
"""
struct Transmission
    from::Area
    to::Area
    modes::Array{TransmissionMode}
end
Base.show(io::IO, t::Transmission) = print(io, "$(t.from)-$(t.to)")

"""
    trans_sub(ℒ, a::Area)

Return connected transmission corridors for a given area.
"""
function trans_sub(ℒ, a::Area)
    return [filter(x -> x.from == a, ℒ),
        filter(x -> x.to == a, ℒ)]
end

"""
    modes(l::Transmission)

Return an array of the transmission modes for a transmission corridor l.
"""
modes(l::Transmission) = l.modes

"""
    modes(ℒ::Vector{::Transmission})

Return an array of all transmission modes present in the different transmission corridors.
"""
function modes(ℒ::Vector{<:Transmission})
    tmp = Vector{TransmissionMode}()
    for l ∈ ℒ
        append!(tmp, modes(l))
    end

    return tmp
end

"""
    corr_from(from::String, ℒᵗʳᵃⁿˢ)

Returns all transmission corridors that orginate in the `Area` with the name `from`.
"""
function corr_from(from::String, ℒᵗʳᵃⁿˢ)

    sub_corr = Array{Transmission}([])
    for l ∈ ℒᵗʳᵃⁿˢ
        if isequal(from, l.from.name)
            append!(sub_corr, [l])
        end
    end

    return sub_corr
end
"""
    corr_from(from::Area, ℒᵗʳᵃⁿˢ)

Returns all transmission corridors that orginate in `Area` `from`.
"""
function corr_from(from::Area, ℒᵗʳᵃⁿˢ)

    sub_corr = Array{Transmission}([])
    for l ∈ ℒᵗʳᵃⁿˢ
        if from == l.from
            append!(sub_corr, [l])
        end
    end

    return sub_corr
end

"""
    corr_to(to::String, ℒᵗʳᵃⁿˢ)

Returns all transmission corridors that end in the `Area` with the name `to`.
"""
function corr_to(to::String, ℒᵗʳᵃⁿˢ)

    sub_corr = Array{Transmission}([])
    for l ∈ ℒᵗʳᵃⁿˢ
        if isequal(to, l.to.name)
            append!(sub_corr, [l])
        end
    end

    return sub_corr
end
"""
    corr_to(to::Area, ℒᵗʳᵃⁿˢ)

Returns all transmission corridors that end in `Area` `to`.
"""
function corr_to(to::Area, ℒᵗʳᵃⁿˢ)

    sub_corr = Array{Transmission}([])
    for l ∈ ℒᵗʳᵃⁿˢ
        if to == l.to
            append!(sub_corr, [l])
        end
    end

    return sub_corr
end

"""
    corr_from_to(from::String, to::String, ℒᵗʳᵃⁿˢ)

Returns the transmission corridor that orginate in the `Area` with the id `from`
and end in the `Area` with the id `to`.
"""
function corr_from_to(from::String, to::String, ℒᵗʳᵃⁿˢ)

    sub_corr = nothing
    for l ∈ ℒᵗʳᵃⁿˢ
        if isequal(from, l.from.id) && isequal(to, l.to.id)
            return l
        end
    end

end

"""
    corr_from_to(from::Area, to::Area, ℒᵗʳᵃⁿˢ)

Returns the transmission corridor that orginate in the `Area` with the id `from`
and end in the `Area` with the id `to`.
"""
function corr_from_to(from::Area, to::Area, ℒᵗʳᵃⁿˢ)

    sub_corr = nothing
    for l ∈ ℒᵗʳᵃⁿˢ
        if from == l.from && to == l.to
            sub_corr = l
        end
    end

    return sub_corr
end

"""
    modes_sub(ℳ, string::String)

Returns all transmission modes that include in the name the `string`.
"""
function modes_sub(ℳ, string::String)

    sub_modes = Array{TransmissionMode}([])
    for tm ∈ ℳ
        if isequal(string, tm.id)
            append!(sub_modes, [tm])
        end
    end

    return sub_modes
end
"""
    modes_sub(ℳ, string_array::Array{String})

Returns all transmission modes that include in the name all entries of
the array `string_array`.
"""
function modes_sub(ℳ, string_array::Array{String})

    sub_modes = Array{TransmissionMode}([])
    for tm ∈ ℳ
        if all(isequal(string, tm.id) for string ∈ string_array)
            append!(sub_modes, [tm])
        end
    end

    return sub_modes
end
"""
    modes_sub(l::Transmission, mode_type::TransmissionMode)

Return an array containing all `TransmissionMode`s of type `type` in `Transmission`
corridor `l`.
"""
function modes_sub(l::Transmission, mode_type::TransmissionMode)
    return [tm for tm ∈ modes(l) if typeof(tm) == mode_type]
end
"""
    modes_sub(ℒᵗʳᵃⁿˢ::Vector{<:Transmission}, mode_type::TransmissionMode)

Return an array containing all `TransmissionMode`s of type `type` in `Transmission`s `ℒ`.
"""
function modes_sub(ℒᵗʳᵃⁿˢ::Vector{<:Transmission}, mode_type::TransmissionMode)
    return filter(tm -> isa(tm, typeof(mode_type)), modes(ℒᵗʳᵃⁿˢ))
end
"""
    modes_sub(l::Transmission, p::Resource)

Return an array containing all `TransmissionMode`s that transport the resource `p` in
`Transmission` corridor `l`.
"""
function modes_sub(l::Transmission, p::Resource)
    return filter(tm -> map_trans_resource(tm) == p, modes(l))
end
"""
    modes_sub(ℒᵗʳᵃⁿˢ::Vector{<:Transmission}, p::Resource)

Return an array containing all `TransmissionMode`s that transport the resource `p` in
`Transmission`s `ℒ`.
"""
function modes_sub(ℒᵗʳᵃⁿˢ::Vector{<:Transmission}, p::Resource)
    return filter(tm -> map_trans_resource(tm) == p, modes(ℒᵗʳᵃⁿˢ))
end

"""
    map_trans_resource(tm)

Returns the transported resource for a given TransmissionMode.
"""
map_trans_resource(tm::TransmissionMode) = tm.resource
map_trans_resource(tm::PipeMode) = tm.inlet

"""
    extract_resources(ℒ, resource_method)

Return the resources transported/consumed by the transmission corridors in ℒ.
"""
function extract_resources(ℒ, resource_method)
    resources = []
    for l ∈ ℒ
        for transmission_mode ∈ modes(l)
            append!(resources, resource_method(transmission_mode))
        end
    end
    return unique(resources)
end


"""
    import_resources(ℒ, a::Area)

Return the resources imported into area `a` on the transmission corridors in `ℒ`.
"""
function import_resources(ℒ, a::Area)
    ℒᵗᵒ = filter(x -> x.to == a, ℒ)
    return extract_resources(ℒᵗᵒ, outputs)
end


"""
    export_resources(ℒ, a::Area)

Return the resources exported from area `a` on the transmission corridors in `ℒ`.
"""
function export_resources(ℒ, a::Area)
    ℒᶠʳᵒᵐ = filter(x -> x.from == a, ℒ)
    return extract_resources(ℒᶠʳᵒᵐ, inputs)
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

Return the transmission modes of dir `directions` for transmission corridor `l``.
"""
function modes_of_dir(l::Transmission, dir::Int)
    return filter(x -> x.directions == dir, modes(l))
end
"""
    modes_of_dir(ℒ, dir::Int)

Return the transmission modes of dir `directions` for transmission modes `ℳ`.
"""
function modes_of_dir(ℳ::Vector{<:TransmissionMode}, dir::Int)

    return filter(x -> x.directions == dir, ℳ)
end

"""
    capacity(tm::TransmissionMode)

Returns the capacity of transmission mode `tm` as `TimeProfile`.
"""
EMB.capacity(tm::TransmissionMode) = tm.trans_cap
"""
    capacity(tm::TransmissionMode, t)

Returns the capacity of transmission mode `tm` at time period `t`.
"""
EMB.capacity(tm::TransmissionMode, t) = tm.trans_cap[t]

"""
    input(tm::TransmissionMode)

Returns the input resources of transmission mode `tm`.
"""
EMB.inputs(tm::TransmissionMode) = [tm.resource]
EMB.inputs(tm::PipeMode) = [tm.inlet, tm.consuming]

"""
    output(tm::TransmissionMode)

Returns the output resources of transmission mode `tm`.
"""
EMB.outputs(tm::TransmissionMode) = [tm.resource]
EMB.outputs(tm::PipeMode) = [tm.outlet]

"""
    opex_var(tm::TransmissionMode)

Returns the variable OPEX of transmission mode `tm` as `TimeProfile`.
"""
EMB.opex_var(tm::TransmissionMode) = tm.opex_var

"""
    opex_var(tm::TransmissionMode, t)

Returns the variable OPEX of transmission mode `tm` at time period `t`.
"""
EMB.opex_var(tm::TransmissionMode, t) = tm.opex_var[t]

"""
    opex_fixed(tm::TransmissionMode)

Returns the variable OPEX of transmission mode `tm` as `TimeProfile`.
"""
EMB.opex_fixed(tm::TransmissionMode) = tm.opex_fixed
"""
    opex_fixed(tm::TransmissionMode, t)

Returns the variable OPEX of transmission mode `tm` at time period `t`.
"""
EMB.opex_fixed(tm::TransmissionMode, t) = tm.opex_fixed[t]

"""
    loss(tm::TransmissionMode)

Returns the loss of transmission mode `tm` as `TimeProfile`.
"""
loss(tm::TransmissionMode) = tm.trans_loss
"""
    loss(tm::TransmissionMode, t)

Returns the loss of transmission mode `tm` at time period `t`.
"""
loss(tm::TransmissionMode, t) = tm.trans_loss[t]

"""
    directions(tm::TransmissionMode)

Returns the directions of transmission mode `tm`.
"""
directions(tm::TransmissionMode) = tm.directions

"""
    consumption_rate(tm::PipeMode)

Returns the consumption rate of pipe mode `tm` as `TimeProfile`.
"""
consumption_rate(tm::PipeMode) = tm.consumption_rate
"""
    consumption_rate(tm::PipeMode, t)

Returns the consumption rate of pipe mode `tm` at time period `t`.
"""
consumption_rate(tm::PipeMode, t) = tm.consumption_rate[t]

"""
    energy_share(tm::PipeLinepackSimple)

Returns the energy share of PipeLinepackSimple `tm`.
"""
energy_share(tm::PipeLinepackSimple) = tm.energy_share

"""
    is_bidirectional(tm::TransmissionMode)

Checks whether TransmissionMode `tm` is bidirectional.
"""
is_bidirectional(tm::TransmissionMode) = tm.directions == 2
