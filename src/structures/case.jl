"""
    get_areas(case::Case)
    get_areas(𝒳::Vector{Vector})

Returns the vector of areas of the Case `case` or the vector of elements vectors 𝒳.
"""
get_areas(case::Case) = filter(el -> isa(el, Vector{<:Area}), get_elements_vec(case))[1]
get_areas(𝒳::Vector{Vector}) =
    filter(el -> isa(el, Vector{<:Area}), 𝒳)[1]

"""
    get_transmissions(case::Case)
    get_transmissions(𝒳::Vector{Vector})

Returns the vector of transmission corridors of the Case `case` or the vector of elements
vectors 𝒳.
"""
get_transmissions(case::Case) =
    filter(el -> isa(el, Vector{<:Transmission}), get_elements_vec(case))[1]
get_transmissions(𝒳::Vector{Vector}) =
    filter(el -> isa(el, Vector{<:Transmission}), 𝒳)[1]
