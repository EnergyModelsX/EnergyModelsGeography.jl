

function bidirectional_case()
    
    # Definition of the individual resources used in the simple system
    NG       = ResourceEmit("NG", 0.2)
    Power    = ResourceCarrier("Power", 0.)
    CO2      = ResourceEmit("CO2",1.)
    products = [NG, Power, CO2]

    # Creation of a dictionary with entries of 0. for all resources
    𝒫₀ = Dict(k => 0 for k ∈ products)

    # Creation of the time structure and the used global data
    𝒯 = TwoLevel(1, 1, SimpleTimes(2, 1))
    modeltype = OperationalModel(Dict(CO2 => FixedProfile(1e10),
                                      NG  => FixedProfile(1e6)
                                     ),
                                  CO2)

    # Definition of the invidivual nodes
    demand = [40 40]
    nodes = [
            EMG.GeoAvailability(1, 𝒫₀, 𝒫₀),
            RefSource(2, FixedProfile(200), OperationalProfile([10 100]), FixedProfile(0), Dict(NG => 1), []),  
            RefNetwork(3, FixedProfile(100), FixedProfile(5.5), FixedProfile(0), Dict(NG => 2), Dict(Power => 1), []),  
            RefSink(4, OperationalProfile(demand), 
                Dict(:Surplus => FixedProfile(0), :Deficit => FixedProfile(1e6)), 
                Dict(Power => 1)),
            
            EMG.GeoAvailability(5, 𝒫₀, 𝒫₀),
            RefSource(6, FixedProfile(200), OperationalProfile([100 10]), FixedProfile(0), Dict(NG => 1), []),  
            RefNetwork(7, FixedProfile(100), FixedProfile(5.5), FixedProfile(0), Dict(NG => 2), Dict(Power => 1), []),  
            RefSink(8, OperationalProfile(demand), 
                Dict(:Surplus => FixedProfile(0), :Deficit => FixedProfile(1e6)), 
                Dict(Power => 1)),
            ]

    # Definition of the links between the nodes in an area
    links = [
            Direct(13,nodes[1],nodes[3],Linear())
            Direct(14,nodes[1],nodes[4],Linear())
            Direct(21,nodes[2],nodes[1],Linear())
            Direct(31,nodes[3],nodes[1],Linear())
            
            Direct(57,nodes[5],nodes[7],Linear())
            Direct(58,nodes[5],nodes[8],Linear())
            Direct(65,nodes[6],nodes[5],Linear())
            Direct(75,nodes[7],nodes[5],Linear())
            ]
    
    # Definition of the two areas and the corresponding transmission line between them
    areas = [RefArea(1, "Oslo", 10.751, 59.921, nodes[1]),
             RefArea(2, "Bergen", 5.334, 60.389, nodes[5])]
            
    # Definition of the power lines
    transmission_line = RefStatic("Transline", Power, FixedProfile(30.0), FixedProfile(0.05), FixedProfile(0.05), FixedProfile(0.05), 2, [])
    transmission = [Transmission(areas[1], areas[2], [transmission_line])]

    # Aggregation of the problem case
    case = Dict(
                :nodes          => Array{EMB.Node}(nodes),
                :links          => Array{Link}(links),
                :products       => products,
                :areas          => Array{Area}(areas),
                :transmission   => Array{Transmission}(transmission),
                :T              => 𝒯,
                )
    return case, modeltype
end

@testset "Bidirectional transmission" begin

    # Reading of the case data
    case, modeltype = bidirectional_case()

    # Create and solve the model
    m = optimize(case, modeltype)
    
    # Run of the generalized tests
    general_tests(m)

    # Reassigning the case data
    𝒯   = case[:T]
    l   = case[:transmission][1]
    cm  = l.Modes[1]

    # The sign should be the same for both directions
    @test sum(sign(value.(m[:trans_in])[cm, t]) 
              == sign(value.(m[:trans_out])[cm, t]) for t ∈ 𝒯) == length(𝒯)
    
    # Depending on the direction, check on the individual flows
    for t ∈ 𝒯
        if value.(m[:trans_in])[cm, t] <= 0
            @test abs(value.(m[:trans_in])[cm, t]) <= abs(value.(m[:trans_out])[cm, t])
            @test abs(value.(m[:trans_in])[cm, t]) == cm.Trans_cap[t]
        else
            @test value.(m[:trans_out])[cm, t] <= value.(m[:trans_in])[cm, t]
            @test value.(m[:trans_out])[cm, t] == cm.Trans_cap[t]
        end
    end

end
