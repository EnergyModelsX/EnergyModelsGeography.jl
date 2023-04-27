
"""
    compute_trans_in(m, t, p, tm::TransmissionMode)

Return the amount of resources going into transmission corridor l by a generic transmission mode.
"""
function compute_trans_in(m, t, p, tm::TransmissionMode)
    exp = 0
    if tm.Resource == p
        exp += m[:trans_in][tm, t]
    end
    return exp
end

"""
    compute_trans_in(m, t, p, tm::PipeMode)

Return the amount of resources going into transmission corridor l by a PipeMode transmission mode.
"""
function compute_trans_in(m, t, p, tm::PipeMode)
    exp = 0
    if tm.Inlet == p
        exp += m[:trans_in][tm, t]
    end
    if tm.Consuming == p
        exp += m[:trans_in][tm, t] * tm.Consumption_rate[t]
    end
    return exp
end

"""
    compute_trans_out(m, t, p, tm::TransmissionMode)

Return the amount of resources going out of transmission corridor l by a generic transmission mode.
"""
function compute_trans_out(m, t, p, tm::TransmissionMode)
    exp = 0
    if tm.Resource == p
        exp += m[:trans_out][tm, t]
    end
    return exp
end

"""
    compute_trans_out(m, t, p, tm::PipeMode)

Return the amount of resources going out of transmission corridor l by a PipeMode transmission mode.
"""
function compute_trans_out(m, t, p, tm::PipeMode)
    exp = 0
    if tm.Outlet == p
        exp += m[:trans_out][tm, t]
    end
    return exp
end