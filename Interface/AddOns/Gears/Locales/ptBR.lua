--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
--- @type Gears_Namespace
local ns = select(2, ...)
local p, t = ns:log('Locale_ptBR')

local L = ns:NewLocale('ptBR'); if not L then return end

--[[-------------------------------------------------------------------
Locale Values
---------------------------------------------------------------------]]
L['Set Name'] = 'Nome do conjunto'
L['Currently Equipped'] = 'Atualmente equipado'
L['Left-click'] = 'Clique esquerdo'
L['Double-click'] = 'Clique duplo'
L['Drag'] = 'Arrastar'
L['Available Actions'] = 'Ações disponíveis'
L['Select'] = 'Selecionar'
L['Equip'] = 'Equipar'
L['Drag to an action bar'] = 'Arrastar para uma barra de ação'
L['Set Icon::TooltipHint'] = 'Arraste e solte no ícone deste conjunto para alterá-lo.'
L['Set Icon::HelpTip'] = 'Arraste e solte no ícone de qualquer conjunto para alterá-lo.'
L['Equip While Combat'] = 'Conjuntos de equipamento não podem ser trocados durante o combate.'

L['Open Gears Panel'] = 'Abrir o painel do Gears'
L['Alt-click'] = 'Alt-clique'
L['Keep open this session'] = 'Manter aberto nesta sessão'
L['Kept open this session'] = 'Aberto nesta sessão'
L['Close and stop keeping open'] = 'Fechar e parar de manter aberto'
L['Resets on /reload'] = 'Redefinido ao usar /reload'
L['Create a new equipment set'] = 'Criar um novo conjunto de equipamento'
L['New Equipment Set'] = 'Novo conjunto de equipamento'
L['LibIconPicker Missing'] =
  'Este recurso requer LibIconPicker.|nCertifique-se de que o LibIconPicker esteja instalado e ativado e, em seguida, recarregue a interface.'

L['Available commands:'] = 'Comandos disponíveis:'
L['displays the addon info'] = 'exibe as informações do addon'
L['equips the named or indexed equipment set'] =
  'equipa o conjunto de equipamento pelo nome ou índice'
L['Usage'] = 'Uso'
L['No such equipment set with name or index'] =
  'Nenhum conjunto de equipamento com esse nome ou índice'
L['Equipped:'] = 'Equipado:'
L['Already Equipped:'] = 'Já equipado:'
L['shows the currently equipped set, if any'] = 'mostra o conjunto atualmente equipado, se houver'
L['No equipment set is currently equipped'] =
  'Nenhum conjunto de equipamento está equipado no momento'
L['lists all equipment sets'] = 'lista todos os conjuntos de equipamento'
L['No equipment sets found'] = 'Nenhum conjunto de equipamento encontrado'
L['Equipment Sets:'] = 'Conjuntos de equipamento:'
L['equipped'] = 'equipado'

L['Select a set to enable slot actions'] = 'Selecione um conjunto para ativar as ações de slot'
L['Include Slot'] = 'Incluir slot'
L['Include Slot::DESC'] = 'Incluir este slot ao salvar o conjunto de equipamento'
L['Ignore Slot'] = 'Ignorar slot'
L['Ignore Slot::DESC'] = 'Excluir este slot ao salvar o conjunto de equipamento'
L['Place item in bags'] = 'Colocar item nas bolsas'
L['Place item in bags::DESC'] = 'Move o item equipado para o primeiro slot de bolsa disponível'
L['Shift-Click'] = 'Shift-clique'
L['Ignore All Slots'] = 'Ignorar todos os slots'
L['Include All Slots'] = 'Incluir todos os slots'
L['General'] = 'Geral'
L['General::DESC'] = 'Configurações compartilhadas por todos os seus personagens'
L['Announce Equip in Chat'] = 'Anunciar equipar no chat'
L['Announce Equip in Chat::DESC'] =
  'Exibe uma mensagem de confirmação na janela de chat ao usar /gears equip'
L['opens the Gears options panel'] = 'abre o painel de opções do Gears'
L['Equipped Items'] = 'Itens equipados'
L['In Bags'] = 'Nas bolsas'
L['Missing'] = 'Faltando'
L['Equipped Set Indicator on Action Bars'] = 'Indicador de conjunto equipado nas barras de ação'
L['Equipped Set Indicator on Action Bars::DESC'] =
  'Destaca o botão da barra de ação de um conjunto de equipamento quando o conjunto inteiro está equipado, e adiciona à dica a quantidade de itens equipados, nas bolsas e faltando'
