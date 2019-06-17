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
	
#-Active SOS1/2
suffix sosno integer IN;
suffix ref integer IN;

#-Sets
set DIMENSIONS;						#-Nbr of dimension multiplied by time step
set ENTRIES;						#-Nbr of days (observations)
set ITERATIONS default {2}; 		#-Nbr of typical days you want to test

#-Parameters
param Nmidx default 1; 						#nr of days
param Ndata{ENTRIES,DIMENSIONS}; 			#already normalized
param Distance{i in ENTRIES,j in ENTRIES} := sum{k in DIMENSIONS}(Ndata[i,k]-Ndata[j,k])^2 ;

#-Variables
var z{ENTRIES,ENTRIES} 		binary default 0; #which day corresponds to which typical day
var y{ENTRIES} 				binary default 0; #which are the typical days 

#-Constraints
#--allocate one cluster centre (i) to each observation (j) 
subject to PAM_c1{j in ENTRIES}:
sum{i in ENTRIES} z[i,j] = 1;

#--if not allocated need to be null 
subject to PAM_c2{i in ENTRIES,j in ENTRIES}:
z[i,j] <= y[i]; 

#--total cluster number
subject to PAM_c3:
sum{i in ENTRIES} y[i] = Nmidx;



#-Objective
minimize PAM_obj: 
sum{i in ENTRIES,j in ENTRIES} Distance[i,j]*z[i,j];

#-Solve
param y_all{ENTRIES,ITERATIONS} 				default 0;
param z_all{ENTRIES,ENTRIES,ITERATIONS} 		binary default 0;
param obj_all{ITERATIONS} 						default 0;
data data.dat

let {i in ENTRIES, j in ENTRIES} z[i,j].sosno := j;
let {i in ENTRIES, j in ENTRIES} z[i,j].ref := 2*i;

option solver cplex;
option cplex_options 'mipdisplay = 2'; 

for {x in ITERATIONS} {
	display(x);
		let Nmidx := x;
		solve;
		
		let {i in ENTRIES: y[i]>0} y_all[i,x] := i;
		let {i in ENTRIES,j in ENTRIES} z_all[i,j,x] := z[i,j];
		let obj_all[x] := sum{i in ENTRIES,j in ENTRIES} Distance[i,j]*z[i,j];	
}

#-display
print {i in ENTRIES} : {j in ITERATIONS} y_all[i,j] 								> days_of_TDs.out;
print {i2 in ENTRIES} : {j in ITERATIONS} (sum{i1 in ENTRIES} i1*z_all[i1,i2,j]) 	> TDs_of_days.out;

;