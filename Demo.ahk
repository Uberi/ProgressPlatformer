#NoEnv

#Include ProgressEngine.ahk

SetBatchLines, -1

#Warn All
#Warn LocalSameAsGlobal, Off

Gui, Color, Black
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
    ;load and parse the level file
    LevelFile := A_ScriptDir . "\Levels\Level " . LevelIndex . ".txt"
    If !FileExist(LevelFile)
        Return, 1
    FileRead, LevelDefinition, %LevelFile%
    If ErrorLevel
        Return, 1
    ParseLevel(Game,LevelDefinition)
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
            Entity := new Game.Blocks.Static, Entity.X := Entry1 / 80, Entity.Y := Entry2 / 80, Entity.W := Entry3 / 80, Entity.H := Entry4 / 80
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
            Entity := new CustomBlocks.Platform, Entity.X := Entry1 / 80, Entity.Y := Entry2 / 80, Entity.W := Entry3 / 80, Entity.H := Entry4 / 80
            If Entry5 ;horizontal platform
                Entity.RangeX := Entry6 / 80, Entity.RangeY := Entity.Y, Entity.RangeW := Entry7 / 80, Entity.RangeH := 0
            Else ;vertical platform
                Entity.RangeX := Entity.X, Entity.RangeY := Entry6 / 80, Entity.RangeW := 0, Entity.RangeH := Entry7 / 80
            Entity.Speed := Entry8
            Game.Entities.Insert(Entity)
        }
    }

    RegExMatch(LevelDefinition,"iS)Player\s*:\s*\K(?:\d+\s*(?:,\s*\d+\s*){3,5})*",Property)
    Entry5 := 0, Entry6 := 0
    StringSplit, Entry, Property, `,, %A_Space%`t`r`n
    Entity := new CustomBlocks.Player, Entity.X := Entry1 / 80, Entity.Y := Entry2 / 80, Entity.W := Entry3 / 80, Entity.H := Entry4 / 80, Entity.SpeedX := Entry5 /80, Entity.SpeedY := Entry6 / 80
    Game.Entities.Insert(Entity)

    If RegExMatch(LevelDefinition,"iS)Goal\s*:\s*\K(?:\d+\s*(?:,\s*\d+\s*){3})*",Property)
    {
        StringSplit, Entry, Property, `,, %A_Space%`t`r`n
        Entity := new CustomBlocks.Goal, Entity.X := Entry1 / 80, Entity.Y := Entry2 / 80, Entity.W := Entry3 / 80, Entity.H := Entry4 / 80
        Game.Entities.Insert(Entity)
    }

    If RegExMatch(LevelDefinition,"iS)Enemies\s*:\s*\K(?:\d+\s*(?:,\s*\d+\s*){3,5})*",Property)
    {
        Property := Trim(RegExReplace(RegExReplace(Property,"S)[\r \t]"),"S)\n+","`n"),"`n")
        Loop, Parse, Property, `n, `r `t
        {
            Entry5 := 0, Entry6 := 0
            StringSplit, Entry, A_LoopField, `,, %A_Space%`t
            Entity := new CustomBlocks.Enemy, Entity.X := Entry1 / 80, Entity.Y := Entry2 / 80, Entity.W := Entry3 / 80, Entity.H := Entry4 / 80, Entity.SpeedX := Entry5 / 80, Entity.SpeedY := Entry6 / 80
            Game.Entities.Insert(Entity)
        }
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
            MoveSpeed := 8
            If GetKeyState("Left","P")
                this.SpeedX -= MoveSpeed * Delta
            If GetKeyState("Right","P")
                this.SpeedX += MoveSpeed * Delta
            base.Step(Delta,Entities)
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