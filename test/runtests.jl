using TimeStructures; const TS  = TimeStructures
using EnergyModelsBase; const EMB = EnergyModelsBase
using JuMP
using GLPK
using Geography; const GEO = Geography
using Test


function optimize(case)
    model = EMB.OperationalModel()
    m = GEO.create_model(case, model)
    optimizer = GLPK.Optimizer
    set_optimizer(m, optimizer)
    optimize!(m)
    return m
end


function general_tests(m)
    # Check if the solution is optimal.
    @testset "Optimal solution" begin
        @test termination_status(m) == MOI.OPTIMAL

        if termination_status(m) != MOI.OPTIMAL
            @show termination_status(m)
        end
    end
end


include("test_geo_unidirectional.jl")
include("test_geo_bidirectional.jl")
include("test_pipelinemode.jl")
