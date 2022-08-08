# Definition of the individual resources used in the simple system
NG       = ResourceEmit("NG", 0.2)
Power    = ResourceCarrier("Power", 0.)
CO2      = ResourceEmit("CO2",1.)
products = [NG, Power, CO2]

# Creation of a dictionary with entries of 0. for all resources
𝒫₀ = Dict(k  => 0 for k ∈ products)

# Creation of a dictionary with entries of 0. for all emission resources
𝒫ᵉᵐ₀ = Dict(k  => 0. for k ∈ products if typeof(k) == ResourceEmit{Float64})
𝒫ᵉᵐ₀[CO2] = 0.0

# Creation of the time structure and the used global data
𝒯 = UniformTwoLevel(1, 1, 1, UniformTimes(1, 2, 1))
global_data = EMB.GlobalData(Dict(CO2 => FixedProfile(1e10),
                                  NG  => FixedProfile(1e6)
                                  ))

# Definition of the invidivual nodes
demand = [40 40]
nodes = [
        GEO.GeoAvailability(1, 𝒫₀, 𝒫₀),
        EMB.RefSource(2, FixedProfile(1e12), OperationalFixedProfile([10 100]), FixedProfile(0), Dict(NG => 1), 𝒫ᵉᵐ₀, Dict("" => EMB.EmptyData())),  
        EMB.RefGeneration(3, FixedProfile(100), FixedProfile(5.5), FixedProfile(0), Dict(NG => 2), Dict(Power => 1, CO2 => 1), 𝒫ᵉᵐ₀, 0, Dict("" => EMB.EmptyData())),  
        EMB.RefSink(4, DynamicProfile(demand), 
            Dict(:Surplus => FixedProfile(0), :Deficit => FixedProfile(1e6)), 
            Dict(Power => 1), 𝒫ᵉᵐ₀),
        
        GEO.GeoAvailability(5, 𝒫₀, 𝒫₀),
        EMB.RefSource(6, FixedProfile(1e12), OperationalFixedProfile([100 10]), FixedProfile(0), Dict(NG => 1), 𝒫ᵉᵐ₀, Dict("" => EMB.EmptyData())),  
        EMB.RefGeneration(7, FixedProfile(100), FixedProfile(5.5), FixedProfile(0), Dict(NG => 2), Dict(Power => 1, CO2 => 1), 𝒫ᵉᵐ₀, 0, Dict("" => EMB.EmptyData())),  
        EMB.RefSink(8, DynamicProfile(demand), 
            Dict(:Surplus => FixedProfile(0), :Deficit => FixedProfile(1e6)), 
            Dict(Power => 1), 𝒫ᵉᵐ₀),
        ]

# Definition of the links between the nodes in an area
links = [
        EMB.Direct(13,nodes[1],nodes[3],EMB.Linear())
        EMB.Direct(14,nodes[1],nodes[4],EMB.Linear())
        EMB.Direct(21,nodes[2],nodes[1],EMB.Linear())
        EMB.Direct(31,nodes[3],nodes[1],EMB.Linear())
        
        EMB.Direct(57,nodes[5],nodes[7],EMB.Linear())
        EMB.Direct(58,nodes[5],nodes[8],EMB.Linear())
        EMB.Direct(65,nodes[6],nodes[5],EMB.Linear())
        EMB.Direct(75,nodes[7],nodes[5],EMB.Linear())
        ]
  
# Definition of the two areas and the corresponding transmission line between them
areas = [GEO.Area(1, "Oslo", 10.751, 59.921, nodes[1]),
         GEO.Area(2, "Bergen", 5.334, 60.389, nodes[5])]
         
# Definition of the power lines
OverheadLine_50MW = GEO.RefStatic("PowerLine_50", Power, 30.0, 0.05, 2)
transmission = [GEO.Transmission(areas[1], areas[2], [OverheadLine_50MW],Dict(""=> EMB.EmptyData()))]

# Aggregation of the problem data
data = Dict(
            :areas          => Array{GEO.Area}(areas),
            :transmission   => Array{GEO.Transmission}(transmission),
            :nodes          => Array{EMB.Node}(nodes),
            :links          => Array{EMB.Link}(links),
            :products       => products,
            :T              => 𝒯,
            :global_data    => global_data,
            )

@testset "Bidirectional transmission" begin

    # Create and solve the model
    model = EMB.OperationalModel()
    m = GEO.create_model(data, model)
    set_optimizer(m, GLPK.Optimizer)
    optimize!(m)

    l   = transmission[1]
    cm  = l.Modes[1]
    # The sign should be the same for both directions
    
    @test sum(sign(value.(m[:trans_in])[l, t, cm]) 
              == sign(value.(m[:trans_out])[l, t, cm]) for t ∈ 𝒯) == length(𝒯)
    # Depending on the direction, check on the individual flows
    for t ∈ 𝒯
        if value.(m[:trans_in])[l, t, cm] <= 0
            @test abs(value.(m[:trans_in])[l, t, cm]) <= abs(value.(m[:trans_out])[l, t, cm])
            @test abs(value.(m[:trans_in])[l, t, cm]) == cm.Trans_cap
        else
            @test value.(m[:trans_out])[l, t, cm] <= value.(m[:trans_in])[l, t, cm]
            @test value.(m[:trans_out])[l, t, cm] == cm.Trans_cap
        end
    end

end
