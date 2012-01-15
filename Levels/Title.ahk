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

Game.Layers[1] := new ProgressEngine.Layer
Game.Layers[2] := new ProgressEngine.Layer
Game.Layers[1].Entities.Insert(new GameEntities.Background)
Random, FlakeCount, 60, 100
Loop, %FlakeCount% ;add clouds
    Game.Layers[1].Entities.Insert(new Snowflake(Game.Layers[1]))
Game.Layers[1].Entities.Insert(new TitleText("Achromatic"))
Game.Layers[1].Entities.Insert(new TitleMessage("Press Space to begin"))
Game.Start()
Game.Layers := []

class Snowflake extends ProgressBlocks.Default
{
    __New(Layer)
    {
        base.__New()
        this.Color := 0xE8E8E8
        Random, Temp1, 0.0, Layer.W
        this.X := Temp1
        Random, Temp1, -Layer.H, Layer.H
        this.Y := Temp1
        this.W := 0.2
        this.H := 0.2
        Random, Temp1, -0.3, 0.3
        this.SpeedX := Temp1
        Random, Temp1, 0.2, 0.5
        this.SpeedY := Temp1
    }

    Step(Delta,Layer,Rectangle,ViewportWidth,ViewportHeight)
    {
        this.X += this.SpeedX * Delta
        this.Y += this.SpeedY * Delta
        If this.X < -this.W
            this.X := Layer.W
        If this.X > Layer.W
            this.X := -this.W
        If this.Y > Layer.H
            this.Y := -this.H
    }
}

class TitleText extends ProgressBlocks.Text
{
    __New(Text)
    {
        base.__New()
        this.X := 5
        this.Y := 5
        this.Size := 15
        this.Color := 0x444444
        this.Weight := 100
        this.Typeface := "Georgia"
        this.Text := Text
    }
}

class TitleMessage extends ProgressBlocks.Text
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