"""
constraints_capacity(m, tm::TransmissionMode, 𝒯::TimeStructure)

Function for creating the constraint on the maximum capacity of a generic `TransmissionMode`.
This function serves as fallback option if no other function is specified for a `TransmissionMode`.
"""
function constraints_capacity(m, tm::TransmissionMode, 𝒯::TimeStructure)

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
        @constraint(m, [t ∈ 𝒯], m[:trans_out][tm, t] >= 0)
    end
end

"""
constraints_capacity(m, tm::PipeMode, 𝒯::TimeStructure)

Function for creating the constraint on the maximum capacity of a generic `PipeMode`.
"""
function constraints_capacity(m, tm::PipeMode, 𝒯::TimeStructure)

    # Upper and lower limit defined by installed capacity
    @constraint(m, [t ∈ 𝒯],
        m[:trans_out][tm, t] <= m[:trans_cap][tm, t]
    )
    @constraint(m, [t ∈ 𝒯], m[:trans_out][tm, t] >= 0)

    # Bi-directional not allowed for PipeMode
    if is_bidirectional(tm)
        @warn "Only uni-directional tranmission is allowed for TransmissionMode of type
        $(typeof(tm)), uni-directional constraints for capacity is implemented for $tm."
    end
end

"""
constraints_capacity(m, tm::PipeLinepackSimple, 𝒯::TimeStructure)

Function for creating the constraint on the maximum capacity of a `PipeLinepackSimple`.
"""
function constraints_capacity(m, tm::PipeLinepackSimple, 𝒯::TimeStructure)

    # Upper and lower transmission limit defined by installed capacity
    @constraint(m, [t ∈ 𝒯],
        m[:trans_out][tm, t] <= m[:trans_cap][tm, t]
    )
    @constraint(m, [t ∈ 𝒯],
        m[:trans_in][tm, t] - m[:trans_loss][tm, t] <= m[:trans_cap][tm, t]
    )
    @constraint(m, [t ∈ 𝒯], m[:trans_out][tm, t] >= 0)
    @constraint(m, [t ∈ 𝒯], m[:trans_in][tm, t] >= 0)

    # Linepack storage upper limit
    @constraint(m, [t ∈ 𝒯],
        m[:linepack_stor_level][tm, t] <= energy_share(tm) * m[:trans_cap][tm, t])

    # Bi-directional not allowed for PipeMode
    if is_bidirectional(tm)
        @warn "Only uni-directional tranmission is allowed for TransmissionMode of type
        $(typeof(tm)), uni-directional constraints for capacity is implemented for $tm."
    end
end


"""
constraints_trans_loss(m, tm::TransmissionMode, 𝒯::TimeStructure)

Function for creating the constraint on the transmission loss of a generic `TransmissionMode`.
This function serves as fallback option if no other function is specified for a `TransmissionMode`.
"""
function constraints_trans_loss(m, tm::TransmissionMode, 𝒯::TimeStructure)

    if is_bidirectional(tm)
        # The total loss equals the sum of negative and positive loss (absolute loss)
        @constraint(m, [t ∈ 𝒯],
            m[:trans_loss][tm, t] ==
                loss(tm, t) * (m[:trans_pos][tm, t] + m[:trans_neg][tm, t])
        )

        # The positive and negative conponents of flow on a transmission mode
        # (depends on the dicrestion a mode is defined)
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

"""
constraints_trans_loss(m, tm::PipeMode, 𝒯::TimeStructure)

Function for creating the constraint on the transmission loss of a generic `PipeMode`.
"""
function constraints_trans_loss(m, tm::PipeMode, 𝒯::TimeStructure)


    @constraint(m, [t ∈ 𝒯],
        m[:trans_loss][tm, t] == loss(tm, t) * m[:trans_in][tm, t])

    if is_bidirectional(tm)
        @warn "Only uni-directional tranmission is allowed for TransmissionMode of type
        $(typeof(tm)), uni-directional constraint for loss is implemented for $tm."
    end

end


"""
constraints_trans_balance(m, tm::TransmissionMode, 𝒯::TimeStructure)

Function for creating the transmission balance for a generic `TransmissionMode`.
This function serves as fallback option if no other function is specified for a `TransmissionMode`.
"""
function constraints_trans_balance(m, tm::TransmissionMode, 𝒯::TimeStructure)

    @constraint(m, [t ∈ 𝒯],
        m[:trans_out][tm, t] == m[:trans_in][tm, t] - m[:trans_loss][tm, t])

end

"""
constraints_trans_balance(m, tm::PipeLinepackSimple, 𝒯::TimeStructure)

Function for creating the transmission balance for a`PipeLinepackSimple`.
"""
function constraints_trans_balance(m, tm::PipeLinepackSimple, 𝒯::TimeStructure)

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
    constraints_opex_fixed(m, tm::TransmissionMode, 𝒯ᴵⁿᵛ)

Function for creating the constraint on the fixed OPEX of a generic `TransmissionMode`.
This function serves as fallback option if no other function is specified for a `TransmissionMode`.
"""
function constraints_opex_fixed(m, tm::TransmissionMode, 𝒯ᴵⁿᵛ)

    @constraint(m, [t_inv ∈ 𝒯ᴵⁿᵛ],
        m[:trans_opex_fixed][tm, t_inv] ==
        opex_fixed(tm, t_inv) * m[:trans_cap][tm, first(t_inv)]
    )
end


"""
    constraints_opex_var(m, tm::TransmissionMode, 𝒯ᴵⁿᵛ)

Function for creating the constraint on the variable OPEX of a generic `TransmissionMode`.
This function serves as fallback option if no other function is specified for a `TransmissionMode`.
"""
function constraints_opex_var(m, tm::TransmissionMode, 𝒯ᴵⁿᵛ)

    if is_bidirectional(tm)
        @constraint(m, [t_inv ∈ 𝒯ᴵⁿᵛ],
            m[:trans_opex_var][tm, t_inv] ==
                opex_var(tm, t_inv) *
                sum((m[:trans_pos][tm, t] + m[:trans_neg][tm, t]) *
                    duration(t) * multiple_strat(t_inv, t) * probability(t)
                for t ∈ t_inv)
        )
    else
        @constraint(m, [t_inv ∈ 𝒯ᴵⁿᵛ],
            m[:trans_opex_var][tm, t_inv] ==
            sum(m[:trans_out][tm, t] * opex_var(tm, t) * duration(t) for t ∈ t_inv)
        )
    end
end
