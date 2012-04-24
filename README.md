ProgressPlatformer
==================
ProgressPlatformer is a game. More specifically, a platformer game. Try it out!

Screenshot
----------

![ProgressPlatformer Screenshot](Achromatic.png "Title screen.")

Usage
-----
If not compiled, this program requires [AutoHotkey](http://www.autohotkey.com/), specifically a version above 1.1.05.00, although the latest version is recommended.

To start, simply open ProgressPlatformer.exe or ProgressPlatformer.ahk, and enjoy the game!

ProgressEngine
==============
Behind the jumping, scrolling, dynamic world of [Achromatic/ProgressPlatformer](http://www.autohotkey.com/forum/topic69424.html) lies ProgressEngine, a simple and elegant game engine. Designed for ease of use, this extensible library takes care of the boilerplate and the low-level stuff so you don't have to.

Features
--------

* Basic physics engine built in.
* Unlimited, movable, scalable layers.
* Consistent coordinate system - viewports can be freely resized.
* MIDI music support with an asynchronous API and conversion tools.
* Brushes, contexts, bitmaps, and other resources are managed automatically.
* Easy customisation of existing drawtypes and the ability to create your own drawtypes.
* Container entities for grouping several entities together.

Usage
-----

Including the main engine is easy:

    #Include ProgressEngine.ahk

Initializing the engine is simple as well; we simply pass the handle to the window to use as the viewport:

    Gui, +Resize +LastFound
    Engine := new ProgressEngine(WinExist())

    Gui, Show, w800 h600, My first game!

Now we create two layers to store our entities in, to keep things organized:

    Engine.Layers[1] := new ProgressEngine.Layer
    Engine.Layers[2] := new ProgressEngine.Layer

Layers at higher indices draw above layers at lower indices. Layers have the following usable properties: X, Y, W, H, and Visible, which affect the position along the X axis, the position along the Y axis, the width, the height, and the visibility of the layer, respectively. All coordinates follow the same coordinate system: orgin at the top left corner, and defaulting to 10 units in width and height.

ProgressEngine works on the concept of entities - objects that implement stepping, drawing, and other functionality. Built in entities can be found in the ProgressEntities class:

* ProgressEntities.Default: a simple rectangle drawtype, that draws a single rectangle. Possesses the following usable properties: X, Y, W, H, Visible, and Color, which affects the position along the X axis, the position along the Y axis, the width, the height, the visibility, and the color of the entity, respectively.
* ProgressEntities.Static: similar to ProgressEntities.Default, this entity type is also a rectangle, except it affects physics simulations. That is, it can influence dynamic objects and collide with other entities. It possesses all the same usable properties as ProgressEntities.Default, along with Density and Restitution, which affect the object's density and how bouncy it is, respectively.
* ProgressEntities.Dynamic: Similar to ProgressEntities.Dynamic, this entity type is still a rectangle and is still affected by physics, except that it can move, collide, and be affected by forces. In addition to all the usable properties of ProgressEntities.Static, two other properties are available: SpeedX and SpeedY, which affect the entity's speed along the X axis and speed along the Y axis, respectively.
* ProgressEntities.Text: A generic text drawtype, that can draw a string of text. Possesses the following usable properties: Align, Size, Weight, Italic, Underline, Strikeout, Typeface, and Text, which affect the text alignment, size, weight, whether it is italic, underlined, or struck out, the typeface, and the text it displays, respectively.

Now that we have the basic built-in types, we can start to create specialized entities.

We'll usually want a background:

    class Background extends ProgressEntities.Default
    {
        __New()
        {
            base.__New()
            this.X := 0 ;start at left
            this.Y := 0 ;start at top
            this.W := 10 ;cover the entire width of the viewport
            this.H := 10 ;cover the entire height of the viewport
            this.Color := 0xCCCCCC ;light grey color
        }
    }

And now let's define a text in a big title style:

    class Title extends ProgressEntities.Text
    {
        __New(X,Y,Text)
        {
            base.__New()
            this.X := X
            this.Y := Y
            this.Align := "Center" ;center aligned
            this.Size := 14 ;large font size
            this.Color := 0x444444 ;dark grey color
            this.Weight := 100 ;light weight
            this.Typeface := "Arial" ;typeface is Arial
            this.Text := Text
        }
    }

But having these classes defined isn't enough. We also need to add them to a layer so they are accessible to the engine. We'll add the background to layer 1:

    Engine.Layers[1].Entities.Insert(new Background)

And the title to layer 2:

    Engine.Layers[2].Entities.Insert(new Title(5,5,"Hello, world!"))

Now let's start the engine!

    Engine.Start()

You will get something like this:

![ProgressEngine Demo](ProgressEngine.png "Test game.")

Here's the code in its entirety:

    #Include ProgressEngine.ahk

    Gui, +Resize +LastFound
    Engine := new ProgressEngine(WinExist())

    Gui, Show, w800 h600, My first game!

    Engine.Layers[1] := new ProgressEngine.Layer
    Engine.Layers[2] := new ProgressEngine.Layer

    Engine.Layers[1].Entities.Insert(new Background)
    Engine.Layers[2].Entities.Insert(new Title(5,5,"Hello, world!"))

    Engine.Start()

    GuiClose:
    ExitApp

    class Background extends ProgressEntities.Default
    {
        __New()
        {
            base.__New()
            this.X := 0 ;start at left
            this.Y := 0 ;start at top
            this.W := 10 ;cover the entire width of the viewport
            this.H := 10 ;cover the entire height of the viewport
            this.Color := 0xCCCCCC ;light grey color
        }
    }

    class Title extends ProgressEntities.Text
    {
        __New(X,Y,Text)
        {
            base.__New()
            this.X := X
            this.Y := Y
            this.Align := "Center" ;center aligned
            this.Size := 14 ;large font size
            this.Color := 0x444444 ;dark grey color
            this.Weight := 100 ;light weight
            this.Typeface := "Arial" ;typeface is Arial
            this.Text := Text
        }
    }

Optionally also include the MIDI music API:

    #Include Music.ahk

The music API also requires initialization; we can optionally pass it the MIDI instrument to use:

    Notes := new NotePlayer(9)

Now we'll enable looping, so it plays over and over:

    Notes.Repeat := 1

Let's add some notes. NotePlayer offers the following methods:

* NotePlayer.Note(Index,Length = 500,DownVelocity = 60,UpVelocity = 60): Adds a single note to the current noteplayer, which plays for Length milliseconds, is pressed with a velocity of DownVelocity, and is released with a velocity of UpVelocity. All velocities are numbers between 0 and 100.
* NotePlayer.Delay(Length = 1000): delays playing of the next note for Length milliseconds while the noteplayer is playing.
* NotePlayer.Play(Index,Length = 500,DownVelocity = 60,UpVelocity = 60): works similar to NotePlayer.Note, except the note begins playing immediately rather than after explicitly playing the noteplayer. This is useful for sound effects and other notes that must be played at specific times. It accepts the same parameters as NotePlayer.Note and uses them in the same way.
* NotePlayer.Start(): begins playing the notes and delays in the order they were added, and sets the Playing property to true.
* NotePlayer.Stop(): stops a currently playing noteplayer, cutting off notes if any are active at the time it is called.
* NotePlayer.Reset(): resets a noteplayer to its initial state; that is, it stops the noteplayer and deletes the notes in it so a new tune can be added.

The noteplayer is asynchronous; that means that when you call any of the above methods, it stores the action and _returns immediately_. Then, when you play the noteplayer, it occasionally does its own thing in the background, without disrupting the rest of the script.

Time for some music! The following is taken directly from ProgressPlatformer:

    Notes.Note(40,1000,70).Note(48,1000,70).Delay(1800)
    Notes.Note(41,1000,70).Note(47,1000,70).Delay(1800)
    Notes.Note(40,1000,70).Note(48,1000,70).Delay(2000)
    Notes.Note(40,1000,70).Note(45,1000,70).Delay(1800)

    Notes.Delay(300)

    Notes.Note(41,1000,70).Note(48,1000,70).Delay(1800)
    Notes.Note(41,1000,70).Note(47,1000,70).Delay(1800)
    Notes.Note(41,1000,70).Note(48,1000,70).Delay(2000)
    Notes.Note(41,1000,70).Note(45,1000,70).Delay(1800)

    Notes.Delay(500)

And now we play it:

    Notes.Play()

All together now:

    #Include ProgressEngine.ahk
    #Include Music.ahk

    Notes := new NotePlayer(9)

    Notes.Repeat := 1

    Notes.Note(40,1000,70).Note(48,1000,70).Delay(1800)
    Notes.Note(41,1000,70).Note(47,1000,70).Delay(1800)
    Notes.Note(40,1000,70).Note(48,1000,70).Delay(2000)
    Notes.Note(40,1000,70).Note(45,1000,70).Delay(1800)

    Notes.Delay(300)

    Notes.Note(41,1000,70).Note(48,1000,70).Delay(1800)
    Notes.Note(41,1000,70).Note(47,1000,70).Delay(1800)
    Notes.Note(41,1000,70).Note(48,1000,70).Delay(2000)
    Notes.Note(41,1000,70).Note(45,1000,70).Delay(1800)

    Notes.Delay(500)

    Notes.Start()

    Gui, +Resize +LastFound
    Engine := new ProgressEngine(WinExist())

    Gui, Show, w800 h600, My first game!

    Engine.Layers[1] := new ProgressEngine.Layer
    Engine.Layers[2] := new ProgressEngine.Layer

    Engine.Layers[1].Entities.Insert(new Background)
    Engine.Layers[2].Entities.Insert(new Title(5,5,"Hello, world!"))

    Engine.Start()

    GuiClose:
    ExitApp

    class Background extends ProgressEntities.Default
    {
        __New()
        {
            base.__New()
            this.X := 0 ;start at left
            this.Y := 0 ;start at top
            this.W := 10 ;cover the entire width of the viewport
            this.H := 10 ;cover the entire height of the viewport
            this.Color := 0xCCCCCC ;light grey color
        }
    }

    class Title extends ProgressEntities.Text
    {
        __New(X,Y,Text)
        {
            base.__New()
            this.X := X
            this.Y := Y
            this.Align := "Center" ;center aligned
            this.Size := 14 ;large font size
            this.Color := 0x444444 ;dark grey color
            this.Weight := 100 ;light weight
            this.Typeface := "Arial" ;typeface is Arial
            this.Text := Text
        }
    }

There we have it! ProgressEngine takes care of the rest.