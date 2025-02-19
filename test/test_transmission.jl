@testset "Transmission utilities" begin

    # Initialize the individual modes of the corridors
    ℳ = Dict()
    n_trans = 5
    n_stat = rand(1:10, n_trans)
    n_dyn = rand(1:10, n_trans)
    n_pipe = rand(1:10, n_trans)
    for k ∈ range(1, n_trans)
        ℳ[k] = mode_subset(; t=k, n_stat=n_stat[k], n_dyn = n_dyn[k], n_pipe = n_pipe[k])
    end

    # Create the Transmission corridors
    products = [H2_hp, H2_lp, Power, CO2]
    av = GeoAvailability(1, products)
    ℒᵗʳᵃⁿˢ = Transmission[]
    for k ∈ range(1,n_trans)
        a = RefArea(k, string(k), k, k, av)
        push!(ℒᵗʳᵃⁿˢ, Transmission(a, a, ℳ[k]))
    end

    # Check that the function `modes` returns the correct values
    @test isempty(setdiff(modes(ℒᵗʳᵃⁿˢ), vcat(collect(values(ℳ))...)))
    @test isempty(setdiff(vcat(collect(values(ℳ))...), modes(ℒᵗʳᵃⁿˢ)))

    # Check that it is possible to extract the individual types
    # - modes_sub(l::Transmission, mode_type::TransmissionMode)
    # - modes_sub(ℒᵗʳᵃⁿˢ::Vector{<:Transmission}, mode_type::TransmissionMode)
    for k ∈ range(1,n_trans)
        @test isempty(setdiff(modes_sub(ℒᵗʳᵃⁿˢ[k], RefStatic), ℳ[k][1:n_stat[k]]))
        @test isempty(setdiff(ℳ[k][1:n_stat[k]], modes_sub(ℒᵗʳᵃⁿˢ[k], RefStatic)))
        @test length(modes_sub(ℒᵗʳᵃⁿˢ[k], RefDynamic)) == n_dyn[k]
        @test length(modes_sub(ℒᵗʳᵃⁿˢ[k], PipeSimple)) == n_pipe[k]
    end
    @test length(modes_sub(ℒᵗʳᵃⁿˢ, RefStatic)) == sum(n_stat)
    @test length(modes_sub(ℒᵗʳᵃⁿˢ, RefDynamic)) == sum(n_dyn)
    @test length(modes_sub(ℒᵗʳᵃⁿˢ, PipeSimple)) == sum(n_pipe)

    # Check that it is possible to extract the individual resource modes
    # - modes_sub(l::Transmission, p::Resource)
    # - modes_sub(ℒᵗʳᵃⁿˢ::Vector{<:Transmission}, p::Resource)
    for k ∈ range(1,n_trans)
        @test isempty(setdiff(modes_sub(ℒᵗʳᵃⁿˢ[k], CO2), ℳ[k][1:n_stat[k]]))
        @test isempty(setdiff(ℳ[k][1:n_stat[k]], modes_sub(ℒᵗʳᵃⁿˢ[k], CO2)))
        @test length(modes_sub(ℒᵗʳᵃⁿˢ[k], Power)) == n_dyn[k]
        @test length(modes_sub(ℒᵗʳᵃⁿˢ[k], H2_hp)) == n_pipe[k]
    end
    @test length(modes_sub(ℒᵗʳᵃⁿˢ, CO2)) == sum(n_stat)
    @test length(modes_sub(ℒᵗʳᵃⁿˢ, Power)) == sum(n_dyn)
    @test length(modes_sub(ℒᵗʳᵃⁿˢ, H2_hp)) == sum(n_pipe)

    # Check that it is possible to extract the individual transmission modes using strings
    # - modes_sub(l::Transmission, str::String)
    # - modes_sub(l::Transmission, string_array::Array{String})
    # - modes_sub(ℒᵗʳᵃⁿˢ::Vector{<:Transmission}, str::String)
    # - modes_sub(ℒᵗʳᵃⁿˢ::Vector{<:Transmission}, string_array::Array{String})
    for k ∈ range(1,n_trans)
        @test isempty(setdiff(modes_sub(ℒᵗʳᵃⁿˢ[k], "static"), ℳ[k][1:n_stat[k]]))
        @test isempty(setdiff(ℳ[k][1:n_stat[k]], modes_sub(ℒᵗʳᵃⁿˢ[k], "static")))
        @test length(modes_sub(ℒᵗʳᵃⁿˢ[k], "dynamic")) == n_dyn[k]
        @test length(modes_sub(ℒᵗʳᵃⁿˢ[k], "pipe")) == n_pipe[k]
        @test length(modes_sub(ℒᵗʳᵃⁿˢ[k], ["pipe", "dynamic"])) == n_pipe[k] + n_dyn[k]
    end
    @test length(modes_sub(ℒᵗʳᵃⁿˢ, "static")) == sum(n_stat)
    @test length(modes_sub(ℒᵗʳᵃⁿˢ, "dynamic")) == sum(n_dyn)
    @test length(modes_sub(ℒᵗʳᵃⁿˢ, ["pipe", "dynamic"])) == sum(n_pipe) + sum(n_dyn)
end
