local appName, internal = ...
local export = internal.Module.export;
local require = internal.require;

local UI, Timer, Event, Action, Underwear, Index, SpellBinding, Tools, RPText, Condition;

-- Contains info about a character, 
local Character = {}
	Character.__index = Character;
	Character.evtFrame = CreateFrame("Frame");
	Character.eventBindings = {};		-- {id:(int)id, evt:(str)evt, fn:(func)function, numTriggers:(int)numTriggers=inf}
	Character.eventBindingIndex = 0;	

	Character.takehitCD = nil			-- Cooldown for takehit texts
	Character.whisperCD = nil

	local myGUID = UnitGUID("player")

	-- Consts
	Character.EXCITEMENT_FADE_PER_SEC = 0.05;
	Character.EXCITEMENT_MAX = 1.25;				-- You can overshoot max excitement and have to wait longer
	Character.EXCITEMENT_FADE_IDLE = 0.001;
	Character.AURAS = {}
	Character.lootContainer = nil					-- Loot container name when looting a container through the "Open" spell

	function Character.getTakehitCD() return Character.takehitCD end
	function Character.getWhisperCD() return Character.whisperCD end

	-- Static
	function Character.ini()

		UI = require("UI");
		Timer = require("Timer");
		Event = require("Event");
		Action = require("Action");
		Underwear = require("Underwear");
		Index = require("Index");
		SpellBinding = require("SpellBinding");
		Tools = require("Tools");
		RPText = require("RPText");
		Condition = require("Condition");

		Character.evtFrame:SetScript("OnEvent", Character.onEvent)
		Character.evtFrame:RegisterEvent("PLAYER_STARTED_MOVING")
		Character.evtFrame:RegisterEvent("PLAYER_STOPPED_MOVING")
		Character.evtFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", "player");
		Character.evtFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCESS", "player");
		
		Character.evtFrame:RegisterEvent("SOUNDKIT_FINISHED");
		Character.evtFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		Character.evtFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
		Character.evtFrame:RegisterUnitEvent("UNIT_AURA", "player")
		Character.evtFrame:RegisterEvent("UNIT_AURA", "player")
		Character.evtFrame:RegisterEvent("UNIT_SPELLCAST_SENT");
		Character.evtFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player")
		Character.evtFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED_QUIET", "player")

		Character.evtFrame:RegisterEvent("LOOT_OPENED");
		Character.evtFrame:RegisterEvent("LOOT_SLOT_CLEARED");
		Character.evtFrame:RegisterEvent("LOOT_CLOSED");
		

		-- Main timer, ticking once per second
		Timer.set(function()
			
			-- Owner meditation
			local me = ExiWoW.ME;
			local fade = 0;
			if me.meditating then
				fade = Character.EXCITEMENT_FADE_PER_SEC;
			elseif not UnitAffectingCombat("player") then
				fade = Character.EXCITEMENT_FADE_IDLE;
			end
			me:addExcitement(-fade);


		end, 1, math.huge)

	end

	function Character.onEvent(self, event, ...)

		local arguments = {...}

		-- Local functions
		local function buildSpellTrigger(spellId, name, harmful, unitCaster, count, crit, char)
			return { spellId = spellId, name=name, harmful=harmful, unitCaster=unitCaster, count=count, crit=crit, char=char}
		end

		local function triggerWhisper(sender, spelldata, spellType)
			if math.random() > globalStorage.taunt_freq then return end 
			if Character.whisperCD then return end

			if RPText.trigger("_WHISPER_", sender, ExiWoW.ME, spelldata, spellType) then
				if globalStorage.taunt_rp_rate > 0 then
					Character.whisperCD = Timer.set(function()
						Character.whisperCD = nil
					end, globalStorage.taunt_rp_rate);
				end
			end
			
		end

		-- Handle combat log
		-- This needs to go first as it should only handle event bindings on the player
		if event == "COMBAT_LOG_EVENT_UNFILTERED" and Index.checkHardLimits("player", "player", true) then

			local timestamp, combatEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags =  ...; -- Those arguments appear for all combat event variants.
			local eventPrefix, eventSuffix = combatEvent:match("^(.-)_?([^_]*)$");

			-- See if a viable unit exists
			local u = false
			if sourceGUID == UnitGUID("target") then u = "target"
			elseif sourceGUID == UnitGUID("focus") then u = "focus"
			elseif sourceGUID == UnitGUID("mouseover") then u = "mouseover"
			elseif sourceGUID == UnitGUID("player") then u = "player"
			end

			if combatEvent == "UNIT_DIED" then
				if 
					bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) == 0 and
					bit.band(destFlags, COMBATLOG_OBJECT_CONTROL_NPC) > 0
				then
					Character.rollLoot(destName);
				end
			end

			-- Only player themselves after this point
			if bit.band(destFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) == 0 then return end 

			
			-- These only work for healing or damage
			if not Character.takehitCD and (eventPrefix == "SPELL" or eventPrefix == "SPELL_PERIODIC") and (eventSuffix == "DAMAGE" or eventSuffix=="HEAL") then
				
				local npc = Character:new({}, sourceName);
				if u then npc = Character.buildNPC(u, sourceName) end

				local crit = arguments[21]
				if localStorage.tank_mode then crit = math.random() < globalStorage.tank_mode_perc end

				-- Todo: Add spell triggers
				damage = arguments[15]
				local harmful = true
				if eventSuffix ~= "DAMAGE" then harmful = false end

				--spellId, name, harmful, unitCaster, count, crit, char
				local trig = buildSpellTrigger(
					arguments[12], -- Spell ID
					arguments[13], --Spell Name
					harmful, 
					sourceName, 
					1,
					crit, -- Crit
					npc
				)
				SpellBinding:onTick(npc, trig)
				if harmful and eventPrefix ~= "SPELL_PERIODIC" then
					triggerWhisper(npc, trig, Condition.Types.RTYPE_SPELL_TICK)
				end

			elseif eventSuffix == "DAMAGE" and eventPrefix == "SWING" then

				local crit = ""
				if arguments[18] or (localStorage.tank_mode and math.random() < globalStorage.tank_mode_perc) then crit = "_CRIT" end

				local damage = 0	
				damage = arguments[12]

				
				local chance = globalStorage.swing_text_freq;
				if crit ~= "" then chance = chance*4 end -- Crits have 3x chance for swing text

				local npc = Character.buildNPC(u, sourceName)
				local rand = math.random()
				if not Character.takehitCD and rand < chance and u and not UnitIsPlayer(u) then

					local rp = RPText.get(eventPrefix..crit, npc, ExiWoW.ME)
					if rp then
						Character.setTakehitTimer();
						rp:convertAndReceive(npc, ExiWoW.ME)
					end

				end

				if damage <= 0 then return end
				local percentage = damage/UnitHealthMax("player");
				ExiWoW.ME:addExcitement(percentage*0.1, false, true);

				triggerWhisper(
					npc, 
					buildSpellTrigger("ATTACK", "ATTACK", true, sourceName, 1, crit, npc), 
					Condition.Types.RTYPE_MELEE
				)
				

			end
		end

		for k,v in pairs(Character.eventBindings) do

			if v.evt == event then

				local trigs = v.numTriggers -1;

				-- Remove if out of triggers
				if trigs < 1 then
					Character.eventBindings[k] = nil;
				else
					Character.eventBindings[k].numTriggers = trigs;
				end

				if type(v.fn) == "function" then
					v:fn(arguments);
				end

			end
		end

		if event == "UNIT_SPELLCAST_SENT" then
			
			local lootableSpells = {
				Fishing = true,
				Mining = true,
				Opening = true,
				["Herb Gathering"] = true,
				Archaeology = true,
				Skinning = true,
				Mining = true,
				Disenchanting = true
			}
			if lootableSpells[arguments[2]] then
				Character.lootSpell = arguments[2];
				Character.lootContainer = arguments[4];
			end
			--print(event, ...)
		end


		if event == "PLAYER_TARGET_CHANGED" then
			UI.portrait.targetHasExiWoWFrame:Hide();
			if UnitExists("target") then
				-- Query for the addon
				Action.useOnTarget("A", "target", true);
			end
		end

		if event == "PLAYER_DEAD" then
			ExiWoW.ME:addExcitement(0, true);
		end
		
		if event == "LOOT_OPENED" or event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_FAILED_QUIET" then
			if Character.lootContainer then 
				print("LootContainer = ", Character.lootContainer);
			
				print("Nr items", GetNumLootItems())
				print("Autoloot", arguments[1])
				for i=1, GetNumLootItems() do
					print("Item", i, GetLootSlotInfo(i))
				end
			end

		end

		if event == "LOOT_CLOSED" then
			print("Clearing container")
			Character.lootContainer = nil
		end

		if event == "UNIT_AURA" then

			local unit = ...;
			if unit ~= "player" then return end
			local active = {} -- spellID = {name=name, count=count}

			local function auraExists(tb, aura)
				for i,a in pairs(tb) do
					if a.spellId == aura.spellId and a.unitCaster == aura.unitCaster and a.harmful == aura.harmful then
						return true;
					end
				end
				return false
			end
			
			local function addAura(spellId, name, harmful, unitCaster, count)

				local uc = unitCaster;
				if not uc then uc = "??" else uc = UnitName(unitCaster) end

				local char = Character.buildNPC(unitCaster, uc)
				--spellId, name, harmful, unitCaster, count, crit, char
				local aura = buildSpellTrigger(spellId, name, harmful, unitCaster, count, false, char)
				table.insert(active, aura)
				if not auraExists(Character.AURAS, aura) then
					SpellBinding:onAdd(char, aura)
				end

			end

			

			-- Read all buffs
			for i=1,40 do 
				local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId = UnitAura(unit, i)
				if name == nil then break end
				addAura(spellId, name, false, unitCaster, count)
			end
			-- Read all debuffs
			for i=1,40 do 
				local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId = UnitAura(unit, i, "HARMFUL")
				if name == nil then break end
				addAura(spellId, name, true, unitCaster, count)
			end

			-- See what auras were removed
			for i,a in pairs(Character.AURAS) do
				if not auraExists(active, a) then
					SpellBinding:onRemove(a.char, a)
				end
			end

			Character.AURAS = active

		end

	end

	function Character.bind(evt, fn, numTriggers)

		Character.eventBindingIndex = Character.eventBindingIndex+1;
		table.insert(Character.eventBindings, {
			id = Character.eventBindingIndex,
			evt = evt,
			fn = fn,
			numTriggers = numTriggers or math.huge
		});

		return Character.eventBindingIndex;

	end

	function Character.unbind(id)

		for k,v in pairs(Character.eventBindings) do
			if v.id == id then
				Character.eventBindings[k] = nil;
				return
			end
		end

	end

	-- Builds an NPC from a unit
	function Character.buildNPC(u, name)

		if not name then name = "???" end
		local npc = Character:new({}, name);
		if not u then u = "???" end
		npc.type = UnitCreatureType(u) or "???";
		--npc.race = UnitRace(u);
		npc.class = UnitClass(u) or "???";

		local sex = UnitSex(u) or 0;
		if sex == 2 then npc.penis_size = 2
		elseif sex == 3 then 
			npc.breast_size = 2;
			npc.vagina_size = 0;
		end
		return npc;
	end


	function Character.setTakehitTimer()
		local rate = globalStorage.takehit_rp_rate;
		Timer.clear(Character.takehitCD);
		Character.takehitCD = Timer.set(function()
			Character.takehitCD = nil;
		end, rate)
	end

	function Character:hasAura(names)
		if type(names) ~= "table" then print("Invalid name var for aura check, type was", type(names)); return false end 
		for k,v in pairs(names) do
			if type(v) ~= "table" then
				print("Error in hasAura, value is not a table")
			else
				local name = v.name;
				local caster = v.caster;
				for _,aura in pairs(Character.AURAS) do
					if (aura.name == name or name == nil) and (aura.cname == caster or caster == nil) then
						return true
					end
				end
			end
			
		end
		return false;
	end

	-- See RPText RTYPE_HAS_INVENTORY
	function Character:hasInventory(names)
		if type(names) ~= "table" then print("Invalid name var for inventory check, type was", type(names)); return false end 

		for i=0,4 do
			local slots = GetContainerNumSlots(i);
			for slot=1,slots do
				local id = GetContainerItemID(i, slot)
				if id then
					local quant = GetItemCount(id, false);
					local name = GetItemInfo(id);
					for _,cond in pairs(names) do
						if (cond.name == name or cond.name == nil) and (cond.quant == quant or cond.quant == nil) then
							return name
						end
					end
				end
			end
		end
		return false;
	end



	-- Removes an equipped item and puts it into inventory if possible
	function Character:removeEquipped( slot )

		for i=0,4 do
			local free = GetContainerNumFreeSlots(i);
			if free > 0 then
				PickupInventoryItem(slot)
				if i == 0 then 
					PutItemInBackpack() 
				else
					PutItemInBag(19+i)	
				end
				break
			end
		end

	end




	-- Forage
	function Character.forage()
		
		if Character.rollLoot("_FORAGE_") then return true end

		PlaySound(1142, "Dialog")
		RPText.print("You found nothing");

		return false

	end

	function Character.rollLoot(npc)
		
		local topzone = GetRealZoneText()
		local subzone = GetSubZoneText()
	

		local function isCloseToPoints(points)
			SetMapToCurrentZone()
			local px,py = GetPlayerMapPosition("player")
			px = px*100
			py = py*100
			for _,v in pairs(points) do
				local x = v.x
				local y = v.y
				local radius = v.rad
				local dist = math.sqrt((px-x)*(px-x)+(py-y)*(py-y))
				if dist <= radius then return true end
			end
			return false
		end

		local available = {}

		for _,item in pairs(ExiWoW.LibAssets.loot) do
			
			local add = true
			if 
				not Tools.multiSearch(topzone, item.zone) or
				not Tools.multiSearch(subzone, item.sub) or
				not Tools.multiSearch(npc, item.name)
			then add = false end

			if add and type(item.points) == "table" then
				add = isCloseToPoints(item.points);
				print("B", item.items[1].id, add);
			end

			if add then
				for _,it in pairs(item.items) do
					table.insert(available, it)
				end
			end

		end

		local size = #available
		for i = size, 1, -1 do
			local rand = math.random(size)
			available[i], available[rand] = available[rand], available[i]
		end

		for _,v in ipairs(available) do

			local chance = 1
			if v.chance then chance = v.chance end

			if math.random() < v.chance then 
				
				local quant = v.quant;
				if not quant or quant < 1 then quant = 1 end
				if type(v.quantRand) == "number" and v.quantRand > 0 then
					quant = quant+math.random(v.quantRand+1)-1;
				end
				local item = ExiWoW.ME:addItem(v.type, v.id, quant);
				if item then
					if v.text then 
						v.text.item = item.name;
						v.text:convertAndReceive(ExiWoW.ME, Character.buildNPC(u, npc), false, nil, function(text)
							
							text = string.gsub(text, "%%Qs", quant ~= 1 and "s" or "")
							text = string.gsub(text, "%%Q", quant)
							return text
						end);
					end
					if v.sound then PlaySound(v.sound, "Dialog") end
					return v;
				end

			end
		end

		return false

	end









		-- Class declaration --
	function Character:new(settings, name)
		local self = {}
		setmetatable(self, Character); 
		if type(settings) ~= "table" then
			settings = {}
		end
		
		local getVar = function(v, def)
			if v == nil then return def end
			return v
		end

		-- Visuals
		self.capFlashTimer = 0			-- Timer event of excitement cap
		self.capFlashPow = 0
		self.portraitBorder = false;
		self.portraitResting = false;
		self.restingTimer = 0;
		self.restingPow = 0;

		-- Stats & Conf
		self.name = name;					-- Nil for player self
		self.excitement = settings.ex or 0;
		self.hasControl = true;
		self.meditating = false;			-- Losing excitement 
		self.masochism = 0.25;
		
		-- Inventory
		self.underwear_ids = {{id="DEFAULT",fav=false}};			-- Unlocked underwear
		self.underwear_worn = "DEFAULT";
		
		-- These are automatically set on export if full is set.
		-- They still need to be fetched from settings though when received by a unit for an RP text
		self.class = settings.cl or UnitClass("player");
		self.race = settings.ra or UnitRace("player");
		
		-- These are not sent on export, but can be used locally for NPC events
		self.type = "player";				-- Can be overridden like humanoid etc. 
		
		-- 

		-- Importable properties
		-- Use Character:getnSize
		-- If all these are false, size will be set to 2 for penis/breasts, 0 for vagina. Base on character sex in WoW 
		self.penis_size = getVar(settings.ps, false);				-- False or range between 0 and 4
		self.vagina_size = getVar(settings.vs, false);				-- False or 0
		self.breast_size = getVar(settings.ts, false);				-- False or range between 0 and 4
		self.butt_size = getVar(settings.bs, 2);						-- Always a number
		self.underwear = false										-- This is a cache of underwear only set when received from another player via an action

		self.intelligence = getVar(settings.int, 5);
		self.muscle_tone = getVar(settings.str, 5);
		self.fat = getVar(settings.fat, 5);
		self.wisdom = getVar(settings.wis, 5);
		

		if settings.uw then self.underwear = Underwear.import(settings.uw) end


		-- Feature tests
		--self:addExcitement(1.1);

		return self
	end

	-- Exporting
	function Character:export(full)

		local underwear = Underwear.get(self.underwear_worn)
		if underwear then underwear = underwear:export() end
		local out = {
			ex = self.excitement,
			ps = self.penis_size,
			vs = self.vagina_size,
			ts = self.breast_size,
			bs = self.butt_size,
			uw = underwear,
			fat = self.fat,
			int = self.intelligence,
			str = self.muscle_tone,
			wis = self.wisdom
		};
		-- Should only be used for "player"
		if full then
			out.cl = UnitClass("player");
			out.ra = UnitRace("player");
		end
		return out;
	end


	-- Gets a clamped excitement value
	function Character:getExcitementPerc()
		return max(min(self.excitement,1),0);
	end

	-- Underwear --
	-- Returns an underwear object
	function Character:getUnderwear()
		-- Received from other players
		if self.underwear then return self.underwear end
		return Underwear.get(self.underwear_worn);
	end

	function Character:useUnderwear(id)
		local uw = Underwear.get(id)
		if self.underwear_worn == id then
			self.underwear_worn = false
			if uw then 
				PlaySound(uw.unequip_sound, "Dialog")
				RPText.print("You take off your "..uw.name)
				uw:onUnequip();
				Event.raise(ACTION_UNDERWEAR_UNEQUIP, {id=id})
			end
		elseif self:ownsUnderwear(id) and uw then
			local cur = Underwear.get(self.underwear_worn)
			if cur then cur:onUnequip(); end
			self.underwear_worn = id
			PlaySound(uw.equip_sound, "Dialog")
			uw:onEquip();
			RPText.print("You put on your "..uw.name)
			Event.raise(ACTION_UNDERWEAR_EQUIP, {id=id})
		else return false
		end
		UI.underwearPage.update();
		return true
	end

	function Character:ownsUnderwear(id)
		for _,u in pairs(self.underwear_ids) do
			if id == u.id then return true end
		end
		return false
	end

	function Character:removeUnderwear(id)
		for k,u in pairs(self.underwear_ids) do
			if id == u.id then 
				self.underwear_ids[k] = nil
				print("Underwear removed")
				return true
			end
		end
		return false
	end

	-- Items --
	-- /run UI.drawLoot("Test", "inv_pants_leather_04")
	function Character:addItem(type, name, quant)

		if not quant then quant = 1 end
		if type == "Underwear" then
			if self:ownsUnderwear(name) then return false end
			local exists = Underwear.get(name)
			if not exists then return false end
			table.insert(self.underwear_ids, {id=name, fav=false})
			UI.underwearPage.update();
			UI.drawLoot(exists.name, exists.icon, exists.rarity)
			Event.raise(Event.Types.INVADD, {type=type, name=name, quant=quant})
			return exists;
		elseif type == "Charges" then
			local action = Action.get(name)
			if not action then return false end
			if action.charges >= action.max_charges or action.charges == math.huge then return false end
			if not action:consumeCharges(-quant) then return false end
			Event.raise(Event.Types.INVADD, {type=type, name=name, quant=quant})
			UI.drawLoot(action.name, action.texture, action.rarity)
			return action
		end

	end

	-- Stats
	function Character:getStat(unit, stat)
		local statlist = {Strength=1, Agility=2, Stamina=3, Intellect=4}
		if not UnitExists(unit) then return 0 end
		if not statlist[stat] then return 0 end

		local am = 0.5;
		if self.fat > 5 then
			am = 0.5-(self.fat-5)/10;
		end
		local multipliers = {
			Strength=(self.muscle_tone/10)+0.5, 
			Intelligence=(self.intelligence/10)+0.5, 
			Agility=am+0.5, 
		}
		local multi = 1;
		if multipliers[stat] then multi = multipliers[stat] end
		local base, stat, posBuff, negBuff = UnitStat(unit, statlist[stat]);
		local out = math.floor((base-posBuff)*multi);

		print("Base", out)

	end

	-- Raised when you max or drop off max excitement --
	function Character:onCapChange()

		local maxed = self.excitement >= 1

		Timer.clear(self.capFlashTimer);
		local se = self
		if maxed then
			self.capFlashTimer = Timer.set(function()
				se.capFlashPow = se.capFlashPow+0.25;
				if se.capFlashPow >= 2 then se.capFlashPow = 0 end
				local green = -0.5 * (math.cos(math.pi * se.capFlashPow) - 1)
				UI.portrait.border:SetVertexColor(1,0.5+green*0.5,1);
			end, 0.05, math.huge);
		else
			UI.portrait.border:SetVertexColor(1,1,1);
		end

	end

	function Character:addExcitement(amount, set, multiplyMasochism)

		local pre = self.excitement >= 1

		if multiplyMasochism then amount = amount*self.masochism end
		
		if not set then
			self.excitement = self.excitement+tonumber(amount);
		else
			self.excitement = tonumber(amount);
		end

		Event.raise(Event.Types.EXADD, {amount=amount, set=set, multiplyMasochism=multiplyMasochism})

		self.excitement =max(min(self.excitement, Character.EXCITEMENT_MAX), 0);
		self:updateExcitementDisplay();

		if (self.excitement >= 1) ~= pre then
			self:onCapChange()
		end

	end

	function Character:toggleResting(on)

		Timer.clear(self.restingTimer);
		local se = self
		if on then
			se.restingPow = 0
			self.restingTimer = Timer.set(function()
				se.restingPow = se.restingPow+0.1;
				local opacity = -0.5 * (math.cos(math.pi * se.restingPow) - 1)
				UI.portrait.resting:SetAlpha(0.5+opacity*0.5);
			end, 0.05, math.huge);
		else
			UI.portrait.resting:SetAlpha(0);
		end

	end

	function Character:updateExcitementDisplay()

		UI.portrait.portraitExcitementBar:SetHeight(UI.portrait.FRAME_HEIGHT*max(self:getExcitementPerc(), 0.00001));

	end



	function Character:isGenderless()
		if self.penis_size == false and self.vagina_size == false and self.type == "player" then
			return true
		end
		return false; 
	end

	function Character:getPenisSize()
		
		if self:isGenderless() then
			if UnitSex("player") == 2 
			then return 2
			else return false end
		end

		return self.penis_size

	end

	function Character:getBreastSize()
		
		if self:isGenderless() and not self.breast_size then
			if UnitSex("player") == 3
			then return 2
			else return false end
		end

		return self.breast_size

	end

	function Character:getVaginaSize()
		
		if self:isGenderless() then
			if UnitSex("player") == 3
			then return 0
			else return false end
		end

		return self.vagina_size

	end

	function Character:getButtSize()
		
		if type(self.butt_size) ~= "number" then
			return 2
		end

		return self.butt_size

	end

	-- Returns an Ambiguate name
	function Character:getName()
		if self.name == nil then
			return Ambiguate(UnitName("player"), "all") 
		end
		return Ambiguate(self.name, "all");
	end

	function Character:isMale()
		return self:getPenisSize() ~= false and self:getBreastSize() == false and self:getVaginaSize() == false
	end

	function Character:isFemale()
		return self:getPenisSize() == false and self:getBreastSize() ~= false and self:getVaginaSize() ~= false
	end

export(
	"Character", 
	Character,
	{
		getTakehitCD = Character.getTakehitCD,
		getWhisperCD = Character.getWhisperCD
	},
	Character
)