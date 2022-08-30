/**
 * # Target Intercept Component
 *
 * When activated intercepts next click and outputs clicked atom.
 * Requires a BCI shell.
 */

/obj/item/circuit_component/target_intercept
	display_name = "ИЧМ целеуказатель"
	desc = "Для работы требуется оболочка ИЧМ. При активации этот компонент позволит пользователю настроить целеуказание на объект с помощью своего мозга и выдаст ссылку на указанный объект."
	category = "BCI"

	required_shells = list(/obj/item/organ/cyberimp/bci)

	var/datum/port/output/clicked_atom

	var/obj/item/organ/cyberimp/bci/bci
	var/intercept_cooldown = 1 SECONDS

/obj/item/circuit_component/target_intercept/populate_ports()
	trigger_input = add_input_port("Activate", PORT_TYPE_SIGNAL)
	trigger_output = add_output_port("Triggered", PORT_TYPE_SIGNAL)
	clicked_atom = add_output_port("Targeted Object", PORT_TYPE_ATOM)

/obj/item/circuit_component/target_intercept/register_shell(atom/movable/shell)
	if(istype(shell, /obj/item/organ/cyberimp/bci))
		bci = shell
		RegisterSignal(shell, COMSIG_ORGAN_REMOVED, .proc/on_organ_removed)

/obj/item/circuit_component/target_intercept/unregister_shell(atom/movable/shell)
	bci = null
	UnregisterSignal(shell, COMSIG_ORGAN_REMOVED)

/obj/item/circuit_component/target_intercept/input_received(datum/port/input/port)
	if(!bci)
		return

	var/mob/living/owner = bci.owner
	if(!owner || !istype(owner) || !owner.client)
		return

	if(TIMER_COOLDOWN_CHECK(parent, COOLDOWN_CIRCUIT_TARGET_INTERCEPT))
		return

	to_chat(owner, "<B>Left-click to trigger target interceptor!</B>")
	owner.client.click_intercept = src

/obj/item/circuit_component/target_intercept/proc/on_organ_removed(datum/source, mob/living/carbon/owner)
	SIGNAL_HANDLER

	if(owner.client && owner.client.click_intercept == src)
		owner.client.click_intercept = null

/obj/item/circuit_component/target_intercept/proc/InterceptClickOn(mob/user, params, atom/object)
	user.client.click_intercept = null
	clicked_atom.set_output(object)
	trigger_output.set_output(COMPONENT_SIGNAL)
	TIMER_COOLDOWN_START(parent, COOLDOWN_CIRCUIT_TARGET_INTERCEPT, intercept_cooldown)

/obj/item/circuit_component/target_intercept/get_ui_notices()
	. = ..()
	. += create_ui_notice("Target Interception Cooldown: [DisplayTimeText(intercept_cooldown)]", "orange", "stopwatch")
