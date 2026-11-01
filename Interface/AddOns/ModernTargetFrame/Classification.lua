--[[	Modern TargetFrame Classification Module
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
AddOn.Options.ClassificationTexture=true;

----------------------------------
--[[	Target Classification	]]
----------------------------------
local TextureLock={};
local function TargetFrame_OnCheckClassification(self,lock)
	if self==TargetFrame or self==FocusFrame then
		TextureLock[self]=lock;--	lock is set when forcing the normal texture
		if AddOn.Options.ClassificationTexture and not lock and UnitClassification(self.unit)=="rareelite" then
			self.borderTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Rare-Elite");
		end
	end
end;

if TargetFrame_CheckClassification then
	hooksecurefunc("TargetFrame_CheckClassification",TargetFrame_OnCheckClassification);
elseif TargetFrameMixin and TargetFrameMixin.CheckClassification then
	hooksecurefunc(TargetFrame,"CheckClassification",TargetFrame_OnCheckClassification);
	hooksecurefunc(FocusFrame,"CheckClassification",TargetFrame_OnCheckClassification);
end

----------------------------------
--[[	Feature Registration	]]
----------------------------------
AddOn.RegisterFeature("ClassificationTexture",function()
	if TargetFrame:IsShown() then
--		Texture locks only happen with the disabled FocusFrame
		if TargetFrame_CheckClassification then
			TargetFrame_CheckClassification(TargetFrame,TextureLock[TargetFrame]);
		else
			TargetFrame:CheckClassification(TextureLock[TargetFrame]);
		end
	end
end);
