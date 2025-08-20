using Pkg
# Activate the local environment including EnergyModelsInvestments, HiGHS, PrettyTables
Pkg.activate(@__DIR__)
# Use dev version if run as part of tests
haskey(ENV, "EMX_TEST") && Pkg.develop(path=joinpath(@__DIR__,".."))
# Install the dependencies.
Pkg.instantiate()

# Import the required packages
using EnergyModelsBase
using EnergyModelsGeography
using EnergyModelsInvestments
using HiGHS
using JuMP
using PrettyTables
using TimeStruct

const EMB = EnergyModelsBase
const EMG = EnergyModelsGeography
const EMI = EnergyModelsInvestments

"""
    generate_example_network_investment()

Generate the data for an example consisting of a simple electricity and CO₂ network. It is
loosely adapted from the `network.jl` example of `EnergyModelsBase`:
https://github.com/EnergyModelsX/EnergyModelsBase.jl/blob/main/examples/network.jl

The example consists of two areas, a coal area with a coal power plant, a flat electricity
demand, and a CO₂ storage site, and a natural gas area with a natural gas power plant with
CCS and a variable electricity demand. The latter has lower deficit costs if not sufficient
electricity is delivered.

There is initially no transmission capacity between both areas, neither for electricity, nor
for CO₂. As a consequence, exchange of energy or mass requires investing into transmission
capacity.
"""
function generate_example_network_investment()
    @info "Generate case data - Simple geographic example with investments"

    # Define the different resources and their emission intensity in tCO2/MWh
    NG = ResourceCarrier("NG", 0.2)
    Coal = ResourceCarrier("Coal", 0.35)
    Power = ResourceCarrier("Power", 0.0)
    CO2 = ResourceEmit("CO₂", 1.0)
    𝒫 = [NG, Coal, Power, CO2]

    # Variables for the individual entries of the time structure
    op_duration = 4 # Each operational period has a duration of 4
    op_number = 4   # There are in total 4 operational periods
    operational_periods = SimpleTimes(op_number, op_duration)

    # Each operational period should correspond to a duration of 4 h while a duration if 1
    # of a strategic period should correspond to a year.
    # This implies, that a strategic period is 8760 times longer than an operational period,
    # resulting in the values below as "/year".
    op_per_strat = 8760

    # Creation of the time structure and global data
    𝒯 = TwoLevel(2, 1, operational_periods; op_per_strat)
    model = InvestmentModel(
        Dict(CO2 => StrategicProfile([200, 100].*500)), # CO₂ emission cap in t/year
        Dict(CO2 => FixedProfile(0)),               # CO₂ emission cost in EUR/t
        CO2,                                        # CO2 instance
        0.07,                                       # Discount rate in absolute value
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
            FixedProfile(0),            # Fixed OPEX in EUR/MW/year
            Dict(Coal => 1),            # Output from the Node, in this case, coal
        ),
        RefNetworkNode(
            "Reg_1-Coal_power_plant",   # Node id
            FixedProfile(25),           # Capacity in MW
            FixedProfile(6),            # Variable OPEX in EUR/MWh
            FixedProfile(0),            # Fixed OPEX in EUR/MW/year
            Dict(Coal => 2.5),          # Input to the node with input ratio
            Dict(Power => 1),           # Output from the node with output ratio
            [EmissionsEnergy()],        # Additional data for emissions
        ),
        RefStorage{AccumulatingEmissions}(
            "Reg_1-CO2_storage",        # Node id
            StorCapOpex(
                FixedProfile(60),       # Charge capacity in t/h
                FixedProfile(9.1),      # Storage variable OPEX for the charging in EUR/t
                FixedProfile(0)         # Storage fixed OPEX for the charging in EUR/(t/h year)
            ),
            StorCap(FixedProfile(600)), # Storage capacity in t
            CO2,                        # Stored resource
            Dict(CO2 => 1, Power => 0.02), # Input resource with input ratio
            # Line above: This implies that storing CO₂ requires Power
            Dict(CO2 => 1),             # Output from the node with output ratio
            # In practice, for CO₂ storage, this is never used.
        ),
        RefSink(
            "Reg_1-Electricity_demand", # Node id
            FixedProfile(10),           # Demand in MW
            Dict(:surplus => FixedProfile(0), :deficit => FixedProfile(1e3)),
            # Line above: Surplus and deficit penalty for the node in EUR/MWh
            Dict(Power => 1),           # Energy demand and corresponding ratio
        ),
    ]

    # Connect all nodes with the availability node for the overall energy/mass balance
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
            FixedProfile(200),          # Capacity in MW
            FixedProfile(30),           # Variable OPEX in EUR/MW
            FixedProfile(0),            # Fixed OPEX in EUR/MW/year
            Dict(NG => 1),              # Output from the Node, in this case, NG
        ),
        RefNetworkNode(
            "Reg_2-NG+CCS_power_plant", # Node id
            StrategicProfile([25, 50]), # Capacity in MW
            FixedProfile(5.5),          # Variable OPEX in EUR/MWh
            FixedProfile(0),            # Fixed OPEX in EUR/MW/year
            Dict(NG => 2),              # Input to the node with input ratio
            Dict(Power => 1, CO2 => 1), # Output from the node with output ratio
            # Line above: CO2 is required as output for variable definition, but the
            # value does not matter
            [CaptureEnergyEmissions(0.9)],  # Additional data for emissions and CO₂ capture
        ),
        RefSink(
            "Reg_2-Electricity_demand", # Node id
            OperationalProfile([10, 20, 30, 20]),           # Demand in MW
            Dict(:surplus => FixedProfile(0), :deficit => FixedProfile(5e2)),
            # Line above: Surplus and deficit penalty for the node in EUR/MWh
            Dict(Power => 1),           # Energy demand and corresponding ratio
        ),
    ]

    # Connect all nodes with the availability node for the overall energy/mass balance
    ℒ₂ = [
        Direct("Reg_2-av-NG_pp", 𝒩₂[1], 𝒩₂[3], Linear())
        Direct("Reg_2-av-demand", 𝒩₂[1], 𝒩₂[4], Linear())
        Direct("Reg_2-NG_src-av", 𝒩₂[2], 𝒩₂[1], Linear())
        Direct("Reg_2-NG_pp-av", 𝒩₂[3], 𝒩₂[1], Linear())
    ]

    # Create the area
    area_2 = RefArea(2, "Natural gas area", 53.45, 6.83, 𝒩₂[1])

    # Merge the data into single vectors
    𝒩 = vcat(𝒩₁, 𝒩₂)
    ℒ = vcat(ℒ₁, ℒ₂)
    𝒜 = [area_1, area_2]

    # Create the transmission modes for transporting power and CO₂ between the areas
    power_inv_data = SingleInvData(
        FixedProfile(50 * 1e3), # Capex in EUR/MW
        FixedProfile(10),       # Max installed capacity [MW]
        ContinuousInvestment(FixedProfile(0), FixedProfile(10)),
        # Line above: Investment mode with the following arguments:
        # 1. argument: min added capactity per investment period [MW]
        # 2. argument: max added capactity per investment period [MW]
    )
    power_line = RefStatic(
        "power_line",           # ID of the transmission mode
        Power,                  # Transported resource
        FixedProfile(0),        # Capacity in MW
        FixedProfile(0.02),     # Relative loss
        FixedProfile(0),        # Variable OPEX in EUR/MWh
        FixedProfile(0),        # Fixed OPEX in EUR/MW/year
        2,                      # Directions of transport, in this case, bidirectional
        [power_inv_data],
    )
    co2_pipe_inv_data = SingleInvData(
        FixedProfile(260 * 1e3),  # Capex in EUR/(t/h)
        FixedProfile(40),       # Max installed capacity [t/h]
        SemiContinuousInvestment(FixedProfile(5), FixedProfile(20)),
        # Line above: Investment mode with the following arguments:
        # 1. argument: min added capactity per investment period [t/h]
        # 2. argument: max added capactity per investment period [t/h]
    )
    co2_pipeline = PipeSimple(
        "co2_pipeline",         # ID of the transmission mode
        CO2,                    # Resource at the inlet
        CO2,                    # Resource at the outlet
        Power,                  # Additional required resource for transportation
        FixedProfile(0.01),     # Relative demand for transporting the resource in MWh/t
        FixedProfile(0),        # Capacity in t/h
        FixedProfile(0),        # Relative loss
        FixedProfile(0),        # Variable OPEX in EUR/t
        FixedProfile(0),        # Fixed OPEX in EUR/(t/h)/year
        [co2_pipe_inv_data],
    )

    # Create the transmission corridor between the two areas
    # Note that the corridor is defined from the natural gas area as pipeline transport is
    # always unidirectional
    ℒᵗʳᵃⁿˢ = [Transmission(𝒜[2], 𝒜[1], [power_line, co2_pipeline])]

    # Input data structure
    case = Case(
        𝒯,
        𝒫,
        [𝒩, ℒ, 𝒜, ℒᵗʳᵃⁿˢ],
        [[get_nodes, get_links], [get_areas, get_transmissions]],
    )
    return case, model
end

# Generate the case and model data and run the model
case, model = generate_example_network_investment()
optimizer = optimizer_with_attributes(HiGHS.Optimizer, MOI.Silent() => true)
m = run_model(case, model, optimizer)

"""
    process_investment_results(m, case)

Function for processing the results to be represented in the a table afterwards.
"""
function process_investment_results(m, case)
    # Extract the transmission modes from the data
    power_line, co2_pipe = modes(get_transmissions(case))
    𝒯ⁱⁿᵛ = strategic_periods(get_time_struct(case))
    sp_1 = first(𝒯ⁱⁿᵛ)
    sp_2 = last(𝒯ⁱⁿᵛ)

    # Transmission variables
    pl_add = sort(                  # Added capacity of the power line
            JuMP.Containers.rowtable(
                value,
                m[:trans_cap_add][power_line, :];
                header = [:t_inv, :val],
        ),
        by = x -> x.t_inv,
    )
    pl_inst = sort(                  # Total capacity of the power line
            JuMP.Containers.rowtable(
                value,
                m[:trans_cap_current][power_line, :];
                header = [:t_inv, :val],
        ),
        by = x -> x.t_inv,
    )
    pl_max_use = [
        (t_inv = sp_1, val = maximum([-value.(m[:trans_in])[power_line, t] for t ∈ sp_1]))
        (t_inv = sp_2, val = maximum([value.(m[:trans_out])[power_line, t] for t ∈ sp_2]))
    ]
    co2_add = sort(                  # Added capacity of the CO₂ pipeline
            JuMP.Containers.rowtable(
                value,
                m[:trans_cap_add][co2_pipe, :];
                header = [:t_inv, :val],
        ),
        by = x -> x.t_inv,
    )
    co2_inst = sort(                  # Total capacity of the CO₂ pipeline
            JuMP.Containers.rowtable(
                value,
                m[:trans_cap_current][co2_pipe, :];
                header = [:t_inv, :val],
        ),
        by = x -> x.t_inv,
    )
    co2_max_use = [
        (t_inv = sp_1, val = maximum([value.(m[:trans_in])[co2_pipe, t] for t ∈ sp_1]))
        (t_inv = sp_2, val = maximum([value.(m[:trans_in])[co2_pipe, t] for t ∈ sp_2]))
    ]

    # Set up the individual named tuples as a single named tuple
    table = [(
            t_inv = repr(con_1.t_inv),
            power_line_add = round(con_2.val; digits=1),
            power_line_inst = round(con_1.val; digits=1),
            power_line_max_use = round(con_3.val; digits=1),
            co2_pipe_add = round(con_5.val; digits=1),
            co2_pipe_inst = round(con_4.val; digits=1),
            co2_pipe_max_use = round(con_6.val; digits=1),
        ) for (con_1, con_2, con_3, con_4, con_5, con_6) ∈
        zip(pl_inst, pl_add, pl_max_use, co2_inst, co2_add, co2_max_use)
    ]
    return table
end

# Display some results
table = process_investment_results(m, case)

@info(
    "Individual results from the simple network:\n" *
    "The optimization results in investing in both the CO₂ pipeline and the power line.\n" *
    "The power line only invests in the required capacity in each strategic period as it\n" *
    "allows for continuous investments. The CO₂ pipeline is however modelled as semi-\n" *
    "continuous investment with a minimum capacity addition of 5 t/h if investments occur.\n" *
    "As a consequence, it overinvests in the first strategic period to account for the\n" *
    "required capacity in the second strategic period.\n"
)
pretty_table(table)
