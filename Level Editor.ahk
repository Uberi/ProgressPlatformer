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

;Editor.Layers[2] := new ProgressEngine.Layer ;wip: debug

Editor.Layers[3] := new ProgressEngine.Layer(1)
Editor.Layers[3].Layers[1] := new ProgressEngine.Layer
Editor.Layers[3].X := 2, Editor.Layers[3].Y := 2
Editor.Layers[3].W := 3, Editor.Layers[3].H := 5
Layers := Editor.Layers[3].Layers
Layers[1] := new ProgressEngine.Layer
Layers[1].Entities.Insert(new EditingPane.Background)
Layers[2] := new ProgressEngine.Layer
Layers[2].Entities.Insert(new EditingPane.Title("Level Editor"))

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

class EditingPane
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
            this.Color := 0x555555
        }
    }

    class Title extends ProgressEntities.Text
    {
        __New(Text)
        {
            base.__New()
            this.X := 5
            this.Y := 1
            this.W := 10
            this.H := 1
            this.Size := 4
            this.Color := 0xFFFFFF
            this.Weight := 100
            this.Typeface := "Georgia"
            this.Text := Text
        }
    }
}

ShowObject(ShowObject,Padding = "")
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