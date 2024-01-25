""" A `Transmission` corridor.

A geographic corridor where `TransmissionModes` are used to transport resources.

# Fields
- **`from::Area`** is the area resources are transported from.\n
- **`to::Area`** is the area resources are transported to.\n
- **`modes::Array{TransmissionMode}`** are the transmission modes that are available.\n
"""
struct Transmission
    from::Area
    to::Area
    modes::Array{TransmissionMode}
end
Base.show(io::IO, t::Transmission) = print(io, "$(t.from)-$(t.to)")

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
    modes_of_dir(l, dir::Int)

Return the transmission modes of dir `directions` for transmission corridor `l``.
"""
function modes_of_dir(l::Transmission, dir::Int)
    return filter(x -> x.directions == dir, modes(l))
end
