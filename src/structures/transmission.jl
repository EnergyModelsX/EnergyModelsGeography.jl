"""
    Transmission <: AbstractElement

A geographic corridor between two [`Area`](@ref)s where [`TransmissionMode`](@ref)s are used
to transport resources.

# Fields
- **`from::Area`** is the area resources are transported from.
- **`to::Area`** is the area resources are transported to.
- **`modes::Vector{<:Transmission}`** are the transmission modes that are available.
"""
struct Transmission <: AbstractElement
    from::Area
    to::Area
    modes::Vector{<:TransmissionMode}
end
Base.show(io::IO, t::Transmission) = print(io, "$(t.from)-$(t.to)")

"""
    modes(l::Transmission)
    modes(ℒᵗʳᵃⁿˢ::Vector{<:Transmission})

Return an array of the transmission modes for a transmission corridor `l` or for a vector
of transmission corridors `ℒᵗʳᵃⁿˢ`.
"""
modes(l::Transmission) = l.modes
function modes(ℒᵗʳᵃⁿˢ::Vector{<:Transmission})
    tmp = TransmissionMode[]
    for l ∈ ℒᵗʳᵃⁿˢ
        append!(tmp, modes(l))
    end
    return tmp
end

"""
    modes_sub(l::Transmission, mode_type::TransmissionMode)
    modes_sub(ℒᵗʳᵃⁿˢ::Vector{<:Transmission}, mode_type::TransmissionMode)

Return an array containing all `TransmissionMode`s of type `mode_type` in `Transmission`
corridor `l` or for a vector of transmission corridors `ℒᵗʳᵃⁿˢ`.
"""
function modes_sub(l::Transmission, mode_type::TransmissionMode)
    return filter(tm -> isa(tm, typeof(mode_type)), modes(l))
end
function modes_sub(ℒᵗʳᵃⁿˢ::Vector{<:Transmission}, mode_type::TransmissionMode)
    return filter(tm -> isa(tm, typeof(mode_type)), modes(ℒᵗʳᵃⁿˢ))
end
"""
    modes_sub(l::Transmission, p::Resource)

Return an array containing all `TransmissionMode`s that transport the resource `p` in
`Transmission` corridor `l` or in a vector of transmission corridors `ℒᵗʳᵃⁿˢ`.
"""
function modes_sub(l::Transmission, p::Resource)
    return filter(tm -> map_trans_resource(tm) == p, modes(l))
end
function modes_sub(ℒᵗʳᵃⁿˢ::Vector{<:Transmission}, p::Resource)
    return filter(tm -> map_trans_resource(tm) == p, modes(ℒᵗʳᵃⁿˢ))
end

"""
    modes_of_dir(l, dir::Int)

Return the transmission modes of dir `directions` for transmission corridor `l``.
"""
function modes_of_dir(l::Transmission, dir::Int)
    return filter(x -> x.directions == dir, modes(l))
end
