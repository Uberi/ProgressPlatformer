#NoEnv

Width := 800, Height := 600

BlockCount := 0, EnemyCount := 0
SelectedRectangleName := "", SelectedRectangleIndex := 0

Gui, 1:Add, GroupBox, vSelectionRectangle Hidden
Gui, 1:Add, Text, vSelectionHitArea gMoveRectangle BackgroundTrans
Gui, 1:+Resize +MinSize20x20
Gui, Color, Black
Gui, 1:Show, w%Width% h%Height%, Level Editor

Gui, 2:Font, s10 Bold, Arial
Gui, 2:Add, Text, x10 y0 w160 h20 Center, Add
Gui, 2:Font, s8
Gui, 2:Add, Button, x10 y30 w50 h20 gAddBlock Default, Block
Gui, 2:Add, Progress, x70 y30 w100 h20 BackgroundRed
Gui, 2:Add, Button, x10 y70 w50 h20 gAddEnemy, Enemy
Gui, 2:Add, Progress, x100 y60 w30 h40 BackgroundBlue

Gui, 2:Font, s10
Gui, 2:Add, Text, x10 y130 w160 h20 Center, Modify
Gui, 2:Font, s8
Gui, 2:Add, Button, x10 y160 w70 h30, Resize
Gui, 2:Add, Button, x100 y160 w70 h30, Remove
Gui, 2:Add, Button, x10 y200 w160 h20, Physics
Gui, 2:+ToolWindow +AlwaysOnTop +Owner1
Gui, 2:Show, x10 w180 h230, Tools
Return

GuiClose:
2GuiClose:
ExitApp

GuiSize:
Width := A_GuiWidth, Height := A_GuiHeight
GuiControl, Move, Deselect, w%Width% h%Height%
Return

AddBlock:
BlockCount ++
PlaceRectangle("LevelRectangle",BlockCount,10,10,100,20,"BackgroundRed")
SelectRectangle("LevelRectangle",BlockCount)
Return

AddEnemy:
EnemyCount ++
PlaceRectangle("EnemyRectangle",EnemyCount,10,10,30,40,"BackgroundBlue")
SelectRectangle("EnemyRectangle",EnemyCount)
Return

MoveRectangle:
GuiControlGet, Rectangle, 1:Pos, %SelectedRectangleName%%SelectedRectangleIndex%
MouseGetPos, OffsetX, OffsetY
OffsetX -= RectangleX, OffsetY -= RectangleY
While, GetKeyState("LButton","P")
{
    MouseGetPos, PosX, PosY
    PlaceRectangle(SelectedRectangleName,SelectedRectangleIndex,PosX - OffsetX,PosY - OffsetY)
    SelectRectangle(SelectedRectangleName,SelectedRectangleIndex)
    WinSet, Redraw
    Sleep, 50
}
Return

Select:
RegExMatch(A_GuiControl,"S)([a-zA-Z]+)(\d+)",Output)
SelectRectangle(Output1,Output2)
Return

MoveRectangle(Name,Index,PosX,PosY)
{
    GuiControl, 1:Move, %Name%%Index%, x%PosX% y%PosY%
    GuiControl, 1:Move, %Name%%Index%HitArea, x%PosX% y%PosY%
}

SelectRectangle(Name,Index)
{
    global SelectedRectangleName, SelectedRectangleIndex
    GuiControlGet, Rectangle, 1:Pos, %Name%%Index%
    RectangleX -= 2, RectangleY -= 8, RectangleW += 4, RectangleH += 10
    GuiControl, 1:Move, SelectionRectangle, x%RectangleX% y%RectangleY% w%RectangleW% h%RectangleH%
    GuiControl, 1:Show, SelectionRectangle
    GuiControl, 1:Move, SelectionHitArea, x%RectangleX% y%RectangleY% w%RectangleW% h%RectangleH%
    SelectedRectangleName := Name, SelectedRectangleIndex := Index
}

PlaceRectangle(Name,Index,X,Y,W = 0,H = 0,Options = "")
{
    global
    static ControlCount := 0
    If (W && H)
        Dimensions := "w" . W . " h" . H
    Else
        Dimensions := ""
    If (Index > ControlCount)
    {
        ControlCount ++
        Gui, 1:Add, Text, x%X% y%Y% %Dimensions% v%Name%%Index%HitArea gSelect
        Gui, 1:Add, Progress, x%X% y%Y% %Dimensions% v%Name%%Index% %Options% hwndhWnd
        Control, ExStyle, -0x20000,, ahk_id %hWnd% ;remove WS_EX_STATICEDGE extended style
    }
    Else
    {
        GuiControl, 1:Show, %Name%%Index%
        GuiControl, 1:Move, %Name%%Index%, x%X% y%Y% %Dimensions%
        GuiControl, 1:Move, %Name%%Index%HitArea, x%X% y%Y% %Dimensions%
    }
}