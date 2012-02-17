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

;wip: container drawtype doesn't support multiple levels of nesting
;wip: credit screen
;wip: total asynchronocity or parallelism (tasklets)
;wip: input manager that supports keyboard and joystick input
;wip: oncollide() callbacks for ProgressEntities.Dynamic, onclick() and onhover() callbacks for ProgressEntities.Default

#Include %A_ScriptDir%

#Include ProgressEngine.ahk
#Include Music.ahk
#Include Environment.ahk

#Warn All
#Warn LocalSameAsGlobal, Off

Gravity := -9.81

SetBatchLines, -1
DetectHiddenWindows, On

Gui, +Resize +MinSize300x200 +LastFound +OwnDialogs
Gui, Show, w800 h600, ProgressPlatformer

Game := new ProgressEngine(WinExist())

#Include Levels/Title.ahk
#Include Levels/Tutorial.ahk

Notes := new NotePlayer(0)

Notes.Repeat := 1

Notes.Delay(1000)
Notes.Note(33,3000,55).Note(41,3000,55).Note(48,3000,55).Note(56,3000,55).Delay(3500)
Notes.Note(36,3000,60).Note(48,3000,60).Note(51,3000,60).Note(60,3000,60).Delay(3000)
Notes.Note(30,3500,70).Note(39,3500,70).Note(56,3500,70).Note(60,3500,70).Delay(3500)
Notes.Note(33,4000,45).Note(41,4000,45).Note(49,4000,45).Note(58,4000,45).Delay(4000)

Notes.Play()

#Include Levels/Level 1.ahk
#Include Levels/Level 2.ahk
#Include Levels/Level 3.ahk

Notes.Stop()
Notes.Device.__Delete() ;wip

#Include Levels/End.ahk
ExitApp

GuiClose:
Try Game.__Delete() ;wip: this is related to a limitation of the reference counting mechanism in AHK (Although references in static and global variables are released automatically when the program exits, references in non-static local variables or on the expression evaluation stack are not. These references are only released if the function or expression is allowed to complete normally.). normal exiting (game complete) works fine though
Catch
{
    
}
Notes.Stop() ;wip: also a garbage collection issue
Try Notes.Device.__Delete() ;wip
Catch
{
    
}
ExitApp

class TitleText extends ProgressEntities.Text
{
    __New(Text)
    {
        base.__New()
        this.X := 5
        this.Y := 5
        this.Size := 14
        this.Color := 0x444444
        this.Weight := 100
        this.Typeface := "Georgia"
        this.Text := Text
    }
}

class TitleMessage extends ProgressEntities.Text
{
    __New(Text)
    {
        base.__New()
        this.X := 5
        this.Y := 6
        this.Size := 3
        this.Color := 0x666666
        this.Weight := 100
        this.Typeface := "Georgia"
        this.Text := Text
    }

    Step(Delta,Layer,Viewport)
    {
        global Game
        If GetKeyState("Space","P") && WinActive("ahk_id " . Game.hWindow)
        {
            KeyWait, Space
            Return, 1
        }
    }
}

class KeyboardController
{
    Step(ByRef Delta,Layer,Viewport)
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

class GameEntities
{
    class HealthBar extends ProgressEntities.Default
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

        Step(Delta,Layer,Viewport)
        {
            this.W := (Mod(this.Player.Health,100) / 100) * this.TotalWidth
            this.H := 0.08 * ((this.Player.Health // 100) + 1)
        }
    }

    class Block extends ProgressEntities.Static
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

    class Platform extends ProgressEntities.Static
    {
        __New(X,Y,W,H,Horizontal,Start,Length,Speed)
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

        Step(Delta,Layer,Viewport)
        {
            ;wip: need to push player along direction of platform
            If (this.X < this.RangeX)
                this.Direction := 1
            Else If (this.X > (this.RangeX + this.RangeW))
                this.Direction := -1
            this.X += this.Speed * Delta * this.Direction
        }
    }
    
    class Box extends ProgressEntities.Dynamic
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
            this.Density := 0.5
        }

        Step(Delta,Layer,Viewport)
        {
            global Gravity

            this.SpeedY += Gravity * Delta ;process gravity
            base.Step(Delta,Layer,Viewport)
        }
    }

    class Player extends ProgressEntities.Dynamic
    {
        __New(X,Y,W,H,SpeedX,SpeedY)
        {
            base.__New()
            this.X := X
            this.Y := Y
            this.W := W
            this.H := H
            this.FullH := H
            this.SpeedX := SpeedX
            this.SpeedY := SpeedY
            this.Color := 0xAFAFAF
            this.LastContact := 0
            this.Health := 100
        }

        Step(Delta,Layer,Viewport)
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
                If (Entity.__Class = "GameEntities.Enemy" && this.Intersect(Entity,IntersectX,IntersectY)) ;player collided with an enemy
                {
                    If (Abs(IntersectY) < Abs(IntersectX) && this.Y < Entity.Y)
                    {
                        Layer.Entities.Remove(Key) ;wip: can't do this in a For loop (maybe would be better in an oncollide callback)
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

            If Crouch
            {
                this.H := this.FullH * 0.75
                MoveSpeed *= 0.5
            }
            Else
                this.H := this.FullH

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
            If this.IntersectY ;contacting top or bottom of a block
                this.LastContact := A_TickCount

            Layer.X += (((this.X + (this.W / 2)) - (Layer.X + (Layer.W / 2))) * 0.03)
            Layer.Y += (((this.Y + (this.H / 2)) - (Layer.Y + (Layer.H / 2))) * 0.03)

            base.Step(Delta,Layer,Viewport)
        }
    }

    class Goal extends ProgressEntities.Default ;wip: have this detect the player instead of the player detecting this
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

    class Enemy extends ProgressEntities.Dynamic
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

        Step(Delta,Layer,Viewport)
        {
            global Gravity
            MoveSpeed := 8
            JumpSpeed := MoveSpeed * 0.25

            ;move towards the player
            For Key, Entity In Layer.Entities ;wip: use NearestEntities(), add a findentity() function
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
            }

            If this.IntersectY ;contacting top or bottom of a block
                this.LastContact := A_TickCount

            this.SpeedY += Gravity * Delta ;process gravity
            base.Step(Delta,Layer,Viewport)
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
    class Background extends ProgressEntities.Default
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

    class Title extends ProgressEntities.Text
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

    class Message extends ProgressEntities.Text
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

        Step(Delta,Layer,Viewport)
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