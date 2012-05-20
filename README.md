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

Layers at higher indices draw above layers at lower indices. Layers have the following usable properties: X, Y, W, H, and Visible, which affect the position along the X axis, the position along the Y axis, the width, the height, and the visibility of the layer, respectively. All coordinates follow the same coordinate system: orgin at the top left corner, and 10 units in width and height.

ProgressEngine works on the concept of entities - objects that implement stepping, drawing, and other functionality. Built-in entities can be found in the ProgressEntities class. A more detailed description can be found in the "Built-in Entities" section. We extend these entities to create specialized entities with custom behavior or appearances.

We'll usually want a background:

    class Background extends ProgressEntities.Rectangle
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

    class Background extends ProgressEntities.Rectangle
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

NotePlayer functions are documented in the "NotePlayer Properties" section. The noteplayer is asynchronous; that means that when you call any of the above methods, it stores the action and _returns immediately_. Then, when you play the noteplayer, it occasionally does its own thing in the background, without disrupting the rest of the script.

Time for some music! The following is taken directly from ProgressPlatformer:

    Notes.Instrument(0)

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

    Notes.Start()

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

    class Background extends ProgressEntities.Rectangle
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

Objects
-------

### Layer

Defined in ProgressEngine.Layer, the Layer object contains entities and various properties affecting them.

| Property    | Purpose                          | Modifiable |
|:------------|:---------------------------------|:-----------|
| X           | Position along X-axis (units)    | Yes        |
| Y           | Position along Y-axis (units)    | Yes        |
| W           | Width (units)                    | Yes        |
| H           | Height (units)                   | Yes        |
| Visible     | Layer visibility (True or False) | Yes        |
| Entities    | Array of entities (array)        | Yes        |

### Rectangle

An object designed to describe a rectangular area.

| Property    | Purpose                          | Modifiable |
|:------------|:---------------------------------|:-----------|
| X           | Position along X-axis (units)    | Yes        |
| Y           | Position along Y-axis (units)    | Yes        |
| W           | Width (units)                    | Yes        |
| H           | Height (units)                   | Yes        |

### Viewport

An object designed to describe a viewport, which is the rectangle in which an entity resides.

| Property    | Purpose                                | Modifiable |
|:------------|:---------------------------------------|:-----------|
| X           | Position along X-axis (units)          | No         |
| Y           | Position along Y-axis (units)          | No         |
| W           | Width (units)                          | No         |
| H           | Height (units)                         | No         |
| ScreenX     | Position along X-axis (pixels)         | No         |
| ScreenY     | Position along Y-axis (pixels)         | No         |
| ScreenW     | Width (pixels)                         | No         |
| ScreenH     | Height (pixels)                        | No         |

Entity Basis
------------

All entities possess certain properties by default:

| Property    | Purpose                                | Modifiable |
|:------------|:---------------------------------------|:-----------|
| X           | Position along X-axis (units)          | Yes        |
| Y           | Position along Y-axis (units)          | Yes        |
| W           | Width (units)                          | Yes        |
| H           | Height (units)                         | Yes        |
| ScreenX     | Position along X-axis (pixels)         | No         |
| ScreenY     | Position along Y-axis (pixels)         | No         |
| ScreenW     | Width (pixels)                         | No         |
| ScreenH     | Height (pixels)                        | No         |
| Visible     | Entity visibility (True or False)      | Yes        |

There are also a number of functions available to each entity. These functions are implemented in the ProgressEntities.Basis class, from which all entities should inherit. All entity functions are overridable.

### ProgressEntities.Basis.Step(Delta,Layer,Viewport)

Defines entity behavior, such as movement or logic.

| Parameter | Purpose                                          |
|:----------|:-------------------------------------------------|
| Delta     | Time since last invocation of callback (seconds) |
| Layer     | Layer the entity resides in (layer object)       |
| Viewport  | Current viewport (viewport object)               |

Returns a truthy value to stop the game engine, otherwise a falsy value.

### ProgressEntities.Basis.Draw(Delta,Layer,Viewport)

Defines entity appearance, such as drawing or animation.

| Parameter | Purpose                                          |
|:----------|:-------------------------------------------------|
| Delta     | Time since last invocation of callback (seconds) |
| Layer     | Layer the entity resides in (layer object)       |
| Viewport  | Current viewport (viewport object)               |

Return value is ignored.

### ProgressEntities.Basis.Intersect(Rectangle,ByRef IntersectX = "",ByRef IntersectY = "")

Used to determine whether the entity intersects a given rectangle object.

| Parameter  | Purpose                                      |
|:-----------|:---------------------------------------------|
| Rectangle  | Rectangle to test against (rectangle object) |
| IntersectX | Output intersection along X-axis (units)     |
| IntersectY | Output intersection along Y-axis (units)     |

Returns True to indicate intersection, False otherwise.

### ProgressEntities.Basis.Inside(Rectangle)

Used to determine whether the entity is completely inside a given rectangle object.

| Parameter  | Purpose                                      |
|:-----------|:---------------------------------------------|
| Rectangle  | Rectangle to test against (rectangle object) |

Returns True to indicate that the entity is completely inside the rectangle, False otherwise.

Built-in Entities
-----------------

### ProgressEntities.Rectangle

A drawtype that appears as a filled, borderless rectangle.

| Property    | Purpose                                | Modifiable |
|:------------|:---------------------------------------|:-----------|
| Color       | Fill color (RGB hex)                   | Yes        |

### ProgressEntities.Static
A drawtype that appears as a filled, borderless rectangle and is considered in physics simulations; entities that are dynamic are able to collide with it.

| Property    | Purpose                                | Modifiable |
|:------------|:---------------------------------------|:-----------|| Color       | Fill color (RGB hex)                   | Yes        |
| Density     | Material density (mass/volume)         | Yes        |
| Restitution | Material bounciness (rebound/incoming) | Yes        |

### ProgressEntities.Dynamic

A drawtype that appears as a filled, borderless rectangle and is active in physics simulations; it moves and collides according to forces acting upon it.
Similar to ProgressEntities.Dynamic, this entity type is still a rectangle and is still affected by physics, except that it can move, collide, and be affected by forces. In addition to all the usable properties of ProgressEntities.Static, two other properties are available: SpeedX and SpeedY, which affect the entity's speed along the X axis and speed along the Y axis, respectively.

| Property    | Purpose                                | Modifiable |
|:------------|:---------------------------------------|:-----------|
| Color       | Fill color (RGB hex)                   | Yes        |
| Density     | Material density (mass/volume)         | Yes        |
| Restitution | Material bounciness (rebound/incoming) | Yes        |
| SpeedX      | Speed along X-axis (units/second)      | Yes        |
| SpeedY      | Speed along Y-axis (units/second)      | Yes        |

### ProgressEntities.Text

A drawtype that appears as text with a transparent background.

| Property  | Purpose                                       | Modifiable |
|:----------|:----------------------------------------------|:-----------|
| W         | Width (units)                                 | No         |
| H         | Height (units)                                | No         |
| Align     | Text alignment ("Left", "Center", or "Right") | Yes        |
| Size      | Font size (units)                             | Yes        |
| Weight    | Font weight (0 to 1000)                       | Yes        |
| Italic    | Font italic flag (True or False)              | Yes        |
| Underline | Font underline flag (True or False)           | Yes        |
| Strikeout | Font strikeout flag (True or False)           | Yes        |
| Typeface  | Text typeface (typeface name)                 | Yes        |
| Text      | Text to display (string)                      | Yes        |

NotePlayer Properties
---------------------

### NotePlayer.Playing

Flag indicating whether the NotePlayer instance is currently playing stored notes.

Useful for determining when the note sequence has ended.

### NotePlayer.Note(Index,Length,DownVelocity = 60,UpVelocity = 60)

Adds a single note, determined by MIDI note number _Index_, to the NotePlayer instance, which plays for _Length_ milliseconds, is pressed with a velocity of _DownVelocity_, and is released with a velocity of _UpVelocity_, where velocities are numbers between 0 and 100.

Useful for creating sequences of notes that are to be played together.

### NotePlayer.Instrument(Sound)

Sets the instrument of the noteplayer to _Sound_, which is also known as a "program" or a "patch" in MIDI terminology.

Useful for playing multiple notes using different instruments.

### NotePlayer.Delay(Length)

Delays playing of the next note for _Length_ milliseconds while the NotePlayer instance is playing.

Useful for adding a pause or delaying the playing of following notes.

### NotePlayer.Play(Index,Length,Sound,DownVelocity = 60,UpVelocity = 60)

Immediately begins playing a single note, determined by MIDI note number _Index_, which plays for _Length_ milliseconds, with the instrument _Sound_ (also known as a "program" or "patch" in MIDI terminology), is pressed with a velocity of _DownVelocity_, and is released with a velocity of _UpVelocity_, where velocities are numbers between 0 and 100.

Useful for sound effects and other notes that must be played at specific times.

### NotePlayer.Start()

Begins playing the notes and delays in the order they were added.

Useful for playing the notes stored in the NotePlayer instance.

### NotePlayer.Stop()

Stops a currently playing noteplayer, cutting off notes if any are active at the time it is called.

Useful for abruptly ending a sequence of notes.

### NotePlayer.Reset()

Resets a noteplayer to its initial state; that is, it stops the noteplayer and deletes the notes in it.

Useful for removing all notes stored in a NotePlayer instrument in order to add another sequence of notes to it.