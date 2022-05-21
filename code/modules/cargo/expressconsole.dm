#define MAX_EMAG_ROCKETS 5
#define BEACON_COST 5000
#define SP_LINKED 1
#define SP_READY 2
#define SP_LAUNCH 3
#define SP_UNLINK 4
#define SP_UNREADY 5

/obj/machinery/computer/cargo/express
	name = "экспресс консоль"
	desc = "Эта консоль позволяет пользователю приобрести пакет \
		с 1/40 от времени доставки: стало возможным благодаря новой \
		орбитальной пушки NT \
		Все продажи практически мгновенные - пожалуйста, выбирайте внимательно"
	icon_screen = "supply_express"
	circuit = /obj/item/circuitboard/computer/cargo/express
	blockade_warning = "Замечена блюспейс нестабильность. Доставка невозможна."
	req_access = list(ACCESS_QM)
	is_express = TRUE

	var/message
	var/printed_beacons = 0 //number of beacons printed. Used to determine beacon names.
	var/list/meme_pack_data
	var/obj/item/supplypod_beacon/beacon //the linked supplypod beacon
	var/area/landingzone = /area/cargo/storage //where we droppin boys
	var/podType = /obj/structure/closet/supplypod
	var/cooldown = 0 //cooldown to prevent printing supplypod beacon spam
	var/locked = TRUE //is the console locked? unlock with ID
	var/usingBeacon = FALSE //is the console in beacon mode? exists to let beacon know when a pod may come in

/obj/machinery/computer/cargo/express/Initialize()
	. = ..()
	packin_up()

/obj/machinery/computer/cargo/express/on_construction()
	. = ..()
	packin_up()

/obj/machinery/computer/cargo/express/Destroy()
	if(beacon)
		beacon.unlink_console()
	return ..()

/obj/machinery/computer/cargo/express/attackby(obj/item/W, mob/living/user, params)
	if(W.GetID() && allowed(user))
		locked = !locked
		to_chat(user, span_notice("[locked ? "Блокирую" : "Разблокирываю"] интерфейс."))
		return
	else if(istype(W, /obj/item/disk/cargo/bluespace_pod))
		podType = /obj/structure/closet/supplypod/bluespacepod//doesnt effect circuit board, making reversal possible
		to_chat(user, span_notice("Вставляю диск в [src], разрешая более продвинутую доставку припасов."))
		qdel(W)
		return TRUE
	else if(istype(W, /obj/item/supplypod_beacon))
		var/obj/item/supplypod_beacon/sb = W
		if (sb.express_console != src)
			sb.link_console(src, user)
			return TRUE
		else
			to_chat(user, span_alert("[capitalize(src.name)] подключен к [sb]."))
	..()

/obj/machinery/computer/cargo/express/emag_act(mob/living/user)
	if(obj_flags & EMAGGED)
		return
	if(user)
		user.visible_message(span_warning("[user] проводит подохрительной картой по [src]!") ,
		span_notice("Изменяю протоколы маршрутизации, позволяя консоли снабжения приземлиться в любом месте на станции."))
	obj_flags |= EMAGGED
	contraband = TRUE
	// This also sets this on the circuit board
	var/obj/item/circuitboard/computer/cargo/board = circuit
	board.obj_flags |= EMAGGED
	board.contraband = TRUE
	packin_up()

/obj/machinery/computer/cargo/express/proc/packin_up() // oh shit, I'm sorry
	meme_pack_data = list() // sorry for what?
	for(var/pack in SSshuttle.supply_packs) // our quartermaster taught us not to be ashamed of our supply packs
		var/datum/supply_pack/P = SSshuttle.supply_packs[pack]  // specially since they're such a good price and all
		if(!meme_pack_data[P.group]) // yeah, I see that, your quartermaster gave you good advice
			meme_pack_data[P.group] = list( // it gets cheaper when I return it
				"name" = P.group, // mmhm
				"packs" = list()  // sometimes, I return it so much, I rip the manifest
			) // see, my quartermaster taught me a few things too
		if((P.hidden) || (P.special)) // like, how not to rip the manifest
			continue// by using someone else's crate
		if(P.contraband && !contraband) // will you show me?
			continue // i'd be right happy to
		meme_pack_data[P.group]["packs"] += list(list(
			"name" = P.name,
			"cost" = P.get_cost(),
			"id" = pack,
			"desc" = P.desc || P.name // If there is a description, use it. Otherwise use the pack's name.
		))

/obj/machinery/computer/cargo/express/ui_interact(mob/living/user, datum/tgui/ui)
	. = ..()
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CargoExpress", name)
		ui.open()

/obj/machinery/computer/cargo/express/ui_data(mob/user)
	var/canBeacon = beacon && (isturf(beacon.loc) || ismob(beacon.loc))//is the beacon in a valid location?
	var/list/data = list()
	var/datum/bank_account/D = SSeconomy.get_dep_account(ACCOUNT_CAR)
	if(D)
		data["points"] = D.account_balance
	data["locked"] = locked//swipe an ID to unlock
	data["siliconUser"] = user.has_unlimited_silicon_privilege
	data["beaconzone"] = beacon ? get_area(beacon) : ""//where is the beacon located? outputs in the tgui
	data["usingBeacon"] = usingBeacon //is the mode set to deliver to the beacon or the cargobay?
	data["canBeacon"] = !usingBeacon || canBeacon //is the mode set to beacon delivery, and is the beacon in a valid location?
	data["canBuyBeacon"] = cooldown <= 0 && D.account_balance >= BEACON_COST
	data["beaconError"] = usingBeacon && !canBeacon ? "(BEACON ERROR)" : ""//changes button text to include an error alert if necessary
	data["hasBeacon"] = beacon != null//is there a linked beacon?
	data["beaconName"] = beacon ? beacon.name : "Маячок не найден"
	data["printMsg"] = cooldown > 0 ? "Напечать маяк за [BEACON_COST] кредит[get_num_string(BEACON_COST)] ([cooldown])" : "Напечатать маяк за [BEACON_COST] кредит[get_num_string(BEACON_COST)]"//buttontext for printing beacons
	data["supplies"] = list()
	message = "Продажи практически мгновенные - пожалуйста, выбирайте внимательно."
	if(SSshuttle.supplyBlocked)
		message = blockade_warning
	if(usingBeacon && !beacon)
		message = "ОШИБКА МАЯКА: МАЯК ОТСУТСВУЕТ"//beacon was destroyed
	else if (usingBeacon && !canBeacon)
		message = "ОШИБКА МАЯКА: ДОЛЖЕН БЫТЬ РАСКРЫТ"//beacon's loc/user's loc must be a turf
	if(obj_flags & EMAGGED)
		message = "(&!#@Ошибка: Маршрутный#Протокол неисправен(*ей#ие. $р%бует@ де#ие: !^/ПУЛЬС3-%E)ET СЛУЧ*)КОН%НДА."
	data["message"] = message
	if(!meme_pack_data)
		packin_up()
		stack_trace("There was no pack data for [src]")
	data["supplies"] = meme_pack_data
	if (cooldown > 0)//cooldown used for printing beacons
		cooldown--
	return data

/obj/machinery/computer/cargo/express/ui_act(action, params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	switch(action)
		if("LZCargo")
			usingBeacon = FALSE
			if (beacon)
				beacon.update_status(SP_UNREADY) //ready light on beacon will turn off
		if("LZBeacon")
			usingBeacon = TRUE
			if (beacon)
				beacon.update_status(SP_READY) //turns on the beacon's ready light
		if("printBeacon")
			var/datum/bank_account/D = SSeconomy.get_dep_account(ACCOUNT_CAR)
			if(D)
				if(D.adjust_money(-BEACON_COST))
					cooldown = 10//a ~ten second cooldown for printing beacons to prevent spam
					var/obj/item/supplypod_beacon/C = new /obj/item/supplypod_beacon(drop_location())
					C.link_console(src, usr)//rather than in beacon's Initialize(), we can assign the computer to the beacon by reusing this proc)
					printed_beacons++//printed_beacons starts at 0, so the first one out will be called beacon # 1
					beacon.name = "Маяк поставки припасов #[printed_beacons]"


		if("add")//Generate Supply Order first
			if(TIMER_COOLDOWN_CHECK(src, COOLDOWN_EXPRESSPOD_CONSOLE))
				say("Railgun recalibrating. Stand by.")
				return
			var/id = text2path(params["id"])
			var/datum/supply_pack/pack = SSshuttle.supply_packs[id]
			if(!istype(pack))
				return
			var/name = "*None Provided*"
			var/rank = "*None Provided*"
			var/ckey = usr.ckey
			if(ishuman(usr))
				var/mob/living/carbon/human/H = usr
				name = H.get_authentification_name()
				rank = H.get_assignment(hand_first = TRUE)
			else if(issilicon(usr))
				name = usr.real_name
				rank = "Silicon"
			var/reason = ""
			var/list/empty_turfs
			var/datum/supply_order/SO = new(pack, name, rank, ckey, reason)
			var/points_to_check
			var/datum/bank_account/D = SSeconomy.get_dep_account(ACCOUNT_CAR)
			if(D)
				points_to_check = D.account_balance
			if(!(obj_flags & EMAGGED))
				if(SO.pack.get_cost() <= points_to_check)
					var/LZ
					if (istype(beacon) && usingBeacon)//prioritize beacons over landing in cargobay
						LZ = get_turf(beacon)
						beacon.update_status(SP_LAUNCH)
					else if (!usingBeacon)//find a suitable supplypod landing zone in cargobay
						landingzone = GLOB.areas_by_type[/area/cargo/storage]
						if (!landingzone)
							WARNING("[src] не удалось найти на станции комнату КМа / Склада (он же Карго), и поэтому он установил зону посадки снабжения для области, в которой он находится.")
							landingzone = get_area(src)
						for(var/turf/open/floor/T in landingzone.contents)//uses default landing zone
							if(T.is_blocked_turf())
								continue
							LAZYADD(empty_turfs, T)
							CHECK_TICK
						if(empty_turfs?.len)
							LZ = pick(empty_turfs)
					if (SO.pack.get_cost() <= points_to_check && LZ)//we need to call the cost check again because of the CHECK_TICK call
						TIMER_COOLDOWN_START(src, COOLDOWN_EXPRESSPOD_CONSOLE, 5 SECONDS)
						D.adjust_money(-SO.pack.get_cost())
						if(pack.special_pod)
							new /obj/effect/pod_landingzone(LZ, pack.special_pod, SO)
						else
							new /obj/effect/pod_landingzone(LZ, podType, SO)
						. = TRUE
						update_icon()
			else
				if(SO.pack.get_cost() * (0.72*MAX_EMAG_ROCKETS) <= points_to_check) // bulk discount :^)
					landingzone = GLOB.areas_by_type[pick(GLOB.the_station_areas)]  //override default landing zone
					for(var/turf/open/floor/T in landingzone.contents)
						if(T.is_blocked_turf())
							continue
						LAZYADD(empty_turfs, T)
						CHECK_TICK
					if(empty_turfs?.len)
						TIMER_COOLDOWN_START(src, COOLDOWN_EXPRESSPOD_CONSOLE, 10 SECONDS)
						D.adjust_money(-(SO.pack.get_cost() * (0.72*MAX_EMAG_ROCKETS)))

						SO.generateRequisition(get_turf(src))
						for(var/i in 1 to MAX_EMAG_ROCKETS)
							var/LZ = pick(empty_turfs)
							LAZYREMOVE(empty_turfs, LZ)
							if(pack.special_pod)
								new /obj/effect/pod_landingzone(LZ, pack.special_pod, SO)
							else
								new /obj/effect/pod_landingzone(LZ, podType, SO)
							. = TRUE
							update_icon()
							CHECK_TICK
