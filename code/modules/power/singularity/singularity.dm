/obj/singularity
	name = "гравитационная сингулярность"
	desc = "Бублик."
	icon = 'icons/obj/singularity.dmi'
	icon_state = "singularity_s1"
	anchored = TRUE
	density = TRUE
	move_resist = INFINITY
	layer = MASSIVE_OBJ_LAYER
	light_range = 6
	appearance_flags = LONG_GLIDE
	var/current_size = 1
	var/allowed_size = 1
	var/contained = 1 //Are we going to move around?
	var/energy = 100 //How strong are we?
	var/dissipate = TRUE //Do we lose energy over time?
	var/dissipate_delay = 10
	var/dissipate_track = 0
	var/dissipate_strength = 1 //How much energy do we lose?
	var/move_self = 1 //Do we move on our own?
	var/grav_pull = 4 //How many tiles out do we pull?
	var/consume_range = 0 //How many tiles out do we eat
	var/event_chance = 10 //Prob for event each tick
	var/target = null //its target. moves towards the target if it has one
	var/last_failed_movement = 0//Will not move in the same dir if it couldnt before, will help with the getting stuck on fields thing
	var/last_warning
	var/consumedSupermatter = 0 //If the singularity has eaten a supermatter shard and can go to stage six
	var/drifting_dir = 0 // Chosen direction to drift in
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF | FREEZE_PROOF
	obj_flags = CAN_BE_HIT | DANGEROUS_POSSESSION

/obj/singularity/Initialize(mapload, starting_energy = 50)
	//CARN: admin-alert for chuckle-fuckery.
	admin_investigate_setup()

	src.energy = starting_energy
	. = ..()
	START_PROCESSING(SSobj, src)
	GLOB.poi_list |= src
	GLOB.singularities |= src
	for(var/obj/machinery/power/singularity_beacon/singubeacon in GLOB.machines)
		if(singubeacon.active)
			target = singubeacon
			break
	AddElement(/datum/element/bsa_blocker)
	RegisterSignal(src, COMSIG_ATOM_BSA_BEAM, .proc/bluespace_reaction)

/obj/singularity/Destroy()
	STOP_PROCESSING(SSobj, src)
	GLOB.poi_list.Remove(src)
	GLOB.singularities.Remove(src)
	return ..()

/obj/singularity/Move(atom/newloc, direct)
	var/turf/T = get_turf(src)
	for(var/dir in GLOB.cardinals)
		if(direct & dir)
			T = get_step(T, dir)
			if(!T)
				break
			// eat the stuff if we're going to move into it so it doesn't mess up our movement
			for(var/atom/A in T.contents)
				consume(A)
			consume(T)

	if(current_size >= STAGE_FIVE || check_turfs_in(direct))
		last_failed_movement = 0//Reset this because we moved
		return ..()
	else
		last_failed_movement = direct
		return FALSE

/obj/singularity/attack_hand(mob/user)
	consume(user)
	return TRUE

/obj/singularity/attack_paw(mob/user)
	consume(user)

/obj/singularity/attack_alien(mob/user)
	consume(user)

/obj/singularity/attack_animal(mob/user)
	consume(user)

/obj/singularity/attackby(obj/item/W, mob/user, params)
	consume(user)
	return TRUE

/obj/singularity/Process_Spacemove() //The singularity stops drifting for no man!
	return FALSE

/obj/singularity/blob_act(obj/structure/blob/B)
	return


/obj/singularity/attack_tk(mob/user)
	if(!iscarbon(user))
		return
	. = COMPONENT_CANCEL_ATTACK_CHAIN
	var/mob/living/carbon/jedi = user
	jedi.visible_message(
		"<span class='danger'>Голова <b>[jedi]</b> взрывается!</span>!</span>",
		"<span class='userdanger'>Моя голова начинает разрываться! Это хуёвая идея!</span>",
		"<span class='hear'>Слышу как что-то взрывается со сладким хрустом.</span>"
		)
	jedi.Stun(3 SECONDS)
	new /obj/effect/gibspawner/generic(get_turf(jedi), jedi)
	jedi.apply_damage(30, BRUTE, BODY_ZONE_HEAD)
	if(QDELETED(jedi))
		return // damage was too much
	if(jedi.stat == DEAD)
		jedi.ghostize()
		var/obj/item/bodypart/head/rip_u = jedi.get_bodypart(BODY_ZONE_HEAD)
		rip_u.dismember(BURN) //nice try jedi
		qdel(rip_u)
		return
	addtimer(CALLBACK(GLOBAL_PROC, .proc/carbon_tk_part_two, jedi), 0.1 SECONDS)


/obj/singularity/proc/carbon_tk_part_two(mob/living/carbon/jedi)
	if(QDELETED(jedi))
		return
	new /obj/effect/gibspawner/generic(get_turf(jedi), jedi)
	jedi.apply_damage(30, BRUTE, BODY_ZONE_HEAD)
	if(QDELETED(jedi))
		return // damage was too much
	if(jedi.stat == DEAD)
		jedi.ghostize()
		var/obj/item/bodypart/head/rip_u = jedi.get_bodypart(BODY_ZONE_HEAD)
		if(rip_u)
			rip_u.dismember(BURN)
			qdel(rip_u)
		return
	addtimer(CALLBACK(GLOBAL_PROC, .proc/carbon_tk_part_three, jedi), 0.1 SECONDS)


/obj/singularity/proc/carbon_tk_part_three(mob/living/carbon/jedi)
	if(QDELETED(jedi))
		return
	new /obj/effect/gibspawner/generic(get_turf(jedi), jedi)
	jedi.apply_damage(30, BRUTE, BODY_ZONE_HEAD)
	if(QDELETED(jedi))
		return // damage was too much
	jedi.ghostize()
	var/obj/item/bodypart/head/rip_u = jedi.get_bodypart(BODY_ZONE_HEAD)
	if(rip_u)
		rip_u.dismember(BURN)
		qdel(rip_u)


/obj/singularity/ex_act(severity, target)
	switch(severity)
		if(1)
			if(current_size <= STAGE_TWO)
				investigate_log("has been destroyed by a heavy explosion.", INVESTIGATE_SINGULO)
				qdel(src)
				return
			else
				energy -= round(((energy+1)/2),1)
		if(2)
			energy -= round(((energy+1)/3),1)
		if(3)
			energy -= round(((energy+1)/4),1)
	return


/obj/singularity/bullet_act(obj/projectile/P)
	qdel(P)
	return BULLET_ACT_HIT //Will there be an impact? Who knows.  Will we see it? No.

/obj/singularity/Bump(atom/A)

	consume(A)
	if(QDELETED(A)) // don't keep moving into objects that weren't destroyed infinitely
		step(src, drifting_dir)
	return

/obj/singularity/Crossed(atom/A)
	..()
	consume(A)

/obj/singularity/Bumped(atom/movable/AM)

	consume(AM)



/obj/singularity/process()


	if(current_size >= STAGE_TWO)
		move()

		var/datum/component/soundplayer/SP = GetComponent(/datum/component/soundplayer)
		if(!SP)
			SP = AddComponent(/datum/component/soundplayer)
			SP.active = TRUE
			SP.environmental = FALSE
			SP.playing_channel = CHANNEL_CUSTOM_JUKEBOX
		SP.playing_volume = current_size*10
		SP.playing_range = current_size*5
		radiation_pulse(src, min(5000, (energy*4.5)+1000), RAD_DISTANCE_COEFFICIENT*0.5)
		if(prob(event_chance))//Chance for it to run a special event TODO:Come up with one or two more that fit
			event()
	eat()
	dissipate()
	check_energy()

	return


/obj/singularity/attack_ai() //to prevent ais from gibbing themselves when they click on one.
	return

/obj/singularity/proc/admin_investigate_setup()
	var/turf/T = get_turf(src)
	last_warning = world.time
	var/count = locate(/obj/machinery/field/containment) in urange(30, src, 1)
	if(!count)
		message_admins("A singulo has been created without containment fields active at [ADMIN_VERBOSEJMP(T)].")
	investigate_log("was created at [AREACOORD(T)]. [count?"":"<font color='red'>No containment fields were active</font>"]", INVESTIGATE_SINGULO)

/obj/singularity/proc/dissipate()
	if(!dissipate)
		return
	if(dissipate_track >= dissipate_delay)
		src.energy -= dissipate_strength
		dissipate_track = 0
	else
		dissipate_track++

/obj/singularity/proc/expand(force_size = 0)
	var/temp_allowed_size = src.allowed_size
	if(force_size)
		temp_allowed_size = force_size
	if(temp_allowed_size >= STAGE_SIX && !consumedSupermatter)
		temp_allowed_size = STAGE_FIVE
	switch(temp_allowed_size)
		if(STAGE_ONE)
			current_size = STAGE_ONE
			icon = 'icons/obj/singularity.dmi'
			icon_state = "singularity_s1"

			pixel_x = 0
			pixel_y = 0
			grav_pull = 4
			consume_range = 0
			dissipate_delay = 10
			dissipate_track = 0
			dissipate_strength = 1
		if(STAGE_TWO)
			if(check_cardinals_range(1, TRUE))
				current_size = STAGE_TWO
				icon = 'icons/effects/96x96.dmi'
				icon_state = "singularity_s3"

				pixel_x = -32
				pixel_y = -32
				grav_pull = 6
				consume_range = 1
				dissipate_delay = 5
				dissipate_track = 0
				dissipate_strength = 5
		if(STAGE_THREE)
			if(check_cardinals_range(2, TRUE))
				current_size = STAGE_THREE
				icon = 'icons/effects/160x160.dmi'
				icon_state = "singularity_s5"

				pixel_x = -64
				pixel_y = -64
				grav_pull = 8
				consume_range = 2
				dissipate_delay = 4
				dissipate_track = 0
				dissipate_strength = 20
		if(STAGE_FOUR)
			if(check_cardinals_range(3, TRUE))
				current_size = STAGE_FOUR
				icon = 'icons/effects/224x224.dmi'
				icon_state = "singularity_s7"

				pixel_x = -96
				pixel_y = -96
				grav_pull = 10
				consume_range = 3
				dissipate_delay = 10
				dissipate_track = 0
				dissipate_strength = 10
		if(STAGE_FIVE)//this one also lacks a check for gens because it eats everything
			current_size = STAGE_FIVE
			icon = 'icons/effects/288x288.dmi'
			icon_state = "singularity_s9"

			pixel_x = -128
			pixel_y = -128
			grav_pull = 10
			consume_range = 4
			dissipate = 0 //It cant go smaller due to e loss
		if(STAGE_SIX) //This only happens if a stage 5 singulo consumes a supermatter shard.
			current_size = STAGE_SIX
			icon = 'icons/effects/352x352.dmi'
			icon_state = "singularity_s11"

			pixel_x = -160
			pixel_y = -160
			grav_pull = 15
			consume_range = 5
			dissipate = 0
	if(current_size == allowed_size)
		investigate_log("<font color='red'>grew to size [current_size]</font>", INVESTIGATE_SINGULO)
		return TRUE
	else if(current_size < (--temp_allowed_size))
		expand(temp_allowed_size)
	else
		return FALSE

/obj/singularity/proc/check_energy()
	if(energy <= 0)
		investigate_log("collapsed.", INVESTIGATE_SINGULO)
		qdel(src)
		return FALSE
	switch(energy)//Some of these numbers might need to be changed up later -Mport
		if(1 to 199)
			allowed_size = STAGE_ONE
		if(200 to 499)
			allowed_size = STAGE_TWO
		if(500 to 999)
			allowed_size = STAGE_THREE
		if(1000 to 1999)
			allowed_size = STAGE_FOUR
		if(2000 to INFINITY)
			if(energy >= 3000 && consumedSupermatter)
				allowed_size = STAGE_SIX
			else
				allowed_size = STAGE_FIVE
	if(current_size != allowed_size)
		expand()
	return TRUE

/obj/singularity/proc/eat()
	for(var/tile in spiral_range_turfs(grav_pull, src))
		var/turf/T = tile
		if(!T || !isturf(loc))
			continue
		if(get_dist(T, src) > consume_range)
			T.singularity_pull(src, current_size)
		else
			consume(T)
		for(var/thing in T)
			if(isturf(loc) && thing != src)
				var/atom/movable/X = thing
				if(get_dist(X, src) > consume_range)
					X.singularity_pull(src, current_size)
				else
					consume(X)
			CHECK_TICK
	return


/obj/singularity/proc/consume(atom/A)

	var/gain = A.singularity_act(current_size, src)
	src.energy += gain
	if(istype(A, /obj/machinery/power/supermatter_crystal) && !consumedSupermatter)
		desc = "[initial(desc)] Яростно светится внутренним огнем."
		name = "supermatter-charged [initial(name)]"
		consumedSupermatter = 1
		set_light(10)
	return

/obj/singularity/proc/move(force_move = 0)
	if(!move_self)
		return FALSE

	var/drifting_dir = pick(GLOB.alldirs - last_failed_movement)

	if(force_move)
		drifting_dir = force_move

	if(target && prob(60))
		drifting_dir = get_dir(src,target) //moves to a singulo beacon, if there is one

	step(src, drifting_dir)

/obj/singularity/proc/check_cardinals_range(steps, retry_with_move = FALSE)
	. = length(GLOB.cardinals)			//Should be 4.
	for(var/i in GLOB.cardinals)
		. -= check_turfs_in(i, steps)	//-1 for each working direction
	if(. && retry_with_move)			//If there's still a positive value it means it didn't pass. Retry with move if applicable
		for(var/i in GLOB.cardinals)
			if(step(src, i))			//Move in each direction.
				if(check_cardinals_range(steps, FALSE))		//New location passes, return true.
					return TRUE
	return !.

/obj/singularity/proc/check_turfs_in(direction = 0, step = 0)
	if(!direction)
		return FALSE
	var/steps = 0
	if(!step)
		switch(current_size)
			if(STAGE_ONE)
				steps = 1
			if(STAGE_TWO)
				steps = 3//Yes this is right
			if(STAGE_THREE)
				steps = 3
			if(STAGE_FOUR)
				steps = 4
			if(STAGE_FIVE)
				steps = 5
	else
		steps = step
	var/list/turfs = list()
	var/turf/T = src.loc
	for(var/i = 1 to steps)
		T = get_step(T,direction)
	if(!isturf(T))
		return FALSE
	turfs.Add(T)
	var/dir2 = 0
	var/dir3 = 0
	switch(direction)
		if(NORTH||SOUTH)
			dir2 = 4
			dir3 = 8
		if(EAST||WEST)
			dir2 = 1
			dir3 = 2
	var/turf/T2 = T
	for(var/j = 1 to steps-1)
		T2 = get_step(T2,dir2)
		if(!isturf(T2))
			return FALSE
		turfs.Add(T2)
	for(var/k = 1 to steps-1)
		T = get_step(T,dir3)
		if(!isturf(T))
			return FALSE
		turfs.Add(T)
	for(var/turf/T3 in turfs)
		if(isnull(T3))
			continue
		if(!can_move(T3))
			return FALSE
	return TRUE



/obj/singularity/proc/can_move(turf/T)
	if(!T)
		return FALSE
	if((locate(/obj/machinery/field/containment) in T)||(locate(/obj/machinery/shieldwall) in T))
		return FALSE
	else if(locate(/obj/machinery/field/generator) in T)
		var/obj/machinery/field/generator/G = locate(/obj/machinery/field/generator) in T
		if(G?.active)
			return FALSE
	else if(locate(/obj/machinery/power/shieldwallgen) in T)
		var/obj/machinery/power/shieldwallgen/S = locate(/obj/machinery/power/shieldwallgen) in T
		if(S?.active)
			return FALSE
	return TRUE

/obj/singularity/proc/event()
	var/numb = rand(1,4)
	switch(numb)
		if(1)//EMP
			emp_area()
		if(2)//Stun mobs who lack optic scanners
			mezzer()
		if(3,4) //Sets all nearby mobs on fire
			if(current_size < STAGE_SIX)
				return FALSE
			combust_mobs()
		else
			return FALSE
	return TRUE

/obj/singularity/proc/combust_mobs()
	for(var/mob/living/carbon/C in urange(20, src, 1))
		C.visible_message("<span class='warning'>Кожа <b>[C]</b> воспламеняется!</span>", \
						  "<span class='userdanger'>Чувствую, что я сейчас <b>ГОРЮ</b>!</span>")
		C.adjust_fire_stacks(5)
		C.IgniteMob()
	return


/obj/singularity/proc/mezzer()
	for(var/mob/living/carbon/M in oviewers(8, src))
		if(isbrain(M)) //Ignore brains
			continue

		if(M.stat == CONSCIOUS)
			if (ishuman(M))
				var/mob/living/carbon/human/H = M
				if(istype(H.glasses, /obj/item/clothing/glasses/meson))
					var/obj/item/clothing/glasses/meson/MS = H.glasses
					if(MS.vision_flags == SEE_TURFS)
						to_chat(H, "<span class='notice'>Смотрю прямо в <b>сингулярность</b>, но меня спасают мои защитные очки!</span>")
						return

		M.apply_effect(60, EFFECT_STUN)
		M.visible_message("<span class='danger'><b>[M]</b> смотрит прямо в <b>сингулярность</b>!</span>", \
						"<span class='userdanger'>Смотрю прямо в <b>сингулярность</b> и ощущаю слабость.</span>")


/obj/singularity/proc/emp_area()
	empulse(src, 8, 10)
	return

/obj/singularity/singularity_act()
	var/gain = (energy/2)
	var/dist = max((current_size - 2),1)
	explosion(src.loc,(dist),(dist*2),(dist*4))
	qdel(src)
	return(gain)

/obj/singularity/proc/bluespace_reaction()
	investigate_log("has been shot by bluespace artillery and destroyed.", INVESTIGATE_SINGULO)
	qdel(src)

/obj/singularity/deadchat_controlled
	move_self = FALSE

/obj/singularity/deadchat_controlled/Initialize(mapload, starting_energy)
	. = ..()
	AddComponent(/datum/component/deadchat_control, DEMOCRACY_MODE, list(
	 "up" = CALLBACK(GLOBAL_PROC, .proc/_step, src, NORTH),
	 "down" = CALLBACK(GLOBAL_PROC, .proc/_step, src, SOUTH),
	 "left" = CALLBACK(GLOBAL_PROC, .proc/_step, src, WEST),
	 "right" = CALLBACK(GLOBAL_PROC, .proc/_step, src, EAST)))
