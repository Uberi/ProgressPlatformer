#NoEnv

/*
Copyright 2011-2012 Anthony Zhang <azhang9@gmail.com>

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

Notes := new NotePlayer(28)

Notes.Repeat := 1

Loop, 2
{
    Notes.Note(49,2000,50).Note(52,2000,50).Delay(3200)
    Notes.Note(52,2000,70).Note(56,2000,70).Delay(3200)
    Notes.Note(47,2000,45).Note(51,2000,45).Delay(3000)
    Notes.Note(45,2000,40).Note(49,2000,40).Delay(3400)
}

Notes.Note(49,2000,50).Note(52,2000,50).Delay(3200)
Notes.Note(52,2000,70).Note(56,2000,70).Delay(3200)
Notes.Note(56,2000,45).Note(59,2000,45).Delay(3000)
Notes.Note(51,2000,40).Note(57,2000,40).Delay(3400)

Notes.Note(49,2000,50).Note(52,2000,50).Delay(3200)
Notes.Note(52,2000,70).Note(56,2000,70).Delay(3200)
Notes.Note(47,2000,45).Note(51,2000,45).Delay(3000)
Notes.Note(54,2000,40).Note(57,2000,40).Delay(3400)

Notes.Start()

StartLevel := 1
Loop
{
    If StartLevel
    {
        Game.Layers[1] := new ProgressEngine.Layer
        Game.Layers[2] := new ProgressEngine.Layer
        Game.Layers[1].Entities.Insert(new KeyboardController)
        Environment.Clouds(Game.Layers[1])
        Entities := Game.Layers[2].Entities
        Entities.Insert(new GameEntities.Block(1,9,8,0.5))
        Entities.Insert(new GameEntities.Goal(7,8.2,0.5,0.8))
        Entities.Insert(new GameEntities.Player(1.5,7,0.333,0.444,0,0))

        Entities.Insert(new TutorialText("Let's warm up."))
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
        Game.Layers[1].Entities.Insert(new KeyboardController)
        Environment.Clouds(Game.Layers[1])
        Entities := Game.Layers[2].Entities
        Entities.Insert(new GameEntities.Block(1,9,8,0.5))
        Entities.Insert(new GameEntities.Goal(7,8.2,0.5,0.8))
        Entities.Insert(new GameEntities.Player(1.5,7,0.333,0.444,0,0))

        Entities.Insert(new GameEntities.Box(3,7,0.5,0.5,0,0))
        Entities.Insert(new GameEntities.Box(3,6.5,0.5,0.5,0,0))
        Entities.Insert(new GameEntities.Box(3,6,0.5,0.5,0,0))
        Entities.Insert(new GameEntities.Box(3,5.5,0.5,0.5,0,0))
        Entities.Insert(new GameEntities.Box(3,5,0.5,0.5,0,0))
        Entities.Insert(new GameEntities.Box(3,4.5,0.5,0.5,0,0))
        Entities.Insert(new GameEntities.Box(3,4,0.5,0.5,0,0))
        Entities.Insert(new GameEntities.Box(3,3.5,0.5,0.5,0,0))
        Entities.Insert(new GameEntities.Box(3,3,0.5,0.5,0,0))

        Entities.Insert(new TutorialText("That was too easy."))
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

Notes.Stop()
Notes.Device.__Delete() ;wip

class TutorialText extends ProgressEntities.Text
{
    __New(Text,X = 5,Y = 3.6)
    {
        base.__New()
        this.X := X
        this.Y := Y
        this.Size := 5
        this.Color := 0x444444
        this.Weight := 100
        this.Typeface := "Georgia"
        this.Text := Text
    }
}