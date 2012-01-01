#NoEnv

class ProgressEngine
{
    static ControlCounter := 0

    __New(hWindow)
    {
        this.Layers := []

        this.FrameRate := 30

        this.hWindow := hWindow
        this.hDC := DllCall("GetDC","UPtr",hWindow)

        this.hMemoryDC := DllCall("CreateCompatibleDC","UPtr",this.hDC)
        this.hBitmap := DllCall("CreateCompatibleBitmap","UPtr",this.hDC,"Int",800,"Int",600,"UPtr")
        DllCall("SelectObject","UInt",this.hMemoryDC,"UPtr",this.hBitmap,"UPtr")
    }

    Start(DeltaLimit = 0.05)
    {
        ;calculate the amount of time each iteration should take
        If this.FrameRate != 0
            FrameDelay := 1000 / this.FrameRate

        TickFrequency := 0, PreviousTicks := 0, CurrentTicks := 0, ElapsedTime := 0
        DllCall("QueryPerformanceFrequency","Int64*",TickFrequency) ;obtain ticks per second
        DllCall("QueryPerformanceCounter","Int64*",PreviousTicks)
        Loop
        {
            ;calculate the total time elapsed since the last iteration
            DllCall("QueryPerformanceCounter","Int64*",CurrentTicks)
            Delta := (CurrentTicks - PreviousTicks) / TickFrequency
            PreviousTicks := CurrentTicks

            ;clamp delta to the upper limit
            If (Delta > DeltaLimit)
                Delta := DeltaLimit

            If this.Step(Delta)
                Break
            this.Update()

            ;calculate the time elapsed during stepping in milliseconds
            DllCall("QueryPerformanceCounter","Int64*",ElapsedTime)
            ElapsedTime := ((ElapsedTime - CurrentTicks) / TickFrequency) * 1000

            ;sleep the amount of time required to limit the framerate to the desired value
            If (this.FrameRate != 0 && ElapsedTime < FrameDelay)
                Sleep, % Round(FrameDelay - ElapsedTime)
        }
    }

    Step(Delta)
    {
        For Index, Layer In this.Layers
        {
            For Key, Entity In Layer.Entities
            {
                If Entity.Step(Delta,Layer)
                    Return, 1
            }
        }
        Return, 0
    }

    class Layer
    {
        __New()
        {
            this.Entities := []
            this.X := 0
            this.Y := 0
            this.W := 10
            this.H := 10
            this.ScaleX := 1
            this.ScaleY := 1
        }
    }

    Update()
    {
        global hBitmap
        ;obtain the dimensions of the client area
        VarSetCapacity(ClientRectangle,16)
        DllCall("GetClientRect","UPtr",this.hWindow,"UPtr",&ClientRectangle)
        Width := NumGet(ClientRectangle,8,"Int"), Height := NumGet(ClientRectangle,12,"Int")

        For Index, Layer In this.Layers
        {
            ScaleX := (Width / Layer.W) * Layer.ScaleX
            ScaleY := (Height / Layer.H) * Layer.ScaleY
            For Key, Entity In Layer.Entities
            {
                ;update the color if it has changed
                If Entity.ColorModified
                {
                    If Entity.hPen
                        DllCall("DeleteObject","UPtr",Entity.hPen)
                    If Entity.hBrush
                        DllCall("DeleteObject","UPtr",Entity.hBrush)
                    Entity.hPen := DllCall("CreatePen","Int",0,"Int",0,"UInt",Entity.Color,"UPtr") ;PS_SOLID
                    Entity.hBrush := DllCall("CreateSolidBrush","UInt",Entity.Color,"UPtr")
                    Entity.ColorModified := 0
                }

                DllCall("SelectObject","UInt",this.hMemoryDC,"UPtr",Entity.hPen,"UPtr")
                DllCall("SelectObject","UInt",this.hMemoryDC,"UPtr",Entity.hBrush,"UPtr")

                ;get the screen coordinates of the rectangle
                CurrentX := Round((Layer.X + Entity.X) * ScaleX), CurrentY := Round((Layer.Y + Entity.Y) * ScaleY)
                CurrentW := Round(Entity.W * ScaleX), CurrentH := Round(Entity.H * ScaleY)
                
                ;check for entity moving out of bounds
                If (CurrentX + CurrentW) < 0 || CurrentX > Width
                    || (CurrentY + CurrentH) < 0 || CurrentY > Height
                {
                    ;wip: skip drawing the rectangle
                    ;Continue
                }

                If Entity.Visible
                    DllCall("Rectangle","UPtr",this.hMemoryDC,"Int",CurrentX,"Int",CurrentY,"Int",CurrentX + CurrentW,"Int",CurrentY + CurrentH)
            }
        }
        DllCall("BitBlt","UPtr",this.hDC,"Int",0,"Int",0,"Int",Width,"Int",Height,"UPtr",this.hMemoryDC,"Int",0,"Int",0,"UInt",0xCC0020) ;SRCCOPY
    }

    class Blocks
    {
        class Default
        {
            __New()
            {
                ObjInsert(this,"",Object())
                this.Visible := 1
                this.ColorModified := 0
                this.Color := 0xFFFFFF
                this.Physical := 0
            }

            Step(Delta,Layer)
            {
                
            }

            NearestEntities(Layer)
            {
                ;wip
            }

            __Get(Key)
            {
                If (Key != "")
                    Return, this[""][Key]
            }

            __Set(Key,Value)
            {
                If (Key = "Color")
                    this.ColorModified := 1
                ObjInsert(this[""],Key,Value)
                Return, this
            }
        }

        class Static extends ProgressEngine.Blocks.Default
        {
            __New()
            {
                base.__New()
                this.Physical := 1
            }

            Step(Delta,Layer)
            {
                
            }
        }

        class Dynamic extends ProgressEngine.Blocks.Static
        {
            Step(Delta,Layer)
            {
                ;wip: use spatial acceleration structure
                ;set physical constants
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
        }
    }

    __Delete()
    {
        DllCall("ReleaseDC","UPtr",this.hWindow,"UPtr",this.hDC) ;release the device context
    }
}