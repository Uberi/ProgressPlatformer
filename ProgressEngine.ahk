#NoEnv

SetBatchLines, -1

#Warn All
#Warn LocalSameAsGlobal, Off

TargetFrameRate := 30
DeltaLimit := 0.05

Gui, Color, Black
Gui, +OwnDialogs

Game := new ProgressEngine

LevelIndex := 1

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

ShowObject(ShowObject,Padding = "")
{
 ListLines, Off
 If !IsObject(ShowObject)
 {
  ListLines, On
  Return, ShowObject
 }
 ObjectContents := ""
 For Key, Value In ShowObject
 {
  If IsObject(Value)
   Value := "`n" . ShowObject(Value,Padding . A_Tab)
  ObjectContents .= Padding . Key . ": " . Value . "`n"
 }
 ObjectContents := SubStr(ObjectContents,1,-1)
 If (Padding = "")
  ListLines, On
 Return, ObjectContents
}

InitializeLevel()
{
    global Game, LevelIndex
    ;load and parse the level file
    LevelFile := A_ScriptDir . "\Levels\Level " . LevelIndex . ".txt"
    If !FileExist(LevelFile)
        Return, 1
    FileRead, LevelDefinition, %LevelFile%
    If ErrorLevel
        Return, 1
    ParseLevel(Game,LevelDefinition)

    ;prevent window redrawing to avoid flickering while updating the level
    Gui, +LastFound
    hWindow := WinExist()
    PreventRedraw(hWindow)

    Gui, +Resize
    Gui, Show, w800 h600, ProgressPlatformer

    Game.Update()

    ;reenable window redrawing and redraw the window
    AllowRedraw(hWindow)
    WinSet, Redraw
}

ParseLevel(ByRef Game,LevelDefinition)
{
    LevelDefinition := RegExReplace(LevelDefinition,"S)#[^\r\n]*")

    If RegExMatch(LevelDefinition,"iS)Blocks\s*:\s*\K(?:\d+\s*(?:,\s*\d+\s*){3})*",Property)
    {
        StringReplace, Property, Property, `r,, All
        StringReplace, Property, Property, %A_Space%,, All
        StringReplace, Property, Property, %A_Tab%,, All
        While, InStr(Property,"`n`n")
            StringReplace, Property, Property, `n`n, `n, All
        Property := Trim(Property,"`n")
        Loop, Parse, Property, `n
        {
            StringSplit, Entry, A_LoopField, `,, %A_Space%`t
            Entity := new Game.Blocks.Static
            Entity.X := Entry1, Entity.Y := Entry2, Entity.W := Entry3, Entity.H := Entry4
            Game.Entities.Insert(Entity)
        }
    }

    If RegExMatch(LevelDefinition,"iS)Platforms\s*:\s*\K(?:\d+\s*(?:,\s*\d+\s*){6,7})*",Property)
    {
        StringReplace, Property, Property, `r,, All
        StringReplace, Property, Property, %A_Space%,, All
        StringReplace, Property, Property, %A_Tab%,, All
        While, InStr(Property,"`n`n")
            StringReplace, Property, Property, `n`n, `n, All
        Property := Trim(Property,"`n")
        Loop, Parse, Property, `n
        {
            Entry8 := 20 ;wip: tweak this speed
            StringSplit, Entry, A_LoopField, `,, %A_Space%`t
            Entity := new CustomBlocks.Platform
            Entity.X := Entry1, Entity.Y := Entry2, Entity.W := Entry3, Entity.H := Entry4
            If Entry5 ;horizontal platform
            {
                Entity.RangeX := Entry6, Entity.RangeY := Entity.Y
                Entity.RangeW := Entry7, Entity.RangeH := 0
            }
            Else ;vertical platform
            {
                Entity.RangeX := Entity.X, Entity.RangeY := Entry6
                Entity.RangeW := 0, Entity.RangeH := Entry7
            }
            Entity.Speed := Entry8
            Game.Entities.Insert(Entity)
        }
    }

    If RegExMatch(LevelDefinition,"iS)Player\s*:\s*\K(?:\d+\s*(?:,\s*\d+\s*){3,5})*",Property)
    {
        Entry5 := 0, Entry6 := 0
        StringSplit, Entry, Property, `,, %A_Space%`t`r`n
        Entity := new CustomBlocks.Player
        Entity.X := Entry1, Entity.Y := Entry2, Entity.W := Entry3, Entity.H := Entry4
        Entity.SpeedX := Entry5, Entity.SpeedY := Entry6
        Game.Entities.Insert(Entity)
    }

    If RegExMatch(LevelDefinition,"iS)Goal\s*:\s*\K(?:\d+\s*(?:,\s*\d+\s*){3})*",Property)
    {
        StringSplit, Entry, Property, `,, %A_Space%`t`r`n
        Entity := new CustomBlocks.Goal
        Entity.X := Entry1, Entity.Y := Entry2, Entity.W := Entry3, Entity.H := Entry4
        Game.Entities.Insert(Entity)
    }

    If RegExMatch(LevelDefinition,"iS)Enemies\s*:\s*\K(?:\d+\s*(?:,\s*\d+\s*){3,5})*",Property)
    {
        StringReplace, Property, Property, `r,, All
        StringReplace, Property, Property, %A_Space%,, All
        StringReplace, Property, Property, %A_Tab%,, All
        While, InStr(Property,"`n`n")
            StringReplace, Property, Property, `n`n, `n, All
        Property := Trim(Property,"`n")
        Loop, Parse, Property, `n, `r `t
        {
            Entry5 := 0, Entry6 := 0
            StringSplit, Entry, A_LoopField, `,, %A_Space%`t
            Entity := new CustomBlocks.Enemy
            Entity.X := Entry1, Entity.Y := Entry2, Entity.W := Entry3, Entity.H := Entry4
            Entity.SpeedX := Entry5, Entity.SpeedY := Entry6
            Game.Entities.Insert(Entity)
        }
    }
}

PreventRedraw(hWindow)
{
    DetectHidden := A_DetectHiddenWindows
    DetectHiddenWindows, On
    SendMessage, 0xB, 0, 0,, ahk_id %hWindow% ;WM_SETREDRAW
    DetectHiddenWindows, %DetectHidden%
}

AllowRedraw(hWindow)
{
    DetectHidden := A_DetectHiddenWindows
    DetectHiddenWindows, On
    SendMessage, 0xB, 1, 0,, ahk_id %hWindow% ;WM_SETREDRAW
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
    Game.Update()
}
Return

SetControlTop(hControl) ;wip
{
    DllCall("SetWindowPos","UPtr",hControl,"UPtr",0,"Int",0,"Int",0,"Int",0,"Int",0,"UInt",0x403) ;HWND_TOP, SWP_NOSENDCHANGING | SWP_NOMOVE | SWP_NOSIZE
}

SetControlBottom(hControl) ;wip
{
    DllCall("SetWindowPos","UPtr",hControl,"UPtr",1,"Int",0,"Int",0,"Int",0,"Int",0,"UInt",0x403) ;HWND_BOTTOM, SWP_NOSENDCHANGING | SWP_NOMOVE | SWP_NOSIZE
}

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
        this.W := 100
        this.H := 100
        this.W := 1000 ;wip
        this.H := 1000 ;wip

        Gui, %GUIIndex%:+LastFound
        this.hWindow := WinExist()
    }

    Step(Delta)
    {
        For Index, Entity In this.Entities
        {
            If Entity.Step(Delta,this.Entities)
                Return, 1
        }
        Return, 0
    }

    Delete(EntityKey)
    {
        GUIIndex := this.GUIIndex
        GuiControl, %GUIIndex%:Hide, ProgressEngine%Index%
        ObjRemove(this.Entities,EntityKey)
    }

    Update()
    {
        global ;must be global in order to use GUI variables
        local GUIIndex, CurrentX, CurrentY, CurrentW, CurrentH, EntityIdentifier
        ;wip: support subcategories in this.entities by checking entity.base.__class and recursing if it is not based on the entity class
        ;wip: use an internal list of controls so that offscreen controls can be reused
        GUIIndex := this.GUIIndex

        WinGetPos,,, Width, Height, % "ahk_id " . this.hWindow ;obtain the window dimensions
        ScaleX := Width / this.W, ScaleY := Height / this.H

        For Index, Entity In this.Entities
        {
            If (Entity.X + Entity.W) <= this.X || Entity.X >= (this.X + this.W) || (Entity.Y + Entity.H) <= this.Y || Entity.Y > (this.Y + this.H)
                Continue

            ;get the screen coordinates of the rectangle
            CurrentX := Round((this.X + Entity.X) * ScaleX), CurrentY := Round((this.Y + Entity.Y) * ScaleY)
            CurrentW := Round(Entity.W * ScaleX), CurrentH := Round(Entity.H * ScaleY)

            If ObjHasKey(Entity,"Index") ;control already exists
            {
                EntityIdentifier := "ProgressEngine" . Entity.Index
                If Entity.Visible
                    GuiControl, %GUIIndex%:Show, %EntityIdentifier%
                Else
                    GuiControl, %GUIIndex%:Hide, %EntityIdentifier%
                GuiControl, %GUIIndex%:Move, %EntityIdentifier%, x%CurrentX% y%CurrentY% w%CurrentW% h%CurrentH%
            }
            Else ;control does not exist
            {
                ProgressEngine.ControlCounter ++
                Entity.Index := ProgressEngine.ControlCounter
                Gui, %GUIIndex%:Add, Progress, % "x" . CurrentX . " y" . CurrentY . " w" . CurrentW . " h" . CurrentH . " vProgressEngine" . ProgressEngine.ControlCounter . " hwndhControl", 0
                Control, ExStyle, -0x20000,, ahk_id %hControl% ;remove WS_EX_STATICEDGE extended style
            }
        }
    }

    class Blocks
    {
        class Default
        {
            __New()
            {
                this.Visible := 1
                this.Physical := 0
            }

            Step(Delta,Entities)
            {
                
            }
        }

        class Static extends ProgressEngine.Blocks.Default
        {
            __New()
            {
                this.Visible := 1
                this.Physical := 1
            }

            Step(Delta,Entities)
            {
                
            }
        }

        class Dynamic extends ProgressEngine.Blocks.Static
        {
            Step(Delta,Entities)
            {
                ;wip
            }
        }
    }
}

class CustomBlocks
{
    class Platform extends ProgressEngine.Blocks.Static
    {
        Step(Delta,Entities)
        {
            ;wip
        }
    }

    class Player extends ProgressEngine.Blocks.Dynamic
    {
        Step(Delta,Entities)
        {
            this.X -= 2
        }
    }

    class Goal extends ProgressEngine.Blocks.Default
    {
        Step(Delta,Entities)
        {
            
        }
    }

    class Enemy extends ProgressEngine.Blocks.Dynamic
    {
        Step(Delta,Entities)
        {
            ;wip
        }
    }
}