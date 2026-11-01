CTT=CreateFrame("Frame")
CTT:SetParent(TargetFrame)
CTT:SetPoint("Right",TargetFrame, 20, 0)
CTT:SetSize(26,26)
CTT.t=CTT:CreateTexture(nil,BORDER)
CTT.t:SetAllPoints()
CTT.t:SetTexture("Interface\\Icons\\ABILITY_DUALWIELD")
CTT:Hide()

local function FrameOnUpdate(self) if UnitAffectingCombat("target") then self:Show() else self:Hide() end end
local g = CreateFrame("Frame")
g:SetScript("OnUpdate", function(self) FrameOnUpdate(CTT) end)

CFT=CreateFrame("Frame")
CFT:SetParent(FocusFrame)
CFT:SetPoint("Right",FocusFrame, 15, 0)
CFT:SetSize(26,26)
CFT.t=CFT:CreateTexture(nil,BORDER)
CFT.t:SetAllPoints()
CFT.t:SetTexture("Interface\\Icons\\ABILITY_DUALWIELD")
CFT:Hide()

local function FrameOnUpdate(self) if UnitAffectingCombat("focus") then self:Show() else self:Hide() end end
local g = CreateFrame("Frame")
g:SetScript("OnUpdate", function(self) FrameOnUpdate(CFT) end)