# -------------------------------------------------------------------------------------------------------------------------													
#	EnergyScope TD is an open-source energy model suitable for country scale analysis. It is a simplified representation of an urban or national energy system accounting for the energy flows												
#	within its boundaries. Based on a hourly resolution, it optimises the design and operation of the energy system while minimizing the cost of the system.												
#													
#	Copyright (C) <2018-2019> <Ecole Polytechnique Fédérale de Lausanne (EPFL), Switzerland and Université catholique de Louvain (UCLouvain), Belgium>
#													
#	Licensed under the Apache License, Version 2.0 (the "License");												
#	you may not use this file except in compliance with the License.												
#	You may obtain a copy of the License at												
#													
#		http://www.apache.org/licenses/LICENSE-2.0												
#													
#	Unless required by applicable law or agreed to in writing, software												
#	distributed under the License is distributed on an "AS IS" BASIS,												
#	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.												
#	See the License for the specific language governing permissions and												
#	limitations under the License.												
#													
#	Description and complete License: see LICENSE file.												
# -------------------------------------------------------------------------------------------------------------------------		


#########################
###  SETS [Figure 3]  ###
#########################

## MAIN SETS: Sets whose elements are input directly in the data file
set PERIODS := 1 .. 8760; # time periods (hours of the year)
set HOURS := 1 .. 24; # hours of the day
set TYPICAL_DAYS:= 1 .. 12; # typical days
set T_H_TD within {PERIODS, HOURS, TYPICAL_DAYS}; # set linking periods, hours, days, typical days
set SECTORS; # sectors of the energy system
set END_USES_INPUT; # Types of demand (end-uses). Input to the model
set END_USES_CATEGORIES; # Categories of demand (end-uses): electricity, heat, mobility
set END_USES_TYPES_OF_CATEGORY {END_USES_CATEGORIES}; # Types of demand (end-uses).
set RESOURCES; # Resources: fuels (renewables and fossils) and electricity imports
set BIOFUELS within RESOURCES; # imported biofuels.
set EXPORT within RESOURCES; # exported resources
set END_USES_TYPES := setof {i in END_USES_CATEGORIES, j in END_USES_TYPES_OF_CATEGORY [i]} j; # secondary set
set TECHNOLOGIES_OF_END_USES_TYPE {END_USES_TYPES}; # set all energy conversion technologies (excluding storage technologies and infrastructure)
set STORAGE_TECH; #  set of storage technologies 
set STORAGE_OF_END_USES_TYPES {END_USES_TYPES} within STORAGE_TECH; # set all storage technologies related to an end-use types (used for thermal solar (TS))
set INFRASTRUCTURE; # Infrastructure: DHN, grid, and intermediate energy conversion technologies (i.e. not directly supplying end-use demand)

## SECONDARY SETS: a secondary set is defined by operations on MAIN SETS
set LAYERS := (RESOURCES diff BIOFUELS diff EXPORT) union END_USES_TYPES; # Layers are used to balance resources/products in the system
set TECHNOLOGIES := (setof {i in END_USES_TYPES, j in TECHNOLOGIES_OF_END_USES_TYPE [i]} j) union STORAGE_TECH union INFRASTRUCTURE; 
set TECHNOLOGIES_OF_END_USES_CATEGORY {i in END_USES_CATEGORIES} within TECHNOLOGIES := setof {j in END_USES_TYPES_OF_CATEGORY[i], k in TECHNOLOGIES_OF_END_USES_TYPE [j]} k;
set RE_RESOURCES within RESOURCES; # List of RE resources (including wind hydro solar), used to compute the RE share
set V2G within TECHNOLOGIES;   # EVs which can be used for vehicle-to-grid (V2G).
set EVs_BATT   within STORAGE_TECH; # specific battery of EVs
set EVs_BATT_OF_V2G {V2G}; # Makes the link between batteries of EVs and the V2G technology
set STORAGE_DAILY within STORAGE_TECH;# Storages technologies for daily application 
set TS_OF_DEC_TECH {TECHNOLOGIES_OF_END_USES_TYPE["HEAT_LOW_T_DECEN"] diff {"DEC_SOLAR"}} ; # Makes the link between TS and the technology producing the heat

##Additional SETS added just to simplify equations.
set TYPICAL_DAY_OF_PERIOD {t in PERIODS} := setof {h in HOURS, td in TYPICAL_DAYS: (t,h,td) in T_H_TD} td; #TD_OF_PERIOD(T)
set HOUR_OF_PERIOD {t in PERIODS} := setof {h in HOURS, td in TYPICAL_DAYS: (t,h,td) in T_H_TD} h; #H_OF_PERIOD(T)

## Additional SETS: only needed for printing out results (not represented in Figure 3).
set COGEN within TECHNOLOGIES; # cogeneration tech
set BOILERS within TECHNOLOGIES; # boiler tech

#################################
### PARAMETERS [Tables 1-2]   ###
#################################

## Parameters added to include time series in the model [Table 1]
param electricity_time_series {HOURS, TYPICAL_DAYS} >= 0, <= 1; # %_elec [-]: factor for sharing lighting across typical days (adding up to 1)
param heating_time_series {HOURS, TYPICAL_DAYS} >= 0, <= 1; # %_sh [-]: factor for sharing space heating across typical days (adding up to 1)
param mob_pass_time_series {HOURS, TYPICAL_DAYS} >= 0, <= 1; # %_pass [-]: factor for sharing passenger transportation across Typical days (adding up to 1) based on https://www.fhwa.dot.gov/policy/2013cpr/chap1.cfm
param mob_freight_time_series {HOURS, TYPICAL_DAYS} >= 0, <= 1; # %_fr [-]: factor for sharing freight transportation across Typical days (adding up to 1)
param c_p_t {TECHNOLOGIES, HOURS, TYPICAL_DAYS} default 1; #Hourly capacity factor [-]. If = 1 (default value) <=> no impact.

## Parameters added to define scenarios and technologies [Table 2]
param end_uses_demand_year {END_USES_INPUT, SECTORS} >= 0 default 0; # end_uses_year [GWh]: table end-uses demand vs sectors (input to the model). Yearly values. [Mpkm] or [Mtkm] for passenger or freight mobility.
param end_uses_input {i in END_USES_INPUT} := sum {s in SECTORS} (end_uses_demand_year [i,s]); # end_uses_input (Figure 1.4) [GWh]: total demand for each type of end-uses across sectors (yearly energy) as input from the demand-side model. [Mpkm] or [Mtkm] for passenger or freight mobility.
param i_rate > 0; # discount rate [-]: real discount rate
param re_share_primary >= 0; # re_share [-]: minimum share of primary energy coming from RE
param gwp_limit >= 0;    # [ktCO2-eq./year] maximum gwp emissions allowed.
param share_mobility_public_min >= 0, <= 1; # %_public,min [-]: min limit for penetration of public mobility over total mobility 
param share_mobility_public_max >= 0, <= 1; # %_public,max [-]: max limit for penetration of public mobility over total mobility 
param share_freight_train_min >= 0, <= 1; # %_rail,min [-]: min limit for penetration of train in freight transportation
param share_freight_train_max >= 0, <= 1; # %_rail,min [-]: max limit for penetration of train in freight transportation
param share_heat_dhn_min >= 0, <= 1; # %_dhn,min [-]: min limit for penetration of dhn in low-T heating
param share_heat_dhn_max >= 0, <= 1; # %_dhn,max [-]: max limit for penetration of dhn in low-T heating
param t_op {HOURS, TYPICAL_DAYS} default 1;# [h]: operating time 
param f_max {TECHNOLOGIES} >= 0; # Maximum feasible installed capacity [GW], refers to main output. storage level [GWh] for STORAGE_TECH
param f_min {TECHNOLOGIES} >= 0; # Minimum feasible installed capacity [GW], refers to main output. storage level [GWh] for STORAGE_TECH
param fmax_perc {TECHNOLOGIES} >= 0, <= 1 default 1; # value in [0,1]: this is to fix that a technology can at max produce a certain % of the total output of its sector over the entire year
param fmin_perc {TECHNOLOGIES} >= 0, <= 1 default 0; # value in [0,1]: this is to fix that a technology can at min produce a certain % of the total output of its sector over the entire year
param avail {RESOURCES} >= 0; # Yearly availability of resources [GWh/y]
param c_op {RESOURCES} >= 0; # cost of resources in the different periods [MCHF/GWh]
param n_car_max >=0; #  [car] Maximum amount of cars. Required to compute the aggregated size of EVs batteries.
param peak_sh_factor >= 0;   # %_Peak_sh [-]: ratio between highest yearly demand and highest TDs demand
param layers_in_out {RESOURCES union TECHNOLOGIES diff STORAGE_TECH , LAYERS}; # f: input/output Resources/Technologies to Layers. Reference is one unit ([GW] or [Mpkm/h] or [Mtkm/h]) of (main) output of the resource/technology. input to layer (output of technology) > 0.
param c_inv {TECHNOLOGIES} >= 0; # Specific investment cost [MCHF/GW].[MCHF/GWh] for STORAGE_TECH
param c_maint {TECHNOLOGIES} >= 0; # O&M cost [MCHF/GW/year]: O&M cost does not include resource (fuel) cost. [MCHF/GWh/year] for STORAGE_TECH
param lifetime {TECHNOLOGIES} >= 0; # n: lifetime [years]
param tau {i in TECHNOLOGIES} := i_rate * (1 + i_rate)^lifetime [i] / (((1 + i_rate)^lifetime [i]) - 1); # Annualisation factor ([-]) for each different technology [Eq. 2]
param gwp_constr {TECHNOLOGIES} >= 0; # GWP emissions associated to the construction of technologies [ktCO2-eq./GW]. Refers to [GW] of main output
param gwp_op {RESOURCES} >= 0; # GWP emissions associated to the use of resources [ktCO2-eq./GWh]. Includes extraction/production/transportation and combustion
param c_p {TECHNOLOGIES} >= 0, <= 1 default 1; # yearly capacity factor of each technology [-], defined on annual basis. Different than 1 if sum {t in PERIODS} F_t (t) <= c_p * F
param storage_eff_in {STORAGE_TECH , LAYERS} >= 0, <= 1; # eta_sto_in [-]: efficiency of input to storage from layers.  If 0 storage_tech/layer are incompatible
param storage_eff_out {STORAGE_TECH , LAYERS} >= 0, <= 1; # eta_sto_out [-]: efficiency of output from storage to layers. If 0 storage_tech/layer are incompatible
param storage_losses {STORAGE_TECH} >= 0, <= 1; # %_sto_loss [-]: Self losses in storage (required for Li-ion batteries). Value = self discharge in 1 hour.
param storage_charge_time    {STORAGE_TECH} >= 0; # t_sto_in [h]: Time to charge storage (Energy to Power ratio). If value =  5 <=>  5h for a full charge.
param storage_discharge_time {STORAGE_TECH} >= 0; # t_sto_out [h]: Time to discharge storage (Energy to Power ratio). If value =  5 <=>  5h for a full discharge.
param storage_availability {STORAGE_TECH} >=0, default 1;# %_sto_avail [-]: Storage technology availability to charge/discharge. Used for EVs 
param loss_network {END_USES_TYPES} >= 0 default 0; # %_net_loss: Losses coefficient [0; 1] in the networks (grid and DHN)
param Batt_per_Car {V2G} >= 0; # ev_Batt_size [GWh]: Battery size per EVs car technology
param c_grid_extra >=0; # Cost to reinforce the grid due to IRE penetration [MCHF].

##Additional parameter (not presented in the paper)
param total_time := sum {t in PERIODS, h in HOUR_OF_PERIOD [t], td in TYPICAL_DAY_OF_PERIOD [t]} (t_op [h, td]); # [h]. added just to simplify equations



#################################
###   VARIABLES [Tables 3-4]  ###
#################################


##Independent variables [Table 3] :
var Share_Mobility_Public >= share_mobility_public_min, <= share_mobility_public_max; # %_Public: Ratio [0; 1] public mobility over total passenger mobility
var Share_Freight_Train, >= share_freight_train_min, <= share_freight_train_max; # %_Rail: Ratio [0; 1] rail transport over total freight transport
var Share_Heat_Dhn, >= share_heat_dhn_min, <= share_heat_dhn_max; # %_DHN: Ratio [0; 1] centralized over total low-temperature heat
var F {TECHNOLOGIES} >= 0; # F: Installed capacity ([GW]) with respect to main output (see layers_in_out). [GWh] for STORAGE_TECH.
var F_t {RESOURCES union TECHNOLOGIES, HOURS, TYPICAL_DAYS} >= 0; # F_t: Operation in each period [GW] or, for STORAGE_TECH, storage level [GWh]. multiplication factor with respect to the values in layers_in_out table. Takes into account c_p
var Storage_in {i in STORAGE_TECH, LAYERS, HOURS, TYPICAL_DAYS} >= 0; # Sto_in [GW]: Power input to the storage in a certain period
var Storage_out {i in STORAGE_TECH, LAYERS, HOURS, TYPICAL_DAYS} >= 0; # Sto_out [GW]: Power output from the storage in a certain period
var Power_nuclear  >=0; # [GW] P_Nuc: Constant load of nuclear
var Shares_Mobility_Passenger {TECHNOLOGIES_OF_END_USES_CATEGORY["MOBILITY_PASSENGER"]} >=0; # %_MobPass [-]: Constant share of passenger mobility
var Shares_LowT_Dec {TECHNOLOGIES_OF_END_USES_TYPE["HEAT_LOW_T_DECEN"] diff {"DEC_SOLAR"}}>=0 ; # %_HeatDec [-]: Constant share of heat Low T decentralised + its specific thermal solar
var F_Solar         {TECHNOLOGIES_OF_END_USES_TYPE["HEAT_LOW_T_DECEN"] diff {"DEC_SOLAR"}} >=0; # F_sol [GW]: Solar thermal installed capacity per heat decentralised technologies
var F_t_Solar       {TECHNOLOGIES_OF_END_USES_TYPE["HEAT_LOW_T_DECEN"] diff {"DEC_SOLAR"}, h in HOURS, td in TYPICAL_DAYS} >= 0; # F_t_sol [GW]: Solar thermal operating per heat decentralised technologies

##Dependent variables [Table 4] :
var End_Uses {LAYERS, HOURS, TYPICAL_DAYS} >= 0; #EndUses [GW]: total demand for each type of end-uses (hourly power). Defined for all layers (0 if not demand). [Mpkm] or [Mtkm] for passenger or freight mobility.
var TotalCost >= 0; # C_tot [ktCO2-eq./year]: Total GWP emissions in the system.
var C_inv {TECHNOLOGIES} >= 0; #C_inv [MCHF]: Total investment cost of each technology
var C_maint {TECHNOLOGIES} >= 0; #C_maint [MCHF/year]: Total O&M cost of each technology (excluding resource cost)
var C_op {RESOURCES} >= 0; #C_op [MCHF/year]: Total O&M cost of each resource
var TotalGWP >= 0; # GWP_tot [ktCO2-eq./year]: Total global warming potential (GWP) emissions in the system
var GWP_constr {TECHNOLOGIES} >= 0; # GWP_constr [ktCO2-eq.]: Total emissions of the technologies
var GWP_op {RESOURCES} >= 0; #  GWP_op [ktCO2-eq.]: Total yearly emissions of the resources [ktCO2-eq./y]
var Network_losses {END_USES_TYPES, HOURS, TYPICAL_DAYS} >= 0; # Net_loss [GW]: Losses in the networks (normally electricity grid and DHN)
var Storage_level {STORAGE_TECH, PERIODS} >= 0; # Sto_level [GWh]: Energy stored at each period

#########################################
###      CONSTRAINTS Eqs [1-42]       ###
#########################################

## End-uses demand calculation constraints 
#-----------------------------------------

# [Figure 4] From annual energy demand to hourly power demand. End_Uses is non-zero only for demand layers.
subject to end_uses_t {l in LAYERS, h in HOURS, td in TYPICAL_DAYS}:
	End_Uses [l, h, td] = (if l == "ELECTRICITY" 
		then
			(end_uses_input[l] / total_time + end_uses_input["LIGHTING"] * electricity_time_series [h, td] / t_op [h, td] ) + Network_losses [l,h,td]
		else (if l == "HEAT_LOW_T_DHN" then
			(end_uses_input["HEAT_LOW_T_HW"] / total_time + end_uses_input["HEAT_LOW_T_SH"] * heating_time_series [h, td] / t_op [h, td] ) * Share_Heat_Dhn + Network_losses [l,h,td]
		else (if l == "HEAT_LOW_T_DECEN" then
			(end_uses_input["HEAT_LOW_T_HW"] / total_time + end_uses_input["HEAT_LOW_T_SH"] * heating_time_series [h, td] / t_op [h, td] ) * (1 - Share_Heat_Dhn)
		else (if l == "MOB_PUBLIC" then
			(end_uses_input["MOBILITY_PASSENGER"] * mob_pass_time_series [h, td] / t_op [h, td]  ) * Share_Mobility_Public
		else (if l == "MOB_PRIVATE" then
			(end_uses_input["MOBILITY_PASSENGER"] * mob_pass_time_series [h, td] / t_op [h, td]  ) * (1 - Share_Mobility_Public)
		else (if l == "MOB_FREIGHT_RAIL" then
			(end_uses_input["MOBILITY_FREIGHT"]   * mob_freight_time_series [h, td] / t_op [h, td] ) *  Share_Freight_Train
		else (if l == "MOB_FREIGHT_ROAD" then
			(end_uses_input["MOBILITY_FREIGHT"]   * mob_freight_time_series [h, td] / t_op [h, td] ) *(1 - Share_Freight_Train)
		else (if l == "HEAT_HIGH_T" then
			end_uses_input[l] / total_time
		else 
			0 )))))))); # For all layers which don't have an end-use demand
	

## Cost
#------

# [Eq. 1]	
subject to totalcost_cal:
	TotalCost = sum {j in TECHNOLOGIES} (tau [j]  * C_inv [j] + C_maint [j]) + sum {i in RESOURCES} C_op [i];
	
# [Eq. 3] Investment cost of each technology
subject to investment_cost_calc {j in TECHNOLOGIES}: 
	C_inv [j] = c_inv [j] * F [j];
		
# [Eq. 4] O&M cost of each technology
subject to main_cost_calc {j in TECHNOLOGIES}: 
	C_maint [j] = c_maint [j] * F [j];		

# [Eq. 5] Total cost of each resource
subject to op_cost_calc {i in RESOURCES}:
	C_op [i] = sum {t in PERIODS, h in HOUR_OF_PERIOD [t], td in TYPICAL_DAY_OF_PERIOD [t]} (c_op [i] * F_t [i, h, td] * t_op [h, td] ) ;

## Emissions
#-----------

# [Eq. 6]
subject to totalGWP_calc:
	TotalGWP = sum {j in TECHNOLOGIES} (GWP_constr [j] / lifetime [j]) + sum {i in RESOURCES} GWP_op [i];
	
# [Eq. 7]
subject to gwp_constr_calc {j in TECHNOLOGIES}:
	GWP_constr [j] = gwp_constr [j] * F [j];

# [Eq. 8]
subject to gwp_op_calc {i in RESOURCES}:
	GWP_op [i] = gwp_op [i] * sum {t in PERIODS, h in HOUR_OF_PERIOD [t], td in TYPICAL_DAY_OF_PERIOD [t]} ( F_t [i, h, td] * t_op [h, td] );	

	
## Multiplication factor
#-----------------------
	
# [Eq. 9] min & max limit to the size of each technology
subject to size_limit {j in TECHNOLOGIES}:
	f_min [j] <= F [j] <= f_max [j];
	
# [Eq. 10] relation between power and capacity via period capacity factor. This forces max hourly output (e.g. renewables)
subject to capacity_factor_t {j in TECHNOLOGIES, h in HOURS, td in TYPICAL_DAYS}:
	F_t [j, h, td] <= F [j] * c_p_t [j, h, td];
	
# [Eq. 11] relation between mult_t and mult via yearly capacity factor. This one forces total annual output
subject to capacity_factor {j in TECHNOLOGIES}:
	sum {t in PERIODS, h in HOUR_OF_PERIOD [t], td in TYPICAL_DAY_OF_PERIOD [t]} (F_t [j, h, td] * t_op [h, td]) <= F [j] * c_p [j] * total_time;	
		
## Resources
#-----------

# [Eq. 12] Resources availability equation
subject to resource_availability {i in RESOURCES}:
	sum {t in PERIODS, h in HOUR_OF_PERIOD[t], td in TYPICAL_DAY_OF_PERIOD[t]} (F_t [i, h, td] * t_op [h, td]) <= avail [i];

## Layers
#--------

# [Eq. 13] Layer balance equation with storage. Layers: input > 0, output < 0. Demand > 0. Storage: in > 0, out > 0;
# output from technologies/resources/storage - input to technologies/storage = demand. Demand has default value of 0 for layers which are not end_uses
subject to layer_balance {l in LAYERS, h in HOURS, td in TYPICAL_DAYS}:
		sum {i in RESOURCES union TECHNOLOGIES diff STORAGE_TECH } 
		(layers_in_out[i, l] * F_t [i, h, td]) 
		+ sum {j in STORAGE_TECH} ( Storage_out [j, l, h, td] - Storage_in [j, l, h, td] )
		- End_Uses [l, h, td]
		= 0;
	
## Storage	
#---------
	
# [Eq. 14] The level of the storage represents the amount of energy stored at a certain time.
subject to storage_level {j in STORAGE_TECH, t in PERIODS, h in HOUR_OF_PERIOD[t], td in TYPICAL_DAY_OF_PERIOD[t]}:
	Storage_level [j, t] = (if t == 1 then
	 			Storage_level [j, card(PERIODS)] * (1.0 -  storage_losses[j])
				+ t_op [h, td] * (   (sum {l in LAYERS: storage_eff_in [j,l] > 0}  (Storage_in [j, l, h, td]  * storage_eff_in  [j, l])) 
				                   - (sum {l in LAYERS: storage_eff_out [j,l] > 0} (Storage_out [j, l, h, td] / storage_eff_out [j, l])))
	else
	 			Storage_level [j, t-1] * (1.0 -  storage_losses[j])
				+ t_op [h, td] * (   (sum {l in LAYERS: storage_eff_in [j,l] > 0}  (Storage_in [j, l, h, td]  * storage_eff_in  [j, l])) 
				                   - (sum {l in LAYERS: storage_eff_out [j,l] > 0} (Storage_out [j, l, h, td] / storage_eff_out [j, l])))
				);

# [Eq. 15] Bounding daily storage
subject to impose_daily_storage {j in STORAGE_DAILY, t in PERIODS, h in HOUR_OF_PERIOD[t], td in TYPICAL_DAY_OF_PERIOD[t]}:
	Storage_level [j, t] = F_t [j, h, td];
	
# [Eq. 16] Bounding seasonal storage
subject to limit_energy_stored_to_maximum {j in STORAGE_TECH diff STORAGE_DAILY , t in PERIODS}:
	Storage_level [j, t] <= F [j];# Never exceed the size of the storage unit
	
# [Eqs. 17-18] Each storage technology can have input/output only to certain layers. If incompatible then the variable is set to 0
subject to storage_layer_in {j in STORAGE_TECH, l in LAYERS, h in HOURS, td in TYPICAL_DAYS}:
	(if storage_eff_in [j, l]=0 then  Storage_in [j, l, h, td]  = 0);
subject to storage_layer_out {j in STORAGE_TECH, l in LAYERS, h in HOURS, td in TYPICAL_DAYS}:
	(if storage_eff_out [j, l]=0 then  Storage_out [j, l, h, td]  = 0);
		
# [Eq. 19] limit the Energy to power ratio. 
subject to limit_energy_to_power_ratio {j in STORAGE_TECH , l in LAYERS, h in HOURS, td in TYPICAL_DAYS}:
	Storage_in [j, l, h, td] * storage_charge_time[j] + Storage_out [j, l, h, td] * storage_discharge_time[j] <=  F [j] * storage_availability[j];
	

## Infrastructure
#----------------

# [Eq. 20] Calculation of losses for each end-use demand type (normally for electricity and DHN)
subject to network_losses {eut in END_USES_TYPES, h in HOURS, td in TYPICAL_DAYS}:
	Network_losses [eut,h,td] = (sum {j in RESOURCES union TECHNOLOGIES diff STORAGE_TECH: layers_in_out [j, eut] > 0} ((layers_in_out[j, eut]) * F_t [j, h, td])) * loss_network [eut];

# [Eq. 21] 9.4 BCHF is the extra investment needed if there is a big deployment of stochastic renewables
subject to extra_grid:
	F ["GRID"] = 1 + (c_grid_extra / c_inv["GRID"]) * (F ["WIND"] + F ["PV"]) / (f_max ["WIND"] + f_max ["PV"]);

# [Eq. 22] DHN: assigning a cost to the network
subject to extra_dhn:
	F ["DHN"] = sum {j in TECHNOLOGIES_OF_END_USES_TYPE["HEAT_LOW_T_DHN"]} (F [j]);

# [Eq. 23] Power2Gas investment cost is calculated on the max size of the two units
subject to Power2gas_1:
	F ["POWER2GAS"] >= F ["POWER2GAS_in"];
subject to Power2gas_2:
	F ["POWER2GAS"] >= F ["POWER2GAS_out"];	
	
	
## Additional constraints
#------------------------
	
# [Eq. 24] Fix nuclear production constant : 
subject to constantNuc {h in HOURS, td in TYPICAL_DAYS}:
	F_t ["NUCLEAR", h, td] = Power_nuclear;

# [Eq. 25] Operating strategy in mobility passenger (to make model more realistic)
# Each passenger mobility technology (j) has to supply a constant share  (Shares_Mobility_Passenger[j]) of the passenger mobility demand
subject to operating_strategy_mob_passenger{j in TECHNOLOGIES_OF_END_USES_CATEGORY["MOBILITY_PASSENGER"], h in HOURS, td in TYPICAL_DAYS}:
	F_t [j, h, td]   = Shares_Mobility_Passenger [j] * (end_uses_input["MOBILITY_PASSENGER"] * mob_pass_time_series [h, td] / t_op [h, td] );
	
## Thermal solar & thermal storage:

# [Eq. 26] relation between decentralised thermal solar power and capacity via period capacity factor.
subject to thermal_solar_capacity_factor {j in TECHNOLOGIES_OF_END_USES_TYPE["HEAT_LOW_T_DECEN"] diff {"DEC_SOLAR"}, h in HOURS, td in TYPICAL_DAYS}:
	F_t_Solar [j, h, td] <= F_Solar[j] * c_p_t["DEC_SOLAR", h, td];
	
# [Eq. 27] Overall thermal solar is the sum of specific thermal solar 	
subject to thermal_solar_total_capacity :
	F ["DEC_SOLAR"] = sum {j in TECHNOLOGIES_OF_END_USES_TYPE["HEAT_LOW_T_DECEN"] diff {"DEC_SOLAR"}} F_Solar[j];

# [Eq. 28]: Decentralised thermal technology must supply a constant share of heat demand.
subject to decentralised_heating_balance  {j in TECHNOLOGIES_OF_END_USES_TYPE["HEAT_LOW_T_DECEN"] diff {"DEC_SOLAR"}, i in TS_OF_DEC_TECH[j], h in HOURS, td in TYPICAL_DAYS}:
	F_t [j, h, td] + F_t_Solar [j, h, td] + sum {l in LAYERS } ( Storage_out [i, l, h, td] - Storage_in [i, l, h, td])  
		= Shares_LowT_Dec[j] * (end_uses_input["HEAT_LOW_T_HW"] / total_time + end_uses_input["HEAT_LOW_T_SH"] * heating_time_series [h, td] / t_op [h, td]);

### Hydroelectric dams.
## In this version applied for the Swiss case, we use Eqs. 40-42 instead of Eqs. 29-31. Hence, the following is commented
## [Eq. 29] Seasonal storage in hydro dams.
## When installed power of new dams 0 -> 0.44, maximum storage capacity changes linearly 0 -> 2400 GWh/y
#subject to storage_level_hydro_dams: 
#	F ["DAM_STORAGE"] <= f_min ["DAM_STORAGE"] + (f_max ["DAM_STORAGE"]-f_min ["DAM_STORAGE"]) * (F ["HYDRO_DAM"] - f_min ["HYDRO_DAM"])/(f_max ["HYDRO_DAM"] - f_min ["HYDRO_DAM"]);
#
## [Eq. 30] Hydro dams can stored the input energy and restore it whenever. Hence, inlet is the input river and outlet is bounded by max capacity
#subject to impose_hydro_dams_inflow {h in HOURS, td in TYPICAL_DAYS}: 
#	Storage_in ["DAM_STORAGE", "ELECTRICITY", h, td] = F_t ["HYDRO_DAM", h, td];
#
## [Eq. 31] Hydro dams production is lower than installed F_t capacity:
#subject to limit_hydro_dams_output {h in HOURS, td in TYPICAL_DAYS}: 
#	Storage_out ["DAM_STORAGE", "ELECTRICITY", h, td] <= F ["HYDRO_DAM"];
#

## EV storage :

# [Eq. 32] Compute the equivalent size of V2G batteries based on the share of V2G, the amount of cars and the battery capacity per EVs technology
subject to EV_storage_size {j in V2G, i in EVs_BATT_OF_V2G[j]}:
	F [i] = n_car_max * Shares_Mobility_Passenger[j] * Batt_per_Car[j];# Battery size proportional to the amount of cars
	
# [Eq. 33]  Impose EVs to be supplied by their battery.
subject to EV_storage_for_V2G_demand {j in V2G, i in EVs_BATT_OF_V2G[j], h in HOURS, td in TYPICAL_DAYS}:
	Storage_out [i,"ELECTRICITY",h,td] >=  - layers_in_out[j,"ELECTRICITY"]* F_t [j, h, td];
		
## Peak demand :

# [Eq. 34] Peak in decentralized heating
subject to peak_lowT_dec {j in TECHNOLOGIES_OF_END_USES_TYPE["HEAT_LOW_T_DECEN"] diff {"DEC_SOLAR"}, h in HOURS, td in TYPICAL_DAYS}:
	F [j] >= peak_sh_factor * F_t [j, h, td] ;

# [Eq. 35] Calculation of max heat demand in DHN (1st constrain required to linearised the max function)
var Max_Heat_Demand >= 0;
subject to max_dhn_heat_demand {h in HOURS, td in TYPICAL_DAYS}:
	Max_Heat_Demand >= End_Uses ["HEAT_LOW_T_DHN", h, td];
# Peak in DHN
subject to peak_lowT_dhn:
	sum {j in TECHNOLOGIES_OF_END_USES_TYPE ["HEAT_LOW_T_DHN"], i in STORAGE_OF_END_USES_TYPES["HEAT_LOW_T_DHN"]} (F [j] + F[i]/storage_discharge_time[i]) >= peak_sh_factor * Max_Heat_Demand;
	

## Adaptation for the case study: Constraints needed for the application to Switzerland (not needed in standard LP formulation)
#-----------------------------------------------------------------------------------------------------------------------

# [Eq. 36]  constraint to reduce the GWP subject to Minimum_gwp_reduction :
subject to Minimum_GWP_reduction :
	TotalGWP <= gwp_limit;

# [Eq. 37] Minimum share of RE in primary energy supply
subject to Minimum_RE_share :
	sum {j in RE_RESOURCES, t in PERIODS, h in HOUR_OF_PERIOD[t], td in TYPICAL_DAY_OF_PERIOD[t]} F_t [j, h, td] * t_op [h, td] 
	>=	re_share_primary *
	sum {j in RESOURCES, t in PERIODS, h in HOUR_OF_PERIOD[t], td in TYPICAL_DAY_OF_PERIOD[t]} F_t [j, h, td] * t_op [h, td]	;
		
# [Eq. 38] Definition of min/max output of each technology as % of total output in a given layer. 
subject to f_max_perc {eut in END_USES_TYPES, j in TECHNOLOGIES_OF_END_USES_TYPE[eut]}:
	sum {t in PERIODS, h in HOUR_OF_PERIOD[t], td in TYPICAL_DAY_OF_PERIOD[t]} (F_t [j,h,td] * t_op[h,td]) <= fmax_perc [j] * sum {j2 in TECHNOLOGIES_OF_END_USES_TYPE[eut], t in PERIODS, h in HOUR_OF_PERIOD[t], td in TYPICAL_DAY_OF_PERIOD[t]} (F_t [j2, h, td] * t_op[h,td]);
subject to f_min_perc {eut in END_USES_TYPES, j in TECHNOLOGIES_OF_END_USES_TYPE[eut]}:
	sum {t in PERIODS, h in HOUR_OF_PERIOD[t], td in TYPICAL_DAY_OF_PERIOD[t]} (F_t [j,h,td] * t_op[h,td]) >= fmin_perc [j] * sum {j2 in TECHNOLOGIES_OF_END_USES_TYPE[eut], t in PERIODS, h in HOUR_OF_PERIOD[t], td in TYPICAL_DAY_OF_PERIOD[t]} (F_t [j2, h, td] * t_op[h,td]);

# [Eq. 39] Energy efficiency is a fixed cost
subject to extra_efficiency:
	F ["EFFICIENCY"] = 1 / (1 + i_rate);	

## Variant equations for hydro dams	
# [Eq. 40] Seasonal storage in hydro dams.
# When installed power of new dams 0 -> 0.44, maximum storage capacity changes linearly 0 -> 2400 GWh/y
subject to storage_level_hydro_dams: 
	F ["DAM_STORAGE"] <= f_min ["DAM_STORAGE"] + (f_max ["DAM_STORAGE"]-f_min ["DAM_STORAGE"]) * (F ["NEW_HYDRO_DAM"] - f_min ["NEW_HYDRO_DAM"])/(f_max ["NEW_HYDRO_DAM"] - f_min ["NEW_HYDRO_DAM"]);

# [Eq. 41] Hydro dams can stored the input energy and restore it whenever. Hence, inlet is the input river and outlet is bounded by max capacity
subject to impose_hydro_dams_inflow {h in HOURS, td in TYPICAL_DAYS}: 
	Storage_in ["DAM_STORAGE", "ELECTRICITY", h, td] = F_t ["HYDRO_DAM", h, td] + F_t ["NEW_HYDRO_DAM", h, td];

# [Eq. 42] Hydro dams production is lower than installed F_t capacity:
subject to limit_hydro_dams_output {h in HOURS, td in TYPICAL_DAYS}: 
	Storage_out ["DAM_STORAGE", "ELECTRICITY", h, td] <= (F ["HYDRO_DAM"] + F ["NEW_HYDRO_DAM"]);


##########################
### OBJECTIVE FUNCTION ###
##########################

# Can choose between TotalGWP and TotalCost
minimize obj: TotalCost;




##############################################
###            GLPK version                ###
##############################################

solve;

### Printing output



