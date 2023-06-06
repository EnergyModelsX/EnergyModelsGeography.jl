using EnergyModelsGeography
using JuMP
using Test

using EnergyModelsBase
using TimeStruct


const TS = TimeStruct
const EMB = EnergyModelsBase
const EMG = EnergyModelsGeography

const TEST_ATOL = 1e-6

@testset "Geography" begin
    include("utils.jl")

    include("test_geo_unidirectional.jl")
    include("test_geo_bidirectional.jl")
    include("test_geo_opex.jl")
    include("test_simplepipe.jl")
    include("test_simplelinepack.jl")
    include("test_examples.jl")
end
