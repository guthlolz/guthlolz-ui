--- @type Gears_Namespace
local ns = select(2, ...)

-- Matches Gears.lua's `cu1` command-keyword highlight, for visual
-- consistency between this popup and the /gears help output.
local cu1 = ns:ColorFn(ns.colorDef.util2)

--- @param cmd string @The literal `/gears ...` command, colored via cu1
--- @param desc string
--- @return string
local function CmdLine(cmd, desc)
  -- Pad the plain command text to a fixed column width BEFORE coloring --
  -- cu1's color escape codes are invisible chars that would otherwise
  -- throw off %-Ns padding, breaking the monospace column alignment.
  local padded = ('%-30s'):format(cmd)
  return ('%s - %s'):format(cu1(padded), desc)
end

--- @param opener string
--- @param descInfo string
--- @param descEquip string
--- @param descStatus string
--- @param descList string
--- @return string
local function BuildContent(opener, descInfo, descEquip, descStatus, descList)
  return table.concat({
    opener,
    '',
    CmdLine('/gears info', descInfo),
    CmdLine('/gears equip <index-or-name>', descEquip),
    CmdLine('/gears status', descStatus),
    CmdLine('/gears list', descList),
  }, '\n')
end

local def = {
  width = 520,
  height = 230,
  dbKey = 'consoleCommands',

  title = 'New Console Commands',
  title_deDE = 'Neue Konsolenbefehle',
  title_frFR = 'Nouvelles commandes de console',
  title_esES = 'Nuevos comandos de consola',
  title_esMX = 'Nuevos comandos de consola',
  title_ruRU = 'Новые консольные команды',
  title_ptBR = 'Novos comandos de console',
  title_zhCN = '新的控制台命令',
  title_zhTW = '新的主控台指令',
  title_koKR = '새로운 콘솔 명령어',
  title_itIT = 'Nuovi comandi console',

  content = BuildContent(
    'Heads up! Gears now supports console commands for quick access without opening the panel.',
    'displays the addon info',
    'equips the named or indexed equipment set',
    'shows the currently equipped set, if any',
    'lists all equipment sets'
  ),

  content_deDE = BuildContent(
    'Übrigens: Gears unterstützt jetzt Konsolenbefehle für schnellen Zugriff, ohne das Fenster zu öffnen.',
    'zeigt die Addon-Informationen an',
    'rüstet das benannte oder indizierte Ausrüstungsset aus',
    'zeigt das aktuell angelegte Set an, falls vorhanden',
    'listet alle Ausrüstungssets auf'
  ),

  content_frFR = BuildContent(
    'Petite info : Gears prend désormais en charge les commandes de console pour un accès rapide sans ouvrir le panneau.',
    "affiche les informations de l'addon",
    "équipe l'ensemble d'équipement nommé ou indexé",
    'affiche le set actuellement équipé, le cas échéant',
    "liste tous les ensembles d'équipement"
  ),

  content_esES = BuildContent(
    'Aviso rápido: Gears ahora admite comandos de consola para un acceso rápido sin abrir el panel.',
    'muestra la información del addon',
    'equipa el conjunto de equipo indicado por nombre o índice',
    'muestra el conjunto actualmente equipado, si lo hay',
    'lista todos los conjuntos de equipo'
  ),

  content_esMX = BuildContent(
    'Aviso rápido: Gears ahora admite comandos de consola para un acceso rápido sin abrir el panel.',
    'muestra la información del addon',
    'equipa el conjunto de equipo indicado por nombre o índice',
    'muestra el conjunto actualmente equipado, si lo hay',
    'lista todos los conjuntos de equipo'
  ),

  content_ruRU = BuildContent(
    'Кстати: теперь в Gears есть консольные команды для быстрого доступа без открытия панели.',
    'показывает информацию об аддоне',
    'экипирует комплект по имени или индексу',
    'показывает текущий надетый комплект, если есть',
    'выводит список всех комплектов снаряжения'
  ),

  content_ptBR = BuildContent(
    'Aviso rápido: o Gears agora suporta comandos de console para acesso rápido sem abrir o painel.',
    'exibe as informações do addon',
    'equipa o conjunto de equipamento pelo nome ou índice',
    'mostra o conjunto atualmente equipado, se houver',
    'lista todos os conjuntos de equipamento'
  ),

  content_zhCN = BuildContent(
    '小提示：Gears 现已支持控制台命令，无需打开面板即可快速访问。',
    '显示插件信息',
    '按名称或索引装备指定的装备集',
    '显示当前已装备的装备集（如有）',
    '列出所有装备集'
  ),

  content_zhTW = BuildContent(
    '小提醒：Gears 現已支援主控台指令，無需開啟面板即可快速存取。',
    '顯示外掛資訊',
    '依名稱或索引裝備指定的裝備組',
    '顯示目前已裝備的裝備組（如有）',
    '列出所有裝備組'
  ),

  content_koKR = BuildContent(
    '알아두세요: 이제 Gears에서 패널을 열지 않고도 빠르게 사용할 수 있는 콘솔 명령어를 지원합니다.',
    '애드온 정보를 표시합니다',
    '이름 또는 번호로 지정한 장비 세트를 장착합니다',
    '현재 장착된 세트가 있으면 표시합니다',
    '모든 장비 세트를 나열합니다'
  ),

  content_itIT = BuildContent(
    'Piccola novità: Gears ora supporta i comandi console per un accesso rapido senza aprire il pannello.',
    "mostra le informazioni sull'addon",
    'equipaggia il set di equipaggiamento indicato per nome o indice',
    'mostra il set attualmente equipaggiato, se presente',
    'elenca tutti i set di equipaggiamento'
  ),
}

ns:RegisterAnnouncement(def)
