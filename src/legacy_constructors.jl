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

"""
    PipeSimple(
        id::String,
        inlet::EMB.Resource,
        outlet::EMB.Resource,
        consuming::EMB.Resource,
        consumption_rate::TimeProfile,
        trans_cap::TimeProfile,
        trans_loss::TimeProfile,
        opex_var::TimeProfile,
        opex_fixed::TimeProfile,
        directions::Int = 1
        data::Vector{Data} = Data[]
    )

Legacy constructor for a `PipeSimple`.
This version will be discontinued in the near future and replaced with the new version that
is no longer using the field directions

See the *[documentation](https://energymodelsx.github.io/EnergyModelsBase.jl/stable/how-to/update-models)*
for further information regarding how you can translate your existing model to the new model.
"""
function PipeSimple(
    id::String,
    inlet::EMB.Resource,
    outlet::EMB.Resource,
    consuming::EMB.Resource,
    consumption_rate::TimeProfile,
    trans_cap::TimeProfile,
    trans_loss::TimeProfile,
    opex_var::TimeProfile,
    opex_fixed::TimeProfile,
    directions::Int,
    data::Vector{Data},
)
    @warn(
        "The used implementation of a `PipeSimple` will be discontinued in the near future. " *
        "See the documentation for the new implementation in which we no longer utilize " *
        "the keyword constructor.\n" *
        "The only change required is to remove the keywords or alternatively the value for" *
        "directions.",
        maxlog = 1
    )

    tmp = PipeSimple(
        id,
        inlet,
        outlet,
        consuming,
        consumption_rate,
        trans_cap,
        trans_loss,
        opex_var,
        opex_fixed,
        data,
    )
    return tmp
end
function PipeSimple(;
    id::String,
    inlet::EMB.Resource,
    outlet::EMB.Resource,
    consuming::EMB.Resource,
    consumption_rate::TimeProfile,
    trans_cap::TimeProfile,
    trans_loss::TimeProfile,
    opex_var::TimeProfile,
    opex_fixed::TimeProfile,
    directions::Int = 1,
    data::Vector{Data} = Data[],
)
    @warn(
        "The used implementation of a `PipeSimple` will be discontinued in the near future. " *
        "See the documentation for the new implementation in which we no longer utilize " *
        "the keyword constructor.\n" *
        "The only change required is to remove the keywords or alternatively the value for" *
        "directions.",
        maxlog = 1
    )

    tmp = PipeSimple(
        id,
        inlet,
        outlet,
        consuming,
        consumption_rate,
        trans_cap,
        trans_loss,
        opex_var,
        opex_fixed,
        data,
    )
    return tmp
end

"""
    PipeLinepackSimple(
        id::String,
        inlet::EMB.Resource,
        outlet::EMB.Resource,
        consuming::EMB.Resource,
        consumption_rate::TimeProfile,
        trans_cap::TimeProfile,
        trans_loss::TimeProfile,
        opex_var::TimeProfile,
        opex_fixed::TimeProfile,
        energy_share::Float64,
        directions::Int = 1
        data::Vector{Data} = Data[]
    )

Legacy constructor for a `PipeLinepackSimple`.
This version will be discontinued in the near future and replaced with the new version that
is no longer using the field directions

See the *[documentation](https://energymodelsx.github.io/EnergyModelsBase.jl/stable/how-to/update-models)*
for further information regarding how you can translate your existing model to the new model.
"""
function PipeLinepackSimple(
    id::String,
    inlet::EMB.Resource,
    outlet::EMB.Resource,
    consuming::EMB.Resource,
    consumption_rate::TimeProfile,
    trans_cap::TimeProfile,
    trans_loss::TimeProfile,
    opex_var::TimeProfile,
    opex_fixed::TimeProfile,
    energy_share::Float64,
    directions::Int,
    data::Vector{Data},
)
    @warn(
        "The used implementation of a `PipeLinepackSimple` will be discontinued in the near future. " *
        "See the documentation for the new implementation in which we no longer utilize " *
        "the keyword constructor.\n" *
        "The only change required is to remove the keywords or alternatively the value for " *
        "directions.",
        maxlog = 1
    )

    tmp = PipeLinepackSimple(
        id,
        inlet,
        outlet,
        consuming,
        consumption_rate,
        trans_cap,
        trans_loss,
        opex_var,
        opex_fixed,
        energy_share,
        data,
    )
    return tmp
end
function PipeLinepackSimple(;
    id::String,
    inlet::EMB.Resource,
    outlet::EMB.Resource,
    consuming::EMB.Resource,
    consumption_rate::TimeProfile,
    trans_cap::TimeProfile,
    trans_loss::TimeProfile,
    opex_var::TimeProfile,
    opex_fixed::TimeProfile,
    energy_share::Float64,
    directions::Int = 1,
    data::Vector{Data} = Data[],
)
    @warn(
        "The used implementation of a `PipeLinepackSimple` will be discontinued in the near future. " *
        "See the documentation for the new implementation in which we no longer utilize " *
        "the keyword constructor.\n" *
        "The only change required is to remove the keywords or alternatively the value for " *
        "directions.",
        maxlog = 1
    )

    tmp = PipeLinepackSimple(
        id,
        inlet,
        outlet,
        consuming,
        consumption_rate,
        trans_cap,
        trans_loss,
        opex_var,
        opex_fixed,
        energy_share,
        data,
    )
    return tmp
end
