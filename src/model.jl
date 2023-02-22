"""
    create_model(case, modeltype::EnergyModel)

Create the model and call all requried functions based on provided 'modeltype'
and case data.
"""
function create_model(case, modeltype)
    @debug "Construct model"
    # Call of the basic model
    m = EMB.create_model(case, modeltype)

    # WIP Data structure
    𝒜           = case[:areas]
    ℒᵗʳᵃⁿˢ      = case[:transmission]
    𝒫           = case[:products]
    𝒯           = case[:T]
    𝒩           = case[:nodes]
    
    # Vector of all `TransmissionMode`s in the corridors
    𝒞ℳ = corridor_modes(ℒᵗʳᵃⁿˢ)

    # Declaration of variables foir areas and transmission corridors
    variables_area(m, 𝒜, 𝒯, ℒᵗʳᵃⁿˢ, modeltype)
    variables_trans_capex(m, 𝒯, ℒᵗʳᵃⁿˢ, modeltype)
    # variables_trans_opex(m, 𝒯, 𝒞ℳ, modeltype)
    variables_trans_capacity(m, 𝒯, 𝒞ℳ, modeltype)
    variables_trans_modes(m, 𝒯, 𝒞ℳ, modeltype)

    # Construction of constraints for areas and transmission corridors
    constraints_area(m, 𝒜, 𝒯, ℒᵗʳᵃⁿˢ, 𝒫, modeltype)
    constraints_transmission(m, 𝒜, 𝒯, ℒᵗʳᵃⁿˢ, modeltype)

    # Updates the objective function
    update_objective(m, 𝒩, 𝒯, 𝒫, ℒᵗʳᵃⁿˢ, modeltype)

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
function variables_trans_capex(m, 𝒯, ℒᵗʳᵃⁿˢ, modeltype::EnergyModel)

end


"""
    variables_trans_capacity(m, 𝒯, 𝒞ℳ, modeltype)

Create variables to track how much of installed transmision capacity is used for all 
time periods `t ∈ 𝒯`.
"""
function variables_trans_capacity(m, 𝒯, 𝒞ℳ, modeltype)
    
    @variable(m, trans_cap[𝒞ℳ, 𝒯] >= 0)

    for cm ∈ 𝒞ℳ, t ∈ 𝒯
        @constraint(m, trans_cap[cm, t] == cm.Trans_cap[t])
    end
end


"""
    variables_trans_modes(m, 𝒯, 𝒞ℳ, modeltype::EnergyModel)

Loop through all `TransmissionMode` types and create variables specific to each type.
This is done by calling the method [`variables_trans_mode`](@ref) on all modes of each type.

The `TransmissionMode` type representing the widest category will be called first. That is, 
`variables_trans_mode` will be called on a `TransmissionMode` before it is called on `PipeMode`-nodes.
"""
function variables_trans_modes(m, 𝒯, 𝒞ℳ, modeltype::EnergyModel)
    
    # Vector of the unique node types in 𝒩.
    mode_composite_types = unique(map(cm -> typeof(cm), 𝒞ℳ))
    # Get all `Node`-types in the type-hierarchy that the transmission modes 𝒞ℳ represents.
    mode_types = EMB.collect_types(mode_composite_types)
    # Sort the node-types such that a supertype will always come its subtypes.
    mode_types = EMB.sort_types(mode_types)

    for mode_type ∈ mode_types
        # All nodes of the given sub type.
        𝒞ℳˢᵘᵇ = filter(cm -> isa(cm, mode_type), 𝒞ℳ)
        # Convert to a Vector of common-type instad of Any.
        𝒞ℳˢᵘᵇ = convert(Vector{mode_type}, 𝒞ℳˢᵘᵇ)
        try
            variables_trans_mode(m, 𝒯, 𝒞ℳˢᵘᵇ, modeltype)
        catch e
            if !isa(e, ErrorException)
                @error "Creating variables failed."
            end
            # 𝒞ℳˢᵘᵇ was already registered by a call to a supertype, so just continue.
        end
    end
end

""""
    variables_trans_mode(m, 𝒯, 𝒞ℳˢᵘᵇ::Vector{<:TransmissionMode}, modeltype::EnergyModel)

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
function variables_trans_mode(m, 𝒯, 𝒞ℳˢᵘᵇ::Vector{<:TransmissionMode}, modeltype::EnergyModel)
    
    𝒞ℳ2 = modes_of_dir(𝒞ℳˢᵘᵇ, 2)    

    @variable(m, trans_in[𝒞ℳˢᵘᵇ, 𝒯])
    @variable(m, trans_out[𝒞ℳˢᵘᵇ, 𝒯])
    @variable(m, trans_loss[𝒞ℳˢᵘᵇ, 𝒯] >= 0)
    @variable(m, trans_loss_neg[𝒞ℳ2, 𝒯] >= 0)
    @variable(m, trans_loss_pos[𝒞ℳ2, 𝒯] >= 0)
end


""""
    variables_trans_mode(m, 𝒯, 𝒞ℳᴸᴾ::Vector{<:PipeLinepackSimple}, modeltype::EnergyModel)

Adds the following special variables for linepacking:

* `:linepack_flow_in`: This is the characteristic throughput of the linepack storage (not of the entire transmission mode)
* `:linepack_flow_out`: [TBD] this variable is not necessary with current implementation but may be useful for more advanced implementations
* `:linepack_stor_level` - storage level in linepack
* `:linepack_cap_inst` - installed storage capacity == cm_lp.Linepack_cap[t]
* `:linepack_rate_inst` - installed maximum inflow == cm_lp.Linepack_rate_cap[t]
"""
function variables_trans_mode(m, 𝒯, 𝒞ℳᴸᴾ::Vector{<:PipeLinepackSimple}, modeltype::EnergyModel)

    𝒯ᴵⁿᵛ = strategic_periods(𝒯)
  
    # @variable(m, linepack_flow_in[𝒞ℳᴸᴾ, 𝒯] >= 0)
    # @variable(m, linepack_flow_out[𝒞ℳᴸᴾ, 𝒯] >= 0)
    @variable(m, linepack_stor_level[𝒞ℳᴸᴾ, 𝒯] >= 0)
    @variable(m, linepack_cap_inst[𝒞ℳᴸᴾ, 𝒯] >= 0)
    # @variable(m, linepack_rate_inst[𝒞ℳᴸᴾ, 𝒯] >= 0)

    # # Setting up the standard upper bounds on installed capacities:
    # for cm ∈ 𝒞ℳᴸᴾ, t ∈ 𝒯
    #     @constraint(m, linepack_cap_inst[cm, t] == cm.Linepack_cap[t])
    #     @constraint(m, linepack_rate_inst[cm, t] == cm.Linepack_rate_cap[t])
    # end
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
                sum(sum(compute_trans_in(m, l, t, p, cm) for cm in l.Modes) for l in ℒᶠʳᵒᵐ)
                == sum(sum(compute_trans_out(m, l, t, p, cm) for cm in l.Modes) for l in ℒᵗᵒ ))
                
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
        m[:area_exchange][a, t, p] >= -1 * a.ExchangeLimit[p][t]) # Export limit

end


"""
    constraints_transmission(m, 𝒜, 𝒯, ℒᵗʳᵃⁿˢ, modeltype::EnergyModel)

Create transmission constraints on all transmission corridors.
"""
function constraints_transmission(m, 𝒜, 𝒯, ℒᵗʳᵃⁿˢ, modeltype::EnergyModel)

    for l ∈ ℒᵗʳᵃⁿˢ
        create_trans(m, 𝒯, l)
    end
end

"""
    compute_trans_in(m, l, t, p, cm::TransmissionMode)

Return the amount of resources going into transmission corridor l by a generic transmission mode.
"""
function compute_trans_in(m, l, t, p, cm::TransmissionMode)
    exp = 0
    if cm.Resource == p
        exp += m[:trans_in][cm, t]
    end
    return exp
end

"""
    compute_trans_in(m, l, t, p, cm::PipeMode)

Return the amount of resources going into transmission corridor l by a PipeMode transmission mode.
"""
function compute_trans_in(m, l, t, p, cm::PipeMode)
    exp = 0
    if cm.Inlet == p
        exp += m[:trans_in][cm, t]
    end
    if cm.Consuming == p
        exp += m[:trans_in][cm, t] * cm.Consumption_rate[t]
    end
    return exp
end

"""
    compute_trans_out(m, l, t, p, cm::TransmissionMode)

Return the amount of resources going out of transmission corridor l by a generic transmission mode.
"""
function compute_trans_out(m, l, t, p, cm::TransmissionMode)
    exp = 0
    if cm.Resource == p
        exp += m[:trans_out][cm, t]
    end
    return exp
end

"""
    compute_trans_out(m, l, t, p, cm::PipeMode)

Return the amount of resources going out of transmission corridor l by a PipeMode transmission mode.
"""
function compute_trans_out(m, l, t, p, cm::PipeMode)
    exp = 0
    if cm.Outlet == p
        exp += m[:trans_out][cm, t]
    end
    return exp
end

"""
    update_objective(m, 𝒩, 𝒯, 𝒫, ℒᵗʳᵃⁿˢ, modeltype::EnergyModel)

Update the objective function with costs related to geography (areas and energy transmission).
"""
function update_objective(m, 𝒩, 𝒯, 𝒫, ℒᵗʳᵃⁿˢ, modeltype::EnergyModel)
end

"""
    create_trans(m, 𝒯, l)

Set transmission mode constraints for all modes on transmission corridor l. 
"""
function create_trans(m, 𝒯, l)
    for cm in l.Modes
        create_transmission_mode(m, 𝒯, l, cm)
    end
end

"""
    create_transmission_mode(m, 𝒯, l, cm)

Set all constraints for transmission mode. Serves as a fallback option for unspecified subtypes of `TransmissionMode`.
"""
function create_transmission_mode(m, 𝒯, l, cm)

    # Generic trans in which each output corresponds to the input
    @constraint(m, [t ∈ 𝒯],
        m[:trans_out][cm, t] == m[:trans_in][cm, t] - m[:trans_loss][cm, t])
    
    @constraint(m, [t ∈ 𝒯],
        m[:trans_out][cm, t] <= m[:trans_cap][cm, t])

    # Constraints for unidirectional energy transmission
    if cm.Directions == 1
        @constraint(m, [t ∈ 𝒯],
            m[:trans_loss][cm, t] == cm.Trans_loss[t] * m[:trans_in][cm, t])

        @constraint(m, [t ∈ 𝒯], m[:trans_out][cm, t] >= 0)

    # Constraints for bidirectional energy transmission
    elseif cm.Directions == 2
        # The total loss equals the negative and positive loss
        @constraint(m, [t ∈ 𝒯],
            m[:trans_loss][cm, t] == m[:trans_loss_pos][cm, t] + m[:trans_loss_neg][cm, t])

        @constraint(m, [t ∈ 𝒯],
            m[:trans_loss_pos][cm, t] - m[:trans_loss_neg][cm, t] == cm.Trans_loss[t] * 0.5 * (m[:trans_in][cm, t] + m[:trans_out][cm, t]))

        @constraint(m, [t ∈ 𝒯],
            m[:trans_in][cm, t] >= -1 * m[:trans_cap][cm, t])

        """Alternative constraints in the case of defining the capacity via the inlet.
        To be switched in the case of a different definition"""
        # @constraint(m, [t ∈ 𝒯],
        #     m[:trans_in][cm, t] <= m[:trans_cap][cm, t])

        # @constraint(m, [t ∈ 𝒯],
        #     m[:trans_out][cm, t] >= -1*m[:trans_cap][cm, t])
    end
end

"""
    create_transmission_mode(m, 𝒯, l, cm::PipeMode)

Set all constraints for transmission mode of type `PipeMode`.
"""
function create_transmission_mode(m, 𝒯, l, cm::PipeMode)

    # Generic trans in which each output corresponds to the input
    @constraint(m, [t ∈ 𝒯],
        m[:trans_out][cm, t] == m[:trans_in][cm, t] - m[:trans_loss][cm, t])
    
    @constraint(m, [t ∈ 𝒯],
        m[:trans_out][cm, t] <= m[:trans_cap][cm, t])

    # Constraints for unidirectional energy transmission
    if cm.Directions == 1
        @constraint(m, [t ∈ 𝒯],
            m[:trans_loss][cm, t] == cm.Trans_loss[t] * m[:trans_in][cm, t])

        @constraint(m, [t ∈ 𝒯], m[:trans_out][cm, t] >= 0)
    end
end


"""
    create_transmission_mode(m, 𝒯, l, cm::PipeLinepackSimple)

Method to set constraints for `PipeLinepackSimple` transmission mode. Only implements basic linepack
as simple_storage.
`linepack_flow_in[cm, t]` taken as the characteristic flow for the opex calculations. 
[WIP]: Need to modify the update objective, objective variable? 
"""
function create_transmission_mode(m, 𝒯, l, cm::PipeLinepackSimple)
    # Defining the required sets
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)

    # First set flow into the line pack. Transmission loss is assumed to occur prior to linepack.
    #@constraint(m, [t ∈ 𝒯],
    #    m[:linepack_flow_in][cm, t] == m[:trans_in][cm, t] - m[:trans_loss][cm, t])

    # Flow rate constraints on storage flows
    @constraint(m, [t ∈ 𝒯],
        m[:trans_in][cm, t] - m[:trans_loss][cm, t] <= m[:trans_cap][cm, t])


    @constraint(m, [t ∈ 𝒯],
        m[:trans_out][cm, t] <= m[:trans_cap][cm, t])

    @constraint(m, [t ∈ 𝒯],
        m[:linepack_cap_inst][cm, t] == cm.Linepack_energy_share * m[:trans_cap][cm, t])

    #@constraint(m, [t ∈ 𝒯],
    #    m[:linepack_flow_out][cm, t] <= m[:linepack_rate_inst][cm, t])

    # Constraints for unidirectional energy transmission.
    if cm.Directions == 1
        @constraint(m, [t ∈ 𝒯],
            m[:trans_loss][cm, t] == cm.Trans_loss[t] * m[:trans_in][cm, t])

        @constraint(m, [t ∈ 𝒯], m[:trans_out][cm, t] >= 0)
        @constraint(m, [t ∈ 𝒯], m[:trans_in][cm, t] >= 0)

        for t_inv ∈ 𝒯ᴵⁿᵛ, t ∈ t_inv
            # Periodicity constraint
            if t == first_operational(t_inv)
                @constraint(m, m[:linepack_stor_level][cm, t] == 
                    m[:linepack_stor_level][cm, last_operational(t_inv)] +
                    (m[:trans_in][cm, t] - m[:trans_loss][cm, t] - m[:trans_out][cm, t])
                )
            else # From one operational period to next.
                @constraint(m, m[:linepack_stor_level][cm, t] == 
                    m[:linepack_stor_level][cm, previous(t, 𝒯)] +
                    (m[:trans_in][cm, t] - m[:trans_loss][cm, t] - m[:trans_out][cm, t])
                )
            end
        end

        # Constraints for bidirectional energy transmission
    elseif cm.Directions == 2
        @warn "Only one-directional flow implemented for linepacking."
    end

    # Linking the linepack to the transmission model
    #@constraint(m, [t ∈ 𝒯],
    #    m[:trans_out][cm, t] == m[:linepack_flow_out][cm, t])

    # Lastly, flow out of the pipeline is capped. Same as parent. 
    @constraint(m, [t ∈ 𝒯],
        m[:trans_out][cm, t] <= m[:trans_cap][cm, t])

    @constraint(m,  [t ∈ 𝒯],
        m[:linepack_stor_level][cm, t] <= m[:linepack_cap_inst][cm, t])

    # Constraint for the Opex contributions
    #@constraint(m, [t_inv ∈ 𝒯ᴵⁿᵛ],
    #    m[:linepack_opex_var][cm, t_inv] == sum((m[:linepack_flow_in][cm, t] * cm.Linepack_opex_var[t]) for t ∈ t_inv))

    # QN: For fixed opex, scale from `linepack_cap_inst` or `linepack_rate_inst`?
    #@constraint(m, [t_inv ∈ 𝒯ᴵⁿᵛ],
    #    m[:linepack_opex_fixed][cm, t_inv] == sum(m[:linepack_rate_inst][cm, t] * cm.Linepack_opex_fixed[t] for t ∈ t_inv))
end