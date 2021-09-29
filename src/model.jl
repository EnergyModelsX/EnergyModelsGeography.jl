# Construction of the model based on the provided data
function create_model(data, modeltype)
    @debug "Construct model"
    m = EMB.create_model(data, modeltype) # Basic model

    𝒜 = data[:areas]
    ℒᵗʳᵃⁿˢ = data[:transmission]
    𝒫 = data[:products]
    𝒯 = data[:T]
    𝒩 = data[:nodes]
    # Add geo elements

    # Declaration of variables for the problem
    variables_area(m, 𝒜, 𝒯, ℒᵗʳᵃⁿˢ, 𝒫, modeltype)
    variables_transmission(m, 𝒯, ℒᵗʳᵃⁿˢ, modeltype)
    variables_capex_transmission(m, 𝒯, ℒᵗʳᵃⁿˢ, modeltype)

    # Construction of constraints for the problem
    constraints_area(m, 𝒜, 𝒯, ℒᵗʳᵃⁿˢ, 𝒫, modeltype)
    constraints_transmission(m, 𝒜, 𝒯, ℒᵗʳᵃⁿˢ, modeltype)

    update_objective(m, 𝒩, 𝒯, 𝒫, ℒᵗʳᵃⁿˢ, modeltype)
    return m
end

"""
    variables_area(m, 𝒜, 𝒯, ℒᵗʳᵃⁿˢ, 𝒫, modeltype)

Create variables to track how much energy is exchanged from an area for all 
time periods `t ∈ 𝒯`.
"""
function variables_area(m, 𝒜, 𝒯, ℒᵗʳᵃⁿˢ, 𝒫, modeltype)
    @variable(m, area_exchange[a ∈ 𝒜, 𝒯, p ∈ exchange_resources(ℒᵗʳᵃⁿˢ, a)])

end

"""
    variables_transmission(m, 𝒯, ℒᵗʳᵃⁿˢ, modeltype)

Create variables to track how much of installed transmision capacity is used for all 
time periods `t ∈ 𝒯` and how much energy is lossed.
"""
function variables_transmission(m, 𝒯, ℒᵗʳᵃⁿˢ, modeltype)
    @variable(m, trans_in[l ∈ ℒᵗʳᵃⁿˢ,  𝒯, corridor_modes(l)])
    @variable(m, trans_out[l ∈ ℒᵗʳᵃⁿˢ, 𝒯, corridor_modes(l)])
    @variable(m, trans_loss[l ∈ ℒᵗʳᵃⁿˢ, 𝒯, corridor_modes(l)] >= 0)
    @variable(m, trans_cap[l ∈ ℒᵗʳᵃⁿˢ, 𝒯, corridor_modes(l)] >= 0)
    @variable(m, trans_loss_neg[l ∈ ℒᵗʳᵃⁿˢ, 𝒯, modes_of_dir(l, 2)] >= 0)
    @variable(m, trans_loss_pos[l ∈ ℒᵗʳᵃⁿˢ, 𝒯, modes_of_dir(l, 2)] >= 0)

    for l ∈ ℒᵗʳᵃⁿˢ, t ∈ 𝒯, cm ∈ corridor_modes(l)
        @constraint(m, trans_cap[l, t, cm] == cm.Trans_cap)
    end
end

"""
    variables_capex_transmission(m, 𝒯, ℒᵗʳᵃⁿˢ,, modeltype)

Create variables for the capital costs for the investments in transmission.

Empty function to allow for multipled dispatch in the InvestmentModels package
"""
function variables_capex_transmission(m, 𝒯, ℒᵗʳᵃⁿˢ, modeltype)

end

"""
    constraints_area(m, 𝒜, 𝒯, ℒᵗʳᵃⁿˢ, 𝒫, modeltype)

Create constraints for the energy balance of an area using the GeoAvailability node
"""
function constraints_area(m, 𝒜, 𝒯, ℒᵗʳᵃⁿˢ, 𝒫, modeltype)
    for a ∈ 𝒜
        n = a.An
        ex_p = exchange_resources(ℒᵗʳᵃⁿˢ, a)
        for p ∈ 𝒫
            if p in ex_p
                @constraint(m, [t ∈ 𝒯],
                            m[:flow_in][n, t, p] == m[:flow_out][n, t, p] + m[:area_exchange][a, t, p])
            else
                @constraint(m, [t ∈ 𝒯],
                            m[:flow_in][n, t, p] == m[:flow_out][n, t, p])
            end
        end
    end
end

"""
    constraints_transmission(m, 𝒜, 𝒯, ℒᵗʳᵃⁿˢ, modeltype)

Create constraints for the energy balance of an area as a function of energy transmission.
This function could be in theory included in constraints_area.
"""
function constraints_transmission(m, 𝒜, 𝒯, ℒᵗʳᵃⁿˢ, modeltype)

    for a ∈ 𝒜
        ℒᶠʳᵒᵐ, ℒᵗᵒ = trans_sub(ℒᵗʳᵃⁿˢ, a)
        @constraint(m, [t ∈ 𝒯, p ∈ exchange_resources(ℒᵗʳᵃⁿˢ, a)], 
            m[:area_exchange][a, t, p] == sum(sum(m[:trans_in][l, t, cm] for cm in l.Modes if cm.Resource == p) for l in ℒᶠʳᵒᵐ)
                                          - sum(sum(m[:trans_out][l, t, cm] for cm in l.Modes if cm.Resource == p) for l in ℒᵗᵒ ))
    end

    for l in ℒᵗʳᵃⁿˢ
        create_trans(m, 𝒯, l)
    end

end

function update_objective(m, 𝒩, 𝒯, 𝒫, ℒᵗʳᵃⁿˢ, modeltype)
end

function EMB.create_node(m, n::GeoAvailability, 𝒯, 𝒫)

    # The constratint for balance in an availability node is replaced
    # by an alternative formulation in the geography package 
end

function create_trans(m, 𝒯, l)
	# Generic trans in which each output corresponds to the input
    @constraint(m, [t ∈ 𝒯, cm ∈ corridor_modes(l)],
        m[:trans_out][l, t, cm] == m[:trans_in][l, t, cm] - m[:trans_loss][l, t, cm])
    
    @constraint(m, [t ∈ 𝒯, cm ∈ corridor_modes(l)],
        m[:trans_out][l, t, cm] <= m[:trans_cap][l, t, cm])

    for cm in corridor_modes(l)
        # Constraints for unidirectional energy transmission
        if cm.Directions == 1
            @constraint(m, [t ∈ 𝒯],
                m[:trans_loss][l, t, cm] == cm.Trans_loss*m[:trans_in][l, t, cm])

            @constraint(m, [t ∈ 𝒯], m[:trans_out][l, t, cm] >= 0)

        # Constraints for bidirectional energy transmission
        elseif cm.Directions == 2
            # The total loss equals the negative and positive loss
            @constraint(m, [t ∈ 𝒯],
                m[:trans_loss][l, t, cm] == m[:trans_loss_pos][l, t, cm] + m[:trans_loss_neg][l, t, cm])

            @constraint(m, [t ∈ 𝒯],
                m[:trans_loss_pos][l, t, cm] - m[:trans_loss_neg][l, t, cm] == cm.Trans_loss*0.5*(m[:trans_in][l, t, cm] + m[:trans_out][l, t, cm]))
                    
            # @constraint(m, [t ∈ 𝒯],
            #     m[:trans_in][l, t, cm] <= m[:trans_cap][l, t, cm])

            # @constraint(m, [t ∈ 𝒯],
            #     m[:trans_out][l, t, cm] >= -1*m[:trans_cap][l, t, cm])

            @constraint(m, [t ∈ 𝒯],
                m[:trans_in][l, t, cm] >= -1*m[:trans_cap][l, t, cm])
        end
    end
end
