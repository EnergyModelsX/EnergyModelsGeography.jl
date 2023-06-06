"""
Main module for `EnergyModelsGeography.jl`.

# Exports:
 - `Area`, `RefArea`, `GeoAvailability`, `Transmission`, `RefStatic`, `RefDynamic`, `PipeMode`, `PipeSimple`, `PipeLinepackSimple`.
"""
module EnergyModelsGeography

using Base: Float64
using JuMP
using EnergyModelsBase; const EMB = EnergyModelsBase
using TimeStruct

include("datastructures.jl")
include("checks.jl")
include("model.jl")
include("constraint_functions.jl")
include("compute_functions.jl")

export Area, RefArea
export GeoAvailability
export Transmission, TransmissionMode
export RefStatic, RefDynamic
export PipeMode, PipeSimple, PipeLinepackSimple

end # module
