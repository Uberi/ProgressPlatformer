#NoEnv

/*
Copyright 2011 Anthony Zhang <azhang9@gmail.com>

This file is part of ProgressPlatformer. Source code is available at <https://github.com/Uberi/ProgressPlatformer>.

ProgressPlatformer is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#Include ProgressEngine.ahk

Gravity := -9.81

SetBatchLines, -1

#Warn All
#Warn LocalSameAsGlobal, Off

Gui, +OwnDialogs
DetectHiddenWindows, On
Gui, +Resize +LastFound

Gui, Show, w800 h600, ProgressPlatformer

Game := new ProgressEngine(WinExist())

;title screen
MessageScreen(Game,"Achromatic","Press Space to begin.")

#Include Levels/Tutorial.ahk

;game screen
LevelIndex := 1
StartLevel := 1
Loop
{
    If StartLevel
    {
        Game.Layers[1] := new ProgressEngine.Layer
        Game.Layers[2] := new ProgressEngine.Layer
        Game.Layers[3] := new ProgressEngine.Layer
        If LoadLevel(Game,LevelIndex)
            Break
        ;Game.Layers[2].Entities.Insert(new GameEntities.Platform(2,2,1,0.2,1,1,2,1.5))
        Game.Layers[1].Entities.Insert(new GameEntities.Background)
        Random, CloudCount, 6, 10
        Loop, %CloudCount% ;add clouds
            Game.Layers[1].Entities.Insert(new GameEntities.Cloud)
        Game.Layers[3].Entities.Insert(new GameEntities.HealthBar(Game.Layers[2]))
    }
    Result := Game.Start()
    StartLevel := 1
    If Result = 1 ;reached goal
        LevelIndex ++ ;move to the next level
    If Result = 2 ;out of health
        MessageScreen(Game,"Try again","Press Space to restart the level.")
    Else If Result = 3 ;out of bounds
        MessageScreen(Game,"Out of bounds","Press Space to restart the level.")
    Else If Result = 4 ;game paused
        MessageScreen(Game,"Paused","Press Space to resume."), StartLevel := 0
}
Game.Layers := []

;completion screen
MessageScreen(Game,"Game complete","Press Space to exit.")
ExitApp

GuiClose:
Game.__Delete() ;wip: this shouldn't be needed
ExitApp

class GameEntities
{
    class Background extends ProgressEngine.Blocks.Default
    {
        __New()
        {
            base.__New()
            this.X := 0
            this.Y := 0
            this.W := 10
            this.H := 10
            this.Color := 0xCCCCCC
        }

        Step(ByRef Delta,Layer,Rectangle,ViewportWidth,ViewportHeight)
        {
            global Game
            If !WinActive("ahk_id " . Game.hWindow)
                Return, 4 ;paused

            If GetKeyState("Tab","P") ;slow motion
                Delta *= 0.25

            If GetKeyState("Space","P") ;pause
            {
                KeyWait, Space
                Return, 4 ;paused
            }
        }
    }

    class HealthBar extends ProgressEngine.Blocks.Default
    {
        __New(Layer)
        {
            base.__New()
            this.Color := 0x555555
            this.X := 1
            this.Y := 9.5
            this.TotalWidth := 8
            this.W := this.TotalWidth
            For Key, Entity In Layer.Entities
            {
                If Entity.__Class = "GameEntities.Player"
                    this.Player := Entity
            }
        }

        Step(Delta,Layer,Rectangle,ViewportWidth,ViewportHeight)
        {
            this.W := (Mod(this.Player.Health,100) / 100) * this.TotalWidth
            this.H := 0.08 * ((this.Player.Health // 100) + 1)
        }
    }

    class Cloud extends ProgressEngine.Blocks.Default
    {
        __New()
        {
            base.__New()
            this.Color := 0xE8E8E8
            Random, Temp1, -10.0, 10.0
            this.X := Temp1
            Random, Temp1, 0.0, 10.0
            this.Y := Temp1
            Random, Temp1, 1.0, 2.5
            this.W := Temp1
            Random, Temp1, 0.5, 1.2
            this.H := Temp1
            Random, Temp1, 0.1, 0.4
            this.SpeedX := Temp1
        }

        Step(Delta,Layer,Rectangle,ViewportWidth,ViewportHeight)
        {
            global Game
            this.X += this.SpeedX * Delta
            If this.X > Game.Layers[1].W
                this.X := -this.W
        }
    }

    class Block extends ProgressEngine.Blocks.Static
    {
        __New(X,Y,W,H)
        {
            base.__New()
            this.X := X
            this.Y := Y
            this.W := W
            this.H := H
            this.Color := 0x333333
        }
    }

    class Platform extends ProgressEngine.Blocks.Static
    {
        __New(X,Y,W,H,Horizontal,Start,Length,Speed) ;wip: allow custom ranges for diagonal platforms
        {
            base.__New()
            this.X := X
            this.Y := Y
            this.W := W
            this.H := H
            this.Start := Start
            If Horizontal ;horizontal platform
                this.RangeX := Start, this.RangeY := Y, this.RangeW := Length, this.RangeH := 0
            Else ;vertical platform
                this.RangeX := X, this.RangeY := Start, this.RangeW := 0, this.RangeH := Length
            this.Speed := Speed
            this.Direction := 1
            this.Color := 0x777777
        }

        Step(Delta,Layer,Rectangle,ViewportWidth,ViewportHeight)
        {
            ;wip: need to push player along direction of platform
            If (this.X < this.RangeX)
                this.Direction := 1
            Else If (this.X > (this.RangeX + this.RangeW))
                this.Direction := -1
            this.X += this.Speed * Delta * this.Direction
        }
    }

    class Player extends ProgressEngine.Blocks.Dynamic
    {
        __New(X,Y,W,H,SpeedX,SpeedY)
        {
            base.__New()
            this.X := X
            this.Y := Y
            this.W := W
            this.H := H
            this.SpeedX := SpeedX
            this.SpeedY := SpeedY
            this.Color := 0xAFAFAF
            this.LastContact := 0
            this.Health := 100
        }

        Step(Delta,Layer,Rectangle,ViewportWidth,ViewportHeight)
        {
            global Gravity
            MoveSpeed := 10

            Left := GetKeyState("Left","P")
            Right := GetKeyState("Right","P")
            Jump := GetKeyState("Up","P")
            Crouch := GetKeyState("Down","P")

            For Key, Entity In Layer.Entities ;wip: use NearestEntities()
            {
                If (Entity.__Class = "GameEntities.Goal" && this.Inside(Entity)) ;player is inside the goal
                    Return, 1 ;reached goal
                If (Entity.__Class = "GameEntities.Enemy" && this.Collide(Entity,IntersectX,IntersectY))
                {
                    If IntersectX && (this.Y + this.H) < (Entity.Y + Entity.H)
                    {
                        Layer.Entities.Remove(Key) ;wip: can't do this in a For loop
                        this.Health += 30
                    }
                    Else
                        this.Health -= 150 * Delta
                }
            }

            this.Health -= Delta

            If this.Health <= 0
                Return, 2 ;out of health

            Padding := 1
            If (this.X > (Layer.W + Padding) || (this.X + this.W) < -Padding || this.Y > (Layer.H + Padding)) ;out of bounds
                Return, 3 ;out of bounds

            If Left
                this.SpeedX -= MoveSpeed * Delta ;move left
            If Right
                this.SpeedX += MoveSpeed * Delta ;move right
            If (Left || Right) && this.IntersectX ;wall grab
            {
                this.SpeedX *= 0.05
                If Jump
                    this.SpeedY += MoveSpeed * Delta
            }
            Else
            {
                this.SpeedY += Gravity * Delta ;process gravity
                If Jump && (A_TickCount - this.LastContact) < 500 ;jump
                    this.SpeedY += MoveSpeed * 0.3, this.LastContact := 0
            }
            this.H := Crouch ? 0.4 : 0.5
            If this.IntersectY ;contacting top or bottom of a block
                this.LastContact := A_TickCount

            base.Step(Delta,Layer,Rectangle,ViewportWidth,ViewportHeight)
        }
    }

    class Goal extends ProgressEngine.Blocks.Default
    {
        __New(X,Y,W,H)
        {
            base.__New()
            this.X := X
            this.Y := Y
            this.W := W
            this.H := H
            this.Color := 0xFFFFFF
        }
    }

    class Enemy extends ProgressEngine.Blocks.Dynamic
    {
        __New(X,Y,W,H,SpeedX,SpeedY)
        {
            base.__New()
            this.X := X
            this.Y := Y
            this.W := W
            this.H := H
            this.SpeedX := SpeedX
            this.SpeedY := SpeedY
            this.Color := 0x777777
        }

        Step(Delta,Layer,Rectangle,ViewportWidth,ViewportHeight)
        {
            global Gravity
            MoveSpeed := 8
            JumpSpeed := MoveSpeed * 0.25

            ;move towards the player
            For Key, Entity In Layer.Entities ;wip: use NearestEntities()
            {
                If (Entity.__Class = "GameEntities.Player")
                {
                    If (Entity.Y - this.Y) < JumpSpeed && Abs(Entity.X - this.X) < (MoveSpeed / 2)
                    {
                        If (this.Y >= Entity.Y)
                        {
                            If this.IntersectX
                            {
                                this.SpeedY -= Gravity * Delta
                                this.SpeedY += MoveSpeed * Delta
                            }
                            Else If (A_TickCount - this.LastContact) < 500 ;jump
                                this.SpeedY += JumpSpeed, this.LastContact := 0
                        }
                        If this.X < Entity.X
                            this.SpeedX += MoveSpeed * Delta
                        Else
                            this.SpeedX -= MoveSpeed * Delta
                    }
                }
                Else If (Entity.__Class = "GameEntities.Enemy" && &this = &Entity)
                {
                    Padding := 1
                    If (this.X > (Layer.W + Padding) || (this.X + this.W) < -Padding || this.Y > (Layer.H + Padding)) ;out of bounds
                        Layer.Entities.Remove(Key) ;wip: can't do this in a For loop
                }
            }

            If this.IntersectY ;contacting top or bottom of a block
                this.LastContact := A_TickCount

            this.SpeedY += Gravity * Delta ;process gravity
            base.Step(Delta,Layer,Rectangle,ViewportWidth,ViewportHeight)
        }
    }
}

LoadLevel(ByRef Game,LevelIndex) ;wip: the divide by 90 thing is really hacky - should replace the actual numbers and add regex to support floats
{
    ;load the level file
    LevelFile := A_ScriptDir . "\Levels\Level " . LevelIndex . ".txt"
    If !FileExist(LevelFile)
        Return, 1
    FileRead, LevelDefinition, %LevelFile%
    If ErrorLevel
        Return, 1

    Entities := Game.Layers[2].Entities

    LevelDefinition := RegExReplace(LevelDefinition,"S)#[^\r\n]*") ;remove comments

    If RegExMatch(LevelDefinition,"iS)Blocks\s*:\s*\K(?:-?\d+\s*(?:,\s*-?\d+\s*){3})*",Property)
    {
        Property := Trim(RegExReplace(RegExReplace(Property,"S)[\r \t]"),"S)\n+","`n"),"`n")
        Loop, Parse, Property, `n
        {
            StringSplit, Entry, A_LoopField, `,, %A_Space%`t
            Entities.Insert(new GameEntities.Block(Entry1 / 90,Entry2 / 90,Entry3 / 90,Entry4 / 90))
        }
    }

    If RegExMatch(LevelDefinition,"iS)Platforms\s*:\s*\K(?:-?\d+\s*(?:,\s*-?\d+\s*){6,7})*",Property)
    {
        Property := Trim(RegExReplace(RegExReplace(Property,"S)[\r \t]"),"S)\n+","`n"),"`n")
        Loop, Parse, Property, `n
        {
            Entry8 := 1.5
            StringSplit, Entry, A_LoopField, `,, %A_Space%`t
            Entities.Insert(new GameEntities.Platform(Entry1 / 90,Entry2 / 90,Entry3 / 90,Entry4 / 90,Entry5 / 90,Entry6 / 90,Entry7 / 90,Entry8 / 90))
        }
    }

    If RegExMatch(LevelDefinition,"iS)Goal\s*:\s*\K(?:-?\d+\s*(?:,\s*-?\d+\s*){3})*",Property)
    {
        StringSplit, Entry, Property, `,, %A_Space%`t`r`n
        Entities.Insert(new GameEntities.Goal(Entry1 / 90,Entry2 / 90,Entry3 / 90,Entry4 / 90))
    }

    RegExMatch(LevelDefinition,"iS)Player\s*:\s*\K(?:\d+\s*(?:,\s*\d+\s*){3,5})*",Property)
    Entry5 := 0, Entry6 := 0
    StringSplit, Entry, Property, `,, %A_Space%`t`r`n
    Entities.Insert(new GameEntities.Player(Entry1 / 90,Entry2 / 90,Entry3 / 90,Entry4 / 90, Entry5 / 90,Entry6 / 90))

    If RegExMatch(LevelDefinition,"iS)Enemies\s*:\s*\K(?:-?\d+\s*(?:,\s*-?\d+\s*){3,5})*",Property)
    {
        Property := Trim(RegExReplace(RegExReplace(Property,"S)[\r \t]"),"S)\n+","`n"),"`n")
        Loop, Parse, Property, `n, `r `t
        {
            Entry5 := 0, Entry6 := 0
            StringSplit, Entry, A_LoopField, `,, %A_Space%`t
            Entities.Insert(new GameEntities.Enemy(Entry1 / 90,Entry2 / 90,Entry3 / 90,Entry4 / 90,Entry5 / 90,Entry6 / 90))
        }
    }
}

MessageScreen(ByRef Game,Title = "",Message = "")
{
    PreviousLayers := Game.Layers
    Game.Layers := []
    Game.Layers[1] := new ProgressEngine.Layer
    Entities := Game.Layers[1].Entities
    Entities.Insert(new MessageScreenEntities.Background)
    Entities.Insert(new MessageScreenEntities.Title(Title))
    Entities.Insert(new MessageScreenEntities.Message(Message))
    Game.Start()
    Game.Layers := PreviousLayers
}

class MessageScreenEntities
{
    class Background extends ProgressEngine.Blocks.Default
    {
        __New()
        {
            base.__New()
            this.X := 0
            this.Y := 0
            this.W := 10
            this.H := 10
            this.Color := 0x444444
        }
    }

    class Title extends ProgressEngine.Blocks.Text
    {
        __New(Text)
        {
            base.__New()
            this.X := 5
            this.Y := 4.5
            this.Size := 8
            this.Color := 0xD0D0D0
            this.Weight := 100
            this.Typeface := "Georgia"
            this.Text := Text
        }
    }

    class Message extends ProgressEngine.Blocks.Text
    {
        __New(Text)
        {
            base.__New()
            this.X := 5
            this.Y := 5.5
            this.Size := 3
            this.Color := 0xF5F5F5
            this.Weight := 100
            this.Typeface := "Georgia"
            this.Text := Text
        }

        Step(Delta,Layer,Rectangle,ViewportWidth,ViewportHeight)
        {
            global Game
            If GetKeyState("Space","P") && WinActive("ahk_id " . Game.hWindow)
            {
                KeyWait, Space
                Return, 1
            }
        }
    }
}