--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
--- @type Gears_Namespace
local ns = select(2, ...)
local p, t = ns:log('Locale_ruRU')

local L = ns:NewLocale('ruRU'); if not L then return end

--[[-------------------------------------------------------------------
Locale Values
---------------------------------------------------------------------]]
L['Set Name'] = 'Название комплекта'
L['Currently Equipped'] = 'Сейчас надето'
L['Left-click'] = 'Левый щелчок'
L['Double-click'] = 'Двойной щелчок'
L['Drag'] = 'Перетащить'
L['Available Actions'] = 'Доступные действия'
L['Select'] = 'Выбрать'
L['Equip'] = 'Надеть'
L['Drag to an action bar'] = 'Перетащите на панель действий'
L['Set Icon::TooltipHint'] =
  'Перетащите на значок этого комплекта, чтобы изменить его.'
L['Set Icon::HelpTip'] =
  'Перетащите на значок любого комплекта, чтобы изменить его.'
L['Equip While Combat'] =
  'Комплекты экипировки нельзя менять во время боя.'

L['Open Gears Panel'] = 'Открыть панель Gears'
L['Alt-click'] = 'Alt-клик'
L['Keep open this session'] = 'Держать открытой в этом сеансе'
L['Kept open this session'] = 'Открыта в этом сеансе'
L['Close and stop keeping open'] =
  'Закрыть и больше не держать открытой'
L['Resets on /reload'] = 'Сбрасывается при /reload'
L['Create a new equipment set'] = 'Создать новый комплект экипировки'
L['New Equipment Set'] = 'Новый комплект экипировки'
L['LibIconPicker Missing'] =
  'Для этой функции требуется LibIconPicker.|nУбедитесь, что LibIconPicker установлен и включён, затем перезагрузите интерфейс.'

L['Available commands:'] = 'Доступные команды:'
L['displays the addon info'] = 'показывает информацию об аддоне'
L['equips the named or indexed equipment set'] =
  'экипирует комплект по имени или индексу'
L['Usage'] = 'Использование'
L['No such equipment set with name or index'] =
  'Нет комплекта экипировки с таким именем или индексом'
L['Equipped:'] = 'Надето:'
L['Already Equipped:'] = 'Уже надето:'
L['shows the currently equipped set, if any'] =
  'показывает текущий надетый комплект, если есть'
L['No equipment set is currently equipped'] =
  'Сейчас не надет ни один комплект экипировки'
L['lists all equipment sets'] =
  'выводит список всех комплектов экипировки'
L['No equipment sets found'] = 'Комплекты экипировки не найдены'
L['Equipment Sets:'] = 'Комплекты экипировки:'
L['equipped'] = 'надето'

L['Select a set to enable slot actions'] =
  'Выберите комплект, чтобы включить действия слотов'
L['Include Slot'] = 'Включить слот'
L['Include Slot::DESC'] =
  'Включить этот слот при сохранении набора экипировки'
L['Ignore Slot'] = 'Игнорировать слот'
L['Ignore Slot::DESC'] =
  'Исключить этот слот при сохранении набора экипировки'
L['Place item in bags'] = 'Поместить предмет в сумки'
L['Place item in bags::DESC'] =
  'Перемещает экипированный предмет в первый доступный слот сумки'
L['Shift-Click'] = 'Shift + щелчок'
L['Ignore All Slots'] = 'Игнорировать все слоты'
L['Include All Slots'] = 'Включить все слоты'
L['General'] = 'Общее'
L['General::DESC'] =
  'Настройки, общие для всех ваших персонажей'
L['Announce Equip in Chat'] = 'Оповещать в чате об экипировке'
L['Announce Equip in Chat::DESC'] =
  'Показывает подтверждающее сообщение в окне чата при использовании /gears equip'
L['opens the Gears options panel'] = 'открывает панель настроек Gears'
L['Equipped Items'] = 'Надетые предметы'
L['In Bags'] = 'В сумках'
L['Missing'] = 'Отсутствует'
L['Equipped Set Indicator on Action Bars'] = 'Индикатор надетого комплекта на панелях действий'
L['Equipped Set Indicator on Action Bars::DESC'] =
  'Обводит кнопку комплекта экипировки на панели действий, когда надет весь комплект, и добавляет в подсказку число надетых, лежащих в сумках и отсутствующих предметов'
