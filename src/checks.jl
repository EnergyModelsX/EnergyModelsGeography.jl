
function check_data(case, modeltype)

    𝒜 = case[:areas]
    ℒᵗʳᵃⁿˢ = case[:transmission]
    ℒ = case[:links]
    𝒩 = case[:nodes]
    𝒫 = case[:products]
    𝒯 = case[:T]

    for a ∈ 𝒜
        check_area(a, 𝒩, ℒ, 𝒯, 𝒫, modeltype)
    end
    for l ∈ ℒᵗʳᵃⁿˢ
        check_transmission(l, 𝒩, 𝒯, 𝒫, modeltype)
    end
end


function check_area(a::Area, 𝒩, ℒ, 𝒯, 𝒫, modeltype)
end

function check_transmission(l::Transmission, 𝒩, 𝒯, 𝒫, modeltype)
end
