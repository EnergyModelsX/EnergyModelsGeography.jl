function run_model(fn, optimizer=nothing)
   @debug "Run model" fn optimizer

    data = read_data()
    case = EMB.OperationalCase(StrategicFixedProfile([450, 400, 350, 300]))
    model = EMB.GeographyModel(case)
    m = create_model(data, model)

    if !isnothing(optimizer)
        set_optimizer(m, optimizer)
        optimize!(m)
        # TODO: print_solution(m) optionally show results summary (perhaps using upcoming JuMP function)
        # TODO: save_solution(m) save results
    else
        @info "No optimizer given"
    end
    return m, data
end

function read_data()
    @debug "Read data"
    @info "Hard coded dummy model for now"

    𝒫₀, 𝒫ᵉᵐ₀, products = get_resources()

    #
    area_ids = [1, 2, 3, 4]
    d_scale = Dict(1=>3.0, 2=>1.5, 3=>1.0, 4=>0.5)
    mc_scale = Dict(1=>2.0, 2=>2.0, 3=>1.5, 4=>0.5)


    # Create identical areas with index accoriding to input array
    an = Dict()
    transmission = []
    nodes = []
    links = []
    for a_id in area_ids
        n, l = get_sub_system_data(a_id, 𝒫₀, 𝒫ᵉᵐ₀, products, mc_scale = mc_scale[a_id], d_scale = d_scale[a_id])
        append!(nodes, n)
        append!(links, l)

        # Add area node for each subsystem
        an[a_id] = n[1]
    end

    areas = [Area(1, "Oslo", 10.751, 59.921, an[1]),
             Area(2, "Bergen", 5.334, 60.389, an[2]),
             Area(3, "Trondheim", 10.398, 63.4366, an[3]),
             Area(4, "Tromsø", 18.953, 69.669, an[4])]

    NG = products[2]
    Power = products[3]

    OverheadLine_50MW = RefStatic("PowerLine_50", Power, 50.0, 0.05)#, EMB.Linear)
    LNG_Ship_100MW = RefDynamic("LNG_100", NG, 100.0, 0.05)#, EMB.Linear)

    # Create transmission between areas
    transmission = [Transmission(areas[1], areas[2], [OverheadLine_50MW]),
                    Transmission(areas[1], areas[3], [OverheadLine_50MW]),
                    Transmission(areas[2], areas[3], [OverheadLine_50MW]),
                    Transmission(areas[3], areas[4], [OverheadLine_50MW]),
                    Transmission(areas[4], areas[2], [LNG_Ship_100MW])]

    T = UniformTwoLevel(1, 4, 1, UniformTimes(1, 24, 1))
    # WIP data structure
    data = Dict(
                :areas => Array{Area}(areas),
                :transmission => Array{Transmission}(transmission),
                :nodes => Array{EMB.Node}(nodes),
                :links => Array{EMB.Link}(links),
                :products => products,
                :T => T
                )
    return data
end

function get_resources()

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
function get_sub_system_data(i,𝒫₀, 𝒫ᵉᵐ₀, products; mc_scale::Float64=1.0, d_scale::Float64=1.0)

    NG, Coal, Power, CO2 = products

    demand = [20 20 20 20 25 30 35 35 40 40 40 40 40 35 35 30 25 30 35 30 25 20 20 20;
              20 20 20 20 25 30 35 35 40 40 40 40 40 35 35 30 25 30 35 30 25 20 20 20;
              20 20 20 20 25 30 35 35 40 40 40 40 40 35 35 30 25 30 35 30 25 20 20 20;
              20 20 20 20 25 30 35 35 40 40 40 40 40 35 35 30 25 30 35 30 25 20 20 20]
    demand *= d_scale

    j=(i-1)*100
    nodes = [
            EMB.Availability(j+1, 𝒫₀, 𝒫₀),
            EMB.RefSource(j+2, FixedProfile(1e12), FixedProfile(30*mc_scale), Dict(NG => 1), 𝒫ᵉᵐ₀),  
            EMB.RefSource(j+3, FixedProfile(1e12), FixedProfile(9*mc_scale), Dict(Coal => 1), 𝒫ᵉᵐ₀),  
            EMB.RefGeneration(j+4, FixedProfile(25), FixedProfile(5.5*mc_scale), Dict(NG => 2), Dict(Power => 1, CO2 => 1), 𝒫ᵉᵐ₀, 0.9),  
            EMB.RefGeneration(j+5, FixedProfile(25), FixedProfile(6*mc_scale),  Dict(Coal => 2.5), Dict(Power => 1, CO2 => 1), 𝒫ᵉᵐ₀, 0),  
            EMB.RefStorage(j+6, FixedProfile(20), 600, FixedProfile(9.1),  Dict(CO2 => 1, Power => 0.02), Dict(CO2 => 1)),
            EMB.RefSink(j+7, DynamicProfile(demand),
                    Dict(:surplus => 0, :deficit => 1e6), Dict(Power => 1), 𝒫ᵉᵐ₀),
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