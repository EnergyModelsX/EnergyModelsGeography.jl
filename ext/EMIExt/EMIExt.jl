module EMIExt

using EnergyModelsBase
using EnergyModelsGeography
using EnergyModelsInvestments
using JuMP
using TimeStruct
using SparseVariables

const EMB = EnergyModelsBase
const EMG = EnergyModelsGeography
const EMI = EnergyModelsInvestments
const TS = TimeStruct

include("model.jl")
include("legacy_constructor.jl")


"""
    EMI.has_investment(tm::EMG.TransmissionMode)

For a given transmission mode `tm`, checks that it contains the required investment data.
"""
function EMI.has_investment(tm::EMG.TransmissionMode)
    (
        hasproperty(tm, :data) &&
        !isnothing(findfirst(data -> typeof(data) <: InvestmentData, mode_data(tm)))
    )
end

"""
    EMI.get_var_inst(m, prefix::Symbol, tm::EMG.TransmissionMode)

When the transmission mode `tm` is used as conditional input, it extracts only the variable
for the specified transmission mode.
"""
EMI.get_var_inst(m, prefix::Symbol, tm::EMG.TransmissionMode)  = m[Symbol(prefix)][tm, :]

"""
    EMI.investment_data(tm::EMG.TransmissionMode)
    EMI.investment_data(tm::EMG.TransmissionMode, field::Symbol)

Return the `InvestmentData` of the transmission mode `tm` or if `field` is specified, it
returns the `InvData` for the corresponding capacity.
"""
EMI.investment_data(tm::EMG.TransmissionMode) =
    tm.data[findfirst(data -> typeof(data) <: InvestmentData, mode_data(tm))]
EMI.investment_data(n::EMG.TransmissionMode, field::Symbol) = getproperty(investment_data(n), field)

EMI.start_cap(tm::EMG.TransmissionMode, t_inv, inv_data::NoStartInvData, cap) =
    capacity(tm, t_inv)

end
