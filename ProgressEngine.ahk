#NoEnv

class ProgressEngine
{
    static ControlCounter := 0
    static Entities := Object()

    __New(GUIIndex = 1)
    {
        this.GUIIndex := GUIIndex
        this.Entities := []
        this.X := 0
        this.Y := 0
        this.W := 10
        this.H := 10

        this.FrameRate := 30

        this.ScaleX := 0.9
        this.ScaleY := 1.1

        Gui, %GUIIndex%:+LastFound
        this.hWindow := WinExist()
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
        For Index, Entity In this.Entities
        {
            If Entity.Step(Delta,this.Entities)
                Return, 1
        }
        Return, 0
    }

    Delete(EntityKey)
    {
        GUIIndex := this.GUIIndex
        GuiControl, %GUIIndex%:Hide, ProgressEngine%Index%
        ObjRemove(this.Entities,EntityKey)
    }

    Update()
    {
        global ;must be global in order to use GUI variables
        local GUIIndex, CurrentX, CurrentY, CurrentW, CurrentH, EntityIdentifier
        ;wip: support subcategories in this.entities by checking entity.base.__class and recursing if it is not based on the entity class
        ;wip: use an internal list of controls so that offscreen controls can be reused
        ;wip: use modification flags or setters to not update properties like color unnecessarily
        GUIIndex := this.GUIIndex

        ;obtain the dimensions of the client area
        VarSetCapacity(ClientRectangle,16)
        DllCall("GetClientRect","UPtr",this.hWindow,"UPtr",&ClientRectangle)
        Width := NumGet(ClientRectangle,8,"Int"), Height := NumGet(ClientRectangle,12,"Int")

        ScaleX := (Width / this.W) * this.ScaleX
        ScaleY := (Height / this.H) * this.ScaleY

        For Index, Entity In this.Entities
        {
            ;get the screen coordinates of the rectangle
            CurrentX := Round((this.X + Entity.X) * ScaleX), CurrentY := Round((this.Y + Entity.Y) * ScaleY)
            CurrentW := Round(Entity.W * ScaleX), CurrentH := Round(Entity.H * ScaleY)

            ;check for the entity being out of bounds
            If (CurrentX + CurrentW) < 0 || CurrentX > Width
                || (CurrentY + CurrentH) < 0 || CurrentY > Height
            {
                ;wip: hide the rectangle
                ;Continue
            }

            If Entity.Index ;control already exists
            {
                EntityIdentifier := "ProgressEngine" . Entity.Index
                For Key In Entity.ModifiedProperties
                {
                    If (Key = "Visible")
                        GuiControl, % GUIIndex . ":Show" . Entity.Visible, %EntityIdentifier%
                    Else If (Key = "Color")
                        GuiControl, % GUIIndex . ":+Background" . Entity.Color, %EntityIdentifier%
                    ObjRemove(Entity.ModifiedProperties,Key)
                }
                GuiControl, %GUIIndex%:Move, %EntityIdentifier%, x%CurrentX% y%CurrentY% w%CurrentW% h%CurrentH%
            }
            Else ;control does not exist
            {
                ProgressEngine.ControlCounter ++
                Entity.Index := ProgressEngine.ControlCounter
                Entity.VisibleState := 1
                Gui, %GUIIndex%:Add, Progress, % "x" . CurrentX . " y" . CurrentY . " w" . CurrentW . " h" . CurrentH . " vProgressEngine" . ProgressEngine.ControlCounter . " hwndhControl Background" . Entity.Color, 0
                Control, ExStyle, -0x20000,, ahk_id %hControl% ;remove WS_EX_STATICEDGE extended style
            }
        }
    }

    class Blocks
    {
        class Default
        {
            __New()
            {
                ObjInsert(this,"",Object())
                this.Index := 0
                this.Visible := 1
                this.Color := "FF0000"
                this.Physical := 0
                this.ModifiedProperties := Object()
            }

            Step(Delta,Entities)
            {
                
            }

            __Get(Key)
            {
                If (Key != "")
                    Return, this[""][Key]
            }

            __Set(Key,Value)
            {
                If Key In Visible,Color,Physical
                    ObjInsert(this.ModifiedProperties,Key,"")
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

            Step(Delta,Entities)
            {
                
            }
        }

        class Dynamic extends ProgressEngine.Blocks.Static
        {
            Step(Delta,Entities)
            {
                ;wip: use spatial acceleration structure
                ;set physical constants
                Gravity := -9.81 ;wip: not sure if this should be a user-implemented thing
                Friction := 0.01
                Restitution := 0.6

                this.SpeedY += Gravity * Delta ;process gravity
                this.X += this.SpeedX * Delta, this.Y -= this.SpeedY * Delta ;process momentum

                CollisionX := 0, CollisionY := 0, TotalIntersectX := 0, TotalIntersectY := 0
                For Index, Entity In Entities
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
                If CollisionY
                {
                    this.IntersectY := TotalIntersectY
                    this.SpeedX *= (Friction * TotalIntersectY) ** Delta ;apply friction
                }
                If CollisionX
                {
                    this.IntersectX := TotalIntersectX
                    this.SpeedY *= (Friction * TotalIntersectX) ** Delta ;apply friction
                }
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
}