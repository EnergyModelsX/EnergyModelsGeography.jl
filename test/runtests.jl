using EnergyModelsGeography
using JuMP
using Test

using EnergyModelsBase
using TimeStructures


const TS = TimeStructures
const EMB = EnergyModelsBase
const GEO = EnergyModelsGeography


@testset "Geography" begin
    include("utils.jl")

    include("test_geo_unidirectional.jl")
    include("test_geo_bidirectional.jl")
    include("test_pipelinemode.jl")
end
