using Pkg
# Activate the local environment including EnergyModelsGeography, HiGHS, PrettyTables
Pkg.activate(@__DIR__)
# Use dev version if run as part of tests
haskey(ENV, "EMX_TEST") && Pkg.develop(path=joinpath(@__DIR__,".."))
# Install the dependencies.
Pkg.instantiate()

# Import the required packages
using EnergyModelsBase
using EnergyModelsGeography
using JuMP
using HiGHS
using PrettyTables
using TimeStruct

const EMB = EnergyModelsBase
const EMG = EnergyModelsGeography

"""
    generate_example_network()

Generate the data for an example consisting of a simple electricity and CO₂ network. It is
loosely adapted from the `network.jl` example of `EnergyModelsBase`:
https://github.com/EnergyModelsX/EnergyModelsBase.jl/blob/main/examples/network.jl

The example consists of two areas, a coal area with a coal power plant, a flat electricity
demand, and a CO₂ storage site, and a natural gas area with a natural gas power plant with
CCS and a variable electricity demand. The latter has lower deficit costs if not sufficient
electricity is delivered.
"""
function generate_example_network()
    @info "Generate case data - Simple geographic example"

    # Define the different resources and their emission intensity in tCO2/MWh
    ng = ResourceCarrier("NG", 0.2)
    coal = ResourceCarrier("Coal", 0.35)
    power = ResourceCarrier("Power", 0.0)
    co2 = ResourceEmit("CO₂", 1.0)
    𝒫 = [ng, coal, power, co2]

    # Variables for the individual entries of the time structure
    op_duration = 4 # Each operational period has a duration of 4 (hours)
    op_number = 4   # There are in total 4 operational periods
    operational_periods = SimpleTimes(op_number, op_duration)

    # The number of operational periods times the duration of the operational periods, which
    # can also be extracted using the function `duration` of a `SimpleTimes` structure.
    # This implies, that a strategic period is 16 times longer than an operational period,
    # resulting in the values below as "/16h".
    op_per_strat = op_duration * op_number

    # Creation of the time structure and global data
    𝒯 = TwoLevel(2, 1, operational_periods; op_per_strat)
    model = OperationalModel(
        Dict(co2 => StrategicProfile([200, 100])),  # CO₂ emission cap in t/16h
        Dict(co2 => FixedProfile(0)),               # CO₂ emission cost in EUR/t
        co2,                                        # CO₂ instance
    )

    ## Create the first area: It consists of a coal sources, a coal power plant, an
    ## electricity demand with a fixed profile, and a CO₂ storage site
    # Create the nodes
    𝒩₁ = [
        GeoAvailability("Reg_1-Availability", 𝒫),
        RefSource(
            "Reg_1-Coal_source",        # Node id
            FixedProfile(100),          # Capacity in MW
            FixedProfile(9),            # Variable OPEX in EUR/MWh
            FixedProfile(0),            # Fixed OPEX in EUR/MW/16h
            Dict(coal => 1),            # Output from the Node, in this case, coal
        ),
        RefNetworkNode(
            "Reg_1-Coal_power_plant",   # Node id
            FixedProfile(25),           # Capacity in MW
            FixedProfile(6),            # Variable OPEX in EUR/MWh
            FixedProfile(0),            # Fixed OPEX in EUR/MW/16h
            Dict(coal => 2.5),          # Input to the node with input ratio
            Dict(power => 1),           # Output from the node with output ratio
            [EmissionsEnergy()],        # Additional data for emissions
            # Line above: `EmissionsEnergy` imply that the emissions data corresponds to
            # emissions through fuel usage as calculated by the CO₂ intensity and efficiency.
        ),
        RefStorage{AccumulatingEmissions}(
            "Reg_1-CO2_storage",        # Node id
            StorCapOpex(
                FixedProfile(60),       # Charge capacity in t/h
                FixedProfile(9.1),      # Storage variable OPEX for the charging in EUR/t
                FixedProfile(0)         # Storage fixed OPEX for the charging in EUR/(t/h 16h)
            ),
            StorCap(FixedProfile(600)), # Storage capacity in t
            co2,                        # Stored resource
            Dict(co2 => 1, power => 0.02), # Input resource with input ratio
            # Line above: This implies that storing CO₂ requires power
            Dict(co2 => 1),             # Output from the node with output ratio
            # Line above: In the case of `AccumulatingEmissions`, you must provide the
            # stored resource as one of the keys. Its value does however not matter as the
            # outlet flow value is fixed to 0.
        ),
        RefSink(
            "Reg_1-Electricity_demand", # Node id
            FixedProfile(10),           # Demand in MW
            Dict(:surplus => FixedProfile(0), :deficit => FixedProfile(1e3)),
            # Line above: Surplus and deficit penalty for the node in EUR/MWh
            Dict(power => 1),           # Energy demand and corresponding ratio
        ),
    ]

    # Connect all nodes with the availability node for the overall energy/mass balance
    # NOTE: This hard coding based on indexing is error prone. It is in general advised to
    #       use a mapping dictionary to avoid any problems when introducing new technology
    #       nodes.
    ℒ₁ = [
        Direct("Reg_1-av-coal_pp", 𝒩₁[1], 𝒩₁[3], Linear())
        Direct("Reg_1-av-CO2_stor", 𝒩₁[1], 𝒩₁[4], Linear())
        Direct("Reg_1-av-demand", 𝒩₁[1], 𝒩₁[5], Linear())
        Direct("Reg_1-coal_src-av", 𝒩₁[2], 𝒩₁[1], Linear())
        Direct("Reg_1-coal_pp-av", 𝒩₁[3], 𝒩₁[1], Linear())
    ]

    # Create the area
    area_1 = RefArea(1, "Coal area", 6.62, 51.04, 𝒩₁[1])

    ## Create the second area: It consists of a natural gas sources, a natrual gas power
    ## plant with CCS, and an electricity demand with a variable profile
    # Create the nodes
    𝒩₂ = [
        GeoAvailability("Reg_2-Availability", 𝒫),
        RefSource(
            "Reg_2-NG_source",          # Node id
            FixedProfile(100),          # Capacity in MW
            FixedProfile(30),           # Variable OPEX in EUR/MW
            FixedProfile(0),            # Fixed OPEX in EUR/MW/16h
            Dict(ng => 1),              # Output from the Node, in this case, ng
        ),
        RefNetworkNode(
            "Reg_2-ng+CCS_power_plant", # Node id
            FixedProfile(25),           # Capacity in MW
            FixedProfile(5.5),          # Variable OPEX in EUR/MWh
            FixedProfile(0),            # Fixed OPEX in EUR/MW/16h
            Dict(ng => 2),              # Input to the node with input ratio
            Dict(power => 1, co2 => 0), # Output from the node with output ratio
            # Line above: `co2` is required as output for variable definition, but the
            # value does not matter as it is not utilized in the model.
            [CaptureEnergyEmissions(0.9)],  # Additional data for emissions and CO₂ capture
            # Line above: `CaptureEnergyEmissions` imply that the emissions data corresponds
            # to emissions through fuel usage as calculated by the CO₂ intensity and efficiency.
            # 90 % of the CO₂ emissions are captured as given by the value 0.9.
        ),
        RefSink(
            "Reg_2-Electricity_demand", # Node id
            OperationalProfile([10, 20, 30, 20]),   # Demand in MW
            Dict(:surplus => FixedProfile(0), :deficit => FixedProfile(5e2)),
            # Line above: Surplus and deficit penalty for the node in EUR/MWh
            Dict(power => 1),           # Energy demand and corresponding ratio
        ),
    ]

    # Connect all nodes with the availability node for the overall energy/mass balance
    # NOTE: This hard coding based on indexing is error prone. It is in general advised to
    #       use a mapping dictionary to avoid any problems when introducing new technology
    #       nodes.
    ℒ₂ = [
        Direct("Reg_2-av-NG_pp", 𝒩₂[1], 𝒩₂[3], Linear())
        Direct("Reg_2-av-demand", 𝒩₂[1], 𝒩₂[4], Linear())
        Direct("Reg_2-NG_src-av", 𝒩₂[2], 𝒩₂[1], Linear())
        Direct("Reg_2-NG_pp-av", 𝒩₂[3], 𝒩₂[1], Linear())
    ]

    # Create the area
    area_2 = RefArea(2, "Natural gas area", 6.83, 53.45, 𝒩₂[1])

    # Merge the data into single vectors
    𝒩 = vcat(𝒩₁, 𝒩₂)
    ℒ = vcat(ℒ₁, ℒ₂)
    𝒜 = [area_1, area_2]

    # Create the transmission modes for transporting power and CO₂ between the areas
    power_line = RefStatic(
        "power_line",           # ID of the transmission mode
        power,                  # Transported resource
        FixedProfile(25),       # Capacity in MW
        FixedProfile(0.02),     # Relative loss as fraction of the transported energy
        FixedProfile(0),        # Variable OPEX in EUR/MWh
        FixedProfile(0),        # Fixed OPEX in EUR/MW/16h
        2,                      # Directions of transport, in this case, bidirectional
    )
    co2_pipeline = PipeSimple(
        "co2_pipeline",         # ID of the transmission mode
        co2,                    # Resource at the inlet
        co2,                    # Resource at the outlet
        power,                  # Additional required resource for transportation
        FixedProfile(0.01),     # Fraction of `CO₂` required as `power` for transporting the resource in MWh/t
        # Line above: the fraction can be seen as, e.g., pumping or compression requirement
        FixedProfile(25),       # Capacity in t/h
        FixedProfile(0),        # Relative loss as fraction of the transported `CO₂`
        FixedProfile(0),        # Variable OPEX in EUR/t
        FixedProfile(0),        # Fixed OPEX in EUR/(t/h)/16h
    )

    # Create the transmission corridor between the two areas
    # Note that the corridor is defined from the natural gas area as pipeline transport is
    # always unidirectional
    ℒᵗʳᵃⁿˢ = [Transmission(𝒜[2], 𝒜[1], [power_line, co2_pipeline])]

    # Input data structure
    # It is also explained on
    # https://energymodelsx.github.io/EnergyModelsBase.jl/stable/library/public/case_element/
    case = Case(
        𝒯,                  # Chosen time structure
        𝒫,                  # Resources used
        [𝒩, ℒ, 𝒜, ℒᵗʳᵃⁿˢ],  # Nodes, Links, Areas, and Transmission corridors used
        [[get_nodes, get_links], [get_areas, get_transmissions]],
        # Line above: the first vector corresponds to the original couplings between `Node`said
        # through `Link`s. The second vector introduces couplings between `Area`s through
        # `Transmission` corridors.
    )
    return case, model
end

# Generate the case and model data and run the model
case, model = generate_example_network()
optimizer = optimizer_with_attributes(HiGHS.Optimizer, MOI.Silent() => true)
m = run_model(case, model, optimizer)

"""
    process_network_results(m, case)

Function for processing the results to be represented in the a table afterwards.
"""
function process_network_results(m, case)
    # Extract the nodes and transmission modes from the data
    coal_pp, demand_1, ng_ccs_pp, demand_2 = get_nodes(case)[[3, 5, 8, 9]]
    power_line, co2_pipe = modes(get_transmissions(case))

    # Transmission variables
    pl_in = sort(                   # Inlet to the power line
            JuMP.Containers.rowtable(
                value,
                m[:trans_in][power_line, :];
                header = [:t, :val],
        ),
        by = x -> x.t,
    )
    pl_out = sort(                  # Outlet from the power line
            JuMP.Containers.rowtable(
                value,
                m[:trans_out][power_line, :];
                header = [:t, :val],
        ),
        by = x -> x.t,
    )
    coal_pp_cap_use = sort(        # coal pp capacity usage
            JuMP.Containers.rowtable(
                value,
                m[:cap_use][coal_pp, :];
                header = [:t, :val],
        ),
        by = x -> x.t,
    )
    ng_ccs_pp_cap_use = sort(       # CCGT capacity usage
            JuMP.Containers.rowtable(
                value,
                m[:cap_use][ng_ccs_pp, :];
                header = [:t, :val],
        ),
        by = x -> x.t,
    )
    deficit_1 = sort(               # Deficit of the demand in area 1
            JuMP.Containers.rowtable(
                value,
                m[:sink_deficit][demand_1, :];
                header = [:t, :val],
        ),
        by = x -> x.t,
    )
    deficit_2 = sort(               # Deficit of the demand in area 2
            JuMP.Containers.rowtable(
                value,
                m[:sink_deficit][demand_2, :];
                header = [:t, :val],
        ),
        by = x -> x.t,
    )

    # Set up the individual named tuples as a single named tuple
    table = [(
            t = repr(con_1.t),
            power_line_in = round(con_1.val; digits=1),
            power_line_out = round(con_2.val; digits=1),
            usage_coal_pp = round(con_3.val; digits=1),
            usage_ng_pp = round(con_4.val; digits=1),
            deficit_area_1 = round(con_5.val; digits=1),
            deficit_area_2 = round(con_6.val; digits=1),
        ) for (con_1, con_2, con_3, con_4, con_5, con_6) ∈
        zip(pl_in, pl_out, coal_pp_cap_use, ng_ccs_pp_cap_use, deficit_1, deficit_2)
    ]
    return table
end

# Display some results
table = process_network_results(m, case)

@info(
    "Individual results from the simple network:\n" *
    "Negative values correspond to flow from area 1 to area 2 while positive values \n" *
    "correspond to flow from area 2 to area 1.\n\n" *
    "The power flow between the different regions is governed by the increasing demand in\n" *
    "area 2 in operational period 3 in which the additional demand must be supplied by\n" *
    "area 1. In addition, the limit on CO₂ emissions forces a limited use of the coal\n" *
    "power plant already in one of the other operational periods in strategic period 1\n" *
    "as well as increased usage of the NG power plant in strategic period 2, including\n" *
    "increased power transmission to area 1. Due to the higher deficit penalty, the\n" *
    "deficit is occuring in area 2.\n\n" *
    "The total electricity generation is higher than the total demand due to the demand\n" *
    "for transporting and storing the CO₂ as well as the transmission losses."
)
pretty_table(table)
