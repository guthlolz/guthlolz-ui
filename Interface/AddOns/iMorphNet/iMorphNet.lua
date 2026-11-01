IMorphInfo = {
	ver = 1,
	frame = nil,
	call = nil,
	prefix = "iMN",
	channel = nil,
	unitFullName = nil,
	unitName = nil,
	netDebug = false,

	model = nil,
	light = nil,
	outfit = nil,
	race = nil,
	gender = nil,
	forms = {},
	enchants = {},
	items = {},
	itemset = nil,
	itemsetVersion = nil,
	transmog = nil,
	transmogVersion = nil,
	flags  = {},
	mountId = nil,
	titleId = nil,

	parseTextOld = nil,
	frame = nil,
}

hooksecurefunc("ChatEdit_ParseText", function(chatEntry, send) 
    if send == 1 then 
        local txt = chatEntry:GetText()
        if txt and txt:sub(1,1) == '.' and txt:len() > 3 and txt:sub(2, 2):match('%a') then
            iMorphChatHandler(txt)
            chatEntry:SetText("") 
        end 
    end 
end)

--[[ 
	iMorphNet:
]]--

local function getMsgPrefix()
	return IMorphInfo.prefix .. ":" .. IMorphInfo.channel
end

local function UnloadAddonMng()
	C_ChatInfo.RegisterAddonMessagePrefix("")
end

local function sendMsg(msg)
	if IsInRaid() then
		C_ChatInfo.SendAddonMessage(getMsgPrefix(), msg, "RAID")
	elseif IsInGroup() then
		C_ChatInfo.SendAddonMessage(getMsgPrefix(), msg, "PARTY")
	end	
end

local function sendModelMsg(model) 
	IMorphInfo.model = model
	sendMsg("model " .. tostring(model))
end
local function sendLightMsg(light)
	IMorphInfo.light = light
	sendMsg("light " .. tostring(light))
end
local function sendOutfitMsg(outfit)
	IMorphInfo.outfit = outfit
	sendMsg("outfit " .. tostring(outfit))
end
local function sendRaceMsg(race)
	IMorphInfo.race = race
	sendMsg("race " .. tostring(race))
end
local function sendGenderMsg(gender)
	IMorphInfo.gender = gender
	sendMsg("gender " .. tostring(gender))
end
local function sendShapeshiftFormMsg(formId, displayId)
	IMorphInfo.forms[formId] = displayId
	sendMsg("shapeshift " .. tostring(formId) .. " " .. tostring(displayId))
end
local function sendEnchantMsg(enchant, slot)
	IMorphInfo.enchants[slot] = enchant
	sendMsg("enchant " .. tostring(enchant) .. " " .. tostring(slot))
end
local function sendItemMsg(item, slot, version)
	IMorphInfo.items[slot] = {item, version}
	sendMsg("item " .. tostring(item) .. " " .. tostring(slot) .. " " .. tostring(version))
end
local function sendItemSetMsg(itemset, version)
	IMorphInfo.itemset = itemset
	IMorphInfo.itemsetVersion = version
	sendMsg("itemset " .. tostring(itemset) .. " " .. tostring(version))
end
local function sendTransmogSetMsg(transmog, version)
	IMorphInfo.transmog = transmog
	IMorphInfo.transmogVersion = version
	sendMsg("transmog " .. tostring(transmog) .. " " .. tostring(version))
end
local function sendFlagMsg(flag, value)
	IMorphInfo.flags[flag] = value
	sendMsg("flag " .. tostring(flag) .. " " .. tostring(value))
end
local function sendMountMsg(mountId)
	IMorphInfo.mountId = mountId
	sendMsg("mount " .. tostring(mountId))
end
local function sendTitleMsg(titleId)
	IMorphInfo.titleId = titleId
	sendMsg("title " .. tostring(titleId))
end
local function sendPlayEffectMsg(effectId, positionId) sendMsg("playeffect " .. tostring(effectId) .. " " .. tostring(positionId)) end
local function sendPlayEffectKitMsg(effectId, repeatEffect) sendMsg("playeffeckit " .. tostring(effectId) .. " " .. tostring(repeatEffect)) end
local function sendJoinedMsg() sendMsg("joined") end
local function sendJoinedAckMsg() sendMsg("joinedack") end
local function sendUpdateMsg() 
	if IMorphInfo.outfit ~= nil then sendOutfitMsg(IMorphInfo.outfit)
	elseif IMorphInfo.itemset ~= nil then sendItemSetMsg(IMorphInfo.itemset, IMorphInfo.itemsetVersion)
	elseif IMorphInfo.transmog ~= nil then sendTransmogSetMsg(IMorphInfo.transmog, IMorphInfo.transmogVersion) end

	if IMorphInfo.model ~= nil then sendModelMsg(IMorphInfo.model)
	elseif IMorphInfo.race ~= nil then sendRaceMsg(IMorphInfo.race) end
	if IMorphInfo.gender ~= nil then sendGenderMsg(IMorphInfo.gender) end
	if IMorphInfo.mountId ~= nil then sendMountMsg(IMorphInfo.mountId) end

	if IMorphInfo.light ~= nil then sendLightMsg(IMorphInfo.light) end

	for formId, displayId in pairs(IMorphInfo.forms) do
		sendShapeshiftFormMsg(formId, displayId)
	end
	for slot, enchant in pairs(IMorphInfo.enchants) do
		sendEnchantMsg(enchant, slot)
	end
	for slot, data in pairs(IMorphInfo.items) do
		item, version = data
		sendItemMsg(item, slot, version)
	end
	for flag, value in pairs(IMorphInfo.flags) do
		sendFlagMsg(flag, value)
	end
end

local function iMorphOnEvent(self, event, ...)

	if IMorphInfo.netDebug then
		print(...)
	end
	
	if event == "CHAT_MSG_ADDON" then
		local prefix, text, channel, sender, target, _zoneChannelID, _localID, _name, _instanceID =  ...
		
		if sender == IMorphInfo.unitFullName or sender == IMorphInfo.unitName or IMorphInfo.channel == nil then
			return
		end
		
		local command, arg1, arg2, arg3 = strsplit(' ', text, 4)
		if command == 'joined' then
			iMorphMiddleware('joined', sender, IMorphInfo.channel)
			--print('(imorph-remote) ' .. sender .. ' joined the channel ' .. IMorphInfo.channel)
			sendJoinedAckMsg()
			sendUpdateMsg()
		elseif command == 'joinedack' then
			--print('(imorph-remote) ' .. sender .. ' in the channel ' .. IMorphInfo.channel)
			iMorphMiddleware('joined', sender, IMorphInfo.channel)
		elseif command == 'enchant' then
			SetEnchant(tonumber(arg1), tonumber(arg2), '-n', sender)
		elseif command == 'item' then
			SetItem(tonumber(arg1), tonumber(arg2), tonumber(arg3), '-n', sender)
		elseif command == 'outfit' then
			SetOutfit(tonumber(arg1), '-n', sender)
		elseif command == 'itemset' then
			SetItemSet(tonumber(arg1), '-n', sender)
		elseif command == 'transmog' then
			SetTransmogSet(tonumber(arg1), tonumber(arg2), '-n', sender)
		elseif command == 'flag' then
			SetFlag(tonumber(arg1), tonumber(arg2), '-n', sender)
		elseif command == 'title' then
			SetTitle(tonumber(arg1), '-n', sender)
		elseif command == 'model' then
			Morph(tonumber(arg1), '-n', sender)
		elseif command == 'race' then
			SetRace(tonumber(arg1), 0, 0, '-n', sender)
		elseif command == 'gender' then
			SetGender(tonumber(arg1), '-n', sender)
		elseif command == 'shapeshift' then
			SetShapeshiftForm(tonumber(arg1), tonumber(arg2), '-n', sender)
		elseif command == 'mount' then
			SetMount(tonumber(arg1), '-n', sender)
		elseif command == 'playeffect' then
			PlayEffect(tonumber(arg1), tonumber(arg2), '-n', sender)
		elseif command == 'playeffeckit' then
			PlayEffectKit(tonumber(arg1), tonumber(arg2), '-n', sender)
		elseif command == 'light' then
			SetLightParam(tonumber(arg1), '-n', sender)
		elseif command == 'weather' then
			SetWeather(tonumber(arg1), tonumber(arg2), '-n', sender)
		else
			print('(imorph-remote) unknown  type ' .. command)
		end
		return
	elseif event == "PLAYER_ENTERING_WORLD" then
		if IMorphInfo.channel ~= nil then
			--print('(imorph) entering the world again')
			IMorphInfo.frame = nil
			InitAddonNet()
			sendUpdateMsg()
		end
	elseif event == "GROUP_ROSTER_UPDATE" then
		--if IMorphInfo.channel ~= nil and IMorphInfo.outfit ~= nil then
		--	sendOutfitMsg()
		--end
	end
end

function InitAddonNet()
	if IMorphInfo.frame == nil then
		IMorphInfo.frame = CreateFrame("Frame")
		IMorphInfo.frame:RegisterEvent("CHAT_MSG_ADDON")
		--IMorphInfo.frame:RegisterEvent("GROUP_ROSTER_UPDATE")
		IMorphInfo.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
		--IMorphInfo.frame:RegisterEvent("GROUP_JOINED")
		--IMorphInfo.frame:RegisterEvent("GROUP_FORMED")
		IMorphInfo.frame:SetScript("OnEvent", iMorphOnEvent)
	end

	if not C_ChatInfo.IsAddonMessagePrefixRegistered(getMsgPrefix()) then
		C_ChatInfo.RegisterAddonMessagePrefix(getMsgPrefix())
	end
end


function iMorphChatHandler(msg, ...)
	local command, arg = strsplit(' ', msg:sub(2), 2)

	if command == 'help' then
		print('|cFFDC143CiMorph|r commands:')
		print('  .dir')
		print('  .site')
		print('  .discord')
		print('  .reset')
		print('  .unload')
		print('  .disablesm')
		print('  .enablesm')
		print('  .gender')
		print('  .scale |cFFCCCCCC<0.5-3.0>|r')
		print('  .scalepet |cFFCCCCCCscale>|r')
		print('  .morph |cFFCCCCCC<display id>|r')
		print('  .morphpet |cFFCCCCCC<display id>|r')
		print('  .race |cFFCCCCCC<1-77> <form 0-1>|r')
		print('  .mount |cFFCCCCCC<display id> | <1 ground, 2 flying>|r')
		print('  .item |cFFCCCCCC<1-19> <item id> <version> <secondary appearance>|r')
		print('  .itemset |cFFCCCCCC<itemset id> <version>|r')
		print('  .transmog |cFFCCCCCC<transmog id> <version>|r')
		print('  .enchant |cFFCCCCCC<1-2> <enchant id>|r')
		print('  .itemswap |cFFCCCCCC<item id> <item id>|r')
		print('  .title |cFFCCCCCC<0-128>|r')
		print('  .customtitle |cFFCCCCCC<title text> <0-1>|r')
		print('  .medal |cFFCCCCCC<0-8>|r')
		print('  .customization |cFFCCCCCC<name> <id>|r')
		print('  .setcustomization |cFFCCCCCC<name> <id>|r')
		print('  .shapeshift |cFFCCCCCC<form id> <display id>|r')
		print('  .spell |cFFCCCCCC<spell id> <spell id>|r')
		print('  .spellvisual |cFFCCCCCC<spell visual id> <spell visual id>|r')
		print('  .spellvisualkit |cFFCCCCCC<spell visual kit id> <spell visual kit id>|r')
		print('  .spellvisualkitmodelattach |cFFCCCCCC<spell visual kit model id> <spell visual kit model id>|r')
		print('  .spellmissile |cFFCCCCCC<spell missile id> <spell missile id>|r')
		print('  .visualeffect |cFFCCCCCC<spell effect id> <spell effect id>|r')
		print('  .playeffect |cFFCCCCCC<effect id> <positioner id>|r')
		print('  .playkit |cFFCCCCCC<effect id> <option id>|r')
		print('  .playpeteffectkit |cFFCCCCCC<effect id> <option id>|r')
		print('  .loadingscreen |cFFCCCCCC<loading screen id>|r')
		print('  .light |cFFCCCCCC<light id>|r')
		print('  .screeneffect |cFFCCCCCC<screen effect id>|r')
		print('  .weather |cFFCCCCCC<weatherId> <0.0-1.0>|r')
		print('  .time |cFFCCCCCC<hours> <minutes>|r')
		print('  .exp')
		print('  .logging')
		print('  .console')
		print('  .mog |cFFCCCCCC<name>|r')
		print('  .mogs')
		print('  .mogreload')
		print('|cFFDC143CiMorphNet|r commands:')
		print('  .outfit |cFFCCCCCC<WoWHead outfit id> ')
		print('  .join |cFFCCCCCC<channel name>')
		print('  .leave')
		return
	end

	if command == 'dir' then
		iMorphMiddleware('dir')
		return
	end

	if command == 'exp' then
		iMorphMiddleware('exp')
		return
	end

	if command == 'unload' then
		iMorphMiddleware('unload')
		return
	end

	if command == 'site' then
		iMorphMiddleware('site')
		return
	end

	if command == 'discord' then
		iMorphMiddleware('discord')
		return
	end

	if command == 'health' then
		iMorphMiddleware('health')
		return
	end

	if command == 'debug' then
		iMorphMiddleware('debug')
		return
	end

	if command == 'reset' then
		ResetIds()
		return
	end

	if command == 'disablesm' then
		SetFlag(2, 0)
		if IMorphInfo.channel ~= nil and (IsInRaid() or IsInGroup()) then
			sendFlag(2, 0)
		end
		return
	end

	if command == 'enablesm' then
		SetFlag(2, 1)
		if IMorphInfo.channel ~= nil and (IsInRaid() or IsInGroup()) then
			sendFlag(2, 0)
		end
		return
	end
	
	if command == 'console' then
		SetConsole(arg)
		return
	end

	if command == 'menu' then
		SetMenu(arg)
		return
	end

	if command == 'helmshow' then
		HelmShow()
		return
	end

	if command == 'join' and tostring(arg) ~= nil then
		if string.len(arg) > 13 then -- len 13 byte limit
			print("(imorph) channel name must be under 13 characters: len(" .. tostring(arg) .. ') = ' .. tostring(string.len(arg)))
			return
		end
		local name, server = UnitFullName("player")
		IMorphInfo.unitFullName = name .. "-" .. server
		IMorphInfo.unitName = name
		IMorphInfo.channel = arg 
		InitAddonNet()
		if IsInRaid() or IsInGroup() then
			sendJoinedMsg()
			if IMorphInfo.outfit ~= nil then
				sendOutfitMsg(IMorphInfo.outfit)
			end
		end
		iMorphMiddleware('join', arg)
		print("(imorph) joined: " .. tostring(arg))
		return
	end
	
	if command == 'leave' and tostring(arg) ~= nil then
		UnloadAddonMng()
		iMorphMiddleware('leave', arg)
		print("(imorph) left: " .. IMorphInfo.channel)
		IMorphInfo.channel = nil
		return
	end
	
	if command == 'gender' then
		SetGender(arg)
		if IMorphInfo.channel ~= nil and (IsInRaid() or IsInGroup()) then
			sendGenderMsg(arg)
		end
		return
	end

	if command == 'mogreload' then
		ReloadMog()
		return
	end

	if command == 'mogs' then
		ListMogs()
		return
	end

	if command == 'mog' and tostring(arg) ~= nil then
		SetMog(arg)
		return
	end

	if command == 'scale' and tonumber(arg) ~= nil then
		SetScale(arg)
		return
	end

	if command == 'scalepet' and tonumber(arg) ~= nil then
		SetScalePet(arg)
		return
	end

	if command == 'morph' and tonumber(arg) ~= nil then
		Morph(arg, nil)
		if IMorphInfo.channel ~= nil and (IsInRaid() or IsInGroup()) then
			sendModelMsg(arg)
		end
		return
	end

	if command == 'morphpet' and tonumber(arg) ~= nil then
		MorphPet(arg)
		return
	end

	if command == 'class' and tonumber(arg) ~= nil then
		SetClass(arg)
		return
	end

	if command == 'npc' and (tonumber(arg) ~= nil or arg ~= nil) then
		MorphNpc(arg)
		return
	end

	if command == 'medal' and tonumber(arg) ~= nil then
		SetMedal(arg)
		return
	end

	if iMorphContains(iMorphCustomization(), command) and tonumber(arg) ~= nil then
		SetCustomization(command, arg)
		return
	end

	if command == 'loadingscreen' and tonumber(arg) ~= nil then
		SetLoadingScreen(arg)
		return
	end

	if command == 'light' and tonumber(arg) ~= nil then
		SetLightParam(arg)
		if IMorphInfo.channel ~= nil and (IsInRaid() or IsInGroup()) then
			sendLightMsg(arg)
		end
		return
	end

	if command == 'screeneffect' and tonumber(arg) ~= nil then
		SetScreenEffect(arg)
		return
	end
	
	if command == 'customization' and arg == nil then
		Customizations()
		return
	end

	if arg then
		local arg1, arg2, arg3, arg4 = strsplit(' ', arg, 4)

		if command == 'customization' or command == 'cust' then
			Customizations(arg1, arg2, arg3)
			return
		end

		if command == 'race' and tonumber(arg1) ~= nil then
			SetRace(arg1, arg2, arg3)
			if IMorphInfo.channel ~= nil and (IsInRaid() or IsInGroup()) then
				sendRaceMsg(arg1)
			end
			return
		end

		if command == 'item' and tonumber(arg1) ~= nil then
			SetItem(arg1, arg2, arg3, arg4)
			if IMorphInfo.channel ~= nil and (IsInRaid() or IsInGroup()) then
				sendItemMsg(arg1, arg2, arg3)
			end
			return
		end

		if command == 'itemset' and tonumber(arg1) ~= nil then
			SetItemSet(tonumber(arg1), tonumber(arg2))
			if IMorphInfo.channel ~= nil and (IsInRaid() or IsInGroup()) then
				sendItemSetMsg(arg1, arg2)
			end
			return
		end

		if command == 'transmog' and tonumber(arg1) ~= nil then
			SetTransmogSet(tonumber(arg1), tonumber(arg2))
			if IMorphInfo.channel ~= nil and (IsInRaid() or IsInGroup()) then
				sendTransmogSetMsg(arg1, arg2)
			end
			return
		end
		
		if command == 'outfit' and tonumber(arg1) ~= nil then
			SetOutfit(arg1, nil)
			if IMorphInfo.channel ~= nil and (IsInRaid() or IsInGroup()) then
				sendOutfitMsg(arg1)
			end			
			return
		end

		if command == 'mount' then
			SetMount(tonumber(arg1), tonumber(arg2))
			if IMorphInfo.channel ~= nil and (IsInRaid() or IsInGroup()) then
				sendMountMsg(arg1)
			end	
			return
		end

		if command == 'log' then
			SetLogging(arg1, arg2)
			return
		end

		if command == 'enchant' and tonumber(arg1) ~= nil and tonumber(arg2) ~= nil then
			slotID = nil
			if tonumber(arg1) == 1 then
				SetEnchant(16, arg2)
				slotID = 16
			elseif tonumber(arg1) == 2 then
				SetEnchant(17, arg2)
				slotID = 17
			end

			if slotID ~= nil and IMorphInfo.channel ~= nil and (IsInRaid() or IsInGroup()) then
				sendEnchantMsg(slotID, arg2)
			end	

			return
		end

		if command == 'shapeshift' and tonumber(arg1) ~= nil and tonumber(arg2) ~= nil then
			SetShapeshiftForm(arg1, arg2)
			if IMorphInfo.channel ~= nil and (IsInRaid() or IsInGroup()) then
				sendShapeshiftFormMsg(arg1, arg2)
			end	
			return
		end

		if command == 'weather' and tonumber(arg1) ~= nil and tonumber(arg2) ~= nil then
			SetWeather(arg1, arg2)
			if IMorphInfo.channel ~= nil and (IsInRaid() or IsInGroup()) then
				sendWeatherMsg(arg1, arg2)
			end	
			return
		end

		if command == 'time' and tonumber(arg1) ~= nil and tonumber(arg2) ~= nil then
			SetTime(arg1, arg2)
			return
		end

		if command == 'spell' and tonumber(arg1) ~= nil and tonumber(arg2) ~= nil then
			SetSpell(arg1, arg2)
			return
		end

		if command == 'spellvisual' and tonumber(arg1) ~= nil and tonumber(arg2) ~= nil then
			SetSpellVisual(arg1, arg2)
			return
		end

		if command == 'spellmissile' and tonumber(arg1) ~= nil and tonumber(arg2) ~= nil then
			SetSpellMissile(arg1, arg2)
			return
		end

		if command == 'spellvisualkit' and tonumber(arg1) ~= nil and tonumber(arg2) ~= nil then
			SetSpellVisualKit(arg1, arg2)
			return
		end

		if command == 'visualeffect' and tonumber(arg1) ~= nil and tonumber(arg2) ~= nil then
			SetVisualEffect(arg1, arg2)
			return
		end

		if command == 'spellvisualkitmodelattach' then
			SetSpellvisualkitmodelattach(arg1, arg2)
			return
		end

		if command == 'itemswap' and tonumber(arg1) ~= nil and tonumber(arg2) ~= nil then
			SetItemSwap(arg1, arg2)
			return
		end		
		
		if command == 'playeffect' and tonumber(arg1) ~= nil then
			PlayEffect(arg1, arg2, nil)
			if IMorphInfo.channel ~= nil and (IsInRaid() or IsInGroup()) then
				sendPlayEffectMsg(arg1, 21)
			end		
			return
		end
		
		if command == 'playkit' and tonumber(arg1) ~= nil then
			PlayEffectKit(arg1, arg2, nil)
			if IMorphInfo.channel ~= nil and (IsInRaid() or IsInGroup()) then
				sendPlayEffectKitMsg(arg1, arg2)
			end		
			return
		end

		if command == 'playpetkit' and tonumber(arg1) ~= nil then
			PlayPetEffectKit(arg1, arg2, nil)
			return
		end

		if command == 'title' and tonumber(arg1) ~= nil then
			SetTitle(arg1, arg2)
			if IMorphInfo.channel ~= nil and (IsInRaid() or IsInGroup()) then
				sendTitleMsg(arg1, arg2)
			end	
			return
		end

		if command == 'customtitle' and tostring(arg1) ~= nil then
			SetCustomTitleEvent(arg1, arg2)
			if IMorphInfo.channel ~= nil and (IsInRaid() or IsInGroup()) then
				sendCustomTitleMsg(arg1, arg2)
			end	
			return
		end

	end
end

function iMorphSetup()
	if IMorphInfo.call == nil then
		IMorphInfo.call = _G[string.char(67, 108, 111, 115, 101, 84, 114, 97, 100, 101)]
	end
end

function iMorphMiddleware(command, ...)
	iMorphSetup()
	IMorphInfo.call(command, ...)
end

function iMorphCustomization()
	return {'aquaticform','armbands','armorcolor','armorstyle','armspikes','armupgrade','beard','bearform','blindfold','blindfolds','bodymarkings','bodypaint','bodypaintcolor','bodypattern','bodyscales','bodysize','bodytattoo','bracelets','breastplate','breechcloth','brow','catform','cheek','cheekbone','chest','chestspikes','chin','chindecoration','circlet','crest','eargauge','earringcolor','earrings','ears','eyebrows','eyecolor','eyes','eyesight','eyestyle','face','facefeatures','facejewelry','facemarkings','facepaint','facepaintcolor','facepattern','faceshape','facetattoo','facialhair','feather','features','feet','flightform','flower','foremane','furcolor','grime','hair','haircolor','hairdecoration','hairhighlights','hairstyle','headdress','helm','horncolor','horndecoration','hornjewelry','hornmarkings','horns','hornstyle','hornwraps','hunched','jawdecoration','jawfeatures','jawjewelry','jewelrycolor','legspikes','legupgrade','lowerarms','luminoushands','makeup','markings','markingscolor','modification','moonkinform','mustache','necklace','nose','nosepiercing','nosering','paint','paintcolor','pattern','piercing','piercings','primarycolor','rune','scalecolor','scalemarkings','scalepattern','scars','secondarycolor','secondarycolorstrength','secondaryhaircolor ','secondaryskincolor','shoulders','sideburns','skincolor','skintype','snout','tail','taildecoration','tailridge','tattoo','tattoocolor','tattoostyle','tendrils','tentacles','thighs','throat','travelform','tusks','underclothesbottom','underclothescolor','underclothestop','upperarms','upright','vinecolor','vines','waist','warpaint','warpaintcolor','wingdecoration'}
end

function iMorphContains(table, val)
    for _index, value in ipairs(table) do
        if value == val then
         return true
      end
   end
   return false
end

function SetShapeshiftForm(...) iMorphMiddleware('shapeshift', ...) end
function SetEnchant(...) iMorphMiddleware('enchant', ...) end
function SetItem(...) iMorphMiddleware('item', ...) end
function ResetIds() iMorphMiddleware('reset') end
function SetFlag(...) iMorphMiddleware('flag', ...) end
function SetWeather(...) iMorphMiddleware('weather', ...) end
function SetTime(...) iMorphMiddleware('time', ...) end
function SetConsole(...) iMorphMiddleware('console', ...) end
function SetScale(...) iMorphMiddleware('scale', ...) end
function SetScalePet(...) iMorphMiddleware('scalepet', ...) end
function Morph(...) iMorphMiddleware('morph', ...) end
function MorphPet(...) iMorphMiddleware('morphpet', ...) end
function MorphNpc(...) iMorphMiddleware('npc', ...) end
function SetGender(...) iMorphMiddleware('gender', ...) end
function Customizations(...) iMorphMiddleware('customization', ...) end
function SetRace(...) iMorphMiddleware('race', ...) end
function SetLogging(...) iMorphMiddleware('logging', ...) end
function SetItemSet(...) iMorphMiddleware('itemset', ...) end
function SetTransmogSet(...) iMorphMiddleware('transmog', ...) end
function SetOutfit(...) iMorphMiddleware('outfit', ...)end
function SetMount(...) iMorphMiddleware('mount', ...) end
function SetTitle(...)iMorphMiddleware('title', ...) end
function SetCustomTitleEvent(...) iMorphMiddleware('customtitle', ...) end
function SetClass(...) iMorphMiddleware('class', ...) end
function SetMedal(...) iMorphMiddleware('medal', ...) end
function SetCustomization(...) iMorphMiddleware('setcustomization', ...) end
function SetSpell(...) iMorphMiddleware('spell', ...) end
function SetSpellVisual(...) iMorphMiddleware('spellvisual', ...) end
function SetSpellVisualKit(...) iMorphMiddleware('spellvisualkit', ...) end
function SetSpellvisualkitmodelattach(...) iMorphMiddleware('spellvisualkitmodelattach', ...) end
function SetSpellMissile(...) iMorphMiddleware('spellmissile', ...) end
function SetVisualEffect(...) iMorphMiddleware('visualeffect', ...) end
function SetLoadingScreen(...) iMorphMiddleware('loadingscreen', ...) end
function SetLightParam(...) iMorphMiddleware('light', ...) end
function SetScreenEffect(...) iMorphMiddleware('screeneffect', ...) end
function PlayEffect(...) iMorphMiddleware('playeffect', ...) end
function PlayEffectKit(...) iMorphMiddleware('playeffectkit', ...) end
function PlayPetEffectKit(...) iMorphMiddleware('playpeteffectkit', ...) end
function SetItemSwap(...) iMorphMiddleware('itemswap', ...) end
function SetMenu(...) iMorphMiddleware('menu', ...) end
function HelmShow() iMorphMiddleware('helmshow') end
function SetMog(...) iMorphMiddleware('mog', ...) end
function ListMogs() iMorphMiddleware('mogs') end
function ReloadMog() iMorphMiddleware('mogreload') end