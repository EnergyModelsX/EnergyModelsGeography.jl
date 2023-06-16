# Philosophy

This package aims at extending `EnergyModelsBase` with geographical functionalities.
New structures are defined for `Area` and `Transmission` corridor.
The `EnergyModelsBase` is used to create a local energy system within an `Area`, additionally the `Area` includes geographical coordinates that specifices its location.
`Transmission` corridors defines pathways from one `Area` to another `Area`, on these corridor multiple `TransmissionModes` can be used to transport resources.
The `TransmissionModes` can be static infrastructure such as `PipelineMode` or dynamic modes such as ships.
