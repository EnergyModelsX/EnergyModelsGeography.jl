function run_model(fn, modeltype, optimizer=nothing)
   @debug "Run model" fn optimizer

    case = read_data(modeltype)
    m = create_model(case, modeltype)

    if !isnothing(optimizer)
        set_optimizer(m, optimizer)
        optimize!(m)
        # TODO: print_solution(m) optionally show results summary (perhaps using upcoming JuMP function)
        # TODO: save_solution(m) save results
    else
        @info "No optimizer given"
    end
    return m, case
end

function read_data(modeltype)
    @debug "Read case data"
    @info "Hard coded dummy model for now."

    # Retrieve the products
    𝒫₀, 𝒫ᵉᵐ₀, products = get_resources()
    NG    = products[1]
    Power = products[3]
    CO2   = products[4]

    # Create input data for the areas
    area_ids    = [1, 2, 3, 4, 5, 6, 7]
    d_scale     = Dict(1=>3.0, 2=>1.5, 3=>1.0, 4=>0.5, 5=>0.5, 6=>0.0, 7=>3.0)
    gen_scale   = Dict(1=>1.0, 2=>1.0, 3=>1.0, 4=>0.5, 5=>1.0, 6=>1.0, 7=>1.0)
    mc_scale    = Dict(1=>2.0, 2=>2.0, 3=>1.5, 4=>0.5, 5=>0.5, 6=>0.5, 7=>3.0)

    tromsø_demand = [10 10 10 10 35 40 45 45 50 50 60 60 50 45 45 40 35 40 45 40 35 30 30 30;
                     20 20 20 20 25 30 35 35 40 40 40 40 40 35 35 30 25 30 35 30 25 20 20 20;
                     20 20 20 20 25 30 35 35 40 40 40 40 40 35 35 30 25 30 35 30 25 20 20 20;
                     20 20 20 20 25 30 35 35 40 40 40 40 40 35 35 30 25 30 35 30 25 20 20 20]
    demand = Dict(1=>false, 2=>false, 3=>false, 4=>tromsø_demand, 5=>false, 6=>false, 7=>false)

    # Create identical areas with index accoriding to input array
    an           = Dict()
    transmission = []
    nodes        = []
    links        = []
    for a_id in area_ids
        n, l = get_sub_system_data(a_id, 𝒫₀, 𝒫ᵉᵐ₀, products, modeltype;
                                   gen_scale = gen_scale[a_id], mc_scale = mc_scale[a_id],
                                   d_scale = d_scale[a_id], demand=demand[a_id])
        append!(nodes, n)
        append!(links, l)

        # Add area node for each subsystem
        an[a_id] = n[1]
    end

    # Create the individual areas and transmission modes
    areas = [Area(1, "Oslo", 10.751, 59.921, an[1]),
             Area(2, "Bergen", 5.334, 60.389, an[2]),
             Area(3, "Trondheim", 10.398, 63.4366, an[3]),
             Area(4, "Tromsø", 18.953, 69.669, an[4]),
             Area(5, "Kristiansand", 7.984, 58.146, an[5]),
             Area(6, "Sørlige Nordsjø II", 6.836, 57.151, an[6]),
             Area(7, "Danmark", 8.614, 56.359, an[7])]

    OverheadLine_50MW   = RefStatic("PowerLine_50", Power, 50.0, 0.05, 2)#, EMB.Linear)
    LNG_Ship_100MW      = RefDynamic("LNG_100", NG, 100.0, 0.05, 1)#, EMB.Linear)

    # Create transmission between areas
    transmission = [Transmission(areas[1], areas[2], [OverheadLine_50MW],[Dict(""=> EMB.EmptyData())]),
                    Transmission(areas[3], areas[1], [OverheadLine_50MW],[Dict(""=> EMB.EmptyData())]),
                    Transmission(areas[2], areas[3], [OverheadLine_50MW],[Dict(""=> EMB.EmptyData())]),
                    Transmission(areas[3], areas[4], [OverheadLine_50MW],[Dict(""=> EMB.EmptyData())]),
                    Transmission(areas[1], areas[5], [OverheadLine_50MW],[Dict(""=> EMB.EmptyData())]),
                    Transmission(areas[2], areas[5], [OverheadLine_50MW],[Dict(""=> EMB.EmptyData())]),
                    Transmission(areas[5], areas[6], [OverheadLine_50MW],[Dict(""=> EMB.EmptyData())]),
                    Transmission(areas[6], areas[7], [OverheadLine_50MW],[Dict(""=> EMB.EmptyData())]),
                    Transmission(areas[4], areas[2], [LNG_Ship_100MW],[Dict(""=> EMB.EmptyData())])]

    # Creation of the time structure and global data
    T = UniformTwoLevel(1, 4, 1, UniformTimes(1, 24, 1))
    global_data = EMB.EMB_global_data(Dict(CO2 => StrategicFixedProfile([450, 400, 350, 300]),
                                           NG  => FixedProfile(1e6))
                                      )

    # WIP data structure
    case = Dict(
                :areas          => Array{Area}(areas),
                :transmission   => Array{Transmission}(transmission),
                :nodes          => Array{EMB.Node}(nodes),
                :links          => Array{EMB.Link}(links),
                :products       => products,
                :T              => T,
                :global_data    => global_data,
                )
    return case
end

function get_resources()

    # Define the different resources
    NG       = ResourceEmit("NG", 0.2)
    Coal     = ResourceCarrier("Coal", 0.35)
    Power    = ResourceCarrier("Power", 0.)
    CO2      = ResourceEmit("CO2",1.)
    products = [NG, Coal, Power, CO2]

    # Creation of a dictionary with entries of 0. for all resources
    𝒫₀ = Dict(k  => 0 for k ∈ products)

    # Creation of a dictionary with entries of 0. for all emission resources
    𝒫ᵉᵐ₀ = Dict(k  => 0. for k ∈ products if typeof(k) == ResourceEmit{Float64})
    𝒫ᵉᵐ₀[CO2] = 0.0

    return 𝒫₀, 𝒫ᵉᵐ₀, products
end

# Subsystem test data for geography package
function get_sub_system_data(i,𝒫₀, 𝒫ᵉᵐ₀, products, modeltype;
                             gen_scale::Float64=1.0, mc_scale::Float64=1.0, d_scale::Float64=1.0, demand=false)
    
    NG, Coal, Power, CO2 = products

    # Use of standard demand if not provided differently
    if demand == false
        demand = [20 20 20 20 25 30 35 35 40 40 40 40 40 35 35 30 25 30 35 30 25 20 20 20;
                  20 20 20 20 25 30 35 35 40 40 40 40 40 35 35 30 25 30 35 30 25 20 20 20;
                  20 20 20 20 25 30 35 35 40 40 40 40 40 35 35 30 25 30 35 30 25 20 20 20;
                  20 20 20 20 25 30 35 35 40 40 40 40 40 35 35 30 25 30 35 30 25 20 20 20]
        demand *= d_scale
    end

    j=(i-1)*100
    nodes = [
            GeoAvailability(j+1, 𝒫₀, 𝒫₀),
            EMB.RefSource(j+2, FixedProfile(1e12), FixedProfile(30*mc_scale), FixedProfile(0), Dict(NG => 1), 𝒫ᵉᵐ₀, Dict("" => EMB.EmptyData())),  
            EMB.RefSource(j+3, FixedProfile(1e12), FixedProfile(9*mc_scale), FixedProfile(0), Dict(Coal => 1), 𝒫ᵉᵐ₀, Dict("" => EMB.EmptyData())),  
            EMB.RefGeneration(j+4, FixedProfile(25), FixedProfile(5.5*mc_scale), FixedProfile(0), Dict(NG => 2), Dict(Power => 1, CO2 => 1), 𝒫ᵉᵐ₀, 0.9, Dict("" => EMB.EmptyData())),  
            EMB.RefGeneration(j+5, FixedProfile(25), FixedProfile(6*mc_scale), FixedProfile(0),  Dict(Coal => 2.5), Dict(Power => 1, CO2 => 1), 𝒫ᵉᵐ₀, 0, Dict("" => EMB.EmptyData())),  
            EMB.RefStorage(j+6, FixedProfile(20), FixedProfile(600), FixedProfile(9.1), FixedProfile(0),  Dict(CO2 => 1, Power => 0.02), Dict(CO2 => 1), Dict("" => EMB.EmptyData())),
            EMB.RefSink(j+7, DynamicProfile(demand),
                    Dict(:Surplus => 0, :Deficit => 1e6), Dict(Power => 1), 𝒫ᵉᵐ₀),
            ]

    links = [
            EMB.Direct(j+14,nodes[1],nodes[4],EMB.Linear())
            EMB.Direct(j+15,nodes[1],nodes[5],EMB.Linear())
            EMB.Direct(j+16,nodes[1],nodes[6],EMB.Linear())
            EMB.Direct(j+17,nodes[1],nodes[7],EMB.Linear())
            EMB.Direct(j+21,nodes[2],nodes[1],EMB.Linear())
            EMB.Direct(j+31,nodes[3],nodes[1],EMB.Linear())
            EMB.Direct(j+41,nodes[4],nodes[1],EMB.Linear())
            EMB.Direct(j+51,nodes[5],nodes[1],EMB.Linear())
            EMB.Direct(j+61,nodes[6],nodes[1],EMB.Linear())
            ]
    return nodes, links
end