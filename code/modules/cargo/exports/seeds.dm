/datum/export/seed
	cost = CARGO_CRATE_VALUE * 0.25 // Gets multiplied by potency
	k_elasticity = 1	//price inelastic/quantity elastic, only need to export a few samples
	unit_name = "образец новых видов растений"
	export_types = list(/obj/item/seeds)
	var/needs_discovery = FALSE // Only for undiscovered species
	var/static/list/discoveredPlants = list()

/datum/export/seed/get_cost(obj/O)
	var/obj/item/seeds/S = O
	if(!needs_discovery && (S.type in discoveredPlants))
		return 0
	if(needs_discovery && !(S.type in discoveredPlants))
		return 0
	return ..() * S.rarity // That's right, no bonus for potency. Send a crappy sample first to "show improvement" later.

/datum/export/seed/sell_object(obj/O, datum/export_report/report, dry_run, apply_elastic)
	. = ..()
	if(. && !dry_run)
		var/obj/item/seeds/S = O
		discoveredPlants[S.type] = S.potency


/datum/export/seed/potency
	cost = CARGO_CRATE_VALUE * 0.125 // Gets multiplied by potency and rarity.
	unit_name = "улучшенный образец растения"
	export_types = list(/obj/item/seeds)
	needs_discovery = TRUE // Only for already discovered species

/datum/export/seed/potency/get_cost(obj/O)
	var/obj/item/seeds/S = O
	var/cost = ..()
	if(!cost)
		return 0

	var/potDiff = (S.potency - discoveredPlants[S.type])

	return round(..() * potDiff)
