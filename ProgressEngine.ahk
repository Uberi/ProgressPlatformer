#NoEnv

TargetFrameRate := 30

Gui, Color, Black
Gui, +OwnDialogs

Game := new ProgressEngine

TargetFrameDelay := 1000 / TargetFrameRate
TickFrequency := 0, DllCall("QueryPerformanceFrequency","Int64*",TickFrequency) ;obtain ticks per second
Loop
{
    If InitializeLevel()
        Break
    Gosub, MainLoop
}
MsgBox, Game complete!
ExitApp

GuiEscape:
GuiClose:
ExitApp

InitializeLevel()
{
    ;load and parse the level file
    LevelFile := A_ScriptDir . "\Levels\Level " . LevelIndex . ".txt"
    If !FileExist(LevelFile)
        Return, 1
    FileRead, LevelDefinition, %LevelFile%
    If ErrorLevel
        Return, 1
    Level := ParseLevel(LevelDefinition)

    ;prevent window redrawing to avoid flickering while updating the level
    Gui, +LastFound
    hWindow := WinExist()
    PreventRedraw(hWindow)

    ;wip: load level

    ;reenable window redrawing and redraw the window
    AllowRedraw(hWindow)
    WinSet, Redraw
}

PreventRedraw(hWnd)
{
 DetectHidden := A_DetectHiddenWindows
 DetectHiddenWindows, On
 SendMessage, 0xB, 0, 0,, ahk_id %hWnd% ;WM_SETREDRAW
 DetectHiddenWindows, %DetectHidden%
}

AllowRedraw(hWnd)
{
 DetectHidden := A_DetectHiddenWindows
 DetectHiddenWindows, On
 SendMessage, 0xB, 1, 0,, ahk_id %hWnd% ;WM_SETREDRAW
 DetectHiddenWindows, %DetectHidden%
}

MainLoop:
PreviousTicks := 0, CurrentTicks := 0
DllCall("QueryPerformanceCounter","Int64*",PreviousTicks)
Loop
{
    DllCall("QueryPerformanceCounter","Int64*",CurrentTicks)
    Delta := Round((CurrentTicks - PreviousTicks) / TickFrequency,4)
    DllCall("QueryPerformanceCounter","Int64*",PreviousTicks)
    If (Delta > DeltaLimit)
        Delta := DeltaLimit
    Sleep, % Round(TargetFrameDelay - (Delta * 1000))
    If Game.Step(Delta)
        Break
}
Return

class ProgressEngine
{
    static ControlCounter := 0
    static Entities := Object()

    __New(GUIIndex = 1)
    {
        this.GUIIndex := GUIIndex
        this.Entities := []
        this.X := 0
        this.Y := 0
    }

    Step()
    {
        For Index, Entity In Entities
            Entity.Step(Entities)
    }

    Delete(EntityKey)
    {
        GUIIndex := this.GUIIndex
        GuiControl, %GUIIndex%:Hide, ProgressEngine%Index%
        ObjRemove(this.Entities,EntityKey)
    }

    Update()
    {
        ;wip: use occlusion culling here
        ;wip: take window sizing into account
        ;wip: don't move blocks unless the position has changed
        ;wip: support subcategories in this.entities by checking entity.base.__class and recursing if it is not based on the entity class
        GUIIndex := this.GUIIndex
        For Index, Entity In this.Entities
        {
            CurrentX := Round(this.X + Entity.X), CurrentY := Round(this.Y + Entity.Y)
            CurrentW := Round(this.W + Entity.W), CurrentH := Round(this.H + Entity.H)
            If !ObjHasKey(Entity,"Index") ;control does not yet exist
            {
                ProgressEngine.ControlCounter ++
                Entity.Index := ProgressEngine.ControlCounter
                Gui, %GUIIndex%:Add, Progress, % "x" . CurrentX . " y" . CurrentY . " w" . CurrentW . " h" . CurrentH . " vProgressEngine" . ProgressEngine.ControlCounter . " hwndhControl", 0
                Control, ExStyle, -0x20000,, ahk_id %hControl% ;remove WS_EX_STATICEDGE extended style
            }
            Else
            {
                EntityIdentifier := "ProgressEngine" . Entity.Index
                If Entity.Visible
                    GuiControl, %GUIIndex%:Show, %EntityIdentifier%
                Else
                    GuiControl, %GUIIndex%:Hide, %EntityIdentifier%
                GuiControl, %GUIIndex%:Move, %EntityIdentifier%, x%CurrentX% y%CurrentY% w%CurrentW% h%CurrentH%
            }
        }
    }

    class Entities
    {
        class Default
        {
            
        }

        class Nonphysical extends ProgressEngine.Entities.Default
        {
            __New()
            {
                this.Visible := 1
                this.Physical := 0
            }

            Step()
            {
                MsgBox
            }
        }

        class Physical extends ProgressEngine.Entities.Default
        {
            __New()
            {
                this.Visible := 1
                this.Physical := 1
            }

            Step()
            {
                MsgBox
            }
        }
    }
}