#NoEnv

#Include ProgressEngine.ahk

SetBatchLines, -1

#Warn All
#Warn LocalSameAsGlobal, Off

Gui, Color, CCCCCC
Gui, +OwnDialogs

Gui, +Resize +LastFound
hWindow := WinExist()
Gui, Show, w800 h600, ProgressPlatformer

Game := new ProgressEngine
Game.FrameRate := 60
LevelIndex := 1

Loop
{
    If InitializeLevel()
        Break
    Game.Start()
}
MsgBox, Game complete!
ExitApp

GuiEscape:
GuiClose:
ExitApp

ShowObject(ShowObject,Padding = "") ;wip: debug
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
    global Game, LevelIndex, hWindow
    ;load the level file
    LevelFile := A_ScriptDir . "\Levels\Level " . LevelIndex . ".txt"
    If !FileExist(LevelFile)
        Return, 1
    FileRead, LevelDefinition, %LevelFile%
    If ErrorLevel
        Return, 1

    ParseLevel(Game,LevelDefinition) ;parse the level

    Random, CloudCount, 6, 10
    Loop, %CloudCount%
    {
        Entity := new CustomBlocks.Cloud
        Random, Temp1, -10.0, 10.0
        Entity.X := Temp1
        Random, Temp1, 0.0, 10.0
        Entity.Y := Temp1
        Random, Temp1, 1.0, 2.5
        Entity.W := Temp1
        Random, Temp1, 0.5, 1.2
        Entity.H := Temp1
        Random, Temp1, 0.002, 0.008
        Entity.SpeedX := Temp1
        Game.Entities.Insert(Entity)
    }

    Game.Update()
}

ParseLevel(ByRef Game,LevelDefinition)
{
    LevelDefinition := RegExReplace(LevelDefinition,"S)#[^\r\n]*")

    If RegExMatch(LevelDefinition,"iS)Blocks\s*:\s*\K(?:\d+\s*(?:,\s*\d+\s*){3})*",Property)
    {
        Property := Trim(RegExReplace(RegExReplace(Property,"S)[\r \t]"),"S)\n+","`n"),"`n")
        Loop, Parse, Property, `n
        {
            StringSplit, Entry, A_LoopField, `,, %A_Space%`t
            Entity := new CustomBlocks.Block, Entity.X := Entry1 / 90, Entity.Y := Entry2 / 90, Entity.W := Entry3 / 90, Entity.H := Entry4 / 90
            Game.Entities.Insert(Entity)
        }
    }

    If RegExMatch(LevelDefinition,"iS)Platforms\s*:\s*\K(?:\d+\s*(?:,\s*\d+\s*){6,7})*",Property)
    {
        Property := Trim(RegExReplace(RegExReplace(Property,"S)[\r \t]"),"S)\n+","`n"),"`n")
        Loop, Parse, Property, `n
        {
            Entry8 := 20 ;wip: tweak this speed
            StringSplit, Entry, A_LoopField, `,, %A_Space%`t
            Entity := new CustomBlocks.Platform, Entity.X := Entry1 / 90, Entity.Y := Entry2 / 90, Entity.W := Entry3 / 90, Entity.H := Entry4 / 90
            If Entry5 ;horizontal platform
                Entity.RangeX := Entry6 / 90, Entity.RangeY := Entity.Y, Entity.RangeW := Entry7 / 90, Entity.RangeH := 0
            Else ;vertical platform
                Entity.RangeX := Entity.X, Entity.RangeY := Entry6 / 90, Entity.RangeW := 0, Entity.RangeH := Entry7 / 90
            Entity.Speed := Entry8
            Game.Entities.Insert(Entity)
        }
    }

    RegExMatch(LevelDefinition,"iS)Player\s*:\s*\K(?:\d+\s*(?:,\s*\d+\s*){3,5})*",Property)
    Entry5 := 0, Entry6 := 0
    StringSplit, Entry, Property, `,, %A_Space%`t`r`n
    Entity := new CustomBlocks.Player, Entity.X := Entry1 / 90, Entity.Y := Entry2 / 90, Entity.W := Entry3 / 90, Entity.H := Entry4 / 90, Entity.SpeedX := Entry5 /80, Entity.SpeedY := Entry6 / 90
    Game.Entities.Insert(Entity)

    If RegExMatch(LevelDefinition,"iS)Enemies\s*:\s*\K(?:\d+\s*(?:,\s*\d+\s*){3,5})*",Property)
    {
        Property := Trim(RegExReplace(RegExReplace(Property,"S)[\r \t]"),"S)\n+","`n"),"`n")
        Loop, Parse, Property, `n, `r `t
        {
            Entry5 := 0, Entry6 := 0
            StringSplit, Entry, A_LoopField, `,, %A_Space%`t
            Entity := new CustomBlocks.Enemy, Entity.X := Entry1 / 90, Entity.Y := Entry2 / 90, Entity.W := Entry3 / 90, Entity.H := Entry4 / 90, Entity.SpeedX := Entry5 / 90, Entity.SpeedY := Entry6 / 90
            Game.Entities.Insert(Entity)
        }
    }

    If RegExMatch(LevelDefinition,"iS)Goal\s*:\s*\K(?:\d+\s*(?:,\s*\d+\s*){3})*",Property)
    {
        StringSplit, Entry, Property, `,, %A_Space%`t`r`n
        Entity := new CustomBlocks.Goal, Entity.X := Entry1 / 90, Entity.Y := Entry2 / 90, Entity.W := Entry3 / 90, Entity.H := Entry4 / 90
        Game.Entities.Insert(Entity)
    }
}

SetControlTop(hControl) ;wip
{
    DllCall("SetWindowPos","UPtr",hControl,"UPtr",0,"Int",0,"Int",0,"Int",0,"Int",0,"UInt",0x403) ;HWND_TOP, SWP_NOSENDCHANGING | SWP_NOMOVE | SWP_NOSIZE
}

SetControlBottom(hControl) ;wip
{
    DllCall("SetWindowPos","UPtr",hControl,"UPtr",1,"Int",0,"Int",0,"Int",0,"Int",0,"UInt",0x403) ;HWND_BOTTOM, SWP_NOSENDCHANGING | SWP_NOMOVE | SWP_NOSIZE
}

class CustomBlocks
{
    class Cloud extends ProgressEngine.Blocks.Default
    {
        __New()
        {
            base.__New()
            this.Color := "E8E8E8"
        }

        Step()
        {
            global Game
            this.X += this.SpeedX
            If this.X > Game.W
                this.X := -this.W
        }
    }

    class Block extends ProgressEngine.Blocks.Static
    {
        __New()
        {
            base.__New()
            this.Color := "333333"
        }

        Step()
        {
            
        }
    }

    class Platform extends ProgressEngine.Blocks.Static
    {
        __New()
        {
            base.__New()
            this.Color := "333333"
        }

        Step(Delta,Entities)
        {
            ;wip
        }
    }

    class Player extends ProgressEngine.Blocks.Dynamic
    {
        __New()
        {
            base.__New()
            this.Color := "AFAFAF"
            this.LastContact := 0
        }

        Step(Delta,Entities)
        {
            Gravity := -9.81
            MoveSpeed := 8

            Left := GetKeyState("Left","P")
            Right := GetKeyState("Right","P")
            Jump := GetKeyState("Up","P")

            If Left
                this.SpeedX -= MoveSpeed * Delta ;move left
            If Right
                this.SpeedX += MoveSpeed * Delta ;move right
            If (Left || Right) && this.IntersectX ;wall grab
            {
                this.SpeedX *= 0.1
                If Jump
                    this.SpeedY += MoveSpeed * Delta
            }
            Else
            {
                this.SpeedY += Gravity * Delta ;process gravity
                If Jump && (A_TickCount - this.LastContact) < 500 ;jump
                    this.SpeedY += MoveSpeed * 0.25, this.LastContact := 0
            }
            If this.IntersectY
                this.LastContact := A_TickCount
            base.Step(Delta,Entities)
        }
    }

    class Goal extends ProgressEngine.Blocks.Default
    {
        __New()
        {
            base.__New()
            this.Color := "FFFFFF"
        }

        Step(Delta,Entities)
        {
            
        }
    }

    class Enemy extends ProgressEngine.Blocks.Dynamic
    {
        __New()
        {
            base.__New()
            this.Color := "777777"
        }

        Step(Delta,Entities)
        {
            ;wip
            base.Step(Delta,Entities)
        }
    }
}