local appName, internal = ...
local require = internal.require;

function internal.build.underwear()
	local lib = ExiWoW.R.underwear;
	local uw = require("Underwear");
	table.insert(lib, uw:new({
		id = "DEFAULT",
		name = "Linen Underwear",
		icon = "Inv_misc_desecrated_clothpants",
		description = "A basic pair of linen underwear.",
		rarity = 1,
		tags = {},
	}));

	table.insert(lib, uw:new({
		id = "LEATHER_THONG",
		name = "Leather Thong",
		icon = "6or_garrison_hangingleather",
		description = "A leather thong.",
		tags = {},
	}));

	table.insert(lib, uw:new({
		id = "ORCISH_BRIEFS",
		name = "Orcish Briefs",
		icon = "item_savageleatherhide",
		description = "Orcish briefs made of haphazardly stitched together pieces of hide.",
		tags = {},
	}));

	table.insert(lib, uw:new({
		id = "KULTIRAS_BOXERS",
		name = "Kul Tiras Boxers",
		icon = "inv_misc_anchor",
		description = "White boxer shorts made of anchor-patterned cotton. Made with gold colored trimmings.",
		rarity = 3,
		tags = {},
	}));

	table.insert(lib, uw:new({
		id = "HIGH_RISING_BIKINI_THONG_PINK",
		name = "High Rising Bikini Thong",
		icon = "inv_belt_cloth_draenei_c_01",
		description = "A pink high rising bikini thong, made out of a stretchy material.",
		rarity = 3,
		tags = {},
	}));

	table.insert(lib, uw:new({
		id = "SKULL_STRAP",
		name = "Skull Strap",
		icon = "inv_helm_laughingskull_01",
		description = "A hollowed out skull with straps attached to it, just about covers your crotch.",
		rarity = 3,
		tags = {},
	}));

	table.insert(lib, uw:new({
		id = "RAZAANI_SOULTHONG",
		name = "Razaani Soulthong",
		icon = "inv_cloth_raidmage_p_01shoulder",
		description = "A thong made of light pink silk wrappings with sparkling soulgems attached around the waist straps.",
		rarity = 3,
		tags = {},
	}));

	table.insert(lib, uw:new({
		id = "FURBOLG_LOINCLOTH",
		name = "Furbolg Loincloth",
		icon = "inv_misc_leatherscrap_16",
		description = "A tattered leather thong with rope straps, usually worn by furbolgs.",
		tags = {},
	}));

	table.insert(lib, uw:new({
		id = "FELCLOTH_PANTIES",
		name = "Felcloth Panties",
		icon = "6or_garrison_clothroof",
		description = "Red panties made of felcloth, with black trimmings.",
		tags = {},
	}));

	table.insert(lib, uw:new({
		id = "LEAF_PANTIES",
		name = "Leaf Panties",
		icon = "ability_druid_flourish",
		rarity = 4,
		description = "Panties made of thick shiny green leaves. Super smooth to the touch.",
		tags = {},
	}));

	table.insert(lib, uw:new({
		id = "WOOLY_SHORTS",
		name = "Wooly Shorts",
		icon = "inv_pants_leather_31red",
		description = "Brown wooly shorts. They're sure to keep you warm!",
		tags = {},
	}));

	table.insert(lib, uw:new({
		id = "JEWELED_HARPY_THONG",
		name = "Jeweled Harpy Thong",
		icon = "inv_misc_necklace_beads10",
		description = "A thong made of a bunch of woven together strings, with large jewels hanging off of it!",
		tags = {},
	}));

	table.insert(lib, uw:new({
		id = "SPIKED_LEATHER_JOCKSTRAP",
		name = "Spiked Leather Jockstrap",
		icon = "inv_misc_spikedbracer",
		rarity = 4,
		description = "A jockstrap made of thick leather with spikes protruding from the groin.",
		tags = {},
	}));

	table.insert(lib, uw:new({
		id = "NETHERWEAVE_PANTIES",
		name = "Netherweave Panties",
		icon = "inv_fabric_netherweave_bolt_imbued",
		rarity = 3,
		description = "Tiny panties in a pink to purple gradient color made from netherweave.",
		tags = {},
	}));

	table.insert(lib, uw:new({
		id = "CRESCENT_THONG",
		name = "Crescent Thong",
		icon = "inv_fabric_moonshroud",
		rarity = 3,
		description = "A white-ish pink colored silk thong with a glowing crescent on the front.",
		tags = {},
	}));

	table.insert(lib, uw:new({
		id = "BLACK_LACE_PANTIES",
		name = "Black Lace Panties",
		icon = "inv_cape_cloth_raidpriest_r_01",
		rarity = 3,
		description = "Lace panties in a black satin material.",
		tags = {},
	}));

	table.insert(lib, uw:new({
		id = "BLACK_LACE_SHORTS",
		name = "Black Lace Shorts",
		icon = "inv_cloth_mageclass_d_01pants",
		rarity = 3,
		description = "Lace shorts in a black satin material.",
		tags = {},
	}));

	table.insert(lib, uw:new({
		id = "TWILIGHT_BRIEFS",
		name = "Twilight Briefs",
		icon = "Inv_pant_cloth_raidwarlock_r_01",
		rarity = 2,
		description = "Black briefs in a soft material with red trimmings.",
		tags = {},
	}));

	table.insert(lib, uw:new({
		id = "MANA_GEM_THONG",
		name = "Mana Gem Thong",
		icon = "spell_misc_conjuremanajewel",
		rarity = 3,
		description = "A bright white silken thong with sparkling pink trimmings radiating mana.",
		tags = {},
	}));

	table.insert(lib, uw:new({
		id = "ARCHMAGE_BRIEFS",
		name = "Archmage Briefs",
		icon = "inv_legion_faction_kirintor",
		rarity = 3,
		description = "Purple silken briefs with the kirin tor symbol on the front and silvery trimmings.",
		tags = {},
	}));

	table.insert(lib, uw:new({
		id = "BRIGHT_WHITE_BIKINI_BOTTOMS",
		name = "Bright-white Bikini Bottoms",
		icon = "Inv_misc_embercloth",
		rarity = 3,
		description = "A bright-white Shal'dorei silk thong with small snaps on the sides adorned with ancient mana crystals.",
		tags = {},
	}));

	table.insert(lib, uw:new({
		id = "FEL_LEATHER_BRIEFS",
		name = "Fel Leather Briefs",
		icon = "Inv_helm_leather_raidmonkmythic_p_01",
		rarity = 3,
		description = "Black leather briefs inscribed with green glowing fel runes. Wear at your own risk.",
		tags = {},
	}));
	
end

