//every quirk in this folder should be coded around being applied on spawn
//these are NOT "mob quirks" like GOTTAGOFAST, but exist as a medium to apply them and other different effects
/datum/quirk
	/// The name of the quirk
	var/name = "Незнайка"
	/// The description of the quirk
	var/desc = "Буквально особенность, которая ничего не делает!"
	/// What the quirk is worth in preferences, zero = neutral / free
	var/value = 0
	var/human_only = TRUE
	/// Text displayed when this quirk is assigned to a mob (and not transferred)
	var/gain_text
	/// Text displayed when this quirk is removed from a mob (and not transferred)
	var/lose_text
	/// This text will appear on medical records for the trait.
	var/medical_record_text
	/// Text will be given to the quirk holder if they get an antag that has it blacklisted.
	var/antag_removal_text
	var/mood_quirk = FALSE //if true, this quirk affects mood and is unavailable if moodlets are disabled
	/// if applicable, apply and remove this mob trait
	var/mob_trait
	/// should we immediately call on_spawn or add a timer to trigger
	var/on_spawn_immediate = TRUE
	/// Reference to the mob currently tied to this quirk datum. Quirks are not singletons.
	var/mob/living/quirk_holder
	var/processing_quirk = FALSE
	/// A lazylist of items people can receive from mail who have this quirk enabled
	/// The base weight for the each quirk's mail goodies list to be selected is 5
	/// then the item selected is determined by pick(selected_quirk.mail_goodies)
	var/list/mail_goodies = list()
	// Отвечает за то не пишется-ли данный квирк на медсканерах и худах (FALSE = пишется)
	var/flavor_quirk = FALSE

/datum/quirk/New(mob/living/quirk_mob, spawn_effects)
	if(!quirk_mob || (human_only && !ishuman(quirk_mob)) || quirk_mob.has_quirk(type))
		qdel(src)
		return
	quirk_holder = quirk_mob
	SSquirks.quirk_objects += src
	if(gain_text)
		to_chat(quirk_holder, gain_text)
	quirk_holder.roundstart_quirks += src
	if(mob_trait)
		ADD_TRAIT(quirk_holder, mob_trait, ROUNDSTART_TRAIT)
	if(processing_quirk)
		START_PROCESSING(SSquirks, src)
	add()
	if(spawn_effects)
		if(on_spawn_immediate)
			on_spawn()
		else
			addtimer(CALLBACK(src, PROC_REF(on_spawn)), 0)
		addtimer(CALLBACK(src, PROC_REF(post_add)), 30)

/datum/quirk/Destroy()
	if(processing_quirk)
		STOP_PROCESSING(SSquirks, src)
	if(quirk_holder)
		if(lose_text)
			to_chat(quirk_holder, lose_text)
		quirk_holder.roundstart_quirks -= src
		if(mob_trait)
			REMOVE_TRAIT(quirk_holder, mob_trait, ROUNDSTART_TRAIT)
		remove()
	SSquirks.quirk_objects -= src
	return ..()

/datum/quirk/proc/transfer_mob(mob/living/to_mob)
	quirk_holder.roundstart_quirks -= src
	to_mob.roundstart_quirks += src
	if(mob_trait)
		REMOVE_TRAIT(quirk_holder, mob_trait, ROUNDSTART_TRAIT)
		ADD_TRAIT(to_mob, mob_trait, ROUNDSTART_TRAIT)
	quirk_holder = to_mob
	on_transfer()

/datum/quirk/proc/add() //special "on add" effects
/datum/quirk/proc/on_spawn() //these should only trigger when the character is being created for the first time, i.e. roundstart/latejoin
/datum/quirk/proc/remove() //special "on remove" effects
/datum/quirk/proc/on_process() //process() has some special checks, so this is the actual process
/datum/quirk/proc/post_add() //for text, disclaimers etc. given after you spawn in with the trait
/datum/quirk/proc/on_transfer() //code called when the trait is transferred to a new mob

/datum/quirk/proc/clone_data() //return additional data that should be remembered by cloning
/datum/quirk/proc/on_clone(data) //create the quirk from clone data

/datum/quirk/process()
	if(QDELETED(quirk_holder))
		quirk_holder = null
		qdel(src)
		return
	if(quirk_holder.stat == DEAD)
		return
	on_process()

//BLUEMOON CHANGE добавляем "укороченную" версию текста для медсканеров и делаем текстик медзаписей красиво
/mob/living/proc/get_trait_string(medical, short) //helper string. gets a string of all the traits the mob has
	var/list/dat = list()
	if(!medical)
		for(var/V in roundstart_quirks)
			var/datum/quirk/T = V
			if(short && T.flavor_quirk)
				continue
			dat += T.name
		if(!dat.len)
			return "Отсутствуют"
		return dat.Join(", ")
	else
		for(var/V in roundstart_quirks)
			var/datum/quirk/T = V
			if(T.medical_record_text)
				dat += T.medical_record_text
			else
				continue
		if(!dat.len)
			return FALSE
		return dat.Join(" ; ")
//BLUEMOON CHANGE END

/mob/living/proc/cleanse_trait_datums() //removes all trait datums
	for(var/V in roundstart_quirks)
		var/datum/quirk/T = V
		qdel(T)

/mob/living/proc/transfer_trait_datums(mob/living/to_mob)
	for(var/V in roundstart_quirks)
		var/datum/quirk/T = V
		T.transfer_mob(to_mob)

/*

Commented version of Nearsighted to help you add your own traits
Use this as a guideline

/datum/quirk/nearsighted
	name = "Nearsighted"
	///The trait's name

	desc = "You are nearsighted without prescription glasses, but spawn with a pair."
	///Short description, shows next to name in the trait panel

	value = -1
	///If this is above 0, it's a positive trait; if it's not, it's a negative one; if it's 0, it's a neutral

	mob_trait = TRAIT_NEARSIGHT
	///This define is in __DEFINES/traits.dm and is the actual "trait" that the game tracks
	///You'll need to use "HAS_TRAIT_FROM(src, X, sources)" checks around the code to check this; for instance, the Ageusia trait is checked in taste code
	///If you need help finding where to put it, the declaration finder on GitHub is the best way to locate it

	gain_text = "<span class='danger'>Things far away from you start looking blurry.</span>"
	lose_text = "<span class='notice'>You start seeing faraway things normally again.</span>"
	medical_record_text = "Subject has permanent nearsightedness."
	///These three are self-explanatory

/datum/quirk/nearsighted/on_spawn()
	var/mob/living/carbon/human/H = quirk_holder
	var/obj/item/clothing/glasses/regular/glasses = new(get_turf(H))
	H.put_in_hands(glasses)
	H.equip_to_slot(glasses, ITEM_SLOT_EYES)
	H.regenerate_icons()

//This whole proc is called automatically
//It spawns a set of prescription glasses on the user, then attempts to put it into their hands, then attempts to make them equip it.
//This means that if they fail to equip it, they glasses spawn in their hands, and if they fail to be put into the hands, they spawn on the ground
//Hooray for fallbacks!
//If you don't need any special effects like spawning glasses, then you don't need an add()

*/
