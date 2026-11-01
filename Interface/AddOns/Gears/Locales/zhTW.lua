--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
--- @type Gears_Namespace
local ns = select(2, ...)
local p, t = ns:log('Locale_zhTW')

local L = ns:NewLocale('zhTW'); if not L then return end

--[[-------------------------------------------------------------------
Locale Values
---------------------------------------------------------------------]]
L['Set Name'] = '裝備組名稱'
L['Currently Equipped'] = '目前已裝備'
L['Left-click'] = '左鍵點擊'
L['Double-click'] = '雙擊'
L['Drag'] = '拖曳'
L['Available Actions'] = '可用操作'
L['Select'] = '選擇'
L['Equip'] = '裝備'
L['Drag to an action bar'] = '拖曳到快捷列'
L['Set Icon::TooltipHint'] = '拖放到此套裝的圖示上即可更換圖示。'
L['Set Icon::HelpTip'] = '拖放到任一套裝的圖示上即可更換圖示。'
L['Equip While Combat'] = '戰鬥中無法更換裝備組。'

L['Open Gears Panel'] = '開啟 Gears 面板'
L['Alt-click'] = 'Alt-點擊'
L['Keep open this session'] = '本次工作階段保持開啟'
L['Kept open this session'] = '本次工作階段已保持開啟'
L['Close and stop keeping open'] = '關閉並停止保持開啟'
L['Resets on /reload'] = '使用 /reload 後重設'
L['Create a new equipment set'] = '建立新的裝備組'
L['New Equipment Set'] = '新裝備組'
L['LibIconPicker Missing'] =
  '此功能需要 LibIconPicker。|n請確認已安裝並啟用 LibIconPicker，然後重新載入介面。'

L['Available commands:'] = '可用指令：'
L['displays the addon info'] = '顯示外掛資訊'
L['equips the named or indexed equipment set'] = '依名稱或索引裝備指定的裝備組'
L['Usage'] = '用法'
L['No such equipment set with name or index'] = '沒有該名稱或索引對應的裝備組'
L['Equipped:'] = '已裝備：'
L['Already Equipped:'] = '已經裝備：'
L['shows the currently equipped set, if any'] = '顯示目前已裝備的裝備組（如有）'
L['No equipment set is currently equipped'] = '目前沒有已裝備的裝備組'
L['lists all equipment sets'] = '列出所有裝備組'
L['No equipment sets found'] = '未找到裝備組'
L['Equipment Sets:'] = '裝備組：'
L['equipped'] = '已裝備'

L['Select a set to enable slot actions'] = '選擇一個裝備組以啟用欄位操作'
L['Include Slot'] = '包含欄位'
L['Include Slot::DESC'] = '儲存裝備組時包含此欄位'
L['Ignore Slot'] = '忽略欄位'
L['Ignore Slot::DESC'] = '儲存裝備組時排除此欄位'
L['Place item in bags'] = '將物品放入背包'
L['Place item in bags::DESC'] = '將已裝備的物品移動到第一個可用的背包位置'
L['Shift-Click'] = 'Shift+點擊'
L['Ignore All Slots'] = '忽略所有欄位'
L['Include All Slots'] = '包含所有欄位'
L['General'] = '一般'
L['General::DESC'] = '所有角色共用的設定'
L['Announce Equip in Chat'] = '在聊天中宣布裝備'
L['Announce Equip in Chat::DESC'] = '使用 /gears equip 時在聊天視窗中顯示確認訊息'
L['opens the Gears options panel'] = '開啟 Gears 選項面板'
L['Equipped Items'] = '已裝備物品'
L['In Bags'] = '在背包中'
L['Missing'] = '缺少'
L['Equipped Set Indicator on Action Bars'] = '快捷列已裝備裝備組指示'
L['Equipped Set Indicator on Action Bars::DESC'] =
  '整套裝備組全部裝備時，為快捷列上的該裝備組按鈕加上外框，並在滑鼠提示中顯示已裝備、在背包中及缺少的物品數量'
