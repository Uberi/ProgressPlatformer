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

class ProgressEngine
{
    __New(hWindow)
    {
        this.Layers := []

        this.FrameRate := 60

        this.hWindow := hWindow
        this.hDC := DllCall("GetDC","UPtr",hWindow)
        If !this.hDC
            throw Exception("Could not obtain window device context.")

        this.hMemoryDC := DllCall("CreateCompatibleDC","UPtr",this.hDC)
        If !this.hMemoryDC
            throw Exception("Could not create memory device context.")

        If !DllCall("SetBkMode","UPtr",this.hMemoryDC,"Int",1) ;TRANSPARENT
            throw Exception("Could not set background mode.")
    }

    __Delete()
    {
        If !DllCall("SelectObject","UInt",this.hMemoryDC,"UPtr",this.hOriginalBitmap,"UPtr") ;deselect the bitmap from the device context
            throw Exception("Could not deselect bitmap from memory device context.")
        If !DllCall("DeleteObject","UPtr",this.hBitmap) ;delete the bitmap
            throw Exception("Could not delete bitmap.")
        If !DllCall("DeleteObject","UPtr",this.hMemoryDC) ;delete the memory device context
            throw Exception("Could not delete memory device context.")
        If !DllCall("ReleaseDC","UPtr",this.hWindow,"UPtr",this.hDC) ;release the window device context
            throw Exception("Could not release window device context.")
    }

    Start(DeltaLimit = 0.05)
    {
        ;calculate the amount of time each iteration should take
        If this.FrameRate != 0
            FrameDelay := 1000 / this.FrameRate

        TickFrequency := 0, PreviousTicks := 0, CurrentTicks := 0, ElapsedTime := 0
        If !DllCall("QueryPerformanceFrequency","Int64*",TickFrequency) ;obtain ticks per second
            throw Exception("Could not obtain performance counter frequency.")
        If !DllCall("QueryPerformanceCounter","Int64*",PreviousTicks) ;obtain the performance counter value
            throw Exception("Could not obtain performance counter value.")
        Loop
        {
            ;calculate the total time elapsed since the last iteration
            If !DllCall("QueryPerformanceCounter","Int64*",CurrentTicks)
                throw Exception("Could not obtain performance counter value.")
            Delta := (CurrentTicks - PreviousTicks) / TickFrequency
            PreviousTicks := CurrentTicks

            ;clamp delta to the upper limit
            If (Delta > DeltaLimit)
                Delta := DeltaLimit

            Result := this.Update(Delta)
            If Result
                Return, Result

            ;calculate the time elapsed during stepping in milliseconds
            If !DllCall("QueryPerformanceCounter","Int64*",ElapsedTime)
                throw Exception("Could not obtain performance counter value.")
            ElapsedTime := ((ElapsedTime - CurrentTicks) / TickFrequency) * 1000

            ;sleep the amount of time required to limit the framerate to the desired value
            If (this.FrameRate != 0 && ElapsedTime < FrameDelay)
                Sleep, % Round(FrameDelay - ElapsedTime)
        }
    }

    class Layer
    {
        __New()
        {
            this.Entities := []
            this.Visible := 1
            this.X := 0
            this.Y := 0
            this.W := 10
            this.H := 10
        }
    }

    Update(Delta)
    {
        static Width1 := -1, Height1 := -1, Rectangle := Object("X",0,"Y",0,"W",0,"H",0)
        ;obtain the dimensions of the client area
        VarSetCapacity(ClientRectangle,16)
        If !DllCall("GetClientRect","UPtr",this.hWindow,"UPtr",&ClientRectangle)
            throw Exception("Could not obtain client area dimensions.")
        Width := NumGet(ClientRectangle,8,"Int"), Height := NumGet(ClientRectangle,12,"Int")

        If (Width != Width1 || Height != Height1)
        {
            If this.hOriginalBitmap
            {
                If !DllCall("SelectObject","UInt",this.hMemoryDC,"UPtr",this.hOriginalBitmap,"UPtr") ;deselect the bitmap
                    throw Exception("Could not select original bitmap into memory device context.")
            }
            this.hBitmap := DllCall("CreateCompatibleBitmap","UPtr",this.hDC,"Int",Width,"Int",Height,"UPtr") ;create a new bitmap
            If !this.hBitmap
                throw Exception("Could not create bitmap.")
            this.hOriginalBitmap := DllCall("SelectObject","UInt",this.hMemoryDC,"UPtr",this.hBitmap,"UPtr")
            If !this.hOriginalBitmap
                throw Exception("Could not select bitmap into memory device context.")
        }
        Width1 := Width, Height1 := Height

        For Index, Layer In this.Layers
        {
            If !Layer.Visible
                Continue
            ScaleX := Width / Layer.W
            ScaleY := Height / Layer.H
            For Key, Entity In Layer.Entities
            {
                ;get the screen coordinates of the rectangle
                Rectangle.X := (Layer.X + Entity.X) * ScaleX, Rectangle.Y := (Layer.Y + Entity.Y) * ScaleY
                Rectangle.W := Entity.W * ScaleX, Rectangle.H := Entity.H * ScaleY

                Result := Entity.Step(Delta,Layer,Rectangle,Width,Height)
                If Result
                    Return, Result

                ;wip: log(n) occlusion culling here
                Entity.Draw(this.hMemoryDC,Rectangle,Width,Height)
            }
        }
        If !DllCall("BitBlt","UPtr",this.hDC,"Int",0,"Int",0,"Int",Width,"Int",Height,"UPtr",this.hMemoryDC,"Int",0,"Int",0,"UInt",0xCC0020) ;SRCCOPY
            throw Exception("Could not transfer pixel data to window device context.")
        Return, 0
    }
}

class ProgressBlocks
{
    class Default
    {
        __New()
        {
            ObjInsert(this,"",Object())
            this.X := 0
            this.Y := 0
            this.W := 10
            this.H := 10
            this.hPen := 0
            this.hBrush := 0
            this.Visible := 1
            this.Color := 0xFFFFFF
            this.Physical := 0
        }

        Step(Delta,Layer,Rectangle,ViewportWidth,ViewportHeight)
        {
            
        }

        NearestEntities(Layer)
        {
            ;wip
        }

        Draw(hDC,Rectangle,ViewportWidth,ViewportHeight)
        {
            ;check for entity moving out of bounds
            If (Rectangle.X + Rectangle.W) < 0 || Rectangle.X > ViewportWidth
                || (Rectangle.Y + Rectangle.H) < 0 || Rectangle.Y > ViewportHeight
                Return

            ;update the color if it has changed
            If this.ColorModified
            {
                If this.hPen && !DllCall("DeleteObject","UPtr",this.hPen)
                    throw Exception("Could not delete pen.")
                If this.hBrush && !DllCall("DeleteObject","UPtr",this.hBrush)
                    throw Exception("Could not delete brush.")
                this.hPen := DllCall("CreatePen","Int",0,"Int",0,"UInt",this.Color,"UPtr") ;PS_SOLID
                If !this.hPen
                    throw Exception("Could not create pen.")
                this.hBrush := DllCall("CreateSolidBrush","UInt",this.Color,"UPtr")
                If !this.hBrush
                    throw Exception("Could not create brush.")
                this.ColorModified := 0
            }

            hOriginalPen := DllCall("SelectObject","UInt",hDC,"UPtr",this.hPen,"UPtr") ;select the pen
            If !hOriginalPen
                throw Exception("Could not select pen into memory device context.")
            hOriginalBrush := DllCall("SelectObject","UInt",hDC,"UPtr",this.hBrush,"UPtr") ;select the brush
            If !hOriginalBrush
                throw Exception("Could not select brush into memory device context.")

            If this.Visible
            {
                If !DllCall("Rectangle","UPtr",hDC,"Int",Round(Rectangle.X),"Int",Round(Rectangle.Y),"Int",Round(Rectangle.X + Rectangle.W),"Int",Round(Rectangle.Y + Rectangle.H))
                    throw Exception("Could not draw rectangle.")
            }

            If !DllCall("SelectObject","UInt",hDC,"UPtr",hOriginalPen,"UPtr") ;deselect the pen
                throw Exception("Could not deselect pen from the memory device context.")
            If !DllCall("SelectObject","UInt",hDC,"UPtr",hOriginalBrush,"UPtr") ;deselect the brush
                throw Exception("Could not deselect brush from the memory device context.")
        }

        MouseHovering(Layer,Rectangle)
        {
            CoordMode, Mouse, Client
            MouseGetPos, MouseX, MouseY
            If (MouseX >= Rectangle.X && MouseX <= (Rectangle.X + Rectangle.W)
                && MouseY >= Rectangle.Y && MouseY <= (Rectangle.Y + Rectangle.H))
                Return, 1
            Return, 0
        }

        Collide(Rectangle,ByRef IntersectX,ByRef IntersectY)
        {
            Left1 := this.X, Left2 := Rectangle.X
            Right1 := Left1 + this.W, Right2 := Left2 + Rectangle.W
            Top1 := this.Y, Top2 := Rectangle.Y
            Bottom1 := Top1 + this.H, Bottom2 := Top2 + Rectangle.H

            ;check for collision
            If (Right1 < Left2 || Right2 < Left1 || Bottom1 < Top2 || Bottom2 < Top1)
            {
                IntersectX := 0, IntersectY := 0
                Return, 0 ;no collision occurred
            }

            ;find width of intersection
            If (Left1 < Left2)
                IntersectX := ((Right1 < Right2) ? Right1 : Right2) - Left2
            Else
                IntersectX := Left1 - ((Right1 < Right2) ? Right1 : Right2)

            ;find height of intersection
            If (Top1 < Top2)
                IntersectY := ((Bottom1 < Bottom2) ? Bottom1 : Bottom2) - Top2
            Else
                IntersectY := Top1 - ((Bottom1 < Bottom2) ? Bottom1 : Bottom2)
            Return, 1 ;collision occurred
        }

        Inside(Rectangle)
        {
            Return, this.X >= Rectangle.X
                    && (this.X + this.W) <= (Rectangle.X + Rectangle.W)
                    && this.Y >= Rectangle.Y
                    && (this.Y + this.H) <= (Rectangle.Y + Rectangle.H)
        }

        __Get(Key)
        {
            If (Key != "")
                Return, this[""][Key]
        }

        __Set(Key,Value)
        {
            If (Key = "Color" && this[Key] != Value)
                this.ColorModified := 1
            ObjInsert(this[""],Key,Value)
            Return, this
        }

        __Delete()
        {
            If this.hPen && !DllCall("DeleteObject","UPtr",this.hPen)
                throw Exception("Could not delete pen.")
            If this.hBrush && !DllCall("DeleteObject","UPtr",this.hBrush)
                throw Exception("Could not delete brush.")
        }
    }

    class Static extends ProgressBlocks.Default
    {
        __New()
        {
            base.__New()
            this.Physical := 1
        }
    }

    class Dynamic extends ProgressBlocks.Static
    {
        Step(Delta,Layer,Rectangle,ViewportWidth,ViewportHeight)
        {
            ;wip: use spatial acceleration structure
            Friction := 0.01
            Restitution := 0.6

            this.X += this.SpeedX * Delta, this.Y -= this.SpeedY * Delta ;process momentum

            CollisionX := 0, CollisionY := 0, TotalIntersectX := 0, TotalIntersectY := 0
            For Index, Entity In Layer.Entities
            {
                If (&Entity = &this || !Entity.Physical) ;entity is the same as the current entity or is not physical
                    Continue
                If !this.Collide(Entity,IntersectX,IntersectY) ;entity did not collide with the rectangle
                    Continue
                If (Abs(IntersectX) >= Abs(IntersectY)) ;collision along top or bottom side
                {
                    CollisionY := 1
                    this.Y -= IntersectY ;move the entity out of the intersection area
                    this.SpeedY *= -Restitution ;reflect the speed and apply damping
                    TotalIntersectY += Abs(IntersectY)
                }
                Else ;collision along left or right side
                {
                    CollisionX := 1
                    this.X -= IntersectX ;move the entity out of the intersection area
                    this.SpeedX *= -Restitution ;reflect the speed and apply damping
                    TotalIntersectX += Abs(IntersectX)
                }
            }
            this.IntersectX := TotalIntersectX, this.IntersectY := TotalIntersectY
            If CollisionY
                this.SpeedX *= (Friction * TotalIntersectY) ** Delta ;apply friction
            If CollisionX
                this.SpeedY *= (Friction * TotalIntersectX) ** Delta ;apply friction
        }
    }

    class Text extends ProgressBlocks.Default
    {
        __New()
        {
            base.__New()
            this.hFont := 0
            this.PreviousViewportWidth := -1
            this.Align := "Center"
            this.Size := 5
            this.Weight := 500
            this.Italic := 0
            this.Underline := 0
            this.Strikeout := 0
            this.Typeface := "Verdana"
            this.Text := "Text"
        }

        Draw(hDC,Rectangle,ViewportWidth,ViewportHeight)
        {
            ;check for entity moving out of bounds
            If (Rectangle.X + Rectangle.W) < 0 || Rectangle.X > ViewportWidth
                || (Rectangle.Y + Rectangle.H) < 0 || Rectangle.Y > ViewportHeight
                Return

            If (this.Align = "Left")
                AlignMode := 24 ;TA_LEFT | TA_BASELINE: align text to the left and the baseline
            Else If (this.Align = "Center")
                AlignMode := 30 ;TA_CENTER | TA_BASELINE: align text to the center and the baseline
            Else If (this.Align = "Right")
                AlignMode := 26 ;TA_RIGHT | TA_BASELINE: align text to the right and the baseline
            Else
                throw Exception("Invalid text alignment: " . this.Align . ".")
            DllCall("SetTextAlign","UPtr",hDC,"UInt",AlignMode)

            LineHeight := this.Size * ViewportWidth * 0.01

            ;update the font if it has changed or if the viewport size has changed
            If this.FontModified || ViewportWidth != this.PreviousViewportWidth
            {
                If this.hFont && !DllCall("DeleteObject","UPtr",this.hFont)
                    throw Exception("Could not delete font.")
                ;wip: doesn't work
                ;If this.Size Is Not Number
                    ;throw Exception("Invalid font size: " . this.Size . ".")
                ;If this.Weight Is Not Integer
                    ;throw Exception("Invalid font weight: " . this.Weight . ".")
                this.hFont := DllCall("CreateFont","Int",Round(LineHeight),"Int",0,"Int",0,"Int",0,"Int",this.Weight,"UInt",this.Italic,"UInt",this.Underline,"UInt",this.Strikeout,"UInt",1,"UInt",0,"UInt",0,"UInt",4,"UInt",0,"Str",this.Typeface,"UPtr") ;DEFAULT_CHARSET, ANTIALIASED_QUALITY
                If !this.hFont
                    throw Exception("Could not create font.")
                this.FontModified := 0
            }
            this.PreviousViewportWidth := ViewportWidth

            If (DllCall("SetTextColor","UPtr",hDC,"UInt",this.Color) = 0xFFFFFFFF) ;CLR_INVALID
                throw Exception("Could not set text color.")

            hOriginalFont := DllCall("SelectObject","UInt",hDC,"UPtr",this.hFont,"UPtr") ;select the font
            If !hOriginalFont
                throw Exception("Could not select font into memory device context.")

            If this.Visible
            {
                ;Loop, Parse, This.Text, `n ;wip
                Text := this.Text, PositionY := Rectangle.Y
                Loop, Parse, Text, `n
                {
                    If !DllCall("TextOut","UPtr",hDC,"Int",Round(Rectangle.X),"Int",Round(PositionY),"Str",A_LoopField,"Int",StrLen(A_LoopField))
                        throw Exception("Could not draw text.")
                    PositionY += LineHeight
                }
            }

            If !DllCall("SelectObject","UInt",hDC,"UPtr",hOriginalFont,"UPtr") ;deselect the font
                throw Exception("Could not deselect font from memory device context.")
        }

        __Set(Key,Value)
        {
            If ((Key = "Size" || Key = "Weight" || Key = "Italic" || Key = "Underline" || Key = "Strikeout" || Key = "Typeface")
                && this[Key] != Value)
                ObjInsert(this[""],"FontModified",1)
            ObjInsert(this[""],Key,Value)
            Return, this
        }

        __Delete()
        {
            If this.hFont && !DllCall("DeleteObject","UPtr",this.hFont)
                throw Exception("Could not delete font.")
        }
    }
}