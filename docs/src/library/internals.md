# Internals


## [`Area`](@id_sec_area)

Other restrictions can be applied on a area level, such as electricity generation reserves, CO2 emission limits or resource limits (wind power, natural gas etc.). 

## [`Transmission`](@id_sec_transmission)



## [`TransmissionModes`](@id_sec_transmission_modes)
A transmission mode for linerized power flow constraints can be imlplemented to improve electricity transmission representation. New parameters needed is reactances, new variables needed are voltage angles. Powerflow constraints of type:

`` p_tij = x_ij(\delta_ti - \delta_tj)  \qquad \forall t \in \mathcal{T}, \forall j \in \mathcal{C}_i, \forall i \in \mathcal{N} ``


## [Optimization variables](@id sec_lib_internal_opt_vars)




## Methods

```@docs

```