"""
    EMG.update_objective(m, 𝒯, ℳ, modeltype::EMB.AbstractInvestmentModel)

Create objective function overloading the default from `EnergyModelsBase` for
[`AbstractInvestmentModel`](@extref EnergyModelsBase.AbstractInvestmentModel).

Maximize Net Present Value from revenues, investments (CAPEX) and operations (OPEX)

## TODO:
# * consider passing expression around for updating
# * consider reading objective and adding terms/coefficients (from model object `m`)
"""
function EMG.update_objective(m, 𝒯, ℳ, modeltype::EMB.AbstractInvestmentModel)

    # Extraction of data
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)
    ℳᴵⁿᵛ = filter(has_investment, ℳ)
    obj  = JuMP.objective_function(m)
    disc = Discounter(discount_rate(modeltype), 𝒯)

    # Calculate the CAPEX cost contribution
    capex = @expression(m, [t_inv ∈ 𝒯ᴵⁿᵛ],
        sum(m[:trans_cap_capex][tm, t_inv] for tm ∈ ℳᴵⁿᵛ)
    )
    # Calculate the OPEX cost contribution
    opex = @expression(m, [t_inv ∈ 𝒯ᴵⁿᵛ],
        sum(m[:trans_opex_var][tm, t_inv] + m[:trans_opex_fixed][tm, t_inv] for tm ∈ ℳ)
    )
    # Update the objective
    @objective(m, Max,
        obj -
        sum(
            opex[t_inv] * duration_strat(t_inv) * objective_weight(t_inv, disc, type="avg") +
            capex[t_inv] * objective_weight(t_inv, disc)
        for t_inv ∈ 𝒯ᴵⁿᵛ)
    )
end

"""
    EMG.variables_trans_capex(m, 𝒯, ℳ,, modeltype::EMB.AbstractInvestmentModel)

Create variables for the capital costs for the investments in transmission.

Additional variables for investment in capacity:
* `:trans_cap_capex` - CAPEX costs for increases in the capacity of a transmission mode
* `:trans_cap_current` - installed capacity for storage in each strategic period
* `:trans_cap_add` - added capacity
* `:trans_cap_rem` - removed capacity
* `:trans_cap_invest_b` - binary variable whether investments in capacity are happening
* `:trans_cap_remove_b` - binary variable whether investments in capacity are removed
"""
function EMG.variables_trans_capex(m, 𝒯, ℳ, modeltype::EMB.AbstractInvestmentModel)

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
