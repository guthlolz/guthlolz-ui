--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
--- @type Gears_Namespace
local ns = select(2, ...)
local p, t = ns:log('Locale_esMX')

local L = ns:NewLocale('esMX'); if not L then return end

--[[-------------------------------------------------------------------
Locale Values
---------------------------------------------------------------------]]
L['Set Name'] = 'Nombre del conjunto'
L['Currently Equipped'] = 'Equipado actualmente'
L['Left-click'] = 'Clic izquierdo'
L['Double-click'] = 'Doble clic'
L['Drag'] = 'Arrastrar'
L['Available Actions'] = 'Acciones disponibles'
L['Select'] = 'Seleccionar'
L['Equip'] = 'Equipar'
L['Drag to an action bar'] = 'Arrastrar a una barra de acción'
L['Set Icon::TooltipHint'] = 'Arrastra y suelta sobre el ícono de este conjunto para cambiarlo.'
L['Set Icon::HelpTip'] = 'Arrastra y suelta sobre el ícono de cualquier conjunto para cambiarlo.'
L['Equip While Combat'] = 'Los conjuntos de equipo no se pueden cambiar durante el combate.'

L['Open Gears Panel'] = 'Abrir el panel de Gears'
L['Alt-click'] = 'Alt-clic'
L['Keep open this session'] = 'Mantener abierto en esta sesión'
L['Kept open this session'] = 'Abierto durante esta sesión'
L['Close and stop keeping open'] = 'Cerrar y dejar de mantener abierto'
L['Resets on /reload'] = 'Se restablece con /reload'
L['Create a new equipment set'] = 'Crear un nuevo conjunto de equipo'
L['New Equipment Set'] = 'Nuevo conjunto de equipo'
L['LibIconPicker Missing'] =
  'Esta función requiere LibIconPicker.|nAsegúrate de que LibIconPicker esté instalado y habilitado, y luego recarga la interfaz.'

L['Available commands:'] = 'Comandos disponibles:'
L['displays the addon info'] = 'muestra la información del addon'
L['equips the named or indexed equipment set'] =
  'equipa el conjunto de equipo indicado por nombre o índice'
L['Usage'] = 'Uso'
L['No such equipment set with name or index'] =
  'No existe un conjunto de equipo con ese nombre o índice'
L['Equipped:'] = 'Equipado:'
L['Already Equipped:'] = 'Ya equipado:'
L['shows the currently equipped set, if any'] =
  'muestra el conjunto actualmente equipado, si lo hay'
L['No equipment set is currently equipped'] =
  'No hay ningún conjunto de equipo equipado actualmente'
L['lists all equipment sets'] = 'lista todos los conjuntos de equipo'
L['No equipment sets found'] = 'No se encontraron conjuntos de equipo'
L['Equipment Sets:'] = 'Conjuntos de equipo:'
L['equipped'] = 'equipado'

L['Select a set to enable slot actions'] =
  'Selecciona un conjunto para habilitar las acciones de ranura'
L['Include Slot'] = 'Incluir ranura'
L['Include Slot::DESC'] = 'Incluir esta ranura al guardar el conjunto de equipo'
L['Ignore Slot'] = 'Ignorar ranura'
L['Ignore Slot::DESC'] = 'Excluir esta ranura al guardar el conjunto de equipo'
L['Place item in bags'] = 'Colocar objeto en las bolsas'
L['Place item in bags::DESC'] =
  'Mueve el objeto equipado al primer espacio disponible en las bolsas'
L['Shift-Click'] = 'Mayús-clic'
L['Ignore All Slots'] = 'Ignorar todas las ranuras'
L['Include All Slots'] = 'Incluir todas las ranuras'
L['General'] = 'General'
L['General::DESC'] = 'Configuración compartida por todos tus personajes'
L['Announce Equip in Chat'] = 'Anunciar equipar en el chat'
L['Announce Equip in Chat::DESC'] =
  'Muestra un mensaje de confirmación en la ventana de chat al usar /gears equip'
L['opens the Gears options panel'] = 'abre el panel de opciones de Gears'
L['Equipped Items'] = 'Objetos equipados'
L['In Bags'] = 'En bolsas'
L['Missing'] = 'Faltan'
L['Equipped Set Indicator on Action Bars'] = 'Indicador de conjunto equipado en barras de acción'
L['Equipped Set Indicator on Action Bars::DESC'] =
  'Resalta el botón de la barra de acción de un conjunto de equipo cuando el conjunto completo está equipado, y agrega a su descripción el número de objetos equipados, en bolsas y que faltan'
