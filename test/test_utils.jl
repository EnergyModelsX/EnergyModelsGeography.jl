@testset "Filter nodes by area" begin
    # This test uses the data from `test_geo_bidirectional.jl.`
    case, m = bidirectional_case()
    areas = get_areas(case)
    nodes = get_nodes(case)
    links = get_links(case)

    a1 = areas[1]
    a2 = areas[2]

    nodes1 = getnodesinarea(a1, links)
    nodes2 = getnodesinarea(a2, links)

    @test length(nodes1) == 4
    for i ∈ range(1, 4)
        @test nodes[i] ∈ nodes1
    end
    @test length(nodes2) == 4
    for i ∈ range(5, 8)
        @test nodes[i] ∈ nodes2
    end
end

@testset "Filter nodes by area - new method" begin
    # Using the same test set as in the original method
    case, m = bidirectional_case()
    areas = get_areas(case)
    nodes = get_nodes(case)
    links = get_links(case)

    a1 = areas[1]
    a2 = areas[2]

    nodes1, links1 = nodes_in_area(a1, links)
    nodes2, links2 = nodes_in_area(a2, links)

    @test length(nodes1) == 4
    for i ∈ range(1, 4)
        @test nodes[i] ∈ nodes1
    end
    @test length(nodes2) == 4
    for i ∈ range(5, 8)
        @test nodes[i] ∈ nodes2
    end

    # Using a new, large test set
    function reg(n_nodes::Int, id::String)
        # Number of random links
        n_links = 5

        # Define the different resources and their emission intensity in tCO2/MWh
        NG = ResourceEmit("NG", 0.2)
        Power = ResourceCarrier("Power", 0.0)
        products = [NG, Power]

        # Define random nodes
        av = GeoAvailability("a_" * id * "_0" , products)
        nodes = EMB.Node[
            RefNetworkNode(
                "a_" * id * "_" * string(k),
                FixedProfile(25),
                FixedProfile(5.5),          # Variable OPEX in EUR/MWh
                FixedProfile(0),            # Fixed OPEX in EUR/MW/8h
                Dict(NG => 2),              # Input to the node with input ratio
                Dict(Power => 1),           # Output from the node with output ratio
            ) for k ∈ 1:n_nodes
        ]
        append!(nodes, [av])

        # Create links so that all nodes are connected
        links_1 = [Direct("a_" * id, nodes[k], nodes[k+1]) for k ∈ 1:n_nodes]
        append!(links_1, [Direct("a_" * id, nodes[1], nodes[end])])

        # Create random links
        n_rand_1 = rand(1:n_nodes+1, n_links*n_nodes)
        n_rand_2 = rand(1:n_nodes+1, n_links*n_nodes)
        links_2 = [Direct("a_" * id, nodes[n_rand_1[k]], nodes[n_rand_2[k]]) for k ∈ 1:n_links*n_nodes]
        links = vcat(links_1, links_2)

        return nodes, links
    end

    # Create multiple areas with a variety of nodes
    a = [100, 200, 600, 20, 5, 150, 900]
    N_dict = Dict()
    L_dict = Dict()
    𝒩 = EMB.Node[]
    ℒ = EMB.Link[]
    for (k, val) ∈ enumerate(a)
        N_dict[k], L_dict[k] = reg(val, string(k))
        append!(𝒩, N_dict[k])
        append!(ℒ, L_dict[k])
    end

    # Evaluate the areas
    nodes = Dict()
    links = Dict()
    for (k, val) ∈ enumerate(a)
        nodes[k], links[k] = nodes_in_area(
            RefArea(k, string(k), 10.751, 59.921, N_dict[k][end]),
            ℒ,
            n_nodes=length(𝒩));
    end

    # Test that the correct nodes are extracted
    @test all(n.id[1:3] == "a_" * string(k) for (k, _) ∈ enumerate(a) for n ∈ nodes[k])

    # Test that the correct links are extracted
    @test all(l.id[1:3] == "a_" * string(k) for (k, _) ∈ enumerate(a) for l ∈ links[k])
end
