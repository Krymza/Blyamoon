/datum/element/skirt_peeking
	element_flags = ELEMENT_DETACH

/datum/element/skirt_peeking/Attach(datum/peeked)
	. = ..()
	if(!ishuman(peeked))
		return ELEMENT_INCOMPATIBLE

	RegisterSignal(peeked, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))
	RegisterSignal(peeked, COMSIG_PARENT_EXAMINE_MORE, PROC_REF(on_closer_look))

/datum/element/skirt_peeking/proc/can_skirt_peek(mob/living/carbon/human/peeked, mob/peeker)
	var/mob/living/living_peeker = peeker
	var/obj/item/clothing/under/worn_uniform = peeked.get_item_by_slot(ITEM_SLOT_ICLOTHING)


	// Unfortunately, you can't see it
	var/obj/item/clothing/suit/outer_clothing = peeked.get_item_by_slot(ITEM_SLOT_OCLOTHING)
	if(outer_clothing && CHECK_MULTIPLE_BITFIELDS(outer_clothing.body_parts_covered, CHEST | GROIN | LEGS | FEET))
		return FALSE
	//

	// Valid clothing section
	if(worn_uniform && is_type_in_typecache(worn_uniform.type, GLOB.skirt_peekable))
		// We are being peeked by a spooky ghost who sees all?
		if(isobserver(peeker))
			return TRUE
		// Are you a living creature (and not us)?
		if(istype(living_peeker) && (living_peeker != peeked))
			// And are you under us while we're standing up?
			if(!(CHECK_BITFIELD(living_peeker.mobility_flags, MOBILITY_STAND)) && (CHECK_BITFIELD(peeked.mobility_flags, MOBILITY_STAND)) && (peeked.loc == living_peeker.loc))
				return TRUE
			if((peeked.dir == living_peeker.dir) && (peeked.loc > living_peeker.loc))
				if(peeked in view(2, peeker.client))
					return TRUE
			// Do you happen to be small enough to easily look under us?
			if(COMPARE_SIZES(peeked, peeker) >= 2)
				return TRUE
			// Or are you nearby and we are up high
			// to-do SOMEONE PLEASE PORT /datum/element/climbable
			var/obj/structure/high_ground_peeked = locate(/obj/structure) in get_turf(peeked)
			var/obj/structure/high_ground_peeker = locate(/obj/structure) in get_turf(peeker)
			if(high_ground_peeked && high_ground_peeked.climbable && CHECK_BITFIELD(peeked.mobility_flags, MOBILITY_STAND) && peeked.Adjacent(peeker))
				// Funnily enough, if we're at the same height, they can't just peek under us!
				if(!(high_ground_peeker && high_ground_peeker.climbable))
					return TRUE
	return FALSE

/datum/element/skirt_peeking/proc/on_examine(mob/living/carbon/human/peeked, mob/peeker, list/examine_list)
	var/obj/item/clothing/suit/outer_clothing = peeked.get_item_by_slot(ITEM_SLOT_OCLOTHING)
	if(!(outer_clothing && CHECK_MULTIPLE_BITFIELDS(outer_clothing.body_parts_covered, CHEST | GROIN | LEGS | FEET)))
		// Valid clothing section
		var/obj/item/clothing/under/worn_uniform = peeked.get_item_by_slot(ITEM_SLOT_ICLOTHING)
		if(worn_uniform && is_type_in_typecache(worn_uniform.type, GLOB.skirt_peekable))
			examine_list += span_purple("[peeked.ru_who(TRUE)] одет[peeked.ru_a()] в юбку! Наверное, под неё можно <b>подсмотреть</b>...")

/datum/element/skirt_peeking/proc/on_closer_look(mob/living/carbon/human/peeked, mob/peeker, list/examine_content)
	if(can_skirt_peek(peeked, peeker))
		var/obj/item/clothing/under/worn_uniform = peeked.get_item_by_slot(ITEM_SLOT_ICLOTHING)
		var/string = "Ты подсматриваешь под [worn_uniform.name] [peeked]. Ты видишь "
		var/obj/item/clothing/underwear/worn_underwear = peeked.get_item_by_slot(ITEM_SLOT_UNDERWEAR)
		if(worn_underwear)
			string += ""
			if(!is_type_in_typecache(worn_underwear.type, GLOB.pairless_panties)) //a pair of thong
				string += ""
			if(worn_underwear.color)
				string += "<font color='[worn_underwear.color]'>[worn_underwear.name]</font>."
			else
				string += "[worn_underwear.name]."

			var/obj/item/organ/genital/penis/penis = peeked.getorganslot(ORGAN_SLOT_PENIS)
			var/obj/item/organ/genital/vagina/vagina = peeked.getorganslot(ORGAN_SLOT_VAGINA)
			if(penis?.aroused_state)
				string += span_love(" На них просматривается выпуклость.")
			else if(vagina?.aroused_state)
				string += span_love(" Они выглядят влажными.")

		else
			string += "абсолютно нагую промежность! [peeked.internal_organs ? "Следом ты замечаешь:" : ""]"
			var/list/genitals = list()
			for(var/obj/item/organ/genital/genital in peeked.internal_organs)
				if(CHECK_BITFIELD(genital.genital_flags, (GENITAL_INTERNAL|GENITAL_HIDDEN)))
					continue

				var/appended
				switch(genital.type)
					if(/obj/item/organ/genital/vagina)
						if(genital.aroused_state)
							appended += " влажная"
						if(lowertext(genital.shape) != "human")
							appended += " [lowertext(genital.shape)]"
						if(lowertext(genital.shape) != "cloaca") //their wet cloaca vagina
							appended += " [lowertext(genital.name)]" // goodbye pussy
						appended += ","

					if(/obj/item/organ/genital/testicles)
						var/obj/item/organ/genital/testicles/nuts = genital
						appended += " [lowertext(nuts.size_name)] размера [lowertext(nuts.name)], "
					if(/obj/item/organ/genital/penis)
						if(genital.aroused_state)
							appended += " стоящий"
						if(lowertext(genital.shape) != "human")
							appended += " [lowertext(genital.shape)]"
						appended += " [lowertext(genital.name)]," // Name it something funny, i dare you.
					if(/obj/item/organ/genital/butt)
						var/obj/item/organ/genital/butt/booty = genital
						appended += " [booty.size_name] размера [lowertext(booty.name)]" // Maybe " average butt pair" isn't the best for now
					else
						continue
				genitals += appended

			string += english_list(genitals, "", "", "")
			string += "."

		examine_content += span_purple(string)
		// Let's see if we caught them, addtimer so it appears after the peek.
		addtimer(CALLBACK(src, PROC_REF(try_notice), peeked, peeker), 1)

/// Alright, they've peeked us and everything, did we notice it though?
/datum/element/skirt_peeking/proc/try_notice(mob/living/carbon/human/peeked, mob/living/peeker)
	if(!peeked || !peeker)
		return
	if(!istype(peeked) || !istype(peeker))
		return
	var/obj/item/clothing/under/worn_uniform = peeked.get_item_by_slot(ITEM_SLOT_ICLOTHING)
	if(!istype(worn_uniform))
		return
	var/obj/item/clothing/glasses/eye_blocker = peeker.get_item_by_slot(ITEM_SLOT_EYES)
	if(!(!peeked.client && (peeked.stat == CONSCIOUS) && !HAS_TRAIT(peeked, TRAIT_BLIND) && !is_blind(peeked) && \
		!peeker.is_eyes_covered(FALSE) && !(eye_blocker && eye_blocker.tint > 0) && \
		!(peeker.invisibility > peeked.invisibility) && !(peeker.alpha <= 30)))
		return
	if(peeker in view(1, peeked.client))
		to_chat(peeked, span_warning("[peeker] подсматривает под твою [worn_uniform.name]!"))
		to_chat(peeker, span_warning("[peeked] замечает, как ты подсматриваешь под [peeked.ru_ego()] [worn_uniform.name]!"))
