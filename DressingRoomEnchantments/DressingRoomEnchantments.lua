----------------------------------------------------------------------------------------------------
-- weapon information
----------------------------------------------------------------------------------------------------
local mainHandLink        = nil   -- the unchanged item link of the currently displayed main hand weapon
local offHandLink         = nil   -- the unchanged item link of the currently displayed off hand weapon
local changedMainHandLink = nil   -- the changed item link of the currently displayed main hand weapon
local changedOffHandLink  = nil   -- the changed item link of the currently displayed off hand weapon
local wearingTwoHanded    = nil   -- if the weapon is two-handed
local sendingEnchantment  = false -- if the next item sent to the dressing room is from an enchantment change

----------------------------------------------------------------------------------------------------
-- enchantment information
----------------------------------------------------------------------------------------------------
-- key: enchant ID seen on items. value: enchantment skill ID to be able to link it
-- some item IDs are used by multiple skills, so those are put in a list
local enchantmentRecipeId = {
	[2564] = 23800, -- Agility (+15 Agility)
	[2675] = 28004, -- Battlemaster
	[1900] = 20034, -- Crusader
	[3273] = 46578, -- Deathfrost
	[912]  = 13915, -- Demonslaying
	[3225] = 42974, -- Executioner
	[803]  = 13898, -- Fiery Weapon
	[3222] = 42620, -- Greater Agility (+20 agility)
	[805]  = 13943, -- Greater Striking (+4 Weapon Damage)
	[2505] = 22750, -- Healing Power (+55 healing Spells and +19 Damage Spells)
	[1894] = 20029, -- Icy Chill (Icy Weapon)
	[853]  = 13653, -- Lesser Beastslayer (+6 Beastslaying)
	[854]  = 13655, -- Lesser Elemental Slayer (+6 Elemental Slayer)
	[241]  = {13503, 7745}, -- Lesser Striking (+2 Weapon Damage) or 2H: Minor Impact (+2 Weapon Damage)
	[1898] = 20032, -- Lifestealing
	[2343] = 34010, -- Major Healing (+81 Healing Spells and +27 Damage Spells)
	[2666] = 27968, -- Major Intellect (+30 Intellect)
	[2669] = 27975, -- Major Spellpower (+40 Spell Damage)
	[963]  = {27967, 13937}, -- Major Striking (+7 Weapon Damage) or 2H: Greater Impact (+7 Weapon Damage)
	[2568] = 23804, -- Mighty Intellect (+22 Intellect)
	[2567] = 23803, -- Mighty Spirit (+20 Spirit)
	[249]  = 7786, -- Minor Beastslayer (+2 Beastslaying)
	[250]  = 7788, -- Minor Striking (+1 Weapon Damage)
	[2673] = 27984, -- Mongoose
	[2668] = 27972, -- Potency (+20 Strength)
	[2672] = 27982, -- Soulfrost
	[2504] = 22749, -- Spell Power (+30 Spell Damage)
	[2674] = 28003, -- Spellsurge
	[2563] = 23799, -- Strength (+15 Strength)
	[943]  = {13693, 13529}, -- Striking (+3 Weapon Damage) or 2H: Lesser Impact (+3 Weapon Damage)
	[2671] = 27981, -- Sunfire
	[1897] = {20031, 13695}, -- Superior Striking (+5 Weapon Damage) or 2H: Impact (+5 Weapon Damage)
	[1899] = 20033, -- Unholy Weapon
	[2443] = 21931, -- Winter's Might (+7 Frost Spell Damage)
	-- 2H below
	[2646] = 27837, -- Agility (+25 Agility)
	[723]  = 7793, -- Lesser Intellect (+3 Intellect)
	[255]  = 13380, -- Lesser Spirit (+3 Spirit)
	[2670] = 27977, -- Major Agility
	[1901] = 20036, -- Major Intellect (+9 Intellect)
	[1903] = 20035, -- Major Spirit (+9 Spirit)
	[2667] = 27971, -- Savagery
	[1896] = 20030, -- Superior Impact (+9 Weapon Damage)
}

----------------------------------------------------------------------------------------------------
-- create the menu
----------------------------------------------------------------------------------------------------
local menuFrame      = CreateFrame("Frame", "DressingRoomEnchantmentsMenu", UIParent, "UIDropDownMenuTemplate")
local handMenuOpened = nil -- which button was clicked: 1 for main hand, 2 for off hand
local menuCheckId    = nil -- the enchantment ID of the selected weapen - for using menu checkmarks

--------------------------------------------------
-- called when a menu item is selected
-- changes enchantment and sends it to the dressing room
--------------------------------------------------
local function SetEnchantment(enchantment_id)
	if not enchantment_id or not handMenuOpened then return end

	local new_link = handMenuOpened == 1 and mainHandLink or offHandLink
	local link_copy = new_link

	if not new_link then
		return
	end

	-- replace the enchantment and send it to the dressing room
	new_link = new_link:gsub("(%d+):([%d-]+)", "%1:"..enchantment_id, 1)
	menuCheckId = enchantment_id
	sendingEnchantment = true -- so that the menu won't be closed
	DressUpItemLink(new_link)
	-- DressUpItemLink will cause the links to change, so fix them now
	if handMenuOpened == 1 then
		changedMainHandLink = mainHandLink
		mainHandLink = link_copy
	else
		changedOffHandLink = offHandLink
		offHandLink = link_copy
	end

	-- show a checkbox for the proper enchantment on the menu
	if enchantment_id == 0 then
		_G["DropDownList1Button2Check"]:Show()
	else
		_G["DropDownList1Button2Check"]:Hide()

		--figure out if it's the 2nd or 3rd submenu
		local submenu = 2
		if _G["DropDownList3"] and _G["DropDownList3"].numButtons > 0 then
			submenu = 3
		end

		local checkbox
		local id
		for i=1,_G["DropDownList"..submenu].numButtons do
			checkbox = _G["DropDownList"..submenu.."Button"..i.."Check"]
			if checkbox then
				id = _G["DropDownList"..submenu.."Button"..i].arg1
				if id == enchantment_id then
					checkbox:Show()
				else
					checkbox:Hide()
				end
			end
		end
	end
end

--------------------------------------------------
-- called from the menu - prints a weapon link
--------------------------------------------------
local function PrintWeaponLink()
	if handMenuOpened == 1 then
		DEFAULT_CHAT_FRAME:AddMessage(changedMainHandLink or "No main hand weapon exists to link!")
	elseif handMenuOpened == 2 then
		DEFAULT_CHAT_FRAME:AddMessage(changedOffHandLink or "No off hand weapon exists to link!")
	end
end

--------------------------------------------------
-- called from the menu - prints an enchantment link
--------------------------------------------------
local function PrintEnchantmentLink()
	local link       = nil -- the weapon link
	local enchant_id = nil -- the enchantment ID on item links

	if handMenuOpened == 1 then
		link = changedMainHandLink
	elseif handMenuOpened == 2 then
		link = changedOffHandLink
	end

	if link then
		enchant_id = tonumber(link:match("%d+:(%d+):"))
		if enchant_id then
			local skill_id = enchantmentRecipeId[enchant_id]
			if skill_id then
				if type(skill_id) == "table" then
					-- it could be multiple enchantments, so list them all
					local list = ""
					for i=1,#skill_id do
						list = string.format("%s%s|cffffd000|Henchant:%d|h[%s]|h|r", list, (i == 1 and "" or " or "), skill_id[i], GetSpellInfo(skill_id[i]))
					end
					DEFAULT_CHAT_FRAME:AddMessage(list)
				else
					DEFAULT_CHAT_FRAME:AddMessage(string.format("|cffffd000|Henchant:%d|h[%s]|h|r", skill_id, GetSpellInfo(skill_id)))
				end
				return
			end
		end
	end
	DEFAULT_CHAT_FRAME:AddMessage("No enchantment was found to link!")
end

--------------------------------------------------
-- check if each menu item should have a checkmark
--------------------------------------------------
local function TestCheckmark(enchantment_id)
	return (enchantment_id == menuCheckId)
end

--------------------------------------------------
-- menu of enchantments - commented out enchantments don't have a glow effect
--------------------------------------------------
-- separated the menu items from the menu below so that it's easy to use them multiple times throughout it
local enchantmentMenuItem = {
	["Agility"]                 = {text="Agility (+15 Agility)",                  func=SetEnchantment, keepShownOnClick=1, arg1=2564, checked=function() return TestCheckmark(2564) end},
	["Battlemaster"]            = {text="Battlemaster",                           func=SetEnchantment, keepShownOnClick=1, arg1=2675, checked=function() return TestCheckmark(2675) end},
	["Crusader"]                = {text="Crusader",                               func=SetEnchantment, keepShownOnClick=1, arg1=1900, checked=function() return TestCheckmark(1900) end},
	["Deathfrost"]              = {text="Deathfrost",                             func=SetEnchantment, keepShownOnClick=1, arg1=3273, checked=function() return TestCheckmark(3273) end},
	["Demonslaying"]            = {text="Demonslaying",                           func=SetEnchantment, keepShownOnClick=1, arg1=912,  checked=function() return TestCheckmark(912) end},
	["Executioner"]             = {text="Executioner",                            func=SetEnchantment, keepShownOnClick=1, arg1=3225, checked=function() return TestCheckmark(3225) end},
	["Fiery Weapon"]            = {text="Fiery Weapon",                           func=SetEnchantment, keepShownOnClick=1, arg1=803,  checked=function() return TestCheckmark(803) end},
	["Greater Agility"]         = {text="Greater Agility (+20 agility)",          func=SetEnchantment, keepShownOnClick=1, arg1=3222, checked=function() return TestCheckmark(3222) end},
	["Greater Striking"]        = {text="Greater Striking (+4 Weapon Damage)",    func=SetEnchantment, keepShownOnClick=1, arg1=805,  checked=function() return TestCheckmark(805) end},
	["Healing Power"]           = {text="Healing Power (+55 healing Spells and +19 Damage Spells)", func=SetEnchantment, keepShownOnClick=1, arg1=2505, checked=function() return TestCheckmark(2505) end},
	["Icy Chill"]               = {text="Icy Chill (Icy Weapon)",                 func=SetEnchantment, keepShownOnClick=1, arg1=1894, checked=function() return TestCheckmark(1894) end},
	["Lesser Beastslayer"]      = {text="Lesser Beastslayer (+6 Beastslaying)",   func=SetEnchantment, keepShownOnClick=1, arg1=853,  checked=function() return TestCheckmark(853) end},
	["Lesser Elemental Slayer"] = {text="Lesser Elemental Slayer (+6 Elemental Slayer)", func=SetEnchantment, keepShownOnClick=1, arg1=854, checked=function() return TestCheckmark(854) end},
	-- ["LesserStriking"]       = {text="Lesser Striking (+2 Weapon Damage)",     func=SetEnchantment, keepShownOnClick=1, arg1=241,  checked=function() return TestCheckmark(241) end},
	["Lifestealing"]            = {text="Lifestealing",                           func=SetEnchantment, keepShownOnClick=1, arg1=1898, checked=function() return TestCheckmark(1898) end},
	["Major Healing"]           = {text="Major Healing (+81 Healing Spells and +27 Damage Spells)", func=SetEnchantment, keepShownOnClick=1, arg1=2343, checked=function() return TestCheckmark(2343) end},
	["Major Intellect"]         = {text="Major Intellect (+30 Intellect)",        func=SetEnchantment, keepShownOnClick=1, arg1=2666, checked=function() return TestCheckmark(2666) end},
	["Major Spellpower"]        = {text="Major Spellpower (+40 Spell Damage)",    func=SetEnchantment, keepShownOnClick=1, arg1=2669, checked=function() return TestCheckmark(2669) end},
	["Major Striking"]          = {text="Major Striking (+7 Weapon Damage)",      func=SetEnchantment, keepShownOnClick=1, arg1=963,  checked=function() return TestCheckmark(963) end},
	["Mighty Intellect"]        = {text="Mighty Intellect (+22 Intellect)",       func=SetEnchantment, keepShownOnClick=1, arg1=2568, checked=function() return TestCheckmark(2568) end},
	["Mighty Spirit"]           = {text="Mighty Spirit (+20 Spirit)",             func=SetEnchantment, keepShownOnClick=1, arg1=2567, checked=function() return TestCheckmark(2567) end},
	["Minor Beastslayer"]       = {text="Minor Beastslayer (+2 Beastslaying)",    func=SetEnchantment, keepShownOnClick=1, arg1=249,  checked=function() return TestCheckmark(249) end},
	-- ["Minor Striking"]       = {text="Minor Striking (+1 Weapon Damage)",      func=SetEnchantment, keepShownOnClick=1, arg1=250,  checked=function() return TestCheckmark(250) end},
	["Mongoose"]                = {text="Mongoose",                               func=SetEnchantment, keepShownOnClick=1, arg1=2673, checked=function() return TestCheckmark(2673) end},
	["Potency"]                 = {text="Potency (+20 Strength)",                 func=SetEnchantment, keepShownOnClick=1, arg1=2668, checked=function() return TestCheckmark(2668) end},
	["Soulfrost"]               = {text="Soulfrost",                              func=SetEnchantment, keepShownOnClick=1, arg1=2672, checked=function() return TestCheckmark(2672) end},
	["Spell Power"]             = {text="Spell Power (+30 Spell Damage)",         func=SetEnchantment, keepShownOnClick=1, arg1=2504, checked=function() return TestCheckmark(2504) end},
	["Spellsurge"]              = {text="Spellsurge",                             func=SetEnchantment, keepShownOnClick=1, arg1=2674, checked=function() return TestCheckmark(2674) end},
	["Strength"]                = {text="Strength (+15 Strength)",                func=SetEnchantment, keepShownOnClick=1, arg1=2563, checked=function() return TestCheckmark(2563) end},
	["Striking"]                = {text="Striking (+3 Weapon Damage)",            func=SetEnchantment, keepShownOnClick=1, arg1=943,  checked=function() return TestCheckmark(943) end},
	["Sunfire"]                 = {text="Sunfire",                                func=SetEnchantment, keepShownOnClick=1, arg1=2671, checked=function() return TestCheckmark(2671) end},
	["Superior Striking"]       = {text="Superior Striking (+5 Weapon Damage)",   func=SetEnchantment, keepShownOnClick=1, arg1=1897, checked=function() return TestCheckmark(1897) end},
	["Unholy Weapon"]           = {text="Unholy Weapon",                          func=SetEnchantment, keepShownOnClick=1, arg1=1899, checked=function() return TestCheckmark(1899) end},
	-- ["Winter's Might"]       = {text="Winter's Might (+7 Frost Spell Damage)", func=SetEnchantment, keepShownOnClick=1, arg1=2443, checked=function() return TestCheckmark(2443) end},
	["2H Agility"]              = {text="2H: Agility (+25 Agility)",              func=SetEnchantment, keepShownOnClick=1, arg1=2646, checked=function() return TestCheckmark(2646) end},
	["2H Greater Impact"]       = {text="2H: Greater Impact (+7 Weapon Damage)",  func=SetEnchantment, keepShownOnClick=1, arg1=963,  checked=function() return TestCheckmark(963) end},
	["2H Impact"]               = {text="2H: Impact (+5 Weapon Damage)",          func=SetEnchantment, keepShownOnClick=1, arg1=1897, checked=function() return TestCheckmark(1897) end},
	["2H Lesser Impact"]        = {text="2H: Lesser Impact (+3 Weapon Damage)",   func=SetEnchantment, keepShownOnClick=1, arg1=943,  checked=function() return TestCheckmark(943) end},
	-- ["2H Lesser Intellect"]  = {text="2H: Lesser Intellect (+3 Intellect)",    func=SetEnchantment, keepShownOnClick=1, arg1=723,  checked=function() return TestCheckmark(723) end},
	-- ["2H Lesser Spirit"]     = {text="2H: Lesser Spirit (+3 Spirit)",          func=SetEnchantment, keepShownOnClick=1, arg1=255,  checked=function() return TestCheckmark(255) end},
	["2H Major Agility"]        = {text="2H: Major Agility",                      func=SetEnchantment, keepShownOnClick=1, arg1=2670, checked=function() return TestCheckmark(2670) end},
	["2H Major Intellect"]      = {text="2H: Major Intellect (+9 Intellect)",     func=SetEnchantment, keepShownOnClick=1, arg1=1901, checked=function() return TestCheckmark(1901) end},
	["2H Major Spirit"]         = {text="2H: Major Spirit (+9 Spirit)",           func=SetEnchantment, keepShownOnClick=1, arg1=1903, checked=function() return TestCheckmark(1903) end},
	-- ["2H Minor Impact"]      = {text="2H: Minor Impact (+2 Weapon Damage)",    func=SetEnchantment, keepShownOnClick=1, arg1=241,  checked=function() return TestCheckmark(241) end},
	["2H Savagery"]             = {text="2H: Savagery",                           func=SetEnchantment, keepShownOnClick=1, arg1=2667, checked=function() return TestCheckmark(2667) end},
	["2H Superior Impact"]      = {text="2H: Superior Impact (+9 Weapon Damage)", func=SetEnchantment, keepShownOnClick=1, arg1=1896, checked=function() return TestCheckmark(1896) end},
}

-- the menu
local enchantmentMenu = {
	{notCheckable=1, text="", isTitle=true}, -- title text is set when the menu opens
	{text="None", func=SetEnchantment, keepShownOnClick=1, arg1=0, checked=function() return TestCheckmark(0) end},
	{notCheckable=1, text="1 Hand", hasArrow=true, notClickable=true, menuList={
		enchantmentMenuItem["Agility"],
		enchantmentMenuItem["Battlemaster"],
		enchantmentMenuItem["Crusader"],
		enchantmentMenuItem["Deathfrost"],
		enchantmentMenuItem["Demonslaying"],
		enchantmentMenuItem["Executioner"],
		enchantmentMenuItem["Fiery Weapon"],
		enchantmentMenuItem["Greater Agility"],
		enchantmentMenuItem["Greater Striking"],
		enchantmentMenuItem["Healing Power"],
		enchantmentMenuItem["Icy Chill"],
		enchantmentMenuItem["Lesser Beastslayer"],
		enchantmentMenuItem["Lesser Elemental Slayer"],
		-- enchantmentMenuItem["Lesser Striking"],
		enchantmentMenuItem["Lifestealing"],
		enchantmentMenuItem["Major Healing"],
		enchantmentMenuItem["Major Intellect"],
		enchantmentMenuItem["Major Spellpower"],
		enchantmentMenuItem["Major Striking"],
		enchantmentMenuItem["Mighty Intellect"],
		enchantmentMenuItem["Mighty Spirit"],
		enchantmentMenuItem["Minor Beastslayer"],
		-- enchantmentMenuItem["MinorS triking"],
		enchantmentMenuItem["Mongoose"],
		enchantmentMenuItem["Potency"],
		enchantmentMenuItem["Soulfrost"],
		enchantmentMenuItem["Spell Power"],
		enchantmentMenuItem["Spellsurge"],
		enchantmentMenuItem["Strength"],
		enchantmentMenuItem["Striking"],
		enchantmentMenuItem["Sunfire"],
		enchantmentMenuItem["Superior Striking"],
		enchantmentMenuItem["Unholy Weapon"],
		-- enchantmentMenuItem["Winter's Might"],
	}},
	{notCheckable=1, text="2 Hand", hasArrow=true, notClickable=true, menuList={
		enchantmentMenuItem["2H Agility"],
		enchantmentMenuItem["2H Greater Impact"],
		enchantmentMenuItem["2H Impact"],
		-- enchantmentMenuItem["2H Lesser Impact"],
		-- enchantmentMenuItem["2H Lesser Intellect"],
		-- enchantmentMenuItem["2H Lesser Spirit"],
		enchantmentMenuItem["2H Major Agility"],
		enchantmentMenuItem["2H Major Intellect"],
		enchantmentMenuItem["2H Major Spirit"],
		-- enchantmentMenuItem["2H Minor Impact"],
		enchantmentMenuItem["2H Savagery"],
		enchantmentMenuItem["2H Superior Impact"],
	}},
	{notCheckable=1, text="Glow Type", hasArrow=true, notClickable=true, menuList={
		{notCheckable=1, text="Blood", hasArrow=true, notClickable=true, menuList={
			enchantmentMenuItem["2H Savagery"],
		}},
		{notCheckable=1, text="Blue", hasArrow=true, notClickable=true, menuList={
			enchantmentMenuItem["Major Intellect"],
			enchantmentMenuItem["Striking"],
			enchantmentMenuItem["Greater Striking"],
			enchantmentMenuItem["Superior Striking"],
			enchantmentMenuItem["Major Striking"],
			enchantmentMenuItem["2H Lesser Impact"],
			enchantmentMenuItem["2H Impact"],
			enchantmentMenuItem["2H Greater Impact"],
			enchantmentMenuItem["2H Superior Impact"],
		}},
		{notCheckable=1, text="Fireball", hasArrow=true, notClickable=true, menuList={
			enchantmentMenuItem["Sunfire"],
		}},
		{notCheckable=1, text="Flames", hasArrow=true, notClickable=true, menuList={
			enchantmentMenuItem["Demonslaying"],
			enchantmentMenuItem["Fiery Weapon"],
		}},
		{notCheckable=1, text="Foggy", hasArrow=true, notClickable=true, menuList={
			enchantmentMenuItem["Battlemaster"],
			enchantmentMenuItem["Major Spellpower"],
		}},
		{notCheckable=1, text="Frosty", hasArrow=true, notClickable=true, menuList={
			enchantmentMenuItem["Deathfrost"],
		}},
		{notCheckable=1, text="Gray", hasArrow=true, notClickable=true, menuList={
			enchantmentMenuItem["Crusader"],
			enchantmentMenuItem["Healing Power"],
		}},
		{notCheckable=1, text="Green", hasArrow=true, notClickable=true, menuList={
			enchantmentMenuItem["Agility"],
			enchantmentMenuItem["Strength"],
			enchantmentMenuItem["Potency"],
			enchantmentMenuItem["Greater Agility"],
			enchantmentMenuItem["2H Agility"],
			enchantmentMenuItem["2H Major Agility"],
		}},
		{notCheckable=1, text="Lightning", hasArrow=true, notClickable=true, menuList={
			enchantmentMenuItem["Mongoose"],
		}},
		{notCheckable=1, text="Purple", hasArrow=true, notClickable=true, menuList={
			enchantmentMenuItem["Lifestealing"],
			enchantmentMenuItem["Spellpower"],
		}},
		{notCheckable=1, text="Red", hasArrow=true, notClickable=true, menuList={
			enchantmentMenuItem["Minor Beastslayer"],
			enchantmentMenuItem["Lesser Beastslayer"],
			enchantmentMenuItem["Lesser Elemental Slayer"],
		}},
		{notCheckable=1, text="Shadowy", hasArrow=true, notClickable=true, menuList={
			enchantmentMenuItem["Soulfrost"],
		}},
		{notCheckable=1, text="Shattering", hasArrow=true, notClickable=true, menuList={
			enchantmentMenuItem["Executioner"],
		}},
		{notCheckable=1, text="Skulls", hasArrow=true, notClickable=true, menuList={
			enchantmentMenuItem["Unholy Weapon"],
		}},
		{notCheckable=1, text="Sparkles", hasArrow=true, notClickable=true, menuList={
			enchantmentMenuItem["Spellsurge"],
		}},
		{notCheckable=1, text="White", hasArrow=true, notClickable=true, menuList={
			enchantmentMenuItem["Icy Chill"],
		}},
		{notCheckable=1, text="Yellow", hasArrow=true, notClickable=true, menuList={
			enchantmentMenuItem["Major Healing"],
			enchantmentMenuItem["Mighty Intellect"],
			enchantmentMenuItem["Mighty Spirit"],
			enchantmentMenuItem["2H Major Intellect"],
			enchantmentMenuItem["2H Major Spirit"],
		}},
	}},
	{notCheckable=1, text="Show Weapon Link",      func=PrintWeaponLink},
	{notCheckable=1, text="Show Enchantment Link", func=PrintEnchantmentLink},
	{notCheckable=1, text="Close"},
}

--------------------------------------------------
-- called when clicking the enchantment buttons to open the menu
-- hand_number is 1 for main hand and 2 for off hand
--------------------------------------------------
local function OpenMenu(button, menu, hand_number)
	CloseDropDownMenus()
	handMenuOpened = hand_number
	if hand_number == 1 then
		enchantmentMenu[1].text = "Main Hand"
		menuCheckId = tonumber(changedMainHandLink:match("%d+:(%d+):"))
	else
		enchantmentMenu[1].text = "Off Hand"
		menuCheckId = tonumber(changedOffHandLink:match("%d+:(%d+):"))
	end
	menuFrame:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT")
	EasyMenu(menu, menuFrame, button, 0, 0, "MENU")
end

----------------------------------------------------------------------------------------------------
-- create the buttons for the dressing room
----------------------------------------------------------------------------------------------------
-- move Reset and Close button to the left side - the Reset button is linked to the Close one
DressUpFrameCancelButton:SetPoint("CENTER", DressUpFrame, "TOPLEFT", 135, -421)

-- The main hand/off hand buttons try to cover up the black space uncovered when moving the Reset/Close buttons
-- main hand button
local buttonMainHand = CreateFrame("Button", "DressingRoomEnchantmentsButtonMainHand", DressUpFrame, "UIPanelButtonTemplate")
buttonMainHand:SetWidth(40)
buttonMainHand:SetHeight(22)
buttonMainHand:SetPoint("CENTER", DressUpFrame, "TOPLEFT", 282, -421)
_G[buttonMainHand:GetName().."Text"]:SetText("MH")
buttonMainHand:SetScript("OnClick", function() OpenMenu(this, enchantmentMenu, 1) end)

-- off hand button
local buttonOffHand = CreateFrame("Button", "DressingRoomEnchantmentsButtonOffHand", DressUpFrame, "UIPanelButtonTemplate")
buttonOffHand:SetWidth(40)
buttonOffHand:SetHeight(22)
buttonOffHand:SetPoint("CENTER", DressUpFrame, "TOPLEFT", 321, -421)
_G[buttonOffHand:GetName().."Text"]:SetText("OH")
buttonOffHand:SetScript("OnClick", function() OpenMenu(this, enchantmentMenu, 2) end)

----------------------------------------------------------------------------------------------------
-- set hooks to know what's going on in the dressing room
----------------------------------------------------------------------------------------------------
----------------------------------------
-- helper function to return if a subtype of a weapon type is used by both hands
----------------------------------------
local function IsSubtypeTwoHanded(subtype)
	return (subtype == "Two-Handed Swords" or subtype == "Two-Handed Maces" or subtype == "Two-Handed Axes"
		or subtype == "Staves"  or subtype == "Polearms")
end

--------------------------------------------------
-- helper function to set up the default weapons
--------------------------------------------------
local function SetDefaultWeapons()
	-- set worn weapons as the current weapons
	mainHandLink = nil
	offHandLink  = nil

	local link
	local itype, subtype

	-- main hand
	link = GetInventoryItemLink("player", GetInventorySlotInfo("MainHandSlot"))
	if link then
		itype, subtype = select(6, GetItemInfo(link))
		if itype == "Weapon" then
			mainHandLink = link
			wearingTwoHanded = IsSubtypeTwoHanded(subtype)
		end
	end
	if mainHandLink then
		changedMainHandLink = mainHandLink
		buttonMainHand:Enable()
	else
		wearingTwoHanded = false
		changedMainHandLink = nil
		buttonMainHand:Disable()
	end

	-- off hand
	link = GetInventoryItemLink("player", GetInventorySlotInfo("SecondaryHandSlot"))
	if link then
		itype = select(6, GetItemInfo(link))
		if itype == "Weapon" then
			offHandLink = link
		end
	end
	if offHandLink then
		changedOffHandLink = offHandLink
		buttonOffHand:Enable()
	else
		changedOffHandLink = nil
		buttonOffHand:Disable()
	end
end

--------------------------------------------------
-- the dressing room is opened
--------------------------------------------------
DressUpFrame:HookScript("OnShow", function()
	SetDefaultWeapons()
end)

--------------------------------------------------
-- the dressing room is reset
--------------------------------------------------
DressUpFrameResetButton:HookScript("OnClick", function()
	CloseDropDownMenus()
	SetDefaultWeapons()
end)

--------------------------------------------------
-- the dressing room is closed
--------------------------------------------------
DressUpFrame:HookScript("OnHide", function()
	CloseDropDownMenus()
end)

--------------------------------------------------
-- a new item is equipped in the dressing room
--------------------------------------------------
-- create a tooltip to scan to see which hand certain weapons go into
local tooltipFrame = CreateFrame("GameTooltip", "DressingRoomEnchantmentsTooptip", UIParent, "GameTooltipTemplate")
tooltipFrame:SetOwner(UIParent, "ANCHOR_NONE")

hooksecurefunc("DressUpItemLink", function(link)
	-- don't close the menu if the addon is just changing the enchantment
	if sendingEnchantment then
		sendingEnchantment = false
	else
		CloseDropDownMenus()
	end

	-- check if the new item is a weapon
	local itype, subtype = select(6, GetItemInfo(link))
	if itype == "Weapon" then
		-- two-handed weapons remove off hand weapons
		if IsSubtypeTwoHanded(subtype) then
			wearingTwoHanded = true
			mainHandLink = link
			changedMainHandLink = link
			offHandLink = nil
			changedOffHandLink = nil
			buttonMainHand:Enable()
			buttonOffHand:Disable()
			return
		end

		-- ranged/fishing pole items hide weapons from both hands
		if subtype == "Bows" or subtype == "Guns" or subtype == "Crossbows"
			or subtype == "Thrown" or subtype == "Wands" or subtype == "Fishing Poles" then
			wearingTwoHanded = false
			mainHandLink = nil
			changedMainHandLink = nil
			offHandLink = nil
			changedOffHandLink = nil
			buttonMainHand:Disable()
			buttonOffHand:Disable()
			return
		end

		-- subtypes that could be a main hand or off hand weapon
		if subtype == "Daggers" or subtype == "Fist Weapons" or subtype == "One-Handed Axes"
			or subtype == "One-Handed Maces" or subtype == "One-Handed Swords" then
			-- set the item into the invisible tooltip
			tooltipFrame:ClearLines()
			tooltipFrame:SetHyperlink(link)
			tooltipFrame:Show()

			-- go through a few possible text lines on the tooltip to figure out where the weapon goes
			local can_dual_wield = (GetSpellInfo("Dual Wield") ~= nil)
			local hand = nil
			for i=2,4 do
				hand = _G[tooltipFrame:GetName().."TextLeft"..i]:GetText()
				if hand then
					if hand == "Main Hand" or (not can_dual_wield and hand == "One-Hand") then
						wearingTwoHanded = false
						mainHandLink = link
						changedMainHandLink = link
						buttonMainHand:Enable()
						if not can_dual_wield then -- if you can't dual wield then it removes the other
							offHandLink = nil
							changedOffHandLink = nil
							buttonOffHand:Disable()
						end
						return
					elseif hand == "Off Hand" or hand == "One-Hand" then
						offHandLink = link
						changedOffHandLink = link
						buttonOffHand:Enable()
						if wearingTwoHanded then
							wearingTwoHanded = false
							mainHandLink = nil
							changedMainHandLink = nil
							buttonMainHand:Disable()
						elseif not can_dual_wield then -- if you can't dual wield then it removes the other
							mainHandLink = nil
							changedMainHandLink = nil
							buttonMainHand:Disable()
						end
						return
					end
				end
			end
		end
		return
	end -- end of testing weapons

	-- test if non-weapons are being held in the off-hand
	tooltipFrame:ClearLines()
	tooltipFrame:SetHyperlink(link)
	tooltipFrame:Show()
	local hand
	for i=2,4 do
		hand = _G[tooltipFrame:GetName().."TextLeft"..i]:GetText()
		if hand == "Off Hand" or hand == "Held In Off-hand" then
			offHandLink = nil
			changedOffHandLink = nil
			buttonOffHand:Disable()
			if wearingTwoHanded then
				wearingTwoHanded = false
				mainHandLink = nil
				changedMainHandLink = nil
				buttonMainHand:Disable()
			end
			return
		end
	end
end)
