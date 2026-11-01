--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
--- @type Gears_Namespace
local ns = select(2, ...)
local p, t = ns:log('Locale_koKR')

local L = ns:NewLocale('koKR'); if not L then return end

--[[-------------------------------------------------------------------
Locale Values
---------------------------------------------------------------------]]
L['Set Name'] = '세트 이름'
L['Currently Equipped'] = '현재 장착 중'
L['Left-click'] = '왼쪽 클릭'
L['Double-click'] = '더블 클릭'
L['Drag'] = '드래그'
L['Available Actions'] = '사용 가능한 작업'
L['Select'] = '선택'
L['Equip'] = '장착'
L['Drag to an action bar'] = '단축바로 드래그'
L['Set Icon::TooltipHint'] =
  '이 세트의 아이콘에 끌어다 놓으면 아이콘이 바뀝니다.'
L['Set Icon::HelpTip'] =
  '어떤 세트의 아이콘에든 끌어다 놓으면 아이콘이 바뀝니다.'
L['Equip While Combat'] = '전투 중에는 장비 세트를 변경할 수 없습니다.'

L['Open Gears Panel'] = 'Gears 패널 열기'
L['Alt-click'] = 'Alt-클릭'
L['Keep open this session'] = '이번 세션 동안 열어 두기'
L['Kept open this session'] = '이번 세션 동안 열어 둠'
L['Close and stop keeping open'] = '닫고 더 이상 열어 두지 않기'
L['Resets on /reload'] = '/reload 시 초기화됨'
L['Create a new equipment set'] = '새 장비 세트 만들기'
L['New Equipment Set'] = '새 장비 세트'
L['LibIconPicker Missing'] =
  '이 기능을 사용하려면 LibIconPicker가 필요합니다.|nLibIconPicker가 설치 및 활성화되어 있는지 확인한 후 UI를 다시 불러오세요.'

L['Available commands:'] = '사용 가능한 명령어:'
L['displays the addon info'] = '애드온 정보를 표시합니다'
L['equips the named or indexed equipment set'] =
  '이름 또는 번호로 지정한 장비 세트를 장착합니다'
L['Usage'] = '사용법'
L['No such equipment set with name or index'] =
  '해당 이름 또는 번호의 장비 세트가 없습니다'
L['Equipped:'] = '장착됨:'
L['Already Equipped:'] = '이미 장착됨:'
L['shows the currently equipped set, if any'] =
  '현재 장착된 세트가 있으면 표시합니다'
L['No equipment set is currently equipped'] = '현재 장착된 장비 세트가 없습니다'
L['lists all equipment sets'] = '모든 장비 세트를 나열합니다'
L['No equipment sets found'] = '장비 세트를 찾을 수 없습니다'
L['Equipment Sets:'] = '장비 세트:'
L['equipped'] = '장착됨'

L['Select a set to enable slot actions'] =
  '슬롯 작업을 활성화하려면 세트를 선택하세요'
L['Include Slot'] = '슬롯 포함'
L['Include Slot::DESC'] = '장비 세트를 저장할 때 이 슬롯을 포함합니다'
L['Ignore Slot'] = '슬롯 무시'
L['Ignore Slot::DESC'] = '장비 세트를 저장할 때 이 슬롯을 제외합니다'
L['Place item in bags'] = '아이템을 가방에 넣기'
L['Place item in bags::DESC'] =
  '장착된 아이템을 사용 가능한 첫 번째 가방 슬롯으로 이동합니다'
L['Shift-Click'] = 'Shift+클릭'
L['Ignore All Slots'] = '모든 슬롯 무시'
L['Include All Slots'] = '모든 슬롯 포함'
L['General'] = '일반'
L['General::DESC'] = '모든 캐릭터가 공유하는 설정'
L['Announce Equip in Chat'] = '채팅에 장착 알리기'
L['Announce Equip in Chat::DESC'] =
  '/gears equip 사용 시 채팅창에 확인 메시지를 표시합니다'
L['opens the Gears options panel'] = 'Gears 옵션 패널을 엽니다'
L['Equipped Items'] = '장착한 아이템'
L['In Bags'] = '가방에 있음'
L['Missing'] = '누락'
L['Equipped Set Indicator on Action Bars'] = '단축바 장착 세트 표시'
L['Equipped Set Indicator on Action Bars::DESC'] =
  '세트 전체를 장착하면 단축바의 장비 세트 버튼에 테두리를 표시하고, 툴팁에 장착한 아이템, 가방에 있는 아이템, 누락된 아이템 수를 추가합니다'
