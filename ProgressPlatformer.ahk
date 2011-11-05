#NoEnv

TargetFrameRate := 40

Gravity := -981
Friction := 0.01
Restitution := 0.6

LevelIndex := 1

SetBatchLines, -1

TargetFrameRate := 1000 / TargetFrameRate
Loop
{
 If Initialize()
  Break
 PreviousTime := A_TickCount
 Loop
 {
  Temp1 := (A_TickCount - PreviousTime) / 1000
  PreviousTime := A_TickCount
  If Step(Temp1)
   Break
  Sleep, TargetFrameRate - (A_TickCount - PreviousTime)
 }
 Gui, Destroy
}
MsgBox, Game complete!
ExitApp

Initialize()
{
 global
 local LevelDefinition
 Health := 100

 LevelFile := A_ScriptDir . "\Levels\Level " . LevelIndex . ".txt"
 If !FileExist(LevelFile)
  Return, 1
 FileRead, LevelDefinition, %LevelFile%
 If ErrorLevel
  Return, 1
 Level := ParseLevel(LevelDefinition)

 ;create window
 Gui, Color, Black

 ;create level
 For Index, Rectangle In Level.Blocks
  Gui, Add, Progress, % "x" . Rectangle.X . " y" . Rectangle.Y . " w" . Rectangle.W . " h" . Rectangle.H . " vLevelRectangle" . Index . " BackgroundRed", 0

 ;create player
 Gui, Add, Progress, % "x" . Level.Player.X . " y" . Level.Player.Y . " w" . Level.Player.W . " h" . Level.Player.H . " vPlayerRectangle -Smooth Vertical"

 ;create goal
 Gui, Add, Edit, % "x" . Level.Goal.X . " y" . Level.Goal.Y . " w" . Level.Goal.W . " h" . Level.Goal.H . " vGoalRectangle Disabled -VScroll"

 ;create enemies
 For Index, Rectangle In Level.Enemies
  Gui, Add, Progress, % "x" . Rectangle.X . " y" . Rectangle.Y . " w" . Rectangle.W . " h" . Rectangle.H . " vEnemyRectangle" . Index . " BackgroundBlue", 0

 Gui, +OwnDialogs
 Gui, Show, AutoSize, ProgressPlatformer
 Return

 GuiEscape:
 GuiClose:
 ExitApp
}

Step(Delta)
{
 Gui, +LastFound
 If !WinActive() ;pause game if window is not active
  Return, 0
 If GetKeyState("Tab","P") ;slow motion
  Delta /= 2
 If Input()
  Return, 1
 If Physics(Delta)
  Return, 1
 If Logic(Delta)
  Return, 1
 If Update()
  Return, 1
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
 global LevelIndex, Left, Right, Jump, Duck, Level, Health, Gravity, EnemyX, EnemyY
 MoveSpeed := 800
 JumpSpeed := 200
 JumpInterval := 250

 Padding := 100
 Gui, +LastFound
 WinGetPos,,, Width, Height
 If (Level.Player.X < -Padding || Level.Player.X > (Width + Padding) || Level.Player.Y > (Height + Padding)) ;out of bounds
  Return, 1
 If (Health <= 0) ;out of health
  Return, 1
 If Inside(Level.Player,Level.Goal) ;reached goal
 {
  Score := Round(Health)
  MsgBox, You win!`n`nYour score was %Score%.
  LevelIndex ++ ;move to the next level
  Return, 1
 }

 If Left
  Level.Player.SpeedX -= MoveSpeed * Delta
 If Right
  Level.Player.SpeedX += MoveSpeed * Delta

 If (Level.Player.IntersectX && (Left || Right))
 {
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
 Level.Player.X += Level.Player.SpeedX * Delta, Level.Player.Y -= Level.Player.SpeedY * Delta ;process momentum
 EntityPhysics(Delta,Level.Player,Level.Blocks) ;process collision with level

 EnemyX := 0, EnemyY := 0
 For Index, Rectangle In Level.Enemies
 {
  ;process enemy
  Rectangle.SpeedY += Gravity * Delta ;process gravity
  Rectangle.X += Rectangle.SpeedX * Delta, Rectangle.Y -= Rectangle.SpeedY * Delta ;process momentum
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
 Entity.IntersectX := TotalIntersectX, Entity.IntersectY := TotalIntersectY
 If CollisionY
 {
  Entity.LastContact := 0
  Entity.SpeedX *= (Friction * TotalIntersectY) ** Delta ;apply friction
 }
 If CollisionX
 {
  Entity.IntersectY := TotalIntersectY
  Entity.SpeedY *= (Friction * TotalIntersectX) ** Delta ;apply friction
 }
}

Update()
{
 global Level, Health
 ;update level
 For Index, Rectangle In Level.Blocks
  GuiControl, Move, LevelRectangle%Index%, % "x" . Rectangle.X . " y" . Rectangle.Y . " w" . Rectangle.W . " h" . Rectangle.H

 ;update player
 GuiControl,, PlayerRectangle, %Health%
 GuiControl, Move, PlayerRectangle, % "x" . Level.Player.X . " y" . Level.Player.Y . " w" . Level.Player.W . " h" . Level.Player.H

 ;update enemies
 For Index, Rectangle In Level.Enemies
  GuiControl, Move, EnemyRectangle%Index%, % "x" . Rectangle.X . " y" . Rectangle.Y . " w" . Rectangle.W . " h" . Rectangle.H
 Return, 0
}

ParseLevel(LevelDefinition)
{
 Level := Object()

 Level.Blocks := []
 If RegExMatch(LevelDefinition,"iS)Blocks\s*:\s*\K(?:\d+\s*(?:,\s*\d+\s*){3})*",Property)
 {
  Loop, Parse, Property, `n, `r `t
  {
   StringSplit, Entry, A_LoopField, `,, %A_Space%`t
   ObjInsert(Level.Blocks,Block(Entry1,Entry2,Entry3,Entry4))
  }
 }

 If RegExMatch(LevelDefinition,"iS)Player\s*:\s*\K(?:\d+\s*(?:,\s*\d+\s*){3,5})*",Property)
 {
  Entry5 := 0, Entry6 := 0
  StringSplit, Entry, Property, `,, %A_Space%`t
  Level.Player := Entity(Entry1,Entry2,Entry3,Entry4,Entry5,Entry6)
 }

 If RegExMatch(LevelDefinition,"iS)Goal\s*:\s*\K(?:\d+\s*(?:,\s*\d+\s*){3})*",Property)
 {
  StringSplit, Entry, Property, `,, %A_Space%`t
  Level.Goal := Block(Entry1,Entry2,Entry3,Entry4)
 }

 Level.Enemies := []
 If RegExMatch(LevelDefinition,"iS)Enemies\s*:\s*\K(?:\d+\s*(?:,\s*\d+\s*){3,5})*",Property)
 {
  Loop, Parse, Property, `n, `r `t
  {
   Entry5 := 0, Entry6 := 0
   StringSplit, Entry, A_LoopField, `,, %A_Space%`t
   ObjInsert(Level.Enemies,Entity(Entry1,Entry2,Entry3,Entry4,Entry5,Entry6))
  }
 }

 Return, Level
}

Entity(X,Y,W,H,SpeedX = 0,SpeedY = 0)
{
 Return, Object("X",X,"Y",Y,"W",W,"H",H,"SpeedX",SpeedX,"SpeedY",SpeedY,"LastContact",0,"IntersectX",0,"IntersectY",0)
}

Block(X,Y,W,H)
{
 Return, Object("X",X,"Y",Y,"W",W,"H",H)
}

Collide(Rectangle1,Rectangle2,ByRef IntersectX = "",ByRef IntersectY = "")
{
 Left1 := Rectangle1.X, Left2 := Rectangle2.X, Right1 := Left1 + Rectangle1.W, Right2 := Left2 + Rectangle2.W
 Top1 := Rectangle1.Y, Top2 := Rectangle2.Y, Bottom1 := Top1 + Rectangle1.H, Bottom2 := Top2 + Rectangle2.H

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

Inside(Rectangle1,Rectangle2)
{
 Return, Rectangle1.X >= Rectangle2.X && (Rectangle1.X + Rectangle1.W) <= (Rectangle2.X + Rectangle2.W) && Rectangle1.Y >= Rectangle2.Y && (Rectangle1.Y + Rectangle1.H) <= (Rectangle2.Y + Rectangle2.H)
}