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
    GeoAvailability <: EMB.Availability

A geography `Availability` node for substituion of the general `Availability` node.
A `GeoAvailability` is required if transmission should be included between individual
`Area`s due to a changed mass balance.

# Fields
- **`id`** is the name/identifier of the node.\n
- **`input::Array{<:Resource}`** are the input `Resource`s with conversion value `Real`. \
The latter are not relevant but included for consistency with other formulations.\n
- **`output::Array{<:Resource}`** are the generated `Resource`s with conversion value `Real`. \
The latter are not relevant but included for consistency with other formulations.\n

"""
struct GeoAvailability <: EMB.Availability
    id
    input::Array{Resource}
    output::Array{Resource}
end
GeoAvailability(id, 𝒫::Array{Resource}) = GeoAvailability(id, 𝒫, 𝒫)

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

"""
    trans_sub(ℒ, a::Area)

Return connected transmission corridors for a given area.
"""
function trans_sub(ℒ, a::Area)
    return [filter(x -> x.from == a, ℒ),
        filter(x -> x.to == a, ℒ)]
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

    for l ∈ ℒᵗʳᵃⁿˢ
        if isequal(from, l.from.name) && isequal(to, l.to.name)
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

    for l ∈ ℒᵗʳᵃⁿˢ
        if from == l.from && to == l.to
            return l
        end
    end
end

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
