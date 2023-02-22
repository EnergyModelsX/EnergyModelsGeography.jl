using EnergyModelsGeography
using JuMP
using Test

using EnergyModelsBase
using TimeStructures


const TS = TimeStructures
const EMB = EnergyModelsBase
const GEO = EnergyModelsGeography

const TEST_ATOL = 1e-6

@testset "Geography" begin
    include("utils.jl")

    include("test_geo.jl")
    include("test_geo_unidirectional.jl")
    include("test_geo_bidirectional.jl")
    include("test_simplepipe.jl")
    include("test_simplelinepack.jl")
end
