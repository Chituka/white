//DO NOT USE THESE FOR ACCESSING ATMOS DATA, THEY MUTATE THINGS WHEN CALLED. I WILL BEAT YOU WITH A STICK. See the actual proc for more details
///Check if the turfs allows gas passage based on density, do not use.
#define CANATMOSPASS(A, O) ( A.can_atmos_pass == ATMOS_PASS_PROC ? A.can_atmos_pass(O) : ( A.can_atmos_pass == ATMOS_PASS_DENSITY ? !A.density : A.can_atmos_pass ) )
///Check if the turfs allows gas passage on a z level, do not use.
#define CANVERTICALATMOSPASS(A, O) ( A.can_atmos_pass_vertical == ATMOS_PASS_PROC ? A.can_atmos_pass(O, TRUE) : ( A.can_atmos_pass_vertical == ATMOS_PASS_DENSITY ? !A.density : A.can_atmos_pass_vertical ) )

//Helpers
///Moves the icon of the device based on the piping layer and on the direction
#define PIPING_LAYER_SHIFT(T, PipingLayer) \
	if(T.dir & (NORTH|SOUTH)) { \
		T.pixel_x = (PipingLayer - PIPING_LAYER_DEFAULT) * PIPING_LAYER_P_X;\
	} \
	if(T.dir & (EAST|WEST)) { \
		T.pixel_y = (PipingLayer - PIPING_LAYER_DEFAULT) * PIPING_LAYER_P_Y;\
	}

///Moves the icon of the device based on the piping layer and on the direction, the shift amount is dictated by more_shift
#define PIPING_FORWARD_SHIFT(T, PipingLayer, more_shift) \
	if(T.dir & (NORTH|SOUTH)) { \
		T.pixel_y += more_shift * (PipingLayer - PIPING_LAYER_DEFAULT);\
	} \
	if(T.dir & (EAST|WEST)) { \
		T.pixel_x += more_shift * (PipingLayer - PIPING_LAYER_DEFAULT);\
	}

///Moves the icon of the device based on the piping layer on both x and y
#define PIPING_LAYER_DOUBLE_SHIFT(T, PipingLayer) \
	T.pixel_x = (PipingLayer - PIPING_LAYER_DEFAULT) * PIPING_LAYER_P_X;\
	T.pixel_y = (PipingLayer - PIPING_LAYER_DEFAULT) * PIPING_LAYER_P_Y;

///Calculate the thermal energy of the selected gas (J)
#define THERMAL_ENERGY(gas) (gas.temperature * gas.heat_capacity())

GLOBAL_LIST_INIT(nonoverlaying_gases, typecache_of_gases_with_no_overlays())

//If you're doing spreading things related to atmos, DO NOT USE CANATMOSPASS, IT IS NOT CHEAP. use this instead, the info is cached after all. it's tweaked just a bit to allow for circular checks
#define TURFS_CAN_SHARE(T1, T2) (LAZYACCESS(T2.atmos_adjacent_turfs, T1) || LAZYLEN(T1.atmos_adjacent_turfs & T2.atmos_adjacent_turfs))
//Use this to see if a turf is fully blocked or not, think windows or firelocks. Fails with 1x1 non full tile windows, but it's not worth the cost.
#define TURF_SHARES(T) (LAZYLEN(T.atmos_adjacent_turfs))
