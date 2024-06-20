"""
    TransInvData(;
        capex_trans::TimeProfile,
        trans_max_inst::TimeProfile,
        trans_max_add::TimeProfile,
        trans_min_add::TimeProfile,
        inv_mode::Investment = ContinuousInvestment(),
        trans_start::Union{Real, Nothing} = nothing,
        trans_increment::TimeProfile = FixedProfile(0),
        capex_trans_offset::TimeProfile = FixedProfile(0),
    )

Legacy constructor for a `InvData`.

The new storage descriptions allows now for a reduction in functions which is used
to make `EnergModelsInvestments` less dependent on `EnergyModelsBase`.

The core changes to the existing structure is the move of the required parameters to the
type [`Investment`](@ref) (_e.g._, the minimum and maximum added capacity is only required
for investment mdodes that require these parameters) as well as moving the `lifetime` to the
type [`LifetimeMode`], when required.

See the _[documentation](https://energymodelsx.github.io/EnergyModelsInvestments.jl/stable/how-to/update-models)_
for further information regarding how you can translate your existing model to the new model.
"""
TransInvData(nothing) = nothing
