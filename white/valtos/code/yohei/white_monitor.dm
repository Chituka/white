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
	var/list/payday_timers = list()

/obj/lab_monitor/yohei_white/Initialize(mapload)
	. = ..()
	GLOB.white_yohei_main_controller = src
	internal_radio = new /obj/item/radio(src)
	internal_radio.set_listening(FALSE)
	internal_radio.independent = TRUE
	internal_radio.set_frequency(FREQ_YOHEI)
	START_PROCESSING(SSobj,src)

/obj/lab_monitor/yohei_white/Destroy(force)
	. = ..()
	QDEL_NULL(internal_radio)
	GLOB.yohei_main_controller = null
	STOP_PROCESSING(SSobj, src)

/obj/lab_monitor/yohei_white/proc/new_whitehat(mob/living/yohei, mob/living/protected_guy)


/*/datum/antagonist/yohei/proc/white_payment()
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
	var/obj/lab_monitor/yohei_white/WM = GLOB.white_yohei_main_controller

	addtimer(CALLBACK(src, .proc/white_payment), 10 MINUTES)
*/

/*/obj/lab_monitor/yohei_white/proc/add_to_white_action_guys(mob/living/user)
	if((user in action_guys))//эта хуйня не работает, чуваков в экшен закидывает немного иначе
		action_guys -= user
	else
		white_action_guys += user

*/
/obj/lab_monitor/yohei_white/setup(mob/living/carbon/human/yohei, mob/living/carbon/human/protected)
	var/datum/white_hat_task/new_task
	new
/obj/lab_monitor/yohei_white/payday(mob/living/carbon/human/yohei, mob/living/carbon/human/protected)
	if(protected != DEAD)
		to_chat(yohei, span_warning ("Мой наниматель ещё жив и Y corp отправила мне плату за мою работу"))
		inc_metabalance(yohei, 100, reason = "Оплата от Y corp.")
		var/obj/item/card/id/cardid = yohei.get_idcard(FALSE)
		cardid?.registered_account?.adjust_money(rand(2500, 5000))
		var/obj/item/armament_points_card/APC = locate() in yohei.get_all_gear()
		if(APC)
			APC.points += 5
			APC.update_maptext() //до тех пор, пока задания не придумаем, тут будет чисто это
	else
		to_chat(yohei, span_warning ("Оплата не поступила. Блядь."))


/obj/lab_monitor/yohei_white/examine(mob/user)
	. = ..()
	. += "<hr>"
	. += span_notice("\n<b>Исполнители:</b> [english_list(white_action_guys)]")

/datum/white_hat_task
	var/desc = null
	var/time = 10 minutes
	var/obj/lab_monitor/yohei_white/parent
	var/mob/living/target
	var/mob/living/worker
