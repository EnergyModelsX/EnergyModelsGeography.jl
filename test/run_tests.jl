using TimeStructures; const TS  = TimeStructures
using EnergyModelsBase; const EMB = EnergyModelsBase
using JuMP
using GLPK
using Geography; const GEO = Geography
using Test

include("test_geo_unidirectional.jl")
include("test_geo_bidirectional.jl")
# include("test_geo.jl")