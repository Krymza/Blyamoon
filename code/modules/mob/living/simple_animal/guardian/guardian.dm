
GLOBAL_LIST_EMPTY(parasites) //all currently existing/living guardians

#define GUARDIAN_HANDS_LAYER 1
#define GUARDIAN_TOTAL_LAYERS 1

/mob/living/simple_animal/hostile/guardian
	name = "Guardian Spirit"
	real_name = "Guardian Spirit"
	desc = "A mysterious being that stands by its charge, ever vigilant."
	speak_emote = list("hisses")
	rad_flags = RAD_NO_CONTAMINATE | RAD_PROTECT_CONTENTS
	gender = NEUTER
	mob_biotypes = NONE
	bubble_icon = "guardian"
	response_help_continuous = "passes through"
	response_help_simple = "pass through"
	response_disarm_continuous = "flails at"
	response_disarm_simple = "flail at"
	response_harm_continuous = "punches"
	response_harm_simple = "punch"
	icon = 'icons/mob/guardian.dmi'
	icon_state = "magicbase"
	icon_living = "magicbase"
	icon_dead = "magicbase"
	speed = -0.5
	blood_volume = 0
	a_intent = INTENT_HARM
	stop_automated_movement = 1
	movement_type = FLYING // Immunity to chasms and landmines, etc.
	attack_sound = 'sound/weapons/punch1.ogg'
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	maxbodytemp = INFINITY
	attack_verb_continuous = "punches"
	attack_verb_simple = "punch"
	maxHealth = INFINITY //The spirit itself is invincible
	health = INFINITY
	healable = FALSE //don't brusepack the guardian
	damage_coeff = list(BRUTE = 0.5, BURN = 0.5, TOX = 0.5, CLONE = 0.5, STAMINA = 0, OXY = 0.5) //how much damage from each damage type we transfer to the owner
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES
	obj_damage = 40
	melee_damage_lower = 15
	melee_damage_upper = 15
	butcher_results = list(/obj/item/ectoplasm = 1)
	AIStatus = AI_OFF
	hud_type = /datum/hud/guardian
	dextrous_hud_type = /datum/hud/dextrous/guardian //if we're set to dextrous, account for it.
	var/mutable_appearance/cooloverlay
	var/guardiancolor = "#ffffff"
	var/recolorentiresprite
	var/theme
	var/list/guardian_overlays[GUARDIAN_TOTAL_LAYERS]
	var/reset = 0 //if the summoner has reset the guardian already
	var/cooldown = 0
	var/mob/living/carbon/summoner
	var/range = 13 //how far from the user the spirit can be
	var/toggle_button_type = /atom/movable/screen/guardian/ToggleMode/Inactive //what sort of toggle button the hud uses
	var/playstyle_string = "<span class='holoparasite bold'>You are a standard Guardian. You shouldn't exist!</span>"
	var/magic_fluff_string = "<span class='holoparasite'>You draw the Coder, symbolizing bugs and errors. This shouldn't happen! Submit a bug report!</span>"
	var/tech_fluff_string = "<span class='holoparasite'>BOOT SEQUENCE COMPLETE. ERROR MODULE LOADED. THIS SHOULDN'T HAPPEN. Submit a bug report!</span>"
	var/carp_fluff_string = "<span class='holoparasite'>CARP CARP CARP SOME SORT OF HORRIFIC BUG BLAME THE CODERS CARP CARP CARP</span>"
	var/customized
	/// sigh, fine.
	var/datum/song/holoparasite/music_datum
	/// is not null only when it has been created with default "deck of tarot cards"
	var/was_randomized = null

/mob/living/simple_animal/hostile/guardian/Initialize(mapload, theme)
	GLOB.parasites += src
	updatetheme(theme)
	music_datum = new(src, get_allowed_instrument_ids())
	. = ..()

/mob/living/simple_animal/hostile/guardian/med_hud_set_health()
	if(summoner)
		var/image/holder = hud_list[HEALTH_HUD]
		holder.icon_state = "hud[RoundHealth(summoner)]"

/mob/living/simple_animal/hostile/guardian/med_hud_set_status()
	if(summoner)
		var/image/holder = hud_list[STATUS_HUD]
		var/icon/I = icon(icon, icon_state, dir)
		holder.pixel_y = I.Height() - world.icon_size
		if(summoner.stat == DEAD)
			holder.icon_state = "huddead"
		else
			holder.icon_state = "hudhealthy"

/mob/living/simple_animal/hostile/guardian/Destroy()
	GLOB.parasites -= src
	QDEL_NULL(music_datum)
	return ..()

/mob/living/simple_animal/hostile/guardian/verb/music_interact()
	set name = "Access Internal Synthesizer"
	set desc = "Access your internal musical synthesizer"
	set category = "IC"

	music_datum.ui_interact(src)

/mob/living/simple_animal/hostile/guardian/proc/updatetheme(theme) //update the guardian's theme
	if(!theme)
		theme = pick("magic", "tech", "carp")
	switch(theme)//should make it easier to create new stand designs in the future if anyone likes that
		if("magic")
			name = "Guardian Spirit"
			real_name = "Guardian Spirit"
			bubble_icon = "guardian"
			icon_state = "magicbase"
			icon_living = "magicbase"
			icon_dead = "magicbase"
		if("tech")
			name = "Holoparasite"
			real_name = "Holoparasite"
			bubble_icon = "holo"
			icon_state = "techbase"
			icon_living = "techbase"
			icon_dead = "techbase"
		if("carp")
			name = "Holocarp"
			real_name = "Holocarp"
			bubble_icon = "holo"
			icon_state = "holocarp"
			icon_living = "holocarp"
			icon_dead = "holocarp"
			speak_emote = list("gnashes")
			desc = "A mysterious fish that stands by its charge, ever vigilant."
			attack_verb_continuous = "bites"
			attack_verb_simple = "bite"
			attack_sound = 'sound/weapons/bite.ogg'
			recolorentiresprite = TRUE
	if(!recolorentiresprite) //we want this to proc before stand logs in, so the overlay isnt gone for some reason
		cooloverlay = mutable_appearance(icon, theme)
		add_overlay(cooloverlay)

/mob/living/simple_animal/hostile/guardian/Login() //if we have a mind, set its name to ours when it logs in
	..()
	if(mind)
		mind.name = "[real_name]"
	if(!summoner)
		to_chat(src, "<span class='holoparasite bold'>For some reason, somehow, you have no summoner. Please report this bug immediately.</span>")
		return
	to_chat(src, "<span class='holoparasite'>You are a <b>[real_name]</b>, bound to serve [summoner.real_name].</span>")
	to_chat(src, "<span class='holoparasite'>You are capable of manifesting or recalling to your master with the buttons on your HUD. You will also find a button to communicate with [summoner.ru_na()] privately there.</span>")
	to_chat(src, "<span class='holoparasite'>While personally invincible, you will die if [summoner.real_name] does, and any damage dealt to you will have a portion passed on to [summoner.ru_na()] as you feed upon [summoner.ru_na()] to sustain yourself.</span>")
	to_chat(src, playstyle_string)
	if(!customized)
		guardiancustomize()

/mob/living/simple_animal/hostile/guardian/proc/guardiancustomize()
	guardianrecolor()
	guardianrename()
	customized = TRUE

/mob/living/simple_animal/hostile/guardian/proc/guardianrecolor()
	guardiancolor = input(src,"What would you like your color to be?","Choose Your Color","#ffffff") as color|null
	if(!guardiancolor) //redo proc until we get a color
		to_chat(src, "<span class='warning'>Not a valid color, please try again.</span>")
		guardianrecolor()
		return
	if(!recolorentiresprite)
		cooloverlay.color = guardiancolor
		cut_overlay(cooloverlay) //we need to get our new color
		add_overlay(cooloverlay)
	else
		add_atom_colour(guardiancolor, FIXED_COLOUR_PRIORITY)

/mob/living/simple_animal/hostile/guardian/proc/guardianrename()
	var/new_name = sanitize_name(reject_bad_text(stripped_input(src, "What would you like your name to be?", "Choose Your Name", real_name, MAX_NAME_LEN)))
	if(!new_name) //redo proc until we get a good name
		to_chat(src, "<span class='warning'>Not a valid name, please try again.</span>")
		guardianrename()
		return
	to_chat(src, "<span class='notice'>Your new name <span class='name'>[new_name]</span> anchors itself in your mind.</span>")
	fully_replace_character_name(null, new_name)

/mob/living/simple_animal/hostile/guardian/PhysicalLife() //Dies if the summoner dies
	. = ..()
	update_health_hud() //we need to update all of our health displays to match our summoner and we can't practically give the summoner a hook to do it
	med_hud_set_health()
	med_hud_set_status()
	if(!QDELETED(summoner))
		if(summoner.stat == DEAD)
			forceMove(summoner.loc)
			to_chat(src, "<span class='danger'>Your summoner has died!</span>")
			visible_message("<span class='danger'><B>\The [src] dies along with its user!</B></span>")
			if(!was_randomized)
				summoner.visible_message("<span class='danger'><B>[summoner]'s body is completely consumed by the strain of sustaining [src]!</B></span>")
				for(var/obj/item/W in summoner)
					if(!summoner.dropItemToGround(W))
						qdel(W)
				summoner.dust()
			death(TRUE)
			qdel(src)
	else
		to_chat(src, "<span class='danger'>Your summoner has died!</span>")
		visible_message("<span class='danger'><B>[src] dies along with its user!</B></span>")
		death(TRUE)
		qdel(src)
	snapback()
	if(HAS_TRAIT(summoner, TRAIT_NODEATH) && (istype(summoner.wear_neck, /obj/item/clothing/neck/necklace/memento_mori)))
		REMOVE_TRAIT(summoner, TRAIT_NODEATH, "memento_mori")
		to_chat(summoner,"<span class='danger'>You feel incredibly vulnerable as the memento mori pulls your life force in one too many directions!")

/mob/living/simple_animal/hostile/guardian/get_status_tab_items()
	. += ..()
	if(summoner)
		var/resulthealth
		if(iscarbon(summoner))
			resulthealth = round((abs(HEALTH_THRESHOLD_DEAD - summoner.health) / abs(HEALTH_THRESHOLD_DEAD - summoner.maxHealth)) * 100)
		else
			resulthealth = round((summoner.health / summoner.maxHealth) * 100, 0.5)
		. += "Summoner Health: [resulthealth]%"
	if(cooldown >= world.time)
		. += "Manifest/Recall Cooldown Remaining: [DisplayTimeText(cooldown - world.time)]"

/mob/living/simple_animal/hostile/guardian/Move() //Returns to summoner if they move out of range
	. = ..()
	snapback()

/mob/living/simple_animal/hostile/guardian/proc/snapback()
	if(summoner)
		if(get_dist(get_turf(summoner),get_turf(src)) <= range)
			return
		else
			to_chat(src, "<span class='holoparasite'>You moved out of range, and were pulled back! You can only move [range] meters from [summoner.real_name]!</span>")
			visible_message("<span class='danger'>\The [src] jumps back to its user.</span>")
			if(istype(summoner.loc, /obj/effect))
				Recall(TRUE)
			else
				new /obj/effect/temp_visual/guardian/phase/out(loc)
				forceMove(summoner.loc)
				new /obj/effect/temp_visual/guardian/phase(loc)

/mob/living/simple_animal/hostile/guardian/canSuicide()
	return FALSE

/mob/living/simple_animal/hostile/guardian/proc/is_deployed()
	return loc != summoner

/mob/living/simple_animal/hostile/guardian/AttackingTarget()
	if(!is_deployed())
		to_chat(src, "<span class='danger'><B>You must be manifested to attack!</span></B>")
		return FALSE
	else
		return ..()

/mob/living/simple_animal/hostile/guardian/death()
	drop_all_held_items()
	..()
	if(summoner)
		to_chat(summoner, "<span class='danger'><B>Your [name] died somehow!</span></B>")
		summoner.death()

/mob/living/simple_animal/hostile/guardian/update_health_hud()
	if(summoner && hud_used && hud_used.healths)
		var/resulthealth
		if(iscarbon(summoner))
			resulthealth = round((abs(HEALTH_THRESHOLD_DEAD - summoner.health) / abs(HEALTH_THRESHOLD_DEAD - summoner.maxHealth)) * 100)
		else
			resulthealth = round((summoner.health / summoner.maxHealth) * 100, 0.5)
		hud_used.healths.maptext = MAPTEXT("<div align='center' valign='middle' style='position:relative; top:0px; left:6px'><font color='#efeeef'>[resulthealth]%</font></div>")

/mob/living/simple_animal/hostile/guardian/adjustHealth(amount, updating_health = TRUE, forced = FALSE) //The spirit is invincible, but passes on damage to the summoner
	. = amount
	if(summoner)
		if(loc == summoner)
			return FALSE
		summoner.adjustBruteLoss(amount)
		if(amount > 0)
			to_chat(summoner, "<span class='danger'><B>Your [name] is under attack! You take damage!</span></B>")
			summoner.visible_message("<span class='danger'><B>Blood sprays from [summoner] as [src] takes damage!</B></span>")
			if(summoner.stat == UNCONSCIOUS)
				to_chat(summoner, "<span class='danger'><B>Your body can't take the strain of sustaining [src] in this condition, it begins to fall apart!</span></B>")
				summoner.adjustCloneLoss(amount * 0.5) //dying hosts take 50% bonus damage as cloneloss
		update_health_hud()

/mob/living/simple_animal/hostile/guardian/ex_act(severity, target, origin)
	switch(severity)
		if(1)
			if(istype(origin, /datum/explosion))
				gib(was_explosion = origin)
			else
				gib()
			return
		if(2)
			adjustBruteLoss(60)
		if(3)
			adjustBruteLoss(30)

/mob/living/simple_animal/hostile/guardian/wave_ex_act(power, datum/wave_explosion/explosion, dir)
	adjustBruteLoss(EXPLOSION_POWER_STANDARD_SCALE_MOB_DAMAGE(power, explosion.mob_damage_mod * 0.33))

/mob/living/simple_animal/hostile/guardian/gib(no_brain, no_organs, no_bodyparts, datum/explosion/was_explosion)
	if(summoner)
		to_chat(summoner, "<span class='danger'><B>Your [src] was blown up!</span></B>")
		if(was_randomized)
			summoner.death()
		else
			summoner.gib(was_explosion = was_explosion)
	ghostize()
	qdel(src)

//HAND HANDLING

/mob/living/simple_animal/hostile/guardian/equip_to_slot(obj/item/I, slot)
	if(!slot)
		return FALSE
	if(!istype(I))
		return FALSE

	. = TRUE
	var/index = get_held_index_of_item(I)
	if(index)
		held_items[index] = null
		update_inv_hands()

	if(I.pulledby)
		I.pulledby.stop_pulling()

	I.screen_loc = null // will get moved if inventory is visible
	I.forceMove(src)
	I.equipped(src, slot)
	I.layer = ABOVE_HUD_LAYER
	I.plane = ABOVE_HUD_PLANE

/mob/living/simple_animal/hostile/guardian/proc/apply_overlay(cache_index)
	if((. = guardian_overlays[cache_index]))
		add_overlay(.)

/mob/living/simple_animal/hostile/guardian/proc/remove_overlay(cache_index)
	var/I = guardian_overlays[cache_index]
	if(I)
		cut_overlay(I)
		guardian_overlays[cache_index] = null

/mob/living/simple_animal/hostile/guardian/update_inv_hands()
	remove_overlay(GUARDIAN_HANDS_LAYER)
	var/list/hands_overlays = list()
	var/obj/item/l_hand = get_item_for_held_index(1)
	var/obj/item/r_hand = get_item_for_held_index(2)

	if(r_hand)
		hands_overlays += r_hand.build_worn_icon(default_layer = GUARDIAN_HANDS_LAYER, default_icon_file = r_hand.righthand_file, isinhands = TRUE)

		if(client && hud_used && hud_used.hud_version != HUD_STYLE_NOHUD)
			r_hand.layer = ABOVE_HUD_LAYER
			r_hand.plane = ABOVE_HUD_PLANE
			r_hand.screen_loc = ui_hand_position(get_held_index_of_item(r_hand))
			client.screen |= r_hand

	if(l_hand)
		hands_overlays +=  l_hand.build_worn_icon(default_layer = GUARDIAN_HANDS_LAYER, default_icon_file = l_hand.lefthand_file, isinhands = TRUE)

		if(client && hud_used && hud_used.hud_version != HUD_STYLE_NOHUD)
			l_hand.layer = ABOVE_HUD_LAYER
			l_hand.plane = ABOVE_HUD_PLANE
			l_hand.screen_loc = ui_hand_position(get_held_index_of_item(l_hand))
			client.screen |= l_hand

	if(hands_overlays.len)
		guardian_overlays[GUARDIAN_HANDS_LAYER] = hands_overlays
	apply_overlay(GUARDIAN_HANDS_LAYER)

/mob/living/simple_animal/hostile/guardian/regenerate_icons()
	update_inv_hands()

//MANIFEST, RECALL, TOGGLE MODE/LIGHT, SHOW TYPE

/mob/living/simple_animal/hostile/guardian/proc/Manifest(forced)
	if(istype(summoner.loc, /obj/effect) || (cooldown > world.time && !forced))
		return FALSE
	if(loc == summoner)
		forceMove(summoner.loc)
		new /obj/effect/temp_visual/guardian/phase(loc)
		cooldown = world.time + 10
		reset_perspective()
		return TRUE
	return FALSE

/mob/living/simple_animal/hostile/guardian/proc/Recall(forced)
	if(!summoner || loc == summoner || (cooldown > world.time && !forced))
		return FALSE
	new /obj/effect/temp_visual/guardian/phase/out(loc)

	forceMove(summoner)
	cooldown = world.time + 10
	return TRUE

/mob/living/simple_animal/hostile/guardian/proc/ToggleMode()
	to_chat(src, "<span class='danger'><B>You don't have another mode!</span></B>")

/mob/living/simple_animal/hostile/guardian/proc/ToggleLight()
	if(light_range<3)
		to_chat(src, "<span class='notice'>You activate your light.</span>")
		set_light(3)
	else
		to_chat(src, "<span class='notice'>You deactivate your light.</span>")
		set_light(0)

/mob/living/simple_animal/hostile/guardian/verb/ShowType()
	set name = "Check Guardian Type"
	set category = "Guardian"
	set desc = "Check what type you are."
	to_chat(src, playstyle_string)

//COMMUNICATION

/mob/living/simple_animal/hostile/guardian/proc/Communicate()
	if(summoner)
		var/input = stripped_input(src, "Please enter a message to tell your summoner.", "Guardian", "")
		if(!input)
			return

		var/preliminary_message = "<span class='holoparasite bold'>[input]</span>" //apply basic color/bolding
		var/my_message = "<font color=\"[guardiancolor]\"><b><i>[src]:</i></b></font> [preliminary_message]" //add source, color source with the guardian's color

		to_chat(summoner, my_message)
		var/list/guardians = summoner.hasparasites()
		for(var/para in guardians)
			to_chat(para, my_message)
		for(var/M in GLOB.dead_mob_list)
			var/link = FOLLOW_LINK(M, src)
			to_chat(M, "[link] [my_message]")

		src.log_talk(input, LOG_SAY, tag="guardian")

/mob/living/proc/guardian_comm()
	set name = "Communicate"
	set category = "Guardian"
	set desc = "Communicate telepathically with your guardian."
	var/input = stripped_input(src, "Please enter a message to tell your guardian.", "Message", "")
	if(!input)
		return

	var/preliminary_message = "<span class='holoparasite bold'>[input]</span>" //apply basic color/bolding
	var/my_message = "<span class='holoparasite bold'><i>[src]:</i> [preliminary_message]</span>" //add source, color source with default grey...

	to_chat(src, my_message)
	var/list/guardians = hasparasites()
	for(var/para in guardians)
		var/mob/living/simple_animal/hostile/guardian/G = para
		to_chat(G, "<font color=\"[G.guardiancolor]\"><b><i>[src]:</i></b></font> [preliminary_message]" )
	for(var/M in GLOB.dead_mob_list)
		var/link = FOLLOW_LINK(M, src)
		to_chat(M, "[link] [my_message]")

	src.log_talk(input, LOG_SAY, tag="guardian")

//FORCE RECALL/RESET

/mob/living/proc/guardian_recall()
	set name = "Recall Guardian"
	set category = "Guardian"
	set desc = "Forcibly recall your guardian."
	var/list/guardians = hasparasites()
	for(var/para in guardians)
		var/mob/living/simple_animal/hostile/guardian/G = para
		G.Recall()

/mob/living/proc/guardian_reset()
	set name = "Reset Guardian Player (One Use)"
	set category = "Guardian"
	set desc = "Re-rolls which ghost will control your Guardian. One use per Guardian."

	var/list/guardians = hasparasites()
	for(var/para in guardians)
		var/mob/living/simple_animal/hostile/guardian/P = para
		if(P.reset)
			guardians -= P //clear out guardians that are already reset
	if(guardians.len)
		var/mob/living/simple_animal/hostile/guardian/G = input(src, "Pick the guardian you wish to reset", "Guardian Reset") as null|anything in guardians
		if(G)
			to_chat(src, "<span class='holoparasite'>You attempt to reset <font color=\"[G.guardiancolor]\"><b>[G.real_name]</b></font>'s personality...</span>")
			var/list/mob/candidates = pollGhostCandidates("Do you want to play as [src.real_name]'s [G.real_name]?", ROLE_PAI, null, FALSE, 100)
			if(LAZYLEN(candidates))
				var/mob/C = pick(candidates)
				to_chat(G, "<span class='holoparasite'>Your user reset you, and your body was taken over by a ghost. Looks like they weren't happy with your performance.</span>")
				to_chat(src, "<span class='holoparasite bold'>Your <font color=\"[G.guardiancolor]\">[G.real_name]</font> has been successfully reset.</span>")
				message_admins("[key_name_admin(C)] has taken control of ([key_name_admin(G)])")
				G.ghostize(FALSE)
				G.guardiancustomize() //give it a new color, to show it's a new person
				C.transfer_ckey(G)
				G.reset = 1
				switch(G.theme)
					if("tech")
						to_chat(src, "<span class='holoparasite'><font color=\"[G.guardiancolor]\"><b>[G.real_name]</b></font> is now online!</span>")
					if("magic")
						to_chat(src, "<span class='holoparasite'><font color=\"[G.guardiancolor]\"><b>[G.real_name]</b></font> has been summoned!</span>")
					if("carp")
						to_chat(src, "<span class='holoparasite'><font color=\"[G.guardiancolor]\"><b>[G.real_name]</b></font> has been caught!</span>")
				guardians -= G
				if(!guardians.len)
					remove_verb(src, /mob/living/proc/guardian_reset)
			else
				to_chat(src, "<span class='holoparasite'>There were no ghosts willing to take control of <font color=\"[G.guardiancolor]\"><b>[G.real_name]</b></font>. Looks like you're stuck with it for now.</span>")
		else
			to_chat(src, "<span class='holoparasite'>You decide not to reset [guardians.len > 1 ? "any of your guardians":"your guardian"].</span>")
	else
		remove_verb(src, /mob/living/proc/guardian_reset)

////////parasite tracking/finding procs

/mob/living/proc/hasparasites() //returns a list of guardians the mob is a summoner for
	. = list()
	for(var/P in GLOB.parasites)
		var/mob/living/simple_animal/hostile/guardian/G = P
		if(G.summoner == src)
			. += G

/mob/living/simple_animal/hostile/guardian/proc/hasmatchingsummoner(mob/living/simple_animal/hostile/guardian/G) //returns 1 if the summoner matches the target's summoner
	return (istype(G) && G.summoner == summoner)


////////Creation

/obj/item/guardiancreator
	name = "deck of tarot cards"
	desc = "An enchanted deck of tarot cards, rumored to be a source of unimaginable power."
	icon = 'icons/obj/toys/toy.dmi'
	icon_state = "deck_syndicate_full"
	var/used = FALSE
	var/theme = "magic"
	var/mob_name = "Guardian Spirit"
	var/use_message = "<span class='holoparasite'>You shuffle the deck...</span>"
	var/used_message = "<span class='holoparasite'>All the cards seem to be blank now.</span>"
	var/failure_message = "<span class='holoparasite bold'>..And draw a card! It's...blank? Maybe you should try again later.</span>"
	var/ling_failure = "<span class='holoparasite bold'>The deck refuses to respond to a souless creature such as you.</span>"
	var/list/possible_guardians = list("Assassin", "Chaos", "Gravitokinetic", "Charger", "Explosive", "Lightning", "Protector", "Ranged", "Standard", "Support")
	var/random = TRUE
	var/allowmultiple = FALSE
	var/allowling = TRUE
	var/allowguardian = FALSE

/obj/item/guardiancreator/attack_self(mob/living/user)
	if(isguardian(user) && !allowguardian)
		to_chat(user, "<span class='holoparasite'>[mob_name] chains are not allowed.</span>")
		return
	var/list/guardians = user.hasparasites()
	if(guardians.len && !allowmultiple)
		to_chat(user, "<span class='holoparasite'>You already have a [mob_name]!</span>")
		return
	if(user.mind && user.mind.has_antag_datum(/datum/antagonist/changeling) && !allowling)
		to_chat(user, "[ling_failure]")
		return
	if(used == TRUE)
		to_chat(user, "[used_message]")
		return
	if(type == /obj/item/guardiancreator)
		switch(alert(user, "Желаете ли вы выбрать тип защитника? Однако в этом случае ваше тело рассыпется в прах при вашей смерти.",, "Да", "Пусть решит судьба", "Отмена призыва"))
			if("Да")
				random = FALSE
			if("Пусть решит судьба")
				random = TRUE
			if("Отмена призыва")
				return
	used = TRUE
	to_chat(user, "[use_message]")
	var/list/mob/candidates = pollGhostCandidates("Do you want to play as the [mob_name] of [user.real_name]?", ROLE_PAI, null, FALSE, 100, POLL_IGNORE_HOLOPARASITE)

	if(LAZYLEN(candidates))
		var/mob/C = pick(candidates)
		spawn_guardian(user, C.key)
	else
		to_chat(user, "[failure_message]")
		used = FALSE


/obj/item/guardiancreator/proc/spawn_guardian(var/mob/living/user, var/key)
	var/guardiantype = "Standard"
	if(random)
		guardiantype = pick(possible_guardians)
	else
		guardiantype = input(user, "Pick the type of [mob_name]", "[mob_name] Creation") as null|anything in possible_guardians
		if(!guardiantype)
			to_chat(user, "[failure_message]" )
			used = FALSE
			return
	var/pickedtype = /mob/living/simple_animal/hostile/guardian/punch
	switch(guardiantype)

		if("Chaos")
			pickedtype = /mob/living/simple_animal/hostile/guardian/fire

		if("Gravitokinetic")
			pickedtype = /mob/living/simple_animal/hostile/guardian/gravitokinetic

		if("Standard")
			pickedtype = /mob/living/simple_animal/hostile/guardian/punch

		if("Ranged")
			pickedtype = /mob/living/simple_animal/hostile/guardian/ranged

		if("Support")
			pickedtype = /mob/living/simple_animal/hostile/guardian/healer

		if("Explosive")
			pickedtype = /mob/living/simple_animal/hostile/guardian/bomb

		if("Lightning")
			pickedtype = /mob/living/simple_animal/hostile/guardian/beam

		if("Protector")
			pickedtype = /mob/living/simple_animal/hostile/guardian/protector

		if("Charger")
			pickedtype = /mob/living/simple_animal/hostile/guardian/charger

		if("Assassin")
			pickedtype = /mob/living/simple_animal/hostile/guardian/assassin

		if("Dextrous")
			pickedtype = /mob/living/simple_animal/hostile/guardian/dextrous

	var/list/guardians = user.hasparasites()
	if(guardians.len && !allowmultiple)
		to_chat(user, "<span class='holoparasite'>You already have a [mob_name]!</span>" )
		used = FALSE
		return
	var/mob/living/simple_animal/hostile/guardian/G = new pickedtype(user, theme)
	G.name = mob_name
	G.summoner = user
	G.key = key
	G.mind.enslave_mind_to_creator(user)
	if(type == /obj/item/guardiancreator)
		G.was_randomized = random
	log_game("[key_name(user)] has summoned [key_name(G)], a [guardiantype] holoparasite.")
	switch(theme)
		if("tech")
			to_chat(user, "[G.tech_fluff_string]")
			to_chat(user, "<span class='holoparasite'><b>[G.real_name]</b> is now online!</span>")
		if("magic")
			to_chat(user, "[G.magic_fluff_string]")
			to_chat(user, "<span class='holoparasite'><b>[G.real_name]</b> has been summoned!</span>")
		if("carp")
			to_chat(user, "[G.carp_fluff_string]")
			to_chat(user, "<span class='holoparasite'><b>[G.real_name]</b> has been caught!</span>")
	add_verb(user, list(/mob/living/proc/guardian_comm, \
						/mob/living/proc/guardian_recall, \
						/mob/living/proc/guardian_reset))

/obj/item/guardiancreator/choose
	random = FALSE

/obj/item/guardiancreator/choose/dextrous
	possible_guardians = list("Assassin", "Chaos", "Gravitokinetic", "Charger", "Dextrous", "Explosive", "Lightning", "Protector", "Ranged", "Standard", "Support")

/obj/item/guardiancreator/choose/wizard
	possible_guardians = list("Assassin", "Chaos", "Gravitokinetic", "Charger", "Dextrous", "Explosive", "Lightning", "Protector", "Ranged", "Standard")
	allowmultiple = TRUE

/obj/item/guardiancreator/tech
	name = "holoparasite injector"
	desc = "It contains an alien nanoswarm of unknown origin. Though capable of near sorcerous feats via use of hardlight holograms and nanomachines, it requires an organic host as a home base and source of fuel."
	icon = 'icons/obj/syringe.dmi'
	icon_state = "combat_hypo"
	theme = "tech"
	mob_name = "Holoparasite"
	use_message = "<span class='holoparasite'>You start to power on the injector...</span>"
	used_message = "<span class='holoparasite'>The injector has already been used.</span>"
	failure_message = "<span class='holoparasite bold'>...ERROR. BOOT SEQUENCE ABORTED. AI FAILED TO INTIALIZE. PLEASE CONTACT SUPPORT OR TRY AGAIN LATER.</span>"
	ling_failure = "<span class='holoparasite bold'>The holoparasites recoil in horror. They want nothing to do with a creature like you.</span>"

/obj/item/guardiancreator/tech/choose/traitor
	possible_guardians = list("Assassin", "Chaos", "Gravitokinetic", "Charger", "Explosive", "Lightning", "Protector", "Ranged", "Standard", "Support")
	allowling = FALSE

/obj/item/guardiancreator/tech/choose/traitor/check_uplink_validity()
	return !used

/obj/item/guardiancreator/tech/choose
	random = FALSE

/obj/item/guardiancreator/tech/choose/dextrous
	possible_guardians = list("Assassin", "Chaos", "Gravitokinetic", "Charger", "Dextrous", "Explosive", "Lightning", "Protector", "Ranged", "Standard", "Support")

/obj/item/guardiancreator/tech/choose/nukie // lacks support and protector as encouraging nukies to play turtle isnt fun and dextrous is epic
	possible_guardians = list("Assassin", "Chaos", "Gravitokinetic", "Charger", "Dextrous", "Explosive", "Lightning", "Ranged", "Standard")

/obj/item/guardiancreator/tech/choose/nukie/check_uplink_validity()
	return !used

/obj/item/paper/guides/antag/guardian
	name = "Holoparasite Guide"
	icon_state = "paper_words"
	default_raw_text = {"<b>A list of Holoparasite Types</b><br>

 <br>
 <b>Assassin</b>: Does medium damage and takes full damage, but can enter stealth, causing its next attack to do massive damage and ignore armor. However, it becomes briefly unable to recall after attacking from stealth.<br>
 <br>
 <b>Chaos</b>: Ignites enemies on touch and causes them to hallucinate all nearby people as the parasite. Automatically extinguishes the user if they catch on fire.<br>
 <br>
 <b>Charger</b>: Moves extremely fast, does medium damage on attack, and can charge at targets, damaging the first target hit and forcing them to drop any items they are holding.<br>
 <br>
 <b>Explosive</b>: High damage resist and medium power attack that may explosively teleport targets. Can turn any object, including objects too large to pick up, into a bomb, dealing explosive damage to the next person to touch it. The object will return to normal after the trap is triggered or after a delay.<br>
 <br>
 <b>Gravitokinetic</b>: Attacks will apply crushing gravity to the target. Can target the ground as well to slow targets advancing on you, but this will affect the user.<br>
 <br>
 <b>Lightning</b>: Attacks apply lightning chains to targets. Has a lightning chain to the user. Lightning chains shock everything near them, doing constant damage.<br>
 <br>
 <b>Protector</b>: Causes you to teleport to it when out of range, unlike other parasites. Has two modes; Combat, where it does and takes medium damage, and Protection, where it does and takes almost no damage but moves slightly slower.<br>
 <br>
 <b>Ranged</b>: Has two modes. Ranged; which fires a constant stream of weak, armor-ignoring projectiles. Scout; Cannot attack, but can move through walls and is quite hard to see. Can lay surveillance snares, which alert it when crossed, in either mode.<br>
 <br>
 <b>Standard</b>: Devastating close combat attacks and high damage resist. Can smash through weak walls.<br>
 <br>
"}

/obj/item/paper/guides/antag/guardian/ComponentInitialize()
	. = ..()
	AddElement(/datum/element/update_icon_blocker)

/obj/item/paper/guides/antag/guardian/wizard
	name = "Guardian Guide"
	default_raw_text = {"<b>A list of Guardian Types</b><br>

 <br>
 <b>Assassin</b>: Does medium damage and takes full damage, but can enter stealth, causing its next attack to do massive damage and ignore armor. However, it becomes briefly unable to recall after attacking from stealth.<br>
 <br>
 <b>Chaos</b>: Ignites enemies on touch and causes them to hallucinate all nearby people as the guardian. Automatically extinguishes the user if they catch on fire.<br>
 <br>
 <b>Charger</b>: Moves extremely fast, does medium damage on attack, and can charge at targets, damaging the first target hit and forcing them to drop any items they are holding.<br>
 <br>
 <b>Dextrous</b>: Does low damage on attack, but is capable of holding items and storing a single item within it. It will drop items held in its hands when it recalls, but it will retain the stored item.<br>
 <br>
 <b>Explosive</b>: High damage resist and medium power attack that may explosively teleport targets. Can turn any object, including objects too large to pick up, into a bomb, dealing explosive damage to the next person to touch it. The object will return to normal after the trap is triggered or after a delay.<br>
 <br>
 <b>Gravitokinetic</b>: Attacks will apply crushing gravity to the target. Can target the ground as well to slow targets advancing on you, but this will affect the user.<br>
 <br>
 <b>Lightning</b>: Attacks apply lightning chains to targets. Has a lightning chain to the user. Lightning chains shock everything near them, doing constant damage.<br>
 <br>
 <b>Protector</b>: Causes you to teleport to it when out of range, unlike other parasites. Has two modes; Combat, where it does and takes medium damage, and Protection, where it does and takes almost no damage but moves slightly slower.<br>
 <br>
 <b>Ranged</b>: Has two modes. Ranged; which fires a constant stream of weak, armor-ignoring projectiles. Scout; Cannot attack, but can move through walls and is quite hard to see. Can lay surveillance snares, which alert it when crossed, in either mode.<br>
 <br>
 <b>Standard</b>: Devastating close combat attacks and high damage resist. Can smash through weak walls.<br>
 <br>
"}

/obj/item/paper/guides/antag/guardian/nukie
	name = "Guardian Guide"
	default_raw_text = {"<b>A list of Guardian Types</b><br>

 <br>
 <b>Assassin</b>: Does medium damage and takes full damage, but can enter stealth, causing its next attack to do massive damage and ignore armor. However, it becomes briefly unable to recall after attacking from stealth.<br>
 <br>
 <b>Chaos</b>: Ignites enemies on touch and causes them to hallucinate all nearby people as the guardian. Automatically extinguishes the user if they catch on fire.<br>
 <br>
 <b>Charger</b>: Moves extremely fast, does medium damage on attack, and can charge at targets, damaging the first target hit and forcing them to drop any items they are holding.<br>
 <br>
 <b>Dextrous</b>: Does low damage on attack, but is capable of holding items and storing a single item within it. It will drop items held in its hands when it recalls, but it will retain the stored item.<br>
 <br>
 <b>Explosive</b>: High damage resist and medium power attack that may explosively teleport targets. Can turn any object, including objects too large to pick up, into a bomb, dealing explosive damage to the next person to touch it. The object will return to normal after the trap is triggered or after a delay.<br>
 <br>
 <b>Gravitokinetic</b>: Attacks will apply crushing gravity to the target. Can target the ground as well to slow targets advancing on you, but this will affect the user.<br>
 <br>
 <b>Lightning</b>: Attacks apply lightning chains to targets. Has a lightning chain to the user. Lightning chains shock everything near them, doing constant damage.<br>
 <br>
 <b>Ranged</b>: Has two modes. Ranged; which fires a constant stream of weak, armor-ignoring projectiles. Scout; Cannot attack, but can move through walls and is quite hard to see. Can lay surveillance snares, which alert it when crossed, in either mode.<br>
 <br>
 <b>Standard</b>: Devastating close combat attacks and high damage resist. Can smash through weak walls.<br>
 <br>
"}

/obj/item/storage/box/syndie_kit/guardian
	name = "holoparasite injector kit"

/obj/item/storage/box/syndie_kit/guardian/PopulateContents()
	new /obj/item/guardiancreator/tech/choose/traitor(src)
	new /obj/item/paper/guides/antag/guardian(src)

/obj/item/storage/box/syndie_kit/nukieguardian
	name = "holoparasite injector kit"

/obj/item/storage/box/syndie_kit/nukieguardian/PopulateContents()
	new /obj/item/guardiancreator/tech/choose/nukie(src)
	new /obj/item/paper/guides/antag/guardian/nukie(src)

/obj/item/guardiancreator/carp
	name = "holocarp fishsticks"
	desc = "Using the power of Carp'sie, you can catch a carp from byond the veil of Carpthulu, and bind it to your fleshy flesh form."
	icon = 'icons/obj/food/food.dmi'
	icon_state = "fishfingers"
	theme = "carp"
	mob_name = "Holocarp"
	use_message = "<span class='holoparasite'>You put the fishsticks in your mouth...</span>"
	used_message = "<span class='holoparasite'>Someone's already taken a bite out of these fishsticks! Ew.</span>"
	failure_message = "<span class='holoparasite bold'>You couldn't catch any carp spirits from the seas of Lake Carp. Maybe there are none, maybe you fucked up.</span>"
	ling_failure = "<span class='holoparasite bold'>Carp'sie is fine with changelings, so you shouldn't be seeing this message.</span>"
	allowmultiple = TRUE

/obj/item/guardiancreator/carp/choose
	random = FALSE
