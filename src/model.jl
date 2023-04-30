"""
    create_model(case, modeltype::EnergyModel)

Create the model and call all requried functions based on provided 'modeltype'
and case data.
"""
function create_model(case, modeltype)
    @debug "Construct model"
    # Call of the basic model
    m = EMB.create_model(case, modeltype)
    check_data(case, modeltype)

    # Data structure
    𝒜 = case[:areas]
    ℒᵗʳᵃⁿˢ = case[:transmission]
    𝒫 = case[:products]
    𝒯 = case[:T]

    # Vector of all `TransmissionMode`s in the corridors
    ℳ = corridor_modes(ℒᵗʳᵃⁿˢ)

    # Declaration of variables foir areas and transmission corridors
    variables_area(m, 𝒜, 𝒯, ℒᵗʳᵃⁿˢ, modeltype)
    variables_trans_capex(m, 𝒯, ℳ, modeltype)
    variables_trans_opex(m, 𝒯, ℳ, modeltype)
    variables_trans_capacity(m, 𝒯, ℳ, modeltype)
    variables_trans_modes(m, 𝒯, ℳ, modeltype)

    # Construction of constraints for areas and transmission corridors
    constraints_area(m, 𝒜, 𝒯, ℒᵗʳᵃⁿˢ, 𝒫, modeltype)
    constraints_transmission(m, 𝒯, ℳ, modeltype)

    # Updates the objective function
    update_objective(m, 𝒯, ℳ, modeltype)

    return m
end


"""
    variables_area(m, 𝒜, 𝒯, ℒᵗʳᵃⁿˢ, modeltype::EnergyModel)

Create variables to track how much energy is exchanged from an area for all 
time periods `t ∈ 𝒯`.
"""
function variables_area(m, 𝒜, 𝒯, ℒᵗʳᵃⁿˢ, modeltype::EnergyModel)
    @variable(m, area_exchange[a ∈ 𝒜, 𝒯, p ∈ exchange_resources(ℒᵗʳᵃⁿˢ, a)])

end


"""
    variables_trans_capex(m, 𝒯, ℒᵗʳᵃⁿˢ, modeltype)

Create variables for the capital costs for the investments in transmission.
Empty function to allow for multiple dispatch in the `EnergyModelsInvestment` package.
"""
function variables_trans_capex(m, 𝒯, ℳ, modeltype::EnergyModel)

end

"""
    variables_trans_opex(m, 𝒯, ℒᵗʳᵃⁿˢ, modeltype)

Create variables for the operational costs for the investments in transmission.
"""
function variables_trans_opex(m, 𝒯, ℳ, modeltype::EnergyModel)

    𝒯ᴵⁿᵛ = strategic_periods(𝒯)

    @variable(m, trans_opex_var[ℳ, 𝒯ᴵⁿᵛ])
    @variable(m, trans_opex_fixed[ℳ, 𝒯ᴵⁿᵛ] >= 0)
end

"""
    variables_trans_capacity(m, 𝒯, ℳ, modeltype)

Create variables to track how much of installed transmision capacity is used for all 
time periods `t ∈ 𝒯`.
"""
function variables_trans_capacity(m, 𝒯, ℳ, modeltype)

    𝒯ᴵⁿᵛ = strategic_periods(𝒯)
    𝒯ᴵⁿᵛ

    @variable(m, trans_cap[ℳ, 𝒯] >= 0)

    for tm ∈ ℳ, t ∈ 𝒯
        @constraint(m, trans_cap[tm, t] == tm.Trans_cap[t])
    end
end


"""
    variables_trans_modes(m, 𝒯, ℳ, modeltype::EnergyModel)

Loop through all `TransmissionMode` types and create variables specific to each type.
This is done by calling the method [`variables_trans_mode`](@ref) on all modes of each type.

The `TransmissionMode` type representing the widest category will be called first. That is, 
`variables_trans_mode` will be called on a `TransmissionMode` before it is called on `PipeMode`-nodes.
"""
function variables_trans_modes(m, 𝒯, ℳ, modeltype::EnergyModel)

    # Vector of the unique node types in 𝒩.
    mode_composite_types = unique(map(tm -> typeof(tm), ℳ))
    # Get all `Node`-types in the type-hierarchy that the transmission modes ℳ represents.
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

""""
    variables_trans_mode(m, 𝒯, ℳˢᵘᵇ::Vector{<:TransmissionMode}, modeltype::EnergyModel)

Default fallback method when no function is defined for a `TransmissionMode` type.
It introduces the variables that are required in all `TransmissionMode`s. These variables
are:

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


""""
    variables_trans_mode(m, 𝒯, ℳᴸᴾ::Vector{<:PipeLinepackSimple}, modeltype::EnergyModel)

Adds the following special variables for linepacking:

* `:linepack_flow_in`: This is the characteristic throughput of the linepack storage (not of the entire transmission mode)
* `:linepack_flow_out`: [TBD] this variable is not necessary with current implementation but may be useful for more advanced implementations
* `:linepack_stor_level` - storage level in linepack
* `:linepack_cap_inst` - installed storage capacity == cm_lp.Linepack_cap[t]
* `:linepack_rate_inst` - installed maximum inflow == cm_lp.Linepack_rate_cap[t]
"""
function variables_trans_mode(m, 𝒯, ℳᴸᴾ::Vector{<:PipeLinepackSimple}, modeltype::EnergyModel)

    𝒯ᴵⁿᵛ = strategic_periods(𝒯)
    @variable(m, linepack_stor_level[ℳᴸᴾ, 𝒯] >= 0)

end


"""
    constraints_area(m, 𝒜, 𝒯, ℒᵗʳᵃⁿˢ, 𝒫, modeltype::EnergyModel)

Create constraints for the energy balances within an area for each resource using the GeoAvailability node.
Keep track of the exchange with other areas in a seperate variable `:area_exchange`.
"""
function constraints_area(m, 𝒜, 𝒯, ℒᵗʳᵃⁿˢ, 𝒫, modeltype::EnergyModel)
    for a ∈ 𝒜
        # Resource balance within an area
        n = a.An
        ex_p = exchange_resources(ℒᵗʳᵃⁿˢ, a)
        for p ∈ 𝒫
            if p ∈ ex_p
                @constraint(m, [t ∈ 𝒯],
                    m[:flow_in][n, t, p] == m[:flow_out][n, t, p] - m[:area_exchange][a, t, p])
            else
                @constraint(m, [t ∈ 𝒯],
                    m[:flow_in][n, t, p] == m[:flow_out][n, t, p])
            end
        end

        # Keep track of exchange with other areas
        ℒᶠʳᵒᵐ, ℒᵗᵒ = trans_sub(ℒᵗʳᵃⁿˢ, a)
        @constraint(m, [t ∈ 𝒯, p ∈ exchange_resources(ℒᵗʳᵃⁿˢ, a)],
            m[:area_exchange][a, t, p] +
            sum(sum(compute_trans_in(m, t, p, tm) for tm in l.Modes) for l in ℒᶠʳᵒᵐ)
            ==
            sum(sum(compute_trans_out(m, t, p, tm) for tm in l.Modes) for l in ℒᵗᵒ))

        # Limit area exchange
        create_area(m, a, 𝒯, ℒᵗʳᵃⁿˢ, modeltype)
    end
end

"""
    EMB.create_node(m, n::GeoAvailability, 𝒯, 𝒫, modeltype::EnergyModel)

Repaces constraints for availability nodes of type GeoAvailability.
The resource balances are set by the area constraints instead.
"""
function EMB.create_node(m, n::GeoAvailability, 𝒯, 𝒫, modeltype::EnergyModel)

end


"""
    create_area(m, a::Area, 𝒯, ℒᵗʳᵃⁿˢ, modeltype)

Default fallback method when no function is defined for a node type.
"""
function create_area(m, a::Area, 𝒯, ℒᵗʳᵃⁿˢ, modeltype)

end

"""
    create_area(m, a::LimitedExchangeArea, 𝒯, ℒᵗʳᵃⁿˢ, modeltype)

Constraint that limit exchange with other areas based on ExchangeLimit.
"""
function create_area(m, a::LimitedExchangeArea, 𝒯, ℒᵗʳᵃⁿˢ, modeltype)
    # n = a.An
    #@constraint(m, [t ∈ 𝒯, p ∈ exchange_resources(ℒᵗʳᵃⁿˢ, a)],
    #    m[:area_exchange][a, t, p] <= a.ExchangeLimit[p]) # Import limit

    @constraint(m, [t ∈ 𝒯, p ∈ exchange_resources(ℒᵗʳᵃⁿˢ, a)],
        m[:area_exchange][a, t, p] >= -1 * a.Exchange_limit[p][t]) # Export limit

end


"""
    constraints_transmission(m, 𝒯, ℳ, modeltype::EnergyModel)

Create transmission constraints on all transmission corridors.
"""
function constraints_transmission(m, 𝒯, ℳ, modeltype::EnergyModel)

    for tm ∈ ℳ
        create_transmission_mode(m, tm, 𝒯)
    end
end


"""
    update_objective(m, 𝒩, 𝒯, 𝒫, ℒᵗʳᵃⁿˢ, modeltype::EnergyModel)

Update the objective function with costs related to geography (areas and energy transmission).
"""
function update_objective(m, 𝒯, ℳ, modeltype::EnergyModel)

    # Extraction of data
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)
    obj = JuMP.objective_function(m)

    # Update of the cost function for modes with investments
    for t_inv ∈ 𝒯ᴵⁿᵛ, tm ∈ ℳ
        obj -= t_inv.duration * m[:trans_opex_fixed][tm, t_inv]
        obj -= t_inv.duration * m[:trans_opex_var][tm, t_inv]
    end

    @objective(m, Max, obj)
end


"""
    create_transmission_mode(m, 𝒯, tm)

Set all constraints for transmission mode. Serves as a fallback option for unspecified subtypes of `TransmissionMode`.
"""
function create_transmission_mode(m, tm::TransmissionMode, 𝒯)


    # Defining the required sets
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)

    # Call of the function for tranmission balance
    # Generic trans in which each output corresponds to the input minus losses
    constraints_trans_balance(m, tm, 𝒯)

    # Call of the functions for tranmission losses
    constraints_trans_loss(m, tm, 𝒯)

    # Call of the function for limiting the capacity to the maximum installed capacity
    constraints_capacity(m, tm, 𝒯)

    # Call of the functions for both fixed and variable OPEX constraints introduction
    constraints_opex_fixed(m, tm, 𝒯ᴵⁿᵛ)
    constraints_opex_var(m, tm, 𝒯ᴵⁿᵛ)
end