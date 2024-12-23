"""
    create_model(case, modeltype::EnergyModel, m::JuMP.Model; check_timeprofiles::Bool=true)

Create the model and call all required functions.

## Input
- `case` - The case dictionary requiring the keys `:T`, `:nodes`, `:links`, `products` as
  it is the case for standard `EnergyModelsBase` models. In addition, the keys `:areas` and
  `:transmission` are required for extending the existing model.
  If the input is not provided in the correct form, the checks will identify the problem.
- `modeltype::EnergyModel` - Used modeltype, that is a subtype of the type `EnergyModel`.
- `m` - the empty `JuMP.Model` instance. If it is not provided, then it is assumed that the
  input is a standard `JuMP.Model`.

## Conditional input
- `check_timeprofiles::Bool=true` - A boolean indicator whether the time profiles of the
  individual nodes should be checked or not. It is advised to not deactivate the check,
  except if you are testing new components. It may lead to unexpected behaviour and
  potential inconsistencies in the input data, if the time profiles are not checked.
- `check_any_data::Bool=true` - A boolean indicator whether the input data is checked or not.
  It is advised to not deactivate the check, except if you are testing new features.
  It may lead to unexpected behaviour and even infeasible models.
"""
function create_model(
    case,
    modeltype::EnergyModel,
    m::JuMP.Model;
    check_timeprofiles::Bool=true,
    check_any_data::Bool = true,
)
    @debug "Construct model"
    # Call of the basic model
    m = EMB.create_model(case, modeltype, m; check_timeprofiles, check_any_data)
    if check_any_data
        check_data(case, modeltype, check_timeprofiles)
    end

    # Data structure
    𝒜 = case[:areas]
    ℒᵗʳᵃⁿˢ = case[:transmission]
    𝒫 = case[:products]
    𝒯 = case[:T]

    # Vector of all `TransmissionMode`s in the corridors
    ℳ = modes(ℒᵗʳᵃⁿˢ)

    # Declaration of variables foir areas and transmission corridors
    variables_area(m, 𝒜, 𝒯, ℒᵗʳᵃⁿˢ, modeltype)
    variables_trans_capex(m, 𝒯, ℳ, modeltype)
    variables_trans_opex(m, 𝒯, ℳ, modeltype)
    variables_trans_capacity(m, 𝒯, ℳ, modeltype)
    variables_trans_modes(m, 𝒯, ℳ, modeltype)
    variables_trans_emission(m, 𝒯, ℳ, 𝒫, modeltype)

    # Construction of constraints for areas and transmission corridors
    constraints_area(m, 𝒜, 𝒯, ℒᵗʳᵃⁿˢ, 𝒫, modeltype)
    constraints_transmission(m, 𝒯, ℳ, modeltype)

    # Updates the global constraint on total emissions
    update_total_emissions(m, 𝒯, ℳ, 𝒫, modeltype)

    # Updates the objective function
    update_objective(m, 𝒯, ℳ, modeltype)

    return m
end
function create_model(
    case,
    modeltype::EnergyModel;
    check_timeprofiles::Bool = true,
    check_any_data::Bool = true,
)
    m = JuMP.Model()
    create_model(case, modeltype, m; check_timeprofiles, check_any_data)
end

"""
    variables_area(m, 𝒜, 𝒯, ℒᵗʳᵃⁿˢ, modeltype::EnergyModel)

Declaration of a variable `:area_exchange` to track how much energy is exchanged from an
area for all operational periods `t ∈ 𝒯`. The variable is only declared for resources that
are exchanged from a given area.
"""
function variables_area(m, 𝒜, 𝒯, ℒᵗʳᵃⁿˢ, modeltype::EnergyModel)
    @variable(m, area_exchange[a ∈ 𝒜, 𝒯, p ∈ exchange_resources(ℒᵗʳᵃⁿˢ, a)])
end

"""
    variables_trans_capex(m, 𝒯, ℳ, modeltype::EnergyModel)

Create variables for the capital costs for the investments in transmission.
Empty function to allow for multiple dispatch in the `EnergyModelsInvestment` package.
"""
function variables_trans_capex(m, 𝒯, ℳ, modeltype::EnergyModel) end

"""
    variables_trans_opex(m, 𝒯, ℳ, modeltype::EnergyModel)

Declaration of variables for the operational costs (`:trans_opex_var` and
`:trans_opex_fixed`) of the tranmission modes.
"""
function variables_trans_opex(m, 𝒯, ℳ, modeltype::EnergyModel)
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)

    @variable(m, trans_opex_var[ℳ, 𝒯ᴵⁿᵛ])
    @variable(m, trans_opex_fixed[ℳ, 𝒯ᴵⁿᵛ] >= 0)
end

"""
    variables_trans_capacity(m, 𝒯, ℳ, modeltype::EnergyModel)

Declaration of variables for tracking how much of installed transmision capacity is used in
all operational periods `t ∈ 𝒯` of the tranmission modes.
"""
function variables_trans_capacity(m, 𝒯, ℳ, modeltype::EnergyModel)

    @variable(m, trans_cap[ℳ, 𝒯] >= 0)
end

"""
    variables_trans_modes(m, 𝒯, ℳ, modeltype::EnergyModel)

Loop through all `TransmissionMode` types and create variables specific to each type.
This is done by calling the method [`variables_trans_mode`](@ref) on all modes of each type.

The `TransmissionMode` type representing the widest category will be called first. That is,
`variables_trans_mode` will be called on a `TransmissionMode` before it is called on
`PipeMode`.
"""
function variables_trans_modes(m, 𝒯, ℳ, modeltype::EnergyModel)

    # Vector of the unique node types in 𝒩.
    mode_composite_types = unique(map(tm -> typeof(tm), ℳ))
    # Get all `TransmissionMode`-types in the type-hierarchy that the transmission modes
    # ℳ represents.
    mode_types = EMB.collect_types(mode_composite_types)
    # Sort the node-types such that a supertype will always come its subtypes.
    mode_types = EMB.sort_types(mode_types)

    for mode_type ∈ mode_types
        # All nodes of the given sub type.
        ℳˢᵘᵇ = filter(tm -> isa(tm, mode_type), ℳ)
        # Convert to a Vector of common-type instad of Any.
        ℳˢᵘᵇ = convert(Vector{mode_type}, ℳˢᵘᵇ)
        try
            variables_trans_mode(m, 𝒯, ℳˢᵘᵇ, modeltype)
        catch e
            if !isa(e, ErrorException)
                @error "Creating variables failed."
            end
            # ℳˢᵘᵇ was already registered by a call to a supertype, so just continue.
        end
    end
end

"""
    variables_trans_mode(m, 𝒯, ℳˢᵘᵇ::Vector{<:TransmissionMode}, modeltype::EnergyModel)

Default fallback method when no function is defined for a [`TransmissionMode`](@ref) type.
It introduces the variables that are required in all `TransmissionMode`s.

These variables are:
* `:trans_in` - inlet flow to transmission mode
* `:trans_out` - outlet flow from a transmission mode
* `:trans_loss` - loss during transmission
* `:trans_loss_neg` - negative loss during transmission, helper variable if bidirectional
  transport is possible
* `:trans_loss_pos` - positive loss during transmission, helper variable if bidirectional
  transport is possible
"""
function variables_trans_mode(m, 𝒯, ℳˢᵘᵇ::Vector{<:TransmissionMode}, modeltype::EnergyModel)

    ℳ2 = modes_of_dir(ℳˢᵘᵇ, 2)

    @variable(m, trans_in[ℳˢᵘᵇ, 𝒯])
    @variable(m, trans_out[ℳˢᵘᵇ, 𝒯])
    @variable(m, trans_loss[ℳˢᵘᵇ, 𝒯] >= 0)
    @variable(m, trans_neg[ℳ2, 𝒯] >= 0)
    @variable(m, trans_pos[ℳ2, 𝒯] >= 0)
end

"""
    variables_trans_mode(m, 𝒯, ℳᴸᴾ::Vector{<:PipeLinepackSimple}, modeltype::EnergyModel)

When the node vector is a `Vector{<:PipeLinepackSimple}`, we declare the variable
`:linepack_stor_level` to account for the energy stored through line packing.
"""
function variables_trans_mode(m, 𝒯, ℳᴸᴾ::Vector{<:PipeLinepackSimple}, modeltype::EnergyModel)

    @variable(m, linepack_stor_level[ℳᴸᴾ, 𝒯] >= 0)
end

"""
    variables_trans_emission(m, 𝒯, ℳ, 𝒫, modeltype)

Declation of variables for the modeling of tranmission emissions. These variables are only
created for transmission modes where emissions are included. All emission resources that are
not included for a type are fixed to a value of 0.

The emission variables are differentiated in:
* `:emissions_trans` - emissions of a transmission mode `tm` in operational period `t`.
"""
function variables_trans_emission(m, 𝒯, ℳ, 𝒫, modeltype)
    ℳᵉᵐ = filter(m -> has_emissions(m), ℳ)
    𝒫ᵉᵐ  = EMB.res_sub(𝒫, ResourceEmit)

    @variable(m, emissions_trans[ℳᵉᵐ, 𝒯, 𝒫ᵉᵐ] >= 0)

    # Fix of unused emission variables to avoid free variables
    for tm ∈ ℳᵉᵐ, t ∈ 𝒯, p_em ∈ setdiff(𝒫ᵉᵐ, emit_resources(tm))
        fix(m[:emissions_trans][tm, t, p_em], 0; force = true)
    end
end

"""
    constraints_area(m, 𝒜, 𝒯, ℒᵗʳᵃⁿˢ, 𝒫, modeltype::EnergyModel)

Function for creating constraints for the energy balances within an area for each resource
using the [`GeoAvailability`](@ref) node. It keeps track of the exchange with other areas
through the variable `:area_exchange` and the functions [`compute_trans_in`](@ref) and
[`compute_trans_out`](@ref).
"""
function constraints_area(m, 𝒜, 𝒯, ℒᵗʳᵃⁿˢ, 𝒫, modeltype::EnergyModel)
    for a ∈ 𝒜
        # Declaration of the required subsets.
        n = availability_node(a)
        𝒫ᵉˣ = exchange_resources(ℒᵗʳᵃⁿˢ, a)

        # Resource balance within an area
        for p ∈ inputs(n)
            if p ∈ 𝒫ᵉˣ
                @constraint(m, [t ∈ 𝒯],
                    m[:flow_in][n, t, p] == m[:flow_out][n, t, p] - m[:area_exchange][a, t, p])
            else
                @constraint(m, [t ∈ 𝒯],
                    m[:flow_in][n, t, p] == m[:flow_out][n, t, p])
            end
        end

        # Keep track of exchange with other areas
        ℒᶠʳᵒᵐ, ℒᵗᵒ = trans_sub(ℒᵗʳᵃⁿˢ, a)
        @constraint(m, [t ∈ 𝒯, p ∈ 𝒫ᵉˣ],
            m[:area_exchange][a, t, p] +
            sum(compute_trans_in(m, t, p, tm) for tm ∈ modes(ℒᶠʳᵒᵐ))
            ==
            sum(compute_trans_out(m, t, p, tm) for tm ∈ modes(ℒᵗᵒ))
        )

        # Limit area exchange
        create_area(m, a, 𝒯, ℒᵗʳᵃⁿˢ, modeltype)
    end
end

"""
    EMB.create_node(m, n::GeoAvailability, 𝒯, 𝒫, modeltype::EnergyModel)

Set all constraints for a [`GeoAvailability`](@ref). The energy balance is handlded in the
function [`constraints_area`](@ref). Hence, no constraints are added
"""
function EMB.create_node(m, n::GeoAvailability, 𝒯, 𝒫, modeltype::EnergyModel) end

"""
    create_area(m, a::Area, 𝒯, ℒᵗʳᵃⁿˢ, modeltype)

Set all constraints for an [`Area`](@ref). Can serve as fallback option for all unspecified
subtypes of `Area`.
"""
function create_area(m, a::Area, 𝒯, ℒᵗʳᵃⁿˢ, modeltype) end

"""
    create_area(m, a::LimitedExchangeArea, 𝒯, ℒᵗʳᵃⁿˢ, modeltype)

When the area is a [`LimitedExchangeArea`](@ref), we limit the export of the specified
limit resources `p` to the providewd value.
"""
function create_area(m, a::LimitedExchangeArea, 𝒯, ℒᵗʳᵃⁿˢ, modeltype)

    ## TODO: Consider adding additional types for import or export exchange limits
    # @constraint(m, [t ∈ 𝒯, p ∈ elimit_resources(a)],
    #     m[:area_exchange][a, t, p] <= exchange_limit(a, p, t)) # Import limit

    @constraint(m, [t ∈ 𝒯, p ∈ limit_resources(a)],
        m[:area_exchange][a, t, p] >= -1 * exchange_limit(a, p, t)) # Export limit

end

"""
    constraints_transmission(m, 𝒯, ℳ, modeltype::EnergyModel)

Create transmission constraints on all transmission corridors.
"""
function constraints_transmission(m, 𝒯, ℳ, modeltype::EnergyModel)

    for tm ∈ ℳ
        create_transmission_mode(m, tm, 𝒯, modeltype)
    end
end

"""
    update_objective(m, 𝒯, ℳ, modeltype::EnergyModel)

Update the objective function with costs related to geography (areas and energy transmission).
"""
function update_objective(m, 𝒯, ℳ, modeltype::EnergyModel)

    # Extraction of data
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)
    obj = objective_function(m)

    # Calculate the OPEX cost contribution
    opex = @expression(m, [t_inv ∈ 𝒯ᴵⁿᵛ],
        sum(m[:trans_opex_var][tm, t_inv] + m[:trans_opex_fixed][tm, t_inv] for tm ∈ ℳ)
    )
    # Update the objective
    @objective(m, Max,
        obj - sum(opex[t_inv] * duration_strat(t_inv) for t_inv ∈ 𝒯ᴵⁿᵛ)
    )
end

"""
    update_total_emissions(m, 𝒯, ℳ, 𝒫, modeltype::EnergyModel)

Update the constraints aggregating total emissions in each operational period with
contributions from transmission emissions.
"""
function update_total_emissions(m, 𝒯, ℳ, 𝒫, modeltype::EnergyModel)
    ℳᵉᵐ = filter(m -> has_emissions(m), ℳ)
    𝒫ᵉᵐ  = EMB.res_sub(𝒫, EMB.ResourceEmit)

    # Modify existing constraints on total emissions by adding contribution from
    # transmission emissions. Note the coefficient is set to -1 since the total constraint
    # has the variables on the RHS.
    for tm ∈ ℳᵉᵐ, p ∈ 𝒫ᵉᵐ, t ∈ 𝒯
        JuMP.set_normalized_coefficient(
            m[:con_em_tot][t, p],
            m[:emissions_trans][tm, t, p],
            -1.0,
        )
    end
end

"""
    create_transmission_mode(m, tm::TransmissionMode, 𝒯, modeltype::EnergyModel)

Set all constraints for a [`TransmissionMode`](@ref).

Serves as a fallback option for unspecified subtypes of `TransmissionMode`.

# Called constraint functions
- [`constraints_trans_balance`](@ref),
- [`constraints_trans_loss`](@ref),
- [`constraints_capacity`](@ref),
- [`constraints_emission`](@ref),
- [`constraints_opex_fixed`](@ref), and
- [`constraints_opex_var`](@ref).
"""
function create_transmission_mode(m, tm::TransmissionMode, 𝒯, modeltype::EnergyModel)

    # Defining the required sets
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)

    # Call of the function for tranmission balance
    # Generic trans in which each output corresponds to the input minus losses
    constraints_trans_balance(m, tm, 𝒯, modeltype)

    # Call of the functions for tranmission losses
    constraints_trans_loss(m, tm, 𝒯, modeltype)

    # Call of the function for limiting the capacity to the maximum installed capacity
    constraints_capacity(m, tm, 𝒯, modeltype)

    # Call of the functions for transmission emissions
    constraints_emission(m, tm, 𝒯, modeltype)

    # Call of the functions for both fixed and variable OPEX constraints introduction
    constraints_opex_fixed(m, tm, 𝒯ᴵⁿᵛ, modeltype)
    constraints_opex_var(m, tm, 𝒯ᴵⁿᵛ, modeltype)
end
