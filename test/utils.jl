const TEST_ATOL = 1e-6
const ROUND_DIGITS = 8
⪆(x, y) = x > y || isapprox(x, y; atol = TEST_ATOL)

using HiGHS

function optimize(case, modeltype)
    m = EMG.create_model(case, modeltype)
    optimizer = HiGHS.Optimizer
    set_optimizer(m, optimizer)
    set_optimizer_attribute(m, MOI.Silent(), true)
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
