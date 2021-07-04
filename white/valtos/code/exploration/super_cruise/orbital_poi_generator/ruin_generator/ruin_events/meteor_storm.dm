/datum/ruin_event/meteor_storm
	warning_message = "МЕТЕОРИТНЫЙ ШТОРМ"
	probability = 1
	start_tick_min = 3000
	start_tick_max = 6000
	tick_rate = 80

/datum/ruin_event/meteor_storm/post_spawn(list/floor_turfs, z_value)
	exploration_announce("Входящий песчанный шторм. ETA: [round(start_tick / 10, 1)] секунд.", z_value)

/datum/ruin_event/meteor_storm/event_tick(z_value)
	var/startSide = pick(GLOB.cardinals)
	var/turf/pickedstart = spaceDebrisStartLoc(startSide, z_value)
	var/turf/pickedgoal = spaceDebrisFinishLoc(startSide, z_value)
	var/Me = pickweight(GLOB.meteorsC)
	var/obj/effect/meteor/M = new Me(pickedstart, pickedgoal)
	M.dest = pickedgoal
