"""
    constraints_capacity(m, tm::TransmissionMode, 𝒯::TimeStructure, modeltype::EnergyModel)
    constraints_capacity(m, tm::PipeMode, 𝒯::TimeStructure, modeltype::EnergyModel)

Function for creating the constraint on the maximum capacity of a generic
[`TransmissionMode`](@ref) and [`PipeMode`](@ref).

These functions serve as fallback option if no other method is specified for a specific
`TransmissionMode`.

!!! warning "Dispatching on this function"
    If you create a new method for this function, it is crucial to call within said function
    the function `constraints_capacity_installed(m, tm, 𝒯, modeltype)` if you want to include
    investment options.
"""
function constraints_capacity(m, tm::TransmissionMode, 𝒯::TimeStructure, modeltype::EnergyModel)

    # Upper limit defined by installed capacity
    @constraint(m, [t ∈ 𝒯],
        m[:trans_out][tm, t] <= m[:trans_cap][tm, t]
    )

    # Lower limit depends on if the transmission is uni- or bi-directional
    if is_bidirectional(tm)
        @constraint(m, [t ∈ 𝒯],
            m[:trans_in][tm, t] >= -1 * m[:trans_cap][tm, t]
        )
    else
        for t ∈ 𝒯
            set_lower_bound(m[:trans_in][tm, t], 0)
            set_lower_bound(m[:trans_out][tm, t], 0)
        end
    end

    # Add constraints for the installed capacity
    constraints_capacity_installed(m, tm, 𝒯, modeltype)
end
function constraints_capacity(m, tm::PipeMode, 𝒯::TimeStructure, modeltype::EnergyModel)

    # Upper and lower limit defined by installed capacity
    @constraint(m, [t ∈ 𝒯],
        m[:trans_out][tm, t] <= m[:trans_cap][tm, t]
    )
    for t ∈ 𝒯
        set_lower_bound(m[:trans_out][tm, t], 0)
        set_lower_bound(m[:trans_in][tm, t], 0)
    end

    # Add constraints for the installed capacity
    constraints_capacity_installed(m, tm, 𝒯, modeltype)
end

"""
    constraints_capacity(m, tm::PipeLinepackSimple, 𝒯::TimeStructure, modeltype::EnergyModel)

Method for creating the constraint on the maximum capacity of a [`PipeLinepackSimple`](@ref).

The function introduces in addition an upper bound on the linepack storage level.
"""
function constraints_capacity(m, tm::PipeLinepackSimple, 𝒯::TimeStructure, modeltype::EnergyModel)

    # Upper and lower transmission limit defined by installed capacity
    @constraint(m, [t ∈ 𝒯],
        m[:trans_out][tm, t] <= m[:trans_cap][tm, t]
    )
    @constraint(m, [t ∈ 𝒯],
        m[:trans_in][tm, t] - m[:trans_loss][tm, t] <= m[:trans_cap][tm, t]
    )
    for t ∈ 𝒯
        set_lower_bound(m[:trans_out][tm, t], 0)
        set_lower_bound(m[:trans_in][tm, t], 0)
    end

    # Linepack storage upper limit
    @constraint(m, [t ∈ 𝒯],
        m[:linepack_stor_level][tm, t] <= energy_share(tm) * m[:trans_cap][tm, t])

    # Add constraints for the installed capacity
    constraints_capacity_installed(m, tm, 𝒯, modeltype)
end

"""
    constraints_capacity_installed(m, tm::TransmissionMode, 𝒯::TimeStructure, modeltype::EnergyModel)

Function for creating the constraint on the installed capacity of a `TransmissionMode`.

This function serves as fallback option if no other method is specified for a specific
`TransmissionMode`.

!!! danger "Dispatching on this function"
    This function should only be used to dispatch on the modeltype for providing investments.
    If you create new capacity variables, it is beneficial to include as well a method for
    this function and the corresponding transmission mode types.
"""
function constraints_capacity_installed(m, tm::TransmissionMode, 𝒯::TimeStructure, modeltype::EnergyModel)

    # Fix the installed capacity to the upper bound
    for t ∈ 𝒯
        fix(m[:trans_cap][tm, t], capacity(tm, t); force=true)
    end
end

"""
    constraints_trans_loss(m, tm::TransmissionMode, 𝒯::TimeStructure, modeltype::EnergyModel)
    constraints_trans_loss(m, tm::PipeMode, 𝒯::TimeStructure, modeltype::EnergyModel)

Function for creating the constraint on the transmission loss of a generic
[`TransmissionMode`](@ref) and [`PipeMode`](@ref)

These functions serve as fallback option if no other function is specified for a
`TransmissionMode`. If you plan to use the methods, it is necessary that the function
[`loss`](@ref) is either declared for your `TransmissionMode` or you provide alternatively
a new method.
"""
function constraints_trans_loss(m, tm::TransmissionMode, 𝒯::TimeStructure, modeltype::EnergyModel)

    if is_bidirectional(tm)
        # The total loss equals the sum of negative and positive loss (absolute loss)
        @constraint(m, [t ∈ 𝒯],
            m[:trans_loss][tm, t] ==
                loss(tm, t) * (m[:trans_pos][tm, t] + m[:trans_neg][tm, t])
        )

        # The positive and negative conponents of flow of a transmission mode
        # depends on the direction a mode is defined
        @constraint(m, [t ∈ 𝒯],
            m[:trans_pos][tm, t] - m[:trans_neg][tm, t] ==
                0.5 * (m[:trans_in][tm, t] + m[:trans_out][tm, t])
        )
    else
        @constraint(m, [t ∈ 𝒯],
            m[:trans_loss][tm, t] == loss(tm, t) * m[:trans_in][tm, t]
        )
    end
end
function constraints_trans_loss(m, tm::PipeMode, 𝒯::TimeStructure, modeltype::EnergyModel)

    @constraint(m, [t ∈ 𝒯],
        m[:trans_loss][tm, t] == loss(tm, t) * m[:trans_in][tm, t])
end

"""
    constraints_trans_balance(m, tm::TransmissionMode, 𝒯::TimeStructure, modeltype::EnergyModel)

Function for creating the transmission balance for a generic [`TransmissionMode`](@ref).

This function serves as fallback option if no other function is specified for a
`TransmissionMode`.
"""
function constraints_trans_balance(m, tm::TransmissionMode, 𝒯::TimeStructure, modeltype::EnergyModel)

    @constraint(m, [t ∈ 𝒯],
        m[:trans_out][tm, t] == m[:trans_in][tm, t] - m[:trans_loss][tm, t])

end

"""
    constraints_trans_balance(m, tm::PipeLinepackSimple, 𝒯::TimeStructure, modeltype::EnergyModel)

Method for creating the transmission balance for a [`PipeLinepackSimple`](@ref).

It adds the linepack level balance.
"""
function constraints_trans_balance(m, tm::PipeLinepackSimple, 𝒯::TimeStructure, modeltype::EnergyModel)

    𝒯ᴵⁿᵛ = strategic_periods(𝒯)
    for t_inv ∈ 𝒯ᴵⁿᵛ, (t_prev, t) ∈ withprev(t_inv)
        # Periodicity constraint
        if isnothing(t_prev)
            @constraint(m, m[:linepack_stor_level][tm, t] ==
                           m[:linepack_stor_level][tm, last(t_inv)] +
                           (m[:trans_in][tm, t] - m[:trans_loss][tm, t] - m[:trans_out][tm, t])
                           * duration(t)
            )
        else # From one operational period to next
            @constraint(m, m[:linepack_stor_level][tm, t] ==
                           m[:linepack_stor_level][tm, t_prev] +
                           (m[:trans_in][tm, t] - m[:trans_loss][tm, t] - m[:trans_out][tm, t])
                           * duration(t)
            )
        end
    end

    if isa(𝒯, TwoLevel{S,T,U} where {S,T,U<:RepresentativePeriods})
        @warn "RepresentativePeriods is not implemented for PipeLinepackSimple. The overall
        storage balance may yield unexpected results."
    end

end

"""
    constraints_opex_fixed(m, tm::TransmissionMode, 𝒯ᴵⁿᵛ, modeltype::EnergyModel)

Function for creating the constraint on the fixed OPEX of a generic [`TransmissionMode`](@ref).

This function serves as fallback option if no other function is specified for a
`TransmissionMode`.
"""
function constraints_opex_fixed(m, tm::TransmissionMode, 𝒯ᴵⁿᵛ, modeltype::EnergyModel)

    @constraint(m, [t_inv ∈ 𝒯ᴵⁿᵛ],
        m[:trans_opex_fixed][tm, t_inv] ==
            opex_fixed(tm, t_inv) * m[:trans_cap][tm, first(t_inv)]
    )
end

"""
    constraints_opex_var(m, tm::TransmissionMode, 𝒯ᴵⁿᵛ, modeltype::EnergyModel)

Function for creating the constraint on the variable OPEX of a generic
[`TransmissionMode`](@ref).

This function serves as fallback option if no other function is specified for a
`TransmissionMode`.
"""
function constraints_opex_var(m, tm::TransmissionMode, 𝒯ᴵⁿᵛ, modeltype::EnergyModel)

    if is_bidirectional(tm)
        @constraint(m, [t_inv ∈ 𝒯ᴵⁿᵛ],
            m[:trans_opex_var][tm, t_inv] ==
                    sum(
                        (m[:trans_pos][tm, t] + m[:trans_neg][tm, t]) *
                        opex_var(tm, t_inv) * scale_op_sp(t_inv, t)
                    for t ∈ t_inv)
        )
    else
        @constraint(m, [t_inv ∈ 𝒯ᴵⁿᵛ],
            m[:trans_opex_var][tm, t_inv] ==
                sum(
                    m[:trans_out][tm, t] * opex_var(tm, t) * scale_op_sp(t_inv, t)
                for t ∈ t_inv)
        )
    end
end

"""
    constraints_emission(m, tm::TransmissionMode, 𝒯, modeltype::EnergyModel)

Function for creating the constraints on the emissions of a generic `TransmissionMode` `tm`.

This function serves as fallback option if no other function is specified for a
`TransmissionMode`.
"""
function constraints_emission(m, tm::TransmissionMode, 𝒯, modeltype::EnergyModel)

    if is_bidirectional(tm)
        @constraint(m, [t ∈ 𝒯, p_em ∈ emit_resources(tm)],
            m[:emissions_trans][tm, t, p_em] ==
                emissions(tm, p_em, t) * (m[:trans_pos][tm, t] + m[:trans_neg][tm, t])
        )
    else
        @constraint(m, [t ∈ 𝒯, p_em ∈ emit_resources(tm)],
            m[:emissions_trans][tm, t, p_em] ==
                emissions(tm, p_em, t) * m[:trans_out][tm, t]
        )
    end
end
