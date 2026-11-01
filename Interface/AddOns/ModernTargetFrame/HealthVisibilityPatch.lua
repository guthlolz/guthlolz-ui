--[[	Modern TargetFrame Health Visibility Patch
	by SDPhantom
	https://www.wowinterface.com/forums/member.php?u=34145
	https://www.curseforge.com/members/sdphantomgamer/projects	]]
--------------------------------------------------------------------------

--------------------------
--[[	Namespace	]]
--------------------------
local AddOn=select(2,...);
AddOn.Options=AddOn.Options or {};

----------------------------------
--[[	Options Defaults	]]
----------------------------------
AddOn.Options.HealthVisibilityPatch=true;

--------------------------
--[[	Compatability	]]
--------------------------
local TextStatusBar_UpdateTextString=TextStatusBarMixin and TextStatusBarMixin.UpdateTextString or TextStatusBar_UpdateTextString;

------------------
--[[	Patch	]]
------------------
local HealthBars={
	[TargetFrameHealthBar]=true;
};
if FocusFrameHealthBar then HealthBars[FocusFrameHealthBar]=true; end

local function ShouldKnowUnitHealth(unit)--	Lua implementation of how health obfuscation works in the current game
--	Note: Totems/Guardians/Etc are considered NPCs when it comes to health obfuscation
	local guid=UnitGUID(unit);
	local unittype=guid and guid:match("^(.-)%-");

	return	(unittype~="Player" and unittype~="Pet")--	Is NPC? (incl. totem/guardian/etc)
	or	(UnitIsUnit(unit,"player") or UnitIsUnit(unit,"pet"))--	Is player or player's pet?
	or	(UnitPlayerOrPetInRaid(unit) or UnitPlayerOrPetInParty(unit));--	Is in party/raid?
end

local UpdateTextStatusBar; do--	Hack to discard calls to show/hide TextStatusBars (Taint mitigation)
	local TextStatusBarReference;

	local TextStatusBarMethodBlacklist={
--		Method=true/false/nil
--			true=Redirect to no-op
--			false=Call on proxy
--			nil=Call on original (default)

		Show=true;
		Hide=true;
		SetShown=true;
		UpdateTextStringWithValues=false;
	};

	local TextStatusBarProxy=setmetatable({},{
		__index=function(t,k)
			local v=TextStatusBarReference and TextStatusBarReference[k];
			if type(v)=="function" and TextStatusBarMethodBlacklist[k]~=false then
				if TextStatusBarMethodBlacklist[k] then
					rawset(t,k,nop); return nop;
				else
					local func=function(self,...) return v(TextStatusBarReference,...); end
					rawset(t,k,func); return func;
				end
			else return v; end
		end;
		__newindex=nop;
	});

	function UpdateTextStatusBar(self,showpercent)
		TextStatusBarReference=self;
		rawset(TextStatusBarProxy,"showPercentage",showpercent);
		return TextStatusBar_UpdateTextString(TextStatusBarProxy);
	end
end

local function TextStatusBar_UpdateTextStringWithValues(self)
	if AddOn.Options.HealthVisibilityPatch and HealthBars[self] then
--		Verify if percent lock is set
		if self and self.unit and not self.lockValues and self.showPercentage then
--			Re-evaluate and update text
			local known=ShouldKnowUnitHealth(self.unit); if known then
				UpdateTextStatusBar(self,false);
			end
		end
	end
end

if TextStatusBarMixin then
--	hooksecurefunc(TextStatusBarMixin,"UpdateTextStringWithValues",TextStatusBar_UpdateTextStringWithValues);
	hooksecurefunc(TargetFrameHealthBar,"UpdateTextStringWithValues",TextStatusBar_UpdateTextStringWithValues);
	hooksecurefunc(FocusFrameHealthBar,"UpdateTextStringWithValues",TextStatusBar_UpdateTextStringWithValues);
else
	hooksecurefunc("TextStatusBar_UpdateTextStringWithValues",TextStatusBar_UpdateTextStringWithValues);
end

----------------------------------
--[[	Feature Registration	]]
----------------------------------
AddOn.RegisterFeature("HealthVisibilityPatch",function(key,enabled)
	local showhealthfunc=enabled and ShouldKnowUnitHealth or _G.ShouldKnowUnitHealth;--	Select between our custom function and Blizzard's version
	for statusbar in pairs(HealthBars) do
		local unit=statusbar.unit; if unit then
			UpdateTextStatusBar(statusbar,not showhealthfunc(unit));
		end
	end
end);
