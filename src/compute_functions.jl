
"""
    compute_trans_in(m, t, p, tm::TransmissionMode)

Return the amount of resources going into transmission corridor `l` by a generic
`TransmissionMode`
"""
function compute_trans_in(m, t, p, tm::TransmissionMode)
    exp = 0
    if tm.resource == p
        exp += m[:trans_in][tm, t]
    end
    return exp
end

"""
    compute_trans_in(m, t, p, tm::PipeMode)

Return the amount of resources going into transmission corridor `l` by a `PipeMode`.
"""
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

Return the amount of resources going out of transmission corridor `l` by a generic
`TransmissionMode`
"""
function compute_trans_out(m, t, p, tm::TransmissionMode)
    exp = 0
    if inputs(tm)[1] == p
        exp += m[:trans_out][tm, t]
    end
    return exp
end

"""
    compute_trans_out(m, t, p, tm::PipeMode)

Return the amount of resources going out of transmission corridor `l` by a `PipeMode`.
"""
function compute_trans_out(m, t, p, tm::PipeMode)
    exp = 0
    if outputs(tm)[1] == p
        exp += m[:trans_out][tm, t]
    end
    return exp
end
