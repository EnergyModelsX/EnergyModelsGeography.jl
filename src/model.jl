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
    variables_area(m, 𝒜, 𝒯, 𝒫, modeltype)
    variables_transmission(m, 𝒯, ℒᵗʳᵃⁿˢ, modeltype)

    # Construction of constraints for the problem
    constraints_area(m, 𝒜, 𝒯, 𝒫, modeltype)
    constraints_transmission(m, 𝒜, 𝒯, ℒᵗʳᵃⁿˢ, modeltype)

    return m
end


function variables_area(m, 𝒜, 𝒯, 𝒫, modeltype)

    @variable(m, area_import[a ∈ 𝒜, 𝒯, 𝒫] >= 0)
    @variable(m, area_export[a ∈ 𝒜, 𝒯, 𝒫] >= 0)

end

function variables_transmission(m, 𝒯, ℒᵗʳᵃⁿˢ, modeltype)
    @variable(m, trans_in[l ∈ ℒᵗʳᵃⁿˢ,  𝒯, corridor_modes(l)] >= 0)
    @variable(m, trans_out[l ∈ ℒᵗʳᵃⁿˢ, 𝒯, corridor_modes(l)] >= 0)
    @variable(m, trans_cap[l ∈ ℒᵗʳᵃⁿˢ, 𝒯, corridor_modes(l)] >= 0)
    @variable(m, trans_loss[l ∈ ℒᵗʳᵃⁿˢ, 𝒯, corridor_modes(l)] >= 0)
    @variable(m, trans_max[l ∈ ℒᵗʳᵃⁿˢ, 𝒯, corridor_modes(l)] >= 0)

    for l ∈ ℒᵗʳᵃⁿˢ, t ∈ 𝒯, cm ∈ corridor_modes(l)
        @constraint(m, trans_max[l, t, cm] == cm.capacity)
    end
end

function constraints_area(m, 𝒜, 𝒯, 𝒫, modeltype)

    for a ∈ 𝒜
        n = a.an
        @constraint(m, [t ∈ 𝒯, p ∈ 𝒫],
            m[:flow_in][n, t, p] + m[:area_import][a, t, p] == m[:flow_out][n, t, p] +  m[:area_export][a, t, p])
    end

end

function constraints_transmission(m, 𝒜, 𝒯, ℒᵗʳᵃⁿˢ, modeltype)

    for a ∈ 𝒜
        ℒᶠʳᵒᵐ, ℒᵗᵒ = trans_sub(ℒᵗʳᵃⁿˢ, a)
        @constraint(m, [t ∈ 𝒯, p ∈ export_resources(ℒᵗʳᵃⁿˢ, a)], 
            m[:area_export][a, t, p] == sum(sum(m[:trans_in][l, t, cm] for cm in l.modes if cm.resource == p) for l in ℒᶠʳᵒᵐ))
        @constraint(m, [t ∈ 𝒯, p ∈ import_resources(ℒᵗʳᵃⁿˢ, a)], 
            m[:area_import][a, t, p] == sum(sum(m[:trans_out][l, t, cm] for cm in l.modes if cm.resource == p) for l in ℒᵗᵒ ))
    end

    for l in ℒᵗʳᵃⁿˢ
        create_trans(m, 𝒯, l)
    end

end

function create_node(m, n::GeoAvailability, 𝒯, 𝒫)

    # The constratint for balance in an availability node is replaced
    # by an alternative formulation in the geography package 
end

function create_trans(m, 𝒯, l)
	# Generic trans in which each output corresponds to the input
    @constraint(m, [t ∈ 𝒯, cm ∈ corridor_modes(l)],
        m[:trans_out][l, t, cm] == m[:trans_in][l, t, cm] + m[:trans_loss][l, t, cm])

    @constraint(m, [t ∈ 𝒯, cm ∈ corridor_modes(l)],
        m[:trans_out][l, t, cm] <= m[:trans_max][l, t, cm])
end
