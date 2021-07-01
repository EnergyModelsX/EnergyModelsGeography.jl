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
    variables_area(m, nodes, T, products, links, modeltype)
    variables_transmission(m, 𝒜, 𝒯, 𝒫, ℒᵗʳᵃⁿˢ, modeltype)

    # Construction of constraints for the problem
    constraints_area(m, nodes, T, products, links, modeltype)
    constraints_transmission(m, 𝒜, 𝒯, 𝒫, ℒᵗʳᵃⁿˢ, modeltype)

    return m
end


function variables_area(m, 𝒩, 𝒯, 𝒫, ℒ, modeltype)


end

function trans_res(l::Transmission)
    return intersect(keys(l.to.an.input), keys(l.from.an.output))
end

function variables_transmission(m, 𝒜, 𝒯, 𝒫, ℒᵗʳᵃⁿˢ, modeltype)
    @variable(m, trans_in[l ∈ ℒᵗʳᵃⁿˢ,  𝒯, trans_res(l)] >= 0)
    @variable(m, trans_out[l ∈ ℒᵗʳᵃⁿˢ, 𝒯, trans_res(l)] >= 0)

end

function constraints_area(m, 𝒩, 𝒯, 𝒫, ℒ, modeltype)


end

function trans_sub(ℒ, a::Area)
    return [ℒ[findall(x -> x.from == a, ℒ)],
            ℒ[findall(x -> x.to   == a, ℒ)]]
end

function constraints_transmission(m, 𝒜, 𝒯, 𝒫, ℒᵗʳᵃⁿˢ, modeltype)

    for a ∈ 𝒜
        n = a.an
        ℒᶠʳᵒᵐ, ℒᵗᵒ = trans_sub(ℒᵗʳᵃⁿˢ, a)
        @constraint(m, [t ∈ 𝒯, p ∈ keys(n.output)], 
            m[:flow_out][n, t, p] == sum(m[:trans_in][l,t,p] for l in ℒᶠʳᵒᵐ if p ∈ keys(l.to.an.input)))
        @constraint(m, [t ∈ 𝒯, p ∈ keys(n.input)], 
            m[:flow_in][n, t, p] == sum(m[:trans_out][l,t,p] for l in ℒᵗᵒ if p ∈ keys(l.from.an.output)))

        #create_node(m, n, 𝒯, 𝒫)
    end

end

