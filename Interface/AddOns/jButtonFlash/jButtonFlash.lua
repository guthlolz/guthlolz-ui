-- locals and speed
local AddonName, jButtonFlash = ...

local CreateFrame = CreateFrame
local hooksecurefunc = hooksecurefunc

-- TBC Classic 2.5.5 API compatibility (uses modern C_AddOns API)
local NUM_ACTIONBAR_BUTTONS = NUM_ACTIONBAR_BUTTONS or 12

-- IsAddOnLoaded: TBC Classic uses C_AddOns.IsAddOnLoaded (modern API)
local IsAddOnLoaded = C_AddOns and C_AddOns.IsAddOnLoaded or _G.IsAddOnLoaded or function() return false end

-- C_Timer.After doesn't exist in TBC Classic - create our own
local C_Timer = C_Timer or {}
if not C_Timer.After then
    C_Timer.After = function(delay, callback)
        local frame = CreateFrame("Frame")
        local elapsed = 0
        frame:SetScript("OnUpdate", function(self, delta)
            elapsed = elapsed + delta
            if elapsed >= delay then
                self:SetScript("OnUpdate", nil)
                callback()
            end
        end)
    end
end

local TEXTURE_OFFSET = 3

local BARTENDER4_ADDON = 'Bartender4'
local BARTENDER4_MAX_BUTTONS = 180

local DOMINOS_ADDON = 'Dominos'
local DOMINOS_MAX_BUTTONS = 14 * NUM_ACTIONBAR_BUTTONS
local DOMINOS_PUSHED_STATE = 'PUSHED'

local ELVUI_ADDON = 'ElvUI'

-- saved variables will be stored in global jButtonFlashDB (declared in .toc)
local defaultDB = { 
    color = {1,1,1}, 
    intensity = 3, 
    glow = 3,
    texture = 4,        -- star4 default
    randomColor = false,
    minimapPos = 220,   -- angle for minimap button
    minimapHide = false, -- hide minimap button
}
local db -- reference after load

-- Color presets for quick selection (will be localized after L is defined)
local COLOR_PRESETS = {}

-- ==============================================================
-- settings & localization
-- ==============================================================

local locale = GetLocale()
local L = {}

-- ============================================================
-- DEUTSCH (German)
-- ============================================================
if locale == 'deDE' then
    L.TITLE = 'jButtonFlash'
    L.COLOR_BUTTON = 'Farbe wählen'
    L.INTENSITY = 'Größe'
    L.GLOW = 'Bling!'
    L.TEXTURE = 'Textur'
    L.RANDOM_COLOR = 'Zufällige Farben'
    L.PRESETS = 'Vorlage'
    L.MINIMAP_TOOLTIP = 'Links-Klick: Einstellungen\nRechts-Klick: Zufallsfarben an/aus'
    L.RANDOM_ON = 'Zufallsfarben |cff00ff00AN|r'
    L.RANDOM_OFF = 'Zufallsfarben |cffff0000AUS|r'
    L.SELECT = 'Auswählen...'
    L.PRESET_WHITE = 'Weiß'
    L.PRESET_GOLD = 'Gold'
    L.PRESET_HOLY = 'Heilig'
    L.PRESET_ARCANE = 'Arkan'
    L.PRESET_FROST = 'Frost'
    L.PRESET_FIRE = 'Feuer'
    L.PRESET_FEL = 'Teufelsmagie'
    L.PRESET_SHADOW = 'Schatten'
    L.PRESET_BLOOD = 'Blut'
    L.PRESET_NATURE = 'Natur'
    L.HIDE_MINIMAP = 'Minimap-Button verstecken'

-- ============================================================
-- RUSSISCH (Russian)
-- ============================================================
elseif locale == 'ruRU' then
    L.TITLE = 'jButtonFlash'
    L.COLOR_BUTTON = 'Выбрать цвет'
    L.INTENSITY = 'Размер'
    L.GLOW = 'Сияние!'
    L.TEXTURE = 'Текстура'
    L.RANDOM_COLOR = 'Случайные цвета'
    L.PRESETS = 'Пресеты'
    L.MINIMAP_TOOLTIP = 'ЛКМ: Настройки\nПКМ: Случайные цвета'
    L.RANDOM_ON = 'Случайные цвета |cff00ff00ВКЛ|r'
    L.RANDOM_OFF = 'Случайные цвета |cffff0000ВЫКЛ|r'
    L.SELECT = 'Выбрать...'
    L.PRESET_WHITE = 'Белый'
    L.PRESET_GOLD = 'Золото'
    L.PRESET_HOLY = 'Свет'
    L.PRESET_ARCANE = 'Тайная магия'
    L.PRESET_FROST = 'Лёд'
    L.PRESET_FIRE = 'Огонь'
    L.PRESET_FEL = 'Скверна'
    L.PRESET_SHADOW = 'Тьма'
    L.PRESET_BLOOD = 'Кровь'
    L.PRESET_NATURE = 'Природа'
    L.HIDE_MINIMAP = 'Скрыть кнопку миникарты'

-- ============================================================
-- FRANZÖSISCH (French)
-- ============================================================
elseif locale == 'frFR' then
    L.TITLE = 'jButtonFlash'
    L.COLOR_BUTTON = 'Choisir couleur'
    L.INTENSITY = 'Taille'
    L.GLOW = 'Éclat!'
    L.TEXTURE = 'Texture'
    L.RANDOM_COLOR = 'Couleurs aléatoires'
    L.PRESETS = 'Préréglages'
    L.MINIMAP_TOOLTIP = 'Clic gauche: Paramètres\nClic droit: Couleurs aléatoires'
    L.RANDOM_ON = 'Couleurs aléatoires |cff00ff00ON|r'
    L.RANDOM_OFF = 'Couleurs aléatoires |cffff0000OFF|r'
    L.SELECT = 'Sélectionner...'
    L.PRESET_WHITE = 'Blanc'
    L.PRESET_GOLD = 'Or'
    L.PRESET_HOLY = 'Sacré'
    L.PRESET_ARCANE = 'Arcane'
    L.PRESET_FROST = 'Givre'
    L.PRESET_FIRE = 'Feu'
    L.PRESET_FEL = 'Gangrène'
    L.PRESET_SHADOW = 'Ombre'
    L.PRESET_BLOOD = 'Sang'
    L.PRESET_NATURE = 'Nature'
    L.HIDE_MINIMAP = 'Masquer bouton minimap'

-- ============================================================
-- SPANISCH (Spanish - Spain & Mexico)
-- ============================================================
elseif locale == 'esES' or locale == 'esMX' then
    L.TITLE = 'jButtonFlash'
    L.COLOR_BUTTON = 'Elegir color'
    L.INTENSITY = 'Tamaño'
    L.GLOW = '¡Brillo!'
    L.TEXTURE = 'Textura'
    L.RANDOM_COLOR = 'Colores aleatorios'
    L.PRESETS = 'Preajustes'
    L.MINIMAP_TOOLTIP = 'Clic izquierdo: Configuración\nClic derecho: Colores aleatorios'
    L.RANDOM_ON = 'Colores aleatorios |cff00ff00ON|r'
    L.RANDOM_OFF = 'Colores aleatorios |cffff0000OFF|r'
    L.SELECT = 'Seleccionar...'
    L.PRESET_WHITE = 'Blanco'
    L.PRESET_GOLD = 'Oro'
    L.PRESET_HOLY = 'Sagrado'
    L.PRESET_ARCANE = 'Arcano'
    L.PRESET_FROST = 'Escarcha'
    L.PRESET_FIRE = 'Fuego'
    L.PRESET_FEL = 'Vil'
    L.PRESET_SHADOW = 'Sombra'
    L.PRESET_BLOOD = 'Sangre'
    L.PRESET_NATURE = 'Naturaleza'
    L.HIDE_MINIMAP = 'Ocultar botón minimapa'

-- ============================================================
-- PORTUGIESISCH (Portuguese - Brazil)
-- ============================================================
elseif locale == 'ptBR' then
    L.TITLE = 'jButtonFlash'
    L.COLOR_BUTTON = 'Escolher cor'
    L.INTENSITY = 'Tamanho'
    L.GLOW = 'Brilho!'
    L.TEXTURE = 'Textura'
    L.RANDOM_COLOR = 'Cores aleatórias'
    L.PRESETS = 'Predefinições'
    L.MINIMAP_TOOLTIP = 'Clique esquerdo: Configurações\nClique direito: Cores aleatórias'
    L.RANDOM_ON = 'Cores aleatórias |cff00ff00ON|r'
    L.RANDOM_OFF = 'Cores aleatórias |cffff0000OFF|r'
    L.SELECT = 'Selecionar...'
    L.PRESET_WHITE = 'Branco'
    L.PRESET_GOLD = 'Ouro'
    L.PRESET_HOLY = 'Sagrado'
    L.PRESET_ARCANE = 'Arcano'
    L.PRESET_FROST = 'Gélido'
    L.PRESET_FIRE = 'Fogo'
    L.PRESET_FEL = 'Vil'
    L.PRESET_SHADOW = 'Sombra'
    L.PRESET_BLOOD = 'Sangue'
    L.PRESET_NATURE = 'Natureza'
    L.HIDE_MINIMAP = 'Ocultar botão minimapa'

-- ============================================================
-- ITALIENISCH (Italian)
-- ============================================================
elseif locale == 'itIT' then
    L.TITLE = 'jButtonFlash'
    L.COLOR_BUTTON = 'Scegli colore'
    L.INTENSITY = 'Dimensione'
    L.GLOW = 'Bagliore!'
    L.TEXTURE = 'Texture'
    L.RANDOM_COLOR = 'Colori casuali'
    L.PRESETS = 'Preset'
    L.MINIMAP_TOOLTIP = 'Clic sinistro: Impostazioni\nClic destro: Colori casuali'
    L.RANDOM_ON = 'Colori casuali |cff00ff00ON|r'
    L.RANDOM_OFF = 'Colori casuali |cffff0000OFF|r'
    L.SELECT = 'Seleziona...'
    L.PRESET_WHITE = 'Bianco'
    L.PRESET_GOLD = 'Oro'
    L.PRESET_HOLY = 'Sacro'
    L.PRESET_ARCANE = 'Arcano'
    L.PRESET_FROST = 'Gelo'
    L.PRESET_FIRE = 'Fuoco'
    L.PRESET_FEL = 'Vile'
    L.PRESET_SHADOW = 'Ombra'
    L.PRESET_BLOOD = 'Sangue'
    L.PRESET_NATURE = 'Natura'
    L.HIDE_MINIMAP = 'Nascondi pulsante minimappa'

-- ============================================================
-- KOREANISCH (Korean)
-- ============================================================
elseif locale == 'koKR' then
    L.TITLE = 'jButtonFlash'
    L.COLOR_BUTTON = '색상 선택'
    L.INTENSITY = '크기'
    L.GLOW = '반짝임!'
    L.TEXTURE = '텍스처'
    L.RANDOM_COLOR = '무작위 색상'
    L.PRESETS = '프리셋'
    L.MINIMAP_TOOLTIP = '좌클릭: 설정\n우클릭: 무작위 색상'
    L.RANDOM_ON = '무작위 색상 |cff00ff00켜짐|r'
    L.RANDOM_OFF = '무작위 색상 |cffff0000꺼짐|r'
    L.SELECT = '선택...'
    L.PRESET_WHITE = '흰색'
    L.PRESET_GOLD = '황금'
    L.PRESET_HOLY = '신성'
    L.PRESET_ARCANE = '비전'
    L.PRESET_FROST = '냉기'
    L.PRESET_FIRE = '화염'
    L.PRESET_FEL = '지옥'
    L.PRESET_SHADOW = '암흑'
    L.PRESET_BLOOD = '피'
    L.PRESET_NATURE = '자연'
    L.HIDE_MINIMAP = '미니맵 버튼 숨기기'

-- ============================================================
-- CHINESISCH VEREINFACHT (Simplified Chinese - China)
-- ============================================================
elseif locale == 'zhCN' then
    L.TITLE = 'jButtonFlash'
    L.COLOR_BUTTON = '选择颜色'
    L.INTENSITY = '大小'
    L.GLOW = '闪光!'
    L.TEXTURE = '材质'
    L.RANDOM_COLOR = '随机颜色'
    L.PRESETS = '预设'
    L.MINIMAP_TOOLTIP = '左键: 设置\n右键: 随机颜色'
    L.RANDOM_ON = '随机颜色 |cff00ff00开启|r'
    L.RANDOM_OFF = '随机颜色 |cffff0000关闭|r'
    L.SELECT = '选择...'
    L.PRESET_WHITE = '白色'
    L.PRESET_GOLD = '金色'
    L.PRESET_HOLY = '神圣'
    L.PRESET_ARCANE = '奥术'
    L.PRESET_FROST = '冰霜'
    L.PRESET_FIRE = '火焰'
    L.PRESET_FEL = '邪能'
    L.PRESET_SHADOW = '暗影'
    L.PRESET_BLOOD = '鲜血'
    L.PRESET_NATURE = '自然'
    L.HIDE_MINIMAP = '隐藏小地图按钮'

-- ============================================================
-- CHINESISCH TRADITIONELL (Traditional Chinese - Taiwan)
-- ============================================================
elseif locale == 'zhTW' then
    L.TITLE = 'jButtonFlash'
    L.COLOR_BUTTON = '選擇顏色'
    L.INTENSITY = '大小'
    L.GLOW = '閃光!'
    L.TEXTURE = '材質'
    L.RANDOM_COLOR = '隨機顏色'
    L.PRESETS = '預設'
    L.MINIMAP_TOOLTIP = '左鍵: 設定\n右鍵: 隨機顏色'
    L.RANDOM_ON = '隨機顏色 |cff00ff00開啟|r'
    L.RANDOM_OFF = '隨機顏色 |cffff0000關閉|r'
    L.SELECT = '選擇...'
    L.PRESET_WHITE = '白色'
    L.PRESET_GOLD = '金色'
    L.PRESET_HOLY = '神聖'
    L.PRESET_ARCANE = '秘法'
    L.PRESET_FROST = '冰霜'
    L.PRESET_FIRE = '火焰'
    L.PRESET_FEL = '乘魔'
    L.PRESET_SHADOW = '暗影'
    L.PRESET_BLOOD = '鮮血'
    L.PRESET_NATURE = '自然'
    L.HIDE_MINIMAP = '隱藏小地圖按鈕'

-- ============================================================
-- ENGLISCH (English - Default/Fallback)
-- ============================================================
else
    L.TITLE = 'jButtonFlash'
    L.COLOR_BUTTON = 'Pick Color'
    L.INTENSITY = 'Size'
    L.GLOW = 'Bling!'
    L.TEXTURE = 'Texture'
    L.RANDOM_COLOR = 'Random Colors'
    L.PRESETS = 'Presets'
    L.MINIMAP_TOOLTIP = 'Left-Click: Settings\nRight-Click: Toggle Random Colors'
    L.RANDOM_ON = 'Random Colors |cff00ff00ON|r'
    L.RANDOM_OFF = 'Random Colors |cffff0000OFF|r'
    L.SELECT = 'Select...'
    L.PRESET_WHITE = 'White'
    L.PRESET_GOLD = 'Gold'
    L.PRESET_HOLY = 'Holy'
    L.PRESET_ARCANE = 'Arcane'
    L.PRESET_FROST = 'Frost'
    L.PRESET_FIRE = 'Fire'
    L.PRESET_FEL = 'Fel'
    L.PRESET_SHADOW = 'Shadow'
    L.PRESET_BLOOD = 'Blood'
    L.PRESET_NATURE = 'Nature'
    L.HIDE_MINIMAP = 'Hide Minimap Button'
end

-- Color presets (now with localized names)
COLOR_PRESETS = {
    { name = L.PRESET_WHITE,   color = {1, 1, 1} },
    { name = L.PRESET_GOLD,    color = {1, 0.84, 0} },
    { name = L.PRESET_HOLY,    color = {1, 0.9, 0.5} },
    { name = L.PRESET_ARCANE,  color = {0.6, 0.4, 1} },
    { name = L.PRESET_FROST,   color = {0.4, 0.8, 1} },
    { name = L.PRESET_FIRE,    color = {1, 0.4, 0.1} },
    { name = L.PRESET_FEL,     color = {0.4, 1, 0.4} },
    { name = L.PRESET_SHADOW,  color = {0.6, 0.2, 0.8} },
    { name = L.PRESET_BLOOD,   color = {0.8, 0.1, 0.1} },
    { name = L.PRESET_NATURE,  color = {0.3, 0.9, 0.3} },
}

-- user-modifiable state (saved only in session)
local flashColor = {1, 1, 1}         -- default white
local flashIntensity = 3             -- 1-6 (size)
local flashGlow = 3                  -- 1-6 (brightness/alpha)

-- scale lookup by intensity (size of the flash effect)
local INTENSITY_SCALE = {1.5, 2.0, 2.5, 3.0, 4.0, 5.0}

-- glow/brightness levels - affects multiple layers for real visible difference
local GLOW_SETTINGS = {
    [1] = { layers = 1, alpha = 0.4, duration = 0.25 },
    [2] = { layers = 1, alpha = 0.6, duration = 0.28 },
    [3] = { layers = 1, alpha = 0.8, duration = 0.30 },
    [4] = { layers = 2, alpha = 0.9, duration = 0.32 },
    [5] = { layers = 2, alpha = 1.0, duration = 0.35 },
    [6] = { layers = 3, alpha = 1.0, duration = 0.40 },  -- MAXIMUM BLING
}

-- default intensity
jButtonFlash_intensity = 3

-- effect texture (star4 - confirmed working in Retail)
local EFFECT_TEXTURE = [[Interface\Cooldown\star4]]

-- state variables
jButtonFlash_textureIndex = 1 -- always star4 (kept for backwards compatibility)
jButtonFlash_randomColor = false

-- ==============================================================
-- Retail Action Button mappings
-- ==============================================================

-- Map action IDs to button frames for Retail (GetActionButtonForID doesn't exist)
local function GetActionButtonForID(id)
    -- Main action bar (1-12)
    if id >= 1 and id <= 12 then
        return _G["ActionButton" .. id]
    end
    -- MultiBarBottomLeft (25-36 -> buttons 1-12)
    if id >= 25 and id <= 36 then
        return _G["MultiBarBottomLeftButton" .. (id - 24)]
    end
    -- MultiBarBottomRight (37-48 -> buttons 1-12)
    if id >= 37 and id <= 48 then
        return _G["MultiBarBottomRightButton" .. (id - 36)]
    end
    -- MultiBarRight (49-60 -> buttons 1-12)
    if id >= 49 and id <= 60 then
        return _G["MultiBarRightButton" .. (id - 48)]
    end
    -- MultiBarLeft (61-72 -> buttons 1-12)
    if id >= 61 and id <= 72 then
        return _G["MultiBarLeftButton" .. (id - 60)]
    end
    -- Paging bars (13-24, 73-120) - these map to ActionButton1-12 with bar swapping
    if id >= 13 and id <= 24 then
        return _G["ActionButton" .. (id - 12)]
    end
    if id >= 73 and id <= 120 then
        local page = math.floor((id - 73) / 12) + 1
        local buttonId = ((id - 73) % 12) + 1
        return _G["ActionButton" .. buttonId]
    end
    return nil
end

-- main
function jButtonFlash:Initialize()
    self.frame = CreateFrame('Frame', nil)

    -- seed RNG once (if function exists)
    if math.randomseed then
        math.randomseed(time())
    end

    -- set OnEvent handler
    self.frame:SetScript('OnEvent', function(_, ...)
        self:EventHandler(...)
    end)

    self.frame:RegisterEvent('ADDON_LOADED')
    self.frame:RegisterEvent('PLAYER_LOGIN')
end

-- frame events
function jButtonFlash:EventHandler(event, ...)
    local action = self[event]

    if (action) then
        action(self, ...)
    end
end

function jButtonFlash:ADDON_LOADED(addon)
    if addon ~= AddonName then return end

    -- load saved variables
    if not jButtonFlashDB then
        jButtonFlashDB = CopyTable(defaultDB)
    end
    db = jButtonFlashDB
    
    -- migrate old DBs
    if db.texture == nil then db.texture = defaultDB.texture end
    if db.randomColor == nil then db.randomColor = defaultDB.randomColor end
    if db.minimapPos == nil then db.minimapPos = defaultDB.minimapPos end

    -- apply to runtime vars
    local c = db.color or defaultDB.color
    flashColor = {c[1], c[2], c[3]}
    flashIntensity = db.intensity or defaultDB.intensity
    flashGlow = db.glow or defaultDB.glow
    jButtonFlash_textureIndex = db.texture or defaultDB.texture
    jButtonFlash_randomColor = db.randomColor or false

    -- unregister; not needed anymore
    self.frame:UnregisterEvent('ADDON_LOADED')
end

function jButtonFlash:PLAYER_LOGIN()
    self:SetupButtonFlash()
    self:HookActionButtons()
    self:HookActionEvents()

    -- build the options panel / slash command
    self:CreateOptionsPanel()
    self:CreateMinimapButton()

    local bt4 = IsAddOnLoaded(BARTENDER4_ADDON)
    if (bt4) then
        self:HookBartender4Buttons()
    end

    local dominos = IsAddOnLoaded(DOMINOS_ADDON)
    if (dominos) then
        self:HookDominosButtons()
        -- Multiple delayed passes: Dominos (TBC) creates bar 2+ on demand, so hook again later
        for _, delay in ipairs({ 0.5, 1.5, 3, 5, 8 }) do
            C_Timer.After(delay, function() jButtonFlash:HookDominosButtons() end)
        end
    end

    local elvui = IsAddOnLoaded(ELVUI_ADDON)
    if (elvui) then
        self:HookElvUIButtons()
    end

    self.frame:UnregisterEvent('PLAYER_LOGIN')
end

function jButtonFlash:SetupButtonFlash()
    -- Create multiple overlay layers for stacking glow effect
    self.overlays = {}
    self.animations = {}
    self.textures = {}
    
    for i = 1, 3 do  -- max 3 layers
        local frame = CreateFrame('Frame', nil)
        frame:SetFrameStrata('TOOLTIP')
        frame:SetFrameLevel(100 + i)

        local texture = frame:CreateTexture()
        texture:SetTexture(EFFECT_TEXTURE)
        texture:SetAlpha(0)
        texture:SetAllPoints(frame)
        texture:SetBlendMode('ADD')
        texture:SetDrawLayer('OVERLAY', 7)
        texture:SetVertexColor(flashColor[1], flashColor[2], flashColor[3])

        local animation = texture:CreateAnimationGroup()

        -- Alpha animation
        local alpha = animation:CreateAnimation('Alpha')
        alpha:SetFromAlpha(0)
        alpha:SetToAlpha(1)
        alpha:SetDuration(0)
        alpha:SetOrder(1)

        -- Initial scale (size of flash) - slightly offset for layers
        local scale1 = animation:CreateAnimation('Scale')
        local baseScale = INTENSITY_SCALE[flashIntensity] or 2.0
        local layerScale = baseScale + (i - 1) * 0.3  -- each layer slightly bigger
        scale1:SetScale(layerScale, layerScale)
        scale1:SetDuration(0)
        scale1:SetOrder(1)

        -- Scale down animation
        local scale2 = animation:CreateAnimation('Scale')
        scale2:SetScale(0, 0)
        scale2:SetDuration(0.3)
        scale2:SetOrder(2)

        -- Rotation for extra bling - different rotation per layer
        local rotation = animation:CreateAnimation('Rotation')
        rotation:SetDegrees(90 + (i - 1) * 30)  -- 90, 120, 150 degrees per layer
        rotation:SetDuration(0.3)
        rotation:SetOrder(2)

        self.overlays[i] = frame
        self.animations[i] = animation
        self.textures[i] = texture
        
        -- Store references for first layer (backwards compat)
        if i == 1 then
            self.overlay = frame
            self.animation = animation
            self.scaleAnim = scale1
            self.texture = texture
        end
    end

    -- Apply initial glow settings
    self:ApplyGlowSettings()
end

function jButtonFlash:ApplyGlowSettings()
    local settings = GLOW_SETTINGS[flashGlow] or GLOW_SETTINGS[3]
    
    for i = 1, 3 do
        if self.textures[i] then
            -- Set color
            self.textures[i]:SetVertexColor(flashColor[1], flashColor[2], flashColor[3])
            
            -- Set alpha based on layer and glow level
            local layerAlpha = settings.alpha
            if i > 1 then
                layerAlpha = layerAlpha * 0.7  -- secondary layers slightly dimmer
            end
            
            -- Update alpha animation and rotation
            local anim = self.animations[i]
            if anim then
                for _, a in pairs({anim:GetAnimations()}) do
                    if a:GetObjectType() == "Alpha" then
                        a:SetToAlpha(layerAlpha)
                    end
                    -- Update duration for all animations in order 2
                    if a:GetOrder() == 2 then
                        a:SetDuration(settings.duration)
                    end
                end
            end
        end
    end
end

-- ==============================================================
-- Hook all action buttons directly (Retail approach)
-- ==============================================================

function jButtonFlash:HookActionButtons()
    -- Hook main action bar buttons
    for i = 1, 12 do
        local button = _G["ActionButton" .. i]
        if button then
            self:HookButton(button)
        end
    end
    
    -- Hook MultiBar buttons (TBC Classic only has these 4)
    local barNames = {
        "MultiBarBottomLeft",
        "MultiBarBottomRight", 
        "MultiBarRight",
        "MultiBarLeft",
    }
    
    for _, barName in ipairs(barNames) do
        for i = 1, 12 do
            local button = _G[barName .. "Button" .. i]
            if button then
                self:HookButton(button)
            end
        end
    end
    
    -- Hook pet bar buttons
    for i = 1, 10 do
        local button = _G["PetActionButton" .. i]
        if button then
            self:HookButton(button)
        end
    end
    
    -- Hook stance/shapeshift bar buttons (TBC uses ShapeshiftButton)
    for i = 1, 10 do
        local button = _G["ShapeshiftButton" .. i] or _G["StanceButton" .. i]
        if button then
            self:HookButton(button)
        end
    end
end

function jButtonFlash:HookButton(button)
    if not button or button._jButtonFlashHooked then return end
    button._jButtonFlashHooked = true
    
    -- Hook OnMouseDown for immediate visual feedback
    button:HookScript('OnMouseDown', function(btn)
        self:AnimateButton(btn)
    end)
end

-- hooks
-- regular action buttons (legacy hook system for compatibility)
do
    local function Button_ActionButtonDown(id)
        jButtonFlash:ActionButtonDown(id)
    end

    local function Button_MultiActionButtonDown(bar, id)
        jButtonFlash:MultiActionButtonDown(bar, id)
    end

    function jButtonFlash:HookActionEvents()
        -- These might not exist in all Retail versions, wrap in pcall
        if ActionButtonDown then
            hooksecurefunc('ActionButtonDown', Button_ActionButtonDown)
        end
        if MultiActionButtonDown then
            hooksecurefunc('MultiActionButtonDown', Button_MultiActionButtonDown)
        end
    end
end

-- bartender4 support
do
    local function Button_OnMouseDown(button)
        jButtonFlash:AnimateButton(button)
    end

    function jButtonFlash:HookBartender4Buttons()
        -- Try to hook LibActionButton directly (works with current Bartender4)
        if LibStub then
            -- Try multiple library versions (Bartender4 uses different forks)
            local LAB = LibStub:GetLibrary("LibActionButton-1.0", true)
                     or LibStub:GetLibrary("LibActionButton-1.0-ElvUI", true)
            
            if LAB and LAB.RegisterCallback then
                -- Modern approach: use library callbacks if available
                LAB:RegisterCallback("OnButtonUpdate", function(_, button)
                    if button and button:GetButtonState() == "PUSHED" then
                        jButtonFlash:AnimateButton(button)
                    end
                end)
            end
        end

        -- Hook individual buttons (primary method - most reliable)
        for i = 1, BARTENDER4_MAX_BUTTONS do
            local button = _G['BT4Button' .. i]
            if button and not button._jButtonFlashHooked then
                button._jButtonFlashHooked = true
                button:HookScript('OnMouseDown', Button_OnMouseDown)
            end
        end
        
        -- Also try Bartender4's ActionBar buttons format
        for barId = 1, 15 do
            for buttonId = 1, 12 do
                local button = _G['BT4Bar' .. barId .. 'Button' .. buttonId]
                if button and not button._jButtonFlashHooked then
                    button._jButtonFlashHooked = true
                    button:HookScript('OnMouseDown', Button_OnMouseDown)
                end
            end
        end
    end
end

-- elvui support
do
    local function Button_OnMouseDown(button)
        jButtonFlash:AnimateButton(button)
    end

    function jButtonFlash:HookElvUIButtons()
        -- ElvUI ActionBar buttons: ElvUI_Bar1Button1 - ElvUI_Bar10Button12
        for barId = 1, 10 do
            for buttonId = 1, 12 do
                local button = _G['ElvUI_Bar' .. barId .. 'Button' .. buttonId]
                if button and not button._jButtonFlashHooked then
                    button._jButtonFlashHooked = true
                    button:HookScript('OnMouseDown', Button_OnMouseDown)
                end
            end
        end
        
        -- ElvUI pet bar buttons
        for i = 1, 10 do
            local button = _G['ElvUI_BarPetButton' .. i]
            if button and not button._jButtonFlashHooked then
                button._jButtonFlashHooked = true
                button:HookScript('OnMouseDown', Button_OnMouseDown)
            end
        end
        
        -- ElvUI stance bar buttons
        for i = 1, 10 do
            local button = _G['ElvUI_StanceBarButton' .. i]
            if button and not button._jButtonFlashHooked then
                button._jButtonFlashHooked = true
                button:HookScript('OnMouseDown', Button_OnMouseDown)
            end
        end
        
        -- Try to hook via LibActionButton-1.0-ElvUI if available
        if LibStub then
            local LAB = LibStub:GetLibrary("LibActionButton-1.0-ElvUI", true)
            if LAB and LAB.RegisterCallback then
                LAB:RegisterCallback("OnButtonUpdate", function(_, button)
                    if button and button:GetButtonState() == "PUSHED" then
                        jButtonFlash:AnimateButton(button)
                    end
                end)
            end
        end
    end
end

-- dominos support (TBC: Dominos uses child "Hotkey" button for clicks; hook parent + children so either click triggers flash)
do
    local function Button_OnMouseDown(button)
        jButtonFlash:AnimateButton(button)
    end

    -- Hook one Dominos action button and its click-receiving children (e.g. Hotkey child in TBC/Retail)
    local function HookOneDominosButton(mainButton)
        if not mainButton or mainButton._jButtonFlashHooked then return false end
        mainButton._jButtonFlashHooked = true
        local ok = pcall(function() mainButton:HookScript('OnMouseDown', function() jButtonFlash:AnimateButton(mainButton) end) end)
        if not ok then mainButton._jButtonFlashHooked = false return false end
        -- Children (e.g. "$parentHotkey") often receive the actual click in Dominos; hook them to flash the parent
        local children = { mainButton:GetChildren() }
        for _, child in ipairs(children) do
            if child and not child._jButtonFlashChildHooked and (child:GetObjectType() == 'Button' or child:GetObjectType() == 'CheckButton') then
                child._jButtonFlashChildHooked = true
                pcall(function() child:HookScript('OnMouseDown', function() jButtonFlash:AnimateButton(mainButton) end) end)
            end
        end
        return true
    end

    -- Dominos (buttons.lua) uses these names per bar: 1-2 DominosActionButton, 3-6 MultiBar*ActionButton, 7-11 DominosActionButton, 12-14 MultiBar5/6/7ActionButton
    local DOMINOS_MULTIBAR_PREFIXES = {
        'MultiBarRightActionButton',      -- bar 3
        'MultiBarLeftActionButton',       -- bar 4
        'MultiBarBottomRightActionButton',-- bar 5
        'MultiBarBottomLeftActionButton', -- bar 6
        'MultiBar5ActionButton',          -- bar 12
        'MultiBar6ActionButton',          -- bar 13
        'MultiBar7ActionButton',          -- bar 14
    }

    function jButtonFlash:HookDominosButtons()
        local hookedAction, hookedPet, hookedStance, hookedExtra = 0, 0, 0, 0
        -- Hook DominosActionButton1-168 (bars 1-2 and 7-11)
        for i = 1, DOMINOS_MAX_BUTTONS do
            local button = _G['DominosActionButton' .. i]
            if button then
                if HookOneDominosButton(button) then hookedAction = hookedAction + 1 end
            end
        end
        -- Hook MultiBar*ActionButton1-12 (bars 3-6 and 12-14) when used by Dominos
        for _, prefix in ipairs(DOMINOS_MULTIBAR_PREFIXES) do
            for i = 1, 12 do
                local button = _G[prefix .. i]
                if button then
                    if HookOneDominosButton(button) then hookedAction = hookedAction + 1 end
                end
            end
        end

        -- Hook Dominos pet bar buttons
        for i = 1, 10 do
            local button = _G['DominosPetActionButton' .. i]
            if button and not button._jButtonFlashHooked then
                button._jButtonFlashHooked = true
                local ok = pcall(function() button:HookScript('OnMouseDown', Button_OnMouseDown) end)
                if ok then hookedPet = hookedPet + 1 else button._jButtonFlashHooked = false end
            end
        end

        -- Hook Dominos stance bar buttons
        for i = 1, 10 do
            local button = _G['DominosStanceButton' .. i] or _G['DominosClassButton' .. i]
            if button and not button._jButtonFlashHooked then
                button._jButtonFlashHooked = true
                local ok = pcall(function() button:HookScript('OnMouseDown', Button_OnMouseDown) end)
                if ok then hookedStance = hookedStance + 1 else button._jButtonFlashHooked = false end
            end
        end

        -- Hook Dominos extra action button
        local extraButton = _G['DominosExtraActionButton']
        if extraButton and not extraButton._jButtonFlashHooked then
            extraButton._jButtonFlashHooked = true
            local ok = pcall(function() extraButton:HookScript('OnMouseDown', Button_OnMouseDown) end)
            if ok then hookedExtra = 1 else extraButton._jButtonFlashHooked = false end
        end
    end
end

function jButtonFlash:ActionButtonDown(id)
    local button = GetActionButtonForID(id)
    if (button) then
        self:AnimateButton(button)
    end
end

function jButtonFlash:MultiActionButtonDown(bar, id)
    local button = _G[bar .. 'Button' .. id]
    if (button) then
        self:AnimateButton(button)
    end
end

-- Re-hook Dominos periodically so late-created bars get the flash (TBC creates bars on demand)
local lastDominosRehook = 0
function jButtonFlash:AnimateButton(button)
    if (not button:IsVisible()) then
        return
    end
    if IsAddOnLoaded(DOMINOS_ADDON) then
        local t = GetTime()
        if t - lastDominosRehook >= 2 then
            lastDominosRehook = t
            self:HookDominosButtons()
        end
    end

    local settings = GLOW_SETTINGS[flashGlow] or GLOW_SETTINGS[3]
    local numLayers = settings.layers

    -- apply random color if enabled
    local r, g, b = flashColor[1], flashColor[2], flashColor[3]
    if jButtonFlash_randomColor then
        r, g, b = math.random(), math.random(), math.random()
    end

    -- Animate each active layer
    for i = 1, 3 do
        local overlay = self.overlays[i]
        local animation = self.animations[i]
        local texture = self.textures[i]
        
        if overlay and animation and texture then
            if i <= numLayers then
                -- Position overlay on button
                overlay:ClearAllPoints()
                overlay:SetPoint('TOPLEFT', button, 'TOPLEFT', -TEXTURE_OFFSET, TEXTURE_OFFSET)
                overlay:SetPoint('BOTTOMRIGHT', button, 'BOTTOMRIGHT', TEXTURE_OFFSET, -TEXTURE_OFFSET)
                
                -- Set color
                texture:SetVertexColor(r, g, b)
                
                -- Play with slight delay for staggered effect
                animation:Stop()
                if i == 1 then
                    animation:Play()
                else
                    C_Timer.After(0.02 * (i - 1), function()
                        animation:Play()
                    end)
                end
            else
                -- Stop inactive layers
                animation:Stop()
            end
        end
    end
end

-- cycle to next texture (kept for API compatibility, but only uses star4)
function jButtonFlash:NextTexture()
    -- Only star4 is used now
end

-- ==============================================================
-- helpers to change settings at runtime
-- ==============================================================

function jButtonFlash:SetFlashColor(r, g, b)
    flashColor[1], flashColor[2], flashColor[3] = r, g, b
    if db then db.color = {r, g, b} end
    -- Update all layer colors
    for i = 1, 3 do
        if self.textures and self.textures[i] then
            self.textures[i]:SetVertexColor(r, g, b)
        end
    end
    -- Update color swatch in GUI
    if self.colorSwatch and self.colorSwatch.SetBackdropColor then
        self.colorSwatch:SetBackdropColor(r, g, b, 1)
    end
end

function jButtonFlash:SetIntensity(level)
    level = math.floor(level)
    if level < 1 then level = 1 elseif level > 6 then level = 6 end
    flashIntensity = level
    if db then db.intensity = level end
    
    -- Update scale for all layers
    local baseScale = INTENSITY_SCALE[level] or 2.0
    for i = 1, 3 do
        if self.animations and self.animations[i] then
            local layerScale = baseScale + (i - 1) * 0.3
            for _, anim in pairs({self.animations[i]:GetAnimations()}) do
                if anim:GetObjectType() == "Scale" and anim:GetOrder() == 1 then
                    anim:SetScale(layerScale, layerScale)
                end
            end
        end
    end
end

function jButtonFlash:SetGlow(level)
    level = math.floor(level)
    if level < 1 then level = 1 elseif level > 6 then level = 6 end
    flashGlow = level
    if db then db.glow = level end
    
    -- Apply new glow settings to all layers
    self:ApplyGlowSettings()
end

-- ==============================================================
-- GUI
-- ==============================================================

function jButtonFlash:CreateOptionsPanel()
    if self.optionsPanel then return self.optionsPanel end

    local parent = UIParent
    local panel = CreateFrame('Frame', 'jButtonFlashOptions', parent, 'BackdropTemplate')
    panel:SetSize(320, 340)
    panel:SetPoint('CENTER')
    panel:SetBackdrop({bgFile='Interface/Tooltips/UI-Tooltip-Background', edgeFile='Interface/Tooltips/UI-Tooltip-Border', tile=true, tileSize=16, edgeSize=16, insets={left=4,right=4,top=4,bottom=4}})
    panel:SetBackdropColor(0.05, 0.05, 0.1, 0.95)
    panel:Hide()
    panel:SetFrameStrata("DIALOG")

    -- Make draggable
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", panel.StopMovingOrSizing)

    -- close button
    local closeBtn = CreateFrame('Button', nil, panel, 'UIPanelCloseButton')
    closeBtn:SetPoint('TOPRIGHT', panel, 'TOPRIGHT', -4, -4)

    -- title
    local title = panel:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
    title:SetPoint('TOP', 0, -12)
    title:SetText(L.TITLE)

    local yOffset = -40

    -- ============ COLOR PRESETS ============
    local presetLabel = panel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
    presetLabel:SetPoint('TOPLEFT', panel, 'TOPLEFT', 16, yOffset)
    presetLabel:SetText(L.PRESETS)

    local presetDropdown = CreateFrame('Frame', 'jButtonFlashPresetDropdown', panel, 'UIDropDownMenuTemplate')
    presetDropdown:SetPoint('LEFT', presetLabel, 'RIGHT', -5, -2)
    UIDropDownMenu_SetWidth(presetDropdown, 120)
    UIDropDownMenu_SetText(presetDropdown, L.SELECT)
    
    UIDropDownMenu_Initialize(presetDropdown, function(self, level)
        for i, preset in ipairs(COLOR_PRESETS) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = preset.name
            info.func = function()
                jButtonFlash:SetFlashColor(preset.color[1], preset.color[2], preset.color[3])
                UIDropDownMenu_SetText(presetDropdown, preset.name)
                CloseDropDownMenus()
            end
            -- Color swatch
            info.hasColorSwatch = true
            info.r, info.g, info.b = preset.color[1], preset.color[2], preset.color[3]
            info.swatchFunc = function() end
            info.cancelFunc = function() end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    yOffset = yOffset - 35

    -- ============ CUSTOM COLOR BUTTON ============
    local colorBtn = CreateFrame('Button', nil, panel, 'UIPanelButtonTemplate')
    colorBtn:SetSize(140, 22)
    colorBtn:SetPoint('TOPLEFT', panel, 'TOPLEFT', 16, yOffset)
    colorBtn:SetText(L.COLOR_BUTTON)
    colorBtn:SetScript('OnClick', function()
        self:OpenColorPicker()
    end)

    -- Color preview swatch (use BackdropTemplate for SetBackdrop)
    local colorSwatch = CreateFrame('Frame', nil, panel, 'BackdropTemplate')
    colorSwatch:SetSize(22, 22)
    colorSwatch:SetPoint('LEFT', colorBtn, 'RIGHT', 8, 0)
    colorSwatch:SetBackdrop({bgFile='Interface/BUTTONS/WHITE8X8', edgeFile='Interface/Tooltips/UI-Tooltip-Border', edgeSize=8, insets={left=1,right=1,top=1,bottom=1}})
    colorSwatch:SetBackdropColor(flashColor[1], flashColor[2], flashColor[3], 1)
    colorSwatch:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    self.colorSwatch = colorSwatch

    yOffset = yOffset - 35

    -- ============ RANDOM COLOR CHECKBOX ============
    local randomCheck = CreateFrame('CheckButton', 'jButtonFlashRandomCheck', panel, 'UICheckButtonTemplate')
    randomCheck:SetPoint('TOPLEFT', panel, 'TOPLEFT', 12, yOffset)
    randomCheck:SetChecked(jButtonFlash_randomColor)
    _G[randomCheck:GetName()..'Text']:SetText(L.RANDOM_COLOR)
    randomCheck:SetScript('OnClick', function(self)
        jButtonFlash:SetRandomColor(self:GetChecked())
    end)
    self.randomCheckbox = randomCheck

    yOffset = yOffset - 40

    -- ============ SIZE SLIDER ============
    local sizeSlider = CreateFrame('Slider', 'jButtonFlashSizeSlider', panel, 'OptionsSliderTemplate')
    sizeSlider:SetPoint('TOPLEFT', panel, 'TOPLEFT', 20, yOffset)
    sizeSlider:SetMinMaxValues(1, 6)
    sizeSlider:SetValueStep(1)
    sizeSlider:SetObeyStepOnDrag(true)
    sizeSlider:SetWidth(220)
    sizeSlider:SetValue(flashIntensity)
    _G[sizeSlider:GetName()..'Low']:SetText('1')
    _G[sizeSlider:GetName()..'High']:SetText('6')
    _G[sizeSlider:GetName()..'Text']:SetText(L.INTENSITY)
    
    -- Value display for size slider
    local sizeValue = panel:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightLarge')
    sizeValue:SetPoint('LEFT', sizeSlider, 'RIGHT', 15, 0)
    sizeValue:SetText(tostring(math.floor(flashIntensity)))
    sizeValue:SetTextColor(1, 0.8, 0)
    self.sizeValueText = sizeValue
    
    sizeSlider:SetScript('OnValueChanged', function(_, val)
        val = math.floor(val)
        self:SetIntensity(val)
        sizeValue:SetText(tostring(val))
    end)

    yOffset = yOffset - 50

    -- ============ BLING SLIDER ============
    local glowSlider = CreateFrame('Slider', 'jButtonFlashGlowSlider', panel, 'OptionsSliderTemplate')
    glowSlider:SetPoint('TOPLEFT', panel, 'TOPLEFT', 20, yOffset)
    glowSlider:SetMinMaxValues(1, 6)
    glowSlider:SetValueStep(1)
    glowSlider:SetObeyStepOnDrag(true)
    glowSlider:SetWidth(220)
    glowSlider:SetValue(flashGlow)
    _G[glowSlider:GetName()..'Low']:SetText('1')
    _G[glowSlider:GetName()..'High']:SetText('6')
    _G[glowSlider:GetName()..'Text']:SetText(L.GLOW)
    
    -- Value display for bling slider
    local glowValue = panel:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightLarge')
    glowValue:SetPoint('LEFT', glowSlider, 'RIGHT', 15, 0)
    glowValue:SetText(tostring(math.floor(flashGlow)))
    glowValue:SetTextColor(1, 0.8, 0)
    self.glowValueText = glowValue
    
    glowSlider:SetScript('OnValueChanged', function(_, val)
        val = math.floor(val)
        self:SetGlow(val)
        glowValue:SetText(tostring(val))
    end)

    yOffset = yOffset - 35

    -- ============ HIDE MINIMAP CHECKBOX ============
    local hideMinimapCheck = CreateFrame('CheckButton', 'jButtonFlashHideMinimapCheck', panel, 'UICheckButtonTemplate')
    hideMinimapCheck:SetPoint('TOPLEFT', panel, 'TOPLEFT', 12, yOffset)
    hideMinimapCheck:SetChecked(db.minimapHide or false)
    _G[hideMinimapCheck:GetName()..'Text']:SetText(L.HIDE_MINIMAP)
    hideMinimapCheck:SetScript('OnClick', function(self)
        local hide = self:GetChecked()
        db.minimapHide = hide
        if jButtonFlash.minimapButton then
            if hide then
                jButtonFlash.minimapButton:Hide()
            else
                jButtonFlash.minimapButton:Show()
            end
        end
    end)

    -- ============ VERSION INFO ============
    local version = panel:CreateFontString(nil, 'ARTWORK', 'GameFontDisableSmall')
    version:SetPoint('BOTTOM', panel, 'BOTTOM', 0, 8)
    version:SetText('v2.1.2-TBC - /jbf')

    self.optionsPanel = panel
    return panel
end


function jButtonFlash:SetRandomColor(enabled)
    jButtonFlash_randomColor = enabled
    if db then db.randomColor = enabled end
end

-- ==============================================================
-- MINIMAP BUTTON (no external libraries needed)
-- ==============================================================

function jButtonFlash:CreateMinimapButton()
    local button = CreateFrame('Button', 'jButtonFlashMinimapButton', Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata('MEDIUM')
    button:SetFrameLevel(8)
    button:EnableMouse(true)
    button:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
    button:RegisterForDrag('LeftButton')
    
    -- Position around minimap (on the edge, like other addons)
    local function UpdatePosition()
        local angle = math.rad(db.minimapPos or 220)
        -- Position exactly on the minimap border (half in, half out)
        local minimapRadius = (Minimap:GetWidth() / 2) + 2
        local x = math.cos(angle) * minimapRadius
        local y = math.sin(angle) * minimapRadius
        button:ClearAllPoints()
        button:SetPoint('CENTER', Minimap, 'CENTER', x, y)
    end
    
    -- Calculate angle from mouse position to minimap center
    local function GetAngleFromMouse()
        local cx, cy = Minimap:GetCenter()
        local mx, my = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        mx, my = mx / scale, my / scale
        return math.deg(math.atan2(my - cy, mx - cx))
    end
    
    -- Icon
    local icon = button:CreateTexture(nil, 'ARTWORK')
    icon:SetTexture([[Interface\Cooldown\star4]])
    icon:SetSize(20, 20)
    icon:SetPoint('CENTER')
    icon:SetVertexColor(1, 0.8, 0.2)
    
    -- Border
    local border = button:CreateTexture(nil, 'OVERLAY')
    border:SetTexture([[Interface\Minimap\MiniMap-TrackingBorder]])
    border:SetSize(54, 54)
    border:SetPoint('TOPLEFT', -2, 2)
    
    -- Background
    local bg = button:CreateTexture(nil, 'BACKGROUND')
    bg:SetTexture([[Interface\Minimap\UI-Minimap-Background]])
    bg:SetSize(24, 24)
    bg:SetPoint('CENTER')
    bg:SetVertexColor(0, 0, 0, 0.6)
    
    -- Highlight
    local highlight = button:CreateTexture(nil, 'HIGHLIGHT')
    highlight:SetTexture([[Interface\Minimap\UI-Minimap-ZoomButton-Highlight]])
    highlight:SetSize(24, 24)
    highlight:SetPoint('CENTER')
    highlight:SetBlendMode('ADD')
    
    -- Click handlers
    button:SetScript('OnClick', function(self, btn)
        if btn == 'LeftButton' then
            jButtonFlash:ToggleOptions()
        elseif btn == 'RightButton' then
            jButtonFlash_randomColor = not jButtonFlash_randomColor
            if db then db.randomColor = jButtonFlash_randomColor end
            if jButtonFlash.randomCheckbox then
                jButtonFlash.randomCheckbox:SetChecked(jButtonFlash_randomColor)
            end
            -- Visual feedback
            if jButtonFlash_randomColor then
                icon:SetVertexColor(math.random(), math.random(), math.random())
                print('|cff00ff00jButtonFlash:|r ' .. L.RANDOM_ON)
            else
                icon:SetVertexColor(1, 0.8, 0.2)
                print('|cff00ff00jButtonFlash:|r ' .. L.RANDOM_OFF)
            end
        end
    end)
    
    -- Dragging - locked to minimap circle edge
    local isDragging = false
    
    button:SetScript('OnDragStart', function(self)
        isDragging = true
        self:SetScript('OnUpdate', function()
            if isDragging then
                local angle = GetAngleFromMouse()
                db.minimapPos = angle
                UpdatePosition()
            end
        end)
    end)
    
    button:SetScript('OnDragStop', function(self)
        isDragging = false
        self:SetScript('OnUpdate', nil)
    end)
    
    -- Tooltip
    button:SetScript('OnEnter', function(self)
        GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
        GameTooltip:AddLine('jButtonFlash', 1, 0.8, 0)
        GameTooltip:AddLine(L.MINIMAP_TOOLTIP, 1, 1, 1)
        if jButtonFlash_randomColor then
            GameTooltip:AddLine('Random: ON', 0, 1, 0)
        end
        GameTooltip:Show()
    end)
    
    button:SetScript('OnLeave', function()
        GameTooltip:Hide()
    end)
    
    UpdatePosition()
    self.minimapButton = button
    
    -- Hide if setting is enabled
    if db.minimapHide then
        button:Hide()
    end
end

function jButtonFlash:OpenColorPicker()
    local r, g, b = unpack(flashColor)

    -- TBC Classic only has the legacy ColorPicker API
    local function ColorCallback(restore)
        local nr, ng, nb
        if restore then
            nr, ng, nb = unpack(restore)
        else
            nr, ng, nb = ColorPickerFrame:GetColorRGB()
        end
        self:SetFlashColor(nr, ng, nb)
    end

    ColorPickerFrame.func = ColorCallback
    ColorPickerFrame.swatchFunc = ColorCallback
    ColorPickerFrame.cancelFunc = ColorCallback
    ColorPickerFrame.hasOpacity = false
    ColorPickerFrame:SetColorRGB(r, g, b)
    ColorPickerFrame.previousValues = {r, g, b}
    ColorPickerFrame:Hide()
    ColorPickerFrame:Show()
end

function jButtonFlash:ToggleOptions()
    local p = self:CreateOptionsPanel()
    if p:IsShown() then p:Hide() else p:Show() end
end

-- register slash command now (after all functions defined)
SLASH_JBUTTONFLASH1 = '/jbf'
SlashCmdList['JBUTTONFLASH'] = function()
    if jButtonFlash and jButtonFlash.ToggleOptions then
        jButtonFlash:ToggleOptions()
    end
end

-- begin
jButtonFlash:Initialize()
