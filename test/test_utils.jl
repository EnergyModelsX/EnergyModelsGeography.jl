@testset "utils" begin
    @testset "filter nodes by area" begin
        # This test uses the data from `test_geo_bidirectional.jl.`
        case, m = bidirectional_case()
        areas = case[:areas]
        nodes = case[:nodes]
        links = case[:links]

        a1 = areas[1]
        a2 = areas[2]

        nodes1 = EMG.getnodesinarea(a1, links)
        nodes2 = EMG.getnodesinarea(a2, links)

        @test length(nodes1) == 4
        for i ∈ range(1, 4)
            @test nodes[i] ∈ nodes1
        end
        @test length(nodes2) == 4
        for i ∈ range(5, 8)
            @test nodes[i] ∈ nodes2
        end
    end
end
