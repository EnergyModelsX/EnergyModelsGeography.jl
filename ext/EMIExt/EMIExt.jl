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
include("utils.jl")

end