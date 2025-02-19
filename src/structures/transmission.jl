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

Returns an array of the transmission modes for a transmission corridor `l` or for a vector
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

Returns an array containing all [`TransmissionMode`](@ref)s of type `mode_type` in
[`Transmission`])@ref) corridor `l` or for a vector of transmission corridors `ℒᵗʳᵃⁿˢ`.
"""
modes_sub(l::Transmission, mode_type::Type{<:TransmissionMode}) =
    filter(tm -> isa(tm, mode_type), modes(l))
modes_sub(ℒᵗʳᵃⁿˢ::Vector{<:Transmission}, mode_type::Type{<:TransmissionMode}) =
    filter(tm -> isa(tm, mode_type), modes(ℒᵗʳᵃⁿˢ))
"""
    modes_sub(l::Transmission, p::Resource)
    modes_sub(ℒᵗʳᵃⁿˢ::Vector{<:Transmission}, p::Resource)

Returns an array containing all [`TransmissionMode`](@ref)s that transport the resource `p`
in [`Transmission`])@ref) corridor `l` or in a vector of transmission corridors `ℒᵗʳᵃⁿˢ`.
"""
modes_sub(l::Transmission, p::Resource) =
    filter(tm -> map_trans_resource(tm) == p, modes(l))
modes_sub(ℒᵗʳᵃⁿˢ::Vector{<:Transmission}, p::Resource) =
    filter(tm -> map_trans_resource(tm) == p, modes(ℒᵗʳᵃⁿˢ))

"""
    modes_sub(l::Transmission, str::String)
    modes_sub(l::Transmission, string_array::Array{String})
    modes_sub(ℒᵗʳᵃⁿˢ::Vector{<:Transmission}, str::String)
    modes_sub(ℒᵗʳᵃⁿˢ::Vector{<:Transmission}, string_array::Array{String})

Returns an array containing all [`TransmissionMode`](@ref)s of [`Transmission`])@ref)
corridor `l` or in a vector of transmission corridors `ℒᵗʳᵃⁿˢ` that include in the name the
String `str` or any of values in the String array `str_arr`.
"""
modes_sub(l::Transmission, str::String) = modes_sub(modes(l), str)
modes_sub(l::Transmission, str_arr::Array{String}) = modes_sub(modes(l), str_arr)
modes_sub(ℒᵗʳᵃⁿˢ::Vector{<:Transmission}, str::String) =
    modes_sub(modes(ℒᵗʳᵃⁿˢ), str)
modes_sub(ℒᵗʳᵃⁿˢ::Vector{<:Transmission}, str_arr::Array{String}) =
    modes_sub(modes(ℒᵗʳᵃⁿˢ), str_arr)
