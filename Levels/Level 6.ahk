#NoEnv

/*
Copyright 2011-2012 Anthony Zhang <azhang9@gmail.com>, Henry Lu <redacted@redacted.com>

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

MessageScreen(Game,"Level 6","Stuck in prison")

LayerX := 0, LayerY := 0
StartLevel := 1
Loop
{
    If StartLevel
    {
        Game.Layers[1] := new ProgressEngine.Layer
        Game.Layers[2] := new ProgressEngine.Layer
        Game.Layers[3] := new ProgressEngine.Layer

        Game.Layers[1].Entities.Insert(new KeyboardController)
        Environment.Clouds(Game.Layers[1])

        Game.Layers[2].X := LayerX, Game.Layers[2].Y := LayerY
        Entities := Game.Layers[2].Entities
        Entities.Insert(new GameEntities.Block(1,9,8,0.5))
        Entities.Insert(new GameEntities.Goal(7,8.2,0.5,0.8))
        Entities.Insert(new GameEntities.Player(4.5,8.556,0.333,0.444,0,0))
        Entities.Insert(new GameEntities.Enemy(6,8.556,0.333,0.444,0,0))

        Entities.Insert(new GameEntities.Box(4.5,4.066,0.333,0.5,0,0))
        Entities.Insert(new GameEntities.Box(4.5,4.466,0.333,0.5,0,0))
        Entities.Insert(new GameEntities.Box(4.5,5.066,0.333,0.5,0,0))
        Entities.Insert(new GameEntities.Box(4.5,5.466,0.333,0.5,0,0))
        Entities.Insert(new GameEntities.Box(4.5,6.066,0.333,0.5,0,0))
        Entities.Insert(new GameEntities.Box(4.5,6.466,0.333,0.5,0,0))
        Entities.Insert(new GameEntities.Box(4.5,7.066,0.333,0.5,0,0))
        Entities.Insert(new GameEntities.Box(4.5,7.466,0.333,0.5,0,0))
        Entities.Insert(new GameEntities.Box(4.5,8.066,0.333,0.5,0,0))
        
        Game.Layers[3].Entities.Insert(new GameEntities.HealthBar(Game.Layers[2]))
    }
    Result := Game.Start()
    StartLevel := 1
    If Result = 1 ;reached goal
        Break
    Else If Result = 4 ;game paused
        MessageScreen(Game,"Game paused","Press space to resume"), StartLevel := 0
    Else
        LayerX := Game.Layers[2].X, LayerY := Game.Layers[2].Y
}
Game.Layers := []