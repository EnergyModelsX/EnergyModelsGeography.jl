# [Update your model to the latest versions](@id how_to-update)

`EnergyModelsGeography` is still in a pre-release version.
Hence, there are frequently breaking changes occuring, although we plan to keep backwards compatibility.
This document is designed to provide users with information regarding how they have to adjust their models to keep compatibility to the latest changes.
We will as well implement information regarding the adjustment of extension packages, although this is more difficult due to the vast majority of potential changes.

## [Adjustments from 0.9.x](@id how_to-update-09)

### [Key changes for transmission mode descriptions](@id how_to-update-06-mode)

Version 0.10 removed the keywrod definition of [`PipeSimple`](@ref) and [`PipeLinepackSimple`](@ref).
A key aim behind this removal is to avoid having to specify the fields if one does not provide a value to the data or the directions field.
THis was solved through

1. an internal constructor only allowing for unidirectional pipelines and
2. an external constructor for cases in which the field `data` is not specified.

Bidirectional transport for pipelines was removed as the model did not support it.
A key factor here is the `consuming` resource which is required for pumping or compression energy demand.
In the case of bidirectional transport, the `consuming` resource is consumed in the `from` region.
In the case of reversed flow, this would lead to undesired behavior.
Previously, warnings were printed.
We consider it to be more consistent with the framework philosophy to remove that potential source of error.

!!! danger "New subtypes for `PipeMode`"
    It is still possible for the user to provide new [`PipeMode`](@ref)s that provide bidirectional transport.
    In this case, it is necessary to provide new methods for [`constraints_capacity`](@ref man-con-cap) and [`constraints_trans_loss`](@ref man-con-trans_loss).
    Otherwise, warnings will be provided and unidirectional transport used.

    The variable OPEX calculation is wrong if you receive the warnings.

The translations below describe the keyword constructor.
You only have to remove the entry to the field of directions.

!!! note "Timeline for constructors"
    The legacy constructors for calls of the composite types of version 0.9 will be included at least until version 0.11.
    However, it is recommended to update your model as soon as possible to the latest version.

### [`PipeSimple`](@ref)

```julia
# The previous description for PipeSimple was given by:
PipeSimple(;
    id::String,
    inlet::EMB.Resource,
    outlet::EMB.Resource,
    consuming::EMB.Resource,
    consumption_rate::TimeProfile,
    trans_cap::TimeProfile,
    trans_loss::TimeProfile,
    opex_var::TimeProfile,
    opex_fixed::TimeProfile,
    directions::Int = 1,            # This value cannot be specified any longer
    data::Vector{Data} = Data[],
)

# This translates to the following new version
 PipeSimple(
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
```

### [`PipeLinepackSimple`](@ref)

```julia
# The previous description for PipeLinepackSimple was given by:
PipeLinepackSimple(;
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
    directions::Int = 1,            # This value cannot be specified any longer
    data::Vector{Data} = Data[],
)

# This translates to the following new version
PipeLinepackSimple(
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
```

## [Adjustments from 0.7.x](@id how_to-update-07)

### [`GeoAvailability`](@ref)

`GeoAvailability` nodes do not require any longer the data for `input` and `output`, as they utilize a constructor, if only a single array is given.

```julia
# The previous nodal description was given by:
GeoAvailability(
    id,
    input::Dict{<:Resource,<:Real},
    output::Dict{<:Resource,<:Real},
)

# This translates to the following new version
GeoAvailability(id, collect(keys(input)), collect(keys(output)))
```
