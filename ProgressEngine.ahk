#NoEnv

class ProgressEngine
{
    static ControlCounter := 0

    __New(GUIIndex = 1)
    {
        this.GUIIndex := GUIIndex
        this.Entities := []
        this.X := 0
        this.Y := 0
    }

    Step()
    {
        For Index, Entity In Entities
        {
            If ObjHasKey(Entity,"Handler")
                Entity.Handler()
        }
    }

    Update()
    {
        ;wip: use occlusion culling here
        For Index, Entity In this.Entities
        {
            CurrentX := this.X + Entity.X, CurrentY := this.Y + Entity.Y
            CurrentW := this.W + Entity.W, CurrentH := this.H + Entity.H
            If (Index > this.ControlCounter) ;control does not yet exist
            {
                ProgressEngine.ControlCounter ++
                Gui, Add, Progress, % "x" . CurrentX . " y" . CurrentY . " w" . CurrentW . " h" . CurrentH . " vProgressEngine" . ProgressEngine.ControlCounter . " hwndhControl", 0
                Control, ExStyle, -0x20000,, ahk_id %hControl% ;remove WS_EX_STATICEDGE extended style
            }
            Else
            {
                GuiControl, Show, %Name%%Index%
                GuiControl, Move, %Name%%Index%, x%CurrentX% y%CurrentY% w%CurrentW% h%CurrentH%
            }
        }
    }
}