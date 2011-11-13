#NoEnv
#SingleInstance Force

;wip: moving platforms and elevators

TargetFrameRate := 30
DeltaLimit := 0.05

Gravity := -981
Friction := 0.01
Restitution := 0.6

LevelIndex := 1

SetBatchLines, -1
SetWinDelay, -1

GoSub, MakeGuis

TargetFrameDelay := 1000 / TargetFrameRate
TickFrequency := 0, DllCall("QueryPerformanceFrequency","Int64*",TickFrequency) ;obtain ticks per second
PreviousTicks := 0, CurrentTicks := 0
Loop
{
    If Initialize()
        Break
    DllCall("QueryPerformanceCounter","Int64*",PreviousTicks)
    Loop
    {
        DllCall("QueryPerformanceCounter","Int64*",CurrentTicks)
        Delta := Round((CurrentTicks - PreviousTicks) / TickFrequency,4)
        DllCall("QueryPerformanceCounter","Int64*",PreviousTicks)
        If (Delta > DeltaLimit)
            Delta := DeltaLimit
        Sleep, % Round(TargetFrameDelay - (Delta * 1000))
        If Step(Delta)
            Break
    }
}
MsgBox, Game complete!
ExitApp

MakeGuis:
    ;create game window
    Gui, Color, Black
    Gui, +OwnDialogs +LastFound
    
    GameGUI := {}
    GameGUI.hwnd := WinExist()
    
    GameGUI.Count := {}
    GameGUI.Count.LevelRectangle  := 0
    GameGUI.Count.PlayerRectangle := 0
    GameGUI.Count.GoalRectangle   := 0
    GameGUI.Count.EnemyRectangle  := 0
Return

GuiEscape:
GuiClose:
ExitApp

Initialize()
{
    global Health, Level, LevelIndex, GameGUI
    
    Health := 100

    LevelFile := A_ScriptDir . "\Levels\Level " . LevelIndex . ".txt"
    If !FileExist(LevelFile)
        Return, 1
    FileRead, LevelDefinition, %LevelFile%
    If ErrorLevel
        Return, 1
    Level := ParseLevel(LevelDefinition)

    Gui, +LastFound
    hWindow := WinExist()
    PreventRedraw(hWindow)

    For Name, Count In GameGUI.Count
    {
        Loop, %Count%
            GuiControl, Hide, %Name%%A_Index%
    }

    ;create level
    For Index, Rectangle In Level.Blocks
        PutProgress(Rectangle.X, Rectangle.Y, Rectangle.W, Rectangle.H, "LevelRectangle", Index, "BackgroundRed")

    ;create player
    PutProgress(Level.Player.X, Level.Player.Y, Level.Player.W, Level.Player.H, "PlayerRectangle", "", "-Smooth Vertical")

    ;create goal
    PutProgress(Level.Goal.X, Level.Goal.Y, Level.Goal.W, Level.Goal.H, "GoalRectangle", "", "BackgroundWhite")

    ;create enemies
    For Index, Rectangle In Level.Enemies
        PutProgress(Rectangle.X, Rectangle.Y, Rectangle.W, Rectangle.H, "EnemyRectangle", Index, "BackgroundBlue")

    AllowRedraw(hWindow)
    WinSet, Redraw

    Gui, Show, AutoSize, ProgressPlatformer
}

PutProgress(X,Y,W,H,Name,Index,Options)
{
    global
    local hWnd
    If (GameGUI.Count[Name] < Index || GameGUI.Count[Name] == 0)
    {
        GameGUI.Count[Name] ++
        Gui, Add, Progress, x%X% y%Y% w%W% h%H% v%Name%%Index% %Options% hwndhWnd, 0
        Control, ExStyle, -0x20000,, ahk_id %hWnd% ;remove WS_EX_STATICEDGE extended style
    }
    Else
    {
        GuiControl, Show, %Name%%Index%
        GuiControl, Move, %Name%%Index%, x%X% y%Y% w%W% h%H%
    }
}

PreventRedraw(hWnd)
{
 DetectHidden := A_DetectHiddenWindows
 DetectHiddenWindows, On
 SendMessage, 0xB, 0, 0,, ahk_id %hWnd% ;WM_SETREDRAW
 DetectHiddenWindows, %DetectHidden%
}

AllowRedraw(hWnd)
{
 DetectHidden := A_DetectHiddenWindows
 DetectHiddenWindows, On
 SendMessage, 0xB, 1, 0,, ahk_id %hWnd% ;WM_SETREDRAW
 DetectHiddenWindows, %DetectHidden%
}

Step(Delta)
{
    If GetKeyState("Tab","P") ;slow motion
        Delta *= 0.3
    If Input()
        Return, 1
    If Physics(Delta)
        Return, 2
    If Logic(Delta)
        Return, 3
    If Update()
        Return, 4
    Return, 0
}

Input()
{
    global Left, Right, Jump, Duck
    Left := GetKeyState("Left","P")
    Right := GetKeyState("Right","P")
    Jump := GetKeyState("Up","P")
    Duck := GetKeyState("Down","P")
    Return, 0
}

Logic(Delta)
{
    global GameGUI, LevelIndex, Left, Right, Jump, Duck, Level, Health, Gravity, EnemyX, EnemyY
    MoveSpeed := 800
    JumpSpeed := 200
    JumpInterval := 250

    Padding := 100
    WinGetPos,,, Width, Height, % "ahk_id" . GameGUI.hwnd
    If (Level.Player.X < -Padding || Level.Player.X > (Width + Padding) || Level.Player.Y > (Height + Padding)) ;out of bounds
        Return, 1
    If (Health <= 0) ;out of health
        Return, 2
    If Inside(Level.Player,Level.Goal) ;reached goal
    {
        Score := Round(Health)
        MsgBox, You win!`n`nYour score was %Score%.
        LevelIndex++ ;move to the next level
        Return, 3
    }

    If Left
        Level.Player.SpeedX -= MoveSpeed * Delta
    If Right
        Level.Player.SpeedX += MoveSpeed * Delta

    If (Level.Player.IntersectX && (Left || Right))
    {
        Level.Player.SpeedX *= 0.01
        Level.Player.SpeedY -= Gravity * Delta
        If Jump
            Level.Player.SpeedY += MoveSpeed * Delta
    }
    Else If (Jump && Level.Player.LastContact < JumpInterval)
        Level.Player.SpeedY += JumpSpeed - (Gravity * Delta), Level.Player.LastContact := JumpInterval
    Level.Player.LastContact += Delta

    Level.Player.H := Duck ? 30 : 40

    If (EnemyX || EnemyY > 0)
        Health -= 200 * Delta
    Else If EnemyY
    {
        EnemyY := Abs(EnemyY)
        ObjRemove(Level.Enemies,EnemyY,"")
        GuiControl, Hide, EnemyRectangle%EnemyY%
        Health += 50
    }

    EnemyLogic(Delta)
    Return, 0
}

EnemyLogic(Delta)
{
    global Gravity, Level
    MoveSpeed := 600, JumpSpeed := 150, JumpInterval := 200
    For Index, Rectangle In Level.Enemies
    {
        If ((Level.Player.Y - Rectangle.Y) < JumpSpeed && Abs(Level.Player.X - Rectangle.X) < (MoveSpeed / 2))
        {
            If (Rectangle.Y >= Level.Player.Y)
            {
                If Rectangle.IntersectX
                    Rectangle.SpeedY += (MoveSpeed - Gravity) * Delta
                Else If (Rectangle.LastContact < JumpInterval)
                    Rectangle.SpeedY += JumpSpeed - (Gravity * Delta), Rectangle.LastContact := JumpInterval
            }
            If (Rectangle.X > Level.Player.X)
                Rectangle.SpeedX -= MoveSpeed * Delta
            Else
                Rectangle.SpeedX += MoveSpeed * Delta
        }
        Rectangle.LastContact += Delta
    }
}

Physics(Delta)
{
    global Gravity, Friction, Restitution, Level, EnemyX, EnemyY
    ;process player
    Level.Player.SpeedY += Gravity * Delta ;process gravity
    Level.Player.X += Level.Player.SpeedX * Delta
    Level.Player.Y -= Level.Player.SpeedY * Delta ;process momentum
    Level.Player.IntersectX := 0, Level.Player.IntersectY := 0
    EntityPhysics(Delta,Level.Player,Level.Blocks) ;process collision with level

    EnemyX := 0, EnemyY := 0
    For Index, Rectangle In Level.Enemies
    {
        ;process enemy
        Rectangle.SpeedY += Gravity * Delta ;process gravity
        Rectangle.X += Rectangle.SpeedX * Delta, Rectangle.Y -= Rectangle.SpeedY * Delta ;process momentum
        Rectangle.IntersectX := 0, Rectangle.IntersectY := 0
        EntityPhysics(Delta,Rectangle,Level.Blocks) ;process collision with level
        Temp1 := ObjClone(Level.Enemies), ObjRemove(Temp1,Index,"") ;create an array of enemies excluding the current one
        EntityPhysics(Delta,Rectangle,Temp1) ;process collision with other enemies

        If !Collide(Rectangle,Level.Player,IntersectX,IntersectY) ;player did not collide with the rectangle
            Continue
        If (Abs(IntersectX) > Abs(IntersectY)) ;collision along top or bottom side
        {
            EnemyY := (IntersectY < 0) ? -Index : Index
            Rectangle.Y -= IntersectY ;move the player out of the intersection area
            Level.Player.Y += IntersectY ;move the player out of the intersection area

            Temp1 := ((Rectangle.SpeedX + Level.Player.SpeedX) / 2) * Restitution
            Rectangle.SpeedY := Temp1 ;reflect the speed and apply damping
            Level.Player.SpeedY := -Temp1 ;reflect the speed and apply damping
        }
        Else ;collision along left or right side
        {
            EnemyX := Index
            Rectangle.X -= IntersectX ;move the player out of the intersection area
            Level.Player.X += IntersectX ;move the player out of the intersection area

            Temp1 := ((Rectangle.SpeedX + Level.Player.SpeedX) / 2) * Restitution
            Rectangle.SpeedX := Temp1 ;reflect the speed and apply damping
            Level.Player.SpeedX := -Temp1 ;reflect the speed and apply damping
        }
        If EnemyY
            Rectangle.SpeedX *= (Friction * Abs(IntersectX)) ** Delta ;apply friction
        If EnemyX
            Rectangle.SpeedY *= (Friction * Abs(IntersectY)) ** Delta ;apply friction
    }
    Return, 0
}

EntityPhysics(Delta,Entity,Rectangles)
{
    global Gravity, Friction, Restitution
    CollisionX := 0, CollisionY := 0, TotalIntersectX := 0, TotalIntersectY := 0
    For Index, Rectangle In Rectangles
    {
        If !Collide(Entity,Rectangle,IntersectX,IntersectY) ;entity did not collide with the rectangle
            Continue
        If (Abs(IntersectX) >= Abs(IntersectY)) ;collision along top or bottom side
        {
            CollisionY := 1
            Entity.Y -= IntersectY ;move the entity out of the intersection area
            Entity.SpeedY *= -Restitution ;reflect the speed and apply damping
            TotalIntersectY += Abs(IntersectY)
        }
        Else ;collision along left or right side
        {
            CollisionX := 1
            Entity.X -= IntersectX ;move the entity out of the intersection area
            Entity.SpeedX *= -Restitution ;reflect the speed and apply damping
            TotalIntersectX += Abs(IntersectX)
        }
    }
    If CollisionY
    {
        Entity.LastContact := 0
        Entity.IntersectY := TotalIntersectY
        Entity.SpeedX *= (Friction * TotalIntersectY) ** Delta ;apply friction
    }
    If CollisionX
    {
        Entity.IntersectX := TotalIntersectX
        Entity.SpeedY *= (Friction * TotalIntersectX) ** Delta ;apply friction
    }
}

Update()
{
    global Level, Health
    ;update level
    For Index, Rectangle In Level.Blocks
        GuiControl, Move, LevelRectangle%Index%, % "x" . Round(Rectangle.X) . " y" . Round(Rectangle.Y) . " w" . Round(Rectangle.W) . " h" . Round(Rectangle.H)

    ;update player
    GuiControl,, PlayerRectangle, %Health%
    GuiControl, Move, PlayerRectangle, % "x" . Round(Level.Player.X) . " y" . Round(Level.Player.Y) . " w" . Round(Level.Player.W) . " h" . Round(Level.Player.H)

    ;update enemies
    For Index, Rectangle In Level.Enemies
        GuiControl, Move, EnemyRectangle%Index%, % "x" . Round(Rectangle.X) . " y" . Round(Rectangle.Y) . " w" . Round(Rectangle.W) . " h" . Round(Rectangle.H)
    Return, 0
}

ParseLevel(LevelDefinition)
{
    LevelDefinition := RegExReplace(LevelDefinition,"S)#[^\r\n]*")

    Level := Object()

    Level.Blocks := []
    If RegExMatch(LevelDefinition,"iS)Blocks\s*:\s*\K(?:\d+\s*(?:,\s*\d+\s*){3})*",Property)
    {
        StringReplace, Property, Property, `r,, All
        StringReplace, Property, Property, %A_Space%,, All
        StringReplace, Property, Property, %A_Tab%,, All
        While, InStr(Property,"`n`n")
            StringReplace, Property, Property, `n`n, `n, All
        Property := Trim(Property,"`n")
        Loop, Parse, Property, `n
        {
            StringSplit, Entry, A_LoopField, `,, %A_Space%`t
            Level.Blocks.Insert(new _Rectangle(Entry1,Entry2,Entry3,Entry4))
        }
    }

    If RegExMatch(LevelDefinition,"iS)Player\s*:\s*\K(?:\d+\s*(?:,\s*\d+\s*){3,5})*",Property)
    {
        Entry5 := 0, Entry6 := 0
        StringSplit, Entry, Property, `,, %A_Space%`t`r`n
        Level.Player := new _Entity(Entry1,Entry2,Entry3,Entry4,Entry5,Entry6)
    }

    If RegExMatch(LevelDefinition,"iS)Goal\s*:\s*\K(?:\d+\s*(?:,\s*\d+\s*){3})*",Property)
    {
        StringSplit, Entry, Property, `,, %A_Space%`t`r`n
        Level.Goal := new _Rectangle(Entry1,Entry2,Entry3,Entry4)
    }
    
    Level.Enemies := []
    If RegExMatch(LevelDefinition,"iS)Enemies\s*:\s*\K(?:\d+\s*(?:,\s*\d+\s*){3,5})*",Property)
    {
        StringReplace, Property, Property, `r,, All
        StringReplace, Property, Property, %A_Space%,, All
        StringReplace, Property, Property, %A_Tab%,, All
        While, InStr(Property,"`n`n")
            StringReplace, Property, Property, `n`n, `n, All
        Property := Trim(Property,"`n")
        Loop, Parse, Property, `n, `r `t
        {
            Entry5 := 0, Entry6 := 0
            StringSplit, Entry, A_LoopField, `,, %A_Space%`t
            Level.Enemies.insert(new _Entity(Entry1,Entry2,Entry3,Entry4,Entry5,Entry6))
        }
    }
    Return, Level
}

class _Rectangle {
    __new(X,Y,W,H)
    {
        this.X := X
        this.Y := Y
        this.W := W
        this.H := H
        this.fixed := true
    }
    
    Center()
    {
        Return, {X: this.X + (this.W / 2),Y: this.Y + (this.H / 2)}
    }
    
    ; Distance between the *centers* of two blocks
    CenterDistance(Rectangle)
    {
        a := this.Center()
        b := Rectangle.Center()
        Return, Sqrt((Abs(a.X - b.X) ** 2) + (Abs(a.Y - b.Y) ** 2))
    }
    
    ; calculates the closest distance between two blocks (*not* the centers)
    Distance(Rectangle)
    {
        X := this.IntersectsX(Rectangle) ? 0 : min(Abs(this.X - (Rectangle.X + Rectangle.W)),Abs(Rectangle.X - (this.X + this.W)))
        Y := this.IntersectsY(Rectangle) ? 0 : min(Abs(this.Y - (Rectangle.Y + Rectangle.H)),Abs(Rectangle.Y - (this.Y + this.H)))
        Return, Sqrt((X ** 2) + (Y ** 2))
    }
    
    ; Returns true if this is completely inside Rectangle
    Inside(Rectangle)
    {
        Return, (this.X >= Rectangle.X) && (this.Y >= Rectangle.Y) && (this.X + this.W <= Rectangle.X + Rectangle.W) && (this.Y + this.H <= Rectangle.Y + Rectangle.H)
    }
    
    ; Returns true if this intersects Rectangle at all
    Intersects(Rectangle)
    {
        Return, this.IntersectsX(Rectangle) && this.IntersectsY(Rectangle)
    }
    
    IntersectsX(Rectangle)
    {
        ; this could be optimized
        Return, Between(this.X,Rectangle.X,Rectangle.X + Rectangle.W)
                || Between(Rectangle.X, this.X, this.X+this.W)
    }
    
    IntersectsY(Rectangle)
    {
        Return, Between(this.Y,Rectangle.Y,Rectangle.Y + Rectangle.H) || Between(Rectangle.Y,this.Y,this.Y + this.H)
    }
}

class _Entity extends _Rectangle {
    __new(X,Y,W,H,SpeedX = 0,SpeedY = 0) {
        this.X := X
        this.Y := Y
        this.W := W
        this.H := H
        this.mass := W * H ; * density
        this.fixed := false
        this.SpeedX := SpeedX
        this.SpeedY := SpeedY
        this.LastContact := 0
    }
}

Collide(Rectangle1,Rectangle2,ByRef IntersectX = "",ByRef IntersectY = "")
{
    Left1 := Rectangle1.X, Left2 := Rectangle2.X
    Right1 := Left1 + Rectangle1.W, Right2 := Left2 + Rectangle2.W
    Top1 := Rectangle1.Y, Top2 := Rectangle2.Y
    Bottom1 := Top1 + Rectangle1.H, Bottom2 := Top2 + Rectangle2.H

    ;check for collision
    If (Right1 < Left2
       || Right2 < Left1
       || Bottom1 < Top2
       || Bottom2 < Top1)
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

Inside(Rectangle1,Rectangle2)
{
    Return, Rectangle1.X >= Rectangle2.X
            && (Rectangle1.X + Rectangle1.W) <= (Rectangle2.X + Rectangle2.W)
            && Rectangle1.Y >= Rectangle2.Y
            && (Rectangle1.Y + Rectangle1.H) <= (Rectangle2.Y + Rectangle2.H)
}

Between( x, a, b ) {
    Return, (a >= x && x >= b)
}

; min that accepts either an array or args
min( x* ) {
    if (ObjMaxIndex(x) == 1 && IsObject(x[1]))
        x := x[1]
    r := x[1]
    loop % ObjMaxIndex(x)
        if (x[1] < r)
            r := x[1]
    Return, r
}