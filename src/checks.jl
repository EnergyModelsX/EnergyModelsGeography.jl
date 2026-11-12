
"""
    EMB.check_elements(log_by_element, 𝒜::Vector{<:Area}, 𝒳ᵛᵉᶜ, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)
    EMB.check_elements(log_by_element, ℒᵗʳᵃⁿˢ::Vector{<:Transmission}, 𝒳ᵛᵉᶜ, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)

!!! note "Area methods"
    All areas are checked through the functions
    - [`check_area`](@ref) to identify problematic input,
    - [`check_time_structure`](@extref EnergyModelsBase.check_time_structure) to identify
      time profiles at the highest level that are not equivalent to the provided timestructure.

    In addition, all areas are directly checked
    - that the node returned by the function [`availability_node`](@ref) is within the Node
      vector,
    - that the availability node is a [`GeoAvailability`](@ref) node, and
    - that the exchange resources are within the resources of the
      [`GeoAvailability`](@ref) node.

!!! note "Transmission methods"
    All transmission corridors are checked through the functions
    - [`check_transmission`](@ref) to identify problematic input,
    - [`check_time_structure`](@extref EnergyModelsBase.check_time_structure) to identify
      time profiles at the highest level that are not equivalent to the provided timestructure.

    The individual transmission modes of a corridor are checked through the functions
    - [`check_mode`](@ref) to identify problematic input and
    - [`check_time_structure`](@extref EnergyModelsBase.check_time_structure) to identify
      time profiles at the highest level that are not equivalent to the provided timestructure.

    In addition, all transmission corridors are directly checked that the areas in the
    fields `:from` and `:to` are present in the Area vector as extracted through the
    function [`get_areas`](@ref).
"""
function EMB.check_elements(
    log_by_element,
    𝒜::Vector{<:Area},
    𝒳ᵛᵉᶜ,
    𝒯,
    modeltype::EnergyModel,
    check_timeprofiles::Bool
)
    # Extract the required subsets
    𝒩  = get_nodes(𝒳ᵛᵉᶜ)
    ℒᵗʳᵃⁿˢ = get_transmissions(𝒳ᵛᵉᶜ)

    for a ∈ 𝒜
        # Empty the logs list before each check.
        global EMB.logs = []

        # Check the availability node of the area
        av = availability_node(a)
        @assert_or_log(
            av ∈ 𝒩,
            "The node accessed through the function `availability_node` is not included in " *
            "the Node vector. As a consequence, the area would not be utilized in the model."
        )
        @assert_or_log(
            isa(av, GeoAvailability),
            "The node accessed through the function `availability_node` is not a `GeoAvailability` " *
            "node. As a consequence, the area cannot exchange resources with other areas."
        )
        for p ∈ exchange_resources(ℒᵗʳᵃⁿˢ, a)
            @assert_or_log(
                p ∈ inputs(av) && p ∈ outputs(av),
                "The exchange resource `$(p)` is not included in inputs or outputs resources of " *
                "the `GeoAvailability` node resulting in an error in model construction."
            )
        end

        # Check the area and the time structure
        check_area(a, 𝒯, modeltype, check_timeprofiles)
        check_timeprofiles && EMB.check_time_structure(a, 𝒯)
        # Put all log messages that emerged during the check, in a dictionary with the area as key.
        log_by_element[a] = EMB.logs
    end
end
function EMB.check_elements(
    log_by_element,
    ℒᵗʳᵃⁿˢ::Vector{<:Transmission},
    𝒳ᵛᵉᶜ,
    𝒯,
    modeltype::EnergyModel,
    check_timeprofiles::Bool
)
    # Extract the required subsets
    𝒜 = get_areas(𝒳ᵛᵉᶜ)

    for l ∈ ℒᵗʳᵃⁿˢ
        # Empty the logs list before each check.
        global EMB.logs = []

        # Check the connections of the transmission corridor
        @assert_or_log(
            l.from ∈ 𝒜,
            "The area in the field `:from` is not included in the Area vector. As a consequence, " *
            "the transmission corridor would not be utilized in the model."
        )
        @assert_or_log(
            l.to ∈ 𝒜,
            "The area in the field `:to` is not included in the Area vector. As a consequence, " *
            "the transmission corridor would not be utilized in the model."
        )

        # Check the transmission corridor and the time structure
        check_transmission(l, 𝒯, modeltype, check_timeprofiles)
        check_timeprofiles && EMB.check_time_structure(l, 𝒯)

        # Check all individual transmission modes
        ℳ = modes(l)
        for tm ∈ ℳ
            check_mode(tm, 𝒯, modeltype, check_timeprofiles)
            check_timeprofiles && EMB.check_time_structure(tm, 𝒯)
        end

        # Put all log messages that emerged during the check, in a dictionary with the
        # transmission corridor as key.
        log_by_element[l] = EMB.logs
    end
end

"""
    check_area(a::Area, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)

Check that the fields of an `Area` correspond to the required structure.
"""
function check_area(a::Area, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)
end

"""
    check_transmission(l::Transmission, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)

Check that the fields of a `Transmission` corridor correspond to the required structure.
"""
function check_transmission(l::Transmission, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)
end


"""
    check_mode(tm::TransmissionMode, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)
    check_mode(tm::Union{RefDynamic, RefStatic}, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)
    check_mode(tm::PipeSimple, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)
    check_mode(tm::PipeLinepackSimple, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)

Check that the fields of a `TransmissionMode` correspond to the required structure.

## Checks [`RefDynamic`](@ref) and [`RefStatic`](@ref)
- The field `trans_cap` is required to be non-negative.
- The field `trans_loss` is required to be in the range ``[0, 1]``.
- The field `opex_fixed` is required to be non-negative and accessible through a
  `StrategicPeriod` as outlined in the function
  [`check_fixed_opex`](@extref EnergyModelsBase.check_fixed_opex).
- The field `directions` must be 1 or 2.

## Checks [`PipeSimple`](@ref)
- All checks included in the subroutine [`check_mode_default`](@ref).

## Checks [`PipeLinepackSimple`](@ref)
- All checks included in the subroutine [`check_mode_default`](@ref).
- The field `energy_share` is required to be non-negative.
"""
function check_mode(tm::TransmissionMode, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)
end
function check_mode(
    tm::Union{RefDynamic, RefStatic},
    𝒯,
    modeltype::EnergyModel,
    check_timeprofiles::Bool,
)
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)

    @assert_or_log(
        all(capacity(tm, t) ≥ 0 for t ∈ 𝒯),
        repr(tm) * ": The field `trans_cap` must be non-negative."
    )
    @assert_or_log(
        all(loss(tm, t) ≤ 1 for t ∈ 𝒯),
        repr(tm) * ": The field `trans_loss` must be less than or equal to 1."
    )
    @assert_or_log(
        all(loss(tm, t) ≥ 0 for t ∈ 𝒯),
        repr(tm) * ": The field `trans_loss` must be non-negative."
    )
    @assert_or_log(
        1 ≤ directions(tm) ≤ 2,
        repr(tm) * ": The field `directions` can only be 1 or 2."
    )
    EMB.check_fixed_opex(tm, 𝒯ᴵⁿᵛ, check_timeprofiles)
end
check_mode(tm::PipeSimple, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool) =
    check_mode_default(tm, 𝒯, modeltype, check_timeprofiles)

function check_mode(
    tm::PipeLinepackSimple,
    𝒯,
    modeltype::EnergyModel,
    check_timeprofiles::Bool,
)
    check_mode_default(tm, 𝒯, modeltype, check_timeprofiles)
    @assert_or_log(
        energy_share(tm) ≥ 0,
        repr(tm) * ": The field `energy_share` must be non-negative."
    )
end

"""
    check_mode_default(tm::PipeMode, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)

Subroutine that can be utilized in other packages for incorporating the standard tests for
a [`PipeMode`](@ref).

## Checks
- The field `consumption_rate` is required to be non-negative.
- The field `trans_cap` is required to be non-negative.
- The field `trans_loss` is required to be in the range ``[0, 1]``.
- The field `opex_fixed` is required to be non-negative and accessible through a
  `StrategicPeriod` as outlined in the function
  [`check_fixed_opex`](@extref EnergyModelsBase.check_fixed_opex).
"""
function check_mode_default(tm::PipeMode, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)

    @assert_or_log(
        all(consumption_rate(tm, t) ≥ 0 for t ∈ 𝒯),
        repr(tm) * ": The field `consumption_rate` must be non-negative."
    )
    @assert_or_log(
        all(capacity(tm, t) ≥ 0 for t ∈ 𝒯),
        repr(tm) * ": The field `trans_cap` must be non-negative."
    )
    @assert_or_log(
        all(loss(tm, t) ≤ 1 for t ∈ 𝒯),
        repr(tm) * ": The field `trans_loss` must be less than or equal to 1."
    )
    @assert_or_log(
        all(loss(tm, t) ≥ 0 for t ∈ 𝒯),
        repr(tm) * ": The field `trans_loss` must be non-negative."
    )
    EMB.check_fixed_opex(tm, 𝒯ᴵⁿᵛ, check_timeprofiles)
end

"""
    EMB.check_time_structure(tm::TransmissionMode, 𝒯)

Check that all fields of a `TransmissionMode` that are of type `TimeProfile` correspond to
the time structure `𝒯`.
"""
function EMB.check_time_structure(tm::TransmissionMode, 𝒯)
    for fieldname ∈ fieldnames(typeof(tm))
        value = getfield(tm, fieldname)
        if isa(value, TimeProfile)
            EMB.check_profile(fieldname, value, 𝒯)
        end
    end
end
