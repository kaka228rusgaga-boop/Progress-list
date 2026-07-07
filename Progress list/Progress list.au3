#include <GUIConstantsEx.au3>
#include <GuiListView.au3>
#include <WindowsConstants.au3>

Global $ProcessNames[1000]
Global $ProcessCount[1000]
Global $Total = 0

$gui = GUICreate("Smart Process Monitor", 950, 550)

$list = GUICtrlCreateListView( _
"Процесс|Количество|Риск", _
10,10,920,450)

$details = GUICtrlCreateButton( _
"Подробнее",250,490,180,35)

$kill = GUICtrlCreateButton( _
"Завершить процесс",500,490,180,35)

LoadProcesses()

GUISetState()

While 1

    $msg = GUIGetMsg()

    If $msg = $GUI_EVENT_CLOSE Then Exit

    ; Подробнее
    If $msg = $details Then

        Local $selected = _
        _GUICtrlListView_GetNextItem($list)

        If $selected <> -1 Then

            Local $name = _
            _GUICtrlListView_GetItemText( _
            $list,$selected,0)

            $name = _
            StringRegExpReplace( _
            $name," \(.*","")

            ShowDetails($name)

        EndIf

    EndIf

    ; Завершение процесса
    If $msg = $kill Then

        Local $selected = _
        _GUICtrlListView_GetNextItem($list)

        If $selected <> -1 Then

            Local $name = _
            _GUICtrlListView_GetItemText( _
            $list,$selected,0)

            $name = _
            StringRegExpReplace( _
            $name," \(.*","")

            Local $result=MsgBox(4, _
            "Внимание", _
            "Завершить " & $name & "?")

            If $result=6 Then
                ProcessClose($name)
            EndIf

        EndIf

    EndIf

WEnd





Func LoadProcesses()

    Local $objWMI = _
    ObjGet("winmgmts:\\.\root\cimv2")

    Local $colItems = _
    $objWMI.ExecQuery( _
    "SELECT Name FROM Win32_Process")

    ; группировка
    For $objItem In $colItems

        Local $found=False

        For $i=0 To $Total-1

            If $ProcessNames[$i]=$objItem.Name Then

                $ProcessCount[$i]+=1

                $found=True

                ExitLoop

            EndIf

        Next

        If Not $found Then

            $ProcessNames[$Total]=$objItem.Name

            $ProcessCount[$Total]=1

            $Total+=1

        EndIf

    Next


    ; вывод
    For $i=0 To $Total-1

        Local $risk=GetRisk($ProcessNames[$i])

        GUICtrlCreateListViewItem( _
        $ProcessNames[$i] & _
        " (" & _
        $ProcessCount[$i] & _
        ")" & "|" & _
        $ProcessCount[$i] & "|" & _
        $risk, _
        $list)

    Next

EndFunc






Func GetRisk($name)

    $name=StringLower($name)

    ; доверенные
    Local $trusted= _
    "svchost.exe|" & _
    "explorer.exe|" & _
    "code.exe|" & _
    "devenv.exe|" & _
    "onedrive.exe|" & _
    "chrome.exe|" & _
    "discord.exe|" & _
    "firefox.exe|" & _
    "taskmgr.exe|" & _
    "searchhost.exe|" & _
    "runtimebroker.exe"

    ; известные вредоносы
    Local $knownMalware= _
    "njrat.exe|" & _
    "darkcomet.exe|" & _
    "xworm.exe|" & _
    "wannacry.exe|" & _
    "redline.exe|" & _
    "remcos.exe|" & _
    "agenttesla.exe|" & _
    "trickbot.exe|" & _
    "emotet.exe"

    ; найден известный вредонос
    If StringInStr( _
    $knownMalware, _
    $name) Then

        Return "🚨 Известная угроза"

    EndIf


    ; доверенные
    If StringInStr( _
    $trusted, _
    $name) Then

        Return "✓ Низкий"

    EndIf


    ; похожие на подделку
    If StringRegExp( _
    $name, _
    "svch0st|expl0rer|chr0me|disc0rd") Then

        Return "🚨 Подделка"

    EndIf


    ; очень длинное имя
    If StringLen($name)>35 Then

        Return "⚠ Средний"

    EndIf


    Return "✓ Низкий"

EndFunc






Func ShowDetails($procName)

    Local $detailsGui=GUICreate( _
    "Информация: " & _
    $procName, _
    1000,500)

    Local $list2= _
    GUICtrlCreateListView( _
    "Имя|ID процесса|Путь", _
    10,10,970,430)

    Local $objWMI= _
    ObjGet("winmgmts:\\.\root\cimv2")

    Local $colItems= _
    $objWMI.ExecQuery( _
    "SELECT Name,ProcessId,ExecutablePath " & _
    "FROM Win32_Process")

    For $objItem In $colItems

        If $objItem.Name=$procName Then

            GUICtrlCreateListViewItem( _
            $objItem.Name & "|" & _
            $objItem.ProcessId & "|" & _
            $objItem.ExecutablePath, _
            $list2)

        EndIf

    Next

    GUISetState()

    While 1

        $msg=GUIGetMsg()

        If $msg=$GUI_EVENT_CLOSE Then

            GUIDelete($detailsGui)

            ExitLoop

        EndIf

    WEnd

EndFunc