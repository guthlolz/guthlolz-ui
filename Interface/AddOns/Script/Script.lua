UIP=UnitIsPlayer UIC=UnitIsConnected RCC=RAID_CLASS_COLORS PFHB=PlayerFrameHealthBar UC=UnitClass
function colour(sb,unit) if UIP(unit) and UIC(unit) and unit==sb.unit and UC(unit) then _,cl=UC(unit) c=RAID_CLASS_COLORS[cl] sb:SetStatusBarColor(c.r,c.g,c.b) PFHB:SetStatusBarColor(0,1,0) end end
hooksecurefunc("UnitFrameHealthBar_Update", colour) hooksecurefunc("HealthBar_OnValueChanged", function(self) colour(self, self.unit) end)
-- hooksecurefunc("TargetFrame_UpdateAuras", function(s) for i=1,MAX_TARGET_BUFFS do if select(4,UnitAura(s.unit,i)) == 'Magic' and UnitIsEnemy('player',s.unit) then _G[s:GetName().."Buff"..(i).."Stealable"]:Show() end end end)
-- local f = CreateFrame("Frame")
-- f:SetScript("OnEvent", function(self, event, ...)
    -- TargetFrameToT:ClearAllPoints()
    -- TargetFrameToT:SetPoint("LEFT",TargetFrame,"RIGHT",-108,-38)
-- end)
-- f:RegisterEvent("PLAYER_ENTERING_WORLD")

-- local f = CreateFrame("Frame")
-- f:SetScript("OnEvent", function(self, event, ...)
    -- FocusFrameToT:ClearAllPoints()
    -- FocusFrameToT:SetPoint("LEFT",FocusFrame,"RIGHT",-108,-38)
-- end)
-- f:RegisterEvent("PLAYER_ENTERING_WORLD")
-- SetCVar("nameplateMaxDistance", 41)
-- UIErrorsFrame:SetAlpha(1)
-- UIErrorsFrame:SetSize(400,20)
-- UIErrorsFrame:SetPoint("TOP", 0, -80);

PetFrameHealthBarText:SetAlpha(0)
PetFrameHealthBarTextLeft:SetAlpha(0)
PetFrameHealthBarTextRight:SetAlpha(1)
PetFrameHealthBarTextRight:SetFont("Fonts\\FRIZQT__.ttf",8,"OUTLINE");
PetFrameHealthBarTextRight:SetShadowColor(0, 0, 0, 1)
PetFrameHealthBarTextRight:ClearAllPoints()
PetFrameHealthBarTextRight:SetPoint("CENTER", PetFrameHealthBar, "CENTER", 0, 0)
PetFrameManaBarTextRight:SetFont("Fonts\\FRIZQT__.ttf",8,"OUTLINE");
PetFrameManaBarTextRight:SetShadowColor(0, 0, 0, 1)
PetFrameManaBarTextRight:ClearAllPoints()
PetFrameManaBarTextRight:SetPoint("CENTER", PetFrameManaBar, "CENTER", 0, -2)
PetFrameManaBarText:SetAlpha(1)
PetFrameManaBarTextLeft:SetAlpha(0)
PetFrameManaBarTextRight:SetAlpha(1)

PetFrameHealthBarText:SetAlpha(0)
PetFrameManaBarText:SetAlpha(0)

PlayerName:SetFont("Fonts\\FRIZQT__.ttf",10,"OUTLINE");
PlayerName:SetShadowColor(0, 0, 0, 1)
PlayerFrameHealthBarTextRight:SetFont("Fonts\\FRIZQT__.ttf",10,"OUTLINE");
PlayerFrameHealthBarTextRight:SetShadowColor(0, 0, 0, 1)
PlayerFrameHealthBarTextRight:ClearAllPoints()
PlayerFrameHealthBarTextRight:SetPoint("CENTER", PlayerFrameHealthBar, "CENTER", 0, 0)
PlayerFrameHealthBarTextLeft:SetAlpha(0)
PlayerFrameManaBarTextRight:SetFont("Fonts\\FRIZQT__.ttf",10,"OUTLINE");
PlayerFrameManaBarTextRight:SetShadowColor(0, 0, 0, 1)
PlayerFrameManaBarTextRight:ClearAllPoints()
PlayerFrameManaBarTextRight:SetPoint("CENTER", PlayerFrameManaBar, "CENTER", 0, 0)
PlayerFrameManaBarTextLeft:SetAlpha(0)

TargetFrameHealthBar.RightText:SetFont("Fonts\\FRIZQT__.ttf",10,"OUTLINE");
TargetFrameHealthBar.RightText:SetShadowColor(0, 0, 0, 1)
TargetFrameHealthBar.RightText:ClearAllPoints()
TargetFrameHealthBar.RightText:SetPoint("CENTER", TargetFrameHealthBar, "CENTER", 0, 0)
TargetFrameHealthBar.RightText:SetAlpha(1)
TargetFrameHealthBar.LeftText:SetFont("Fonts\\FRIZQT__.ttf",12,"OUTLINE");
TargetFrameHealthBar.LeftText:SetShadowColor(0, 0, 0, 1)
TargetFrameHealthBar.LeftText:ClearAllPoints()
TargetFrameHealthBar.LeftText:SetPoint("LEFT", TargetFrameHealthBar, "LEFT", 138, 60)
TargetFrameManaBar.RightText:SetFont("Fonts\\FRIZQT__.ttf",10,"OUTLINE");
TargetFrameManaBar.RightText:SetShadowColor(0, 0, 0, 1)
TargetFrameManaBar.RightText:ClearAllPoints()
TargetFrameManaBar.RightText:SetPoint("CENTER", TargetFrameManaBar, "CENTER", 0, 0)
TargetFrameManaBar.LeftText:SetAlpha(0)
TargetFrameHealthBar.TextString:SetFont("Fonts\\FRIZQT__.ttf",10,"OUTLINE");

FocusFrameTextureFrame.HealthBarTextRight:SetFont("Fonts\\FRIZQT__.ttf",10,"OUTLINE");
FocusFrameTextureFrame.HealthBarTextRight:SetShadowColor(0, 0, 0, 1)
FocusFrameTextureFrame.HealthBarTextRight:ClearAllPoints()
FocusFrameTextureFrame.HealthBarTextRight:SetPoint("CENTER", FocusFrameHealthBar, "CENTER", 0, 0)
FocusFrameTextureFrame.HealthBarTextRight:SetAlpha(1)
FocusFrameTextureFrame.HealthBarTextLeft:SetFont("Fonts\\FRIZQT__.ttf",12,"OUTLINE");
FocusFrameTextureFrame.HealthBarTextLeft:SetShadowColor(0, 0, 0, 1)
FocusFrameTextureFrame.HealthBarTextLeft:ClearAllPoints()
FocusFrameTextureFrame.HealthBarTextLeft:SetPoint("LEFT", FocusFrameHealthBar, "LEFT", 0, 32)
FocusFrameTextureFrame.ManaBarTextRight:SetFont("Fonts\\FRIZQT__.ttf",10,"OUTLINE");
FocusFrameTextureFrame.ManaBarTextRight:SetShadowColor(0, 0, 0, 1)
FocusFrameTextureFrame.ManaBarTextRight:ClearAllPoints()
FocusFrameTextureFrame.ManaBarTextRight:SetPoint("CENTER", FocusFrameManaBar, "CENTER", 0, 0)
FocusFrameTextureFrame.ManaBarTextLeft:SetAlpha(0)

-- PetName:SetFont("Fonts\\FRIZQT__.ttf",10,"OUTLINE");
-- PetName:SetShadowColor(0, 0, 0, 1)


-- end)

-- hooksecurefunc("TextStatusBar_UpdateTextStringWithValues", function()
    -- PlayerFrameHealthBarTextRight:SetText(AbbreviateNumbers(UnitHealth("player")))
    -- PetFrameHealthBarTextRight:SetText(AbbreviateNumbers(UnitHealth("pet")))
    -- PetFrameManaBarTextRight:SetText(AbbreviateNumbers(UnitPower("pet")))
    -- PlayerFrameManaBarTextRight:SetText(AbbreviateNumbers(UnitPower("player")))
    -- TargetFrameTextureFrame.HealthBarTextRight:SetText(AbbreviateNumbers(UnitHealth("target")))
    -- TargetFrameTextureFrame.ManaBarTextRight:SetText(AbbreviateNumbers(UnitPower("target")))
    -- FocusFrameTextureFrame.HealthBarTextRight:SetText(AbbreviateNumbers(UnitHealth("focus")))
    -- FocusFrameTextureFrame.ManaBarTextRight:SetText(AbbreviateNumbers(UnitPower("focus")))
-- end)

-- for _, objname in ipairs({

-- "ActionButton1",
-- "ActionButton2",
-- "ActionButton3",
-- "ActionButton4",
-- "ActionButton5",
-- "ActionButton6",
-- "ActionButton7",
-- "ActionButton8",
-- "ActionButton9",
-- "ActionButton10",
-- "ActionButton11",
-- "ActionButton12",

-- "MultiBarLeftButton1",
-- "MultiBarLeftButton2",
-- "MultiBarLeftButton3",
-- "MultiBarLeftButton4",
-- "MultiBarLeftButton5",
-- "MultiBarLeftButton6",
-- "MultiBarLeftButton7",
-- "MultiBarLeftButton8",
-- "MultiBarLeftButton9",
-- "MultiBarLeftButton10",
-- "MultiBarLeftButton11",
-- "MultiBarLeftButton12",



-- "MultiBarRightButton1",
-- "MultiBarRightButton2",
-- "MultiBarRightButton3",
-- "MultiBarRightButton4",
-- "MultiBarRightButton5",
-- "MultiBarRightButton6",
-- "MultiBarRightButton7",
-- "MultiBarRightButton8",
-- "MultiBarRightButton9",
-- "MultiBarRightButton10",
-- "MultiBarRightButton11",
-- "MultiBarRightButton12",


-- "MultiBarBottomLeftButton1",
-- "MultiBarBottomLeftButton2",
-- "MultiBarBottomLeftButton3",
-- "MultiBarBottomLeftButton4",
-- "MultiBarBottomLeftButton5",
-- "MultiBarBottomLeftButton6",
-- "MultiBarBottomLeftButton7",
-- "MultiBarBottomLeftButton8",
-- "MultiBarBottomLeftButton9",
-- "MultiBarBottomLeftButton10",
-- "MultiBarBottomLeftButton11",
-- "MultiBarBottomLeftButton12",


-- "PetActionButton1",
-- "PetActionButton2",
-- "PetActionButton3",
-- "PetActionButton4",
-- "PetActionButton5",
-- "PetActionButton6",
-- "PetActionButton7",
-- "PetActionButton8",
-- "PetActionButton9",
-- "PetActionButton10",


-- "MultiBarBottomRightButton1",
-- "MultiBarBottomRightButton2",
-- "MultiBarBottomRightButton3",
-- "MultiBarBottomRightButton4",
-- "MultiBarBottomRightButton5",
-- "MultiBarBottomRightButton6",
-- "MultiBarBottomRightButton7",
-- "MultiBarBottomRightButton8",
-- "MultiBarBottomRightButton9",
-- "MultiBarBottomRightButton10",
-- "MultiBarBottomRightButton11",
-- "MultiBarBottomRightButton12",

-- "StanceButton1",
-- "StanceButton2",
-- "StanceButton3",

-- "DominosActionButton97",
-- "DominosActionButton98",


-- }) do
    -- local obj = _G[objname]
    -- if obj then
        -- obj.HotKey:SetFont("Fonts\\FRIZQT__.ttf",11,"OUTLINE");
        -- obj.HotKey:SetShadowColor(0, 0, 0, 1)
        -- obj.HotKey:SetFrameLevel(3)

        -- obj.Count:SetFont("Fonts\\FRIZQT__.ttf",11,"OUTLINE");
        -- obj.Count:SetShadowColor(0, 0, 0, 1)
        -- obj.Count:SetFrameLevel(3)
    -- end
-- end

-- TotemFrameTotem1Background:SetAlpha(0)
-- TotemFrameTotem2Background:SetAlpha(0)
-- TotemFrameTotem3Background:SetAlpha(0)
-- TotemFrameTotem4Background:SetAlpha(0)
-- TotemFrameTotem1Duration:SetAlpha(0)
-- TotemFrameTotem2Duration:SetAlpha(0)
-- TotemFrameTotem3Duration:SetAlpha(0)
-- TotemFrameTotem4Duration:SetAlpha(0)

-- TargetFrameTextureFramePVPIcon:SetAlpha(0)
-- FocusFrameTextureFramePVPIcon:SetAlpha(0)

-- RaidBossEmoteFrame:ClearAllPoints()
-- RaidBossEmoteFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 175)

-- hooksecurefunc("CompactUnitFrame_UpdateAggroHighlight", function(self)
                -- if self.aggroHighlight then
                    -- self.aggroHighlight:Hide()
                    -- return
                -- end
            -- end)
