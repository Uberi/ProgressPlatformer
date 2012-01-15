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

StartLevel := 1
Loop
{
    If StartLevel
    {
        Game.Layers[1] := new ProgressEngine.Layer
        Game.Layers[2] := new ProgressEngine.Layer
        Game.Layers[1].Entities.Insert(new GameEntities.Background)
        Game.Layers[1].Entities.Insert(new KeyboardController)
        Random, CloudCount, 6, 10
        Loop, %CloudCount% ;add clouds
            Game.Layers[1].Entities.Insert(new Cloud(Game.Layers[1]))
        Game.Layers[1].Entities.Insert(new TutorialText("Oh look!`n`nA door!"))
        Entities := Game.Layers[2].Entities
        Entities.Insert(new GameEntities.Block(1,9,8,0.5))
        Entities.Insert(new GameEntities.Goal(7,8.2,0.5,0.8))
        Entities.Insert(new GameEntities.Player(1.5,7,1 / 3,4 / 9,0,0))
    }
    Result := Game.Start()
    StartLevel := 1
    If Result = 1 ;reached goal
        Break
    If Result = 3 ;out of bounds
        MessageScreen(Game,"Out of bounds","Press Space to restart the level.")
    Else If Result = 4 ;paused
        MessageScreen(Game,"Paused","Press Space to resume."), StartLevel := 0
}
Game.Layers := []

StartLevel := 1
Loop
{
    If StartLevel
    {
        Game.Layers[1] := new ProgressEngine.Layer
        Game.Layers[2] := new ProgressEngine.Layer
        Game.Layers[1].Entities.Insert(new GameEntities.Background)
        Game.Layers[1].Entities.Insert(new KeyboardController)
        Random, CloudCount, 6, 10
        Loop, %CloudCount% ;add clouds
            Game.Layers[1].Entities.Insert(new Cloud(Game.Layers[1]))
        Game.Layers[1].Entities.Insert(new TutorialText("That was too easy."))
        Entities := Game.Layers[2].Entities
        Entities.Insert(new GameEntities.Block(1,9,8,0.5))
        Entities.Insert(new GameEntities.Goal(7,8.2,0.5,0.8))
        Entities.Insert(new GameEntities.Player(1.5,7,1 / 3,4 / 9,0,0))
    }
    Result := Game.Start()
    StartLevel := 1
    If Result = 1 ;reached goal
        Break
    If Result = 3 ;out of bounds
        MessageScreen(Game,"Out of bounds","Press Space to restart the level.")
    Else If Result = 4 ;paused
        MessageScreen(Game,"Paused","Press Space to resume."), StartLevel := 0
}

class TutorialText extends ProgressBlocks.Text
{
    __New(Text)
    {
        base.__New()
        this.X := 5
        this.Y := 3.6
        this.Size := 5
        this.Color := 0x444444
        this.Weight := 100
        this.Typeface := "Georgia"
        this.Text := Text
    }
}