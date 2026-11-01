----------------------------------------------------------------------
-- 	Leatrix Plus 2.5.47 (28th October 2026)
----------------------------------------------------------------------

--	01:Functions 02:Locks   03:Restart 40:Player   45:Rest
--	60:Events    62:Profile 70:Logout  80:Commands 90:Panel

----------------------------------------------------------------------
-- 	Leatrix Plus
----------------------------------------------------------------------

	-- Create global table
	_G.LeaPlusDB = _G.LeaPlusDB or {}

	-- Create locals
	local LeaPlusLC, LeaPlusCB, LeaDropList, LeaConfigList, LeaLockList = {}, {}, {}, {}, {}
	local ClientVersion = GetBuildInfo()
	local GameLocale = GetLocale()
	local void

	-- Version
	LeaPlusLC["AddonVer"] = "2.5.47"

	-- Get locale table
	local void, Leatrix_Plus = ...
	local L = Leatrix_Plus.L

	-- Check Wow version is valid
	do
		local gameversion, gamebuild, gamedate, gametocversion = GetBuildInfo()
		if gametocversion and gametocversion > 29999 then
			-- Game client is not Burning Crusade Anniversary
			C_Timer.After(2, function()
				print(L["LEATRIX PLUS: WRONG VERSION INSTALLED!"])
			end)
			return
		end
		if gametocversion and gametocversion == 20505 then
			-- Used for upcoming game patch
			LeaPlusLC.NewPatch = true
		end
	end

	-- Check for ElvUI
	if C_AddOns.IsAddOnLoaded("ElvUI") then LeaPlusLC.ElvUI = unpack(ElvUI) end

----------------------------------------------------------------------
--	L00: Leatrix Plus
----------------------------------------------------------------------

	-- Initialise variables
	LeaPlusLC["ShowErrorsFlag"] = 1
	LeaPlusLC["NumberOfPages"] = 9
	LeaPlusLC["MainPanelHeight"] = 390

	-- Class colors
	do
		local void, playerClass = UnitClass("player")
		if CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[playerClass] then
			LeaPlusLC["RaidColors"] = CUSTOM_CLASS_COLORS
		else
			LeaPlusLC["RaidColors"] = RAID_CLASS_COLORS
		end
	end

	-- Create event frame
	local LpEvt = CreateFrame("FRAME")
	LpEvt:RegisterEvent("ADDON_LOADED")
	LpEvt:RegisterEvent("PLAYER_LOGIN")

	-- Set bindings translations
	_G.BINDING_NAME_LEATRIX_PLUS_GLOBAL_TOGGLE = L["Toggle panel"]
	_G.BINDING_NAME_LEATRIX_PLUS_GLOBAL_RARE = L["Announce rare"]

----------------------------------------------------------------------
--	L01: Functions
----------------------------------------------------------------------

	-- Create a random global name that changes every time the addon loads
	function LeaPlusLC:CreateRandomName()
		local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
		local name
		repeat
			local parts = {"F"} -- Start with a letter
			for i = 1, 16 do
				local n = math.random(#chars)
				parts[#parts + 1] = chars:sub(n, n)
			end
			name = table.concat(parts)
		until not _G[name] -- Make sure the name is not already in use
		return name
	end

	-- Print text
	function LeaPlusLC:Print(text)
		DEFAULT_CHAT_FRAME:AddMessage(L[text], 1.0, 0.85, 0.0)
	end

	-- Lock and unlock an item
	function LeaPlusLC:LockItem(item, lock)
		if lock then
			item:Disable()
			item:SetAlpha(0.3)
		else
			item:Enable()
			item:SetAlpha(1.0)
		end
	end

	-- Hide configuration panels
	function LeaPlusLC:HideConfigPanels()
		for k, v in pairs(LeaConfigList) do
			v:Hide()
		end
	end

	-- Decline a shared quest if needed
	function LeaPlusLC:CheckIfQuestIsSharedAndShouldBeDeclined()
		if LeaPlusLC["NoSharedQuests"] == "On" then
			local npcName = UnitName("questnpc")
			if npcName and UnitIsPlayer(npcName) then
				if UnitInParty(npcName) or UnitInRaid(npcName) then
					if not LeaPlusLC:FriendCheck(npcName) then
						DeclineQuest()
						return
					end
				end
			end
		end
	end

	-- Show a single line prefilled editbox with copy functionality
	function LeaPlusLC:ShowSystemEditBox(word, focuschat)
		if not LeaPlusLC.FactoryEditBox then
			-- Create frame for first time
			local eFrame = CreateFrame("FRAME", nil, UIParent)
			LeaPlusLC.FactoryEditBox = eFrame
			eFrame:SetSize(700, 110)
			eFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
			eFrame:SetFrameStrata("FULLSCREEN_DIALOG")
			eFrame:SetFrameLevel(5000)
			eFrame:SetScript("OnMouseDown", function(self, btn)
				if btn == "RightButton" then
					eFrame:Hide()
				end
			end)
			-- Add background color
			eFrame.t = eFrame:CreateTexture(nil, "BACKGROUND")
			eFrame.t:SetAllPoints()
			eFrame.t:SetColorTexture(0.05, 0.05, 0.05, 0.9)
			-- Add copy title
			eFrame.f = eFrame:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
			eFrame.f:SetPoint("TOPLEFT", x, y)
			eFrame.f:SetPoint("TOPLEFT", eFrame, "TOPLEFT", 12, -52)
			eFrame.f:SetWidth(676)
			eFrame.f:SetJustifyH("LEFT")
			eFrame.f:SetWordWrap(false)
			-- Add copy label
			eFrame.c = eFrame:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
			eFrame.c:SetPoint("TOPLEFT", x, y)
			eFrame.c:SetText(L["Press CTRL/C to copy"])
			eFrame.c:SetPoint("TOPLEFT", eFrame, "TOPLEFT", 12, -82)
			-- Add cancel label
			eFrame.x = eFrame:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
			eFrame.x:SetPoint("TOPRIGHT", x, y)
			eFrame.x:SetText(L["Right-click to close"])
			eFrame.x:SetPoint("TOPRIGHT", eFrame, "TOPRIGHT", -12, -82)
			-- Create editbox
			eFrame.b = CreateFrame("EditBox", nil, eFrame, "InputBoxTemplate")
			eFrame.b:ClearAllPoints()
			eFrame.b:SetPoint("TOPLEFT", eFrame, "TOPLEFT", 16, -12)
			eFrame.b:SetSize(672, 24)
			eFrame.b:SetFontObject("GameFontNormalLarge")
			eFrame.b:SetTextColor(1.0, 1.0, 1.0, 1)
			eFrame.b:SetBlinkSpeed(0)
			eFrame.b:SetHitRectInsets(99, 99, 99, 99)
			eFrame.b:SetAutoFocus(true)
			eFrame.b:SetAltArrowKeyMode(true)
			-- Editbox texture
			eFrame.t = CreateFrame("FRAME", nil, eFrame.b, "BackdropTemplate")
			eFrame.t:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = false, tileSize = 16, edgeSize = 16, insets = { left = 5, right = 5, top = 5, bottom = 5 }})
			eFrame.t:SetPoint("LEFT", -6, 0)
			eFrame.t:SetWidth(eFrame.b:GetWidth() + 6)
			eFrame.t:SetHeight(eFrame.b:GetHeight())
			eFrame.t:SetBackdropColor(1.0, 1.0, 1.0, 0.3)
			-- Handler
			eFrame.b:SetScript("OnKeyDown", function(void, key)
				if key == "C" and (IsControlKeyDown() or IsMetaKeyDown()) then
					C_Timer.After(0.1, function()
						eFrame:Hide()
						ActionStatus_DisplayMessage(L["Copied to clipboard."], true)
						if LeaPlusLC.FactoryEditBoxFocusChat then
							local eBox = ChatEdit_ChooseBoxForSend()
							ChatEdit_ActivateChat(eBox)
						end
					end)
				end
			end)
			-- Prevent changes
			eFrame.b:SetScript("OnEscapePressed", function() eFrame:Hide() end)
			eFrame.b:SetScript("OnEnterPressed", eFrame.b.HighlightText)
			eFrame.b:SetScript("OnMouseDown", eFrame.b.ClearFocus)
			eFrame.b:SetScript("OnMouseUp", eFrame.b.HighlightText)
			eFrame.b:SetFocus(true)
			eFrame.b:HighlightText()
			eFrame:Show()
		end
		if focuschat then LeaPlusLC.FactoryEditBoxFocusChat = true else LeaPlusLC.FactoryEditBoxFocusChat = nil end
		LeaPlusLC.FactoryEditBox:Show()
		LeaPlusLC.FactoryEditBox.b:SetText(word)
		LeaPlusLC.FactoryEditBox.b:HighlightText()
		LeaPlusLC.FactoryEditBox.b:SetScript("OnChar", function() LeaPlusLC.FactoryEditBox.b:SetFocus(true) LeaPlusLC.FactoryEditBox.b:SetText(word) LeaPlusLC.FactoryEditBox.b:HighlightText() end)
		LeaPlusLC.FactoryEditBox.b:SetScript("OnKeyUp", function() LeaPlusLC.FactoryEditBox.b:SetFocus(true) LeaPlusLC.FactoryEditBox.b:SetText(word) LeaPlusLC.FactoryEditBox.b:HighlightText() end)
	end

	-- Load a string variable or set it to default if it's not set to "On" or "Off"
	function LeaPlusLC:LoadVarChk(var, def)
		if LeaPlusDB[var] and type(LeaPlusDB[var]) == "string" and LeaPlusDB[var] == "On" or LeaPlusDB[var] == "Off" then
			LeaPlusLC[var] = LeaPlusDB[var]
		else
			LeaPlusLC[var] = def
			LeaPlusDB[var] = def
		end
	end

	-- Load a numeric variable and set it to default if it's not within a given range
	function LeaPlusLC:LoadVarNum(var, def, valmin, valmax)
		if LeaPlusDB[var] and type(LeaPlusDB[var]) == "number" and LeaPlusDB[var] >= valmin and LeaPlusDB[var] <= valmax then
			LeaPlusLC[var] = LeaPlusDB[var]
		else
			LeaPlusLC[var] = def
			LeaPlusDB[var] = def
		end
	end

	-- Load an anchor point variable and set it to default if the anchor point is invalid
	function LeaPlusLC:LoadVarAnc(var, def)
		if LeaPlusDB[var] and type(LeaPlusDB[var]) == "string" and LeaPlusDB[var] == "CENTER" or LeaPlusDB[var] == "TOP" or LeaPlusDB[var] == "BOTTOM" or LeaPlusDB[var] == "LEFT" or LeaPlusDB[var] == "RIGHT" or LeaPlusDB[var] == "TOPLEFT" or LeaPlusDB[var] == "TOPRIGHT" or LeaPlusDB[var] == "BOTTOMLEFT" or LeaPlusDB[var] == "BOTTOMRIGHT" then
			LeaPlusLC[var] = LeaPlusDB[var]
		else
			LeaPlusLC[var] = def
			LeaPlusDB[var] = def
		end
	end

	-- Load a string variable and set it to default if it is not a string (used with minimap exclude list)
	function LeaPlusLC:LoadVarStr(var, def)
		if LeaPlusDB[var] and type(LeaPlusDB[var]) == "string" then
			LeaPlusLC[var] = LeaPlusDB[var]
		else
			LeaPlusLC[var] = def
			LeaPlusDB[var] = def
		end
	end

	-- Show tooltips for checkboxes
	function LeaPlusLC:TipSee()
		GameTooltip:SetOwner(self, "ANCHOR_NONE")
		local parent = self:GetParent()
		if parent:GetParent() and parent:GetParent():GetObjectType() == "ScrollFrame" then
			-- Scrolling frame tooltips have different parent
			parent = self:GetParent():GetParent():GetParent():GetParent()
		end
		local pscale = parent:GetEffectiveScale()
		local gscale = UIParent:GetEffectiveScale()
		local tscale = GameTooltip:GetEffectiveScale()
		local gap = ((UIParent:GetRight() * gscale) - (parent:GetRight() * pscale))
		if gap < (250 * tscale) then
			GameTooltip:SetPoint("TOPRIGHT", parent, "TOPLEFT", 0, 0)
		else
			GameTooltip:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, 0)
		end
		GameTooltip:SetText(self.tiptext, nil, nil, nil, nil, true)
	end

	-- Show tooltips for dropdown menu tooltips
	function LeaPlusLC:ShowDropTip()
		GameTooltip:SetOwner(self, "ANCHOR_NONE")
		local parent = self:GetParent():GetParent():GetParent()
		local pscale = parent:GetEffectiveScale()
		local gscale = UIParent:GetEffectiveScale()
		local tscale = GameTooltip:GetEffectiveScale()
		local gap = ((UIParent:GetRight() * gscale) - (parent:GetRight() * pscale))
		if gap < (250 * tscale) then
			GameTooltip:SetPoint("TOPRIGHT", parent, "TOPLEFT", 0, 0)
		else
			GameTooltip:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, 0)
		end
		GameTooltip:SetText(self.tiptext, nil, nil, nil, nil, true)
	end

	-- Show tooltips for configuration buttons and dropdown menus
	function LeaPlusLC:ShowTooltip()
		GameTooltip:SetOwner(self, "ANCHOR_NONE")
		local parent = LeaPlusLC["PageF"]
		local pscale = parent:GetEffectiveScale()
		local gscale = UIParent:GetEffectiveScale()
		local tscale = GameTooltip:GetEffectiveScale()
		local gap = ((UIParent:GetRight() * gscale) - (LeaPlusLC["PageF"]:GetRight() * pscale))
		if gap < (250 * tscale) then
			GameTooltip:SetPoint("TOPRIGHT", parent, "TOPLEFT", 0, 0)
		else
			GameTooltip:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, 0)
		end
		GameTooltip:SetText(self.tiptext, nil, nil, nil, nil, true)
	end

	-- Create configuration button
	function LeaPlusLC:CfgBtn(name, parent)
		local CfgBtn = CreateFrame("BUTTON", nil, parent)
		LeaPlusCB[name] = CfgBtn
		CfgBtn:SetWidth(20)
		CfgBtn:SetHeight(20)
		CfgBtn:SetPoint("LEFT", parent.f, "RIGHT", 0, 0)

		CfgBtn.t = CfgBtn:CreateTexture(nil, "BORDER")
		CfgBtn.t:SetAllPoints()
		CfgBtn.t:SetTexture("Interface\\WorldMap\\Gear_64.png")
		CfgBtn.t:SetTexCoord(0, 0.50, 0, 0.50);
		CfgBtn.t:SetVertexColor(1.0, 0.82, 0, 1.0)

		CfgBtn:SetHighlightTexture("Interface\\WorldMap\\Gear_64.png")
		CfgBtn:GetHighlightTexture():SetTexCoord(0, 0.50, 0, 0.50);

		CfgBtn.tiptext = L["Click to configure the settings for this option."]
		CfgBtn:SetScript("OnEnter", LeaPlusLC.ShowTooltip)
		CfgBtn:SetScript("OnLeave", GameTooltip_Hide)
	end

	-- Create a help button to the right of a fontstring
	function LeaPlusLC:CreateHelpButton(frame, panel, parent, tip)
		LeaPlusLC:CfgBtn(frame, panel)
		LeaPlusCB[frame]:ClearAllPoints()
		LeaPlusCB[frame]:SetPoint("LEFT", parent, "RIGHT", -parent:GetWidth() + parent:GetStringWidth(), 0)
		LeaPlusCB[frame]:SetSize(25, 25)
		LeaPlusCB[frame].t:SetTexture("Interface\\COMMON\\help-i.blp")
		LeaPlusCB[frame].t:SetTexCoord(0, 1, 0, 1)
		LeaPlusCB[frame].t:SetVertexColor(0.9, 0.8, 0.0)
		LeaPlusCB[frame]:SetHighlightTexture("Interface\\COMMON\\help-i.blp")
		LeaPlusCB[frame]:GetHighlightTexture():SetTexCoord(0, 1, 0, 1)
		LeaPlusCB[frame].tiptext = L[tip]
		LeaPlusCB[frame]:SetScript("OnEnter", LeaPlusLC.TipSee)
	end

	-- Show a footer
	function LeaPlusLC:MakeFT(frame, text, left, width)
		local footer = LeaPlusLC:MakeTx(frame, text, left, 96)
		footer:SetWidth(width); footer:SetJustifyH("LEFT"); footer:SetWordWrap(true); footer:ClearAllPoints()
		footer:SetPoint("BOTTOMLEFT", left, 96)
		return footer
	end

	-- Capitalise first character in a string
	function LeaPlusLC:CapFirst(str)
		return gsub(string.lower(str), "^%l", strupper)
	end

	-- Toggle Zygor addon
	function LeaPlusLC:ZygorToggle()
		if select(2, C_AddOns.GetAddOnInfo("ZygorGuidesViewerClassic")) then
			if not C_AddOns.IsAddOnLoaded("ZygorGuidesViewerClassic") then
				if LeaPlusLC:PlayerInCombat() then
					return
				else
					C_AddOns.EnableAddOn("ZygorGuidesViewerClassic")
					ReloadUI()
				end
			else
				C_AddOns.DisableAddOn("ZygorGuidesViewerClassic")
				ReloadUI()
			end
		else
			-- Zygor cannot be found
			LeaPlusLC:Print("Zygor addon not found.")
		end
		return
	end

	-- Show memory usage stat
	function LeaPlusLC:ShowMemoryUsage(frame, anchor, x, y)

		-- Create frame
		local memframe = CreateFrame("FRAME", nil, frame)
		memframe:ClearAllPoints()
		memframe:SetPoint(anchor, x, y)
		memframe:SetWidth(100)
		memframe:SetHeight(20)

		-- Create labels
		local pretext = memframe:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
		pretext:SetPoint("TOPLEFT", 0, 0)
		pretext:SetText(L["Memory Usage"])

		local memtext = memframe:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
		memtext:SetPoint("TOPLEFT", 0, 0 - 30)

		-- Create stat
		local memstat = memframe:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
		memstat:SetPoint("BOTTOMLEFT", memtext, "BOTTOMRIGHT")
		memstat:SetText("(calculating...)")

		-- Create update script
		local memtime = -1
		memframe:SetScript("OnUpdate", function(self, elapsed)
			if memtime > 2 or memtime == -1 then
				UpdateAddOnMemoryUsage();
				memtext = GetAddOnMemoryUsage("Leatrix_Plus")
				memtext = math.floor(memtext + .5) .. " KB"
				memstat:SetText(memtext);
				memtime = 0;
			end
			memtime = memtime + elapsed;
		end)

		-- Release memory
		LeaPlusLC.ShowMemoryUsage = nil

	end

	-- Check if player is in LFG queue (battleground)
	function LeaPlusLC:IsInLFGQueue()

		-- Looking for Group realms (check for everything)
		if C_LFGList.HasActiveEntryInfo() then
			return true
		end

		-- Realms without Looking for Group (just check for battlegrounds)
		for i = 1, GetMaxBattlefieldID() do
			local status = GetBattlefieldStatus(i)
			if status == "queued" or status == "confirmed" then
				return true
			end
		end

	end

	-- Check if player is in combat
	function LeaPlusLC:PlayerInCombat()
		if (UnitAffectingCombat("player")) then
			LeaPlusLC:Print("You cannot do that in combat.")
			return true
		end
	end

	--  Hide panel and pages
	function LeaPlusLC:HideFrames()

		-- Hide option pages
		for i = 0, LeaPlusLC["NumberOfPages"] do
			if LeaPlusLC["Page"..i] then
				LeaPlusLC["Page"..i]:Hide();
			end;
		end

		-- Hide options panel
		LeaPlusLC["PageF"]:Hide();

	end

	-- Find out if Leatrix Plus is showing (main panel or config panel)
	function LeaPlusLC:IsPlusShowing()
		if LeaPlusLC["PageF"]:IsShown() then return true end
		for k, v in pairs(LeaConfigList) do
			if v:IsShown() then
				return true
			end
		end
	end

	-- Check if a name is in your friends list or guild (does not check realm as realm is unknown for some checks)
	function LeaPlusLC:FriendCheck(name, guid)

		-- Do nothing if name is empty (such as whispering from the Battle.net app)
		if not name then return end

		-- Update friends list
		C_FriendList.ShowFriends()

		-- Remove realm (since we have GUID checking)
		name = strsplit("-", name, 2)

		-- Check character friends
		for i = 1, C_FriendList.GetNumFriends() do
			-- Return true is character name matches and GUID matches if there is one (realm is not checked)
			local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
			local charFriendName = C_FriendList.GetFriendInfoByIndex(i).name
			charFriendName = strsplit("-", charFriendName, 2)
			if (name == charFriendName) and (guid and (guid == friendInfo.guid) or true) then
				return true
			end
		end

		-- Check Battle.net friends
		local numfriends = BNGetNumFriends()
		for i = 1, numfriends do
			local numtoons = C_BattleNet.GetFriendNumGameAccounts(i)
			for j = 1, numtoons do
				local gameAccountInfo = C_BattleNet.GetFriendGameAccountInfo(i, j)
				local characterName = gameAccountInfo.characterName
				local client = gameAccountInfo.clientProgram
				if client == "WoW" and characterName == name then
					return true
				end
			end
		end

		-- Check guild members if guild is enabled (new members may need to press J to refresh roster)
		if LeaPlusLC["FriendlyGuild"] == "On" then
			local gCount = GetNumGuildMembers()
			for i = 1, gCount do
				local gName, void, void, void, void, void, void, void, gOnline, void, void, void, void, gMobile, void, void, gGUID = GetGuildRosterInfo(i)
				if gOnline and not gMobile then
					gName = strsplit("-", gName, 2)
					-- Return true if character name matches including GUID if there is one
					if (name == gName) and (guid and (guid == gGUID) or true) then
						return true
					end
				end
			end
		end

	end

----------------------------------------------------------------------
--	L02: Locks
----------------------------------------------------------------------

	-- Function to set lock state for configuration buttons
	function LeaPlusLC:LockOption(option, item, reloadreq)
		if reloadreq then
			-- Option change requires UI reload
			if LeaPlusLC[option] ~= LeaPlusDB[option] or LeaPlusLC[option] == "Off" then
				LeaPlusLC:LockItem(LeaPlusCB[item], true)
			else
				LeaPlusLC:LockItem(LeaPlusCB[item], false)
			end
		else
			-- Option change does not require UI reload
			if LeaPlusLC[option] == "Off" then
				LeaPlusLC:LockItem(LeaPlusCB[item], true)
			else
				LeaPlusLC:LockItem(LeaPlusCB[item], false)
			end
		end
	end

--	Set lock state for configuration buttons
	function LeaPlusLC:SetDim()
		LeaPlusLC:LockOption("AutomateQuests", "AutomateQuestsBtn", false)			-- Automate quests
		LeaPlusLC:LockOption("AutoAcceptRes", "AutoAcceptResBtn", false)			-- Accept resurrection
		LeaPlusLC:LockOption("AutoReleasePvP", "AutoReleasePvPBtn", false)			-- Release in PvP
		LeaPlusLC:LockOption("AutoSellJunk", "AutoSellJunkBtn", false)				-- Sell junk automatically
		LeaPlusLC:LockOption("AutoRepairGear", "AutoRepairBtn", false)				-- Repair automatically
		LeaPlusLC:LockOption("InviteFromWhisper", "InvWhisperBtn", false)			-- Invite from whispers
		LeaPlusLC:LockOption("FilterChatMessages", "FilterChatMessagesBtn", true)	-- Filter chat messages
		LeaPlusLC:LockOption("MailFontChange", "MailTextBtn", true)					-- Resize mail text
		LeaPlusLC:LockOption("QuestFontChange", "QuestTextBtn", true)				-- Resize quest text
		LeaPlusLC:LockOption("BookFontChange", "BookTextBtn", true)					-- Resize book text
		LeaPlusLC:LockOption("MinimapModder", "ModMinimapBtn", true)				-- Enhance minimap
		LeaPlusLC:LockOption("TipModEnable", "MoveTooltipButton", true)				-- Enhance tooltip
		LeaPlusLC:LockOption("EnhanceDressup", "EnhanceDressupBtn", true)			-- Enhance dressup
		LeaPlusLC:LockOption("EnhanceQuestLog", "EnhanceQuestLogBtn", true)			-- Enhance quest log
		LeaPlusLC:LockOption("EnhanceTrainers", "EnhanceTrainersBtn", true)			-- Enhance trainers
		LeaPlusLC:LockOption("EnhanceFlightMap", "EnhanceFlightMapBtn", true)		-- Enhance flight map
		LeaPlusLC:LockOption("ShowCooldowns", "CooldownsButton", true)				-- Show cooldowns
		LeaPlusLC:LockOption("ShowBorders", "ModBordersBtn", true)					-- Show borders
		LeaPlusLC:LockOption("ShowPlayerChain", "ModPlayerChain", true)				-- Show player chain
		LeaPlusLC:LockOption("ShowInfoCards", "ShowInfoCardsBtn", true)				-- Show info cards
		LeaPlusLC:LockOption("ShowDruidPowerBar", "ShowDruidPowerBarBtn", true)		-- Show druid power bar
		LeaPlusLC:LockOption("ShowWowheadLinks", "ShowWowheadLinksBtn", true)		-- Show Wowhead links
		LeaPlusLC:LockOption("ShowFlightTimes", "ShowFlightTimesBtn", true)			-- Show flight times
		LeaPlusLC:LockOption("ManageWidget", "ManageWidgetButton", true)			-- Manage widget
		LeaPlusLC:LockOption("ManageTimer", "ManageTimerButton", true)				-- Manage timer
		LeaPlusLC:LockOption("ClassColFrames", "ClassColFramesBtn", true)			-- Class colored frames
		LeaPlusLC:LockOption("SetWeatherDensity", "SetWeatherDensityBtn", false)	-- Set weather density
		LeaPlusLC:LockOption("MuteGameSounds", "MuteGameSoundsBtn", false)			-- Mute game sounds
		LeaPlusLC:LockOption("MuteMountSounds", "MuteMountSoundsBtn", false)		-- Mute mount sounds
		LeaPlusLC:LockOption("MuteCustomSounds", "MuteCustomSoundsBtn", false)		-- Mute custom sounds
		LeaPlusLC:LockOption("StandAndDismount", "DismountBtn", true)				-- Dismount me
		LeaPlusLC:LockOption("SetEditModeLayout", "SetEditModeLayoutBtn", false)	-- Set edit mode layout
	end

----------------------------------------------------------------------
--	L03: Restarts
----------------------------------------------------------------------

	-- Set the reload button state
	function LeaPlusLC:ReloadCheck()

		-- Chat
		if	(LeaPlusLC["UseEasyChatResizing"]	~= LeaPlusDB["UseEasyChatResizing"])	-- Use easy resizing
		or	(LeaPlusLC["NoCombatLogTab"]		~= LeaPlusDB["NoCombatLogTab"])			-- Hide the combat log
		or	(LeaPlusLC["NoChatButtons"]			~= LeaPlusDB["NoChatButtons"])			-- Hide chat buttons
		or	(LeaPlusLC["UnclampChat"]			~= LeaPlusDB["UnclampChat"])			-- Unclamp chat frame
		or	(LeaPlusLC["MoveChatEditBoxToTop"]	~= LeaPlusDB["MoveChatEditBoxToTop"])	-- Move editbox to top
		or	(LeaPlusLC["MoreChatFontSizes"]		~= LeaPlusDB["MoreChatFontSizes"])		-- More chat font sizes
		or	(LeaPlusLC["NoStickyChat"]			~= LeaPlusDB["NoStickyChat"])			-- Disable sticky chat
		or	(LeaPlusLC["UseArrowKeysInChat"]	~= LeaPlusDB["UseArrowKeysInChat"])		-- Use arrow keys in chat
		or	(LeaPlusLC["NoChatFade"]			~= LeaPlusDB["NoChatFade"])				-- Disable chat fade
		or	(LeaPlusLC["ClassColorsInChat"]		~= LeaPlusDB["ClassColorsInChat"])		-- Use class colors in chat
		or	(LeaPlusLC["RecentChatWindow"]		~= LeaPlusDB["RecentChatWindow"])		-- Recent chat window
		or	(LeaPlusLC["MaxChatHstory"]			~= LeaPlusDB["MaxChatHstory"])			-- Increase chat history
		or	(LeaPlusLC["FilterChatMessages"]	~= LeaPlusDB["FilterChatMessages"])		-- Filter chat messages
		or	(LeaPlusLC["RestoreChatMessages"]	~= LeaPlusDB["RestoreChatMessages"])	-- Restore chat messages

		-- Text
		or	(LeaPlusLC["HideErrorMessages"]		~= LeaPlusDB["HideErrorMessages"])		-- Hide error messages
		or	(LeaPlusLC["NoHitIndicators"]		~= LeaPlusDB["NoHitIndicators"])		-- Hide portrait text
		or	(LeaPlusLC["HideZoneText"]			~= LeaPlusDB["HideZoneText"])			-- Hide zone text
		or	(LeaPlusLC["HideKeybindText"]		~= LeaPlusDB["HideKeybindText"])		-- Hide keybind text
		or	(LeaPlusLC["HideMacroText"]			~= LeaPlusDB["HideMacroText"])			-- Hide macro text
		or	(LeaPlusLC["HideRaidGroupLabels"]	~= LeaPlusDB["HideRaidGroupLabels"])	-- Hide raid group labels

		or	(LeaPlusLC["MailFontChange"]		~= LeaPlusDB["MailFontChange"])			-- Resize mail text
		or	(LeaPlusLC["QuestFontChange"]		~= LeaPlusDB["QuestFontChange"])		-- Resize quest text
		or	(LeaPlusLC["BookFontChange"]		~= LeaPlusDB["BookFontChange"])			-- Resize book text

		-- Interface
		or	(LeaPlusLC["MinimapModder"]			~= LeaPlusDB["MinimapModder"])			-- Enhance minimap
		or	(LeaPlusLC["HideMiniDayNight"]		~= LeaPlusDB["HideMiniDayNight"])		-- Hide the day and night indicator
		or	(LeaPlusLC["HideMiniZoneText"]		~= LeaPlusDB["HideMiniZoneText"])		-- Hide the zone text bar
		or	(LeaPlusLC["SquareMinimap"]			~= LeaPlusDB["SquareMinimap"])			-- Square minimap
		or	(LeaPlusLC["MinimapButtonBag"]		~= LeaPlusDB["MinimapButtonBag"])		-- Minimap button bag
		or	(LeaPlusLC["HideMiniTracking"]		~= LeaPlusDB["HideMiniTracking"])		-- Hide tracking button
		or	(LeaPlusLC["HideMiniLFG"]			~= LeaPlusDB["HideMiniLFG"])			-- Hide the Looking for Group button
		or	(LeaPlusLC["MiniExcludeList"]		~= LeaPlusDB["MiniExcludeList"])		-- Minimap exclude list
		or	(LeaPlusLC["TipModEnable"]			~= LeaPlusDB["TipModEnable"])			-- Enhance tooltip
		or	(LeaPlusLC["TipNoHealthBar"]		~= LeaPlusDB["TipNoHealthBar"])			-- Tooltip hide health bar
		or	(LeaPlusLC["EnhanceDressup"]		~= LeaPlusDB["EnhanceDressup"])			-- Enhance dressup
		or	(LeaPlusLC["EnhanceQuestLog"]		~= LeaPlusDB["EnhanceQuestLog"])		-- Enhance quest log
		or	(LeaPlusLC["EnhanceQuestTaller"]	~= LeaPlusDB["EnhanceQuestTaller"])		-- Enhance quest taller
		or	(LeaPlusLC["EnhanceProfessions"]	~= LeaPlusDB["EnhanceProfessions"])		-- Enhance professions
		or	(LeaPlusLC["EnhanceTrainers"]		~= LeaPlusDB["EnhanceTrainers"])		-- Enhance trainers
		or	(LeaPlusLC["EnhanceFlightMap"]		~= LeaPlusDB["EnhanceFlightMap"])		-- Enhance flight map

		or	(LeaPlusLC["ShowVolume"]			~= LeaPlusDB["ShowVolume"])				-- Show volume slider
		or	(LeaPlusLC["AhExtras"]				~= LeaPlusDB["AhExtras"])				-- Show auction controls
		or	(LeaPlusLC["ShowCooldowns"]			~= LeaPlusDB["ShowCooldowns"])			-- Show cooldowns
		or	(LeaPlusLC["DurabilityStatus"]		~= LeaPlusDB["DurabilityStatus"])		-- Show durability status
		or	(LeaPlusLC["ShowVanityControls"]	~= LeaPlusDB["ShowVanityControls"])		-- Show vanity controls
		or	(LeaPlusLC["ShowBagSearchBox"]		~= LeaPlusDB["ShowBagSearchBox"])		-- Show bag search box
		or	(LeaPlusLC["ShowFreeBagSlots"]		~= LeaPlusDB["ShowFreeBagSlots"])		-- Show free bag slots
		or	(LeaPlusLC["ShowRaidToggle"]		~= LeaPlusDB["ShowRaidToggle"])			-- Show raid button
		or	(LeaPlusLC["ShowBorders"]			~= LeaPlusDB["ShowBorders"])			-- Show borders
		or	(LeaPlusLC["ShowPlayerChain"]		~= LeaPlusDB["ShowPlayerChain"])		-- Show player chain
		or	(LeaPlusLC["ShowReadyTimer"]		~= LeaPlusDB["ShowReadyTimer"])			-- Show ready timer
		or	(LeaPlusLC["ShowDruidPowerBar"]		~= LeaPlusDB["ShowDruidPowerBar"])		-- Show druid power bar
		or	(LeaPlusLC["ShowDruidStatusText"]	~= LeaPlusDB["ShowDruidStatusText"])	-- Show druid power bar status text
		or	(LeaPlusLC["ShowRangeColoring"]		~= LeaPlusDB["ShowRangeColoring"])		-- Show range coloring
		or	(LeaPlusLC["ShowInfoCards"]			~= LeaPlusDB["ShowInfoCards"])			-- Show info cards
		or	(LeaPlusLC["ShowWowheadLinks"]		~= LeaPlusDB["ShowWowheadLinks"])		-- Show Wowhead links
		or	(LeaPlusLC["ShowFlightTimes"]		~= LeaPlusDB["ShowFlightTimes"])		-- Show flight times

		-- Frames
		or	(LeaPlusLC["ManageWidget"]			~= LeaPlusDB["ManageWidget"])			-- Manage widget
		or	(LeaPlusLC["ManageTimer"]			~= LeaPlusDB["ManageTimer"])			-- Manage timer
		or	(LeaPlusLC["ClassColFrames"]		~= LeaPlusDB["ClassColFrames"])			-- Class colored frames
		or	(LeaPlusLC["NoGryphons"]			~= LeaPlusDB["NoGryphons"])				-- Hide gryphons
		or	(LeaPlusLC["NoClassBar"]			~= LeaPlusDB["NoClassBar"])				-- Hide stance bar

		-- System
		or	(LeaPlusLC["NoRestedEmotes"]		~= LeaPlusDB["NoRestedEmotes"])			-- Silence rested emotes
		or	(LeaPlusLC["KeepAudioSynced"]		~= LeaPlusDB["KeepAudioSynced"])		-- Keep audio synced
		or	(LeaPlusLC["NoBagAutomation"]		~= LeaPlusDB["NoBagAutomation"])		-- Disable bag automation
		or	(LeaPlusLC["FasterLooting"]			~= LeaPlusDB["FasterLooting"])			-- Faster auto loot
		or	(LeaPlusLC["FasterMovieSkip"]		~= LeaPlusDB["FasterMovieSkip"])		-- Faster movie skip
		or	(LeaPlusLC["StandAndDismount"]		~= LeaPlusDB["StandAndDismount"])		-- Dismount me
		or	(LeaPlusLC["ShowVendorPrice"]		~= LeaPlusDB["ShowVendorPrice"])		-- Show vendor price
		or	(LeaPlusLC["CombatPlates"]			~= LeaPlusDB["CombatPlates"])			-- Combat plates
		or	(LeaPlusLC["EasyItemDestroy"]		~= LeaPlusDB["EasyItemDestroy"])		-- Easy item destroy

		-- Settings
		or	(LeaPlusLC["AddonLanguage"]			~= LeaPlusDB["AddonLanguage"])			-- Addon language
		or	(LeaPlusLC["SimpleAddonListing"]	~= LeaPlusDB["SimpleAddonListing"])		-- Simple addon listing

		then
			-- Enable the reload button
			LeaPlusLC:LockItem(LeaPlusCB["ReloadUIButton"], false)
			LeaPlusCB["ReloadUIButton"].f:Show()
		else
			-- Disable the reload button
			LeaPlusLC:LockItem(LeaPlusCB["ReloadUIButton"], true)
			LeaPlusCB["ReloadUIButton"].f:Hide()
		end

	end

----------------------------------------------------------------------
--	L40: Player
----------------------------------------------------------------------

	function LeaPlusLC:Player()

		-- LeaPlusLC.NewPatch - Set WorldFrame level to ensure world frame mouse events work (WorldFrame:IsMouseMotionFocus())
		-- In case invalid WorldFrame frame level is stored in layout-local cache
		WorldFrame:SetFrameLevel(1)

		----------------------------------------------------------------------
		-- Show info cards
		----------------------------------------------------------------------

		if LeaPlusLC["ShowInfoCards"] == "On" then

			-- Watch for Ctrl being pressed and only then give the card's link box the keyboard so CTRL/C copies the link
			-- (made now, while loading, as setting it up is not allowed in combat after loading)
			do
				local watcher = CreateFrame("Frame", nil, UIParent)
				watcher:SetPropagateKeyboardInput(true)
				watcher:EnableKeyboard(true)
				watcher:SetScript("OnKeyDown", function(self, key)
					local card = LeaPlusLC.IDCard
					if not card or not card:IsShown() then
						-- No card showing, so every key goes to the game
						if not InCombatLockdown() and not self:GetPropagateKeyboardInput() then self:SetPropagateKeyboardInput(true) end
						return
					end
					-- Escape closes the card (and is kept from the game, outside combat)
					if not InCombatLockdown() then self:SetPropagateKeyboardInput(key ~= "ESCAPE") end
					if key == "ESCAPE" then
						local viewer = LeaPlusLC.IDViewer
						if viewer and viewer.scenePopup and viewer.scenePopup:IsShown() then viewer.scenePopup:Hide() elseif viewer and viewer.fullscreen then viewer:SetFullscreen(false) else card:Hide() end
						-- Let keys through to the game again straight after (never left blocked)
						C_Timer.After(0, function() if not InCombatLockdown() then self:SetPropagateKeyboardInput(true) end end)
						return
					end
					if (key == "LCTRL" or key == "RCTRL" or key == "LMETA" or key == "RMETA") and card.url and not card.edit:HasFocus() then
						card.ctrlFocus = true
						card.edit:SetFocus()
						card.edit:HighlightText()
					end
				end)
			end

			-- Show the info card for whatever is under the mouse (arg1 is retry or upgrade when it runs itself again)
			local function ShowInfoCard(arg1, forceUnit)
				-- Secret values: the game can hide some values from addons (such as in combat, encounters and arenas)
				-- Anything that can be hidden is passed through Safe, which gives nil for a hidden value so it is left out
				local function IsSecret(v) return issecretvalue and issecretvalue(v) or false end
				local function Safe(...)
					local count = select("#", ...)
					if count == 1 then
						local v = ...
						if IsSecret(v) then return nil end
						return v
					end
					local values = {...}
					for i = 1, count do if IsSecret(values[i]) then values[i] = nil end end
					return unpack(values, 1, count)
				end
				-- Tables the game does not let addons read are left out too
				local function SafeTable(t)
					if type(t) == "table" and not IsSecret(t) and (not canaccesstable or canaccesstable(t)) then return t end
				end
				-- Auras: when auras are hidden, the game does not let addons read them at all (asking is an error), so check first
				local function AurasHidden()
					return C_Secrets and C_Secrets.ShouldAurasBeSecret and C_Secrets.ShouldAurasBeSecret() or false
				end
				-- Get a buff or debuff by its index: gives the aura (nil if it is hidden), and true when there are no more to look at
				local function GetAura(unit, index, harmful)
					if AurasHidden() then return nil, true end
					if C_Secrets and C_Secrets.ShouldUnitAuraIndexBeSecret and C_Secrets.ShouldUnitAuraIndexBeSecret(unit, index, harmful and "HARMFUL" or "HELPFUL") then return nil, false end
					local aura
					if harmful then aura = C_UnitAuras.GetDebuffDataByIndex(unit, index) else aura = C_UnitAuras.GetBuffDataByIndex(unit, index) end
					if not aura then return nil, true end
					return SafeTable(aura), false
				end
				-- Size of one screen pixel (borders this thin stay sharp and do not vanish when frames are moved)
				local function OnePixel()
					local physicalHeight = select(2, GetPhysicalScreenSize())
					if not physicalHeight or physicalHeight == 0 then return 1 end
					return (768 / physicalHeight) / UIParent:GetEffectiveScale()
				end
				-- Round a size or offset to whole screen pixels
				local function PixelRound(v)
					local px = OnePixel()
					return math.floor(v / px + 0.5) * px
				end
				-- Line a frame up with the screen pixels (position and size) so thin borders are always drawn
				local function SnapToPixels(frame)
					local px = OnePixel()
					local left, bottom, width, height = frame:GetLeft(), frame:GetBottom(), frame:GetWidth(), frame:GetHeight()
					if not (left and bottom) then return end
					local function Round(v) return math.floor(v / px + 0.5) * px end
					frame:ClearAllPoints()
					frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", Round(left), Round(bottom))
					frame:SetSize(Round(width), Round(height))
				end
				-- Attach the model viewer to the right side of the card, and keep the card and viewer on the screen together
				local function AttachViewer()
					local card, viewer = LeaPlusLC.IDCard, LeaPlusLC.IDViewer
					if not card or not viewer then return end
					local gap = PixelRound(8)
					viewer:ClearAllPoints()
					if viewer.offscreen then
						-- Switched off with the checkbox: kept loaded but off the screen, so ticking the box shows it straight away
						viewer:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", -4000, -4000)
						return
					end
					if viewer.fullscreen then
						-- Fullscreen: fill the whole screen (over the card)
						viewer:SetAllPoints(UIParent)
						return
					end
					viewer:SetPoint("BOTTOMLEFT", card, "BOTTOMRIGHT", gap, 0)
					if not viewer:IsShown() then return end
					-- Move the card if the viewer would go off the right or top of the screen
					local cardLeft, cardBottom = card:GetLeft(), card:GetBottom()
					if not cardLeft then return end
					local overRight = (cardLeft + card:GetWidth() + gap + viewer:GetWidth()) - UIParent:GetRight()
					local overTop = (cardBottom + viewer:GetHeight()) - UIParent:GetTop()
					if overRight > 0 or overTop > 0 then
						card:ClearAllPoints()
						card:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", math.max(0, cardLeft - math.max(0, overRight)), math.max(0, cardBottom - math.max(0, overTop)))
						SnapToPixels(card)
					end
				end
				-- Flat button in the ID card style (dark with an accent coloured border and text)
				local function FlatButton(parent, width, height, text)
					local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
					button:SetSize(width, height)
					button:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = OnePixel()})
					button:SetBackdropColor(1, 1, 1, 0.05)
					button.label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
					button.label:SetPoint("CENTER", button, "CENTER", 0, 0)
					button.label:SetText(text)
					button:SetScript("OnEnter", function(self) self:SetBackdropColor(1, 1, 1, 0.14) end)
					button:SetScript("OnLeave", function(self) self:SetBackdropColor(1, 1, 1, 0.05) end)
					button:SetScript("OnMouseDown", function(self) self.label:SetPoint("CENTER", self, "CENTER", 1, -1) end)
					button:SetScript("OnMouseUp", function(self) self.label:SetPoint("CENTER", self, "CENTER", 0, 0) end)
					function button:SetAccent(r, g, b)
						self:SetBackdropBorderColor(r, g, b, 0.7)
						self.label:SetTextColor(r, g, b)
					end
					function button:SetLabel(newText) self.label:SetText(newText) end
					button:SetAccent(1, 0.82, 0)
					return button
				end
				-- Model viewer: a 3D model (players, NPCs and wearable items) with flavour text
				-- The model is only ever changed while the viewer is showing, and changes that need the model wait until it has loaded
				local viewerAnims = {0, 4, 5, 143, 119, 26, 25, 27, 28, 108, 120, 51, 124, 52, 125, 126, 62, 63, 41, 42, 43, 44, 132, 38, 14, 115, 193, 48, 110, 109, 134, 197, 0} -- Same as Enhance dressup
				local function ShowViewer(info)
					local card = LeaPlusLC.IDCard
					local view = info and info.view
					local viewer = LeaPlusLC.IDViewer
					if not view then if viewer then viewer:Hide() end return end
					if not viewer then
						viewer = CreateFrame("Frame", nil, card, "BackdropTemplate")
						viewer:Hide()
						viewer:SetSize(PixelRound(380), PixelRound(520))
						viewer:SetPoint("BOTTOMLEFT", card, "BOTTOMRIGHT", PixelRound(8), 0)
						viewer:SetFrameStrata("FULLSCREEN_DIALOG")
						viewer:SetFrameLevel(card:GetFrameLevel() + 50) -- Above the card and its buttons
						viewer:EnableMouse(true)
						viewer:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = OnePixel()})
						viewer:SetBackdropColor(0.06, 0.06, 0.08, 0.96)
						-- Drawn into its own buffer, so 3D models open behind it (such as the character frame's model) cannot show through the model as a silhouette
						-- (set once here and left on, as turning it off again leaves the model blank)
						if viewer.SetIsFrameBuffer then viewer:SetIsFrameBuffer(true) end
						viewer.title = viewer:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
						viewer.title:SetPoint("TOPLEFT", viewer, "TOPLEFT", 14, -14)
						viewer.title:SetPoint("RIGHT", viewer, "RIGHT", -110, 0)
						viewer.title:SetJustifyH("LEFT")
						viewer.title:SetWordWrap(false)
						-- Gear button (takes equipped items off and puts them back on)
						viewer.gear = FlatButton(viewer, 86, 22, L["Hide gear"])
						viewer.gear:SetPoint("TOPRIGHT", viewer, "TOPRIGHT", -10, -10)
						-- Fullscreen button (shows the viewer over the whole screen, Escape or the button again puts it back)
						viewer.full = FlatButton(viewer, 86, 22, L["Exit fullscreen"])
						local exitWidth = viewer.full.label:GetStringWidth()
						viewer.full:SetLabel(L["Fullscreen"])
						viewer.full:SetWidth(math.max(exitWidth, viewer.full.label:GetStringWidth()) + 20) -- Wide enough for both labels
						viewer.full:SetScript("OnClick", function() viewer:SetFullscreen(not viewer.fullscreen) end)
						-- Place the fullscreen button left of the gear button (or in the corner when there is no gear button), and keep the title clear of them
						function viewer:LayoutButtons()
							-- Fullscreen button on the far right, then the gear button (players and items), then the scene button (fullscreen only)
							self.full:ClearAllPoints()
							self.full:SetPoint("TOPRIGHT", self, "TOPRIGHT", -10, -10)
							self.gear:ClearAllPoints()
							self.gear:SetPoint("RIGHT", self.full, "LEFT", -6, 0)
							local used = 10 + self.full:GetWidth() + (self.gear:IsShown() and (6 + self.gear:GetWidth()) or 0) + 14
							if self.sceneBtn then
								self.sceneBtn:ClearAllPoints()
								self.sceneBtn:SetPoint("RIGHT", self.gear:IsShown() and self.gear or self.full, "LEFT", -6, 0)
								if self.sceneBtn:IsShown() then used = used + 6 + self.sceneBtn:GetWidth() end
							end
							self.title:ClearAllPoints()
							self.title:SetPoint("TOPLEFT", self, "TOPLEFT", 14, -14)
							if self.fullscreen and self.sceneBtn then
								self.title:SetWidth(math.min(self.title.GetUnboundedStringWidth and self.title:GetUnboundedStringWidth() or self.title:GetStringWidth(), 320) + 2) -- Only as wide as the name (the flavour text follows it)
							else
								self.title:SetPoint("RIGHT", self, "RIGHT", -used, 0)
							end
						end
						viewer.gear:HookScript("OnShow", function() viewer:LayoutButtons() end)
						viewer.gear:HookScript("OnHide", function() viewer:LayoutButtons() end)
						-- Model area
						viewer.stage = viewer:CreateTexture(nil, "BORDER")
						viewer.stage:SetPoint("TOPLEFT", viewer, "TOPLEFT", 12, -42)
						viewer.stage:SetColorTexture(0, 0, 0, 0.45)
						-- Model frames: two dressing room models for players and items (one wearing gear, one without, so the gear button
						-- just swaps between them and nothing reloads or moves), and a plain model for NPCs and pets
						-- (creature models in a dressing room model can crash the game)
						viewer.dressModel = CreateFrame("DressUpModel", nil, viewer)
						viewer.nakedModel = CreateFrame("DressUpModel", nil, viewer)
						viewer.creatureModel = CreateFrame("PlayerModel", nil, viewer)
						viewer.dressModel.twin, viewer.nakedModel.twin = viewer.nakedModel, viewer.dressModel
						for void, model in ipairs({viewer.dressModel, viewer.nakedModel, viewer.creatureModel}) do
						if model.SetKeepModelOnHide then model:SetKeepModelOnHide(true) end -- Keep the model when it is hidden (for the gear swap)
						model:SetAllPoints(viewer.stage)
						model:EnableMouse(true)
						model:EnableMouseWheel(true)
						model:Hide()
						-- Run a function once the model has loaded (or straight away if it already has)
						function model:WhenLoaded(func)
							if self.loaded then C_Timer.After(0, function() if self.loaded and self:IsVisible() then func() end end) return end
							self.onLoaded = func
							C_Timer.After(0.3, function() -- In case the loaded event does not fire
								if self.onLoaded == func and self:IsVisible() then self.loaded = true self.onLoaded = nil func() end
							end)
						end
						model:SetScript("OnModelLoaded", function(self)
							self.loaded = true
							local func = self.onLoaded
							self.onLoaded = nil
							if func then C_Timer.After(0, function() if self.loaded and self:IsVisible() then func() end end) end -- Next frame, not in the middle of loading
						end)
						-- Left button turns, right button moves, middle button turns and tilts freely, mouse wheel zooms
						model:SetScript("OnMouseDown", function(self, btn)
							if btn == "LeftButton" then self.turning = GetCursorPosition() elseif btn == "RightButton" then self.panX, self.panY = GetCursorPosition() elseif btn == "MiddleButton" then self.freeX, self.freeY = GetCursorPosition() end
						end)
						model:SetScript("OnMouseUp", function(self, btn)
							if btn == "LeftButton" then self.turning = nil elseif btn == "RightButton" then self.panX, self.panY = nil, nil elseif btn == "MiddleButton" then self.freeX, self.freeY = nil, nil end
						end)
						model:SetScript("OnHide", function(self) self.turning, self.panX, self.panY, self.freeX, self.freeY = nil, nil, nil, nil, nil end)
						model:SetScript("OnUpdate", function(self, elapsed)
							if not self.loaded then return end
							local changed
							-- Smooth zoom (eases towards the zoom chosen with the mouse wheel by moving the model towards the camera)
							-- Camera distance functions are not used as they can crash the game while a model is loading
							local target = self.zoomTarget or 0
							if math.abs(target - (self.zoom or 0)) > 0.001 then
								self.zoom = (self.zoom or 0) + (target - (self.zoom or 0)) * math.min(1, elapsed * 10)
								self:SetPosition(self.zoom, self.offsetY or 0, self.offsetZ or 0)
								changed = true
							end
							if self.turning then
								local x = GetCursorPosition()
								self.facing = (self.facing or 0) + (x - self.turning) * 0.012
								self.turning = x
								self:SetFacing(self.facing)
								changed = true
							end
							if self.freeX then
								-- Middle button: left and right turns, up and down tilts
								local x, y = GetCursorPosition()
								self.facing = (self.facing or 0) + (x - self.freeX) * 0.012
								self.pitch = (self.pitch or 0) - (y - self.freeY) * 0.012
								self.freeX, self.freeY = x, y
								self:SetFacing(self.facing)
								if self.SetPitch then self:SetPitch(self.pitch) end
								changed = true
							end
							if self.panX then
								local x, y = GetCursorPosition()
								local step = 0.004 * math.max(0.3, 1 - (self.zoom or 0) * 0.3)
								self.offsetY = (self.offsetY or 0) + (x - self.panX) * step
								self.offsetZ = (self.offsetZ or 0) + (y - self.panY) * step
								self.panX, self.panY = x, y
								self:SetPosition(self.zoom or 0, self.offsetY, self.offsetZ)
								changed = true
							end
							-- Keep the other dressing room model (gear on or off) the same, so swapping gear does not move anything
							local twin = self.twin
							if changed and twin and twin.loaded then
								twin.facing, twin.pitch, twin.zoom, twin.zoomTarget, twin.offsetY, twin.offsetZ = self.facing, self.pitch, self.zoom, self.zoomTarget, self.offsetY, self.offsetZ
								twin:SetFacing(twin.facing or 0)
								if twin.SetPitch then twin:SetPitch(twin.pitch or 0) end
								twin:SetPosition(twin.zoom or 0, twin.offsetY or 0, twin.offsetZ or 0)
							end
						end)
						model:SetScript("OnMouseWheel", function(self, delta)
							if not self.loaded then return end
							self.zoomTarget = math.max(-1.5, math.min(2.5, (self.zoomTarget or 0) + delta * 0.3))
						end)
						end
						viewer.model = viewer.dressModel
						-- Controls button (pointing at it shows how to turn, move, tilt and zoom the model)
						viewer.hint = FlatButton(viewer, 70, 20, L["Controls"])
						viewer.hint:SetWidth(viewer.hint.label:GetStringWidth() + 20)
						viewer.hint:SetPoint("BOTTOMRIGHT", viewer.stage, "BOTTOMRIGHT", -10, 10)
						-- Controls popup (made the first time the button is pointed at)
						function viewer:ShowControls()
							local tip = self.controlsTip
							if not tip then
								tip = CreateFrame("Frame", nil, self, "BackdropTemplate")
								self.controlsTip = tip
								tip:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = OnePixel()})
								tip:SetBackdropColor(0.06, 0.06, 0.08, 0.98)
								tip.heading = tip:CreateFontString(nil, "OVERLAY", "GameFontNormal")
								tip.heading:SetPoint("TOPLEFT", tip, "TOPLEFT", 14, -12)
								tip.heading:SetText(L["Model controls"])
								local rows = {
									{L["Left-drag"], L["Turn"]},
									{L["Right-drag"], L["Move"]},
									{L["Middle-drag"], L["Turn and tilt"]},
									{L["Mouse wheel"], L["Zoom"]},
								}
								tip.keys, tip.actions = {}, {}
								local keyWidth, actionWidth = 0, 0
								for i, row in ipairs(rows) do
									local key = tip:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
									key:SetPoint("TOPLEFT", tip, "TOPLEFT", 14, -36 - (i - 1) * 18)
									key:SetText(row[1])
									local action = tip:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
									action:SetText(row[2])
									action:SetTextColor(0.8, 0.8, 0.8)
									tip.keys[i], tip.actions[i] = key, action
									keyWidth = math.max(keyWidth, key:GetStringWidth())
									actionWidth = math.max(actionWidth, action:GetStringWidth())
								end
								for i, action in ipairs(tip.actions) do
									action:SetPoint("LEFT", tip.keys[i], "LEFT", keyWidth + 18, 0)
								end
								tip:SetSize(math.max(tip.heading:GetStringWidth(), keyWidth + 18 + actionWidth) + 28, 36 + #rows * 18 + 6)
							end
							-- Colours follow the viewer (key names in the accent colour)
							local r, g, b = unpack(self.accent or {1, 0.82, 0})
							tip:SetBackdropBorderColor(r, g, b, 0.55)
							tip.heading:SetTextColor(r, g, b)
							for void, key in ipairs(tip.keys) do key:SetTextColor(r, g, b) end
							-- Above the button, lined up with its right edge
							tip:ClearAllPoints()
							tip:SetPoint("BOTTOMRIGHT", self.hint, "TOPRIGHT", 0, 6)
							tip:SetFrameLevel(self:GetFrameLevel() + 30)
							tip:Show()
						end
						local function HideControls() if viewer.controlsTip then viewer.controlsTip:Hide() end end
						viewer.hint:HookScript("OnEnter", function() viewer:ShowControls() end)
						viewer.hint:HookScript("OnLeave", HideControls)
						viewer.hint:HookScript("OnHide", HideControls)
						-- Waiting for a player (shown when they can no longer be found, the model loads when the mouse is over them again)
						viewer.waitText = viewer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
						viewer.waitText:SetPoint("LEFT", viewer.stage, "LEFT", 20, 0)
						viewer.waitText:SetPoint("RIGHT", viewer.stage, "RIGHT", -20, 0)
						viewer.waitText:SetWordWrap(true)
						viewer.waitText:Hide()
						viewer:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
						function viewer:CheckWaiting()
							if not self:IsShown() or self.waitGUID == nil then return end
							if not UnitExists("mouseover") then return end
							-- Match by GUID, or by name when the GUID cannot be read
							local guid = UnitGUID("mouseover")
							local match
							if guid and not (issecretvalue and issecretvalue(guid)) and self.waitGUID then
								match = guid == self.waitGUID
							else
								local name, realm = UnitName("mouseover")
								if name and not (issecretvalue and (issecretvalue(name) or (realm and issecretvalue(realm)))) then
									match = name == self.waitName or (realm and realm ~= "" and (name .. " " .. realm) == self.waitName)
								end
							end
							if match then
								local cardInfo = LeaPlusLC.IDCard and LeaPlusLC.IDCard.info
								if cardInfo and cardInfo.view and cardInfo.name == self.waitName then
									cardInfo.view.unit = "mouseover"
									cardInfo.view.fresh = true
									self.lastLoad = nil -- Load straight away
									cardInfo.openViewer = true
									ShowViewer(cardInfo)
									cardInfo.view.fresh = nil
									cardInfo.openViewer = nil
								end
							end
						end
						viewer:SetScript("OnEvent", function(self) self:CheckWaiting() end)
						-- Animation slider (same animations as Enhance dressup)
						-- Gear slot buttons (players and items): click one to take that piece off the model, click again to put it back on
						viewer.hiddenSlots, viewer.slotInfo, viewer.slotButtons = {}, {}, {}
						viewer.slotRow = CreateFrame("Frame", nil, viewer)
						viewer.slotRow:SetPoint("TOPLEFT", viewer.stage, "BOTTOMLEFT", 0, -8)
						viewer.slotRow:SetPoint("TOPRIGHT", viewer.stage, "BOTTOMRIGHT", 0, -8)
						viewer.slotRow:SetHeight(22)
						viewer.slotRow:Hide()
						local slotList = {{1, "HeadSlot"}, {3, "ShoulderSlot"}, {15, "BackSlot"}, {5, "ChestSlot"}, {4, "ShirtSlot"}, {19, "TabardSlot"}, {9, "WristSlot"}, {10, "HandsSlot"}, {6, "WaistSlot"}, {7, "LegsSlot"}, {8, "FeetSlot"}, {16, "MainHandSlot"}, {17, "SecondaryHandSlot"}, {18, "RangedSlot"}}
						for void, entry in ipairs(slotList) do
							local slotID, slotName = entry[1], entry[2]
							local ok, slotNumber, emptyTexture = pcall(GetInventorySlotInfo, slotName) -- Slots this game does not have are left out
							if ok and slotNumber then
								local button = CreateFrame("Button", nil, viewer.slotRow, "BackdropTemplate")
								button.slotID, button.slotName, button.emptyTexture = slotID, slotName, emptyTexture
								button.label = _G[strupper(slotName)] or slotName
								button:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = OnePixel()})
								button:SetBackdropColor(0, 0, 0, 0.6)
								button:SetBackdropBorderColor(1, 1, 1, 0.15)
								button.icon = button:CreateTexture(nil, "ARTWORK")
								button.icon:SetPoint("TOPLEFT", button, "TOPLEFT", OnePixel(), -OnePixel())
								button.icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -OnePixel(), OnePixel())
								button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
								button:SetScript("OnEnter", function(self)
									GameTooltip:SetOwner(self, "ANCHOR_TOP")
									GameTooltip:AddLine(self.label, 1, 1, 1)
									if not viewer.slotInfo[self.slotID] then
										GameTooltip:AddLine(L["Nothing to show in this slot"], 0.6, 0.6, 0.65)
									elseif viewer.gearOff then
										GameTooltip:AddLine(L["Click Show gear first"], 0.6, 0.6, 0.65)
									elseif viewer.hiddenSlots[self.slotID] then
										GameTooltip:AddLine(L["Click to show"], 0.6, 0.6, 0.65)
									else
										GameTooltip:AddLine(L["Click to hide"], 0.6, 0.6, 0.65)
									end
									GameTooltip:Show()
								end)
								button:SetScript("OnLeave", function() GameTooltip:Hide() end)
								button:SetScript("OnClick", function(self)
									local info = viewer.slotInfo[self.slotID]
									local model = viewer.dressModel
									if not info or viewer.gearOff or not model.loaded then return end
									if viewer.hiddenSlots[self.slotID] then
										-- Put it back on
										viewer.hiddenSlots[self.slotID] = nil
										if info.transmog and model.SetItemTransmogInfo then
											pcall(model.SetItemTransmogInfo, model, info.transmog, self.slotID)
										elseif info.link then
											pcall(model.TryOn, model, info.link, (self.slotID == 16 or self.slotID == 17) and strupper(self.slotName) or nil)
										end
									else
										-- Take it off
										viewer.hiddenSlots[self.slotID] = true
										pcall(model.UndressSlot, model, self.slotID)
									end
									viewer:UpdateSlots()
									if GameTooltip:IsOwned(self) then self:GetScript("OnEnter")(self) end
								end)
								tinsert(viewer.slotButtons, button)
							end
						end
						-- Show each button as worn, taken off or empty
						function viewer:UpdateSlots()
							local r, g, b = unpack(self.accent or {1, 0.82, 0})
							for void, button in ipairs(self.slotButtons) do
								local info = self.slotInfo[button.slotID]
								local hidden = self.hiddenSlots[button.slotID] and true or false
								local worn = info and not hidden and not self.gearOff
								button.icon:SetTexture((info and info.icon) or button.emptyTexture or 136528)
								button.icon:SetDesaturated(not worn)
								button.icon:SetAlpha(not info and 0.3 or worn and 1 or 0.45)
								if worn then button:SetBackdropBorderColor(r, g, b, 0.7) else button:SetBackdropBorderColor(1, 1, 1, 0.15) end
							end
						end
						-- Read what the model is wearing in each slot (so a piece can be put back on after it is taken off)
						function viewer:ReadSlots(model, unit)
							wipe(self.slotInfo)
							wipe(self.hiddenSlots)
							local GetIcon = (C_Item and C_Item.GetItemIconByID) or GetItemIcon
							for void, button in ipairs(self.slotButtons) do
								local slotID = button.slotID
								local info = {}
								if model.GetItemTransmogInfo then
									local ok, transmog = pcall(model.GetItemTransmogInfo, model, slotID)
									local appearanceID = ok and SafeTable(transmog) and Safe(transmog.appearanceID)
									if type(appearanceID) == "number" and appearanceID > 0 then
										info.transmog = transmog
										if C_TransmogCollection and C_TransmogCollection.GetSourceInfo then
											local source = SafeTable(C_TransmogCollection.GetSourceInfo(appearanceID))
											local itemID = source and Safe(source.itemID)
											if itemID and GetIcon then info.icon = Safe(GetIcon(itemID)) end
										end
									end
								end
								if unit and Safe(UnitExists(unit)) then
									info.link = Safe(GetInventoryItemLink(unit, slotID))
									if not info.icon then info.icon = Safe(GetInventoryItemTexture(unit, slotID)) end
								end
								if info.link and not info.icon and GetIcon then info.icon = Safe(GetIcon(info.link)) end
								if info.transmog or info.link then self.slotInfo[slotID] = info end
							end
							self:UpdateSlots()
						end
						-- Other players: the game does not always put every weapon on the model (such as the main hand of a dual wielder) until
						-- they have been inspected, so the weapons read by the card's own inspect are put on the model and on the slot buttons
						function viewer:ApplyInspectGear()
							local view = self.view
							if not self:IsShown() or not view or view.mode ~= "unit" or not view.isPlayer or not view.guid then return end
							local gear = LeaPlusLC.IDGear and LeaPlusLC.IDGear[view.guid]
							local model = self.dressModel
							if not gear or not model.loaded then return end
							local GetIcon = (C_Item and C_Item.GetItemIconByID) or GetItemIcon
							-- Weapons are put straight into their own hand slot as appearances (trying them on makes the game treat the player
							-- as unable to dual wield, so a weapon in one hand pushes out the other)
							local weapons = {}
							if model.SetItemTransmogInfo and C_TransmogCollection and C_TransmogCollection.GetItemInfo and ItemUtil and ItemUtil.CreateItemTransmogInfo then
								for void, slotID in ipairs({16, 17}) do
									if gear[slotID] then
										local ok, void, sourceID = pcall(C_TransmogCollection.GetItemInfo, gear[slotID])
										sourceID = ok and Safe(sourceID)
										if type(sourceID) == "number" and sourceID > 0 then
											local made, transmog = pcall(ItemUtil.CreateItemTransmogInfo, sourceID)
											if made and transmog then weapons[slotID] = transmog end
										end
									end
								end
							end
							local function Wield()
								if self.view ~= view or not model.loaded then return end
								for void, slotID in ipairs({16, 17}) do
									if weapons[slotID] and not self.hiddenSlots[slotID] then pcall(model.SetItemTransmogInfo, model, weapons[slotID], slotID) end
								end
							end
							if weapons[16] or weapons[17] then
								Wield()
								C_Timer.After(0.3, Wield) -- Again a moment later in case the game was still dressing the model
							end
							-- Fill in the slot buttons (weapons use the same appearances, so clicking to put one back on keeps both showing)
							for void, button in ipairs(self.slotButtons) do
								local slotID = button.slotID
								local link, info = gear[slotID], self.slotInfo[slotID]
								if link and (not info or not info.link or weapons[slotID]) then
									info = info or {}
									info.link = link
									if weapons[slotID] then info.transmog = weapons[slotID] end
									if not info.icon and GetIcon then info.icon = Safe(GetIcon(link)) end
									self.slotInfo[slotID] = info
								end
							end
							self:UpdateSlots()
						end
						-- Other players: the model is kept hidden (with a message) until their inspect has come back, then shown complete with both weapons,
						-- rather than showing the game's own version first and the weapons appearing a moment later
						function viewer:HoldModel(guid)
							self.holdGUID = guid
							self.holdID = (self.holdID or 0) + 1
							local holdID = self.holdID
							self.dressModel:SetAlpha(0)
							self.nakedModel:SetAlpha(0)
							self.waitText:SetText(RETRIEVING_DATA or SEARCH_LOADING_TEXT or "...")
							self.waitText:Show()
							-- Keep waiting while the inspect is on the way (up to 6 seconds), or while its reply is waiting for the player to be pointed at again
							local started = GetTime()
							local function Check()
								if self.holdID ~= holdID then return end
								local wait = LeaPlusLC.IDGearWait
								if wait and wait.guid == guid then
									self.waitText:SetFormattedText(L["Move your mouse over %s to show their model."], self.title:GetText() or "")
									C_Timer.After(0.5, Check)
									return
								end
								local card = LeaPlusLC.IDCard
								local pending = card and card:IsShown() and (card.inspectGUID == guid or card.talentsGUID == guid or card.gearReadingGUID == guid)
								if pending and GetTime() - started < 6 then C_Timer.After(0.5, Check) return end
								self:RevealModel()
							end
							C_Timer.After(1, Check)
						end
						function viewer:RevealModel()
							if not self.holdGUID then return end
							self.holdGUID = nil
							self.holdID = (self.holdID or 0) + 1
							self.dressModel:SetAlpha(1)
							self.nakedModel:SetAlpha(1)
							if self.waitGUID == nil then self.waitText:Hide() end
						end
						-- Show the model once its gear has been read (or once no inspect is on the way)
						function viewer:CheckReveal()
							local guid = self.holdGUID
							if not guid then return end
							local view = self.view
							if not self:IsShown() or not view or view.guid ~= guid then self:RevealModel() return end
							local gear = LeaPlusLC.IDGear and LeaPlusLC.IDGear[guid]
							local card = LeaPlusLC.IDCard
							local pending = card and card:IsShown() and (card.inspectGUID == guid or card.gearReadingGUID == guid or (LeaPlusLC.IDGearWait and LeaPlusLC.IDGearWait.guid == guid))
							if (gear and gear.complete) or not pending then
								local holdID = self.holdID
								C_Timer.After(0.1, function() if self.holdID == holdID then self:RevealModel() end end) -- Give the weapons a moment to be drawn
							end
						end
						viewer:HookScript("OnHide", function(self) self:RevealModel() end)
						viewer.animLabel = viewer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
						viewer.animLabel:SetPoint("TOPLEFT", viewer.stage, "BOTTOMLEFT", 2, -14)
						viewer.animLabel:SetText(L["Animation"])
						LeaPlusLC["IDViewerAnim"] = 1 -- Not saved
						LeaPlusLC:MakeSL(viewer, "IDViewerAnim", "", 1, #viewerAnims - 1, 1, 0, 0, "%.0f")
						viewer.anim = LeaPlusCB["IDViewerAnim"]
						viewer.anim:ClearAllPoints()
						viewer.anim:SetPoint("LEFT", viewer.animLabel, "RIGHT", 12, 0)
						viewer.anim:SetScript("OnEnter", nil)
						viewer.anim:SetScript("OnLeave", nil)
						if viewer.anim.SetObeyStepOnDrag then viewer.anim:SetObeyStepOnDrag(true) end -- Move in whole steps while dragging
						viewer.anim:HookScript("OnValueChanged", function(self, setting)
							setting = math.floor(setting + 0.5)
							-- Only change the animation when the step changes (restarting it on every small movement makes it jerky)
							if setting == viewer.lastAnim then return end
							local model = viewer.model
							if model and model.loaded and model:IsVisible() and viewerAnims[setting] then
								viewer.lastAnim = setting
								model:SetAnimation(viewerAnims[setting])
							end
						end)
						-- Flavour text
						viewer.text = viewer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
						viewer.text:SetPoint("TOPLEFT", viewer.animLabel, "BOTTOMLEFT", 0, -14)
						viewer.text:SetPoint("RIGHT", viewer, "RIGHT", -14, 0)
						viewer.text:SetJustifyH("LEFT")
						viewer.text:SetWordWrap(true)
						viewer.text:SetTextColor(1, 0.82, 0)
						-- Keep the model area filling the frame above the slider and text
						function viewer:Layout()
							local full = self.fullscreen and self.sceneBtn
							-- Flavour text: on one line along the top in fullscreen, normal lines under the slider otherwise
							local raw = self.flavourRaw
							if raw then self.text:SetText(full and (raw:gsub("\n", "     ")) or raw) end
							local count = #self.slotButtons
							local gap = 2
							if full then
								-- Fullscreen: the gear slot buttons, a shorter animation slider and the flavour text go along the top, so the model area reaches the bottom
								self.stage:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -12, 12)
								self.stageBottom = 12
								local size = 22
								self.slotRow:ClearAllPoints()
								self.slotRow:SetSize(math.max(1, count * (size + gap) - gap), size)
								self.slotRow:SetPoint("RIGHT", self.sceneBtn, "LEFT", -20, 0)
								for i, button in ipairs(self.slotButtons) do
									button:SetSize(size, size)
									button:ClearAllPoints()
									button:SetPoint("LEFT", self.slotRow, "LEFT", (i - 1) * (size + gap), 0)
								end
								self.anim:SetWidth(120)
								self.anim:ClearAllPoints()
								self.anim:SetPoint("RIGHT", self.slotRow:IsShown() and self.slotRow or self.sceneBtn, "LEFT", -40, 0) -- Room for the number after the slider
								self.animLabel:ClearAllPoints()
								self.animLabel:SetPoint("RIGHT", self.anim, "LEFT", -10, 0)
								self.text:ClearAllPoints()
								self.text:SetPoint("LEFT", self.title, "RIGHT", 16, 0)
								self.text:SetPoint("RIGHT", self.animLabel, "LEFT", -20, 0)
								self.text:SetWordWrap(false)
								-- Controls button in the bottom-right corner of the model area
								self.hint:ClearAllPoints()
								self.hint:SetPoint("BOTTOMRIGHT", self.stage, "BOTTOMRIGHT", -10, 10)
							else
								-- Controls button in the bottom-right corner of the model area (same as fullscreen)
								self.hint:ClearAllPoints()
								self.hint:SetPoint("BOTTOMRIGHT", self.stage, "BOTTOMRIGHT", -10, 10)
								-- Normal: gear slot buttons, then the animation slider, then the flavour text, all under the model area
								self.slotRow:ClearAllPoints()
								self.slotRow:SetPoint("TOPLEFT", self.stage, "BOTTOMLEFT", 0, -8)
								self.slotRow:SetPoint("TOPRIGHT", self.stage, "BOTTOMRIGHT", 0, -8)
								self.slotRow:SetHeight(22)
								-- The label was attached to the slider in fullscreen, so free it first (the slider is then attached to the label)
								self.animLabel:ClearAllPoints()
								self.animLabel:SetPoint("TOPLEFT", self.stage, "BOTTOMLEFT", 2, -14)
								self.anim:ClearAllPoints()
								self.anim:SetPoint("LEFT", self.animLabel, "RIGHT", 12, 0)
								self.text:ClearAllPoints()
								self.text:SetPoint("TOPLEFT", self.animLabel, "BOTTOMLEFT", 0, -14)
								self.text:SetPoint("RIGHT", self, "RIGHT", -14, 0)
								self.text:SetWordWrap(true)
								local text = Safe(self.text:GetText())
								local textHeight = (text and text ~= "") and (self.text:GetStringHeight() + 14) or 0
								local slotsHeight = self.slotRow:IsShown() and 30 or 0
								self.stage:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -12, 44 + textHeight + slotsHeight)
								self.stageBottom = 44 + textHeight + slotsHeight
								-- Animation slider goes under the gear slot buttons when they are showing
								self.animLabel:ClearAllPoints()
								self.animLabel:SetPoint("TOPLEFT", slotsHeight > 0 and self.slotRow or self.stage, "BOTTOMLEFT", 2, -14)
								-- Gear slot buttons share the width of the row (centred)
								if count > 0 then
									local rowWidth = self:GetWidth() - 24
									local size = math.max(10, math.min(22, math.floor((rowWidth - gap * (count - 1)) / count)))
									local left = math.floor((rowWidth - (size * count + gap * (count - 1))) / 2)
									for i, button in ipairs(self.slotButtons) do
										button:SetSize(size, size)
										button:ClearAllPoints()
										button:SetPoint("LEFT", self.slotRow, "LEFT", left + (i - 1) * (size + gap), 0)
									end
								end
								self.anim:SetWidth(math.min(500, math.max(80, self:GetWidth() - 24 - self.animLabel:GetStringWidth() - 70)))
							end
							if self.LayoutScene then self:LayoutScene() end
						end
						viewer:SetScript("OnSizeChanged", function(self) self:Layout() end)
						-- Gear button
						viewer.gear:SetScript("OnClick", function()
							local from = viewer.model
							local to = from and from.twin
							if not (from and to and from.loaded and to.loaded) then return end
							viewer.gearOff = not viewer.gearOff
							-- Swap to the other model, with the same turn, position, zoom and animation (nothing reloads, so nothing moves)
							to.facing, to.pitch, to.zoom, to.zoomTarget, to.offsetY, to.offsetZ = from.facing, from.pitch, from.zoom, from.zoomTarget, from.offsetY, from.offsetZ
							to:Show()
							to:SetFacing(to.facing or 0)
							if to.SetPitch then to:SetPitch(to.pitch or 0) end
							to:SetPosition(to.zoom or 0, to.offsetY or 0, to.offsetZ or 0)
							local setting = math.floor(viewer.anim:GetValue() + 0.5)
							if viewerAnims[setting] then to:SetAnimation(viewerAnims[setting]) end
							from:Hide()
							viewer.model = to
							viewer.gear:SetLabel(viewer.gearOff and L["Show gear"] or L["Hide gear"])
							viewer:UpdateSlots()
						end)
						viewer:Layout()
						-- Fullscreen on or off (the same viewer is made to fill the screen, so the model, slider and gear buttons all keep working)
						function viewer:SetFullscreen(on)
							on = on and true or false
							if on == (self.fullscreen or false) then return end
							local card = LeaPlusLC.IDCard
							if on then
								self.normalWidth = self:GetWidth()
								self.fullscreen = true
								-- In fullscreen the viewer goes under the card's layer (so the card can be shown over it when pointing at the name)
								-- and the card waits off the screen (still open, so Escape, the keys and the model updates all work as normal)
								self:SetParent(UIParent)
								self:SetFrameStrata("FULLSCREEN")
								card.savedPoints = {}
								for i = 1, card:GetNumPoints() do card.savedPoints[i] = {card:GetPoint(i)} end
								self:HideCard()
							else
								self.fullscreen = nil
								self:EndHoverCard() -- In case the card is showing from the name
								-- Back on top of the card, and the card back where it was
								self:SetParent(card)
								self:SetFrameStrata("FULLSCREEN_DIALOG")
								self:SetFrameLevel(card:GetFrameLevel() + 50)
								if card.savedPoints and card.savedPoints[1] then
									card:ClearAllPoints()
									for void, point in ipairs(card.savedPoints) do card:SetPoint(unpack(point)) end
								end
								card.savedPoints = nil
								card:SetClampedToScreen(true)
								self:ClearAllPoints()
								self:SetSize(self.normalWidth or PixelRound(380), self.normalHeight or PixelRound(520))
							end
							if on then self.randomScene = nil end -- A new random loading screen each time
							self:SetBackdropColor(0.06, 0.06, 0.08, on and 1 or 0.96) -- Solid in fullscreen so nothing behind shows through
							self.full:SetLabel(on and L["Exit fullscreen"] or L["Fullscreen"])
							AttachViewer()
							self:Layout()
							if not on then
								-- Back to normal size: fit the height to the flavour text again (it was on one line in fullscreen)
								local text = Safe(self.text:GetText())
								self.normalHeight = PixelRound(42 + 380 + 44 + (self.slotRow:IsShown() and 30 or 0) + ((text and text ~= "") and (self.text:GetStringHeight() + 14) or 0))
								self:SetHeight(self.normalHeight)
								AttachViewer()
							end
							self:ApplyScene()
							self:ApplyLevels()
							self:LayoutButtons()
						end
						-- Background scenes for fullscreen (plain colours, racial dressing room backgrounds and class talent backgrounds)
						-- Each picture is made of pieces: position and size of each piece in the picture, then its texture coordinates
						local loadLayout = {w = 1024, h = 768, fit = true, pieces = {{0, 0, 1024, 768, 0, 1, 0, 1}}} -- Loading screens (4:3, shown whole: fit = true, or topCrop = 0.27 to fill the area and crop the logo off)
						local wideLayout = {w = 1600, h = 900, pieces = {{0, 0, 1600, 900, 0, 1, 0, 1}}} -- Widescreen loading screens (the game stretches the whole picture across a widescreen, so it is shown at 16:9)
						local letterboxLayout = {w = 1600, h = 900, pieces = {{0, 0, 1600, 900, 0.157, 0.843, 0.157, 0.843}}} -- WoW Forever loading screens (16:9 with black bands painted across the top and bottom): the bands are cropped off and the sides are trimmed to match, so they fill the same 16:9 space as the other loading screens
						local logoLayout = {w = 1600, h = 900, pieces = {{0, 0, 1600, 900, 0.22, 0.78, 0.29, 0.85}}} -- Legion and Battle for Azeroth loading screens: the logo and the frame painted across the top and bottom are cropped off, and the sides are trimmed to match, so they fill the same 16:9 space
						-- Check a picture is in the game (by its file ID, or by trying to load it)
						local probe = viewer:CreateTexture(nil, "BACKGROUND")
						probe:Hide()
						local function FileExists(path)
							if GetFileIDFromPath then return GetFileIDFromPath(path) ~= nil end
							local loaded = probe:SetTexture(path)
							probe:SetTexture(nil)
							if loaded == false then return false end
							return true
						end
						local scenes, sceneByKey = {}, {}
						local function AddScene(scene)
							-- Some pictures have more than one possible file name, the first one in the game is used
							if scene.candidates then
								for void, base in ipairs(scene.candidates) do
									if FileExists(base) then scene.files = {base} break end
								end
								if not scene.files then return end
							end
							if scene.files and not FileExists(scene.files[1]) then return end -- Scenes this game does not have are left out
							tinsert(scenes, scene)
							if scene.key then sceneByKey[scene.key] = scene end
						end
						sceneByKey.random = {key = "random", name = L["Random"]} -- Not in the list: used when no scene has been chosen (a different loading screen each time fullscreen is opened)
						AddScene({key = "none", name = L["None"]})
						AddScene({header = L["Patterns"]})
						AddScene({key = "grey", name = L["Studio grey"], gradient = {0.10, 0.10, 0.11, 0.42, 0.42, 0.45}})
						AddScene({key = "night", name = L["Night sky"], gradient = {0.10, 0.16, 0.32, 0.01, 0.02, 0.06}})
						AddScene({key = "sunset", name = L["Sunset"], gradient = {0.85, 0.45, 0.20, 0.18, 0.06, 0.10}})
						-- Loading screens grouped by expansion (file names from the community listfile, only widescreen ones are used)
						-- Each entry: zone ID for the game's own zone name (or nil), English name, then the files to try in order
						-- A file marked wide, letterbox or logo is widescreen (letterbox and logo ones are cropped); any other file is a 4:3 one, and only its widescreen version (Wide on the end) is used if the game has one
						local function ExpansionName(number, english) return _G["EXPANSION_NAME" .. number] or L[english] end
						local function AddLoadingScreen(screen)
							local zoneName = screen[1] and GetRealZoneText and Safe(GetRealZoneText(screen[1]))
							if type(zoneName) ~= "string" or zoneName == "" then zoneName = L[screen[2]] end
							local base, files, layout = "Interface\\Glues\\LoadingScreens\\"
							for void, candidate in ipairs(screen[3]) do
								local file, kind = candidate[1], candidate[2]
								if kind == "wide" or kind == "letterbox" or kind == "logo" then
									if FileExists(base .. file) then files, layout = {base .. file}, kind == "letterbox" and letterboxLayout or kind == "logo" and logoLayout or wideLayout end
								elseif FileExists(base .. file .. "Wide") then
									files, layout = {base .. file .. "Wide"}, wideLayout
								end
								if files then break end
							end
							if files then AddScene({key = "load" .. screen[3][1][1], name = zoneName .. (screen[4] or ""), layout = layout, files = files, isLoad = true}) end
						end
						for void, group in ipairs({
							{L["WoW Forever"], {
								{1, "Kalimdor", {{"Camelot160\\Main\\loadscreen_camelot_kalimdor", "letterbox"}}},
								{0, "Eastern Kingdoms", {{"Camelot160\\Main\\loadscreen_camelot_easternkingdom", "letterbox"}}},
								{nil, "Dalaran", {{"Camelot160\\Main\\loadscreen_camelot_dalaran", "letterbox"}}},
								{nil, "Old Ironforge", {{"Camelot160\\Main\\loadscreen_camelot_oldironforge", "letterbox"}}},
								{nil, "Ruins of Lordaeron", {{"Camelot160\\Main\\loadscreen_camelot_ruinsoflordaeron", "letterbox"}}},
								{nil, "Zephras Isle", {{"Camelot160\\Main\\loadscreen_camelot_zephrasisle", "letterbox"}}},
								{nil, "Excavation", {{"Camelot160\\Main\\loadscreen_camelot_excavation", "letterbox"}}},
							}},
							{ExpansionName(6, "Legion"), {
								{nil, "Broken Isles", {{"LoadingScreen_BrokenIsles_Wide", "logo"}}},
								{nil, "Mardum", {{"loadingscreen_mardumwide", "logo"}}},
								{nil, "Death Knight Order Hall", {{"LoadScreen_DeathKnightOrderHall_wide", "logo"}}},
								{nil, "Demon Hunter Order Hall", {{"LoadingScreen_DemonHunterOrderHall_wide", "logo"}}},
								{nil, "Druid Order Hall", {{"LoadingScreen_DruidOrderHall_Wide", "logo"}}},
								{nil, "Hunter Order Hall", {{"LoadScreen_HunterOrderHall_wide", "logo"}}},
								{nil, "Monk Order Hall", {{"LoadScreen_MonkOrderHall_Wide_NoLOGO", "logo"}}},
								{nil, "Priest Order Hall", {{"LoadScreen_PriestOrderHall_wide", "logo"}}},
								{nil, "Warlock Order Hall", {{"LoadScreen_WarlockOrderHall_wide", "logo"}}},
								{nil, "Mage Artifact", {{"LoadScreen_MageArtifact", "logo"}}},
								{nil, "Shaman Artifact", {{"Loadingscreen_shamanartifact_wide", "logo"}}},
								{nil, "Niskara", {{"Loadingscreen_Niskara_wide", "logo"}}},
								{nil, "Light's Hope Chapel", {{"LoadingScreen_LightHopesChapel_wide", "logo"}}},
								{nil, "Eye of Azshara", {{"LoadScreen_NagaDungeon", "logo"}}},
								{nil, "Darkheart Thicket", {{"LoadingScreen_NightmareDungeon_wide", "logo"}}},
								{nil, "Neltharion's Lair", {{"LoadingScreen_NeltharionsLair_wide", "logo"}}},
								{nil, "Halls of Valor", {{"LoadingScreen_HallsofValor_wide", "logo"}}},
								{nil, "Helheim", {{"LoadingScreen_Helheimship_wide", "logo"}}},
								{nil, "Black Rook Hold", {{"LoadingScreen_BlackrookHold_wide", "logo"}}},
								{nil, "Vault of the Wardens", {{"LoadingScreen_VaultOfTheWardens_wide", "logo"}}},
								{nil, "Violet Hold", {{"Loadingscreen_VioletHold_wide", "logo"}}},
								{nil, "Court of Stars", {{"LoadScreen_SuramarCityDungeon", "logo"}}},
								{nil, "Suramar Catacombs", {{"LoadScreen_SuramarCatacombs_wide", "logo"}}},
								{nil, "Return to Karazhan", {{"LoadingScreen_ReturntoKarazhan", "logo"}}},
								{nil, "Cathedral of Eternal Night", {{"LoadScreen_TombOfSargerasDUNGEON_wide", "logo"}}},
								{nil, "The Emerald Nightmare", {{"LoadScreen_EmeraldNightmareRaid_wide", "logo"}}},
								{nil, "Emerald Dreamway", {{"LoadingScreen_EmeraldDreamway_wide", "logo"}}},
								{nil, "Trial of Valor", {{"LoadingScreen_TrialsofValor", "logo"}}},
								{nil, "The Nighthold", {{"LoadScreen_SuramarRaid", "logo"}}},
								{nil, "Tomb of Sargeras", {{"LoadScreen_TombOfSargerasRAID_wide", "logo"}}},
								{nil, "Argus", {{"LoadingScreen_Argus3", "logo"}}},
								{nil, "Krokuun", {{"LoadingScreen_Krokuun_wide", "logo"}}},
								{nil, "Mac'Aree", {{"LoadingScreen_MacAree_wide", "logo"}}},
								{nil, "Seat of the Triumvirate", {{"LoadingScreen_ArgusDungeon_Widescreen", "logo"}}},
								{nil, "Antorus, the Burning Throne", {{"LoadingScreen_ArgusRaid_Widescreen", "logo"}}},
								{nil, "Chromie's Scenario", {{"LoadScreen_ChromieScenario_wide", "logo"}}},
								{nil, "Black Rook Hold Arena", {{"LoadingScreen_BlackrookHoldArena_wide", "logo"}}},
								{nil, "Blade's Edge Arena", {{"LoadingScreen_BladesEdgeArena_wide", "logo"}}},
								{nil, "Nagrand Arena", {{"LoadingScreen_NagrandArena_wide", "logo"}}},
								{nil, "Val'sharah Arena", {{"LoadingScreen_ArenaValSharah_wide", "logo"}}},
								{529, "Arathi Basin", {{"Loadingscreen_ArathiBasinwinter", "logo"}}, " (winter)"},
							}},
							{ExpansionName(7, "Battle for Azeroth"), {
								{489, "Warsong Gulch", {{"loadscreen_warsonggulch_update_wide", "logo"}}},
								{529, "Arathi Basin", {{"loadingscreen_arathibasin_update_wide", "logo"}}},
							}},
						}) do
							AddScene({header = group[1]})
							for void, screen in ipairs(group[2]) do AddLoadingScreen(screen) end
						end
						-- Leave out headings with nothing under them
						for i = #scenes, 1, -1 do
							if scenes[i].header and (not scenes[i + 1] or scenes[i + 1].header) then tremove(scenes, i) end
						end
						-- Chosen scene (saved)
						if LeaPlusLC.IDViewerScene == nil then LeaPlusLC.IDViewerScene = LeaPlusDB and LeaPlusDB["IDViewerScene"] or "random" end
						-- Scene area: fills the model area, clipped to it, under the models
						viewer.sceneFrame = CreateFrame("Frame", nil, viewer)
						viewer.sceneFrame:SetAllPoints(viewer.stage)
						viewer.sceneFrame:SetClipsChildren(true)
						viewer.sceneFrame:Hide()
						viewer.sceneCanvas = CreateFrame("Frame", nil, viewer.sceneFrame)
						-- Softening: the picture is drawn several times, each slightly offset and blended evenly, which smooths out the blocks of low quality pictures
						local softOffsets = {{0, 0}, {1, 0}, {-1, 0}, {0, 1}, {0, -1}, {1, 1}, {-1, -1}, {1, -1}, {-1, 1}}
						viewer.sceneLayers = {}
						for k = 1, #softOffsets do
							viewer.sceneLayers[k] = {}
							for i = 1, 4 do viewer.sceneLayers[k][i] = viewer.sceneCanvas:CreateTexture(nil, "BACKGROUND", nil, k - 9) end -- Later copies on top
						end
						viewer.sceneDim = viewer.sceneCanvas:CreateTexture(nil, "OVERLAY")
						viewer.sceneDim:SetAllPoints(viewer.sceneCanvas)
						viewer.sceneDim:SetColorTexture(0, 0, 0, 1)
						viewer.sceneGradient = viewer.sceneFrame:CreateTexture(nil, "BACKGROUND")
						viewer.sceneGradient:SetAllPoints()
						viewer.sceneGradient:SetTexture("Interface\\Buttons\\WHITE8X8")
						-- Text in the model area is moved to its own layer so it stays above the scene and the models
						viewer.overlay = CreateFrame("Frame", nil, viewer)
						viewer.overlay:SetAllPoints(viewer)
						viewer.hint:SetParent(viewer.overlay)
						viewer.waitText:SetParent(viewer.overlay)
						-- Scene button (only shown in fullscreen)
						viewer.sceneBtn = FlatButton(viewer, 200, 22, "")
						viewer.sceneBtn.label:SetWidth(188)
						viewer.sceneBtn.label:SetWordWrap(false)
						viewer.sceneBtn:Hide()
						viewer.sceneBtn:SetScript("OnClick", function() viewer:ToggleScenePopup() end)
						viewer.sceneBtn:HookScript("OnShow", function() viewer:LayoutButtons() end)
						viewer.sceneBtn:HookScript("OnHide", function() viewer:LayoutButtons() end)
						-- Keep the layers in order: scene, then models, then text and buttons, then the scene list
						function viewer:ApplyLevels()
							local base = self:GetFrameLevel()
							self.sceneFrame:SetFrameLevel(base + 1)
							self.sceneCanvas:SetFrameLevel(base + 2)
							for void, model in ipairs({self.dressModel, self.nakedModel, self.creatureModel}) do model:SetFrameLevel(base + 5) end
							self.overlay:SetFrameLevel(base + 6)
							self.gear:SetFrameLevel(base + 7)
							self.full:SetFrameLevel(base + 7)
							self.sceneBtn:SetFrameLevel(base + 7)
							self.hint:SetFrameLevel(base + 7)
							if self.scenePopup then self.scenePopup:SetFrameLevel(base + 20) end
						end
						-- Size the scene picture to fill the model area (edges are cropped so nothing is stretched)
						function viewer:LayoutScene()
							local scene = self.currentScene
							if not scene or not scene.layout or not self.sceneFrame:IsShown() then return end
							local w, h = self:GetWidth() - 24, self:GetHeight() - 42 - (self.stageBottom or 44)
							if w <= 0 or h <= 0 then return end
							local layout = scene.layout
							local scale = math.min(w / layout.w, h / layout.h) -- Never zoomed in: the whole picture is always shown (dark bars where it does not reach)
							self.sceneCanvas:SetSize(layout.w * scale, layout.h * scale)
							self.sceneCanvas:ClearAllPoints()
							self.sceneCanvas:SetPoint("CENTER", self.sceneFrame, "CENTER", 0, 0)
							local spread = scene.soft and (scale * 0.75) or 0 -- About one picture pixel
							for k, layer in ipairs(self.sceneLayers) do
								local used = k == 1 or scene.soft
								for i, piece in ipairs(layer) do
									local spec = layout.pieces[i]
									if used and spec then
										piece:ClearAllPoints()
										piece:SetPoint("TOPLEFT", self.sceneCanvas, "TOPLEFT", spec[1] * scale + softOffsets[k][1] * spread, -spec[2] * scale + softOffsets[k][2] * spread)
										piece:SetSize(spec[3] * scale, spec[4] * scale)
									end
								end
							end
						end
						-- Show the chosen scene (fullscreen only)
						function viewer:ApplyScene()
							local scene = sceneByKey[self.previewKey or LeaPlusLC.IDViewerScene] or sceneByKey.random -- Hovered scene in the list, or the chosen one (a saved scene no longer in the list uses the default)
							local label = scene.name
							if scene.key == "random" then
								-- Pick a loading screen (a new one each time fullscreen is opened, or when Random is chosen again)
								if not self.randomScene then
									local choices = {}
									for void, entry in ipairs(scenes) do if entry.isLoad then tinsert(choices, entry) end end
									self.randomScene = choices[1] and choices[math.random(#choices)] or sceneByKey.none
								end
								scene = self.randomScene
								label = L["Random"] .. ": " .. scene.name
							end
							self.currentScene = scene
							self.sceneBtn:SetLabel(L["Scene"] .. ": " .. label)
							self.sceneBtn:SetShown(self.fullscreen and true or false)
							if not self.fullscreen and self.scenePopup then self.scenePopup:Hide() end
							local show = self.fullscreen and scene.key ~= "none"
							self.sceneFrame:SetShown(show and true or false)
							if not show then return end
							if scene.gradient then
								local g = scene.gradient
								self.sceneCanvas:Hide()
								self.sceneGradient:Show()
								self.sceneGradient:SetGradient("VERTICAL", CreateColor(g[1], g[2], g[3], 1), CreateColor(g[4], g[5], g[6], 1))
							else
								self.sceneGradient:Hide()
								self.sceneCanvas:Show()
								for k, layer in ipairs(self.sceneLayers) do
									local used = k == 1 or scene.soft
									for i, piece in ipairs(layer) do
										local spec = scene.layout.pieces[i]
										if used and spec then
											piece:SetTexture(scene.files[i], nil, nil, "TRILINEAR") -- Smooth filtering when the picture is enlarged
											piece:SetTexCoord(spec[5], spec[6], spec[7], spec[8])
											piece:SetAlpha(1 / k) -- Each copy blended in evenly with the ones under it
											piece:Show()
										else
											piece:Hide()
										end
									end
								end
								self.sceneDim:SetAlpha(scene.soft and 0.25 or 0) -- Softened pictures are darkened a little so the model stands out
								self:LayoutScene()
							end
						end
						-- Scene list (Leatrix's own list, not the game's dropdown menus)
						function viewer:ToggleScenePopup()
							local popup = self.scenePopup
							if popup and popup:IsShown() then popup:Hide() return end
							if not popup then
								popup = CreateFrame("Frame", nil, self, "BackdropTemplate")
								self.scenePopup = popup
								popup:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = OnePixel()})
								popup:SetBackdropColor(0.06, 0.06, 0.08, 0.98)
								popup:SetBackdropBorderColor(1, 1, 1, 0.15)
								popup:EnableMouse(true)
								popup.rows = {}
								local rowHeight, colWidth = 18, 190
								local maxRows = math.max(10, math.floor((self:GetHeight() - 70) / rowHeight)) -- Columns nearly as tall as the screen, so the list is as narrow as possible
								local col, row, mostRows = 0, 0, 0
								for i, scene in ipairs(scenes) do
									-- Start a new column when this one is full (a heading always has at least one entry under it)
									if row >= maxRows or (scene.header and row >= maxRows - 1) then col, row = col + 1, 0 end
									if scene.header then
										local text = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
										text:SetPoint("TOPLEFT", popup, "TOPLEFT", 14 + col * colWidth, -13 - row * rowHeight)
										text:SetText(scene.header)
									else
										local button = CreateFrame("Button", nil, popup)
										button:SetSize(colWidth - 8, rowHeight)
										button:SetPoint("TOPLEFT", popup, "TOPLEFT", 8 + col * colWidth, -10 - row * rowHeight)
										button.selected = button:CreateTexture(nil, "BACKGROUND")
										button.selected:SetAllPoints()
										button.selected:SetColorTexture(1, 1, 1, 0.12)
										button:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
										button:GetHighlightTexture():SetVertexColor(1, 1, 1, 0.08)
										button.text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
										button.text:SetPoint("LEFT", button, "LEFT", 6, 0)
										button.text:SetPoint("RIGHT", button, "RIGHT", -4, 0)
										button.text:SetJustifyH("LEFT")
										button.text:SetWordWrap(false)
										button.text:SetText(scene.name)
										button.key = scene.key
										-- Pointing at a scene shows it straight away (pointing at Random shows another random loading screen)
										button:SetScript("OnEnter", function(self)
											if viewer.previewKey == self.key and self.key ~= "random" then return end
											viewer.previewKey = self.key
											if self.key == "random" then viewer.randomScene = nil end
											viewer:ApplyScene()
										end)
										-- Clicking keeps the scene being shown
										button:SetScript("OnClick", function(self)
											LeaPlusLC.IDViewerScene = self.key
											if LeaPlusDB then LeaPlusDB["IDViewerScene"] = self.key end
											popup.confirmed = true
											popup:Hide()
										end)
										tinsert(popup.rows, button)
									end
									row = row + 1
									mostRows = math.max(mostRows, row)
								end
								popup:SetSize((col + 1) * colWidth + 8, mostRows * rowHeight + 20)
								popup:SetPoint("TOPRIGHT", self, "TOPRIGHT", -10, -36) -- Far right, just under the buttons
								-- Like the game's own menus, the list stays open until something else is clicked (or Escape is pressed)
								popup:RegisterEvent("GLOBAL_MOUSE_DOWN")
								popup:SetScript("OnEvent", function(self, event)
									if event == "GLOBAL_MOUSE_DOWN" and self:IsShown() and not self:IsMouseOver() and not viewer.sceneBtn:IsMouseOver() then self:Hide() end
								end)
								-- Scenes only change while pointing at the list: moving the pointer off it puts the chosen scene back (until one is clicked)
								popup:SetScript("OnUpdate", function(self)
									if viewer.previewKey and not self:IsMouseOver() then
										viewer.previewKey = nil
										viewer.randomScene = self.randomBefore
										viewer:ApplyScene()
									end
								end)
								-- Closing the list keeps a clicked scene, otherwise goes back to the scene that was showing before
								popup:SetScript("OnHide", function()
									if not popup.confirmed then viewer.randomScene = popup.randomBefore end
									popup.confirmed, popup.randomBefore = nil, nil
									viewer.previewKey = nil
									viewer:ApplyScene()
								end)
							end
							for void, button in ipairs(popup.rows) do button.selected:SetShown(button.key == LeaPlusLC.IDViewerScene or (button.key == "random" and not sceneByKey[LeaPlusLC.IDViewerScene])) end
							popup.confirmed, popup.randomBefore = nil, self.randomScene -- Remember the random loading screen in case nothing is clicked
							self:ApplyLevels()
							popup:Show()
						end
						viewer:ApplyLevels()
						-- Fullscreen: the card waits off the screen, and pointing at the name shows it just under the name
						function viewer:HideCard()
							local card = LeaPlusLC.IDCard
							card:SetClampedToScreen(false) -- Otherwise the game pulls it back onto the screen (into the bottom-left corner)
							card:ClearAllPoints()
							card:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", -4000, -4000)
						end
						viewer.titleHover = CreateFrame("Frame", nil, viewer)
						viewer.titleHover:SetAllPoints(viewer.title)
						viewer.titleHover:EnableMouse(true)
						-- Highlight behind the name while pointing at it (fullscreen only, so it is clear the name shows the card)
						viewer.titleHover.highlight = viewer:CreateTexture(nil, "ARTWORK") -- On the viewer itself so it sits behind the name
						viewer.titleHover.highlight:SetPoint("TOPLEFT", viewer.titleHover, "TOPLEFT", -6, 4)
						viewer.titleHover.highlight:SetPoint("BOTTOMRIGHT", viewer.titleHover, "BOTTOMRIGHT", 6, -4)
						viewer.titleHover.highlight:SetColorTexture(1, 1, 1, 0.12)
						viewer.titleHover.highlight:Hide()
						-- The card shown from the name is for reading only: the buff list, close button, 3D model box, hints and clicks are all left out
						local function CardControls(card)
							return {card.close, card.modelCheck, card.modelCheck.label, card.hint, card.hint2, LeaPlusLC.AuraPicker}
						end
						local function PlainCard(card, plain)
							if plain then
								card.plainHidden = {}
								for i, control in ipairs(CardControls(card)) do
									if control and control:IsShown() then card.plainHidden[i] = true control:Hide() end
								end
							elseif card.plainHidden then
								for i, control in ipairs(CardControls(card)) do
									if control and card.plainHidden[i] then control:Show() end
								end
								card.plainHidden = nil
							end
							card:EnableMouse(not plain)
							card.edit:EnableMouse(not plain)
						end
						viewer.titleHover:SetScript("OnEnter", function()
							if not viewer.fullscreen or viewer.cardShowing then return end
							viewer.titleHover.highlight:Show()
							local card = LeaPlusLC.IDCard
							PlainCard(card, true)
							card:ClearAllPoints()
							card:SetPoint("TOPLEFT", viewer.title, "BOTTOMLEFT", 8, -20)
							card:SetClampedToScreen(true)
							card:Raise()
							viewer.cardShowing, viewer.cardAway = true, 0
						end)
						-- The card goes as soon as the pointer leaves the name (and everything on it comes back for when fullscreen ends)
						function viewer:EndHoverCard()
							if not self.cardShowing then return end
							self.cardShowing = nil
							self.titleHover.highlight:Hide()
							PlainCard(LeaPlusLC.IDCard, false)
							if self.fullscreen then self:HideCard() end
						end
						-- The card stays while the pointer is over the name or the card, and goes a short moment after it leaves both
						viewer.titleHover:SetScript("OnUpdate", function(self, elapsed)
							if not viewer.cardShowing then return end
							if self:IsMouseOver() or LeaPlusLC.IDCard:IsMouseOver() then
								viewer.cardAway = 0
							else
								viewer.cardAway = viewer.cardAway + elapsed
								if viewer.cardAway > 0.3 then viewer:EndHoverCard() end
							end
						end)
						viewer:HookScript("OnHide", function(self) if self.fullscreen then self:SetFullscreen(false) end end)
						viewer:LayoutButtons()
						LeaPlusLC.IDViewer = viewer
					end
					-- Nothing changes on the model unless the viewer is showing (or being opened now)
					if not info.openViewer and not viewer:IsShown() then return end
					-- Do not change models more than about three times a second (pressing the key quickly loads the last one)
					local now = GetTime()
					if viewer.lastLoad and now - viewer.lastLoad < 0.35 then
						viewer.pendingInfo = info
						info.openViewer = true
						if not viewer.pendingTimer then
							viewer.pendingTimer = true
							C_Timer.After(0.35 - (now - viewer.lastLoad), function()
								viewer.pendingTimer = nil
								local pending = viewer.pendingInfo
								viewer.pendingInfo = nil
								if pending and LeaPlusLC.IDCard and LeaPlusLC.IDCard:IsShown() and LeaPlusLC.IDCard.info == pending then ShowViewer(pending) end
							end)
						end
						return
					end
					viewer.lastLoad = now
					-- Choose the model frames (NPCs and pets use the plain model, players and items use the two dressing room models)
					local useCreature = view.mode == "unit" and not view.isPlayer
					local models = useCreature and {viewer.creatureModel} or {viewer.dressModel, viewer.nakedModel}
					for void, other in ipairs(useCreature and {viewer.dressModel, viewer.nakedModel} or {viewer.creatureModel}) do
						other:Hide()
						other.loaded, other.onLoaded = false, nil
					end
					-- Find the unit again by its GUID (the mouse may have moved since the card was shown)
					local unit
					if view.mode == "unit" then
						if view.guid and issecretvalue and issecretvalue(view.guid) then view.guid = nil end
						-- Shown at the same moment as the card: use the card's own unit (searching again can fail for new characters)
						if view.fresh and view.unit and UnitExists(view.unit) then unit = view.unit end
						if not unit and view.guid then
							local tokens = {"mouseover", view.unit or "mouseover", "target", "focus", "targettarget", "pet", "party1", "party2", "party3", "party4"}
							for i = 1, 40 do tinsert(tokens, "nameplate" .. i) end
							if IsInRaid() then for i = 1, 40 do tinsert(tokens, "raid" .. i) end end
							for void, token in ipairs(tokens) do
								local tokenGUID = UnitExists(token) and UnitGUID(token)
								if tokenGUID and not (issecretvalue and issecretvalue(tokenGUID)) and tokenGUID == view.guid then unit = token break end
							end
						end
					end
					-- Show the viewer first, then load the model
					local r, g, b = unpack(info.color or {1, 0.82, 0})
					viewer:SetBackdropBorderColor(r, g, b, 0.55)
					viewer.gear:SetAccent(r, g, b)
					viewer.hint:SetAccent(r, g, b)
					viewer.accent = {r, g, b}
					viewer.title:SetText(info.name or "")
					if info.nameColor then viewer.title:SetTextColor(unpack(info.nameColor)) else viewer.title:SetTextColor(1, 1, 1) end
					viewer.flavourRaw = view.text or ""
					viewer.text:SetText(view.text or "")
					if info.offscreen ~= nil then viewer.offscreen = info.offscreen end
					viewer.slotRow:SetShown(not useCreature and viewer.dressModel.UndressSlot ~= nil) -- Gear slot buttons for players and items
					viewer:Show()
					do
						local text = view.text
						viewer.normalHeight = PixelRound(42 + 380 + 44 + (viewer.slotRow:IsShown() and 30 or 0) + ((text and text ~= "") and (viewer.text:GetStringHeight() + 14) or 0))
						if not viewer.fullscreen then viewer:SetHeight(viewer.normalHeight) end
					end
					AttachViewer()
					viewer:Layout()
					viewer.view = view
					viewer.gearOff = (view.mode == "item") -- Items are shown on your character with your own gear off
					viewer.gear:SetLabel(viewer.gearOff and L["Show gear"] or L["Hide gear"])
					viewer.gear:SetShown(not useCreature) -- NPCs and pets have no gear to change
					wipe(viewer.slotInfo) wipe(viewer.hiddenSlots) viewer:UpdateSlots() -- Filled in once the model has loaded
					viewer:LayoutButtons()
					viewer:RevealModel() -- Start from a shown model (it is hidden again below for players whose inspect is on the way)
					-- A player who cannot be found right now: wait until the mouse is over them again
					if view.mode == "unit" and not unit and not view.npcID then
						viewer.waitGUID = view.guid or false
						viewer.waitName = info.name
						for void, m in ipairs({viewer.dressModel, viewer.nakedModel, viewer.creatureModel}) do m:Hide() m.loaded = false end
						viewer.hint:Hide()
						viewer.gear:Hide()
						viewer.waitText:SetFormattedText(L["Move your mouse over %s to show their model."], info.name or "")
						viewer.waitText:Show()
						-- Also check a few times a second, as the game can be slow to register the character under the mouse
						if not viewer.waitTicker then
							viewer.waitTicker = C_Timer.NewTicker(0.2, function(ticker)
								if not viewer:IsShown() or viewer.waitGUID == nil then ticker:Cancel() viewer.waitTicker = nil return end
								viewer:CheckWaiting()
							end)
						end
						return
					end
					-- Cannot be seen (too far away, offline and so on): do not load a model (it can make the game pause), just say so
					if view.mode == "unit" and unit and not Safe(UnitIsVisible(unit)) then
						viewer.waitGUID = nil
						for void, m in ipairs({viewer.dressModel, viewer.nakedModel, viewer.creatureModel}) do m:Hide() m.loaded = false end
						viewer.hint:Hide()
						viewer.gear:Hide()
						viewer.waitText:SetFormattedText(L["No model is available for %s right now."], info.name or "")
						viewer.waitText:Show()
						return
					end
					viewer.waitGUID = nil
					viewer.waitText:Hide()
					viewer.hint:Show()
					if view.mode == "unit" and view.isPlayer and unit and view.guid and not Safe(UnitIsUnit(unit, "player")) then viewer:HoldModel(view.guid) end
					viewer.loadID = (viewer.loadID or 0) + 1 -- Changes from an earlier model are ignored
					local loadID = viewer.loadID
					viewer.lastAnim = nil
					-- The model shown first (items start with your gear off)
					local active = useCreature and viewer.creatureModel or (viewer.gearOff and viewer.nakedModel or viewer.dressModel)
					viewer.model = active
					for void, model in ipairs(models) do
						model.loaded, model.onLoaded = false, nil
						model.facing, model.zoom, model.zoomTarget, model.turning, model.panX, model.panY, model.offsetY, model.offsetZ = 0, 0, 0, nil, nil, nil, 0, 0
						model.pitch, model.freeX, model.freeY = 0, nil, nil
						local function Finish()
							if not model:IsVisible() or viewer.loadID ~= loadID then return end
							model:SetFacing(0)
							if model.SetPitch then model:SetPitch(0) end
							model:SetPosition(0, 0, 0)
							if model == viewer.nakedModel and model.Undress then model:Undress() end
							if view.mode == "item" and view.link then model:TryOn(view.link) end
							-- Both dressing room models are loaded while showing (safest), then the one not in use is hidden
							if model == viewer.dressModel then
								viewer:ReadSlots(model, (view.mode == "unit" and unit) or "player")
								viewer:ApplyInspectGear()
								viewer:CheckReveal()
							end
							if model ~= viewer.model then model:Hide() end
						end
						model:Show()
						if view.mode == "unit" and unit then
							model:SetUnit(unit)
						elseif view.mode == "unit" then
							model:SetCreature(tonumber(view.npcID))
						else
							model:SetUnit("player")
						end
						model:WhenLoaded(Finish)
					end
					viewer.anim:SetValue(1)
				end
				-- ID card: shows the icon, name, ID and Wowhead link for what is under the mouse
				local function ShowIDCard(info)
					-- Leave out anything the game hides, so the card never shows or measures a hidden value
					info.name, info.sub, info.note, info.id, info.url, info.icon, info.unit = Safe(info.name, info.sub, info.note, info.id, info.url, info.icon, info.unit)
					if info.view then
						local view = info.view
						view.text, view.icon, view.link, view.guid, view.npcID, view.unit = Safe(view.text, view.icon, view.link, view.guid, view.npcID, view.unit)
					end
					local card = LeaPlusLC.IDCard
					if not card then
						card = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
						card:Hide()
						card:SetSize(480, 140)
						card:SetPoint("TOP", UIParent, "BOTTOM", 0, UIParent:GetHeight() * 0.28) -- Lower part of the screen, above the action bars
						SnapToPixels(card)
						card:SetFrameStrata("FULLSCREEN_DIALOG")
						card:SetFrameLevel(5000)
						card:SetClampedToScreen(true)
						card:EnableMouse(true)
						card:SetScript("OnMouseDown", function(self, btn) if btn == "RightButton" then self:Hide() end end)
						card:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = OnePixel()})
						card:SetBackdropColor(0.06, 0.06, 0.08, 0.96)
						-- Soft glow along the top in the accent colour
						card.glow = card:CreateTexture(nil, "BORDER")
						card.glow:SetPoint("TOPLEFT", card, "TOPLEFT", 1, -1)
						card.glow:SetPoint("TOPRIGHT", card, "TOPRIGHT", -1, -1)
						card.glow:SetHeight(70)
						card.glow:SetTexture("Interface\\Buttons\\WHITE8X8")
						-- Icon with a thin accent border
						card.iconBorder = card:CreateTexture(nil, "ARTWORK")
						card.iconBorder:SetSize(58, 58)
						card.iconBorder:SetPoint("TOPLEFT", card, "TOPLEFT", 20, -16)
						card.icon = card:CreateTexture(nil, "OVERLAY")
						card.icon:SetPoint("TOPLEFT", card.iconBorder, "TOPLEFT", 2, -2)
						card.icon:SetPoint("BOTTOMRIGHT", card.iconBorder, "BOTTOMRIGHT", -2, 2)
						-- 3D portrait for players and NPCs (a plain model framed on the face, over the flat portrait)
						card.portraitBg = card:CreateTexture(nil, "ARTWORK", nil, 2) -- Dark backdrop behind the 3D portrait (instead of the round flat portrait)
						card.portraitBg:SetAllPoints(card.icon)
						card.portraitBg:SetTexture("Interface\\Buttons\\WHITE8X8")
						card.portraitBg:SetGradient("VERTICAL", CreateColor(0.03, 0.03, 0.04, 1), CreateColor(0.14, 0.14, 0.17, 1))
						card.portraitBg:Hide()
						card.portrait = CreateFrame("PlayerModel", nil, card)
						card.portrait:SetAllPoints(card.icon)
						card.portrait:Hide()
						card.portrait:SetScript("OnModelLoaded", function(self)
							local id = self.loadID
							-- Frame the face on the next frame (never in the middle of loading)
							C_Timer.After(0, function()
								if self.loadID == id and self:IsVisible() then
									self:SetPortraitZoom(1)
									self:SetPosition(0, 0, 0)
									self:SetFacing(0)
								end
							end)
						end)
						-- Type (top right), name and details
						card.kind = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
						card.kind:SetPoint("TOPRIGHT", card, "TOPRIGHT", -36, -16)
						card.title = card:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
						card.title:SetPoint("TOPLEFT", card.iconBorder, "TOPRIGHT", 14, -4)
						card.title:SetPoint("RIGHT", card.kind, "LEFT", -10, 0)
						card.title:SetJustifyH("LEFT")
						card.title:SetWordWrap(false)
						card.sub = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
						card.sub:SetPoint("TOPLEFT", card.title, "BOTTOMLEFT", 0, -8)
						card.sub:SetPoint("RIGHT", card, "RIGHT", -16, 0)
						card.sub:SetJustifyH("LEFT")
						card.sub:SetWordWrap(false)
						card.sub:SetTextColor(0.62, 0.62, 0.66)
						-- Details line (guild, item level, sell price, rewards and so on), it can wrap onto more lines
						card.detail = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
						card.detail:SetPoint("TOPLEFT", card.sub, "BOTTOMLEFT", 0, -6)
						card.detail:SetWidth(372)
						card.detail:SetJustifyH("LEFT")
						card.detail:SetWordWrap(true)
						card.detail:SetTextColor(0.78, 0.78, 0.82)
						card.talents = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
						card.talents:SetWidth(372)
						card.talents:SetJustifyH("LEFT")
						card.talents:SetWordWrap(false)
						-- Add a part to the details line (parts that arrive later, such as item level from an inspect, are added too)
						function card:AddDetail(text)
							if not text or text == "" then return end
							tinsert(self.detailParts, text)
							self.detail:SetText(table.concat(self.detailParts, "    "))
							self:Relayout()
						end
						-- Item level for other players has its own place in the details, so a waiting message can be shown there and replaced
						-- once the item level is read (nil removes it)
						function card:SetItemLevelDetail(text)
							if text == "" then text = nil end
							local index = self.itemLevelPart
							if index and self.detailParts[index] then
								if text then self.detailParts[index] = text else tremove(self.detailParts, index) self.itemLevelPart = nil end
							elseif text then
								tinsert(self.detailParts, text)
								self.itemLevelPart = #self.detailParts
							else
								return
							end
							self.detail:SetText(table.concat(self.detailParts, "    "))
							self:Relayout()
						end
						-- Place the lines, the link box and set the card height to fit the text
						function card:Relayout()
							local hasDetail = #self.detailParts > 0
							self.detail:SetShown(hasDetail)
							self.talents:ClearAllPoints()
							self.talents:SetPoint("TOPLEFT", hasDetail and self.detail or self.sub, "BOTTOMLEFT", 0, -6)
							self.talents:SetShown(self.talentsReserved)
							local textBottom = 20 + (self.title:GetStringHeight() or 20) + 8 + (self.sub:GetStringHeight() or 12)
							if hasDetail then textBottom = textBottom + 6 + (self.detail:GetStringHeight() or 12) end
							if self.talentsReserved then textBottom = textBottom + 6 + math.max(10, self.talents:GetStringHeight() or 10) end
							local contentBottom = math.max(74, textBottom)
							self.box:ClearAllPoints()
							self.box:SetPoint("TOPLEFT", self, "TOPLEFT", 20, -(contentBottom + 14))
							self.box:SetPoint("RIGHT", self, "RIGHT", -16, 0)
							self:SetHeight(PixelRound(self.url and (contentBottom + 14 + 28 + 24) or (contentBottom + 26)))
						end
						-- Close button
						card.close = FlatButton(card, 22, 22, "X")
						card.close:SetPoint("TOPRIGHT", card, "TOPRIGHT", -10, -10)
						card.close:SetScript("OnClick", function() card:Hide() end)
						-- Link box
						card.box = CreateFrame("Frame", nil, card, "BackdropTemplate")
						card.box:SetPoint("TOPLEFT", card, "TOPLEFT", 20, -88)
						card.box:SetPoint("RIGHT", card, "RIGHT", -16, 0)
						card.box:SetHeight(28)
						card.box:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = OnePixel()})
						card.box:SetBackdropColor(0, 0, 0, 0.6)
						card.box:SetBackdropBorderColor(1, 1, 1, 0.12)
						card.edit = CreateFrame("EditBox", nil, card.box)
						card.edit:SetPoint("TOPLEFT", card.box, "TOPLEFT", 10, 0)
						card.edit:SetPoint("BOTTOMRIGHT", card.box, "BOTTOMRIGHT", -10, 0)
						card.edit:SetFontObject("ChatFontNormal")
						card.edit:SetTextColor(0.82, 0.88, 1)
						card.edit:SetAutoFocus(false)
						card.edit:SetAltArrowKeyMode(true)
						if card.edit.SetHighlightColor then card.edit:SetHighlightColor(0, 0, 0, 0) end -- The link is selected (so CTRL/C copies it) but the selection is not shown
						-- The link box's own text (and its blinking cursor) is pushed out of sight, and the link is shown as plain text instead
						card.edit:SetTextInsets(5000, 0, 0, 0)
						card.edit:SetTextColor(0, 0, 0, 0)
						card.urlText = card.box:CreateFontString(nil, "OVERLAY", "ChatFontNormal")
						card.urlText:SetPoint("LEFT", card.box, "LEFT", 10, 0)
						card.urlText:SetPoint("RIGHT", card.box, "RIGHT", -10, 0)
						card.urlText:SetJustifyH("LEFT")
						card.urlText:SetWordWrap(false)
						card.urlText:SetTextColor(0.82, 0.88, 1)
						-- Hints
						card.hint = card:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
						card.hint:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 22, 10) -- Same level as the right-click hint
						-- Checkbox to show or hide the model viewer (only shown for things with a 3D model, the choice is saved)
						card.modelCheck = CreateFrame("Button", nil, card, "BackdropTemplate")
						card.modelCheck:SetSize(PixelRound(11), PixelRound(11))
						card.modelCheck:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 22, 11)
						card.modelCheck:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = OnePixel()})
						card.modelCheck:SetBackdropColor(0, 0, 0, 0.6)
						card.modelCheck.tick = card.modelCheck:CreateTexture(nil, "OVERLAY")
						card.modelCheck.tick:SetPoint("TOPLEFT", card.modelCheck, "TOPLEFT", PixelRound(2), -PixelRound(2))
						card.modelCheck:SetHitRectInsets(-2, -80, -4, -4) -- The label can be clicked too
						card.modelCheck.tick:SetPoint("BOTTOMRIGHT", card.modelCheck, "BOTTOMRIGHT", -PixelRound(2), PixelRound(2))
						card.modelCheck.label = card:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
						card.modelCheck.label:SetPoint("LEFT", card.modelCheck, "RIGHT", 6, 0)
						card.modelCheck.label:SetText(L["3D model"])
						function card.modelCheck:Update()
							local on = LeaPlusLC.IDModelOn
							self.tick:SetShown(on)
							self.label:SetTextColor(on and 0.85 or 0.5, on and 0.85 or 0.5, on and 0.85 or 0.5)
						end
						card.modelCheck:SetScript("OnEnter", function(self) self.label:SetTextColor(1, 1, 1) end)
						card.modelCheck:SetScript("OnLeave", function(self) self:Update() end)
						card.modelCheck:SetScript("OnClick", function(self)
							LeaPlusLC.IDModelOn = not LeaPlusLC.IDModelOn
							if LeaPlusDB then LeaPlusDB["IDModelOn"] = LeaPlusLC.IDModelOn end
							self:Update()
							local viewer = LeaPlusLC.IDViewer
							if card.info then card.info.offscreen = not LeaPlusLC.IDModelOn end
							if viewer and viewer:IsShown() then
								-- Already loaded, so just move it on or off the screen
								viewer.offscreen = not LeaPlusLC.IDModelOn
								AttachViewer()
							elseif LeaPlusLC.IDModelOn and card.info and card.info.view then
								card.info.openViewer = true
								ShowViewer(card.info)
								card.info.openViewer = nil
							end
						end)
						card.hint2 = card:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
						card.hint2:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -18, 10)
						card.hint2:SetText(L["Right-click to close"])
						-- Keep the link unchanged and selected (CTRL/C copies it and closes the card)
						local function Reselect() card.edit:SetText(card.url or "") card.edit:HighlightText() end
						card.edit:SetScript("OnChar", Reselect)
						-- Put the link straight back if anything changes it (such as CTRL/X cutting it or pasting over it)
						card.edit:SetScript("OnTextChanged", function(self, userInput)
							if userInput and self:GetText() ~= (card.url or "") then Reselect() end
						end)
						local function IsCtrlKey(key) return key == "LCTRL" or key == "RCTRL" or key == "LMETA" or key == "RMETA" end
						card.edit:SetScript("OnKeyUp", function(self, key)
							Reselect()
							-- Letting go of Ctrl gives the keyboard back to the game (when Leatrix is watching for Ctrl)
							if card.ctrlFocus and IsCtrlKey(key) then card.ctrlFocus = nil self:ClearFocus() end
						end)
						-- Holding Ctrl gives the link box the keyboard so CTRL/C copies the link (the Ctrl watcher is made when Leatrix Plus loads)
						-- Clicking the link box does not take the keyboard (only holding Ctrl does), so the character can still be moved
						card.edit:SetScript("OnEditFocusGained", function(self)
							if not card.ctrlFocus then self:ClearFocus() end
						end)
						card.edit:SetScript("OnMouseUp", function(self) self:HighlightText() end)
						card.edit:SetScript("OnEnterPressed", function(self) self:HighlightText() end)
						card.edit:SetScript("OnEscapePressed", function() local viewer = LeaPlusLC.IDViewer if viewer and viewer.scenePopup and viewer.scenePopup:IsShown() then viewer.scenePopup:Hide() elseif viewer and viewer.fullscreen then viewer:SetFullscreen(false) else card:Hide() end end)
						card.edit:SetScript("OnKeyDown", function(self, key)
							if key == "C" and (IsControlKeyDown() or IsMetaKeyDown()) then
								card.hint:SetText("|cff40ff40" .. L["Copied to clipboard."] .. "|r")
								C_Timer.After(0.4, function() card:Hide() end)
								return
							end
							-- The link box has the keyboard, so pass the info card key binding through (shows whatever is now under the mouse)
							local combo = (IsAltKeyDown() and "ALT-" or "") .. (IsControlKeyDown() and "CTRL-" or "") .. (IsShiftKeyDown() and "SHIFT-" or "") .. ((IsMetaKeyDown and IsMetaKeyDown()) and "META-" or "") .. key
							if LeaPlusLC["ShowInfoCards"] == "On" and LeaPlusLC["InfoCardKey"] ~= "" and combo == LeaPlusLC["InfoCardKey"] then
								ShowInfoCard()
								-- If no new card was shown (such as pointing at a mailbox), the link box still has the keyboard, so give it back now
								if card.ctrlFocus then card.ctrlFocus = nil self:ClearFocus() end
								return
							end
							-- Any other key (not Ctrl itself) gives the keyboard back so the next press reaches the game
							if card.ctrlFocus and not IsCtrlKey(key) and key ~= "LSHIFT" and key ~= "RSHIFT" and key ~= "LALT" and key ~= "RALT" then
								card.ctrlFocus = nil
								self:ClearFocus()
							end
						end)
						-- Fade in
						card.fade = card:CreateAnimationGroup()
						local fadeIn = card.fade:CreateAnimation("Alpha")
						fadeIn:SetFromAlpha(0)
						fadeIn:SetToAlpha(1)
						fadeIn:SetDuration(0.15)
						card:SetScript("OnShow", function() card.fade:Play() end)
						-- The link box only keeps the keyboard while Ctrl is held (letting go of Ctrl is not always seen by the link box, so check every frame)
						card:SetScript("OnUpdate", function(self)
							if self.ctrlFocus and not (IsControlKeyDown() or (IsMetaKeyDown and IsMetaKeyDown())) then
								self.ctrlFocus = nil
								if self.edit:HasFocus() then self.edit:ClearFocus() end
							end
						end)
						-- Closing the card always gives the keyboard back to the game
						card:SetScript("OnHide", function(self)
							local viewer = LeaPlusLC.IDViewer
							if viewer and viewer.fullscreen then viewer:SetFullscreen(false) end -- The viewer is not inside the card in fullscreen, so end fullscreen with the card
							self.ctrlFocus = nil
							if self.edit:HasFocus() then self.edit:ClearFocus() end
						end)
						LeaPlusLC.IDCard = card
					end
					-- Back to the normal lines (a card for a hidden aura uses its own lines, see ShowHiddenAuraCard)
					card.hiddenMode = nil
					card.title:Show()
					card.sub:Show()
					card.urlText:Show()
					card.edit:Show()
					if card.hiddenTitle then
						card.hiddenTitle:Hide()
						card.hiddenSub:Hide()
						card.hiddenUrlText:Hide()
					end
					-- Accent colour
					local r, g, b = unpack(info.color or {1, 0.82, 0})
					card.iconBorder:SetColorTexture(r, g, b, 0.9)
					card:SetBackdropBorderColor(r, g, b, 0.55)
					card.glow:SetVertexColor(1, 1, 1, 1)
					card.glow:SetGradient("VERTICAL", CreateColor(r, g, b, 0), CreateColor(r, g, b, 0.16))
					-- Icon or portrait
					card.icon:SetTexture(nil)
					-- (round portraits and class icons are cropped to the square inside the circle, to match the square 3D portrait)
					local function InnerSquare(left, right, top, bottom)
						local w, h = right - left, bottom - top
						return left + w * 0.15, right - w * 0.15, top + h * 0.15, bottom - h * 0.15
					end
					if info.unit and UnitExists(info.unit) then
						SetPortraitTexture(card.icon, info.unit)
						card.icon:SetTexCoord(InnerSquare(0, 1, 0, 1))
					elseif info.icon == "Interface\\TargetingFrame\\UI-Classes-Circles" and info.iconCoords then
						card.icon:SetTexture(info.icon)
						card.icon:SetTexCoord(InnerSquare(unpack(info.iconCoords)))
					else
						card.icon:SetTexture(info.icon or 134400)
						card.icon:SetTexCoord(unpack(info.iconCoords or {0.08, 0.92, 0.08, 0.92}))
					end
					-- Text
					card.kind:SetText(strupper(info.kind or ""))
					card.kind:SetTextColor(r, g, b)
					card.title:SetText(info.name or "")
					if info.nameColor then card.title:SetTextColor(unpack(info.nameColor)) else card.title:SetTextColor(1, 1, 1) end
					card.sub:SetText(info.sub or (L["ID"] .. " |cffffffff" .. tostring(info.id or "") .. "|r" .. (info.note and ("    " .. info.note) or "")))
					card.hint:SetText(L["Press CTRL/C to copy"])
					card.talents:SetText("")
					card.talentsReserved = info.talents and true or false
					card.detailParts = {}
					card.itemLevelPart = nil
					card.detail:SetText("")
					for void, part in ipairs(info.details or {}) do if part and not IsSecret(part) and part ~= "" then tinsert(card.detailParts, part) end end
					card.detail:SetText(table.concat(card.detailParts, "    "))
					card.inspectGUID = nil
					card.talentsGUID = nil
					card.upgradeGUID = nil
					card.itemLevelGUID = nil
					card.gearReadingGUID = nil
					LeaPlusLC.IDGearWait = nil -- A reply kept for the last player is no longer needed
					-- Model viewer (only for things that can be shown as a 3D model, kept up to date while it is open)
					if info.view and info.view.mode == "icon" then info.view = nil end
					card.info = info
					card.close:SetAccent(r, g, b)
					-- Link (some cards, such as players on Forever, have no link)
					card.url = info.url
					card.edit:SetText(info.url or "")
					card.urlText:SetText(info.url or "")
					card.box:SetShown(info.url ~= nil)
					card.hint:SetShown(info.url ~= nil)
					-- Model viewer checkbox (the copy hint moves along to make room for it)
					card.modelCheck:SetShown(info.view ~= nil)
					card.modelCheck.label:SetShown(info.view ~= nil)
					card.modelCheck:SetBackdropBorderColor(r, g, b, 0.8)
					card.modelCheck.tick:SetColorTexture(r, g, b, 1)
					card.modelCheck:Update()
					card.hint:ClearAllPoints()
					if info.view then
						card.hint:SetPoint("LEFT", card.modelCheck.label, "RIGHT", 18, 0)
					else
						card.hint:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 22, 10)
					end
					card.hint2:Show()
					card:Relayout()
					card:Show()
					if not card.snapped then card.snapped = true SnapToPixels(card) end -- Line up with screen pixels when first shown
					-- 3D portrait (loaded now the card is showing, for players and NPCs)
					local portrait = card.portrait
					portrait.loadID = (portrait.loadID or 0) + 1
					-- (only for characters you can see: loading a model for someone far away can make the game pause)
					if info.unit and UnitExists(info.unit) and Safe(UnitIsVisible(info.unit)) and not (info.iconCoords) then
						portrait:Show()
						portrait:SetUnit(info.unit)
					elseif info.view and info.view.npcID and not info.view.isPlayer then
						portrait:Show()
						portrait:SetCreature(tonumber(info.view.npcID))
					else
						portrait:Hide()
					end
					-- With a 3D portrait, show a plain dark backdrop instead of the round flat portrait underneath
					card.icon:SetShown(not portrait:IsShown())
					card.portraitBg:SetShown(portrait:IsShown())
					if portrait:IsShown() then
						-- In case the loaded event does not fire (such as a model that was already loaded)
						local id = portrait.loadID
						C_Timer.After(0.3, function()
							if portrait.loadID == id and portrait:IsVisible() then
								portrait:SetPortraitZoom(1)
								portrait:SetPosition(0, 0, 0)
								portrait:SetFacing(0)
							end
						end)
					end
					-- Update the model viewer now the card is showing
					local viewer = LeaPlusLC.IDViewer
					if info.view then
						-- Things with a 3D model open the model viewer, loaded now while the mouse is still over them
						-- (off the screen when the 3D model box is unticked, so ticking it shows the model straight away)
						info.offscreen = not LeaPlusLC.IDModelOn
						info.openViewer = true
						info.view.fresh = true
						ShowViewer(info)
						info.view.fresh = nil
						info.openViewer = nil
					elseif viewer and viewer:IsShown() then
						viewer:Hide()
					end
					card:Raise()
					card.ctrlFocus = nil
					card.edit:ClearFocus() -- The keyboard stays with the game (holding Ctrl gives it to the link box)
					card.edit:HighlightText()
				end
				-- Card for a buff or debuff the game has hidden from addons (such as in combat or a PvP match)
				-- The hidden name, ID and link are never read, only passed straight to the game to show them. They use their own lines,
				-- as anything that has shown a hidden value stays hidden (and the normal lines are measured for the layout).
				-- The link cannot be copied, as the game does not let a link box show a hidden value.
				local function ShowHiddenAuraCard(auraID, auraName)
					-- Set up the card as normal with blank lines (these set the layout), then show the hidden values over them
					ShowIDCard({kind = L["Aura"], name = " ", sub = " ", url = " ", icon = 134400, color = {0.6, 0.6, 0.65}})
					local card = LeaPlusLC.IDCard
					if not card.hiddenTitle then
						card.hiddenTitle = card:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
						card.hiddenTitle:SetPoint("TOPLEFT", card.title, "TOPLEFT", 0, 0)
						card.hiddenTitle:SetPoint("RIGHT", card.title, "RIGHT", 0, 0)
						card.hiddenTitle:SetJustifyH("LEFT")
						card.hiddenTitle:SetWordWrap(false)
						card.hiddenTitle:SetTextColor(1, 1, 1)
						card.hiddenSub = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
						card.hiddenSub:SetPoint("TOPLEFT", card.sub, "TOPLEFT", 0, 0)
						card.hiddenSub:SetPoint("RIGHT", card.sub, "RIGHT", 0, 0)
						card.hiddenSub:SetJustifyH("LEFT")
						card.hiddenSub:SetWordWrap(false)
						card.hiddenSub:SetTextColor(0.62, 0.62, 0.66)
						card.hiddenUrlText = card.box:CreateFontString(nil, "OVERLAY", "ChatFontNormal")
						card.hiddenUrlText:SetPoint("LEFT", card.urlText, "LEFT", 0, 0)
						card.hiddenUrlText:SetPoint("RIGHT", card.urlText, "RIGHT", 0, 0)
						card.hiddenUrlText:SetJustifyH("LEFT")
						card.hiddenUrlText:SetWordWrap(false)
						card.hiddenUrlText:SetTextColor(0.82, 0.88, 1)
					end
					-- Show the hidden values in place of the normal lines
					card.hiddenMode = true
					card.title:Hide()
					card.sub:Hide()
					card.urlText:Hide()
					card.edit:ClearFocus()
					card.edit:Hide()
					card.url = nil -- Nothing to copy (holding Ctrl does nothing)
					card.hint:SetText(L["The link cannot be copied right now"])
					card.hiddenTitle:SetText(auraName or "")
					card.hiddenSub:SetText(L["ID"] .. " |cffffffff" .. auraID .. "|r    |cff8a8a90" .. L["Details are hidden right now"] .. "|r")
					card.hiddenUrlText:SetText("https://" .. LeaPlusLC.WowheadLock .. "/spell=" .. auraID)
					card.hiddenTitle:Show()
					card.hiddenSub:Show()
					card.hiddenUrlText:Show()
				end
				local function SpellIcon(spellID)
					return (C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(spellID)) or (GetSpellTexture and GetSpellTexture(spellID))
				end
				-- Flavour text helpers for the model viewer
				local function SpellText(spellID)
					local text = Safe((C_Spell and C_Spell.GetSpellDescription and C_Spell.GetSpellDescription(spellID)) or (GetSpellDescription and GetSpellDescription(spellID)))
					if type(text) == "string" and text ~= "" then return text end
				end
				local function TooltipLines(tooltip)
					local lines = {}
					local name = tooltip and tooltip.GetName and tooltip:GetName()
					if not name then return lines end
					for i = 1, tooltip:NumLines() do
						local line = _G[name .. "TextLeft" .. i]
						local text = line and line:GetText()
						text = Safe(text)
						if type(text) == "string" then tinsert(lines, (text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))) end
					end
					return lines
				end
				local function ItemFlavour(tooltip)
					for void, text in ipairs(TooltipLines(tooltip)) do
						if text:find('^"') then return text end -- Flavour text is the quoted line
					end
				end
				local function NPCText(tooltip)
					local parts = {}
					local lines = TooltipLines(tooltip)
					if lines[2] and lines[2]:find("^<") then tinsert(parts, lines[2]) end -- Title such as <Innkeeper>
					local creatureType = Safe(UnitCreatureType("mouseover"))
					if type(creatureType) == "string" then tinsert(parts, creatureType) end
					if #parts > 0 then return table.concat(parts, "\n") end
				end
				local function PlayerText(unit)
					local parts = {}
					local guildName = Safe(GetGuildInfo(unit))
					if type(guildName) == "string" then tinsert(parts, "<" .. guildName .. ">") end
					local race = Safe(UnitRace(unit))
					if type(race) == "string" then tinsert(parts, race .. " " .. (Safe(UnitClass(unit)) or "")) end
					if #parts > 0 then return table.concat(parts, "\n") end
				end
				local function QuestText(questID)
					local objectives = SafeTable(C_QuestLog.GetQuestObjectives(questID))
					if not objectives then return end
					local parts = {}
					for void, objective in ipairs(objectives) do
						local text = SafeTable(objective) and Safe(objective.text)
						if type(text) == "string" and text ~= "" then tinsert(parts, text) end
					end
					if #parts > 0 then return table.concat(parts, "\n") end
				end
				-- Items that show on a character (only these open the model viewer)
				local hiddenSlots = {INVTYPE_AMMO = true, INVTYPE_FINGER = true, INVTYPE_NECK = true, INVTYPE_TRINKET = true, INVTYPE_RELIC = true, INVTYPE_BAG = true, INVTYPE_QUIVER = true, INVTYPE_NON_EQUIP = true, INVTYPE_NON_EQUIP_IGNORE = true, [""] = true}
				local function IsEquippable(itemLink)
					local dressable = (C_Item and C_Item.IsDressableItemByID) or IsDressableItem
					if dressable then
						local result = Safe(dressable(itemLink))
						if result ~= nil then return result end
					end
					local check = (C_Item and C_Item.IsEquippableItem) or IsEquippableItem
					if not (check and Safe(check(itemLink))) then return false end
					local GetInfoInstant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
					local equipLoc = GetInfoInstant and Safe(select(4, GetInfoInstant(itemLink)))
					return equipLoc ~= nil and not hiddenSlots[equipLoc]
				end
				local colorBuff, colorDebuff, colorSpell, colorQuest = {0.3, 0.9, 0.4}, {1, 0.35, 0.35}, {0.35, 0.65, 1}, {1, 0.82, 0}
				-- Forever uses surnames where other games use realm names (Forever is interface version 1.6x)
				local tocVersion = select(4, GetBuildInfo()) or 0
				local isForever = tocVersion >= 16000 and tocVersion < 20000
				-- Talent tree names for each class, left to right (Forever has one spec per class, so the game does not name the trees)
				local talentTreeNames = {
					WARRIOR = {L["Arms"], L["Fury"], L["Protection"]},
					PALADIN = {L["Holy"], L["Protection"], L["Retribution"]},
					HUNTER = {L["Beast Mastery"], L["Marksmanship"], L["Survival"]},
					ROGUE = {L["Assassination"], L["Combat"], L["Subtlety"]},
					PRIEST = {L["Discipline"], L["Holy"], L["Shadow"]},
					SHAMAN = {L["Elemental Combat"], L["Enhancement"], L["Restoration"]},
					MAGE = {L["Arcane"], L["Fire"], L["Frost"]},
					WARLOCK = {L["Affliction"], L["Demonology"], L["Destruction"]},
					DRUID = {L["Balance"], L["Feral Combat"], L["Restoration"]},
				}
				-- Talent summary: the talent trees with points in them, most points first (such as Frost 31   Arcane 20)
				-- Forever keeps the three trees side by side in one modern talent tree, so talents are grouped by
				-- their position (a new tree starts where the gap between columns is much wider than usual)
				local function TalentSummary(configID, classFile)
					if not configID or not C_Traits or not C_Traits.GetConfigInfo then return nil end
					local config = SafeTable(C_Traits.GetConfigInfo(configID))
					local treeIDs = config and SafeTable(config.treeIDs)
					if not treeIDs or not Safe(treeIDs[1]) then return nil end
					local nodes = {}
					for void, treeID in ipairs(treeIDs) do
						treeID = Safe(treeID)
						for void, nodeID in ipairs(treeID and SafeTable(C_Traits.GetTreeNodes(treeID)) or {}) do
							local node = SafeTable(C_Traits.GetNodeInfo(configID, Safe(nodeID)))
							if node and type(Safe(node.posX)) == "number" then tinsert(nodes, node) end
						end
					end
					-- Points per column (use purchased ranks, or active ranks if nothing was purchased, such as some inspect data)
					local function Columns(field)
						local columns, total = {}, 0
						for void, node in ipairs(nodes) do
							local points = Safe(node[field])
							if type(points) ~= "number" then points = 0 end
							columns[node.posX] = (columns[node.posX] or 0) + points
							total = total + points
						end
						return columns, total
					end
					local columns, total = Columns("ranksPurchased")
					if total == 0 then columns, total = Columns("activeRank") end
					local xs = {}
					for x in pairs(columns) do tinsert(xs, x) end
					table.sort(xs)
					if #xs == 0 then return nil end
					if total == 0 then return "|cff8a8a90" .. L["No talents"] .. "|r" end
					-- Split the columns into trees where the gap is much wider than the usual gap between columns
					local gaps = {}
					for i = 2, #xs do tinsert(gaps, xs[i] - xs[i - 1]) end
					table.sort(gaps)
					local usualGap = gaps[math.ceil(#gaps / 2)] or 0
					local trees = {{points = 0, order = 1}}
					for i, x in ipairs(xs) do
						if i > 1 and xs[i] - xs[i - 1] > usualGap * 1.5 then tinsert(trees, {points = 0, order = #trees + 1}) end
						trees[#trees].points = trees[#trees].points + columns[x]
					end
					-- Name the trees (left to right)
					local names = classFile and talentTreeNames[classFile]
					for i, tree in ipairs(trees) do
						tree.name = names and names[i] or (L["Tree"] .. " " .. i)
					end
					table.sort(trees, function(x, y) if x.points ~= y.points then return x.points > y.points end return x.order < y.order end)
					local parts = {}
					for i, tree in ipairs(trees) do
						if tree.points > 0 then tinsert(parts, (i == 1 and "|cffffffff" or "|cffa0a0a8") .. tree.name .. " " .. tree.points .. "|r") end
					end
					return table.concat(parts, "    ")
				end
				-- Run a game function safely (gives nothing if it is missing or fails, and leaves out hidden values)
				local function Try(func, ...)
					if type(func) ~= "function" then return nil end
					local results = {pcall(func, ...)}
					if not results[1] then return nil end
					return Safe(unpack(results, 2, table.maxn(results)))
				end
				-- Specialisation summary for games with specialisations (Mists and later), such as Retribution (with hero talents where the game has them)
				local function SpecTalentSummary(unit, configID, isPlayer)
					local GetSpec = (C_SpecializationInfo and C_SpecializationInfo.GetSpecialization) or GetSpecialization
					local GetSpecInfo = (C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo) or GetSpecializationInfo
					local specID
					if isPlayer then
						local index = Try(GetSpec)
						if type(index) == "number" and index > 0 then specID = Try(GetSpecInfo, index) end
					else
						if unit then specID = Try(GetInspectSpecialization, unit) end
						-- The player cannot be found now (the mouse has moved off them), so use the inspected player's details
						if not (type(specID) == "number" and specID > 0) then
							local index = Try(GetSpec, true)
							if type(index) == "number" and index > 0 then specID = Try(GetSpecInfo, index, true) end
						end
					end
					local specName, specIcon
					if type(specID) == "number" and specID > 0 then
						local void
						void, specName, void, specIcon = Try(GetSpecializationInfoByID, specID)
					end
					local heroName
					if configID and C_Traits and C_Traits.GetSubTreeInfo then
						local subTreeIDs = {}
						if isPlayer and C_ClassTalents and C_ClassTalents.GetActiveHeroTalentSpec then
							local active = Try(C_ClassTalents.GetActiveHeroTalentSpec)
							if active then tinsert(subTreeIDs, active) end
						end
						if #subTreeIDs == 0 and type(specID) == "number" and C_ClassTalents and C_ClassTalents.GetHeroTalentSpecsForClassSpec then
							for void, id in ipairs(SafeTable(Try(C_ClassTalents.GetHeroTalentSpecsForClassSpec, configID, specID)) or {}) do tinsert(subTreeIDs, id) end
						end
						for void, subTreeID in ipairs(subTreeIDs) do
							local info = SafeTable(Try(C_Traits.GetSubTreeInfo, configID, Safe(subTreeID)))
							if info and Safe(info.isActive) and type(Safe(info.name)) == "string" then heroName = info.name break end
						end
					end
					if not specName and not heroName then return nil end
					local parts = {}
					if specName then tinsert(parts, (specIcon and ("|T" .. specIcon .. ":14:14:0:0|t ") or "") .. "|cffffffff" .. specName .. "|r") end
					if heroName then tinsert(parts, "|cffa0a0a8" .. heroName .. "|r") end
					return table.concat(parts, "    ")
				end
				-- Find a player by their GUID (the mouse may have moved off them since the key was pressed)
				local function FindUnitByGUID(guid, first)
					if not guid then return nil end
					local tokens = {first or "mouseover", "mouseover", "target", "focus", "targettarget"}
					for i = 1, 4 do tinsert(tokens, "party" .. i) end
					if IsInRaid and IsInRaid() then for i = 1, 40 do tinsert(tokens, "raid" .. i) end end
					for i = 1, 40 do tinsert(tokens, "nameplate" .. i) end
					for void, token in ipairs(tokens) do
						if UnitExists(token) and Safe(UnitGUID(token)) == guid then return token end
					end
				end
				-- Talent tree summary for games with three talent trees (Classic Era, Burning Crusade and Wrath), such as Fire 31    Arcane 20
				-- The game gives each tree's name and points (newer clients through C_SpecializationInfo, older ones through GetTalentTabInfo)
				local function TreeInfo(index, isInspect, inspectUnit)
					if C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo then
						local r = {Try(C_SpecializationInfo.GetSpecializationInfo, index, isInspect, false, inspectUnit)}
						if type(r[2]) == "string" and r[2] ~= "" then return r[2], type(r[7]) == "number" and r[7] or 0 end
					end
					if GetTalentTabInfo then
						local r = {Try(GetTalentTabInfo, index, isInspect)}
						-- Newer clients start with the tree ID, older ones start with the name
						if type(r[1]) == "number" and type(r[2]) == "string" and r[2] ~= "" then return r[2], type(r[5]) == "number" and r[5] or 0 end
						if type(r[1]) == "string" and r[1] ~= "" then return r[1], type(r[3]) == "number" and r[3] or 0 end
					end
				end
				local function ClassicTalentSummary(inspectUnit, isPlayer)
					local trees, total = {}, 0
					for i = 1, 5 do
						local name, points = TreeInfo(i, not isPlayer, not isPlayer and inspectUnit or nil)
						if not name then break end
						tinsert(trees, {name = name, points = points, order = i})
						total = total + points
					end
					if #trees == 0 then return nil end
					if total == 0 then
						-- Nothing spent: say so for your own character, but show nothing for other players (the game may not have sent their talents)
						if isPlayer then return "|cff8a8a90" .. L["No talents"] .. "|r" end
						return nil
					end
					table.sort(trees, function(x, y) if x.points ~= y.points then return x.points > y.points end return x.order < y.order end)
					local parts = {}
					for i, tree in ipairs(trees) do
						if tree.points > 0 then tinsert(parts, (i == 1 and "|cffffffff" or "|cffa0a0a8") .. tree.name .. " " .. tree.points .. "|r") end
					end
					return table.concat(parts, "    ")
				end
				-- Details for the card (each returns a list of short parts; anything the game hides or does not have is left out)
				local function NotSecret(v) return v ~= nil and not IsSecret(v) end
				local function Grey(text) return "|cff8a8a90" .. text .. "|r" end
				-- Money with gold, silver and copper icons
				local function CoinText(copper)
					-- Size the coin icons to the card's details text (the default size suits larger text, so the icons sit low)
					local card = LeaPlusLC.IDCard
					local fontSize = card and card.detail and select(2, card.detail:GetFont())
					fontSize = fontSize and math.floor(fontSize + 0.5) or nil
					if C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString then return C_CurrencyInfo.GetCoinTextureString(copper, fontSize) end
					if GetCoinTextureString then return GetCoinTextureString(copper, fontSize) end
					local gold, silver, bronze = math.floor(copper / 10000), math.floor(copper % 10000 / 100), copper % 100
					local text = {}
					if gold > 0 then tinsert(text, gold .. "|TInterface\\MoneyFrame\\UI-GoldIcon:12:12:2:0|t") end
					if silver > 0 then tinsert(text, silver .. "|TInterface\\MoneyFrame\\UI-SilverIcon:12:12:2:0|t") end
					if bronze > 0 or #text == 0 then tinsert(text, bronze .. "|TInterface\\MoneyFrame\\UI-CopperIcon:12:12:2:0|t") end
					return table.concat(text, " ")
				end
				-- Players: guild, relationship to you, PvP
				local function PlayerDetails(unit, guid)
					local parts = {}
					unit, guid = Safe(unit, guid)
					local hasUnit = unit and UnitExists(unit)
					-- Guild
					if hasUnit then
						local guildName, rankName = Safe(GetGuildInfo(unit))
						if guildName and guildName ~= "" then tinsert(parts, "|cff40ff40" .. guildName .. "|r" .. (rankName and rankName ~= "" and (" " .. rankName) or "")) end
					end
					-- Relationship to you
					local relation = {}
					if hasUnit and not Safe(UnitIsUnit(unit, "player")) then -- Nothing to say about your own character
						if Safe(UnitInRaid(unit)) or Safe(UnitInParty(unit)) then tinsert(relation, L["In your group"]) end
						if UnitIsInMyGuild and Safe(UnitIsInMyGuild(unit)) then tinsert(relation, L["Guildmate"]) end
					end
					if guid and C_FriendList and C_FriendList.IsFriend and Safe(C_FriendList.IsFriend(guid)) then tinsert(relation, L["Friend"]) end
					if #relation > 0 then tinsert(parts, "|cff66bbff" .. table.concat(relation, ", ") .. "|r") end
					-- PvP
					if hasUnit then
						local pvp = {}
						if UnitIsPVPFreeForAll and Safe(UnitIsPVPFreeForAll(unit)) then tinsert(pvp, L["Free for all PvP"])
						elseif Safe(UnitIsPVP(unit)) then tinsert(pvp, L["PvP"]) end
						if UnitPVPRank and GetPVPRankInfo then
							local rank = Safe(UnitPVPRank(unit))
							if type(rank) == "number" and rank >= 5 then
								local rankName = Safe(GetPVPRankInfo(rank, unit))
								if rankName and rankName ~= "" then tinsert(pvp, rankName) end
							end
						end
						if #pvp > 0 then tinsert(parts, "|cffff6060" .. table.concat(pvp, ", ") .. "|r") end
					end
					return parts
				end
				-- Average item level of a unit's equipped gear (shirt and tabard are left out, a two-hand weapon counts twice)
				local function AverageItemLevel(unit)
					if Safe(UnitIsUnit(unit, "player")) and GetAverageItemLevel then
						local void, equipped = Safe(GetAverageItemLevel())
						if type(equipped) == "number" and equipped > 0 then
							-- Match the character sheet: never below the minimum item level, and always round down
							local minLevel = C_PaperDollInfo and C_PaperDollInfo.GetMinItemLevel and Safe(C_PaperDollInfo.GetMinItemLevel())
							if type(minLevel) == "number" and minLevel > equipped then equipped = minLevel end
							return math.floor(equipped)
						end
					end
					local total, count, mainHandTwoHand, offHand = 0, 0, false, false
					local GetInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
					local GetLevel = (C_Item and C_Item.GetDetailedItemLevelInfo) or GetDetailedItemLevelInfo
					for slot = 1, 18 do
						if slot ~= 4 then
							local link = Safe(GetInventoryItemLink(unit, slot))
							if link then
								local level = Safe(GetLevel and GetLevel(link) or select(4, GetInfo(link)))
								if type(level) == "number" and level > 0 then
									total, count = total + level, count + 1
									if slot == 16 and Safe(select(9, GetInfo(link))) == "INVTYPE_2HWEAPON" then mainHandTwoHand = level end
									if slot == 17 then offHand = true end
								end
							end
						end
					end
					if mainHandTwoHand and not offHand then total, count = total + mainHandTwoHand, count + 1 end
					if count == 0 then return nil end
					return math.floor(total / count)
				end
				-- Items: item level, binding, sell price, item set
				local function ItemDetails(itemLink, tooltip)
					local parts = {}
					local GetInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
					local void, itemLevel, sellPrice, bindType
					void, void, void, itemLevel, void, void, void, void, void, void, sellPrice, void, void, bindType = Safe(GetInfo(itemLink))
					local GetLevel = (C_Item and C_Item.GetDetailedItemLevelInfo) or GetDetailedItemLevelInfo
					itemLevel = (GetLevel and Safe(GetLevel(itemLink))) or itemLevel
					if type(itemLevel) == "number" and itemLevel > 0 then tinsert(parts, L["Item level"] .. " |cffffffff" .. itemLevel .. "|r") end
					-- Binding (soulbound if the tooltip says so, otherwise how it binds)
					local lines = TooltipLines(tooltip)
					local bound
					for void, text in ipairs(lines) do
						if text == ITEM_SOULBOUND or (ITEM_ACCOUNTBOUND and text == ITEM_ACCOUNTBOUND) then bound = text break end
					end
					if not bound then
						if bindType == 1 then bound = ITEM_BIND_ON_PICKUP
						elseif bindType == 2 then bound = ITEM_BIND_ON_EQUIP
						elseif bindType == 3 then bound = ITEM_BIND_ON_USE
						elseif bindType == 4 then bound = ITEM_BIND_QUEST end
					end
					if bound then tinsert(parts, bound) end
					-- Sell price
					if type(sellPrice) == "number" then
						if sellPrice > 0 then
							tinsert(parts, L["Sells for"] .. " " .. CoinText(sellPrice))
						else
							tinsert(parts, Grey(L["Cannot be sold"]))
						end
					end
					-- Item set (the tooltip line with the set name and pieces, such as "Battlegear of Might (2/8)")
					for void, text in ipairs(lines) do
						local setName, have, total = text:match("^(.-) %((%d+)/(%d+)%)$")
						if setName and setName ~= "" then
							tinsert(parts, "|cffffd100" .. L["Set"] .. ": " .. setName .. " (" .. have .. "/" .. total .. ")|r")
							break
						end
					end
					return parts
				end
				-- Spells: rank
				local function SpellDetails(spellID)
					local parts = {}
					local subtext = Safe((C_Spell and C_Spell.GetSpellSubtext and C_Spell.GetSpellSubtext(spellID)) or (GetSpellSubtext and GetSpellSubtext(spellID)))
					if type(subtext) == "string" and subtext ~= "" then tinsert(parts, subtext) end
					return parts
				end
				-- Buffs and debuffs: who cast it
				local function AuraDetails(sourceUnit, spellID)
					local parts = {}
					sourceUnit = Safe(sourceUnit)
					-- For the buff frame, look up the caster from your own auras
					if not sourceUnit and spellID and C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID and not AurasHidden() then
						local aura = SafeTable(C_UnitAuras.GetPlayerAuraBySpellID(spellID))
						if aura then sourceUnit = Safe(aura.sourceUnit) end
					end
					if type(sourceUnit) ~= "string" or not UnitExists(sourceUnit) then return parts end
					if Safe(UnitIsUnit(sourceUnit, "player")) then
						tinsert(parts, L["Cast by"] .. " |cffffffff" .. L["You"] .. "|r")
					else
						local name = Safe(UnitName(sourceUnit))
						if name then
							local classFile = Safe(UnitIsPlayer(sourceUnit)) and Safe(select(2, UnitClass(sourceUnit)))
							local color = classFile and RAID_CLASS_COLORS[classFile]
							tinsert(parts, L["Cast by"] .. " " .. (color and string.format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, name) or ("|cffffffff" .. name .. "|r")))
						end
					end
					return parts
				end
				-- Quests: level (coloured by difficulty), complete, group or elite, rewards
				local function QuestDetails(questID)
					local parts = {}
					local index = C_QuestLog.GetLogIndexForQuestID and Safe(C_QuestLog.GetLogIndexForQuestID(questID))
					local info = index and SafeTable(C_QuestLog.GetInfo(index))
					local level = info and Safe(info.level)
					local suggestedGroup = info and Safe(info.suggestedGroup)
					if type(suggestedGroup) ~= "number" then suggestedGroup = 0 end
					if type(level) == "number" and level > 0 then
						local color = GetQuestDifficultyColor and GetQuestDifficultyColor(level)
						local text = L["Level"] .. " " .. level
						tinsert(parts, color and string.format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, text) or text)
					end
					if C_QuestLog.IsComplete and Safe(C_QuestLog.IsComplete(questID)) then tinsert(parts, "|cff40ff40" .. L["Complete"] .. "|r") end
					-- Group size, elite, dungeon and so on
					local tag = C_QuestLog.GetQuestTagInfo and SafeTable(C_QuestLog.GetQuestTagInfo(questID))
					local tagName = tag and Safe(tag.tagName)
					if type(tagName) == "string" and tagName ~= "" then
						tinsert(parts, "|cffff9020" .. tagName .. ((suggestedGroup > 1) and (" (" .. suggestedGroup .. ")") or "") .. "|r")
					elseif suggestedGroup > 1 then
						tinsert(parts, "|cffff9020" .. L["Group"] .. " (" .. suggestedGroup .. ")|r")
					end
					-- Rewards (money, experience, items and item choices)
					local rewards = {}
					local money = GetQuestLogRewardMoney and Safe(GetQuestLogRewardMoney(questID))
					if type(money) == "number" and money > 0 then tinsert(rewards, CoinText(money)) end
					local xp = GetQuestLogRewardXP and Safe(GetQuestLogRewardXP(questID))
					if type(xp) == "number" and xp > 0 then tinsert(rewards, xp .. " " .. L["XP"]) end
					local function ItemIcons(count, getInfo)
						local icons = {}
						count = Safe(count)
						for i = 1, type(count) == "number" and count or 0 do
							local void, texture, number = Safe(getInfo(i, questID))
							if texture then tinsert(icons, "|T" .. texture .. ":14:14|t" .. ((type(number) == "number" and number > 1) and ("x" .. number) or "")) end
						end
						return table.concat(icons, " ")
					end
					if GetNumQuestLogRewards and GetQuestLogRewardInfo then
						local icons = ItemIcons(GetNumQuestLogRewards(questID), GetQuestLogRewardInfo)
						if icons ~= "" then tinsert(rewards, icons) end
					end
					if GetNumQuestLogChoices and GetQuestLogChoiceInfo then
						local icons = ItemIcons(GetNumQuestLogChoices(questID), GetQuestLogChoiceInfo)
						if icons ~= "" then tinsert(rewards, L["Choose"] .. " " .. icons) end
					end
					if #rewards > 0 then tinsert(parts, L["Rewards"] .. ": " .. table.concat(rewards, "  ")) end
					return parts
				end
				-- Show the talent summary on the card (other players are inspected first)
				local function ShowPlayerTalents(unit)
					local card = LeaPlusLC.IDCard
					unit = Safe(unit)
					if not card or not unit or not UnitExists(unit) then return end
					local classFile = Safe(select(2, UnitClass(unit)))
					-- Players under level 10 have no talents (and no specialisation), so leave talents off the card entirely (nothing is said and nothing is asked for)
					local level = Safe(UnitLevel(unit))
					local lowLevel = not isForever and type(level) == "number" and level > 0 and level < 10
					if lowLevel then
						card.talentsReserved = false
						card.talents:SetText("")
						card:Relayout()
					end
					if Safe(UnitIsUnit(unit, "player")) then
						local activeConfigID = C_ClassTalents and C_ClassTalents.GetActiveConfigID and Safe(C_ClassTalents.GetActiveConfigID())
						if lowLevel then
							-- No talents line under level 10
						elseif isForever then
							card.talents:SetText(TalentSummary(activeConfigID, classFile) or "")
						elseif tocVersion >= 50000 then
							card.talents:SetText(SpecTalentSummary(unit, activeConfigID, true) or "")
						else
							card.talents:SetText(ClassicTalentSummary(nil, true) or "")
						end
						local itemLevel = AverageItemLevel("player")
						if itemLevel then card:AddDetail(L["Item level"] .. " |cffffffff" .. itemLevel .. "|r") end
						return
					end
					if lowLevel then return end
					local guid = Safe(UnitGUID(unit))
					if not guid or not NotifyInspect or not CanInspect or not Safe(CanInspect(unit)) then return end
					if InspectFrame and InspectFrame:IsShown() then return end -- Do not disturb the inspect window
					card.inspectGUID = guid
					card.inspectTime = GetTime() -- Each inspect starts with fresh gear for the model viewer
					card:SetItemLevelDetail("|cff8a8a90" .. L["Item level"] .. " ...|r") -- Shown until the inspect has come back
					card.inspectClassFile = classFile
					card.inspectUnit = unit
					LeaPlusLC.IDReinspect = nil -- A new key press can ask again
					card.talents:SetText("|cff8a8a90" .. L["Reading talents..."] .. "|r")
					if not LeaPlusLC.IDCardInspect then
						LeaPlusLC.IDCardInspect = CreateFrame("Frame")
						LeaPlusLC.IDCardInspect:SetScript("OnEvent", function(self, event, readyGUID)
							local c = LeaPlusLC.IDCard
							readyGUID = Safe(readyGUID)
							if not c or not c.inspectGUID or not readyGUID or readyGUID ~= c.inspectGUID then return end
							c.inspectGUID = nil
							LeaPlusLC.IDInspectPending = nil
							self:UnregisterEvent("INSPECT_READY")
							local inspectConfigID = Constants and Constants.TraitConsts and Constants.TraitConsts.INSPECT_TRAIT_CONFIG_ID or -1
							-- Average item level from the inspected gear (the player is found again in case the mouse has moved off them)
							local gearUnit = FindUnitByGUID(readyGUID, c.inspectUnit)
							if gearUnit and c.itemLevelGUID ~= readyGUID then
								local itemLevel = AverageItemLevel(gearUnit)
								c.itemLevelGUID = readyGUID
								c:SetItemLevelDetail(itemLevel and (L["Item level"] .. " |cffffffff" .. itemLevel .. "|r") or nil)
							end
							-- Gear for the model viewer: each item is kept as soon as it can be read (items the game has not loaded yet are read again for up to
							-- 3 seconds), and the viewer is updated if it shows this player (the inspect data is kept until this is done, then cleared)
							local gearInspectUnit = c.inspectUnit
							c.gearReadingGUID = readyGUID
							-- Item level from the inspected gear (or take the waiting message away if there is none)
							local function ShowGearItemLevel(unit)
								if not c:IsShown() then return end
								local itemLevel = unit and AverageItemLevel(unit)
								c.itemLevelGUID = readyGUID
								c:SetItemLevelDetail(itemLevel and (L["Item level"] .. " |cffffffff" .. itemLevel .. "|r") or nil)
							end
							local function ReadGear()
								local gearUnit = FindUnitByGUID(readyGUID, gearInspectUnit)
								if not gearUnit then return false end
								LeaPlusLC.IDGear = LeaPlusLC.IDGear or {}
								local gear = LeaPlusLC.IDGear[readyGUID]
								if not gear or gear.inspectTime ~= c.inspectTime then gear = {inspectTime = c.inspectTime} LeaPlusLC.IDGear = {[readyGUID] = gear} end -- Only the player just inspected is kept
								local RequestLoad = C_Item and C_Item.RequestLoadItemDataByID
								local complete, newWeapon = true, false
								for slot = 1, 19 do
									local link = Safe(GetInventoryItemLink(gearUnit, slot))
									if link then
										if not gear[slot] then
											gear[slot] = link
											if slot >= 16 and slot <= 18 then newWeapon = true end
										end
									else
										local itemID = GetInventoryItemID and Safe(GetInventoryItemID(gearUnit, slot))
										if itemID then
											complete = false
											if RequestLoad then pcall(RequestLoad, itemID) end
										end
									end
								end
								local viewer = LeaPlusLC.IDViewer
								if newWeapon and viewer then viewer:ApplyInspectGear() end
								if not complete then return false end
								gear.complete = true
								ShowGearItemLevel(gearUnit) -- Every item has loaded, so the item level is right
								if viewer then viewer:ApplyInspectGear() viewer:CheckReveal() end
								return true
							end
							local function ClearIfDone()
								if ClearInspectPlayer and not (InspectFrame and InspectFrame:IsShown()) and not c.inspectGUID and c.talentsGUID ~= readyGUID and c.gearReadingGUID ~= readyGUID and not LeaPlusLC.IDGearWait then ClearInspectPlayer() end
							end
							-- The reply came back but the player could not be found (the mouse has moved off them and nothing else points at them), so keep the
							-- reply and read their gear as soon as they can be found again (pointed at, targeted or their nameplate shown)
							local function SetGearWait()
								LeaPlusLC.IDGearWait = {guid = readyGUID, read = ReadGear}
								c:SetItemLevelDetail("|cff8a8a90" .. string.format(L["Move your mouse over %s to show their item level."], c.title:GetText() or "") .. "|r")
								if not LeaPlusLC.IDGearWatch then
									local watch = CreateFrame("Frame")
									LeaPlusLC.IDGearWatch = watch
									local function TryWait()
										local wait, card = LeaPlusLC.IDGearWait, LeaPlusLC.IDCard
										if not wait then return end
										if not card or not card:IsShown() then LeaPlusLC.IDGearWait = nil return end
										if wait.read() then
											LeaPlusLC.IDGearWait = nil
											if ClearInspectPlayer and not (InspectFrame and InspectFrame:IsShown()) and not card.inspectGUID then ClearInspectPlayer() end
										elseif FindUnitByGUID(wait.guid) and (wait.tries or 0) < 12 then
											-- Found, but some items are still loading
											wait.tries = (wait.tries or 0) + 1
											C_Timer.After(0.25, TryWait)
										end
									end
									watch:SetScript("OnEvent", TryWait)
									watch:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
									watch:RegisterEvent("PLAYER_TARGET_CHANGED")
									watch:RegisterEvent("NAME_PLATE_UNIT_ADDED")
									watch:RegisterEvent("GROUP_ROSTER_UPDATE")
								end
							end
							local gearTries = 0
							local function GearAttempt()
								if c.gearReadingGUID ~= readyGUID or not c:IsShown() then return end
								gearTries = gearTries + 1
								local done = ReadGear()
								local found = done or FindUnitByGUID(readyGUID, gearInspectUnit)
								if done or not found or gearTries >= 12 then
									if not done and not found then SetGearWait() end
									if not done and found then ShowGearItemLevel(found) end -- Some items never loaded, so show what can be read
									c.gearReadingGUID = nil
									ClearIfDone()
									if LeaPlusLC.IDViewer then LeaPlusLC.IDViewer:CheckReveal() end
									return
								end
								C_Timer.After(0.25, GearAttempt)
							end
							-- Talents: players the game has not seen before can send their talents a moment after the inspect has finished,
							-- so read them again a few times before giving up (the inspect data is only cleared once this is done)
							local inspectUnit, inspectClassFile = c.inspectUnit, c.inspectClassFile
							local function ReadTalents()
								if isForever then return TalentSummary(inspectConfigID, inspectClassFile) end
								-- Find the player again (the mouse may have moved off them), the talents can still be read if they cannot be found
								local specUnit = FindUnitByGUID(readyGUID, inspectUnit)
								if tocVersion >= 50000 then return SpecTalentSummary(specUnit, inspectConfigID, false) end
								return ClassicTalentSummary(specUnit, false)
							end
							local function Finish(text)
								if c.talentsGUID == readyGUID then c.talents:SetText(text or "") c.talentsGUID = nil end
								-- Clear the inspect data (not while the inspect window is open or another player is being inspected)
								if ClearInspectPlayer and not (InspectFrame and InspectFrame:IsShown()) and not c.inspectGUID and c.gearReadingGUID ~= readyGUID and not LeaPlusLC.IDGearWait then ClearInspectPlayer() end
							end
							c.talentsGUID = readyGUID
							local tries = 0
							local function Attempt()
								-- Stop if the card has been closed or now shows something else
								if c.talentsGUID ~= readyGUID or not c:IsShown() then Finish() return end
								local text = ReadTalents()
								tries = tries + 1
								if text then Finish(text) return end
								if tries < 6 then C_Timer.After(0.25, Attempt) return end
								-- Still no talents: the first reply for a player the game has not seen before can come without them,
								-- so clear the inspect and ask once more (the same as pressing the key again, which gets them)
								local askUnit = FindUnitByGUID(readyGUID, inspectUnit)
								local stillThere = askUnit and CanInspect and Safe(CanInspect(askUnit))
								if LeaPlusLC.IDReinspect == readyGUID or not stillThere or (InspectFrame and InspectFrame:IsShown()) then Finish() return end
								LeaPlusLC.IDReinspect = readyGUID
								c.talentsGUID = nil
								if ClearInspectPlayer then ClearInspectPlayer() end
								c.inspectGUID = readyGUID
								self:RegisterEvent("INSPECT_READY")
								LeaPlusLC.IDInspectPending = {guid = readyGUID, time = GetTime()}
								NotifyInspect(askUnit)
								C_Timer.After(4, function()
									if c.inspectGUID == readyGUID then
										c.inspectGUID = nil
										self:UnregisterEvent("INSPECT_READY")
										c.talents:SetText("")
									end
								end)
							end
							GearAttempt()
							Attempt()
						end)
					end
					LeaPlusLC.IDCardInspect:RegisterEvent("INSPECT_READY")
					-- Only ask the server once per player at a time (asking again quickly can be ignored, so the answer never comes)
					local pending = LeaPlusLC.IDInspectPending
					if not (pending and pending.guid == guid and GetTime() - pending.time < 4) then
						LeaPlusLC.IDInspectPending = {guid = guid, time = GetTime()}
						NotifyInspect(unit)
					end
					C_Timer.After(4, function()
						local c = LeaPlusLC.IDCard
						if c and c.inspectGUID == guid and LeaPlusLC.IDReinspect ~= guid then -- Not while asking again (that has its own time limit)
							c.inspectGUID = nil
							LeaPlusLC.IDCardInspect:UnregisterEvent("INSPECT_READY")
							c.talents:SetText("|cff8a8a90" .. L["Talents are not available right now."] .. "|r")
							if c.itemLevelGUID ~= guid then c:SetItemLevelDetail(nil) end -- No reply, so no item level
						end
					end)
				end
				-- Retries happen when a new player or creature has not finished loading (see the unknown tooltip below)
				if arg1 ~= "retry" and arg1 ~= "upgrade" then
					LeaPlusLC.IDRetries, LeaPlusLC.IDUpgrades = 0, 0
					-- Remember what was under the mouse when the key was pressed (retries only show a card for that, never for something else)
					LeaPlusLC.IDPressID = (LeaPlusLC.IDPressID or 0) + 1
					LeaPlusLC.IDPressFocus = GetMouseFoci and GetMouseFoci()[1] or nil
					LeaPlusLC.IDPressHadUnit = Safe(UnitExists("mouseover")) and true or false
					LeaPlusLC.IDPressGUID = Safe(UnitGUID("mouseover"))
					-- Whether the key was pressed on a unit at all (a mailbox, the ground and so on are not units)
					local tipData = GameTooltip:IsShown() and SafeTable(GameTooltip.GetTooltipData and GameTooltip:GetTooltipData())
					LeaPlusLC.IDPressOnUnit = LeaPlusLC.IDPressHadUnit or (tipData and Safe(tipData.type) == Enum.TooltipDataType.Unit) or false
				elseif arg1 == "retry" then
					-- The mouse has moved on to something else since the key was pressed, so give up (the key was not pressed for that)
					local focus = GetMouseFoci and GetMouseFoci()[1] or nil
					if focus ~= LeaPlusLC.IDPressFocus then LeaPlusLC.IDRetries = 0 return end
					if LeaPlusLC.IDPressHadUnit and not Safe(UnitExists("mouseover")) then LeaPlusLC.IDRetries = 0 return end
					local guid = Safe(UnitGUID("mouseover"))
					if LeaPlusLC.IDPressGUID and guid and guid ~= LeaPlusLC.IDPressGUID then LeaPlusLC.IDRetries = 0 return end
					-- The key was pressed on a unit the game was hiding, and the unit now under the mouse can be read, so it is a different unit
					if LeaPlusLC.IDPressHadUnit and not LeaPlusLC.IDPressGUID and guid then LeaPlusLC.IDRetries = 0 return end
					-- The key was not pressed on a unit (such as a mailbox), and the mouse is now over one, so it is a different thing
					if not LeaPlusLC.IDPressOnUnit and Safe(UnitExists("mouseover")) then LeaPlusLC.IDRetries = 0 return end
				end
				-- Model viewer option (on unless it has been switched off with the checkbox on the card)
				if LeaPlusLC.IDModelOn == nil then LeaPlusLC.IDModelOn = not (LeaPlusDB and LeaPlusDB["IDModelOn"] == false) end
				-- Find the unit frame under the mouse (used by the aura picker below)
				if LeaPlusLC.AuraPicker then LeaPlusLC.AuraPicker:Hide() end
				local pickerUnit
				if not forceUnit then -- Not when a player was given
					local mouseFocus = GetMouseFoci and GetMouseFoci()[1]
					while mouseFocus and not pickerUnit do
						if mouseFocus.IsForbidden and mouseFocus:IsForbidden() then break end
						local unit = Safe(mouseFocus.unit)
						if type(unit) == "string" and UnitExists(unit) then pickerUnit = unit end
						mouseFocus = mouseFocus:GetParent()
					end
				end
				if pickerUnit and LeaPlusLC.IDCard then LeaPlusLC.IDCard:Hide() end
				-- Show the card for what is under the mouse
				local function ShowCardForMouse()
					-- Show info card for tooltip
					if not LeaPlusLC.WowheadLock then
						-- Set Wowhead link prefix
						if GameLocale == "deDE" then LeaPlusLC.WowheadLock = "www.wowhead.com/tbc/de"
						elseif GameLocale == "esMX" then LeaPlusLC.WowheadLock = "www.wowhead.com/tbc/mx"
						elseif GameLocale == "esES" then LeaPlusLC.WowheadLock = "www.wowhead.com/tbc/es"
						elseif GameLocale == "frFR" then LeaPlusLC.WowheadLock = "www.wowhead.com/tbc/fr"
						elseif GameLocale == "itIT" then LeaPlusLC.WowheadLock = "www.wowhead.com/tbc/it"
						elseif GameLocale == "ptBR" then LeaPlusLC.WowheadLock = "www.wowhead.com/tbc/pt"
						elseif GameLocale == "ruRU" then LeaPlusLC.WowheadLock = "www.wowhead.com/tbc/ru"
						elseif GameLocale == "koKR" then LeaPlusLC.WowheadLock = "www.wowhead.com/tbc/ko"
						elseif GameLocale == "zhCN" then LeaPlusLC.WowheadLock = "www.wowhead.com/tbc/cn"
						elseif GameLocale == "zhTW" then LeaPlusLC.WowheadLock = "www.wowhead.com/tbc/tw"
						else							 LeaPlusLC.WowheadLock = "www.wowhead.com/tbc"
						end
					end
					if not LeaPlusLC.BlizzardLock then
						-- Set Blizzard link prefix (https://wowpedia.fandom.com/wiki/Localization) (region will be added by website automatically)
							if GameLocale == "deDE" then LeaPlusLC.BlizzardLock = "https://worldofwarcraft.blizzard.com/de-de/classicann/eu/armory/character/" -- Germany
						elseif GameLocale == "frFR" then LeaPlusLC.BlizzardLock = "https://worldofwarcraft.blizzard.com/fr-fr/classicann/eu/armory/character/" -- France
						elseif GameLocale == "itIT" then LeaPlusLC.BlizzardLock = "https://worldofwarcraft.blizzard.com/it-it/classicann/eu/armory/character/" -- Italy
						elseif GameLocale == "ruRU" then LeaPlusLC.BlizzardLock = "https://worldofwarcraft.blizzard.com/ru-ru/classicann/eu/armory/character/" -- Russia
						elseif GameLocale == "koKR" then LeaPlusLC.BlizzardLock = "https://worldofwarcraft.blizzard.com/ko-kr/classicann/kr/armory/character/" -- Korea
						elseif GameLocale == "zhTW" then LeaPlusLC.BlizzardLock = "https://worldofwarcraft.blizzard.com/zh-tw/classicann/tw/armory/character/" -- Tiawan
						elseif GameLocale == "esES" and GetCurrentRegion() == 1 then LeaPlusLC.BlizzardLock = "https://worldofwarcraft.blizzard.com/es-es/classicann/us/armory/character/" -- Spain (esES connected to US)
						elseif GameLocale == "esES" and GetCurrentRegion() == 3 then LeaPlusLC.BlizzardLock = "https://worldofwarcraft.blizzard.com/es-es/classicann/eu/armory/character/" -- Spain (esES connected to EU)
						elseif GameLocale == "esMX" and GetCurrentRegion() == 1 then LeaPlusLC.BlizzardLock = "https://worldofwarcraft.blizzard.com/es-mx/classicann/us/armory/character/" -- Mexico (esMX connected to US)
						elseif GameLocale == "esMX" and GetCurrentRegion() == 3 then LeaPlusLC.BlizzardLock = "https://worldofwarcraft.blizzard.com/es-mx/classicann/eu/armory/character/" -- Spain (esMX connected to EU)
						elseif GameLocale == "ptBR" and GetCurrentRegion() == 1 then LeaPlusLC.BlizzardLock = "https://worldofwarcraft.blizzard.com/pt-br/classicann/us/armory/character/" -- Brazil (ptBR connected to US)
						elseif GameLocale == "ptBR" and GetCurrentRegion() == 3 then LeaPlusLC.BlizzardLock = "https://worldofwarcraft.blizzard.com/pt-br/classicann/eu/armory/character/" -- Portugal (ptBR connected to US)
						elseif GameLocale == "enUS" and GetCurrentRegion() == 3 then LeaPlusLC.BlizzardLock = "https://worldofwarcraft.blizzard.com/en-gb/classicann/eu/armory/character/" -- UK (enUS connected to Europe)
						else 														 LeaPlusLC.BlizzardLock = "https://worldofwarcraft.blizzard.com/en-us/classicann/us/armory/character/" -- US (default)
						end
					end
					-- Player card (for the player under the mouse, or the player given to ShowInfoCard such as from the dressing room)
					local function ShowPlayerCard(unitFocus)
						-- Show armory link
						local name, realm = Safe(UnitName(unitFocus))
						local surname = isForever and realm or nil -- On Forever, the second name is the surname (and there is no armory link yet)
						local class = Safe(UnitClassBase(unitFocus))
						local color = class and RAID_CLASS_COLORS[class]
						if not color then return end
						if not realm then realm = Safe(GetNormalizedRealmName()) end
						if not (name and realm) then return end
						-- Debug
						-- local realm = "StrandoftheAncients" -- Debug
						-- Fix non-standard names
							if realm == "Area52" then realm = "Area-52"
						elseif realm == "AzjolNerub" then realm = "AzjolNerub"
						elseif realm == "Chantséternels" then realm = "Chants-Éternels"
						elseif realm == "ConfrérieduThorium" then realm = "Confrérie-du-Thorium"
						elseif realm == "ConseildesOmbres" then realm = "Conseil-des-Ombres"
						elseif realm == "CultedelaRivenoire" then realm = "Culte-de-la-Rive-noire"
						elseif realm == "DerRatvonDalaran" then realm = "Der-Rat-von-Dalaran"
						elseif realm == "DieewigeWacht" then realm = "Die-ewige-Wacht"
						elseif realm == "FestungderStürme" then realm = "Festung-der-Stürme"
						elseif realm == "KultderVerdammten" then realm = "Kult-der-Verdammten"
						elseif realm == "LaCroisadeécarlate" then realm = "La-Croisade-Écarlate"
						elseif realm == "MarécagedeZangar" then realm = "Marécage-de-Zangar"
						elseif realm == "Pozzodell'Eternità" then realm = "Pozzo-dellEternità"
						elseif realm == "Templenoir" then realm = "Temple-noir"
						elseif realm == "VanCleef" then realm = "Vancleef"
						elseif realm == "ZirkeldesCenarius" then realm = "Zirkel-des-Cenarius"
						-- Fix Russian names
						elseif realm == "СвежевательДуш" then realm = "Свежеватель-Душ"
						elseif realm == "СтражСмерти" then realm = "Страж-Смерти"
						elseif realm == "Ревущийфьорд" then realm = "Ревущий-фьорд"
						elseif realm == "ТкачСмерти" then realm = "Ткач-Смерти"
						elseif realm == "Борейскаятундра" then realm = "Борейская-тундра"
						elseif realm == "Ясеневыйлес" then realm = "Ясеневый-лес"
						elseif realm == "ПиратскаяБухта" then realm = "Пиратская-Бухта"
						elseif realm == "ВечнаяПесня" then realm = "Вечная-Песня"
						elseif realm == "ЧерныйШрам" then realm = "Черный-Шрам"
						elseif realm == "ВестникРока" then realm = "Вестник-Рока"
						-- Fix all other names
						else
							-- Realm name is not one of the above so fix it
							realm = realm:gsub("(%l[of])(%u)", "-%1-%2") -- Add hyphen after of if capital follows of (CavernsofTime becomes Cavernsof-Time)
							realm = realm:gsub("(ofthe)", "-of-the-") -- Replace ofthe with -of-the- (ShrineoftheDormantFlame becomes Shrine-of-the-DormantFlame)
							realm = realm:gsub("(%l)(%u)", "%1 %2") -- Add space before capital letters (CavernsofTime becomes Cavernsof Time)
							realm = realm:gsub(" ", "-") -- Replace space with hyphen (Cavernsof Time becomes Cavernsof-Time)
							realm = realm:gsub("'", "") -- Remove apostrophe
							realm = realm:gsub("[(]", "-") -- Replace opening parentheses with hyphen
							realm = realm:gsub("[)]", "") -- Remove closing parentheses
						end
						-- print(realm) -- Debug
						local armoryLink = LeaPlusLC.BlizzardLock .. strlower(realm) .. "/" .. strlower(name)
						realm = realm:gsub("-", " ") -- Replace hyphen with space
						local playerColor = {color.r, color.g, color.b}
						local playerLevel = Safe(UnitLevel(unitFocus))
						local playerName, realmText = name, realm
						if surname and surname ~= "" then playerName, realmText = name .. " " .. surname, Safe(GetRealmName()) or "" end
						local playerNote = realmText
						if type(playerLevel) == "number" and playerLevel > 0 then playerNote = L["Level"] .. " " .. playerLevel .. " " .. (Safe(UnitClass(unitFocus)) or "") .. "    " .. realmText end
						local unitGUID = Safe(UnitGUID(unitFocus))
						ShowIDCard({kind = L["Player"], name = playerName, sub = playerNote, url = not isForever and GameLocale ~= "zhCN" and armoryLink or nil, unit = unitFocus, color = playerColor, nameColor = playerColor, view = {mode = "unit", isPlayer = true, unit = unitFocus, guid = unitGUID, text = PlayerText(unitFocus)}, talents = true, details = PlayerDetails(unitFocus, unitGUID)})
						ShowPlayerTalents(unitFocus)
					end
					-- A player was given, so show their card and nothing else
					if forceUnit then
						if Safe(UnitExists(forceUnit)) and Safe(UnitIsPlayer(forceUnit)) then ShowPlayerCard(forceUnit) end
						return
					end
					-- Quest tracker (the list of quests under the minimap)
					local questID, questTitle
					do
						-- Modern tracker: look for a quest ID on the frame under the mouse or its parents
						local frame = GetMouseFoci and GetMouseFoci()[1]
						while frame and not questID do
							if frame.IsForbidden and frame:IsForbidden() then break end
							local id = Safe(frame.questID)
							if not id and Safe(frame.id) and frame.GetDebugName then
								local debugName = Safe(frame:GetDebugName())
								if type(debugName) == "string" and debugName:find("Quest") then id = Safe(frame.id) end
							end
							if type(id) == "number" then
								local title = Safe(C_QuestLog.GetTitleForQuestID(id))
								if title then questID, questTitle = id, title end
							end
							frame = frame:GetParent()
						end
						-- Classic tracker: find the hovered line and walk up to its quest title
						if not questID and QuestWatchFrame and QuestWatchFrame:IsShown() and QuestWatchFrame:IsMouseOver() then
							local hovered
							for i = 1, 50 do
								local watchLine = _G["QuestWatchLine" .. i]
								if not watchLine then break end
								if watchLine:IsShown() and watchLine:IsMouseOver() then hovered = i break end
							end
							if hovered then
								local titles = {}
								for i = 1, (Safe(C_QuestLog.GetNumQuestLogEntries()) or 0) do
									local info = SafeTable(C_QuestLog.GetInfo(i))
									local title, id = info and Safe(info.title), info and Safe(info.questID)
									if info and not Safe(info.isHeader) and type(title) == "string" and id then titles[title] = id end
								end
								for i = hovered, 1, -1 do
									local text = Safe(_G["QuestWatchLine" .. i]:GetText())
									if type(text) == "string" then
										text = strtrim((text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")))
										if titles[text] then questID, questTitle = titles[text], text break end
									end
								end
							end
						end
					end
					if questID then
						ShowIDCard({kind = L["Quest"], name = questTitle, id = questID, url = "https://" .. LeaPlusLC.WowheadLock .. "/quest=" .. questID, icon = "Interface\\Icons\\INV_Scroll_03", color = colorQuest, view = {mode = "icon", icon = "Interface\\Icons\\INV_Scroll_03", text = QuestText(questID)}, details = QuestDetails(questID)})
						return
					end
					-- ItemRefTooltip or GameTooltip
					local tooltip
					if ItemRefTooltip:IsMouseMotionFocus() then tooltip = ItemRefTooltip else tooltip = GameTooltip end
					-- Process tooltip
					if not tooltip:IsShown() then return end
					-- Buff or debuff (tooltip data, such as the buff frame)
					local tipData = SafeTable(tooltip.GetTooltipData and tooltip:GetTooltipData())
					if tipData and Safe(tipData.type) == Enum.TooltipDataType.UnitAura then
						local auraID = tipData.id
						if IsSecret(auraID) then
							-- Hidden by the game: show its name, ID and link without reading them
							local titleLine = _G[tooltip:GetName() .. "TextLeft1"]
							ShowHiddenAuraCard(auraID, titleLine and titleLine:GetText())
							return
						end
						if auraID then
							local auraName = Safe((C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(auraID)) or (GetSpellInfo and GetSpellInfo(auraID))) or Safe(GameTooltipTextLeft1:GetText()) or ""
							-- Debuff if the player or target has a debuff with this spell ID, otherwise buff
							local auraType = "Buff"
							for void, unit in ipairs({"player", "target"}) do
								if UnitExists(unit) then
									for i = 1, 40 do
										local aura, done = GetAura(unit, i, true)
										if done then break end
										if aura and Safe(aura.spellId) == auraID then auraType = "Debuff" break end
									end
								end
							end
							pickerUnit = nil -- Aura found so the aura picker is not needed
							ShowIDCard({kind = L[auraType], name = auraName, id = auraID, url = "https://" .. LeaPlusLC.WowheadLock .. "/spell=" .. auraID, icon = SpellIcon(auraID), color = auraType == "Debuff" and colorDebuff or colorBuff, view = {mode = "icon", icon = SpellIcon(auraID), text = SpellText(auraID)}, details = AuraDetails(nil, auraID)})
							return
						end
					end
					-- Item
					local itemLink = Safe(select(2, tooltip:GetItem()))
					if itemLink then
						local itemID = Safe(GetItemInfoFromHyperlink(itemLink))
						if itemID then
							local GetInfo = C_Item and C_Item.GetItemInfo or GetItemInfo
							local itemName, void, itemQuality, void, void, void, void, void, void, itemIcon = Safe(GetInfo(itemLink))
							local qualityColor = itemQuality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[itemQuality]
							local nameColor = qualityColor and {qualityColor.r, qualityColor.g, qualityColor.b} or {1, 1, 1}
							itemIcon = itemIcon or (C_Item and C_Item.GetItemIconByID and Safe(C_Item.GetItemIconByID(itemID))) or (GetItemIcon and Safe(GetItemIcon(itemID)))
							ShowIDCard({kind = L["Item"], name = itemName or itemLink, id = itemID, url = "https://" .. LeaPlusLC.WowheadLock .. "/item=" .. itemID, icon = itemIcon, color = nameColor, nameColor = nameColor, view = {mode = IsEquippable(itemLink) and "item" or "icon", link = itemLink, icon = itemIcon, text = ItemFlavour(tooltip)}, details = ItemDetails(itemLink, tooltip)})
							return
						end
					end
					-- Spell
					local name, spellID = Safe(tooltip:GetSpell())
					if name and spellID then
						ShowIDCard({kind = L["Spell"], name = name, id = spellID, url = "https://" .. LeaPlusLC.WowheadLock .. "/spell=" .. spellID, icon = SpellIcon(spellID), color = colorSpell, view = {mode = "icon", icon = SpellIcon(spellID), text = SpellText(spellID)}, details = SpellDetails(spellID)})
						return
					end
					-- Buff or debuff (match the tooltip title against auras on likely units)
					if not WorldFrame:IsMouseMotionFocus() then
						local titleLine = _G[tooltip:GetName() .. "TextLeft1"]
						local auraTitle = titleLine and Safe(titleLine:GetText())
						if auraTitle then
							local auraUnits = {}
							local tipUnit = Safe(select(2, tooltip:GetUnit()))
							if tipUnit then tinsert(auraUnits, tipUnit) end
							for void, unit in ipairs({"player", "target", "focus", "pet", "party1", "party2", "party3", "party4"}) do tinsert(auraUnits, unit) end
							for void, unit in ipairs(auraUnits) do
								if UnitExists(unit) then
									for void, auraType in ipairs({"Buff", "Debuff"}) do
										for i = 1, 40 do
											local aura, done = GetAura(unit, i, auraType == "Debuff")
											if done then break end
											local auraName, auraID = aura and Safe(aura.name), aura and Safe(aura.spellId)
											if auraName and auraID and auraName == auraTitle then
												local auraIcon = Safe(aura.icon) or SpellIcon(auraID)
												pickerUnit = nil -- Aura found so the aura picker is not needed
												ShowIDCard({kind = L[auraType], name = auraName, id = auraID, url = "https://" .. LeaPlusLC.WowheadLock .. "/spell=" .. auraID, icon = auraIcon, color = auraType == "Debuff" and colorDebuff or colorBuff, view = {mode = "icon", icon = auraIcon, text = SpellText(auraID)}, details = AuraDetails(aura.sourceUnit, auraID)})
												return
											end
										end
									end
								end
							end
						end
					end
					-- NPC (the name can be hidden in combat, the card is still shown)
					local npcName = Safe(UnitName("mouseover"))
					local npcGuid = Safe(UnitGUID("mouseover"))
					if not npcGuid then
						-- The mouseover unit is not always set yet, so use the creature in the tooltip itself
						local unitData = SafeTable(tooltip.GetTooltipData and tooltip:GetTooltipData())
						local dataGUID = unitData and Safe(unitData.type) == Enum.TooltipDataType.Unit and Safe(unitData.guid)
						if type(dataGUID) == "string" and (dataGUID:find("^Creature%-") or dataGUID:find("^Vehicle%-") or dataGUID:find("^Pet%-")) then
							npcGuid = dataGUID
							if not npcName then
								local title = Safe(GameTooltipTextLeft1:GetText())
								if type(title) == "string" then npcName = title:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "") end
							end
						end
					end
					if type(npcGuid) == "string" then
						local void, void, void, void, void, npcID = strsplit("-", npcGuid)
						if npcID then
							local reaction = Safe(UnitReaction("mouseover", "player"))
							local reactionColor = reaction and FACTION_BAR_COLORS and FACTION_BAR_COLORS[reaction]
							local npcColor = reactionColor and {reactionColor.r, reactionColor.g, reactionColor.b} or {1, 0.82, 0}
							local npcLevel = Safe(UnitLevel("mouseover"))
							local npcNote
							if type(npcLevel) == "number" then
								if npcLevel > 0 then npcNote = L["Level"] .. " " .. npcLevel else npcNote = L["Level"] .. " ??" end
							end
							local classification = Safe(UnitClassification("mouseover"))
							if npcNote and (classification == "elite" or classification == "worldboss") then npcNote = npcNote .. " " .. L["Elite"] elseif npcNote and classification == "rareelite" then npcNote = npcNote .. " " .. L["Rare Elite"] elseif npcNote and classification == "rare" then npcNote = npcNote .. " " .. L["Rare"] end
							ShowIDCard({kind = L["NPC"], name = npcName or L["Name not available right now"], id = npcID, url = "https://" .. LeaPlusLC.WowheadLock .. "/npc=" .. npcID, unit = "mouseover", color = npcColor, nameColor = npcColor, note = npcNote, view = {mode = "unit", unit = "mouseover", guid = npcGuid, npcID = npcID, text = NPCText(tooltip)}})
							return
						end
					end
					-- Pet, player and unknown tooltip (this must be last)
					if not GameTooltipTextLeft1:GetText() then return end
					-- Show armory link for players outside zhCN
					local unitFocus
					if WorldFrame:IsMouseMotionFocus() then unitFocus = "mouseover" else unitFocus = Safe(select(2, GameTooltip:GetUnit())) end
					if not unitFocus and UnitExists("mouseover") then unitFocus = "mouseover" end
					if unitFocus and Safe(UnitIsPlayer(unitFocus)) then
						ShowPlayerCard(unitFocus)
						return
					end
					-- Unknown tooltip
					-- A new player or creature can take a moment to load, so try again a few times before giving up
					if (UnitExists("mouseover") or WorldFrame:IsMouseMotionFocus() or GameTooltip:GetUnit()) and (LeaPlusLC.IDRetries or 0) < 4 then
						LeaPlusLC.IDRetries = (LeaPlusLC.IDRetries or 0) + 1
						local pressID = LeaPlusLC.IDPressID
						C_Timer.After(0.15, function() if LeaPlusLC.IDPressID == pressID then ShowInfoCard("retry") end end) -- Not if the key has been pressed again since
						return
					end
					LeaPlusLC.IDRetries = 0
					-- A player the game has not finished loading as a unit: always show a player card using the player in the tooltip itself
					-- (fill in what is known now, then refresh the card once the game has loaded the player)
					local unitData = SafeTable(GameTooltip.GetTooltipData and GameTooltip:GetTooltipData())
					local dataGUID = unitData and Safe(unitData.type) == Enum.TooltipDataType.Unit and Safe(unitData.guid)
					if type(dataGUID) == "string" and dataGUID:find("^Player%-") then
						local localizedClass, classFile, playerName, playerRealm
						if GetPlayerInfoByGUID then
							local void
							localizedClass, classFile, void, void, void, playerName, playerRealm = Safe(GetPlayerInfoByGUID(dataGUID))
						end
						if not classFile and Safe(UnitGUID("mouseover")) == dataGUID then
							classFile, localizedClass = Safe(UnitClassBase("mouseover")), Safe(UnitClass("mouseover"))
						end
						local classColor = classFile and RAID_CLASS_COLORS[classFile]
						local playerColor = classColor and {classColor.r, classColor.g, classColor.b} or {0.6, 0.6, 0.65}
						-- Name (the tooltip title already includes the surname on Forever)
						local titleName = (Safe(GameTooltipTextLeft1:GetText()) or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
						local displayName, realmText = titleName, Safe(GetRealmName()) or ""
						if playerName and playerName ~= "" then
							displayName = playerName
							if isForever and playerRealm and playerRealm ~= "" then displayName = playerName .. " " .. playerRealm
							elseif playerRealm and playerRealm ~= "" then realmText = playerRealm end
						end
						if displayName == "" then displayName = L["Name not available right now"] end
						local armoryLink
						if not isForever and GameLocale ~= "zhCN" and playerName and playerName ~= "" then
							local realmSlug = ((playerRealm and playerRealm ~= "") and playerRealm or Safe(GetNormalizedRealmName()) or ""):gsub("(%l)(%u)", "%1-%2"):gsub("'", ""):gsub(" ", "-")
							armoryLink = LeaPlusLC.BlizzardLock .. strlower(realmSlug) .. "/" .. strlower(playerName)
						end
						local coords = classFile and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[classFile]
						local subText = localizedClass and (localizedClass .. "    " .. realmText) or realmText
						ShowIDCard({kind = L["Player"], name = displayName, sub = subText, url = armoryLink, icon = coords and "Interface\\TargetingFrame\\UI-Classes-Circles" or 134400, iconCoords = coords, color = playerColor, nameColor = playerColor, view = {mode = "unit", isPlayer = true, guid = dataGUID}, details = PlayerDetails(nil, dataGUID)})
						-- Refresh the card while the mouse is still over the same player, to get the full card
						-- (a player the game has not seen before can take a few seconds to load, so keep checking for about 3 seconds)
						LeaPlusLC.IDCard.upgradeGUID = dataGUID
						if (LeaPlusLC.IDUpgrades or 0) == 0 then -- One check loop per key press
							LeaPlusLC.IDUpgrades = 1
							local pressID, waited = LeaPlusLC.IDPressID, 0
							local function Wait()
								local c = LeaPlusLC.IDCard
								-- Stop once the full card is showing, the card is closed or shows something else, or the key has been pressed again
								if not (c and c:IsShown()) or c.upgradeGUID ~= dataGUID or LeaPlusLC.IDPressID ~= pressID then return end
								if Safe(UnitGUID("mouseover")) == dataGUID then
									LeaPlusLC.IDRetries = 0
									ShowInfoCard("upgrade")
								end
								waited = waited + 0.3
								if waited < 3 then C_Timer.After(0.3, Wait) end
							end
							C_Timer.After(0.3, Wait)
						end
						return
					end
					-- Anything else is not known, so show nothing
				end
				ShowCardForMouse()
				-- Aura picker: list the buffs and debuffs of the hovered unit frame (addons cannot tell which aura icon is under the mouse)
				local function ShowAuraPicker()
					-- Collect auras (auras the game hides are left out)
					local auras = {}
					for void, auraType in ipairs({"Buff", "Debuff"}) do
						for i = 1, 40 do
							local aura, done = GetAura(pickerUnit, i, auraType == "Debuff")
							if done then break end
							local auraName, auraID, auraIcon = aura and Safe(aura.name), aura and Safe(aura.spellId), aura and Safe(aura.icon)
							if auraName and auraID and auraIcon then
								tinsert(auras, {auraType = auraType, name = auraName, spellID = auraID, icon = auraIcon, source = Safe(aura.sourceUnit)})
							end
						end
					end
					if #auras == 0 then return end
					-- Show the card for an aura and mark it in the list
					local picker
					local function ShowAuraLink(info)
						ShowIDCard({kind = L[info.auraType], name = info.name, id = info.spellID, url = "https://" .. LeaPlusLC.WowheadLock .. "/spell=" .. info.spellID, icon = info.icon, color = info.auraType == "Debuff" and colorDebuff or colorBuff, view = {mode = "icon", icon = info.icon, text = SpellText(info.spellID)}, details = AuraDetails(info.source, info.spellID)})
						if LeaPlusLC.AuraPicker then
							for void, row in ipairs(LeaPlusLC.AuraPicker.rows) do row.selected:SetShown(row.info == info) end
						end
					end
					-- If nothing else is showing (such as a buff icon), start with the first aura
					local startWithFirst = not LeaPlusLC.IDCard or not LeaPlusLC.IDCard:IsShown()
					if startWithFirst then ShowAuraLink(auras[1]) end
					local card = LeaPlusLC.IDCard
					-- Create the picker (a child of the card so it closes with it)
					local cols, rowHeight = 2, 26
					local colWidth = (480 - 24) / cols
					picker = LeaPlusLC.AuraPicker
					if not picker then
						picker = CreateFrame("Frame", nil, card, "BackdropTemplate")
						LeaPlusLC.AuraPicker = picker
						picker:SetPoint("BOTTOMLEFT", card, "TOPLEFT", 0, 6) -- Above the card so it does not cover the action bars
						picker:SetPoint("BOTTOMRIGHT", card, "TOPRIGHT", 0, 6)
						picker:EnableMouse(true)
						picker:SetScript("OnMouseDown", function(self, btn) if btn == "RightButton" then card:Hide() end end)
						picker:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = OnePixel()})
						picker:SetBackdropColor(0.06, 0.06, 0.08, 0.96)
						picker:SetBackdropBorderColor(1, 1, 1, 0.12)
						picker.title = picker:CreateFontString(nil, "OVERLAY", "GameFontNormal")
						picker.title:SetPoint("TOPLEFT", picker, "TOPLEFT", 14, -10)
						picker.hint = picker:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
						picker.hint:SetPoint("TOPRIGHT", picker, "TOPRIGHT", -14, -12)
						picker.hint:SetText(L["Click a buff or debuff to show its link."])
						picker.rows = {}
					end
					-- Name (on Forever, players' second name is their surname)
					local pickerName, pickerSurname = Safe(UnitName(pickerUnit))
					if isForever and pickerName and pickerSurname and pickerSurname ~= "" and Safe(UnitIsPlayer(pickerUnit)) then pickerName = pickerName .. " " .. pickerSurname end
					picker.title:SetText(pickerName or "")
					-- Fill the rows
					for i, info in ipairs(auras) do
						local row = picker.rows[i]
						if not row then
							row = CreateFrame("Button", nil, picker)
							row:SetSize(colWidth - 4, rowHeight - 2)
							row.bg = row:CreateTexture(nil, "BACKGROUND")
							row.bg:SetAllPoints()
							row.bg:SetColorTexture(1, 1, 1, 0.03)
							row.selected = row:CreateTexture(nil, "BORDER")
							row.selected:SetAllPoints()
							row.selected:SetColorTexture(1, 1, 1, 0.1)
							row.icon = row:CreateTexture(nil, "ARTWORK")
							row.icon:SetSize(rowHeight - 6, rowHeight - 6)
							row.icon:SetPoint("LEFT", row, "LEFT", 2, 0)
							row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
							row.text = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
							row.text:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
							row.text:SetPoint("RIGHT", row, "RIGHT", -6, 0)
							row.text:SetJustifyH("LEFT")
							row.text:SetWordWrap(false)
							row:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
							row:GetHighlightTexture():SetVertexColor(1, 1, 1, 0.08)
							row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
							row:SetScript("OnClick", function(self, btn)
								if btn == "RightButton" then card:Hide() else ShowAuraLink(self.info) end
							end)
							picker.rows[i] = row
						end
						row.info = info
						row.icon:SetTexture(info.icon)
						if info.auraType == "Debuff" then row.text:SetTextColor(1, 0.45, 0.45) else row.text:SetTextColor(0.45, 1, 0.55) end
						row.text:SetText(info.name .. "  |cff8a8a90" .. info.spellID .. "|r")
						row.selected:SetShown(startWithFirst and i == 1)
						row:ClearAllPoints()
						row:SetPoint("TOPLEFT", picker, "TOPLEFT", 12 + ((i - 1) % cols) * colWidth, -34 - math.floor((i - 1) / cols) * rowHeight)
						row:Show()
					end
					for i = #auras + 1, #picker.rows do picker.rows[i]:Hide() end
					picker:SetHeight(34 + math.ceil(#auras / cols) * rowHeight + 10)
					picker:Show()
				end
				if pickerUnit then ShowAuraPicker() end
			end

			-- Hidden button that the key clicks (the key is bound to it in the addon code, no Bindings.xml entry needed)
			local InfoButton = CreateFrame("Button", "LeaPlusGlobalInfoButton", UIParent)
			InfoButton:Hide()
			InfoButton:RegisterForClicks("AnyDown")
			InfoButton:SetScript("OnClick", function()
				ShowInfoCard()
			end)

			-- Show the card for a player unit (used by the dressing room)
			LeaPlusLC.ShowInfoCardForUnit = function(unit) ShowInfoCard(nil, unit) end

			-- Create configuration panel
			local InfoCardPanel = LeaPlusLC:CreatePanel("Show info cards", "InfoCardPanel")

			-- Key section
			LeaPlusLC:MakeTx(InfoCardPanel, "Key", 16, -72)
			local keyText = LeaPlusLC:MakeWD(InfoCardPanel, "", 16, -92)
			keyText:SetWidth(530)

			local setBtn = LeaPlusLC:CreateButton("InfoCardSetKeyBtn", InfoCardPanel, "Set key", "TOPLEFT", 16, -116, 0, 25, true, "Click, then press the key you want to use.|n|nYou can include Shift, Ctrl or Alt.|n|nPress Escape to cancel.|n|nThis does not change your saved key bindings.  If the key already does something, it will go back to doing that when you clear the key or turn this option off.")
			local clearBtn = LeaPlusLC:CreateButton("InfoCardClearKeyBtn", InfoCardPanel, "Clear key", "TOPLEFT", 16, -116, 0, 25, true, "Click to remove the key.  Anything the key did before will work again.")
			clearBtn:ClearAllPoints()

			-- Make the set key button wide enough for both of its labels
			setBtn.f:SetText(L["Press a key"])
			local wideLabel = setBtn.f:GetStringWidth()
			setBtn.f:SetText(L["Set key"])
			setBtn:SetWidth(math.max(wideLabel, setBtn.f:GetStringWidth()) + 20)
			clearBtn:SetPoint("LEFT", setBtn, "RIGHT", 10, 0)

			-- How to use section
			LeaPlusLC:MakeTx(InfoCardPanel, "How to use", 16, -162)
			local howText = LeaPlusLC:MakeWD(InfoCardPanel, "Point at a player, NPC, item, spell, buff or quest and press the key.  A card will show its details and a link to it on Wowhead.|n|nWhile the card is showing, hold Ctrl and press C to copy the link, then paste it into your web browser.", 16, -182)
			howText:SetWidth(530)
			howText:SetWordWrap(true)
			howText:SetSpacing(2)

			-- Show the current key
			local function KeyName(key)
				return GetBindingText and GetBindingText(key) or key
			end

			local listening = false
			local applyPending = false

			-- Apply the keybind
			local function ApplyKey()
				if InCombatLockdown() then
					applyPending = true
					return
				end
				applyPending = false
				ClearOverrideBindings(InfoCardPanel)
				if LeaPlusLC["ShowInfoCards"] == "On" and LeaPlusLC["InfoCardKey"] ~= "" then
					SetOverrideBindingClick(InfoCardPanel, false, LeaPlusLC["InfoCardKey"], "LeaPlusGlobalInfoButton")
				end
			end

			local function Refresh()
				if listening then
					keyText:SetText(L["Press the key you want to use (Escape to cancel)."])
					setBtn:SetText(L["Press a key"])
					return
				end
				setBtn:SetText(L["Set key"])
				local text
				if LeaPlusLC["InfoCardKey"] ~= "" then
					text = L["Current key"] .. ": |cff00ff00" .. KeyName(LeaPlusLC["InfoCardKey"]) .. "|r"
					clearBtn:Enable()
				else
					text = L["Current key"] .. ": |cffff8080" .. L["None"] .. "|r"
					clearBtn:Disable()
				end
				keyText:SetText(text)
			end

			local function StopListening()
				listening = false
				setBtn:EnableKeyboard(false)
				Refresh()
			end

			-- Capture the next key pressed
			local modifierKeys = {LSHIFT = true, RSHIFT = true, LCTRL = true, RCTRL = true, LALT = true, RALT = true, LMETA = true, RMETA = true}

			setBtn:SetScript("OnKeyDown", function(self, key)
				if not listening then return end
				if modifierKeys[key] then return end
				if key == "ESCAPE" then
					StopListening()
					return
				end
				if InCombatLockdown() then
					StopListening()
					LeaPlusLC:Print("You cannot do that in combat.")
					return
				end
				local combo = (IsAltKeyDown() and "ALT-" or "") .. (IsControlKeyDown() and "CTRL-" or "") .. (IsShiftKeyDown() and "SHIFT-" or "") .. (IsMetaKeyDown and IsMetaKeyDown() and "META-" or "") .. key
				local oldAction = GetBindingAction(combo)
				LeaPlusLC["InfoCardKey"] = combo
				ApplyKey()
				if oldAction and oldAction ~= "" then
					local oldName = _G["BINDING_NAME_" .. oldAction] or oldAction
					LeaPlusLC:Print(L["Key set to"] .. " " .. KeyName(combo) .. ".  " .. L["It normally does"] .. " " .. oldName .. ", " .. L["and will again when you clear the key."])
				else
					LeaPlusLC:Print(L["Key set to"] .. " " .. KeyName(combo) .. ".")
				end
				StopListening()
			end)

			-- Setting a key script turns keyboard input on by itself, so turn it off until the button is clicked
			setBtn:EnableKeyboard(false)

			setBtn:SetScript("OnClick", function()
				if InCombatLockdown() then
					LeaPlusLC:Print("You cannot do that in combat.")
					return
				end
				if listening then
					StopListening()
				else
					listening = true
					setBtn:EnableKeyboard(true)
					setBtn:SetPropagateKeyboardInput(false)
					Refresh()
				end
			end)

			clearBtn:SetScript("OnClick", function()
				if InCombatLockdown() then
					LeaPlusLC:Print("You cannot do that in combat.")
					return
				end
				LeaPlusLC["InfoCardKey"] = ""
				ApplyKey()
				Refresh()
			end)

			-- Turning the option on or off sets or removes the key
			LeaPlusCB["ShowInfoCards"]:HookScript("OnClick", ApplyKey)

			InfoCardPanel:HookScript("OnShow", Refresh)
			InfoCardPanel:HookScript("OnHide", function() if listening then StopListening() end end)
			InfoCardPanel:RegisterEvent("UPDATE_BINDINGS")
			InfoCardPanel:RegisterEvent("PLAYER_REGEN_DISABLED")
			InfoCardPanel:RegisterEvent("PLAYER_REGEN_ENABLED")
			InfoCardPanel:SetScript("OnEvent", function(self, event)
				if event == "PLAYER_REGEN_DISABLED" then
					-- Entering combat, stop listening so key presses reach the game
					if listening then StopListening() end
				elseif event == "PLAYER_REGEN_ENABLED" then
					-- Set the key if it could not be set during combat
					if applyPending then ApplyKey() end
				elseif InfoCardPanel:IsShown() then
					Refresh()
				end
			end)

			-- Set the key now
			ApplyKey()

			-- Help and reset buttons hidden
			InfoCardPanel.h:Hide()
			InfoCardPanel.r:Hide()

			-- Back button handler
			InfoCardPanel.b:SetScript("OnClick", function()
				InfoCardPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page5"]:Show()
				return
			end)

			-- Show configuration panel when options panel button is clicked
			LeaPlusCB["ShowInfoCardsBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile (nothing to set)
				else
					InfoCardPanel:Show()
					LeaPlusLC:HideFrames()
				end
			end)

		end

		----------------------------------------------------------------------
		-- Show range coloring
		----------------------------------------------------------------------

		if LeaPlusLC["ShowRangeColoring"] == "On" then

			-- Colors (red, green, blue, desaturate)
			local stateColors = {
				normal		= {1.0, 1.0, 1.0, false},	-- Usable
				range		= {1.0, 0.3, 0.1, true},	-- Out of range
				mana		= {0.1, 0.3, 1.0, true},	-- Not enough mana
				unusable	= {0.4, 0.4, 0.4, false},	-- Not usable
			}

			-- Upvalues
			local IsActionInRange, IsUsableAction, GetActionInfo, GetMacroInfo, GetMacroSpell = IsActionInRange, IsUsableAction, GetActionInfo, GetMacroInfo, GetMacroSpell
			local IsSpellUsable = C_Spell and C_Spell.IsSpellUsable or IsUsableSpell
			local hooksecurefunc, pairs, strsub = hooksecurefunc, pairs, strsub

			-- Button data is stored locally
			local hookedButtons = {}	-- Buttons which have been set up
			local iconStates = {}		-- Icon texture -> last applied state
			local hotkeyStates = {}		-- Hotkey text -> last applied state
			local flashGroups = {}		-- Button -> attack flash animation

			----------------------------------------------------------------------
			-- Coloring
			----------------------------------------------------------------------

			-- Function to color an icon
			local function SetIconState(icon, state)
				iconStates[icon] = state
				local c = stateColors[state]
				icon:SetVertexColor(c[1], c[2], c[3])
				icon:SetDesaturated(c[4])
			end

			-- Function to color a hotkey
			local function SetHotkeyState(hotkey, state)
				hotkeyStates[hotkey] = state
				local c = stateColors[state]
				hotkey:SetVertexColor(c[1], c[2], c[3])
			end

			-- Function to get the state of an action slot (second return is true if out of range)
			local function GetActionState(slot)
				local isUsable, notEnoughMana
				-- Macros with names starting with # use the macro spell for the mana check
				local actionType, id = GetActionInfo(slot)
				if actionType == "macro" then
					local name = GetMacroInfo(id)
					if name and strsub(name, 1, 1) == "#" then
						local spellID = GetMacroSpell(id)
						if spellID then
							isUsable, notEnoughMana = IsSpellUsable(spellID)
						end
					end
				end
				if isUsable == nil then
					isUsable, notEnoughMana = IsUsableAction(slot)
				end
				local outOfRange = IsActionInRange(slot) == false
				if isUsable then
					return outOfRange and "range" or "normal", outOfRange
				elseif notEnoughMana then
					return "mana", outOfRange
				end
				return "unusable", outOfRange
			end

			-- Function to get the state of a pet action
			local function GetPetActionState(index)
				local void, void, void, void, void, void, spellID, checksRange, inRange = GetPetActionInfo(index)
				local outOfRange = checksRange and not inRange
				local isUsable, notEnoughMana
				if spellID then
					isUsable, notEnoughMana = IsSpellUsable(spellID)
				else
					isUsable, notEnoughMana = GetPetActionSlotUsable(index), false
				end
				if isUsable then
					return outOfRange and "range" or "normal"
				elseif notEnoughMana then
					return "mana"
				end
				return "unusable"
			end

			-- Function to color an action button (runs after the game colors it)
			local function UpdateActionButton(button)
				local state, outOfRange = GetActionState(button.action)
				SetIconState(button.icon, state)
				SetHotkeyState(button.HotKey, outOfRange and "range" or "normal")
			end

			-- Function to update range coloring when the game says the range has changed
			-- (only switches between usable and out of range, other states are left alone)
			local function UpdateRange(button, checksRange, inRange)
				if not hookedButtons[button] then return end
				local outOfRange = checksRange and not inRange
				local icon, hotkey = button.icon, button.HotKey
				local state = iconStates[icon]
				if state == "normal" and outOfRange then
					SetIconState(icon, "range")
				elseif state == "range" and not outOfRange then
					SetIconState(icon, "normal")
				end
				state = hotkeyStates[hotkey]
				if state == "normal" and outOfRange then
					SetHotkeyState(hotkey, "range")
				elseif state == "range" and not outOfRange then
					SetHotkeyState(hotkey, "normal")
				end
			end

			-- Function to color the pet bar
			local function UpdatePetBar(bar)
				if not PetHasActionBar() then return end
				for index, button in pairs(bar.actionButtons) do
					local icon = button.icon
					if icon:IsVisible() then
						SetIconState(icon, GetPetActionState(index))
					end
				end
			end

			----------------------------------------------------------------------
			-- Attack flash (animation instead of the game's update loop)
			----------------------------------------------------------------------

			-- Function to start flashing
			local function StartFlashing(button)
				local ag = flashGroups[button]
				if not ag then
					ag = button.Flash:CreateAnimationGroup()
					ag:SetLooping("BOUNCE")
					local fade = ag:CreateAnimation("Alpha")
					fade:SetDuration(ATTACK_BUTTON_FLASH_TIME * 2)
					fade:SetFromAlpha(0)
					fade:SetToAlpha(0.7)
					flashGroups[button] = ag
				end
				button.Flash:Show()
				ag:Play()
			end

			-- Function to stop flashing
			local function StopFlashing(button)
				local ag = flashGroups[button]
				if ag then
					ag:Stop()
					button.Flash:Hide()
				end
			end

			-- Start flashing when the game starts the flash
			local function FlashStarted(button)
				if button:IsVisible() then
					StartFlashing(button)
				end
			end

			-- Start or stop flashing when the button is shown or hidden
			local function FlashShownOrHidden(button)
				if (button.flashing == 1 or button.flashing == true) and button:IsVisible() then
					StartFlashing(button)
				else
					StopFlashing(button)
				end
			end

			----------------------------------------------------------------------
			-- Setup
			----------------------------------------------------------------------

			-- Function to set up an action button
			local function SetupActionButton(button)
				if hookedButtons[button] then return end
				hooksecurefunc(button, "UpdateUsable", UpdateActionButton)
				button:HookScript("OnShow", FlashShownOrHidden)
				button:HookScript("OnHide", FlashShownOrHidden)
				hooksecurefunc(button, "StartFlash", FlashStarted)
				hookedButtons[button] = true
			end

			-- Function to set up a pet button
			local function SetupPetButton(button)
				if hookedButtons[button] then return end
				hooksecurefunc(button, "StartFlash", FlashStarted)
				button:HookScript("OnShow", FlashShownOrHidden)
				button:HookScript("OnHide", FlashShownOrHidden)
				hookedButtons[button] = true
			end

			-- Set up action buttons (including any created later)
			ActionBarButtonEventsFrame:ForEachFrame(SetupActionButton)
			hooksecurefunc(ActionBarButtonEventsFrame, "RegisterFrame", function(void, button)
				SetupActionButton(button)
			end)

			-- Range changes are event driven (the game calls this from ACTION_RANGE_CHECK_UPDATE)
			hooksecurefunc("ActionButton_UpdateRangeIndicator", UpdateRange)

			-- Turn off the game's action button update loop (the attack flash is now an animation)
			ActionBarButtonUpdateFrame:SetScript("OnUpdate", nil)

			-- Set up pet buttons and update the pet bar when it changes or pet power changes
			if PetActionBar and PetActionBar.actionButtons then
				for void, button in pairs(PetActionBar.actionButtons) do
					SetupPetButton(button)
				end
				hooksecurefunc(PetActionBar, "Update", UpdatePetBar)
				local petFrame = CreateFrame("FRAME")
				petFrame:RegisterUnitEvent("UNIT_POWER_UPDATE", "pet")
				petFrame:SetScript("OnEvent", function()
					UpdatePetBar(PetActionBar)
				end)
			end

			-- Color everything once at startup
			C_Timer.After(1 / 30, function()
				ActionBarButtonEventsFrame:ForEachFrame(UpdateActionButton)
				if PetActionBar and PetActionBar.actionButtons then
					UpdatePetBar(PetActionBar)
				end
			end)

		end

		----------------------------------------------------------------------
		-- Simple addon list
		----------------------------------------------------------------------

		if LeaPlusLC["SimpleAddonListing"] == "On" then

			-- Strip Wow color codes
			local function StripColors(s) return (s or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "") end

			-- Build, filter, sort and feed the list in one pass
			local function UpdateList()
				local provider   = CreateTreeDataProvider()
				local filter     = AddonList.SearchBox:GetText():lower()
				local groups     = {}

				for i = 1, C_AddOns.GetNumAddOns() do
					local name, title = C_AddOns.GetAddOnInfo(i)
					local group = C_AddOns.GetAddOnMetadata(i, "Group") or name
					local searchable = (StripColors(title or name) .. StripColors(group)):lower()

					if filter == "" or searchable:find(filter, 1, true) then
						groups[group] = groups[group] or {parent = {addonIndex = i}, children = {}}
						if name == group then
							groups[group].parent = {addonIndex = i}
						else
							table.insert(groups[group].children, {addonIndex = i})
						end
					end
				end

				-- Sort groups alphabetically (ignoring color codes)
				local sortedGroups = {}
				for g in pairs(groups) do table.insert(sortedGroups, g) end
				table.sort(sortedGroups, function(a, b) return StripColors(a):lower() < StripColors(b):lower() end)

				-- Insert sorted groups and their sorted children into the provider
				for void, gName in ipairs(sortedGroups) do
					local node = provider:Insert(groups[gName].parent)

					local ch = groups[gName].children
					table.sort(ch, function(a, b)
						local aT = StripColors(select(2, C_AddOns.GetAddOnInfo(a.addonIndex)) or ""):lower()
						local bT = StripColors(select(2, C_AddOns.GetAddOnInfo(b.addonIndex)) or ""):lower()
						return aT < bT
					end)

					for void, child in ipairs(ch) do node:Insert(child) end
				end

				AddonList.ScrollBox:SetDataProvider(provider, ScrollBoxConstants.RetainScrollPosition)
				AddonList.ScrollBox:Show()
			end

			AddonList.SearchBox:HookScript("OnTextChanged", UpdateList)
			hooksecurefunc("AddonList_Update", UpdateList)
			AddonList:HookScript("OnShow", function()
				AddonList.ScrollBox:Hide()
				C_Timer.After(0, UpdateList)
			end)

		end

		----------------------------------------------------------------------
		-- Set edit mode layout
		----------------------------------------------------------------------

		do

			-- Create configuration panel
			local LayoutPanel = LeaPlusLC:CreatePanel("Set edit mode layout", "LayoutPanel")

			local titleTX = LeaPlusLC:MakeTx(LayoutPanel, "Layout name", 16, -72)
			local LayoutBox = LeaPlusLC:CreateEditBox("LayoutBox", LayoutPanel, 500, 40, "TOPLEFT", 20, -92, "LayoutBox", "LayoutBox")

			LeaPlusLC:CreateHelpButton("EditModeLayoutNameHelpButton", LayoutPanel, titleTX, "If the edit mode layout name that you enter here exists, that layout will be applied when you login to any character on your account.")

			-- Apply the layout on login if it is not already active
			if LeaPlusLC["SetEditModeLayout"] == "On" then

				local function TryApplyLayout()
					local wanted = strtrim(tostring(LeaPlusLC["EditModeLayoutName"] or "")):lower()
					if wanted == "" then return true end
					if not EditModeManagerFrame or not EditModeManagerFrame.layoutInfo then return false end
					local layouts = EditModeManagerFrame:GetLayouts()
					if type(layouts) ~= "table" or #layouts == 0 then return false end
					local active = EditModeManagerFrame:GetActiveLayoutInfo()
					for index, layout in ipairs(layouts) do
						if layout.layoutName and layout.layoutName:lower() == wanted then
							if not (active and active.layoutName and active.layoutName:lower() == wanted) then
								C_EditMode.SetActiveLayout(index)
								LeaPlusLC:Print(L["Edit Mode layout"] .. " '" .. layout.layoutName .. "' " .. L["applied"])
							end
							return true
						end
					end
					return true
				end

				-- Layouts already loaded (e.g. after /reload)
				if not TryApplyLayout() then
					-- Cold login: wait until the layouts arrive, then apply once
					local f = CreateFrame("Frame")
					local done = false
					f:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
					f:SetScript("OnEvent", function(self)
						C_Timer.After(0, function()
							if done then return end
							if TryApplyLayout() then
								done = true
								self:UnregisterAllEvents()
							end
						end)
					end)
				end

			end

			-- Function to save the keyword
			local function SetEditModeName()
				local LayoutText = LayoutBox:GetText()
				if LayoutText and LayoutText ~= "" then
					LeaPlusLC["EditModeLayoutName"] = strtrim(LayoutBox:GetText())
				else
					LeaPlusLC["EditModeLayoutName"] = ""
				end
			end

			-- Save the keyword when it changes
			LayoutBox:SetScript("OnTextChanged", SetEditModeName)

			-- Refresh editbox with trimmed keyword when edit focus is lost (removes additional spaces)
			LayoutBox:SetScript("OnEditFocusLost", function()
				LayoutBox:SetText(LeaPlusLC["EditModeLayoutName"])
			end)

			-- Help button hidden
			LayoutPanel.h:Hide()

			-- Back button handler
			LayoutPanel.b:SetScript("OnClick", function()
				-- Save the keyword
				SetEditModeName()
				-- Show the options panel
				LayoutPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page8"]:Show()
				return
			end)

			-- Add reset button
			LayoutPanel.r:SetScript("OnClick", function()
				-- Reset the keyword to default
				LeaPlusLC["EditModeLayoutName"] = ""
				-- Set the editbox to default
				LayoutBox:SetText("")
				-- Save the keyword
				SetEditModeName()
				-- Refresh panel
				LayoutPanel:Hide(); LayoutPanel:Show()
			end)

			-- Ensure keyword is a string on startup
			LeaPlusLC["EditModeLayoutName"] = tostring(LeaPlusLC["EditModeLayoutName"] or "")

			-- Set editbox value when shown
			LayoutBox:HookScript("OnShow", function()
				LayoutBox:SetText(LeaPlusLC["EditModeLayoutName"])
			end)

			-- Configuration button handler
			LeaPlusCB["SetEditModeLayoutBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					LeaPlusLC["EditModeLayoutName"] = "Main"
					LayoutBox:SetText(LeaPlusLC["EditModeLayoutName"])
					SetEditModeName()
				else
					-- Show panel
					LayoutPanel:Show()
					LeaPlusLC:HideFrames()
				end
			end)

		end

		----------------------------------------------------------------------
		-- Hide raid group labels
		----------------------------------------------------------------------

		if LeaPlusLC["HideRaidGroupLabels"] == "On" then

			-- Hide player frame group indiciator labels
			hooksecurefunc("PlayerFrame_UpdateGroupIndicator", function()
				if PlayerFrameGroupIndicator:IsShown() then
					PlayerFrameGroupIndicator:Hide()
				end
			end)

			EventUtil.ContinueOnAddOnLoaded("Blizzard_RaidUI", function()
				-- Hide raid pullout frame labels
				hooksecurefunc("RaidPullout_Update", function(frame)
					if frame then
						local frameName = frame:GetName()
						if frameName then
							local title = _G[frameName .. "Name"]
							if title and title:IsShown() then
								title:Hide()
							end
						end
					end
				end)

				-- Hide raid container group titles
				local function HideRaidContainerGroupTitles(groupIndex)
					if groupIndex then
						local frame = _G["CompactRaidGroup" .. groupIndex]
						if frame then
							frame.title:Hide()
						end
					end
				end

				hooksecurefunc("CompactRaidGroup_GenerateForGroup", function(index)
					HideRaidContainerGroupTitles(index)
				end)

				for index = 1, 8 do
					HideRaidContainerGroupTitles(index)
				end

			end)

			-- Hide compact party frame title
			if CompactPartyFrame and CompactPartyFrame.title and CompactPartyFrame.title:IsShown() then CompactPartyFrame.title:Hide() end
			hooksecurefunc("CompactPartyFrame_Generate", function()
				if CompactPartyFrame and CompactPartyFrame.title and CompactPartyFrame.title:IsShown() then
					CompactPartyFrame.title:Hide()
				end
			end)

		end

		----------------------------------------------------------------------
		-- Block friend requests (no reload required)
		----------------------------------------------------------------------

		-- Function to decline friend requests
		local function DeclineReqs()
			if LeaPlusLC["NoFriendRequests"] == "On" then
				for i = BNGetNumFriendInvites(), 1, -1 do
					local id, player = BNGetFriendInviteInfo(i)
					if id and player then
						BNDeclineFriendInvite(id)
						C_Timer.After(0.1, function()
							LeaPlusLC:Print(L["A friend request from"] .. " " .. player .. " " .. L["was automatically declined."])
						end)
					end
				end
			end
		end

		-- Event frame for incoming friend requests
		local DecEvt = CreateFrame("FRAME")
		DecEvt:SetScript("OnEvent", DeclineReqs)

		-- Function to register or unregister the event
		local function ControlEvent()
			if LeaPlusLC["NoFriendRequests"] == "On" then
				DecEvt:RegisterEvent("BN_FRIEND_INVITE_ADDED")
				DeclineReqs()
			else
				DecEvt:UnregisterEvent("BN_FRIEND_INVITE_ADDED")
			end
		end

		-- Set event status when option is clicked and on startup
		LeaPlusCB["NoFriendRequests"]:HookScript("OnClick", ControlEvent)
		ControlEvent()

		----------------------------------------------------------------------
		--	Block duels (no reload required)
		----------------------------------------------------------------------

		do

			-- Handler for event
			local frame = CreateFrame("FRAME")
			frame:SetScript("OnEvent", function(self, event, arg1)
				if event == "DUEL_REQUESTED" and not LeaPlusLC:FriendCheck(arg1) then
					CancelDuel()
					StaticPopup_Hide("DUEL_REQUESTED")
					return
				elseif event == "DUEL_TO_THE_DEATH_REQUESTED" and not LeaPlusLC:FriendCheck(arg1) then
					CancelDuel()
					StaticPopup_Hide("DUEL_TO_THE_DEATH_REQUESTED")
					return
				end
			end)

			-- Function to set event
			local function SetEvent()
				if LeaPlusLC["NoDuelRequests"] == "On" then
					frame:RegisterEvent("DUEL_REQUESTED")
					frame:RegisterEvent("DUEL_TO_THE_DEATH_REQUESTED")
				else
					frame:UnregisterEvent("DUEL_REQUESTED")
					frame:UnregisterEvent("DUEL_TO_THE_DEATH_REQUESTED")
				end
			end

			-- Set event on startup if enabled and when option is clicked
			if LeaPlusLC["NoDuelRequests"] == "On" then SetEvent() end
			LeaPlusCB["NoDuelRequests"]:HookScript("OnClick", SetEvent)

		end

		----------------------------------------------------------------------
		--	Invite from whispers (no reload required)
		----------------------------------------------------------------------

		do

			local frame = CreateFrame("FRAME")
			frame:SetScript("OnEvent", function(self, event, arg1, arg2, ...)
				if (not UnitExists("party1") or UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) and strlower(strtrim(arg1)) == strlower(LeaPlusLC["InvKey"]) then
					if not LeaPlusLC:IsInLFGQueue() then
						if event == "CHAT_MSG_WHISPER" then
							local void, void, void, void, void, void, void, void, void, guid = ...
							if LeaPlusLC:FriendCheck(arg2, guid) or LeaPlusLC["InviteFriendsOnly"] == "Off" then
								-- If whisper name is same realm, remove realm name
								local theWhisperName, theWhisperRealm = strsplit("-", arg2, 2)
								if theWhisperRealm then
									local void, theCharRealm = UnitFullName("player")
									if theCharRealm then
										if theWhisperRealm == theCharRealm then arg2 = theWhisperName end
									end
								end

								-- Invite whisper player
								C_PartyInfo.InviteUnit(arg2)
							end
						elseif event == "CHAT_MSG_BN_WHISPER" then
							local presenceID = select(11, ...)
							if presenceID and BNIsFriend(presenceID) then
								local index = BNGetFriendIndex(presenceID)
								if index then
									local accountInfo = C_BattleNet.GetFriendAccountInfo(index)
									local gameAccountInfo = accountInfo.gameAccountInfo
									local gameAccountID = gameAccountInfo.gameAccountID
									if gameAccountID then
										BNInviteFriend(gameAccountID)
									end
								end
							end
						end
					end
				end
				return
			end)

			-- Function to set event
			local function SetEvent()
				if LeaPlusLC["InviteFromWhisper"] == "On" then
					frame:RegisterEvent("CHAT_MSG_WHISPER")
					frame:RegisterEvent("CHAT_MSG_BN_WHISPER")
				else
					frame:UnregisterEvent("CHAT_MSG_WHISPER")
					frame:UnregisterEvent("CHAT_MSG_BN_WHISPER")
				end
			end

			-- Set event on startup if enabled and when option is clicked
			if LeaPlusLC["InviteFromWhisper"] == "On" then SetEvent() end
			LeaPlusCB["InviteFromWhisper"]:HookScript("OnClick", SetEvent)

			-- Create configuration panel
			local InvPanel = LeaPlusLC:CreatePanel("Invite from whispers", "InvPanel")

			-- Add editbox
			LeaPlusLC:MakeTx(InvPanel, "Settings", 16, -72)
			LeaPlusLC:MakeCB(InvPanel, "InviteFriendsOnly", "Restrict to friends", 16, -92, false, "If checked, group invites will only be sent to friends.|n|nIf unchecked, group invites will be sent to everyone.")

			LeaPlusLC:MakeTx(InvPanel, "Keyword", 356, -72)
			local KeyBox = LeaPlusLC:CreateEditBox("KeyBox", InvPanel, 140, 10, "TOPLEFT", 356, -92, "KeyBox", "KeyBox")

			-- Function to show the keyword in the option tooltip
			local function SetKeywordTip()
				LeaPlusCB["InviteFromWhisper"].tiptext = gsub(LeaPlusCB["InviteFromWhisper"].tiptext, "(|cffffffff)[^|]*(|r)",  "%1" .. LeaPlusLC["InvKey"] .. "%2")
			end

			-- Function to save the keyword
			local function SetInvKey()
				local keytext = KeyBox:GetText()
				if keytext and keytext ~= "" then
					LeaPlusLC["InvKey"] = strtrim(KeyBox:GetText())
				else
					LeaPlusLC["InvKey"] = "inv"
				end
				-- Show the keyword in the option tooltip
				SetKeywordTip()
			end

			-- Show the keyword in the option tooltip on startup
			SetKeywordTip()

			-- Save the keyword when it changes
			KeyBox:SetScript("OnTextChanged", SetInvKey)

			-- Refresh editbox with trimmed keyword when edit focus is lost (removes additional spaces)
			KeyBox:SetScript("OnEditFocusLost", function()
				KeyBox:SetText(LeaPlusLC["InvKey"])
			end)

			-- Help button hidden
			InvPanel.h:Hide()

			-- Back button handler
			InvPanel.b:SetScript("OnClick", function()
				-- Save the keyword
				SetInvKey()
				-- Show the options panel
				InvPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page2"]:Show()
				return
			end)

			-- Add reset button
			InvPanel.r:SetScript("OnClick", function()
				-- Settings
				LeaPlusLC["InviteFriendsOnly"] = "Off"
				-- Reset the keyword to default
				LeaPlusLC["InvKey"] = "inv"
				-- Set the editbox to default
				KeyBox:SetText("inv")
				-- Save the keyword
				SetInvKey()
				-- Refresh panel
				InvPanel:Hide(); InvPanel:Show()
			end)

			-- Ensure keyword is a string on startup
			LeaPlusLC["InvKey"] = tostring(LeaPlusLC["InvKey"]) or "inv"

			-- Set editbox value when shown
			KeyBox:HookScript("OnShow", function()
				KeyBox:SetText(LeaPlusLC["InvKey"])
			end)

			-- Configuration button handler
			LeaPlusCB["InvWhisperBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					LeaPlusLC["InviteFriendsOnly"] = "On"
					LeaPlusLC["InvKey"] = "inv"
					KeyBox:SetText(LeaPlusLC["InvKey"])
					SetInvKey()
				else
					-- Show panel
					InvPanel:Show()
					LeaPlusLC:HideFrames()
				end
			end)

		end

		----------------------------------------------------------------------
		--	Party from friends (no reload required)
		----------------------------------------------------------------------

		do

			local frame = CreateFrame("FRAME")
			frame:SetScript("OnEvent", function(self, event, arg1, ...)

				-- If a friend, accept if you're accepting friends and not queued
				local void, void, void, void, void, guid = ...
				if (LeaPlusLC["AcceptPartyFriends"] == "On" and LeaPlusLC:FriendCheck(arg1, guid)) then
					if not LeaPlusLC:IsInLFGQueue() then
						AcceptGroup()
						StaticPopup_ForEachShownDialog(function(self)
							if self.which == "PARTY_INVITE" then
								self.inviteAccepted = 1
								StaticPopup_Hide("PARTY_INVITE")
								return
							elseif self.which == "PARTY_INVITE_XREALM" then
								self.inviteAccepted = 1
								StaticPopup_Hide("PARTY_INVITE_XREALM")
								return
							end
						end)
						return
					end
				end
			end)

			-- Function to set event
			local function SetEvent()
				if LeaPlusLC["AcceptPartyFriends"] == "On" then
					frame:RegisterEvent("PARTY_INVITE_REQUEST")
				else
					frame:UnregisterEvent("PARTY_INVITE_REQUEST")
				end
			end

			-- Set event on startup if enabled and when option is clicked
			if LeaPlusLC["AcceptPartyFriends"] == "On" then SetEvent() end
			LeaPlusCB["AcceptPartyFriends"]:HookScript("OnClick", SetEvent)

		end

		----------------------------------------------------------------------
		--	Block party invites (no reload required)
		----------------------------------------------------------------------

		do

			local frame = CreateFrame("FRAME")
			frame:SetScript("OnEvent", function(self, event, arg1, ...)
				-- If not a friend and you're blocking invites, decline
				local void, void, void, void, void, guid = ...
				if LeaPlusLC["NoPartyInvites"] == "On" then
					if LeaPlusLC:FriendCheck(arg1, guid) then
						return
					else
						DeclineGroup()
						StaticPopup_Hide("PARTY_INVITE")
						StaticPopup_Hide("PARTY_INVITE_XREALM")
						return
					end
				end
			end)

			-- Function to set event
			local function SetEvent()
				if LeaPlusLC["NoPartyInvites"] == "On" then
					frame:RegisterEvent("PARTY_INVITE_REQUEST")
				else
					frame:UnregisterEvent("PARTY_INVITE_REQUEST")
				end
			end

			-- Set event on startup if enabled and when option is clicked
			if LeaPlusLC["NoPartyInvites"] == "On" then SetEvent() end
			LeaPlusCB["NoPartyInvites"]:HookScript("OnClick", SetEvent)

		end

		----------------------------------------------------------------------
		--	Automatic summon (no reload required)
		----------------------------------------------------------------------

		do

			-- Event function
			local frame = CreateFrame("FRAME")
			frame:SetScript("OnEvent", function(self, event, arg1)
				if not UnitAffectingCombat("player") then
					local sName = C_SummonInfo.GetSummonConfirmSummoner()
					local sLocation = C_SummonInfo.GetSummonConfirmAreaName()
					LeaPlusLC:Print(L["The summon from"] .. " " .. sName .. " (" .. sLocation .. ") " .. L["will be automatically accepted in 10 seconds unless cancelled."])
					C_Timer.After(10, function()
						local sNameNew = C_SummonInfo.GetSummonConfirmSummoner()
						local sLocationNew = C_SummonInfo.GetSummonConfirmAreaName()
						if sName == sNameNew and sLocation == sLocationNew then
							-- Automatically accept summon after 10 seconds if summoner name and location have not changed
							C_SummonInfo.ConfirmSummon()
							StaticPopup_Hide("CONFIRM_SUMMON")
						end
					end)
				end
				return
			end)

			-- Function to set event
			local function SetEvent()
				if LeaPlusLC["AutoAcceptSummon"] == "On" then
					frame:RegisterEvent("CONFIRM_SUMMON")
				else
					frame:UnregisterEvent("CONFIRM_SUMMON")
				end
			end

			-- Set event on startup if enabled and when option is clicked
			if LeaPlusLC["AutoAcceptSummon"] == "On" then SetEvent() end
			LeaPlusCB["AutoAcceptSummon"]:HookScript("OnClick", SetEvent)

		end

		----------------------------------------------------------------------
		--	Disable loot warnings
		----------------------------------------------------------------------

		do

			local frame = CreateFrame("FRAME")
			frame:SetScript("OnEvent", function(self, event, arg1, arg2, ...)
				-- Disable warnings for attempting to roll Need on loot
				if event == "CONFIRM_LOOT_ROLL" then
					ConfirmLootRoll(arg1, arg2)
					StaticPopup_Hide("CONFIRM_LOOT_ROLL")
					return
				end

				-- Disable warning for attempting to loot a Bind on Pickup item
				if event == "LOOT_BIND_CONFIRM" then
					ConfirmLootSlot(arg1, arg2)
					StaticPopup_Hide("LOOT_BIND",...)
					return
				end

				-- Disable warning for attempting to vendor an item within its refund window
				if event == "MERCHANT_CONFIRM_TRADE_TIMER_REMOVAL" then
					SellCursorItem()
					return
				end

				-- Disable warning for attempting to mail an item within its refund window
				if event == "MAIL_LOCK_SEND_ITEMS" then
					RespondMailLockSendItem(arg1, true)
					return
				end
			end)

			-- Function to set event
			local function SetEvent()
				if LeaPlusLC["NoConfirmLoot"] == "On" then
					frame:RegisterEvent("CONFIRM_LOOT_ROLL")
					frame:RegisterEvent("LOOT_BIND_CONFIRM")
					frame:RegisterEvent("MERCHANT_CONFIRM_TRADE_TIMER_REMOVAL")
					frame:RegisterEvent("MAIL_LOCK_SEND_ITEMS")
				else
					frame:UnregisterEvent("CONFIRM_LOOT_ROLL")
					frame:UnregisterEvent("LOOT_BIND_CONFIRM")
					frame:UnregisterEvent("MERCHANT_CONFIRM_TRADE_TIMER_REMOVAL")
					frame:UnregisterEvent("MAIL_LOCK_SEND_ITEMS")
				end
			end

			-- Set event on startup if enabled and when option is clicked
			if LeaPlusLC["NoConfirmLoot"] == "On" then SetEvent() end
			LeaPlusCB["NoConfirmLoot"]:HookScript("OnClick", SetEvent)

		end

		----------------------------------------------------------------------
		-- Mute mount sounds (no reload required)
		----------------------------------------------------------------------

		do

			-- Get mute table
			local mountTable = Leatrix_Plus["mountTable"]

			-- Give table file level scope (its used during logout and for wipe and admin commands)
			LeaPlusLC["mountTable"] = mountTable

			-- Load saved settings or set default values
			for k, v in pairs(mountTable) do
				if LeaPlusDB[k] and type(LeaPlusDB[k]) == "string" and LeaPlusDB[k] == "On" or LeaPlusDB[k] == "Off" then
					LeaPlusLC[k] = LeaPlusDB[k]
				else
					LeaPlusLC[k] = "Off"
					LeaPlusDB[k] = "Off"
				end
			end

			-- Create configuration panel
			local MountPanel = LeaPlusLC:CreatePanel("Mute mount sounds", "MountPanel")

			-- Add checkboxes
			LeaPlusLC:MakeTx(MountPanel, "Mounts", 16, -72)
			LeaPlusLC:MakeCB(MountPanel, "MuteGyrocopters", "Gyrocopters", 16, -92, false, "If checked, gyrocopters will be muted.|n|nThis applies to the engineering flying machine mounts.")
			LeaPlusLC:MakeCB(MountPanel, "MuteMechSteps", "Mechsteps", 16, -112, false, "If checked, footsteps for mechanical mounts will be muted.")
			LeaPlusLC:MakeCB(MountPanel, "MuteStriders", "Mechstriders", 16, -132, false, "If checked, mechanostriders will be quieter.")
			LeaPlusLC:MakeCB(MountPanel, "MuteHorsesteps", "Horsesteps", 16, -152, false, "If checked, footsteps for horse mounts will be muted.")

			-- Set click width for sounds checkboxes
			for k, v in pairs(mountTable) do
				LeaPlusCB[k].f:SetWidth(90)
				if LeaPlusCB[k].f:GetStringWidth() > 90 then
					LeaPlusCB[k]:SetHitRectInsets(0, -80, 0, 0)
				else
					LeaPlusCB[k]:SetHitRectInsets(0, -LeaPlusCB[k].f:GetStringWidth() + 4, 0, 0)
				end
			end

			-- Function to mute and unmute sounds
			local function SetupMute()
				for k, v in pairs(mountTable) do
					if LeaPlusLC["MuteMountSounds"] == "On" and LeaPlusLC[k] == "On" then
						for i, e in pairs(v) do
							local file, soundID = e:match("([^,]+)%#([^,]+)")
							MuteSoundFile(soundID)
						end
					else
						for i, e in pairs(v) do
							local file, soundID = e:match("([^,]+)%#([^,]+)")
							UnmuteSoundFile(soundID)
						end
					end
				end
			end

			-- Setup mute on startup if option is enabled
			if LeaPlusLC["MuteMountSounds"] == "On" then SetupMute() end

			-- Setup mute when options are clicked
			for k, v in pairs(mountTable) do
				LeaPlusCB[k]:HookScript("OnClick", SetupMute)
			end
			LeaPlusCB["MuteMountSounds"]:HookScript("OnClick", SetupMute)

			-- Help button hidden
			MountPanel.h:Hide()

			-- Back button handler
			MountPanel.b:SetScript("OnClick", function()
				MountPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page7"]:Show()
				return
			end)

			-- Reset button handler
			MountPanel.r:SetScript("OnClick", function()

				-- Reset checkboxes
				for k, v in pairs(mountTable) do
					LeaPlusLC[k] = "Off"
				end
				SetupMute()

				-- Refresh panel
				MountPanel:Hide(); MountPanel:Show()

			end)

			-- Show panal when options panel button is clicked
			LeaPlusCB["MuteMountSoundsBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					for k, v in pairs(mountTable) do
						LeaPlusLC[k] = "On"
					end
					SetupMute()
				else
					MountPanel:Show()
					LeaPlusLC:HideFrames()
				end
			end)

		end

		----------------------------------------------------------------------
		-- Mute game sounds (no reload required) (MuteGameSounds)
		----------------------------------------------------------------------

		do

			-- Get mute table
			local muteTable = Leatrix_Plus["muteTable"]

			-- Give table file level scope (its used during logout and for wipe and admin commands)
			LeaPlusLC["muteTable"] = muteTable

			-- Load saved settings or set default values
			for k, v in pairs(muteTable) do
				if LeaPlusDB[k] and type(LeaPlusDB[k]) == "string" and LeaPlusDB[k] == "On" or LeaPlusDB[k] == "Off" then
					LeaPlusLC[k] = LeaPlusDB[k]
				else
					LeaPlusLC[k] = "Off"
					LeaPlusDB[k] = "Off"
				end
			end

			-- Create configuration panel
			local SoundPanel = LeaPlusLC:CreatePanel("Mute game sounds", "SoundPanel")

			-- Add checkboxes
			LeaPlusLC:MakeTx(SoundPanel, "General", 16, -72)
			LeaPlusLC:MakeCB(SoundPanel, "MuteChimes", "Chimes", 16, -92, false, "If checked, clock hourly chimes will be muted.")
			LeaPlusLC:MakeCB(SoundPanel, "MuteFizzle", "Fizzle", 16, -112, false, "If checked, the spell fizzle sounds will be muted.")
			LeaPlusLC:MakeCB(SoundPanel, "MuteInterface", "Interface", 16, -132, false, "If checked, the interface button sound, the chat frame tab click sound and the game menu toggle sound will be muted.")
			LeaPlusLC:MakeCB(SoundPanel, "MuteLogin", "Login", 16, -152, false, "If checked, login screen sounds will be muted when you logout of the game.|n|nNote that login screen sounds will not be muted when you initially launch the game.|n|nThey will only be muted when you logout of the game.  This includes manually logging out as well as being forcefully logged out by the game server for reasons such as being away for an extended period of time.")
			LeaPlusLC:MakeCB(SoundPanel, "MuteTrains", "Trains", 16, -172, false, "If checked, train sounds will be muted.")
			LeaPlusLC:MakeCB(SoundPanel, "MuteEvents", "Events", 16, -192, false, "If checked, holiday event sounds will be muted.|n|nThis applies to Headless Horseman.")
			LeaPlusLC:MakeCB(SoundPanel, "MuteReady", "Ready", 16, -212, false, "If checked, the ready check sound will be muted.")

			LeaPlusLC:MakeTx(SoundPanel, "Pets", 150, -72)
			LeaPlusLC:MakeCB(SoundPanel, "MuteScreech", "Screech", 150, -92, false, "If checked, Screech will be muted.|n|nThis is a spell used by some flying pets.")
			LeaPlusLC:MakeCB(SoundPanel, "MuteYawns", "Yawns", 150, -112, false, "If checked, yawns from hunter pet cats will be muted.")

			LeaPlusLC:MakeTx(SoundPanel, "Toys", 150, -152)
			LeaPlusLC:MakeCB(SoundPanel, "MutePiccolo", "Piccolo", 150, -172, false, "If checked, Piccolo of the Flaming Fire wil be muted.|n|nNote that enabling this will also mute the harp sound of the warlock seduction spell.")

			LeaPlusLC:MakeTx(SoundPanel, "Misc", 284, -72)
			LeaPlusLC:MakeCB(SoundPanel, "MuteAdal", "A'dal", 284, -92, false, "If checked, A'dal in Shattrath City will be muted.")

			-- Set click width for sounds checkboxes
			for k, v in pairs(muteTable) do
				LeaPlusCB[k].f:SetWidth(90)
				if LeaPlusCB[k].f:GetStringWidth() > 90 then
					LeaPlusCB[k]:SetHitRectInsets(0, -80, 0, 0)
				else
					LeaPlusCB[k]:SetHitRectInsets(0, -LeaPlusCB[k].f:GetStringWidth() + 4, 0, 0)
				end
			end

			-- Function to mute and unmute sounds
			local function SetupMute()
				for k, v in pairs(muteTable) do
					if LeaPlusLC["MuteGameSounds"] == "On" and LeaPlusLC[k] == "On" then
						for i, e in pairs(v) do
							local file, soundID = e:match("([^,]+)%#([^,]+)")
							MuteSoundFile(soundID)
						end
					else
						for i, e in pairs(v) do
							local file, soundID = e:match("([^,]+)%#([^,]+)")
							UnmuteSoundFile(soundID)
						end
					end
				end
			end

			-- Setup mute on startup if option is enabled
			if LeaPlusLC["MuteGameSounds"] == "On" then SetupMute() end

			-- Setup mute when options are clicked
			for k, v in pairs(muteTable) do
				LeaPlusCB[k]:HookScript("OnClick", SetupMute)
			end
			LeaPlusCB["MuteGameSounds"]:HookScript("OnClick", SetupMute)

			-- Help button hidden
			SoundPanel.h:Hide()

			-- Back button handler
			SoundPanel.b:SetScript("OnClick", function()
				SoundPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page7"]:Show()
				return
			end)

			-- Reset button handler
			SoundPanel.r:SetScript("OnClick", function()

				-- Reset checkboxes
				for k, v in pairs(muteTable) do
					LeaPlusLC[k] = "Off"
				end
				SetupMute()

				-- Refresh panel
				SoundPanel:Hide(); SoundPanel:Show()

			end)

			-- Show panal when options panel button is clicked
			LeaPlusCB["MuteGameSoundsBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					for k, v in pairs(muteTable) do
						LeaPlusLC[k] = "On"
					end
					LeaPlusLC["MuteReady"] = "Off"
					SetupMute()
				else
					SoundPanel:Show()
					LeaPlusLC:HideFrames()
				end
			end)

			----------------------------------------------------------------------
			-- Login setting
			----------------------------------------------------------------------

			-- Create soundtable for PLAYER_LOGOUT (these sounds are only muted or unmuted when logging out
			local muteLogoutTable = {

				-- Game music (sound/music/gluescreenmusic/bc_main_theme.mp3#53220)
				"53220",

			}

			-- Handle sounds that get muted or unmuted when logging out
			local logoutEvent = CreateFrame("FRAME")
			logoutEvent:RegisterEvent("PLAYER_LOGOUT")

			-- Mute or unmute sounds when logging out
			logoutEvent:SetScript("OnEvent", function()
				if LeaPlusLC["MuteGameSounds"] == "On" and LeaPlusLC["MuteLogin"] == "On" then
					-- Mute logout table sounds on logout
					for void, soundID in pairs(muteLogoutTable) do
						MuteSoundFile(soundID)
					end
				else
					-- Unmute logout table sounds on logout
					for void, soundID in pairs(muteLogoutTable) do
						UnmuteSoundFile(soundID)
					end
				end
			end)

			-- Unmute sounds when logging in
			for void, soundID in pairs(muteLogoutTable) do
				UnmuteSoundFile(soundID)
			end

		end

		----------------------------------------------------------------------
		-- Faster movie skip
		----------------------------------------------------------------------

		if LeaPlusLC["FasterMovieSkip"] == "On" then

			-- Allow space bar, escape key and enter key to cancel cinematic without confirmation
			CinematicFrame:HookScript("OnKeyDown", function(self, key)
				if key == "ESCAPE" then
					if CinematicFrame:IsShown() and CinematicFrame.closeDialog and CinematicFrameCloseDialogConfirmButton then
						CinematicFrameCloseDialog:Hide()
					end
				end
			end)
			CinematicFrame:HookScript("OnKeyUp", function(self, key)
				if key == "SPACE" or key == "ESCAPE" or key == "ENTER" then
					if CinematicFrame:IsShown() and CinematicFrame.closeDialog and CinematicFrameCloseDialogConfirmButton then
						CinematicFrameCloseDialogConfirmButton:Click()
					end
				end
			end)
			MovieFrame:HookScript("OnKeyUp", function(self, key)
				if key == "SPACE" or key == "ESCAPE" or key == "ENTER" then
					if MovieFrame:IsShown() and MovieFrame.CloseDialog and MovieFrame.CloseDialog.Buttons and MovieFrame.CloseDialog.Buttons.ConfirmButton then
						MovieFrame.CloseDialog.Buttons.ConfirmButton:Click()
					end
				end
			end)

		end

		----------------------------------------------------------------------
		-- Wowhead Links
		----------------------------------------------------------------------

		if LeaPlusLC["ShowWowheadLinks"] == "On" then

			-- Create configuration panel
			local WowheadPanel = LeaPlusLC:CreatePanel("Show Wowhead links", "WowheadPanel")

			LeaPlusLC:MakeTx(WowheadPanel, "Settings", 16, -72)
			LeaPlusLC:MakeCB(WowheadPanel, "WowheadLinkComments", "Links go directly to the comments section", 16, -92, false, "If checked, Wowhead links will go directly to the comments section.")

			-- Help button hidden
			WowheadPanel.h:Hide()

			-- Back button handler
			WowheadPanel.b:SetScript("OnClick", function()
				WowheadPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page5"]:Show()
				return
			end)

			-- Reset button handler
			WowheadPanel.r:SetScript("OnClick", function()

				-- Reset controls
				LeaPlusLC["WowheadLinkComments"] = "Off"

				-- Refresh configuration panel
				WowheadPanel:Hide(); WowheadPanel:Show()

			end)

			-- Show configuration panal when options panel button is clicked
			LeaPlusCB["ShowWowheadLinksBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					LeaPlusLC["WowheadLinkComments"] = "Off"
				else
					WowheadPanel:Show()
					LeaPlusLC:HideFrames()
				end
			end)

			-- Get localised Wowhead URL
			local wowheadLoc
			if GameLocale == "deDE" then wowheadLoc = "de.tbc.wowhead.com"
			elseif GameLocale == "esMX" then wowheadLoc = "mx.tbc.wowhead.com"
			elseif GameLocale == "esES" then wowheadLoc = "es.tbc.wowhead.com"
			elseif GameLocale == "frFR" then wowheadLoc = "fr.tbc.wowhead.com"
			elseif GameLocale == "itIT" then wowheadLoc = "it.tbc.wowhead.com"
			elseif GameLocale == "ptBR" then wowheadLoc = "pt.tbc.wowhead.com"
			elseif GameLocale == "ruRU" then wowheadLoc = "ru.tbc.wowhead.com"
			elseif GameLocale == "koKR" then wowheadLoc = "ko.tbc.wowhead.com"
			elseif GameLocale == "zhCN" then wowheadLoc = "cn.tbc.wowhead.com"
			elseif GameLocale == "zhTW" then wowheadLoc = "tw.tbc.wowhead.com"
			else							 wowheadLoc = "tbc.wowhead.com"
			end

			-- Create editbox
			local mEB = CreateFrame("EditBox", nil, QuestLogFrame)
			mEB:ClearAllPoints()
			mEB:SetPoint("TOPLEFT", 70, 4)
			mEB:SetHeight(16)
			mEB:SetFontObject("GameFontNormal")
			mEB:SetBlinkSpeed(0)
			mEB:SetAutoFocus(false)
			mEB:EnableKeyboard(false)
			mEB:SetHitRectInsets(0, 90, 0, 0)
			mEB:SetScript("OnKeyDown", function() end)
			mEB:SetScript("OnMouseUp", function()
				if mEB:IsMouseOver() then
					mEB:HighlightText()
				else
					mEB:HighlightText(0, 0)
				end
			end)

			-- Set the background color
			mEB.t = mEB:CreateTexture(nil, "BACKGROUND")
			mEB.t:SetPoint(mEB:GetPoint())
			mEB.t:SetSize(mEB:GetSize())
			mEB.t:SetColorTexture(0.05, 0.05, 0.05, 1.0)

			-- Create hidden font string (used for setting width of editbox)
			mEB.z = mEB:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
			mEB.z:Hide()

			-- Function to set editbox value
			local function SetQuestInBox(questListID)

				local questTitle, void, void, isHeader, void, void, void, questID = GetQuestLogTitle(questListID)
				if questID and not isHeader then

					-- Hide editbox if quest ID is invalid
					if questID == 0 then mEB:Hide() else mEB:Show() end

					-- Set editbox text
					if LeaPlusLC["WowheadLinkComments"] == "On" then
						mEB:SetText("https://" .. wowheadLoc .. "/quest=" .. questID .. "#comments")
					else
						mEB:SetText("https://" .. wowheadLoc .. "/quest=" .. questID)
					end

					-- Set hidden fontstring then resize editbox to match
					mEB.z:SetText(mEB:GetText())
					mEB:SetWidth(mEB.z:GetStringWidth() + 90)
					mEB.t:SetWidth(mEB.z:GetStringWidth())

					-- Get quest title for tooltip
					if questTitle then
						mEB.tiptext = questTitle .. "|n" .. L["Press CTRL/C to copy."]
					else
						mEB.tiptext = ""
						if mEB:IsMouseOver() and GameTooltip:IsShown() then GameTooltip:Hide() end
					end

				end
			end

			-- Set URL when quest is selected (this works with Questie, old method used QuestLog_SetSelection)
			hooksecurefunc("SelectQuestLogEntry", function(questListID)
				SetQuestInBox(questListID)
			end)

			-- Create tooltip
			mEB:HookScript("OnEnter", function()
				mEB:HighlightText()
				mEB:SetFocus()
				GameTooltip:SetOwner(mEB, "ANCHOR_BOTTOM", 0, -10)
				GameTooltip:SetText(mEB.tiptext, nil, nil, nil, nil, true)
				GameTooltip:Show()
			end)

			mEB:HookScript("OnLeave", function()
				mEB:HighlightText(0, 0)
				mEB:ClearFocus()
				GameTooltip:Hide()
			end)

			-- ElvUI fix to move Wowhead link inside the quest log frame
			if LeaPlusLC.ElvUI then
				C_Timer.After(0.1, function()
					QuestLogTitleText:ClearAllPoints()
					QuestLogTitleText:SetPoint("TOPLEFT", QuestLogFrame, "TOPLEFT", 32, -18)
					if QuestLogTitleText:GetStringWidth() > 200 then
						QuestLogTitleText:SetWidth(200)
					else
						QuestLogTitleText:SetWidth(QuestLogTitleText:GetStringWidth())
					end
					mEB:ClearAllPoints()
					mEB:SetPoint("LEFT", QuestLogTitleText, "RIGHT", 10, 0)
					mEB.t:Hide()
				end)
			end

		end

		----------------------------------------------------------------------
		-- Automate gossip (no reload required)
		----------------------------------------------------------------------

		do

			-- Function to skip gossip
			local function SkipGossip(skipAltKeyRequirement)
				if not skipAltKeyRequirement and not IsAltKeyDown() then return end
				local gossipInfoTable = C_GossipInfo.GetOptions()
				if gossipInfoTable and #gossipInfoTable == 1 and C_GossipInfo.GetNumAvailableQuests() == 0 and C_GossipInfo.GetNumActiveQuests() == 0 and gossipInfoTable[1] and gossipInfoTable[1].gossipOptionID then
					C_GossipInfo.SelectOption(gossipInfoTable[1].gossipOptionID)
				end
			end

			-- Create gossip event frame
			local gossipFrame = CreateFrame("FRAME")

			-- Function to setup events
			local function SetupEvents()
				if LeaPlusLC["AutomateGossip"] == "On" then
					gossipFrame:RegisterEvent("GOSSIP_SHOW")
				else
					gossipFrame:UnregisterEvent("GOSSIP_SHOW")
				end
			end

			-- Setup events when option is clicked and on startup (if option is enabled)
			LeaPlusCB["AutomateGossip"]:HookScript("OnClick", SetupEvents)
			if LeaPlusLC["AutomateGossip"] == "On" then SetupEvents() end

			-- Create tables for specific NPC IDs (these are automatically selected with no alt key requirement)
			local npcTable = {

				-- Stable masters (https://www.wowhead.com/tbc/npcs?filter=27%3B1%3B0)
				24974, 9981, 21517, 9986, 19018, 22469, 10061, 16656, 19019, 21518, 23392, 21336, 14741, 17896, 18244, 18984, 19368, 9985, 9989, 11105, 10056, 10059, 11117, 13616, 16586, 10085, 16665, 10050, 13617, 6749, 10060, 25037, 9980, 16185, 10054, 17485, 11069, 10055, 9982, 15131, 10063, 11104, 9977, 9978, 18250, 10045, 19476, 10052, 10047, 9988, 17666, 11119, 10046, 10048, 22468, 9979, 15722, 10062, 9976, 10057, 9984, 10053, 16764, 16094, 10058, 10049, 9983, 24905, 16824, 10051, 9987,

				-- Banker (https://www.wowhead.com/tbc/npcs?filter=19;1;0)
				3309, 2625, 19338, 17633, 2457, 21734, 2460, 4155, 19034, 8124, 17631, 28343, 8123, 8119, 4209, 21733, 16615, 17773, 16616, 17632, 18350, 16710, 3318, 4208, 2459, 3320, 2996, 5060, 19246, 8356, 3496, 7799, 19318, 13917, 2456, 2455, 2458, 5099, 8357, 2461, 21732, 4549, 16617, 4550,

				-- Flightmaster (https://www.wowhead.com/tbc/npcs?filter=21;1;0)
				18940, 16189, 3310, 523, 16822, 3615, 1573, 1571, 16587, 17555, 15178, 16192, 2835, 10583, 24366, 21107, 13177, 21766, 18931, 6026, 2432, 23612, 2226, 1572, 1387, 8018, 18939, 15177, 4267, 2861, 20515, 24851, 16227, 2858, 26560, 20234, 22216, 12577, 19583, 18788, 4312, 4319, 12616, 11901, 22485, 11138, 12578, 2995, 18930, 18937, 931, 12596, 3841, 12740, 18789, 18809, 18942, 4317, 19317, 4314, 22931, 20762, 18785, 10378, 11899, 22935, 2851, 3305, 18808, 18938, 8610, 17554, 19581, 4551, 8020, 10897, 18953, 6706, 7824, 12636, 18807, 12617, 2941, 22455, 4407, 3838, 8609, 19558, 7823, 2299, 11900, 18791, 352, 8019, 2859, 11139, 2389, 6726, 4321, 2409,

				-- Trainer (https://www.wowhead.com/tbc/npcs?filter=28;1;0)
				19778, 20791, 18775, 18772, 20500, 7867, 20511, 19775, 19052, 18749, 19252, 15501, 18773, 18802, 18753, 7866, 20124, 18751, 16588, 18774, 18752, 19063, 27703, 4752, 7868, 17637, 16583, 7232, 7869, 11178, 16773, 7870, 18776, 18779, 20914, 19186, 18747, 19184, 17634, 7871, 16640, 5491, 23128, 4732, 17204, 8126, 11146, 18777, 27705, 16280, 16729, 7231, 16681, 25099, 16621, 4218, 24868, 16275, 16646, 1317, 5493, 18771, 18987, 1346, 16253, 20407, 5885, 16823, 4614, 11073, 19540, 18988, 12042, 16755, 4753, 16663, 19187, 3332, 3032, 1103, 3494, 5159, 17441, 5173, 16644, 3363, 17212, 18754, 7954, 3345, 19539, 3344, 13417, 19576, 4568, 7406, 23127, 3365, 11557, 16654, 18748, 16633, 3171, 5492, 1300, 18993, 8128, 16276, 3065, 3353, 11866, 4576, 5174, 16642, 17089, 4773, 17110, 17101, 16269, 3324, 17520, 5938, 4606, 8736, 16667, 3601, 16680, 19340, 6251, 3406, 11097, 4165, 11072, 19180, 5994, 11098, 16655, 11048, 16648, 11870, 20406, 5157, 7089, 7953, 5164, 16272, 14740, 4616, 18755, 3605, 22225, 3355, 5566, 17246, 17121, 3484, 928, 331, 18018, 16266, 9584, 3404, 13283, 3357, 16726, 377, 11017, 3007, 5515, 3064, 9465, 17504, 16763, 5137, 16647, 11068, 5144, 5513, 5153, 6297, 16723, 11177, 3352, 3328, 918, 4212, 4772, 17424, 4573, 23534, 16660, 17488, 17482, 1234, 3354, 3041, 16728, 4156, 16756, 11074, 17519, 3028, 3690, 17480, 3407, 16676, 3033, 5495, 1232, 16761, 4595, 2836, 3290, 11031, 15280, 1651, 16719, 1700, 2327, 1683, 914, 17120, 4258, 5957, 13084, 3698, 5484, 8142, 2837, 3555, 3013, 3604, 5567, 5564, 5482, 3011, 3347, 16771, 16658, 2856, 5149, 4582, 17005, 1676, 5161, 19341, 5497, 5113, 917, 5506, 2798, 16277, 514, 7944, 11867, 17514, 16669, 3523, 5172, 4598, 7315, 7312, 16780, 5498, 16774, 17487, 4586, 986, 17983, 16653, 4138, 17505, 5499, 16688, 2489, 17442, 5504, 3403, 16271, 11052, 8738, 16674, 16662, 11865, 3963, 4211, 461, 16738, 5883, 16712, 11406, 5165, 19185, 5941, 1228, 15284, 17434, 5146, 16679, 15285, 3688, 5392, 16651, 16684, 3373, 17222, 7946, 4898, 2399, 3594, 4193, 4146, 16499, 3036, 12025, 11397, 16673, 3401, 328, 3624, 4160, 2131, 5142, 3001, 19369, 5690, 8306, 19251, 4204, 4219, 4254, 5612, 2627, 3620, 376, 3154, 3170, 16659, 3704, 2130, 1680, 16686, 11096, 17481, 3034, 5502, 17219, 4213, 3169, 5505, 895, 2857, 1430, 10993, 460, 3607, 3047, 16501, 1702, 927, 16736, 1701, 6299, 19478, 5127, 21087, 2704, 5501, 2998, 7948, 3061, 3600, 16273, 16724, 3325, 1382, 16725, 6287, 5943, 10276, 2391, 16721, 17483, 10266, 5516, 6295, 7949, 3399, 8308, 4087, 4605, 5489, 3153, 1470, 1229, 1466, 1231, 915, 5145, 198, 4564, 5884, 4217, 3137, 5150, 3412, 375, 3067, 1386, 3706, 16279, 5939, 5784, 3326, 11869, 4588, 4090, 17245, 2128, 5115, 4611, 16270, 3179, 3039, 4596, 4091, 17509, 988, 3707, 3063, 985, 12030, 16752, 3066, 8153, 16731, 5882, 2878, 3042, 4163, 5171, 3031, 5143, 11050, 7311, 16502, 1632, 3606, 812, 2390, 5148, 5114, 837, 1385, 1681, 8140, 957, 4205, 4607, 5167, 3327, 4584, 3557, 1218, 17510, 11037, 4578, 4563, 1473, 3703, 3175, 8144, 11067, 4591, 2126, 2329, 4583, 5759, 5116, 15513, 11868, 7230, 3173, 2326, 5880, 6018, 5695, 17122, 6286, 17214, 4215, 15400, 3009, 17484, 3136, 3087, 3965, 2123, 23103, 16685, 4552, 3046, 908, 17513, 3599, 11066, 3602, 1901, 913, 3597, 906, 3044, 11041, 3185, 987, 5166, 11401, 5117, 2127, 16278, 16366, 2818, 2855, 15283, 5517, 7088, 11029, 3048, 11051, 17844, 6291, 10090, 926, 925, 3069, 3545, 2119, 11083, 3172, 459, 16749, 6292, 4214, 17511, 2114, 4608, 3622, 6306, 10086, 5480, 15279, 3043, 3598, 2485, 5518, 4159, 3062, 3156, 16652, 4565, 8146, 3595, 5177, 1458, 5141, 5511, 3049, 10088, 6290, 4900, 3593, 22477, 3026, 16367, 6094, 4320, 17215, 223, 4609, 6387, 6707, 11081, 3181, 10277, 16675, 27704, 2124, 6288, 11028, 3038, 3306, 12961, 7087, 11047, 3964, 11070, 911, 3008, 1292, 1226, 18804, 6289, 11049, 3030, 1383, 3004, 10278, 5958, 3478, 16692, 3040, 1703, 16500, 5147, 11046, 3408, 20125, 3967, 1215, 4210, 4594, 16161, 3596, 4593, 1355, 3603, 2129, 2122, 11044, 2367, 3174, 3060, 1699, 4566, 5811, 3184, 2834, 4567, 3155, 3549, 3157, 4089, 10089, 916, 11026, 11042, 16672, 11084, 5500, 1246, 6014, 8141, 10930, 3059, 16503, 1404, 12032, 16160, 944, 11071, 11025, 11065, 912, 2132, 1411, 2879, 4092, 2492, 3045, 543, 5496, 1241, 5479, 16703,

				-- Vendor Level 1-40 (https://www.wowhead.com/tbc/npcs/min-level:1/max-level:40?filter=29;1;0)
				1448, 4561, 4229, 3954, 4877, 12043, 8137, 3955, 16528, 2810, 16262, 1285, 12033, 16442, 1298, 17246, 3323, 16611, 8139, 16191, 66, 17421, 2381, 1257, 16757, 5494, 16624, 23995, 4897, 17630, 3350, 3410, 2821, 17584, 5940, 16367, 1286, 16268, 16443, 3027, 3550, 3313, 16224, 384, 16619, 16264, 16274, 5162, 3482, 4574, 16253, 16444, 10118, 1261, 3499, 6929, 1465, 1148, 1460, 3556, 5163, 3935, 2393, 16678, 16690, 16739, 3334, 17245, 16635, 16612, 14860, 16187, 16636, 16366, 4981, 4730, 5942, 5101, 16683, 16860, 2685, 14847, 3029, 3367, 14846, 16657, 4169, 3351, 3342, 4731, 9087, 8363, 12246, 15400, 8361, 4775, 3335, 6740, 16638, 16625, 16747, 23521, 23604, 6746, 7564, 1303, 16618, 5110, 483, 17930, 14637, 3490, 5817, 4453, 4604, 4575, 6741, 16259, 3413, 16705, 15433, 21019, 17101, 2118, 17490, 18427, 1321, 4265, 3333, 5122, 16782, 20377, 16748, 1275, 2357, 18672, 12245, 3562, 4891, 4307, 16263, 17412, 844, 16768, 16613, 4553, 17553, 1291, 16641, 5175, 4305, 11106, 16767, 5193, 7978, 1351, 4585, 15397, 16691, 3314, 4896, 6301, 3348, 3658, 3614, 1146, 16689, 16664, 16553, 16765, 5483, 11116, 1325, 2401, 3497, 16715, 4569, 19383, 5188, 4885, 16732, 23481, 3489, 5128, 16722, 1297, 2832, 1326, 734, 5565, 5748, 789, 3346, 4241, 7683, 4165, 5160, 5151, 894, 2483, 5411, 3958, 277, 18426, 17222, 4555, 18951, 16919, 1308, 16623, 3369, 3881, 16542, 1684, 3361, 16714, 17486, 16650, 8362, 16706, 4085, 16718, 3541, 16261, 3366, 6576, 16709, 3291, 3133, 4200, 24468, 15289, 3178, 16631, 3090, 5111, 3322, 3015, 1462, 2698, 19065, 8666, 1287, 5124, 7976, 3405, 1347, 777, 465, 1463, 3168, 3495, 13418, 21145, 3005, 18347, 18810, 3409, 3364, 16267, 3578, 16716, 1318, 222, 8681, 18947, 3488, 2481, 16257, 3493, 3532, 274, 3522, 5100, 3934, 4557, 5848, 4562, 4086, 3485, 5620, 3368, 23605, 4236, 24396, 10216, 6731, 9501, 7714, 4892, 5783, 1237, 4558, 18811, 1350, 4189, 16637, 4602, 5514, 2672, 5138, 3962, 7733, 15291, 4173, 227, 3883, 5520, 4195, 3960, 2808, 13433, 3081, 1682, 4894, 4220, 956, 836, 4170, 2682, 15353, 1313, 3531, 3479, 3012, 4603, 3539, 1249, 16677, 2819, 3534, 2679, 4230, 829, 4203, 5123, 1304, 1250, 3329, 1299, 3529, 13429, 16632, 491, 18954, 5178, 4222, 1349, 4610, 4191, 3019, 4556, 1362, 5816, 3480, 4879, 3528, 18926, 4221, 3953, 16626, 15494, 1214, 11287, 17667, 1302, 9549, 3577, 1669, 16708, 14481, 3165, 1692, 1243, 1247, 3542, 8403, 3025, 3683, 2380, 17446, 5132, 3319, 15287, 9551, 3187, 5754, 23896, 3481, 5519, 152, 6028, 4587, 4256, 3088, 12776, 2388, 6790, 3164, 1454, 6730, 3937, 17489, 1694, 4580, 16620, 1322, 3017, 14450, 1645, 1474, 23571, 5510, 12962, 3537, 16917, 151, 1319, 54, 6374, 4182, 190, 233, 16666, 5750, 16753, 8508, 1452, 1104, 17656, 5155, 295, 6737, 16766, 3498, 4589, 2115, 3186, 3021, 372, 1456, 4231, 5871, 791, 3533, 2364, 3530, 3161, 3053, 5812, 4194, 23603, 896, 4175, 1668, 11137, 5944, 2816, 228, 5611, 3096, 6373, 2668, 24510, 3969, 3095, 4181, 960, 1464, 6747, 13435, 8305, 8118, 5757, 3970, 5107, 4171, 4183, 23065, 13420, 5108, 4225, 4597, 4185, 3609, 14845, 3016, 1650, 12027, 3492, 3167, 16750, 3075, 2365, 2812, 6300, 225, 843, 4232, 4082, 3956, 6930, 11118, 4083, 16918, 3072, 1691, 18929, 12028, 5049, 5156, 12031, 2394, 4577, 3330, 2814, 6495, 3553, 1320, 3612, 9099, 3356, 8307, 10369, 4226, 4228, 8404, 3572, 1673, 3162, 20378, 3180, 4167, 23064, 1310, 16258, 3091, 5820, 3085, 3358, 3086, 3093, 5133, 1324, 2264, 8931, 5688, 5814, 3491, 13430, 9179, 3360, 3536, 3002, 3134, 1295, 13434, 5753, 4186, 16751, 4878, 4571, 9555, 3959, 8364, 945, 10380, 3548, 5191, 6298, 4235, 1685, 3400, 16260, 23522, 3951, 4266, 2397, 14962, 5125, 5140, 2137, 5569, 3591, 3705, 4600, 3540, 3316, 3160, 6736, 7736, 1686, 3483, 6574, 8122, 74, 5758, 2383, 4177, 5190, 3321, 7485, 4592, 2136, 3317, 1323, 16920, 5821, 3089, 1407, 4192, 9676, 3177, 5169, 16186, 4560, 16693, 8129, 1309, 3592, 5152, 17655, 5120, 2697, 3166, 5102, 6367, 2140, 5503, 3020, 4601, 1698, 4223, 1348, 5886, 12045, 3486, 4187, 14964, 5119, 8358, 5170, 3948, 1147, 3477, 6727, 12196, 11103, 8150, 3590, 4876, 3884, 6027, 16610, 3561, 1671, 1672, 3077, 3135, 3961, 3076, 8878, 2683, 3684, 5154, 15354, 2684, 1457, 3138, 13432, 2669, 4617, 3518, 1690, 5158, 3315, 3074, 13431, 8117, 6376, 1263, 3952, 8359, 3608, 4234, 1312, 2366, 3097, 2116, 1450, 3611, 8934, 4084, 1687, 4164, 958, 1453, 1314, 3158, 15292, 3003, 1238, 14963, 1273, 5103, 1289, 3933, 8401, 3547, 4886, 3080, 2265, 3018, 2352, 6739, 16458, 6734, 7731, 6738, 9356, 7744, 1305, 3544, 3610, 1311, 4590, 1301, 5512, 5509, 5749, 1697, 3589, 3078, 18277, 17929, 3159, 5129, 3010, 3613, 1670, 3044, 14961, 167, 959, 2134, 16735, 5109, 4233, 1459, 3014, 8398, 5126, 1198, 3543, 4581, 5508, 3022, 23606, 4570, 3092, 15124, 4554, 4259, 1149, 3882, 1294, 3552, 14480, 3554, 2113, 1441, 6496, 5106, 4216, 12960, 6091, 3411, 8360, 20121, 4043, 2820, 13436, 5112, 8152, 4188, 7737, 6928, 6272, 6791, 78, 5698, 2997, 793, 790, 3331, 954, 4615, 5121, 3588, 1381, 5870, 4190, 3587, 3073, 1339, 5819, 226, 1461, 9553, 13018, 3551, 955, 8665, 3023, 14844, 2999, 5189, 4889, 16762, 4875, 3163, 3349, 4899, 4954, 1678, 1469, 1341, 2135, 1315, 4172, 2046, 1240, 23525, 4240, 6328, 4168, 1333, 1213, 2117, 6735, 8121, 258, 3487, 3359, 15125, 4888, 4599, 4559, 3079,

				-- Vendor Level 41-200 (https://www.wowhead.com/tbc/npcs/min-level:41/max-level:200?filter=29;1;0)
				12794, 12777, 12792, 12784, 14753, 12785, 12795, 14754, 13219, 12022, 13218, 13217, 13216, 15126, 15127, 18525, 12919, 12781, 2805, 8125, 12782, 2626, 14581, 12793, 13476, 21643, 15419, 11189, 20080, 17904, 17585, 2803, 12097, 12096, 21432, 340, 15179, 19321, 21655, 10667, 17657, 2664, 17512, 7947, 23381, 19331, 8145, 20278, 12805, 2806, 9499, 12796, 12783, 3362, 7955, 989, 18990, 18756, 18774, 23489, 18960, 27721, 20510, 18772, 19232, 12941, 27668, 7952, 18752, 11038, 20494, 18382, 18802, 19663, 9636, 18775, 20241, 25176, 18911, 20613, 18751, 5594, 16826, 20240, 20097, 14921, 20096, 12799, 20242, 22213, 22208, 27722, 20807, 3546, 12944, 7852, 22212, 18255, 11536, 16583, 18771, 18749, 19837, 19004, 20616, 16588, 19213, 7775, 3685, 11185, 18773, 25976, 18753, 2482, 18987, 15174, 11278, 23428, 19074, 18005, 23007, 26352, 25032, 14437, 18484, 21905, 19662, 20081, 4217, 18011, 25046, 21183, 18754, 23748, 20916, 18991, 18993, 16376, 16015, 18898, 28225, 25177, 23437, 2084, 19772, 19038, 19042, 20028, 19373, 11557, 19521, 2848, 19773, 11056, 15165, 11057, 21906, 21113, 14522, 18908, 7854, 19186, 25950, 17518, 18015, 21488, 18988, 5134, 2670, 18581, 18267, 14322, 3625, 23263, 23367, 11187, 20808, 9544, 18897, 16585, 25179, 18564, 20981, 19539, 18822, 18821, 15006, 11555, 16823, 14740, 18664, 2480, 6779, 25196, 12384, 16388, 10618, 18266, 25977, 19678, 19227, 6568, 23396, 14624, 12959, 19296, 19661, 21485, 5173, 10857, 16602, 21474, 19536, 15471, 23159, 19575, 26089, 8679, 24975, 3682, 27667, 18957, 6382, 12942, 18906, 16829, 8178, 15176, 19836, 18018, 20092, 24780, 2839, 19722, 7879, 26092, 21483, 12943, 19932, 5815, 19015, 20082, 4782, 10856, 23710, 20980, 19049, 22227, 19540, 19017, 1307, 19197, 27666, 19452, 8177, 14371, 20112, 19196, 7940, 5139, 8157, 19314, 23245, 18907, 6807, 26091, 23363, 19538, 3343, 24408, 11184, 19617, 27819, 19053, 19047, 11874, 8160, 4890, 18017, 12957, 19371, 4184, 19223, 18905, 19342, 19857, 14738, 2699, 12956, 18542, 19235, 25036, 9548, 19534, 2687, 19694, 19560, 16798, 5135, 15197, 20989, 20986, 25178, 7942, 3000, 23484, 19879, 12023, 6548, 19236, 20892, 984, 10364, 9552, 24208, 20249, 12021, 1328, 16670, 25195, 23373, 19370, 19451, 19436, 19244, 15864, 6777, 19194, 6567, 8161, 3700, 26090, 4883, 19330, 22225, 23533, 18019, 19625, 23483, 16713, 22476, 8131, 27812, 11188, 12958, 26124, 21744, 2622, 23482, 24495, 4255, 19532, 18959, 19526, 4180, 3298, 23511, 19561, 8678, 2303, 18010, 23112, 19664, 18006, 19014, 22266, 19718, 17277, 2849, 25035, 15293, 27806, 14301, 8158, 19499, 19573, 21110, 2908, 25039, 11186, 7941, 23560, 19374, 16649, 23243, 19517, 27817, 16543, 11703, 19333, 23143, 7772, 4257, 18913, 14739, 19011, 19473, 17598, 19182, 20890, 19012, 982, 2225, 18962, 21112, 19056, 2838, 19537, 10293, 19518, 19572, 2844, 19195, 2843, 3689, 27478, 24392, 19520, 18243, 26123, 19559, 2663, 11182, 22264, 23724, 23510, 2842, 1316, 23244, 21111, 28344, 2846, 5570, 21746, 19535, 21083, 19495, 1471, 21082, 15898, 19239, 12024, 20893, 23110, 3312, 19479, 18009, 23145, 2688, 15199, 19315, 19472, 24545, 15011, 4884, 19679, 4893, 21084, 19533, 20194, 19352, 21484, 14337, 19050, 10361, 7943, 23573, 18245, 12026, 15315, 19021, 19528, 20915, 19471, 19045, 19372, 21172, 20231, 19348, 27711, 983, 25034, 22099, 10379, 20463, 27810, 27820, 18251, 19435, 19531, 1296, 12807, 23144, 981, 19345, 2840, 19020, 22271, 20250, 27489, 22479, 19240, 20891, 14737, 3500, 19343, 19013, 19245, 23157, 11183, 27811, 27813, 27814, 27818, 19497, 21487, 19351, 12019, 19649, 24501, 18997, 2845, 8176, 19470, 980, 3708, 16256, 19474, 23699, 15175, 19574, 3621, 24409, 8143, 19243, 21085, 1695, 21086, 7945, 25043, 10367, 23208, 19001, 19498, 19238, 8159, 20917, 19043, 18914, 19530, 2847, 15012, 22491, 19339, 14731, 18998, 23535, 12029, 22270, 19562, 18278, 19450, 3779, 19234, 8116, 23897,

				-- Battlemaster (https://www.wowhead.com/tbc/npcs?filter=20;1;0)
				12197, 14981, 18895, 15105, 3890, 20384, 14990, 25991, 15008, 15007, 907, 19858, 20388, 19911, 5118, 14991, 15103, 20497, 19910, 20271, 20381, 19912, 857, 20118, 19908, 15106, 20386, 12198, 19859, 21235, 20273, 22101, 19923, 20383, 22013, 347, 20374, 20119, 19915, 19925, 7427, 20120, 20390, 22015, 20274, 10360, 16696, 19855, 7410, 20385, 15006, 16695, 14942, 20269, 19909, 15102, 20276, 2302, 20499, 19907, 16694, 20272, 19905, 20362, 2804, 14982, 19906,

			}

			-- Event handler
			gossipFrame:SetScript("OnEvent", function()
				-- Special treatment for specific NPCs
				local npcGuid = UnitGUID("npc") or nil
				if npcGuid and not IsShiftKeyDown() then
					local void, void, void, void, void, npcID = strsplit("-", npcGuid)
					if npcID then
						-- Skip gossip with no alt key requirement
						if npcID == "999999999"	-- Reserved for future use
						or tContains(npcTable, tonumber(npcID))
						then
							SkipGossip(true) 	-- true means skip alt key requirement
							return
						end
					end
				end
				-- Process gossip
				SkipGossip()
			end)

			-- Show battleground name in battfield frame labels
			hooksecurefunc("BattlefieldFrame_Update", function()
				if LeaPlusLC["AutomateGossip"] == "On" then
					local localizedName = GetBattlegroundInfo()
					if localizedName then
						BattlefieldFrameFrameLabel:SetText(localizedName)
					end
				end
			end)

		end

		----------------------------------------------------------------------
		--	Faster looting
		----------------------------------------------------------------------

		if LeaPlusLC["FasterLooting"] == "On" then

			-- Time delay
			local tDelay = 0

			-- Fast loot function
			local function FastLoot()
				if GetTime() - tDelay >= 0.3 then
					tDelay = GetTime()
					if GetCVarBool("autoLootDefault") ~= IsModifiedClick("AUTOLOOTTOGGLE") then
						if TSMDestroyBtn and TSMDestroyBtn:IsShown() and TSMDestroyBtn:GetButtonState() == "DISABLED" then tDelay = GetTime() return end
						local lootMethod = C_PartyInfo.GetLootMethod()
						if lootMethod == 2 then
							-- Master loot is enabled so fast loot if item should be auto looted
							local lootThreshold = GetLootThreshold()
							for i = GetNumLootItems(), 1, -1 do
								local lootIcon, lootName, lootQuantity, currencyID, lootQuality = GetLootSlotInfo(i)
								if lootQuality and lootThreshold and lootQuality < lootThreshold then
									LootSlot(i)
								end
							end
						else
							-- Master loot is disabled so fast loot regardless
							for i = GetNumLootItems(), 1, -1 do
								LootSlot(i)
							end
						end
						tDelay = GetTime()
					end
				end
			end

			-- Event frame
			local faster = CreateFrame("Frame")
			faster:RegisterEvent("LOOT_READY")
			faster:SetScript("OnEvent", FastLoot)

		end

		----------------------------------------------------------------------
		--	Disable bag automation
		----------------------------------------------------------------------

		if LeaPlusLC["NoBagAutomation"] == "On" and not LeaLockList["NoBagAutomation"] then
			RunScript("hooksecurefunc('OpenAllBags', CloseAllBags)")
		end

		----------------------------------------------------------------------
		--	Automate quests (no reload required)
		----------------------------------------------------------------------

		do

			-- Create configuration panel
			local QuestPanel = LeaPlusLC:CreatePanel("Automate quests", "QuestPanel")

			LeaPlusLC:MakeTx(QuestPanel, "Settings", 16, -72)
			LeaPlusLC:MakeCB(QuestPanel, "AutoQuestAvailable", "Accept available quests automatically", 16, -92, false, "If checked, available quests will be accepted automatically.")
			LeaPlusLC:MakeCB(QuestPanel, "AutoQuestCompleted", "Turn-in completed quests automatically", 16, -112, false, "If checked, completed quests will be turned-in automatically.")
			LeaPlusLC:MakeCB(QuestPanel, "AutoQuestShift", "Require override key for quest automation", 16, -132, false, "If checked, you will need to hold the override key down for quests to be automated.|n|nIf unchecked, holding the override key will prevent quests from being automated.")

			LeaPlusLC:CreateDropdown("AutoQuestKeyMenu", "Override key", 146, "TOPLEFT", QuestPanel, "TOPLEFT", 356, -92, false, {{L["SHIFT"], 1}, {L["ALT"], 2}, {L["CONTROL"], 3}, {L["CMD (MAC)"], 4}})

			-- Help button hidden
			QuestPanel.h:Hide()

			-- Back button handler
			QuestPanel.b:SetScript("OnClick", function()
				QuestPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page1"]:Show();
				return
			end)

			-- Reset button handler
			QuestPanel.r:SetScript("OnClick", function()

				-- Reset checkboxes
				LeaPlusLC["AutoQuestShift"] = "Off"
				LeaPlusLC["AutoQuestAvailable"] = "On"
				LeaPlusLC["AutoQuestCompleted"] = "On"
				LeaPlusLC["AutoQuestKeyMenu"] = 1

				-- Refresh panel
				QuestPanel:Hide(); QuestPanel:Show()

			end)

			-- Show panal when options panel button is clicked
			LeaPlusCB["AutomateQuestsBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					LeaPlusLC["AutoQuestShift"] = "Off"
					LeaPlusLC["AutoQuestAvailable"] = "On"
					LeaPlusLC["AutoQuestCompleted"] = "On"
					LeaPlusLC["AutoQuestKeyMenu"] = 1
				else
					QuestPanel:Show()
					LeaPlusLC:HideFrames()
				end
			end)

			-- Function to determine if override key is being held
			local function IsOverrideKeyDown()
				if LeaPlusLC["AutoQuestKeyMenu"] == 1 and IsShiftKeyDown()
				or LeaPlusLC["AutoQuestKeyMenu"] == 2 and IsAltKeyDown()
				or LeaPlusLC["AutoQuestKeyMenu"] == 3 and IsControlKeyDown()
				or LeaPlusLC["AutoQuestKeyMenu"] == 4 and IsMetaKeyDown()
				then
					return true
				end
			end

			-- Funcion to ignore specific NPCs
			local function isNpcBlocked(actionType)
				local npcGuid = UnitGUID("npc") or nil -- works when SoftTargetInteract set to 3
				if npcGuid then
					local void, void, void, void, void, npcID = strsplit("-", npcGuid)
					if npcID then
						-- Ignore specific NPCs for selecting, accepting and turning-in quests (required if automation has consequences)
						if npcID == "15192"	-- Anachronos (Caverns of Time)
						or npcID == "19935" -- Soridormi (The Scale of Sands, Caverns of Time)
						or npcID == "19936" -- Arazmodu (The Scale of Sands, Caverns of Time)
						or npcID == "3430" 	-- Mangletooth (Blood Shard quests, Barrens)
						or npcID == "14828" -- Gelvas Grimegate (Darkmoon Faire Ticket Redemption, Elwynn Forest and Mulgore)
						or npcID == "14921" -- Rin'wosho the Trader (Zul'Gurub Isle, Stranglethorn Vale)
						or npcID == "18166" -- Khadgar (Allegiance to Aldor/Scryer, Shattrath)
						or npcID == "18253" -- Archmage Leryda (Violet Signet, Karazhan)
						or npcID == "15864" -- Valadar Starsong (Coin of Ancestry Collector, Moonglade)
						or npcID == "15909" -- Fariel Starsong (Coin of Ancestry Collector, Moonglade)
						or npcID == "15540" -- Windcaller Kaldon (Badge Collector, Silithus)
						-- Ignore supply officers
						or npcID == "213077" -- Elaine Compton <Supply Officer> (Stormwind)
						or npcID == "214099" -- Tamelyn Aldridge <Supply Officer> (Ironforge)
						or npcID == "214101" -- Marcy Baker <Supply Officer> (Darnassus)
						or npcID == "214070" -- Jornah <Supply Officer> (Orgrimmar)
						or npcID == "214096" -- Dokimi <Supply Officer> (Thunder Bluff)
						or npcID == "214098" -- Gishah <Supply Officer> (Undercity)
						then
							return true
						end
						-- Ignore specific NPCs for accepting quests only
						if actionType == "Accept" then
							-- Classic escort quests
							if npcID == "467" -- The Defias Traitor (The Defias Brotherhood)
							or npcID == "349" -- Corporal Keeshan (Missing In Action)
							or npcID == "1379" -- Miran (Protecting the Shipment)
							or npcID == "7766" -- Tyrion (The Attack!)
							or npcID == "1978" -- Deathstalker Erland (Escorting Erland)
							or npcID == "7784" -- Homing Robot OOX-17/TN (Rescue OOX-17/TN!)
							or npcID == "2713" -- Kinelory (Hints of a New Plague?)
							or npcID == "2768" -- Professor Phizzlethorpe (Sunken Treasure)
							or npcID == "2610" -- Shakes O'Breen (Death From Below)
							or npcID == "2917" -- Prospector Remtravel (The Absent Minded Prospector)
							or npcID == "7806" -- Homing Robot OOX-09/HL (Rescue OOX-09/HL!)
							or npcID == "3439" -- Wizzlecrank's Shredder (The Escape)
							or npcID == "3465" -- Gilthares Firebough (Free From the Hold)
							or npcID == "3568" -- Mist (Mist)
							or npcID == "3584" -- Therylune (Therylune's Escape)
							or npcID == "4484" -- Feero Ironhand (Supplies to Auberdine)
							or npcID == "3692" -- Volcor (Escape Through Force)
							or npcID == "4508" -- Willix the Importer (Willix the Importer)
							or npcID == "4880" -- "Stinky" Ignatz (Stinky's Escape)
							or npcID == "4983" -- Ogron (Questioning Reethe)
							or npcID == "5391" -- Galen Goodward (Galen's Escape)
							or npcID == "5644" -- Dalinda Malem (Return to Vahlarriel)
							or npcID == "5955" -- Tooga (Tooga's Quest)
							or npcID == "7780" -- Rin'ji (Rin'ji is Trapped!)
							or npcID == "7807" -- Homing Robot OOX-22/FE (Rescue OOX-22/FE!)
							or npcID == "7774" -- Shay Leafrunner (Wandering Shay)
							or npcID == "7850" -- Kernobee (A Fine Mess)
							or npcID == "8284" -- Dorius Stonetender (Suntara Stones)
							or npcID == "8380" -- Captain Vanessa Beltis (A Crew Under Fire)
							or npcID == "8516" -- Belnistrasz (Extinguishing the Idol)
							or npcID == "9020" -- Commander Gor'shak (What Is Going On?)
							or npcID == "9520" -- Grark Lorkrub (Precarious Predicament)
							or npcID == "9623" -- A-Me 01 (Chasing A-Me 01)
							or npcID == "9598" -- Arei (Ancient Spirit)
							or npcID == "9023" -- Marshal Windsor (Jail Break!)
							or npcID == "9999" -- Ringo (A Little Help From My Friends)
							or npcID == "10427" -- Pao'ka Swiftmountain (Homeward Bound)
							or npcID == "10300" -- Ranshalla (Guardians of the Altar)
							or npcID == "10646" -- Lakota Windsong (Free at Last)
							or npcID == "10638" -- Kanati Greycloud (Protect Kanati Greycloud)
							or npcID == "11016" -- Captured Arko'narin (Rescue From Jaedenar)
							or npcID == "11218" -- Kerlonian Evershade (The Sleeper Has Awakened)
							or npcID == "11711" -- Sentinel Aynasha (One Shot. One Kill.)
							or npcID == "11625" -- Cork Gizelton (Bodyguard for Hire)
							or npcID == "11626" -- Rigger Gizelton (Gizelton Caravan)
							or npcID == "1842" -- Highlord Taelan Fordring (In Dreams)
							or npcID == "12277" -- Melizza Brimbuzzle (Get Me Out of Here!)
							or npcID == "12580" -- Reginald Windsor (The Great Masquerade)
							or npcID == "12818" -- Ruul Snowhoof (Freedom to Ruul)
							or npcID == "11856" -- Kaya Flathoof (Protect Kaya)
							or npcID == "12858" -- Torek (Torek's Assault)
							or npcID == "12717" -- Muglash (Vorsha the Lasher)
							or npcID == "13716" -- Celebras the Redeemed (The Scepter of Celebras)
							or npcID == "19401" -- Wing Commander Brack (Return to the Abyssal Shelf) (Horde)
							or npcID == "20235" -- Gryphoneer Windbellow (Return to the Abyssal Shelf) (Alliance)
							-- BCC escort quests
							or npcID == "16295" -- Ranger Lilatha (Escape from the Catacombs)
							or npcID == "17238" -- Anchorite Truuen (Tomb of the Lightbringer)
							or npcID == "17312" -- Magwin (A Cry For Help)
							or npcID == "17877" -- Fhwoor (Fhwoor Smash!)
							or npcID == "17969" -- Kayra Longmane (Escape from Umbrafen)
							or npcID == "18210" -- Mag'har Captive (The Totem of Kar'dash, Horde)
							or npcID == "18209" -- Kurenai Captive (The Totem of Kar'dash, Alliance)
							or npcID == "18760" -- Isla Starmane (Escape from Firewing Point!)
							or npcID == "19589" -- Maxx A. Million Mk. V (Mark V is Alive!)
							or npcID == "19671" -- Cryo-Engineer Sha'heen (Someone Else's Hard Work Pays Off)
							or npcID == "20281" -- Drijya (Sabotage the Warp-Gate!)
							or npcID == "20415" -- Bessy (When the Cows Come Home)
							or npcID == "20482" -- Image of Commander Ameer (Delivering the Message)
							or npcID == "20763" -- Captured Protectorate Vanguard (Escape from the Staging Grounds)
							or npcID == "21027" -- Earthmender Wilda (Escape from Coilskar Cistern)
							or npcID == "22424" -- Skywing (Skywing)
							or npcID == "22458" -- Chief Archaeologist Letoll (Digging Through Bones)
							or npcID == "23383" -- Skyguard Prisoner (Escape from Skettis)
							then
								return true
							end
						end
						-- Ignore specific NPCs for selecting quests only (only used for items that have no other purpose)
						if actionType == "Select" then
							if npcID == "12944" -- Lokhtos Darkbargainer (Thorium Brotherhood, Blackrock Depths)
							or npcID == "19401" -- Wing Commander Brack (Return to the Abyssal Shelf) (Horde)
							or npcID == "20235" -- Gryphoneer Windbellow (Return to the Abyssal Shelf) (Alliance)
							or npcID == "10307" -- Witch Doctor Mau'ari (E'Ko quests, Winterspring)
							-- Ahn'Qiraj War Effort (Alliance, Ironforge)
							or npcID == "15446" -- Bonnie Stoneflayer (Light Leather Collector)
							or npcID == "15458" -- Commander Stronghammer (Alliance Ambassador)
							or npcID == "15431" -- Corporal Carnes (Iron Bar Collector)
							or npcID == "15432" -- Dame Twinbraid (Thorium Bar Collector)
							or npcID == "15453" -- Keeper Moonshade (Runecloth Bandage Collector)
							or npcID == "15457" -- Huntress Swiftriver (Spotted Yellowtail Collector)
							or npcID == "15450" -- Marta Finespindle (Thick Leather Collector)
							or npcID == "15437" -- Master Nightsong (Purple Lotus Collector)
							or npcID == "15452" -- Nurse Stonefield (Silk Bandage Collector)
							or npcID == "15434" -- Private Draxlegauge (Stranglekelp Collector)
							or npcID == "15448" -- Private Porter (Medium Leather Collector)
							or npcID == "15456" -- Sarah Sadwhistle (Roast Raptor Collector)
							or npcID == "15451" -- Sentinel Silversky (Linen Bandage Collector)
							or npcID == "15445" -- Sergeant Major Germaine (Arthas' Tears Collector)
							or npcID == "15383" -- Sergeant Stonebrow (Copper Bar Collector)
							or npcID == "15455" -- Slicky Gastronome (Rainbow Fin Albacore Collector)
							-- Ahn'Qiraj War Effort (Horde, Orgrimmar)
							or npcID == "15512" -- Apothecary Jezel (Purple Lotus Collector)
							or npcID == "15508" -- Batrider Pele'keiki (Firebloom Collector)
							or npcID == "15533" -- Bloodguard Rawtar (Lean Wolf Steak Collector)
							or npcID == "15535" -- Chief Sharpclaw (Baked Salmon Collector)
							or npcID == "15525" -- Doctor Serratus (Rugged Leather Collector)
							or npcID == "15534" -- Fisherman Lin'do (Spotted Yellowtail Collector)
							or npcID == "15539" -- General Zog (Horde Ambassador)
							or npcID == "15460" -- Grunt Maug (Tin Bar Collector)
							or npcID == "15528" -- Healer Longrunner (Wool Bandage Collector)
							or npcID == "15477" -- Herbalist Proudfeather (Peacebloom Collector)
							or npcID == "15529" -- Lady Callow (Mageweave Bandage Collector)
							or npcID == "15459" -- Miner Cromwell (Copper Bar Collector)
							or npcID == "15469" -- Senior Sergeant T'kelah (Mithril Bar Collector)
							or npcID == "15522" -- Sergeant Umala (Thick Leather Collector)
							or npcID == "15515" -- Skinner Jamani (Heavy Leather Collector)
							or npcID == "15532" -- Stoneguard Clayhoof (Runecloth Bandage Collector)
							-- Alliance Commendations
							or npcID == "15764" -- Officer Ironbeard (Ironforge Commendations)
							or npcID == "15762" -- Officer Lunalight (Darnassus Commendations)
							or npcID == "15766" -- Officer Maloof (Stormwind Commendations)
							or npcID == "15763" -- Officer Porterhouse (Gnomeregan Commendations)
							-- Horde Commendations
							or npcID == "15768" -- Officer Gothena (Undercity Commendations)
							or npcID == "15765" -- Officer Redblade (Orgrimmar Commendations)
							or npcID == "15767" -- Officer Thunderstrider (Thunder Bluff Commendations)
							or npcID == "15761" -- Officer Vu'Shalay (Darkspear Commendations)
							-- Battlegrounds (Alliance)
							or npcID == "13442" -- Arch Druid Renferal (Storm Crystal, Alterac Valley)
							-- Battlegrounds (Horde)
							or npcID == "13236" -- Primalist Thurloga (Stormpike Soldier's Blood, Alterac Valley)
							-- Scourgestones
							or npcID == "11039" -- Duke Nicholas Zverenhoff (Eastern Plaguelands)
							-- Un'Goro crystals
							or npcID == "9117" 	-- J. D. Collie (Un'Goro Crater)
							then
								return true
							end
						end
					end
				end
			end

			-- Function to check if quest requires a blocked item
			local function QuestRequiresBlockedItem()
				for i = 1, 6 do
					local progItem = _G["QuestProgressItem" ..i] or nil
					if progItem and progItem:IsShown() and progItem.type == "required" then
						if progItem.objectType == "item" then
							local name, texture, numItems = GetQuestItemInfo("required", i)
							if name then
								local itemID = C_Item.GetItemInfoInstant(name)
								if itemID then
									if itemID == 9999999999 then -- Reserved for future use
										return true
									end
								end
							end
						end
					end
				end
			end

			-- Function to check if quest requires gold
			local function QuestRequiresGold()
				local goldRequiredAmount = GetQuestMoneyToGet()
				if goldRequiredAmount and goldRequiredAmount > 0 then
					return true
				end
			end

			-- Function to check if quest title has requirements met
			local function DoesQuestHaveRequirementsMet(title)
				if title and title ~= "" then

					if not title then

					-- Battlemasters
					elseif title == L["Concerted Efforts"] or title == L["For Great Honor"] then
						-- Requires 3 Alterac Valley Mark of Honor, 3 Arathi Basin Mark of Honor, 3 Warsong Gulch Mark of Honor (must be before other Mark of Honor quests)
						if C_Item.GetItemCount(20560) >= 3 and C_Item.GetItemCount(20559) >= 3 and C_Item.GetItemCount(20558) >= 3 then return true end
					elseif title == L["Remember Alterac Valley!"] or title == L["Invaders of Alterac Valley"] then
						-- Requires 3 Alterac Valley Mark of Honor
						if C_Item.GetItemCount(20560) >= 3 then return true end
					elseif title == L["Claiming Arathi Basin"] or title == L["Conquering Arathi Basin"] then
						-- Requires 3 Arathi Basin Mark of Honor
						if C_Item.GetItemCount(20559) >= 3 then return true end
					elseif title == L["Fight for Warsong Gulch"] or title == L["Battle of Warsong Gulch"] then
						-- Requires 3 Warsong Gulch Mark of Honor
						if C_Item.GetItemCount(20558) >= 3 then return true end

					-- Cloth quartermasters
					elseif title == L["A Donation of Wool"] then
						-- Requires 60 Wool Cloth
						if C_Item.GetItemCount(2592) >= 60 then return true end
					elseif title == L["A Donation of Silk"] then
						-- Requires 60 Silk Cloth
						if C_Item.GetItemCount(4306) >= 60 then return true end
					elseif title == L["A Donation of Mageweave"] then
						-- Requires 60 Mageweave
						if C_Item.GetItemCount(4338) >= 60 then return true end
					elseif title == L["A Donation of Runecloth"] then
						-- Requires 60 Runecloth
						if C_Item.GetItemCount(14047) >= 60 then return true end
					elseif title == L["Additional Runecloth"] then
						-- Requires 20 Runecloth
						if C_Item.GetItemCount(14047) >= 20 then return true end
					elseif title == L["Gurubashi, Vilebranch, and Witherbark Coins"] then
						-- Requires 1 Gurubashi Coin, 1 Vilebranch Coin, 1 Witherbark Coin
						if C_Item.GetItemCount(19701) >= 1 and C_Item.GetItemCount(19702) >= 1 and C_Item.GetItemCount(19703) >= 1 then return true end
					elseif title == L["Sandfury, Skullsplitter, and Bloodscalp Coins"] then
						-- Requires 1 Sandfury Coin, 1 Skullsplitter Coin, 1 Bloodscalp Coin
						if C_Item.GetItemCount(19704) >= 1 and C_Item.GetItemCount(19705) >= 1 and C_Item.GetItemCount(19706) >= 1 then return true end
					elseif title == L["Zulian, Razzashi, and Hakkari Coins"] then
						-- Requires 1 Zulian Coin, 1 Razzashi Coin, 1 Hakkari Coin
						if C_Item.GetItemCount(19698) >= 1 and C_Item.GetItemCount(19699) >= 1 and C_Item.GetItemCount(19700) >= 1 then return true end
					elseif title == L["Frostsaber E'ko"] then
						-- Requires 3 Frostsaber E'ko
						if C_Item.GetItemCount(12430) >= 3 then return true end
					elseif title == L["Winterfall E'ko"] then
						-- Requires 3 Winterfall E'ko
						if C_Item.GetItemCount(12431) >= 3 then return true end
					elseif title == L["Shardtooth E'ko"] then
						-- Requires 3 Shardtooth E'ko
						if C_Item.GetItemCount(12432) >= 3 then return true end
					elseif title == L["Wildkin E'ko"] then
						-- Requires 3 Wildkin E'ko
						if C_Item.GetItemCount(12433) >= 3 then return true end
					elseif title == L["Chillwind E'ko"] then
						-- Requires 3 Chillwind E'ko
						if C_Item.GetItemCount(12434) >= 3 then return true end
					elseif title == L["Ice Thistle E'ko"] then
						-- Requires 3 Ice Thistle E'ko
						if C_Item.GetItemCount(12435) >= 3 then return true end
					elseif title == L["Frostmaul E'ko"] then
						-- Requires 3 Ice Thistle E'ko
						if C_Item.GetItemCount(12436) >= 3 then return true end
					elseif title == L["Marks of Kil'jaeden"] or title == L["More Marks of Kil'jaeden"] then
						-- Requires 10 More Marks of Kil'jaeden
						if C_Item.GetItemCount(29425) >= 10 then return true end
					elseif title == L["Single Mark of Sargeras"] then
						-- Requires 1 Marks of Sargeras (if more than 10, leave for More Marks of Sargeras)
						if C_Item.GetItemCount(30809) >= 1 and C_Item.GetItemCount(30809) < 10 then return true end
					elseif title == L["More Marks of Sargeras"] then
						-- Requires 10 Marks of Sargeras
						if C_Item.GetItemCount(30809) >= 10 then return true end
					elseif title == L["Firewing Signets"] or title == L["More Firewing Signets"] then
						-- Requires 10 Firewing Signets
						if C_Item.GetItemCount(29426) >= 10 then return true end
					elseif title == L["Single Sunfury Signet"] then
						-- Requires 1 Sunfury Signet (if more than 10, leave for More Sunfury Signets)
						if C_Item.GetItemCount(30810) >= 1 and C_Item.GetItemCount(30810) < 10 then return true end
					elseif title == L["More Sunfury Signets"] then
						-- Requires 10 Sunfury Signets
						if C_Item.GetItemCount(30810) >= 10 then return true end

					-- Darkmoon Faire (Rinling)
					elseif title == L["Copper Modulator"] then
						if C_Item.GetItemCount(4363) >= 5 then return true end
					elseif title == L["Whirring Bronze Gizmo"] then
						if C_Item.GetItemCount(4375) >= 7 then return true end
					elseif title == L["Green Fireworks"] then
						if C_Item.GetItemCount(9313) >= 36 then return true end
					elseif title == L["Mechanical Repair Kits"] then
						if C_Item.GetItemCount(11590) >= 6 then return true end
					elseif title == L["Thorium Widget"] then
						if C_Item.GetItemCount(15994) >= 6 then return true end
					elseif title == L["More Thorium Widgets"] then
						if C_Item.GetItemCount(15994) >= 6 then return true end

					-- Darkmoon Faire (Yebb Neblegear)
					elseif title == L["Small Furry Paws"] then
						if C_Item.GetItemCount(5134) >= 5 then return true end
					elseif title == L["Evil Bat Eyes"] then
						if C_Item.GetItemCount(11404) >= 10 then return true end
					elseif title == L["Glowing Scorpid Blood"] then
						if C_Item.GetItemCount(19933) >= 10 then return true end
					elseif title == L["More Bat Eyes"] then
						if C_Item.GetItemCount(11404) >= 10 then return true end
					elseif title == L["More Glowing Scorpid Blood"] then
						if C_Item.GetItemCount(19933) >= 10 then return true end
					elseif title == L["Soft Bushy Tails"] then
						if C_Item.GetItemCount(4582) >= 5 then return true end
					elseif title == L["Torn Bear Pelts"] then
						if C_Item.GetItemCount(11407) >= 5 then return true end
					elseif title == L["Vibrant Plumes"] then
						if C_Item.GetItemCount(5117) >= 5 then return true end

					-- Darkmoon Faire (Chronos)
					elseif title == L["Armor Kits"] then
						if C_Item.GetItemCount(15564) >= 8 then return true end
					elseif title == L["Carnival Boots"] then
						if C_Item.GetItemCount(2309) >= 3 then return true end
					elseif title == L["Carnival Jerkins"] then
						if C_Item.GetItemCount(2314) >= 3 then return true end
					elseif title == L["Crocolisk Boy and the Bearded Murloc"] then
						if C_Item.GetItemCount(8185) >= 1 then return true end
					elseif title == L["More Armor Kits"] then
						if C_Item.GetItemCount(15564) >= 8 then return true end
					elseif title == L["The World's Largest Gnome!"] then
						if C_Item.GetItemCount(5739) >= 3 then return true end

					-- Darkmoon Faire (Kerri Hicks)
					elseif title == L["Big Black Mace"] then
						if C_Item.GetItemCount(7945) >= 1 then return true end
					elseif title == L["Coarse Weightstone"] then
						if C_Item.GetItemCount(3240) >= 10 then return true end
					elseif title == L["Green Iron Bracers"] then
						if C_Item.GetItemCount(3835) >= 3 then return true end
					elseif title == L["Heavy Grinding Stone"] then
						if C_Item.GetItemCount(3486) >= 7 then return true end
					elseif title == L["More Dense Grinding Stones"] then
						if C_Item.GetItemCount(12644) >= 8 then return true end
					elseif title == L["Rituals of Strength"] then
						if C_Item.GetItemCount(12644) >= 8 then return true end

					else return true
					end
				end
			end

			-- Create event frame
			local qFrame = CreateFrame("FRAME")

			-- Function to setup events
			local function SetupEvents()
				if LeaPlusLC["AutomateQuests"] == "On" then
					qFrame:RegisterEvent("QUEST_DETAIL")
					qFrame:RegisterEvent("QUEST_ACCEPT_CONFIRM")
					qFrame:RegisterEvent("QUEST_PROGRESS")
					qFrame:RegisterEvent("QUEST_COMPLETE")
					qFrame:RegisterEvent("QUEST_GREETING")
					qFrame:RegisterEvent("QUEST_AUTOCOMPLETE")
					qFrame:RegisterEvent("GOSSIP_SHOW")
					qFrame:RegisterEvent("QUEST_FINISHED")
				else
					qFrame:UnregisterAllEvents()
				end
			end

			-- Setup events when option is clicked and on startup (if option is enabled)
			LeaPlusCB["AutomateQuests"]:HookScript("OnClick", SetupEvents)
			if LeaPlusLC["AutomateQuests"] == "On" then SetupEvents() end

			-- Event handler
			qFrame:SetScript("OnEvent", function(self, event, arg1)

				-- Block shared quests if option is enabled
				if event == "QUEST_DETAIL" then
					LeaPlusLC:CheckIfQuestIsSharedAndShouldBeDeclined()
				end

				-- Clear progress items when quest interaction has ceased
				if event == "QUEST_FINISHED" then
					for i = 1, 6 do
						local progItem = _G["QuestProgressItem" ..i] or nil
						if progItem and progItem:IsShown() then
							progItem:Hide()
						end
					end
					return
				end

				-- Check for SHIFT key modifier
				if LeaPlusLC["AutoQuestShift"] == "On" and not IsOverrideKeyDown() then return
				elseif LeaPlusLC["AutoQuestShift"] == "Off" and IsOverrideKeyDown() then return
				end

				----------------------------------------------------------------------
				-- Accept quests automatically
				----------------------------------------------------------------------

				-- Accept quests with a quest detail window
				if event == "QUEST_DETAIL" then
					if LeaPlusLC["AutoQuestAvailable"] == "On" then
						-- Don't accept blocked quests
						if isNpcBlocked("Accept") then return end
						-- Accept quest
						AcceptQuest()
						-- HideUIPanel(QuestFrame)
					end
				end

				-- Accept quests which require confirmation (such as sharing escort quests)
				if event == "QUEST_ACCEPT_CONFIRM" then
					if LeaPlusLC["AutoQuestAvailable"] == "On" then
						ConfirmAcceptQuest()
						StaticPopup_Hide("QUEST_ACCEPT")
					end
				end

				----------------------------------------------------------------------
				-- Turn-in quests automatically
				----------------------------------------------------------------------

				-- Turn-in progression quests
				if event == "QUEST_PROGRESS" and IsQuestCompletable() then
					if LeaPlusLC["AutoQuestCompleted"] == "On" then
						-- Don't continue quests for blocked NPCs
						if isNpcBlocked("Complete") then return end
						-- Don't continue if quest requires blocked item
						if QuestRequiresBlockedItem() then return end
						-- Don't continue if quest requires gold
						if QuestRequiresGold() then return end
						-- Continue quest
						CompleteQuest()
					end
				end

				-- Turn in completed quests if only one reward item is being offered
				if event == "QUEST_COMPLETE" then
					if LeaPlusLC["AutoQuestCompleted"] == "On" then
						-- Don't complete quests for blocked NPCs
						if isNpcBlocked("Complete") then return end
						-- Don't complete if quest requires blocked item
						if QuestRequiresBlockedItem() then return end
						-- Don't complete if quest requires gold
						if QuestRequiresGold() then return end
						-- Complete quest
						if GetNumQuestChoices() <= 1 then
							GetQuestReward(GetNumQuestChoices())
						end
					end
				end

				-- Show quest dialog for quests that use the objective tracker (it will be completed automatically)
				if event == "QUEST_AUTOCOMPLETE" then
					if LeaPlusLC["AutoQuestCompleted"] == "On" then
						local index = GetQuestLogIndexByID(arg1)
						if GetQuestLogIsAutoComplete(index) then
							ShowQuestComplete(index)
						end
					end
				end

				----------------------------------------------------------------------
				-- Select quests automatically
				----------------------------------------------------------------------

				if event == "GOSSIP_SHOW" or event == "QUEST_GREETING" then

					-- Select quests
					if UnitExists("npc") or QuestFrameGreetingPanel:IsShown() then

						-- Don't select quests for blocked NPCs
						if isNpcBlocked("Select") then return end

						-- Select quests
						if event == "QUEST_GREETING" then
							-- Select quest greeting completed quests
							if LeaPlusLC["AutoQuestCompleted"] == "On" then
								for i = 1, GetNumActiveQuests() do
									local title, isComplete = GetActiveTitle(i)
									if title and isComplete then
										return SelectActiveQuest(i)
									end
								end
							end
							-- Select quest greeting available quests
							if LeaPlusLC["AutoQuestAvailable"] == "On" then
								for i = 1, GetNumAvailableQuests() do
									local title, isComplete = GetAvailableTitle(i)
									if title and not isComplete then
										return SelectAvailableQuest(i)
									end
								end
							end
						else
							-- Select gossip completed quests
							-- questInfo.isComplete can return false for completed quests with no objectives in Classic Era (test with first quest for level 1 Orc) (does not currently apply to Wrath Classic or Dragonflight)
							if LeaPlusLC["AutoQuestCompleted"] == "On" then
								local gossipQuests = C_GossipInfo.GetActiveQuests()
								for titleIndex, questInfo in ipairs(gossipQuests) do
									if questInfo.title and (questInfo.isComplete or questInfo.questID and IsQuestComplete(questInfo.questID)) then
										if questInfo.questID then
											return C_GossipInfo.SelectActiveQuest(questInfo.questID)
										end
									end
								end
							end
							-- Select gossip available quests
							if LeaPlusLC["AutoQuestAvailable"] == "On" then
								local GossipQuests = C_GossipInfo.GetAvailableQuests()
								for titleIndex, questInfo in ipairs(GossipQuests) do
									if questInfo.questID and DoesQuestHaveRequirementsMet(questInfo.questID) then
										return C_GossipInfo.SelectAvailableQuest(questInfo.questID)
									end
								end
							end
						end
					end
				end

			end)

		end

		----------------------------------------------------------------------
		--	Sell junk automatically (no reload required)
		----------------------------------------------------------------------

		do

			-- Create sell junk banner
			local StartMsg = CreateFrame("FRAME", nil, MerchantFrame)
			StartMsg:ClearAllPoints()
			StartMsg:SetPoint("BOTTOMLEFT", 4, 4)
			StartMsg:SetSize(160, 22)
			StartMsg:SetToplevel(true)
			StartMsg:Hide()

			StartMsg.s = StartMsg:CreateTexture(nil, "BACKGROUND")
			StartMsg.s:SetAllPoints()
			StartMsg.s:SetColorTexture(0.1, 0.1, 0.1, 1.0)

			StartMsg.f = StartMsg:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
			StartMsg.f:SetAllPoints();
			StartMsg.f:SetText(L["SELLING JUNK"])

			-- Declarations
			local IterationCount, totalPrice = 500, 0
			local SellJunkTicker

			-- Create custom NewTicker function (from Wrath)
			local function LeaPlusNewTicker(duration, callback, iterations)
				local ticker = setmetatable({}, TickerMetatable)
				ticker._remainingIterations = iterations
				ticker._callback = function()
					if (not ticker._cancelled) then
						callback(ticker)
						--Make sure we weren't cancelled during the callback
						if (not ticker._cancelled) then
							if (ticker._remainingIterations) then
								ticker._remainingIterations = ticker._remainingIterations - 1
							end
							if (not ticker._remainingIterations or ticker._remainingIterations > 0) then
								C_Timer.After(duration, ticker._callback)
							end
						end
					end
				end
				C_Timer.After(duration, ticker._callback)
				return ticker
			end

			-- Create configuration panel
			local SellJunkFrame = LeaPlusLC:CreatePanel("Sell junk automatically", "SellJunkFrame")
			LeaPlusLC:MakeTx(SellJunkFrame, "Settings", 16, -72)
			LeaPlusLC:MakeCB(SellJunkFrame, "AutoSellShowSummary", "Show vendor summary in chat", 16, -92, false, "If checked, a vendor summary will be shown in chat when junk is automatically sold.")

			-- Help button hidden
			SellJunkFrame.h:Hide()

			-- Back button handler
			SellJunkFrame.b:SetScript("OnClick", function()
				SellJunkFrame:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page1"]:Show();
				return
			end)

			-- Reset button handler
			SellJunkFrame.r.tiptext = SellJunkFrame.r.tiptext .. "|n|n" .. L["Note that this will not reset your exclusions list."]
			SellJunkFrame.r:SetScript("OnClick", function()

				-- Reset checkboxes
				LeaPlusLC["AutoSellShowSummary"] = "On"

				-- Refresh panel
				SellJunkFrame:Hide(); SellJunkFrame:Show()

			end)

			-- Show panal when options panel button is clicked
			LeaPlusCB["AutoSellJunkBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					LeaPlusLC["AutoSellShowSummary"] = "On"
				else
					SellJunkFrame:Show()
					LeaPlusLC:HideFrames()
				end
			end)

			-- Function to stop selling
			local function StopSelling()
				if SellJunkTicker then SellJunkTicker._cancelled = true; end
				StartMsg:Hide()
				SellJunkFrame:UnregisterEvent("ITEM_LOCKED")
				SellJunkFrame:UnregisterEvent("UI_ERROR_MESSAGE")
			end

			-- Create excluded box
			local titleTX = LeaPlusLC:MakeTx(SellJunkFrame, "Exclusions", 356, -72)
			titleTX:SetWidth(200)
			titleTX:SetWordWrap(false)
			titleTX:SetJustifyH("LEFT")

			-- Show help button for exclusions
			LeaPlusLC:CreateHelpButton("SellJunkExcludeHelpButton", SellJunkFrame, titleTX, "Enter item IDs separated by commas.  Item IDs can be found in item tooltips while this panel is showing.|n|nJunk items entered here will not be sold automatically.|n|nWhite items entered here will be sold automatically.|n|nThe editbox tooltip will show you more information about the items you have entered.")

			local eb = CreateFrame("Frame", nil, SellJunkFrame, "BackdropTemplate")
			eb:SetSize(200, LeaPlusLC.MainPanelHeight - 180)
			eb:SetPoint("TOPLEFT", 350, -92)
			eb:SetBackdrop({
				bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
				edgeFile = "Interface\\PVPFrame\\UI-Character-PVP-Highlight",
				edgeSize = 16,
				insets = {left = 8, right = 6, top = 8, bottom = 8},
			})
			eb:SetBackdropBorderColor(1.0, 0.85, 0.0, 0.5)

			eb.scroll = CreateFrame("ScrollFrame", nil, eb, "LeaPlusSellJunkScrollFrameTemplate")
			eb.scroll:SetPoint("TOPLEFT", eb, 12, -10)
			eb.scroll:SetPoint("BOTTOMRIGHT", eb, -30, 10)
			eb.scroll:SetPanExtent(16)

			-- Create character count
			eb.scroll.CharCount = eb.scroll:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
			eb.scroll.CharCount:Hide()

			eb.Text = eb.scroll.EditBox
			eb.Text:SetWidth(150)
			eb.Text:SetPoint("TOPLEFT", eb.scroll)
			eb.Text:SetPoint("BOTTOMRIGHT", eb.scroll, -12, 0)
			eb.Text:SetMaxLetters(2000)
			eb.Text:SetFontObject(GameFontNormalLarge)
			eb.Text:SetAutoFocus(false)
			eb.scroll:SetScrollChild(eb.Text)

			-- Set focus on the editbox text when clicking the editbox
			eb:SetScript("OnMouseDown", function()
				eb.Text:SetFocus()
				eb.Text:SetCursorPosition(eb.Text:GetMaxLetters())
			end)

			-- Function to create whitelist
			local whiteList = {}
			local function UpdateWhiteList()
				wipe(whiteList)

				local whiteString = eb.Text:GetText()
				if whiteString and whiteString ~= "" then
					whiteString = whiteString:gsub("[^,%d]", "")
					local tList = {strsplit(",", whiteString)}
					for i = 1, #tList do
						if tList[i] then
							tList[i] = tonumber(tList[i])
							if tList[i] then
								whiteList[tList[i]] = true
							end
						end
					end
				end

				LeaPlusLC["AutoSellExcludeList"] = whiteString
				eb.Text:SetText(LeaPlusLC["AutoSellExcludeList"])

			end

			-- Save the excluded list when it changes and at startup
			eb.Text:SetScript("OnTextChanged", UpdateWhiteList)
			eb.Text:SetText(LeaPlusLC["AutoSellExcludeList"])
			UpdateWhiteList()

			-- Create whitelist on startup and option or preset is clicked
			UpdateWhiteList()
			LeaPlusCB["AutoSellJunkBtn"]:HookScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					UpdateWhiteList()
				end
			end)

			-- Function to make tooltip string
			local function MakeTooltipString()

				local keepMsg = ""
				local sellMsg = ""
				local dupMsg = ""
				local novalueMsg = ""
				local incompatMsg = ""

				local tipString = eb.Text:GetText()
				if tipString and tipString ~= "" then
					tipString = tipString:gsub("[^,%d]", "")
					local tipList = {strsplit(",", tipString)}
					for i = 1, #tipList do
						if tipList[i] then
							tipList[i] = tonumber(tipList[i])
							if tipList[i] and tipList[i] > 0 and tipList[i] < 999999999 then
								local void, tLink, Rarity, void, void, void, void, void, void, void, ItemPrice = C_Item.GetItemInfo(tipList[i])
								if tLink and tLink ~= "" then
									local linkCol = string.sub(tLink, 1, 10)
									if linkCol then
										local linkName = tLink:match("%[(.-)%]")
										if linkName and ItemPrice then
											if ItemPrice > 0 then
												if Rarity == 0 then
													-- Junk item
													if string.find(keepMsg, "%(" .. tipList[i] .. "%)") then
														-- Duplicate (ID appears more than once in list)
														dupMsg = dupMsg .. linkCol .. linkName .. " (" .. tipList[i] .. ")" .. "|r|n"
													else
														-- Add junk item to keep list
														keepMsg = keepMsg .. linkCol .. linkName .. " (" .. tipList[i] .. ")" .. "|r|n"
													end
												elseif Rarity == 1 then
													-- White item
													if string.find(sellMsg, "%(" .. tipList[i] .. "%)") then
														-- Duplicate (ID appears more than once in list)
														dupMsg = dupMsg .. linkCol .. linkName .. " (" .. tipList[i] .. ")" .. "|r|n"
													else
														-- Add non-junk item to sell list
														sellMsg = sellMsg .. linkCol .. linkName .. " (" .. tipList[i] .. ")" .. "|r|n"
													end
												else
													-- Incompatible item (not junk or white)
													if string.find(incompatMsg, "%(" .. tipList[i] .. "%)") then
														-- Duplicate (ID appears more than once in list)
														dupMsg = dupMsg .. linkCol .. linkName .. " (" .. tipList[i] .. ")" .. "|r|n"
													else
														-- Add item to incompatible list
														incompatMsg = incompatMsg .. linkCol .. linkName .. " (" .. tipList[i] .. ")" .. "|r|n"
													end
												end
											else
												-- Item has no sell price so cannot be sold
												if string.find(novalueMsg, "%(" .. tipList[i] .. "%)") then
													-- Duplicate (ID appears more than once in list)
													dupMsg = dupMsg .. linkCol .. linkName .. " (" .. tipList[i] .. ")" .. "|r|n"
												else
													-- Add item to cannot be sold list
													novalueMsg = novalueMsg .. linkCol .. linkName .. " (" .. tipList[i] .. ")" .. "|r|n"
												end
											end
										end
									end
								end
							end
						end
					end
				end

				if keepMsg ~= "" then keepMsg = "|n" .. L["Keep"] .. "|n" .. keepMsg end
				if sellMsg ~= "" then sellMsg = "|n" .. L["Sell"] .. "|n" .. sellMsg end
				if dupMsg ~= "" then dupMsg = "|n" .. L["Duplicates"] .. "|n" .. dupMsg end
				if novalueMsg ~= "" then novalueMsg = "|n" .. L["Cannot be sold"] .. "|n" .. novalueMsg end
				if incompatMsg ~= "" then incompatMsg = "|n" .. L["Incompatible"] .. "|n" .. incompatMsg end

				eb.tiptext = L["Exclusions"] .. "|n" .. keepMsg .. sellMsg .. dupMsg .. novalueMsg .. incompatMsg
				eb.Text.tiptext = L["Exclusions"] .. "|n" .. keepMsg .. sellMsg .. dupMsg .. novalueMsg .. incompatMsg
				if eb.tiptext == L["Exclusions"] .. "|n" then eb.tiptext = eb.tiptext .. "|n" .. L["Nothing to see here."] end
				if eb.Text.tiptext == L["Exclusions"] .. "|n" then eb.Text.tiptext = "-" end

				if GameTooltip:IsShown() then
					if MouseIsOver(eb) or MouseIsOver(eb.Text) then
						GameTooltip:SetText(eb.tiptext, nil, nil, nil, nil, false)
					end
				end

			end

			eb.Text:HookScript("OnTextChanged", MakeTooltipString)
			eb.Text:HookScript("OnTextChanged", function()
				C_Timer.After(0.1, function()
					MakeTooltipString()
				end)
			end)

			-- Show the button tooltip for the editbox
			eb:SetScript("OnEnter", MakeTooltipString)
			eb:HookScript("OnEnter", LeaPlusLC.TipSee)
			eb:HookScript("OnEnter", function() GameTooltip:SetText(eb.tiptext, nil, nil, nil, nil, false) end)
			eb:SetScript("OnLeave", GameTooltip_Hide)
			eb.Text:SetScript("OnEnter", MakeTooltipString)
			eb.Text:HookScript("OnEnter", LeaPlusLC.ShowDropTip)
			eb.Text:HookScript("OnEnter", function() GameTooltip:SetText(eb.tiptext, nil, nil, nil, nil, false) end)
			eb.Text:SetScript("OnLeave", GameTooltip_Hide)

			-- Show item ID in item tooltips while configuration panel is showing
			GameTooltip:HookScript("OnTooltipSetItem", function(self)
				if SellJunkFrame:IsShown() then
					local void, itemLink = self:GetItem()
					if itemLink then
						local itemID = GetItemInfoFromHyperlink(itemLink)
						if itemID then self:AddLine(L["Item ID"] .. ": " .. itemID) end
					end
				end
			end)

			-- Vendor function
			local function SellJunkFunc()

				-- Variables
				local SoldCount, Rarity, ItemPrice = 0, 0, 0
				local CurrentItemLink, void

				-- Traverse bags and sell grey items
				for BagID = 0, 4 do
					for BagSlot = 1, C_Container.GetContainerNumSlots(BagID) do
						CurrentItemLink = C_Container.GetContainerItemLink(BagID, BagSlot)
						if CurrentItemLink then
							void, void, Rarity, void, void, void, void, void, void, void, ItemPrice = C_Item.GetItemInfo(CurrentItemLink)
							-- Don't sell whitelisted items
							local itemID = GetItemInfoFromHyperlink(CurrentItemLink)
							if itemID and whiteList[itemID] then
								if Rarity == 0 then
									-- Junk item to keep
									Rarity = 3
									ItemPrice = 0
								elseif Rarity == 1 then
									-- White item to sell
									Rarity = 0
								end
							end
							-- Continue
							local cInfo = C_Container.GetContainerItemInfo(BagID, BagSlot)
							local itemCount = cInfo.stackCount
							if Rarity == 0 and ItemPrice ~= 0 then
								SoldCount = SoldCount + 1
								if MerchantFrame:IsShown() then
									-- If merchant frame is open, vendor the item
									C_Container.UseContainerItem(BagID, BagSlot)
									-- Perform actions on first iteration
									if SellJunkTicker._remainingIterations == IterationCount then
										-- Calculate total price
										totalPrice = totalPrice + (ItemPrice * itemCount)
									end
								else
									-- If merchant frame is not open, stop selling
									StopSelling()
									return
								end
							end
						end
					end
				end

				-- Stop selling if no items were sold for this iteration or iteration limit was reached
				if SoldCount == 0 or SellJunkTicker and SellJunkTicker._remainingIterations == 1 then
					StopSelling()
					if totalPrice > 0 and LeaPlusLC["AutoSellShowSummary"] == "On" then
						LeaPlusLC:Print(L["Sold junk for"] .. " " .. GetCoinText(totalPrice) .. ".")
					end
				end

			end

			-- Function to setup events
			local function SetupEvents()
				if LeaPlusLC["AutoSellJunk"] == "On" then
					SellJunkFrame:RegisterEvent("MERCHANT_SHOW");
					SellJunkFrame:RegisterEvent("MERCHANT_CLOSED");
				else
					SellJunkFrame:UnregisterEvent("MERCHANT_SHOW")
					SellJunkFrame:UnregisterEvent("MERCHANT_CLOSED")
				end
			end

			-- Setup events when option is clicked and on startup (if option is enabled)
			LeaPlusCB["AutoSellJunk"]:HookScript("OnClick", SetupEvents)
			if LeaPlusLC["AutoSellJunk"] == "On" then SetupEvents() end

			-- Event handler
			SellJunkFrame:SetScript("OnEvent", function(self, event, arg1, arg2)
				if event == "MERCHANT_SHOW" then
					-- Check for vendors that refuse to buy items
					SellJunkFrame:RegisterEvent("UI_ERROR_MESSAGE")
					-- Reset variable
					totalPrice = 0
					-- Do nothing if shift key is held down
					if IsShiftKeyDown() then return end
					-- Cancel existing ticker if present
					if SellJunkTicker then SellJunkTicker._cancelled = true; end
					-- Sell grey items using ticker (ends when all grey items are sold or iteration count reached)
					SellJunkTicker = LeaPlusNewTicker(0.2, SellJunkFunc, IterationCount)
					SellJunkFrame:RegisterEvent("ITEM_LOCKED")
				elseif event == "ITEM_LOCKED" then
					StartMsg:Show()
					SellJunkFrame:UnregisterEvent("ITEM_LOCKED")
				elseif event == "MERCHANT_CLOSED" then
					-- If merchant frame is closed, stop selling
					StopSelling()
				elseif event == "UI_ERROR_MESSAGE" then
					if arg2 and (arg2 == ERR_VENDOR_DOESNT_BUY or arg2 == ERR_TOO_MUCH_GOLD) then
						-- Vendor refuses to buy items or player at gold limit
						StopSelling()
					end
				end
			end)

		end

		----------------------------------------------------------------------
		--	Repair automatically (no reload required)
		----------------------------------------------------------------------

		do

			-- Repair when suitable merchant frame is shown
			local function RepairFunc()
				if IsShiftKeyDown() then return end
				if CanMerchantRepair() then -- If merchant is capable of repair
					-- Process repair
					local RepairCost, CanRepair = GetRepairAllCost()
					if CanRepair then -- If merchant is offering repair
						if GetMoney() >= RepairCost then
							RepairAllItems()
							-- Show cost summary
							if LeaPlusLC["AutoRepairShowSummary"] == "On" then
								LeaPlusLC:Print(L["Repaired for"] .. " " .. GetCoinText(RepairCost) .. ".")
							end
						end
					end
				end
			end

			-- Create event frame
			local RepairFrame = CreateFrame("FRAME")

			-- Function to setup event
			local function SetupEvent()
				if LeaPlusLC["AutoRepairGear"] == "On" then
					RepairFrame:RegisterEvent("MERCHANT_SHOW")
				else
					RepairFrame:UnregisterEvent("MERCHANT_SHOW")
				end
			end

			-- Setup event when option is clicked and on startup (if option is enabled)
			LeaPlusCB["AutoRepairGear"]:HookScript("OnClick", SetupEvent)
			if LeaPlusLC["AutoRepairGear"] == "On" then SetupEvent() end

			-- Event handler
			RepairFrame:SetScript("OnEvent", RepairFunc)

			-- Create configuration panel
			local RepairPanel = LeaPlusLC:CreatePanel("Repair automatically", "RepairPanel")

			LeaPlusLC:MakeTx(RepairPanel, "Settings", 16, -72)
			LeaPlusLC:MakeCB(RepairPanel, "AutoRepairShowSummary", "Show repair summary in chat", 16, -92, false, "If checked, a repair summary will be shown in chat when your gear is automatically repaired.")

			-- Help button hidden
			RepairPanel.h:Hide()

			-- Back button handler
			RepairPanel.b:SetScript("OnClick", function()
				RepairPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page1"]:Show();
				return
			end)

			-- Reset button handler
			RepairPanel.r:SetScript("OnClick", function()

				-- Reset checkboxes
				LeaPlusLC["AutoRepairShowSummary"] = "On"

				-- Refresh panel
				RepairPanel:Hide(); RepairPanel:Show()

			end)

			-- Show panal when options panel button is clicked
			LeaPlusCB["AutoRepairBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					LeaPlusLC["AutoRepairShowSummary"] = "On"
				else
					RepairPanel:Show()
					LeaPlusLC:HideFrames()
				end
			end)

		end

		----------------------------------------------------------------------
		-- Hide the combat log
		----------------------------------------------------------------------

		if LeaPlusLC["NoCombatLogTab"] == "On" and not LeaLockList["NoCombatLogTab"] then

			-- Function to setup the combat log tab
			local function SetupCombatLogTab()
				ChatFrame2Tab:EnableMouse(false)
				ChatFrame2Tab:SetText(" ") -- Needs to be something for chat settings to function
				ChatFrame2Tab:SetScale(0.01)
				ChatFrame2Tab:SetWidth(0.01)
				ChatFrame2Tab:SetHeight(0.01)
			end

			local frame = CreateFrame("FRAME")
			frame:SetScript("OnEvent", SetupCombatLogTab)

			-- Ensure combat log is docked
			if ChatFrame2.isDocked then
				-- Set combat log attributes when chat windows are updated
				frame:RegisterEvent("UPDATE_CHAT_WINDOWS")
				-- Set combat log tab placement when tabs are assigned by the client
				hooksecurefunc("FCF_SetTabPosition", function()
					ChatFrame2Tab:SetPoint("BOTTOMLEFT", ChatFrame1Tab, "BOTTOMRIGHT", 0, 0)
				end)
				SetupCombatLogTab()
			else
				-- If combat log is undocked, do nothing but show warning
				C_Timer.After(1, function()
					LeaPlusLC:Print("Combat log cannot be hidden while undocked.")
				end)
			end

		end

		----------------------------------------------------------------------
		--	Show player chain
		----------------------------------------------------------------------

		if LeaPlusLC["ShowPlayerChain"] == "On" and not LeaLockList["ShowPlayerChain"] then

			-- Fix for Burning Crusade Anniversary
			-- PlayerFrameTexture:ClearAllPoints()
			-- PlayerFrameTexture:SetPoint("CENTER", -18, -4)
			-- PlayerFrameTexture:SetSize(232, 100)

			PlayerFrameTexture:ClearAllPoints()
			PlayerFrameTexture:SetPoint("TOPLEFT", PlayerFrame, "TOPLEFT", -17, -4)
			PlayerFrameTexture:SetSize(231, 99)

			-- Ensure chain doesnt clip through pet portrait
			PetPortrait:GetParent():SetFrameLevel(4)

			-- Create configuration panel
			local ChainPanel = LeaPlusLC:CreatePanel("Show player chain", "ChainPanel")

			-- Add dropdown menu
			LeaPlusLC:CreateDropdown("PlayerChainMenu", "Chain style", 146, "TOPLEFT", ChainPanel, "TOPLEFT", 16, -92, false, {{L["RARE"], 1}, {L["ELITE"], 2}, {L["RARE ELITE"], 3}})

			-- Set chain style
			local function SetChainStyle()

				-- If EasyFrames is installed, get the EasyFrames light texture setting
				local EasyFramesLightTexture
				if EasyFramesDB and EasyFramesDB.profiles and EasyFramesDB.profiles.Default and EasyFramesDB.profiles.Default.general and EasyFramesDB.profiles.Default.general.lightTexture then
					EasyFramesLightTexture = true
				end

				-- Get dropdown menu value
				local chain = LeaPlusLC["PlayerChainMenu"] -- Numeric value

				-- Set chain style according to value
				if chain == 1 then -- Rare
					if C_AddOns.IsAddOnLoaded("EasyFrames") then
						PlayerFrameTexture:SetTexture("Interface\\AddOns\\Leatrix_Plus\\Leatrix_Plus.blp")
						if EasyFramesLightTexture then
							PlayerFrameTexture:SetTexCoord(0, 0.2265, 0.875, 0.9726)
						else
							PlayerFrameTexture:SetTexCoord(0, 0.2265, 0.75, 0.8476)
						end
					else
						PlayerFrameTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Rare.blp")
						PlayerFrameTexture:SetTexCoord(1, .09375, 0, .78125)
					end
				elseif chain == 2 then -- Elite
					if C_AddOns.IsAddOnLoaded("EasyFrames") then
						PlayerFrameTexture:SetTexture("Interface\\AddOns\\Leatrix_Plus\\Leatrix_Plus.blp")
						if EasyFramesLightTexture then
							PlayerFrameTexture:SetTexCoord(0.5, 0.7265, 0.875, 0.9726)
						else
							PlayerFrameTexture:SetTexCoord(0.5, 0.7265, 0.75, 0.8476)
						end
					else
						PlayerFrameTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Elite.blp")
						PlayerFrameTexture:SetTexCoord(1, .09375, 0, .78125)
					end
				elseif chain == 3 then -- Rare Elite
					if C_AddOns.IsAddOnLoaded("EasyFrames") then
						PlayerFrameTexture:SetTexture("Interface\\AddOns\\Leatrix_Plus\\Leatrix_Plus.blp")
						if EasyFramesLightTexture then
							PlayerFrameTexture:SetTexCoord(0.25, 0.4765, 0.875, 0.9726)
						else
							PlayerFrameTexture:SetTexCoord(0.25, 0.4765, 0.75, 0.8476)
						end
					else
						PlayerFrameTexture:SetTexture("Interface\\AddOns\\Leatrix_Plus\\Leatrix_Plus.blp")
						PlayerFrameTexture:SetTexCoord(0.75, 0.9765, 0.75, 0.8476)
					end
				end

			end

			-- Set style on startup
			SetChainStyle()

			-- If Easy Frames is installed, set chain style when Easy Frames has loaded
			EventUtil.ContinueOnAddOnLoaded("EasyFrames", function()
				local EasyFrames = LibStub("AceAddon-3.0"):GetAddon("EasyFrames", true)
				if EasyFrames then
					local General = EasyFrames:GetModule("General", true)
					if General then
						-- Set chain style when Easy Frames use a light texture checkbox is toggled
						local SetLightTextureFunc = General.SetLightTexture
						if SetLightTextureFunc then
							hooksecurefunc(General, "SetLightTexture", SetChainStyle)
						end
					end
				end
				-- Set chain style after Easy Frames has loaded
				SetChainStyle()
			end)

			-- Set style when a drop menu is selected (procs when the list is hidden)
			LeaPlusCB["PlayerChainMenu"]:RegisterCallback("OnMenuClose", SetChainStyle)

			-- Help button hidden
			ChainPanel.h:Hide()

			-- Back button handler
			ChainPanel.b:SetScript("OnClick", function()
				ChainPanel:Hide()
				LeaPlusLC["PageF"]:Show()
				LeaPlusLC["Page5"]:Show()
				return
			end)

			-- Reset button handler
			ChainPanel.r:SetScript("OnClick", function()
				LeaPlusLC["PlayerChainMenu"] = 2
				ChainPanel:Hide(); ChainPanel:Show()
				SetChainStyle()
			end)

			-- Show the panel when the configuration button is clicked
			LeaPlusCB["ModPlayerChain"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					LeaPlusLC["PlayerChainMenu"] = 3;
					SetChainStyle();
				else
					LeaPlusLC:HideFrames();
					ChainPanel:Show();
				end
			end)

		end

		----------------------------------------------------------------------
		-- Show raid frame toggle button
		----------------------------------------------------------------------

		if LeaPlusLC["ShowRaidToggle"] == "On" and not LeaLockList["ShowRaidToggle"] then

			-- Check to make sure raid toggle button exists
			if CompactRaidFrameManagerDisplayFrameHiddenModeToggle then

				-- Create a border for the button
				local cBackdrop = CreateFrame("Frame", nil, CompactRaidFrameManagerDisplayFrameHiddenModeToggle, "BackdropTemplate")
				cBackdrop:SetAllPoints()
				cBackdrop.backdropInfo = {edgeFile = "Interface/Tooltips/UI-Tooltip-Border", tile = false, tileSize = 0, edgeSize = 16, insets = {left = 0, right = 0, top = 0, bottom = 0}}
				cBackdrop:ApplyBackdrop()

				-- Move the button (function runs after PLAYER_ENTERING_WORLD and PARTY_LEADER_CHANGED)
				hooksecurefunc("CompactRaidFrameManager_UpdateOptionsFlowContainer", function()
					if CompactRaidFrameManager and CompactRaidFrameManagerDisplayFrameHiddenModeToggle then
						local void, void, void, void, y = CompactRaidFrameManager:GetPoint()
						CompactRaidFrameManagerDisplayFrameHiddenModeToggle:SetWidth(40)
						CompactRaidFrameManagerDisplayFrameHiddenModeToggle:ClearAllPoints()
						CompactRaidFrameManagerDisplayFrameHiddenModeToggle:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, y + 22)
						CompactRaidFrameManagerDisplayFrameHiddenModeToggle:SetParent(UIParent)
					end
				end)

			end

		end

		----------------------------------------------------------------------
		-- Hide hit indicators (portrait text)
		----------------------------------------------------------------------

		if LeaPlusLC["NoHitIndicators"] == "On" and not LeaLockList["NoHitIndicators"] then
			hooksecurefunc(PlayerHitIndicator, "Show", PlayerHitIndicator.Hide)
			hooksecurefunc(PetHitIndicator, "Show", PetHitIndicator.Hide)
		end

		----------------------------------------------------------------------
		-- Class colored frames
		----------------------------------------------------------------------

		if LeaPlusLC["ClassColFrames"] == "On" and not LeaLockList["ClassColFrames"] then

			-- Create background frame for player frame
			local PlayFN = CreateFrame("FRAME", nil, PlayerFrame)
			PlayFN:Hide()

			PlayFN:SetWidth(TargetFrameNameBackground:GetWidth())
			PlayFN:SetHeight(TargetFrameNameBackground:GetHeight())

			local void, void, void, x, y = TargetFrameNameBackground:GetPoint()
			PlayFN:SetPoint("TOPLEFT", PlayerFrame, "TOPLEFT", -x, y)

			PlayFN.t = PlayFN:CreateTexture(nil, "BORDER")
			PlayFN.t:SetAllPoints()
			PlayFN.t:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-LevelBackground")

			local c = LeaPlusLC["RaidColors"][select(2, UnitClass("player"))]
			if c then PlayFN.t:SetVertexColor(c.r, c.g, c.b) end

			-- Create color function for target and focus frames
			local function TargetFrameCol()
				if UnitIsPlayer("target") then
					local c = LeaPlusLC["RaidColors"][select(2, UnitClass("target"))]
					if c then TargetFrameNameBackground:SetVertexColor(c.r, c.g, c.b) end
				end
				if UnitIsPlayer("focus") then
					local c = LeaPlusLC["RaidColors"][select(2, UnitClass("focus"))]
					if c then FocusFrameNameBackground:SetVertexColor(c.r, c.g, c.b) end
				end
			end

			local ColTar = CreateFrame("FRAME")
			ColTar:SetScript("OnEvent", TargetFrameCol) -- Events are registered if target option is enabled

			-- Refresh color if focus frame size changes
			hooksecurefunc(FocusFrame, "SetSmallSize", function()
				if LeaPlusLC["ClassColTarget"] == "On" then
					TargetFrameCol()
				end
			end)

			-- Create configuration panel
			local ClassFrame = LeaPlusLC:CreatePanel("Class colored frames", "ClassFrame")

			LeaPlusLC:MakeTx(ClassFrame, "Settings", 16, -72)
			LeaPlusLC:MakeCB(ClassFrame, "ClassColPlayer", "Show player frame in class color", 16, -92, false, "If checked, the player frame background will be shown in class color.")
			LeaPlusLC:MakeCB(ClassFrame, "ClassColTarget", "Show target frame and focus frame in class color", 16, -112, false, "If checked, the target frame background and focus frame background will be shown in class color.")

			-- Help button hidden
			ClassFrame.h:Hide()

			-- Back button handler
			ClassFrame.b:SetScript("OnClick", function()
				ClassFrame:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page6"]:Show()
				return
			end)

			-- Function to set class colored frames
			local function SetClassColFrames()
				-- Player frame
				if LeaPlusLC["ClassColPlayer"] == "On" then
					PlayFN:Show()
				else
					PlayFN:Hide()
				end
				-- Target and focus frames
				if LeaPlusLC["ClassColTarget"] == "On" then
					ColTar:RegisterEvent("GROUP_ROSTER_UPDATE")
					ColTar:RegisterEvent("PLAYER_TARGET_CHANGED")
					ColTar:RegisterEvent("PLAYER_FOCUS_CHANGED")
					ColTar:RegisterEvent("UNIT_FACTION")
					TargetFrameCol()
				else
					ColTar:UnregisterAllEvents()
					TargetFrame.CheckFaction(TargetFrame) -- Reset target frame colors
					TargetFrame.CheckFaction(FocusFrame) -- Reset focus frame colors
				end
			end

			-- Run function when options are clicked and on startup
			LeaPlusCB["ClassColPlayer"]:HookScript("OnClick", SetClassColFrames)
			LeaPlusCB["ClassColTarget"]:HookScript("OnClick", SetClassColFrames)
			SetClassColFrames()

			-- Reset button handler
			ClassFrame.r:SetScript("OnClick", function()

				-- Reset checkboxes
				LeaPlusLC["ClassColPlayer"] = "On"
				LeaPlusLC["ClassColTarget"] = "On"

				-- Update colors and refresh configuration panel
				SetClassColFrames()
				ClassFrame:Hide(); ClassFrame:Show()

			end)

			-- Show configuration panal when options panel button is clicked
			LeaPlusCB["ClassColFramesBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					LeaPlusLC["ClassColPlayer"] = "On"
					LeaPlusLC["ClassColTarget"] = "On"
					SetClassColFrames()
				else
					ClassFrame:Show()
					LeaPlusLC:HideFrames()
				end
			end)

		end

		----------------------------------------------------------------------
		--	Quest text size
		----------------------------------------------------------------------

		if LeaPlusLC["QuestFontChange"] == "On" then

			-- Set gossip frame scroll box layout
			GossipFrame.GreetingPanel.ScrollBox:SetHeight(320)
			GossipFrame.GreetingPanel.ScrollBar:ClearAllPoints()
			GossipFrame.GreetingPanel.ScrollBar:SetPoint("TOPLEFT", GossipFrame.GreetingPanel.ScrollBox, "TOPRIGHT", 4, 9)
			GossipFrame.GreetingPanel.ScrollBar:SetPoint("BOTTOMLEFT", GossipFrame.GreetingPanel.ScrollBox, "BOTTOMRIGHT", 4, -14)

			-- Create configuration panel
			local QuestTextPanel = LeaPlusLC:CreatePanel("Resize quest text", "QuestTextPanel")

			LeaPlusLC:MakeTx(QuestTextPanel, "Text size", 16, -72)
			LeaPlusLC:MakeSL(QuestTextPanel, "LeaPlusQuestFontSize", "Drag to set the font size of quest text.", 10, 30, 1, 16, -92, "%.0f")

			-- Function to update the font size
			local function QuestSizeUpdate()
				local a, b, c = QuestFont:GetFont()
				QuestTitleFont:SetFont(a, LeaPlusLC["LeaPlusQuestFontSize"] + 3, c)
				QuestFont:SetFont(a, LeaPlusLC["LeaPlusQuestFontSize"] + 1, c)
				local d, e, f = QuestFontNormalSmall:GetFont()
				QuestFontNormalSmall:SetFont(d, LeaPlusLC["LeaPlusQuestFontSize"], f)
			end

			-- Set text size when slider changes and on startup
			LeaPlusCB["LeaPlusQuestFontSize"]:HookScript("OnValueChanged", QuestSizeUpdate)
			QuestSizeUpdate()

			-- Help button hidden
			QuestTextPanel.h:Hide()

			-- Back button handler
			QuestTextPanel.b:SetScript("OnClick", function()
				QuestTextPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page4"]:Show()
				return
			end)

			-- Reset button handler
			QuestTextPanel.r:SetScript("OnClick", function()

				-- Reset slider
				LeaPlusLC["LeaPlusQuestFontSize"] = 12
				QuestSizeUpdate()

				-- Refresh side panel
				QuestTextPanel:Hide(); QuestTextPanel:Show()

			end)

			-- Show configuration panal when options panel button is clicked
			LeaPlusCB["QuestTextBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					LeaPlusLC["LeaPlusQuestFontSize"] = 18
					QuestSizeUpdate()
				else
					QuestTextPanel:Show()
					LeaPlusLC:HideFrames()
				end
			end)

		end

		----------------------------------------------------------------------
		--	Resize mail text
		----------------------------------------------------------------------

		if LeaPlusLC["MailFontChange"] == "On" then

			-- Create configuration panel
			local MailTextPanel = LeaPlusLC:CreatePanel("Resize mail text", "MailTextPanel")

			LeaPlusLC:MakeTx(MailTextPanel, "Text size", 16, -72)
			LeaPlusLC:MakeSL(MailTextPanel, "LeaPlusMailFontSize", "Drag to set the font size of mail text.", 10, 30, 1, 16, -92, "%.0f")

			-- Function to set the text size
			local function MailSizeUpdate()
				local MailFont, void, flags = QuestFont:GetFont()
				OpenMailBodyText:SetFont("h1", MailFont, LeaPlusLC["LeaPlusMailFontSize"], flags)
				OpenMailBodyText:SetFont("h2", MailFont, LeaPlusLC["LeaPlusMailFontSize"], flags)
				OpenMailBodyText:SetFont("h3", MailFont, LeaPlusLC["LeaPlusMailFontSize"], flags)
				OpenMailBodyText:SetFont("p", MailFont, LeaPlusLC["LeaPlusMailFontSize"], flags)
				MailEditBox:GetEditBox():SetFont(MailFont, LeaPlusLC["LeaPlusMailFontSize"], flags)
			end

			-- Set text size after changing slider and on startup
			LeaPlusCB["LeaPlusMailFontSize"]:HookScript("OnValueChanged", MailSizeUpdate)
			MailSizeUpdate()

			-- Help button hidden
			MailTextPanel.h:Hide()

			-- Back button handler
			MailTextPanel.b:SetScript("OnClick", function()
				MailTextPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page4"]:Show()
				return
			end)

			-- Reset button handler
			MailTextPanel.r:SetScript("OnClick", function()

				-- Reset slider
				LeaPlusLC["LeaPlusMailFontSize"] = 15

				-- Refresh side panel
				MailTextPanel:Hide(); MailTextPanel:Show()

			end)

			-- Show configuration panal when options panel button is clicked
			LeaPlusCB["MailTextBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					LeaPlusLC["LeaPlusMailFontSize"] = 22
					MailSizeUpdate()
				else
					MailTextPanel:Show()
					LeaPlusLC:HideFrames()
				end
			end)

		end

		----------------------------------------------------------------------
		--	Resize book text
		----------------------------------------------------------------------

		if LeaPlusLC["BookFontChange"] == "On" then

			-- Create configuration panel
			local BookTextPanel = LeaPlusLC:CreatePanel("Resize book text", "BookTextPanel")

			LeaPlusLC:MakeTx(BookTextPanel, "Text size", 16, -72)
			LeaPlusLC:MakeSL(BookTextPanel, "LeaPlusBookFontSize", "Drag to set the font size of book text.", 10, 30, 1, 16, -92, "%.0f")

			-- Function to set the text size
			local function BookSizeUpdate()
				local BookFont, void, flags = QuestFont:GetFont()
				ItemTextFontNormal:SetFont(BookFont, LeaPlusLC["LeaPlusBookFontSize"], flags)
			end

			-- Set text size after changing slider and on startup
			LeaPlusCB["LeaPlusBookFontSize"]:HookScript("OnValueChanged", BookSizeUpdate)
			BookSizeUpdate()

			-- Help button hidden
			BookTextPanel.h:Hide()

			-- Back button handler
			BookTextPanel.b:SetScript("OnClick", function()
				BookTextPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page4"]:Show()
				return
			end)

			-- Reset button handler
			BookTextPanel.r:SetScript("OnClick", function()

				-- Reset slider
				LeaPlusLC["LeaPlusBookFontSize"] = 15

				-- Refresh side panel
				BookTextPanel:Hide(); BookTextPanel:Show()

			end)

			-- Show configuration panal when options panel button is clicked
			LeaPlusCB["BookTextBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					LeaPlusLC["LeaPlusBookFontSize"] = 22
					BookSizeUpdate()
				else
					BookTextPanel:Show()
					LeaPlusLC:HideFrames()
				end
			end)

		end

		----------------------------------------------------------------------
		--	Show durability status
		----------------------------------------------------------------------

		if LeaPlusLC["DurabilityStatus"] == "On" then

			-- Create durability button
			local cButton = CreateFrame("BUTTON", nil, PaperDollFrame)
			cButton:ClearAllPoints()
			cButton:SetPoint("BOTTOMRIGHT", CharacterFrame, "BOTTOMRIGHT", -40, 80)
			cButton:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
			cButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
			cButton:SetSize(32, 32)

			-- Create durability tables
			local Slots = {"HeadSlot", "ShoulderSlot", "ChestSlot", "WristSlot", "HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot", "MainHandSlot", "SecondaryHandSlot", "RangedSlot"}
			local SlotsFriendly = {INVTYPE_HEAD, INVTYPE_SHOULDER, INVTYPE_CHEST, INVTYPE_WRIST, INVTYPE_HAND, INVTYPE_WAIST, INVTYPE_LEGS, INVTYPE_FEET, INVTYPE_WEAPONMAINHAND, INVTYPE_WEAPONOFFHAND, INVTYPE_RANGED}

			-- Show durability status in tooltip or status line (tip or status)
			local function ShowDuraStats(where)

				local duravaltotal, duramaxtotal, durapercent = 0, 0, 0
				local valcol, id, duraval, duramax

				if where == "tip" then
					-- Creare layout
					GameTooltip:AddLine("|cffffffff")
					GameTooltip:AddLine("|cffffffff")
					GameTooltip:AddLine("|cffffffff")
					_G["GameTooltipTextLeft1"]:SetText("|cffffffff"); _G["GameTooltipTextRight1"]:SetText("|cffffffff")
					_G["GameTooltipTextLeft2"]:SetText("|cffffffff"); _G["GameTooltipTextRight2"]:SetText("|cffffffff")
					_G["GameTooltipTextLeft3"]:SetText("|cffffffff"); _G["GameTooltipTextRight3"]:SetText("|cffffffff")
				end

				local validItems = false

				-- Traverse equipment slots
				for k, slotName in ipairs(Slots) do
					if GetInventorySlotInfo(slotName) then
						id = GetInventorySlotInfo(slotName)
						duraval, duramax = GetInventoryItemDurability(id)
						if duraval ~= nil then

							-- At least one item has durability stat
							validItems = true

							-- Add to tooltip
							if where == "tip" then
								durapercent = tonumber(format("%.0f", duraval / duramax * 100))
								valcol = (durapercent >= 80 and "|cff00FF00") or (durapercent >= 60 and "|cff99FF00") or (durapercent >= 40 and "|cffFFFF00") or (durapercent >= 20 and "|cffFF9900") or (durapercent >= 0 and "|cffFF2000") or ("|cffFFFFFF")
								_G["GameTooltipTextLeft1"]:SetText(L["Durability"])
								_G["GameTooltipTextLeft2"]:SetText(_G["GameTooltipTextLeft2"]:GetText() .. SlotsFriendly[k] .. "|n")
								_G["GameTooltipTextRight2"]:SetText(_G["GameTooltipTextRight2"]:GetText() ..  valcol .. durapercent .. "%" .. "|r|n")
							end

							duravaltotal = duravaltotal + duraval
							duramaxtotal = duramaxtotal + duramax
						end
					end
				end
				if duravaltotal > 0 and duramaxtotal > 0 then
					durapercent = duravaltotal / duramaxtotal * 100
				else
					durapercent = 0
				end

				if where == "tip" then

					if validItems == true then
						-- Show overall durability in the tooltip
						if durapercent >= 80 then valcol = "|cff00FF00"	elseif durapercent >= 60 then valcol = "|cff99FF00"	elseif durapercent >= 40 then valcol = "|cffFFFF00"	elseif durapercent >= 20 then valcol = "|cffFF9900"	elseif durapercent >= 0 then valcol = "|cffFF2000" else return end
						_G["GameTooltipTextLeft3"]:SetText(L["Overall"] .. " " .. valcol)
						_G["GameTooltipTextRight3"]:SetText(valcol .. string.format("%.0f", durapercent) .. "%")

						-- Show lines of the tooltip
						GameTooltipTextLeft1:Show(); GameTooltipTextRight1:Show()
						GameTooltipTextLeft2:Show(); GameTooltipTextRight2:Show()
						GameTooltipTextLeft3:Show(); GameTooltipTextRight3:Show()
						GameTooltipTextRight2:SetJustifyH"RIGHT";
						GameTooltipTextRight3:SetJustifyH"RIGHT";
						GameTooltip:Show()
					else
						-- No items have durability stat
						GameTooltip:ClearLines()
						GameTooltip:AddLine("" .. L["Durability"],1.0, 0.85, 0.0)
						GameTooltip:AddLine("" .. L["No items with durability equipped."], 1, 1, 1)
						GameTooltip:Show()
					end

				elseif where == "status" then
					if validItems == true then
						-- Show simple status line instead
						if tonumber(durapercent) >= 0 then -- Ensure character has some durability items equipped
							LeaPlusLC:Print(L["You have"] .. " " .. string.format("%.0f", durapercent) .. "%" .. " " .. L["durability"] .. ".")
						end
					end

				end
			end

			-- Hover over the durability button to show the durability tooltip
			cButton:SetScript("OnEnter", function()
				GameTooltip:SetOwner(cButton, "ANCHOR_RIGHT");
				GameTooltip:SetMinimumWidth(0) -- Needed due to MoP mage reset specialisation and choose frost
				ShowDuraStats("tip");
			end)
			cButton:SetScript("OnLeave", GameTooltip_Hide)

			-- Create frame to watch events
			local DeathDura = CreateFrame("FRAME")
			DeathDura:RegisterEvent("PLAYER_DEAD")
			DeathDura:SetScript("OnEvent", function(self, event)
				ShowDuraStats("status")
				DeathDura:UnregisterEvent("PLAYER_DEAD")
				C_Timer.After(2, function()
					DeathDura:RegisterEvent("PLAYER_DEAD")
				end)
			end)

			hooksecurefunc("AcceptResurrect", function()
				-- Player has ressed without releasing
				ShowDuraStats("status")
			end)

		end

		----------------------------------------------------------------------
		--	Hide zone text
		----------------------------------------------------------------------

		if LeaPlusLC["HideZoneText"] == "On" then
			ZoneTextFrame:SetScript("OnShow", ZoneTextFrame.Hide);
			SubZoneTextFrame:SetScript("OnShow", SubZoneTextFrame.Hide);
		end

		----------------------------------------------------------------------
		--	Disable sticky chat
		----------------------------------------------------------------------

		if LeaPlusLC["NoStickyChat"] == "On" and not LeaLockList["NoStickyChat"] then
			-- These taint if set to anything other than nil
			ChatTypeInfo.WHISPER.sticky = nil
			ChatTypeInfo.BN_WHISPER.sticky = nil
			ChatTypeInfo.CHANNEL.sticky = nil
		end

		----------------------------------------------------------------------
		--	Hide stance bar
		----------------------------------------------------------------------

		if LeaPlusLC["NoClassBar"] == "On" and not LeaLockList["NoClassBar"] then
			local stancebar = CreateFrame("FRAME", nil, UIParent)
			stancebar:Hide()
			StanceBar:UnregisterAllEvents()
			StanceBar:SetParent(stancebar)
		end

		----------------------------------------------------------------------
		--	Hide gryphons
		----------------------------------------------------------------------

		if LeaPlusLC["NoGryphons"] == "On" and not LeaLockList["NoGryphons"] then

			-- Different textures depending on hiding bar scrolling in Edit Mode settings
			MainMenuBarLeftEndCap:Hide()
			MainMenuBarRightEndCap:Hide()
			MainActionBar.EndCaps.LeftEndCap:Hide()
			MainActionBar.EndCaps.RightEndCap:Hide()

		end

		----------------------------------------------------------------------
		--	Disable chat fade
		----------------------------------------------------------------------

		if LeaPlusLC["NoChatFade"] == "On" and not LeaLockList["NoChatFade"] then
			-- Process normal and existing chat frames
			for i = 1, 50 do
				if _G["ChatFrame" .. i] then
					_G["ChatFrame" .. i]:SetFading(false)
				end
			end
			-- Process temporary frames
			hooksecurefunc("FCF_OpenTemporaryWindow", function()
				local cf = FCF_GetCurrentChatFrame():GetName() or nil
				if cf then
					_G[cf]:SetFading(false)
				end
			end)
		end

		----------------------------------------------------------------------
		--	Use easy chat frame resizing
		----------------------------------------------------------------------

		if LeaPlusLC["UseEasyChatResizing"] == "On" and not LeaLockList["UseEasyChatResizing"] then
			ChatFrame1Tab:HookScript("OnMouseDown", function(self,arg1)
				if arg1 == "LeftButton" then
					if select(8, GetChatWindowInfo(1)) then
						ChatFrame1:StartSizing("TOP")
					end
				end
			end)
			ChatFrame1Tab:SetScript("OnMouseUp", function(self,arg1)
				if arg1 == "LeftButton" then
					ChatFrame1:StopMovingOrSizing()
					FCF_SavePositionAndDimensions(ChatFrame1)
				end
			end)
		end

		----------------------------------------------------------------------
		--	Increase chat history
		----------------------------------------------------------------------

		if LeaPlusLC["MaxChatHstory"] == "On" and not LeaLockList["MaxChatHstory"] then
			-- Process normal and existing chat frames
			for i = 1, 50 do
				if _G["ChatFrame" .. i] then
					_G["ChatFrame" .. i]:SetMaxLines(4096)
				end
			end
			-- Process temporary chat frames
			hooksecurefunc("FCF_OpenTemporaryWindow", function()
				local cf = FCF_GetCurrentChatFrame():GetName() or nil
				if cf then
					_G[cf]:SetMaxLines(4096)
				end
			end)
		end

		----------------------------------------------------------------------
		--	Hide error messages
		----------------------------------------------------------------------

		if LeaPlusLC["HideErrorMessages"] == "On" then

			--	Error message events
			local OrigErrHandler = UIErrorsFrame:GetScript('OnEvent')
			UIErrorsFrame:SetScript('OnEvent', function (self, event, id, err, ...)
				if event == "UI_ERROR_MESSAGE" then
					-- Hide error messages
					if LeaPlusLC["ShowErrorsFlag"] == 1 then
						if 	err == ERR_INV_FULL or
							err == ERR_QUEST_LOG_FULL or
							err == ERR_RAID_GROUP_ONLY or
							err == ERR_PET_SPELL_DEAD or
							err == ERR_PLAYER_DEAD or
							err == ERR_FEIGN_DEATH_RESISTED or
							err == SPELL_FAILED_TARGET_NO_POCKETS or
							err == ERR_ALREADY_PICKPOCKETED then
							return OrigErrHandler(self, event, id, err, ...)
						end
					else
						return OrigErrHandler(self, event, id, err, ...)
					end
				elseif event == 'UI_INFO_MESSAGE'  then
					-- Show information messages
					return OrigErrHandler(self, event, id, err, ...)
				end
			end)

		end

		----------------------------------------------------------------------
		-- Easy item destroy
		----------------------------------------------------------------------

		if LeaPlusLC["EasyItemDestroy"] == "On" then

			-- Get the type "DELETE" into the field to confirm text
			local TypeDeleteLine = gsub(DELETE_GOOD_ITEM, "[\r\n]", "@")
			local void, TypeDeleteLine = strsplit("@", TypeDeleteLine, 2)

			-- Add hyperlinks to regular item destroy
			RunScript('StaticPopupDialogs["DELETE_GOOD_ITEM"].OnHyperlinkEnter = function(self, link, text, region, boundsLeft, boundsBottom, boundsWidth, boundsHeight) GameTooltip:SetOwner(self, "ANCHOR_PRESERVE") GameTooltip:ClearAllPoints() local cursorClearance = 30 GameTooltip:SetPoint("TOPLEFT", region, "BOTTOMLEFT", boundsLeft, boundsBottom - cursorClearance) GameTooltip:SetHyperlink(link) end')
			RunScript('StaticPopupDialogs["DELETE_GOOD_ITEM"].OnHyperlinkLeave = function(self) GameTooltip:Hide() end')
			RunScript('StaticPopupDialogs["DELETE_ITEM"].OnHyperlinkEnter = StaticPopupDialogs["DELETE_GOOD_ITEM"].OnHyperlinkEnter')
			RunScript('StaticPopupDialogs["DELETE_ITEM"].OnHyperlinkLeave = StaticPopupDialogs["DELETE_GOOD_ITEM"].OnHyperlinkLeave')
			RunScript('StaticPopupDialogs["DELETE_QUEST_ITEM"].OnHyperlinkEnter = StaticPopupDialogs["DELETE_GOOD_ITEM"].OnHyperlinkEnter')
			RunScript('StaticPopupDialogs["DELETE_QUEST_ITEM"].OnHyperlinkLeave = StaticPopupDialogs["DELETE_GOOD_ITEM"].OnHyperlinkLeave')
			RunScript('StaticPopupDialogs["DELETE_GOOD_QUEST_ITEM"].OnHyperlinkEnter = StaticPopupDialogs["DELETE_GOOD_ITEM"].OnHyperlinkEnter')
			RunScript('StaticPopupDialogs["DELETE_GOOD_QUEST_ITEM"].OnHyperlinkLeave = StaticPopupDialogs["DELETE_GOOD_ITEM"].OnHyperlinkLeave')

			-- Hide editbox and set item link
			local easyDelFrame = CreateFrame("FRAME")
			easyDelFrame:RegisterEvent("DELETE_ITEM_CONFIRM")
			easyDelFrame:SetScript("OnEvent", function()
				if StaticPopup1EditBox:IsShown() then
					-- Item requires player to type delete so hide editbox and show link
					StaticPopup1EditBox:Hide()
					StaticPopup1Button1:Enable()
					local link = select(3, GetCursorInfo())
					if link then
						StaticPopup1Text:SetText(gsub(StaticPopup1Text:GetText(), gsub(TypeDeleteLine, "@", ""), "") .. link)
					end
				else
					-- Item does not require player to type delete so just show item link
					StaticPopup1:SetHeight(StaticPopup1:GetHeight() + 40)
					StaticPopup1EditBox:Hide()
					StaticPopup1Button1:Enable()
					local link = select(3, GetCursorInfo())
					if link then
						StaticPopup1Text:SetText(gsub(StaticPopup1Text:GetText(), gsub(TypeDeleteLine, "@", ""), "") .. "|n|n" .. link .. "|n|n")
					end
				end
			end)

		end

		----------------------------------------------------------------------
		-- Unclamp chat frame
		----------------------------------------------------------------------

		if LeaPlusLC["UnclampChat"] == "On" and not LeaLockList["UnclampChat"] then

			-- Process normal and existing chat frames on startup
			for i = 1, 50 do
				if _G["ChatFrame" .. i] then
					_G["ChatFrame" .. i]:SetClampedToScreen(false)
					_G["ChatFrame" .. i]:SetClampRectInsets(0, 0, 0, 0)
				end
			end

			-- Process new chat frames and combat log
			hooksecurefunc("FloatingChatFrame_UpdateBackgroundAnchors", function(self)
				self:SetClampRectInsets(0, 0, 0, 0)
			end)

			-- Process temporary chat frames
			hooksecurefunc("FCF_OpenTemporaryWindow", function()
				local cf = FCF_GetCurrentChatFrame():GetName() or nil
				if cf then
					_G[cf]:SetClampRectInsets(0, 0, 0, 0)
				end
			end)

		end

		----------------------------------------------------------------------
		-- Enhance flight map
		----------------------------------------------------------------------

		if LeaPlusLC["EnhanceFlightMap"] == "On" then

			-- Hide flight map textures
			local regions = {TaxiFrame:GetRegions()}
			regions[2]:Hide()
			regions[3]:Hide()
			regions[4]:Hide()
			regions[5]:Hide()
			TaxiPortrait:Hide()
			TaxiMerchant:Hide()

			-- Create flight map border
			local border = TaxiFrame:CreateTexture(nil, "BACKGROUND")
			border:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background-Dark")
			border:SetPoint("TOPLEFT", 18, -73)
			border:SetPoint("BOTTOMRIGHT", -45, 83)
			border:SetVertexColor(0, 0, 0, 1)

			-- Set flight map properties
			TaxiFrame:SetFrameStrata("FULLSCREEN_DIALOG")
			TaxiFrame:SetHitRectInsets(18, 45, 73, 83)
			TaxiFrame:SetClampedToScreen(true)
			TaxiFrame:SetClampRectInsets(200, -200, -300, 300)

			-- Position flight map when shown
			hooksecurefunc(TaxiFrame, "SetPoint", function(self, ...)
				local a, void, r, x, y = TaxiFrame:GetPoint()
				x = tonumber(string.format("%.2f", x))
				y = tonumber(string.format("%.2f", y))
				local xb = tonumber(string.format("%.2f", LeaPlusLC["FlightMapX"]))
				local yb = tonumber(string.format("%.2f", LeaPlusLC["FlightMapY"]))
				if a ~= LeaPlusLC["FlightMapA"] or r ~= LeaPlusLC["FlightMapR"] or x ~= xb or y ~= yb then
					TaxiFrame:ClearAllPoints()
					TaxiFrame:SetPoint(LeaPlusLC["FlightMapA"], UIParent, LeaPlusLC["FlightMapR"], LeaPlusLC["FlightMapX"], LeaPlusLC["FlightMapY"])
				end
			end)

			-- Set flight point buttons size
			TaxiFrame:HookScript("OnShow", function()
				for i = 1, NUM_TAXI_BUTTONS do
					local button = _G["TaxiButton"..i]
					if button and button:IsVisible() then
						_G["TaxiButton" .. i]:SetSize(LeaPlusLC["LeaPlusTaxiIconSize"], LeaPlusLC["LeaPlusTaxiIconSize"])
						if button:GetHighlightTexture() then button:GetHighlightTexture():SetSize(LeaPlusLC["LeaPlusTaxiIconSize"] * 2, LeaPlusLC["LeaPlusTaxiIconSize"] * 2) end
						if button:GetPushedTexture() then button:GetPushedTexture():SetSize(LeaPlusLC["LeaPlusTaxiIconSize"] * 2, LeaPlusLC["LeaPlusTaxiIconSize"] * 2) end
				   end
				end
			end)

			-- Move close button
			TaxiCloseButton:SetIgnoreParentScale(true)
			TaxiCloseButton:ClearAllPoints()
			TaxiCloseButton:SetPoint("TOPRIGHT", TaxiRouteMap, "TOPRIGHT", 0, 0)

			--UIPanelWindows["TaxiFrame"].width = 0

			-- Create configuration panel
			local TaxiPanel = LeaPlusLC:CreatePanel("Enhance flight map", "TaxiPanel")

			LeaPlusLC:MakeTx(TaxiPanel, "Map scale", 356, -72)
			LeaPlusLC:MakeSL(TaxiPanel, "LeaPlusTaxiMapScale", "Drag to set the scale of the flight map.", 1, 3, 0.05, 356, -92, "%.0f")

			LeaPlusLC:MakeTx(TaxiPanel, "Icon size", 356, -132)
			LeaPlusLC:MakeSL(TaxiPanel, "LeaPlusTaxiIconSize", "Drag to set the size of the icons.", 5, 30, 1, 356, -152, "%.0f")

			LeaPlusLC:MakeTx(TaxiPanel, "Position", 16, -72)
			TaxiPanel.txt = LeaPlusLC:MakeWD(TaxiPanel, "Hold ALT and drag the flight map to move it.", 16, -92, 500)
			TaxiPanel.txt:SetWordWrap(true)
			TaxiPanel.txt:SetWidth(300)

			-- Function to set flight map scale
			local function SetFlightMapScale()
				TaxiFrame:SetScale(LeaPlusLC["LeaPlusTaxiMapScale"])
				LeaPlusCB["LeaPlusTaxiMapScale"].f:SetFormattedText("%.0f%%", LeaPlusLC["LeaPlusTaxiMapScale"] * 100)
			end

			-- Function to set icon size (used for reset and when slider changes)
			local function SetFlightMapIconSize()
				for i = 1, NUM_TAXI_BUTTONS do
					local button = _G["TaxiButton"..i]
					if button and button:IsVisible() then
						_G["TaxiButton" .. i]:SetSize(LeaPlusLC["LeaPlusTaxiIconSize"], LeaPlusLC["LeaPlusTaxiIconSize"])
						if button:GetHighlightTexture() then button:GetHighlightTexture():SetSize(LeaPlusLC["LeaPlusTaxiIconSize"] * 2, LeaPlusLC["LeaPlusTaxiIconSize"] * 2) end
						if button:GetPushedTexture() then button:GetPushedTexture():SetSize(LeaPlusLC["LeaPlusTaxiIconSize"] * 2, LeaPlusLC["LeaPlusTaxiIconSize"] * 2) end
				   end
				end
				LeaPlusCB["LeaPlusTaxiIconSize"].f:SetFormattedText("%.0f%%", LeaPlusLC["LeaPlusTaxiIconSize"] * 10)
			end

			-- Set flight map scale when slider changes and on startup
			LeaPlusCB["LeaPlusTaxiMapScale"]:HookScript("OnValueChanged", SetFlightMapScale)
			LeaPlusCB["LeaPlusTaxiIconSize"]:HookScript("OnValueChanged", SetFlightMapIconSize)
			SetFlightMapScale()

			-- Help button tooltip
			TaxiPanel.h.tiptext = L["This panel will close automatically if you enter combat."]

			-- Back button handler
			TaxiPanel.b:SetScript("OnClick", function()
				TaxiPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page5"]:Show()
				return
			end)

			-- Reset button handler
			TaxiPanel.r:SetScript("OnClick", function()

				-- Reset slider
				LeaPlusLC["LeaPlusTaxiMapScale"] = 1.9
				LeaPlusLC["LeaPlusTaxiIconSize"] = 10
				SetFlightMapScale()
				LeaPlusLC["FlightMapA"] = "TOPLEFT"
				LeaPlusLC["FlightMapR"] = "TOPLEFT"
				LeaPlusLC["FlightMapX"] = 0
				LeaPlusLC["FlightMapY"] = 61
				TaxiFrame:ClearAllPoints()
				TaxiFrame:SetPoint(LeaPlusLC["FlightMapA"], UIParent, LeaPlusLC["FlightMapR"], LeaPlusLC["FlightMapX"], LeaPlusLC["FlightMapY"])

				-- Refresh side panel
				TaxiPanel:Hide(); TaxiPanel:Show()

			end)

			-- Show configuration panal when options panel button is clicked
			LeaPlusCB["EnhanceFlightMapBtn"]:SetScript("OnClick", function()
				if LeaPlusLC:PlayerInCombat() then
					return
				else
					if IsShiftKeyDown() and IsControlKeyDown() then
						-- Preset profile
						LeaPlusLC["LeaPlusTaxiMapScale"] = 1.9
						LeaPlusLC["LeaPlusTaxiIconSize"] = 10
						LeaPlusLC["FlightMapA"] = "TOPLEFT"
						LeaPlusLC["FlightMapR"] = "TOPLEFT"
						LeaPlusLC["FlightMapX"] = 0
						LeaPlusLC["FlightMapY"] = 61
						SetFlightMapScale()
						SetFlightMapIconSize()
					else
						TaxiPanel:Show()
						LeaPlusLC:HideFrames()
					end
				end
			end)

			-- Hide the configuration panel if combat starts
			TaxiPanel:SetScript("OnUpdate", function()
				if UnitAffectingCombat("player") then
					TaxiPanel:Hide()
				end
			end)

			-- Move the flight map
			TaxiFrame:SetMovable(true)
			TaxiFrame:RegisterForDrag("LeftButton")
			TaxiFrame:SetScript("OnDragStart", function()
				if IsAltKeyDown() then
					TaxiFrame:StartMoving()
				end
			end)
			TaxiFrame:SetScript("OnDragStop", function()
				TaxiFrame:StopMovingOrSizing()
				TaxiFrame:SetUserPlaced(false)
				LeaPlusLC["FlightMapA"], void, LeaPlusLC["FlightMapR"], LeaPlusLC["FlightMapX"], LeaPlusLC["FlightMapY"] = TaxiFrame:GetPoint()
			end)

			-- ElvUI fixes
			if LeaPlusLC.ElvUI then
				if TaxiFrame.backdrop then
					border:ClearAllPoints()
					border:SetPoint("TOPLEFT", 22, -70)
					border:SetPoint("BOTTOMRIGHT", -44, 88)
					TaxiFrame:SetHitRectInsets(22, 44, 70, 88)
					TaxiFrame.backdrop:SetAlpha(0)
				end
			end

		end

		----------------------------------------------------------------------
		-- Keep audio synced
		----------------------------------------------------------------------

		if LeaPlusLC["KeepAudioSynced"] == "On" then

			SetCVar("Sound_OutputDriverIndex", "0")
			local event = CreateFrame("FRAME")
			event:RegisterEvent("VOICE_CHAT_OUTPUT_DEVICES_UPDATED")
			event:SetScript("OnEvent", function()
				if not CinematicFrame:IsShown() and not MovieFrame:IsShown() then -- Dont restart sound system during cinematic
					SetCVar("Sound_OutputDriverIndex", "0")
					Sound_GameSystem_RestartSoundSystem()
				end
			end)

		end

		----------------------------------------------------------------------
		-- Mute custom sounds (no reload required)
		----------------------------------------------------------------------

		do

			-- Create configuration panel
			local MuteCustomPanel = LeaPlusLC:CreatePanel("Mute custom sounds", "MuteCustomPanel")

			local titleTX = LeaPlusLC:MakeTx(MuteCustomPanel, "Editor", 16, -72)
			titleTX:SetWidth(534)
			titleTX:SetWordWrap(false)
			titleTX:SetJustifyH("LEFT")

			-- Show help button for title
			LeaPlusLC:CreateHelpButton("MuteGameSoundsCustomHelpButton", MuteCustomPanel, titleTX, "Enter sound file IDs separated by comma then click the Mute button.|n|nIf you wish, you can enter a brief note for each file ID but do not include numbers in your notes.|n|nFor example, you can enter 'DevAura 569679, RetAura 568744' to mute the Devotion Aura and Retribution Aura spells.|n|nUse Leatrix Sounds to find, test and play sound file IDs.")

			-- Add large editbox
			local eb = CreateFrame("Frame", nil, MuteCustomPanel, "BackdropTemplate")
			eb:SetSize(548, LeaPlusLC.MainPanelHeight - 180)
			eb:SetPoint("TOPLEFT", 10, -92)
			eb:SetBackdrop({
				bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
				edgeFile = "Interface\\PVPFrame\\UI-Character-PVP-Highlight",
				edgeSize = 16,
				insets = { left = 8, right = 6, top = 8, bottom = 8 },
			})
			eb:SetBackdropBorderColor(1.0, 0.85, 0.0, 0.5)

			eb.scroll = CreateFrame("ScrollFrame", nil, eb, "LeaPlusMuteCustomSoundsScrollFrameTemplate")
			eb.scroll:SetPoint("TOPLEFT", eb, 12, -10)
			eb.scroll:SetPoint("BOTTOMRIGHT", eb, -30, 10)
			eb.scroll:SetPanExtent(16)

			-- Create character count
			eb.scroll.CharCount = eb.scroll:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
			eb.scroll.CharCount:Hide()

			eb.Text = eb.scroll.EditBox
			eb.Text:SetWidth(494)
			eb.Text:SetHeight(230)
			eb.Text:SetPoint("TOPLEFT", eb.scroll)
			eb.Text:SetPoint("BOTTOMRIGHT", eb.scroll, -12, 0)
			eb.Text:SetMaxLetters(2000)
			eb.Text:SetFontObject(GameFontNormalLarge)
			eb.Text:SetAutoFocus(false)
			eb.scroll:SetScrollChild(eb.Text)

			-- Set focus on the editbox text when clicking the editbox
			eb:SetScript("OnMouseDown", function()
				eb.Text:SetFocus()
				eb.Text:SetCursorPosition(eb.Text:GetMaxLetters())
			end)

			-- Function to save the custom sound list
			local function SaveString(self, userInput)
				local keytext = eb.Text:GetText()
				if keytext and keytext ~= "" then
					LeaPlusLC["MuteCustomList"] = strtrim(eb.Text:GetText())
				else
					LeaPlusLC["MuteCustomList"] = ""
				end
			end

			-- Save the custom sound list when it changes and at startup
			eb.Text:SetScript("OnTextChanged", SaveString)
			eb.Text:SetText(LeaPlusLC["MuteCustomList"])
			SaveString()

			-- Help button hidden
			MuteCustomPanel.h:Hide()

			-- Back button handler
			MuteCustomPanel.b:SetScript("OnClick", function()
				MuteCustomPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page7"]:Show()
				return
			end)

			-- Reset button hidden
			MuteCustomPanel.r:Hide()

			-- Show configuration panal when options panel button is clicked
			LeaPlusCB["MuteCustomSoundsBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					LeaPlusLC["MuteCustomList"] = "Devotion Aura 569679, Retribution Aura 568744"
					eb.Text:SetText(LeaPlusLC["MuteCustomList"])
				else
					MuteCustomPanel:Show()
					LeaPlusLC:HideFrames()
				end
			end)

			-- Function to mute custom sound list
			local function MuteCustomListFunc(unmute, userInput)
				-- local mutedebug = true -- Debug
				local counter = 0
				local muteString = LeaPlusLC["MuteCustomList"]
				if muteString and muteString ~= "" then
					muteString = muteString:gsub("%s", ",")
					muteString = muteString:gsub("[\n]", ",")
					muteString = muteString:gsub("[^,%d]", "")
					if mutedebug then print(muteString) end
					local tList = {strsplit(",", muteString)}
					if mutedebug then ChatFrame1:Clear() end
					for i = 1, #tList do
						if tList[i] then
							tList[i] = tonumber(tList[i])
							if tList[i] and tList[i] < 20000000 then
								if mutedebug then print(tList[i]) end
								if unmute then
									UnmuteSoundFile(tList[i])
								else
									MuteSoundFile(tList[i])
								end
								counter = counter + 1
							end
						end
					end
					if userInput then
						if unmute then
							if counter == 1 then
								LeaPlusLC:Print(L["Unmuted"] .. " " .. counter .. " " .. L["sound"] .. ".")
							else
								LeaPlusLC:Print(L["Unmuted"] .. " " .. counter .. " " .. L["sounds"] .. ".")
							end
						else
							if counter == 1 then
								LeaPlusLC:Print(L["Muted"] .. " " .. counter .. " " .. L["sound"] .. ".")
							else
								LeaPlusLC:Print(L["Muted"] .. " " .. counter .. " " .. L["sounds"] .. ".")
							end
						end
					end
				end
			end

			-- Mute custom list on startup if option is enabled
			if LeaPlusLC["MuteCustomSounds"] == "On" then
				MuteCustomListFunc()
			end

			-- Mute or unmute when option is clicked
			LeaPlusCB["MuteCustomSounds"]:HookScript("OnClick", function()
				if LeaPlusLC["MuteCustomSounds"] == "On" then
					MuteCustomListFunc(false, false)
				else
					MuteCustomListFunc(true, false)
				end
			end)

			-- Add mute button
			local MuteCustomNowButton = LeaPlusLC:CreateButton("MuteCustomNowButton", MuteCustomPanel, "Mute", "BOTTOMLEFT", 16, 53, 0, 25, true, "Click to mute sounds in the list.")
			LeaPlusCB["MuteCustomNowButton"]:SetScript("OnClick", function() MuteCustomListFunc(false, true) end)

			-- Add unmute button
			local UnmuteCustomNowButton = LeaPlusLC:CreateButton("UnmuteCustomNowButton", MuteCustomPanel, "Unmute", "BOTTOMLEFT", 16, 53, 0, 25, true, "Click to unmute sounds in the list.")
			LeaPlusCB["UnmuteCustomNowButton"]:ClearAllPoints()
			LeaPlusCB["UnmuteCustomNowButton"]:SetPoint("LEFT", MuteCustomNowButton, "RIGHT", 10, 0)
			LeaPlusCB["UnmuteCustomNowButton"]:SetScript("OnClick", function() MuteCustomListFunc(true, true) end)

			-- Add play sound file editbox
			local willPlay, musicHandle
			local MuteCustomSoundsStopButton = LeaPlusLC:CreateButton("MuteCustomSoundsStopButton", MuteCustomPanel, "Stop", "TOPRIGHT", -18, -66, 0, 25, true, "")
			MuteCustomSoundsStopButton:SetScript("OnClick", function()
				if musicHandle then StopSound(musicHandle) end
			end)

			local MuteCustomSoundsPlayButton = LeaPlusLC:CreateButton("MuteCustomSoundsPlayButton", MuteCustomPanel, "Play", "TOPRIGHT", -18, -66, 0, 25, true, "")
			MuteCustomSoundsPlayButton:ClearAllPoints()
			MuteCustomSoundsPlayButton:SetPoint("RIGHT", MuteCustomSoundsStopButton, "LEFT", -10, 0)

			local MuteCustomSoundsSoundBox = LeaPlusLC:CreateEditBox("MuteCustomSoundsSoundBox", eb, 80, 8, "TOPRIGHT", -10, 20, "PlaySoundBox", "PlaySoundBox")
			MuteCustomSoundsSoundBox:SetNumeric(true)
			MuteCustomSoundsSoundBox:ClearAllPoints()
			MuteCustomSoundsSoundBox:SetPoint("RIGHT", MuteCustomSoundsPlayButton, "LEFT", -10, 0)
			MuteCustomSoundsPlayButton:SetScript("OnClick", function()
				MuteCustomSoundsSoundBox:GetText()
				if musicHandle then StopSound(musicHandle) end
				willPlay, musicHandle = PlaySoundFile(MuteCustomSoundsSoundBox:GetText(), "Master")
			end)

			-- Add mousewheel support to the editbox
			MuteCustomSoundsSoundBox:SetScript("OnMouseWheel", function(self, delta)
				local endSound = tonumber(MuteCustomSoundsSoundBox:GetText())
				if endSound then
					if delta == 1 then endSound = endSound + 1 else endSound = endSound - 1 end
					if endSound < 1 then endSound = 1 elseif endSound >= 10000000 then endSound = 10000000 end
					MuteCustomSoundsSoundBox:SetText(endSound)
					MuteCustomSoundsPlayButton:Click()
				end
			end)

			local titlePlayer = LeaPlusLC:MakeTx(MuteCustomPanel, "Player", 16, -72)
			titlePlayer:ClearAllPoints()
			titlePlayer:SetPoint("TOPLEFT", MuteCustomSoundsSoundBox, "TOPLEFT", -4, 16)
			LeaPlusLC:CreateHelpButton("MuteGameSoundsCustomPlayHelpButton", MuteCustomPanel, titlePlayer, "If you want to listen to a sound file, enter the sound file ID into the editbox and click the play button.|n|nYou can scroll the mousewheel over the editbox to play neighbouring sound files.")
		end

		----------------------------------------------------------------------
		-- Block shared quests (no reload needed)
		----------------------------------------------------------------------

		do

			local eFrame = CreateFrame("FRAME")
			eFrame:SetScript("OnEvent", LeaPlusLC.CheckIfQuestIsSharedAndShouldBeDeclined)

			-- Function to set event
			local function SetSharedQuestsFunc()
				if LeaPlusLC["NoSharedQuests"] == "On" then
					eFrame:RegisterEvent("QUEST_DETAIL")
				else
					eFrame:UnregisterEvent("QUEST_DETAIL")
				end
			end

			-- Set event when option is clicked and on startup
			LeaPlusCB["NoSharedQuests"]:HookScript("OnClick", SetSharedQuestsFunc)
			SetSharedQuestsFunc()

		end

		----------------------------------------------------------------------
		-- Restore chat messages
		----------------------------------------------------------------------

		if LeaPlusLC["RestoreChatMessages"] == "On" and not LeaLockList["RestoreChatMessages"] then

			local historyFrame = CreateFrame("FRAME")
			historyFrame:RegisterEvent("PLAYER_LOGIN")
			historyFrame:RegisterEvent("PLAYER_LOGOUT")

			local FCF_IsChatWindowIndexActive = FCF_IsChatWindowIndexActive
			local GetMessageInfo = GetMessageInfo
			local GetNumMessages = GetNumMessages

			-- Use function from Dragonflight
			local function FCF_IsChatWindowIndexActive(chatWindowIndex)
				local shown = select(7, FCF_GetChatWindowInfo(chatWindowIndex))
				if shown then
					return true
				end
				local chatFrame = _G["ChatFrame" .. chatWindowIndex]
				return (chatFrame and chatFrame.isDocked)
			end

			-- Save chat messages on logout
			historyFrame:SetScript("OnEvent", function(self, event)
				if event == "PLAYER_LOGOUT" then
					local name, realm = UnitFullName("player")
					if not realm then realm = GetNormalizedRealmName() end
					if name and realm then
						LeaPlusDB["ChatHistoryName"] = name .. "-" .. realm
						LeaPlusDB["ChatHistoryTime"] = GetServerTime()
						for i = 1, 50 do
							if i ~= 2 and _G["ChatFrame" .. i] then
								if FCF_IsChatWindowIndexActive(i) then
									LeaPlusDB["ChatHistory" .. i] = {}
									local chtfrm = _G["ChatFrame" .. i]
									local NumMsg = chtfrm:GetNumMessages()
									local StartMsg = 1
									if NumMsg > 256 then StartMsg = NumMsg - 255 end
									for iMsg = StartMsg, NumMsg do
										local chatMessage, r, g, b, chatTypeID = chtfrm:GetMessageInfo(iMsg)
										if chatMessage then
											if r and g and b then
												local colorCode = RGBToColorCode(r, g, b)
												chatMessage = colorCode .. chatMessage
											end
											tinsert(LeaPlusDB["ChatHistory" .. i], chatMessage)
										end
									end
								end
							end
						end
					end
				end
			end)

			-- Restore chat messages on login
			local name, realm = UnitFullName("player")
			if not realm then realm = GetNormalizedRealmName() end
			if name and realm then
				if LeaPlusDB["ChatHistoryName"] and LeaPlusDB["ChatHistoryTime"] then
					local timeDiff = GetServerTime() - LeaPlusDB["ChatHistoryTime"]
					if LeaPlusDB["ChatHistoryName"] == name .. "-" .. realm and timeDiff and timeDiff < 10 then -- reload must be done within 15 seconds

						-- Store chat messages from current session and clear chat
						for i = 1, 50 do
							if i ~= 2 and _G["ChatFrame" .. i] and FCF_IsChatWindowIndexActive(i) then
								LeaPlusDB["ChatTemp" .. i] = {}
								local chtfrm = _G["ChatFrame" .. i]
								local NumMsg = chtfrm:GetNumMessages()
								for iMsg = 1, NumMsg do
									local chatMessage, r, g, b, chatTypeID = chtfrm:GetMessageInfo(iMsg)
									if chatMessage then
										if r and g and b then
											local colorCode = RGBToColorCode(r, g, b)
											chatMessage = colorCode .. chatMessage
										end
										tinsert(LeaPlusDB["ChatTemp" .. i], chatMessage)
									end
								end
								chtfrm:Clear()
							end
						end

						-- Restore chat messages from previous session
						for i = 1, 50 do
							if i ~= 2 and _G["ChatFrame" .. i] and LeaPlusDB["ChatHistory" .. i] and FCF_IsChatWindowIndexActive(i) then
								LeaPlusDB["ChatHistory" .. i .. "Count"] = 0
								-- Add previous session messages to chat
								for k = 1, #LeaPlusDB["ChatHistory" .. i] do
									if LeaPlusDB["ChatHistory" .. i][k] ~= string.match(LeaPlusDB["ChatHistory" .. i][k], "|cffffd800" .. L["Restored"] .. " " .. ".*" .. " " .. L["message"] .. ".*.|r") then
										_G["ChatFrame" .. i]:AddMessage(LeaPlusDB["ChatHistory" .. i][k])
										LeaPlusDB["ChatHistory" .. i .. "Count"] = LeaPlusDB["ChatHistory" .. i .. "Count"] + 1
									end
								end
								-- Show how many messages were restored
								if LeaPlusDB["ChatHistory" .. i .. "Count"] == 1 then
									_G["ChatFrame" .. i]:AddMessage("|cffffd800" .. L["Restored"] .. " " .. LeaPlusDB["ChatHistory" .. i .. "Count"] .. " " .. L["message from previous session"] .. ".|r")
								else
									_G["ChatFrame" .. i]:AddMessage("|cffffd800" .. L["Restored"] .. " " .. LeaPlusDB["ChatHistory" .. i .. "Count"] .. " " .. L["messages from previous session"] .. ".|r")
								end
							else
								-- No messages to restore
								LeaPlusDB["ChatHistory" .. i] = nil
							end
						end

						-- Restore chat messages from this session
						for i = 1, 50 do
							if i ~= 2 and _G["ChatFrame" .. i] and LeaPlusDB["ChatTemp" .. i] and FCF_IsChatWindowIndexActive(i) then
								for k = 1, #LeaPlusDB["ChatTemp" .. i] do
									_G["ChatFrame" .. i]:AddMessage(LeaPlusDB["ChatTemp" .. i][k])
								end
							end
						end

					end
				end
			end

		else

			-- Option is disabled so clear any messages from saved variables
			LeaPlusDB["ChatHistoryName"] = nil
			LeaPlusDB["ChatHistoryTime"] = nil
			for i = 1, 50 do
				LeaPlusDB["ChatHistory" .. i] = nil
				LeaPlusDB["ChatTemp" .. i] = nil
				LeaPlusDB["ChatHistory" .. i .. "Count"] = nil
			end

		end

		----------------------------------------------------------------------
		-- Manage timer
		----------------------------------------------------------------------

		if LeaPlusLC["ManageTimer"] == "On" and not LeaLockList["ManageTimer"] then

			-- Allow timer frame to be moved
			MirrorTimer1:SetMovable(true)
			MirrorTimer1:SetUserPlaced(true)
			MirrorTimer1:SetDontSavePosition(true)
			MirrorTimer1:SetClampedToScreen(true)

			-- Set timer frame position at startup
			MirrorTimer1:ClearAllPoints()
			MirrorTimer1:SetPoint(LeaPlusLC["TimerA"], UIParent, LeaPlusLC["TimerR"], LeaPlusLC["TimerX"], LeaPlusLC["TimerY"])
			MirrorTimer1:SetScale(LeaPlusLC["TimerScale"])

			-- Create drag frame
			local dragframe = CreateFrame("FRAME", nil, nil, "BackdropTemplate")
			dragframe:SetPoint("TOPRIGHT", MirrorTimer1, "TOPRIGHT", 0, 2.5)
			dragframe:SetBackdropColor(0.0, 0.5, 1.0)
			dragframe:SetBackdrop({edgeFile = "Interface/Tooltips/UI-Tooltip-Border", tile = false, tileSize = 0, edgeSize = 16, insets = { left = 0, right = 0, top = 0, bottom = 0 }})
			dragframe:SetToplevel(true)
			dragframe:Hide()
			dragframe:SetScale(LeaPlusLC["TimerScale"])

			dragframe.t = dragframe:CreateTexture()
			dragframe.t:SetAllPoints()
			dragframe.t:SetColorTexture(0.0, 1.0, 0.0, 0.5)
			dragframe.t:SetAlpha(0.5)

			dragframe.f = dragframe:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
			dragframe.f:SetPoint('CENTER', 0, 0)
			dragframe.f:SetText(L["Timer"])

			-- Click handler
			dragframe:SetScript("OnMouseDown", function(self, btn)
				-- Start dragging if left clicked
				if btn == "LeftButton" then
					MirrorTimer1:StartMoving()
				end
			end)

			dragframe:SetScript("OnMouseUp", function()
				-- Save frame positions
				MirrorTimer1:StopMovingOrSizing()
				LeaPlusLC["TimerA"], void, LeaPlusLC["TimerR"], LeaPlusLC["TimerX"], LeaPlusLC["TimerY"] = MirrorTimer1:GetPoint()
				MirrorTimer1:SetMovable(true)
				MirrorTimer1:ClearAllPoints()
				MirrorTimer1:SetPoint(LeaPlusLC["TimerA"], UIParent, LeaPlusLC["TimerR"], LeaPlusLC["TimerX"], LeaPlusLC["TimerY"])
			end)

			-- Snap-to-grid
			do
				local frame, grid = dragframe, 10
				local w, h = 180, 20
				local xpos, ypos, scale, uiscale
				frame:RegisterForDrag("RightButton")
				frame:HookScript("OnDragStart", function()
					frame:SetScript("OnUpdate", function()
						scale, uiscale = frame:GetScale(), UIParent:GetScale()
						xpos, ypos = GetCursorPosition()
						xpos = floor((xpos / scale / uiscale) / grid) * grid - w / 2
						ypos = ceil((ypos / scale / uiscale) / grid) * grid + h / 2
						MirrorTimer1:ClearAllPoints()
						MirrorTimer1:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", xpos, ypos)
					end)
				end)
				frame:HookScript("OnDragStop", function()
					frame:SetScript("OnUpdate", nil)
					frame:GetScript("OnMouseUp")()
				end)
			end

			-- Create configuration panel
			local TimerPanel = LeaPlusLC:CreatePanel("Manage timer", "TimerPanel")

			LeaPlusLC:MakeTx(TimerPanel, "Scale", 16, -72)
			LeaPlusLC:MakeSL(TimerPanel, "TimerScale", "Drag to set the timer bar scale.", 0.5, 2, 0.05, 16, -92, "%.2f")

			-- Set scale when slider is changed
			LeaPlusCB["TimerScale"]:HookScript("OnValueChanged", function()
				MirrorTimer1:SetScale(LeaPlusLC["TimerScale"])
				dragframe:SetScale(LeaPlusLC["TimerScale"])
				-- Show formatted slider value
				LeaPlusCB["TimerScale"].f:SetFormattedText("%.0f%%", LeaPlusLC["TimerScale"] * 100)
			end)

			-- Hide frame alignment grid with panel
			TimerPanel:HookScript("OnHide", function()
				LeaPlusLC.grid:Hide()
			end)

			-- Toggle grid button
			local TimerToggleGridButton = LeaPlusLC:CreateButton("TimerToggleGridButton", TimerPanel, "Toggle Grid", "TOPLEFT", 16, -72, 0, 25, true, "Click to toggle the frame alignment grid.")
			LeaPlusCB["TimerToggleGridButton"]:ClearAllPoints()
			LeaPlusCB["TimerToggleGridButton"]:SetPoint("LEFT", TimerPanel.h, "RIGHT", 10, 0)
			LeaPlusCB["TimerToggleGridButton"]:SetScript("OnClick", function()
				if LeaPlusLC.grid:IsShown() then LeaPlusLC.grid:Hide() else LeaPlusLC.grid:Show() end
			end)
			TimerPanel:HookScript("OnHide", function()
				if LeaPlusLC.grid then LeaPlusLC.grid:Hide() end
			end)

			-- Help button tooltip
			TimerPanel.h.tiptext = L["Drag the frame overlay with the left button to position it freely or with the right button to position it using snap-to-grid."]

			-- Back button handler
			TimerPanel.b:SetScript("OnClick", function()
				TimerPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page6"]:Show()
				return
			end)

			-- Reset button handler
			TimerPanel.r:SetScript("OnClick", function()

				-- Reset position and scale
				LeaPlusLC["TimerA"] = "TOP"
				LeaPlusLC["TimerR"] = "TOP"
				LeaPlusLC["TimerX"] = -5
				LeaPlusLC["TimerY"] = -96
				LeaPlusLC["TimerScale"] = 1
				MirrorTimer1:ClearAllPoints()
				MirrorTimer1:SetPoint(LeaPlusLC["TimerA"], UIParent, LeaPlusLC["TimerR"], LeaPlusLC["TimerX"], LeaPlusLC["TimerY"])

				-- Refresh configuration panel
				TimerPanel:Hide(); TimerPanel:Show()
				dragframe:Show()

				-- Show frame alignment grid
				LeaPlusLC.grid:Show()

			end)

			-- Show configuration panel when options panel button is clicked
			LeaPlusCB["ManageTimerButton"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					LeaPlusLC["TimerA"] = "TOP"
					LeaPlusLC["TimerR"] = "TOP"
					LeaPlusLC["TimerX"] = 0
					LeaPlusLC["TimerY"] = -120
					LeaPlusLC["TimerScale"] = 1
					MirrorTimer1:ClearAllPoints()
					MirrorTimer1:SetPoint(LeaPlusLC["TimerA"], UIParent, LeaPlusLC["TimerR"], LeaPlusLC["TimerX"], LeaPlusLC["TimerY"])
					MirrorTimer1:SetScale(LeaPlusLC["TimerScale"])
				else
					-- Find out if the UI has a non-standard scale
					if GetCVar("useuiscale") == "1" then
						LeaPlusLC["gscale"] = GetCVar("uiscale")
					else
						LeaPlusLC["gscale"] = 1
					end

					-- Set drag frame size according to UI scale
					dragframe:SetWidth(206 * LeaPlusLC["gscale"])
					dragframe:SetHeight(20 * LeaPlusLC["gscale"])
					dragframe:SetFrameStrata("HIGH") -- MirrorTimer is medium

					-- Show configuration panel
					TimerPanel:Show()
					LeaPlusLC:HideFrames()
					dragframe:Show()

					-- Show frame alignment grid
					LeaPlusLC.grid:Show()
				end
			end)

			-- Hide drag frame when configuration panel is closed
			TimerPanel:HookScript("OnHide", function() dragframe:Hide() end)

		end

		----------------------------------------------------------------------
		-- Show ready timer
		----------------------------------------------------------------------

		if LeaPlusLC["ShowReadyTimer"] == "On" then

			-- Player vs Player
			do

				-- Declare variables
				local t, barTime = -1, -1

				-- Create status bar below dungeon ready popup
				local bar = CreateFrame("StatusBar", nil, PVPReadyDialog)
				bar:SetPoint("TOPLEFT", PVPReadyDialog, "BOTTOMLEFT", 0, -5)
				bar:SetPoint("TOPRIGHT", PVPReadyDialog, "BOTTOMRIGHT", 0, -5)
				bar:SetHeight(5)
				bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
				bar:SetStatusBarColor(1.0, 0.85, 0.0)

				-- Create status bar text
				local text = bar:CreateFontString(nil, "ARTWORK")
				text:SetFontObject("GameFontNormalLarge")
				text:SetTextColor(1.0, 0.85, 0.0)
				text:SetPoint("TOP", 0, -10)

				-- Update bar as timer counts down
				bar:SetScript("OnUpdate", function(self, elapsed)
					t = t - elapsed
					if barTime >= 1 or barTime == -1 then
						self:SetValue(t)
						text:SetText(SecondsToTime(floor(t + 0.5)))
						barTime = 0
					end
					barTime = barTime + elapsed
				end)

				-- Show frame when PvP ready frame shows
				hooksecurefunc("PVPReadyDialog_Display", function(self, id)
					t = GetBattlefieldPortExpiration(id) + 1
					-- t = 89; -- debug
					if t and t > 1 then
						bar:SetMinMaxValues(0, t)
						barTime = -1
						bar:Show()
					else
						bar:Hide()
					end
				end)

				PVPReadyDialog:HookScript("OnHide", function()
					bar:Hide()
				end)

				-- Debug
				-- C_Timer.After(2, function() PVPReadyDialog_Display(self, 1, "Warsong Gulch", 0, "BATTLEGROUND", "", "DAMAGER"); bar:Show() end)

			end

		end

		----------------------------------------------------------------------
		-- Show flight times
		----------------------------------------------------------------------

		if LeaPlusLC["ShowFlightTimes"] == "On" then

			-- Load flight data
			Leatrix_Plus["FlightData"] = {}
			local faction = UnitFactionGroup("player")
			if faction == "Alliance" then
				Leatrix_Plus:LoadFlightDataAlliance()
			elseif faction == "Horde" then
				Leatrix_Plus:LoadFlightDataHorde()
			end

			-- Minimum time difference (in seconds) to flight data entry before flight report window is shown
			local timeBuffer = 15

			-- Create editbox
			local editFrame = CreateFrame("ScrollFrame", nil, UIParent, "LeaPlusShowFlightTimesScrollFrameTemplate")

			-- Set frame parameters
			editFrame:ClearAllPoints()
			editFrame:SetPoint("BOTTOM", 0, 130)
			editFrame:SetSize(600, 200)
			editFrame:SetFrameStrata("MEDIUM")
			editFrame:SetToplevel(true)
			editFrame:Hide()

			-- Add background color
			editFrame.t = editFrame:CreateTexture(nil, "BACKGROUND")
			editFrame.t:SetAllPoints()
			editFrame.t:SetColorTexture(0.00, 0.00, 0.0, 0.6)

			-- Create title bar
			local titleFrame = CreateFrame("Frame", nil, editFrame)
			titleFrame:ClearAllPoints()
			titleFrame:SetPoint("TOP", 0, 24)
			titleFrame:SetSize(600, 24)
			titleFrame:SetFrameStrata("MEDIUM")
			titleFrame:SetToplevel(true)
			titleFrame:SetHitRectInsets(-6, -6, -6, -6)
			titleFrame.t = titleFrame:CreateTexture(nil, "BACKGROUND")
			titleFrame.t:SetAllPoints()
			titleFrame.t:SetColorTexture(0.00, 0.00, 0.0, 0.8)

			-- Add title
			titleFrame.m = titleFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
			titleFrame.m:SetPoint("LEFT", 4, 0)
			titleFrame.m:SetText(L["Leatrix Plus"])
			titleFrame.m:SetFont(titleFrame.m:GetFont(), 16, nil)

			-- Add right-click to close message
			titleFrame.x = titleFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
			titleFrame.x:SetPoint("RIGHT", -4, 0)
			titleFrame.x:SetText(L["Right-click to close"])
			titleFrame.x:SetFont(titleFrame.x:GetFont(), 16, nil)
			titleFrame.x:SetWidth(600 - titleFrame.m:GetStringWidth() - 30)
			titleFrame.x:SetWordWrap(false)
			titleFrame.x:SetJustifyH("RIGHT")

			-- Create editbox
			local editBox = CreateFrame("EditBox", nil, editFrame)
			editBox:SetAltArrowKeyMode(false)
			editBox:SetTextInsets(4, 4, 4, 4)
			editBox:SetWidth(editFrame:GetWidth() - 30)
			editBox:SetSecurityDisablePaste()
			editBox:SetFont(_G["ChatFrame1"]:GetFont())
			editBox:SetMaxLetters(0)
			editBox:SetMultiLine(true)

			editFrame:SetScrollChild(editBox)

			local introMsg = L["Leatrix Plus needs to be updated with the flight details.  Press CTRL/C to copy the flight details below then paste them into an email to flight@leatrix.com.  When your report is received, Leatrix Plus will be updated and you will never see this window again for this flight."] .. "|n|n"
			local startHighlight = string.len(introMsg)

			local function DoHighlight()
				editBox:HighlightText(startHighlight)
			end

			editBox:SetScript("OnEscapePressed", DoHighlight)
			editBox:SetScript("OnEnterPressed", DoHighlight)
			editBox:SetScript("OnMouseUp", DoHighlight)
			editBox:HookScript("OnShow", function()
				editBox:SetFocus(); DoHighlight()
			end)

			-- Close frame with right-click of editframe or editbox
			local function CloseFlightReportWindow(self, btn)
				if btn and btn == "RightButton" then
					editBox:SetText("")
					editBox:ClearFocus()
					editFrame:Hide()
				end
			end

			editFrame:SetScript("OnMouseDown", CloseFlightReportWindow)
			editBox:SetScript("OnMouseDown", CloseFlightReportWindow)
			titleFrame:HookScript("OnMouseDown", CloseFlightReportWindow)

			-- Disable text changes while still allowing editing controls to work
			editBox:EnableKeyboard(false)
			editBox:SetScript("OnKeyDown", function() end)

			-- Debug (uncomment to show flight report window test)
			-- editBox:SetText(introMsg .. "Flight details (Classic Era): Nesingwary Base Camp (0.18:0.40) to Conquest Hold (0.70:0.55) (Horde) took 690 seconds (5 hop)." .. "|n|n" .. "[" .. '"' .. "0.18:0.40:0.24:0.40:0.52:0.38:0.54:0.52:0.59:0.55:0.70:0.55" .. '"' .. "] = 690, -- Nesingwary Base Camp, River's Heart, Dalaran, Wyrmrest Temple, Venomspite, Conquest Hold|n|nThis flight does not exist in the database."); editFrame:Show()

			-- Load LibCandyBar
			Leatrix_Plus:LeaPlusCandyBar()

			-- Variables
			local data = Leatrix_Plus["FlightData"]
			local candy = LibStub("LibCandyBar-3.0")
			local texture = "Interface\\TargetingFrame\\UI-StatusBar"
			local flightFrame = CreateFrame("FRAME")
			LeaPlusLC.flightFrame = flightFrame

			-- Set game title as shown in incorrect flight details window
			local gameTitle = L["Burning Crusade Anniversary"]

			-- Function to get continent
			local function getContinent()
				local mapID = C_Map.GetBestMapForUnit("player")
				if(mapID) then
					local info = C_Map.GetMapInfo(mapID)
					if(info) then
						while(info['mapType'] and info['mapType'] > 2) do
							info = C_Map.GetMapInfo(info['parentMapID'])
						end
						if(info['mapType'] == 2) then
							return info['mapID']
						end
					end
				end
			end

			-- Function to get node name
			local function GetNodeName(i)
				return strmatch(TaxiNodeName(i), "[^,]+")
			end

			-- Show progress bar when flight is taken
			hooksecurefunc("TakeTaxiNode", function(node)
				if UnitAffectingCombat("player") then return end
				if editFrame:IsShown() then editFrame:Hide() end
				for i = 1, NumTaxiNodes() do
					local nodeType = TaxiNodeGetType(i)
					local nodeName = GetNodeName(i)
					if nodeType == "CURRENT" then

						-- Get current node
						local continent = getContinent()
						local startX, startY = TaxiNodePosition(i)
						local currentNode = string.format("%0.2f", startX) .. ":" .. string.format("%0.2f", startY)

						-- Get flight duration and start the progress timer
						local endX, endY = TaxiNodePosition(node)
						local destination = string.format("%0.2f", endX) .. ":" .. string.format("%0.2f", endY)
						local barName = GetNodeName(node)

						-- Assign file level scope to destination (it's used for removing bar name)
						LeaPlusLC.FlightDestination = barName

						-- Build route string and debug string
						local numHops = GetNumRoutes(node)
						local debugString = '\t\t\t\t\t["' .. currentNode
						local routeString = currentNode
						for i = 2, numHops + 1 do
							local hopPosX, hopPosY = TaxiNodePosition(TaxiGetNodeSlot(node, i, true))
							local hopPos = string.format("%0.2f", hopPosX) .. ":" .. string.format("%0.2f", hopPosY)
							local fpName = string.split(", ", TaxiNodeName(TaxiGetNodeSlot(node, i, true)))
							debugString = debugString .. ":" .. hopPos
							routeString = routeString .. ":" .. hopPos
						end

						-- If route string does not contain destination, add it to the end (such as Altar of Sha'tar)
						if not string.find(routeString, destination) then
							debugString = debugString .. ":" .. destination
							routeString = routeString .. ":" .. destination
						end

						debugString = debugString .. '"] = TimeTakenPlaceHolder,'
						debugString = debugString .. " -- " .. nodeName
						for i = 2, numHops + 1 do
							local fpName = string.split(",", TaxiNodeName(TaxiGetNodeSlot(node, i, true)))
							debugString = debugString .. ", " .. fpName
						end

						-- If debug string does not contain destination, add it to the end
						if not string.find(debugString, barName) then
							debugString = debugString .. ", " .. barName
						end

						-- Handle flight time not correct or flight does not exist in database
						local timeStart = GetTime()
						C_Timer.After(1, function()
							if UnitOnTaxi("player") then
								-- Player is on a taxi so register when taxi lands
								flightFrame:RegisterEvent("PLAYER_CONTROL_GAINED")
							else
								-- Player is not on a taxi so delete the flight progress bar
								flightFrame:UnregisterEvent("PLAYER_CONTROL_GAINED")
								if LeaPlusLC.FlightProgressBar then
									LeaPlusLC.FlightProgressBar:Stop()
									LeaPlusLC.FlightProgressBar = nil
								end
							end
						end)
						flightFrame:SetScript("OnEvent", function()
							local timeEnd = GetTime()
							local timeTaken = timeEnd - timeStart
							debugString = gsub(debugString, "TimeTakenPlaceHolder", string.format("%0.0f", timeTaken))
							local flightMsg = L["Flight details"] .. " (" .. gameTitle.. "): " .. nodeName .. " (" .. currentNode .. ") " .. L["to"] .. " " .. barName .. " (" .. destination .. ") (" .. faction .. ") " .. L["took"] .. " " .. string.format("%0.0f", timeTaken) .. " " .. L["seconds"] .. " (" .. numHops .. " " .. L["hop"] ..").|n|n" .. debugString .. "|n|n"
							if destination and data[faction] and data[faction][continent] and data[faction][continent][routeString] then
								local savedDuration = data[faction][continent][routeString]
								if savedDuration then
									if timeTaken > (savedDuration + timeBuffer) or timeTaken < (savedDuration - timeBuffer) then
										local editMsg = introMsg .. flightMsg .. L["This flight's actual time of"] .. " " .. string.format("%0.0f", timeTaken) .. " " .. L["seconds does not match the saved flight time of"] .. " " .. savedDuration .. " " .. L["seconds"] .. "."
										editBox:SetText(editMsg); if LeaPlusLC["FlightBarContribute"] == "On2" then editFrame:Show() end -- LeaPlusLC.NewPatch: Currently disabled, change to On to enable again
									end
								else
									local editMsg = introMsg .. flightMsg .. L["This flight does not have a saved duration in the database."]
									editBox:SetText(editMsg); if LeaPlusLC["FlightBarContribute"] == "On2" then editFrame:Show() end -- LeaPlusLC.NewPatch: Currently disabled, change to On to enable again
								end
							else
								local editMsg = introMsg .. flightMsg .. L["This flight does not exist in the database."]
								editBox:SetText(editMsg); if LeaPlusLC["FlightBarContribute"] == "On2" then editFrame:Show() end -- LeaPlusLC.NewPatch: Currently disabled, change to On to enable again
							end
							flightFrame:UnregisterEvent("PLAYER_CONTROL_GAINED")

							-- Delete the progress bar since we have landed
							if LeaPlusLC.FlightProgressBar then
								LeaPlusLC.FlightProgressBar:Stop()
								LeaPlusLC.FlightProgressBar = nil
							end
						end)

						-- Show flight progress bar if flight exists in database
						if data[faction] and data[faction][continent] and data[faction][continent][routeString] then

							local duration = data[faction][continent][routeString]
							if duration then

								-- Delete an existing progress bar if one exists
								if LeaPlusLC.FlightProgressBar then
									LeaPlusLC.FlightProgressBar:Stop()
									LeaPlusLC.FlightProgressBar = nil
								end

								-- Create progress bar
								local mybar = candy:New(texture, 230, 16)
								mybar:SetPoint(LeaPlusLC["FlightBarA"], UIParent, LeaPlusLC["FlightBarR"], LeaPlusLC["FlightBarX"], LeaPlusLC["FlightBarY"])
								mybar:SetScale(LeaPlusLC["FlightBarScale"])
								mybar:SetWidth(LeaPlusLC["FlightBarWidth"])

								-- Setup sound files
								local mt
								local Seconds600, Seconds540, Seconds480, Seconds420, Seconds360
								local Seconds300, Seconds240, Seconds180, Seconds120, Seconds060
								local Seconds030, Seconds020, Seconds010
								local speed = -2

								if LeaPlusLC["FlightBarSpeech"] == "On" then
									C_Timer.After(1, function()
										C_VoiceChat.SpeakText(0, L["Flight commenced."], speed, GetCVar("Sound_MasterVolume") * 100)
									end)
									mybar:AddUpdateFunction(function(bar)
										mt = bar.remaining
											if mt > 600 and mt < 601 and not Seconds600 then Seconds600 = true; C_VoiceChat.SpeakText(0, L["Ten minutes"], speed, GetCVar("Sound_MasterVolume") * 100)
										elseif mt > 540 and mt < 541 and not Seconds540 then Seconds540 = true; C_VoiceChat.SpeakText(0, L["Nine minutes"], speed, GetCVar("Sound_MasterVolume") * 100)
										elseif mt > 480 and mt < 481 and not Seconds480 then Seconds480 = true; C_VoiceChat.SpeakText(0, L["Eight minutes"], speed, GetCVar("Sound_MasterVolume") * 100)
										elseif mt > 420 and mt < 421 and not Seconds420 then Seconds420 = true; C_VoiceChat.SpeakText(0, L["Seven minutes"], speed, GetCVar("Sound_MasterVolume") * 100)
										elseif mt > 360 and mt < 361 and not Seconds360 then Seconds360 = true; C_VoiceChat.SpeakText(0, L["Six minutes"], speed, GetCVar("Sound_MasterVolume") * 100)
										elseif mt > 300 and mt < 301 and not Seconds300 then Seconds300 = true; C_VoiceChat.SpeakText(0, L["Five minutes"], speed, GetCVar("Sound_MasterVolume") * 100)
										elseif mt > 240 and mt < 241 and not Seconds240 then Seconds240 = true; C_VoiceChat.SpeakText(0, L["Four minutes"], speed, GetCVar("Sound_MasterVolume") * 100)
										elseif mt > 180 and mt < 181 and not Seconds180 then Seconds180 = true; C_VoiceChat.SpeakText(0, L["Three minutes"], speed, GetCVar("Sound_MasterVolume") * 100)
										elseif mt > 120 and mt < 121 and not Seconds120 then Seconds120 = true; C_VoiceChat.SpeakText(0, L["Two minutes"], speed, GetCVar("Sound_MasterVolume") * 100)
										elseif mt > 060 and mt < 061 and not Seconds060 then Seconds060 = true; C_VoiceChat.SpeakText(0, L["One minute"], speed, GetCVar("Sound_MasterVolume") * 100)
										elseif mt > 030 and mt < 031 and not Seconds030 then Seconds030 = true; C_VoiceChat.SpeakText(0, L["Thirty seconds"], speed, GetCVar("Sound_MasterVolume") * 100)
										elseif mt > 020 and mt < 021 and not Seconds020 then Seconds020 = true; C_VoiceChat.SpeakText(0, L["Twenty seconds"], speed, GetCVar("Sound_MasterVolume") * 100)
										elseif mt > 010 and mt < 011 and not Seconds010 then Seconds010 = true; C_VoiceChat.SpeakText(0, L["Ten seconds"], speed, GetCVar("Sound_MasterVolume") * 100)
										end
									end)
								end

								if faction == "Alliance" then
									mybar:SetColor(0, 0.5, 1, 0.5)
								else
									mybar:SetColor(1, 0.0, 0, 0.5)
								end
								mybar:SetShadowColor(0, 0, 0, 0.5)

								mybar:SetScript("OnMouseDown", function(self, btn)
									if btn == "RightButton" then
										mybar:Stop()
										LeaPlusLC.FlightProgressBar = nil
									end
								end)

								-- Set bar label width
								-- barName = "SupercalifragilisticexpialidociousDociousaliexpisticfragicalirupus" -- Debug
								mybar.candyBarLabel:ClearAllPoints()
								mybar.candyBarLabel:SetPoint("TOPLEFT", mybar.candyBarBackground, "TOPLEFT", 2, 0)
								mybar.candyBarLabel:SetPoint("BOTTOMRIGHT", mybar.candyBarBackground, "BOTTOMRIGHT", -40, 0)

								-- Set flight bar background
								if LeaPlusLC["FlightBarBackground"] == "On" then
									if LeaPlusLC.ElvUI then
										_G.LeaPlusGlobalFlightBar = mybar.candyBarBar
										if faction == "Alliance" then
											LeaPlusLC.ElvUI:GetModule("Skins"):HandleStatusBar(_G.LeaPlusGlobalFlightBar, {0, 0.5, 1, 0.5})
										else
											LeaPlusLC.ElvUI:GetModule("Skins"):HandleStatusBar(_G.LeaPlusGlobalFlightBar, {1, 0.0, 0, 0.5})
										end
									else
										mybar:SetTexture(texture)
									end
								else
									mybar:SetTexture("")
								end

								-- Set flight bar destination
								if LeaPlusLC["FlightBarDestination"] == "On" then
									mybar:SetLabel(barName)
								end

								-- Set flight bar fill mode
								if LeaPlusLC["FlightBarFillBar"] == "On" then
									mybar:SetFill(true)
								else
									mybar:SetFill(false)
								end

								mybar:EnableMouse(false)
								mybar:SetDuration(duration)
								mybar:Start()

								-- Unlock close bar button
								if LeaPlusCB["CloseFlightBarButton"] then
									LeaPlusLC:LockItem(LeaPlusCB["CloseFlightBarButton"], false)
								end

								-- Assign file level scope to the bar so it can be cancelled later
								LeaPlusLC.FlightProgressBar = mybar

							end

						end

					end
				end
			end)

			-- Function to stop the progress bar
			local function CeaseProgress()
				if LeaPlusLC.FlightProgressBar then
					LeaPlusLC.FlightProgressBar:Stop()
					LeaPlusLC.FlightProgressBar = nil
				end
			end

			-- Stop the progress bar under various circumstances
			hooksecurefunc("TaxiRequestEarlyLanding", CeaseProgress)
			hooksecurefunc("AcceptBattlefieldPort", CeaseProgress)
			hooksecurefunc(C_SummonInfo, "ConfirmSummon", CeaseProgress)

			-- Show flight time in node tooltips
			hooksecurefunc("TaxiNodeOnButtonEnter", function(button)
				local index = button:GetID()
				for i = 1, NumTaxiNodes() do
					local nodeType = TaxiNodeGetType(i)
					local nodeName = GetNodeName(i)
					if nodeType == "CURRENT" then

						-- Get current node
						local continent = getContinent()
						local startX, startY = TaxiNodePosition(i)
						local currentNode = string.format("%0.2f", startX) .. ":" .. string.format("%0.2f", startY)

						-- Get destination
						local endX, endY = TaxiNodePosition(index)
						local destination = string.format("%0.2f", endX) .. ":" .. string.format("%0.2f", endY)
						local barName = GetNodeName(index)

						-- Build route string and debug string
						local numEnterHops = GetNumRoutes(index)
						local debugString = '["' .. currentNode
						local routeString = currentNode
						for i = 2, numEnterHops + 1 do
							local hopPosX, hopPosY = TaxiNodePosition(TaxiGetNodeSlot(index, i, true)) -- TaxiNodeName
							local hopPos = string.format("%0.2f", hopPosX) .. ":" .. string.format("%0.2f", hopPosY)
							local fpName = string.split(", ", TaxiNodeName(TaxiGetNodeSlot(index, i, true)))
							debugString = debugString .. ":" .. hopPos
							routeString = routeString .. ":" .. hopPos
						end

						-- If route string does not contain destination, add it to the end (such as Altar of Sha'tar)
						if not string.find(routeString, destination) then
							debugString = debugString .. ":" .. destination
							routeString = routeString .. ":" .. destination
						end
						debugString = debugString .. '"] = '

						-- Show flight time in tooltip if it exists
						if data[faction] and data[faction][continent] and data[faction][continent][routeString] then
							local duration = data[faction][continent][routeString]
							if duration and type(duration) == "number" then
								duration = date("%M:%S", duration):gsub("^0","")
								GameTooltip:AddLine(L["Duration"] .. ": " .. duration, 0.9, 0.9, 0.9, true)
								GameTooltip:Show()
							end
						elseif currentNode ~= destination then
							GameTooltip:AddLine(L["Duration"] .. ": -:--", 0.9, 0.9, 0.9, true)
							GameTooltip:Show()
						end

						-- Add node names to debug string
						debugString = debugString .. " -- " .. nodeName
						for i = 2, numEnterHops + 1 do
							local fpName = string.split(",", TaxiNodeName(TaxiGetNodeSlot(index, i, true)))
							debugString = debugString .. ", " .. fpName
						end

						-- If debug string does not contain destination, add it to the end
						if not string.find(debugString, barName) then
							debugString = debugString .. ", " .. barName
						end

						-- Print debug string (used for showing full routes for nodes)
						-- print(debugString)

						-- Print destination node
						-- print(destination .. " - " .. barName)

					end
				end
			end)

			-- Unregister landing event for various reasons that stop taxi early
			local function StopLandingEvent()
				LeaPlusLC.flightFrame:UnregisterEvent("PLAYER_CONTROL_GAINED")
			end

			hooksecurefunc("TaxiNodeOnButtonEnter", StopLandingEvent)
			hooksecurefunc("TaxiRequestEarlyLanding", StopLandingEvent)
			hooksecurefunc("AcceptBattlefieldPort", StopLandingEvent)
			hooksecurefunc(C_SummonInfo, "ConfirmSummon", StopLandingEvent)

			----------------------------------------------------------------------
			-- Drag frame
			----------------------------------------------------------------------

			-- Create drag frame
			local tempFrame = CreateFrame("FRAME", nil, UIParent)
			tempFrame:SetWidth(230)
			tempFrame:SetHeight(16)
			tempFrame:SetScale(2)
			tempFrame:ClearAllPoints()
			tempFrame:SetPoint(LeaPlusLC["FlightBarA"], UIParent, LeaPlusLC["FlightBarR"], LeaPlusLC["FlightBarX"], LeaPlusLC["FlightBarY"])
			tempFrame:Hide()
			tempFrame:SetFrameStrata("FULLSCREEN_DIALOG")
			tempFrame:SetFrameLevel(5000)
			tempFrame:SetClampedToScreen(false)

			-- Create texture
			tempFrame.t = tempFrame:CreateTexture(nil, "BORDER")
			tempFrame.t:SetAllPoints()
			tempFrame.t:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
			tempFrame.t:SetVertexColor(0.0, 1.0, 0.0, 0.5)

			-- Enable movement
			tempFrame:EnableMouse(true)
			tempFrame:SetMovable(true)
			tempFrame:SetScript("OnMouseDown", function()
				tempFrame:StartMoving()
			end)
			tempFrame:SetScript("OnMouseUp", function()
				tempFrame:StopMovingOrSizing()
				LeaPlusLC["FlightBarA"], void, LeaPlusLC["FlightBarR"], LeaPlusLC["FlightBarX"], LeaPlusLC["FlightBarY"] = tempFrame:GetPoint()
				-- Position actual flight progress bar if one exists
				if LeaPlusLC.FlightProgressBar then
					LeaPlusLC.FlightProgressBar:ClearAllPoints()
					LeaPlusLC.FlightProgressBar:SetPoint(LeaPlusLC["FlightBarA"], UIParent, LeaPlusLC["FlightBarR"], LeaPlusLC["FlightBarX"], LeaPlusLC["FlightBarY"])
				end
			end)

			----------------------------------------------------------------------
			-- Configuration panel
			----------------------------------------------------------------------

			-- Create configuration panel
			local FlightPanel = LeaPlusLC:CreatePanel("Show flight times", "FlightPanel")

			LeaPlusLC:MakeTx(FlightPanel, "Settings", 16, -72)
			LeaPlusLC:MakeCB(FlightPanel, "FlightBarBackground", "Show background", 16, -92, false, "If checked, the flight progress bar background texture will be shown.")
			LeaPlusLC:MakeCB(FlightPanel, "FlightBarDestination", "Show destination", 16, -112, false, "If checked, the flight progress bar destination will be shown.")
			LeaPlusLC:MakeCB(FlightPanel, "FlightBarFillBar", "Fill instead of drain", 16, -132, false, "If checked, the flight progress bar background will fill instead of drain.")
			LeaPlusLC:MakeCB(FlightPanel, "FlightBarSpeech", "Speak the remaining time", 16, -152, false, "If checked, the remaining flight time will be spoken using text to speech.|n|nChanges to this setting will take effect on the next flight you take.")

			LeaPlusLC:MakeTx(FlightPanel, "Contribute", 16, -192)
			LeaPlusLC:MakeCB(FlightPanel, "FlightBarContribute", "Help contribute flight times", 16, -212, false, "If checked, you will be prompted to submit missing flight times.")

			LeaPlusLC:MakeTx(FlightPanel, "Scale", 356, -72)
			LeaPlusLC:MakeSL(FlightPanel, "FlightBarScale", "Drag to set the flight progress bar scale.", 1, 5, 0.1, 356, -92, "%.2f")

			LeaPlusLC:MakeTx(FlightPanel, "Width", 356, -132)
			LeaPlusLC:MakeSL(FlightPanel, "FlightBarWidth", "Drag to set the flight progress bar width.", 40, 460, 10, 356, -152, "%.0f")

			-- Function to lock an option and add a note to the tooltip
			local function LockDF(option, reason)
				LeaPlusLC:LockItem(LeaPlusCB[option], true)
				if reason then
					LeaPlusCB[option].tiptext = LeaPlusCB[option].tiptext .. "|n|n|cff00AAFF" .. L[reason]
				end
			end

			-- LeaPlusLC.NewPatch
			LockDF("FlightBarContribute", L["This option is not currently available."])

			-- Add close bar button
			local CloseFlightBarButton = LeaPlusLC:CreateButton("CloseFlightBarButton", FlightPanel, "Close Bar", "TOPLEFT", 16, -72, 0, 25, true, "Click to close the currently active flight progress bar.")
			LeaPlusCB["CloseFlightBarButton"]:ClearAllPoints()
			LeaPlusCB["CloseFlightBarButton"]:SetPoint("LEFT", FlightPanel.h, "RIGHT", 10, 0)
			LeaPlusCB["CloseFlightBarButton"]:SetScript("OnClick", function()
				if LeaPlusLC.FlightProgressBar then
					LeaPlusLC.FlightProgressBar:Stop()
					LeaPlusLC.FlightProgressBar = nil
				end
			end)

			-- Lock close bar button at startup and when flight progress bar stops
			LeaPlusLC:LockItem(LeaPlusCB["CloseFlightBarButton"], true)
			candy.RegisterCallback(LeaPlusLC, "LibCandyBar_Stop", function()
				if LeaPlusCB["CloseFlightBarButton"] then
					LeaPlusLC:LockItem(LeaPlusCB["CloseFlightBarButton"], true)
				end
			end)

			-- Set progress bar background
			if LeaPlusLC.ElvUI then

				-- Progress bar background is always enabled and cannot be disabled with ElvUI
				LeaPlusLC:LockItem(LeaPlusCB["FlightBarBackground"], true)
				LeaPlusLC["FlightBarBackground"] = "On"
				LeaPlusCB["FlightBarBackground"].tiptext = LeaPlusCB["FlightBarBackground"].tiptext .. "|n|n|cff00AAFF" .. L["The background is always shown with ElvUI."]

			else

				-- Set progress bar background
				local function SetProgressBarBackground()
					if LeaPlusLC.FlightProgressBar then
						if LeaPlusLC["FlightBarBackground"] == "On" then
							LeaPlusLC.FlightProgressBar:SetTexture(texture)
						else
							LeaPlusLC.FlightProgressBar:SetTexture("")
						end
					end
				end

				-- Set progress bar background when option is clicked and on startup
				LeaPlusCB["FlightBarBackground"]:HookScript("OnClick", SetProgressBarBackground)
				SetProgressBarBackground()

			end

			-- Set progress bar fill mode
			local function SetProgressBarFillMode()
				if LeaPlusLC.FlightProgressBar then
					if LeaPlusLC["FlightBarFillBar"] == "On" then
						LeaPlusLC.FlightProgressBar:SetFill(true)
					else
						LeaPlusLC.FlightProgressBar:SetFill(false)
					end
				end
			end

			-- Set progress bar fill mode when option is clicked and on startup
			LeaPlusCB["FlightBarFillBar"]:HookScript("OnClick", SetProgressBarFillMode)
			SetProgressBarFillMode()

			-- Set progress bar destination
			local function SetProgressBarDestination()
				if LeaPlusLC.FlightProgressBar then
					if LeaPlusLC["FlightBarDestination"] == "On" then
						if LeaPlusLC.FlightDestination then
							LeaPlusLC.FlightProgressBar:SetLabel(LeaPlusLC.FlightDestination)
						end
					else
						LeaPlusLC.FlightProgressBar:SetLabel("")
					end
				end
			end

			-- Set flight bar destination when option is clicked and on startup
			LeaPlusCB["FlightBarDestination"]:HookScript("OnClick", SetProgressBarDestination)
			SetProgressBarDestination()

			-- Flight progress bar scale
			local function SetFlightBarScale()
				tempFrame:SetScale(LeaPlusLC["FlightBarScale"])
				if LeaPlusLC.FlightProgressBar then
					LeaPlusLC.FlightProgressBar:SetScale(LeaPlusLC["FlightBarScale"])
				end
				-- Set slider formatted text
				LeaPlusCB["FlightBarScale"].f:SetFormattedText("%.0f%%", (LeaPlusLC["FlightBarScale"] / 2) * 100)
			end

			-- Set flight bar scale when slider is changed and on startup
			LeaPlusCB["FlightBarScale"]:HookScript("OnValueChanged", SetFlightBarScale)
			SetFlightBarScale()

			-- Flight progress bar width
			local function SetFlightBarWidth()
				tempFrame:SetWidth(LeaPlusLC["FlightBarWidth"])
				if LeaPlusLC.FlightProgressBar then
					LeaPlusLC.FlightProgressBar:SetWidth(LeaPlusLC["FlightBarWidth"])
				end
				-- Set slider formatted text
				LeaPlusCB["FlightBarWidth"].f:SetFormattedText("%.0f%%", (LeaPlusLC["FlightBarWidth"] / 230) * 100)
			end

			-- Set flight bar width when slider is changed and on startup
			LeaPlusCB["FlightBarWidth"]:HookScript("OnValueChanged", SetFlightBarWidth)
			SetFlightBarWidth()

			-- Help button tooltip
			FlightPanel.h.tiptext = L["Drag the frame overlay to position the frame."]

			-- Back button handler
			FlightPanel.b:SetScript("OnClick", function()
				FlightPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page7"]:Show()
				return
			end)

			-- Reset button handler
			FlightPanel.r:SetScript("OnClick", function()

				-- Reset controls
				LeaPlusLC["FlightBarA"], LeaPlusLC["FlightBarR"], LeaPlusLC["FlightBarX"], LeaPlusLC["FlightBarY"] = "TOP", "TOP", 0, -66
				tempFrame:ClearAllPoints()
				tempFrame:SetPoint(LeaPlusLC["FlightBarA"], UIParent, LeaPlusLC["FlightBarR"], LeaPlusLC["FlightBarX"], LeaPlusLC["FlightBarY"])
				-- Reset scale
				LeaPlusLC["FlightBarScale"] = 2
				tempFrame:SetScale(LeaPlusLC["FlightBarScale"])
				-- Reset width
				LeaPlusLC["FlightBarWidth"] = 230
				tempFrame:SetWidth(LeaPlusLC["FlightBarWidth"])
				-- Reset checkboxes
				LeaPlusLC["FlightBarBackground"] = "On"
				LeaPlusLC["FlightBarDestination"] = "On"
				LeaPlusLC["FlightBarFillBar"] = "Off"; SetProgressBarFillMode()
				LeaPlusLC["FlightBarSpeech"] = "Off"
				LeaPlusLC["FlightBarContribute"] = "On"
				-- Reset live progress bar
				if LeaPlusLC.FlightProgressBar then
					-- Reset position
					LeaPlusLC.FlightProgressBar:ClearAllPoints()
					LeaPlusLC.FlightProgressBar:SetPoint(LeaPlusLC["FlightBarA"], UIParent, LeaPlusLC["FlightBarR"], LeaPlusLC["FlightBarX"], LeaPlusLC["FlightBarY"])
					LeaPlusLC.FlightProgressBar:SetScale(LeaPlusLC["FlightBarScale"])
					-- Reset width
					LeaPlusLC.FlightProgressBar:SetWidth(LeaPlusLC["FlightBarWidth"])
					-- Reset background
					LeaPlusLC.FlightProgressBar:SetTexture(texture)
					-- Reset destination
					if LeaPlusLC.FlightDestination then
						LeaPlusLC.FlightProgressBar:SetLabel(LeaPlusLC.FlightDestination)
					end
				end

				-- Refresh configuration panel
				FlightPanel:Hide(); FlightPanel:Show()

			end)

			-- Show configuration panal when options panel button is clicked
			LeaPlusCB["ShowFlightTimesBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					LeaPlusLC["FlightBarContribute"] = "On"
				else
					FlightPanel:Show()
					LeaPlusLC:HideFrames()
				end
			end)

			-- Toggle drag frame with configuration panel
			FlightPanel:HookScript("OnShow", function()
				tempFrame:Show()
			end)

			FlightPanel:HookScript("OnHide", function()
				tempFrame:Hide()
			end)

		end

		----------------------------------------------------------------------
		-- Enhance minimap
		----------------------------------------------------------------------

		if LeaPlusLC["MinimapModder"] == "On" and not LeaLockList["MinimapModder"] then

			local miniFrame = CreateFrame("FRAME")
			local LibDBIconStub = LibStub("LibDBIcon-1.0")

			QuestWatchFrame:SetFrameStrata("LOW")

			-- Function to set button radius
			local function SetButtonRad()
				if LeaPlusLC["SquareMinimap"] == "On" then
					LibDBIconStub:SetButtonRadius(26 + ((LeaPlusLC["MinimapSize"] - 140) * 0.165))
				else
					LibDBIconStub:SetButtonRadius(1)
				end
			end

			-- Disable mouse on invisible minimap cluster
			MinimapCluster:EnableMouse(false)

			----------------------------------------------------------------------
			-- Button test mode
			----------------------------------------------------------------------

			-- Create a ton of minimap buttons for test purposes
			local useMinimapButtonTestMode = false
			if useMinimapButtonTestMode then
				local numberOfTestButtons = 50
				local miniTable = {}
				for i = 1, numberOfTestButtons do
					miniTable[i] = LibStub("LibDataBroker-1.1"):NewDataObject("Leatrix_Plus" .. i, {
						type = "data source",
						text = "Test Addon " .. i,
						icon = "Interface\\HELPFRAME\\ReportLagIcon-Movement",
						OnClick = function(self, btn)
							LeaPlusGlobalMiniBtnClickFunc(btn)
						end,
						OnTooltipShow = function(tooltip)
							if not tooltip or not tooltip.AddLine then return end
							tooltip:AddLine("Test Addon " .. i)
						end,
					})
					miniTable[i].minimapPos = i * 50
				end
				for i = 1, numberOfTestButtons do
					LibStub("LibDBIcon-1.0", true):Register("Leatrix_Plus" .. i, miniTable[i], miniTable[i])
				end
			end

			----------------------------------------------------------------------
			-- Configuration panel
			----------------------------------------------------------------------

			-- Create configuration panel
			local SideMinimap = LeaPlusLC:CreatePanel("Enhance minimap", "SideMinimap", true)

			-- Hide panel during combat
			SideMinimap:SetScript("OnUpdate", function()
				if UnitAffectingCombat("player") then
					SideMinimap:Hide()
				end
			end)

			-- Add checkboxes
			LeaPlusLC:MakeTx(SideMinimap.scrollChild, "Settings", 16, 0)
			LeaPlusLC:MakeCB(SideMinimap.scrollChild, "HideMiniZoomBtns", "Hide the zoom buttons", 16, -20, false, "If checked, the zoom buttons will be hidden.  You can use the mousewheel to zoom regardless of this setting.")
			LeaPlusLC:MakeCB(SideMinimap.scrollChild, "HideMiniClock", "Hide the clock", 16, -40, false, "If checked, the clock will be hidden.")
			LeaPlusLC:MakeCB(SideMinimap.scrollChild, "HideMiniDayNight", "Hide the day and night indicator", 16, -60, true, "If checked, the day and night indicator will be hidden.")
			LeaPlusLC:MakeCB(SideMinimap.scrollChild, "HideMiniZoneText", "Hide the zone text bar", 16, -80, true, "If checked, the zone text bar will be hidden.")
			LeaPlusLC:MakeCB(SideMinimap.scrollChild, "HideMiniTracking", "Hide the tracking button", 16, -100, true, "If checked, the tracking button will be hidden while the pointer is not over the minimap.")
			LeaPlusLC:MakeCB(SideMinimap.scrollChild, "HideMiniLFG", "Hide the Looking for Group button", 16, -120, true, "If checked, the Looking for Group button will be hidden while you are not queued.|n|nThis only applies to game realms with a Looking for Group feature.")
			LeaPlusLC:MakeCB(SideMinimap.scrollChild, "HideMiniAddonButtons", "Hide addon buttons", 16, -140, false, "If checked, addon buttons will be hidden while the pointer is not over the minimap.")
			LeaPlusLC:MakeCB(SideMinimap.scrollChild, "MinimapButtonBag", "Minimap button bag", 16, -160, true, "If checked, minimap buttons for addons will be collected and placed in a bag which you can toggle by right-clicking the minimap.|n|nThis setting will help you declutter the minimap without the need to install a separate addon to do that.")
			LeaPlusLC:MakeCB(SideMinimap.scrollChild, "SquareMinimap", "Square minimap", 16, -180, true, "If checked, the minimap shape will be square.|n|nMinimap rotation (a setting in Edit Mode) is not recommended with a square minimap.")

			-- Add excluded button
			local MiniExcludedButton = LeaPlusLC:CreateButton("MiniExcludedButton", SideMinimap, "Buttons", "TOPLEFT", 16, -72, 0, 25, true, "Click to toggle the addon buttons editor.")
			LeaPlusCB["MiniExcludedButton"]:ClearAllPoints()
			LeaPlusCB["MiniExcludedButton"]:SetPoint("LEFT", SideMinimap.r, "RIGHT", 10, 0)

			-- Set exclude button visibility
			local function SetExcludeButtonsFunc()
				if LeaPlusLC["HideMiniAddonButtons"] == "On" or LeaPlusLC["MinimapButtonBag"] == "On" then
					LeaPlusLC:LockItem(LeaPlusCB["MiniExcludedButton"], false)
				else
					LeaPlusLC:LockItem(LeaPlusCB["MiniExcludedButton"], true)
				end
			end
			LeaPlusCB["HideMiniAddonButtons"]:HookScript("OnClick", SetExcludeButtonsFunc)
			SetExcludeButtonsFunc()

			-- Add effects dropdown
			LeaPlusLC:CreateDropdown("MinimapEffect", "Visual effect", 150, "TOPLEFT", SideMinimap.scrollChild, "TOPLEFT", 346, -20, false, {{L["None"], 1}, {L["Arcane"], 2}, {L["Rune"], 3}, {L["Vortex"], 4}, {L["Inferno"], 5}, {L["Snow"], 6}, {L["Storm"], 7}, {L["Corona"], 8}, {L["Aurora"], 9}, {L["Starfield"], 10}, {L["Chronometer"], 11}, {L["Heartbeat"], 12}, {L["Fireworks"], 13}, {L["Crystals"], 14}, {L["Neon"], 15}, {L["Marquee"], 16}, {L["Glitch"], 17}, {L["Lava"], 18}, {L["Fuse"], 19}, {L["Rain"], 20}, {L["Prism"], 21}, {L["Candy"], 22}, {L["Rainbow"], 23}, {L["Fireflies"], 24}, {L["Synthwave"], 25}, {L["Collider"], 26}, {L["Bubbles"], 27}, {L["Acid"], 28}, {L["Shadow"], 29}, {L["Radar"], 30}, {L["Tesla"], 31}, {L["Meteor"], 32}, {L["Tube"], 33}})

			-- Add slider controls
			LeaPlusLC:MakeTx(SideMinimap.scrollChild, "Square size", 346, -62)
			LeaPlusLC:MakeSL(SideMinimap.scrollChild, "MinimapSize", "Drag to set the square minimap size.|n|nAdjusting this slider makes the minimap bigger but keeps the elements the same size.", 140, 560, 1, 346, -72, "%.0f")

			LeaPlusLC:MakeTx(SideMinimap.scrollChild, "Border width", 346, -112)
			LeaPlusLC:MakeSL(SideMinimap.scrollChild, "MinimapBorderWidth", "Drag to set the square minimap border width.", 1, 10, 1, 346, -122, "%.0f")

			----------------------------------------------------------------------
			-- Addon buttons editor
			----------------------------------------------------------------------

			do

				-- Create configuration panel
				local ExcludedButtonsPanel = LeaPlusLC:CreatePanel("Enhance minimap", "ExcludedButtonsPanel")
				local boxWidth = 272

				-- Add second excluded button
				local MiniExcludedButton2 = LeaPlusLC:CreateButton("MiniExcludedButton2", ExcludedButtonsPanel, "Buttons", "TOPLEFT", 16, -72, 0, 25, true, "Click to toggle the addon buttons editor.")
				LeaPlusCB["MiniExcludedButton2"]:ClearAllPoints()
				LeaPlusCB["MiniExcludedButton2"]:SetPoint("LEFT", ExcludedButtonsPanel.r, "RIGHT", 10, 0)
				LeaPlusCB["MiniExcludedButton2"]:SetScript("OnClick", function()
					ExcludedButtonsPanel:Hide(); SideMinimap:Show()
					return
				end)

				-- Add large editbox
				local titleTX = LeaPlusLC:MakeTx(ExcludedButtonsPanel, "Editor", 16, -72)
				titleTX:SetWidth(boxWidth - 14) -- 534
				titleTX:SetWordWrap(false)
				titleTX:SetJustifyH("LEFT")

				-- Add help button
				LeaPlusLC:CreateHelpButton("MinimapButtonsAvailableHelpButton", ExcludedButtonsPanel, titleTX, "If you use the 'Hide addon buttons' or 'Minimap button bag' settings but you want some addon buttons to remain visible around the minimap, enter the button names into the editbox below separated by commas.|n|nChanges will require a UI reload to take effect.")

				local eb = CreateFrame("Frame", nil, ExcludedButtonsPanel, "BackdropTemplate")
				eb:SetSize(boxWidth, LeaPlusLC.MainPanelHeight - 180) -- 548
				eb:SetPoint("TOPLEFT", 10, -92)
				eb:SetBackdrop({
					bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
					edgeFile = "Interface\\PVPFrame\\UI-Character-PVP-Highlight",
					edgeSize = 16,
					insets = { left = 8, right = 6, top = 8, bottom = 8 },
				})
				eb:SetBackdropBorderColor(1.0, 0.85, 0.0, 0.5)

				eb.scroll = CreateFrame("ScrollFrame", nil, eb, "LeaPlusEnhanceMinimapExcludeButtonsScrollFrameTemplate")
				eb.scroll:SetPoint("TOPLEFT", eb, 12, -10)
				eb.scroll:SetPoint("BOTTOMRIGHT", eb, -30, 10)
				eb.scroll:SetPanExtent(16)

				-- Create character count
				eb.scroll.CharCount = eb.scroll:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
				eb.scroll.CharCount:Hide()

				eb.Text = eb.scroll.EditBox
				eb.Text:SetWidth(boxWidth - 54) -- 494
				eb.Text:SetHeight(230)
				eb.Text:SetPoint("TOPLEFT", eb.scroll)
				eb.Text:SetPoint("BOTTOMRIGHT", eb.scroll, -12, 0)
				eb.Text:SetMaxLetters(1200)
				eb.Text:SetFontObject(GameFontNormalLarge)
				eb.Text:SetAutoFocus(false)
				eb.scroll:SetScrollChild(eb.Text)

				-- Set focus on the editbox text when clicking the editbox
				eb:SetScript("OnMouseDown", function()
					eb.Text:SetFocus()
					eb.Text:SetCursorPosition(eb.Text:GetMaxLetters())
				end)

				-- Debug
				-- eb.Text:SetText("Leatrix_Plus\nLeatrix_Maps\nBugSack\nLeatrix_Plus\nLeatrix_Maps\nBugSack\nLeatrix_Plus\nLeatrix_Maps\nBugSack\nLeatrix_Plus\nLeatrix_Maps\nBugSack\nLeatrix_Plus\nLeatrix_Maps\nBugSack")

				-- Function to save the excluded list
				local function SaveString(self, userInput)
					local keytext = eb.Text:GetText()
					if keytext and keytext ~= "" then
						LeaPlusLC["MiniExcludeList"] = strtrim(eb.Text:GetText())
					else
						LeaPlusLC["MiniExcludeList"] = ""
					end
					if userInput then
						LeaPlusLC:ReloadCheck()
					end
				end

				-- Save the excluded list when it changes and at startup
				eb.Text:SetScript("OnTextChanged", SaveString)
				eb.Text:SetText(LeaPlusLC["MiniExcludeList"])
				SaveString()

				-- Add large editbox for available addons
				local titleAbTX = LeaPlusLC:MakeTx(ExcludedButtonsPanel, "Available button names", boxWidth + 20, -72)
				titleAbTX:SetWidth(boxWidth - 14)
				titleAbTX:SetWordWrap(false)
				titleAbTX:SetJustifyH("LEFT")

				-- Add help button
				LeaPlusLC:CreateHelpButton("MinimapButtonsAvailableHelpButton", ExcludedButtonsPanel, titleAbTX, "This is a list of available addon button names.  You can use this list to copy and paste button names that you want into the editor.|n|nThis listing is automatically generated and cannot be edited.")

				local ab = CreateFrame("Frame", nil, ExcludedButtonsPanel, "BackdropTemplate")
				ab:SetSize(boxWidth, LeaPlusLC.MainPanelHeight - 180) -- 548
				ab:SetPoint("TOPLEFT", 286, -92)
				ab:SetBackdrop({
					bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
					edgeFile = "Interface\\PVPFrame\\UI-Character-PVP-Highlight",
					edgeSize = 16,
					insets = { left = 8, right = 6, top = 8, bottom = 8 },
				})
				ab:SetBackdropBorderColor(1.0, 0.85, 0.0, 0.5)
				ab:SetBackdropColor(0, 0, 0, 0.5)

				ab.scroll = CreateFrame("ScrollFrame", nil, ab, "LeaPlusEnhanceMinimapExcludeButtonsScrollFrameTemplate")
				ab.scroll:SetPoint("TOPLEFT", ab, 12, -10)
				ab.scroll:SetPoint("BOTTOMRIGHT", ab, -30, 10)
				ab.scroll:SetPanExtent(16)

				-- Create character count
				ab.scroll.CharCount = ab.scroll:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
				ab.scroll.CharCount:Hide()

				ab.Text = ab.scroll.EditBox
				ab.Text:SetWidth(boxWidth - 54) -- 494
				ab.Text:SetHeight(230)
				ab.Text:SetPoint("TOPLEFT", ab.scroll)
				ab.Text:SetPoint("BOTTOMRIGHT", ab.scroll, -12, 0)
				ab.Text:SetMaxLetters(1200)
				ab.Text:SetFontObject(GameFontNormalLarge)
				ab.Text:SetAutoFocus(false)
				ab.scroll:SetScrollChild(ab.Text)

				-- Set focus on the editbox text when clicking the editbox
				ab:SetScript("OnMouseDown", function()
					ab.Text:SetFocus()
					ab.Text:SetCursorPosition(ab.Text:GetMaxLetters())
				end)

				-- Function to make string with list of buttons
				local function MakeAddonString()
					local msg = ""
					local numAddons = C_AddOns.GetNumAddOns()
					local buttons = LibDBIconStub:GetButtonList()
					table.sort(buttons)
					for i = 1, #buttons do
						local button = LibDBIconStub:GetMinimapButton(buttons[i])
						local buttonName = buttons[i]
						msg = msg .. buttonName .. ",|n|n"
					end
					if msg ~= "" then
					else
						msg = L["No supported addons."]
					end
					ab.Text:SetText(msg)
				end

				ab.Text:HookScript("OnShow", MakeAddonString)
				ab.Text:HookScript("OnTextChanged", function(self, userInput)
					if userInput then MakeAddonString() end
				end)

				-- Hide help button
				ExcludedButtonsPanel.h:Hide()

				-- Back button handler
				ExcludedButtonsPanel.b:SetScript("OnClick", function()
					ExcludedButtonsPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page5"]:Show()
					return
				end)

				-- Reset button handler
				ExcludedButtonsPanel.r:SetScript("OnClick", function()

					-- Reset controls
					LeaPlusLC["MiniExcludeList"] = ""
					eb.Text:SetText(LeaPlusLC["MiniExcludeList"])

					-- Refresh configuration panel
					ExcludedButtonsPanel:Hide(); ExcludedButtonsPanel:Show()
					LeaPlusLC:ReloadCheck()

				end)

				-- Show configuration panal when options panel button is clicked
				LeaPlusCB["MiniExcludedButton"]:SetScript("OnClick", function()
					if IsShiftKeyDown() and IsControlKeyDown() then
						-- Preset profile
						LeaPlusLC["MiniExcludeList"] = "BugSack, Leatrix_Plus"
						LeaPlusLC:ReloadCheck()
					else
						ExcludedButtonsPanel:Show()
						SideMinimap:Hide()
					end
				end)

			end

			----------------------------------------------------------------------
			-- Minimap size
			----------------------------------------------------------------------

			if LeaPlusLC["SquareMinimap"] == "On" then

				-- Function to set minimap size
				local function SetMinimapSize()
					-- Set minimap size
					Minimap:SetSize(LeaPlusLC["MinimapSize"], LeaPlusLC["MinimapSize"])
					-- Refresh minimap
					if Minimap:GetZoom() ~= 5 then
						Minimap:SetZoom(Minimap:GetZoom() + 1)
						Minimap:SetZoom(Minimap:GetZoom() - 1)
					else
						Minimap:SetZoom(Minimap:GetZoom() - 1)
						Minimap:SetZoom(Minimap:GetZoom() + 1)
					end
					-- Refresh addon button radius
					SetButtonRad()
					-- Update slider text
					LeaPlusCB["MinimapSize"].f:SetFormattedText("%.0f%%", (LeaPlusLC["MinimapSize"] / 140) * 100)
				end

				-- Set minimap size when slider is changed and on startup
				LeaPlusCB["MinimapSize"]:HookScript("OnValueChanged", SetMinimapSize)
				SetMinimapSize()

				-- Assign file level scope (for reset and preset)
				LeaPlusLC.SetMinimapSize = SetMinimapSize

			else

				-- Square minimap is disabled so lock the size slider
				LeaPlusLC:LockItem(LeaPlusCB["MinimapSize"], true)
				LeaPlusCB["MinimapSize"].tiptext = LeaPlusCB["MinimapSize"].tiptext .. "|cff00AAFF|n|n" .. L["This slider requires 'Square minimap' to be enabled."] .. "|r"

			end

			----------------------------------------------------------------------
			-- Minimap effects
			----------------------------------------------------------------------

			do

				local square = LeaPlusLC["SquareMinimap"] == "On"
				local TAU = math.pi * 2
				local sin, cos, abs, max, floor, atan2 = math.sin, math.cos, math.abs, math.max, math.floor, math.atan2
				local DOT = "Interface\\CHARACTERFRAME\\TempPortraitAlphaMask"
				local WHITE = "Interface\\Buttons\\WHITE8X8"

				-- Function to get a point at angle a (0 is right, anticlockwise) on the minimap edge, d pixels outside it
				local function EdgeAt(a, d)
					local half = Minimap:GetWidth() / 2 + (d or 0)
					local x, y = cos(a), sin(a)
					if square then
						local m = max(abs(x), abs(y))
						return x / m * half, y / m * half
					end
					return x * half, y * half
				end

				-- Function to get a point at position t (0 to 1, evenly spaced around the edge) on the minimap edge, d pixels outside it
				local function EdgeT(t, d)
					local half = Minimap:GetWidth() / 2 + (d or 0)
					t = t % 1
					if not square then
						return cos(t * TAU) * half, sin(t * TAU) * half
					end
					local s = (t * 4 + 0.5) % 4
					local side = floor(s)
					local p = (s - side) * 2 - 1
					if side == 0 then return half, p * half
					elseif side == 1 then return -p * half, half
					elseif side == 2 then return -half, -p * half
					else return p * half, -half end
				end

				-- Function to create a texture
				local function Tex(parent, file, layer, sub, r, g, b, a)
					local t = parent:CreateTexture(nil, layer or "ARTWORK", nil, sub or 0)
					t:SetTexture(file)
					t:SetBlendMode("ADD")
					t:SetVertexColor(r or 1, g or 1, b or 1, a or 1)
					return t
				end

				-- Function to create a glow around the minimap edge
				local function MakeGlow(parent, size, r, g, b, a, spread)
					local p = {}
					if not square then
						spread = spread or 0.15
						for k = 1, 6 do
							local t = Tex(parent, DOT, "BACKGROUND", 0, r, g, b, a * 0.3)
							t:SetPoint("CENTER")
							p[k] = t
						end
						p.Layout = function()
							local w = Minimap:GetWidth()
							for k = 1, 6 do local s = w * (1 + spread * k / 6); p[k]:SetSize(s, s) end
						end
					else
						local c = 16 * size
						local function Piece(file, l, rr, tt, bb) local t = Tex(parent, "Interface\\Common\\" .. file, "BACKGROUND", 0, r, g, b, a); t:SetTexCoord(l, rr, tt, bb); return t end
						local tl = Piece("GlowBorder-Corner", 0, 1, 0, 1); tl:SetSize(c, c); tl:SetPoint("TOPLEFT", -c / 2, c / 2)
						local tr = Piece("GlowBorder-Corner", 1, 0, 0, 1); tr:SetSize(c, c); tr:SetPoint("TOPRIGHT", c / 2, c / 2)
						local bl = Piece("GlowBorder-Corner", 0, 1, 1, 0); bl:SetSize(c, c); bl:SetPoint("BOTTOMLEFT", -c / 2, -c / 2)
						local br = Piece("GlowBorder-Corner", 1, 0, 1, 0); br:SetSize(c, c); br:SetPoint("BOTTOMRIGHT", c / 2, -c / 2)
						local top = Piece("GlowBorder-Top", 0, 1, 0, 1); top:SetPoint("TOPLEFT", tl, "TOPRIGHT"); top:SetPoint("BOTTOMRIGHT", tr, "BOTTOMLEFT")
						local bottom = Piece("GlowBorder-Top", 0, 1, 1, 0); bottom:SetPoint("TOPLEFT", bl, "TOPRIGHT"); bottom:SetPoint("BOTTOMRIGHT", br, "BOTTOMLEFT")
						local left = Piece("GlowBorder-Left", 0, 1, 0, 1); left:SetPoint("TOPLEFT", tl, "BOTTOMLEFT"); left:SetPoint("BOTTOMRIGHT", bl, "TOPRIGHT")
						local right = Piece("GlowBorder-Left", 1, 0, 0, 1); right:SetPoint("TOPLEFT", tr, "BOTTOMLEFT"); right:SetPoint("BOTTOMRIGHT", br, "TOPRIGHT")
						-- Pieces in order around the edge (used for colour flow)
						p = {right, tr, top, tl, left, bl, bottom, br}
					end
					return p
				end

				-- Function to create an animation group (added to the effect so it starts and stops with it)
				local function Group(e, region, looping)
					local ag = region:CreateAnimationGroup()
					ag:SetLooping(looping or "REPEAT")
					tinsert(e.groups, ag)
					return ag
				end

				-- Function to create an animation
				local function Anim(ag, kind, duration, order, delay)
					local an = ag:CreateAnimation(kind)
					an:SetDuration(duration)
					an:SetOrder(order or 1)
					if delay then an:SetStartDelay(delay) end
					return an
				end

				-- Function to convert a hue (0 to 1) to a soft colour
				local function Hue(h)
					h = (h % 1) * 6
					local i, f = floor(h), h - floor(h)
					local r, g, b
					if i == 0 then r, g, b = 1, f, 0 elseif i == 1 then r, g, b = 1 - f, 1, 0 elseif i == 2 then r, g, b = 0, 1, f
					elseif i == 3 then r, g, b = 0, 1 - f, 1 elseif i == 4 then r, g, b = f, 0, 1 else r, g, b = 1, 0, 1 - f end
					return 0.3 + 0.7 * r, 0.3 + 0.7 * g, 0.3 + 0.7 * b
				end

				-- Function to get the outward direction (angle) at position t on the edge
				local function EdgeNormal(t)
					if not square then return (t % 1) * TAU end
					local x, y = EdgeT(t, 0)
					if abs(abs(x) - abs(y)) < 3 then return atan2(y, x) end -- Corner
					if abs(x) > abs(y) then return x > 0 and 0 or math.pi end
					return y > 0 and TAU / 4 or -TAU / 4
				end

				-- Helpers passed to each effect
				local helpers = {square = square, Tex = Tex, Anim = Anim, Group = Group, MakeGlow = MakeGlow, EdgeAt = EdgeAt, EdgeT = EdgeT, EdgeNormal = EdgeNormal, Hue = Hue}

				-- Function to get an effect (the effects are only loaded the first time an effect other than None is selected)
				local effects, effectList
				local function GetEffect(index)
					if index == 1 then return end -- None
					if not effectList then
						effectList = Leatrix_Plus.LoadMinimapEffects()
						effects = {}
					end
					if not effects[index] and effectList[index] then
						local e = {groups = {}, build = effectList[index], gen = 0}
						-- Front layer (above the minimap) and back layer (behind the minimap)
						e.frame = CreateFrame("Frame", nil, Minimap); e.frame:SetAllPoints(); e.frame:SetFrameLevel(Minimap:GetFrameLevel() + 2); e.frame:Hide()
						e.back = CreateFrame("Frame", nil, Minimap); e.back:SetAllPoints(); e.back:SetFrameLevel(max(Minimap:GetFrameLevel() - 1, 0)); e.back:Hide()
						effects[index] = e
					end
					return effects[index]
				end

				-- Function to start an effect (built the first time it is selected)
				local function StartEffect(e)
					if not e.built then e.build(e, helpers); e.built = true end
					if e.Layout then e.Layout() end
					e.frame:Show(); e.back:Show()
					for i = 1, #e.groups do e.groups[i]:Play() end
					if e.OnStart then e.OnStart() end
				end

				-- Function to stop an effect
				local function StopEffect(e)
					e.gen = e.gen + 1
					if e.OnStop then e.OnStop() end
					for i = 1, #e.groups do e.groups[i]:Stop() end
					e.frame:Hide(); e.back:Hide()
				end

				-- Function to show the selected effect (does nothing if the selected effect is already showing)
				local current, currentIndex = nil, 1
				local function SetMinimapEffect()
					local index = LeaPlusLC["MinimapEffect"]
					if index == currentIndex then return end
					currentIndex = index
					if current then StopEffect(current); current = nil end
					local e = GetEffect(index)
					if e then StartEffect(e); current = e end
				end

				-- Set effect when the dropdown menu is closed and on startup
				LeaPlusCB["MinimapEffect"]:RegisterCallback("OnMenuClose", SetMinimapEffect)
				SetMinimapEffect()

				-- Rebuild the effect positions if the minimap size changes
				Minimap:HookScript("OnSizeChanged", function()
					if current then StopEffect(current); StartEffect(current) end
				end)

				-- Assign file level scope (used in reset)
				LeaPlusLC.SetMinimapEffect = SetMinimapEffect

			end

			----------------------------------------------------------------------
			-- Minimap button bag
			----------------------------------------------------------------------

			if LeaPlusLC["MinimapButtonBag"] == "On" then

				-- Lock out hide minimap buttons
				LeaPlusLC:LockItem(LeaPlusCB["HideMiniAddonButtons"], true)
				LeaPlusCB["HideMiniAddonButtons"].tiptext = LeaPlusCB["HideMiniAddonButtons"].tiptext .. "|n|n|cff00AAFF" .. L["Cannot be used with Minimap button bag."]

				-- Create button frame (parenting to cluster ensures bFrame scales correctly)
				local bFrame = CreateFrame("FRAME", nil, MinimapCluster, "BackdropTemplate")
				bFrame:ClearAllPoints()
				bFrame:SetPoint("TOPLEFT", Minimap, "TOPRIGHT", 4, 4)
				bFrame:Hide()
				bFrame:SetClampedToScreen(true)
				bFrame:SetFrameLevel(8)

				LeaPlusLC.bFrame = bFrame -- Used in LibDBIcon callback
				_G["LeaPlusGlobalMinimapCombinedButtonFrame"] = bFrame -- For third party addons

				-- Hide button frame automatically
				local ButtonFrameTicker
				bFrame:HookScript("OnShow", function()
					if ButtonFrameTicker then ButtonFrameTicker:Cancel() end
					ButtonFrameTicker = C_Timer.NewTicker(2, function()
						if ItemRackMenuFrame and ItemRackMenuFrame:IsShown() and ItemRackMenuFrame:IsMouseOver() then return end
						if not bFrame:IsMouseOver() and not Minimap:IsMouseOver() then
							bFrame:Hide()
							if ButtonFrameTicker then ButtonFrameTicker:Cancel() end
						end
					end, 15)
				end)

				-- Match scale with minimap
				if LeaPlusLC["SquareMinimap"] == "On" then
					bFrame:SetScale(MinimapCluster.BorderTop:GetScale() * 0.75)
				else
					bFrame:SetScale(MinimapCluster.BorderTop:GetScale())
				end

				-- Function to set button frame scale
				local function SetButtonFrameScale()
					if LeaPlusLC["SquareMinimap"] == "On" then
						bFrame:SetScale(MinimapCluster.BorderTop:GetScale() * 0.75)
					else
						bFrame:SetScale(MinimapCluster.BorderTop:GetScale())
					end
				end

				hooksecurefunc(MinimapCluster.BorderTop, "SetScale", SetButtonFrameScale)

				-- Position LibDBIcon tooltips when shown
				LibDBIconTooltip:HookScript("OnShow", function()
					GameTooltip:Hide()
					LibDBIconTooltip:ClearAllPoints()
					if bFrame:GetPoint() == "BOTTOMLEFT" then
						LibDBIconTooltip:SetPoint("TOPLEFT", Minimap, "BOTTOMLEFT", 0, -6)
					else
						LibDBIconTooltip:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", 0, -6)
					end
				end)

				-- Function to position GameTooltip below the minimap
				local function SetButtonTooltip()
					GameTooltip:ClearAllPoints()
					if bFrame:GetPoint() == "BOTTOMLEFT" then
						GameTooltip:SetPoint("TOPLEFT", Minimap, "BOTTOMLEFT", 0, -6)
					else
						GameTooltip:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", 0, -6)
					end
				end

				LeaPlusLC.SetButtonTooltip = SetButtonTooltip -- Used in LibDBIcon callback

				-- Hide existing LibDBIcon icons
				local buttons = LibDBIconStub:GetButtonList()
				for i = 1, #buttons do
					local button = LibDBIconStub:GetMinimapButton(buttons[i])
					local buttonName = strlower(buttons[i])
					if not strfind(strlower(LeaPlusDB["MiniExcludeList"]), buttonName) then
						button:Hide()
						button:SetScript("OnShow", function() if not bFrame:IsShown() then button:Hide() end end)
						-- Create background texture
						local bFrameBg = button:CreateTexture(nil, "BACKGROUND")
						bFrameBg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
						bFrameBg:SetPoint("CENTER")
						bFrameBg:SetSize(30, 30)
						bFrameBg:SetVertexColor(0, 0, 0, 0.5)
					elseif strfind(strlower(LeaPlusDB["MiniExcludeList"]), buttonName) and LeaPlusLC["SquareMinimap"] == "On" then
						button:SetScale(0.75)
					end
					-- Move GameTooltip to below the minimap in case the button uses it
					button:HookScript("OnEnter", SetButtonTooltip)
					-- Special case for MoveAny because it doesn't have button.db
					if buttonName == "moveany" then
						button.db = button.db or {}
						if not button.db.hide then button.db.hide = false end
					end
				end

				-- Hide new LibDBIcon icons
				-- LibDBIcon_IconCreated: Done in LibDBIcon callback function

				-- Toggle button frame
				Minimap:SetScript("OnMouseUp", function(frame, button)
					if button == "RightButton" then
						if bFrame:IsShown() then
							bFrame:Hide()
						else bFrame:Show()
							-- Position button frame
							local side
							local m = Minimap:GetCenter()
							local b = Minimap:GetEffectiveScale()
							local w = GetScreenWidth()
							local s = UIParent:GetEffectiveScale()
							bFrame:ClearAllPoints()
							if m * b > (w * s / 2) then
								side = "Right"
								bFrame:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMLEFT", -10, -0)
							else
								side = "Left"
								bFrame:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMRIGHT", 10, 0)
							end
							-- Show button frame
							local x, y, row, col = 0, 0, 0, 0
							local buttons = LibDBIconStub:GetButtonList()
							-- Sort the button table
							table.sort(buttons, function(a, b)
								if string.find(a, "LeaPlusCustomIcon_") then
									a = string.gsub(a, "LeaPlusCustomIcon_", "")
								end
								if string.find(b, "LeaPlusCustomIcon_") then
									b = string.gsub(b, "LeaPlusCustomIcon_", "")
								end
								return a:lower() < b:lower()
							end)
							-- Calculate buttons per row
							local buttonsPerRow
							local totalButtons = #buttons
								if totalButtons > 36 then buttonsPerRow = 10
							elseif totalButtons > 32 then buttonsPerRow = 9
							elseif totalButtons > 28 then buttonsPerRow = 8
							elseif totalButtons > 24 then buttonsPerRow = 7
							elseif totalButtons > 20 then buttonsPerRow = 6
							elseif totalButtons > 16 then buttonsPerRow = 5
							elseif totalButtons > 12 then buttonsPerRow = 4
							elseif totalButtons > 8 then buttonsPerRow = 3
							elseif totalButtons > 4 then buttonsPerRow = 2
							else
								buttonsPerRow = 1
							end
							-- Build button grid
							for i = 1, totalButtons do
								local buttonName = strlower(buttons[i])
								if not strfind(strlower(LeaPlusDB["MiniExcludeList"]), buttonName) then
									local button = LibDBIconStub:GetMinimapButton(buttons[i])
									if button.db then
										if buttonName == "armory" then button.db.hide = false end -- Armory addon sets hidden to true
										if not button.db.hide then
											button:SetParent(bFrame)
											button:ClearAllPoints()
											if side == "Left" then
												-- Minimap is on left side of screen
												button:SetPoint("TOPLEFT", bFrame, "TOPLEFT", x, y)
												col = col + 1; if col >= buttonsPerRow then col = 0; row = row + 1; x = 0; y = y - 30 else x = x + 30 end
											else
												-- Minimap is on right side of screen (changed from TOPRIGHT to TOPLEFT and x - 30 to x + 30 to make sorting work)
												button:SetPoint("TOPLEFT", bFrame, "TOPLEFT", x, y)
												col = col + 1; if col >= buttonsPerRow then col = 0; row = row + 1; x = 0; y = y - 30 else x = x + 30 end
											end
											if totalButtons <= buttonsPerRow then
												bFrame:SetWidth(totalButtons * 30)
											else
												bFrame:SetWidth(buttonsPerRow * 30)
											end
											local void, void, void, void, e = button:GetPoint()
											bFrame:SetHeight(0 - e + 30)
											LibDBIconStub:Show(buttons[i])
										end
									end
								end
							end
						end
					else
						Minimap_OnClick(frame, button)
					end
				end)

			end

			----------------------------------------------------------------------
			-- Square minimap
			----------------------------------------------------------------------

			if LeaPlusLC["SquareMinimap"] == "On" then

				-- Set minimap shape
				_G.GetMinimapShape = function() return "SQUARE" end

				-- Create black border around map
				local miniBorder = CreateFrame("Frame", nil, Minimap, "BackdropTemplate")
				miniBorder:SetAlpha(0.8)

				-- Adjust border width using slider control
				local function SetMinimapBorderWidth()
					miniBorder:ClearAllPoints()
					miniBorder:SetPoint("TOPLEFT", -LeaPlusLC["MinimapBorderWidth"], LeaPlusLC["MinimapBorderWidth"])
					miniBorder:SetPoint("BOTTOMRIGHT", LeaPlusLC["MinimapBorderWidth"], -LeaPlusLC["MinimapBorderWidth"])
					miniBorder:SetBackdrop({
						edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
						edgeSize = LeaPlusLC["MinimapBorderWidth"],
					})
				end

				-- Set border width when slider is changed and on startup
				LeaPlusCB["MinimapBorderWidth"]:HookScript("OnValueChanged", SetMinimapBorderWidth)
				SetMinimapBorderWidth()

				-- Hide the default border
				MinimapBorder:Hide()

				-- Mask texture
				Minimap:SetMaskTexture('Interface\\ChatFrame\\ChatFrameBackground')

				-- Keep the square look (rotation, FarmHud and other addons can change the mask or show the rings)
				local SQUARE_MASK = "Interface\\ChatFrame\\ChatFrameBackground"
				local applyingMask = false

				-- Hide the compass rings and apply the square mask
				local function ApplySquareLook()
					MinimapCompassTexture:Hide()
					if MinimapCompassTextureUnderlay then MinimapCompassTextureUnderlay:Hide() end
					applyingMask = true
					Minimap:SetMaskTexture(SQUARE_MASK)
					applyingMask = false
				end

				-- Apply the square look now and again after Blizzard's own code has finished running
				local function ReapplySquare()
					ApplySquareLook()
					C_Timer.After(0, ApplySquareLook)
				end

				-- Put the square mask back if anything changes it
				hooksecurefunc(Minimap, "SetMaskTexture", function()
					if not applyingMask then ApplySquareLook() end
				end)

				-- Keep the rings hidden if anything shows them
				hooksecurefunc(MinimapCompassTexture, "Show", ApplySquareLook)
				if MinimapCompassTextureUnderlay then
					hooksecurefunc(MinimapCompassTextureUnderlay, "Show", ApplySquareLook)
				end

				-- Reapply the square look on loading screens and when minimap rotation is toggled
				local squareWatcher = CreateFrame("Frame")
				squareWatcher:RegisterEvent("CVAR_UPDATE")
				squareWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
				squareWatcher:SetScript("OnEvent", function(self, event, cvar)
					if event == "PLAYER_ENTERING_WORLD" or (cvar and strlower(cvar) == "rotateminimap") then
						ReapplySquare()
					end
				end)
				ReapplySquare()

				-- Hide the North tag
				MinimapNorthTag:Hide()

				-- Tracking button (only visible when needed)
				C_Timer.After(0.1, function()
					MiniMapTracking:SetScale(0.60)
					miniFrame.ClearAllPoints(MiniMapTracking)
					MiniMapTracking:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -24, -24) -- SetLookingForGroupUIAvailable
				end)

				-- Mail button
				MiniMapMailFrame:SetScale(0.75)
				miniFrame.ClearAllPoints(MiniMapMailFrame)
				MiniMapMailFrame:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -19, -53)

				-- Battleground queue button
				MiniMapBattlefieldFrame:SetScale(0.75)
				miniFrame.ClearAllPoints(MiniMapBattlefieldFrame)
				MiniMapBattlefieldFrame:SetPoint("TOP", MiniMapMailFrame, "BOTTOM", 0, 0)

				-- Looking For Group button
				EventUtil.ContinueOnAddOnLoaded("Blizzard_GroupFinder_VanillaStyle", function()
					if LFGMinimapFrame then
						LFGMinimapFrame:SetScale(0.75)
						LFGMinimapFrame:ClearAllPoints()
						LFGMinimapFrame:SetPoint("TOP", MiniMapBattlefieldFrame, "BOTTOM", 0, 0)
					end
				end)

				-- Zoom in button
				MinimapZoomIn:SetScale(0.75)
				miniFrame.ClearAllPoints(MinimapZoomIn)
				MinimapZoomIn:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", 19, -120)

				-- Zoom out button
				MinimapZoomOut:SetScale(0.75)
				miniFrame.ClearAllPoints(MinimapZoomOut)
				MinimapZoomOut:SetPoint("TOP", MinimapZoomIn, "BOTTOM", 0, 0)

				-- Day and night indicator
				miniFrame.ClearAllPoints(GameTimeFrame)
				GameTimeFrame:SetPoint("BOTTOM", MinimapZoomIn, "TOP", 0, 1)
				GameTimeFrame:SetParent(MinimapBackdrop)
				GameTimeFrame:SetSize(23, 23)

				-- Debug buttons
				local LeaPlusMiniMapDebug = nil
				if LeaPlusMiniMapDebug then
					C_Timer.After(1, function()
						MiniMapMailFrame:Show()
						MiniMapBattlefieldFrame:Show()
						GameTimeFrame:Show()
						if LFGMinimapFrame then
							LFGMinimapFrame:Show()
						end
						MiniMapTracking:Show()
					end)
				end

				-- Rescale addon buttons if minimap button bag is disabled
				if LeaPlusLC["MinimapButtonBag"] == "Off" then
					-- Scale existing buttons
					local buttons = LibDBIconStub:GetButtonList()
					for i = 1, #buttons do
						local button = LibDBIconStub:GetMinimapButton(buttons[i])
						button:SetScale(0.75)
					end
					-- Scale new buttons
					-- LibDBIcon_IconCreated: Done in LiBDBIcon callback function
				end

				-- Refresh buttons
				C_Timer.After(0.1, SetButtonRad)

			else

				-- Square minimap is disabled so use round shape
				_G.GetMinimapShape = function() return "ROUND" end
				Minimap:SetMaskTexture([[Interface\CharacterFrame\TempPortraitAlphaMask]])

				-- Square minimap is disabled so disable border width slider
				LeaPlusLC:LockItem(LeaPlusCB["MinimapBorderWidth"], true)
				LeaPlusCB["MinimapBorderWidth"].tiptext = LeaPlusCB["MinimapBorderWidth"].tiptext .. "|cff00AAFF|n|n" .. L["This slider requires 'Square minimap' to be enabled."] .. "|r"

			end

			----------------------------------------------------------------------
			-- Hide day and night indicator
			----------------------------------------------------------------------

			if LeaPlusLC["HideMiniDayNight"] == "On" then
				GameTimeFrame:Hide()
			end

			----------------------------------------------------------------------
			-- Replace non-standard buttons
			----------------------------------------------------------------------

			-- Replace non-standard buttons for addons that don't use the standard LibDBIcon library
			do

				-- Make LibDBIcon buttons for addons that don't use LibDBIcon
				local CustomAddonTable = {}
				LeaPlusDB["CustomAddonButtons"] = LeaPlusDB["CustomAddonButtons"] or {}

				-- Function to create a LibDBIcon button
				local function CreateBadButton(name)

					-- Get non-standard button texture
					local finalTex = "Interface\\HELPFRAME\\HelpIcon-KnowledgeBase"

					if _G[name .. "Icon"] then
						if _G[name .. "Icon"]:GetObjectType() == "Texture" then
							local gTex = _G[name .. "Icon"]:GetTexture()
							if gTex then
								finalTex = gTex
							end
						end
					else
						for i = 1, select('#', _G[name]:GetRegions()) do
							local region = select(i, _G[name]:GetRegions())
							if region.GetTexture then
								local x, y = region:GetSize()
								if x and x < 30 then
									finalTex = region:GetTexture()
								end
							end
						end
					end

					if not finalTex then finalTex = "Interface\\HELPFRAME\\HelpIcon-KnowledgeBase" end

					-- Function to anchor the tooltip to the custom button or the minimap
					local function ReanchorTooltip(tip, myButton)
						tip:ClearAllPoints()
						if LeaPlusLC["MinimapButtonBag"] == "On" then
							if LeaPlusLC.bFrame and LeaPlusLC.bFrame:GetPoint() == "BOTTOMLEFT" then
								tip:SetPoint("TOPLEFT", Minimap, "BOTTOMLEFT", 0, -6)
							else
								tip:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", 0, -6)
							end
						else
							if Minimap:GetCenter() * Minimap:GetEffectiveScale() > (GetScreenWidth() * UIParent:GetEffectiveScale() / 2) then
								tip:SetPoint("TOPRIGHT", myButton, "BOTTOMRIGHT", 0, -6)
							else
								tip:SetPoint("TOPLEFT", myButton, "BOTTOMLEFT", 0, -6)
							end
						end
					end

					local zeroButton = LibStub("LibDataBroker-1.1"):NewDataObject("LeaPlusCustomIcon_" .. name, {
						type = "data source",
						text = name,
						icon = finalTex,
						OnClick = function(self, btn)
							if _G[name] then
								if string.find(name, "LibDBIcon") then
									-- It's a fake LibDBIcon
									local mouseUp = _G[name]:GetScript("OnMouseUp")
									if mouseUp then
										mouseUp(self, btn)
									end
								else
									-- It's a genuine LibDBIcon
									local clickUp = _G[name]:GetScript("OnClick")
									if clickUp then
										_G[name]:Click(btn)
									end
								end
							end
						end,
					})
					LeaPlusDB["CustomAddonButtons"][name] = LeaPlusDB["CustomAddonButtons"][name] or {}
					LeaPlusDB["CustomAddonButtons"][name].hide = false
					CustomAddonTable[name] = name
					local icon = LibStub("LibDBIcon-1.0", true)
					icon:Register("LeaPlusCustomIcon_" .. name, zeroButton, LeaPlusDB["CustomAddonButtons"][name])
					-- Custom buttons
					if name == "AllTheThings-Minimap" then
						-- AllTheThings
						local myButton = LibStub("LibDBIcon-1.0"):GetMinimapButton("LeaPlusCustomIcon_" .. name)
						myButton.icon:SetTexture("Interface\\AddOns\\AllTheThings\\assets\\logo_tiny")
						myButton:HookScript("OnEnter", function()
							_G[name]:GetScript("OnEnter")(_G[name], true)
							ReanchorTooltip(GameTooltip, myButton)
						end)
						myButton:HookScript("OnLeave", function()
							_G[name]:GetScript("OnLeave")()
						end)
					elseif name == "AltoholicMinimapButton" then
						-- Altoholic
						local myButton = LibStub("LibDBIcon-1.0"):GetMinimapButton("LeaPlusCustomIcon_" .. name)
						myButton.icon:SetTexture("Interface\\Icons\\INV_Drink_13")
						myButton:HookScript("OnEnter", function()
							_G[name]:GetScript("OnEnter")(_G[name], true)
							ReanchorTooltip(AltoTooltip, myButton)
						end)
						myButton:HookScript("OnLeave", function()
							_G[name]:GetScript("OnLeave")()
						end)
					elseif name == "Narci_MinimapButton" then
						-- Narcissus
						local myButton = LibStub("LibDBIcon-1.0"):GetMinimapButton("LeaPlusCustomIcon_" .. name)
						myButton.icon:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Minimap\\LOGO-Dragonflight")
						myButton:HookScript("OnEnter", function()
							_G[name]:GetScript("OnEnter")(_G[name], true)
						end)
						hooksecurefunc(myButton.icon, "UpdateCoord", function()
							myButton.icon:SetTexCoord(0, 0.25, 0.75, 1)
						end)
						myButton.icon:SetTexCoord(0, 0.25, 0.75, 1)
					elseif name == "WIM3MinimapButton" then
						-- WIM
						local myButton = LibStub("LibDBIcon-1.0"):GetMinimapButton("LeaPlusCustomIcon_" .. name)
						myButton:HookScript("OnEnter", function()
							_G[name]:GetScript("OnEnter")(_G[name], true)
							GameTooltip:SetOwner(myButton, "ANCHOR_TOP")
							GameTooltip:AddLine(name)
							GameTooltip:Show()
							ReanchorTooltip(GameTooltip, myButton)
						end)
						myButton:HookScript("OnLeave", function()
							_G[name]:GetScript("OnLeave")()
							GameTooltip:Hide()
						end)
					elseif name == "ZygorGuidesViewerMapIcon" then
						-- Zygor (uses LibDBIcon10_LeaPlusCustomIcon_ZygorGuidesViewerMapIcon)
						local myButton = LibStub("LibDBIcon-1.0"):GetMinimapButton("LeaPlusCustomIcon_" .. name)
						myButton.icon:SetTexture("Interface\\AddOns\\ZygorGuidesViewerClassic\\Skins\\minimap-icon.tga")
						hooksecurefunc(myButton.icon, "UpdateCoord", function()
							myButton.icon:SetTexCoord(0, 0.5, 0, 0.25)
						end)
						myButton.icon:SetTexCoord(0, 0.5, 0, 0.25)
						myButton:HookScript("OnEnter", function()
							_G[name]:GetScript("OnEnter")(_G[name], true)
							ReanchorTooltip(GameTooltip, myButton)
						end)
						myButton:HookScript("OnLeave", function()
							GameTooltip:Hide()
						end)
						if ZGV_Notification_Entry_Template_Mixin then
							-- Fix notification system entry height
							hooksecurefunc(ZGV_Notification_Entry_Template_Mixin, "UpdateHeight", function(self)
								self:Show()
								local height = 46
								if ZGV and ZGV.db and ZGV.db.profile and ZGV.db.profile.nc_size and ZGV.db.profile.nc_size == 1 then height = 36 end
								height = height + (self.time:IsVisible() and self.time:GetStringHeight()+0 or 0)
								height = height + (self.title:IsVisible() and self.title:GetStringHeight()+3 or 0)
								height = height + (self.text:IsVisible() and self.text:GetStringHeight()+3 or 0)
								height = height + (self.SpecialButton and self.SpecialButton:IsVisible() and self.SpecialButton:GetHeight()+8 or 0)
								if (self.single or self.special) then height = max(height,25) end
								self:SetHeight(height)
								self:Hide()
							end)
						end
					elseif name == "TomCats-MinimapButton"				-- TomCat's Tours
						or name == "LibDBIcon10_MethodRaidTools"		-- Method Raid Tools
						or name == "Lib_GPI_Minimap_LFGBulletinBoard"	-- LFG Bulletin Board
						or name == "wlMinimapButton"					-- Wowhead Looter (part of Wowhead client)
						then
						local myButton = LibStub("LibDBIcon-1.0"):GetMinimapButton("LeaPlusCustomIcon_" .. name)
						myButton:HookScript("OnEnter", function()
							_G[name]:GetScript("OnEnter")(_G[name], true)
							ReanchorTooltip(GameTooltip, myButton)
						end)
						myButton:HookScript("OnLeave", function()
							GameTooltip:Hide()
						end)
					else
						-- Unknown custom buttons
						local myButton = LibStub("LibDBIcon-1.0"):GetMinimapButton("LeaPlusCustomIcon_" .. name)
						myButton:HookScript("OnEnter", function()
							GameTooltip:SetOwner(myButton, "ANCHOR_TOP")
							GameTooltip:AddLine(name)
							GameTooltip:AddLine(L["This is a custom button.  Please ask the addon author to use the standard LibDBIcon library instead."], 1, 1, 1, true)
							GameTooltip:Show()
							ReanchorTooltip(GameTooltip, myButton)
						end)
						myButton:HookScript("OnLeave", function()
							GameTooltip:Hide()
						end)
					end
				end

				-- Create LibDBIcon buttons for these addons that have LibDBIcon prefixes
				local customButtonTable = {
					"LibDBIcon10_MethodRaidTools", -- Method Raid Tools
				}

				-- Do not create LibDBIcon buttons for these special case buttons
				local BypassButtonTable = {
					"SexyMapZoneTextButton", -- SexyMap
				}

				-- Some buttons have less than 3 regions.  These need to be manually defined below.
				local LowRegionCountButtons = {
					"AllTheThings-Minimap", -- AllTheThings
				}

				-- Function to loop through minimap children to find non-standard addon buttons
				local function MakeButtons()
					local temp = {Minimap:GetChildren()}
					for i = 1, #temp do
						if temp[i] then
							local btn = temp[i]
							local name = btn:GetName()
							local btype = btn:GetObjectType()
							if name and btype == "Button" and not CustomAddonTable[name] and (btn:GetNumRegions() >= 3 or tContains(LowRegionCountButtons, name)) and not issecurevariable(name) and btn:IsShown() then
								if not strfind(strlower(LeaPlusDB["MiniExcludeList"]), strlower("##" .. name)) then
									if not string.find(name, "LibDBIcon") and not tContains(BypassButtonTable, name) or tContains(customButtonTable, name) then
										if not strfind(name, "^QuestieFrame") then -- Don't make buttons for Questie icons
											CreateBadButton(name)
											btn:Hide()
											btn:SetScript("OnShow", function() btn:Hide() end)
										end
									end
								end
							end
						end
					end
				end

				-- Run the function a few times on startup
				C_Timer.NewTicker(2, MakeButtons, 8)
				C_Timer.After(0.1, MakeButtons)

			end

			----------------------------------------------------------------------
			-- Hide addon buttons
			----------------------------------------------------------------------

			if LeaPlusLC["MinimapButtonBag"] == "Off" then

				-- Function to set button state
				local function SetHideButtons()
					if LeaPlusLC["HideMiniAddonButtons"] == "On" then
						-- Hide existing buttons
						local buttons = LibDBIconStub:GetButtonList()
						for i = 1, #buttons do
							local buttonName = strlower(buttons[i])
							if not strfind(strlower(LeaPlusDB["MiniExcludeList"]), buttonName) then
								LibDBIconStub:ShowOnEnter(buttons[i], true)
							end
						end
						-- Hide new buttons
						-- LibDBIcon_IconCreated: Done in LibDBIcon callback function
					else
						-- Show existing buttons
						local buttons = LibDBIconStub:GetButtonList()
						for i = 1, #buttons do
							local buttonName = strlower(buttons[i])
							if not strfind(strlower(LeaPlusDB["MiniExcludeList"]), buttonName) then
								LibDBIconStub:ShowOnEnter(buttons[i], false)
							end
						end
						-- Show new buttons
						-- LibDBIcon_IconCreated: Done in LibDBIcon callback function
					end
				end

				-- Assign file level scope (it's used in reset and preset)
				LeaPlusLC.SetHideButtons = SetHideButtons

				-- Set buttons when option is clicked and on startup
				LeaPlusCB["HideMiniAddonButtons"]:HookScript("OnClick", SetHideButtons)
				SetHideButtons()

			end

			----------------------------------------------------------------------
			-- Unlock the minimap
			----------------------------------------------------------------------

			MinimapCluster:SetClampedToScreen(false)

			if LeaPlusLC["SquareMinimap"] == "On" then
				Minimap:SetClampRectInsets(-3, 3, 3, -3)
			else
				Minimap:SetClampRectInsets(-2, 0, 2, -2)
			end

			----------------------------------------------------------------------
			-- Hide the zone text bar and time of day button
			----------------------------------------------------------------------

			-- Hide zone text
			if LeaPlusDB["SquareMinimap"] == "On" then
				MinimapCluster.BorderTop:SetTexture("")
				MinimapToggleButton:SetNormalTexture(0)
				MinimapToggleButton:SetPushedTexture(0)
				MinimapToggleButton:SetHighlightTexture(0)
				MinimapToggleButton:EnableMouse(false)
				if LeaPlusLC["HideMiniZoneText"] == "On" then
					MinimapZoneTextButton:Hide()
				else
					MinimapZoneTextButton:ClearAllPoints()
					MinimapZoneTextButton:SetParent(Minimap)
					MinimapZoneTextButton:SetPoint("TOP", Minimap, "TOP", 0, -2)
					MinimapZoneTextButton:SetFrameLevel(100)
				end
			else
				if LeaPlusLC["HideMiniZoneText"] == "On" then
					MinimapCluster.BorderTop:SetTexture("")
					MinimapToggleButton:SetNormalTexture(0)
					MinimapToggleButton:SetPushedTexture(0)
					MinimapToggleButton:SetHighlightTexture(0)
					MinimapToggleButton:EnableMouse(false)
					MinimapZoneTextButton:Hide()
				end
			end

			----------------------------------------------------------------------
			-- Hide the zoom buttons
			----------------------------------------------------------------------

			-- Function to toggle the zoom buttons
			local function ToggleZoomButtons()
				if LeaPlusLC["HideMiniZoomBtns"] == "On" then
					MinimapZoomIn:Hide()
					MinimapZoomOut:Hide()
				else
					MinimapZoomIn:Show()
					MinimapZoomOut:Show()
				end
			end

			-- Set the zoom buttons when the option is clicked and on startup
			LeaPlusCB["HideMiniZoomBtns"]:HookScript("OnClick", ToggleZoomButtons)
			ToggleZoomButtons()

			----------------------------------------------------------------------
			-- Hide the clock
			----------------------------------------------------------------------

			-- Function to show or hide the clock
			EventUtil.ContinueOnAddOnLoaded("Blizzard_TimeManager",function()
				if LeaPlusLC["SquareMinimap"] == "On" then
					local regions = {TimeManagerClockButton:GetRegions()}
					regions[1]:Hide()
					TimeManagerClockButton:ClearAllPoints()
					TimeManagerClockButton:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", -15, -8)
					TimeManagerClockButton:SetHitRectInsets(15, 10, 5, 8)
					TimeManagerClockButton:SetFrameLevel(100)
					local timeBG = TimeManagerClockButton:CreateTexture(nil, "BACKGROUND")
					timeBG:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
					timeBG:SetPoint("TOPLEFT", 15, -5)
					timeBG:SetPoint("BOTTOMRIGHT", -10, 8)
					timeBG:SetVertexColor(0, 0, 0, 0.6)
				end
				-- Hide clock (intentionally not using cvar)
				local function SetTimeClockButtonFunc()
					if LeaPlusLC["HideMiniClock"] == "On" then
						TimeManagerClockButton:Hide()
					else
						TimeManagerClockButton:Show()
					end
				end
				SetTimeClockButtonFunc()
				hooksecurefunc("TimeManagerClockButton_UpdateShowClockSetting", SetTimeClockButtonFunc)
			end)

			-- Function to toggle clock
			local function SetMiniClock()
				if LeaPlusLC["HideMiniClock"] == "On" then
					TimeManagerClockButton:Hide()
				else
					TimeManagerClockButton:Show()
				end
			end

			-- Update the clock when the checkbox is clicked
			LeaPlusCB["HideMiniClock"]:HookScript("OnClick", SetMiniClock)

			----------------------------------------------------------------------
			-- Enable mousewheel zoom
			----------------------------------------------------------------------

			-- Function to control mousewheel zoom
			local function MiniZoom(self, arg1)
				if arg1 > 0 and self:GetZoom() < 5 then
					-- Zoom in
					MinimapZoomOut:Enable()
					self:SetZoom(self:GetZoom() + 1)
					if(Minimap:GetZoom() == (Minimap:GetZoomLevels() - 1)) then
						MinimapZoomIn:Disable()
					end
				elseif arg1 < 0 and self:GetZoom() > 0 then
					-- Zoom out
					MinimapZoomIn:Enable()
					self:SetZoom(self:GetZoom() - 1)
					if(Minimap:GetZoom() == 0) then
						MinimapZoomOut:Disable()
					end
				end
			end

			-- Enable mousewheel zoom
			Minimap:EnableMouseWheel(true)
			Minimap:SetScript("OnMouseWheel", MiniZoom)

			----------------------------------------------------------------------
			-- Buttons
			----------------------------------------------------------------------

			-- Hide help button
			SideMinimap.h:Hide()

			-- Back button handler
			SideMinimap.b:SetScript("OnClick", function()
				SideMinimap:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page5"]:Show()
				return
			end)

			-- Reset button handler
			SideMinimap.r.tiptext = SideMinimap.r.tiptext .. "|n|n" .. L["Note that this will not reset settings that require a UI reload."]
			SideMinimap.r:HookScript("OnClick", function()
				LeaPlusLC["MinimapEffect"] = 1; LeaPlusLC.SetMinimapEffect()
				LeaPlusLC["HideMiniZoomBtns"] = "Off"; ToggleZoomButtons()
				LeaPlusLC["HideMiniClock"] = "Off"; SetMiniClock()
				LeaPlusLC["HideMiniAddonButtons"] = "On"; if LeaPlusLC.SetHideButtons then LeaPlusLC.SetHideButtons() end
				LeaPlusLC["MinimapSize"] = 140; if LeaPlusLC.SetMinimapSize then LeaPlusLC:SetMinimapSize() end
				LeaPlusLC["MinimapBorderWidth"] = 3
				-- Refresh panel
				SideMinimap:Hide(); SideMinimap:Show()
			end)

			-- Configuration button handler
			LeaPlusCB["ModMinimapBtn"]:HookScript("OnClick", function()
				if LeaPlusLC:PlayerInCombat() then
					return
				else
					if IsShiftKeyDown() and IsControlKeyDown() then
						-- Preset profile
						LeaPlusLC["MinimapEffect"] = 3; LeaPlusLC.SetMinimapEffect()
						LeaPlusLC["HideMiniZoomBtns"] = "Off"; ToggleZoomButtons()
						LeaPlusLC["HideMiniClock"] = "Off"; SetMiniClock()
						LeaPlusLC["HideMiniAddonButtons"] = "On"; if LeaPlusLC.SetHideButtons then LeaPlusLC.SetHideButtons() end
						LeaPlusLC["MinimapSize"] = 180; if LeaPlusLC.SetMinimapSize then LeaPlusLC:SetMinimapSize() end
						LeaPlusLC["MinimapBorderWidth"] = 3
						LeaPlusLC:ReloadCheck() -- Special reload check
					else
						-- Show configuration panel
						SideMinimap:Show()
						LeaPlusLC:HideFrames()
					end
				end
			end)

			-- Hide the Looking for Group button (SoD and Anniversary realms)
			if LeaPlusLC["HideMiniLFG"] == "On" then

				EventUtil.ContinueOnAddOnLoaded("Blizzard_GroupFinder_VanillaStyle", function()

					local function SetLFGButton()
						if C_LFGList.HasActiveEntryInfo() then
							LFGMinimapFrame:Show()
						else
							LFGMinimapFrame:Hide()
						end
					end

					LFGMinimapFrame:HookScript("OnEvent", SetLFGButton)
					SetLFGButton()

				end)

			end

			-- Hide tracking button
			if LeaPlusLC["HideMiniTracking"] == "On" and MiniMapTracking then

				-- The part you hover and click
				local trackingButton = MiniMapTrackingButton or MiniMapTracking

				-- Fade out after 1 second over 0.2 seconds (same as LibDBIcon)
				local fadeOut = MiniMapTracking:CreateAnimationGroup()
				local animOut = fadeOut:CreateAnimation("Alpha")
				animOut:SetOrder(1)
				animOut:SetDuration(0.2)
				animOut:SetFromAlpha(1)
				animOut:SetToAlpha(0)
				animOut:SetStartDelay(1)
				fadeOut:SetToFinalAlpha(true)

				-- Function to show the tracking button straight away
				local function ShowTracking()
					fadeOut:Stop()
					MiniMapTracking:SetAlpha(1)
				end

				-- Function to fade the tracking button out (not while its menu is open)
				local function HideTracking()
					if trackingButton.IsMenuOpen and trackingButton:IsMenuOpen() then return end
					fadeOut:Play()
				end

				-- Show when the pointer is over the minimap or the button and fade out when it leaves
				Minimap:HookScript("OnEnter", ShowTracking)
				Minimap:HookScript("OnLeave", HideTracking)
				trackingButton:HookScript("OnEnter", ShowTracking)
				trackingButton:HookScript("OnLeave", HideTracking)

				-- Keep button visible while menu is open and fade out when it closes if the pointer has moved away
				if trackingButton.RegisterCallback and trackingButton.IsMenuOpen then
					trackingButton:RegisterCallback("OnMenuOpen", ShowTracking)
					trackingButton:RegisterCallback("OnMenuClose", function()
						if not (Minimap:IsMouseOver() or trackingButton:IsMouseOver()) then fadeOut:Play() end
					end)
				end

				-- Hidden on startup
				MiniMapTracking:SetAlpha(0)

			end

			-- LibDBIcon callback (search LibDBIcon_IconCreated to find calls to this)
			LibDBIconStub.RegisterCallback(miniFrame, "LibDBIcon_IconCreated", function(self, button, name)

				-- Minimap button bag: Hide new LibDBIcon icons
				if LeaPlusLC["MinimapButtonBag"] == "On" then
					--C_Timer.After(0.1, function() -- Removed for now
						local buttonName = strlower(name)

						-- Special case for MoveAny because it doesn't have button.db
						if buttonName == "moveany" then
							button.db = button.db or {}
							if not button.db.hide then button.db.hide = false end
						end

						if not strfind(strlower(LeaPlusDB["MiniExcludeList"]), buttonName) then
							if button.db and not button.db.hide then
								button:Hide()
								button:SetScript("OnShow", function() if not LeaPlusLC.bFrame:IsShown() then button:Hide() end end)
							end
							-- Create background texture
							local bFrameBg = button:CreateTexture(nil, "BACKGROUND")
							bFrameBg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
							bFrameBg:SetPoint("CENTER")
							bFrameBg:SetSize(30, 30)
							bFrameBg:SetVertexColor(0, 0, 0, 0.5)
						elseif strfind(strlower(LeaPlusDB["MiniExcludeList"]), buttonName) and LeaPlusLC["SquareMinimap"] == "On" then
							button:SetScale(0.75)
						end
						-- Move GameTooltip to below the minimap in case the button uses it
						button:HookScript("OnEnter", LeaPlusLC.SetButtonTooltip)
					--end)
				end

				-- Square minimap: Set scale of new LibDBIcon icons
				if LeaPlusLC["SquareMinimap"] == "On" and LeaPlusLC["MinimapButtonBag"] == "Off" then
					button:SetScale(0.75)
				end

				-- Hide addon buttons: Hide new LibDBIcon icons
				if LeaPlusLC["MinimapButtonBag"] == "Off" then
					local buttonName = strlower(name)
					if LeaPlusLC["HideMiniAddonButtons"] == "On" then
						-- Hide addon buttons is enabled
						if not strfind(strlower(LeaPlusDB["MiniExcludeList"]), buttonName) then
							LibDBIconStub:ShowOnEnter(name, true)
						end
					else
						-- Hide addon buttons is disabled
						if not strfind(strlower(LeaPlusDB["MiniExcludeList"]), buttonName) then
							LibDBIconStub:ShowOnEnter(name, false)
						end
					end
				end

			end)

		end

		----------------------------------------------------------------------
		-- Filter chat messages
		----------------------------------------------------------------------

		if LeaPlusLC["FilterChatMessages"] == "On" and not LeaLockList["FilterChatMessages"] then

			-- Load LibChatAnims
			Leatrix_Plus:LeaPlusLCA()

			-- Create configuration panel
			local ChatFilterPanel = LeaPlusLC:CreatePanel("Filter chat messages", "ChatFilterPanel")

			LeaPlusLC:MakeTx(ChatFilterPanel, "Settings", 16, -72)
			LeaPlusLC:MakeCB(ChatFilterPanel, "BlockSpellLinks", "Block spell links during combat", 16, -92, false, "If checked, messages containing spell links will be blocked while you are in combat.|n|nThis is useful for blocking spell interrupt spam.|n|nThis applies to the say, party, raid, emote and yell channels.")
			LeaPlusLC:MakeCB(ChatFilterPanel, "BlockDrunkenSpam", "Block drunken spam", 16, -112, false, "If checked, drunken messages will be blocked unless they apply to your character.|n|nThis applies to the system channel.")
			LeaPlusLC:MakeCB(ChatFilterPanel, "BlockDuelSpam", "Block duel spam", 16, -132, false, "If checked, duel victory and retreat messages will be blocked unless your character took part in the duel.|n|nThis applies to the system channel.")

			-- Lock block drunken spam option for zhTW
			if GameLocale == "zhTW" then
				LeaPlusLC:LockItem(LeaPlusCB["BlockDrunkenSpam"], true)
				LeaPlusLC["BlockDrunkenSpam"] = "Off"
				LeaPlusDB["BlockDrunkenSpam"] = "Off"
				LeaPlusCB["BlockDrunkenSpam"].tiptext = LeaPlusCB["BlockDrunkenSpam"].tiptext .. "|n|n|cff00AAFF" .. L["Cannot use this with your locale."]
			end

			-- Help button hidden
			ChatFilterPanel.h:Hide()

			-- Back button handler
			ChatFilterPanel.b:SetScript("OnClick", function()
				ChatFilterPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page3"]:Show()
				return
			end)

			local charName = GetUnitName("player")
			local charRealm = GetNormalizedRealmName()
			local nameRealm = charName .. "%%-" .. charRealm

			-- Chat filter
			local function ChatFilterFunc(self, event, msg)
				-- Block duel spam
				if LeaPlusLC["BlockDuelSpam"] == "On" then
					-- Block duel messages unless you are part of the duel
					if msg:match(DUEL_WINNER_KNOCKOUT:gsub("%%1$s", "%.+"):gsub("%%2$s", "%.+")) or msg:match(DUEL_WINNER_RETREAT:gsub("%%1$s", "%.+"):gsub("%%2$s", "%.+")) then
						-- Player has defeated player in a duel.
						if msg:match(DUEL_WINNER_KNOCKOUT:gsub("%%1$s", charName):gsub("%%2$s", "%.+")) then return false end
						if msg:match(DUEL_WINNER_KNOCKOUT:gsub("%%1$s", nameRealm):gsub("%%2$s", "%.+")) then return false end
						if msg:match(DUEL_WINNER_KNOCKOUT:gsub("%%1$s", "%.+"):gsub("%%2$s", charName)) then return false end
						if msg:match(DUEL_WINNER_KNOCKOUT:gsub("%%1$s", "%.+"):gsub("%%2$s", nameRealm)) then return false end
						-- Player has fled from player in a duel.
						if msg:match(DUEL_WINNER_RETREAT:gsub("%%1$s", charName):gsub("%%2$s", "%.+")) then return false end
						if msg:match(DUEL_WINNER_RETREAT:gsub("%%1$s", nameRealm):gsub("%%2$s", "%.+")) then return false end
						if msg:match(DUEL_WINNER_RETREAT:gsub("%%1$s", "%.+"):gsub("%%2$s", charName)) then return false end
						if msg:match(DUEL_WINNER_RETREAT:gsub("%%1$s", "%.+"):gsub("%%2$s", nameRealm)) then return false end
						-- Block all duel messages not involving player
						return true
					end
				end
				-- Block spell links
				if LeaPlusLC["BlockSpellLinks"] == "On" and UnitAffectingCombat("player") then
					if msg:find("|Hspell") then return true end
				end
				-- Block drunken spam
				if LeaPlusLC["BlockDrunkenSpam"] == "On" then
					for i = 1, 4 do
						local drunk1 = _G["DRUNK_MESSAGE_ITEM_OTHER"..i]:gsub("%%s", "%s-")
						local drunk2 = _G["DRUNK_MESSAGE_OTHER"..i]:gsub("%%s", "%s-")
						if msg:match(drunk1) or msg:match(drunk2) then
							return true
						end
					end
				end
			end

			-- Enable or disable chat filter settings
			local function SetChatFilter()
				if LeaPlusLC["BlockSpellLinks"] == "On" then
					ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", ChatFilterFunc)
					ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", ChatFilterFunc)
					ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", ChatFilterFunc)
					ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", ChatFilterFunc)
					ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_LEADER", ChatFilterFunc)
					ChatFrame_AddMessageEventFilter("CHAT_MSG_EMOTE", ChatFilterFunc)
					ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", ChatFilterFunc)
				else
					ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SAY", ChatFilterFunc)
					ChatFrame_RemoveMessageEventFilter("CHAT_MSG_PARTY", ChatFilterFunc)
					ChatFrame_RemoveMessageEventFilter("CHAT_MSG_PARTY_LEADER", ChatFilterFunc)
					ChatFrame_RemoveMessageEventFilter("CHAT_MSG_RAID", ChatFilterFunc)
					ChatFrame_RemoveMessageEventFilter("CHAT_MSG_RAID_LEADER", ChatFilterFunc)
					ChatFrame_RemoveMessageEventFilter("CHAT_MSG_EMOTE", ChatFilterFunc)
					ChatFrame_RemoveMessageEventFilter("CHAT_MSG_YELL", ChatFilterFunc)
				end
				if LeaPlusLC["BlockDrunkenSpam"] == "On" or LeaPlusLC["BlockDuelSpam"] == "On" then
					ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", ChatFilterFunc)
				else
					ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SYSTEM", ChatFilterFunc)
				end
			end

			-- Set chat filter when settings are clicked and on startup
			LeaPlusCB["BlockSpellLinks"]:HookScript("OnClick", SetChatFilter)
			LeaPlusCB["BlockDrunkenSpam"]:HookScript("OnClick", SetChatFilter)
			LeaPlusCB["BlockDuelSpam"]:HookScript("OnClick", SetChatFilter)
			SetChatFilter()

			-- Reset button handler
			ChatFilterPanel.r:SetScript("OnClick", function()

				-- Reset controls
				LeaPlusLC["BlockSpellLinks"] = "Off"
				LeaPlusLC["BlockDrunkenSpam"] = "Off"
				LeaPlusLC["BlockDuelSpam"] = "Off"
				SetChatFilter()

				-- Refresh configuration panel
				ChatFilterPanel:Hide(); ChatFilterPanel:Show()

			end)

			-- Show configuration panal when options panel button is clicked
			LeaPlusCB["FilterChatMessagesBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					LeaPlusLC["BlockSpellLinks"] = "On"
					LeaPlusLC["BlockDrunkenSpam"] = "On"
					LeaPlusLC["BlockDuelSpam"] = "On"
					SetChatFilter()
				else
					ChatFilterPanel:Show()
					LeaPlusLC:HideFrames()
				end
			end)

		end

		----------------------------------------------------------------------
		-- Automatically accept resurrection requests (no reload required)
		----------------------------------------------------------------------

		do

			-- Create configuration panel
			local AcceptResPanel = LeaPlusLC:CreatePanel("Accept resurrection", "AcceptResPanel")

			LeaPlusLC:MakeTx(AcceptResPanel, "Settings", 16, -72)
			LeaPlusLC:MakeCB(AcceptResPanel, "AutoResNoCombat", "Exclude combat resurrection", 16, -92, false, "If checked, resurrection requests will not be automatically accepted if the player resurrecting you is in combat.")

			-- Help button hidden
			AcceptResPanel.h:Hide()

			-- Back button handler
			AcceptResPanel.b:SetScript("OnClick", function()
				AcceptResPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page1"]:Show();
				return
			end)

			-- Reset button handler
			AcceptResPanel.r:SetScript("OnClick", function()

				-- Reset checkboxes
				LeaPlusLC["AutoResNoCombat"] = "On"

				-- Refresh panel
				AcceptResPanel:Hide(); AcceptResPanel:Show()

			end)

			-- Show panal when options panel button is clicked
			LeaPlusCB["AutoAcceptResBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					LeaPlusLC["AutoResNoCombat"] = "On"
				else
					AcceptResPanel:Show()
					LeaPlusLC:HideFrames()
				end
			end)

			-- Function to set resurrect event
			local function SetResEvent()
				if LeaPlusLC["AutoAcceptRes"] == "On" then
					AcceptResPanel:RegisterEvent("RESURRECT_REQUEST")
				else
					AcceptResPanel:UnregisterEvent("RESURRECT_REQUEST")
				end
			end

			-- Run function when option is clicked and on startup if option is enabled
			LeaPlusCB["AutoAcceptRes"]:HookScript("OnClick", SetResEvent)
			if LeaPlusLC["AutoAcceptRes"] == "On" then SetResEvent() end

			-- Handle event
			AcceptResPanel:SetScript("OnEvent", function(self, event, arg1)
				if event == "RESURRECT_REQUEST" then

					-- Exclude Chained Spirit (Zul'Gurub)
					local chainLoc

					-- Exclude Chained Spirit (Zul'Gurub)
					chainLoc = "Chained Spirit"
					if 	   GameLocale == "zhCN" then chainLoc = "被禁锢的灵魂"
					elseif GameLocale == "zhTW" then chainLoc = "禁錮之魂"
					elseif GameLocale == "ruRU" then chainLoc = "Скованный дух"
					elseif GameLocale == "koKR" then chainLoc = "구속된 영혼"
					elseif GameLocale == "esMX" then chainLoc = "Espíritu encadenado"
					elseif GameLocale == "ptBR" then chainLoc = "Espírito Acorrentado"
					elseif GameLocale == "deDE" then chainLoc = "Angeketteter Geist"
					elseif GameLocale == "esES" then chainLoc = "Espíritu encadenado"
					elseif GameLocale == "frFR" then chainLoc = "Esprit enchaîné"
					elseif GameLocale == "itIT" then chainLoc = "Spirito Incatenato"
					end
					if arg1 == chainLoc then return	end

					-- Resurrect
					local resTimer = GetCorpseRecoveryDelay()
					if resTimer and resTimer > 0 then
						-- Resurrect has a delay so wait before resurrecting
						C_Timer.After(resTimer + 1, function()
							if not UnitAffectingCombat(arg1) or LeaPlusLC["AutoResNoCombat"] == "Off" then
								if LeaPlusLC["AutoAcceptRes"] == "On" then
									AcceptResurrect()
									StaticPopup_Hide("RESURRECT_NO_TIMER")
								end
							end
						end)
					else
						-- Resurrect has no delay so resurrect now
						if not UnitAffectingCombat(arg1) or LeaPlusLC["AutoResNoCombat"] == "Off" then
							AcceptResurrect()
							StaticPopup_Hide("RESURRECT_NO_TIMER")
						end
					end

					return

				end
			end)

		end

		----------------------------------------------------------------------
		-- Hide keybind text
		----------------------------------------------------------------------

		if LeaPlusLC["HideKeybindText"] == "On" and not LeaLockList["HideKeybindText"] then

			-- Hide bind text
			for i = 1, 12 do

				-- Bar 1: Main action bar
				_G["ActionButton"..i.."HotKey"]:SetAlpha(0)

				-- Bars 2 and 3: Bottom of screen
				_G["MultiBarBottomLeftButton"..i.."HotKey"]:SetAlpha(0)
				_G["MultiBarBottomRightButton"..i.."HotKey"]:SetAlpha(0)

				-- Bars 4 and 5: Right side of screen
				_G["MultiBarRightButton"..i.."HotKey"]:SetAlpha(0)
				_G["MultiBarLeftButton"..i.."HotKey"]:SetAlpha(0)

				-- Bars 6, 7 and 8: Middle of screen
				for j = 5, 7 do
					if _G["MultiBar"..j.."Button"..i.."HotKey"] then
						_G["MultiBar"..j.."Button"..i.."HotKey"]:SetAlpha(0)
					end
				end

			end

		end

		----------------------------------------------------------------------
		-- Hide macro text
		----------------------------------------------------------------------

		if LeaPlusLC["HideMacroText"] == "On" and not LeaLockList["HideMacroText"] then

			-- Hide marco text
			for i = 1, 12 do

				-- Bar 1: Main action bar
				_G["ActionButton"..i.."Name"]:SetAlpha(0)

				-- Bars 2 and 3: Bottom of screen
				_G["MultiBarBottomLeftButton"..i.."Name"]:SetAlpha(0)
				_G["MultiBarBottomRightButton"..i.."Name"]:SetAlpha(0)

				-- Bars 4 and 5: Right side of screen
				_G["MultiBarRightButton"..i.."Name"]:SetAlpha(0)
				_G["MultiBarLeftButton"..i.."Name"]:SetAlpha(0)

				-- Bars 6, 7 and 8: Middle of screen
				for j = 5, 7 do
					if _G["MultiBar"..j.."Button"..i.."Name"] then
						_G["MultiBar"..j.."Button"..i.."Name"]:SetAlpha(0)
					end
				end

			end

		end

		----------------------------------------------------------------------
		--	More chat font sizes
		----------------------------------------------------------------------

		if LeaPlusLC["MoreChatFontSizes"] == "On" and not LeaLockList["MoreChatFontSizes"] then

			local extraSizes = {22, 26, 28, 30, 32, 34, 36, 38, 40}

			Menu.ModifyMenu("MENU_FCF_TAB", function(owner, rootDescription)
				local chatFrame = FCF_GetChatFrameByID(owner:GetID())
				if not chatFrame then return end

				-- Find Blizzard's font size submenu (it contains a radio for the first chat font size)
				local fontMenu
				for void, element in rootDescription:EnumerateElementDescriptions() do
					for void, child in element:EnumerateElementDescriptions() do
						if child.IsRadio and child:IsRadio() and child:GetData() == CHAT_FONT_HEIGHTS[1] then
							fontMenu = element
							break
						end
					end
					if fontMenu then break end
				end
				if not fontMenu then return end

				-- Tick the size in use (font height is checked for secrets before it is compared)
				local function IsSelected(size)
					local void, height = chatFrame:GetFont()
					if not height or (issecretvalue and issecretvalue(height)) then return false end
					return math.floor(height + 0.5) == size
				end

				-- Set and save the font size the same way Blizzard's own options do
				local function SetSelected(size)
					FCF_SetChatWindowFontSize(nil, chatFrame, size)
				end

				-- Insert each extra size in order, skipping any size Blizzard already has
				for void, size in ipairs(extraSizes) do
					local index, exists = 1, false
					for i, child in fontMenu:EnumerateElementDescriptions() do
						local data = child:GetData()
						if data == size then exists = true; break end
						if type(data) == "number" and data < size then index = i + 1 end
					end
					if not exists then
						fontMenu:Insert(MenuUtil.CreateRadio(format(FONT_SIZE_TEMPLATE, size), IsSelected, SetSelected, size), index)
					end
				end
			end)

		end

		----------------------------------------------------------------------
		--	Show druid power bar
		----------------------------------------------------------------------

		if LeaPlusLC["ShowDruidPowerBar"] == "On" and not LeaLockList["ShowDruidPowerBar"] then

			-- Create configuration panel
			local DruidBarPanel = LeaPlusLC:CreatePanel("Show druid power bar", "DruidBarPanel")

			-- Add checkboxes
			LeaPlusLC:MakeTx(DruidBarPanel, "Settings", 16, -72)
			LeaPlusLC:MakeCB(DruidBarPanel, "ShowDruidStatusText", "Show druid power bar status text", 16, -92, true, "If checked, status text will be shown in the druid power bar as long as status text is enabled in the game settings interface display panel.")

			-- Hide help button
			DruidBarPanel.h:Hide()

			-- Back button handler
			DruidBarPanel.b:SetScript("OnClick", function()
				DruidBarPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page5"]:Show()
				return
			end)

			-- Reset button handler
			DruidBarPanel.r.tiptext = DruidBarPanel.r.tiptext .. "|n|n" .. L["Note that this will not reset settings that require a UI reload."]
			DruidBarPanel.r:SetScript("OnClick", function()

				-- Refresh configuration panel
				DruidBarPanel:Hide(); DruidBarPanel:Show()

			end)

			-- Show configuration panel when options panel button is clicked
			LeaPlusCB["ShowDruidPowerBarBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
				else
					-- Show configuration panel
					DruidBarPanel:Show()
					LeaPlusLC:HideFrames()
				end
			end)

			local void, class = UnitClass("player")
			if class == "DRUID" then

				-- Create druid power bar
				local ADDITIONAL_POWER_BAR_NAME = "MANA"
				local ADDITIONAL_POWER_BAR_INDEX = 0
				local ALT_MANA_BAR_PAIR_DISPLAY_INFO = {DRUID = {[Enum.PowerType.Rage] = true; [Enum.PowerType.Energy] = true}}

				-- Create local copies of Shadowlands functions (from Blizzard code AlternatePowerBar.lua)

				-- Line 13
				local function AlternatePowerBar_Initialize(self)
					if not (self.powerName and self.powerIndex) then
						self.powerName = ADDITIONAL_POWER_BAR_NAME
						self.powerIndex = ADDITIONAL_POWER_BAR_INDEX
					end

					local parent = self:GetParent()
					self:RegisterEvent("PLAYER_ENTERING_WORLD")
					self:RegisterUnitEvent("UNIT_DISPLAYPOWER", parent.unit)
					self:RegisterUnitEvent("UNIT_MAXPOWER", parent.unit)
					self:RegisterUnitEvent("UNIT_POWER_UPDATE", parent.unit)

					local color = PowerBarColor[self.powerName]
					self:SetStatusBarColor(color.r, color.g, color.b)
				end

				-- Line 66
				local function AlternatePowerBar_UpdateMaxValue(self)
					self:SetMinMaxValues(0, UnitPowerMax(self:GetParent().unit, self.powerIndex))
				end

				-- Line 60
				local function AlternatePowerBar_UpdateValue(self)
					self:SetValue(UnitPower(self:GetParent().unit, self.powerIndex))
				end

				-- Line 101
				local function AlternatePowerBar_UpdatePowerType(self)
					local unit = self:GetParent().unit
					local void, class = UnitClass(unit)
					local show = (UnitPowerMax(unit, self.powerIndex) > 0 and ALT_MANA_BAR_PAIR_DISPLAY_INFO[class] and ALT_MANA_BAR_PAIR_DISPLAY_INFO[class][UnitPowerType(unit)])

					self.pauseUpdates = not show
					if show then AlternatePowerBar_UpdateValue(self) end
					self:SetShown(show)
				end

				-- Line 4
				local function AlternatePowerBar_OnLoad(self)
					self.textLockable = 1
					self.cvar = "statusText"
					self.cvarLabel = "STATUS_TEXT_PLAYER"
					self.capNumericDisplay = true
					AlternatePowerBar_Initialize(self)
					self:InitializeTextStatusBar()
				end

				-- Line 32
				local function AlternatePowerBar_OnEvent(self, event, ...)
					if event == "PLAYER_ENTERING_WORLD" or event == "UNIT_MAXPOWER" then AlternatePowerBar_UpdateMaxValue(self) end
					if event == "PLAYER_ENTERING_WORLD" or event == "UNIT_DISPLAYPOWER" then AlternatePowerBar_UpdatePowerType(self) end
					if event == "UNIT_POWER_UPDATE" and self:IsShown() then AlternatePowerBar_UpdateValue(self) end
				end

				-- Line 55
				local function AlternatePowerBar_OnUpdate(self, elapsed)
					AlternatePowerBar_UpdateValue(self)
				end

				-- Create bar (uses Blizzard names from AlternatePowerBar.xml)
				local bar = CreateFrame("StatusBar", nil, PlayerFrame, "TextStatusBar")
				bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
				bar:SetStatusBarColor(0,0,1)
				bar:SetSize(104, 12)
				bar:SetPoint("BOTTOMLEFT", 98, 20)

				-- Show bar above player chain if it's enabled
				if LeaPlusLC["ShowPlayerChain"] == "On" then
					bar:SetFrameLevel(3)
				end

				bar.DefaultBackground = bar:CreateTexture(nil, "BACKGROUND")
				bar.DefaultBackground:SetColorTexture(0,0, 0, 0.5)
				bar.DefaultBackground:SetAllPoints(bar)

				-- Store yellow border colors for player chain
				local chainR, chainG, chainB = 0.86, 0.70, 0.12

				bar.DefaultBorder = bar:CreateTexture(nil, "OVERLAY")
				bar.DefaultBorder:SetTexture("Interface\\CharacterFrame\\UI-CharacterFrame-GroupIndicator")
				bar.DefaultBorder:SetTexCoord(0.125, 0.25, 1, 0)
				bar.DefaultBorder:SetHeight(16)
				bar.DefaultBorder:SetPoint("TOPLEFT", 4, 0)
				bar.DefaultBorder:SetPoint("TOPRIGHT", -4, 0)
				if LeaPlusLC["ShowPlayerChain"] == "On" then
					bar.DefaultBorder:SetVertexColor(chainR, chainG, chainB)
				end

				bar.DefaultBorderLeft = bar:CreateTexture(nil, "OVERLAY")
				bar.DefaultBorderLeft:SetTexture("Interface\\CharacterFrame\\UI-CharacterFrame-GroupIndicator")
				bar.DefaultBorderLeft:SetTexCoord(0, 0.125, 1, 0)
				bar.DefaultBorderLeft:SetSize(16, 16)
				bar.DefaultBorderLeft:SetPoint("TOPLEFT", -12, 0)
				if LeaPlusLC["ShowPlayerChain"] == "On" then
					bar.DefaultBorderLeft:SetVertexColor(chainR, chainG, chainB)
				end

				bar.DefaultBorderRight = bar:CreateTexture(nil, "OVERLAY")
				bar.DefaultBorderRight:SetTexture("Interface\\CharacterFrame\\UI-CharacterFrame-GroupIndicator")
				bar.DefaultBorderRight:SetTexCoord(0.125, 0, 1, 0)
				bar.DefaultBorderRight:SetSize(16, 16)
				bar.DefaultBorderRight:SetPoint("TOPRIGHT", 12, 0)
				if LeaPlusLC["ShowPlayerChain"] == "On" then
					bar.DefaultBorderRight:SetVertexColor(chainR, chainG, chainB)
				end

				if LeaPlusLC["ShowDruidStatusText"] == "On" then
					bar.TextString = bar:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
					bar.TextString:SetPoint("CENTER")

					bar.LeftText = bar:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
					bar.LeftText:SetPoint("LEFT")

					bar.RightText = bar:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
					bar.RightText:SetPoint("RIGHT")
				end

				bar:SetScript("OnEvent", AlternatePowerBar_OnEvent)
				bar:SetScript("OnUpdate", AlternatePowerBar_OnUpdate)
				AlternatePowerBar_OnLoad(bar)

			end

		end

		----------------------------------------------------------------------
		--	Show vanity controls (must be before Enhance dressup)
		----------------------------------------------------------------------

		if LeaPlusLC["ShowVanityControls"] == "On" then

			-- Create checkboxes
			LeaPlusLC:MakeCB(PaperDollFrame, "ShowHelm", L["Helm"], 2, -192, false, "")
			LeaPlusLC:MakeCB(PaperDollFrame, "ShowCloak", L["Cloak"], 281, -192, false, "")
			LeaPlusCB["ShowHelm"]:SetFrameStrata("HIGH")
			LeaPlusCB["ShowCloak"]:SetFrameStrata("HIGH")

			-- Function to set vanity controls layout
			local function SetVanityControlsLayout()
				if LeaPlusLC["VanityAltLayout"] == "On" then
					-- Alternative layout
					LeaPlusCB["ShowHelm"].f:SetText(L["H"])
					LeaPlusCB["ShowHelm"]:ClearAllPoints()
					LeaPlusCB["ShowHelm"]:SetPoint("TOPLEFT", 275, -224)
					LeaPlusCB["ShowHelm"]:SetHitRectInsets(-LeaPlusCB["ShowHelm"].f:GetStringWidth() + 4, 3, 0, 0)
					LeaPlusCB["ShowHelm"].f:ClearAllPoints()
					LeaPlusCB["ShowHelm"].f:SetPoint("RIGHT", LeaPlusCB["ShowHelm"], "LEFT", 4, 0)

					LeaPlusCB["ShowCloak"].f:SetText(L["C"])
					LeaPlusCB["ShowCloak"]:ClearAllPoints()
					LeaPlusCB["ShowCloak"]:SetPoint("TOP", LeaPlusCB["ShowHelm"], "BOTTOM", 0, 6)
					LeaPlusCB["ShowCloak"].f:ClearAllPoints()
					LeaPlusCB["ShowCloak"].f:SetPoint("RIGHT", LeaPlusCB["ShowCloak"], "LEFT", 4, 0)
					LeaPlusCB["ShowCloak"]:SetHitRectInsets(-LeaPlusCB["ShowCloak"].f:GetStringWidth() + 4, 3, 0, 0)
				else
					-- Default layout
					LeaPlusCB["ShowHelm"].f:SetText(L["Helm"])
					LeaPlusCB["ShowHelm"]:ClearAllPoints()
					if C_AddOns.IsAddOnLoaded("CharacterStatsClassic") then
						LeaPlusCB["ShowHelm"]:SetPoint("TOPLEFT", 65, -258)
					else
						LeaPlusCB["ShowHelm"]:SetPoint("TOPLEFT", 65, -250)
					end
					LeaPlusCB["ShowHelm"]:SetHitRectInsets(3, -LeaPlusCB["ShowHelm"].f:GetStringWidth(), 0, 0)
					LeaPlusCB["ShowHelm"].f:ClearAllPoints()
					LeaPlusCB["ShowHelm"].f:SetPoint("LEFT", LeaPlusCB["ShowHelm"], "RIGHT", 0, 0)

					LeaPlusCB["ShowCloak"].f:SetText(L["Cloak"])
					LeaPlusCB["ShowCloak"]:ClearAllPoints()
					if C_AddOns.IsAddOnLoaded("CharacterStatsClassic") then
						LeaPlusCB["ShowCloak"]:SetPoint("TOPLEFT", 275, -258)
					else
						LeaPlusCB["ShowCloak"]:SetPoint("TOPLEFT", 275, -250)
					end
					LeaPlusCB["ShowCloak"]:SetHitRectInsets(-LeaPlusCB["ShowCloak"].f:GetStringWidth(), 3, 0, 0)
					LeaPlusCB["ShowCloak"].f:ClearAllPoints()
					LeaPlusCB["ShowCloak"].f:SetPoint("RIGHT", LeaPlusCB["ShowCloak"], "LEFT", 0, 0)
				end
			end

			-- Set position when controls are shift/right-clicked
			LeaPlusCB["ShowHelm"]:SetScript('OnMouseDown', function(self, btn)
				if btn == "RightButton" and IsShiftKeyDown() then
					if LeaPlusLC["VanityAltLayout"] == "On" then LeaPlusLC["VanityAltLayout"] = "Off" else LeaPlusLC["VanityAltLayout"] = "On" end
					SetVanityControlsLayout()
				end
			end)

			LeaPlusCB["ShowCloak"]:SetScript('OnMouseDown', function(self, btn)
				if btn == "RightButton" and IsShiftKeyDown() then
					if LeaPlusLC["VanityAltLayout"] == "On" then LeaPlusLC["VanityAltLayout"] = "Off" else LeaPlusLC["VanityAltLayout"] = "On" end
					SetVanityControlsLayout()
				end
			end)

			-- Set controls on startup
			SetVanityControlsLayout()

			-- Manage alpha
			LeaPlusCB["ShowHelm"]:SetAlpha(0.3)
			LeaPlusCB["ShowCloak"]:SetAlpha(0.3)
			LeaPlusCB["ShowHelm"]:HookScript("OnEnter", function() LeaPlusCB["ShowHelm"]:SetAlpha(1.0) end)
			LeaPlusCB["ShowHelm"]:HookScript("OnLeave", function() LeaPlusCB["ShowHelm"]:SetAlpha(0.3) end)
			LeaPlusCB["ShowCloak"]:HookScript("OnEnter", function()	LeaPlusCB["ShowCloak"]:SetAlpha(1.0) end)
			LeaPlusCB["ShowCloak"]:HookScript("OnLeave", function()	LeaPlusCB["ShowCloak"]:SetAlpha(0.3) end)

			-- Toggle helm with click
			LeaPlusCB["ShowHelm"]:HookScript("OnClick", function()
				LeaPlusCB["ShowHelm"]:Disable()
				LeaPlusCB["ShowHelm"]:SetAlpha(1.0)
				C_Timer.After(0.5, function()
					if ShowingHelm() then
						ShowHelm(false)
					else
						ShowHelm(true)
					end
					LeaPlusCB["ShowHelm"]:Enable()
					if not LeaPlusCB["ShowHelm"]:IsMouseOver() then
						LeaPlusCB["ShowHelm"]:SetAlpha(0.3)
					end
				end)
			end)

			-- Toggle cloak with click
			LeaPlusCB["ShowCloak"]:HookScript("OnClick", function()
				LeaPlusCB["ShowCloak"]:Disable()
				LeaPlusCB["ShowCloak"]:SetAlpha(1.0)
				C_Timer.After(0.5, function()
					if ShowingCloak() then
						ShowCloak(false)
					else
						ShowCloak(true)
					end
					LeaPlusCB["ShowCloak"]:Enable()
					if not LeaPlusCB["ShowCloak"]:IsMouseOver() then
						LeaPlusCB["ShowCloak"]:SetAlpha(0.3)
					end
				end)
			end)

			-- Set checkbox state when checkboxes are shown
			LeaPlusCB["ShowCloak"]:HookScript("OnShow", function()
				if ShowingHelm() then
					LeaPlusCB["ShowHelm"]:SetChecked(true)
				else
					LeaPlusCB["ShowHelm"]:SetChecked(false)
				end
				if ShowingCloak() then
					LeaPlusCB["ShowCloak"]:SetChecked(true)
				else
					LeaPlusCB["ShowCloak"]:SetChecked(false)
				end
			end)

		end

		----------------------------------------------------------------------
		-- Enhance dressup
		----------------------------------------------------------------------

		if LeaPlusLC["EnhanceDressup"] == "On" then

			-- Create configuration panel
			local DressupPanel = LeaPlusLC:CreatePanel("Enhance dressup", "DressupPanel")

			LeaPlusLC:MakeTx(DressupPanel, "Settings", 16, -72)
			LeaPlusLC:MakeCB(DressupPanel, "DressupItemButtons", "Show item buttons", 16, -92, false, "If checked, item buttons will be shown in the dressing room.  You can click the item buttons to hide individual items on the model and click them again to show them.")
			LeaPlusLC:MakeCB(DressupPanel, "DressupAnimControl", "Show animation slider", 16, -112, false, "If checked, an animation slider will be shown in the dressing room.")

			-- Help button hidden
			DressupPanel.h:Hide()

			-- Back button handler
			DressupPanel.b:SetScript("OnClick", function()
				DressupPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page5"]:Show()
				return
			end)

			-- Reset button handler
			DressupPanel.r:SetScript("OnClick", function()

				-- Refresh configuration panel
				DressupPanel:Hide(); DressupPanel:Show()

			end)

			-- Show configuration panal when options panel button is clicked
			LeaPlusCB["EnhanceDressupBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
				else
					DressupPanel:Show()
					LeaPlusLC:HideFrames()
				end
			end)

			----------------------------------------------------------------------
			-- Item buttons
			----------------------------------------------------------------------

			-- Shared with the bottom buttons (further down)
			local DressupGear = {}

			-- Show a message in the dressing room, at the top of the model on a dark background (where people are looking, and clear of
			-- the button tooltips), which fades out after a few seconds
			do
				local msgFrame = CreateFrame("Frame", nil, DressUpFrame)
				msgFrame:SetFrameStrata("HIGH")
				msgFrame:SetPoint("TOPLEFT", DressUpFrame, "TOPLEFT", 52, -68)
				msgFrame:SetPoint("TOPRIGHT", DressUpFrame, "TOPRIGHT", -54, -68)
				msgFrame:SetHeight(30)
				msgFrame:Hide()
				local bg = msgFrame:CreateTexture(nil, "BACKGROUND")
				bg:SetAllPoints()
				bg:SetColorTexture(0, 0, 0, 0.75)
				local text = msgFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
				text:SetPoint("TOPLEFT", 6, -6)
				text:SetPoint("TOPRIGHT", -6, -6)
				text:SetJustifyH("CENTER")
				local fade = msgFrame:CreateAnimationGroup()
				local alpha = fade:CreateAnimation("Alpha")
				alpha:SetFromAlpha(1)
				alpha:SetToAlpha(0)
				alpha:SetStartDelay(3)
				alpha:SetDuration(0.5)
				fade:SetScript("OnFinished", function() msgFrame:Hide() end)
				function DressupGear.Message(message)
					text:SetText(message)
					msgFrame:SetHeight(text:GetStringHeight() + 12) -- Fits the text (long messages go over two lines)
					fade:Stop()
					msgFrame:SetAlpha(1)
					msgFrame:Show()
					fade:Play()
				end
				DressUpFrame:HookScript("OnHide", function() fade:Stop() msgFrame:Hide() end)
			end

			-- Give a button the same look as the item slots in the character sheet (the icon is btn.t)
			local function PaperDollButton(btn, size)
				btn:SetSize(size, size)
				local bg = btn:CreateTexture(nil, "BACKGROUND")
				bg:SetAllPoints()
				bg:SetColorTexture(0, 0, 0, 0.7) -- Behind the icon (portraits are round, so this fills the corners)
				btn.t = btn:CreateTexture(nil, "BORDER")
				btn.t:SetAllPoints()
				btn:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
				local border = btn:GetNormalTexture()
				border:ClearAllPoints()
				border:SetSize(size * 64 / 37, size * 64 / 37)
				border:SetPoint("CENTER", 0, -size / 37)
				btn:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
				btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
			end

			do

				local model = DressUpFrame.DressUpModel
				local buttons, slotOrder = {}, {}
				local slotInfo, hiddenSlots, triedOn, nudeSaved = {}, {}, {}, {} -- What is in each slot, slots taken off, slots with a tried on item, slots to put back on after nude
				local setID, modelUnit, modelGUID, isOther, selfDressing, isNude = 0, nil, nil, false, false, false
				local nudeBtn -- The all items button at the bottom of the left column
				local mode -- What the model shows: me, target, myOutfitOnTarget or targetOutfitOnMe (nil for anyone else)

				-- Set what the model shows (the model menu shows it)
				local function SetMode(newMode)
					mode = newMode
					if DressupGear.OnModeChanged then DressupGear.OnModeChanged() end
				end
				function DressupGear.GetMode() return mode end
				local GetInstant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant

				-- Slot buttons (slot ID, slot name, icon shown when the slot is empty and the game has no empty slot icon)
				local leftSlots = {{1, "HeadSlot", "INV_Misc_Desecrated_ClothHelm"}, {3, "ShoulderSlot", "INV_Misc_Desecrated_ClothShoulder"}, {15, "BackSlot", "INV_Misc_Cape_01"}, {5, "ChestSlot", "INV_Misc_Desecrated_ClothChest"}, {4, "ShirtSlot", "INV_Shirt_01"}, {19, "TabardSlot", "INV_Shirt_GuildTabard_01"}, {9, "WristSlot", "INV_Misc_Desecrated_ClothBracer"}}
				local rightSlots = {{10, "HandsSlot", "INV_Misc_Desecrated_ClothGlove"}, {6, "WaistSlot", "INV_Misc_Desecrated_ClothBelt"}, {7, "LegsSlot", "INV_Misc_Desecrated_ClothPants"}, {8, "FeetSlot", "INV_Misc_Desecrated_ClothBoots"}, {16, "MainHandSlot", "INV_Sword_01"}, {17, "SecondaryHandSlot", "INV_Shield_01"}, {18, "RangedSlot", "INV_Weapon_Bow_01"}}

				-- The slot a tried on item goes into
				local equipSlots = {INVTYPE_HEAD = 1, INVTYPE_SHOULDER = 3, INVTYPE_BODY = 4, INVTYPE_CHEST = 5, INVTYPE_ROBE = 5, INVTYPE_WAIST = 6, INVTYPE_LEGS = 7, INVTYPE_FEET = 8, INVTYPE_WRIST = 9, INVTYPE_HAND = 10, INVTYPE_CLOAK = 15, INVTYPE_WEAPON = 16, INVTYPE_WEAPONMAINHAND = 16, INVTYPE_2HWEAPON = 16, INVTYPE_WEAPONOFFHAND = 17, INVTYPE_SHIELD = 17, INVTYPE_HOLDABLE = 17, INVTYPE_RANGED = 18, INVTYPE_RANGEDRIGHT = 18, INVTYPE_THROWN = 18, INVTYPE_RELIC = 18, INVTYPE_TABARD = 19}

				-- Item ID, equip slot and icon (works without the item being loaded)
				local function ItemData(item)
					if not item or not GetInstant then return end
					local ok, itemID, void, void, equipLoc, icon = pcall(GetInstant, item)
					if ok and itemID then return itemID, equipLoc, icon end
				end

				-- Weapon appearance for a hand slot (weapons are put straight into their own slot as appearances, because trying them
				-- on makes the game treat the model as unable to dual wield, so a weapon in one hand pushes out the other)
				local function WeaponTransmog(link)
					if not (link and model.SetItemTransmogInfo and C_TransmogCollection and C_TransmogCollection.GetItemInfo and ItemUtil and ItemUtil.CreateItemTransmogInfo) then return end
					local ok, void, sourceID = pcall(C_TransmogCollection.GetItemInfo, link)
					if ok and type(sourceID) == "number" and sourceID > 0 then
						local made, transmog = pcall(ItemUtil.CreateItemTransmogInfo, sourceID)
						if made and transmog then return transmog end
					end
				end

				-- Put the item for a slot on the model (noFallback leaves weapons alone if they cannot be put on as appearances)
				local function DressSlot(slotID, noFallback)
					local info = slotInfo[slotID]
					if not info or not info.link then return end
					selfDressing = true
					if slotID == 16 or slotID == 17 or slotID == 18 then
						if info.transmog == nil then info.transmog = WeaponTransmog(info.link) or false end
						local done = info.transmog and pcall(model.SetItemTransmogInfo, model, info.transmog, slotID)
						if not done and not noFallback then
							pcall(model.TryOn, model, info.link, (slotID == 16 and "MAINHANDSLOT") or (slotID == 17 and "SECONDARYHANDSLOT") or nil)
						end
					else
						pcall(model.TryOn, model, info.link)
					end
					selfDressing = false
				end

				-- Other players: the game does not always put both weapons on the model (such as the main hand of a dual wielder),
				-- so their weapons are put on as appearances once known (set stops this if the model has shown something else since)
				local function Wield(set)
					if set ~= setID or not isOther then return end
					for void, slotID in ipairs({16, 17}) do
						if slotInfo[slotID] and not hiddenSlots[slotID] and not triedOn[slotID] then DressSlot(slotID, true) end
					end
				end

				-- Show each button as worn, taken off or empty
				local function UpdateSlots()
					for void, button in ipairs(buttons) do
						local info = slotInfo[button.slotID]
						local hidden = hiddenSlots[button.slotID]
						-- Worn: the item icon, taken off: the item icon greyed out, empty: the empty slot picture (as in the character sheet)
						button.t:SetTexture((info and info.icon) or button.emptyTexture)
						button.t:SetDesaturated(hidden and true or false)
						button.t:SetAlpha(hidden and 0.45 or 1)
					end
					-- All items button: gold while anything is showing, grey once everything is off
					if nudeBtn then
						local anyShown = not next(slotInfo)
						for slotID in pairs(slotInfo) do
							if not hiddenSlots[slotID] then anyShown = true break end
						end
						nudeBtn.t:SetDesaturated(not anyShown)
						nudeBtn.badge:SetShown(anyShown)
						nudeBtn.t:SetAlpha(anyShown and 1 or 0.45)
					end
				end

				-- Read gear from a unit (or from a table of item links), leaving tried on items alone
				-- Gives true when every item could be read, and true when a weapon has come in
				local function ReadGear(unit, gear)
					local complete, newWeapon = true, false
					for void, slotID in ipairs(slotOrder) do
						if not triedOn[slotID] then
							local link
							if gear then
								link = gear[slotID]
							else
								link = GetInventoryItemLink(unit, slotID)
								if not link and GetInventoryItemID(unit, slotID) then complete = false end -- Still loading
							end
							if link and not (slotInfo[slotID] and slotInfo[slotID].link == link) then
								local void, void, icon = ItemData(link)
								slotInfo[slotID] = {link = link, icon = icon or (unit and GetInventoryItemTexture(unit, slotID))}
								if isNude then hiddenSlots[slotID] = true end -- Gear read after nude stays off
								if slotID >= 16 then newWeapon = true end
							end
						end
					end
					return complete, newWeapon
				end

				-- Find the unit shown on the model (the target may have changed since)
				local function FindUnit()
					if not modelGUID then return end
					for void, token in ipairs({modelUnit, "target", "mouseover", "focus"}) do
						if token and UnitExists(token) and UnitGUID(token) == modelGUID then return token end
					end
				end

				-- Gear from Show info cards (if it has inspected the same player)
				local function MergeInspected()
					local gear = modelGUID and LeaPlusLC.IDGear and LeaPlusLC.IDGear[modelGUID]
					if gear then
						local void, newWeapon = ReadGear(nil, gear)
						return newWeapon
					end
				end

				-- Look for the gear of another player again
				local function Poll(set)
					if set ~= setID or not isOther then return end
					MergeInspected()
					local unit = FindUnit()
					if unit then ReadGear(unit) end
					Wield(set)
					UpdateSlots()
				end

				----------------------------------------------------------------------
				-- Inspect (other players)
				----------------------------------------------------------------------

				local inspectFrame = CreateFrame("Frame")
				local inspectGUID, inspectSet, inspectOwn

				local function StopInspect()
					inspectGUID = nil
					inspectFrame:UnregisterEvent("INSPECT_READY")
				end

				-- Clear the inspect data (not while the inspect window is open or Show info cards is using it)
				local function ClearInspect()
					local card = LeaPlusLC.IDCard
					if ClearInspectPlayer and not (InspectFrame and InspectFrame:IsShown()) and not (card and (card.inspectGUID or card.gearReadingGUID)) and not LeaPlusLC.IDGearWait then
						ClearInspectPlayer()
					end
				end

				local function InInspectRange(unit)
					if InCombatLockdown() or not CheckInteractDistance then return true end
					local ok, inRange = pcall(CheckInteractDistance, unit, 1)
					return not (ok and inRange == false)
				end

				local function StartInspect(unit, set)
					if not NotifyInspect or not CanInspect or not CanInspect(unit) then return end
					if InspectFrame and InspectFrame:IsShown() then return end -- Do not disturb the inspect window (its data is read anyway)
					local card = LeaPlusLC.IDCard
					local cardGUID = card and card.inspectGUID
					if cardGUID and cardGUID ~= modelGUID then return end -- Show info cards is inspecting someone else
					if not cardGUID and not InInspectRange(unit) then return end
					inspectGUID, inspectSet, inspectOwn = modelGUID, set, not cardGUID
					inspectFrame:RegisterEvent("INSPECT_READY")
					if inspectOwn then
						-- Only ask once per player at a time (shared with Show info cards, which then uses the same reply)
						local pending = LeaPlusLC.IDInspectPending
						if not (pending and pending.guid == modelGUID and GetTime() - pending.time < 4) then
							LeaPlusLC.IDInspectPending = {guid = modelGUID, time = GetTime()}
							NotifyInspect(unit)
						end
					end
					C_Timer.After(5, function() if inspectSet == set and inspectGUID then StopInspect() end end) -- No reply
				end

				inspectFrame:SetScript("OnEvent", function(self, event, guid)
					if not inspectGUID or guid ~= inspectGUID then return end
					local set, own = inspectSet, inspectOwn
					StopInspect()
					local pending = LeaPlusLC.IDInspectPending
					if own and pending and pending.guid == guid then LeaPlusLC.IDInspectPending = nil end
					-- Read the gear (items the game has not loaded yet are read again, for up to 3 seconds)
					local tries = 0
					local function Read()
						if set ~= setID then if own then ClearInspect() end return end
						tries = tries + 1
						local unit = FindUnit()
						local complete = true
						if unit then complete = ReadGear(unit) end
						Wield(set)
						UpdateSlots()
						if unit and not complete and tries < 12 then C_Timer.After(0.25, Read) return end
						C_Timer.After(0.3, function() Wield(set) end) -- Again a moment later in case the game was still dressing the model
						if own then ClearInspect() end
					end
					Read()
				end)

				----------------------------------------------------------------------
				-- Follow what is put on the model
				----------------------------------------------------------------------

				-- A unit is shown (dressing room opened, reset, show me, show target)
				local function OnSetUnit(unit)
					setID = setID + 1
					isNude = false
					wipe(slotInfo) wipe(hiddenSlots) wipe(triedOn) wipe(nudeSaved)
					StopInspect()
					modelUnit, modelGUID, isOther = nil, nil, false
					local newMode
					if type(unit) == "string" and UnitExists(unit) then
						modelUnit, modelGUID = unit, UnitGUID(unit)
						isOther = UnitIsPlayer(unit) and not UnitIsUnit(unit, "player") or false
						if UnitIsUnit(unit, "player") then newMode = "me" elseif isOther then newMode = "target" end
						ReadGear(unit)
						if isOther then
							local set = setID
							MergeInspected()
							StartInspect(unit, set)
							C_Timer.After(0.5, function() Poll(set) end)
							C_Timer.After(1.5, function() Poll(set) end)
							C_Timer.After(3, function() Poll(set) end)
						end
					end
					UpdateSlots()
					SetMode(newMode)
				end
				hooksecurefunc(model, "SetUnit", function(self, unit) OnSetUnit(unit) end)

				-- The dressing room starts with the player (in case it is shown before anything has set the model)
				DressUpFrame:HookScript("OnShow", function()
					if not modelGUID then OnSetUnit("player") end
				end)

				-- The model has finished loading (weapons can only be put on after this)
				model:HookScript("OnModelLoaded", function()
					if isOther then
						local set = setID
						Wield(set)
						C_Timer.After(0.3, function() Wield(set) end)
					end
				end)

				-- An item is tried on (such as with Ctrl-click)
				hooksecurefunc(model, "TryOn", function(self, item, hand)
					if selfDressing then return end
					local itemID, equipLoc, icon = ItemData(item)
					local slotID = equipLoc and equipSlots[equipLoc]
					if not slotID then return end
					if hand == "SECONDARYHANDSLOT" then slotID = 17 elseif hand == "MAINHANDSLOT" then slotID = 16 end
					slotInfo[slotID] = {link = type(item) == "string" and item or ("item:" .. itemID), icon = icon}
					hiddenSlots[slotID], triedOn[slotID] = nil, true
					isNude = false
					if equipLoc == "INVTYPE_2HWEAPON" then
						-- Two-handed weapons take the off hand too
						slotInfo[17], hiddenSlots[17], triedOn[17] = nil, nil, true
					end
					UpdateSlots()
				end)

				----------------------------------------------------------------------
				-- Slot buttons
				----------------------------------------------------------------------

				local function SlotTip(self)
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
					local info = slotInfo[self.slotID]
					if not (info and info.link and pcall(GameTooltip.SetHyperlink, GameTooltip, info.link)) then
						GameTooltip:SetText(self.label, 1, 1, 1)
					end
					if not info then
						GameTooltip:AddLine(L["Nothing to show in this slot"], 0.6, 0.6, 0.65)
					elseif hiddenSlots[self.slotID] then
						GameTooltip:AddLine(L["Click to show"], 0.6, 0.6, 0.65)
					else
						GameTooltip:AddLine(L["Click to hide"], 0.6, 0.6, 0.65)
					end
					GameTooltip:Show()
				end

				-- A column for each set of slot buttons (down each side of the model, like the character sheet)
				local columns = {}
				local step = 33 -- Distance from one slot button to the next (the same spacing as the character sheet, scaled to these smaller buttons)
				local function MakeColumn(anchor, x, y)
					local column = CreateFrame("Frame", nil, DressUpFrame)
					column:SetFrameStrata("HIGH")
					column:SetPoint(anchor, DressUpFrame, anchor, x, y)
					column:SetWidth(38)
					column.count = 0
					tinsert(columns, column)
					return column
				end
				local leftColumn = MakeColumn("TOPLEFT", 8, -64)
				local rightColumn = MakeColumn("TOPRIGHT", -10, -64)

				-- The frame each slot sits in on the character sheet (with a tab towards the model), if this game has it
				local slotFrameFile = "Interface\\CharacterFrame\\Char-Paperdoll-Parts"
				local hasSlotFrames = GetFileIDFromPath and GetFileIDFromPath(slotFrameFile) and true or false
				local function AddSlotFrame(btn, column)
					if not hasSlotFrames then return end
					local frame = column:CreateTexture(nil, "BACKGROUND") -- On the column, so it is always behind every slot button
					frame:SetTexture(slotFrameFile)
					local scale = btn:GetWidth() / 37 -- The character sheet slots are 37 wide
					if column == leftColumn then
						frame:SetTexCoord(0.20703125, 0.39843750, 0.59375000, 0.93750000)
						frame:SetSize(49 * scale, 44 * scale)
						frame:SetPoint("TOPLEFT", btn, "TOPLEFT", -4 * scale, 0)
					else
						frame:SetTexCoord(0.00390625, 0.19921875, 0.59375000, 0.93750000)
						frame:SetSize(50 * scale, 44 * scale)
						frame:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 4 * scale, 0)
					end
				end

				local function MakeSlotButton(entry, column)

					-- Slots this game does not have are left out
					local slotID, slotName, fallbackIcon = entry[1], entry[2], entry[3]
					local ok, slotNumber, emptyTexture = pcall(GetInventorySlotInfo, slotName)
					if not ok or not slotNumber then return end

					-- Create slot button
					local slotBtn = CreateFrame("Button", nil, column)
					slotBtn:SetFrameLevel(column:GetFrameLevel() + 2)
					PaperDollButton(slotBtn, 30)
					AddSlotFrame(slotBtn, column)
					slotBtn.slotID = slotID
					slotBtn.label = _G[strupper(slotName)] or slotName
					slotBtn.emptyTexture = emptyTexture or ("interface\\icons\\" .. fallbackIcon)
					slotBtn:ClearAllPoints()
					slotBtn:SetPoint("TOP", column, "TOP", 0, -4 - step * column.count)
					column.count = column.count + 1
					column:SetHeight(8 + step * column.count - (step - 30))
					slotBtn:RegisterForClicks("LeftButtonUp")
					slotBtn:SetMotionScriptsWhileDisabled(true)

					-- Slot button click: take the item off, click again to put it back on
					slotBtn:SetScript("OnClick", function(self)
						local slot = self.slotID
						if not slotInfo[slot] then return end
						if hiddenSlots[slot] then
							hiddenSlots[slot] = nil
							isNude = false
							DressSlot(slot)
						else
							hiddenSlots[slot] = true
							pcall(model.UndressSlot, model, slot)
						end
						UpdateSlots()
						if GameTooltip:IsOwned(self) then SlotTip(self) end
					end)

					-- Slot button tooltip
					slotBtn:SetScript("OnEnter", SlotTip)
					slotBtn:SetScript("OnLeave", GameTooltip_Hide)

					-- Add slot button to table
					tinsert(buttons, slotBtn)
					tinsert(slotOrder, slotID)

				end

				-- Show left column slot buttons
				for i, entry in ipairs(leftSlots) do
					MakeSlotButton(entry, leftColumn)
				end

				-- Show right column slot buttons
				for i, entry in ipairs(rightSlots) do
					MakeSlotButton(entry, rightColumn)
				end

				-- All items button (nude) at the bottom of the left column
				do
					local column = leftColumn
					nudeBtn = CreateFrame("Button", nil, column)
					nudeBtn:SetFrameLevel(column:GetFrameLevel() + 2)
					PaperDollButton(nudeBtn, 30)
					AddSlotFrame(nudeBtn, column)
					nudeBtn:SetPoint("TOP", column, "TOP", 0, -4 - step * column.count)
					column.count = column.count + 1
					column:SetHeight(8 + step * column.count - (step - 30))

					nudeBtn.t:SetTexture("Interface\\Icons\\INV_Shirt_01")

					-- Red cross in the corner while anything is on (click to take it all off)
					nudeBtn.badge = nudeBtn:CreateTexture(nil, "OVERLAY", nil, 2)
					nudeBtn.badge:SetSize(14, 14)
					nudeBtn.badge:SetPoint("BOTTOMRIGHT", nudeBtn, "BOTTOMRIGHT", 1, -1)
					nudeBtn.badge:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")

					local function NudeTip(self)
						GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
						GameTooltip:SetText(L["All items"], 1, 1, 1)
						if DressupGear.AnyShown() then
							GameTooltip:AddLine(L["Click to remove all items"], 0.6, 0.6, 0.65)
						else
							GameTooltip:AddLine(L["Click to put all items back on"], 0.6, 0.6, 0.65)
						end
						GameTooltip:Show()
					end
					nudeBtn:RegisterForClicks("LeftButtonUp")
					nudeBtn:SetScript("OnEnter", NudeTip)
					nudeBtn:SetScript("OnLeave", GameTooltip_Hide)
					nudeBtn:SetScript("OnClick", function(self)
						DressupGear.ToggleNude()
						if GameTooltip:IsOwned(self) then NudeTip(self) end
					end)
				end

				UpdateSlots()

				----------------------------------------------------------------------
				-- Nude (used by the nude button)
				----------------------------------------------------------------------

				-- Is anything still showing (true when nothing is known about the gear, so nude always takes everything off)
				function DressupGear.AnyShown()
					if not next(slotInfo) then return true end
					for slotID in pairs(slotInfo) do
						if not hiddenSlots[slotID] then return true end
					end
					return false
				end

				-- The unit shown in the dressing room (nil if it cannot be found any more, such as when another player is no longer targeted)
				function DressupGear.GetUnit()
					if not modelGUID or modelGUID == UnitGUID("player") then return "player" end
					return FindUnit()
				end

				-- Take everything off, click again to put back on what was showing before
				function DressupGear.ToggleNude()
					if DressupGear.AnyShown() then
						wipe(nudeSaved)
						for slotID in pairs(slotInfo) do
							if not hiddenSlots[slotID] then nudeSaved[slotID] = true; hiddenSlots[slotID] = true end
						end
						isNude = true
						-- Undress leaves weapons on the model, so every slot is taken off as well (and again a moment later in case the game puts a weapon back)
						local function Strip()
							model:Undress()
							for void, slotID in ipairs(slotOrder) do pcall(model.UndressSlot, model, slotID) end
						end
						Strip()
						local set = setID
						C_Timer.After(0.3, function() if set == setID and isNude then Strip() end end)
					else
						isNude = false
						local all = not next(nudeSaved) -- Nothing remembered, so put everything back on
						for void, slotID in ipairs(slotOrder) do
							if slotInfo[slotID] and (all or nudeSaved[slotID]) then
								hiddenSlots[slotID] = nil
								DressSlot(slotID)
							end
						end
						wipe(nudeSaved)
					end
					UpdateSlots()
				end

				----------------------------------------------------------------------
				-- Outfits (my outfit on target, target outfit on me)
				----------------------------------------------------------------------

				-- Item links for each slot a unit is wearing (and whether every item could be read)
				local function UnitLinks(unit)
					local gear, complete = {}, true
					for void, slotID in ipairs(slotOrder) do
						local link = GetInventoryItemLink(unit, slotID)
						if link then gear[slotID] = link elseif GetInventoryItemID(unit, slotID) then complete = false end
					end
					return gear, complete
				end

				-- Put the outfit on the model (everything off first, then each slot, weapons straight into their own hand)
				local pendingOutfit, outfitLoadDressed
				local function DressOutfit(set)
					if set ~= setID or pendingOutfit ~= set then return end
					model:Undress()
					for void, slotID in ipairs(slotOrder) do pcall(model.UndressSlot, model, slotID) end
					for void, slotID in ipairs(slotOrder) do
						if slotInfo[slotID] and not hiddenSlots[slotID] then DressSlot(slotID) end
					end
				end

				-- Show an outfit (a table of item links by slot) on the unit the model has just been set to
				local function ApplyOutfit(gear)
					StopInspect()
					isOther = false -- The model's own gear is not wanted, so it is not read or put back on
					isNude = false
					wipe(slotInfo) wipe(hiddenSlots) wipe(triedOn) wipe(nudeSaved)
					for void, slotID in ipairs(slotOrder) do
						local link = gear[slotID]
						if link then
							local void, void, icon = ItemData(link)
							slotInfo[slotID] = {link = link, icon = icon}
							triedOn[slotID] = true
						end
					end
					local set = setID
					pendingOutfit, outfitLoadDressed = set, false
					-- Again once the model has loaded and a moment later, in case the game was still dressing the model
					DressOutfit(set)
					C_Timer.After(0.1, function() DressOutfit(set) end)
					C_Timer.After(0.5, function() DressOutfit(set) end)
					UpdateSlots()
				end
				model:HookScript("OnModelLoaded", function()
					if pendingOutfit == setID and not outfitLoadDressed then
						outfitLoadDressed = true
						DressOutfit(setID)
					end
				end)

				-- Find a player by GUID
				local function FindGUID(guid)
					for void, token in ipairs({"target", "mouseover", "focus"}) do
						if UnitExists(token) and UnitGUID(token) == guid then return token end
					end
				end

				-- Get the gear of another player (they are inspected first, so they need to be close by), then run func with it
				local fetchFrame = CreateFrame("Frame")
				local fetchID, fetchGUID, fetchOwn = 0, nil, false
				local function FetchGear(unit, func)
					fetchID = fetchID + 1
					local myID, guid = fetchID, UnitGUID(unit)
					fetchFrame:UnregisterEvent("INSPECT_READY")
					fetchGUID = nil
					StopInspect() -- The model's own inspect stops waiting (so it does not clear the reply before it is read here)
					-- Gear Show info cards already has for them
					local function Known()
						local cached = LeaPlusLC.IDGear and LeaPlusLC.IDGear[guid]
						if cached and cached.complete then
							local gear = {}
							for void, slotID in ipairs(slotOrder) do gear[slotID] = cached[slotID] end
							return gear
						end
					end
					local function Failed(tooFar)
						if tooFar then
							DressupGear.Message(L["Target is too far away."])
						else
							DressupGear.Message(L["Their gear could not be read.  Move closer and try again."])
						end
					end
					-- The inspect window is open, so their gear can be read now
					if InspectFrame and InspectFrame:IsShown() then
						local gear = UnitLinks(unit)
						if next(gear) then func(gear) elseif Known() then func(Known()) else Failed() end
						return
					end
					-- Inspect them
					local card = LeaPlusLC.IDCard
					local cardGUID = card and card.inspectGUID
					local canAsk = NotifyInspect and CanInspect and CanInspect(unit) and (not cardGUID or cardGUID == guid) and (cardGUID or InInspectRange(unit))
					if not canAsk then
						if Known() then func(Known()) else Failed(CanInspect and CanInspect(unit) and not InInspectRange(unit)) end
						return
					end
					fetchGUID, fetchOwn = guid, not cardGUID
					fetchFrame:SetScript("OnEvent", function(self, event, readyGUID)
						if readyGUID ~= fetchGUID or myID ~= fetchID then return end
						self:UnregisterEvent("INSPECT_READY")
						fetchGUID = nil
						local pending = LeaPlusLC.IDInspectPending
						if fetchOwn and pending and pending.guid == guid then LeaPlusLC.IDInspectPending = nil end
						-- Read the gear (items the game has not loaded yet are read again, for up to 3 seconds)
						local tries = 0
						local function Read()
							if myID ~= fetchID then return end
							tries = tries + 1
							local found = FindGUID(guid)
							local gear, complete = {}, false
							if found then gear, complete = UnitLinks(found) end
							if found and not complete and tries < 12 then C_Timer.After(0.25, Read) return end
							if fetchOwn then ClearInspect() end
							if next(gear) then func(gear) elseif Known() then func(Known()) else Failed() end
						end
						Read()
					end)
					fetchFrame:RegisterEvent("INSPECT_READY")
					if fetchOwn then
						local pending = LeaPlusLC.IDInspectPending
						if not (pending and pending.guid == guid and GetTime() - pending.time < 4) then
							LeaPlusLC.IDInspectPending = {guid = guid, time = GetTime()}
							NotifyInspect(unit)
						end
					end
					-- No reply
					C_Timer.After(5, function()
						if myID == fetchID and fetchGUID == guid then
							fetchFrame:UnregisterEvent("INSPECT_READY")
							fetchGUID = nil
							if Known() then func(Known()) else Failed() end
						end
					end)
				end

				-- Show my outfit on the target
				function DressupGear.MyOutfitOnTarget()
					if not UnitIsPlayer("target") then return end
					local gear = UnitLinks("player")
					fetchID = fetchID + 1 -- Anything still being fetched is no longer wanted
					model:SetUnit("target")
					ApplyOutfit(gear)
					SetMode("myOutfitOnTarget")
				end

				-- Show the target's outfit on me (done runs once it is showing)
				function DressupGear.TargetOutfitOnMe(done)
					if not UnitIsPlayer("target") then return end
					if UnitIsUnit("target", "player") then model:SetUnit("player") done() return end
					FetchGear("target", function(gear)
						if not DressUpFrame:IsShown() then return end
						model:SetUnit("player")
						ApplyOutfit(gear)
						SetMode("targetOutfitOnMe")
						done()
					end)
				end

				-- Function to set item buttons
				local function ToggleItemButtons()
					-- The buttons are inside the columns, so showing or hiding the columns does the buttons too
					for i = 1, #columns do columns[i]:SetShown(LeaPlusLC["DressupItemButtons"] == "On" and columns[i].count > 0) end
				end
				LeaPlusLC.ToggleItemButtons = ToggleItemButtons

				-- Set item buttons for option click, startup, reset click and preset click
				LeaPlusCB["DressupItemButtons"]:HookScript("OnClick", ToggleItemButtons)
				ToggleItemButtons()
				DressupPanel.r:HookScript("OnClick", function()
					LeaPlusLC["DressupItemButtons"] = "On"
					ToggleItemButtons()
					DressupPanel:Hide(); DressupPanel:Show()
				end)
				LeaPlusCB["EnhanceDressupBtn"]:HookScript("OnClick", function()
					if IsShiftKeyDown() and IsControlKeyDown() then
						LeaPlusLC["DressupItemButtons"] = "On"
						ToggleItemButtons()
					end
				end)

			end

			----------------------------------------------------------------------
			-- Animation slider (must be before bottom row buttons)
			----------------------------------------------------------------------

			local animTable = {0, 4, 5, 143, 119, 26, 25, 27, 28, 108, 120, 51, 124, 52, 125, 126, 62, 63, 41, 42, 43, 44, 132, 38, 14, 115, 193, 48, 110, 109, 134, 197, 0}
			local lastSetting

			LeaPlusLC["DressupAnim"] = 0 -- Defined here since the setting is not saved
			LeaPlusLC:MakeSL(DressUpFrame, "DressupAnim", "", 1, #animTable - 1, 1, 356, -92, "%.0f")
			LeaPlusCB["DressupAnim"]:ClearAllPoints()
			LeaPlusCB["DressupAnim"]:SetPoint("TOP", 35, -38) -- At the top, above the model (the title goes to the left of it and the number to the right)

			-- Hide the Ctrl-click message at the top (the slider is there now)
			if DressUpFrameDescriptionText then DressUpFrameDescriptionText:Hide() end
			LeaPlusCB["DressupAnim"]:SetWidth(150)

			-- Title to the left of the slider (part of the slider, so it hides with it)
			local animTitle = LeaPlusCB["DressupAnim"]:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
			animTitle:SetPoint("RIGHT", LeaPlusCB["DressupAnim"], "LEFT", -8, 0)
			animTitle:SetText(L["Animation"])
			LeaPlusCB["DressupAnim"]:SetFrameLevel(5)
			LeaPlusCB["DressupAnim"]:HookScript("OnValueChanged", function(self, setting)
				local playerActor = DressUpFrame.DressUpModel
				setting = math.floor(setting + 0.5)
				if playerActor and setting ~= lastSetting then
					lastSetting = setting
					DressUpFrame.DressUpModel:SetAnimation(animTable[setting], 0, 1, 1)
					-- print(animTable[setting]) -- Debug
				end
			end)

			-- Function to show animation control
			local function SetAnimationSlider()
				if LeaPlusLC["DressupAnimControl"] == "On" then
					LeaPlusCB["DressupAnim"]:Show()
				else
					LeaPlusCB["DressupAnim"]:Hide()
				end
				LeaPlusCB["DressupAnim"]:SetValue(1)
			end

			-- Set animation control with option, startup, preset and reset
			LeaPlusCB["DressupAnimControl"]:HookScript("OnClick", SetAnimationSlider)
			SetAnimationSlider()
			LeaPlusCB["EnhanceDressupBtn"]:HookScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					LeaPlusLC["DressupAnimControl"] = "On"
					SetAnimationSlider()
				end
			end)
			DressupPanel.r:HookScript("OnClick", function()
				LeaPlusLC["DressupAnimControl"] = "On"
				SetAnimationSlider()
				DressupPanel:Hide(); DressupPanel:Show()
			end)

			-- Reset animation when dressup frame is shown and model is reset
			hooksecurefunc(DressUpFrame, "Show", SetAnimationSlider)
			DressUpFrameResetButton:HookScript("OnClick", SetAnimationSlider)

			-- Skin slider for ElvUI
			if LeaPlusLC.ElvUI then
				_G.LeaPlusGlobalDressupAnim = LeaPlusCB["DressupAnim"]
				LeaPlusLC.ElvUI:GetModule("Skins"):HandleSliderFrame(_G.LeaPlusGlobalDressupAnim, false)
			end

			----------------------------------------------------------------------
			-- Bottom row buttons
			----------------------------------------------------------------------

			-- Function to modify a button
			local function SetButton(where, text, tip)
				if text ~= "" then
					where:SetText(L[text])
					where:SetWidth(where:GetFontString():GetStringWidth() + 20)
				end
				where:HookScript("OnEnter", function()
					GameTooltip:SetOwner(where, "ANCHOR_NONE")
					GameTooltip:SetPoint("BOTTOM", where, "TOP", 0, 10)
					GameTooltip:SetText(L[tip], nil, nil, nil, nil, true)
				end)
				where:HookScript("OnLeave", GameTooltip_Hide)
			end

			-- Close
			SetButton(DressUpFrameCancelButton, "", "Close")
			DressUpFrameCancelButton:ClearAllPoints()
			DressUpFrameCancelButton:SetPoint("BOTTOMRIGHT", DressUpFrame, "BOTTOMRIGHT", -4, 4)

			-- Reset
			SetButton(DressUpFrameResetButton, "", "Reset")

			-- Function to set the animation again after the model has changed
			local function ResetAnimation()
				local playerActor = DressUpFrame.DressUpModel
				playerActor:SetAnimation(0)
				C_Timer.After(0.1, function()
					playerActor:SetAnimation(animTable[math.floor(LeaPlusCB["DressupAnim"]:GetValue() + 0.5)], 0, 1, 1)
				end)
			end

			-- Bottom bar: picture buttons in the same style as the slot buttons, then Reset and Close
			local size, gap = 30, 6
			local mePics, targetPics, shades = {}, {}, {}

			-- Grey out a button's pictures when it is disabled
			local function Shade(btn)
				local on = btn:IsEnabled()
				for void, pic in ipairs({btn.t, btn.badge}) do
					pic:SetDesaturated(not on)
					pic:SetAlpha(on and 1 or 0.45)
				end
			end

			-- Create a bar button (title and optional text for the tooltip, isMode for buttons that stay lit while the model shows that)
			local barCount = 0
			local function MakeBarButton(title, text, isMode)
				local btn = CreateFrame(isMode and "CheckButton" or "Button", nil, DressUpFrame)
				PaperDollButton(btn, size)
				if isMode then
					btn:SetCheckedTexture("Interface\\Buttons\\CheckButtonHilight")
					btn:GetCheckedTexture():SetBlendMode("ADD")
				end
				btn:SetPoint("BOTTOMLEFT", DressUpFrame, "BOTTOMLEFT", 12 + barCount * (size + gap), 7)
				barCount = barCount + 1
				btn:SetMotionScriptsWhileDisabled(true) -- Tooltip shows while greyed out
				btn:SetScript("OnEnter", function(self)
					GameTooltip:SetOwner(self, "ANCHOR_NONE")
					GameTooltip:SetPoint("BOTTOM", self, "TOP", 0, 10)
					GameTooltip:SetText(L[title], 1, 1, 1)
					if text then GameTooltip:AddLine(L[text], nil, nil, nil, true) end
					if self.why and not self:IsEnabled() then GameTooltip:AddLine(self.why, 1, 0.3, 0.3, true) end
					GameTooltip:Show()
				end)
				btn:SetScript("OnLeave", GameTooltip_Hide)
				-- Small round picture in the corner (whose gear is being worn)
				btn.badge = btn:CreateTexture(nil, "OVERLAY", nil, 2)
				btn.badge:SetSize(15, 15)
				btn.badge:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 3, -3)
				btn.badge:Hide()
				btn:SetScript("OnEnable", Shade)
				btn:SetScript("OnDisable", Shade)
				tinsert(shades, btn)
				return btn
			end

			-- Make a picture round (portraits)
			local circle = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
			local function MakeRound(btn, pic)
				local mask = btn:CreateMaskTexture()
				mask:SetTexture(circle, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
				mask:SetAllPoints(pic)
				pic:AddMaskTexture(mask)
			end

			-- Show a small portrait in the corner of a button (with a dark ring so it stands apart from the big picture)
			local function AddBadge(btn, list)
				local ring = btn:CreateTexture(nil, "OVERLAY", nil, 1)
				ring:SetTexture(circle)
				ring:SetVertexColor(0, 0, 0, 1)
				ring:SetSize(18, 18)
				ring:SetPoint("CENTER", btn.badge, "CENTER")
				MakeRound(btn, btn.badge)
				btn.badge:Show()
				tinsert(list, btn.badge)
			end

			local meBtn = MakeBarButton("Show me", nil, true)
			tinsert(mePics, meBtn.t)

			local targetBtn = MakeBarButton("Show target", nil, true)
			tinsert(targetPics, targetBtn.t)

			local myGearBtn = MakeBarButton("Show my gear on target", nil, true)
			tinsert(targetPics, myGearBtn.t)
			AddBadge(myGearBtn, mePics)

			local theirGearBtn = MakeBarButton("Show target gear on me", "Target needs to be close by.", true)
			tinsert(mePics, theirGearBtn.t)
			AddBadge(theirGearBtn, targetPics)

			local infoBtn = MakeBarButton("Show info card", nil, false)
			infoBtn.t:SetTexture("Interface\\Icons\\INV_Misc_Note_02")

			-- Reset and Close on the right, given the same look as the other buttons
			-- These are Blizzard's own buttons, so they are only re-skinned (their red art is made see-through and pictures are laid
			-- over it): clicking them still runs Blizzard's own code, nothing is replaced and nothing is written onto them
			local skinParts = {}
			local function SkinBlizzardButton(btn, file, picSize)
				btn:SetText("")
				btn:SetSize(size, size)
				for void, region in ipairs({btn:GetRegions()}) do
					if region:IsObjectType("Texture") then region:SetAlpha(0) end -- Stays see-through when the game changes the art (pressed, disabled)
				end
				local parts = {}
				parts.bg = btn:CreateTexture(nil, "BACKGROUND", nil, 7)
				parts.bg:SetAllPoints()
				parts.bg:SetColorTexture(0, 0, 0, 0.7)
				parts.pic = btn:CreateTexture(nil, "BORDER")
				parts.pic:SetSize(picSize, picSize)
				parts.pic:SetPoint("CENTER")
				parts.pic:SetTexture(file)
				parts.border = btn:CreateTexture(nil, "ARTWORK")
				parts.border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
				parts.border:SetSize(size * 64 / 37, size * 64 / 37)
				parts.border:SetPoint("CENTER", 0, -size / 37)
				parts.pushed = btn:CreateTexture(nil, "OVERLAY")
				parts.pushed:SetAllPoints()
				parts.pushed:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
				parts.pushed:Hide()
				parts.glow = btn:CreateTexture(nil, "OVERLAY")
				parts.glow:SetAllPoints()
				parts.glow:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
				parts.glow:SetBlendMode("ADD")
				parts.glow:Hide()
				skinParts[btn] = parts
				btn:HookScript("OnEnter", function() parts.glow:Show() end)
				btn:HookScript("OnLeave", function() parts.glow:Hide() parts.pushed:Hide() end)
				btn:HookScript("OnMouseDown", function(self) if self:IsEnabled() then parts.pushed:Show() end end)
				btn:HookScript("OnMouseUp", function() parts.pushed:Hide() end)
			end

			-- Close: a red cross
			SkinBlizzardButton(DressUpFrameCancelButton, "Interface\\RaidFrame\\ReadyCheck-NotReady", 20)
			DressUpFrameCancelButton:ClearAllPoints()
			DressUpFrameCancelButton:SetPoint("BOTTOMRIGHT", DressUpFrame, "BOTTOMRIGHT", -12, 7)

			-- Reset: a circular arrow
			SkinBlizzardButton(DressUpFrameResetButton, "Interface\\Buttons\\UI-RefreshButton", 20)
			DressUpFrameResetButton:ClearAllPoints()
			DressUpFrameResetButton:SetPoint("RIGHT", DressUpFrameCancelButton, "LEFT", -gap, 0)

			-- Update the buttons: pictures, greyed out ones and the one for what the model shows
			local modeButtons = {me = meBtn, target = targetBtn, myOutfitOnTarget = myGearBtn, targetOutfitOnMe = theirGearBtn}
			local function UpdateButtons()
				local hasTarget = UnitIsPlayer("target") and true or false
				for void, pic in ipairs(mePics) do SetPortraitTexture(pic, "player") end
				for void, pic in ipairs(targetPics) do
					if hasTarget then SetPortraitTexture(pic, "target") else pic:SetTexture("Interface\\CharacterFrame\\TempPortrait") end
				end
				for void, btn in ipairs({targetBtn, myGearBtn, theirGearBtn}) do
					btn:SetEnabled(hasTarget)
					btn.why = L["Target a player to use this."]
				end
				infoBtn:SetEnabled(LeaPlusLC.ShowInfoCardForUnit ~= nil)
				if LeaPlusLC["ShowInfoCards"] == "On" then
					infoBtn.why = L["Reload your UI to use this."]
				else
					infoBtn.why = L["This needs Show info cards to be turned on in Leatrix Plus."]
				end
				local mode = DressupGear.GetMode()
				for key, btn in pairs(modeButtons) do btn:SetChecked(key == mode) end
				for void, btn in ipairs(shades) do Shade(btn) end
			end
			DressupGear.OnModeChanged = UpdateButtons

			-- Clicks (each then shows what the model really shows, as clicking a check button would otherwise flip it)
			meBtn:SetScript("OnClick", function()
				DressUpFrame.DressUpModel:SetUnit("player")
				ResetAnimation()
				UpdateButtons()
			end)
			targetBtn:SetScript("OnClick", function()
				if UnitIsPlayer("target") then
					DressUpFrame.DressUpModel:SetUnit("target")
					ResetAnimation()
				end
				UpdateButtons()
			end)
			myGearBtn:SetScript("OnClick", function()
				if UnitIsPlayer("target") then
					DressupGear.MyOutfitOnTarget()
					ResetAnimation()
				end
				UpdateButtons()
			end)
			theirGearBtn:SetScript("OnClick", function()
				DressupGear.TargetOutfitOnMe(ResetAnimation) -- The target is inspected first, so this can take a moment
				UpdateButtons()
			end)
			infoBtn:SetScript("OnClick", function()
				if not LeaPlusLC.ShowInfoCardForUnit then return end
				local unit = DressupGear.GetUnit()
				if unit then
					LeaPlusLC.ShowInfoCardForUnit(unit)
				else
					DressupGear.Message(L["Target that player to show their info card."])
				end
			end)

			-- The bottom bar sits above the model (it overlaps the bottom of the model area a little)
			local barLevel = DressUpFrame.DressUpModel:GetFrameLevel() + 5
			for void, btn in ipairs({meBtn, targetBtn, myGearBtn, theirGearBtn, infoBtn, DressUpFrameResetButton, DressUpFrameCancelButton}) do
				btn:SetFrameLevel(barLevel)
			end

			-- Grey background behind the bottom bar (the frame's own grey, raised to cover the bottom of the model area, as the bar
			-- buttons are taller than Blizzard's own buttons and the edge of the model area would otherwise run through them)
			do
				local barBg = CreateFrame("Frame", nil, DressUpFrame)
				barBg:SetFrameLevel(barLevel - 1) -- Above the model, below the buttons
				barBg:SetPoint("LEFT", DressUpFrame.Inset or DressUpFrame, "LEFT", DressUpFrame.Inset and 0 or 4, 0)
				barBg:SetPoint("RIGHT", DressUpFrame.Inset or DressUpFrame, "RIGHT", DressUpFrame.Inset and 0 or -4, 0)
				barBg:SetPoint("BOTTOM", DressUpFrame, "BOTTOM", 0, 3)
				barBg:SetPoint("TOP", meBtn, "TOP", 0, 4)
				local tex = barBg:CreateTexture(nil, "BACKGROUND")
				tex:SetAllPoints()
				local frameBg = DressUpFrame.Bg
				local atlas = frameBg and frameBg.GetAtlas and frameBg:GetAtlas()
				if atlas then
					tex:SetAtlas(atlas)
					tex:SetHorizTile(frameBg:GetHorizTile())
					tex:SetVertTile(frameBg:GetVertTile())
				elseif frameBg and frameBg:GetTexture() then
					tex:SetTexture(frameBg:GetTexture(), frameBg:GetHorizTile() and "REPEAT" or nil, frameBg:GetVertTile() and "REPEAT" or nil)
					tex:SetHorizTile(frameBg:GetHorizTile())
					tex:SetVertTile(frameBg:GetVertTile())
				else
					tex:SetColorTexture(0.1, 0.1, 0.1, 1)
				end
				if frameBg then tex:SetVertexColor(frameBg:GetVertexColor()) end

				-- Border line along the top of the grey, copied from the bottom border of the model area (the inset), so it looks the
				-- same as the default line (the pieces keep their own positions, moved from the bottom of the inset to the top of the grey)
				local inset = DressUpFrame.Inset
				local source = inset and inset.NineSlice
				local keys = {"BottomLeftCorner", "BottomEdge", "BottomRightCorner"}
				if not (source and source.BottomEdge) then
					source = inset
					keys = {"InsetBorderBottomLeft", "InsetBorderBottom", "InsetBorderBottomRight"}
				end
				local copies = {}
				for void, key in ipairs(keys) do
					local piece = source and source[key]
					if piece and piece.GetTexture then
						local t = barBg:CreateTexture(nil, "BORDER")
						local pieceAtlas = piece.GetAtlas and piece:GetAtlas()
						if pieceAtlas then
							t:SetAtlas(pieceAtlas)
						else
							t:SetTexture(piece:GetTexture())
							t:SetTexCoord(piece:GetTexCoord())
						end
						t:SetHorizTile(piece:GetHorizTile())
						t:SetVertTile(piece:GetVertTile())
						t:SetVertexColor(piece:GetVertexColor())
						t:SetSize(piece:GetSize())
						copies[piece] = t
					end
				end
				if next(copies) then
					for piece, t in pairs(copies) do
						for i = 1, piece:GetNumPoints() do
							local point, relativeTo, relativePoint, x, y = piece:GetPoint(i)
							if copies[relativeTo] then
								-- Anchored to another piece, so anchor to its copy
								t:SetPoint(point, copies[relativeTo], relativePoint, x, y)
							else
								-- Anchored to the inset, so anchor to the top of the grey instead of the bottom of the inset
								t:SetPoint(point, barBg, (gsub(relativePoint, "BOTTOM", "TOP")), x, y)
							end
						end
					end
				else
					-- No border pieces found, so draw a plain line
					local line = barBg:CreateTexture(nil, "BORDER")
					line:SetColorTexture(0.35, 0.35, 0.35, 1)
					line:SetPoint("TOPLEFT"); line:SetPoint("TOPRIGHT")
					line:SetHeight(2)
				end
			end

			-- Only watch the target while the dressing room is open
			local watcher = CreateFrame("Frame")
			watcher:SetScript("OnEvent", UpdateButtons)
			DressUpFrame:HookScript("OnShow", function()
				watcher:RegisterEvent("PLAYER_TARGET_CHANGED")
				watcher:RegisterUnitEvent("UNIT_PORTRAIT_UPDATE", "player", "target")
				UpdateButtons()
			end)
			DressUpFrame:HookScript("OnHide", function() watcher:UnregisterAllEvents() end)
			UpdateButtons()

			-- Change player actor to player when reset button is clicked (needed because target button changes it)
			DressUpFrameResetButton:HookScript("OnClick", function()
				DressUpFrame.DressUpModel:SetUnit("player")
			end)

			-- Auction house
			local BtnStrata, BtnLevel = SideDressUpModelResetButton:GetFrameStrata(), SideDressUpModelResetButton:GetFrameLevel()

			-- Add buttons to auction house dressup frame
			LeaPlusLC:CreateButton("DressUpSideBtn", SideDressUpModelResetButton, "Tabard", "BOTTOMLEFT", -36, -31, 60, 22, false, "")
			LeaPlusCB["DressUpSideBtn"]:SetFrameStrata(BtnStrata)
			LeaPlusCB["DressUpSideBtn"]:SetFrameLevel(BtnLevel)
			LeaPlusCB["DressUpSideBtn"]:SetScript("OnClick", function()
				SideDressUpModel:UndressSlot(19)
			end)

			LeaPlusLC:CreateButton("DressUpSideNudeBtn", SideDressUpModelResetButton, "Nude", "BOTTOMRIGHT", 39, -31, 60, 22, false, "")
			LeaPlusCB["DressUpSideNudeBtn"]:SetFrameStrata(BtnStrata)
			LeaPlusCB["DressUpSideNudeBtn"]:SetFrameLevel(BtnLevel)
			LeaPlusCB["DressUpSideNudeBtn"]:SetScript("OnClick", function()
				SideDressUpModel:Undress()
			end)


			----------------------------------------------------------------------
			-- Controls
			----------------------------------------------------------------------

			-- Hide model rotation controls
			CharacterModelFrameRotateLeftButton:HookScript("OnShow", CharacterModelFrameRotateLeftButton.Hide)
			CharacterModelFrameRotateRightButton:HookScript("OnShow", CharacterModelFrameRotateRightButton.Hide)
			DressUpModelFrameRotateLeftButton:HookScript("OnShow", DressUpModelFrameRotateLeftButton.Hide)
			DressUpModelFrameRotateRightButton:HookScript("OnShow", DressUpModelFrameRotateRightButton.Hide)
			SideDressUpModelControlFrame:HookScript("OnShow", SideDressUpModelControlFrame.Hide)

			----------------------------------------------------------------------
			-- Toggle character attributes (supports CharacterStatsClassic)
			----------------------------------------------------------------------

			local function ToggleStats()
				if LeaPlusLC["HideDressupStats"] == "On" then
					CharacterResistanceFrame:Hide()
					if CSC_HideStatsPanel then
						-- CharacterStatsClassic is installed
						RunScript('CSC_HideStatsPanel()')
					else
						-- CharacterStatsClassic is not installed
						CharacterAttributesFrame:Hide()
					end
					CharacterModelFrame:ClearAllPoints()
					CharacterModelFrame:SetPoint("TOPLEFT", PaperDollFrame, 66, -76)
					CharacterModelFrame:SetPoint("BOTTOMRIGHT", PaperDollFrame, -86, 116) -- Down to the line below the slot columns
					if LeaPlusLC["ShowVanityControls"] == "On" then
						LeaPlusCB["ShowHelm"]:Hide()
						LeaPlusCB["ShowCloak"]:Hide()
					end
				else
					CharacterResistanceFrame:Show()
					if CSC_ShowStatsPanel then
						-- CharacterStatsClassic is installed
						RunScript('CSC_ShowStatsPanel()')
					else
						-- CharacterStatsClassic is not installed
						CharacterAttributesFrame:Show()
					end
					CharacterModelFrame:ClearAllPoints()
					CharacterModelFrame:SetPoint("TOPLEFT", PaperDollFrame, 66, -76)
					CharacterModelFrame:SetPoint("BOTTOMRIGHT", PaperDollFrame, -86, 220)
					if LeaPlusLC["ShowVanityControls"] == "On" then
						LeaPlusCB["ShowHelm"]:Show()
						LeaPlusCB["ShowCloak"]:Show()
					end
				end
			end

			-- Toggle stats with middle mouse button
			CharacterModelFrame:HookScript("OnMouseDown", function(self, btn)
				if btn == "MiddleButton" then
					if LeaPlusLC["HideDressupStats"] == "On" then LeaPlusLC["HideDressupStats"] = "Off" else LeaPlusLC["HideDressupStats"] = "On" end
					ToggleStats()
				end
			end)
			ToggleStats()

			-- Create toggle stats button
			local toggleButton = CreateFrame("Button", nil, PaperDollFrame)
			toggleButton:SetSize(36, 36)
			toggleButton:SetPoint("TOPLEFT", PaperDollFrame, "TOPLEFT", 64, -45)
			toggleButton:SetNormalTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-RotationRight-Big-Up")
			toggleButton:SetHighlightTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-RotationRight-Big-Up")
			toggleButton:SetPushedTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-RotationRight-Big-Up")
			toggleButton:SetScript("OnEnter", function()
				GameTooltip:SetOwner(toggleButton, "ANCHOR_NONE")
				GameTooltip:SetPoint("BOTTOMLEFT", toggleButton, "BOTTOMRIGHT", 0, 0)
				GameTooltip:SetText(L["Toggle character stats"], nil, nil, nil, nil, true)
				GameTooltip:Show()
			end)
			toggleButton:SetScript("OnLeave", GameTooltip_Hide)
			toggleButton:SetScript("OnClick", function()
				if LeaPlusLC["HideDressupStats"] == "On" then LeaPlusLC["HideDressupStats"] = "Off" else LeaPlusLC["HideDressupStats"] = "On" end
				ToggleStats()
			end)

			----------------------------------------------------------------------
			-- Enable zooming and panning
			----------------------------------------------------------------------

			-- Enable zooming for character frame and dressup frame
			CharacterModelFrame:EnableMouseWheel(true)
			CharacterModelFrame:HookScript("OnMouseWheel", Model_OnMouseWheel)
			DressUpModelFrame:EnableMouseWheel(true)
			DressUpModelFrame:HookScript("OnMouseWheel", Model_OnMouseWheel)

			-- Enable panning for character frame
			CharacterModelFrame:HookScript("OnMouseDown", function(self, btn)
				if btn == "RightButton" then
					Model_StartPanning(self)
				end
			end)

			CharacterModelFrame:HookScript("OnMouseUp", function(self, btn)
				Model_StopPanning(self)
			end)

			-- Enable panning for dressup frame
			DressUpModelFrame:HookScript("OnMouseDown", function(self, btn)
				if btn == "RightButton" then
					Model_StartPanning(self)
				end
			end)

			DressUpModelFrame:HookScript("OnMouseUp", function(self, btn)
				Model_StopPanning(self)
			end)

			DressUpModelFrame:ClearAllPoints()
			DressUpModelFrame:SetPoint("TOPLEFT", DressUpFrame, 8, -64)
			DressUpModelFrame:SetPoint("BOTTOMRIGHT", DressUpFrame, -8, 28) -- Down to the bottom of the model area, the same as the default UI

			-- Reset dressup frame when reset button clicked
			DressUpFrameResetButton:HookScript("OnClick", function()
				DressUpModelFrame.rotation = 0
				DressUpModelFrame:SetRotation(0)
				DressUpModelFrame:SetPosition(0, 0, 0)
				DressUpModelFrame.zoomLevel = 0
				DressUpModelFrame:SetPortraitZoom(0)
				DressUpModelFrame:RefreshCamera()
			end)

			-- Reset side dressup when reset button clicked
			SideDressUpModelResetButton:HookScript("OnClick", function()
				SideDressUpModel.rotation = 0
				SideDressUpModel:SetRotation(0)
				SideDressUpModel:SetPosition(0, 0, 0)
				SideDressUpModel.zoomLevel = 0
				SideDressUpModel:SetPortraitZoom(0)
				SideDressUpModel:RefreshCamera()
			end)

			----------------------------------------------------------------------
			-- Inspect system
			----------------------------------------------------------------------

			-- Inspect System
			EventUtil.ContinueOnAddOnLoaded("Blizzard_InspectUI",function()

				-- Hide model rotation controls
				InspectModelFrameRotateLeftButton:Hide()
				InspectModelFrameRotateRightButton:Hide()

				-- Enable zooming
				InspectModelFrame:EnableMouseWheel(true)
				InspectModelFrame:HookScript("OnMouseWheel", Model_OnMouseWheel)

				-- Enable panning
				InspectModelFrame:HookScript("OnMouseDown", function(self, btn)
					if btn == "RightButton" then
						Model_StartPanning(self)
					end
				end)

				InspectModelFrame:HookScript("OnMouseUp", function(self, btn)
					Model_StopPanning(self)
				end)

			end)

		end

		----------------------------------------------------------------------
		-- Automatically release in battlegrounds
		----------------------------------------------------------------------

		do

			-- Create configuration panel
			local ReleasePanel = LeaPlusLC:CreatePanel("Release in PvP", "ReleasePanel")

			LeaPlusLC:MakeTx(ReleasePanel, "Settings", 16, -72)
			LeaPlusLC:MakeCB(ReleasePanel, "AutoReleaseNoAlterac", "Exclude Alterac Valley", 16, -92, false, "If checked, you will not release automatically in Alterac Valley.")

			LeaPlusLC:MakeTx(ReleasePanel, "Delay", 356, -72)
			LeaPlusLC:MakeSL(ReleasePanel, "AutoReleaseDelay", "Drag to set the number of milliseconds before you are automatically released.|n|nYou can hold down shift as the timer is ending to cancel the automatic release.", 200, 3000, 100, 356, -92, "%.0f")

			-- Help button hidden
			ReleasePanel.h:Hide()

			-- Back button handler
			ReleasePanel.b:SetScript("OnClick", function()
				ReleasePanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page1"]:Show();
				return
			end)

			-- Reset button handler
			ReleasePanel.r:SetScript("OnClick", function()

				-- Reset checkboxes
				LeaPlusLC["AutoReleaseNoAlterac"] = "Off"
				LeaPlusLC["AutoReleaseDelay"] = 200

				-- Refresh panel
				ReleasePanel:Hide(); ReleasePanel:Show()

			end)

			-- Show panal when options panel button is clicked
			LeaPlusCB["AutoReleasePvPBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					LeaPlusLC["AutoReleaseNoAlterac"] = "Off"
					LeaPlusLC["AutoReleaseDelay"] = 200
				else
					ReleasePanel:Show()
					LeaPlusLC:HideFrames()
				end
			end)

			-- Release in battlegrounds
			hooksecurefunc("StaticPopup_Show", function(sType)
				if sType and sType == "DEATH" and LeaPlusLC["AutoReleasePvP"] == "On" then
					if C_DeathInfo.GetSelfResurrectOptions() and #C_DeathInfo.GetSelfResurrectOptions() > 0 then return end
					local InstStat, InstType = IsInInstance()
					if InstStat and InstType == "pvp" then
						-- Exclude specific maps
						local mapID = C_Map.GetBestMapForUnit("player") or nil
						if mapID then
							if mapID == 1459 and LeaPlusLC["AutoReleaseNoAlterac"] == "On" then return end -- Alterac Valley
						end
						-- Release automatically
						local delay = LeaPlusLC["AutoReleaseDelay"] / 1000
						C_Timer.After(delay, function()
							local dialog = StaticPopup_Visible("DEATH")
							if dialog then
								if IsShiftKeyDown() then
									ActionStatus_DisplayMessage(L["Automatic Release Cancelled"], true)
								else
									StaticPopup_OnClick(_G[dialog], 1)
								end
							end
						end)
					end
				end
			end)

		end

		----------------------------------------------------------------------
		--	Enhance trainers
		----------------------------------------------------------------------

		if LeaPlusLC["EnhanceTrainers"] == "On" then

			-- Create configuration panel
			local TrainerPanel = LeaPlusLC:CreatePanel("Enhance trainers", "TrainerPanel")

			LeaPlusLC:MakeTx(TrainerPanel, "Settings", 16, -72)
			LeaPlusLC:MakeCB(TrainerPanel, "ShowTrainAllBtn", "Show train all skills button", 16, -92, false, "If checked, a train all skills button will be shown in the skill trainer frame allowing you to train all available skills instantly.")

			-- Help button hidden
			TrainerPanel.h:Hide()

			-- Back button handler
			TrainerPanel.b:SetScript("OnClick", function()
				TrainerPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page5"]:Show()
				return
			end)

			-- Reset button handler
			TrainerPanel.r:SetScript("OnClick", function()

				-- Reset controls
				LeaPlusLC["ShowTrainAllBtn"] = "On"

				-- Refresh configuration panel
				TrainerPanel:Hide(); TrainerPanel:Show()

			end)

			-- Show configuration panal when options panel button is clicked
			LeaPlusCB["EnhanceTrainersBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					LeaPlusLC["ShowTrainAllBtn"] = "On"
				else
					TrainerPanel:Show()
					LeaPlusLC:HideFrames()
				end
			end)

			-- Set increased height of skill trainer frame and maximum number of skills listed
			local tall, numTallTrainers = 73, 17

			----------------------------------------------------------------------
			--	Skill trainer frame
			----------------------------------------------------------------------

			EventUtil.ContinueOnAddOnLoaded("Blizzard_TrainerUI",function()

				-- Make the frame double-wide
				UIPanelWindows["ClassTrainerFrame"] = {area = "override", pushable = 0, xoffset = -16, yoffset = 12, bottomClampOverride = 140 + 12, width = 685, height = 487, whileDead = 1}

				-- Size the frame
				_G["ClassTrainerFrame"]:SetSize(714, 487 + tall)

				-- Lower title text slightly
				_G["ClassTrainerNameText"]:ClearAllPoints()
				_G["ClassTrainerNameText"]:SetPoint("TOP", _G["ClassTrainerFrame"], "TOP", 0, -18)

				-- Expand the skill list to full height
				_G["ClassTrainerListScrollFrame"]:ClearAllPoints()
				_G["ClassTrainerListScrollFrame"]:SetPoint("TOPLEFT", _G["ClassTrainerFrame"], "TOPLEFT", 25, -75)
				_G["ClassTrainerListScrollFrame"]:SetSize(295, 336 + tall)

				-- Create additional list rows
				do

					local oldSkillsDisplayed = CLASS_TRAINER_SKILLS_DISPLAYED

					-- Position existing buttons
					for i = 1 + 1, CLASS_TRAINER_SKILLS_DISPLAYED do
						_G["ClassTrainerSkill" .. i]:ClearAllPoints()
						_G["ClassTrainerSkill" .. i]:SetPoint("TOPLEFT", _G["ClassTrainerSkill" .. (i - 1)], "BOTTOMLEFT", 0, 1)
					end

					-- Create and position new buttons
					_G.CLASS_TRAINER_SKILLS_DISPLAYED = _G.CLASS_TRAINER_SKILLS_DISPLAYED + numTallTrainers
					for i = oldSkillsDisplayed + 1, CLASS_TRAINER_SKILLS_DISPLAYED do
						local button = CreateFrame("Button", "ClassTrainerSkill" .. i, ClassTrainerFrame, "ClassTrainerSkillButtonTemplate")
						button:SetID(i)
						button:Hide()
						button:ClearAllPoints()
						button:SetPoint("TOPLEFT", _G["ClassTrainerSkill" .. (i - 1)], "BOTTOMLEFT", 0, 1)
					end

					hooksecurefunc("ClassTrainer_SetToTradeSkillTrainer", function()
						_G.CLASS_TRAINER_SKILLS_DISPLAYED = _G.CLASS_TRAINER_SKILLS_DISPLAYED + numTallTrainers
						ClassTrainerListScrollFrame:SetHeight(336 + tall)
						ClassTrainerDetailScrollFrame:SetHeight(336 + tall)
					end)

					hooksecurefunc("ClassTrainer_SetToClassTrainer", function()
						_G.CLASS_TRAINER_SKILLS_DISPLAYED = _G.CLASS_TRAINER_SKILLS_DISPLAYED + numTallTrainers - 1
						ClassTrainerListScrollFrame:SetHeight(336 + tall)
						ClassTrainerDetailScrollFrame:SetHeight(336 + tall)
					end)

				end

				-- Set highlight bar width when shown
				hooksecurefunc(_G["ClassTrainerSkillHighlightFrame"], "Show", function()
					ClassTrainerSkillHighlightFrame:SetWidth(290)
				end)

				-- Move the detail frame to the right and stretch it to full height
				_G["ClassTrainerDetailScrollFrame"]:ClearAllPoints()
				_G["ClassTrainerDetailScrollFrame"]:SetPoint("TOPLEFT", _G["ClassTrainerFrame"], "TOPLEFT", 352, -74)
				_G["ClassTrainerDetailScrollFrame"]:SetSize(296, 336 + tall)
				-- _G["ClassTrainerSkillIcon"]:SetHeight(500) -- Debug

				-- Hide detail scroll frame textures
				_G["ClassTrainerDetailScrollFrameTop"]:SetAlpha(0)
				_G["ClassTrainerDetailScrollFrameBottom"]:SetAlpha(0)

				-- Hide expand tab (left of All button)
				_G["ClassTrainerExpandTabLeft"]:Hide()

				-- Get frame textures
				local regions = {_G["ClassTrainerFrame"]:GetRegions()}

				-- Set top left texture
				regions[2]:SetSize(512, 512)
				regions[2]:SetTexture("Interface\\AddOns\\Leatrix_Plus\\Leatrix_Plus")
				regions[2]:SetTexCoord(0.25, 0.75, 0, 0.5)

				-- Set top right texture
				regions[3]:ClearAllPoints()
				regions[3]:SetPoint("TOPLEFT", regions[2], "TOPRIGHT", 0, 0)
				regions[3]:SetSize(256, 512)
				regions[3]:SetTexture("Interface\\AddOns\\Leatrix_Plus\\Leatrix_Plus")
				regions[3]:SetTexCoord(0.75, 1, 0, 0.5)

				-- Hide bottom left and bottom right textures
				regions[4]:Hide()
				regions[5]:Hide()

				-- Hide skills list dividing bar
				regions[9]:Hide()
				ClassTrainerHorizontalBarLeft:Hide()

				-- Set skills list backdrop
				local RecipeInset = _G["ClassTrainerFrame"]:CreateTexture(nil, "ARTWORK")
				RecipeInset:SetSize(304, 361 + tall)
				RecipeInset:SetPoint("TOPLEFT", _G["ClassTrainerFrame"], "TOPLEFT", 16, -72)
				RecipeInset:SetTexture("Interface\\RAIDFRAME\\UI-RaidFrame-GroupBg")

				-- Set detail frame backdrop
				local DetailsInset = _G["ClassTrainerFrame"]:CreateTexture(nil, "ARTWORK")
				DetailsInset:SetSize(302, 339 + tall)
				DetailsInset:SetPoint("TOPLEFT", _G["ClassTrainerFrame"], "TOPLEFT", 348, -72)
				DetailsInset:SetTexture("Interface\\ACHIEVEMENTFRAME\\UI-GuildAchievement-Parchment-Horizontal-Desaturated")

				-- Move bottom button row
				_G["ClassTrainerTrainButton"]:ClearAllPoints()
				_G["ClassTrainerTrainButton"]:SetPoint("RIGHT", _G["ClassTrainerCancelButton"], "LEFT", -1, 0)

				-- Position and size close button
				_G["ClassTrainerCancelButton"]:SetSize(80, 22)
				_G["ClassTrainerCancelButton"]:SetText(CLOSE)
				_G["ClassTrainerCancelButton"]:ClearAllPoints()
				_G["ClassTrainerCancelButton"]:SetPoint("BOTTOMRIGHT", _G["ClassTrainerFrame"], "BOTTOMRIGHT", -42, 54)

				-- Position close box
				_G["ClassTrainerFrameCloseButton"]:ClearAllPoints()
				_G["ClassTrainerFrameCloseButton"]:SetPoint("TOPRIGHT", _G["ClassTrainerFrame"], "TOPRIGHT", -30, -8)

				-- Position dropdown menus
				ClassTrainerFrame.FilterDropdown:ClearAllPoints()
				ClassTrainerFrame.FilterDropdown:SetPoint("TOPLEFT", ClassTrainerFrame, "TOPLEFT", 536, -44)

				-- Position money frame
				ClassTrainerMoneyFrame:ClearAllPoints()
				ClassTrainerMoneyFrame:SetPoint("TOPLEFT", _G["ClassTrainerFrame"], "TOPLEFT", 143, -49)
				ClassTrainerGreetingText:Hide()

				----------------------------------------------------------------------
				--	Train All button
				----------------------------------------------------------------------

				-- Create train all button
				LeaPlusLC:CreateButton("TrainAllButton", ClassTrainerFrame, "Train All", "BOTTOMLEFT", 344, 54, 0, 22, false, "")

				-- Give button global scope (useful for compatibility with other addons and essential for ElvUI)
				_G.LeaPlusGlobalTrainAllButton = LeaPlusCB["TrainAllButton"]

				-- Button tooltip
				LeaPlusCB["TrainAllButton"]:SetScript("OnEnter", function(self)
					-- Get number of available skills and total cost
					local count, cost = 0, 0
					for i = 1, GetNumTrainerServices() do
						local void, void, isAvail = GetTrainerServiceInfo(i)
						if isAvail and isAvail == "available" then
							count = count + 1
							cost = cost + GetTrainerServiceCost(i)
						end
					end
					-- Show tooltip
					if count > 0 then
						GameTooltip:SetOwner(self, "ANCHOR_TOP", 0, 4)
						GameTooltip:ClearLines()
						if count > 1 then
							GameTooltip:AddLine(L["Train"] .. " " .. count .. " " .. L["skills for"] .. " " .. GetCoinTextureString(cost))
						else
							GameTooltip:AddLine(L["Train"] .. " " .. count .. " " .. L["skill for"] .. " " .. GetCoinTextureString(cost))
						end
						GameTooltip:Show()
					end
				end)

				-- Button click handler
				LeaPlusCB["TrainAllButton"]:SetScript("OnClick",function(self)
					for i = 1, GetNumTrainerServices() do
						local void, void, isAvail = GetTrainerServiceInfo(i)
						if isAvail and isAvail == "available" then
							BuyTrainerService(i)
						end
					end
				end)

				-- Enable button only when skills are available
				local skillsAvailable
				hooksecurefunc("ClassTrainerFrame_Update", function()
					skillsAvailable = false
					for i = 1, GetNumTrainerServices() do
						local void, void, isAvail = GetTrainerServiceInfo(i)
						if isAvail and isAvail == "available" then
							skillsAvailable = true
						end
					end
					LeaPlusCB["TrainAllButton"]:SetEnabled(skillsAvailable)
					-- Refresh tooltip
					if LeaPlusCB["TrainAllButton"]:IsMouseOver() and skillsAvailable then
						LeaPlusCB["TrainAllButton"]:GetScript("OnEnter")(LeaPlusCB["TrainAllButton"])
					end
				end)

				-- Function to set train all button
				local function SetTrainAllFunc()
					if LeaPlusLC["ShowTrainAllBtn"] == "On" then
						LeaPlusCB["TrainAllButton"]:Show()
					else
						LeaPlusCB["TrainAllButton"]:Hide()
					end
				end

				-- Run function when option is clicked, reset or preset button is clicked and on startup
				LeaPlusCB["ShowTrainAllBtn"]:HookScript("OnClick", SetTrainAllFunc)
				TrainerPanel.r:HookScript("OnClick", SetTrainAllFunc)
				LeaPlusCB["EnhanceTrainersBtn"]:HookScript("OnClick", function()
					if IsShiftKeyDown() and IsControlKeyDown() then
						-- Preset profile
						LeaPlusLC["ShowTrainAllBtn"] = "On"
						SetTrainAllFunc()
					end
				end)
				SetTrainAllFunc()

				----------------------------------------------------------------------
				--	ElvUI fixes
				----------------------------------------------------------------------

				-- ElvUI fixes
				if LeaPlusLC.ElvUI then
					local E = LeaPlusLC.ElvUI
					if E.private.skins.blizzard.enable and E.private.skins.blizzard.trainer then
						regions[2]:Hide()
						regions[3]:Hide()
						RecipeInset:Hide()
						DetailsInset:Hide()
						_G["ClassTrainerFrame"]:SetHeight(512 + tall)
						_G["ClassTrainerTrainButton"]:ClearAllPoints()
						_G["ClassTrainerTrainButton"]:SetPoint("BOTTOMRIGHT", _G["ClassTrainerFrame"], "BOTTOMRIGHT", -42, 78)
						LeaPlusCB["TrainAllButton"]:ClearAllPoints()
						LeaPlusCB["TrainAllButton"]:SetPoint("BOTTOMLEFT", _G["ClassTrainerFrame"], "BOTTOMLEFT", 344, 78)
						E:GetModule("Skins"):HandleButton(_G.LeaPlusGlobalTrainAllButton)
					end
				end

			end)

		end

		----------------------------------------------------------------------
		--	Set weather density (no reload required)
		----------------------------------------------------------------------

		do

			-- Create configuration panel
			local weatherPanel = LeaPlusLC:CreatePanel("Set weather density", "weatherPanel")
			LeaPlusLC:MakeTx(weatherPanel, "Settings", 16, -72)
			LeaPlusLC:MakeSL(weatherPanel, "WeatherLevel", "Drag to set the density of weather effects.", 0, 3, 1, 16, -92, "%.0f")

			local weatherSliderTable = {L["Very Low"], L["Low"], L["Medium"], L["High"]}

			-- Function to set the weather density
			local function SetWeatherFunc()
				LeaPlusCB["WeatherLevel"].f:SetText(LeaPlusLC["WeatherLevel"] .. "  (" .. weatherSliderTable[LeaPlusLC["WeatherLevel"] + 1] .. ")")
				if LeaPlusLC["SetWeatherDensity"] == "On" then
					SetCVar("WeatherDensity", LeaPlusLC["WeatherLevel"])
					SetCVar("RAIDweatherDensity", LeaPlusLC["WeatherLevel"])
				else
					SetCVar("WeatherDensity", "3")
					SetCVar("RAIDweatherDensity", "3")
				end
			end

			-- Set weather density when options are clicked and on startup if option is enabled
			LeaPlusCB["SetWeatherDensity"]:HookScript("OnClick", SetWeatherFunc)
			LeaPlusCB["WeatherLevel"]:HookScript("OnValueChanged", SetWeatherFunc)
			if LeaPlusLC["SetWeatherDensity"] == "On" then SetWeatherFunc() end

			-- Prevent weather density from being changed when particle density is changed
			hooksecurefunc("SetCVar", function(setting, value)
				if setting and LeaPlusLC["SetWeatherDensity"] == "On" then
					if setting == "graphicsParticleDensity" then
						if GetCVar("WeatherDensity") ~= LeaPlusLC["WeatherLevel"] then
							C_Timer.After(0.1, function()
								SetCVar("WeatherDensity", LeaPlusLC["WeatherLevel"])
							end)
						end
					elseif setting == "raidGraphicsParticleDensity" then
						if GetCVar("RAIDweatherDensity") ~= LeaPlusLC["WeatherLevel"] then
							C_Timer.After(0.1, function()
								SetCVar("RAIDweatherDensity", LeaPlusLC["WeatherLevel"])
							end)
						end
					end
				end
			end)

			-- Help button hidden
			weatherPanel.h:Hide()

			-- Back button handler
			weatherPanel.b:SetScript("OnClick", function()
				weatherPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page7"]:Show()
				return
			end)

			-- Reset button handler
			weatherPanel.r:SetScript("OnClick", function()

				-- Reset slider
				LeaPlusLC["WeatherLevel"] = 3

				-- Refresh side panel
				weatherPanel:Hide(); weatherPanel:Show()

			end)

			-- Show configuration panal when options panel button is clicked
			LeaPlusCB["SetWeatherDensityBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					LeaPlusLC["WeatherLevel"] = 0
					SetWeatherFunc()
				else
					weatherPanel:Show()
					LeaPlusLC:HideFrames()
				end
			end)

		end

		----------------------------------------------------------------------
		--	Enhance professions
		----------------------------------------------------------------------

		if LeaPlusLC["EnhanceProfessions"] == "On" and not LeaLockList["EnhanceProfessions"] then

			-- Set increased height of professions frame and maximum number of recipes listed
			local tall, numTallProfs = 73, 19

			----------------------------------------------------------------------
			--	TradeSkill Frame
			----------------------------------------------------------------------

			EventUtil.ContinueOnAddOnLoaded("Blizzard_TradeSkillUI",function()

				-- Make the tradeskill frame double-wide
				UIPanelWindows["TradeSkillFrame"] = {area = "override", pushable = 1, xoffset = -16, yoffset = 12, bottomClampOverride = 140 + 12, width = 685, height = 487, whileDead = 1}

				-- Size the tradeskill frame
				_G["TradeSkillFrame"]:SetWidth(714)
				_G["TradeSkillFrame"]:SetHeight(487 + tall)

				-- Adjust title text
				_G["TradeSkillFrameTitleText"]:ClearAllPoints()
				_G["TradeSkillFrameTitleText"]:SetPoint("TOP", _G["TradeSkillFrame"], "TOP", 0, -18)

				-- Expand the tradeskill list to full height
				_G["TradeSkillListScrollFrame"]:ClearAllPoints()
				_G["TradeSkillListScrollFrame"]:SetPoint("TOPLEFT", _G["TradeSkillFrame"], "TOPLEFT", 25, -75)
				_G["TradeSkillListScrollFrame"]:SetSize(295, 336 + tall)

				-- Create additional list rows
				local oldTradeSkillsDisplayed = TRADE_SKILLS_DISPLAYED

				-- Position existing buttons
				for i = 1 + 1, TRADE_SKILLS_DISPLAYED do
					_G["TradeSkillSkill" .. i]:ClearAllPoints()
					_G["TradeSkillSkill" .. i]:SetPoint("TOPLEFT", _G["TradeSkillSkill" .. (i-1)], "BOTTOMLEFT", 0, 1)
				end

				-- Create and position new buttons
				_G.TRADE_SKILLS_DISPLAYED = _G.TRADE_SKILLS_DISPLAYED + numTallProfs
				for i = oldTradeSkillsDisplayed + 1, TRADE_SKILLS_DISPLAYED do
					local button = CreateFrame("Button", "TradeSkillSkill" .. i, TradeSkillFrame, "TradeSkillSkillButtonTemplate")
					button:SetID(i)
					button:Hide()
					button:ClearAllPoints()
					button:SetPoint("TOPLEFT", _G["TradeSkillSkill" .. (i-1)], "BOTTOMLEFT", 0, 1)
				end

				-- Set highlight bar width when shown
				hooksecurefunc(_G["TradeSkillHighlightFrame"], "Show", function()
					_G["TradeSkillHighlightFrame"]:SetWidth(290)
				end)

				-- Move the tradeskill detail frame to the right and stretch it to full height
				_G["TradeSkillDetailScrollFrame"]:ClearAllPoints()
				_G["TradeSkillDetailScrollFrame"]:SetPoint("TOPLEFT", _G["TradeSkillFrame"], "TOPLEFT", 352, -74)
				_G["TradeSkillDetailScrollFrame"]:SetSize(298, 336 + tall)
				-- _G["TradeSkillReagent1"]:SetHeight(500) -- Debug

				-- Hide detail scroll frame textures
				_G["TradeSkillDetailScrollFrameTop"]:SetAlpha(0)
				_G["TradeSkillDetailScrollFrameBottom"]:SetAlpha(0)

				-- Create texture for skills list
				local RecipeInset = _G["TradeSkillFrame"]:CreateTexture(nil, "ARTWORK")
				RecipeInset:SetSize(304, 361 + tall)
				RecipeInset:SetPoint("TOPLEFT", _G["TradeSkillFrame"], "TOPLEFT", 16, -72)
				RecipeInset:SetTexture("Interface\\RAIDFRAME\\UI-RaidFrame-GroupBg")

				-- Set detail frame backdrop
				local DetailsInset = _G["TradeSkillFrame"]:CreateTexture(nil, "ARTWORK")
				DetailsInset:SetSize(302, 339 + tall)
				DetailsInset:SetPoint("TOPLEFT", _G["TradeSkillFrame"], "TOPLEFT", 348, -72)
				DetailsInset:SetTexture("Interface\\ACHIEVEMENTFRAME\\UI-GuildAchievement-Parchment-Horizontal-Desaturated")

				-- Hide expand tab (left of All button)
				_G["TradeSkillExpandTabLeft"]:Hide()

				-- Hide skills list horizontal dividing bar (this hides it behind RecipeInset)
				TradeSkillHorizontalBarLeft:SetSize(1, 1)
				TradeSkillHorizontalBarLeft:Hide()

				-- Get tradeskill frame textures
				local regions = {_G["TradeSkillFrame"]:GetRegions()}

				-- Set top left texture
				regions[2]:SetSize(512, 512)
				regions[2]:SetTexture("Interface\\AddOns\\Leatrix_Plus\\Leatrix_Plus")
				regions[2]:SetTexCoord(0.25, 0.75, 0, 0.5)

				-- Set top right texture
				regions[3]:ClearAllPoints()
				regions[3]:SetPoint("TOPLEFT", regions[2], "TOPRIGHT", 0, 0)
				regions[3]:SetSize(256, 512)
				regions[3]:SetTexture("Interface\\AddOns\\Leatrix_Plus\\Leatrix_Plus")
				regions[3]:SetTexCoord(0.75, 1, 0, 0.5)

				-- Hide bottom left and bottom right textures
				regions[4]:Hide()
				regions[5]:Hide()

				-- Hide horizonal bar in recipe list
				regions[8]:Hide()

				-- Move create button row
				_G["TradeSkillCreateButton"]:ClearAllPoints()
				_G["TradeSkillCreateButton"]:SetPoint("RIGHT", _G["TradeSkillCancelButton"], "LEFT", -1, 0)

				-- Position and size close button
				_G["TradeSkillCancelButton"]:SetSize(80, 22)
				_G["TradeSkillCancelButton"]:SetText(CLOSE)
				_G["TradeSkillCancelButton"]:ClearAllPoints()
				_G["TradeSkillCancelButton"]:SetPoint("BOTTOMRIGHT", _G["TradeSkillFrame"], "BOTTOMRIGHT", -42, 54)

				-- Position close box
				_G["TradeSkillFrameCloseButton"]:ClearAllPoints()
				_G["TradeSkillFrameCloseButton"]:SetPoint("TOPRIGHT", _G["TradeSkillFrame"], "TOPRIGHT", -30, -8)

				-- Position dropdown menus
				TradeSkillInvSlotDropdown:ClearAllPoints()
				TradeSkillInvSlotDropdown:SetPoint("TOPLEFT", TradeSkillFrame, "TOPLEFT", 550, -42)
				TradeSkillSubClassDropdown:ClearAllPoints()
				TradeSkillSubClassDropdown:SetPoint("RIGHT", TradeSkillInvSlotDropdown, "LEFT", -10, 0)

				-- Move search box
				TradeSearchInputBox:ClearAllPoints()
				TradeSearchInputBox:SetPoint("LEFT", TradeSkillFrameAvailableFilterCheckButtonText, "RIGHT", 30, 0)

				-- ElvUI fixes
				if LeaPlusLC.ElvUI then
					local E = LeaPlusLC.ElvUI
					if E.private.skins.blizzard.enable and E.private.skins.blizzard.tradeskill then
						RunNextFrame(function()
							regions[2]:Hide()
							regions[3]:Hide()
							RecipeInset:Hide()
							DetailsInset:Hide()
							_G["TradeSkillFrame"]:SetHeight(512 + tall)
							_G["TradeSkillCancelButton"]:ClearAllPoints()
							_G["TradeSkillCancelButton"]:SetPoint("BOTTOMRIGHT", _G["TradeSkillFrame"], "BOTTOMRIGHT", -42, 78)
							_G["TradeSkillRankFrame"]:ClearAllPoints()
							_G["TradeSkillRankFrame"]:SetPoint("TOPLEFT", _G["TradeSkillFrame"], "TOPLEFT", 24, -44)
							TradeSkillInvSlotDropdown:ClearAllPoints()
							TradeSkillInvSlotDropdown:SetPoint("TOPLEFT", TradeSkillFrame, "TOPLEFT", 550, -41)
							TradeSkillInvSlotDropdown:SetHeight(21)
							TradeSkillSubClassDropdown:ClearAllPoints()
							TradeSkillSubClassDropdown:SetPoint("RIGHT", TradeSkillInvSlotDropdown, "LEFT", -10, 0)
							TradeSkillSubClassDropdown:SetHeight(21)
						end)
					end
				end

				-- Classic Profession Filter addon fixes
				if C_AddOns.IsAddOnLoaded("ClassicProfessionFilter") and TradeSkillFrame.SearchBox and TradeSkillFrame.HaveMats and TradeSkillFrame.HaveMats.text then
					TradeSkillFrame.SearchBox:ClearAllPoints()
					TradeSkillFrame.SearchBox:SetPoint("LEFT", TradeSkillRankFrame, "RIGHT", 20, -10)

					TradeSkillFrame.HaveMats:ClearAllPoints()
					TradeSkillFrame.HaveMats:SetPoint("LEFT", TradeSkillFrame.SearchBox, "RIGHT", 10, 8)
					TradeSkillFrame.HaveMats.text:SetText(L["Have mats?"])
					TradeSkillFrame.HaveMats:SetHitRectInsets(0, -TradeSkillFrame.HaveMats.text:GetStringWidth() + 4, 0, 0)
					TradeSkillFrame.HaveMats.text:SetJustifyH("LEFT")
					TradeSkillFrame.HaveMats.text:SetWordWrap(false)
					if TradeSkillFrame.HaveMats.text:GetWidth() > 80 then
						TradeSkillFrame.HaveMats.text:SetWidth(80)
						TradeSkillFrame.HaveMats:SetHitRectInsets(0, -80 + 4, 0, 0)
					end

					TradeSkillFrame.SearchMats:ClearAllPoints()
					TradeSkillFrame.SearchMats:SetPoint("BOTTOMLEFT", TradeSkillFrame.HaveMats, "BOTTOMLEFT", 0, -16)
					TradeSkillFrame.SearchMats.text:SetText(L["Search mats?"])
					TradeSkillFrame.SearchMats:SetHitRectInsets(0, -TradeSkillFrame.SearchMats.text:GetStringWidth() + 2, 0, 0)
					TradeSkillFrame.SearchMats.text:SetJustifyH("LEFT")
					TradeSkillFrame.SearchMats.text:SetWordWrap(false)
					if TradeSkillFrame.SearchMats.text:GetWidth() > 80 then
						TradeSkillFrame.SearchMats.text:SetWidth(80)
						TradeSkillFrame.SearchMats:SetHitRectInsets(0, -80 + 4, 0, 0)
					end
				end

			end)

			----------------------------------------------------------------------
			--	Craft Frame
			----------------------------------------------------------------------

			EventUtil.ContinueOnAddOnLoaded("Blizzard_CraftUI",function()

				-- Make the craft frame double-wide
				UIPanelWindows["CraftFrame"] = {area = "override", pushable = 1, xoffset = -16, yoffset = 12, bottomClampOverride = 140 + 12, width = 685, height = 487, whileDead = 1}

				-- Size the craft frame
				_G["CraftFrame"]:SetWidth(714)
				_G["CraftFrame"]:SetHeight(487 + tall)

				-- Adjust title text
				_G["CraftFrameTitleText"]:ClearAllPoints()
				_G["CraftFrameTitleText"]:SetPoint("TOP", _G["CraftFrame"], "TOP", 0, -18)

				-- Expand the crafting list to full height
				_G["CraftListScrollFrame"]:ClearAllPoints()
				_G["CraftListScrollFrame"]:SetPoint("TOPLEFT", _G["CraftFrame"], "TOPLEFT", 25, -75)
				_G["CraftListScrollFrame"]:SetSize(295, 336 + tall)

				-- Create additional list rows
				local oldCraftsDisplayed = CRAFTS_DISPLAYED

				-- Position existing buttons
				_G["Craft1Cost"]:ClearAllPoints()
				_G["Craft1Cost"]:SetPoint("RIGHT", _G["Craft1"], "RIGHT", -30, 0)
				for i = 1 + 1, CRAFTS_DISPLAYED do
					_G["Craft" .. i]:ClearAllPoints()
					_G["Craft" .. i]:SetPoint("TOPLEFT", _G["Craft" .. (i-1)], "BOTTOMLEFT", 0, 1)
					_G["Craft" .. i .. "Cost"]:ClearAllPoints()
					_G["Craft" .. i .. "Cost"]:SetPoint("RIGHT", _G["Craft" .. i], "RIGHT", -30, 0)
				end

				-- Create and position new buttons
				_G.CRAFTS_DISPLAYED = _G.CRAFTS_DISPLAYED + numTallProfs
				for i = oldCraftsDisplayed + 1, CRAFTS_DISPLAYED do
					local button = CreateFrame("Button", "Craft" .. i, CraftFrame, "CraftButtonTemplate")
					button:SetID(i)
					button:Hide()
					button:ClearAllPoints()
					button:SetPoint("TOPLEFT", _G["Craft" .. (i-1)], "BOTTOMLEFT", 0, 1)
					_G["Craft" .. i .. "Cost"]:ClearAllPoints()
					_G["Craft" .. i .. "Cost"]:SetPoint("RIGHT", _G["Craft" .. i], "RIGHT", -30, 0)
				end

				-- Move craft frame points (such as Beast Training)
				CraftFramePointsLabel:ClearAllPoints()
				CraftFramePointsLabel:SetPoint("TOPLEFT", CraftFrame, "TOPLEFT", 100, -50)
				CraftFramePointsText:ClearAllPoints()
				CraftFramePointsText:SetPoint("LEFT", CraftFramePointsLabel, "RIGHT", 3, 0)

				-- Move craft frame cost column (such as Beast Training)
				hooksecurefunc("CraftFrame_Update", function()
					for i = 1, CRAFTS_DISPLAYED, 1 do
						if _G["Craft" .. i] then
							local craftButtonCost = _G["Craft"..i.."Cost"]
							if craftButtonCost then
								craftButtonCost:SetPoint("RIGHT", -30, 0)
							end
						end
					end
				end)

				-- Set highlight bar width when shown
				hooksecurefunc(_G["CraftHighlightFrame"], "Show", function()
					_G["CraftHighlightFrame"]:SetWidth(290)
				end)

				-- Move the craft detail frame to the right and stretch it to full height
				_G["CraftDetailScrollFrame"]:ClearAllPoints()
				_G["CraftDetailScrollFrame"]:SetPoint("TOPLEFT", _G["CraftFrame"], "TOPLEFT", 352, -74)
				_G["CraftDetailScrollFrame"]:SetSize(298, 336 + tall)
				-- _G["CraftReagent1"]:SetHeight(500) -- Debug

				-- Hide detail scroll frame textures
				_G["CraftDetailScrollFrameTop"]:SetAlpha(0)
				_G["CraftDetailScrollFrameBottom"]:SetAlpha(0)

				-- Create texture for skills list
				local RecipeInset = _G["CraftFrame"]:CreateTexture(nil, "ARTWORK")
				RecipeInset:SetSize(304, 361 + tall)
				RecipeInset:SetPoint("TOPLEFT", _G["CraftFrame"], "TOPLEFT", 16, -72)
				RecipeInset:SetTexture("Interface\\RAIDFRAME\\UI-RaidFrame-GroupBg")

				-- Set detail frame backdrop
				local DetailsInset = _G["CraftFrame"]:CreateTexture(nil, "ARTWORK")
				DetailsInset:SetSize(302, 339 + tall)
				DetailsInset:SetPoint("TOPLEFT", _G["CraftFrame"], "TOPLEFT", 348, -72)
				DetailsInset:SetTexture("Interface\\ACHIEVEMENTFRAME\\UI-GuildAchievement-Parchment-Horizontal-Desaturated")

				-- Hide expand tab (left of All button)
				_G["CraftExpandTabLeft"]:Hide()

				-- Get craft frame textures
				local regions = {_G["CraftFrame"]:GetRegions()}

				-- Set top left texture
				regions[2]:SetSize(512, 512)
				regions[2]:SetTexture("Interface\\AddOns\\Leatrix_Plus\\Leatrix_Plus")
				regions[2]:SetTexCoord(0.25, 0.75, 0, 0.5)

				-- Set top right texture
				regions[3]:ClearAllPoints()
				regions[3]:SetPoint("TOPLEFT", regions[2], "TOPRIGHT", 0, 0)
				regions[3]:SetSize(256, 512)
				regions[3]:SetTexture("Interface\\AddOns\\Leatrix_Plus\\Leatrix_Plus")
				regions[3]:SetTexCoord(0.75, 1, 0, 0.5)

				-- Hide bottom left and bottom right textures
				regions[4]:Hide()
				regions[5]:Hide()

				-- Hide skills list dividing bar
				regions[9]:Hide()
				regions[10]:Hide()

				-- Move create button row
				_G["CraftCreateButton"]:ClearAllPoints()
				_G["CraftCreateButton"]:SetPoint("RIGHT", _G["CraftCancelButton"], "LEFT", -1, 0)

				-- Position and size close button
				_G["CraftCancelButton"]:SetSize(80, 22)
				_G["CraftCancelButton"]:SetText(CLOSE)
				_G["CraftCancelButton"]:ClearAllPoints()
				_G["CraftCancelButton"]:SetPoint("BOTTOMRIGHT", _G["CraftFrame"], "BOTTOMRIGHT", -42, 54)

				-- Position close box
				_G["CraftFrameCloseButton"]:ClearAllPoints()
				_G["CraftFrameCloseButton"]:SetPoint("TOPRIGHT", _G["CraftFrame"], "TOPRIGHT", -30, -8)

				-- Position dropdown menu
				CraftFrame.Dropdown:ClearAllPoints()
				CraftFrame.Dropdown:SetPoint("TOPLEFT", CraftFrame, "TOPLEFT", 550, -42)

				-- ElvUI fixes
				if LeaPlusLC.ElvUI then
					local E = LeaPlusLC.ElvUI
					if E.private.skins.blizzard.enable and E.private.skins.blizzard.craft then
						RunNextFrame(function()
							regions[2]:Hide()
							regions[3]:Hide()
							RecipeInset:Hide()
							DetailsInset:Hide()
							_G["CraftFrame"]:SetHeight(512 + tall)
							_G["CraftCancelButton"]:ClearAllPoints()
							_G["CraftCancelButton"]:SetPoint("BOTTOMRIGHT", _G["CraftFrame"], "BOTTOMRIGHT", -42, 78)
							_G["CraftRankFrame"]:ClearAllPoints()
							_G["CraftRankFrame"]:SetPoint("TOPLEFT", _G["CraftFrame"], "TOPLEFT", 24, -44)
							CraftFrame.Dropdown:ClearAllPoints()
							CraftFrame.Dropdown:SetPoint("TOPLEFT", CraftFrame, "TOPLEFT", 541, -41)
							CraftFrame.Dropdown:SetHeight(21)
						end)
					end
				end

				-- Fix for TradeSkillMaster moving the craft create button
				hooksecurefunc(CraftCreateButton, "SetFrameLevel", function()
					CraftCreateButton:ClearAllPoints()
					CraftCreateButton:SetPoint("RIGHT", CraftCancelButton, "LEFT", -1, 0)
				end)

				-- Classic Profession Filter addon fixes
				if C_AddOns.IsAddOnLoaded("ClassicProfessionFilter") and CraftFrame.SearchBox and CraftFrame.HaveMats and CraftFrame.HaveMats.text and CraftFrame.SearchMats and CraftFrame.SearchMats.text then
					CraftFrame.SearchBox:ClearAllPoints()
					CraftFrame.SearchBox:SetPoint("LEFT", CraftRankFrame, "RIGHT", 20, -10)

					CraftFrame.HaveMats:ClearAllPoints()
					CraftFrame.HaveMats:SetPoint("LEFT", CraftFrame.SearchBox, "RIGHT", 10, 8)
					CraftFrame.HaveMats.text:SetText(L["Have mats?"])
					CraftFrame.HaveMats:SetHitRectInsets(0, -CraftFrame.HaveMats.text:GetStringWidth() + 4, 0, 0)
					CraftFrame.HaveMats.text:SetJustifyH("LEFT")
					CraftFrame.HaveMats.text:SetWordWrap(false)
					if CraftFrame.HaveMats.text:GetWidth() > 80 then
						CraftFrame.HaveMats.text:SetWidth(80)
						CraftFrame.HaveMats:SetHitRectInsets(0, -80 + 4, 0, 0)
					end

					CraftFrame.SearchMats:ClearAllPoints()
					CraftFrame.SearchMats:SetPoint("BOTTOMLEFT", CraftFrame.HaveMats, "BOTTOMLEFT", 0, -16)
					CraftFrame.SearchMats.text:SetText(L["Search mats?"])
					CraftFrame.SearchMats:SetHitRectInsets(0, -CraftFrame.SearchMats.text:GetStringWidth() + 2, 0, 0)
					CraftFrame.SearchMats.text:SetJustifyH("LEFT")
					CraftFrame.SearchMats.text:SetWordWrap(false)
					if CraftFrame.SearchMats.text:GetWidth() > 80 then
						CraftFrame.SearchMats.text:SetWidth(80)
						CraftFrame.SearchMats:SetHitRectInsets(0, -80 + 4, 0, 0)
					end
				end

			end)

		end

		----------------------------------------------------------------------
		--	Show free bag slots
		----------------------------------------------------------------------

		if LeaPlusLC["ShowFreeBagSlots"] == "On" and not LeaLockList["ShowFreeBagSlots"] then

			-- Set the CVAR and show the count
			SetCVar("displayFreeBagSlots", "1")
			MainMenuBarBackpackButtonCount:Show()

			-- Function to update the count value
			local function UpdateSlots()
				if MainMenuBarBackpackButton.freeSlots then
					MainMenuBarBackpackButtonCount:SetText(string.format("(%s)", MainMenuBarBackpackButton.freeSlots))
				end
			end

			-- Update the count value when free slots are updated
			hooksecurefunc("MainMenuBarBackpackButton_UpdateFreeSlots", UpdateSlots)

			-- Show free slots in the backpack tooltip
			MainMenuBarBackpackButton:HookScript("OnEnter", function(self)
				GameTooltip:AddLine(string.format(NUM_FREE_SLOTS, (self.freeSlots or 0)))
				GameTooltip:Show()
			end)

		end

		----------------------------------------------------------------------
		--	Enhance quest log
		----------------------------------------------------------------------

		if LeaPlusLC["EnhanceQuestLog"] == "On" then

			if LeaPlusLC["EnhanceQuestTaller"] == "On" then

				-- Set increased height of quest log frame and maximum number of quests listed
				local tall, numTallQuests = 73, 21

				-- Make the quest log frame double-wide
				UIPanelWindows["QuestLogFrame"] = {area = "override", pushable = 0, xoffset = -16, yoffset = 12, bottomClampOverride = 140 + 12, width = 685, height = 487, whileDead = 1}

				-- Size the quest log frame
				QuestLogFrame:SetWidth(714)
				QuestLogFrame:SetHeight(487 + tall)

				-- Adjust quest log title text
				QuestLogTitleText:ClearAllPoints()
				QuestLogTitleText:SetPoint("TOP", QuestLogFrame, "TOP", 0, -18)

				-- Move the detail frame to the right and stretch it to full height
				QuestLogDetailScrollFrame:ClearAllPoints()
				QuestLogDetailScrollFrame:SetPoint("TOPLEFT", QuestLogListScrollFrame, "TOPRIGHT", 31, 1)
				QuestLogDetailScrollFrame:SetHeight(336 + tall)

				-- Expand the quest list to full height
				QuestLogListScrollFrame:SetHeight(336 + tall)

				-- Create additional quest rows
				local oldQuestsDisplayed = QUESTS_DISPLAYED
				_G.QUESTS_DISPLAYED = _G.QUESTS_DISPLAYED + numTallQuests
				for i = oldQuestsDisplayed + 1, QUESTS_DISPLAYED do
					local button = CreateFrame("Button", "QuestLogTitle" .. i, QuestLogFrame, "QuestLogTitleButtonTemplate")
					button:SetID(i)
					button:Hide()
					button:ClearAllPoints()
					button:SetPoint("TOPLEFT", _G["QuestLogTitle" .. (i-1)], "BOTTOMLEFT", 0, 1)
				end

				-- Get quest frame textures
				local regions = {QuestLogFrame:GetRegions()}

				-- Set top left texture
				regions[3]:SetSize(512, 512)
				regions[3]:SetTexture("Interface\\AddOns\\Leatrix_Plus\\Leatrix_Plus.blp")
				regions[3]:SetTexCoord(0.25, 0.75, 0, 0.5)

				-- Set top right texture
				regions[4]:ClearAllPoints()
				regions[4]:SetPoint("TOPLEFT", regions[3], "TOPRIGHT", 0, 0)
				regions[4]:SetSize(256, 512)
				regions[4]:SetTexture("Interface\\AddOns\\Leatrix_Plus\\Leatrix_Plus.blp")
				regions[4]:SetTexCoord(0.75, 1, 0, 0.5)

				-- Hide bottom left and bottom right textures
				regions[5]:Hide()
				regions[6]:Hide()

				-- Position and resize abandon button
				QuestLogFrameAbandonButton:SetSize(110, 21)
				QuestLogFrameAbandonButton:SetText(ABANDON_QUEST_ABBREV)
				QuestLogFrameAbandonButton:ClearAllPoints()
				QuestLogFrameAbandonButton:SetPoint("BOTTOMLEFT", QuestLogFrame, "BOTTOMLEFT", 17, 54)

				-- Position and resize share button
				QuestFramePushQuestButton:SetSize(100, 21)
				QuestFramePushQuestButton:SetText(SHARE_QUEST_ABBREV)
				QuestFramePushQuestButton:ClearAllPoints()
				QuestFramePushQuestButton:SetPoint("LEFT", QuestLogFrameAbandonButton, "RIGHT", -3, 0)

				-- Add map button
				local logMapButton = CreateFrame("Button", "LeaPlusGlobalQuestLogMapButton", QuestLogFrame, "UIPanelButtonTemplate")
				logMapButton:SetText(L["Map"])
				logMapButton:ClearAllPoints()
				logMapButton:SetPoint("LEFT", QuestFramePushQuestButton, "RIGHT", -3, 0)
				logMapButton:SetSize(100, 21)
				logMapButton:SetScript("OnClick", ToggleWorldMap)

				-- Position and size close button
				QuestFrameExitButton:SetSize(80, 22)
				QuestFrameExitButton:SetText(CLOSE)
				QuestFrameExitButton:ClearAllPoints()
				QuestFrameExitButton:SetPoint("BOTTOMRIGHT", QuestLogFrame, "BOTTOMRIGHT", -42, 54)

				-- Empty quest frame
				QuestLogNoQuestsText:ClearAllPoints()
				QuestLogNoQuestsText:SetPoint("TOP", QuestLogListScrollFrame, 0, -50)
				hooksecurefunc(EmptyQuestLogFrame, "Show", function()
					EmptyQuestLogFrame:ClearAllPoints()
					EmptyQuestLogFrame:SetPoint("BOTTOMLEFT", QuestLogFrame, "BOTTOMLEFT", 20, -76)
					EmptyQuestLogFrame:SetHeight(487)
				end)

				-- Show map button (not currently used)
				local mapButton = CreateFrame("BUTTON", nil, QuestLogFrame)
				mapButton:SetSize(36, 25)
				mapButton:SetPoint("TOPRIGHT", -390, -44)
				mapButton:SetNormalTexture("Interface\\QuestFrame\\UI-QuestMap_Button")
				mapButton:GetNormalTexture():SetTexCoord(0.125, 0.875, 0, 0.5)
				mapButton:SetPushedTexture("Interface\\QuestFrame\\UI-QuestMap_Button")
				mapButton:GetPushedTexture():SetTexCoord(0.125, 0.875, 0.5, 1.0)
				mapButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
				mapButton:SetScript("OnClick", ToggleWorldMap)
				mapButton:Hide()

				-- ElvUI fixes
				if LeaPlusLC.ElvUI then
					local E = LeaPlusLC.ElvUI
					if E.private.skins.blizzard.enable and E.private.skins.blizzard.quest then
						-- Skin map button
						_G.LeaPlusGlobalMapButton = logMapButton
						E:GetModule("Skins"):HandleButton(_G.LeaPlusGlobalMapButton)
					end
				end

			end

			-- Translations for quest level suffixes (need to be English so links work in addons such as Questie for non-English locales)
			L["D"] = "D" -- Dungeon quest
			L["R"] = "R" -- Raid quest
			L["P"] = "P" -- PvP quest
			L["+"] = "+" -- Elite or group quest

			-- Show quest level in quest log detail frame (but not in quest accept or turn-in frame)
			hooksecurefunc("QuestLog_UpdateQuestDetails", function()
				if LeaPlusLC["EnhanceQuestLevels"] == "On" then
					local quest = GetQuestLogSelection()
					if quest then
						local title, level, suggestedGroup = GetQuestLogTitle(quest)
						if title and level then
							if suggestedGroup then
								if suggestedGroup == LFG_TYPE_DUNGEON then level = level .. L["D"]
								elseif suggestedGroup == RAID then level = level .. L["R"]
								elseif suggestedGroup == ELITE then level = level .. L["+"]
								elseif suggestedGroup == GROUP then level = level .. L["+"]
								elseif suggestedGroup == PVP then level = level .. L["P"]
								end
							end
							QuestLogQuestTitle:SetText("[" .. level .. "] " .. title)
						end
					end
				end
			end)

			-- Show quest levels in quest log
			hooksecurefunc("QuestLog_Update", function()
				local numEntries, numQuests = GetNumQuestLogEntries()
				if numEntries == 0 then return end
				-- Traverse quests in log
				for i = 1, QUESTS_DISPLAYED do
					local questIndex = i + FauxScrollFrame_GetOffset(QuestLogListScrollFrame)
					-- Can use below line instead of FauxScrollFrame_GetOffset (Wrath Classic uses QuestLogTitleButton_Resize)
					-- local questIndex = i + math.floor(QuestLogListScrollFrame:GetVerticalScroll() / QUESTLOG_QUEST_HEIGHT)
					if questIndex <= numEntries then
						-- Get quest title and check
						local questLogTitle = _G["QuestLogTitle" .. i]
						local questCheck = _G["QuestLogTitle" .. i .. "Check"]
						local title, level, suggestedGroup, isHeader = GetQuestLogTitle(questIndex)
						if title and level and not isHeader and LeaPlusLC["EnhanceQuestLevels"] == "On" then
							-- Add level tag if its not a header
							local levelSuffix = ""
							if suggestedGroup and LeaPlusLC["EnhanceQuestDifficulty"] == "On" then
								if suggestedGroup == LFG_TYPE_DUNGEON then levelSuffix = "D"
								elseif suggestedGroup == RAID then levelSuffix = "R"
								elseif suggestedGroup == ELITE then levelSuffix = "+"
								elseif suggestedGroup == GROUP then levelSuffix = "+"
								elseif suggestedGroup == PVP then levelSuffix = "P"
								end
							end
							local questTextFormatted = string.format("  [%d" .. L[levelSuffix] .. "] %s", level, title)
							questLogTitle:SetText(questTextFormatted)
							QuestLogDummyText:SetText(questTextFormatted)
						end
						-- Show tracking check mark
						local checkText = _G["QuestLogTitle" .. i .. "NormalText"]
						if checkText then
							local checkPos = checkText:GetStringWidth()
							if checkPos then
								if checkPos <= 210 then
									questCheck:SetPoint("LEFT", questLogTitle, "LEFT", checkPos + 24, 0)
								else
									questCheck:SetPoint("LEFT", questLogTitle, "LEFT", 210, 0)
								end
							end
						end
					end
				end
			end)

			-- Create configuration panel
			local EnhanceQuestPanel = LeaPlusLC:CreatePanel("Enhance quest log", "EnhanceQuestPanel")

			LeaPlusLC:MakeTx(EnhanceQuestPanel, "Settings", 16, -72)
			LeaPlusLC:MakeCB(EnhanceQuestPanel, "EnhanceQuestTaller", "Larger quest log frame", 16, -92, true, "If checked, the quest log frame will be larger.")

			LeaPlusLC:MakeTx(EnhanceQuestPanel, "Levels", 16, -132)
			LeaPlusLC:MakeCB(EnhanceQuestPanel, "EnhanceQuestLevels", "Show quest levels", 16, -152, false, "If checked, quest levels will be shown.")
			LeaPlusLC:MakeCB(EnhanceQuestPanel, "EnhanceQuestDifficulty", "Show quest difficulty in quest log list", 16, -172, false, "If checked, the quest difficulty will be shown next to the quest level in the quest log list.|n|nThis will indicate whether the quest requires a group (+), dungeon (D), raid (R) or PvP (P).|n|nThe quest difficulty will always be shown in the quest log detail pane regardless of this setting.")

			-- Disable Show quest difficulty option if Show quest levels is disabled
			LeaPlusCB["EnhanceQuestLevels"]:HookScript("OnClick", function()
				LeaPlusLC:LockOption("EnhanceQuestLevels", "EnhanceQuestDifficulty", false)
			end)
			LeaPlusLC:LockOption("EnhanceQuestLevels", "EnhanceQuestDifficulty", false)

			-- Help button hidden
			EnhanceQuestPanel.h:Hide()

			-- Back button handler
			EnhanceQuestPanel.b:SetScript("OnClick", function()
				EnhanceQuestPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page5"]:Show();
				return
			end)

			-- Reset button handler
			EnhanceQuestPanel.r.tiptext = EnhanceQuestPanel.r.tiptext .. "|n|n" .. L["Note that this will not reset settings that require a UI reload."]
			EnhanceQuestPanel.r:SetScript("OnClick", function()

				-- Reset checkboxes
				LeaPlusLC["EnhanceQuestLevels"] = "On"
				LeaPlusLC["EnhanceQuestDifficulty"] = "On"

				-- Refresh panel
				EnhanceQuestPanel:Hide(); EnhanceQuestPanel:Show()

			end)

			-- Show panal when options panel button is clicked
			LeaPlusCB["EnhanceQuestLogBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					LeaPlusLC["EnhanceQuestLevels"] = "On"
					LeaPlusLC["EnhanceQuestDifficulty"] = "On"
				else
					EnhanceQuestPanel:Show()
					LeaPlusLC:HideFrames()
				end
			end)

		end

		----------------------------------------------------------------------
		--	Show bag search box
		----------------------------------------------------------------------

		if LeaPlusLC["ShowBagSearchBox"] == "On" and not LeaLockList["ShowBagSearchBox"] then

			-- Create bag item search box
			local BagItemSearchBox = CreateFrame("EditBox", nil, ContainerFrame1, "BagSearchBoxTemplate")
			BagItemSearchBox:SetSize(110, 18)
			BagItemSearchBox:SetMaxLetters(15)

			-- Create bank item search box
			local BankItemSearchBox = CreateFrame("EditBox", nil, BankFrame, "BagSearchBoxTemplate")
			BankItemSearchBox:SetSize(120, 14)
			BankItemSearchBox:SetMaxLetters(15)
			BankItemSearchBox:SetPoint("TOPRIGHT", -60, -40)

			-- Attach bag search box first bag only
			hooksecurefunc("ContainerFrame_Update", function(self)
				if self:GetID() == 0 then
					BagItemSearchBox:SetParent(self)
					BagItemSearchBox:SetPoint("TOPLEFT", self, "TOPLEFT", 54, -29)
					BagItemSearchBox.anchorBag = self
					BagItemSearchBox:Show()
				elseif BagItemSearchBox.anchorBag == self then
					BagItemSearchBox:ClearAllPoints()
					BagItemSearchBox:Hide()
					BagItemSearchBox.anchorBag = nil
				end
			end)

		end

		----------------------------------------------------------------------
		--	Show vendor price
		----------------------------------------------------------------------

		if LeaPlusLC["ShowVendorPrice"] == "On" then

			-- Function to show vendor price
			local function ShowSellPrice(tooltip, tooltipObject)
				if tooltip.shownMoneyFrames then return end
				tooltipObject = tooltipObject or GameTooltip
				-- Get container
				local container = GetMouseFoci()[1]
				if not container then return end
				-- Get item
				local itemName, itemlink = tooltipObject:GetItem()
				if not itemlink then return end
				local void, ilink, void, void, void, void, void, void, void, void, sellPrice, classID = C_Item.GetItemInfo(itemlink)
				if sellPrice and sellPrice > 0 then
					local count = container and type(container.count) == "number" and container.count or 1
					if sellPrice and count > 0 then
						if classID and classID == 11 then count = 1 end -- Fix for quiver/ammo pouch so ammo is not included
						if sellPrice == 4000 and ilink and string.find(ilink, "item:210781:") then
							-- Bug with Phoenix Bindings (real price is 24 silver 81 copper, but game returns 40 silver) (seems fixed now)
							-- Test with GameTooltip:SetHyperlink("item:210781")
							-- SetTooltipMoney(tooltip, 2481 * count, "STATIC", SELL_PRICE .. ":")
						else
							-- Everything else get game price
							SetTooltipMoney(tooltip, sellPrice * count, "STATIC", SELL_PRICE .. ":")
						end
					end
				end
				-- Refresh chat tooltips
				if tooltipObject == ItemRefTooltip then ItemRefTooltip:Show() end
			end

			-- Show vendor price when tooltips are shown
			GameTooltip:HookScript("OnTooltipSetItem", ShowSellPrice)
			hooksecurefunc(GameTooltip, "SetHyperlink", function(tip) ShowSellPrice(tip, GameTooltip) end)
			hooksecurefunc(ItemRefTooltip, "SetHyperlink", function(tip) ShowSellPrice(tip, ItemRefTooltip) end)

		end

		----------------------------------------------------------------------
		--	Dismount me
		----------------------------------------------------------------------

		if LeaPlusLC["StandAndDismount"] == "On" then

			local eFrame = CreateFrame("FRAME")
			eFrame:RegisterEvent("UI_ERROR_MESSAGE")
			eFrame:SetScript("OnEvent", function(self, event, messageType, msg)
				-- Auto dismount
				if msg == ERR_OUT_OF_RAGE and LeaPlusLC["DismountNoResource"] == "On"
				or msg == ERR_OUT_OF_MANA and LeaPlusLC["DismountNoResource"] == "On"
				or msg == ERR_OUT_OF_ENERGY and LeaPlusLC["DismountNoResource"] == "On"
				or msg == SPELL_FAILED_MOVING and LeaPlusLC["DismountNoMoving"] == "On"
				or msg == ERR_TAXIPLAYERSHAPESHIFTED
				then
					if IsMounted() then
						Dismount()
						UIErrorsFrame:Clear()
					end
				end
			end)

			-- Dismount when flight point map is opened
			local taxiFrame = CreateFrame("FRAME")
			taxiFrame:RegisterEvent("TAXIMAP_OPENED")
			taxiFrame:SetScript("OnEvent", function()
				if IsMounted() then Dismount() end
			end)

			-- Create configuration panel
			local DismountFrame = LeaPlusLC:CreatePanel("Dismount me", "DismountFrame")

			LeaPlusLC:MakeTx(DismountFrame, "Settings", 16, -72)
			LeaPlusLC:MakeCB(DismountFrame, "DismountNoResource", "Dismount when not enough rage, mana or energy", 16, -92, false, "If checked, you will be dismounted when you attempt to cast a spell but don't have the rage, mana or energy to cast it.")
			LeaPlusLC:MakeCB(DismountFrame, "DismountNoMoving", "Dismount when casting a spell while moving", 16, -112, false, "If checked, you will be dismounted when you attempt to cast a non-instant cast spell while moving.")
			LeaPlusLC:MakeCB(DismountFrame, "DismountNoTaxi", "Dismount when the flight map opens", 16, -132, false, "If checked, you will be dismounted when you instruct a flight master to open the flight map.")
			LeaPlusLC:MakeCB(DismountFrame, "DismountShowFormBtn", "Show cancel form button on flight map", 16, -152, false, "If checked, a cancel form button will be shown on the flight map while you are playing as a shapeshifted druid or shaman.")

			-- Help button hidden
			DismountFrame.h.tiptext = L["The game will dismount you if you successfully cast a spell without addons.  These settings let you set some additional dismount rules."]

			-- Back button handler
			DismountFrame.b:SetScript("OnClick", function()
				DismountFrame:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page7"]:Show()
				return
			end)

			-- Function to set dismount options
			local function SetDismount()
				if LeaPlusLC["DismountNoTaxi"] == "On" then
					taxiFrame:RegisterEvent("TAXIMAP_OPENED")
				else
					taxiFrame:UnregisterEvent("TAXIMAP_OPENED")
				end
			end

			-- Run function when certain options are clicked and on startup
			LeaPlusCB["DismountNoTaxi"]:HookScript("OnClick", SetDismount)
			SetDismount()

			-- Reset button handler
			DismountFrame.r:SetScript("OnClick", function()

				-- Reset checkboxes
				LeaPlusLC["DismountNoResource"] = "On"
				LeaPlusLC["DismountNoMoving"] = "On"
				LeaPlusLC["DismountNoTaxi"] = "On"
				LeaPlusLC["DismountShowFormBtn"] = "On"

				-- Update settings and configuration panel
				SetDismount()
				DismountFrame:Hide(); DismountFrame:Show()

			end)

			-- Show configuration panal when options panel button is clicked
			LeaPlusCB["DismountBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					LeaPlusLC["DismountNoResource"] = "On"
					LeaPlusLC["DismountNoMoving"] = "On"
					LeaPlusLC["DismountNoTaxi"] = "On"
					LeaPlusLC["DismountShowFormBtn"] = "On"
					SetDismount()
				else
					DismountFrame:Show()
					LeaPlusLC:HideFrames()
				end
			end)

			-- Druid cancel form button
			local void, class = UnitClass("player")
			if class == "DRUID" or class == "SHAMAN" then

				-- Create button
				local cancelFormBtn = CreateFrame("Button", nil, TaxiFrame, "InsecureActionButtonTemplate")
				cancelFormBtn:RegisterForClicks("AnyUp", "AnyDown")
				cancelFormBtn:SetAttribute("type", "macro")
				cancelFormBtn:SetAttribute("macrotext", "/cancelform")
				cancelFormBtn:ClearAllPoints()
				cancelFormBtn:SetSize(24, 24)
				if LeaPlusLC["EnhanceFlightMap"] == "On" then
					cancelFormBtn:SetPoint("TOPRIGHT", TaxiFrame, "TOPRIGHT", -76, -80)
				else
					cancelFormBtn:SetPoint("TOPRIGHT", TaxiFrame, "TOPRIGHT", -46, -46)
				end
				cancelFormBtn:SetNormalTexture("Interface\\ICONS\\Achievement_Character_Nightelf_Female")
				cancelFormBtn:SetPushedTexture("Interface\\ICONS\\Achievement_Character_Nightelf_Female")
				cancelFormBtn:SetHighlightTexture("Interface\\ICONS\\Achievement_Character_Nightelf_Female")

				-- Button message
				cancelFormBtn.f = cancelFormBtn:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
				cancelFormBtn.f:SetHeight(32)
				cancelFormBtn.f:SetPoint('RIGHT', cancelFormBtn, 'LEFT', -10, 0)
				cancelFormBtn.f:SetText(L["Click to unshift"])

				-- Toggle button when form changes
				cancelFormBtn:SetScript("OnEvent", function()
					local form = GetShapeshiftForm() or 0
					if form ~= 0 then
						if not cancelFormBtn:IsShown() then	cancelFormBtn:Show() end
					else
						cancelFormBtn:Hide()
					end
				end)

				-- Function to set event and button status
				local function SetShiftEvent()
					if LeaPlusLC["DismountShowFormBtn"] == "On" then
						cancelFormBtn:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
						local form = GetShapeshiftForm() or 0
						if form ~= 0 then cancelFormBtn:Show() else cancelFormBtn:Hide() end
					else
						cancelFormBtn:UnregisterEvent("UPDATE_SHAPESHIFT_FORM")
						cancelFormBtn:Hide()
					end
				end

				-- Set button when option is clicked, when reset button is clicked, preset profile and on startup
				LeaPlusCB["DismountShowFormBtn"]:HookScript("OnClick", SetShiftEvent)
				DismountFrame.r:HookScript("OnClick", SetShiftEvent)
				LeaPlusCB["DismountBtn"]:HookScript("OnClick", function()
					if IsShiftKeyDown() and IsControlKeyDown() then	SetShiftEvent() end
				end)
				SetShiftEvent()

			end

		end

		----------------------------------------------------------------------
		--	Use class colors in chat
		----------------------------------------------------------------------

		if LeaPlusLC["ClassColorsInChat"] == "On" and not LeaLockList["ClassColorsInChat"] then

			SetCVar("chatClassColorOverride", "0")

			for void, v in ipairs({"SAY", "EMOTE", "YELL", "GUILD", "OFFICER", "WHISPER", "PARTY", "PARTY_LEADER", "RAID", "RAID_LEADER", "RAID_WARNING", "INSTANCE_CHAT", "INSTANCE_CHAT_LEADER", "VOICE_TEXT"}) do
				SetChatColorNameByClass(v, true)
			end

			for i = 1, 50 do
				SetChatColorNameByClass("CHANNEL" .. i, true)
			end

		end

		----------------------------------------------------------------------
		-- Disable screen glow (no reload required)
		----------------------------------------------------------------------

		do

			-- Function to set screen glow
			local function SetGlow()
				if LeaPlusLC["NoScreenGlow"] == "On" then
					SetCVar("ffxGlow", "0")
				else
					SetCVar("ffxGlow", "1")
				end
			end

			-- Set screen glow on startup and when option is clicked (if enabled)
			LeaPlusCB["NoScreenGlow"]:HookScript("OnClick", SetGlow)
			if LeaPlusLC["NoScreenGlow"] == "On" then SetGlow() end

		end

		----------------------------------------------------------------------
		-- Disable screen effects (no reload required)
		----------------------------------------------------------------------

		do

			-- Function to set screen effects
			local function SetEffects()
				if LeaPlusLC["NoScreenEffects"] == "On" then
					SetCVar("ffxDeath", "0")
					SetCVar("ffxNether", "0")
				else
					SetCVar("ffxDeath", "1")
					SetCVar("ffxNether", "1")
				end
			end

			-- Set screen effects when option is clicked and on startup (if enabled)
			LeaPlusCB["NoScreenEffects"]:HookScript("OnClick", SetEffects)
			if LeaPlusLC["NoScreenEffects"] == "On" then SetEffects() end

		end

		----------------------------------------------------------------------
		-- Universal group chat color (no reload required)
		----------------------------------------------------------------------

		do

			-- Function to set chat colors
			local function SetCol()
				if LeaPlusLC["UnivGroupColor"] == "On" then
					ChangeChatColor("RAID", 0.67, 0.67, 1)
					ChangeChatColor("RAID_LEADER", 0.46, 0.78, 1)
				else
					ChangeChatColor("RAID", 1, 0.50, 0)
					ChangeChatColor("RAID_LEADER", 1, 0.28, 0.04)
				end
			end

			-- Set chat colors when option is clicked and on startup (if enabled)
			LeaPlusCB["UnivGroupColor"]:HookScript("OnClick", SetCol)
			if LeaPlusLC["UnivGroupColor"] == "On" then	SetCol() end

		end

		----------------------------------------------------------------------
		-- Minimap button (no reload required)
		----------------------------------------------------------------------

		do

			-- Minimap button click function
			local function MiniBtnClickFunc(arg1)
				-- Prevent options panel from showing if chat configuration panel is showing
				if ChatConfigFrame:IsShown() then return end
				-- Prevent options panel from showing if Blizzard Store is showing
				if StoreFrame and StoreFrame:GetAttribute("isshown") then return end
				-- Left button down
				if arg1 == "LeftButton" then

					-- Shift key toggles music
					if IsShiftKeyDown() and not IsControlKeyDown() and not IsAltKeyDown() then
						Sound_ToggleMusic()
						return
					end

					-- Control key does nothing
					if IsControlKeyDown() and not IsShiftKeyDown() and not IsAltKeyDown() then
						return
					end

					-- Alt key toggles error messages
					if IsAltKeyDown() and not IsControlKeyDown() and not IsShiftKeyDown() then
						if LeaPlusDB["HideErrorMessages"] == "On" then -- Checks global
							if LeaPlusLC["ShowErrorsFlag"] == 1 then
								LeaPlusLC["ShowErrorsFlag"] = 0
								ActionStatus_DisplayMessage(L["Error messages will be shown"], true)
							else
								LeaPlusLC["ShowErrorsFlag"] = 1
								ActionStatus_DisplayMessage(L["Error messages will be hidden"], true)
							end
							return
						end
						return
					end

					-- Shift key does nothing
					if IsShiftKeyDown() and not IsControlKeyDown() then
						return
					end

					-- Control key and alt key toggles Zygor addon
					if IsControlKeyDown() and IsAltKeyDown() and not IsShiftKeyDown() then
						LeaPlusLC:ZygorToggle()
						return
					end

					-- Control key and shift key toggles maximised window mode
					if IsControlKeyDown() and IsShiftKeyDown() and not IsAltKeyDown() then
						if LeaPlusLC:PlayerInCombat() then
							return
						else
							SetCVar("gxMaximize", tostring(1 - GetCVar("gxMaximize")))
							UpdateWindow()
						end
						return
					end

					-- No modifier key toggles the options panel
					if LeaPlusLC:IsPlusShowing() then
						LeaPlusLC:HideFrames()
						LeaPlusLC:HideConfigPanels()
					else
						LeaPlusLC:HideFrames()
						LeaPlusLC["PageF"]:Show()
					end
					LeaPlusLC["Page"..LeaPlusLC["LeaStartPage"]]:Show()
				end

				-- Right button down
				if arg1 == "RightButton" then

					-- No modifier key toggles the options panel
					if LeaPlusLC:IsPlusShowing() then
						LeaPlusLC:HideFrames()
						LeaPlusLC:HideConfigPanels()
					else
						LeaPlusLC:HideFrames()
						LeaPlusLC["PageF"]:Show()
					end
					LeaPlusLC["Page" .. LeaPlusLC["LeaStartPage"]]:Show()

				end

			end

			-- Assign global scope for function
			_G.LeaPlusGlobalMiniBtnClickFunc = MiniBtnClickFunc

			-- Create minimap button using LibDBIcon
			local miniButton = LibStub("LibDataBroker-1.1"):NewDataObject("Leatrix_Plus", {
				type = "data source",
				text = "Leatrix Plus",
				icon = "Interface\\HELPFRAME\\ReportLagIcon-Movement",
				OnClick = function(self, btn)
					MiniBtnClickFunc(btn)
				end,
				OnTooltipShow = function(tooltip)
					if not tooltip or not tooltip.AddLine then return end
					tooltip:AddLine("Leatrix Plus")
				end,
			})

			local icon = LibStub("LibDBIcon-1.0", true)
			icon:Register("Leatrix_Plus", miniButton, LeaPlusDB)

			-- Function to toggle LibDBIcon
			local function SetLibDBIconFunc()
				if LeaPlusLC["ShowMinimapIcon"] == "On" then
					LeaPlusDB["hide"] = false
					icon:Show("Leatrix_Plus")
				else
					LeaPlusDB["hide"] = true
					icon:Hide("Leatrix_Plus")
				end
			end

			-- Set LibDBIcon when option is clicked and on startup
			LeaPlusCB["ShowMinimapIcon"]:HookScript("OnClick", SetLibDBIconFunc)
			SetLibDBIconFunc()

		end

		----------------------------------------------------------------------
		-- Auction House Extras
		----------------------------------------------------------------------

		if LeaPlusLC["AhExtras"] == "On" then

			EventUtil.ContinueOnAddOnLoaded("Blizzard_AuctionUI",function()

				-- Set default auction duration value to saved settings or default settings
				AuctionFrameAuctions.duration = LeaPlusDB["AHDuration"] or 3

				-- Update duration radio button
				AuctionsShortAuctionButton:SetChecked(false)
				AuctionsMediumAuctionButton:SetChecked(false)
				AuctionsLongAuctionButton:SetChecked(false)
				if AuctionFrameAuctions.duration == 1 then
					AuctionsShortAuctionButton:SetChecked(true)
				elseif AuctionFrameAuctions.duration == 2 then
					AuctionsMediumAuctionButton:SetChecked(true)
				elseif AuctionFrameAuctions.duration == 3 then
					AuctionsLongAuctionButton:SetChecked(true)
				end

				-- Functions
				local function CreateAuctionCB(name, anchor, x, y, text)
					LeaPlusCB[name] = CreateFrame("CheckButton", nil, AuctionFrameAuctions, "ChatConfigCheckButtonTemplate")
					LeaPlusCB[name]:SetFrameStrata("HIGH")
					LeaPlusCB[name]:SetSize(20, 20)
					LeaPlusCB[name]:SetPoint(anchor, x, y)
					LeaPlusCB[name].f = LeaPlusCB[name]:CreateFontString(nil, 'OVERLAY', "GameFontNormal")
					LeaPlusCB[name].f:SetPoint("LEFT", 20, 0)
					LeaPlusCB[name].f:SetText(L[text])
					LeaPlusCB[name].f:Show();
					LeaPlusCB[name]:SetScript('OnClick', function()
						if LeaPlusCB[name]:GetChecked() then
							LeaPlusLC[name] = "On"
						else
							LeaPlusLC[name] = "Off"
						end
					end)
					LeaPlusCB[name]:SetScript('OnShow', function(self)
						if LeaPlusLC[name] == "On" then
							self:SetChecked(true)
						else
							self:SetChecked(false)
						end
					end)
				end

				-- Show the correct fields in the AH frame and match prices
				local function SetupAh()
					if LeaPlusLC["AhBuyoutOnly"] == "On" then
						-- Hide the start price
						StartPrice:SetAlpha(0);
						-- Set start price to buyout price
						StartPriceGold:SetText(BuyoutPriceGold:GetText());
						StartPriceSilver:SetText(BuyoutPriceSilver:GetText());
						StartPriceCopper:SetText(BuyoutPriceCopper:GetText());
					else
						-- Show the start price
						StartPrice:SetAlpha(1);
					end
					-- If gold only is on, set copper and silver to 99
					if LeaPlusLC["AhGoldOnly"] == "On" then
						StartPriceCopper:SetText("99"); StartPriceCopper:Disable();
						StartPriceSilver:SetText("99"); StartPriceSilver:Disable();
						BuyoutPriceCopper:SetText("99"); BuyoutPriceCopper:Disable();
						BuyoutPriceSilver:SetText("99"); BuyoutPriceSilver:Disable();
					else
						StartPriceCopper:Enable();
						StartPriceSilver:Enable();
						BuyoutPriceCopper:Enable();
						BuyoutPriceSilver:Enable();
					end
					-- Validate the auction (mainly for the create auction button status)
					AuctionsFrameAuctions_ValidateAuction()
				end

				-- Create checkboxes
				CreateAuctionCB("AhBuyoutOnly", "BOTTOMLEFT", 200, 16, "Buyout Only")
				CreateAuctionCB("AhGoldOnly", "BOTTOMLEFT", 320, 16, "Gold Only")

				-- Reposition Gold Only checkbox so it does not overlap Buyout Only checkbox label
				LeaPlusCB["AhGoldOnly"]:ClearAllPoints()
				LeaPlusCB["AhGoldOnly"]:SetPoint("LEFT", LeaPlusCB["AhBuyoutOnly"].f, "RIGHT", 20, 0)

				-- Set click boundaries
				LeaPlusCB["AhBuyoutOnly"]:SetHitRectInsets(0, -LeaPlusCB["AhBuyoutOnly"].f:GetStringWidth() + 6, 0, 0);
				LeaPlusCB["AhGoldOnly"]:SetHitRectInsets(0, -LeaPlusCB["AhGoldOnly"].f:GetStringWidth() + 6, 0, 0);

				LeaPlusCB["AhBuyoutOnly"]:HookScript('OnClick', SetupAh);
				LeaPlusCB["AhBuyoutOnly"]:HookScript('OnShow', SetupAh);

				AuctionFrameAuctions:HookScript("OnShow", SetupAh)
				BuyoutPriceGold:HookScript("OnTextChanged", SetupAh)
				BuyoutPriceSilver:HookScript("OnTextChanged", SetupAh)
				BuyoutPriceCopper:HookScript("OnTextChanged", SetupAh)
				StartPriceGold:HookScript("OnTextChanged", SetupAh)
				StartPriceSilver:HookScript("OnTextChanged", SetupAh)
				StartPriceCopper:HookScript("OnTextChanged", SetupAh)

				-- Lock the create auction button if buyout gold box is empty (when using buyout only and gold only)
				AuctionsCreateAuctionButton:HookScript("OnEnable", function()
					-- Do nothing if wow token frame is showing
					if AuctionsWowTokenAuctionFrame:IsShown() then return end
					-- Lock the create auction button if both checkboxes are enabled and buyout gold price is empty
					if LeaPlusLC["AhGoldOnly"] == "On" and LeaPlusLC["AhBuyoutOnly"] == "On" then
						if BuyoutPriceGold:GetText() == "" then
							AuctionsCreateAuctionButton:Disable()
						end
					end
				end)

				-- Clear copper and silver prices if gold only box is unchecked
				LeaPlusCB["AhGoldOnly"]:HookScript('OnClick', function()
					if LeaPlusCB["AhGoldOnly"]:GetChecked() == false then
						BuyoutPriceCopper:SetText("")
						BuyoutPriceSilver:SetText("")
						StartPriceCopper:SetText("")
						StartPriceSilver:SetText("")
					end
					SetupAh();
				end)

				-- Create find button
				AuctionsItemText:Hide()
				LeaPlusLC:CreateButton("FindAuctionButton", AuctionsStackSizeMaxButton, "Find Item", "CENTER", 0, 68, 0, 21, false, "")
				LeaPlusCB["FindAuctionButton"]:SetParent(AuctionFrameAuctions)

				if LeaPlusLC.ElvUI then
					_G.LeaPlusGlobalFindItemButton = LeaPlusCB["FindAuctionButton"]
					LeaPlusLC.ElvUI:GetModule("Skins"):HandleButton(_G.LeaPlusGlobalFindItemButton)
				end

				-- Show find button when the auctions tab is shown
				AuctionFrameAuctions:HookScript("OnShow", function()
					LeaPlusCB["FindAuctionButton"]:SetEnabled(GetAuctionSellItemInfo() and true or false)
				end)

				-- Show find button when a new item is added
				AuctionsItemButton:HookScript("OnEvent", function(self, event)
					if event == "NEW_AUCTION_UPDATE" then
						LeaPlusCB["FindAuctionButton"]:SetEnabled(GetAuctionSellItemInfo() and true or false)
					end
				end)

				LeaPlusCB["FindAuctionButton"]:SetScript("OnClick", function()
					if GetAuctionSellItemInfo() then
						if BrowseWowTokenResults:IsShown() then
							-- Stop if Game Time filter is currently shown
							AuctionFrameTab1:Click()
							LeaPlusLC:Print("To use the Find Item button, you need to deselect the WoW Token category.")
						else
							-- Otherwise, search for the required item
							local name = GetAuctionSellItemInfo()
							BrowseName:SetText(name)
							QueryAuctionItems(name, 0, 0, 0, false, 0, false, true)
							AuctionFrameTab1:Click()
						end
					end
				end)

				-- Clear the cursor and reset editboxes when a new item replaces an existing one
				hooksecurefunc("AuctionsFrameAuctions_ValidateAuction", function()
					if GetAuctionSellItemInfo() then
						-- Return anything you might be holding
						ClearCursor();
						-- Set copper and silver prices to 99 if gold mode is on
						if LeaPlusLC["AhGoldOnly"] == "On" then
							StartPriceCopper:SetText("99")
							StartPriceSilver:SetText("99")
							BuyoutPriceCopper:SetText("99")
							BuyoutPriceSilver:SetText("99")
						end
					end
				end)

				-- Clear gold editbox after an auction has been created (to force user to enter something)
				AuctionsCreateAuctionButton:HookScript("OnClick", function()
					StartPriceGold:SetText("")
					BuyoutPriceGold:SetText("")
				end)

				-- Set tab key actions (if different from defaults)
				StartPriceGold:HookScript("OnTabPressed", function()
					if not IsShiftKeyDown() then
						if LeaPlusLC["AhBuyoutOnly"] == "Off" and LeaPlusLC["AhGoldOnly"] == "On" then
							BuyoutPriceGold:SetFocus()
						end
					end
				end)

				BuyoutPriceGold:HookScript("OnTabPressed", function()
					if IsShiftKeyDown() then
						if LeaPlusLC["AhBuyoutOnly"] == "Off" and LeaPlusLC["AhGoldOnly"] == "On" then
							StartPriceGold:SetFocus()
						end
					end
				end)
			end)

		end

		----------------------------------------------------------------------
		-- Show volume control on character frame
		----------------------------------------------------------------------

		if LeaPlusLC["ShowVolume"] == "On" then

			-- Function to update master volume
			local function MasterVolUpdate()
				if LeaPlusLC["ShowVolume"] == "On" then
					-- Set the volume
					SetCVar("Sound_MasterVolume", LeaPlusLC["LeaPlusMaxVol"]);
					-- Format the slider text
					LeaPlusCB["LeaPlusMaxVol"].f:SetFormattedText("%.0f", LeaPlusLC["LeaPlusMaxVol"] * 20)
				end
			end

			-- Create slider control
			LeaPlusLC["LeaPlusMaxVol"] = tonumber(GetCVar("Sound_MasterVolume"));
			LeaPlusLC:MakeSL(CharacterModelFrame, "LeaPlusMaxVol", "",	0, 1, 0.05, -42, -328, "%.2f")
			LeaPlusCB["LeaPlusMaxVol"]:SetWidth(64)
			LeaPlusCB["LeaPlusMaxVol"].f:ClearAllPoints()
			LeaPlusCB["LeaPlusMaxVol"].f:SetPoint("LEFT", LeaPlusCB["LeaPlusMaxVol"], "RIGHT", 6, 0)

			-- Set slider control value when shown
			LeaPlusCB["LeaPlusMaxVol"]:SetScript("OnShow", function()
				LeaPlusCB["LeaPlusMaxVol"]:SetValue(GetCVar("Sound_MasterVolume"))
			end)

			-- Update volume when slider control is changed
			LeaPlusCB["LeaPlusMaxVol"]:HookScript("OnValueChanged", function()
				if IsMouseButtonDown("RightButton") and IsShiftKeyDown() then
					-- Dual layout is active so don't adjust slider
					LeaPlusCB["LeaPlusMaxVol"].f:SetFormattedText("%.0f", LeaPlusLC["LeaPlusMaxVol"] * 20)
					LeaPlusCB["LeaPlusMaxVol"]:Hide()
					LeaPlusCB["LeaPlusMaxVol"]:Show()
					return
				else
					-- Set sound level and refresh slider
					MasterVolUpdate()
				end
			end)

			-- ElvUI skin for slider control
			if LeaPlusLC.ElvUI then
				_G.LeaPlusGlobalVolumeButton = LeaPlusCB["LeaPlusMaxVol"]
				LeaPlusLC.ElvUI:GetModule("Skins"):HandleSliderFrame(_G.LeaPlusGlobalVolumeButton, false)
			end

		end

		----------------------------------------------------------------------
		--	Use arrow keys in chat
		----------------------------------------------------------------------

		if LeaPlusLC["UseArrowKeysInChat"] == "On" and not LeaLockList["UseArrowKeysInChat"] then
			-- Enable arrow keys for normal and existing chat frames
			for i = 1, 50 do
				if _G["ChatFrame" .. i] then
					_G["ChatFrame" .. i .. "EditBox"]:SetAltArrowKeyMode(false)
				end
			end
			-- Enable arrow keys for temporary chat frames
			hooksecurefunc("FCF_OpenTemporaryWindow", function()
				local cf = FCF_GetCurrentChatFrame():GetName() or nil
				if cf then
					_G[cf .. "EditBox"]:SetAltArrowKeyMode(false)
				end
			end)
		end

		----------------------------------------------------------------------
		-- L43: Manage widget
		----------------------------------------------------------------------

		if LeaPlusLC["ManageWidget"] == "On" and not LeaLockList["ManageWidget"] then

			-- Create and manage container for UIWidgetTopCenterContainerFrame
			local topCenterHolder = CreateFrame("Frame", nil, UIParent)
			topCenterHolder:SetPoint("TOP", UIParent, "TOP", 0, -15)
			topCenterHolder:SetSize(10, 58)

			local topCenterContainer = _G.UIWidgetTopCenterContainerFrame
			topCenterContainer:ClearAllPoints()
			topCenterContainer:SetPoint('CENTER', topCenterHolder)

			hooksecurefunc(topCenterContainer, 'SetPoint', function(self, void, b)
				if b and (b ~= topCenterHolder) then
					-- Reset parent if it changes from topCenterHolder
					self:ClearAllPoints()
					self:SetPoint('CENTER', topCenterHolder)
					self:SetParent(topCenterHolder)
				end
			end)

			-- Allow widget frame to be moved
			topCenterHolder:SetMovable(true)
			topCenterHolder:SetUserPlaced(true)
			topCenterHolder:SetDontSavePosition(true)
			topCenterHolder:SetClampedToScreen(false)

			-- Set widget frame position at startup
			topCenterHolder:ClearAllPoints()
			topCenterHolder:SetPoint(LeaPlusLC["WidgetA"], UIParent, LeaPlusLC["WidgetR"], LeaPlusLC["WidgetX"], LeaPlusLC["WidgetY"])
			topCenterHolder:SetScale(LeaPlusLC["WidgetScale"])
			UIWidgetTopCenterContainerFrame:SetScale(LeaPlusLC["WidgetScale"])

			-- Create drag frame
			local dragframe = CreateFrame("FRAME", nil, nil, "BackdropTemplate")
			dragframe:SetPoint("CENTER", topCenterHolder, "CENTER", 0, 1)
			dragframe:SetBackdropColor(0.0, 0.5, 1.0)
			dragframe:SetBackdrop({edgeFile = "Interface/Tooltips/UI-Tooltip-Border", tile = false, tileSize = 0, edgeSize = 16, insets = { left = 0, right = 0, top = 0, bottom = 0}})
			dragframe:SetToplevel(true)
			dragframe:Hide()
			dragframe:SetScale(LeaPlusLC["WidgetScale"])

			dragframe.t = dragframe:CreateTexture()
			dragframe.t:SetAllPoints()
			dragframe.t:SetColorTexture(0.0, 1.0, 0.0, 0.5)
			dragframe.t:SetAlpha(0.5)

			dragframe.f = dragframe:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
			dragframe.f:SetPoint('CENTER', 0, 0)
			dragframe.f:SetText(L["Widget"])

			-- Click handler
			dragframe:SetScript("OnMouseDown", function(self, btn)
				-- Start dragging if left clicked
				if btn == "LeftButton" then
					topCenterHolder:StartMoving()
				end
			end)

			dragframe:SetScript("OnMouseUp", function()
				-- Save frame position
				topCenterHolder:StopMovingOrSizing()
				LeaPlusLC["WidgetA"], void, LeaPlusLC["WidgetR"], LeaPlusLC["WidgetX"], LeaPlusLC["WidgetY"] = topCenterHolder:GetPoint()
				topCenterHolder:SetMovable(true)
				topCenterHolder:ClearAllPoints()
				topCenterHolder:SetPoint(LeaPlusLC["WidgetA"], UIParent, LeaPlusLC["WidgetR"], LeaPlusLC["WidgetX"], LeaPlusLC["WidgetY"])
			end)

			-- Snap-to-grid
			do
				local frame, grid = dragframe, 10
				local w, h = 0, 60
				local xpos, ypos, scale, uiscale
				frame:RegisterForDrag("RightButton")
				frame:HookScript("OnDragStart", function()
					frame:SetScript("OnUpdate", function()
						scale, uiscale = frame:GetScale(), UIParent:GetScale()
						xpos, ypos = GetCursorPosition()
						xpos = floor((xpos / scale / uiscale) / grid) * grid - w / 2
						ypos = ceil((ypos / scale / uiscale) / grid) * grid + h / 2
						topCenterHolder:ClearAllPoints()
						topCenterHolder:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", xpos, ypos)
					end)
				end)
				frame:HookScript("OnDragStop", function()
					frame:SetScript("OnUpdate", nil)
					frame:GetScript("OnMouseUp")()
				end)
			end

			-- Create configuration panel
			local WidgetPanel = LeaPlusLC:CreatePanel("Manage widget", "WidgetPanel")

			-- Create Titan Panel screen adjust warning
			local titanFrame = CreateFrame("FRAME", nil, WidgetPanel)
			titanFrame:SetAllPoints()
			titanFrame:Hide()
			LeaPlusLC:MakeTx(titanFrame, "Warning", 16, -172)
			titanFrame.txt = LeaPlusLC:MakeWD(titanFrame, "Titan Panel screen adjust needs to be disabled for the frame to be saved correctly.", 16, -192, 500)
			titanFrame.txt:SetWordWrap(false)
			titanFrame.txt:SetWidth(520)
			titanFrame.btn = LeaPlusLC:CreateButton("fixTitanBtn", titanFrame, "Okay, disable screen adjust for me", "TOPLEFT", 16, -212, 0, 25, true, "Click to disable Titan Panel screen adjust.  Your UI will be reloaded.")
			titanFrame.btn:SetScript("OnClick", function()
				TitanPanelSetVar("ScreenAdjust", 1)
				ReloadUI()
			end)

			LeaPlusLC:MakeTx(WidgetPanel, "Scale", 16, -72)
			LeaPlusLC:MakeSL(WidgetPanel, "WidgetScale", "Drag to set the widget scale.", 0.5, 2, 0.05, 16, -92, "%.2f")

			-- Set scale when slider is changed
			LeaPlusCB["WidgetScale"]:HookScript("OnValueChanged", function()
				topCenterHolder:SetScale(LeaPlusLC["WidgetScale"])
				UIWidgetTopCenterContainerFrame:SetScale(LeaPlusLC["WidgetScale"])
				dragframe:SetScale(LeaPlusLC["WidgetScale"])
				-- Show formatted slider value
				LeaPlusCB["WidgetScale"].f:SetFormattedText("%.0f%%", LeaPlusLC["WidgetScale"] * 100)
			end)

			-- Hide frame alignment grid with panel
			WidgetPanel:HookScript("OnHide", function()
				LeaPlusLC.grid:Hide()
			end)

			-- Toggle grid button
			local WidgetToggleGridButton = LeaPlusLC:CreateButton("WidgetToggleGridButton", WidgetPanel, "Toggle Grid", "TOPLEFT", 16, -72, 0, 25, true, "Click to toggle the frame alignment grid.")
			LeaPlusCB["WidgetToggleGridButton"]:ClearAllPoints()
			LeaPlusCB["WidgetToggleGridButton"]:SetPoint("LEFT", WidgetPanel.h, "RIGHT", 10, 0)
			LeaPlusCB["WidgetToggleGridButton"]:SetScript("OnClick", function()
				if LeaPlusLC.grid:IsShown() then LeaPlusLC.grid:Hide() else LeaPlusLC.grid:Show() end
			end)
			WidgetPanel:HookScript("OnHide", function()
				if LeaPlusLC.grid then LeaPlusLC.grid:Hide() end
			end)

			-- Help button tooltip
			WidgetPanel.h.tiptext = L["Drag the frame overlay with the left button to position it freely or with the right button to position it using snap-to-grid."]

			-- Back button handler
			WidgetPanel.b:SetScript("OnClick", function()
				WidgetPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page6"]:Show()
				return
			end)

			-- Reset button handler
			WidgetPanel.r:SetScript("OnClick", function()

				-- Reset position and scale
				LeaPlusLC["WidgetA"] = "TOP"
				LeaPlusLC["WidgetR"] = "TOP"
				LeaPlusLC["WidgetX"] = 0
				LeaPlusLC["WidgetY"] = -15
				LeaPlusLC["WidgetScale"] = 1
				topCenterHolder:ClearAllPoints()
				topCenterHolder:SetPoint(LeaPlusLC["WidgetA"], UIParent, LeaPlusLC["WidgetR"], LeaPlusLC["WidgetX"], LeaPlusLC["WidgetY"])

				-- Refresh configuration panel
				WidgetPanel:Hide(); WidgetPanel:Show()
				dragframe:Show()

				-- Show frame alignment grid
				LeaPlusLC.grid:Show()

			end)

			-- Show configuration panel when options panel button is clicked
			LeaPlusCB["ManageWidgetButton"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					LeaPlusLC["WidgetA"] = "CENTER"
					LeaPlusLC["WidgetR"] = "CENTER"
					LeaPlusLC["WidgetX"] = 0
					LeaPlusLC["WidgetY"] = -160
					LeaPlusLC["WidgetScale"] = 1.25
					topCenterHolder:ClearAllPoints()
					topCenterHolder:SetPoint(LeaPlusLC["WidgetA"], UIParent, LeaPlusLC["WidgetR"], LeaPlusLC["WidgetX"], LeaPlusLC["WidgetY"])
					topCenterHolder:SetScale(LeaPlusLC["WidgetScale"])
					UIWidgetTopCenterContainerFrame:SetScale(LeaPlusLC["WidgetScale"])
				else
					-- Show Titan Panel screen adjust warning if Titan Panel is installed with screen adjust enabled
					if C_AddOns.IsAddOnLoaded("TitanClassic") then
						if TitanPanelSetVar and TitanPanelGetVar then
							if not TitanPanelGetVar("ScreenAdjust") then
								titanFrame:Show()
							end
						end
					end

					-- Find out if the UI has a non-standard scale
					if GetCVar("useuiscale") == "1" then
						LeaPlusLC["gscale"] = GetCVar("uiscale")
					else
						LeaPlusLC["gscale"] = 1
					end

					-- Set drag frame size according to UI scale
					dragframe:SetWidth(160 * LeaPlusLC["gscale"])
					dragframe:SetHeight(79 * LeaPlusLC["gscale"])

					-- Show configuration panel
					WidgetPanel:Show()
					LeaPlusLC:HideFrames()
					dragframe:Show()

					-- Show frame alignment grid
					LeaPlusLC.grid:Show()
				end
			end)

			-- Hide drag frame when configuration panel is closed
			WidgetPanel:HookScript("OnHide", function() dragframe:Hide() end)

		end

		----------------------------------------------------------------------
		-- Hide chat buttons
		----------------------------------------------------------------------

		if LeaPlusLC["NoChatButtons"] == "On" and not LeaLockList["NoChatButtons"] then

			-- Create hidden frame to store unwanted frames (more efficient than creating functions)
			local tframe = CreateFrame("FRAME")
			tframe:Hide()

			-- Function to enable mouse scrolling with CTRL and SHIFT key modifiers
			local function AddMouseScroll(chtfrm)
				if _G[chtfrm] then
					_G[chtfrm]:SetScript("OnMouseWheel", function(self, direction)
						if direction == 1 then
							if IsControlKeyDown() then
								self:ScrollToTop()
							elseif IsShiftKeyDown() then
								self:PageUp()
							else
								self:ScrollUp()
							end
						else
							if IsControlKeyDown() then
								self:ScrollToBottom()
							elseif IsShiftKeyDown() then
								self:PageDown()
							else
								self:ScrollDown()
							end
						end
					end)
					_G[chtfrm]:EnableMouseWheel(true)
				end
			end

			-- Function to hide chat buttons
			local function HideButtons(chtfrm)
				_G[chtfrm .. "ButtonFrameUpButton"]:SetParent(tframe)
				_G[chtfrm .. "ButtonFrameDownButton"]:SetParent(tframe)
				_G[chtfrm .. "ButtonFrameUpButton"]:Hide()
				_G[chtfrm .. "ButtonFrameDownButton"]:Hide()
				_G[chtfrm .. "ButtonFrame"]:SetSize(0.1, 0.1)
				_G[chtfrm .. "MinimizeButton"]:SetParent(tframe)
			end

			FriendsMicroButton:Hide()

			-- Function to highlight chat tabs and click to scroll to bottom
			local function HighlightTabs(chtfrm)

				-- Hide bottom button
				_G[chtfrm .. "ButtonFrameBottomButton"]:SetSize(0.1, 0.1) -- Positions it away

				-- Remove click from the bottom button
				_G[chtfrm .. "ButtonFrameBottomButton"]:SetScript("OnClick", nil)

				-- Remove textures
				_G[chtfrm .. "ButtonFrameBottomButton"]:SetNormalTexture("")
				_G[chtfrm .. "ButtonFrameBottomButton"]:SetHighlightTexture("")
				_G[chtfrm .. "ButtonFrameBottomButton"]:SetPushedTexture("")
				_G[chtfrm .. "ButtonFrameBottomButton"]:SetDisabledTexture("")

				-- Resize bottom button according to tab size
				_G[chtfrm .. "Tab"]:SetScript("OnSizeChanged", function()
					for j = 1, 50 do
						-- Resize bottom button to tab width
						if _G["ChatFrame" .. j .. "ButtonFrameBottomButton"] then
							_G["ChatFrame" .. j .. "ButtonFrameBottomButton"]:SetWidth(_G["ChatFrame" .. j .. "Tab"]:GetWidth()-10)
						end
					end
					-- If combat log is hidden, resize it's bottom button
					if LeaPlusLC["NoCombatLogTab"] == "On" and not LeaLockList["NoCombatLogTab"] then
						if _G["ChatFrame2ButtonFrameBottomButton"] then
							-- Resize combat log bottom button
							_G["ChatFrame2ButtonFrameBottomButton"]:SetWidth(0.1);
						end
					end
				end)

				-- Remove click from the bottom button
				_G[chtfrm .. "ButtonFrameBottomButton"]:SetScript("OnClick", nil)

				-- Remove textures
				_G[chtfrm .. "ButtonFrameBottomButton"]:SetNormalTexture("")
				_G[chtfrm .. "ButtonFrameBottomButton"]:SetHighlightTexture("")
				_G[chtfrm .. "ButtonFrameBottomButton"]:SetPushedTexture("")

				-- Always scroll to bottom when clicking a tab
				_G[chtfrm .. "Tab"]:HookScript("OnClick", function(self,arg1)
					if arg1 == "LeftButton" then
						_G[chtfrm]:ScrollToBottom();
					end
				end)

				-- Create new bottom button under tab
				_G[chtfrm .. "Tab"].newglow = _G[chtfrm .. "Tab"]:CreateTexture(nil, "BACKGROUND")
				_G[chtfrm .. "Tab"].newglow:ClearAllPoints()
				_G[chtfrm .. "Tab"].newglow:SetAllPoints()
				_G[chtfrm .. "Tab"].newglow:SetTexture("Interface\\ChatFrame\\ChatFrameTab-NewMessage")
				_G[chtfrm .. "Tab"].newglow:SetVertexColor(0.6, 0.6, 1, 0.7)
				_G[chtfrm .. "Tab"].newglow:SetBlendMode("ADD")
				_G[chtfrm .. "Tab"].newglow:Hide()

				-- Show new bottom button when old one glows
				_G[chtfrm .. "ButtonFrameBottomButtonFlash"]:HookScript("OnShow", function(self,arg1)
					_G[chtfrm .. "Tab"].newglow:Show()
				end)

				_G[chtfrm .. "ButtonFrameBottomButtonFlash"]:HookScript("OnHide", function(self,arg1)
					_G[chtfrm .. "Tab"].newglow:Hide()
				end)

			end

			-- Hide chat menu buttons
			ChatFrameMenuButton:SetParent(tframe)
			ChatFrameChannelButton:SetParent(tframe)

			-- Set options for normal and existing chat frames
			for i = 1, 50 do
				if _G["ChatFrame" .. i] then
					AddMouseScroll("ChatFrame" .. i)
					HideButtons("ChatFrame" .. i)
					HighlightTabs("ChatFrame" .. i)
				end
			end

			-- Do the functions above for temporary chat frames
			hooksecurefunc("FCF_OpenTemporaryWindow", function(chatType)
				local cf = FCF_GetCurrentChatFrame():GetName() or nil
				if cf then

					-- Set options for temporary frame
					AddMouseScroll(cf)
					HideButtons(cf)
					HighlightTabs(cf)

					-- Create new bottom button under tab
					_G[cf .. "Tab"].newglow = _G[cf .. "Tab"]:CreateTexture(nil, "BACKGROUND")
					_G[cf .. "Tab"].newglow:ClearAllPoints()
					_G[cf .. "Tab"].newglow:SetAllPoints()
					_G[cf .. "Tab"].newglow:SetTexture("Interface\\ChatFrame\\ChatFrameTab-NewMessage")
					_G[cf .. "Tab"].newglow:SetVertexColor(0.6, 0.6, 1, 1)
					_G[cf .. "Tab"].newglow:SetBlendMode("ADD")
					_G[cf .. "Tab"].newglow:Hide()

					-- Show new bottom button when old one glows
					_G[cf].ScrollToBottomButton.Flash:HookScript("OnShow", function(self,arg1)
						_G[cf .. "Tab"].newglow:Show()
					end)

					_G[cf].ScrollToBottomButton.Flash:HookScript("OnHide", function(self,arg1)
						_G[cf .. "Tab"].newglow:Hide()
					end)

				end
			end)

		end

		----------------------------------------------------------------------
		-- Recent chat window
		----------------------------------------------------------------------

		if LeaPlusLC["RecentChatWindow"] == "On" and not LeaLockList["RecentChatWindow"] then

			-- Create recent chat frame
			local editFrame = CreateFrame("ScrollFrame", nil, UIParent, "LeaPlusRecentChatScrollFrameTemplate")

			-- Set frame parameters
			editFrame:ClearAllPoints()
			editFrame:SetPoint("BOTTOM", 0, 130)
			editFrame:SetSize(600, LeaPlusLC["RecentChatSize"])
			editFrame:SetFrameStrata("MEDIUM")
			editFrame:SetToplevel(true)
			editFrame:Hide()

			-- Add background color
			editFrame.t = editFrame:CreateTexture(nil, "BACKGROUND")
			editFrame.t:SetAllPoints()
			editFrame.t:SetColorTexture(0.00, 0.00, 0.0, 0.6)

			-- Create character count
			editFrame.CharCount = editFrame:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
			editFrame.CharCount:Hide()

			-- Create title bar
			local titleFrame = CreateFrame("Frame", nil, editFrame)
			titleFrame:ClearAllPoints()
			titleFrame:SetPoint("TOP", 0, 24)
			titleFrame:SetSize(600, 24)
			titleFrame:SetFrameStrata("MEDIUM")
			titleFrame:SetToplevel(true)
			titleFrame:SetHitRectInsets(-6, -6, -6, -6)
			titleFrame.t = titleFrame:CreateTexture(nil, "BACKGROUND")
			titleFrame.t:SetAllPoints()
			titleFrame.t:SetColorTexture(0.00, 0.00, 0.0, 0.8)

			-- Add message count
			titleFrame.m = titleFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
			titleFrame.m:SetPoint("LEFT", 4, 0)
			titleFrame.m:SetText(L["Messages"] .. ": 0")
			titleFrame.m:SetFont(titleFrame.m:GetFont(), 16, nil)

			-- Add right-click to close message
			titleFrame.x = titleFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
			titleFrame.x:SetPoint("RIGHT", -4, 0)
			titleFrame.x:SetText(L["Drag to size"] .. " | " .. L["Right-click to close"])
			titleFrame.x:SetFont(titleFrame.x:GetFont(), 16, nil)
			titleFrame.x:SetWidth(600 - titleFrame.m:GetStringWidth() - 30)
			titleFrame.x:SetWordWrap(false)
			titleFrame.x:SetJustifyH("RIGHT")

			-- Drag to resize
			editFrame:SetResizable(true)
			editFrame:SetResizeBounds(600, 170, 600, 560)

			titleFrame:HookScript("OnMouseDown", function(self, btn)
				if btn == "LeftButton" then
					editFrame:StartSizing("TOP")
				end
			end)
			titleFrame:HookScript("OnMouseUp", function(self, btn)
				if btn == "LeftButton" then
					editFrame:StopMovingOrSizing()
					LeaPlusLC["RecentChatSize"] = editFrame:GetHeight()
				elseif btn == "MiddleButton" then
					-- Reset frame size
					LeaPlusLC["RecentChatSize"] = 170
					editFrame:SetSize(600, LeaPlusLC["RecentChatSize"])
					editFrame:ClearAllPoints()
					editFrame:SetPoint("BOTTOM", 0, 130)
				end
			end)

			-- Create editbox
			local editBox = editFrame.EditBox
			editBox:SetAltArrowKeyMode(false)
			editBox:SetTextInsets(4, 4, 4, 4)
			editBox:SetWidth(editFrame:GetWidth() - 30)
			editBox:SetSecurityDisablePaste()
			editBox:SetMaxLetters(0)

			editFrame:SetScrollChild(editBox)

			-- Manage focus
			editBox:HookScript("OnEditFocusLost", function()
				if MouseIsOver(titleFrame) and IsMouseButtonDown("LeftButton") then
					editBox:SetFocus()
				end
			end)

			-- Close frame with right-click of editframe or editbox
			local function CloseRecentChatWindow()
				editBox:SetText("")
				editBox:ClearFocus()
				editFrame:Hide()
			end

			editFrame:SetScript("OnMouseDown", function(self, btn)
				if btn == "RightButton" then CloseRecentChatWindow() end
			end)

			editBox:SetScript("OnMouseDown", function(self, btn)
				if btn == "RightButton" then CloseRecentChatWindow() end
			end)

			titleFrame:HookScript("OnMouseDown", function(self, btn)
				if btn == "RightButton" then CloseRecentChatWindow() end
			end)

			-- Disable text changes while still allowing editing controls to work
			editBox:EnableKeyboard(false)
			editBox:SetScript("OnKeyDown", function() end)

			-- Populate recent chat frame with chat messages
			local function ShowChatbox(chtfrm)
				editBox:SetText("")
				local NumMsg = chtfrm:GetNumMessages()
				local StartMsg = 1
				if NumMsg > 256 then StartMsg = NumMsg - 255 end
				local totalMsgCount = 0
				for iMsg = StartMsg, NumMsg do
					local chatMessage, r, g, b, chatTypeID = chtfrm:GetMessageInfo(iMsg)
					if chatMessage then

						-- Handle Battle.net
						if string.match(chatMessage, "k:(%d+):(%d+):BN_WHISPER:")
						or string.match(chatMessage, "k:(%d+):(%d+):BN_INLINE_TOAST_ALERT:")
						or string.match(chatMessage, "k:(%d+):(%d+):BN_INLINE_TOAST_BROADCAST:")
						then
							local ctype
							if string.match(chatMessage, "k:(%d+):(%d+):BN_WHISPER:") then
								ctype = "BN_WHISPER"
							elseif string.match(chatMessage, "k:(%d+):(%d+):BN_INLINE_TOAST_ALERT:") then
								ctype = "BN_INLINE_TOAST_ALERT"
							elseif string.match(chatMessage, "k:(%d+):(%d+):BN_INLINE_TOAST_BROADCAST:") then
								ctype = "BN_INLINE_TOAST_BROADCAST"
							end
							local id = tonumber(string.match(chatMessage, "k:(%d+):%d+:" .. ctype .. ":"))
							local totalBNFriends = BNGetNumFriends()
							for friendIndex = 1, totalBNFriends do
								local bnetAccountID, void, battleTag = BNGetFriendInfo(friendIndex)
								if id == bnetAccountID then
									battleTag = strsplit("#", battleTag)
									chatMessage = chatMessage:gsub("(|HBNplayer%S-|k)(%d-)(:%S-" .. ctype .. "%S-|h)%[(%S-)%](|?h?)(:?)", "[" .. battleTag .. "]:")
								end
							end
						end

						-- Handle colors
						if r and g and b then
							local colorCode = RGBToColorCode(r, g, b)
							-- chatMessage = string.gsub(chatMessage, "|r", "|r" .. colorCode) -- Needed for Classic only
							chatMessage = colorCode .. chatMessage .. "|r"
						end

						chatMessage = gsub(chatMessage, "|T.-|t", "") -- Remove textures
						chatMessage = gsub(chatMessage, "|A.-|a", "") -- Remove atlases
						editBox:Insert(chatMessage .. "|r|n")

					end
					totalMsgCount = totalMsgCount + 1
				end
				titleFrame.m:SetText(L["Messages"] .. ": " .. totalMsgCount)
				editFrame:SetVerticalScroll(0)
				editFrame.ScrollBar:ScrollToEnd()
				editFrame:Show()
				editBox:ClearFocus()
			end

			-- Hook normal chat frame tab clicks
			for i = 1, 50 do
				if _G["ChatFrame" .. i] then
					_G["ChatFrame" .. i .. "Tab"]:HookScript("OnClick", function()
						if IsControlKeyDown() then
							editBox:SetFont(_G["ChatFrame" .. i]:GetFont())
							editFrame:SetPanExtent(select(2, _G["ChatFrame" .. i]:GetFont()))
							ShowChatbox(_G["ChatFrame" .. i])
						end
					end)
				end
			end

			-- Hook temporary chat frame tab clicks
			hooksecurefunc("FCF_OpenTemporaryWindow", function()
				local cf = FCF_GetCurrentChatFrame():GetName() or nil
				if cf then
					_G[cf .. "Tab"]:HookScript("OnClick", function()
						if IsControlKeyDown() then
							editBox:SetFont(_G[cf]:GetFont())
							editFrame:SetPanExtent(select(2, _G[cf]:GetFont()))
							ShowChatbox(_G[cf])
						end
					end)
				end
			end)

		end

		----------------------------------------------------------------------
		-- Show cooldowns
		----------------------------------------------------------------------

		if LeaPlusLC["ShowCooldowns"] == "On" then

			-- Create main table structure in saved variables if it doesn't exist
			if LeaPlusDB["Cooldowns"] == nil then
				LeaPlusDB["Cooldowns"] = {}
			end

			-- Create class tables if they don't exist
			local classList = {"WARRIOR", "PALADIN", "HUNTER", "SHAMAN", "ROGUE", "DRUID", "MAGE", "WARLOCK", "PRIEST"}
			for index = 1, #classList do
				if LeaPlusDB["Cooldowns"][classList[index]] == nil then
					LeaPlusDB["Cooldowns"][classList[index]] = {}
				end
			end

			-- Get current class
			local PlayerClass = select(2, UnitClass("player"))
			local activeSpec = 1 -- Fixed to 1 for Classic

			-- Create local tables to store cooldown frames and editboxes
			local icon = {} -- Used to store cooldown frames
			local SpellEB = {} -- Used to store editbox values
			local iCount = 5 -- Number of cooldowns

			-- Create cooldown frames
			for i = 1, iCount do

				-- Create cooldown frame
				icon[i] = CreateFrame("Frame", nil, UIParent)
				icon[i]:SetFrameStrata("BACKGROUND")
				icon[i]:SetWidth(20)
				icon[i]:SetHeight(20)

				-- Create cooldown icon
				icon[i].c = CreateFrame("Cooldown", nil, icon[i], "CooldownFrameTemplate")
				icon[i].c:SetAllPoints()
				icon[i].c:SetReverse(true)

				-- Create blank texture (will be assigned a cooldown texture later)
				icon[i].t = icon[i]:CreateTexture(nil,"BACKGROUND")
				icon[i].t:SetAllPoints()

				-- Show icon above target frame and set initial scale
				icon[i]:ClearAllPoints()
				icon[i]:SetPoint("TOPLEFT", TargetFrame, "TOPLEFT", 6 + (22 * (i - 1)), 5)
				icon[i]:SetScale(TargetFrame:GetScale())

				-- Show tooltip
				icon[i]:SetScript("OnEnter", function(self)
					GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT", 15, -25)
					GameTooltip:SetText(GetSpellInfo(LeaPlusCB["Spell" .. i]:GetText()))
				end)

				-- Hide tooltip
				icon[i]:SetScript("OnLeave", GameTooltip_Hide)

			end

			-- Change cooldown icon scale when player frame scale changes
			PlayerFrame:HookScript("OnSizeChanged", function()
				if LeaPlusLC["CooldownsOnPlayer"] == "On" then
					for i = 1, iCount do
						icon[i]:SetScale(PlayerFrame:GetScale())
					end
				end
			end)

			-- Change cooldown icon scale when target frame scale changes
			TargetFrame:HookScript("OnSizeChanged", function()
				if LeaPlusLC["CooldownsOnPlayer"] == "Off" then
					for i = 1, iCount do
						icon[i]:SetScale(TargetFrame:GetScale())
					end
				end
			end)

			-- Function to show cooldown textures in the cooldown frames (run when icons are loaded or changed)
			local function ShowIcon(i, id, owner)

				local void

				-- Get spell information
				local spell, void, path = GetSpellInfo(id)
				if spell and path then

					-- Set icon texture to the spell texture
					icon[i].t:SetTexture(path)

					-- Set top level and raise frame strata (ensures tooltips show properly)
					icon[i]:SetToplevel(true)
					icon[i]:SetFrameStrata("LOW")

					-- Handle events
					icon[i]:RegisterUnitEvent("UNIT_AURA", owner)
					icon[i]:RegisterUnitEvent("UNIT_PET", "player")
					icon[i]:SetScript("OnEvent", function(self, event, arg1)

						-- If pet was dismissed (or otherwise disappears such as when flying), hide pet cooldowns
						if event == "UNIT_PET" then
							if not UnitExists("pet") then
								if LeaPlusDB["Cooldowns"][PlayerClass]["S" .. activeSpec .. "R" .. i .. "Pet"] then
									icon[i]:Hide()
								end
							end

						-- Ensure cooldown belongs to the owner we are watching (player or pet)
						elseif arg1 == owner then

							-- Hide the cooldown frame (required for cooldowns to disappear after the duration)
							icon[i]:Hide()

							-- If buff matches cooldown we want, start the cooldown
							for q = 1, 40 do
								local BuffData = C_UnitAuras.GetBuffDataByIndex(owner, q)
								if BuffData then
									local spellID = BuffData.spellId
									local length = BuffData.duration
									local expire = BuffData.expirationTime
									if spellID and id == spellID then
										icon[i]:Show()
										local start = expire - length
										CooldownFrame_Set(icon[i].c, start, length, 1)
									end
								end
							end

						end
					end)

				else

					-- Spell does not exist so stop watching it
					icon[i]:SetScript("OnEvent", nil)
					icon[i]:Hide()

				end

			end

			-- Create configuration panel
			local CooldownPanel = LeaPlusLC:CreatePanel("Show cooldowns", "CooldownPanel")

			-- Function to refresh the editbox tooltip with the spell name
			local function RefSpellTip(self,elapsed)
				local spellinfo, void, icon = GetSpellInfo(self:GetText())
				if spellinfo and spellinfo ~= "" and icon and icon ~= "" then
					GameTooltip:SetOwner(self, "ANCHOR_NONE")
					GameTooltip:ClearAllPoints()
					GameTooltip:SetPoint("RIGHT", self, "LEFT", -10, 0)
					GameTooltip:SetText("|T" .. icon .. ":0|t " .. spellinfo, nil, nil, nil, nil, true)
				else
					GameTooltip:Hide()
				end
			end

			-- Function to create spell ID editboxes and pet checkboxes
			local function MakeSpellEB(num, x, y, tab, shifttab)

				-- Create editbox for spell ID
                SpellEB[num] = LeaPlusLC:CreateEditBox("Spell" .. num, CooldownPanel, 80, 8, "TOPLEFT", x, y - 20, "Spell" .. tab, "Spell" .. shifttab)
				SpellEB[num]:SetNumeric(true)

				-- Set initial value (for current spec)
				SpellEB[num]:SetText(LeaPlusDB["Cooldowns"][PlayerClass]["S" .. activeSpec .. "R" .. num .. "Idn"] or "")

				-- Refresh tooltip when mouse is hovering over the editbox
				SpellEB[num]:SetScript("OnEnter", function()
					SpellEB[num]:SetScript("OnUpdate", RefSpellTip)
				end)
				SpellEB[num]:SetScript("OnLeave", function()
					SpellEB[num]:SetScript("OnUpdate", nil)
					GameTooltip:Hide()
				end)

				-- Create checkbox for pet cooldown
				LeaPlusLC:MakeCB(CooldownPanel, "Spell" .. num .."Pet", "", 472, y - 20, false, "")
				LeaPlusCB["Spell" .. num .."Pet"]:SetHitRectInsets(0, 0, 0, 0)

			end

			-- Add titles
			LeaPlusLC:MakeTx(CooldownPanel, "Spell ID", 384, -92)
			LeaPlusLC:MakeTx(CooldownPanel, "Pet", 472, -92)

			-- Add editboxes and checkboxes
			MakeSpellEB(1, 386, -92, "2", "5")
			MakeSpellEB(2, 386, -122, "3", "1")
			MakeSpellEB(3, 386, -152, "4", "2")
			MakeSpellEB(4, 386, -182, "5", "3")
			MakeSpellEB(5, 386, -212, "1", "4")

			-- Add checkboxes
			LeaPlusLC:MakeTx(CooldownPanel, "Settings", 16, -72)
			LeaPlusLC:MakeCB(CooldownPanel, "ShowCooldownID", "Show the spell ID in buff icon tooltips", 16, -92, false, "If checked, spell IDs will be shown in buff icon tooltips located in the buff frame and under the target frame.");
			LeaPlusLC:MakeCB(CooldownPanel, "NoCooldownDuration", "Hide cooldown duration numbers (if enabled)", 16, -112, false, "If checked, cooldown duration numbers will not be shown over the cooldowns.|n|nIf unchecked, cooldown duration numbers will be shown over the cooldowns if they are enabled in the game options panel ('ActionBars' menu).")
			LeaPlusLC:MakeCB(CooldownPanel, "CooldownsOnPlayer", "Show cooldowns above the player frame", 16, -132, false, "If checked, cooldown icons will be shown above the player frame instead of the target frame.|n|nIf unchecked, cooldown icons will be shown above the target frame.")

			-- Function to save the panel control settings and refresh the cooldown icons
			local function SavePanelControls()
				for i = 1, iCount do

					-- Refresh the cooldown texture
					icon[i].c:SetCooldown(0,0)

					-- Show icons above target or player frame
					icon[i]:ClearAllPoints()
					if LeaPlusLC["CooldownsOnPlayer"] == "On" then
						icon[i]:SetPoint("TOPLEFT", PlayerFrame, "TOPLEFT", 116 + (22 * (i - 1)), 5)
						icon[i]:SetScale(PlayerFrame:GetScale())
					else
						icon[i]:SetPoint("TOPLEFT", TargetFrame, "TOPLEFT", 6 + (22 * (i - 1)), 5)
						icon[i]:SetScale(TargetFrame:GetScale())
					end

					-- Save control states to globals
					LeaPlusDB["Cooldowns"][PlayerClass]["S" .. activeSpec .. "R" .. i .. "Idn"] = SpellEB[i]:GetText()
					LeaPlusDB["Cooldowns"][PlayerClass]["S" .. activeSpec .. "R" .. i .. "Pet"] = LeaPlusCB["Spell" .. i .."Pet"]:GetChecked()

					-- Set cooldowns
					if LeaPlusCB["Spell" .. i .."Pet"]:GetChecked() then
						ShowIcon(i, tonumber(SpellEB[i]:GetText()), "pet")
					else
						ShowIcon(i, tonumber(SpellEB[i]:GetText()), "player")
					end

					-- Show or hide cooldown duration
					if LeaPlusLC["NoCooldownDuration"] == "On" then
						icon[i].c:SetHideCountdownNumbers(true)
					else
						icon[i].c:SetHideCountdownNumbers(false)
					end

					-- Show or hide cooldown icons depending on current buffs
					local newowner
					local newspell = tonumber(SpellEB[i]:GetText())

					if newspell then
						if LeaPlusDB["Cooldowns"][PlayerClass]["S" .. activeSpec .. "R" .. i .. "Pet"] then
							newowner = "pet"
						else
							newowner = "player"
						end
						-- Hide cooldown icon
						icon[i]:Hide()

						-- If buff matches spell we want, show cooldown icon
						for q = 1, 40 do
							local BuffData = C_UnitAuras.GetBuffDataByIndex(newowner, q)
							if BuffData then
								local length = BuffData.duration
								local expire = BuffData.expirationTime
								local spellID = BuffData.spellId
								if spellID and newspell == spellID then
									icon[i]:Show()
									-- Set the cooldown to the buff cooldown
									CooldownFrame_Set(icon[i].c, expire - length, length, 1)
								end
							end
						end
					end

				end

			end

			-- Update cooldown icons when checkboxes are clicked
			LeaPlusCB["NoCooldownDuration"]:HookScript("OnClick", SavePanelControls)
			LeaPlusCB["CooldownsOnPlayer"]:HookScript("OnClick", SavePanelControls)

			-- Help button hidden
			CooldownPanel.h:Hide()

			-- Back button handler
			CooldownPanel.b:SetScript("OnClick", function()
				CooldownPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page5"]:Show()
				return
			end)

			-- Reset button handler
			CooldownPanel.r:SetScript("OnClick", function()
				-- Reset the checkboxes
				LeaPlusLC["ShowCooldownID"] = "On"
				LeaPlusLC["NoCooldownDuration"] = "On"
				LeaPlusLC["CooldownsOnPlayer"] = "Off"
				for i = 1, iCount do
					-- Reset the panel controls
					SpellEB[i]:SetText("");
					LeaPlusDB["Cooldowns"][PlayerClass]["S" .. activeSpec .. "R" .. i .. "Pet"] = false
					-- Hide cooldowns and clear scripts
					icon[i]:Hide()
					icon[i]:SetScript("OnEvent", nil)
				end
				CooldownPanel:Hide(); CooldownPanel:Show()
			end)

			-- Save settings when changed
			for i = 1, iCount do
				-- Set initial checkbox states
				LeaPlusCB["Spell" .. i .."Pet"]:SetChecked(LeaPlusDB["Cooldowns"][PlayerClass]["S" .. activeSpec .. "R" .. i .. "Pet"])
				-- Set checkbox states when shown
				LeaPlusCB["Spell" .. i .."Pet"]:SetScript("OnShow", function()
					LeaPlusCB["Spell" .. i .."Pet"]:SetChecked(LeaPlusDB["Cooldowns"][PlayerClass]["S" .. activeSpec .. "R" .. i .. "Pet"])
				end)
				-- Set states when changed
				SpellEB[i]:SetScript("OnTextChanged", SavePanelControls)
				LeaPlusCB["Spell" .. i .."Pet"]:SetScript("OnClick", SavePanelControls)
			end

			-- Show cooldowns on startup
			SavePanelControls()

			-- Show panel when configuration button is clicked
			LeaPlusCB["CooldownsButton"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- No preset profile
				else
					-- Show panel
					CooldownPanel:Show()
					LeaPlusLC:HideFrames()
				end
			end)

			-- Create class tag banner fontstring
			local classTagBanner = CooldownPanel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
			local myClassName = UnitClass("player")
			classTagBanner:SetPoint("TOPLEFT", 384, -72)
			classTagBanner:SetText(myClassName)

			-- Add help button
			LeaPlusLC:CreateHelpButton("ShowCooldownsHelpButton", CooldownPanel, classTagBanner, "Enter the spell IDs for the cooldown icons that you want to see.|n|nIf a cooldown icon normally appears under the pet frame, check the pet checkbox.|n|nCooldown icons are saved to your class.")

			-- Function to show spell ID in tooltips
			local function CooldownIDFunc(unit, target, index, auratype)
				if LeaPlusLC["ShowCooldownID"] == "On" and auratype ~= "HARMFUL" then
					local AuraData = C_UnitAuras.GetAuraDataByIndex(target, index)
					if AuraData then
						local spellid = AuraData.spellId
						if spellid then
							GameTooltip:AddLine(L["Spell ID"] .. ": " .. spellid)
							GameTooltip:Show()
						end
					end
				end
			end

			-- Add spell ID to tooltip when buff frame buffs are hovered
			hooksecurefunc(GameTooltip, 'SetUnitAura', CooldownIDFunc)

			-- Add spell ID to tooltip when target frame buffs are hovered
			hooksecurefunc(GameTooltip, 'SetUnitBuff', CooldownIDFunc)

		end

		----------------------------------------------------------------------
		-- Combat plates
		----------------------------------------------------------------------

		if LeaPlusLC["CombatPlates"] == "On" then

			-- Toggle nameplates with combat
			local f = CreateFrame("Frame")
			f:RegisterEvent("PLAYER_REGEN_DISABLED")
			f:RegisterEvent("PLAYER_REGEN_ENABLED")
			f:SetScript("OnEvent", function(self, event)
				SetCVar("nameplateShowEnemies", event == "PLAYER_REGEN_DISABLED" and 1 or 0)
			end)

			-- Run combat check on startup
			SetCVar("nameplateShowEnemies", UnitAffectingCombat("player") and 1 or 0)

		end

		----------------------------------------------------------------------
		-- Enhance tooltip
		----------------------------------------------------------------------

		if LeaPlusLC["TipModEnable"] == "On" and not LeaLockList["TipModEnable"] then

			-- Enable mouse hover events for world frame (required for hide tooltips, cursor anchor and maybe other addons)
			WorldFrame:EnableMouseMotion(true) -- LeaPlusLC.NewPatch: Using GetMouseFoci()[1] for now

			----------------------------------------------------------------------
			--	Position the tooltip
			----------------------------------------------------------------------

			hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
				if LeaPlusLC["TooltipAnchorMenu"] ~= 1 then
					if (not tooltip or not parent) then
						return
					end
					if LeaPlusLC["TooltipAnchorMenu"] == 2 or not WorldFrame:IsMouseMotionFocus() then
						local a,b,c,d,e = tooltip:GetPoint()
						if a ~= "BOTTOMRIGHT" or c ~= "BOTTOMRIGHT" then
							tooltip:ClearAllPoints()
						end
						tooltip:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", LeaPlusLC["TipOffsetX"], LeaPlusLC["TipOffsetY"]);
						return
					else
						if LeaPlusLC["TooltipAnchorMenu"] == 3 then
							tooltip:SetOwner(parent, "ANCHOR_CURSOR")
							return
						elseif LeaPlusLC["TooltipAnchorMenu"] == 4 then
							tooltip:SetOwner(parent, "ANCHOR_CURSOR_LEFT", LeaPlusLC["TipCursorX"], LeaPlusLC["TipCursorY"])
							return
						elseif LeaPlusLC["TooltipAnchorMenu"] == 5 then
							tooltip:SetOwner(parent, "ANCHOR_CURSOR_RIGHT", LeaPlusLC["TipCursorX"], LeaPlusLC["TipCursorY"])
							return
						end
					end
				end
			end)

			----------------------------------------------------------------------
			--	Tooltip Configuration
			----------------------------------------------------------------------

			local LT = {}

			-- Create locale specific level string
			LT["LevelLocale"] = strtrim(strtrim(string.gsub(TOOLTIP_UNIT_LEVEL, "%%s", "")))
			if GameLocale == "ruRU" then
				LT["LevelLocale"] = "-ro уровня"
			end

			-- Tooltip
			LT["ColorBlind"] = GetCVar("colorblindMode")

			-- 	Create drag frame
			local TipDrag = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
			TipDrag:SetToplevel(true);
			TipDrag:SetClampedToScreen(false);
			TipDrag:SetSize(130, 64);
			TipDrag:Hide();
			TipDrag:SetFrameStrata("TOOLTIP")
			TipDrag:SetMovable(true)
			TipDrag:SetBackdropColor(0.0, 0.5, 1.0);
			TipDrag:SetBackdrop({
				edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
				tile = false, tileSize = 0, edgeSize = 16,
				insets = { left = 0, right = 0, top = 0, bottom = 0 }});

			-- Show text in drag frame
			TipDrag.f = TipDrag:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
			TipDrag.f:SetPoint("CENTER", 0, 0)
			TipDrag.f:SetText(L["Tooltip"])

			-- Create texture
			TipDrag.t = TipDrag:CreateTexture();
			TipDrag.t:SetAllPoints();
			TipDrag.t:SetColorTexture(0.0, 0.5, 1.0, 0.5);
			TipDrag.t:SetAlpha(0.5);

			---------------------------------------------------------------------------------------------------------
			-- Tooltip movement settings
			---------------------------------------------------------------------------------------------------------

			-- Create tooltip customisation side panel
			local SideTip = LeaPlusLC:CreatePanel("Enhance tooltip", "SideTip")

			-- Add controls
			LeaPlusLC:MakeTx(SideTip, "Settings", 16, -72)
			LeaPlusLC:MakeCB(SideTip, "TipShowRank", "Show guild ranks for your guild", 16, -92, false, "If checked, guild ranks will be shown for players in your guild.")
			LeaPlusLC:MakeCB(SideTip, "TipShowOtherRank", "Show guild ranks for other guilds", 16, -112, false, "If checked, guild ranks will be shown for players who are not in your guild.")
			LeaPlusLC:MakeCB(SideTip, "TipShowTarget", "Show unit targets", 16, -132, false, "If checked, unit targets will be shown.")
			LeaPlusLC:MakeCB(SideTip, "TipNoHealthBar", "Hide the health bar", 16, -152, true, "If checked, the health bar will not be shown.")

			LeaPlusLC:MakeTx(SideTip, "Hide tooltips", 16, -192)
			LeaPlusLC:MakeCB(SideTip, "TipHideInCombat", "Hide tooltips for world units during combat", 16, -212, false, "If checked, tooltips for world units will be hidden during combat.")
			LeaPlusLC:MakeCB(SideTip, "TipHideShiftOverride", "Show tooltips with shift key", 16, -232, false, "If checked, you can hold shift while tooltips are hidden to show them temporarily.")

			-- Handle show tooltips with shift key lock
			local function SetTipHideShiftOverrideFunc()
				if LeaPlusLC["TipHideInCombat"] == "On" then
					LeaPlusLC:LockItem(LeaPlusCB["TipHideShiftOverride"], false)
				else
					LeaPlusLC:LockItem(LeaPlusCB["TipHideShiftOverride"], true)
				end
			end

			LeaPlusCB["TipHideInCombat"]:HookScript("OnClick", SetTipHideShiftOverrideFunc)
			SetTipHideShiftOverrideFunc()

			LeaPlusLC:CreateDropdown("TooltipAnchorMenu", "Anchor", 146, "TOPLEFT", SideTip, "TOPLEFT", 356, -92, false, {{L["None"], 1}, {L["Overlay"], 2}, {L["Cursor"], 3}, {L["Cursor Left"], 4}, {L["Cursor Right"], 5}})

			local XOffsetHeading = LeaPlusLC:MakeTx(SideTip, "X Offset", 356, -132)
			LeaPlusLC:MakeSL(SideTip, "TipCursorX", "Drag to set the cursor X offset.", -128, 128, 1, 356, -152, "%.0f")

			local YOffsetHeading = LeaPlusLC:MakeTx(SideTip, "Y Offset", 356, -182)
			LeaPlusLC:MakeSL(SideTip, "TipCursorY", "Drag to set the cursor Y offset.", -128, 128, 1, 356, -202, "%.0f")

			LeaPlusLC:MakeTx(SideTip, "Scale", 356, -232)
			LeaPlusLC:MakeSL(SideTip, "LeaPlusTipSize", "Drag to set the tooltip scale.", 0.50, 2.00, 0.05, 356, -252, "%.2f")

			-- Function to enable or disable anchor controls
			local function SetAnchorControls()
				-- Hide overlay if anchor is set to none
				if LeaPlusLC["TooltipAnchorMenu"] == 1 then
					TipDrag:Hide()
				else
					TipDrag:Show()
				end
				-- Set the X and Y sliders
				if LeaPlusLC["TooltipAnchorMenu"] == 1 or LeaPlusLC["TooltipAnchorMenu"] == 2 or LeaPlusLC["TooltipAnchorMenu"] == 3 then
					-- Dropdown is set to screen or cursor so disable X and Y offset sliders
					LeaPlusLC:LockItem(LeaPlusCB["TipCursorX"], true)
					LeaPlusLC:LockItem(LeaPlusCB["TipCursorY"], true)
					XOffsetHeading:SetAlpha(0.3)
					YOffsetHeading:SetAlpha(0.3)
					LeaPlusCB["TipCursorX"]:SetScript("OnEnter", nil)
					LeaPlusCB["TipCursorY"]:SetScript("OnEnter", nil)
				else
					-- Dropdown is set to cursor left or cursor right so enable X and Y offset sliders
					LeaPlusLC:LockItem(LeaPlusCB["TipCursorX"], false)
					LeaPlusLC:LockItem(LeaPlusCB["TipCursorY"], false)
					XOffsetHeading:SetAlpha(1.0)
					YOffsetHeading:SetAlpha(1.0)
					LeaPlusCB["TipCursorX"]:SetScript("OnEnter", LeaPlusLC.TipSee)
					LeaPlusCB["TipCursorY"]:SetScript("OnEnter", LeaPlusLC.TipSee)
				end
			end

			-- Set controls when anchor dropdown menu is changed and on startup
			LeaPlusCB["TooltipAnchorMenu"]:RegisterCallback("OnMenuClose", SetAnchorControls)
			SetAnchorControls()

			---------------------------------------------------------------------------------------------------------
			-- Rest of configuration panel
			---------------------------------------------------------------------------------------------------------

			-- Help button hidden
			SideTip.h:Hide()

			-- Back button handler
			SideTip.b:SetScript("OnClick", function()
				SideTip:Hide();
				if TipDrag:IsShown() then
					TipDrag:Hide();
				end
				LeaPlusLC["PageF"]:Show();
				LeaPlusLC["Page5"]:Show();
				return
			end)

			-- Reset button handler
			SideTip.r.tiptext = SideTip.r.tiptext .. "|n|n" .. L["Note that this will not reset settings that require a UI reload."]
			SideTip.r:SetScript("OnClick", function()
				LeaPlusLC["TipShowRank"] = "On"
				LeaPlusLC["TipShowOtherRank"] = "Off"
				LeaPlusLC["TipShowTarget"] = "On"
				LeaPlusLC["TipHideInCombat"] = "Off"; SetTipHideShiftOverrideFunc()
				LeaPlusLC["TipHideShiftOverride"] = "On"
				LeaPlusLC["LeaPlusTipSize"] = 1.00
				LeaPlusLC["TipOffsetX"] = -13
				LeaPlusLC["TipOffsetY"] = 94
				LeaPlusLC["TooltipAnchorMenu"] = 1
				LeaPlusLC["TipCursorX"] = 0
				LeaPlusLC["TipCursorY"] = 0
				TipDrag:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", LeaPlusLC["TipOffsetX"], LeaPlusLC["TipOffsetY"]);
				SetAnchorControls()
				LeaPlusLC:SetTipScale()
				SideTip:Hide(); SideTip:Show();
			end)

			-- Show drag frame with configuration panel if anchor is not set to none
			SideTip:HookScript("OnShow", function()
				if LeaPlusLC["TooltipAnchorMenu"] == 1 then
					TipDrag:Hide()
				else
					TipDrag:Show()
				end
			end)
			SideTip:HookScript("OnHide", function() TipDrag:Hide() end)

			-- Control movement functions
			local void, LTax, LTay, LTbx, LTby, LTcx, LTcy
			TipDrag:SetScript("OnMouseDown", function(self, btn)
				if btn == "LeftButton" then
					void, void, void, LTax, LTay = TipDrag:GetPoint()
					TipDrag:StartMoving()
					void, void, void, LTbx, LTby = TipDrag:GetPoint()
				end
			end)
			TipDrag:SetScript("OnMouseUp", function(self, btn)
				if btn == "LeftButton" then
					void, void, void, LTcx, LTcy = TipDrag:GetPoint()
					TipDrag:StopMovingOrSizing();
					LeaPlusLC["TipOffsetX"], LeaPlusLC["TipOffsetY"] = LTcx - LTbx + LTax, LTcy - LTby + LTay
					TipDrag:ClearAllPoints()
					TipDrag:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", LeaPlusLC["TipOffsetX"], LeaPlusLC["TipOffsetY"])
				end
			end)

			--	Move the tooltip
			LeaPlusCB["MoveTooltipButton"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					LeaPlusLC["TipShowRank"] = "On"
					LeaPlusLC["TipShowOtherRank"] = "Off"
					LeaPlusLC["TipShowTarget"] = "On"
					LeaPlusLC["TipHideInCombat"] = "Off"; SetTipHideShiftOverrideFunc()
					LeaPlusLC["TipHideShiftOverride"] = "On"
					LeaPlusLC["LeaPlusTipSize"] = 1.25
					LeaPlusLC["TipOffsetX"] = -13
					LeaPlusLC["TipOffsetY"] = 94
					LeaPlusLC["TooltipAnchorMenu"] = 2
					LeaPlusLC["TipCursorX"] = 0
					LeaPlusLC["TipCursorY"] = 0
					TipDrag:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", LeaPlusLC["TipOffsetX"], LeaPlusLC["TipOffsetY"]);
					SetAnchorControls()
					LeaPlusLC:SetTipScale()
					LeaPlusLC:SetDim();
					LeaPlusLC:ReloadCheck()
					SideTip:Show(); SideTip:Hide(); -- Needed to update tooltip scale
					LeaPlusLC["PageF"]:Hide(); LeaPlusLC["PageF"]:Show()
				else
					-- Show tooltip configuration panel
					LeaPlusLC:HideFrames()
					SideTip:Show()

					-- Set scale
					TipDrag:SetScale(LeaPlusLC["LeaPlusTipSize"])

					-- Set position of the drag frame
					TipDrag:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", LeaPlusLC["TipOffsetX"], LeaPlusLC["TipOffsetY"])
				end

			end)

			-- Hide health bar
			if LeaPlusLC["TipNoHealthBar"] == "On" then
				local tipHide = GameTooltip.Hide
				GameTooltipStatusBar:HookScript("OnShow", tipHide)
				GameTooltipStatusBar:Hide()
			end

			---------------------------------------------------------------------------------------------------------
			-- Tooltip scale settings
			---------------------------------------------------------------------------------------------------------

			-- Function to set the tooltip scale
			local function SetTipScale()

				-- General tooltip
				if GameTooltip then GameTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"]) end

				-- Friends
				if FriendsTooltip then FriendsTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"]) end

				-- AutoCompleteBox
				if AutoCompleteBox then AutoCompleteBox:SetScale(LeaPlusLC["LeaPlusTipSize"]) end

				-- Items (links, comparisons)
				if ItemRefTooltip then ItemRefTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"]) end
				if ItemRefShoppingTooltip1 then ItemRefShoppingTooltip1:SetScale(LeaPlusLC["LeaPlusTipSize"]) end
				if ItemRefShoppingTooltip2 then ItemRefShoppingTooltip2:SetScale(LeaPlusLC["LeaPlusTipSize"]) end
				if ShoppingTooltip1 then ShoppingTooltip1:SetScale(LeaPlusLC["LeaPlusTipSize"]) end
				if ShoppingTooltip2 then ShoppingTooltip2:SetScale(LeaPlusLC["LeaPlusTipSize"]) end

				-- Embedded item tooltip (as used in PVP UI)
				if EmbeddedItemTooltip then EmbeddedItemTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"]) end

				-- Nameplate tooltip
				if NamePlateTooltip then NamePlateTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"]) end

				-- LibDBIcon
				if LibDBIconTooltip then LibDBIconTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"]) end

				-- Total RP 3
				if C_AddOns.IsAddOnLoaded("totalRP3") and TRP3_MainTooltip and TRP3_CharacterTooltip then
					TRP3_MainTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"])
					TRP3_CharacterTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"])
				end

				-- Altoholic
				if AltoTooltip then
					AltoTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"])
				end

				-- Leatrix Plus
				TipDrag:SetScale(LeaPlusLC["LeaPlusTipSize"])

				-- Set slider formatted text
				LeaPlusCB["LeaPlusTipSize"].f:SetFormattedText("%.0f%%", LeaPlusLC["LeaPlusTipSize"] * 100)

			end

			-- Give function a file level scope
			LeaPlusLC.SetTipScale = SetTipScale

			-- Set tooltip scale when slider or checkbox changes and on startup
			LeaPlusCB["LeaPlusTipSize"]:HookScript("OnValueChanged", SetTipScale)
			SetTipScale()

			----------------------------------------------------------------------
			-- Blizzard Settings tooltip
			----------------------------------------------------------------------

			-- Set tooltip scale when tooltip is shown
			SettingsTooltip:HookScript("OnShow", function()
				SettingsTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"] * UIParent:GetScale())
			end)

			---------------------------------------------------------------------------------------------------------
			-- Other tooltip code
			---------------------------------------------------------------------------------------------------------

			-- Colorblind setting change
			TipDrag:RegisterEvent("CVAR_UPDATE");
			TipDrag:SetScript("OnEvent", function(self, event, arg1, arg2)
				if (arg1 == "USE_COLORBLIND_MODE") then
					LT["ColorBlind"] = arg2;
				end
			end)

			-- Store locals
			local TipMClass = LOCALIZED_CLASS_NAMES_MALE
			local TipFClass = LOCALIZED_CLASS_NAMES_FEMALE

			-- Level string
			local LevelString, LevelString2
			if GameLocale == "ruRU" then
				-- Level string for ruRU
				LevelString = "уровня"
				LevelString2 = "уровень"
			else
				-- Level string for all other locales
				LevelString = string.lower(TOOLTIP_UNIT_LEVEL:gsub("%%s",".+"))
				LevelString2 = ""
			end

			-- Tag locale (code construction from tiplang)
			local ttYou, ttLevel, ttBoss, ttElite, ttRare, ttRareElite, ttRareBoss, ttTarget
			if 		GameLocale == "zhCN" then 	ttYou = "您"		; ttLevel = "等级"		; ttBoss = "首领"	; ttElite = "精英"	; ttRare = "精良"	; ttRareElite = "精良 精英"		; ttRareBoss = "精良 首领"		; ttTarget = "目标"
			elseif 	GameLocale == "zhTW" then 	ttYou = "您"		; ttLevel = "等級"		; ttBoss = "首領"	; ttElite = "精英"	; ttRare = "精良"	; ttRareElite = "精良 精英"		; ttRareBoss = "精良 首領"		; ttTarget = "目標"
			elseif 	GameLocale == "ruRU" then 	ttYou = "ВЫ"	; ttLevel = "Уровень"	; ttBoss = "босс"	; ttElite = "элита"	; ttRare = "Редкое"	; ttRareElite = "Редкое элита"	; ttRareBoss = "Редкое босс"	; ttTarget = "Цель"
			elseif 	GameLocale == "koKR" then 	ttYou = "당신"	; ttLevel = "레벨"		; ttBoss = "우두머리"	; ttElite = "정예"	; ttRare = "희귀"	; ttRareElite = "희귀 정예"		; ttRareBoss = "희귀 우두머리"		; ttTarget = "대상"
			elseif 	GameLocale == "esMX" then 	ttYou = "TÚ"	; ttLevel = "Nivel"		; ttBoss = "Jefe"	; ttElite = "Élite"	; ttRare = "Raro"	; ttRareElite = "Raro Élite"	; ttRareBoss = "Raro Jefe"		; ttTarget = "Objetivo"
			elseif 	GameLocale == "ptBR" then 	ttYou = "VOCÊ"	; ttLevel = "Nível"		; ttBoss = "Chefe"	; ttElite = "Elite"	; ttRare = "Raro"	; ttRareElite = "Raro Elite"	; ttRareBoss = "Raro Chefe"		; ttTarget = "Alvo"
			elseif 	GameLocale == "deDE" then 	ttYou = "SIE"	; ttLevel = "Stufe"		; ttBoss = "Boss"	; ttElite = "Elite"	; ttRare = "Selten"	; ttRareElite = "Selten Elite"	; ttRareBoss = "Selten Boss"	; ttTarget = "Ziel"
			elseif 	GameLocale == "esES" then	ttYou = "TÚ"	; ttLevel = "Nivel"		; ttBoss = "Jefe"	; ttElite = "Élite"	; ttRare = "Raro"	; ttRareElite = "Raro Élite"	; ttRareBoss = "Raro Jefe"		; ttTarget = "Objetivo"
			elseif 	GameLocale == "frFR" then 	ttYou = "TOI"	; ttLevel = "Niveau"	; ttBoss = "Boss"	; ttElite = "Élite"	; ttRare = "Rare"	; ttRareElite = "Rare Élite"	; ttRareBoss = "Rare Boss"		; ttTarget = "Cible"
			elseif 	GameLocale == "itIT" then 	ttYou = "TU"	; ttLevel = "Livello"	; ttBoss = "Boss"	; ttElite = "Élite"	; ttRare = "Raro"	; ttRareElite = "Raro Élite"	; ttRareBoss = "Raro Boss"		; ttTarget = "Bersaglio"
			else 								ttYou = "YOU"	; ttLevel = "Level"		; ttBoss = "Boss"	; ttElite = "Elite"	; ttRare = "Rare"	; ttRareElite = "Rare Elite"	; ttRareBoss = "Rare Boss"		; ttTarget = "Target"
			end

			-- Show tooltip
			local function ShowTip()

				-- Do nothing if CTRL, SHIFT and ALT are being held
				if IsControlKeyDown() and IsAltKeyDown() and IsShiftKeyDown() then
					return
				end

				-- Get unit information
				if WorldFrame:IsMouseMotionFocus() then
					LT["Unit"] = "mouseover"
					-- Hide and quit if tips should be hidden during combat
					if LeaPlusLC["TipHideInCombat"] == "On" and UnitAffectingCombat("player") then
						if not IsShiftKeyDown() or LeaPlusLC["TipHideShiftOverride"] == "Off" then
							GameTooltip:Hide()
							return
						end
					end
				else
					LT["Unit"] = select(2, GameTooltip:GetUnit())
					if not (LT["Unit"]) then return end
				end

				-- Quit if unit has no reaction to player
				LT["Reaction"] = UnitReaction(LT["Unit"], "player") or nil
				if not LT["Reaction"] then
					return
				end

				-- Setup variables
				LT["TipUnitName"], LT["TipUnitRealm"] = UnitName(LT["Unit"])
				LT["TipIsPlayer"] = UnitIsPlayer(LT["Unit"])
				LT["UnitLevel"] = UnitLevel(LT["Unit"])
				LT["UnitClass"] = UnitClassBase(LT["Unit"])
				LT["PlayerControl"] = UnitPlayerControlled(LT["Unit"])
				LT["PlayerRace"] = UnitRace(LT["Unit"])

				-- Get colorblind information
				if LT["TipIsPlayer"] then
					if LT["ColorBlind"] == "1" then
						LT["InfoLine"] = 3
					else
						LT["InfoLine"] = 2
					end
					local unitGuild, unitRank = GetGuildInfo(LT["Unit"])
					if unitGuild and unitRank then
						LT["InfoLine"] = LT["InfoLine"] + 1
					end
					-- Lower information line if unit is charmed
					if UnitIsCharmed(LT["Unit"]) then
						LT["InfoLine"] = LT["InfoLine"] + 1
					end
				end

				-- Determine class color
				if LT["UnitClass"] then
					-- Define male or female (for certain locales)
					LT["Sex"] = UnitSex(LT["Unit"])
					if LT["Sex"] == 2 then
						LT["Class"] = TipMClass[LT["UnitClass"]]
					else
						LT["Class"] = TipFClass[LT["UnitClass"]]
					end
					-- Define class color
					LT["ClassCol"] = LeaPlusLC["RaidColors"][LT["UnitClass"]]
					LT["LpTipClassColor"] = "|cff" .. string.format("%02x%02x%02x", LT["ClassCol"].r * 255, LT["ClassCol"].g * 255, LT["ClassCol"].b * 255)
				end

				----------------------------------------------------------------------
				-- Name line
				----------------------------------------------------------------------

				if ((LT["TipIsPlayer"]) or (LT["PlayerControl"])) or LT["Reaction"] > 4 then

					-- If it's a player show name in class color
					if LT["TipIsPlayer"] then
						LT["NameColor"] = LT["LpTipClassColor"]
					else
						-- If not, set to green or blue depending on PvP status
						if UnitIsPVP(LT["Unit"]) then
							LT["NameColor"] = "|cff00ff00"
						else
							LT["NameColor"] = "|cff00aaff"
						end
					end

					-- Show name
					LT["NameText"] = UnitPVPName(LT["Unit"]) or LT["TipUnitName"]

					-- Show realm
					if LT["TipUnitRealm"] then
						LT["NameText"] = LT["NameText"] .. " - " .. LT["TipUnitRealm"]
					end

					-- Show dead units in grey
					if UnitIsDeadOrGhost(LT["Unit"]) then
						LT["NameColor"] = "|c88888888"
					end

					-- Show name line
					_G["GameTooltipTextLeft1"]:SetText(LT["NameColor"] .. LT["NameText"] .. "|cffffffff|r")

				elseif UnitIsDeadOrGhost(LT["Unit"]) then

					-- Show grey name for other dead units
					_G["GameTooltipTextLeft1"]:SetText("|c88888888" .. (_G["GameTooltipTextLeft1"]:GetText() or "") .. "|cffffffff|r")
					return

				end

				----------------------------------------------------------------------
				-- Information line (level, class, race)
				----------------------------------------------------------------------

				if LT["TipIsPlayer"] then

					if GameLocale == "ruRU" then

						LT["InfoText"] = ""

						-- Show race
						if LT["PlayerRace"] then
							LT["InfoText"] = LT["InfoText"] .. LT["PlayerRace"] .. ","
						end

						-- Show class
						LT["InfoText"] = LT["InfoText"] .. " " .. LT["LpTipClassColor"] .. LT["Class"] .. "|r " or LT["InfoText"] .. "|r "

						-- Show level
						if LT["Reaction"] < 5 then
							if LT["UnitLevel"] == -1 then
								LT["InfoText"] = LT["InfoText"] .. ("|cffff3333" .. "??-ro" .. " " .. ttLevel .. "|cffffffff")
							else
								LT["LevelColor"] = GetCreatureDifficultyColor(LT["UnitLevel"])
								LT["LevelColor"] = string.format('%02x%02x%02x', LT["LevelColor"].r * 255, LT["LevelColor"].g * 255, LT["LevelColor"].b * 255)
								LT["InfoText"] = LT["InfoText"] .. ("|cff" .. LT["LevelColor"] .. LT["UnitLevel"] .. LT["LevelLocale"] .. "|cffffffff")
							end
						else
							LT["InfoText"] = LT["InfoText"] .. LT["UnitLevel"] .. LT["LevelLocale"]
						end

						-- Show information line
						_G["GameTooltipTextLeft" .. LT["InfoLine"]]:SetText(LT["InfoText"] .. "|cffffffff|r")

					else

						-- Show level
						if LT["Reaction"] < 5 then
							if LT["UnitLevel"] == -1 then
								LT["InfoText"] = ("|cffff3333" .. ttLevel .. " ??|cffffffff")
							else
								LT["LevelColor"] = GetCreatureDifficultyColor(LT["UnitLevel"])
								LT["LevelColor"] = string.format('%02x%02x%02x', LT["LevelColor"].r * 255, LT["LevelColor"].g * 255, LT["LevelColor"].b * 255)
								LT["InfoText"] = ("|cff" .. LT["LevelColor"] .. LT["LevelLocale"] .. " " .. LT["UnitLevel"] .. "|cffffffff")
							end
						else
							LT["InfoText"] = LT["LevelLocale"] .. " " .. LT["UnitLevel"]
						end

						-- Show race
						if LT["PlayerRace"] then
							LT["InfoText"] = LT["InfoText"] .. " " .. LT["PlayerRace"]
						end

						-- Show class
						LT["InfoText"] = LT["InfoText"] .. " " .. LT["LpTipClassColor"] .. LT["Class"] or LT["InfoText"]

						-- Show information line
						_G["GameTooltipTextLeft" .. LT["InfoLine"]]:SetText(LT["InfoText"] .. "|cffffffff|r")

					end

				end

				----------------------------------------------------------------------
				-- Mob name in brighter red (alive) and steel blue (tap denied)
				----------------------------------------------------------------------

				if not (LT["TipIsPlayer"]) and LT["Reaction"] < 4 and not (LT["PlayerControl"]) then
					if UnitIsTapDenied(LT["Unit"]) then
						LT["NameText"] = "|c8888bbbb" .. LT["TipUnitName"] .. "|r"
					else
						LT["NameText"] = "|cffff3333" .. LT["TipUnitName"] .. "|r"
					end
					_G["GameTooltipTextLeft1"]:SetText(LT["NameText"])
				end

				----------------------------------------------------------------------
				-- Mob level in color (neutral or lower)
				----------------------------------------------------------------------

				if UnitCanAttack(LT["Unit"], "player") and not (LT["TipIsPlayer"]) and LT["Reaction"] < 5 and not (LT["PlayerControl"]) then

					-- Find the level line
					LT["MobInfoLine"] = 0
					local line2, line3, line4
					if _G["GameTooltipTextLeft2"] then line2 = _G["GameTooltipTextLeft2"]:GetText() end
					if _G["GameTooltipTextLeft3"] then line3 = _G["GameTooltipTextLeft3"]:GetText() end
					if _G["GameTooltipTextLeft4"] then line4 = _G["GameTooltipTextLeft4"]:GetText() end
					if GameLocale == "ruRU" then -- Additional check for ruRU
						if line2 and string.lower(line2):find(LevelString2) then LT["MobInfoLine"] = 2 end
						if line3 and string.lower(line3):find(LevelString2) then LT["MobInfoLine"] = 3 end
						if line4 and string.lower(line4):find(LevelString2) then LT["MobInfoLine"] = 4 end
					end
					if line2 and string.lower(line2):find(LevelString) then LT["MobInfoLine"] = 2 end
					if line3 and string.lower(line3):find(LevelString) then LT["MobInfoLine"] = 3 end
					if line4 and string.lower(line4):find(LevelString) then LT["MobInfoLine"] = 4 end

					-- Show level line
					if LT["MobInfoLine"] > 1 then

						if GameLocale == "ruRU" then

							LT["InfoText"] = ""

							-- Show creature type and classification
							LT["CreatureType"] = UnitCreatureType(LT["Unit"])
							if (LT["CreatureType"]) and not (LT["CreatureType"] == "Not specified") then
								LT["InfoText"] = LT["InfoText"] .. "|cffffffff" .. LT["CreatureType"] .. "|cffffffff "
							end

							-- Level ?? mob
							if LT["UnitLevel"] == -1 then
								LT["InfoText"] = LT["InfoText"] .. "|cffff3333" .. "??-ro " .. ttLevel .. "|cffffffff "

							-- Mobs within level range
							else
								LT["MobColor"] = GetCreatureDifficultyColor(LT["UnitLevel"])
								LT["MobColor"] = string.format('%02x%02x%02x', LT["MobColor"].r * 255, LT["MobColor"].g * 255, LT["MobColor"].b * 255)
								LT["InfoText"] = LT["InfoText"] .. "|cff" .. LT["MobColor"] .. LT["UnitLevel"] .. LT["LevelLocale"] .. "|cffffffff "
							end

						else

							-- Level ?? mob
							if LT["UnitLevel"] == -1 then
								LT["InfoText"] = "|cffff3333" .. ttLevel .. " ??|cffffffff "

							-- Mobs within level range
							else
								LT["MobColor"] = GetCreatureDifficultyColor(LT["UnitLevel"])
								LT["MobColor"] = string.format('%02x%02x%02x', LT["MobColor"].r * 255, LT["MobColor"].g * 255, LT["MobColor"].b * 255)
								LT["InfoText"] = "|cff" .. LT["MobColor"] .. LT["LevelLocale"] .. " " .. LT["UnitLevel"] .. "|cffffffff "
							end

							-- Show creature type and classification
							LT["CreatureType"] = UnitCreatureType(LT["Unit"])
							if (LT["CreatureType"]) and not (LT["CreatureType"] == "Not specified") then
								LT["InfoText"] = LT["InfoText"] .. "|cffffffff" .. LT["CreatureType"] .. "|cffffffff "
							end

						end

						-- Rare, elite and boss mobs
						LT["Special"] = UnitClassification(LT["Unit"])
						if LT["Special"] then
							if LT["Special"] == "elite" then
								if strfind(_G["GameTooltipTextLeft" .. LT["MobInfoLine"]]:GetText(), "(" .. ttBoss .. ")") then
									LT["Special"] = "(" .. ttBoss .. ")"
								else
									LT["Special"] = "(" .. ttElite .. ")"
								end
							elseif LT["Special"] == "rare" then
								LT["Special"] = "|c00e066ff(" .. ttRare .. ")"
							elseif LT["Special"] == "rareelite" then
								if strfind(_G["GameTooltipTextLeft" .. LT["MobInfoLine"]]:GetText(), "(" .. ttBoss .. ")") then
									LT["Special"] = "|c00e066ff(" .. ttRareBoss .. ")"
								else
									LT["Special"] = "|c00e066ff(" .. ttRareElite .. ")"
								end
							elseif LT["Special"] == "worldboss" then
								LT["Special"] = "(" .. ttBoss .. ")"
							elseif LT["UnitLevel"] == -1 and LT["Special"] == "normal" and strfind(_G["GameTooltipTextLeft" .. LT["MobInfoLine"]]:GetText(), "(" .. ttBoss .. ")") then
								LT["Special"] = "(" .. ttBoss .. ")"
							else
								LT["Special"] = nil
							end

							if (LT["Special"]) then
								LT["InfoText"] = LT["InfoText"] .. LT["Special"]
							end
						end

						-- Show mob info line
						_G["GameTooltipTextLeft" .. LT["MobInfoLine"]]:SetText(LT["InfoText"])

					end

				end

				----------------------------------------------------------------------
				-- Show guild
				----------------------------------------------------------------------

				if LT["TipIsPlayer"] then
					local unitGuild, unitRank = GetGuildInfo(LT["Unit"])
					if unitGuild and unitRank then
						if UnitIsInMyGuild(LT["Unit"]) then
							if LeaPlusLC["TipShowRank"] == "On" then
								_G["GameTooltipTextLeft2"]:SetText("|c00aaaaff" .. unitGuild .. " - " .. unitRank .. "|r")
							else
								_G["GameTooltipTextLeft2"]:SetText("|c00aaaaff" .. unitGuild .. "|cffffffff|r")
							end
						else
							if LeaPlusLC["TipShowOtherRank"] == "On" then
								_G["GameTooltipTextLeft2"]:SetText("|c00aaaaff" .. unitGuild .. " - " .. unitRank .. "|r")
							else
								_G["GameTooltipTextLeft2"]:SetText("|c00aaaaff" .. unitGuild .. "|cffffffff|r")
							end
						end
					end
				end

				----------------------------------------------------------------------
				--	Show target
				----------------------------------------------------------------------

				if LeaPlusLC["TipShowTarget"] == "On" then

					-- Get target
					LT["Target"] = UnitName(LT["Unit"] .. "target");

					-- If target doesn't exist, quit
					if LT["Target"] == nil or LT["Target"] == "" then return end

					-- If target is you, set target to YOU
					if (UnitIsUnit(LT["Target"], "player")) then
						LT["Target"] = ("|c12ff4400" .. ttYou)

					-- If it's not you, but it's a player, show target in class color
					elseif UnitIsPlayer(LT["Unit"] .. "target") then
						LT["TargetBase"] = UnitClassBase(LT["Unit"] .. "target")
						LT["TargetCol"] = LeaPlusLC["RaidColors"][LT["TargetBase"]]
						LT["TargetCol"] = "|cff" .. string.format('%02x%02x%02x', LT["TargetCol"].r * 255, LT["TargetCol"].g * 255, LT["TargetCol"].b * 255)
						LT["Target"] = (LT["TargetCol"] .. LT["Target"])

					end

					-- Add target line
					GameTooltip:AddLine(ttTarget .. ": " .. LT["Target"])

				end

			end

			GameTooltip:HookScript("OnTooltipSetUnit", ShowTip)

		end

		----------------------------------------------------------------------
		--	Move chat editbox to top
		----------------------------------------------------------------------

		if LeaPlusLC["MoveChatEditBoxToTop"] == "On" then

			-- Set options for normal chat frames
			for i = 1, 50 do
				if _G["ChatFrame" .. i] then
					-- Position the editbox
					_G["ChatFrame" .. i .. "EditBox"]:ClearAllPoints()
					_G["ChatFrame" .. i .. "EditBox"]:SetPoint("TOP", _G["ChatFrame" .. i], "TOP", 0, 0)
					_G["ChatFrame" .. i .. "EditBox"]:SetPoint("LEFT", _G["ChatFrame" .. i], "LEFT", 0, 0)
					_G["ChatFrame" .. i .. "EditBox"]:SetPoint("RIGHT", _G["ChatFrame" .. i], "RIGHT", 0, 0)
				end
			end

			-- Do the functions above for other chat frames (pet battles, whispers, etc)
			hooksecurefunc("FCF_OpenTemporaryWindow", function()
				local cf = FCF_GetCurrentChatFrame():GetName() or nil
				if cf then
					-- Position the editbox
					_G[cf .. "EditBox"]:ClearAllPoints()
					_G[cf .. "EditBox"]:SetPoint("TOP", cf, "TOP", 0, 0)
					_G[cf .. "EditBox"]:SetPoint("LEFT", cf, "LEFT", 0, 0)
					_G[cf .. "EditBox"]:SetPoint("RIGHT", cf, "RIGHT", 0, 0)
				end
			end)

		end

		----------------------------------------------------------------------
		-- Show borders
		----------------------------------------------------------------------

		if LeaPlusLC["ShowBorders"] == "On" then

			-- Create border textures
			local BordTop = WorldFrame:CreateTexture(nil, "ARTWORK"); BordTop:SetColorTexture(0, 0, 0, 1); BordTop:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0); BordTop:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, 0)
			local BordBot = WorldFrame:CreateTexture(nil, "ARTWORK"); BordBot:SetColorTexture(0, 0, 0, 1); BordBot:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0); BordBot:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)
			local BordLeft = WorldFrame:CreateTexture(nil, "ARTWORK"); BordLeft:SetColorTexture(0, 0, 0, 1); BordLeft:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0); BordLeft:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)
			local BordRight = WorldFrame:CreateTexture(nil, "ARTWORK"); BordRight:SetColorTexture(0, 0, 0, 1); BordRight:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, 0); BordRight:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)

			-- Create border configuration panel
			local bordersPanel = LeaPlusLC:CreatePanel("Show borders", "bordersPanel")

			-- Function to set border parameters
			local function RefreshBorders()

				-- Set border size and transparency
				BordTop:SetHeight(LeaPlusLC["BordersTop"]); BordTop:SetAlpha(1 - LeaPlusLC["BordersAlpha"])
				BordBot:SetHeight(LeaPlusLC["BordersBottom"]); BordBot:SetAlpha(1 - LeaPlusLC["BordersAlpha"])
				BordLeft:SetWidth(LeaPlusLC["BordersLeft"]); BordLeft:SetAlpha(1 - LeaPlusLC["BordersAlpha"])
				BordRight:SetWidth(LeaPlusLC["BordersRight"]); BordRight:SetAlpha(1 - LeaPlusLC["BordersAlpha"])

				-- Show formatted slider value
				LeaPlusCB["BordersAlpha"].f:SetFormattedText("%.0f%%", LeaPlusLC["BordersAlpha"] * 100)

			end

			-- Create slider controls
			LeaPlusLC:MakeTx(bordersPanel, "Top", 16, -72)
			LeaPlusLC:MakeSL(bordersPanel, "BordersTop", "Drag to set the size of the top border.", 0, 300, 5, 16, -92, "%.0f")
			LeaPlusCB["BordersTop"]:HookScript("OnValueChanged", RefreshBorders)

			LeaPlusLC:MakeTx(bordersPanel, "Bottom", 16, -132)
			LeaPlusLC:MakeSL(bordersPanel, "BordersBottom", "Drag to set the size of the bottom border.", 0, 300, 5, 16, -152, "%.0f")
			LeaPlusCB["BordersBottom"]:HookScript("OnValueChanged", RefreshBorders)

			LeaPlusLC:MakeTx(bordersPanel, "Left", 186, -72)
			LeaPlusLC:MakeSL(bordersPanel, "BordersLeft", "Drag to set the size of the left border.", 0, 300, 5, 186, -92, "%.0f")
			LeaPlusCB["BordersLeft"]:HookScript("OnValueChanged", RefreshBorders)

			LeaPlusLC:MakeTx(bordersPanel, "Right", 186, -132)
			LeaPlusLC:MakeSL(bordersPanel, "BordersRight", "Drag to set the size of the right border.", 0, 300, 5, 186, -152, "%.0f")
			LeaPlusCB["BordersRight"]:HookScript("OnValueChanged", RefreshBorders)

			LeaPlusLC:MakeTx(bordersPanel, "Transparency", 356, -132)
			LeaPlusLC:MakeSL(bordersPanel, "BordersAlpha", "Drag to set the transparency of the borders.", 0, 0.9, 0.1, 356, -152, "%.1f")
			LeaPlusCB["BordersAlpha"]:HookScript("OnValueChanged", RefreshBorders)

			-- Help button hidden
			bordersPanel.h:Hide()

			-- Back button handler
			bordersPanel.b:SetScript("OnClick", function()
				bordersPanel:Hide()
				LeaPlusLC["PageF"]:Show()
				LeaPlusLC["Page5"]:Show()
				return
			end)

			-- Reset button handler
			bordersPanel.r:SetScript("OnClick", function()
				LeaPlusLC["BordersTop"] = 0
				LeaPlusLC["BordersBottom"] = 0
				LeaPlusLC["BordersLeft"] = 0
				LeaPlusLC["BordersRight"] = 0
				LeaPlusLC["BordersAlpha"] = 0
				bordersPanel:Hide(); bordersPanel:Show()
				RefreshBorders()
			end)

			-- Configuration button handler
			LeaPlusCB["ModBordersBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					LeaPlusLC["BordersTop"] = 0
					LeaPlusLC["BordersBottom"] = 0
					LeaPlusLC["BordersLeft"] = 0
					LeaPlusLC["BordersRight"] = 0
					LeaPlusLC["BordersAlpha"] = 0.7
					RefreshBorders()
				else
					bordersPanel:Show()
					LeaPlusLC:HideFrames()
				end
			end)

			-- Set borders on startup
			RefreshBorders()

			-- Hide borders when cinematic is shown
			hooksecurefunc(CinematicFrame, "Hide", function()
				BordTop:Show(); BordBot:Show(); BordLeft:Show(); BordRight:Show()
			end)
			hooksecurefunc(CinematicFrame, "Show", function()
				BordTop:Hide(); BordBot:Hide(); BordLeft:Hide(); BordRight:Hide()
			end)

		end

		----------------------------------------------------------------------
		-- Silence rested emotes
		----------------------------------------------------------------------

		-- Manage emotes
		if LeaPlusLC["NoRestedEmotes"] == "On" then

			-- Zone table 		English					, French					, German					, Italian						, Russian					, S Chinese	, Spanish					, T Chinese	,
			local zonetable = {	"The Grim Guzzler"		, "Le Sinistre écluseur"	, "Zum Grimmigen Säufer"	, "Torvo Beone"					, "Трактир Угрюмый обжора"	, "黑铁酒吧"	, "Tragapenas"				, "黑鐵酒吧"	,}

			-- Function to set rested state
			local function UpdateEmoteSound()

				-- Find character's current zone
				local szone = GetSubZoneText() or "None"

				-- Find out if emote sounds are disabled or enabled
				local emoset = GetCVar("Sound_EnableEmoteSounds")

				if IsResting() then
					-- Character is resting so silence emotes
					if emoset ~= "0" then
						SetCVar("Sound_EnableEmoteSounds", "0")
					end
					return
				end

				-- Traverse zone table and silence emotes if character is in a designated zone
				for k, v in next, zonetable do
					if szone == zonetable[k] then
						if emoset ~= "0" then
							SetCVar("Sound_EnableEmoteSounds", "0")
						end
						return
					end
				end

				-- If the above didn't return, emote sounds should be enabled
				if emoset ~= "1" then
					SetCVar("Sound_EnableEmoteSounds", "1")
				end
				return

			end

			-- Set emote sound when rest state or zone changes
			local RestEvent = CreateFrame("FRAME")
			RestEvent:RegisterEvent("PLAYER_UPDATE_RESTING")
            RestEvent:RegisterEvent("ZONE_CHANGED_NEW_AREA")
			RestEvent:RegisterEvent("ZONE_CHANGED")
			RestEvent:RegisterEvent("ZONE_CHANGED_INDOORS")
			RestEvent:SetScript("OnEvent", UpdateEmoteSound)

			-- Set sound setting at startup
			UpdateEmoteSound()

		end

		----------------------------------------------------------------------
		--	Max camera zoom (no reload required)
		----------------------------------------------------------------------

		do

			-- Create event frame
			local frame = CreateFrame("FRAME")

			-- Function to set camera zoom
			local function SetZoom()
				if LeaPlusLC["MaxCameraZoom"] == "On" then
					SetCVar("cameraDistanceMaxZoomFactor", 4.0)
					frame:RegisterEvent("PLAYER_ENTERING_WORLD")
				else
					SetCVar("cameraDistanceMaxZoomFactor", 1.9)
					frame:UnregisterEvent("PLAYER_ENTERING_WORLD")
				end
			end

			frame:SetScript("OnEvent", SetZoom)

			-- Set camera zoom when option is clicked and on startup (if enabled)
			LeaPlusCB["MaxCameraZoom"]:HookScript("OnClick", SetZoom)
			if LeaPlusLC["MaxCameraZoom"] == "On" then SetZoom() end

		end

		----------------------------------------------------------------------
		-- L45: Create panel in game options panel
		----------------------------------------------------------------------

		do

			local interPanel = CreateFrame("FRAME")
			interPanel.name = "Leatrix Plus"

			local maintitle = LeaPlusLC:MakeTx(interPanel, "Leatrix Plus", 0, 0)
			maintitle:SetFont(maintitle:GetFont(), 72)
			maintitle:ClearAllPoints()
			maintitle:SetPoint("TOP", 0, -72)

			local expTitle = LeaPlusLC:MakeTx(interPanel, L["Burning Crusade Anniversary"], 0, 0)
			expTitle:SetFont(expTitle:GetFont(), 32)
			expTitle:ClearAllPoints()
			expTitle:SetPoint("TOP", 0, -152)

			local subTitle = LeaPlusLC:MakeTx(interPanel, "curseforge.com/wow/addons/leatrix-plus", 0, 0)
			subTitle:SetFont(subTitle:GetFont(), 20)
			subTitle:ClearAllPoints()
			subTitle:SetPoint("BOTTOM", 0, 72)

			local slashTitle = LeaPlusLC:MakeTx(interPanel, "/ltp", 0, 0)
			slashTitle:SetFont(slashTitle:GetFont(), 72)
			slashTitle:ClearAllPoints()
			slashTitle:SetPoint("BOTTOM", subTitle, "TOP", 0, 40)
			slashTitle:SetScript("OnMouseUp", function(self, button)
				if button == "LeftButton" then
					SlashCmdList["Leatrix_Plus"]("")
				end
			end)
			slashTitle:SetScript("OnEnter", function()
				slashTitle.r,  slashTitle.g, slashTitle.b = slashTitle:GetTextColor()
				slashTitle:SetTextColor(1, 1, 0)
			end)
			slashTitle:SetScript("OnLeave", function()
				slashTitle:SetTextColor(slashTitle.r, slashTitle.g, slashTitle.b)
			end)

			local pTex = interPanel:CreateTexture(nil, "BACKGROUND")
			pTex:SetAllPoints()
			pTex:SetTexture("Interface\\GLUES\\Models\\UI_MainMenu\\swordgradient2")
			pTex:SetAlpha(0.2)
			pTex:SetTexCoord(0, 1, 1, 0)

			local category = Settings.RegisterCanvasLayoutCategory(interPanel, L["Leatrix Plus"])
			Settings.RegisterAddOnCategory(category)

		end

		----------------------------------------------------------------------
		-- Frame alignment grid
		----------------------------------------------------------------------

		do

			-- Create frame alignment grid
			local grid = CreateFrame('FRAME')
			LeaPlusLC.grid = grid
			grid:Hide()
			grid:SetAllPoints(UIParent)
			local w, h = GetScreenWidth() * UIParent:GetEffectiveScale(), GetScreenHeight() * UIParent:GetEffectiveScale()
			local ratio = w / h
			local sqsize = w / 20
			local wline = floor(sqsize - (sqsize % 2))
			local hline = floor(sqsize / ratio - ((sqsize / ratio) % 2))
			-- Plot vertical lines
			for i = 0, wline do
				local t = LeaPlusLC.grid:CreateTexture(nil, 'BACKGROUND')
				if i == wline / 2 then t:SetColorTexture(1, 0, 0, 0.5) else t:SetColorTexture(0, 0, 0, 0.5) end
				t:SetPoint('TOPLEFT', grid, 'TOPLEFT', i * w / wline - 1, 0)
				t:SetPoint('BOTTOMRIGHT', grid, 'BOTTOMLEFT', i * w / wline + 1, 0)
			end
			-- Plot horizontal lines
			for i = 0, hline do
				local t = LeaPlusLC.grid:CreateTexture(nil, 'BACKGROUND')
				if i == hline / 2 then	t:SetColorTexture(1, 0, 0, 0.5) else t:SetColorTexture(0, 0, 0, 0.5) end
				t:SetPoint('TOPLEFT', grid, 'TOPLEFT', 0, -i * h / hline + 1)
				t:SetPoint('BOTTOMRIGHT', grid, 'TOPRIGHT', 0, -i * h / hline - 1)
			end

		end

		----------------------------------------------------------------------
		-- Media player
		----------------------------------------------------------------------

		function LeaPlusLC:MediaFunc()

			-- Create tables for list data and zone listing
			local ListData, playlist = {}, {}
			local scrollFrame, willPlay, musicHandle, ZonePage, LastPlayed, LastFolder, TempFolder, HeadingOfClickedTrack, LastMusicHandle
			local numButtons = math.floor((LeaPlusLC.MainPanelHeight - 110) / 16) - 1
			local uframe = CreateFrame("FRAME")

			-- These categories will not appear in random track selections
			local randomBannedList = {L["Narration"], L["Cinematics"]}

			-- Remove the duplicate number some tracks have after the file ID (path#fileid#2 becomes path#fileid)
			local function StripDup(track)
				return (track:gsub("^(.-#%d+)#%d+$", "%1"))
			end

			-- Get media table
			local ZoneList = Leatrix_Plus["ZoneList"]

			-- Show relevant list items
			local function UpdateList()
				local offset = max(0, floor(scrollFrame:GetVerticalScroll() + 0.5))
				for i, button in ipairs(scrollFrame.buttons) do
					local index = offset + i
					if index <= #ListData then
						-- Show zone listing or track listing (store the full list entry on the button)
						button.item = ListData[index]
						local label = ListData[index].zone or ListData[index]
						-- Hide the duplicate number some tracks have after the file ID (path#fileid#2 shows as path#fileid)
						if type(ListData[index]) == "string" then label = StripDup(label) end
						button:SetText(label)
						-- Set width of highlight texture
						if button:GetTextWidth() > 290 then
							button.t:SetSize(290, 16)
						else
							button.t:SetSize(button:GetTextWidth(), 16)
						end
						-- Show the button
						button:Show()
						-- Hide highlight bar texture by default
						button.s:Hide()
						-- Hide highlight bar if the button is a heading
						if strfind(button:GetText(), "|c") then button.t:Hide() end
						-- Show last played track highlight bar texture
						if LastPlayed == button.item then
							local HeadingOfCurrentFolder = ListData[1]
							if HeadingOfCurrentFolder == HeadingOfClickedTrack then
								button.s:Show()
							end
						end
						-- Show last played folder highlight bar texture
						if LastFolder == button:GetText() then
							button.s:Show()
						end
						-- Set width of highlight bar
						if button:GetTextWidth() > 290 then
							button.s:SetSize(290, 16)
						else
							button.s:SetSize(button:GetTextWidth(), 16)
						end
						-- Limit click to label width
						local bWidth = button:GetFontString():GetStringWidth() or 0
						if bWidth > 290 then bWidth = 290 end
						button:SetHitRectInsets(0, 454 - bWidth, 0, 0)
						-- Disable label click movement
						button:SetPushedTextOffset(0, 0)
						-- Disable word wrap and set width
						button:GetFontString():SetWidth(290)
						button:GetFontString():SetWordWrap(false)
					else
						button:Hide()
					end
				end

				local bRoll = ((36 + (LeaPlusLC.MainPanelHeight - 370)) / 16) + 16
				scrollFrame.child:SetSize(200, #ListData + (math.floor(bRoll * 15)))

			end

			-- Give function file level scope (it's used in SetPlusScale to set the highlight bar scale)
			LeaPlusLC.UpdateList = UpdateList

			-- Right-button click to go back
			local function BackClick()
				-- Return to the current zone list (back button)
				if type(ListData[1]) == "string" then
					-- Strip the color code from the list data
					local nocol = string.gsub(ListData[1], "|cffffd800", "")
					-- Strip the zone
					local backzone = strsplit(":", nocol, 2)
					-- Don't go back if random or search category is being shown
					if backzone == L["Random"] or backzone == L["Search"] then return end
					-- Show the tracklist continent
					if ZoneList[backzone] then ListData = ZoneList[backzone] end
					UpdateList()
					scrollFrame:SetVerticalScroll(ZonePage or 0)
				end
			end

			-- Function to make navigation menu buttons
			local function MakeButton(where, y)
				local mbtn = CreateFrame("Button", nil, LeaPlusLC["Page9"])
				mbtn:Show()
				mbtn:SetAlpha(1.0)
				mbtn:SetPoint("TOPLEFT", 146, y)

				-- Create hover texture
				mbtn.t = mbtn:CreateTexture(nil, "BACKGROUND")
				mbtn.t:SetColorTexture(0.3, 0.3, 0.00, 0.8)
				mbtn.t:SetAlpha(0.7)
				mbtn.t:SetAllPoints()
				mbtn.t:Hide()

				-- Create highlight texture
				mbtn.s = mbtn:CreateTexture(nil, "BACKGROUND")
				mbtn.s:SetColorTexture(0.3, 0.3, 0.00, 0.8)
				mbtn.s:SetAlpha(1.0)
				mbtn.s:SetAllPoints()
				mbtn.s:Hide()

				-- Create fontstring
				mbtn.f = mbtn:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
				mbtn.f:SetPoint('LEFT', 1, 0)
				mbtn.f:SetText(L[where])

				mbtn:SetScript("OnEnter", function()
					mbtn.t:Show()
				end)

				mbtn:SetScript("OnLeave", function()
					mbtn.t:Hide()
				end)

				-- Set button size when shown
				mbtn:SetScript("OnShow", function()
					mbtn:SetSize(mbtn.f:GetStringWidth() + 1, 16)
				end)

				mbtn:SetScript("OnClick", function()
					-- Show zone listing for clicked item
					ListData = ZoneList[where]
					UpdateList()
				end)

				return mbtn, mbtn.s

			end

			-- Create a table for each button
			local conbtn = {}
			for q, w in pairs(ZoneList) do
				conbtn[q] = {}
			end

			-- Create buttons
			local function MakeButtonNow(title, anchor)
				conbtn[title], conbtn[title].s = MakeButton(title, height)
				conbtn[title]:ClearAllPoints()
				if title == L["Zones"] then
					-- Set first button position
					conbtn[title]:SetPoint("TOPLEFT", LeaPlusLC["Page9"], "TOPLEFT", 145, -70)
				elseif anchor then
					-- Set subsequent button positions
					conbtn[title]:SetPoint("TOPLEFT", conbtn[anchor], "BOTTOMLEFT", 0, 0)
					conbtn[title].f:SetText(L[title])
				end
			end

			MakeButtonNow(L["Zones"])
			MakeButtonNow(L["Dungeons"], L["Zones"])
			MakeButtonNow(L["Various"], L["Dungeons"])
			MakeButtonNow(L["Movies"], L["Various"])
			MakeButtonNow(L["Random"], L["Movies"])
			MakeButtonNow(L["Search"]) -- Positioned when search editbox is created

			-- Show button highlight for clicked button
			for q, w in pairs(ZoneList) do
				if type(w) == "string" and conbtn[w] then
					conbtn[w]:HookScript("OnClick", function()
						-- Hide all button highlights
						for k, v in pairs(ZoneList) do
							if type(v) == "string" and conbtn[v] then
								conbtn[v].s:Hide()
							end
						end
						-- Show clicked button highlight
						conbtn[w].s:Show()
						LeaPlusDB["MusicContinent"] = w
						scrollFrame:SetVerticalScroll(0)
						-- Set TempFolder for listings without folders
						if w == L["Random"] then TempFolder = L["Random"] end
						if w == L["Search"] then TempFolder = L["Search"] end
					end)
				end
			end

			-- Create scroll bar
			scrollFrame = CreateFrame("ScrollFrame", nil, LeaPlusLC["Page9"], "LeaPlusConfigurationPanelScrollFrameTemplate")
			scrollFrame:SetPoint("TOPLEFT", 0, -32)
			scrollFrame:SetPoint("BOTTOMRIGHT", -30, 50)
			scrollFrame:SetPanExtent(1)
			scrollFrame:SetScript("OnVerticalScroll", UpdateList)

			-- Create the scroll child
			scrollFrame.child = CreateFrame("Frame", nil, scrollFrame)
			scrollFrame:SetScrollChild(scrollFrame.child)

			-- Add stop button
			local stopBtn = LeaPlusLC:CreateButton("StopMusicBtn", LeaPlusLC["Page9"], "Stop", "BOTTOMLEFT", 146, 53, 0, 25, true, "")
			stopBtn:Hide(); stopBtn:Show()
			LeaPlusLC:LockItem(stopBtn, true)
			stopBtn:SetScript("OnClick", function()
				-- Unregister loading screen event and cancel the track monitor first so stopping doesn't start the next track
				uframe:UnregisterEvent("LOADING_SCREEN_DISABLED")
				if LeaPlusLC.TrackTimer then LeaPlusLC.TrackTimer:Cancel() end
				LastMusicHandle = nil
				if musicHandle then
					StopSound(musicHandle)
					musicHandle = nil
					-- Hide highlight bars
					LastPlayed = ""
					LastFolder = ""
					UpdateList()
				end
				-- Lock button
				LeaPlusLC:LockItem(stopBtn, true)
			end)

			-- Store currently playing track number
			local tracknumber = 1

			-- Count tracks in a row that failed to start (stops the player looping forever if nothing can play)
			local failedTracks = 0

			-- Forward declaration so the track monitor can move on to the next track
			local PlayTrack

			-- Function to play the next track in the playlist
			local function PlayNextTrack()
				-- Playlist is at the end (last entry repeats the first track), restart from first track
				if tracknumber >= #playlist then tracknumber = 1 end
				PlayTrack()
			end

			-- Function to play a track and show the static highlight bar
			function PlayTrack()
				if not playlist[tracknumber] then return end
				-- Stop the previous track and its monitor (clear the handle first so stopping it doesn't trigger the next track)
				if LeaPlusLC.TrackTimer then LeaPlusLC.TrackTimer:Cancel() end
				local oldHandle = musicHandle
				musicHandle, LastMusicHandle = nil, nil
				if oldHandle then StopSound(oldHandle) end
				-- Play music file (entries are path#filedataid)
				local file, soundID = playlist[tracknumber]:match("^(.-)#(%d+)")
				willPlay, musicHandle = PlaySoundFile(tonumber(soundID) or soundID, "Master")
				if willPlay and musicHandle then
					-- Watch the track and play the next one when it stops playing
					failedTracks = 0
					local thisHandle, ticker = musicHandle
					ticker = C_Timer.NewTicker(1, function()
						-- Another track has started since this one so stop watching
						if musicHandle ~= thisHandle then ticker:Cancel() return end
						if not C_Sound.IsPlaying(thisHandle) then
							-- Track has finished
							ticker:Cancel()
							PlayNextTrack()
						end
					end)
					LeaPlusLC.TrackTimer = ticker
				else
					-- Track could not be played so try the next one (give up after a full pass of the playlist)
					failedTracks = failedTracks + 1
					if failedTracks < #playlist then
						LeaPlusLC.TrackTimer = C_Timer.NewTimer(1, PlayNextTrack)
					end
				end
				-- Store its handle for later use
				LastMusicHandle = musicHandle
				LastPlayed = playlist[tracknumber]
				tracknumber = tracknumber + 1
				-- Show static highlight bar
				for index = 1, numButtons do
					local button = scrollFrame.buttons[index]
					local item = button:IsShown() and button.item
					if type(item) == "string" and item:match("^(.-)#(%d+)") then
						if item == LastPlayed and LastFolder == TempFolder then
							button.s:Show()
						else
							button.s:Hide()
						end
					end
				end
			end

			-- Create editbox for search
			local sBox = LeaPlusLC:CreateEditBox("MusicSearchBox", LeaPlusLC["Page9"], 78, 10, "TOPLEFT", 150, -(LeaPlusLC.MainPanelHeight - 110), "MusicSearchBox", "MusicSearchBox")
			sBox:SetMaxLetters(50)

			-- Position search button above editbox
			conbtn[L["Search"]]:ClearAllPoints()
			conbtn[L["Search"]]:SetPoint("BOTTOMLEFT", sBox, "TOPLEFT", -4, 0)

			-- Set initial search data
			for q, w in pairs(ZoneList) do
				if conbtn[w] then
					conbtn[w]:HookScript("OnClick", function()
						if w == L["Search"] then
							ListData[1] = "|cffffd800" .. L["Search"]
							if #ListData == 1 then
								ListData[2] = "|cffffffaa{" .. L["enter zone or track name"] .. "}"
							end
							UpdateList()
						else
							sBox:ClearFocus()
						end
					end)
				end
			end

			-- Function to show search results
			local function ShowSearchResults()
				-- Get search words (lower case and matched as plain text, so pattern characters don't need escaping)
				local searchText = strtrim(strlower(sBox:GetText() or ""))
				-- Wipe the track listing
				wipe(ListData)
				-- Set the track list heading
				ListData[1] = "|cffffd800" .. L["Search"]
				-- Show the subheading only if no search results are being shown
				if searchText == "" then
					ListData[2] = "|cffffffaa{" .. L["enter zone or track name"] .. "}"
				else
					ListData[2] = ""
					-- Up to five search words
					local words = {}
					for word in searchText:gmatch("%S+") do
						if #words < 5 then words[#words + 1] = word end
					end
					-- Traverse music listing and populate ListData
					local hash = {}
					local trackCount = 0
					for i, e in ipairs(ZoneList) do
						local entries = ZoneList[e]
						if entries then
							for a, b in ipairs(entries) do
								if type(b) == "table" and b.tracks then
									-- Lower the zone and category once per entry (not once per track and word)
									local zoneLower, categoryLower = strlower(b.zone), strlower(b.category)
									-- Words found in the zone or category match every track in it, so only the rest are checked per track
									local trackWords = {}
									for w = 1, #words do
										if not strfind(zoneLower, words[w], 1, true) and not strfind(categoryLower, words[w], 1, true) then
											trackWords[#trackWords + 1] = words[w]
										end
									end
									for k, v in ipairs(b.tracks) do
										if strfind(v, "#", 1, true) or strfind(v, "|r", 1, true) then
											local match = true
											if #trackWords > 0 then
												local vLower = strlower(v)
												for w = 1, #trackWords do
													if not strfind(vLower, trackWords[w], 1, true) then match = false break end
												end
											end
											if match then
												-- Show category
												if not hash[b.category] then
													tinsert(ListData, "|cffffffff")
													if b.category == e then
														-- No category so just show ZoneList entry (such as Various)
														tinsert(ListData, "|cffffd800" .. e)
													else
														-- Category exists so show that
														tinsert(ListData, "|cffffd800" .. e .. ": " .. b.category)
													end
													hash[b.category] = true
												end
												-- Show track (only once if it appears more than once in the same entry)
												local dupKey = "|Cffffffaa" .. b.zone .. " |r" .. StripDup(v)
												if not hash[dupKey] then
													tinsert(ListData, "|Cffffffaa" .. b.zone .. " |r" .. v)
													trackCount = trackCount + 1
													hash[dupKey] = true
												end
											end
										end
									end
								end
							end
						end
					end

					-- Set results tag
					if trackCount == 1 then
						ListData[2] = "|cffffffaa{" .. trackCount .. " " .. L["result"] .. "}"
					else
						ListData[2] = "|cffffffaa{" .. trackCount .. " " .. L["results"] .. "}"
					end
				end
				-- Refresh the track listing
				UpdateList()
				-- Set track listing to top
				scrollFrame:SetVerticalScroll(0)
			end

			-- Search runs once typing pauses (not on every key press)
			local searchTimer
			local function SearchSoon()
				if searchTimer then searchTimer:Cancel() end
				searchTimer = C_Timer.NewTimer(0.25, function()
					searchTimer = nil
					ShowSearchResults()
				end)
			end

			-- Populate ListData when editbox is changed by user
			sBox:HookScript("OnTextChanged", function(self, userInput)
				if userInput then
					-- Show search page
					conbtn[L["Search"]]:Click()
					-- If search results are currently playing, stop playback since search results will be changed
					if LastFolder == L["Search"] then stopBtn:Click() end
					-- Show search results when typing pauses
					SearchSoon()
				end
			end)

			-- Populate ListData when editbox enter key is pressed
			sBox:HookScript("OnEnterPressed", function()
				-- Cancel any waiting search and search now
				if searchTimer then searchTimer:Cancel(); searchTimer = nil end
				-- Show search page
				conbtn[L["Search"]]:Click()
				-- If search results are currently playing, stop playback since search results will be changed
				if LastFolder == L["Search"] then stopBtn:Click() end
				-- Show search results
				ShowSearchResults()
			end)

			-- Function to show random track listing
			local function ShowRandomList()
				-- If random track is currently playing, stop playback since random track list will be changed
				if LastFolder == L["Random"] then
					stopBtn:Click()
				end
				-- Wipe the track listing for random
				wipe(ListData)
				-- Set the track list heading
				ListData[1] = "|cffffd800" .. L["Random"]
				ListData[2] = "|Cffffffaa{" .. L["click here for new selection"] .. "}" -- Must be capital |C
				ListData[3] = "|cffffd800"
				ListData[4] = "|cffffd800" .. L["Selection of music tracks"] -- Must be lower case |c
				-- Populate list data until it contains desired number of tracks
				while #ListData < 50 do
					-- Get random category
					local rCategory = GetRandomArgument(L["Zones"], L["Dungeons"], L["Various"])
					-- Get random zone within category
					local rZone = random(1, #ZoneList[rCategory])
					-- Get random track within zone
					local rTrack = ZoneList[rCategory][rZone].tracks[random(1, #ZoneList[rCategory][rZone].tracks)]
					-- Insert track into ListData if it's not a duplicate or on the banned list
					-- Check the track isn't already listed (ignoring any duplicate number)
					local alreadyListed = false
					if rTrack and rTrack ~= "" and strfind(rTrack, "#") then
						local rKey = "|Cffffffaa" .. ZoneList[rCategory][rZone].zone .. " |r" .. StripDup(rTrack)
						for n = 5, #ListData do
							if StripDup(ListData[n]) == rKey then alreadyListed = true break end
						end
					end
					if rTrack and rTrack ~= "" and strfind(rTrack, "#") and not alreadyListed then
						if not tContains(randomBannedList, L[ZoneList[rCategory][rZone].zone]) and not tContains(randomBannedList, rTrack) then
							tinsert(ListData, "|Cffffffaa" .. ZoneList[rCategory][rZone].zone .. " |r" .. rTrack)
						end
					end
				end
				-- Refresh the track listing
				UpdateList()
				-- Set track listing to top
				scrollFrame:SetVerticalScroll(0)
			end

			-- Show random track listing on startup when random button is clicked
			for q, w in pairs(ZoneList) do
				if conbtn[w] then
					conbtn[w]:HookScript("OnClick", function()
						if w == L["Random"] then
							-- Generate initial playlist for first run
							if #ListData == 0 then
								ShowRandomList()
							end
						end
					end)
				end
			end

			-- Create list items
			scrollFrame.buttons = {}
			for i = 1, numButtons do
				scrollFrame.buttons[i] = CreateFrame("Button", nil, LeaPlusLC["Page9"])
				local button = scrollFrame.buttons[i]

				button:SetSize(470 - 14, 16)
				button:SetNormalFontObject("GameFontHighlightLeft")
				button:SetPoint("TOPLEFT", 246, -62+ -(i - 1) * 16 - 8)

				-- Create highlight bar texture
				button.t = button:CreateTexture(nil, "BACKGROUND")
				button.t:SetPoint("TOPLEFT", button, 0, 0)
				button.t:SetSize(516, 16)

				button.t:SetColorTexture(0.3, 0.3, 0.0, 0.8)
				button.t:SetAlpha(0.7)
				button.t:Hide()

				-- Create last playing highlight bar texture
				button.s = button:CreateTexture(nil, "BACKGROUND")
				button.s:SetPoint("TOPLEFT", button, 0, 0)
				button.s:SetSize(516, 16)

				button.s:SetColorTexture(0.3, 0.4, 0.00, 0.6)
				button.s:Hide()

				button:SetScript("OnEnter", function()
					-- Highlight links only
					if not string.match(button:GetText() or "", "|c") then
						button.t:Show()
					end
				end)

				button:SetScript("OnLeave", function()
					button.t:Hide()
				end)

				button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

				-- Handler for restarting the player after a loading screen (track endings are watched in PlayTrack)
				uframe:SetScript("OnEvent", function(self, event)
					if event == "LOADING_SCREEN_DISABLED" then
						-- Restart player if it stopped between tracks during loading screen
						if playlist and tracknumber and playlist[tracknumber] and not willPlay and not musicHandle then
							tracknumber = tracknumber - 1
							C_Timer.After(0.1, PlayTrack)
						end
					end
				end)

				-- Click handler for track, zone and back button
				button:SetScript("OnClick", function(self, btn)
					if btn == "LeftButton" then
						-- Remove focus from search box
						sBox:ClearFocus()
						-- Get clicked list entry (full entry, including any hidden duplicate number)
						local item = type(self.item) == "string" and self.item or self:GetText()
						-- Do nothing if its a blank line or informational heading
						if not item or strfind(item, "|c") then return end
						if item == "|Cffffffaa{" .. L["click here for new selection"] .. "}" then -- must be capital |C
							-- Create new random track listing
							ShowRandomList()
							return
						elseif strfind(item, "#") then
							-- Enable sound if required
							if GetCVar("Sound_EnableAllSound") == "0" then SetCVar("Sound_EnableAllSound", "1") end
							-- Disable music if it's currently enabled
							if GetCVar("Sound_EnableMusic") == "1" then	SetCVar("Sound_EnableMusic", "0") end
							-- Add all tracks to playlist
							wipe(playlist)
							local StartItem = 0
							-- Get item clicked row number
							for index = 1, #ListData do
								if ListData[index] == item then StartItem = index end
							end
							-- Add all items from clicked item onwards to playlist
							for index = StartItem, #ListData do
								local item = ListData[index]
								if item then
									if strfind(item, "#") then
										tinsert(playlist, item)
									end
								end
							end
							-- Add all items up to clicked item to playlist
							for index = 1, StartItem do
								local item = ListData[index]
								if item then
									if strfind(item, "#") then
										tinsert(playlist, item)
									end
								end
							end
							-- Enable the stop button
							LeaPlusLC:LockItem(stopBtn, false)
							-- Set Temp Folder to Random if track is in Random
							if ListData[1] == "|cffffd800" .. L["Random"] then TempFolder = L["Random"] end
							-- Set Temp Folder to Search if track is in Search
							if ListData[1] == "|cffffd800" .. L["Search"] then TempFolder = L["Search"] end
							-- Store information about the track we are about to play
							tracknumber = 1
							LastPlayed = item
							LastFolder = TempFolder
							HeadingOfClickedTrack = ListData[1]
							-- Play first track
							PlayTrack()
							-- Restart the player if a loading screen stops it between tracks
							uframe:RegisterEvent("LOADING_SCREEN_DISABLED")
							return
						elseif strfind(item, "|r") then
							-- A movie was clicked
							local movieName, movieID = item:match("([^,]+)%|r([^,]+)")
							movieID = strtrim(movieID, "()")
							if IsMoviePlayable(movieID) then
								stopBtn:Click()
								MovieFrame_PlayMovie(MovieFrame, movieID)
							else
								LeaPlusLC:Print("Movie not playable.")
							end
							return
						else
							-- A zone was clicked so show track listing
							ZonePage = scrollFrame:GetVerticalScroll()
							-- Find the track listing for the clicked zone
							for q, w in pairs(ZoneList) do
								for k, v in pairs(ZoneList[w]) do
									if item == v.zone then
										-- Show track listing
										TempFolder = item
										LeaPlusDB["MusicZone"] = item
										ListData = v.tracks
										UpdateList()
										-- Hide hover highlight if track under pointer is a heading
										if strfind(scrollFrame.buttons[i]:GetText(), "|c") then
											scrollFrame.buttons[i].t:Hide()
										end
										-- Show top of track list
										scrollFrame:SetVerticalScroll(0)
										return
									end
								end
							end
						end
					elseif btn == "RightButton" then
						-- Back button was clicked
						BackClick()
					end
				end)

			end

			-- Right-click to go back (from anywhere on the main content area of the panel)
			LeaPlusLC["PageF"]:HookScript("OnMouseUp", function(self, btn)
				if LeaPlusLC["Page9"]:IsShown() and LeaPlusLC["Page9"]:IsMouseOver(0, 0, 0, -440) == false and LeaPlusLC["Page9"]:IsMouseOver(-(LeaPlusLC.MainPanelHeight - 47), 0, 0, 0) == false then
					if btn == "RightButton" then
						BackClick()
					end
				end
			end)

			-- Delete the global scroll frame pointer
			_G.LeaPlusScrollFrame = nil

			-- Set zone listing on startup
			if LeaPlusDB["MusicContinent"] and LeaPlusDB["MusicContinent"] ~= "" then
				-- Saved music continent exists
				if conbtn[LeaPlusDB["MusicContinent"]] then
					-- Saved continent is valid button so click it
					conbtn[LeaPlusDB["MusicContinent"]]:Click()
				else
					-- Saved continent is not valid button so click default button
					conbtn[L["Zones"]]:Click()
				end
			else
				-- Saved music continent does not exist so click default button
				conbtn[L["Zones"]]:Click()
			end
			UpdateList()

			-- Manage events
			LeaPlusLC["Page9"]:RegisterEvent("PLAYER_LOGOUT")
			LeaPlusLC["Page9"]:RegisterEvent("UI_SCALE_CHANGED")
			LeaPlusLC["Page9"]:SetScript("OnEvent", function(self, event)
				if event == "PLAYER_LOGOUT" then
					-- Stop playing at reload or logout
					if musicHandle then
						StopSound(musicHandle)
					end
				elseif event == "UI_SCALE_CHANGED" then
					-- Refresh list
					UpdateList()
				end
			end)

		end

		-- Run on startup
		LeaPlusLC:MediaFunc()

		-- Release memory
		LeaPlusLC.MediaFunc = nil

		----------------------------------------------------------------------
		-- Panel alpha
		----------------------------------------------------------------------

		do

			-- Function to set panel alpha
			local function SetPlusAlpha()
				-- Set panel alpha
				LeaPlusLC["PageF"].t:SetAlpha(1 - LeaPlusLC["PlusPanelAlpha"])
				-- Show formatted value
				LeaPlusCB["PlusPanelAlpha"].f:SetFormattedText("%.0f%%", LeaPlusLC["PlusPanelAlpha"] * 100)
			end

			-- Set alpha on startup
			SetPlusAlpha()

			-- Set alpha after changing slider
			LeaPlusCB["PlusPanelAlpha"]:HookScript("OnValueChanged", SetPlusAlpha)

		end

		----------------------------------------------------------------------
		-- Panel scale
		----------------------------------------------------------------------

		do

			-- Function to set panel scale
			local function SetPlusScale()
				-- Reset panel position
				LeaPlusLC["MainPanelA"], LeaPlusLC["MainPanelR"], LeaPlusLC["MainPanelX"], LeaPlusLC["MainPanelY"] = "CENTER", "CENTER", 0, 0
				if LeaPlusLC["PageF"]:IsShown() then
					LeaPlusLC["PageF"]:Hide()
					LeaPlusLC["PageF"]:Show()
				end
				-- Set panel scale
				LeaPlusLC["PageF"]:SetScale(LeaPlusLC["PlusPanelScale"])
				-- Update music player highlight bar scale
				LeaPlusLC:UpdateList()
			end

			-- Set scale on startup
			LeaPlusLC["PageF"]:SetScale(LeaPlusLC["PlusPanelScale"])

			-- Set scale and reset panel position after changing slider
			LeaPlusCB["PlusPanelScale"]:HookScript("OnMouseUp", SetPlusScale)
			LeaPlusCB["PlusPanelScale"]:HookScript("OnMouseWheel", SetPlusScale)

			-- Show formatted slider value
			LeaPlusCB["PlusPanelScale"]:HookScript("OnValueChanged", function()
				LeaPlusCB["PlusPanelScale"].f:SetFormattedText("%.0f%%", LeaPlusLC["PlusPanelScale"] * 100)
			end)

		end

		----------------------------------------------------------------------
		-- Final code for Player
		----------------------------------------------------------------------

		-- Show first run message
		if not LeaPlusDB["FirstRunMessageSeen"] then
			C_Timer.After(1, function()
				LeaPlusLC:Print(L["Enter"] .. " |cff00ff00" .. "/ltp" .. "|r " .. L["or click the minimap button to open Leatrix Plus."])
				LeaPlusDB["FirstRunMessageSeen"] = true
			end)
		end

		-- Register logout event to save settings
		LpEvt:RegisterEvent("PLAYER_LOGOUT")

		-- Update addon memory usage (speeds up initial value)
		UpdateAddOnMemoryUsage()

		-- Release memory
		LeaPlusLC.Player = nil

	end

----------------------------------------------------------------------
-- 	L60: Default events
----------------------------------------------------------------------

	local function eventHandler(self, event, arg1, arg2, ...)

		----------------------------------------------------------------------
		-- L62: Profile events
		----------------------------------------------------------------------

		if event == "ADDON_LOADED" then
			if arg1 == "Leatrix_Plus" then

				-- Replace old var names with new ones
				local function UpdateVars(oldvar, newvar)
					if LeaPlusDB[oldvar] and not LeaPlusDB[newvar] then LeaPlusDB[newvar] = LeaPlusDB[oldvar]; LeaPlusDB[oldvar] = nil end
				end

				UpdateVars("MoreFontSizes", "MoreChatFontSizes") -- 18/10/2026

				-- Automation
				LeaPlusLC:LoadVarChk("AutomateQuests", "Off")				-- Automate quests
				LeaPlusLC:LoadVarChk("AutoQuestShift", "Off")				-- Automate quests requires shift
				LeaPlusLC:LoadVarChk("AutoQuestAvailable", "On")			-- Accept available quests
				LeaPlusLC:LoadVarChk("AutoQuestCompleted", "On")			-- Turn-in completed quests
				LeaPlusLC:LoadVarNum("AutoQuestKeyMenu", 1, 1, 4)			-- Automate quests override key
				LeaPlusLC:LoadVarChk("AutomateGossip", "Off")				-- Automate gossip
				LeaPlusLC:LoadVarChk("AutoAcceptSummon", "Off")				-- Accept summon
				LeaPlusLC:LoadVarChk("AutoAcceptRes", "Off")				-- Accept resurrection
				LeaPlusLC:LoadVarChk("AutoResNoCombat", "On")				-- Accept resurrection exclude combat
				LeaPlusLC:LoadVarChk("AutoReleasePvP", "Off")				-- Release in PvP
				LeaPlusLC:LoadVarChk("AutoReleaseNoAlterac", "Off")			-- Release in PvP Exclude Alterac Valley
				LeaPlusLC:LoadVarNum("AutoReleaseDelay", 200, 200, 3000)	-- Release in PvP Delay

				LeaPlusLC:LoadVarChk("AutoSellJunk", "Off")					-- Sell junk automatically
				LeaPlusLC:LoadVarChk("AutoSellShowSummary", "On")			-- Sell junk summary in chat
				LeaPlusLC:LoadVarStr("AutoSellExcludeList", "")				-- Sell junk exclude list
				LeaPlusLC:LoadVarChk("AutoRepairGear", "Off")				-- Repair automatically
				LeaPlusLC:LoadVarChk("AutoRepairShowSummary", "On")			-- Repair show summary in chat

				-- Social
				LeaPlusLC:LoadVarChk("NoDuelRequests", "Off")				-- Block duels
				LeaPlusLC:LoadVarChk("NoPartyInvites", "Off")				-- Block party invites
				LeaPlusLC:LoadVarChk("NoFriendRequests", "Off")				-- Block friend requests
				LeaPlusLC:LoadVarChk("NoSharedQuests", "Off")				-- Block shared quests

				LeaPlusLC:LoadVarChk("AcceptPartyFriends", "Off")			-- Party from friends
				LeaPlusLC:LoadVarChk("InviteFromWhisper", "Off")			-- Invite from whispers
				LeaPlusLC:LoadVarChk("InviteFriendsOnly", "Off")			-- Restrict invites to friends
				LeaPlusLC["InvKey"]	= LeaPlusDB["InvKey"] or "inv"			-- Invite from whisper keyword
				LeaPlusLC:LoadVarChk("FriendlyGuild", "On")					-- Friendly guild

				-- Chat
				LeaPlusLC:LoadVarChk("UseEasyChatResizing", "Off")			-- Use easy resizing
				LeaPlusLC:LoadVarChk("NoCombatLogTab", "Off")				-- Hide the combat log
				LeaPlusLC:LoadVarChk("NoChatButtons", "Off")				-- Hide chat buttons
				LeaPlusLC:LoadVarChk("UnclampChat", "Off")					-- Unclamp chat frame
				LeaPlusLC:LoadVarChk("MoveChatEditBoxToTop", "Off")			-- Move editbox to top
				LeaPlusLC:LoadVarChk("MoreChatFontSizes", "Off")			-- More chat font sizes

				LeaPlusLC:LoadVarChk("NoStickyChat", "Off")					-- Disable sticky chat
				LeaPlusLC:LoadVarChk("UseArrowKeysInChat", "Off")			-- Use arrow keys in chat
				LeaPlusLC:LoadVarChk("NoChatFade", "Off")					-- Disable chat fade
				LeaPlusLC:LoadVarChk("UnivGroupColor", "Off")				-- Universal group color
				LeaPlusLC:LoadVarChk("ClassColorsInChat", "Off")			-- Use class colors in chat
				LeaPlusLC:LoadVarChk("RecentChatWindow", "Off")				-- Recent chat window
				LeaPlusLC:LoadVarNum("RecentChatSize", 170, 170, 600)		-- Recent chat size
				LeaPlusLC:LoadVarChk("MaxChatHstory", "Off")				-- Increase chat history
				LeaPlusLC:LoadVarChk("FilterChatMessages", "Off")			-- Filter chat messages
				LeaPlusLC:LoadVarChk("BlockSpellLinks", "Off")				-- Block spell links
				LeaPlusLC:LoadVarChk("BlockDrunkenSpam", "Off")				-- Block drunken spam
				LeaPlusLC:LoadVarChk("BlockDuelSpam", "Off")				-- Block duel spam
				LeaPlusLC:LoadVarChk("RestoreChatMessages", "Off")			-- Restore chat messages

				-- Text
				LeaPlusLC:LoadVarChk("HideErrorMessages", "Off")			-- Hide error messages
				LeaPlusLC:LoadVarChk("NoHitIndicators", "Off")				-- Hide portrait text
				LeaPlusLC:LoadVarChk("HideZoneText", "Off")					-- Hide zone text
				LeaPlusLC:LoadVarChk("HideKeybindText", "Off")				-- Hide keybind text
				LeaPlusLC:LoadVarChk("HideMacroText", "Off")				-- Hide macro text
				LeaPlusLC:LoadVarChk("HideRaidGroupLabels", "Off")			-- Hide raid group labels

				LeaPlusLC:LoadVarChk("MailFontChange", "Off")				-- Resize mail text
				LeaPlusLC:LoadVarNum("LeaPlusMailFontSize", 15, 10, 30)		-- Mail text slider

				LeaPlusLC:LoadVarChk("QuestFontChange", "Off")				-- Resize quest text
				LeaPlusLC:LoadVarNum("LeaPlusQuestFontSize", 12, 10, 30)	-- Quest text slider

				LeaPlusLC:LoadVarChk("BookFontChange", "Off")				-- Resize book text
				LeaPlusLC:LoadVarNum("LeaPlusBookFontSize", 15, 10, 30)		-- Book text slider

				-- Interface
				LeaPlusLC:LoadVarChk("MinimapModder", "Off")				-- Enhance minimap
				LeaPlusLC:LoadVarChk("SquareMinimap", "Off")				-- Square minimap
				LeaPlusLC:LoadVarChk("MinimapButtonBag", "Off")				-- Minimap button bag
				LeaPlusLC:LoadVarStr("MiniExcludeList", "")					-- Minimap exclude list
				LeaPlusLC:LoadVarChk("HideMiniZoomBtns", "Off")				-- Hide zoom buttons
				LeaPlusLC:LoadVarChk("HideMiniClock", "Off")				-- Hide the clock
				LeaPlusLC:LoadVarChk("HideMiniDayNight", "Off")				-- Hide the day and night indicator
				LeaPlusLC:LoadVarChk("HideMiniZoneText", "Off")				-- Hide the zone text bar
				LeaPlusLC:LoadVarChk("HideMiniAddonButtons", "On")			-- Hide addon buttons
				LeaPlusLC:LoadVarChk("HideMiniTracking", "Off")				-- Hide the tracking button
				LeaPlusLC:LoadVarChk("HideMiniLFG", "Off")					-- Hide the Looking for Group button
				LeaPlusLC:LoadVarNum("MinimapSize", 140, 140, 560)			-- Minimap size slider
				LeaPlusLC:LoadVarNum("MinimapBorderWidth", 3, 1, 10)		-- Minimap border width
				LeaPlusLC:LoadVarNum("MinimapEffect", 1, 1, 33)				-- Minimap effect

				LeaPlusLC:LoadVarChk("TipModEnable", "Off")					-- Enhance tooltip
				LeaPlusLC:LoadVarChk("TipShowRank", "On")					-- Show guild rank for your own guild
				LeaPlusLC:LoadVarChk("TipShowOtherRank", "Off")				-- Show guild rank for other guilds
				LeaPlusLC:LoadVarChk("TipShowTarget", "On")					-- Show target
				LeaPlusLC:LoadVarChk("TipHideInCombat", "Off")				-- Hide tooltips during combat
				LeaPlusLC:LoadVarChk("TipHideShiftOverride", "On")			-- Hide tooltips shift override
				LeaPlusLC:LoadVarChk("TipNoHealthBar", "Off")				-- Hide health bar
				LeaPlusLC:LoadVarNum("LeaPlusTipSize", 1.00, 0.50, 2.00)	-- Tooltip scale slider
				LeaPlusLC:LoadVarNum("TipOffsetX", -13, -5000, 5000)		-- Tooltip X offset
				LeaPlusLC:LoadVarNum("TipOffsetY", 94, -5000, 5000)			-- Tooltip Y offset
				LeaPlusLC:LoadVarNum("TooltipAnchorMenu", 1, 1, 5)			-- Tooltip anchor menu
				LeaPlusLC:LoadVarNum("TipCursorX", 0, -128, 128)			-- Tooltip cursor X offset
				LeaPlusLC:LoadVarNum("TipCursorY", 0, -128, 128)			-- Tooltip cursor Y offset

				LeaPlusLC:LoadVarChk("EnhanceDressup", "Off")				-- Enhance dressup
				LeaPlusLC:LoadVarChk("DressupItemButtons", "On")			-- Dressup item buttons
				LeaPlusLC:LoadVarChk("DressupAnimControl", "On")			-- Dressup animation control
				LeaPlusLC:LoadVarChk("HideDressupStats", "Off")				-- Hide dressup stats
				LeaPlusLC:LoadVarChk("EnhanceQuestLog", "Off")				-- Enhance quest log
				LeaPlusLC:LoadVarChk("EnhanceQuestTaller", "On")			-- Enhance quest log taller
				LeaPlusLC:LoadVarChk("EnhanceQuestLevels", "On")			-- Enhance quest log quest levels
				LeaPlusLC:LoadVarChk("EnhanceQuestDifficulty", "On")		-- Enhance quest log quest difficulty
				LeaPlusLC:LoadVarChk("EnhanceProfessions", "Off")			-- Enhance professions
				LeaPlusLC:LoadVarChk("EnhanceTrainers", "Off")				-- Enhance trainers
				LeaPlusLC:LoadVarChk("ShowTrainAllBtn", "On")				-- Enhance trainers train all button
				LeaPlusLC:LoadVarChk("EnhanceFlightMap", "Off")				-- Enhance flight map
				LeaPlusLC:LoadVarNum("LeaPlusTaxiMapScale", 1.9, 1, 3)		-- Enhance flight map scale
				LeaPlusLC:LoadVarNum("LeaPlusTaxiIconSize", 10, 5, 30)		-- Enhance flight icon size
				LeaPlusLC:LoadVarAnc("FlightMapA", "TOPLEFT")				-- Enhance flight map anchor
				LeaPlusLC:LoadVarAnc("FlightMapR", "TOPLEFT")				-- Enhance flight map relative
				LeaPlusLC:LoadVarNum("FlightMapX", 0, -5000, 5000)			-- Enhance flight map X
				LeaPlusLC:LoadVarNum("FlightMapY", 61, -5000, 5000)			-- Enhance flight map Y

				LeaPlusLC:LoadVarChk("ShowVolume", "Off")					-- Show volume slider
				LeaPlusLC:LoadVarChk("AhExtras", "Off")						-- Show auction controls
				LeaPlusLC:LoadVarChk("AhBuyoutOnly", "Off")					-- Auction buyout only
				LeaPlusLC:LoadVarChk("AhGoldOnly", "Off")					-- Auction gold only

				LeaPlusLC:LoadVarChk("ShowCooldowns", "Off")				-- Show cooldowns
				LeaPlusLC:LoadVarChk("ShowCooldownID", "On")				-- Show cooldown ID in tips
				LeaPlusLC:LoadVarChk("NoCooldownDuration", "On")			-- Hide cooldown duration
				LeaPlusLC:LoadVarChk("CooldownsOnPlayer", "Off")			-- Anchor to player
				LeaPlusLC:LoadVarChk("DurabilityStatus", "Off")				-- Show durability status
				LeaPlusLC:LoadVarChk("ShowVanityControls", "Off")			-- Show vanity controls
				LeaPlusLC:LoadVarChk("VanityAltLayout", "Off")				-- Vanity alternative layout
				LeaPlusLC:LoadVarChk("ShowBagSearchBox", "Off")				-- Show bag search box
				LeaPlusLC:LoadVarChk("ShowFreeBagSlots", "Off")				-- Show free bag slots
				LeaPlusLC:LoadVarChk("ShowRaidToggle", "Off")				-- Show raid button
				LeaPlusLC:LoadVarChk("ShowBorders", "Off")					-- Show borders
				LeaPlusLC:LoadVarNum("BordersTop", 0, 0, 300)				-- Top border
				LeaPlusLC:LoadVarNum("BordersBottom", 0, 0, 300)			-- Bottom border
				LeaPlusLC:LoadVarNum("BordersLeft", 0, 0, 300)				-- Left border
				LeaPlusLC:LoadVarNum("BordersRight", 0, 0, 300)				-- Right border
				LeaPlusLC:LoadVarNum("BordersAlpha", 0, 0, 0.9)				-- Border alpha
				LeaPlusLC:LoadVarChk("ShowPlayerChain", "Off")				-- Show player chain
				LeaPlusLC:LoadVarChk("ShowReadyTimer", "Off")				-- Show ready timer
				LeaPlusLC:LoadVarNum("PlayerChainMenu", 2, 1, 3)			-- Player chain dropdown value
				LeaPlusLC:LoadVarChk("ShowDruidPowerBar", "Off")			-- Show druid power bar
				LeaPlusLC:LoadVarChk("ShowDruidStatusText", "On")			-- Show druid power bar status text
				LeaPlusLC:LoadVarChk("ShowRangeColoring", "Off")			-- Show range coloring
				LeaPlusLC:LoadVarChk("ShowInfoCards", "Off")				-- Show info cards
				LeaPlusLC:LoadVarStr("InfoCardKey", "")						-- Info card key
				LeaPlusLC:LoadVarChk("ShowWowheadLinks", "Off")				-- Show Wowhead links
				LeaPlusLC:LoadVarChk("WowheadLinkComments", "Off")			-- Show Wowhead links to comments

				-- Frames
				LeaPlusLC:LoadVarChk("ManageWidget", "Off")					-- Manage widget
				LeaPlusLC:LoadVarAnc("WidgetA", "TOP")						-- Manage widget anchor
				LeaPlusLC:LoadVarAnc("WidgetR", "TOP")						-- Manage widget relative
				LeaPlusLC:LoadVarNum("WidgetX", 0, -5000, 5000)				-- Manage widget position X
				LeaPlusLC:LoadVarNum("WidgetY", -15, -5000, 5000)			-- Manage widget position Y
				LeaPlusLC:LoadVarNum("WidgetScale", 1, 0.5, 2)				-- Manage widget scale

				LeaPlusLC:LoadVarChk("ManageTimer", "Off")					-- Manage timer
				LeaPlusLC:LoadVarAnc("TimerA", "TOP")						-- Manage timer anchor
				LeaPlusLC:LoadVarAnc("TimerR", "TOP")						-- Manage timer relative
				LeaPlusLC:LoadVarNum("TimerX", -5, -5000, 5000)				-- Manage timer position X
				LeaPlusLC:LoadVarNum("TimerY", -96, -5000, 5000)			-- Manage timer position Y
				LeaPlusLC:LoadVarNum("TimerScale", 1, 0.5, 2)				-- Manage timer scale

				LeaPlusLC:LoadVarChk("ClassColFrames", "Off")				-- Class colored frames
				LeaPlusLC:LoadVarChk("ClassColPlayer", "On")				-- Class colored player frame
				LeaPlusLC:LoadVarChk("ClassColTarget", "On")				-- Class colored target frame

				LeaPlusLC:LoadVarChk("NoGryphons", "Off")					-- Hide gryphons
				LeaPlusLC:LoadVarChk("NoClassBar", "Off")					-- Hide stance bar

				-- System
				LeaPlusLC:LoadVarChk("NoScreenGlow", "Off")					-- Disable screen glow
				LeaPlusLC:LoadVarChk("NoScreenEffects", "Off")				-- Disable screen effects
				LeaPlusLC:LoadVarChk("SetWeatherDensity", "Off")			-- Set weather density
				LeaPlusLC:LoadVarNum("WeatherLevel", 3, 0, 3)				-- Weather density level
				LeaPlusLC:LoadVarChk("MaxCameraZoom", "Off")				-- Max camera zoom

				LeaPlusLC:LoadVarChk("NoRestedEmotes", "Off")				-- Silence rested emotes
				LeaPlusLC:LoadVarChk("KeepAudioSynced", "Off")				-- Keep audio synced
				LeaPlusLC:LoadVarChk("MuteGameSounds", "Off")				-- Mute game sounds
				LeaPlusLC:LoadVarChk("MuteMountSounds", "Off")				-- Mute mount sounds
				LeaPlusLC:LoadVarChk("MuteCustomSounds", "Off")				-- Mute custom sounds
				LeaPlusLC:LoadVarStr("MuteCustomList", "")					-- Mute custom sounds list

				LeaPlusLC:LoadVarChk("NoBagAutomation", "Off")				-- Disable bag automation
				LeaPlusLC:LoadVarChk("NoConfirmLoot", "Off")				-- Disable loot warnings
				LeaPlusLC:LoadVarChk("FasterLooting", "Off")				-- Faster auto loot
				LeaPlusLC:LoadVarChk("FasterMovieSkip", "Off")				-- Faster movie skip
				LeaPlusLC:LoadVarChk("StandAndDismount", "Off")				-- Dismount me
				LeaPlusLC:LoadVarChk("DismountNoResource", "On")			-- Dismount on resource error
				LeaPlusLC:LoadVarChk("DismountNoMoving", "On")				-- Dismount on moving
				LeaPlusLC:LoadVarChk("DismountNoTaxi", "On")				-- Dismount on flight map open
				LeaPlusLC:LoadVarChk("DismountShowFormBtn", "On")			-- Dismount cancel form button
				LeaPlusLC:LoadVarChk("ShowVendorPrice", "Off")				-- Show vendor price
				LeaPlusLC:LoadVarChk("CombatPlates", "Off")					-- Combat plates
				LeaPlusLC:LoadVarChk("EasyItemDestroy", "Off")				-- Easy item destroy

				LeaPlusLC:LoadVarChk("ShowFlightTimes", "Off")				-- Show flight times
				LeaPlusLC:LoadVarChk("FlightBarBackground", "On")			-- Show flight times bar background
				LeaPlusLC:LoadVarChk("FlightBarDestination", "On")			-- Show flight times bar destination
				LeaPlusLC:LoadVarChk("FlightBarFillBar", "Off")				-- Show flight times bar fill mode
				LeaPlusLC:LoadVarChk("FlightBarSpeech", "Off")				-- Show flight times bar speech
				LeaPlusLC:LoadVarChk("FlightBarContribute", "On")			-- Show flight times contribute
				LeaPlusLC:LoadVarAnc("FlightBarA", "TOP")					-- Show flight times anchor
				LeaPlusLC:LoadVarAnc("FlightBarR", "TOP")					-- Show flight times relative
				LeaPlusLC:LoadVarNum("FlightBarX", 0, -5000, 5000)			-- Show flight position X
				LeaPlusLC:LoadVarNum("FlightBarY", -66, -5000, 5000)		-- Show flight position Y
				LeaPlusLC:LoadVarNum("FlightBarScale", 2, 1, 5)				-- Show flight times bar scale
				LeaPlusLC:LoadVarNum("FlightBarWidth", 230, 40, 460)		-- Show flight times bar width

				-- Settings
				LeaPlusLC:LoadVarNum("AddonLanguage", 1, 1, 12)				-- Addon language
				LeaPlusLC:LoadVarChk("ShowMinimapIcon", "On")				-- Show minimap button
				LeaPlusLC:LoadVarChk("SetEditModeLayout", "Off")			-- Set edit mode layout
				LeaPlusLC["EditModeLayoutName"]	= LeaPlusDB["EditModeLayoutName"] or ""			-- Edit mode layout name
				LeaPlusLC:LoadVarChk("SimpleAddonListing", "Off")			-- Simple addon listing

				LeaPlusLC:LoadVarNum("PlusPanelScale", 1, 1, 2)				-- Panel scale
				LeaPlusLC:LoadVarNum("PlusPanelAlpha", 0, 0, 1)				-- Panel alpha

				-- Panel position
				LeaPlusLC:LoadVarAnc("MainPanelA", "CENTER")				-- Panel anchor
				LeaPlusLC:LoadVarAnc("MainPanelR", "CENTER")				-- Panel relative
				LeaPlusLC:LoadVarNum("MainPanelX", 0, -5000, 5000)			-- Panel X axis
				LeaPlusLC:LoadVarNum("MainPanelY", 0, -5000, 5000)			-- Panel Y axis

				-- Start page
				LeaPlusLC:LoadVarNum("LeaStartPage", 0, 0, LeaPlusLC["NumberOfPages"])

				-- Lock conflicting options
				do

					-- Function to disable and lock an option and add a note to the tooltip
					local function Lock(option, reason, optmodule)
						LeaLockList[option] = LeaPlusLC[option]
						LeaPlusLC:LockItem(LeaPlusCB[option], true)
						LeaPlusCB[option].tiptext = LeaPlusCB[option].tiptext .. "|n|n|cff00AAFF" .. reason
						if optmodule then
							LeaPlusCB[option].tiptext = LeaPlusCB[option].tiptext .. " " .. optmodule .. " " .. L["module"]
						end
						LeaPlusCB[option].tiptext = LeaPlusCB[option].tiptext .. "."
						-- Remove hover from configuration button if there is one
						local temp = {LeaPlusCB[option]:GetChildren()}
						if temp and temp[1] and temp[1].t and temp[1].t:GetTexture() == "Interface\\WorldMap\\Gear_64.png" then
							temp[1]:SetHighlightTexture(0)
							temp[1]:SetScript("OnEnter", nil)
						end
					end

					-- Disable items that currently are not compatible with Burning Crusade Anniversary
					-- Lock("FilterChatMessages", L["This option is not currently available in Burning Crusade Anniversary"])

					-- Disable items that conflict with Easy Frames
					if C_AddOns.IsAddOnLoaded("EasyFrames") then
						Lock("ClassColFrames", L["Cannot be used with Easy Frames"]) -- Class colored frames
					end

					-- Disable items that conflict with Glass
					if C_AddOns.IsAddOnLoaded("Glass") then
						local reason = L["Cannot be used with Glass"]
						Lock("UseEasyChatResizing", reason) -- Use easy resizing
						Lock("NoCombatLogTab", reason) -- Hide the combat log
						Lock("NoChatButtons", reason) -- Hide chat buttons
						Lock("UnclampChat", reason) -- Unclamp chat frame
						Lock("MoveChatEditBoxToTop", reason) -- Move editbox to top
						Lock("MoreChatFontSizes", reason) -- More chat font sizes
						Lock("NoChatFade", reason) --  Disable chat fade
						Lock("ClassColorsInChat", reason) -- Use class colors in chat
						Lock("RecentChatWindow", reason) -- Recent chat window
					end

					-- Disable items that conflict with ElvUI
					if LeaPlusLC.ElvUI then
						local E = LeaPlusLC.ElvUI
						if E and E.private then

							local reason = L["Cannot be used with ElvUI"]

							-- Chat
							if E.private.chat.enable then
								Lock("UseEasyChatResizing", reason, "Chat") -- Use easy resizing
								Lock("NoCombatLogTab", reason, "Chat") -- Hide the combat log
								Lock("NoChatButtons", reason, "Chat") -- Hide chat buttons
								Lock("UnclampChat", reason, "Chat") -- Unclamp chat frame
								Lock("MoreChatFontSizes", reason, "Chat") -- More chat font sizes
								Lock("NoStickyChat", reason, "Chat") -- Disable sticky chat
								Lock("UseArrowKeysInChat", reason, "Chat") -- Use arrow keys in chat
								Lock("NoChatFade", reason, "Chat") -- Disable chat fade
								Lock("MaxChatHstory", reason, "Chat") -- Increase chat history
								Lock("RestoreChatMessages", reason, "Chat") -- Restore chat messages
							end

							-- Minimap
							if E.private.general.minimap.enable then
								Lock("MinimapModder", reason, "Minimap") -- Enhance minimap
							end

							-- UnitFrames
							if E.private.unitframe.enable then
								Lock("ShowRaidToggle", reason, "UnitFrames") -- Show raid button
								Lock("ShowDruidPowerBar", reason, "UnitFrames") -- Show druid power bar
							end

							-- ActionBars
							if E.private.actionbar.enable then
								Lock("NoGryphons", reason, "ActionBars") -- Hide gryphons
								Lock("NoClassBar", reason, "ActionBars") -- Hide stance bar
								Lock("HideKeybindText", reason, "ActionBars") -- Hide keybind text
								Lock("HideMacroText", reason, "ActionBars") -- Hide macro text
								Lock("ShowFreeBagSlots", reason, "ActionBars") -- Show free bag slots
							end

							-- Bags
							if E.private.bags.enable then
								Lock("NoBagAutomation", reason, "Bags") -- Disable bag automation
								Lock("ShowBagSearchBox", reason, "Bags") -- Show bag search box
							end

							-- Tooltip
							if E.private.tooltip.enable then
								Lock("TipModEnable", reason, "Tooltip") -- Enhance tooltip
							end

							-- UnitFrames: Disabled Blizzard: Player
							if E.private.unitframe.disabledBlizzardFrames.player then
								Lock("ShowPlayerChain", reason, "UnitFrames (Disabled Blizzard Frames Player)") -- Show player chain
								Lock("NoHitIndicators", reason, "UnitFrames (Disabled Blizzard Frames Player)") -- Hide portrait numbers
							end

							-- UnitFrames: Disabled Blizzard: Player and Target
							if E.private.unitframe.disabledBlizzardFrames.player or E.private.unitframe.disabledBlizzardFrames.target then
								Lock("ClassColFrames", reason, "UnitFrames (Disabled Blizzard Frames Player and Target)") -- Class-colored frames
							end

							-- Base
							do
								Lock("ManageWidget", reason) -- Manage widget
								Lock("ManageTimer", reason) -- Manage timer
							end

						end

						C_AddOns.EnableAddOn("Leatrix_Plus")
					end

				end

				-- Run other startup items
				LeaPlusLC:SetDim()

			end
			return
		end

		if event == "PLAYER_LOGIN" then
			LeaPlusLC:Player()
			collectgarbage()
			return
		end

		-- Save locals back to globals on logout
		if event == "PLAYER_LOGOUT" then

			-- Run the logout function without wipe flag
			LeaPlusLC:PlayerLogout(false)

			-- Automation
			LeaPlusDB["AutomateQuests"]			= LeaPlusLC["AutomateQuests"]
			LeaPlusDB["AutoQuestShift"]			= LeaPlusLC["AutoQuestShift"]
			LeaPlusDB["AutoQuestAvailable"]		= LeaPlusLC["AutoQuestAvailable"]
			LeaPlusDB["AutoQuestCompleted"]		= LeaPlusLC["AutoQuestCompleted"]
			LeaPlusDB["AutoQuestKeyMenu"]		= LeaPlusLC["AutoQuestKeyMenu"]
			LeaPlusDB["AutomateGossip"]			= LeaPlusLC["AutomateGossip"]
			LeaPlusDB["AutoAcceptSummon"] 		= LeaPlusLC["AutoAcceptSummon"]
			LeaPlusDB["AutoAcceptRes"] 			= LeaPlusLC["AutoAcceptRes"]
			LeaPlusDB["AutoResNoCombat"] 		= LeaPlusLC["AutoResNoCombat"]
			LeaPlusDB["AutoReleasePvP"] 		= LeaPlusLC["AutoReleasePvP"]
			LeaPlusDB["AutoReleaseNoAlterac"] 	= LeaPlusLC["AutoReleaseNoAlterac"]
			LeaPlusDB["AutoReleaseDelay"] 		= LeaPlusLC["AutoReleaseDelay"]

			LeaPlusDB["AutoSellJunk"] 			= LeaPlusLC["AutoSellJunk"]
			LeaPlusDB["AutoSellShowSummary"] 	= LeaPlusLC["AutoSellShowSummary"]
			LeaPlusDB["AutoSellExcludeList"] 	= LeaPlusLC["AutoSellExcludeList"]
			LeaPlusDB["AutoRepairGear"] 		= LeaPlusLC["AutoRepairGear"]
			LeaPlusDB["AutoRepairShowSummary"] 	= LeaPlusLC["AutoRepairShowSummary"]

			-- Social
			LeaPlusDB["NoDuelRequests"] 		= LeaPlusLC["NoDuelRequests"]
			LeaPlusDB["NoPartyInvites"]			= LeaPlusLC["NoPartyInvites"]
			LeaPlusDB["NoFriendRequests"]		= LeaPlusLC["NoFriendRequests"]
			LeaPlusDB["NoSharedQuests"]			= LeaPlusLC["NoSharedQuests"]

			LeaPlusDB["AcceptPartyFriends"]		= LeaPlusLC["AcceptPartyFriends"]
			LeaPlusDB["InviteFromWhisper"]		= LeaPlusLC["InviteFromWhisper"]
			LeaPlusDB["InviteFriendsOnly"]		= LeaPlusLC["InviteFriendsOnly"]
			LeaPlusDB["InvKey"]					= LeaPlusLC["InvKey"]
			LeaPlusDB["FriendlyGuild"]			= LeaPlusLC["FriendlyGuild"]

			-- Chat
			LeaPlusDB["UseEasyChatResizing"]	= LeaPlusLC["UseEasyChatResizing"]
			LeaPlusDB["NoCombatLogTab"]			= LeaPlusLC["NoCombatLogTab"]
			LeaPlusDB["NoChatButtons"]			= LeaPlusLC["NoChatButtons"]
			LeaPlusDB["UnclampChat"]			= LeaPlusLC["UnclampChat"]
			LeaPlusDB["MoveChatEditBoxToTop"]	= LeaPlusLC["MoveChatEditBoxToTop"]
			LeaPlusDB["MoreChatFontSizes"]		= LeaPlusLC["MoreChatFontSizes"]

			LeaPlusDB["NoStickyChat"] 			= LeaPlusLC["NoStickyChat"]
			LeaPlusDB["UseArrowKeysInChat"]		= LeaPlusLC["UseArrowKeysInChat"]
			LeaPlusDB["NoChatFade"]				= LeaPlusLC["NoChatFade"]
			LeaPlusDB["UnivGroupColor"]			= LeaPlusLC["UnivGroupColor"]
			LeaPlusDB["ClassColorsInChat"]		= LeaPlusLC["ClassColorsInChat"]
			LeaPlusDB["RecentChatWindow"]		= LeaPlusLC["RecentChatWindow"]
			LeaPlusDB["RecentChatSize"]			= LeaPlusLC["RecentChatSize"]
			LeaPlusDB["MaxChatHstory"]			= LeaPlusLC["MaxChatHstory"]
			LeaPlusDB["FilterChatMessages"]		= LeaPlusLC["FilterChatMessages"]
			LeaPlusDB["BlockSpellLinks"]		= LeaPlusLC["BlockSpellLinks"]
			LeaPlusDB["BlockDrunkenSpam"]		= LeaPlusLC["BlockDrunkenSpam"]
			LeaPlusDB["BlockDuelSpam"]			= LeaPlusLC["BlockDuelSpam"]
			LeaPlusDB["RestoreChatMessages"]	= LeaPlusLC["RestoreChatMessages"]

			-- Text
			LeaPlusDB["HideErrorMessages"]		= LeaPlusLC["HideErrorMessages"]
			LeaPlusDB["NoHitIndicators"]		= LeaPlusLC["NoHitIndicators"]
			LeaPlusDB["HideZoneText"] 			= LeaPlusLC["HideZoneText"]
			LeaPlusDB["HideKeybindText"] 		= LeaPlusLC["HideKeybindText"]
			LeaPlusDB["HideMacroText"] 			= LeaPlusLC["HideMacroText"]
			LeaPlusDB["HideRaidGroupLabels"] 	= LeaPlusLC["HideRaidGroupLabels"]

			LeaPlusDB["MailFontChange"] 		= LeaPlusLC["MailFontChange"]
			LeaPlusDB["LeaPlusMailFontSize"] 	= LeaPlusLC["LeaPlusMailFontSize"]

			LeaPlusDB["QuestFontChange"] 		= LeaPlusLC["QuestFontChange"]
			LeaPlusDB["LeaPlusQuestFontSize"]	= LeaPlusLC["LeaPlusQuestFontSize"]

			LeaPlusDB["BookFontChange"] 		= LeaPlusLC["BookFontChange"]
			LeaPlusDB["LeaPlusBookFontSize"]	= LeaPlusLC["LeaPlusBookFontSize"]

			-- Interface
			LeaPlusDB["MinimapModder"]			= LeaPlusLC["MinimapModder"]
			LeaPlusDB["SquareMinimap"]			= LeaPlusLC["SquareMinimap"]
			LeaPlusDB["MinimapButtonBag"]		= LeaPlusLC["MinimapButtonBag"]
			LeaPlusDB["MiniExcludeList"] 		= LeaPlusLC["MiniExcludeList"]
			LeaPlusDB["HideMiniZoomBtns"]		= LeaPlusLC["HideMiniZoomBtns"]
			LeaPlusDB["HideMiniClock"]			= LeaPlusLC["HideMiniClock"]
			LeaPlusDB["HideMiniDayNight"]		= LeaPlusLC["HideMiniDayNight"]
			LeaPlusDB["HideMiniZoneText"]		= LeaPlusLC["HideMiniZoneText"]
			LeaPlusDB["HideMiniAddonButtons"]	= LeaPlusLC["HideMiniAddonButtons"]
			LeaPlusDB["HideMiniTracking"]		= LeaPlusLC["HideMiniTracking"]
			LeaPlusDB["HideMiniLFG"]			= LeaPlusLC["HideMiniLFG"]
			LeaPlusDB["MinimapSize"]			= LeaPlusLC["MinimapSize"]
			LeaPlusDB["MinimapBorderWidth"]		= LeaPlusLC["MinimapBorderWidth"]
			LeaPlusDB["MinimapEffect"]			= LeaPlusLC["MinimapEffect"]

			LeaPlusDB["TipModEnable"]			= LeaPlusLC["TipModEnable"]
			LeaPlusDB["TipShowRank"]			= LeaPlusLC["TipShowRank"]
			LeaPlusDB["TipShowOtherRank"]		= LeaPlusLC["TipShowOtherRank"]
			LeaPlusDB["TipShowTarget"]			= LeaPlusLC["TipShowTarget"]
			LeaPlusDB["TipHideInCombat"]		= LeaPlusLC["TipHideInCombat"]
			LeaPlusDB["TipHideShiftOverride"]	= LeaPlusLC["TipHideShiftOverride"]
			LeaPlusDB["TipNoHealthBar"]			= LeaPlusLC["TipNoHealthBar"]
			LeaPlusDB["LeaPlusTipSize"]			= LeaPlusLC["LeaPlusTipSize"]
			LeaPlusDB["TipOffsetX"]				= LeaPlusLC["TipOffsetX"]
			LeaPlusDB["TipOffsetY"]				= LeaPlusLC["TipOffsetY"]
			LeaPlusDB["TooltipAnchorMenu"]		= LeaPlusLC["TooltipAnchorMenu"]
			LeaPlusDB["TipCursorX"]				= LeaPlusLC["TipCursorX"]
			LeaPlusDB["TipCursorY"]				= LeaPlusLC["TipCursorY"]

			LeaPlusDB["EnhanceDressup"]			= LeaPlusLC["EnhanceDressup"]
			LeaPlusDB["DressupItemButtons"]		= LeaPlusLC["DressupItemButtons"]
			LeaPlusDB["DressupAnimControl"]		= LeaPlusLC["DressupAnimControl"]
			LeaPlusDB["HideDressupStats"]		= LeaPlusLC["HideDressupStats"]
			LeaPlusDB["EnhanceQuestLog"]		= LeaPlusLC["EnhanceQuestLog"]
			LeaPlusDB["EnhanceQuestTaller"]		= LeaPlusLC["EnhanceQuestTaller"]
			LeaPlusDB["EnhanceQuestLevels"]		= LeaPlusLC["EnhanceQuestLevels"]
			LeaPlusDB["EnhanceQuestDifficulty"]	= LeaPlusLC["EnhanceQuestDifficulty"]
			LeaPlusDB["EnhanceProfessions"]		= LeaPlusLC["EnhanceProfessions"]
			LeaPlusDB["EnhanceTrainers"]		= LeaPlusLC["EnhanceTrainers"]
			LeaPlusDB["ShowTrainAllBtn"]		= LeaPlusLC["ShowTrainAllBtn"]
			LeaPlusDB["EnhanceFlightMap"]		= LeaPlusLC["EnhanceFlightMap"]
			LeaPlusDB["LeaPlusTaxiMapScale"]	= LeaPlusLC["LeaPlusTaxiMapScale"]
			LeaPlusDB["LeaPlusTaxiIconSize"]	= LeaPlusLC["LeaPlusTaxiIconSize"]
			LeaPlusDB["FlightMapA"]				= LeaPlusLC["FlightMapA"]
			LeaPlusDB["FlightMapR"]				= LeaPlusLC["FlightMapR"]
			LeaPlusDB["FlightMapX"]				= LeaPlusLC["FlightMapX"]
			LeaPlusDB["FlightMapY"]				= LeaPlusLC["FlightMapY"]

			LeaPlusDB["ShowVolume"] 			= LeaPlusLC["ShowVolume"]
			LeaPlusDB["AhExtras"]				= LeaPlusLC["AhExtras"]
			LeaPlusDB["AhBuyoutOnly"]			= LeaPlusLC["AhBuyoutOnly"]
			LeaPlusDB["AhGoldOnly"]				= LeaPlusLC["AhGoldOnly"]

			LeaPlusDB["ShowCooldowns"]			= LeaPlusLC["ShowCooldowns"]
			LeaPlusDB["ShowCooldownID"]			= LeaPlusLC["ShowCooldownID"]
			LeaPlusDB["NoCooldownDuration"]		= LeaPlusLC["NoCooldownDuration"]
			LeaPlusDB["CooldownsOnPlayer"]		= LeaPlusLC["CooldownsOnPlayer"]
			LeaPlusDB["DurabilityStatus"]		= LeaPlusLC["DurabilityStatus"]
			LeaPlusDB["ShowVanityControls"]		= LeaPlusLC["ShowVanityControls"]
			LeaPlusDB["VanityAltLayout"]		= LeaPlusLC["VanityAltLayout"]
			LeaPlusDB["ShowBagSearchBox"]		= LeaPlusLC["ShowBagSearchBox"]
			LeaPlusDB["ShowFreeBagSlots"]		= LeaPlusLC["ShowFreeBagSlots"]
			LeaPlusDB["ShowRaidToggle"]			= LeaPlusLC["ShowRaidToggle"]
			LeaPlusDB["ShowBorders"]			= LeaPlusLC["ShowBorders"]
			LeaPlusDB["BordersTop"]				= LeaPlusLC["BordersTop"]
			LeaPlusDB["BordersBottom"]			= LeaPlusLC["BordersBottom"]
			LeaPlusDB["BordersLeft"]			= LeaPlusLC["BordersLeft"]
			LeaPlusDB["BordersRight"]			= LeaPlusLC["BordersRight"]
			LeaPlusDB["BordersAlpha"]			= LeaPlusLC["BordersAlpha"]
			LeaPlusDB["ShowPlayerChain"]		= LeaPlusLC["ShowPlayerChain"]
			LeaPlusDB["PlayerChainMenu"]		= LeaPlusLC["PlayerChainMenu"]
			LeaPlusDB["ShowReadyTimer"]			= LeaPlusLC["ShowReadyTimer"]
			LeaPlusDB["ShowDruidPowerBar"]		= LeaPlusLC["ShowDruidPowerBar"]
			LeaPlusDB["ShowDruidStatusText"]	= LeaPlusLC["ShowDruidStatusText"]
			LeaPlusDB["ShowRangeColoring"]		= LeaPlusLC["ShowRangeColoring"]
			LeaPlusDB["ShowInfoCards"]			= LeaPlusLC["ShowInfoCards"]
			LeaPlusDB["InfoCardKey"]			= LeaPlusLC["InfoCardKey"]
			LeaPlusDB["ShowWowheadLinks"]		= LeaPlusLC["ShowWowheadLinks"]
			LeaPlusDB["WowheadLinkComments"]	= LeaPlusLC["WowheadLinkComments"]

			-- Frames
			LeaPlusDB["ManageWidget"]			= LeaPlusLC["ManageWidget"]
			LeaPlusDB["WidgetA"]				= LeaPlusLC["WidgetA"]
			LeaPlusDB["WidgetR"]				= LeaPlusLC["WidgetR"]
			LeaPlusDB["WidgetX"]				= LeaPlusLC["WidgetX"]
			LeaPlusDB["WidgetY"]				= LeaPlusLC["WidgetY"]
			LeaPlusDB["WidgetScale"]			= LeaPlusLC["WidgetScale"]

			LeaPlusDB["ManageTimer"]			= LeaPlusLC["ManageTimer"]
			LeaPlusDB["TimerA"]					= LeaPlusLC["TimerA"]
			LeaPlusDB["TimerR"]					= LeaPlusLC["TimerR"]
			LeaPlusDB["TimerX"]					= LeaPlusLC["TimerX"]
			LeaPlusDB["TimerY"]					= LeaPlusLC["TimerY"]
			LeaPlusDB["TimerScale"]				= LeaPlusLC["TimerScale"]

			LeaPlusDB["ClassColFrames"]			= LeaPlusLC["ClassColFrames"]
			LeaPlusDB["ClassColPlayer"]			= LeaPlusLC["ClassColPlayer"]
			LeaPlusDB["ClassColTarget"]			= LeaPlusLC["ClassColTarget"]

			LeaPlusDB["NoGryphons"]				= LeaPlusLC["NoGryphons"]
			LeaPlusDB["NoClassBar"]				= LeaPlusLC["NoClassBar"]

			-- System
			LeaPlusDB["NoScreenGlow"] 			= LeaPlusLC["NoScreenGlow"]
			LeaPlusDB["NoScreenEffects"] 		= LeaPlusLC["NoScreenEffects"]
			LeaPlusDB["SetWeatherDensity"] 		= LeaPlusLC["SetWeatherDensity"]
			LeaPlusDB["WeatherLevel"] 			= LeaPlusLC["WeatherLevel"]
			LeaPlusDB["MaxCameraZoom"] 			= LeaPlusLC["MaxCameraZoom"]

			LeaPlusDB["NoRestedEmotes"]			= LeaPlusLC["NoRestedEmotes"]
			LeaPlusDB["KeepAudioSynced"]		= LeaPlusLC["KeepAudioSynced"]
			LeaPlusDB["MuteGameSounds"]			= LeaPlusLC["MuteGameSounds"]
			LeaPlusDB["MuteMountSounds"]		= LeaPlusLC["MuteMountSounds"]
			LeaPlusDB["MuteCustomSounds"]		= LeaPlusLC["MuteCustomSounds"]
			LeaPlusDB["MuteCustomList"]			= LeaPlusLC["MuteCustomList"]

			LeaPlusDB["NoBagAutomation"]		= LeaPlusLC["NoBagAutomation"]
			LeaPlusDB["NoConfirmLoot"] 			= LeaPlusLC["NoConfirmLoot"]
			LeaPlusDB["FasterLooting"] 			= LeaPlusLC["FasterLooting"]
			LeaPlusDB["FasterMovieSkip"] 		= LeaPlusLC["FasterMovieSkip"]
			LeaPlusDB["StandAndDismount"] 		= LeaPlusLC["StandAndDismount"]
			LeaPlusDB["DismountNoResource"] 	= LeaPlusLC["DismountNoResource"]
			LeaPlusDB["DismountNoMoving"] 		= LeaPlusLC["DismountNoMoving"]
			LeaPlusDB["DismountNoTaxi"] 		= LeaPlusLC["DismountNoTaxi"]
			LeaPlusDB["DismountShowFormBtn"] 	= LeaPlusLC["DismountShowFormBtn"]
			LeaPlusDB["ShowVendorPrice"] 		= LeaPlusLC["ShowVendorPrice"]
			LeaPlusDB["CombatPlates"]			= LeaPlusLC["CombatPlates"]
			LeaPlusDB["EasyItemDestroy"]		= LeaPlusLC["EasyItemDestroy"]

			LeaPlusDB["ShowFlightTimes"]		= LeaPlusLC["ShowFlightTimes"]
			LeaPlusDB["FlightBarBackground"]	= LeaPlusLC["FlightBarBackground"]
			LeaPlusDB["FlightBarDestination"]	= LeaPlusLC["FlightBarDestination"]
			LeaPlusDB["FlightBarFillBar"]		= LeaPlusLC["FlightBarFillBar"]
			LeaPlusDB["FlightBarSpeech"]		= LeaPlusLC["FlightBarSpeech"]
			LeaPlusDB["FlightBarContribute"]	= LeaPlusLC["FlightBarContribute"]
			LeaPlusDB["FlightBarA"]				= LeaPlusLC["FlightBarA"]
			LeaPlusDB["FlightBarR"]				= LeaPlusLC["FlightBarR"]
			LeaPlusDB["FlightBarX"]				= LeaPlusLC["FlightBarX"]
			LeaPlusDB["FlightBarY"]				= LeaPlusLC["FlightBarY"]
			LeaPlusDB["FlightBarScale"]			= LeaPlusLC["FlightBarScale"]
			LeaPlusDB["FlightBarWidth"]			= LeaPlusLC["FlightBarWidth"]

			-- Settings
			LeaPlusDB["AddonLanguage"] 			= LeaPlusLC["AddonLanguage"]
			LeaPlusDB["ShowMinimapIcon"] 		= LeaPlusLC["ShowMinimapIcon"]
			LeaPlusDB["SetEditModeLayout"] 		= LeaPlusLC["SetEditModeLayout"]
			LeaPlusDB["EditModeLayoutName"] 	= LeaPlusLC["EditModeLayoutName"]
			LeaPlusDB["SimpleAddonListing"] 	= LeaPlusLC["SimpleAddonListing"]

			LeaPlusDB["PlusPanelScale"] 		= LeaPlusLC["PlusPanelScale"]
			LeaPlusDB["PlusPanelAlpha"] 		= LeaPlusLC["PlusPanelAlpha"]

			-- Panel position
			LeaPlusDB["MainPanelA"]				= LeaPlusLC["MainPanelA"]
			LeaPlusDB["MainPanelR"]				= LeaPlusLC["MainPanelR"]
			LeaPlusDB["MainPanelX"]				= LeaPlusLC["MainPanelX"]
			LeaPlusDB["MainPanelY"]				= LeaPlusLC["MainPanelY"]

			-- Start page
			LeaPlusDB["LeaStartPage"]			= LeaPlusLC["LeaStartPage"]

			-- Mute game sounds (LeaPlusLC["MuteGameSounds"])
			for k, v in pairs(LeaPlusLC["muteTable"]) do
				LeaPlusDB[k] = LeaPlusLC[k]
			end

			-- Mute mount sounds (LeaPlusLC["MuteMountSounds"])
			for k, v in pairs(LeaPlusLC["mountTable"]) do
				LeaPlusDB[k] = LeaPlusLC[k]
			end

		end

	end

--	Register event handler
	LpEvt:SetScript("OnEvent", eventHandler);

----------------------------------------------------------------------
--	L70: Player logout
----------------------------------------------------------------------

	-- Player Logout
	function LeaPlusLC:PlayerLogout(wipe)

		----------------------------------------------------------------------
		-- Restore default values for options that do not require reloads
		----------------------------------------------------------------------

		-- Disable screen glow (LeaPlusLC["NoScreenGlow"])
		if wipe then

			-- Disable screen glow (LeaPlusLC["NoScreenGlow"])
			SetCVar("ffxGlow", "1")

			-- Disable screen effects (LeaPlusLC["NoScreenEffects"])
			SetCVar("ffxDeath", "1")
			SetCVar("ffxNether", "1")

			-- Set weather density (LeaPlusLC["SetWeatherDensity"])
			SetCVar("WeatherDensity", "3")
			SetCVar("RAIDweatherDensity", "3")

			-- Max camera zoom (LeaPlusLC["MaxCameraZoom"])
			SetCVar("cameraDistanceMaxZoomFactor", 1.9)

			-- Universal group color (LeaPlusLC["UnivGroupColor"])
			ChangeChatColor("RAID", 1, 0.50, 0)
			ChangeChatColor("RAID_LEADER", 1, 0.28, 0.04)

			-- Mute game sounds (LeaPlusLC["MuteGameSounds"])
			for k, v in pairs(LeaPlusLC["muteTable"]) do
				for i, e in pairs(v) do
					local file, soundID = e:match("([^,]+)%#([^,]+)")
					UnmuteSoundFile(soundID)
				end
			end

			-- Mute mount sounds (LeaPlusLC["MuteMountSounds"])
			for k, v in pairs(LeaPlusLC["mountTable"]) do
				for i, e in pairs(v) do
					local file, soundID = e:match("([^,]+)%#([^,]+)")
					UnmuteSoundFile(soundID)
				end
			end

		end

		----------------------------------------------------------------------
		-- Restore default values for options that require reloads
		----------------------------------------------------------------------

		-- Use class colors in chat
		if LeaPlusDB["ClassColorsInChat"] == "On" and not LeaLockList["ClassColorsInChat"] then
			if wipe or (not wipe and LeaPlusLC["ClassColorsInChat"] == "Off") then
				SetCVar("chatClassColorOverride", "1")
				for void, v in ipairs({"SAY", "EMOTE", "YELL", "GUILD", "OFFICER", "WHISPER", "PARTY", "PARTY_LEADER", "RAID", "RAID_LEADER", "RAID_WARNING", "INSTANCE_CHAT", "INSTANCE_CHAT_LEADER", "VOICE_TEXT"}) do
					SetChatColorNameByClass(v, false)
				end
				for i = 1, 50 do
					SetChatColorNameByClass("CHANNEL" .. i, false)
				end
			end
		end

		-- Enhance minimap restore round minimap if wipe or enhance minimap is toggled off
		if LeaPlusDB["MinimapModder"] == "On" and LeaPlusDB["SquareMinimap"] == "On" and not LeaLockList["MinimapModder"] then
			if wipe or (not wipe and LeaPlusLC["MinimapModder"] == "Off") then
				Minimap:SetMaskTexture([[Interface\CharacterFrame\TempPortraitAlphaMask]])
			end
		end

		-- Silence rested emotes
		if LeaPlusDB["NoRestedEmotes"] == "On" then
			if wipe or (not wipe and LeaPlusLC["NoRestedEmotes"] == "Off") then
				SetCVar("Sound_EnableEmoteSounds", "1")
			end
		end

		-- Show free bag slos
		if LeaPlusDB["ShowFreeBagSlots"] == "On" and not LeaLockList["ShowFreeBagSlots"] then
			if wipe or (not wipe and LeaPlusLC["ShowFreeBagSlots"] == "Off") then
				SetCVar("displayFreeBagSlots", "0")
			end
		end

		----------------------------------------------------------------------
		-- Do other stuff during logout
		----------------------------------------------------------------------

		-- Store the auction house duration and price type values if auction house option is enabled
		if LeaPlusDB["AhExtras"] == "On" then
			if AuctionFrameAuctions then
				if AuctionFrameAuctions.duration then
					LeaPlusDB["AHDuration"] = AuctionFrameAuctions.duration
				end
			end
		end

	end

----------------------------------------------------------------------
-- 	Options panel functions
----------------------------------------------------------------------

	-- Function to add textures to panels
	function LeaPlusLC:CreateBar(name, parent, width, height, anchor, r, g, b, alp, tex)
		local ft = parent:CreateTexture(nil, "BORDER")
		ft:SetTexture(tex)
		ft:SetSize(width, height)
		ft:SetPoint(anchor)
		ft:SetVertexColor(r ,g, b, alp)
		if name == "MainTexture" then
			ft:SetTexCoord(0.09, 1, 0, 1);
		end
	end

	-- Create a configuration panel
	function LeaPlusLC:CreatePanel(title, globref, scrolling)

		-- Create the panel
		local Side = CreateFrame("Frame", LeaPlusLC:CreateRandomName(), UIParent)

		-- Make it a system frame
		table.insert(UISpecialFrames, Side:GetName())

		-- Store it in the configuration panel table
		tinsert(LeaConfigList, Side)

		-- Set frame parameters
		Side:Hide();
		Side:SetSize(570, LeaPlusLC.MainPanelHeight)
		Side:SetClampedToScreen(true)
		Side:SetClampRectInsets(500, -500, -300, 300)
		Side:SetFrameStrata("FULLSCREEN_DIALOG")

		-- Set the background color
		Side.t = Side:CreateTexture(nil, "BACKGROUND")
		Side.t:SetAllPoints()
		Side.t:SetColorTexture(0.05, 0.05, 0.05, 0.9)

		-- Add a close Button
		Side.c = CreateFrame("Button", nil, Side, "UIPanelCloseButton")
		Side.c:SetSize(30, 30)
		Side.c:SetPoint("TOPRIGHT", 0, 0)
		Side.c:SetScript("OnClick", function() Side:Hide() end)

		-- Add reset, help and back buttons
		Side.r = LeaPlusLC:CreateButton("ResetButton", Side, "Reset", "BOTTOMLEFT", 16, 53, 0, 25, true, "Click to reset the settings on this page.")
		Side.h = LeaPlusLC:CreateButton("HelpButton", Side, "Help", "BOTTOMLEFT", 76, 53, 0, 25, true, "No help is available for this page.")
		Side.b = LeaPlusLC:CreateButton("BackButton", Side, "Back to Main Menu", "BOTTOMRIGHT", -16, 53, 0, 25, true, "Click to return to the main menu.")

		-- Reposition help button so it doesn't overlap reset button
		Side.h:ClearAllPoints()
		Side.h:SetPoint("LEFT", Side.r, "RIGHT", 10, 0)

		-- Remove the click texture from the help button
		Side.h:SetPushedTextOffset(0, 0)

		-- Add a reload button and syncronise it with the main panel reload button
		local reloadb = LeaPlusLC:CreateButton("ConfigReload", Side, "Reload", "BOTTOMRIGHT", -16, 10, 0, 25, true, LeaPlusCB["ReloadUIButton"].tiptext)
		LeaPlusLC:LockItem(reloadb,true)
		reloadb:SetScript("OnClick", ReloadUI)

		reloadb.f = reloadb:CreateFontString(nil, 'ARTWORK', 'GameFontNormalSmall')
		reloadb.f:SetHeight(32);
		reloadb.f:SetPoint('RIGHT', reloadb, 'LEFT', -10, 0)
		reloadb.f:SetText(LeaPlusCB["ReloadUIButton"].f:GetText())
		reloadb.f:Hide()

		LeaPlusCB["ReloadUIButton"]:HookScript("OnEnable", function()
			LeaPlusLC:LockItem(reloadb, false)
			reloadb.f:Show()
		end)

		LeaPlusCB["ReloadUIButton"]:HookScript("OnDisable", function()
			LeaPlusLC:LockItem(reloadb, true)
			reloadb.f:Hide()
		end)

		-- Set textures
		LeaPlusLC:CreateBar("FootTexture", Side, 570, 48, "BOTTOM", 0.5, 0.5, 0.5, 1.0, "Interface\\ACHIEVEMENTFRAME\\UI-GuildAchievement-Parchment-Horizontal-Desaturated.png")
		LeaPlusLC:CreateBar("MainTexture", Side, 570, LeaPlusLC.MainPanelHeight - 47, "TOPRIGHT", 0.7, 0.7, 0.7, 0.7,  "Interface\\ACHIEVEMENTFRAME\\UI-GuildAchievement-Parchment-Horizontal-Desaturated.png")

		-- Allow movement
		Side:EnableMouse(true)
		Side:SetMovable(true)
		Side:RegisterForDrag("LeftButton")
		Side:SetScript("OnDragStart", Side.StartMoving)
		Side:SetScript("OnDragStop", function ()
			Side:StopMovingOrSizing();
			Side:SetUserPlaced(false);
			-- Save panel position
			LeaPlusLC["MainPanelA"], void, LeaPlusLC["MainPanelR"], LeaPlusLC["MainPanelX"], LeaPlusLC["MainPanelY"] = Side:GetPoint()
		end)

		-- Set panel attributes when shown
		Side:SetScript("OnShow", function()
			Side:ClearAllPoints()
			Side:SetPoint(LeaPlusLC["MainPanelA"], UIParent, LeaPlusLC["MainPanelR"], LeaPlusLC["MainPanelX"], LeaPlusLC["MainPanelY"])
			Side:SetScale(LeaPlusLC["PlusPanelScale"])
			Side.t:SetAlpha(1 - LeaPlusLC["PlusPanelAlpha"])
		end)

		-- Add title
		Side.f = Side:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
		Side.f:SetPoint('TOPLEFT', 16, -16);
		Side.f:SetText(L[title])

		-- Add description
		Side.v = Side:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightSmall')
		Side.v:SetHeight(32);
		Side.v:SetPoint('TOPLEFT', Side.f, 'BOTTOMLEFT', 0, -8);
		Side.v:SetPoint('RIGHT', Side, -32, 0)
		Side.v:SetJustifyH('LEFT'); Side.v:SetJustifyV('TOP');
		Side.v:SetText(L["Configuration Panel"])

		-- Prevent options panel from showing while side panel is showing
		LeaPlusLC["PageF"]:HookScript("OnShow", function()
			if Side:IsShown() then LeaPlusLC["PageF"]:Hide(); end
		end)

		-- Create scroll frame if needed
		if scrolling then

			-- Create backdrop
			Side.backFrame = CreateFrame("FRAME", nil, Side, "BackdropTemplate")
			Side.backFrame:SetSize(Side:GetSize())
			Side.backFrame:SetPoint("TOPLEFT", 16, -68)
			Side.backFrame:SetPoint("BOTTOMRIGHT", -16, 98)
			Side.backFrame:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"})
			Side.backFrame:SetBackdropColor(0, 0, 1, 0.5)

			-- Create scroll frame
			Side.scrollFrame = CreateFrame("ScrollFrame", nil, Side.backFrame, "LeaPlusConfigurationPanelScrollFrameTemplate")
			Side.scrollChild = CreateFrame("Frame", nil, Side.scrollFrame)

			Side.scrollChild:SetSize(1, 1)
			Side.scrollFrame:SetScrollChild(Side.scrollChild)
			Side.scrollFrame:SetPoint("TOPLEFT", -8, -6)
			Side.scrollFrame:SetPoint("BOTTOMRIGHT", -29, 6)
			Side.scrollFrame:SetPanExtent(20)

			-- Set scroll list to top when shown
			Side.scrollFrame:HookScript("OnShow", function()
				Side.scrollFrame:SetVerticalScroll(0)
			end)

			-- Add scroll for more message
			local footMessage = LeaPlusLC:MakeTx(Side, "(scroll the list for more)", 16, 0)
			footMessage:ClearAllPoints()
			footMessage:SetPoint("TOPRIGHT", Side.scrollFrame, "TOPRIGHT", 28, 24)

			-- Give child a file level scope (it's used in LeaPlusLC.TipSee)
			LeaPlusLC[globref .. "ScrollChild"] = Side.scrollChild

		end

		-- Return the frame
		return Side

	end

	-- Define subheadings
	function LeaPlusLC:MakeTx(frame, title, x, y)
		local text = frame:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
		text:SetPoint("TOPLEFT", x, y)
		text:SetText(L[title])
		return text
	end

	-- Define text
	function LeaPlusLC:MakeWD(frame, title, x, y)
		local text = frame:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')
		text:SetPoint("TOPLEFT", x, y)
		text:SetText(L[title])
		text:SetJustifyH"LEFT";
		return text
	end

	-- Create a slider control (uses standard template)
	function LeaPlusLC:MakeSL(frame, field, caption, low, high, step, x, y, form)

		-- Create slider control
		local Slider = CreateFrame("Slider", nil, frame, "LeaPlusConfigurationPanelSliderTemplate") -- Old is UISliderTemplate
		LeaPlusCB[field] = Slider
		Slider:SetMinMaxValues(low, high)
		Slider:SetValueStep(step)
		Slider:EnableMouseWheel(true)
		Slider:SetPoint('TOPLEFT', x, y)
		Slider:SetWidth(100)
		Slider:SetHeight(20)
		Slider:SetHitRectInsets(0, 0, 0, 0)
		Slider.tiptext = L[caption]
		Slider:SetScript("OnEnter", LeaPlusLC.TipSee)
		Slider:SetScript("OnLeave", GameTooltip_Hide)

		-- Create slider label
		Slider.f = Slider:CreateFontString(nil, 'BACKGROUND')
		Slider.f:SetFontObject('GameFontHighlight')
		Slider.f:SetPoint('LEFT', Slider, 'RIGHT', 12, 0)
		Slider.f:SetFormattedText("%.2f", Slider:GetValue())

		-- Process mousewheel scrolling
		Slider:SetScript("OnMouseWheel", function(self, arg1)
			if Slider:IsEnabled() then
				local step = step * arg1
				local value = self:GetValue()
				if step > 0 then
					self:SetValue(min(value + step, high))
				else
					self:SetValue(max(value + step, low))
				end
			end
		end)

		-- Process value changed
		Slider:SetScript("OnValueChanged", function(self, value)
			local value = floor((value - low) / step + 0.5) * step + low
			Slider.f:SetFormattedText(form, value)
			LeaPlusLC[field] = value
		end)

		-- Set slider value when shown
		Slider:SetScript("OnShow", function(self)
			self:SetValue(LeaPlusLC[field])
		end)

	end

	-- Create a checkbox control (uses standard template)
	function LeaPlusLC:MakeCB(parent, field, caption, x, y, reload, tip, tipstyle)

		-- Create the checkbox
		local Cbox = CreateFrame('CheckButton', nil, parent, "ChatConfigCheckButtonTemplate")
		LeaPlusCB[field] = Cbox
		Cbox:SetPoint("TOPLEFT",x, y)
		Cbox:SetScript("OnEnter", LeaPlusLC.TipSee)
		Cbox:SetScript("OnLeave", GameTooltip_Hide)

		-- Add label and tooltip
		Cbox.f = Cbox:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')
		Cbox.f:SetPoint('LEFT', 20, 0)
		if reload then
			-- Checkbox requires UI reload
			Cbox.f:SetText(L[caption] .. "*")
			Cbox.tiptext = L[tip] .. "|n|n* " .. L["Requires UI reload."]
		else
			-- Checkbox does not require UI reload
			Cbox.f:SetText(L[caption])
			Cbox.tiptext = L[tip]
		end

		-- Set label parameters
		Cbox.f:SetJustifyH("LEFT")
		Cbox.f:SetWordWrap(false)

		-- Set maximum label width
		if parent:GetParent() == LeaPlusLC["PageF"] then
			-- Main panel checkbox labels
			if Cbox.f:GetWidth() > 152 then
				Cbox.f:SetWidth(152)
				LeaPlusLC["TruncatedLabelsList"] = LeaPlusLC["TruncatedLabelsList"] or {}
				LeaPlusLC["TruncatedLabelsList"][Cbox.f] = L[caption]
			end
			-- Set checkbox click width
			if Cbox.f:GetStringWidth() > 152 then
				Cbox:SetHitRectInsets(0, -142, 0, 0)
			else
				Cbox:SetHitRectInsets(0, -Cbox.f:GetStringWidth() + 4, 0, 0)
			end
		else
			-- Configuration panel checkbox labels (other checkboxes either have custom functions or blank labels)
			if Cbox.f:GetWidth() > 302 then
				Cbox.f:SetWidth(302)
				LeaPlusLC["TruncatedLabelsList"] = LeaPlusLC["TruncatedLabelsList"] or {}
				LeaPlusLC["TruncatedLabelsList"][Cbox.f] = L[caption]
			end
			-- Set checkbox click width
			if Cbox.f:GetStringWidth() > 302 then
				Cbox:SetHitRectInsets(0, -292, 0, 0)
			else
				Cbox:SetHitRectInsets(0, -Cbox.f:GetStringWidth() + 4, 0, 0)
			end
		end

		-- Set default checkbox state and click area
		Cbox:SetScript('OnShow', function(self)
			if LeaPlusLC[field] == "On" then
				self:SetChecked(true)
			else
				self:SetChecked(false)
			end
		end)

		-- Process clicks
		Cbox:SetScript('OnClick', function()
			if Cbox:GetChecked() then
				LeaPlusLC[field] = "On"
			else
				LeaPlusLC[field] = "Off"
			end
			LeaPlusLC:SetDim(); -- Lock invalid options
			LeaPlusLC:ReloadCheck(); -- Show reload button if needed
		end)
	end

	-- Create an editbox (uses standard template)
	function LeaPlusLC:CreateEditBox(frame, parent, width, maxchars, anchor, x, y, tab, shifttab)

		-- Create editbox
        local eb = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
		LeaPlusCB[frame] = eb
		eb:SetPoint(anchor, x, y)
		eb:SetWidth(width)
		eb:SetHeight(24)
		eb:SetFontObject("GameFontNormal")
		eb:SetTextColor(1.0, 1.0, 1.0)
		eb:SetAutoFocus(false)
		eb:SetMaxLetters(maxchars)
		eb:SetScript("OnEscapePressed", eb.ClearFocus)
		eb:SetScript("OnEnterPressed", eb.ClearFocus)

		-- Add editbox border and backdrop
		eb.f = CreateFrame("FRAME", nil, eb, "BackdropTemplate")
		eb.f:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = false, tileSize = 16, edgeSize = 16, insets = { left = 5, right = 5, top = 5, bottom = 5 }})
		eb.f:SetPoint("LEFT", -6, 0)
		eb.f:SetWidth(eb:GetWidth()+6)
		eb.f:SetHeight(eb:GetHeight())
		eb.f:SetBackdropColor(1.0, 1.0, 1.0, 0.3)

		-- Move onto next editbox when tab key is pressed
		eb:SetScript("OnTabPressed", function(self)
			self:ClearFocus()
			if IsShiftKeyDown() then
				LeaPlusCB[shifttab]:SetFocus()
			else
				LeaPlusCB[tab]:SetFocus()
			end
		end)

		return eb

	end

	-- Create a standard button (using standard button template)
	function LeaPlusLC:CreateButton(name, frame, label, anchor, x, y, width, height, reskin, tip, naked)
		local mbtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
		LeaPlusCB[name] = mbtn
		mbtn:SetSize(width, height)
		mbtn:SetPoint(anchor, x, y)
		mbtn:SetHitRectInsets(0, 0, 0, 0)
		mbtn:SetText(L[label])

		-- Create fontstring so the button can be sized correctly
		mbtn.f = mbtn:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
		mbtn.f:SetText(L[label])
		if width > 0 then
			-- Button should have static width
			mbtn:SetWidth(width)
		else
			-- Button should have variable width
			mbtn:SetWidth(mbtn.f:GetStringWidth() + 20)
		end

		-- Tooltip handler
		mbtn.tiptext = L[tip]
		mbtn:SetScript("OnEnter", LeaPlusLC.TipSee)
		mbtn:SetScript("OnLeave", GameTooltip_Hide)

		-- Texture the button
		if reskin then

			-- Set skinned button textures
			if not naked then
				mbtn:SetNormalTexture("Interface\\AddOns\\Leatrix_Plus\\Leatrix_Plus.blp")
				mbtn:GetNormalTexture():SetTexCoord(0.125, 0.25, 0.21875, 0.25)
			end
			mbtn:SetHighlightTexture("Interface\\AddOns\\Leatrix_Plus\\Leatrix_Plus.blp")
			mbtn:GetHighlightTexture():SetTexCoord(0, 0.125, 0.21875, 0.25)

			-- Hide the default textures
			mbtn:HookScript("OnShow", function() mbtn.Left:Hide(); mbtn.Middle:Hide(); mbtn.Right:Hide() end)
			mbtn:HookScript("OnEnable", function() mbtn.Left:Hide(); mbtn.Middle:Hide(); mbtn.Right:Hide() end)
			mbtn:HookScript("OnDisable", function() mbtn.Left:Hide(); mbtn.Middle:Hide(); mbtn.Right:Hide() end)
			mbtn:HookScript("OnMouseDown", function() mbtn.Left:Hide(); mbtn.Middle:Hide(); mbtn.Right:Hide() end)
			mbtn:HookScript("OnMouseUp", function() mbtn.Left:Hide(); mbtn.Middle:Hide(); mbtn.Right:Hide() end)

		end

		return mbtn
	end

	-- Create a dropdown menu (using standard dropdown template)
	function LeaPlusLC:CreateDropdown(frame, label, width, anchor, parent, relative, x, y, reload, items)

		local RadioDropdown = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
		LeaPlusCB[frame] = RadioDropdown
		RadioDropdown:SetPoint(anchor, parent, relative, x, y)
		RadioDropdown:SetWidth(width)

		local function IsSelected(value)
			return value == LeaPlusLC[frame]
		end

		local function SetSelected(value)
			LeaPlusLC[frame] = value
		end

		MenuUtil.CreateRadioMenu(RadioDropdown, IsSelected, SetSelected, unpack(items))

		local lf = RadioDropdown:CreateFontString(nil, "OVERLAY", "GameFontNormal"); lf:SetPoint("TOPLEFT", RadioDropdown, 0, 20); lf:SetPoint("TOPRIGHT", RadioDropdown, -5, 20); lf:SetJustifyH("LEFT"); lf:SetText(L[label])

		-- Cycle through the options with the mousewheel while the menu is closed (scroll down for the next option, up for the previous one)
		RadioDropdown:EnableMouseWheel(true)

		-- Apply the new option in the same way as choosing it from the menu (runs anything hooked to the menu closing)
		RadioDropdown:HookScript("OnMouseWheel", function(self)
			self:TriggerEvent(DropdownButtonMixin.Event.OnMenuClose, self)
		end)

		-- Cycle through the options with the mousewheel while the menu is open (an invisible layer over the menu takes the mousewheel but lets clicks through)
		local wheel
		RadioDropdown:RegisterCallback("OnMenuOpen", function()
			local menu = RadioDropdown.menu
			if not menu then return end
			if not wheel then
				wheel = CreateFrame("Frame", nil, UIParent)
				wheel:EnableMouse(false)
				wheel:EnableMouseWheel(true)
				wheel:SetScript("OnMouseWheel", function(self, delta)
					-- Find the current option and step to the next or previous one (stops at either end)
					local index = 1
					for i = 1, #items do
						if items[i][2] == LeaPlusLC[frame] then index = i; break end
					end
					index = index + (delta < 0 and 1 or -1)
					if index < 1 or index > #items then return end
					LeaPlusLC[frame] = items[index][2]
					-- Move the tick in the open menu, update the dropdown text and apply the option
					if RadioDropdown.menu then RadioDropdown.menu:ReinitializeAll() end
					RadioDropdown:SignalUpdate()
					RadioDropdown:TriggerEvent(DropdownButtonMixin.Event.OnMenuClose, RadioDropdown)
				end)
			end
			wheel:SetAllPoints(menu)
			wheel:SetFrameStrata(menu:GetFrameStrata())
			wheel:SetFrameLevel(menu:GetFrameLevel() + 50)
			wheel:Show()
		end)

		-- Hide the layer when the menu really closes (the mousewheel also signals the menu closing so options apply, but without a menu)
		RadioDropdown:RegisterCallback("OnMenuClose", function(owner, dropdown, menu)
			if menu and wheel then wheel:Hide() end
			if reload then
				LeaPlusLC:ReloadCheck()
			end
		end)

	end

----------------------------------------------------------------------
-- 	Create main options panel frame
----------------------------------------------------------------------

	function LeaPlusLC:CreateMainPanel()

		-- Create the panel
		local PageF = CreateFrame("Frame", LeaPlusLC:CreateRandomName(), UIParent);

		-- Make it a system frame
		table.insert(UISpecialFrames, PageF:GetName())

		-- Set frame parameters
		LeaPlusLC["PageF"] = PageF
		PageF:SetSize(570, LeaPlusLC.MainPanelHeight)
		PageF:Hide();
		PageF:SetFrameStrata("FULLSCREEN_DIALOG")
		PageF:SetClampedToScreen(true)
		PageF:SetClampRectInsets(500, -500, -300, 300)
		PageF:EnableMouse(true)
		PageF:SetMovable(true)
		PageF:RegisterForDrag("LeftButton")
		PageF:SetScript("OnDragStart", PageF.StartMoving)
		PageF:SetScript("OnDragStop", function ()
			PageF:StopMovingOrSizing();
			PageF:SetUserPlaced(false);
			-- Save panel position
			LeaPlusLC["MainPanelA"], void, LeaPlusLC["MainPanelR"], LeaPlusLC["MainPanelX"], LeaPlusLC["MainPanelY"] = PageF:GetPoint()
		end)

		-- Add background color
		PageF.t = PageF:CreateTexture(nil, "BACKGROUND")
		PageF.t:SetAllPoints()
		PageF.t:SetColorTexture(0.05, 0.05, 0.05, 0.9)

		-- Add textures
		LeaPlusLC:CreateBar("FootTexture", PageF, 570, 48, "BOTTOM", 0.5, 0.5, 0.5, 1.0, "Interface\\ACHIEVEMENTFRAME\\UI-GuildAchievement-Parchment-Horizontal-Desaturated.png")
		LeaPlusLC:CreateBar("MainTexture", PageF, 440, LeaPlusLC.MainPanelHeight - 47, "TOPRIGHT", 0.7, 0.7, 0.7, 0.7,  "Interface\\ACHIEVEMENTFRAME\\UI-GuildAchievement-Parchment-Horizontal-Desaturated.png")
		LeaPlusLC:CreateBar("MenuTexture", PageF, 130, LeaPlusLC.MainPanelHeight - 47, "TOPLEFT", 0.7, 0.7, 0.7, 0.7, "Interface\\ACHIEVEMENTFRAME\\UI-GuildAchievement-Parchment-Horizontal-Desaturated.png")

		-- Set panel position when shown
		PageF:SetScript("OnShow", function()
			PageF:ClearAllPoints()
			PageF:SetPoint(LeaPlusLC["MainPanelA"], UIParent, LeaPlusLC["MainPanelR"], LeaPlusLC["MainPanelX"], LeaPlusLC["MainPanelY"])
		end)

		-- Add main title (shown above menu in the corner)
		PageF.mt = PageF:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
		PageF.mt:SetPoint('TOPLEFT', 16, -16)
		PageF.mt:SetText("Leatrix Plus")

		-- Add version text (shown underneath main title)
		PageF.v = PageF:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightSmall')
		PageF.v:SetHeight(32);
		PageF.v:SetPoint('TOPLEFT', PageF.mt, 'BOTTOMLEFT', 0, -8);
		PageF.v:SetPoint('RIGHT', PageF, -32, 0)
		PageF.v:SetJustifyH('LEFT'); PageF.v:SetJustifyV('TOP');
		PageF.v:SetNonSpaceWrap(true); PageF.v:SetText(L["BCA"] .. " " .. LeaPlusLC["AddonVer"])

		-- Add reload UI Button
		local reloadb = LeaPlusLC:CreateButton("ReloadUIButton", PageF, "Reload", "BOTTOMRIGHT", -16, 10, 0, 25, true, "Your UI needs to be reloaded for some of the changes to take effect.|n|nYou don't have to click the reload button immediately but you do need to click it when you are done making changes and you want the changes to take effect.")
		LeaPlusLC:LockItem(reloadb,true)
		reloadb:SetScript("OnClick", ReloadUI)

		reloadb.f = reloadb:CreateFontString(nil, 'ARTWORK', 'GameFontNormalSmall')
		reloadb.f:SetHeight(32);
		reloadb.f:SetPoint('RIGHT', reloadb, 'LEFT', -10, 0)
		reloadb.f:SetText(L["Your UI needs to be reloaded."])
		reloadb.f:Hide()

		-- Add close Button
		local CloseB = CreateFrame("Button", nil, PageF, "UIPanelCloseButton")
		CloseB:SetSize(30, 30)
		CloseB:SetPoint("TOPRIGHT", 0, 0)
		CloseB:SetScript("OnClick", LeaPlusLC.HideFrames)

		-- Release memory
		LeaPlusLC.CreateMainPanel = nil

	end

	LeaPlusLC:CreateMainPanel();

----------------------------------------------------------------------
-- 	L80: Commands
----------------------------------------------------------------------

	-- Slash command function
	function LeaPlusLC:SlashFunc(str)
		if str and str ~= "" then
			-- Get parameters in lower case with duplicate spaces removed
			local str, arg1, arg2, arg3 = strsplit(" ", string.lower(str:gsub("%s+", " ")))
			-- Traverse parameters
			if str == "wipe" then
				-- Wipe settings
				LeaPlusLC:PlayerLogout(true) -- Run logout function with wipe parameter
				wipe(LeaPlusDB)
				LpEvt:UnregisterAllEvents(); -- Don't save any settings
				ReloadUI();
			elseif str == "nosave" then
				-- Prevent Leatrix Plus from overwriting LeaPlusDB at next logout
				LpEvt:UnregisterEvent("PLAYER_LOGOUT")
				LeaPlusLC:Print("Leatrix Plus will not overwrite LeaPlusDB at next logout.")
				return
			elseif str == "reset" then
				-- Reset panel positions
				LeaPlusLC["MainPanelA"], LeaPlusLC["MainPanelR"], LeaPlusLC["MainPanelX"], LeaPlusLC["MainPanelY"] = "CENTER", "CENTER", 0, 0
				LeaPlusLC["PlusPanelScale"] = 1
				LeaPlusLC["PlusPanelAlpha"] = 0
				LeaPlusLC["PageF"]:SetScale(1)
				LeaPlusLC["PageF"].t:SetAlpha(1 - LeaPlusLC["PlusPanelAlpha"])
				-- Refresh panels
				LeaPlusLC["PageF"]:ClearAllPoints()
				LeaPlusLC["PageF"]:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
				-- Reset currently showing configuration panel
				for k, v in pairs(LeaConfigList) do
					if v:IsShown() then
						v:ClearAllPoints()
						v:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
						v:SetScale(1)
						v.t:SetAlpha(1 - LeaPlusLC["PlusPanelAlpha"])
					end
				end
				-- Refresh Leatrix Plus settings menu only
				if LeaPlusLC["Page8"]:IsShown() then
					LeaPlusLC["Page8"]:Hide()
					LeaPlusLC["Page8"]:Show()
				end
				return
			elseif str == "taint" then
				-- Set taint log level
				if arg1 and arg1 ~= "" then
					arg1 = tonumber(arg1)
					if arg1 and arg1 >= 0 and arg1 <= 2 then
						if arg1 == 0 then
							-- Disable taint log
							ConsoleExec("taintLog 0")
							LeaPlusLC:Print("Taint level: Disabled (0).")
						elseif arg1 == 1 then
							-- Basic taint log
							ConsoleExec("taintLog 1")
							LeaPlusLC:Print("Taint level: Basic (1).")
						elseif arg1 == 2 then
							-- Full taint log
							ConsoleExec("taintLog 2")
							LeaPlusLC:Print("Taint level: Full (2).")
						end
					else
						LeaPlusLC:Print("Invalid taint level.")
					end
				else
					-- Show current taint level
					local taintCurrent = GetCVar("taintLog")
					if taintCurrent == "0" then
						LeaPlusLC:Print("Taint level: Disabled (0).")
					elseif taintCurrent == "1" then
						LeaPlusLC:Print("Taint level: Basic (1).")
					elseif taintCurrent == "2" then
						LeaPlusLC:Print("Taint level: Full (2).")
					end
				end
				return
			elseif str == "quest" then
				-- Show quest completed status
				if arg1 and arg1 ~= "" then
					if arg1 == "wipe" then
						-- Wipe quest log
						for i = 1, GetNumQuestLogEntries() do
							SelectQuestLogEntry(i)
							SetAbandonQuest()
							AbandonQuest()
						end
						LeaPlusLC:Print(L["Quest log wiped."])
						return
					elseif tonumber(arg1) and tonumber(arg1) < 999999999 then
						-- Show quest information
						local questCompleted = C_QuestLog.IsQuestFlaggedCompleted(arg1)
						local questTitle = C_QuestLog.GetQuestInfo(arg1) or L["Unknown"]
						C_Timer.After(0.5, function()
							local questTitle = C_QuestLog.GetQuestInfo(arg1) or L["Unknown"]
							if questCompleted then
								LeaPlusLC:Print(questTitle .. " (" .. arg1 .. "):" .. "|cffffffff " .. L["Completed."])
							else
								LeaPlusLC:Print(questTitle .. " (" .. arg1 .. "):" .. "|cffffffff " .. L["Not completed."])
							end
						end)
					else
						LeaPlusLC:Print("Invalid quest ID.")
					end
				else
					LeaPlusLC:Print("Missing quest ID.")
				end
				return
			elseif str == "rest" then
				-- Show rested bubbles
				LeaPlusLC:Print(L["Rested bubbles"] .. ": |cffffffff" .. (math.floor(20 * (GetXPExhaustion() or 0) / UnitXPMax("player") + 0.5)))
				return
			elseif str == "zygor" then
				-- Toggle Zygor addon
				LeaPlusLC:ZygorToggle()
				return
			elseif str == "npcid" then
				-- Print NPC ID
				local npcName = UnitName("target")
				local npcGuid = UnitGUID("target") or nil
				if npcName and npcGuid then
					local void, void, void, void, void, npcID = strsplit("-", npcGuid)
					if npcID then
						LeaPlusLC:Print(npcName .. ": |cffffffff" .. npcID)
					end
				end
				return
			elseif str == "tooltip" then
				-- Print tooltip frame name
				pcall(function()
					local enumf = EnumerateFrames()
					while enumf do
						if (enumf:GetObjectType() == "GameTooltip" or strfind((enumf:GetName() or ""):lower(),"tip")) and enumf:IsVisible() and enumf:GetPoint() then
							print(enumf:GetName())
						end
						enumf = EnumerateFrames(enumf)
					end
					collectgarbage()
					return
				end)
			elseif str == "rsnd" then
				-- Restart sound system
				if LeaPlusCB["StopMusicBtn"] then LeaPlusCB["StopMusicBtn"]:Click() end
				Sound_GameSystem_RestartSoundSystem()
				LeaPlusLC:Print("Sound system restarted.")
				return
			elseif str == "event" then
				-- List events (used for debug)
				LeaPlusLC["DbF"] = LeaPlusLC["DbF"] or CreateFrame("FRAME")
				if not LeaPlusLC["DbF"]:GetScript("OnEvent") then
					LeaPlusLC:Print("Tracing started.")
					LeaPlusLC["DbF"]:RegisterAllEvents()
					LeaPlusLC["DbF"]:SetScript("OnEvent", function(self, event)
						if event == "ACTIONBAR_UPDATE_COOLDOWN"
						or event == "BAG_UPDATE_COOLDOWN"
						or event == "CHAT_MSG_TRADESKILLS"
						or event == "COMBAT_LOG_EVENT_UNFILTERED"
						or event == "SPELL_UPDATE_COOLDOWN"
						or event == "SPELL_UPDATE_USABLE"
						or event == "UNIT_POWER_FREQUENT"
						or event == "UPDATE_INVENTORY_DURABILITY"
						then return
						else
							print(event)
						end
					end)
				else
					LeaPlusLC["DbF"]:UnregisterAllEvents()
					LeaPlusLC["DbF"]:SetScript("OnEvent", nil)
					LeaPlusLC:Print("Tracing stopped.")
				end
				return
			elseif str == "game" then
				-- Show game build
				local version, build, gdate, tocversion = GetBuildInfo()
				LeaPlusLC:Print(L["World of Warcraft"] .. ": |cffffffff" .. version .. "." .. build .. " (" .. gdate .. ") (" .. tocversion .. ")")
				return
			elseif str == "config" then
				-- Show maximum camera distance
				LeaPlusLC:Print(L["Camera distance"] .. ": |cffffffff" .. GetCVar("cameraDistanceMaxZoomFactor"))
				-- Show screen effects
				LeaPlusLC:Print(L["Shaders"] .. ": |cffffffff" .. GetCVar("ffxGlow") .. ", " .. GetCVar("ffxDeath") .. ", " .. GetCVar("ffxNether"))
				-- Show particle density
				LeaPlusLC:Print(L["Particle density"] .. ": |cffffffff" .. GetCVar("particleDensity"))
				LeaPlusLC:Print(L["Weather density"] .. ": |cffffffff" .. GetCVar("weatherDensity"))
				-- Show config
				LeaPlusLC:Print("SynchroniseConfig: |cffffffff" .. GetCVar("synchronizeConfig"))
				-- Show raid restrictions
				local unRaid = GetAllowLowLevelRaid()
				if unRaid and unRaid == true then
					LeaPlusLC:Print("GetAllowLowLevelRaid: |cffffffff" .. "True")
				else
					LeaPlusLC:Print("GetAllowLowLevelRaid: |cffffffff" .. "False")
				end
				return
			elseif str == "tipcol" then
				-- Show default tooltip title color
				if GameTooltipTextLeft1:IsShown() then
					local r, g, b, a = GameTooltipTextLeft1:GetTextColor()
					r = r <= 1 and r >= 0 and r or 0
					g = g <= 1 and g >= 0 and g or 0
					b = b <= 1 and b >= 0 and b or 0
					LeaPlusLC:Print(L["Tooltip title color"] .. ": " .. strupper(string.format("%02x%02x%02x", r * 255, g * 255, b * 255) .. "."))
				else
					LeaPlusLC:Print("No tooltip showing.")
				end
				return
			elseif str == "list" then
				-- Enumerate frames
				local frame = EnumerateFrames()
				while frame do
					if (frame:IsVisible() and MouseIsOver(frame)) then
						LeaPlusLC:Print(frame:GetName() or string.format("[Unnamed Frame: %s]", tostring(frame)))
					end
					frame = EnumerateFrames(frame)
				end
				return
			elseif str == "grid" then
				-- Toggle frame alignment grid
				if LeaPlusLC.grid:IsShown() then LeaPlusLC.grid:Hide() else LeaPlusLC.grid:Show() end
				return
			elseif str == "chk" then
				-- List truncated checkbox labels
				if LeaPlusLC["TruncatedLabelsList"] then
					for i, v in pairs(LeaPlusLC["TruncatedLabelsList"]) do
						LeaPlusLC:Print(LeaPlusLC["TruncatedLabelsList"][i])
					end
				else
					LeaPlusLC:Print("Checkbox labels are Ok.")
				end
				return
			elseif str == "cv" then
				-- Print and set console variable setting
				if arg1 and arg1 ~= "" then
					if GetCVar(arg1) then
						if arg2 and arg2 ~= ""  then
							if tonumber(arg2) then
								SetCVar(arg1, arg2)
							else
								LeaPlusLC:Print("Value must be a number.")
								return
							end
						end
						LeaPlusLC:Print(arg1 .. ": |cffffffff" .. GetCVar(arg1))
					else
						LeaPlusLC:Print("Invalid console variable.")
					end
				else
					LeaPlusLC:Print("Missing console variable.")
				end
				return
			elseif str == "play" then
				-- Play sound ID
				if arg1 and arg1 ~= "" then
					if tonumber(arg1) then
						-- Stop last played sound ID
						if LeaPlusLC.SNDcanitHandle then
							StopSound(LeaPlusLC.SNDcanitHandle)
						end
						-- Play sound ID
						LeaPlusLC.SNDcanitPlay, LeaPlusLC.SNDcanitHandle = C_Sound.PlaySound(arg1, "Master", false, false)
						if not LeaPlusLC.SNDcanitPlay then LeaPlusLC:Print(L["Invalid sound ID"] .. ": |cffffffff" .. arg1) end
					else
						LeaPlusLC:Print(L["Invalid sound ID"] .. ": |cffffffff" .. arg1)
					end
				else
					LeaPlusLC:Print("Missing sound ID.")
				end
				return
			elseif str == "stop" then
				-- Stop last played sound ID
				if LeaPlusLC.SNDcanitHandle then
					StopSound(LeaPlusLC.SNDcanitHandle)
				end
				return
			elseif str == "wipecds" then
				-- Wipe cooldowns
				LeaPlusDB["Cooldowns"] = nil
				ReloadUI()
				return
			elseif str == "tipchat" then
				-- Print tooltip contents in chat
				local numLines = GameTooltip:NumLines()
				if numLines then
					for i = 1, numLines do
						print(_G["GameTooltipTextLeft" .. i]:GetText() or "")
					end
				end
				return
			elseif str == "tiplang" then
				-- Tooltip tag locale code constructor
				local msg = ""
				msg = msg .. 'if GameLocale == "' .. GameLocale .. '" then '
				msg = msg .. 'ttLevel = "' .. LEVEL .. '"; '
				msg = msg .. 'ttBoss = "' .. BOSS .. '"; '
				msg = msg .. 'ttElite = "' .. ELITE .. '"; '
				msg = msg .. 'ttRare = "' .. ITEM_QUALITY3_DESC .. '"; '
				msg = msg .. 'ttRareElite = "' .. ITEM_QUALITY3_DESC .. " " .. ELITE .. '"; '
				msg = msg .. 'ttRareBoss = "' .. ITEM_QUALITY3_DESC .. " " .. BOSS .. '"; '
				msg = msg .. 'ttTarget = "' .. TARGET .. '"; '
				msg = msg .. "end"
				print(msg)
				return
			elseif str == "con" then
				-- Show the developer console
				DeveloperConsole:SetFontHeight(28)
				DeveloperConsole:Toggle(true)
				return
			elseif str == "movie" then
				-- Playback movie by ID
				arg1 = tonumber(arg1)
				if arg1 and arg1 ~= "" then
					-- Play movie by ID
					if IsMoviePlayable(arg1) then
						MovieFrame_PlayMovie(MovieFrame, arg1)
					else
						LeaPlusLC:Print("Movie not playable.")
					end
				else
					-- List playable movie IDs
					local count = 0
					for i = 1, 1000 do
						if IsMoviePlayable(i) then
							print(i)
							count = count + 1
						end
					end
					LeaPlusLC:Print("Total movies: |cffffffff" .. count)
				end
				return
			elseif str == "cin" then
				-- Play opening cinematic (only works if character has never gained XP) (used for testing)
				OpeningCinematic()
				return
			elseif str == "skit" then
				-- Play a test sound kit
				C_Sound.PlaySound("1020", "Master", false, true)
				return
			elseif str == "marker" then
				-- Prevent showing raid target markers on self
				if not LeaPlusLC.MarkerFrame then
					LeaPlusLC.MarkerFrame = CreateFrame("FRAME")
					LeaPlusLC.MarkerFrame:RegisterEvent("RAID_TARGET_UPDATE")
				end
				LeaPlusLC.MarkerFrame.Update = true
				if LeaPlusLC.MarkerFrame.Toggle == false then
					-- Show markers
					LeaPlusLC.MarkerFrame:SetScript("OnEvent", nil)
					ActionStatus_DisplayMessage(L["Self Markers Allowed"], true)
					LeaPlusLC.MarkerFrame.Toggle = true
				else
					-- Hide markers
					SetRaidTarget("player", 0)
					LeaPlusLC.MarkerFrame:SetScript("OnEvent", function()
						if LeaPlusLC.MarkerFrame.Update == true then
							LeaPlusLC.MarkerFrame.Update = false
							SetRaidTarget("player", 0)
						end
						LeaPlusLC.MarkerFrame.Update = true
					end)
					ActionStatus_DisplayMessage(L["Self Markers Blocked"], true)
					LeaPlusLC.MarkerFrame.Toggle = false
				end
				return
			elseif str == "af" then
				-- Automatically follow player target using ticker
				if LeaPlusLC.followTick then
					-- Existing ticker is active so cancel it
					LeaPlusLC.followTick:Cancel()
					LeaPlusLC.followTick = nil
					FollowUnit("player")
					LeaPlusLC:Print("AutoFollow disabled.")
				else
					-- No ticker is active so create one
					local targetName, targetRealm = UnitName("target")
					if not targetName or not UnitIsPlayer("target") or UnitIsUnit("player", "target") then
						LeaPlusLC:Print("Invalid target.")
						return
					end
					if targetRealm then targetName = targetName .. "-" .. targetRealm end
					if LeaPlusLC.followTick then
						LeaPlusLC.followTick:Cancel()
					end
					FollowUnit(targetName, true)
					LeaPlusLC.followTick = C_Timer.NewTicker(0.5, function()
						FollowUnit(targetName, true)
					end)
					LeaPlusLC:Print(L["AutoFollow"] .. ": |cffffffff" .. targetName .. "|r.")
				end
				return
			elseif str == "mapid" then
				-- Print map ID
				if WorldMapFrame:IsShown() then
					-- Show world map ID
					local mapID = WorldMapFrame.mapID or nil
					local artID = C_Map.GetMapArtID(mapID) or nil
					local mapName = C_Map.GetMapInfo(mapID).name or nil
					if mapID and artID and mapName then
						LeaPlusLC:Print(mapID .. " (" .. artID .. "): " .. mapName .. " (map)")
					end
				else
					-- Show character map ID
					local mapID = C_Map.GetBestMapForUnit("player") or nil
					local artID = C_Map.GetMapArtID(mapID) or nil
					local mapName = C_Map.GetMapInfo(mapID).name or nil
					if mapID and artID and mapName then
						LeaPlusLC:Print(mapID .. " (" .. artID .. "): " .. mapName .. " (player)")
					end
				end
				return
			elseif str == "pos" then
				-- Map POI code builder
				local mapID = C_Map.GetBestMapForUnit("player") or nil
				local mapName = C_Map.GetMapInfo(mapID).name or nil
				local mapRects = {}
				local tempVec2D = CreateVector2D(0, 0)
				local void
				-- Get player map position
				tempVec2D.x, tempVec2D.y = UnitPosition("player")
				if not tempVec2D.x then return end
				local mapRect = mapRects[mapID]
				if not mapRect then
					mapRect = {}
					void, mapRect[1] = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(0, 0))
					void, mapRect[2] = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(1, 1))
					mapRect[2]:Subtract(mapRect[1])
					mapRects[mapID] = mapRect
				end
				tempVec2D:Subtract(mapRects[mapID][1])
				local pX, pY = tempVec2D.y/mapRects[mapID][2].y, tempVec2D.x/mapRects[mapID][2].x
				pX = string.format("%0.1f", 100 * pX)
				pY = string.format("%0.1f", 100 * pY)
				if mapID and mapName and pX and pY then
					ChatFrame1:Clear()
					local dnType, dnTex = "Dungeon", "dnTex"
					if arg1 == "raid" then dnType, dnTex = "Raid", "rdTex" end
					if arg1 == "portal" then dnType = "Portal" end
					print('[' .. mapID .. '] =  --[[' .. mapName .. ']] {{' .. pX .. ', ' .. pY .. ', L[' .. '"Name"' .. '], L[' .. '"' .. dnType .. '"' .. '], ' .. dnTex .. '},},')
				end
				return
			elseif str == "mapref" then
				-- Print map reveal structure code
				if not WorldMapFrame:IsShown() then
					LeaPlusLC:Print("Open the map first!")
					return
				end
				ChatFrame1:Clear()
				local msg = ""
				local mapID = WorldMapFrame.mapID
				local mapName = C_Map.GetMapInfo(mapID).name
				local mapArt = C_Map.GetMapArtID(mapID)
				msg = msg .. "--[[" .. mapName .. "]] [" .. mapArt .. "] = {"
				local exploredMapTextures = C_MapExplorationInfo.GetExploredMapTextures(mapID);
				if exploredMapTextures then
					for i, exploredTextureInfo in ipairs(exploredMapTextures) do
						local twidth = exploredTextureInfo.textureWidth or 0
						if twidth > 0 then
							local theight = exploredTextureInfo.textureHeight or 0
							local offsetx = exploredTextureInfo.offsetX
							local offsety = exploredTextureInfo.offsetY
							local filedataIDS = exploredTextureInfo.fileDataIDs
							msg = msg .. "[" .. '"' .. twidth .. ":" .. theight .. ":" .. offsetx .. ":" .. offsety .. '"' .. "] = " .. '"'
							for fileData = 1, #filedataIDS do
								msg = msg .. filedataIDS[fileData]
								if fileData < #filedataIDS then
									msg = msg .. ", "
								else
									msg = msg .. '",'
									if i < #exploredMapTextures then
										msg = msg .. " "
									end
								end
							end
						end
					end
					msg = msg .. "},"
					print(msg)
				end
				return
			elseif str == "mk" then
				-- Print a map key
				if not arg1 then LeaPlusLC:Print("Key missing!") return end
				if not tonumber(arg1) then LeaPlusLC:Print("Must be a number!") return end
				local key = arg1
				ChatFrame1:Clear()
				print('"' .. mod(floor(key / 2^36), 2^12) .. ":" .. mod(floor(key / 2^24), 2^12) .. ":" .. mod(floor(key / 2^12), 2^12) .. ":" .. mod(key, 2^12) .. '"')
				return
			elseif str == "map" then
				-- Set map by ID, print currently showing map ID or print character map ID
				if not arg1 then
					-- Print map ID
					if WorldMapFrame:IsShown() then
						-- Show world map ID
						local mapID = WorldMapFrame.mapID or nil
						local artID = C_Map.GetMapArtID(mapID) or nil
						local mapName = C_Map.GetMapInfo(mapID).name or nil
						if mapID and artID and mapName then
							LeaPlusLC:Print(mapID .. " (" .. artID .. "): " .. mapName .. " (map)")
						end
					else
						-- Show character map ID
						local mapID = C_Map.GetBestMapForUnit("player") or nil
						local artID = C_Map.GetMapArtID(mapID) or nil
						local mapName = C_Map.GetMapInfo(mapID).name or nil
						if mapID and artID and mapName then
							LeaPlusLC:Print(mapID .. " (" .. artID .. "): " .. mapName .. " (player)")
						end
					end
					return
				elseif not tonumber(arg1) or not C_Map.GetMapInfo(arg1) then
					-- Invalid map ID
					LeaPlusLC:Print("Invalid map ID.")
				else
					-- Set map by ID
					WorldMapFrame:SetMapID(tonumber(arg1))
				end
				return
			elseif str == "cls" then
				-- Clear chat frame
				ChatFrame1:Clear()
				return
			elseif str == "al" then
				-- Enable auto loot
				SetCVar("autoLootDefault", "1")
				LeaPlusLC:Print("Auto loot is now enabled.")
				return
			elseif str == "realm" then
				-- Show list of connected realms
				local titleRealm = GetRealmName()
				local userRealm = GetNormalizedRealmName()
				local connectedServers = GetAutoCompleteRealms()
				if titleRealm and userRealm and connectedServers then
					LeaPlusLC:Print(L["Connections for"] .. "|cffffffff " .. titleRealm)
					if #connectedServers > 0 then
						local count = 1
						for i = 1, #connectedServers do
							if userRealm ~= connectedServers[i] then
								LeaPlusLC:Print(count .. ".  " .. connectedServers[i])
								count = count + 1
							end
						end
					else
						LeaPlusLC:Print("None")
					end
				end
				return
			elseif str == "dup" then
				-- Print music track duplicates
				local found
				for i, e in pairs(Leatrix_Plus["ZoneList"]) do
					if Leatrix_Plus["ZoneList"][e] then
						for a, b in pairs(Leatrix_Plus["ZoneList"][e]) do
							local same = {}
							if b.tracks then
								for k, v in pairs(b.tracks) do
									if not strfind(v, "|c") then
										if tContains(same, v) then
											found = true
											print("|cffec51ff" .. L["Dup"] .. ": |r" .. e .. ": " .. b.zone .. ":", v)
										end
										tinsert(same, v)
									end
								end
							end
						end
					end
				end
				if not found then
					LeaPlusLC:Print("No media duplicates found.")
				end
				return
			elseif str == "help" then
				-- Help panel
				if not LeaPlusLC.HelpFrame then
					local frame = CreateFrame("FRAME", nil, UIParent)
					frame:SetSize(570, 340); frame:SetFrameStrata("FULLSCREEN_DIALOG"); frame:SetFrameLevel(100)
					frame.tex = frame:CreateTexture(nil, "BACKGROUND"); frame.tex:SetAllPoints(); frame.tex:SetColorTexture(0.05, 0.05, 0.05, 0.9)
					frame.close = CreateFrame("Button", nil, frame, "UIPanelCloseButton"); frame.close:SetSize(30, 30); frame.close:SetPoint("TOPRIGHT", 0, 0); frame.close:SetScript("OnClick", function() frame:Hide() end)
					frame:ClearAllPoints(); frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
					frame:SetClampedToScreen(true)
					frame:SetClampRectInsets(450, -450, -300, 300)
					frame:EnableMouse(true)
					frame:SetMovable(true)
					frame:RegisterForDrag("LeftButton")
					frame:SetScript("OnDragStart", frame.StartMoving)
					frame:SetScript("OnDragStop", function() frame:StopMovingOrSizing() frame:SetUserPlaced(false) end)
					frame:Hide()
					LeaPlusLC:CreateBar("HelpPanelMainTexture", frame, 570, 340, "TOPRIGHT", 0.7, 0.7, 0.7, 0.7,  "Interface\\ACHIEVEMENTFRAME\\UI-GuildAchievement-Parchment-Horizontal-Desaturated.png")
					-- Panel contents
					local col1, col2, color1 = 10, 120, "|cffffffaa"
					LeaPlusLC:MakeTx(frame, "Leatrix Plus Help", col1, -10)
					LeaPlusLC:MakeWD(frame, color1 .. "/ltp", col1, -30)
					LeaPlusLC:MakeWD(frame, "Toggle opttions panel.", col2, -30)
					LeaPlusLC:MakeWD(frame, color1 .. "/ltp reset", col1, -50)
					LeaPlusLC:MakeWD(frame, "Reset addon panel position and scale.", col2, -50)
					LeaPlusLC:MakeWD(frame, color1 .. "/ltp wipe", col1, -70)
					LeaPlusLC:MakeWD(frame, "Wipe all addon settings (reloads UI).", col2, -70)
					LeaPlusLC:MakeWD(frame, color1 .. "/ltp realm", col1, -90)
					LeaPlusLC:MakeWD(frame, "Show realms connected to yours.", col2, -90)
					LeaPlusLC:MakeWD(frame, color1 .. "/ltp rest", col1, -110)
					LeaPlusLC:MakeWD(frame, "Show number of rested XP bubbles remaining.", col2, -110)
					LeaPlusLC:MakeWD(frame, color1 .. "/ltp quest <id>", col1, -130)
					LeaPlusLC:MakeWD(frame, "Show quest completion status for <quest id>.", col2, -130)
					LeaPlusLC:MakeWD(frame, color1 .. "/ltp quest wipe", col1, -150)
					LeaPlusLC:MakeWD(frame, "Wipe your quest log.", col2, -150)
					LeaPlusLC:MakeWD(frame, color1 .. "/ltp grid", col1, -170)
					LeaPlusLC:MakeWD(frame, "Toggle a frame alignment grid.", col2, -170)
					LeaPlusLC:MakeWD(frame, color1 .. "/ltp zygor", col1, -190)
					LeaPlusLC:MakeWD(frame, "Toggle the Zygor addon (reloads UI).", col2, -190)
					LeaPlusLC:MakeWD(frame, color1 .. "/ltp movie <id>", col1, -210)
					LeaPlusLC:MakeWD(frame, "Play a movie by its ID.", col2, -210)
					LeaPlusLC:MakeWD(frame, color1 .. "/ltp marker", col1, -230)
					LeaPlusLC:MakeWD(frame, "Block target markers (toggle) (requires assistant or leader in raid).", col2, -230)
					LeaPlusLC:MakeWD(frame, color1 .. "/ltp rsnd", col1, -250)
					LeaPlusLC:MakeWD(frame, "Restart the sound system.", col2, -250)
					LeaPlusLC:MakeWD(frame, color1 .. "/ltp ra", col1, -270)
					LeaPlusLC:MakeWD(frame, "Announce target in General chat channel (useful for rares).", col2, -270)
					LeaPlusLC:MakeWD(frame, color1 .. "/ltp con", col1, -290)
					LeaPlusLC:MakeWD(frame, "Launch the developer console with a large font.", col2, -290)
					LeaPlusLC:MakeWD(frame, color1 .. "/rl", col1, -310)
					LeaPlusLC:MakeWD(frame, "Reload the UI.", col2, -310)
					LeaPlusLC.HelpFrame = frame
					_G["LeaPlusGlobalHelpPanel"] = frame
					table.insert(UISpecialFrames, "LeaPlusGlobalHelpPanel")
				end
				if LeaPlusLC.HelpFrame:IsShown() then LeaPlusLC.HelpFrame:Hide() else LeaPlusLC.HelpFrame:Show() end
				return
			elseif str == "ra" then
				-- Announce target name, health percentage, coordinates and map pin link in General chat channel
				local genChannel
				if GameLocale == "deDE" 	then genChannel = "Allgemein"
				elseif GameLocale == "esMX" then genChannel = "General"
				elseif GameLocale == "esES" then genChannel = "General"
				elseif GameLocale == "frFR" then genChannel = "Général"
				elseif GameLocale == "itIT" then genChannel = "Generale"
				elseif GameLocale == "ptBR" then genChannel = "Geral"
				elseif GameLocale == "ruRU" then genChannel = "Общий"
				elseif GameLocale == "koKR" then genChannel = "공개"
				elseif GameLocale == "zhCN" then genChannel = "综合"
				elseif GameLocale == "zhTW" then genChannel = "綜合"
				else							 genChannel = "General"
				end
				if genChannel then
					local index = GetChannelName(genChannel)
					if index and index > 0 then
						local mapID = C_Map.GetBestMapForUnit("player")
						local pos = C_Map.GetPlayerMapPosition(mapID, "player")
						if pos.x and pos.x ~= "0" and pos.y and pos.y ~= "0" then
							local uHealth = UnitHealth("target")
							local uHealthMax = UnitHealthMax("target")
							-- Announce in chat
							if uHealth and uHealth > 0 and uHealthMax and uHealthMax > 0 then
								-- Get unit classification (elite, rare, rare elite or boss)
								local unitType, unitTag = UnitClassification("target"), ""
								if unitType then
									if unitType == "rare" or unitType == "rareelite" then unitTag = "(" .. L["Rare"] .. ") " elseif unitType == "worldboss" then unitTag = "(" .. L["Boss"] .. ") " end
								end
								C_ChatInfo.SendChatMessage(format("%%t " .. unitTag .. "(%d%%)%s", uHealth / uHealthMax * 100, " " .. string.format("%.0f", pos.x * 100) .. ":" .. string.format("%.0f", pos.y * 100)), "CHANNEL", nil, index)
								-- C_ChatInfo.SendChatMessage(format("%%t " .. unitTag .. "(%d%%)%s", uHealth / uHealthMax * 100, " " .. string.format("%.0f", pos.x * 100) .. ":" .. string.format("%.0f", pos.y * 100)), "WHISPER", nil, GetUnitName("player")) -- Debug
							else
								LeaPlusLC:Print("Invalid target.")
							end
						else
							LeaPlusLC:Print("Cannot announce in this zone.")
						end
					else
						LeaPlusLC:Print("Cannot find General chat channel.")
					end
				end
				return
			elseif str == "perf" then
				-- Average FPS during combat
				local fTab = {}
				if not LeaPlusLC.perf then
					LeaPlusLC.perf = CreateFrame("FRAME")
				end
				local fFrm = LeaPlusLC.perf
				local k, startTime = 0, 0
				if fFrm:IsEventRegistered("PLAYER_REGEN_DISABLED") then
					fFrm:UnregisterAllEvents()
					fFrm:SetScript("OnUpdate", nil)
					LeaPlusLC:Print("PERF unloaded.")
				else
					fFrm:RegisterEvent("PLAYER_REGEN_DISABLED")
					fFrm:RegisterEvent("PLAYER_REGEN_ENABLED")
					LeaPlusLC:Print("Waiting for combat to start...")
				end
				fFrm:SetScript("OnEvent", function(self, event)
					if event == "PLAYER_REGEN_DISABLED" then
						LeaPlusLC:Print("Monitoring FPS during combat...")
						fFrm:SetScript("OnUpdate", function()
							k = k + 1
							fTab[k] = GetFramerate()
						end)
						startTime = GetTime()
					else
						fFrm:SetScript("OnUpdate", nil)
						local tSum = 0
						for i = 1, #fTab do
							tSum = tSum + fTab[i]
						end
						local timeTaken = string.format("%.0f", GetTime() - startTime)
						if tSum > 0 then
							LeaPlusLC:Print("Average FPS for " .. timeTaken .. " seconds of combat: " .. string.format("%.0f", tSum / #fTab))
						end
					end
				end)
				return
			elseif str == "col" then
				-- Convert color values
				LeaPlusLC:Print("|n")
				local r, g, b = tonumber(arg1), tonumber(arg2), tonumber(arg3)
				if r and g and b then
					-- RGB source
					LeaPlusLC:Print("Source: |cffffffff" .. r .. " " .. g .. " " .. b .. " ")
					-- RGB to Hex
					if r > 1 and g > 1 and b > 1 then
						-- RGB to Hex
						LeaPlusLC:Print("Hex: |cffffffff" .. strupper(string.format("%02x%02x%02x", r, g, b)) .. " (from RGB)")
					else
						-- Wow to Hex
						LeaPlusLC:Print("Hex: |cffffffff" .. strupper(string.format("%02x%02x%02x", r * 255, g * 255, b * 255)) .. " (from Wow)")
						-- Wow to RGB
						local rwow = string.format("%.0f", r * 255)
						local gwow = string.format("%.0f", g * 255)
						local bwow = string.format("%.0f", b * 255)
						if rwow ~= "0.0" and gwow ~= "0.0" and bwow ~= "0.0" then
							LeaPlusLC:Print("RGB: |cffffffff" .. rwow .. " " .. gwow .. " " .. bwow .. " (from Wow)")
						end
					end
					-- RGB to Wow
					local rwow = string.format("%.1f", r / 255)
					local gwow = string.format("%.1f", g / 255)
					local bwow = string.format("%.1f", b / 255)
					if rwow ~= "0.0" and gwow ~= "0.0" and bwow ~= "0.0" then
						LeaPlusLC:Print("Wow: |cffffffff" .. rwow .. " " .. gwow .. " " .. bwow)
					end
					LeaPlusLC:Print("|n")
				elseif arg1 and strlen(arg1) == 6 and strmatch(arg1,"%x") and arg2 == nil and arg3 == nil then
					-- Hex source
					local rhex, ghex, bhex = string.sub(arg1, 1, 2), string.sub(arg1, 3, 4), string.sub(arg1, 5, 6)
					if strmatch(rhex,"%x") and strmatch(ghex,"%x") and strmatch(bhex,"%x") then
						LeaPlusLC:Print("Source: |cffffffff" .. strupper(arg1))
						LeaPlusLC:Print("Wow: |cffffffff" .. string.format("%.1f", tonumber(rhex, 16) / 255) ..  "  " .. string.format("%.1f", tonumber(ghex, 16) / 255) .. "  " .. string.format("%.1f", tonumber(bhex, 16) / 255))
						LeaPlusLC:Print("RGB: |cffffffff" .. tonumber(rhex, 16) .. "  " .. tonumber(ghex, 16) .. "  " .. tonumber(bhex, 16))
					else
						LeaPlusLC:Print("Invalid arguments.")
					end
					LeaPlusLC:Print("|n")
				else
					LeaPlusLC:Print("Invalid arguments.")
				end
				return
			elseif str == "click" then
				-- Click a button (optional x number of times)
				local mouseFoci = GetMouseFoci()
				if mouseFoci then
					local frame = mouseFoci[#mouseFoci]
					local ftype = frame:GetObjectType()
					if frame and ftype and ftype == "Button" then
						if arg1 and tonumber(arg1) > 1 and tonumber(arg1) < 1000 then
							for i =1, tonumber(arg1) do C_Timer.After(0.1 * i, function() frame:Click() end) end
						else
							frame:Click()
						end
					else
						LeaPlusLC:Print("Hover the pointer over a button.")
					end
					return
				end
			elseif str == "frame" then
				-- Print frame name under mouse
				local mouseFoci = GetMouseFoci()
				if mouseFoci then
					local frame = mouseFoci[#mouseFoci]
					local ftype = frame:GetObjectType()
					if frame and ftype then
						local fname = frame:GetName()
						local issecure, tainted = issecurevariable(fname)
						if issecure then issecure = "Yes" else issecure = "No" end
						if tainted then tainted = "Yes" else tainted = "No" end
						if fname then
							LeaPlusLC:Print("Name: |cffffffff" .. fname)
							LeaPlusLC:Print("Type: |cffffffff" .. ftype)
							LeaPlusLC:Print("Secure: |cffffffff" .. issecure)
							LeaPlusLC:Print("Tainted: |cffffffff" .. tainted)
						end
					end
				end
				return
			elseif str == "arrow" then
				-- Arrow (left: drag, shift/ctrl: rotate, mouseup: loc, pointer must be on arrow stem)
				local f = CreateFrame("Frame", nil, WorldMapFrame.ScrollContainer)
				f:SetSize(64, 64)
				f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
				f:SetFrameLevel(500)
				f:SetParent(WorldMapFrame.ScrollContainer)
				f:SetScale(0.6)

				f.t = f:CreateTexture(nil, "ARTWORK")
				f.t:SetAtlas("Garr_LevelUpgradeArrow")
				f.t:SetAllPoints()

				f.f = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
				f.f:SetText("0.0")

				local x = 0
				f:SetScript("OnUpdate", function()
					if IsShiftKeyDown() then
						x = x + 0.01
						if x > 6.3 then x = 0 end
						f.t:SetRotation(x)
						f.f:SetFormattedText("%.1f", x)
					elseif IsControlKeyDown() then
						x = x - 0.01
						if x < 0 then x = 6.3 end
						f.t:SetRotation(x)
						f.f:SetFormattedText("%.1f", x)
					end
					-- Print coordinates when mouse is in right place
					local x, y = WorldMapFrame.ScrollContainer:GetNormalizedCursorPosition()
					if x and y and x > 0 and y > 0 then
						if MouseIsOver(f, -31, 31, 31, -31) then
							ChatFrame1:Clear()
							print(('{"Arrow", ' .. floor(x * 1000 + 0.5) / 10) .. ',', (floor(y * 1000 + 0.5) / 10) .. ', L["Step 1"], L["Start here."], arTex, nil, nil, nil, nil, nil, ' .. f.f:GetText() .. "},")
							PlaySoundFile(567412, "Master", false, true)
						end
					end
				end)

				f:SetMovable(true)
				f:SetScript("OnMouseDown", function(self, btn)
					if btn == "LeftButton" then
						f:StartMoving()
					end
				end)

				f:SetScript("OnMouseUp", function()
					f:StopMovingOrSizing()
					--ChatFrame1:Clear()
					--local x, y = WorldMapFrame.ScrollContainer:GetNormalizedCursorPosition()
					--if x and y and x > 0 and y > 0 and MouseIsOver(f) then
					--	print(('{"Arrow", ' .. floor(x * 1000 + 0.5) / 10) .. ',', (floor(y * 1000 + 0.5) / 10) .. ', L["Step 1"], L["Start here."], ' .. f.f:GetText() .. "},")
					--end
				end)
				return
			elseif str == "dis" then
				-- Disband group
				if not LeaPlusLC:IsInLFGQueue() and not IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
					local x = GetNumGroupMembers() or 0
					for i = x, 1, -1 do
						if GetNumGroupMembers() > 0 then
							local name = GetRaidRosterInfo(i)
							if name and name ~= UnitName("player") then
								UninviteUnit(name)
							end
						end
					end
				else
					LeaPlusLC:Print("You cannot do that while in group finder.")
				end
				return
			elseif str == "reinv" then
				-- Disband and reinvite raid
				if not LeaPlusLC:IsInLFGQueue() then
					if UnitIsGroupLeader("player") then
						-- Disband
						local groupNames = {}
						local x = GetNumGroupMembers() or 0
						for i = x, 1, -1 do
							if GetNumGroupMembers() > 0 then
								local name = GetRaidRosterInfo(i)
								if name and name ~= UnitName("player") then
									UninviteUnit(name)
									tinsert(groupNames, name)
								end
							end
						end
						-- Reinvite
						C_Timer.After(0.1, function()
							for k, v in pairs(groupNames) do
								C_PartyInfo.InviteUnit(v)
							end
						end)
					else
						LeaPlusLC:Print("You need to be group leader.")
					end
				else
					LeaPlusLC:Print("You cannot do that while in group finder.")
				end
				return
			elseif str == "limit" then
				-- Sound Limit
				if not LeaPlusLC.MuteFrame then
					-- Panel frame
					local frame = CreateFrame("FRAME", nil, UIParent)
					frame:SetSize(294, 86); frame:SetFrameStrata("FULLSCREEN_DIALOG"); frame:SetFrameLevel(100); frame:SetScale(2)
					frame.tex = frame:CreateTexture(nil, "BACKGROUND"); frame.tex:SetAllPoints(); frame.tex:SetColorTexture(0.05, 0.05, 0.05, 0.9)
					frame.close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
					frame.close:SetSize(30, 30)
					frame.close:SetPoint("TOPRIGHT", 0, 0)
					frame.close:SetScript("OnClick", function() frame:Hide() end)
					frame:ClearAllPoints(); frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
					frame:SetClampedToScreen(true)
					frame:EnableMouse(true)
					frame:SetMovable(true)
					frame:RegisterForDrag("LeftButton")
					frame:SetScript("OnDragStart", frame.StartMoving)
					frame:SetScript("OnDragStop", function() frame:StopMovingOrSizing() frame:SetUserPlaced(false) end)
					frame:Hide()
					LeaPlusLC:CreateBar("MutePanelMainTexture", frame, 294, 86, "TOPRIGHT", 0.7, 0.7, 0.7, 0.7,  "Interface\\ACHIEVEMENTFRAME\\UI-GuildAchievement-Parchment-Horizontal-Desaturated.png")
					-- Panel contents
					LeaPlusLC:MakeTx(frame, "Sound Limit", 16, -12)
					local endBox = LeaPlusLC:CreateEditBox("SoundEndBox", frame, 116, 10, "TOPLEFT", 16, -32, "SoundEndBox", "SoundEndBox")
					endBox:SetText(9000000)
					endBox:SetScript("OnMouseWheel", function(self, delta)
						local endSound = tonumber(endBox:GetText())
						if endSound then
							if delta == 1 then endSound = endSound + LeaPlusLC.SoundByte else endSound = endSound - LeaPlusLC.SoundByte end
							if endSound < 1 then endSound = 1 elseif endSound >= 9000000 then endSound = 9000000 end
							endBox:SetText(endSound)
						else
							endSound = 100000
							endBox:SetText(endSound)
						end
					end)
					-- Set limit button
					frame.btn = LeaPlusLC:CreateButton("muteRangeButton", frame, "SET LIMIT", "TOPLEFT", 16, -72, 0, 25, true, "Click to set the sound file limit.  Use the mousewheel on the editbox along with the step buttons below to adjust the sound limit.  Acceptable range is from 1 to 9000000.  Sound files higher than this limit will be muted.")
					frame.btn:ClearAllPoints()
					frame.btn:SetPoint("LEFT", endBox, "RIGHT", 10, 0)
					frame.btn:SetScript("OnClick", function()
						local endSound = tonumber(endBox:GetText())
						if endSound then
							if endSound > 9000000 then endSound = 9000000 endBox:SetText(endSound) end
							frame.btn:SetText("WAIT")
							C_Timer.After(0.1, function()
								for i = 1, 9000000 do
									MuteSoundFile(i)
								end
								for i = 1, endSound do
									UnmuteSoundFile(i)
								end
								Sound_GameSystem_RestartSoundSystem()
								frame.btn:SetText("SET LIMIT")
							end)
						else
							frame.btn:SetText("INVALID")
							frame.btn:EnableMouse(false)
							C_Timer.After(2, function()
								frame.btn:SetText("SET LIMIT")
								frame.btn:EnableMouse(true)
							end)
						end
					end)
					-- Mute all button
					frame.MuteAllBtn = LeaPlusLC:CreateButton("muteMuteAllButton", frame, "MUTE ALL", "TOPLEFT", 16, -92, 0, 25, true, "Click to mute every sound in the game.")
					frame.MuteAllBtn:SetScale(0.5)
					frame.MuteAllBtn:ClearAllPoints()
					frame.MuteAllBtn:SetPoint("TOPLEFT", frame.btn, "TOPRIGHT", 20, 0)
					frame.MuteAllBtn:SetScript("OnClick", function()
						frame.MuteAllBtn:SetText("WAIT")
						C_Timer.After(0.1, function()
							for i = 1, 9000000 do
								MuteSoundFile(i)
							end
							Sound_GameSystem_RestartSoundSystem()
							frame.MuteAllBtn:SetText("MUTE ALL")
						end)
						return
					end)
					-- Unmute all button
					frame.UnmuteAllBtn = LeaPlusLC:CreateButton("muteUnmuteAllButton", frame, "UNMUTE ALL", "TOPLEFT", 16, -92, 0, 25, true, "Click to unmute every sound in the game.")
					frame.UnmuteAllBtn:SetScale(0.5)
					frame.UnmuteAllBtn:ClearAllPoints()
					frame.UnmuteAllBtn:SetPoint("TOPLEFT", frame.MuteAllBtn, "BOTTOMLEFT", 0, -10)
					frame.UnmuteAllBtn:SetScript("OnClick", function()
						frame.UnmuteAllBtn:SetText("WAIT")
						C_Timer.After(0.1, function()
							for i = 1, 9000000 do
								UnmuteSoundFile(i)
							end
							Sound_GameSystem_RestartSoundSystem()
							frame.UnmuteAllBtn:SetText("UNMUTE ALL")
						end)
						return
					end)
					-- Step buttons
					frame.millionBtn = LeaPlusLC:CreateButton("SoundMillionButton", frame, "1000000", "TOPLEFT", 26, -122, 0, 25, true, "Set the editbox step value to 1000000.")
					frame.millionBtn:SetScale(0.5)

					frame.hundredThousandBtn = LeaPlusLC:CreateButton("SoundHundredThousandButton", frame, "100000", "TOPLEFT", 16, -112, 0, 25, true, "Set the editbox step value to 100000.")
					frame.hundredThousandBtn:ClearAllPoints()
					frame.hundredThousandBtn:SetPoint("LEFT", frame.millionBtn, "RIGHT", 10, 0)
					frame.hundredThousandBtn:SetScale(0.5)

					frame.tenThousandBtn = LeaPlusLC:CreateButton("SoundTenThousandButton", frame, "10000", "TOPLEFT", 16, -112, 0, 25, true, "Set the editbox step value to 10000.")
					frame.tenThousandBtn:ClearAllPoints()
					frame.tenThousandBtn:SetPoint("LEFT", frame.hundredThousandBtn, "RIGHT", 10, 0)
					frame.tenThousandBtn:SetScale(0.5)

					frame.thousandBtn = LeaPlusLC:CreateButton("SoundThousandButton", frame, "1000", "TOPLEFT", 16, -112, 0, 25, true, "Set the editbox step value to 1000.")
					frame.thousandBtn:ClearAllPoints()
					frame.thousandBtn:SetPoint("LEFT", frame.tenThousandBtn, "RIGHT", 10, 0)
					frame.thousandBtn:SetScale(0.5)

					frame.hundredBtn = LeaPlusLC:CreateButton("SoundHundredButton", frame, "100", "TOPLEFT", 16, -112, 0, 25, true, "Set the editbox step value to 100.")
					frame.hundredBtn:ClearAllPoints()
					frame.hundredBtn:SetPoint("LEFT", frame.thousandBtn, "RIGHT", 10, 0)
					frame.hundredBtn:SetScale(0.5)

					frame.tenBtn = LeaPlusLC:CreateButton("SoundTenButton", frame, "10", "TOPLEFT", 16, -112, 0, 25, true, "Set the editbox step value to 10.")
					frame.tenBtn:ClearAllPoints()
					frame.tenBtn:SetPoint("LEFT", frame.hundredBtn, "RIGHT", 10, 0)
					frame.tenBtn:SetScale(0.5)

					frame.oneBtn = LeaPlusLC:CreateButton("SoundTenButton", frame, "1", "TOPLEFT", 16, -112, 0, 25, true, "Set the editbox step value to 1.")
					frame.oneBtn:ClearAllPoints()
					frame.oneBtn:SetPoint("LEFT", frame.tenBtn, "RIGHT", 10, 0)
					frame.oneBtn:SetScale(0.5)

					local function DimAllBoxes()
						frame.millionBtn:SetAlpha(0.3)
						frame.hundredThousandBtn:SetAlpha(0.3)
						frame.tenThousandBtn:SetAlpha(0.3)
						frame.thousandBtn:SetAlpha(0.3)
						frame.hundredBtn:SetAlpha(0.3)
						frame.tenBtn:SetAlpha(0.3)
						frame.oneBtn:SetAlpha(0.3)
					end

					LeaPlusLC.SoundByte = 1000000
					DimAllBoxes()
					frame.millionBtn:SetAlpha(1)

					-- Step button handlers
					frame.millionBtn:SetScript("OnClick", function()
						LeaPlusLC.SoundByte = 1000000
						DimAllBoxes()
						frame.millionBtn:SetAlpha(1)
					end)

					frame.hundredThousandBtn:SetScript("OnClick", function()
						LeaPlusLC.SoundByte = 100000
						DimAllBoxes()
						frame.hundredThousandBtn:SetAlpha(1)
					end)

					frame.tenThousandBtn:SetScript("OnClick", function()
						LeaPlusLC.SoundByte = 10000
						DimAllBoxes()
						frame.tenThousandBtn:SetAlpha(1)
					end)

					frame.thousandBtn:SetScript("OnClick", function()
						LeaPlusLC.SoundByte = 1000
						DimAllBoxes()
						frame.thousandBtn:SetAlpha(1)
					end)

					frame.hundredBtn:SetScript("OnClick", function()
						LeaPlusLC.SoundByte = 100
						DimAllBoxes()
						frame.hundredBtn:SetAlpha(1)
					end)

					frame.tenBtn:SetScript("OnClick", function()
						LeaPlusLC.SoundByte = 10
						DimAllBoxes()
						frame.tenBtn:SetAlpha(1)
					end)

					frame.oneBtn:SetScript("OnClick", function()
						LeaPlusLC.SoundByte = 1
						DimAllBoxes()
						frame.oneBtn:SetAlpha(1)
					end)

					-- Final code
					LeaPlusLC.MuteFrame = frame
					_G["LeaPlusGlobalMutePanel"] = frame
					table.insert(UISpecialFrames, "LeaPlusGlobalMutePanel")
				end
				if LeaPlusLC.MuteFrame:IsShown() then LeaPlusLC.MuteFrame:Hide() else LeaPlusLC.MuteFrame:Show() end
				return
			elseif str == "mem" or str == "m" then
				-- Show addon panel with memory usage
				if LeaPlusLC.ShowMemoryUsage then
					LeaPlusLC:ShowMemoryUsage(LeaPlusLC["Page8"], "TOPLEFT", 146, -262)
				end
				-- Prevent options panel from showing if a chat configuration panel is showing
				if ChatConfigFrame:IsShown() then return end
				-- Prevent options panel from showing if Blizzard Store is showing
				if StoreFrame and StoreFrame:GetAttribute("isshown") then return end
				-- Toggle the options panel if game options panel is not showing
				if LeaPlusLC:IsPlusShowing() then
					LeaPlusLC:HideFrames()
					LeaPlusLC:HideConfigPanels()
				else
					LeaPlusLC:HideFrames()
					LeaPlusLC["PageF"]:Show()
				end
				LeaPlusLC["Page"..LeaPlusLC["LeaStartPage"]]:Show()
				return
			elseif str == "gossinfo" then
				-- Print gossip frame information
				if GossipFrame:IsShown() then
					local npcName = UnitName("npc")
					local npcGuid = UnitGUID("npc") or nil
					if npcName and npcGuid then
						local void, void, void, void, void, npcID = strsplit("-", npcGuid)
						if npcID then
							LeaPlusLC:Print(npcName .. ": |cffffffff" .. npcID)
						end
					end
					LeaPlusLC:Print("Available quests: |cffffffff" .. C_GossipInfo.GetNumAvailableQuests())
					LeaPlusLC:Print("Active quests: |cffffffff" .. C_GossipInfo.GetNumActiveQuests())
					local gossipInfoTable = C_GossipInfo.GetOptions()
					if gossipInfoTable and gossipInfoTable[1] and gossipInfoTable[1].name then
						LeaPlusLC:Print("Gossip count: |cffffffff" .. #gossipInfoTable)
						LeaPlusLC:Print("Gossip name: |cffffffff" .. gossipInfoTable[1].name)
					else
						LeaPlusLC:Print("Gossip info: |cffffffff" .. "Nil")
					end
					if GossipTitleButton1 and GossipTitleButton1:GetText() then
						LeaPlusLC:Print("First option: |cffffffff" .. GossipTitleButton1:GetText())
					end
					-- LeaPlusLC:Print("Gossip text: |cffffffff" .. GetGossipText())
					if not IsShiftKeyDown() then
						SelectGossipOption(1)
					end
				else
					LeaPlusLC:Print("Gossip frame not open.")
				end
				return
			elseif str == "svars" then
				-- Print saved variables
				LeaPlusLC:Print(L["Saved Variables"] .. "|n")
				LeaPlusLC:Print(L["The following list shows option label, setting name and currently saved value.  Enable |cffffffffIncrease chat history|r (chat) and |cffffffffRecent chat window|r (chat) to make it easier."] .. "|n")
				LeaPlusLC:Print(L["Modifying saved variables must start with |cffffffff/ltp nosave|r to prevent your changes from being reverted during reload or logout."] .. "|n")
				LeaPlusLC:Print(L['Syntax is |cffffffff/run LeaPlusDB[' .. '"' .. 'setting name' .. '"' .. '] = ' .. '"' .. 'value' .. '" |r(case sensitive).'])
				LeaPlusLC:Print(L["When done, |cffffffff/reload|r to save your changes."] .. "|n")
				-- Checkboxes
				LeaPlusLC:Print(L["Checkboxes"] .. "|n")
				LeaPlusLC:Print(L["Checkboxes can be set to On or Off."] .. "|n")
				for key, value in pairs(LeaPlusDB) do
					if LeaPlusCB[key] and LeaPlusCB[key].f then
						if LeaPlusCB[key]:GetObjectType() ~= "Slider" and LeaPlusCB[key]:GetObjectType() ~= "Button" then
							LeaPlusLC:Print(string.gsub(LeaPlusCB[key].f:GetText(), "%*$", "") .. ": |cffffffff" .. key .. "|r |cff1eff0c(" .. value .. ")|r")
						end
					end
				end
				-- Sliders
				LeaPlusLC:Print("|n" .. L["Sliders"] .. "|n")
				LeaPlusLC:Print(L["Sliders can be set to a numeric value which must be in the range supported by the slider."] .. "|n")
				for key, value in pairs(LeaPlusDB) do
					if LeaPlusCB[key] and LeaPlusCB[key].f then
						if LeaPlusCB[key]:GetObjectType() == "Slider" then
							LeaPlusLC:Print("Slider: " .. "|cffffffff" .. key .. "|r |cff1eff0c(" .. value .. ")|r" .. " (" .. string.gsub(LeaPlusCB[key].f:GetText(), "%*$", "") .. ")" )
						end
					end
				end
				-- Dropdowns
				LeaPlusLC:Print("|n" .. L["Dropdowns"] .. "|n")
				LeaPlusLC:Print(L["Dropdowns can be set to a numeric value which must be in the range supported by the dropdown."] .. "|n")
				for key, value in pairs(LeaPlusDB) do
					if LeaPlusCB[key] and LeaPlusCB[key]:GetObjectType() == "Button" and LeaPlusLC[key] then
						LeaPlusLC:Print("Dropdown: " .. "|cffffffff" .. key .. "|r |cff1eff0c(" .. value .. ")|r")
					end
				end
				return
			elseif str == "tags" then
				-- Print open menu tags (such as dropdown menus)
				Menu.PrintOpenMenuTags()
				return
			elseif str == "taintmap" then
				-- TaintMap
				if LeaPlusLC.TaintMap then
					LeaPlusLC.TaintMap:Cancel()
					LeaPlusLC.TaintMap = nil
					LeaPlusLC:Print("TaintMap stopped.")
					return
				end
				LeaPlusLC.TaintMap = C_Timer.NewTicker(1, function()
					for k,v in pairs(WorldMapFrame) do
						local ok, who = issecurevariable(WorldMapFrame, k)
						if not ok then
							print("Tainted:", k, "by", who or "unknown")
						end
					end
				end)
				LeaPlusLC:Print("TaintMap started.")
				return
			elseif str == "guildinfo" then
				-- Print guild roster
				C_Timer.After(0, function()
					local str = ""
					C_FriendList.ShowFriends()
					local gCount = GetNumGuildMembers()
					for i = 1, gCount do
						local gName, void, void, void, void, void, void, void, gOnline, void, void, void, void, gMobile, void, void, gGUID = GetGuildRosterInfo(i)
						gName = strsplit("-", gName, 2)
						if gMobile then gMobile = "TRUE" else gMobile = "FALSE" end
						if gOnline then gOnline = "TRUE" else gOnline = "FALSE" end
						str = str .. i .. " " ..  gName .. " " .. gOnline .. " " .. gMobile .. " " .. gGUID .. "|n"
					end
					print(str)
				end)
				return
			elseif str == "checkglobal" then
				-- Print global frame names created by the addon
				local c = 0
				for k, v in pairs(_G) do
					if type(k) == "string" and type(v) == "table" then
						local void, a = issecurevariable(k)
						if a == "Leatrix_Plus" then
							c = c + 1
							print(k)
						end
					end
				end
				print(c,"global tables/frames")
				return
			elseif str == "admin" then
				-- Preset profile (used for testing)
				LpEvt:UnregisterAllEvents()						-- Prevent changes
				wipe(LeaPlusDB)									-- Wipe settings
				LeaPlusLC:PlayerLogout(true)					-- Reset permanent settings
				-- Automation
				LeaPlusDB["AutomateQuests"] = "On"				-- Automate quests
				LeaPlusDB["AutoQuestShift"] = "Off"				-- Automate quests requires shift
				LeaPlusDB["AutoQuestAvailable"] = "On"			-- Accept available quests
				LeaPlusDB["AutoQuestCompleted"] = "On"			-- Turn-in completed quests
				LeaPlusDB["AutoQuestKeyMenu"] = 1				-- Automate quests override key
				LeaPlusDB["AutomateGossip"] = "On"				-- Automate gossip
				LeaPlusDB["AutoAcceptSummon"] = "On"			-- Accept summon
				LeaPlusDB["AutoAcceptRes"] = "On"				-- Accept resurrection
				LeaPlusDB["AutoReleasePvP"] = "On"				-- Release in PvP
				LeaPlusDB["AutoSellJunk"] = "On"				-- Sell junk automatically
				LeaPlusDB["AutoSellExcludeList"] = ""			-- Sell junk exclusions list
				LeaPlusDB["AutoRepairGear"] = "On"				-- Repair automatically

				-- Social
				LeaPlusDB["NoDuelRequests"] = "On"				-- Block duels
				LeaPlusDB["NoPartyInvites"] = "Off"				-- Block party invites
				LeaPlusDB["NoFriendRequests"] = "Off"			-- Block friend requests
				LeaPlusDB["NoSharedQuests"] = "Off"				-- Block shared quests

				LeaPlusDB["AcceptPartyFriends"] = "On"			-- Party from friends
				LeaPlusDB["InviteFromWhisper"] = "On"			-- Invite from whispers
				LeaPlusDB["InviteFriendsOnly"] = "On"			-- Restrict invites to friends
				LeaPlusDB["FriendlyGuild"] = "On"				-- Friendly guild

				-- Chat
				LeaPlusDB["UseEasyChatResizing"] = "On"			-- Use easy resizing
				LeaPlusDB["NoCombatLogTab"] = "On"				-- Hide the combat log
				LeaPlusDB["NoChatButtons"] = "On"				-- Hide chat buttons
				LeaPlusDB["UnclampChat"] = "On"					-- Unclamp chat frame
				LeaPlusDB["MoveChatEditBoxToTop"] = "On"		-- Move editbox to top
				LeaPlusDB["MoreChatFontSizes"] = "On"			-- More chat font sizes

				LeaPlusDB["NoStickyChat"] = "On"				-- Disable sticky chat
				LeaPlusDB["UseArrowKeysInChat"] = "On"			-- Use arrow keys in chat
				LeaPlusDB["NoChatFade"] = "On"					-- Disable chat fade
				LeaPlusDB["UnivGroupColor"] = "On"				-- Universal group color
				LeaPlusDB["ClassColorsInChat"] = "On"			-- Use class colors in chat
				LeaPlusDB["RecentChatWindow"] = "On"			-- Recent chat window
				LeaPlusDB["RecentChatSize"] = 170				-- Recent chat size
				LeaPlusDB["MaxChatHstory"] = "Off"				-- Increase chat history
				LeaPlusDB["FilterChatMessages"] = "On"			-- Filter chat messages
				LeaPlusDB["BlockSpellLinks"] = "On"				-- Block spell links
				LeaPlusDB["BlockDrunkenSpam"] = "On"			-- Block drunken spam
				LeaPlusDB["BlockDuelSpam"] = "On"				-- Block duel spam
				LeaPlusDB["RestoreChatMessages"] = "On"			-- Restore chat messages

				-- Text
				LeaPlusDB["HideErrorMessages"] = "On"			-- Hide error messages
				LeaPlusDB["NoHitIndicators"] = "On"				-- Hide portrait text
				LeaPlusDB["HideKeybindText"] = "On"				-- Hide keybind text
				LeaPlusDB["HideMacroText"] = "On"				-- Hide macro text
				LeaPlusDB["HideRaidGroupLabels"] = "On"			-- Hide raid group labels

				LeaPlusDB["MailFontChange"] = "On"				-- Resize mail text
				LeaPlusDB["LeaPlusMailFontSize"] = 22			-- Mail font size
				LeaPlusDB["QuestFontChange"] = "On"				-- Resize quest text
				LeaPlusDB["LeaPlusQuestFontSize"] = 18			-- Quest font size
				LeaPlusDB["BookFontChange"] = "On"				-- Resize book text
				LeaPlusDB["LeaPlusBookFontSize"] = 22			-- Book font size

				-- Interface
				LeaPlusDB["MinimapModder"] = "On"				-- Enhance minimap
				LeaPlusDB["SquareMinimap"] = "On"				-- Square minimap
				LeaPlusDB["MinimapButtonBag"] = "Off"			-- Minimap button bag
				LeaPlusDB["MiniExcludeList"] = "BugSack, Leatrix_Plus" -- Excluded addon list
				LeaPlusDB["MinimapSize"] = 180					-- Minimap size slider
				LeaPlusDB["MinimapBorderWidth"] = 3				-- Minimap border width
				LeaPlusDB["HideMiniZoneText"] = "On"			-- Hide zone text bar
				LeaPlusDB["HideMiniTracking"] = "On"			-- Hide tracking button
				LeaPlusDB["HideMiniLFG"] = "On"					-- Hide the Looking for Group button
				LeaPlusDB["MinimapEffect"] = 1					-- Minimap effect

				LeaPlusDB["TipModEnable"] = "On"				-- Enhance tooltip
				LeaPlusDB["LeaPlusTipSize"] = 1.25				-- Tooltip scale slider
				LeaPlusDB["TooltipAnchorMenu"] = 2				-- Tooltip anchor
				LeaPlusDB["TipCursorX"] = 0						-- X offset
				LeaPlusDB["TipCursorY"] = 0						-- Y offset
				LeaPlusDB["EnhanceDressup"] = "On"				-- Enhance dressup
				LeaPlusDB["HideDressupStats"] = "On"			-- Hide dressup stats
				LeaPlusDB["EnhanceQuestLog"] = "On"				-- Enhance quest log
				LeaPlusDB["EnhanceQuestTaller"] = "On"			-- Enhance quest log taller
				LeaPlusDB["EnhanceQuestLevels"] = "On"			-- Enhance quest log quest levels
				LeaPlusDB["EnhanceQuestDifficulty"] = "On"		-- Enhance quest log quest difficulty
				LeaPlusDB["EnhanceProfessions"] = "On"			-- Enhance professions
				LeaPlusDB["EnhanceTrainers"] = "On"				-- Enhance trainers
				LeaPlusDB["ShowTrainAllBtn"] = "On"				-- Show train all button
				LeaPlusDB["EnhanceFlightMap"] = "On"			-- Enhance flight map
				LeaPlusDB["LeaPlusTaxiMapScale"] = 1.9			-- Enhance flight map scale
				LeaPlusDB["LeaPlusTaxiIconSize"] = 10			-- Enhance flight icon size
				LeaPlusDB["FlightMapA"] = "TOPLEFT"				-- Enhance flight map anchor
				LeaPlusDB["FlightMapR"] = "TOPLEFT"				-- Enhance flight map relative
				LeaPlusDB["FlightMapX"] = 0						-- Enhance flight map X
				LeaPlusDB["FlightMapX"] = 61					-- Enhance flight map Y

				LeaPlusDB["ShowVolume"] = "On"					-- Show volume slider
				LeaPlusDB["AhExtras"] = "On"					-- Show auction controls
				LeaPlusDB["ShowCooldowns"] = "On"				-- Show cooldowns
				LeaPlusDB["DurabilityStatus"] = "On"			-- Show durability status
				LeaPlusDB["ShowVanityControls"] = "On"			-- Show vanity controls
				LeaPlusDB["ShowBagSearchBox"] = "On"			-- Show bag search box
				LeaPlusDB["ShowFreeBagSlots"] = "On"			-- Show free bag slots
				LeaPlusDB["ShowRaidToggle"] = "On"				-- Show raid button
				LeaPlusDB["ShowBorders"] = "On"					-- Show borders
				LeaPlusDB["ShowPlayerChain"] = "On"				-- Show player chain
				LeaPlusDB["PlayerChainMenu"] = 3				-- Player chain style
				LeaPlusDB["ShowReadyTimer"] = "On"				-- Show ready timer
				LeaPlusDB["ShowDruidPowerBar"] = "On"			-- Show druid power bar
				LeaPlusDB["ShowDruidStatusText"] = "On"			-- Show druid power bar status text
				LeaPlusDB["ShowRangeColoring"] = "On"			-- Show range coloring
				LeaPlusDB["ShowInfoCards"] = "On"				-- Show info cards
				LeaPlusDB["InfoCardKey"] = "CTRL-A"				-- Info card key
				LeaPlusDB["ShowWowheadLinks"] = "On"			-- Show Wowhead links
				LeaPlusDB["WowheadLinkComments"] = "On"			-- Show Wowhead links to comments

				-- Frames
				LeaPlusDB["ManageWidget"] = "On"				-- Manage widget
				LeaPlusDB["WidgetA"] = "TOP"					-- Manage widget anchor
				LeaPlusDB["WidgetR"] = "TOP"					-- Manage widget relative
				LeaPlusDB["WidgetX"] = 0						-- Manage widget position X
				LeaPlusDB["WidgetY"] = -432						-- Manage widget position Y
				LeaPlusDB["WidgetScale"] = 1.25					-- Manage widget scale

				LeaPlusDB["ManageTimer"] = "On"					-- Manage timer
				LeaPlusDB["TimerA"] = "TOP"						-- Manage timer anchor
				LeaPlusDB["TimerR"] = "TOP"						-- Manage timer relative
				LeaPlusDB["TimerX"] = 0							-- Manage timer position X
				LeaPlusDB["TimerY"] = -120						-- Manage timer position Y
				LeaPlusDB["TimerScale"] = 1.00					-- Manage timer scale

				LeaPlusDB["ClassColFrames"] = "On"				-- Class colored frames

				LeaPlusDB["NoGryphons"] = "On"					-- Hide gryphons
				LeaPlusDB["NoClassBar"] = "On"					-- Hide stance bar

				-- System
				LeaPlusDB["NoScreenGlow"] = "On"				-- Disable screen glow
				LeaPlusDB["NoScreenEffects"] = "On"				-- Disable screen effects
				LeaPlusDB["SetWeatherDensity"] = "On"			-- Set weather density
				LeaPlusDB["WeatherLevel"] = 0					-- Weather density level
				LeaPlusDB["MaxCameraZoom"] = "On"				-- Max camera zoom
				LeaPlusDB["NoRestedEmotes"] = "On"				-- Silence rested emotes
				LeaPlusDB["KeepAudioSynced"] = "On"				-- Keep audio synced
				LeaPlusDB["MuteGameSounds"] = "On"				-- Mute game sounds
				LeaPlusDB["MuteCustomSounds"] = "On"			-- Mute custom sounds
				LeaPlusDB["MuteCustomList"] = ""				-- Mute custom sounds list

				LeaPlusDB["NoBagAutomation"] = "On"				-- Disable bag automation
				LeaPlusDB["NoConfirmLoot"] = "On"				-- Disable loot warnings
				LeaPlusDB["FasterLooting"] = "On"				-- Faster auto loot
				LeaPlusDB["FasterMovieSkip"] = "On"				-- Faster movie skip
				LeaPlusDB["StandAndDismount"] = "On"			-- Dismount me
				LeaPlusDB["ShowVendorPrice"] = "On"				-- Show vendor price
				LeaPlusDB["CombatPlates"] = "On"				-- Combat plates
				LeaPlusDB["EasyItemDestroy"] = "On"				-- Easy item destroy

				LeaPlusDB["ShowFlightTimes"] = "On"				-- Show flight times
				LeaPlusDB["FlightBarBackground"] = "Off"		-- Show flight times bar background
				LeaPlusDB["FlightBarDestination"] = "On"		-- Show flight times bar destination
				LeaPlusDB["FlightBarFillBar"] = "Off"			-- Show flight times bar fill mode
				LeaPlusDB["FlightBarSpeech"] = "On"				-- Show flight times bar speech
				LeaPlusDB["FlightBarContribute"] = "On"			-- Show flight times contribute

				-- Settings
				LeaPlusDB["SetEditModeLayout"] = "On"			-- Set edit mode layout
				LeaPlusDB["EditModeLayoutName"] = "Main"		-- Edit mode layout name
				LeaPlusDB["SimpleAddonListing"] = "On"			-- Simple addon listing

				-- Function to assign cooldowns
				local function setIcon(pclass, pspec, sp1, pt1, sp2, pt2, sp3, pt3, sp4, pt4, sp5, pt5)
					-- Set spell ID
					if sp1 == 0 then LeaPlusDB["Cooldowns"][pclass]["S" .. pspec .. "R1Idn"] = "" else LeaPlusDB["Cooldowns"][pclass]["S" .. pspec .. "R1Idn"] = sp1 end
					if sp2 == 0 then LeaPlusDB["Cooldowns"][pclass]["S" .. pspec .. "R2Idn"] = "" else LeaPlusDB["Cooldowns"][pclass]["S" .. pspec .. "R2Idn"] = sp2 end
					if sp3 == 0 then LeaPlusDB["Cooldowns"][pclass]["S" .. pspec .. "R3Idn"] = "" else LeaPlusDB["Cooldowns"][pclass]["S" .. pspec .. "R3Idn"] = sp3 end
					if sp4 == 0 then LeaPlusDB["Cooldowns"][pclass]["S" .. pspec .. "R4Idn"] = "" else LeaPlusDB["Cooldowns"][pclass]["S" .. pspec .. "R4Idn"] = sp4 end
					if sp5 == 0 then LeaPlusDB["Cooldowns"][pclass]["S" .. pspec .. "R5Idn"] = "" else LeaPlusDB["Cooldowns"][pclass]["S" .. pspec .. "R5Idn"] = sp5 end
					-- Set pet checkbox
					if pt1 == 0 then LeaPlusDB["Cooldowns"][pclass]["S" .. pspec .. "R1Pet"] = false else LeaPlusDB["Cooldowns"][pclass]["S" .. pspec .. "R1Pet"] = true end
					if pt2 == 0 then LeaPlusDB["Cooldowns"][pclass]["S" .. pspec .. "R2Pet"] = false else LeaPlusDB["Cooldowns"][pclass]["S" .. pspec .. "R2Pet"] = true end
					if pt3 == 0 then LeaPlusDB["Cooldowns"][pclass]["S" .. pspec .. "R3Pet"] = false else LeaPlusDB["Cooldowns"][pclass]["S" .. pspec .. "R3Pet"] = true end
					if pt4 == 0 then LeaPlusDB["Cooldowns"][pclass]["S" .. pspec .. "R4Pet"] = false else LeaPlusDB["Cooldowns"][pclass]["S" .. pspec .. "R4Pet"] = true end
					if pt5 == 0 then LeaPlusDB["Cooldowns"][pclass]["S" .. pspec .. "R5Pet"] = false else LeaPlusDB["Cooldowns"][pclass]["S" .. pspec .. "R5Pet"] = true end
				end

				-- Create main table
				LeaPlusDB["Cooldowns"] = {}

				-- Create class tables
				local classList = {"WARRIOR", "PALADIN", "HUNTER", "SHAMAN", "ROGUE", "DRUID", "MAGE", "WARLOCK", "PRIEST"}
				for index = 1, #classList do
					if LeaPlusDB["Cooldowns"][classList[index]] == nil then
						LeaPlusDB["Cooldowns"][classList[index]] = {}
					end
				end

				-- Assign cooldowns
				setIcon("WARRIOR", 		1, --[[1]] 0, 0, 		--[[2]] 0, 0, 		--[[3]] 0, 0, 		--[[4]] 0, 0, 		--[[5]] 0, 0)
				setIcon("PALADIN", 		1, --[[1]] 0, 0, 		--[[2]] 0, 0, 		--[[3]] 0, 0, 		--[[4]] 0, 0, 		--[[5]] 19740, 0) -- nil, nil, nil, nil, Might
				setIcon("HUNTER", 		1, --[[1]] 136, 1, 		--[[2]] 118455, 1, 	--[[3]] 0, 0, 		--[[4]] 0, 0, 		--[[5]] 5384, 0) -- Mend Pet, nil, nil, nil, Feign Death
				setIcon("SHAMAN", 		1, --[[1]] 0, 0, 		--[[2]] 0, 0, 		--[[3]] 0, 0, 		--[[4]] 215864, 0, 	--[[5]] 546, 0) -- nil, nil, nil, Rainfall, Water Walking
				setIcon("ROGUE", 		1, --[[1]] 1784, 0, 	--[[2]] 0, 0, 		--[[3]] 0, 0, 		--[[4]] 2823, 0, 	--[[5]] 3408, 0) -- Stealth, nil, nil, Deadly Poison, Crippling Poison
				setIcon("DRUID", 		1, --[[1]] 0, 0, 		--[[2]] 0, 0, 		--[[3]] 0, 0, 		--[[4]] 0, 0, 		--[[5]] 0, 0)
				setIcon("MAGE", 		1, --[[1]] 235450, 0, 	--[[2]] 0, 0, 		--[[3]] 0, 0, 		--[[4]] 0, 0, 		--[[5]] 0, 0) -- Prismatic Barrier
				setIcon("WARLOCK", 		1, --[[1]] 0, 0, 		--[[2]] 0, 0, 		--[[3]] 0, 0, 		--[[4]] 0, 0, 		--[[5]] 0, 0)
				setIcon("PRIEST", 		1, --[[1]] 17, 0, 		--[[2]] 0, 0, 		--[[3]] 0, 0, 		--[[4]] 0, 0, 		--[[5]] 0, 0) -- Power Word: Shield

				-- Mute game sounds (LeaPlusLC["MuteGameSounds"])
				for k, v in pairs(LeaPlusLC["muteTable"]) do
					LeaPlusDB[k] = "On"
				end
				LeaPlusDB["MuteReady"] = "Off"	-- Mute ready check

				-- Mute mount sounds (LeaPlusLC["MuteMountSounds"])
				for k, v in pairs(LeaPlusLC["mountTable"]) do
					LeaPlusDB[k] = "On"
				end

				-- Set chat font sizes
				RunScript('for i = 1, 50 do if _G["ChatFrame" .. i] then FCF_SetChatWindowFontSize(self, _G["ChatFrame" .. i], 20) end end')

				-- Reload
				ReloadUI()
			else
				LeaPlusLC:Print("Invalid parameter.")
			end
			return
		else
			-- Prevent options panel from showing if a chat configuration panel is showing
			if ChatConfigFrame:IsShown() then return end
			-- Prevent options panel from showing if Blizzard Store is showing
			if StoreFrame and StoreFrame:GetAttribute("isshown") then return end
			-- Toggle the options panel if game options panel is not showing
			if LeaPlusLC:IsPlusShowing() then
				LeaPlusLC:HideFrames()
				LeaPlusLC:HideConfigPanels()
			else
				LeaPlusLC:HideFrames()
				LeaPlusLC["PageF"]:Show()
			end
			LeaPlusLC["Page"..LeaPlusLC["LeaStartPage"]]:Show()
		end
	end

	-- Slash command for global function
	_G.SLASH_Leatrix_Plus1 = "/ltp"
	_G.SLASH_Leatrix_Plus2 = "/leaplus"
	SlashCmdList["Leatrix_Plus"] = function(self)
		-- Run slash command function
		LeaPlusLC:SlashFunc(self)
		-- Redirect tainted variables
		RunScript('ACTIVE_CHAT_EDIT_BOX = ACTIVE_CHAT_EDIT_BOX')
		RunScript('LAST_ACTIVE_CHAT_EDIT_BOX = LAST_ACTIVE_CHAT_EDIT_BOX')
	end

	-- Slash command for UI reload
	_G.SLASH_LEATRIX_PLUS_RL1 = "/rl"
	SlashCmdList["LEATRIX_PLUS_RL"] = function()
		ReloadUI()
	end

----------------------------------------------------------------------
-- 	L90: Create options panel pages (no content yet)
----------------------------------------------------------------------

	-- Function to add menu button
	function LeaPlusLC:MakeMN(name, text, parent, anchor, x, y, width, height)

		local mbtn = CreateFrame("Button", nil, parent)
		LeaPlusLC[name] = mbtn
		mbtn:Show();
		mbtn:SetSize(width, height)
		mbtn:SetAlpha(1.0)
		mbtn:SetPoint(anchor, x, y)

		mbtn.t = mbtn:CreateTexture(nil, "BACKGROUND")
		mbtn.t:SetAllPoints()
		mbtn.t:SetColorTexture(0.3, 0.3, 0.00, 0.8)
		mbtn.t:SetAlpha(0.7)
		mbtn.t:Hide()

		mbtn.s = mbtn:CreateTexture(nil, "BACKGROUND")
		mbtn.s:SetAllPoints()
		mbtn.s:SetColorTexture(0.3, 0.3, 0.00, 0.8)
		mbtn.s:Hide()

		mbtn.f = mbtn:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
		mbtn.f:SetPoint('LEFT', 16, 0)
		mbtn.f:SetText(L[text])

		mbtn:SetScript("OnEnter", function()
			mbtn.t:Show()
		end)

		mbtn:SetScript("OnLeave", function()
			mbtn.t:Hide()
		end)

		return mbtn, mbtn.s

	end

	-- Function to create individual options panel pages
	function LeaPlusLC:MakePage(name, title, menu, menuname, menuparent, menuanchor, menux, menuy, menuwidth, menuheight)

		-- Create frame
		local oPage = CreateFrame("Frame", nil, LeaPlusLC["PageF"]);
		LeaPlusLC[name] = oPage
		oPage:SetAllPoints(LeaPlusLC["PageF"])
		oPage:Hide();

		-- Add page title
		oPage.s = oPage:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
		oPage.s:SetPoint('TOPLEFT', 146, -16)
		oPage.s:SetText(L[title])

		-- Add menu item if needed
		if menu then
			LeaPlusLC[menu], LeaPlusLC[menu .. ".s"] = LeaPlusLC:MakeMN(menu, menuname, menuparent, menuanchor, menux, menuy, menuwidth, menuheight)
			LeaPlusLC[name]:SetScript("OnShow", function() LeaPlusLC[menu .. ".s"]:Show(); end)
			LeaPlusLC[name]:SetScript("OnHide", function() LeaPlusLC[menu .. ".s"]:Hide(); end)
		end

		return oPage;

	end

	-- Create options pages
	LeaPlusLC["Page0"] = LeaPlusLC:MakePage("Page0", "Home"			, "LeaPlusNav0", "Home"			, LeaPlusLC["PageF"], "TOPLEFT", 16, -72, 112, 20)
	LeaPlusLC["Page1"] = LeaPlusLC:MakePage("Page1", "Automation"	, "LeaPlusNav1", "Automation"	, LeaPlusLC["PageF"], "TOPLEFT", 16, -112, 112, 20)
	LeaPlusLC["Page2"] = LeaPlusLC:MakePage("Page2", "Social"		, "LeaPlusNav2", "Social"		, LeaPlusLC["PageF"], "TOPLEFT", 16, -132, 112, 20)
	LeaPlusLC["Page3"] = LeaPlusLC:MakePage("Page3", "Chat"			, "LeaPlusNav3", "Chat"			, LeaPlusLC["PageF"], "TOPLEFT", 16, -152, 112, 20)
	LeaPlusLC["Page4"] = LeaPlusLC:MakePage("Page4", "Text"			, "LeaPlusNav4", "Text"			, LeaPlusLC["PageF"], "TOPLEFT", 16, -172, 112, 20)
	LeaPlusLC["Page5"] = LeaPlusLC:MakePage("Page5", "Interface"	, "LeaPlusNav5", "Interface"	, LeaPlusLC["PageF"], "TOPLEFT", 16, -192, 112, 20)
	LeaPlusLC["Page6"] = LeaPlusLC:MakePage("Page6", "Frames"		, "LeaPlusNav6", "Frames"		, LeaPlusLC["PageF"], "TOPLEFT", 16, -212, 112, 20)
	LeaPlusLC["Page7"] = LeaPlusLC:MakePage("Page7", "System"		, "LeaPlusNav7", "System"		, LeaPlusLC["PageF"], "TOPLEFT", 16, -232, 112, 20)
	LeaPlusLC["Page8"] = LeaPlusLC:MakePage("Page8", "Settings"		, "LeaPlusNav8", "Settings"		, LeaPlusLC["PageF"], "TOPLEFT", 16, -272, 112, 20)
	LeaPlusLC["Page9"] = LeaPlusLC:MakePage("Page9", "Media"		, "LeaPlusNav9", "Media"		, LeaPlusLC["PageF"], "TOPLEFT", 16, -292, 112, 20)

	-- Page navigation mechanism
	for i = 0, LeaPlusLC["NumberOfPages"] do
		LeaPlusLC["LeaPlusNav"..i]:SetScript("OnClick", function()
			LeaPlusLC:HideFrames()
			LeaPlusLC["PageF"]:Show();
			LeaPlusLC["Page"..i]:Show();
			LeaPlusLC["LeaStartPage"] = i
		end)
	end

	----------------------------------------------------------------------
	-- 	Options search
	----------------------------------------------------------------------

	do

		local PageF = LeaPlusLC["PageF"]
		local numPages = LeaPlusLC["NumberOfPages"]
		local rowHeight = 20
		local cogTip = L["Click to configure the settings for this option."]

		----------------------------------------------------------------------
		-- Results page
		----------------------------------------------------------------------

		local results = CreateFrame("Frame", nil, PageF)
		results:SetAllPoints(PageF)
		results:Hide()

		-- Page title and result count
		results.s = results:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
		results.s:SetPoint("TOPLEFT", 146, -16)
		results.s:SetText(L["Search results"])

		results.c = results:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		results.c:SetPoint("TOPLEFT", PageF.v, "TOPLEFT", 130, 0)
		results.c:SetJustifyH("LEFT")

		-- Hide results when any options page is shown
		for i = 0, numPages do
			if LeaPlusLC["Page" .. i] then
				LeaPlusLC["Page" .. i]:HookScript("OnShow", function() results:Hide() end)
			end
		end

		-- Scrolling list (same style as the scrolling configuration panels)
		local backFrame = CreateFrame("Frame", nil, results, "BackdropTemplate")
		backFrame:SetPoint("TOPLEFT", 146, -68)
		backFrame:SetPoint("BOTTOMRIGHT", -16, 58)
		backFrame:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"})
		backFrame:SetBackdropColor(0, 0, 1, 0.5)

		-- Scroll frame is inset so the links and their highlight stay inside the darker box
		local scrollFrame = CreateFrame("ScrollFrame", nil, backFrame, "LeaPlusConfigurationPanelScrollFrameTemplate")
		local scrollChild = CreateFrame("Frame", nil, scrollFrame)
		scrollChild:SetSize(1, 1)
		scrollFrame:SetScrollChild(scrollChild)
		scrollFrame:SetPoint("TOPLEFT", 6, -6)
		scrollFrame:SetPoint("BOTTOMRIGHT", -29, 6)
		scrollFrame:SetPanExtent(rowHeight)

		-- Scroll for more message (only shown when the list is longer than the panel)
		local moreMessage = LeaPlusLC:MakeTx(results, "(scroll the list for more)", 16, 0)
		moreMessage:ClearAllPoints()
		moreMessage:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", 28, 24)
		moreMessage:Hide()

		----------------------------------------------------------------------
		-- Search index (options on the main pages and settings in the configuration panels)
		----------------------------------------------------------------------

		local index, otherPanels

		-- Remove color codes, line breaks and reload asterisks, and make lower case
		local function Clean(text)
			text = (text or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|n", " "):gsub("%*", "")
			return strtrim(string.lower(text))
		end

		-- Find the configuration button (cogwheel) for an option (created by CfgBtn as a child of the checkbox)
		local function FindCog(cb)
			for i, child in ipairs({cb:GetChildren()}) do
				if child:GetObjectType() == "Button" and child.t and child.tiptext == cogTip then
					return child
				end
			end
		end

		-- Find the label above a dropdown (created by CreateDropdown 20 pixels above it)
		local function DropdownLabel(dd)
			for i, region in ipairs({dd:GetRegions()}) do
				if region:GetObjectType() == "FontString" then
					local point, relativeTo, relativePoint, x, y = region:GetPoint(1)
					if relativeTo == dd and y == 20 then return region:GetText() end
				end
			end
		end

		-- Find the heading just above a slider (slider captions are used for their tooltips)
		local function SliderLabel(slider)
			local _, _, _, sx, sy = slider:GetPoint()
			if not sx or not sy then return end
			local best, bestGap
			for i, region in ipairs({slider:GetParent():GetRegions()}) do
				if region:GetObjectType() == "FontString" then
					local _, _, _, x, y = region:GetPoint(1)
					if x == sx and y and y > sy and y - sy <= 30 and (not bestGap or y - sy < bestGap) then
						best, bestGap = region:GetText(), y - sy
					end
				end
			end
			return best
		end

		local function BuildIndex()
			index, otherPanels = {}, {}

			local pageOf, isPanel = {}, {}
			for i = 1, numPages do
				if LeaPlusLC["Page" .. i] then pageOf[LeaPlusLC["Page" .. i]] = i end
			end
			for i, panel in ipairs(LeaConfigList) do isPanel[panel] = true end

			-- Find the configuration panel a control is in (controls can be inside a scroll frame)
			local function PanelOf(frame)
				local p = frame:GetParent()
				while p do
					if isPanel[p] then return p end
					p = p:GetParent()
				end
			end

			local byTitle, subsByPanel = {}, {}

			for field, w in pairs(LeaPlusCB) do
				if type(w) == "table" and w.GetObjectType then
					local objType = w:GetObjectType()
					local page = pageOf[w:GetParent()]
					if page then
						-- Option on a main page
						if objType == "CheckButton" and w.f then
							local _, _, _, x, y = w:GetPoint()
							local label = w.f:GetText() or ""
							local entry = {cb = w, cog = FindCog(w), field = field, page = page, x = x or 0, y = y or 0, label = label, pageName = LeaPlusLC["Page" .. page].s:GetText(), text = Clean(label .. " " .. (w.tiptext or "")), subs = {}}
							index[#index + 1] = entry
							byTitle[Clean(label)] = entry
						end
					else
						-- Setting in a configuration panel
						local panel = PanelOf(w)
						if panel then
							local label, isCheck
							if objType == "CheckButton" and w.f then
								label, isCheck = w.f:GetText(), true
							elseif objType == "Slider" then
								label = SliderLabel(w) or w.tiptext
							elseif objType == "DropdownButton" then
								label = DropdownLabel(w)
							end
							if label and strtrim(label) ~= "" then
								local _, _, _, x, y = w:GetPoint()
								subsByPanel[panel] = subsByPanel[panel] or {}
								tinsert(subsByPanel[panel], {target = w, panel = panel, field = isCheck and field or nil, label = label, tiptext = w.tiptext, x = x or 0, y = y or 0, text = Clean(label .. " " .. (w.tiptext or ""))})
							end
						end
					end
				end
			end

			-- Sort options in the same order as the pages (page, then column, then top to bottom)
			table.sort(index, function(a, b)
				if a.page ~= b.page then return a.page < b.page end
				if a.x ~= b.x then return a.x < b.x end
				return a.y > b.y
			end)

			-- Link each configuration panel to the option with the same name (others go under Other settings)
			for panel, subs in pairs(subsByPanel) do
				table.sort(subs, function(a, b)
					if a.y ~= b.y then return a.y > b.y end
					return a.x < b.x
				end)
				local title = panel.f and panel.f:GetText() or ""
				local parent = byTitle[Clean(title)]
				for i, sub in ipairs(subs) do sub.parent = parent end
				if parent then
					parent.subs = subs
				else
					otherPanels[#otherPanels + 1] = {panel = panel, label = title, subs = subs}
				end
			end
			table.sort(otherPanels, function(a, b) return a.label < b.label end)
		end

		----------------------------------------------------------------------
		-- Highlight an option or setting after jumping to it
		----------------------------------------------------------------------

		local flash = CreateFrame("Frame", nil, PageF)
		flash:Hide()
		flash.t = flash:CreateTexture(nil, "OVERLAY")
		flash.t:SetAllPoints()
		flash.t:SetColorTexture(1, 0.82, 0, 0.35)
		flash.t:SetBlendMode("ADD")

		local flashAnim = flash:CreateAnimationGroup()
		for i, v in ipairs({{0, 1, 0.2}, {1, 0, 0.4}, {0, 1, 0.2}, {1, 0, 0.8}}) do
			local a = flashAnim:CreateAnimation("Alpha")
			a:SetFromAlpha(v[1])
			a:SetToAlpha(v[2])
			a:SetDuration(v[3])
			a:SetOrder(i)
		end
		flashAnim:SetScript("OnFinished", function() flash:Hide() end)

		-- Flash a control (holder is the panel it's shown on)
		local function Flash(target, holder)
			flash:SetParent(holder)
			flash:SetFrameStrata(holder:GetFrameStrata())
			flash:ClearAllPoints()
			local objType = target:GetObjectType()
			if objType == "CheckButton" and target.f then
				-- Checkbox and its label
				flash:SetPoint("TOPLEFT", target, "TOPLEFT", -2, 0)
				flash:SetPoint("BOTTOMLEFT", target, "BOTTOMLEFT", -2, 0)
				flash:SetWidth(28 + math.min(target.f:GetStringWidth(), target.f:GetWidth()))
			elseif objType == "Slider" then
				-- Slider and its value
				flash:SetPoint("TOPLEFT", target, "TOPLEFT", -4, 4)
				flash:SetPoint("BOTTOMLEFT", target, "BOTTOMLEFT", -4, -4)
				flash:SetWidth(target:GetWidth() + 8 + (target.f and target.f:GetStringWidth() + 12 or 0))
			else
				-- Dropdown and its label above
				flash:SetPoint("TOPLEFT", target, "TOPLEFT", -4, 22)
				flash:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", 4, -4)
			end
			flash:SetFrameLevel(target:GetFrameLevel() + 5)
			flash:Show()
			flashAnim:Stop()
			flashAnim:Play()
		end

		-- Open an options page (used by the headings)
		local function ShowPage(page)
			LeaPlusLC:HideFrames()
			PageF:Show()
			LeaPlusLC["Page" .. page]:Show()
			LeaPlusLC["LeaStartPage"] = page
		end

		-- Open the page an option is on and highlight it
		local function ShowOption(entry)
			ShowPage(entry.page)
			Flash(entry.cb, PageF)
		end

		-- Open a configuration panel directly (used when a panel has no matching option)
		local function ShowPanel(panel)
			LeaPlusLC:HideFrames()
			LeaPlusLC:HideConfigPanels()
			panel:Show()
		end

		-- Open the configuration panel a setting is in and highlight it
		local function ShowSub(sub)
			local parent = sub.parent
			local cog = parent and parent.cog
			if cog then
				if cog:IsEnabled() and parent.cb:IsEnabled() then
					-- Use the real cogwheel so the panel is set up as normal
					GameTooltip:Hide()
					cog:Click()
				else
					-- Cogwheel is locked (option is off or needs a reload) so show the option instead
					ShowOption(parent)
					return
				end
			else
				ShowPanel(sub.panel)
			end
			if sub.panel:IsShown() then Flash(sub.target, sub.panel) end
		end

		----------------------------------------------------------------------
		-- Result list (page headings, options, and configuration panel settings underneath)
		----------------------------------------------------------------------

		local rows = {}

		local function GetRow(n)
			if rows[n] then return rows[n] end

			local row = CreateFrame("Button", nil, scrollChild)
			row:SetHeight(rowHeight)
			row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -(n - 1) * rowHeight)
			row:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, -(n - 1) * rowHeight)

			row.hl = row:CreateTexture(nil, "BACKGROUND")
			row.hl:SetAllPoints()
			row.hl:SetColorTexture(0.3, 0.3, 0.00, 0.5)
			row.hl:Hide()

			-- Page heading
			row.h = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
			row.h:SetPoint("LEFT", 8, 0)
			row.h:SetJustifyH("LEFT")

			-- Enabled status (fixed width column on the right)
			row.e = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
			row.e:SetPoint("RIGHT", -8, 0)
			row.e:SetWidth(28)
			row.e:SetJustifyH("CENTER")

			-- Option or setting name (indent is set when the row is used)
			row.f = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
			row.f:SetJustifyH("LEFT")
			row.f:SetWordWrap(false)

			row:SetScript("OnEnter", function(self)
				self.hl:Show()
				if self.tiptext then LeaPlusLC.TipSee(self) end
			end)
			row:SetScript("OnLeave", function(self)
				self.hl:Hide()
				GameTooltip:Hide()
			end)
			row:SetScript("OnClick", function(self)
				if self.kind == "option" then
					ShowOption(self.data)
				elseif self.kind == "sub" then
					ShowSub(self.data)
				elseif self.kind == "panel" then
					ShowPanel(self.data.panel)
				elseif self.kind == "heading" and self.page then
					ShowPage(self.page)
				end
			end)

			rows[n] = row
			return row
		end

		-- Set the indent of a row's name
		local function SetIndent(row, indent)
			row.f:ClearAllPoints()
			row.f:SetPoint("LEFT", indent, 0)
			row.f:SetPoint("RIGHT", row.e, "LEFT", -8, 0)
		end

		-- Show the On or Off status for a setting
		local function SetStatus(row, field)
			if not field then row.e:Hide() return end
			if LeaPlusLC[field] == "On" then
				row.e:SetText(L["On"])
				row.e:SetTextColor(0.2, 1, 0.2)
			else
				row.e:SetText(L["Off"])
				row.e:SetTextColor(0.5, 0.5, 0.5)
			end
			row.e:Show()
		end

		----------------------------------------------------------------------
		-- Show search results
		----------------------------------------------------------------------

		local function ShowResults(query)

			if not index then BuildIndex() end

			-- Every word typed must appear in the name or tooltip
			local words = {}
			for word in string.lower(query):gmatch("%S+") do words[#words + 1] = word end

			local function Matches(text)
				for i, word in ipairs(words) do
					if not text:find(word, 1, true) then return false end
				end
				return true
			end

			-- Build the list
			local items, count, lastHeading = {}, 0, nil
			local function AddHeading(key, name, page)
				if key ~= lastHeading then
					items[#items + 1] = {kind = "heading", name = name, page = page}
					lastHeading = key
				end
			end

			-- Options and their configuration panel settings
			for i, entry in ipairs(index) do
				local optionMatch = Matches(entry.text)
				local subs = {}
				for j, sub in ipairs(entry.subs) do
					if Matches(sub.text) then subs[#subs + 1] = sub end
				end
				if optionMatch or #subs > 0 then
					AddHeading(entry.page, entry.pageName, entry.page)
					items[#items + 1] = {kind = "option", data = entry}
					if optionMatch then count = count + 1 end
					for j, sub in ipairs(subs) do
						items[#items + 1] = {kind = "sub", data = sub}
						count = count + 1
					end
				end
			end

			-- Configuration panels without a matching option
			for i, group in ipairs(otherPanels) do
				local subs = {}
				for j, sub in ipairs(group.subs) do
					if Matches(sub.text) then subs[#subs + 1] = sub end
				end
				if #subs > 0 then
					AddHeading("other", L["Other settings"])
					items[#items + 1] = {kind = "panel", data = group}
					for j, sub in ipairs(subs) do
						items[#items + 1] = {kind = "sub", data = sub}
						count = count + 1
					end
				end
			end

			-- Show the list
			for i, item in ipairs(items) do
				local row = GetRow(i)
				row.kind, row.data, row.page, row.tiptext = item.kind, item.data, nil, nil
				row.h:Hide()
				row.f:Hide()
				row.e:Hide()
				if item.kind == "heading" then
					row.page = item.page
					row.h:SetText(item.name)
					row.h:Show()
				elseif item.kind == "option" then
					SetIndent(row, 20)
					row.f:SetText(item.data.label)
					row.f:SetTextColor(1, 1, 1)
					row.f:Show()
					row.tiptext = item.data.cb.tiptext
					SetStatus(row, item.data.field)
				elseif item.kind == "panel" then
					SetIndent(row, 20)
					row.f:SetText(item.data.label)
					row.f:SetTextColor(1, 1, 1)
					row.f:Show()
				elseif item.kind == "sub" then
					SetIndent(row, 36)
					row.f:SetText(item.data.label)
					row.f:SetTextColor(0.6, 0.6, 0.6)
					row.f:Show()
					row.tiptext = item.data.tiptext
					SetStatus(row, item.data.field)
				end
				row:Show()
			end
			for i = #items + 1, #rows do
				rows[i]:Hide()
				rows[i].kind, rows[i].data, rows[i].page = nil, nil, nil
			end

			-- Size the list and scroll to the top
			scrollChild:SetWidth(scrollFrame:GetWidth())
			scrollChild:SetHeight(math.max(#items * rowHeight, 1))
			scrollFrame:SetVerticalScroll(0)
			moreMessage:SetShown(#items * rowHeight > scrollFrame:GetHeight())

			-- Result count (options and settings that matched, not context rows)
			if count == 0 then
				results.c:SetText(L["No options found."])
			elseif count == 1 then
				results.c:SetText(L["1 option found."])
			else
				results.c:SetFormattedText(L["%d options found."], count)
			end

		end

		----------------------------------------------------------------------
		-- Search box (top right of the panel)
		----------------------------------------------------------------------

		local eb = LeaPlusLC:CreateEditBox("OptionsSearchBox", PageF, 180, 40, "TOPRIGHT", -36, -12, "OptionsSearchBox", "OptionsSearchBox")
		eb:SetHeight(25)
		eb:SetFontObject("GameFontHighlight")
		eb:SetTextInsets(8, 22, 0, 0)

		-- Remove the default editbox art
		eb.f:Hide()
		for i, key in pairs({"Left", "Middle", "Mid", "Right"}) do
			if eb[key] then eb[key]:SetAlpha(0) end
		end

		-- Translucent inset that blends with the panel (dark fill and a faint outline)
		eb.bg = eb:CreateTexture(nil, "BACKGROUND")
		eb.bg:SetAllPoints()
		eb.bg:SetColorTexture(0, 0, 0, 0.35)

		-- Outline (1 pixel lines around the box)
		eb.edges = {}
		local function MakeEdge(p1, p2, horizontal)
			local edge = eb:CreateTexture(nil, "BORDER")
			edge:SetPoint(p1, eb, p1)
			edge:SetPoint(p2, eb, p2)
			if PixelUtil then
				if horizontal then PixelUtil.SetHeight(edge, 1) else PixelUtil.SetWidth(edge, 1) end
			else
				if horizontal then edge:SetHeight(1) else edge:SetWidth(1) end
			end
			eb.edges[#eb.edges + 1] = edge
		end
		MakeEdge("TOPLEFT", "TOPRIGHT", true)
		MakeEdge("BOTTOMLEFT", "BOTTOMRIGHT", true)
		MakeEdge("TOPLEFT", "BOTTOMLEFT", false)
		MakeEdge("TOPRIGHT", "BOTTOMRIGHT", false)

		-- Set outline color
		local function SetEdgeColor(r, g, b, a)
			for i, edge in pairs(eb.edges) do edge:SetColorTexture(r, g, b, a) end
		end

		-- Placeholder text
		eb.ph = eb:CreateFontString(nil, "ARTWORK", "GameFontDisable")
		eb.ph:SetPoint("LEFT", 8, 0)
		eb.ph:SetText(L["Search options"])

		-- Clear button (cross on the right, shown when there is text)
		eb.clear = CreateFrame("Button", nil, eb)
		eb.clear:SetSize(14, 14)
		eb.clear:SetPoint("RIGHT", -6, 0)
		eb.clear.t = eb.clear:CreateTexture(nil, "ARTWORK")
		eb.clear.t:SetAllPoints()
		eb.clear.t:SetTexture("Interface\\FriendsFrame\\ClearBroadcastIcon")
		eb.clear.t:SetAlpha(0.5)
		eb.clear:SetScript("OnEnter", function(self) self.t:SetAlpha(1) end)
		eb.clear:SetScript("OnLeave", function(self) self.t:SetAlpha(0.5) end)
		eb.clear:Hide()

		-- Update placeholder, clear button and outline (gold while typing, lighter on hover)
		local function UpdateBox()
			local empty = eb:GetText() == ""
			eb.ph:SetShown(empty and not eb:HasFocus())
			eb.clear:SetShown(not empty)
			if eb:HasFocus() then
				SetEdgeColor(1, 0.82, 0, 0.5)
			elseif eb:IsMouseOver() then
				SetEdgeColor(1, 1, 1, 0.3)
			else
				SetEdgeColor(1, 1, 1, 0.15)
			end
		end
		eb:HookScript("OnEditFocusGained", UpdateBox)
		eb:HookScript("OnEditFocusLost", UpdateBox)
		eb:HookScript("OnEnter", UpdateBox)
		eb:HookScript("OnLeave", UpdateBox)

		-- Return to the last options page
		local function ShowLastPage()
			results:Hide()
			local page = LeaPlusLC["Page" .. (LeaPlusLC["LeaStartPage"] or 0)]
			if page then page:Show() end
		end

		-- Clear the search and return to the last page
		local function ClearSearch()
			eb:SetText("")
			eb:ClearFocus()
			ShowLastPage()
			UpdateBox()
		end
		eb.clear:SetScript("OnClick", ClearSearch)

		-- Search as you type
		eb:SetScript("OnTextChanged", function(self, userInput)
			UpdateBox()
			if not userInput then return end
			local query = strtrim(self:GetText())
			if query == "" then
				ShowLastPage()
			else
				for i = 0, numPages do
					if LeaPlusLC["Page" .. i] then LeaPlusLC["Page" .. i]:Hide() end
				end
				results:Show()
				ShowResults(query)
			end
		end)

		-- Escape clears the search, enter takes focus off the editbox
		eb:SetScript("OnEscapePressed", ClearSearch)
		eb:SetScript("OnEnterPressed", eb.ClearFocus)

		-- Clear the search when the panel is closed or another page is chosen (index is rebuilt next time)
		PageF:HookScript("OnHide", function()
			results:Hide()
			eb:SetText("")
			eb:ClearFocus()
			UpdateBox()
			index = nil
		end)

		UpdateBox()

	end

	-- Use a variable to contain the page number (makes it easier to move options around)
	local pg;

----------------------------------------------------------------------
-- 	LC0: Welcome
----------------------------------------------------------------------

	pg = "Page0";

	LeaPlusLC:MakeTx(LeaPlusLC[pg], "Welcome to Leatrix Plus.", 146, -72);
	LeaPlusLC:MakeWD(LeaPlusLC[pg], "To begin, choose an options page.", 146, -92);

	LeaPlusLC:MakeTx(LeaPlusLC[pg], "Support", 146, -132);
	LeaPlusLC:MakeWD(LeaPlusLC[pg], "curseforge.com/wow/addons/leatrix-plus", 146, -152);

----------------------------------------------------------------------
-- 	LC1: Automation
----------------------------------------------------------------------

	pg = "Page1";

	LeaPlusLC:MakeTx(LeaPlusLC[pg], "Character"					, 	146, -72);
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "AutomateQuests"			,	"Automate quests"				,	146, -92, 	false,	"If checked, quests will be selected, accepted and turned-in automatically.|n|nQuests which have a gold requirement will not be turned-in automatically.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "AutomateGossip"			,	"Automate gossip"				,	146, -112, 	false,	"If checked, you can hold down the alt key while opening a gossip window to automatically select a single gossip item.|n|nIf the gossip item type is banker, taxi, trainer, vendor or battlemaster, gossip will be skipped without needing to hold the alt key.  You can hold the shift key down to prevent this.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "AutoAcceptSummon"			,	"Accept summon"					, 	146, -132, 	false,	"If checked, summon requests will be accepted automatically unless you are in combat.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "AutoAcceptRes"				,	"Accept resurrection"			, 	146, -152, 	false,	"If checked, resurrection requests will be accepted automatically.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "AutoReleasePvP"			,	"Release in PvP"				, 	146, -172, 	false,	"If checked, you will release automatically after you die in a battleground.|n|nYou will not release automatically if you have the ability to self-resurrect.")

	LeaPlusLC:MakeTx(LeaPlusLC[pg], "Vendors"					, 	340, -72);
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "AutoSellJunk"				,	"Sell junk automatically"		,	340, -92, 	false,	"If checked, all grey items in your bags will be sold automatically when you visit a merchant.|n|nYou can hold the shift key down when you talk to a merchant to override this setting.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "AutoRepairGear"			, 	"Repair automatically"			,	340, -112, 	false,	"If checked, your gear will be repaired automatically when you visit a suitable merchant.|n|nYou can hold the shift key down when you talk to a merchant to override this setting.")

	LeaPlusLC:CfgBtn("AutomateQuestsBtn", LeaPlusCB["AutomateQuests"])
	LeaPlusLC:CfgBtn("AutoAcceptResBtn", LeaPlusCB["AutoAcceptRes"])
	LeaPlusLC:CfgBtn("AutoReleasePvPBtn", LeaPlusCB["AutoReleasePvP"])
	LeaPlusLC:CfgBtn("AutoSellJunkBtn", LeaPlusCB["AutoSellJunk"])
	LeaPlusLC:CfgBtn("AutoRepairBtn", LeaPlusCB["AutoRepairGear"])

----------------------------------------------------------------------
-- 	LC2: Social
----------------------------------------------------------------------

	pg = "Page2";

	LeaPlusLC:MakeTx(LeaPlusLC[pg], "Blocks"					, 	146, -72);
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoDuelRequests"			, 	"Block duels"					,	146, -92, 	false,	"If checked, duel requests will be blocked unless the player requesting the duel is a friend.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoPartyInvites"			, 	"Block party invites"			, 	146, -112, 	false,	"If checked, party invitations will be blocked unless the player inviting you is a friend.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoFriendRequests"			, 	"Block friend requests"			, 	146, -132, 	false,	"If checked, BattleTag and Real ID friend requests will be automatically declined.|n|nEnabling this option will automatically decline any pending requests.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoSharedQuests"			, 	"Block shared quests"			, 	146, -152, 	false,	"If checked, shared quests will be declined unless the player sharing the quest is a friend.")

	LeaPlusLC:MakeTx(LeaPlusLC[pg], "Groups"					, 	340, -72);
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "AcceptPartyFriends"		, 	"Party from friends"			, 	340, -92, 	false,	"If checked, party invitations from friends will be automatically accepted unless you are queued for a battleground or the Looking for Group feature.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "InviteFromWhisper"			,   "Invite from whispers"			,	340, -112,	false,	L["If checked, a group invite will be sent to anyone who whispers you with a set keyword as long as you are ungrouped, group leader or raid assistant and not queued for a battleground or the Looking for Group feature.|n|nFriends who message the keyword using Battle.net will not be sent a group invite if they are appearing offline.  They need to either change their online status or use character whispers."] .. "|n|n" .. L["Keyword"] .. ": |cffffffff" .. "dummy" .. "|r")

	local FriendlyGuildFooter = LeaPlusLC:MakeFT(LeaPlusLC[pg], "For all of the social options above, you can treat guild members as friends too.", 146, 380)
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "FriendlyGuild"				, 	"Guild"							, 	146, -282, 	false,	"If checked, members of your guild will be treated as friends for all of the options on this page.")
	LeaPlusCB["FriendlyGuild"]:ClearAllPoints()
	LeaPlusCB["FriendlyGuild"]:SetPoint("TOPLEFT", FriendlyGuildFooter, "BOTTOMLEFT", 0, -10)
	if LeaPlusCB["FriendlyGuild"].f:GetStringWidth() > 90 then
		LeaPlusCB["FriendlyGuild"].f:SetWidth(90)
		LeaPlusCB["FriendlyGuild"]:SetHitRectInsets(0, -84, 0, 0)
	end

	LeaPlusLC:CfgBtn("InvWhisperBtn", LeaPlusCB["InviteFromWhisper"])

----------------------------------------------------------------------
-- 	LC3: Chat
----------------------------------------------------------------------

	pg = "Page3";

	LeaPlusLC:MakeTx(LeaPlusLC[pg], "Chat Frame"				, 	146, -72);
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "UseEasyChatResizing"		,	"Use easy resizing"				,	146, -92,	true,	"If checked, dragging the General chat tab while the chat frame is locked will expand the chat frame upwards.|n|nIf the chat frame is unlocked, dragging the General chat tab will move the chat frame.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoCombatLogTab" 			, 	"Hide the combat log"			, 	146, -112, 	true,	"If checked, the combat log will be hidden.|n|nThe combat log must be docked in order for this option to work.|n|nIf the combat log is undocked, you can dock it by dragging the tab (and reloading your UI) or by resetting the chat windows (from the chat menu).")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoChatButtons"				,	"Hide chat buttons"				,	146, -132,	true,	"If checked, chat frame buttons will be hidden.|n|nClicking chat tabs will automatically show the latest messages.|n|nUse the mouse wheel to scroll through the chat history.  Hold down SHIFT for page jump or CTRL to jump to the top or bottom of the chat history.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "UnclampChat"				,	"Unclamp chat frame"			,	146, -152,	true,	"If checked, you will be able to drag the chat frame to the edge of the screen.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "MoveChatEditBoxToTop" 		, 	"Move editbox to top"			,	146, -172, 	true,	"If checked, the editbox will be moved to the top of the chat frame.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "MoreChatFontSizes"		 	, 	"More chat font sizes"			,	146, -192, 	true,	"If checked, additional font sizes will be available in the chat frame font size menu.")

	LeaPlusLC:MakeTx(LeaPlusLC[pg], "Mechanics"					, 	340, -72);
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoStickyChat"				, 	"Disable sticky chat"			,	340, -92,	true,	"If checked, sticky chat will be disabled.|n|nNote that this does not apply to temporary chat windows.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "UseArrowKeysInChat"		, 	"Use arrow keys in chat"		, 	340, -112, 	true,	"If checked, you can press the arrow keys to move the insertion point left and right in the chat frame.|n|nIf unchecked, the arrow keys will use the default keybind setting.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoChatFade"				, 	"Disable chat fade"				, 	340, -132, 	true,	"If checked, chat text will not fade out after a time period.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "UnivGroupColor"			,	"Universal group color"			,	340, -152,	false,	"If checked, raid chat will be colored blue (to match the default party chat color).")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "ClassColorsInChat"			,	"Use class colors in chat"		,	340, -172,	true,	"If checked, class colors will be used in the chat frame.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "RecentChatWindow"			,	"Recent chat window"			, 	340, -192, 	true,	"If checked, you can hold down the control key and click a chat tab to view recent chat in a copy-friendly window.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "MaxChatHstory"				,	"Increase chat history"			, 	340, -212, 	true,	"If checked, your chat history will increase to 4096 lines.  If unchecked, the default will be used (128 lines).|n|nEnabling this option may prevent some chat text from showing during login.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "FilterChatMessages"		, 	"Filter chat messages"			,	340, -232, 	true,	"If checked, you can block drunken spam and duel spam.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "RestoreChatMessages"		, 	"Restore chat messages"			,	340, -252, 	true,	"If checked, recent chat will be restored when you reload your interface.")

	LeaPlusLC:CfgBtn("FilterChatMessagesBtn", LeaPlusCB["FilterChatMessages"])

----------------------------------------------------------------------
-- 	LC4: Text
----------------------------------------------------------------------

	pg = "Page4";

	LeaPlusLC:MakeTx(LeaPlusLC[pg], "Visibility"				, 	146, -72);
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "HideErrorMessages"			, 	"Hide error messages"			,	146, -92, 	true,	"If checked, most error messages (such as 'Not enough rage') will not be shown.  Some important errors are excluded.|n|nIf you have the minimap button enabled, you can hold down the alt key and click it to toggle error messages without affecting this setting.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoHitIndicators"			, 	"Hide portrait numbers"			,	146, -112, 	true,	"If checked, damage and healing numbers in the player and pet portrait frames will be hidden.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "HideZoneText"				,	"Hide zone text"				,	146, -132, 	true,	"If checked, zone text will not be shown (eg. 'Ironforge').")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "HideKeybindText"			,	"Hide keybind text"				,	146, -152, 	true,	"If checked, keybind text will not be shown on action buttons.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "HideMacroText"				,	"Hide macro text"				,	146, -172, 	true,	"If checked, macro text will not be shown on action buttons.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "HideRaidGroupLabels"		,	"Hide raid group labels"		,	146, -192, 	true,	"If checked, the player frame group indicator and the group labels displayed above the compact raid frames and the pullout raid frames will be hidden.")

	LeaPlusLC:MakeTx(LeaPlusLC[pg], "Text Size"					, 	340, -72);
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "MailFontChange"			,	"Resize mail text"				, 	340, -92, 	true,	"If checked, you will be able to change the font size of standard mail text.|n|nThis does not affect mail created using templates (such as auction house invoices).")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "QuestFontChange"			,	"Resize quest text"				, 	340, -112, 	true,	"If checked, you will be able to change the font size of quest text.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "BookFontChange"			,	"Resize book text"				, 	340, -132, 	true,	"If checked, you will be able to change the font size of book text.")

	LeaPlusLC:CfgBtn("MailTextBtn", LeaPlusCB["MailFontChange"])
	LeaPlusLC:CfgBtn("QuestTextBtn", LeaPlusCB["QuestFontChange"])
	LeaPlusLC:CfgBtn("BookTextBtn", LeaPlusCB["BookFontChange"])

----------------------------------------------------------------------
-- 	LC5: Interface
----------------------------------------------------------------------

	pg = "Page5";

	LeaPlusLC:MakeTx(LeaPlusLC[pg], "Enhancements"				, 	146, -72);
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "MinimapModder"				,	"Enhance minimap"				, 	146, -92, 	true,	"If checked, you will be able to customise the minimap.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "TipModEnable"				,	"Enhance tooltip"				,	146, -112, 	true,	"If checked, the tooltip will be color coded and you will be able to modify the tooltip layout and scale.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "EnhanceDressup"			, 	"Enhance dressup"				,	146, -132, 	true,	"If checked, you will be able to pan (right-button) and zoom (mousewheel) in the character frame, dressup frame and inspect frame.|n|nA toggle stats button will be shown in the character frame.  You can also middle-click the character model to toggle stats.|n|nModel rotation controls will be hidden.  Buttons to toggle gear will be added to the dressup frame.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "EnhanceQuestLog"			, 	"Enhance quest log"				,	146, -152, 	true,	"If checked, the quest log frame will be larger and feature a world map button and quest levels.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "EnhanceProfessions"		, 	"Enhance professions"			,	146, -172, 	true,	"If checked, the professions frame will be larger.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "EnhanceTrainers"			, 	"Enhance trainers"				,	146, -192, 	true,	"If checked, the skill trainer frame will be larger and feature a train all skills button.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "EnhanceFlightMap"			, 	"Enhance flight map"			,	146, -212, 	true,	"If checked, you will be able to customise the flight map.")

	LeaPlusLC:MakeTx(LeaPlusLC[pg], "Extras"					, 	146, -252);
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowVolume"				, 	"Show volume slider"			, 	146, -272, 	true,	"If checked, a master volume slider will be shown in the character frame.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "AhExtras"					, 	"Show auction controls"			, 	146, -292, 	true,	"If checked, additional functionality will be added to the auction house.|n|nBuyout only - create buyout auctions without filling in the starting price.|n|nGold only - set the copper and silver prices at 99 to speed up new auctions.|n|nFind item - search the auction house for the item you are selling.|n|nIn addition, the auction duration setting will be saved account-wide.")

	LeaPlusLC:MakeTx(LeaPlusLC[pg], "Extras"					, 	340, -72);
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowCooldowns"				, 	"Show cooldowns"				, 	340, -92, 	true,	"If checked, you will be able to place up to five beneficial cooldown icons above the target frame.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "DurabilityStatus"			, 	"Show durability status"		, 	340, -112, 	true,	"If checked, a button will be added to the character frame which will show your equipped item durability when you hover the pointer over it.|n|nIn addition, an overall percentage will be shown in the chat frame when you die.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowVanityControls"		, 	"Show vanity controls"			, 	340, -132, 	true,	"If checked, helm and cloak toggle checkboxes will be shown in the character frame.|n|nYou can hold shift and right-click the checkboxes to switch layouts.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowBagSearchBox"			, 	"Show bag search box"			, 	340, -152, 	true,	"If checked, a bag search box will be shown in the backpack frame and the bank frame.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowFreeBagSlots"			, 	"Show free bag slots"			, 	340, -172, 	true,	"If checked, the number of free bag slots will be shown in the backpack button icon and tooltip.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowRaidToggle"			, 	"Show raid button"				,	340, -192, 	true,	"If checked, the button to toggle the raid container frame will be shown just above the raid management frame (left side of the screen) instead of in the raid management frame itself.|n|nThis allows you to toggle the raid container frame without needing to open the raid management frame.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowBorders"				,	"Show borders"					,	340, -212, 	true,	"If checked, you will be able to show customisable borders around the edges of the screen.|n|nThe borders are placed on top of the game world but under the UI so you can place UI elements over them.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowPlayerChain"			, 	"Show player chain"				,	340, -232, 	true,	"If checked, you will be able to show a rare, elite or rare elite chain around the player frame.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowDruidPowerBar"			, 	"Show druid power bar"			,	340, -252, 	true,	"If checked, a power bar will be shown in the player frame when you are playing a shapeshifted druid.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowReadyTimer"			, 	"Show ready timer"				,	340, -272, 	true,	"If checked, a timer will be shown under the PvP encounter ready frame so that you know how long you have left to click the enter button.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowRangeColoring"			, 	"Show range coloring"			, 	340, -292, 	true,	"If checked, action button icons will be colored red for out of range and blue for not enough mana.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowInfoCards"				, 	"Show info cards"				, 	340, -312, 	true,	"If checked, you can point at almost anything and press a key to show an information card, model preview and a link to Wowhead.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowWowheadLinks"			, 	"Show Wowhead links"			, 	340, -332, 	true,	"If checked, Wowhead links will be shown above the quest log frame.")

	LeaPlusLC:CfgBtn("ModMinimapBtn", LeaPlusCB["MinimapModder"])
	LeaPlusLC:CfgBtn("MoveTooltipButton", LeaPlusCB["TipModEnable"])
	LeaPlusLC:CfgBtn("EnhanceDressupBtn", LeaPlusCB["EnhanceDressup"])
	LeaPlusLC:CfgBtn("EnhanceQuestLogBtn", LeaPlusCB["EnhanceQuestLog"])
	LeaPlusLC:CfgBtn("EnhanceTrainersBtn", LeaPlusCB["EnhanceTrainers"])
	LeaPlusLC:CfgBtn("EnhanceFlightMapBtn", LeaPlusCB["EnhanceFlightMap"])
	LeaPlusLC:CfgBtn("CooldownsButton", LeaPlusCB["ShowCooldowns"])
	LeaPlusLC:CfgBtn("ModBordersBtn", LeaPlusCB["ShowBorders"])
	LeaPlusLC:CfgBtn("ModPlayerChain", LeaPlusCB["ShowPlayerChain"])
	LeaPlusLC:CfgBtn("ShowDruidPowerBarBtn", LeaPlusCB["ShowDruidPowerBar"])
	LeaPlusLC:CfgBtn("ShowInfoCardsBtn", LeaPlusCB["ShowInfoCards"])
	LeaPlusLC:CfgBtn("ShowWowheadLinksBtn", LeaPlusCB["ShowWowheadLinks"])

----------------------------------------------------------------------
-- 	LC6: Frames
----------------------------------------------------------------------

	pg = "Page6";

	LeaPlusLC:MakeTx(LeaPlusLC[pg], "Features"					, 	146, -72);
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "ManageWidget"				,	"Manage widget"					, 	146, -92, 	true,	"If checked, you will be able to change the position and scale of the widget frame.|n|nThe widget frame is commonly used for showing PvP scores and tracking objectives.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "ManageTimer"				,	"Manage timer"					, 	146, -112, 	true,	"If checked, you will be able to change the position and scale of the timer bar.|n|nThe timer bar is used for showing remaining breath when underwater as well as other things.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "ClassColFrames"			, 	"Class colored frames"			,	146, -132, 	true,	"If checked, class coloring will be used in the player frame and target frame.")

	LeaPlusLC:MakeTx(LeaPlusLC[pg], "Visibility"				, 	340, -72);
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoGryphons"				,	"Hide gryphons"					, 	340, -92, 	true,	"If checked, the main bar gryphons will not be shown.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoClassBar"				,	"Hide stance bar"				, 	340, -112, 	true,	"If checked, the stance bar will not be shown.")

	LeaPlusLC:CfgBtn("ManageWidgetButton", LeaPlusCB["ManageWidget"])
	LeaPlusLC:CfgBtn("ManageTimerButton", LeaPlusCB["ManageTimer"])
	LeaPlusLC:CfgBtn("ClassColFramesBtn", LeaPlusCB["ClassColFrames"])

----------------------------------------------------------------------
-- 	LC7: System
----------------------------------------------------------------------

	pg = "Page7";

	LeaPlusLC:MakeTx(LeaPlusLC[pg], "Graphics and Sound"		, 	146, -72);
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoScreenGlow"				, 	"Disable screen glow"			, 	146, -92, 	false,	"If checked, the screen glow will be disabled.|n|nEnabling this option will also disable the drunken haze effect.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoScreenEffects"			, 	"Disable screen effects"		, 	146, -112, 	false,	"If checked, the grey screen of death and the netherworld effect will be disabled.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "SetWeatherDensity"			, 	"Set weather density"			, 	146, -132, 	false,	"If checked, you will be able to set the density of weather effects.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "MaxCameraZoom"				, 	"Max camera zoom"				, 	146, -152, 	false,	"If checked, you will be able to zoom out to a greater distance.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoRestedEmotes"			, 	"Silence rested emotes"			,	146, -172, 	true,	"If checked, emote sounds will be silenced while your character is resting or at the Grim Guzzler.|n|nEmote sounds will be enabled at all other times.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "KeepAudioSynced"			, 	"Keep audio synced"				,	146, -192, 	true,	"If checked, when you change the audio output device in your operating system, the game audio output device will change automatically as long as a cinematic is not playing at the time.|n|nFor this to work, the game audio output device will be set to system default.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "MuteGameSounds"			, 	"Mute game sounds"				,	146, -212, 	false,	"If checked, you will be able to mute a selection of game sounds.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "MuteMountSounds"			, 	"Mute mount sounds"				,	146, -232, 	false,	"If checked, you will be able to mute a selection of mount sounds.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "MuteCustomSounds"			, 	"Mute custom sounds"			,	146, -252, 	false,	"If checked, you will be able to mute your own choice of sounds.")

	LeaPlusLC:MakeTx(LeaPlusLC[pg], "Game Options"				, 	340, -72);
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoBagAutomation"			, 	"Disable bag automation"		, 	340, -92, 	true,	"If checked, your bags will not be opened or closed automatically when you interact with a merchant, bank or mailbox.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoConfirmLoot"				, 	"Disable loot warnings"			,	340, -112, 	false,	"If checked, confirmations will no longer appear when you choose a loot roll option or attempt to sell or mail a tradable item.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "FasterLooting"				, 	"Faster auto loot"				,	340, -132, 	true,	"If checked, the amount of time it takes to auto loot creatures will be significantly reduced.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "FasterMovieSkip"			, 	"Faster movie skip"				,	340, -152, 	true,	"If checked, you will be able to cancel cinematics without being prompted for confirmation.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "StandAndDismount"			, 	"Dismount me"					,	340, -172, 	true,	"If checked, you will be able to set some additional rules for when your character is automatically dismounted.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowVendorPrice"			, 	"Show vendor price"				,	340, -192, 	true,	"If checked, the vendor price will be shown in item tooltips.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "CombatPlates"				, 	"Combat plates"					,	340, -212, 	true,	"If checked, enemy nameplates will be shown during combat and hidden when combat ends.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "EasyItemDestroy"			, 	"Easy item destroy"				,	340, -232, 	true,	"If checked, you will no longer need to type delete when destroying a superior quality item.|n|nIn addition, item links will be shown in all item destroy confirmation windows.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowFlightTimes"			, 	"Show flight times"				, 	340, -252, 	true,	"If checked, flight times will be shown in the flight map and when you take a flight.")

	LeaPlusLC:CfgBtn("SetWeatherDensityBtn", LeaPlusCB["SetWeatherDensity"])
	LeaPlusLC:CfgBtn("MuteGameSoundsBtn", LeaPlusCB["MuteGameSounds"])
	LeaPlusLC:CfgBtn("MuteMountSoundsBtn", LeaPlusCB["MuteMountSounds"])
	LeaPlusLC:CfgBtn("MuteCustomSoundsBtn", LeaPlusCB["MuteCustomSounds"])
	LeaPlusLC:CfgBtn("DismountBtn", LeaPlusCB["StandAndDismount"])
	LeaPlusLC:CfgBtn("ShowFlightTimesBtn", LeaPlusCB["ShowFlightTimes"])

----------------------------------------------------------------------
-- 	LC8: Settings
----------------------------------------------------------------------

	pg = "Page8";

	LeaPlusLC:MakeTx(LeaPlusLC[pg], "Addon"						, 146, -72);
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowMinimapIcon"			, "Show minimap button"				, 146, -92,		false,	"If checked, a minimap button will be available.|n|nClick - Toggle options panel.|n|nSHIFT-click - Toggle music.|n|nALT-click - Toggle errors (if enabled).|n|nCTRL/SHIFT-click - Toggle windowed mode.|n|nCTRL/ALT-click - Toggle Zygor (if installed).")

	LeaPlusLC:MakeTx(LeaPlusLC[pg], "Miscellaneous"				, 146, -132)
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "SetEditModeLayout"			, "Set edit mode layout"			, 146, -152,	false,	"If checked, you can specify an edit mode layout that will always be applied when you login to any character.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "SimpleAddonListing"		, "Simple addon listing"			, 146, -172,	true,	"If checked, the addon listing will be shown in alphabetical order without categories.")

	LeaPlusLC:CreateDropdown("AddonLanguage", "Language", 146, "TOPLEFT", LeaPlusLC[pg], "TOPLEFT", 340, -92, true, {{L["Automatic"], 1}, {L["English"], 2}, {L["Deutsch"], 3}, {L["Español (EU)"], 4}, {L["Español (AL)"], 5}, {L["Français"], 6}, {L["Italiano"], 7}, {L["Português"], 8}, {L["Русский"], 9}, {L["한국어"], 10}, {L["简体中文"], 11}, {L["繁體中文"], 12}})

	LeaPlusLC:MakeTx(LeaPlusLC[pg], "Scale", 340, -142);
	LeaPlusLC:MakeSL(LeaPlusLC[pg], "PlusPanelScale", "Drag to set the scale of the Leatrix Plus panel.", 1, 2, 0.1, 340, -162, "%.1f")

	LeaPlusLC:MakeTx(LeaPlusLC[pg], "Transparency", 340, -202);
	LeaPlusLC:MakeSL(LeaPlusLC[pg], "PlusPanelAlpha", "Drag to set the transparency of the Leatrix Plus panel.", 0, 1, 0.1, 340, -222, "%.1f")

	LeaPlusLC:CfgBtn("SetEditModeLayoutBtn", LeaPlusCB["SetEditModeLayout"])
