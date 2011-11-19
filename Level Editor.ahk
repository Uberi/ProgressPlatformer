#NoEnv

Width := 800, Height := 600

CoordMode, Mouse, Client

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
Gui, 2:Add, Button, x10 y160 w70 h30, Properties
Gui, 2:Add, Button, x100 y160 w70 h30, Physics
Gui, 2:Add, Button, x10 y200 w160 h20, Remove
Gui, 2:+ToolWindow +AlwaysOnTop +Owner1
Gui, 2:Show, x10 w180 h230, Tools

PlaceRectangle("PlayerRectangle","",30,30,30,40,"-Smooth Vertical")
SelectRectangle("PlayerRectangle")

PlaceRectangle("GoalRectangle","",100,10,50,70,"BackgroundWhite")
GuiControl,, PlayerRectangle, 100
Return

GuiClose:
2GuiClose:
Gui, 1:Hide
Gui, 2:Hide
GoSub, Save
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
BorderSize := 3
ResizeLeft := (OffsetX >= -BorderSize && OffsetX <= BorderSize)
ResizeTop := (OffsetY >= -BorderSize && OffsetY <= BorderSize)
ResizeRight := ((OffsetX - RectangleW) >= -BorderSize && (OffsetX - RectangleW) <= BorderSize)
ResizeBottom := ((OffsetY - RectangleH) >= -BorderSize && (OffsetY - RectangleH) <= BorderSize)
While, GetKeyState("LButton","P")
{
    MouseGetPos, PosX, PosY
    PosX -= OffsetX, PosY -= OffsetY
    ValueX := PosX, ValueY := PosY, ValueW := "", ValueH := ""
    If ResizeTop
        ValueH := (RectangleY - PosY) + RectangleH
    If ResizeBottom
        ValueY := "", ValueH := (PosY - RectangleY) + RectangleH
    If ResizeLeft
        ValueW := (RectangleX - PosX) + RectangleW
    If ResizeRight
        ValueX := "", ValueW := (PosX - RectangleX) + RectangleW
    If ((ResizeTop || ResizeBottom) && !(ResizeLeft || ResizeRight))
        ValueX := ""
    Else If ((ResizeLeft || ResizeRight) && !(ResizeTop || ResizeBottom))
        ValueY := ""
    If (ValueW != "" && ValueW < 20)
        ValueW := 20
    If (ValueH != "" && ValueH < 20)
        ValueH := 20
    PlaceRectangle(SelectedRectangleName,SelectedRectangleIndex,ValueX,ValueY,ValueW,ValueH)
    SelectRectangle(SelectedRectangleName,SelectedRectangleIndex)
    WinSet, Redraw
    Sleep, 50
}
Return

Select:
RegExMatch(A_GuiControl,"S)([a-zA-Z]+)(\d*)HitArea",Output)
SelectRectangle(Output1,Output2)
WinSet, Redraw
Return

Save:
Result := ""
If BlockCount
{
 Result .= "`n`nBlocks:"
 Loop, %BlockCount%
 {
     GuiControlGet, Rectangle, 1:Pos, LevelRectangle%A_Index%
     Result .= "`n" . RectangleX . ", " . RectangleY . ", " . RectangleW . ", " . RectangleH
 }
}
GuiControlGet, Rectangle, 1:Pos, PlayerRectangle
Result .= "`n`nPlayer: " . RectangleX . ", " . RectangleY . ", " . RectangleW . ", " . RectangleH
GuiControlGet, Rectangle, 1:Pos, GoalRectangle
Result .= "`n`nGoal: " . RectangleX . ", " . RectangleY . ", " . RectangleW . ", " . RectangleH
If EnemyCount
{
 Result .= "`n`nEnemies:"
 Loop, %EnemyCount%
 {
     GuiControlGet, Rectangle, 1:Pos, EnemyRectangle%A_Index%
     Result .= "`n" . RectangleX . ", " . RectangleY . ", " . RectangleW . ", " . RectangleH
 }
}
Result := Trim(Result,"`n")
FileSelectFile, Filename, S2, %A_ScriptDir%, Select a location to save the level to:, *.txt
If !ErrorLevel
{
    If FileExist(Filename)
        FileDelete, %Filename%
    FileAppend, %Result%, %Filename%
}
Return

SelectRectangle(Name,Index = "")
{
    global SelectedRectangleName, SelectedRectangleIndex
    GuiControlGet, Rectangle, 1:Pos, %Name%%Index%
    RectangleX -= 2, RectangleY -= 8, RectangleW += 4, RectangleH += 10
    GuiControl, 1:Move, SelectionRectangle, x%RectangleX% y%RectangleY% w%RectangleW% h%RectangleH%
    GuiControl, 1:Show, SelectionRectangle
    GuiControl, 1:Move, SelectionHitArea, x%RectangleX% y%RectangleY% w%RectangleW% h%RectangleH%
    SelectedRectangleName := Name, SelectedRectangleIndex := Index
}

PlaceRectangle(Name,Index = "",X = "",Y = "",W = "",H = "",Options = "")
{
    global
    static NameCount := Object()
    Dimensions := ((X = "") ? "" : (" x" . X)) . ((Y = "") ? "" : (" y" . Y)) . ((W = "") ? "" : (" w" . W)) . ((H = "") ? "" : (" h" . H))
    If !ObjHasKey(NameCount,Name)
        NameCount[Name] := 0
    If ((Index = "" && NameCount[Name] = 0) || NameCount[Name] < Index) ;control does not yet exist
    {
        NameCount[Name] ++
        Gui, 1:Add, Text, %Dimensions% v%Name%%Index%HitArea gSelect
        Gui, 1:Add, Progress, %Dimensions% v%Name%%Index% %Options% hwndhWnd
        Control, ExStyle, -0x20000,, ahk_id %hWnd% ;remove WS_EX_STATICEDGE extended style
    }
    Else
    {
        GuiControl, 1:Show, %Name%%Index%
        GuiControl, 1:Move, %Name%%Index%, %Dimensions%
        GuiControl, 1:Move, %Name%%Index%HitArea, %Dimensions%
    }
}