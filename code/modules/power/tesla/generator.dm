/obj/machinery/the_singularitygen/tesla
	name = "инициатор Тесла-аномалии"
	desc = "При облучении излучателем частиц порождает огромную высоковольтную шаровую молнию, сдержать которую может только силовое поле."
	icon = 'icons/obj/tesla_engine/tesla_generator.dmi'
	icon_state = "TheSingGen"
	creation_type = /obj/energy_ball

/obj/machinery/the_singularitygen/tesla/zap_act(power, zap_flags)
	if(zap_flags & ZAP_MACHINE_EXPLOSIVE)
		energy += power
	zap_flags &= ~(ZAP_MACHINE_EXPLOSIVE | ZAP_OBJ_DAMAGE) // Don't blow yourself up yeah?
	return ..()
