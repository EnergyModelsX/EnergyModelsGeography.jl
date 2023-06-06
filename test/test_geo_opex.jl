

function solve_and_check(case, modeltype, A_B_t1, B_A_t2)

    # Create and solve the model
    m = optimize(case, modeltype)

    # Get times and transmission mode
    T = collect(case[:T])
    tm = case[:transmission][1].Modes[1]


    if typeof(A_B_t1) == String
        A_B_t1 = getfield(tm, Symbol(A_B_t1))[T[1]]
    end
    if typeof(B_A_t2) == String
        B_A_t2 = getfield(tm, Symbol(B_A_t2))[T[2]]
    end

    # Check flow in the positive direction in t1
    @test value.(m[:trans_out])[tm, T[1]] == A_B_t1
    # Check flow in the negative direction in t2
    @test abs(value.(m[:trans_in])[tm, T[2]]) == B_A_t2

    return m
end

@testset "Opex transmission" begin

    # Reading of the case data
    case, modeltype = bidirectional_case()

    t_cap = FixedProfile(30.0)
    t_loss = FixedProfile(0.0)
    t_opex_var = FixedProfile(0.0)
    t_opex_fixed = FixedProfile(0.0)

    # increase opex var, but not enough to change the results
    case[:transmission][1].Modes[1] = RefStatic("Transline", Power, t_cap, t_loss, t_opex_var, t_opex_fixed, 2, [])

    # Create and solve the model
    m = optimize(case, modeltype)

    # Get reference objective value without any trans opex
    obj_val_no_opex = objective_value(m)

    fuel_opex_diff = 90
    gen_fuel_coeff = 2
    marginal_diff = 1

    # TEST 1: Low trans opex does not chage results

    # Cange transmission mode parameters
    t_opex_var = FixedProfile((fuel_opex_diff - marginal_diff) * gen_fuel_coeff)
    case[:transmission][1].Modes[1] = RefStatic("Transline", Power, t_cap, t_loss, t_opex_var, t_opex_fixed, 2, [])

    m = solve_and_check(case, modeltype, "Trans_cap", "Trans_cap")

    # TEST 2: Opex restricts flow in both periods

    # increase opex var, so high that transmission in not profitable
    t_opex_var = FixedProfile((fuel_opex_diff + marginal_diff) * gen_fuel_coeff)
    case[:transmission][1].Modes[1] = RefStatic("Transline", Power, t_cap, t_loss, t_opex_var, t_opex_fixed, 2, [])

    m = solve_and_check(case, modeltype, 0.0, 0.0)

    # TEST 3: fixed opex does not chage flow, but does change the objective value

    # Cange transmission mode parameters
    t_opex_var = FixedProfile(0.0) # no opex var
    t_opex_fixed = FixedProfile(1e3) # high opex fixed
    case[:transmission][1].Modes[1] = RefStatic("Transline", Power, t_cap, t_loss, t_opex_var, t_opex_fixed, 2, [])

    m = solve_and_check(case, modeltype, "Trans_cap", "Trans_cap")

    # Check objective value
    @test objective_value(m) == obj_val_no_opex - 1e3 * case[:transmission][1].Modes[1].Trans_cap.val

    # TEST 4: Repeat TEST 1 with unidirectional transmission mode

    # Cange transmission mode parameters
    t_opex_var = FixedProfile((fuel_opex_diff - marginal_diff) * gen_fuel_coeff)
    case[:transmission][1].Modes[1] = RefStatic("Transline", Power, t_cap, t_loss, t_opex_var, t_opex_fixed, 1, [])

    m = solve_and_check(case, modeltype, "Trans_cap", 0.0)

    # TEST 5: Repeat TEST 2 with unidirectional transmission mode

    # increase opex var, so high that transmission in not profitable
    t_opex_var = FixedProfile((fuel_opex_diff + marginal_diff) * gen_fuel_coeff)
    case[:transmission][1].Modes[1] = RefStatic("Transline", Power, t_cap, t_loss, t_opex_var, t_opex_fixed, 1, [])

    m = solve_and_check(case, modeltype, 0.0, 0.0)  


end