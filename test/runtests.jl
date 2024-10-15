using EnergyModelsGeography
using JuMP
using Test

using EnergyModelsBase
using TimeStruct

const TS = TimeStruct
const EMB = EnergyModelsBase
const EMG = EnergyModelsGeography

include("utils.jl")

@testset "Geography" begin

    @testset "Geography | Reference modes" begin
        include("test_geo_unidirectional.jl")
        include("test_geo_bidirectional.jl")
    end

    @testset "Geography | OPEX" begin
        include("test_geo_opex.jl")
    end

    @testset "Geography | SimplePipe" begin
        include("test_simplepipe.jl")
    end

    @testset "Geography | SimpleLinePack" begin
        include("test_simplelinepack.jl")
    end

    @testset "Geography | Utilities" begin
        include("test_utils.jl")
    end

    @testset "Geography | Checks" begin
        include("test_checks.jl")
    end

    @testset "Geography | Investments" begin
        include("test_investments.jl")
    end

    @testset "Geography | examples" begin
        include("test_examples.jl")
    end
end
