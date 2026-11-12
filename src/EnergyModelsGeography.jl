"""
Main module for `EnergyModelsGeography.jl`.

# Exports:
 - `Area`, `RefArea`, `LimitedExchangeArea`, `GeoAvailability`, `Transmission`,
   `TransmissionMode`, `RefStatic`, `RefDynamic`, `PipeMode`, `PipeSimple`, and
   `PipeLinepackSimple`.
 - Functions for accessing the case elements, utility functions, and functions for
   extracting the fields of `Area`s, `Transmission`s, and `TransmissionMode`s.
"""
module EnergyModelsGeography

using Base: Float64
using JuMP
using EnergyModelsBase; const EMB = EnergyModelsBase
using TimeStruct; const TS = TimeStruct

include(joinpath("structures", "area.jl"))
include(joinpath("structures", "mode.jl"))
include(joinpath("structures", "transmission.jl"))
include(joinpath("structures", "data.jl"))
include(joinpath("structures", "case.jl"))

include("checks.jl")
include("model.jl")
include("constraint_functions.jl")
include("data_functions.jl")
include("compute_functions.jl")
include("legacy_constructors.jl")
include("utils.jl")

# Export the functions for the case type
export get_areas, get_transmissions

# Export the individual types and composite types
export Area, RefArea, LimitedExchangeArea
export GeoAvailability
export Transmission, TransmissionMode
export RefStatic, RefDynamic
export PipeMode, PipeSimple, PipeLinepackSimple

# Export utility functions
export getnodesinarea, nodes_in_area

# Export commonly used functions for extracting fields in `Area`s
export name, availability_node, limit_resources, exchange_limit, exchange_resources

# Export commonly used functions for extracting fields in `Transmission`s
export modes, mode_sub, modes_sub, corr_from, corr_to, corr_from_to

# Export commonly used functions for extracting fields in `TransmissionMode`s
export map_trans_resource
export loss, directions, mode_data, consumption_rate, energy_share

end # module
