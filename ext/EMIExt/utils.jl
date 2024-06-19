"""
    EMI.get_var_inst(m, prefix::Symbol, tm::EMG.TransmissionMode)

When the transmission mode `tm` is used as conditional input, it extracts only the variable
for the specified transmission mode.
"""
EMI.get_var_inst(m, prefix::Symbol, tm::EMG.TransmissionMode)  = m[Symbol(prefix)][tm, :]


function EMI.has_investment(tm::EMG.TransmissionMode)
    (
        hasproperty(tm, :data) &&
        !isnothing(findfirst(data -> typeof(data) <: InvestmentData, tm.data)) # TODO: access function for data
    )
end

EMI.investment_data(tm::EMG.TransmissionMode) =
    tm.data[findfirst(data -> typeof(data) <: InvestmentData, tm.data)]

EMI.investment_data(n::EMG.TransmissionMode, field::Symbol) = getproperty(investment_data(n), field)


EMI.start_cap(tm::EMG.TransmissionMode, t_inv, inv_data::NoStartInvData, cap) =
    capacity(tm, t_inv)
