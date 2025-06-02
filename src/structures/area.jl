"""
    Area <: AbstractElement

Declaration of the general type for areas.
"""
abstract type Area <: AbstractElement end

"""
    RefArea <: Area

A `RefArea` is an area representation with no additional constraints on energy/mass exchange.

# Fields
- **`id`** is the name/identifier of the area.
- **`name`** is the name of the area.
- **`lon::Real`** is the longitudinal position of the area.
- **`lat::Real`** is the latitudinal position of the area.
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
- **`id`** is the name/identifier of the area.
- **`name`** is the name of the area.
- **`lon::Real`** is the longitudinal position of the area.
- **`lat::Real`** is the latitudinal position of the area.
- **`node::Availability`** is the `Availability` node routing different resources within an
  area.
- **`limit::Dict{<:EMB.Resource, <:TimeProfile}`** is the amount of a resource that can be
  exchanged with other areas.
"""
struct LimitedExchangeArea <: Area
    id
    name
    lon::Real
    lat::Real
    node::EMB.Availability
    limit::Dict{<:EMB.Resource, <:TimeProfile}
end

"""
    GeoAvailability <: EMB.Availability

A geography `Availability` node for substituion of the general
[`GenAvailability`](@extref EnergyModelsBase.GenAvailability) node. A `GeoAvailability` is
required if transmission should be included between individual [`Area`](@ref)s due to a
changed mass balance.

# Fields
- **`id`** is the name/identifier of the node.
- **`inputs::Vector{<:Resource}`** are the input [`Resource`](@extref EnergyModelsBase.Resource)s.
- **`output::Vector{<:Resource}`** are the output [`Resource`](@extref EnergyModelsBase.Resource)s.
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
limit_resources(a::LimitedExchangeArea) = collect(keys(a.limit))

"""
    exchange_limit(a::LimitedExchangeArea)
    exchange_limit(a::LimitedExchangeArea, p::Resource)
    exchange_limit(a::LimitedExchangeArea, p::Resource, t)

Returns the limits of the exchange resources in area `a` as dictionary, the value of
resource `p` as `TimeProfile`, or the value of resource p in operational period `t`.

If the resource `p` is not included, the function returns either a `FixedProfile(0)` or a
value of 0.
"""
exchange_limit(a::LimitedExchangeArea) = a.limit
exchange_limit(a::LimitedExchangeArea, p::Resource) =
    haskey(a.limit, p) ? a.limit[p] : FixedProfile(0)
exchange_limit(a::LimitedExchangeArea, p::Resource, t) =
    haskey(a.limit, p) ? a.limit[p][t] : 0

"""
    trans_sub(ℒᵗʳᵃⁿˢ, a::Area)

Return connected transmission corridors for a given area `a`.
"""
function trans_sub(ℒᵗʳᵃⁿˢ, a::Area)
    return [filter(x -> x.from == a, ℒᵗʳᵃⁿˢ),
        filter(x -> x.to == a, ℒᵗʳᵃⁿˢ)]
end

"""
    corr_from(from::Area, ℒᵗʳᵃⁿˢ)
    corr_from(from::String, ℒᵗʳᵃⁿˢ)

Returns all transmission corridors in `ℒᵗʳᵃⁿˢ` that orginate in the [`Area`](@ref) `from`.
If `from` is provided as `String`, it returns the corridors in which the name is equal to
`from`
"""
corr_from(from::Area, ℒᵗʳᵃⁿˢ) = filter(x -> x.from == from, ℒᵗʳᵃⁿˢ)
corr_from(from::String, ℒᵗʳᵃⁿˢ) = filter(x -> name(x.from) == from, ℒᵗʳᵃⁿˢ)

"""
    corr_to(to::Area, ℒᵗʳᵃⁿˢ)
    corr_to(to::String, ℒᵗʳᵃⁿˢ)

Returns all transmission corridors in `ℒᵗʳᵃⁿˢ` that end in the [`Area`](@ref) `to`.
If `to` is provided as `String`, it returns the corridors in which the name is equal to
`to`
"""
corr_to(to::Area, ℒᵗʳᵃⁿˢ) = filter(x -> x.to == to, ℒᵗʳᵃⁿˢ)
corr_to(to::String, ℒᵗʳᵃⁿˢ) = filter(x -> name(x.to) == to, ℒᵗʳᵃⁿˢ)

"""
    corr_from_to(from::Union{Area,String}, to::Union{Area,String}, ℒᵗʳᵃⁿˢ)

Returns the transmission corridor that orginate in the [`Area`](@ref) `from` and end in the
[`Area`](@ref) `to`.

The function accepts both inputs as `String` and `Area` as well as a combination of both
"""
function corr_from_to(from::Union{Area,String}, to::Union{Area,String}, ℒᵗʳᵃⁿˢ)
    ℒᶠʳᵒᵐ = corr_from(from, ℒᵗʳᵃⁿˢ)
    return  corr_to(to, ℒᶠʳᵒᵐ)
end

"""
    extract_resources(ℒᵗʳᵃⁿˢ, resource_method)

Return the resources transported/consumed by the transmission corridors in `ℒᵗʳᵃⁿˢ`.
"""
function extract_resources(ℒᵗʳᵃⁿˢ, resource_method)
    resources = []
    for l ∈ ℒᵗʳᵃⁿˢ
        for transmission_mode ∈ modes(l)
            append!(resources, resource_method(transmission_mode))
        end
    end
    return unique(resources)
end


"""
    import_resources(ℒᵗʳᵃⁿˢ, a::Area)

Return the resources imported into area `a` on the transmission corridors in `ℒᵗʳᵃⁿˢ`.
"""
function import_resources(ℒᵗʳᵃⁿˢ, a::Area)
    ℒᵗᵒ = filter(x -> x.to == a, ℒᵗʳᵃⁿˢ)
    return extract_resources(ℒᵗᵒ, outputs)
end


"""
    export_resources(ℒᵗʳᵃⁿˢ, a::Area)

Return the resources exported from area `a` on the transmission corridors in `ℒᵗʳᵃⁿˢ`.
"""
function export_resources(ℒᵗʳᵃⁿˢ, a::Area)
    ℒᶠʳᵒᵐ = filter(x -> x.from == a, ℒᵗʳᵃⁿˢ)
    return extract_resources(ℒᶠʳᵒᵐ, inputs)
end

"""
    exchange_resources(ℒᵗʳᵃⁿˢ, a::Area)

Return the resources exchanged (import and export) from area `a` on the transmission
corridors in `ℒᵗʳᵃⁿˢ`.
"""
function exchange_resources(ℒᵗʳᵃⁿˢ, a::Area)
    l_exch = vcat(import_resources(ℒᵗʳᵃⁿˢ, a), export_resources(ℒᵗʳᵃⁿˢ, a))
    return unique(l_exch)
end
