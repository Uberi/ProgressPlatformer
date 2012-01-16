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
Environment.Snow(Game.Layers[1])
Game.Layers[1].Entities.Insert(new TitleText("Game Complete"))
Game.Layers[1].Entities.Insert(new TitleMessage("Press Space to exit"))
Game.Start()
Game.Layers := []