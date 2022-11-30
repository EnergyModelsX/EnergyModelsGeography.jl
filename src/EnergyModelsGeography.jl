"""
Main module for `Geography.jl`.

# Exports:
 - `Area`, `Transmission`, `RefStatic`, `RefDynamic`, `PipelineMode`.
"""
module EnergyModelsGeography

using Base: Float64
using JuMP
using EnergyModelsBase; const EMB = EnergyModelsBase
using TimeStructures

include("datastructures.jl")
include("model.jl")
include("user_interface.jl")

export Area, Transmission
export RefStatic, RefDynamic, PipelineMode

end # module
