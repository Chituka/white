/obj/lab_monitor/yohei_white
	name = "Монитор исполнения"
	desc = "Здесь выводятся задания и плата йохеям, действующим по протоколу 'WhiteHat'."

	var/obj/item/radio/internal_radio
	var/datum/yohei_task/current_task = null
	var/list/possible_tasks = list()
	var/list/white_action_guys = list()
	var/mission_mode = null

/datum/antagonist/yohei/proc/white_payment()
	if(protected_guy != DEAD)
		to_chat(owner, span_warning ("Мой наниматель ещё жив и Y corp отправила мне плату за мою работу"))
		for(var/mob/living/carbon/human/H in white_action_guys)
			inc_metabalance(H, current_task.prize, reason = "Оплата от Y corp.")
			var/obj/item/card/id/cardid = H.get_idcard(FALSE)
			cardid?.registered_account?.adjust_money(rand(5000, 10000))
			var/obj/item/armament_points_card/APC = locate() in H.get_all_gear()
			if(APC)
				APC.points += 10
				APC.update_maptext()

addtimer(CALLBACK(src, .proc/white_payment), 5 MINUTES)
