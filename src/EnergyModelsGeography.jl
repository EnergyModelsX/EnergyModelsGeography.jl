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
include("legacy_constructors.jl")
include("utils.jl")

# Export the invidiual types and composite types
export Area, RefArea, LimitedExchangeArea
export GeoAvailability
export Transmission, TransmissionMode
export RefStatic, RefDynamic
export PipeMode, PipeSimple, PipeLinepackSimple

# Export commonly used functions for extracting fields in `Area`s
export name, availability_node, limit_resources, exchange_limit, exchange_resources

# Export commonly used functions for exctracting fields in `Transmission`s
export modes, mode_sub, modes_sub, corr_from, corr_to, corr_from_to, modes_of_dir
export getnodesinarea

# Export commonly used functions for extracting fields in `TransmissionMode`s
export map_trans_resource, exchange_resources
export loss, directions, consumption_rate, energy_share

end # module
