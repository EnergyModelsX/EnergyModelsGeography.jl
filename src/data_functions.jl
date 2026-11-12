"""
    EMB.constraints_ext_data(m, tm::TransmissionMode, 𝒯, modeltype::EnergyModel, data::ExtensionData)

Fallback option when data is specified for a [`TransmissionMode`](@ref), but it is not
desired to add constraints through this function. This is, *e.g.*, the case for
`EnergyModelsInvestments` as the capacity constraint has to be replaced.
"""
EMB.constraints_ext_data(
    m,
    tm::TransmissionMode,
    𝒯,
    modeltype::EnergyModel,
    data::ExtensionData,
) = nothing
