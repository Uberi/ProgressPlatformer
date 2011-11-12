#NoEnv

Width := 800, Height := 600

Gui, 1:Font,, Arial
Gui, 1:+Resize +MinSize20x20 +LastFound
Gui, Color, Black
Gui, 1:Show, w%Width% h%Height%, Level Editor

Gui, 2:Font, s10 Bold, Arial
Gui, 2:Add, Text, x10 y0 w160 h20 Center, Add
Gui, 2:Font, s8
Gui, 2:Add, Button, x10 y30 w50 h20 Default, Block
Gui, 2:Add, Progress, x70 y30 w100 h20 BackgroundRed
Gui, 2:Add, Button, x10 y70 w50 h20, Zombie
Gui, 2:Add, Progress, x100 y60 w30 h40 BackgroundBlue

Gui, 2:Font, s10
Gui, 2:Add, Text, x10 y130 w160 h20 Center, Modify
Gui, 2:Font, s8
Gui, 2:Add, Button, x10 y160 w70 h30, Velocity
Gui, 2:Add, Button, x100 y160 w70 h30, Physics
Gui, 2:Add, Button, x10 y200 w160 h20, Remove
Gui, 2:+ToolWindow +AlwaysOnTop +Owner1
Gui, 2:Show, x10 w180 h230, Tools
Return

GuiClose:
2GuiClose:
ExitApp

GuiSize:
Width := A_GuiWidth, Height := A_GuiHeight
Return

PlaceRectangle(X,Y,W,H,Name,Index,Options)

PlaceRectangle(X,Y,W,H,Name,Index,Options)
{
    global
    static ControlCount := 0
    If (GameGUI.Count[Name] < Index || GameGUI.Count[Name] == 0)
    {
        GameGUI.Count[Name] ++
        Gui, Add, Progress, x%X% y%Y% w%W% h%H% v%Name%%Index% %Options% hwndhwnd, 0
        Gui, +LastFound
        Control, ExStyle, -0x20000 ;remove WS_EX_STATICEDGE extended style
    }
    Else
    {
        GuiControl, Show, %Name%%Index%
        GuiControl, Move, %Name%%Index%, x%X% y%Y% w%W% h%H%
    }
}