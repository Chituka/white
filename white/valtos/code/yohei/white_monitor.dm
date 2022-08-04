/obj/lab_monitor/yohei_white
	name = "Монитор исполнения"
	desc = "Здесь выводятся задания и плата йохеям, действующим по протоколу 'WhiteHat'."
	icon = 'white/valtos/icons/white_monitor.dmi'
	//пока что тут нихуя нет, но будет добавляться... Надеюсь

	var/obj/item/radio/internal_radio
	var/datum/yohei_task/current_task = null
	var/list/possible_tasks = list()
	var/list/white_action_guys = list()
	var/mission_mode = null
	GLOB.white_yohei_main_controller = src

	internal_radio = new /obj/item/radio(src)
	internal_radio.set_listening(FALSE)
	internal_radio.independent = TRUE
	internal_radio.set_frequency(FREQ_YOHEI)

	/obj/lab_monitor/yohei_white/Destroy(force)
	. = ..()
	QDEL_NULL(internal_radio)
	GLOB.yohei_main_controller = null
	STOP_PROCESSING(SSobj, src)

/datum/antagonist/yohei/proc/white_payment()
	if(protected_guy != DEAD)
		to_chat(owner, span_warning ("Мой наниматель ещё жив и Y corp отправила мне плату за мою работу"))
		for(var/mob/living/carbon/human/H in white_action_guys)
			inc_metabalance(H, 200, reason = "Оплата от Y corp.")
			var/obj/item/card/id/cardid = H.get_idcard(FALSE)
			cardid?.registered_account?.adjust_money(rand(2500, 5000))
			var/obj/item/armament_points_card/APC = locate() in H.get_all_gear()
			if(APC)
				APC.points += 5
				APC.update_maptext() //до тех пор, пока задания не придумаем, тут будет чисто это

addtimer(CALLBACK(src, .proc/white_payment), 10 MINUTES)

/obj/lab_monitor/yohei_white/proc/add_to_white_action_guys(mob/living/user)
	if((user in action_guys))
		action_guys -= user
	else
		white_action_guys += user
