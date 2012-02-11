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
#Include Environment.ahk

LevelBackground := "Snow"

Gui, +Resize +LastFound +OwnDialogs
Gui, Show, w800 h600, ProgressPlatformer

Editor := new ProgressEngine(WinExist())

Editor.Layers[1] := new ProgressEngine.Layer
Environment[LevelBackground](Editor.Layers[1])

Editor.Layers[2] := new ProgressEngine.Layer

Editor.Layers[3] := new ProgressEngine.Layer
Entities := Editor.Layers[3].Entities
Entities.Insert(new EditingPane(2,2,3,5))
Loop
{
    Result := Editor.Start()
    If (Result = 1) ;save
        SaveLevel(Editor.Layers[2])
    Else If (Result = 2) ;change background
    {
        Editor.Layers[1] := new ProgressEngine.Layer
        Environment[LevelBackground](Editor.Layers[1])
    }
}
ExitApp

GuiClose:
Try Game.__Delete() ;wip: this is related to a limitation of the reference counting mechanism in AHK (Although references in static and global variables are released automatically when the program exits, references in non-static local variables or on the expression evaluation stack are not. These references are only released if the function or expression is allowed to complete normally.). normal exiting (game complete) works fine though
Catch
{
    
}
ExitApp

SaveLevel(Layer)
{
    For Index, Entity In Layer.Entities
    {
        ;save entity here
    }
}

class EditingPane extends ProgressEntities.Default
{
    __New(X,Y,W,H)
    {
        base.__New()
        this.X := X
        this.Y := Y
        this.W := W
        this.H := H
        this.OffsetX := 0
        this.OffsetY := 0
        this.Color := 0x555555
    }
}
