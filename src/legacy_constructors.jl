"""
Legacy constructor for a `GeoAvailability`. This version will be discontinued
    in the near future and replaced with the application of Arrays instead of Dictionaries.
"""
function GeoAvailability(
    id,
    input::Dict{<:Resource,<:Real},
    output::Dict{<:Resource,<:Real},
    )

    @warn("This implementation of a `GeoAvailability` will be discontinued in \
    the near future. See the documentation for the new implementation not requiring using \
    a dictionary. It is recommended to update the existing version to the new version.")

    return GeoAvailability(id, collect(keys(input)), collect(keys(output)))
end
