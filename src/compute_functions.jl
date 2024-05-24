
"""
    compute_trans_in(m, t, p, tm::TransmissionMode)
    compute_trans_in(m, t, p, tm::PipeMode)

Return the amount of resource `p` going into transmission mode `tm` in operational period
`t`.

The function is declared for both a generic [`TransmissionMode`](@ref) and for a
[`PipeMode`](@ref).
"""
function compute_trans_in(m, t, p, tm::TransmissionMode)
    exp = 0
    if tm.resource == p
        exp += m[:trans_in][tm, t]
    end
    return exp
end
function compute_trans_in(m, t, p, tm::PipeMode)
    exp = 0
    if inputs(tm)[1] == p
        exp += m[:trans_in][tm, t]
    end
    if inputs(tm)[2] == p
        exp += m[:trans_in][tm, t] * consumption_rate(tm, t)
    end
    return exp
end

"""
    compute_trans_out(m, t, p, tm::TransmissionMode)
    compute_trans_out(m, t, p, tm::PipeMode)

Return the amount of resource `p` going out of transmission mode `tm` in operational period
`t`.

The function is declared for both a generic [`TransmissionMode`](@ref) and for a
[`PipeMode`](@ref).
"""
function compute_trans_out(m, t, p, tm::TransmissionMode)
    exp = 0
    if inputs(tm)[1] == p
        exp += m[:trans_out][tm, t]
    end
    return exp
end
function compute_trans_out(m, t, p, tm::PipeMode)
    exp = 0
    if outputs(tm)[1] == p
        exp += m[:trans_out][tm, t]
    end
    return exp
end
