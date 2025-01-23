"""
    EMB.objective_invest(
        m,
        ℒᵗʳᵃⁿˢ::Vector{Transmission},
        𝒯ᴵⁿᵛ::TS.AbstractStratPers,
        modeltype::AbstractInvestmentModel,
    )

Create a JuMP expression indexed over the investment periods `𝒯ᴵⁿᵛ` for the capital expenditures
contribution of the [`TransmissionMode`](@ref)s within the [`Transmission`](@ref) corridors.
They are not discounted and do not take the duration of the investment periods into account.

The expression includes the sum of the capital expenditures for all [`TransmissionMode`](@ref)s
within the [`Transmission`](@ref) corridors whose method of the function
[`has_investment`](@extref EnergyModelsBase.has_investment) returns true.
"""
function EMB.objective_invest(
    m,
    ℒᵗʳᵃⁿˢ::Vector{Transmission},
    𝒯ᴵⁿᵛ::TS.AbstractStratPers,
    modeltype::AbstractInvestmentModel,
)
    # Declaration of the required subsets
    ℳ = modes(ℒᵗʳᵃⁿˢ)
    ℳᴵⁿᵛ = filter(has_investment, ℳ)

    return @expression(m, [t_inv ∈ 𝒯ᴵⁿᵛ],
        sum(m[:trans_cap_capex][tm, t_inv] for tm ∈ ℳᴵⁿᵛ)
    )
end

"""
    EMB.variables_capex(m, ℒᵗʳᵃⁿˢ::Vector{Transmission}, 𝒳, 𝒯, modeltype::AbstractInvestmentModel)

Create variables for the capital costs for the investments in transmission.

Additional variables for investment in capacity:
* `:trans_cap_capex` - CAPEX costs for increases in the capacity of a transmission mode
* `:trans_cap_current` - installed capacity for storage in each strategic period
* `:trans_cap_add` - added capacity
* `:trans_cap_rem` - removed capacity
* `:trans_cap_invest_b` - binary variable whether investments in capacity are happening
* `:trans_cap_remove_b` - binary variable whether investments in capacity are removed
"""
function EMB.variables_capex(m, ℒᵗʳᵃⁿˢ::Vector{Transmission}, 𝒳, 𝒯, modeltype::AbstractInvestmentModel)
    # Declaration of the required subsets
    ℳ = modes(ℒᵗʳᵃⁿˢ)
    ℳᴵⁿᵛ = filter(has_investment, ℳ)
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)

    # Add transmission specific investment variables for each strategic period:
    @variable(m, trans_cap_capex[ℳᴵⁿᵛ,  𝒯ᴵⁿᵛ] >= 0)
    @variable(m, trans_cap_current[ℳᴵⁿᵛ, 𝒯ᴵⁿᵛ] >= 0)
    @variable(m, trans_cap_add[ℳᴵⁿᵛ, 𝒯ᴵⁿᵛ] >= 0)
    @variable(m, trans_cap_rem[ℳᴵⁿᵛ, 𝒯ᴵⁿᵛ] >= 0)
    @variable(m, trans_cap_invest_b[ℳᴵⁿᵛ, 𝒯ᴵⁿᵛ]; container=IndexedVarArray)
    @variable(m, trans_cap_remove_b[ℳᴵⁿᵛ, 𝒯ᴵⁿᵛ]; container=IndexedVarArray)
end

"""
    EMG.constraints_capacity_installed(
        m,
        tm::TransmissionMode,
        𝒯::TimeStructure,
        modeltype::EMB.AbstractInvestmentModel,
    )

When the modeltype is an investment model, the function introduces the related constraints
for the capacity expansion. The investment mode and lifetime mode are used for adding
constraints.

The default function only accepts nodes with
[`SingleInvData`](@extref EnergyModelsBase.SingleInvData). If you have several capacities
for investments, you have to dispatch specifically on the function.
"""
function EMG.constraints_capacity_installed(
    m,
    tm::TransmissionMode,
    𝒯::TimeStructure,
    modeltype::EMB.AbstractInvestmentModel,
)
    if has_investment(tm)
        # Extract the investment data and the discount rate
        disc_rate = discount_rate(modeltype)
        inv_data = EMI.investment_data(tm, :cap)
        𝒯ᴵⁿᵛ = strategic_periods(𝒯)

        # Add the investment constraints
        EMI.add_investment_constraints(m, tm, inv_data, :cap, :trans_cap, 𝒯ᴵⁿᵛ, disc_rate)
    else
        for t ∈ 𝒯
            fix(m[:trans_cap][tm, t], EMB.capacity(tm, t); force=true)
        end
    end
end
