"""
Main module for `EnergyModelsGeography.jl`.

# Exports:
 - `Area`, `RefArea`, `GeoAvailability`, `Transmission`, `RefStatic`, `RefDynamic`, `PipeMode`, `PipeSimple`.
"""
module EnergyModelsGeography

using Base: Float64
using JuMP
using EnergyModelsBase; const EMB = EnergyModelsBase
using TimeStructures

include("datastructures.jl")
include("model.jl")
include("user_interface.jl")

export Area, RefArea
export GeoAvailability
export Transmission
export RefStatic, RefDynamic
export PipeMode, PipeSimple

end # module
