NotePlayer
==========
The NotePlayer API is a library that allows the creation and playing of note sequences - a number of notes played sequentially.

This library can be used to play music, sound effects, and more. As a part of ProgressEngine, it emphasizes a simple interface, with the complexity behind MIDI output taken away from the user.

MIDI Number Converter
---------------------
The "MIDI Number Converter" utility provides a simpler way to input music, without writing code. It can be found in the "MIDI" subfolder of the main ProgressEngine distribution. See the utility's README for usage information.

Examples
--------

### Play a single note immediately

    n := new NotePlayer
    n.Play(48)

Reference
---------

### NotePlayer.Offset

The current offset from the beginning of the note sequence, in milliseconds. This is increased by NotePlayer.Delay and used as the starting time for NotePlayer.Instrument and NotePlayer.Note.

This value can be modified at will, and doing so is a good way to play two different sequences at the same time. Saving the offset, adding a note sequence, restoring the offset, and adding another note sequence results in both playing at the same time.

### NotePlayer.Playing

Flag indicating whether the NotePlayer instance is currently playing stored notes.

Useful for determining when the note sequence has ended.

### NotePlayer.Note(Index,Length,DownVelocity = 60,UpVelocity = 60)

Adds a single note, determined by MIDI note number _Index_ (integer between 0 and 127 inclusive), to the NotePlayer instance, which plays for _Length_ milliseconds (positive integer or decimal), is pressed with a velocity of _DownVelocity_ (integer or decimal between 0 and 100 inclusive), and is released with a velocity of _UpVelocity_ (integer or decimal between 0 and 100 inclusive).

Useful for creating sequences of notes that are to be played together.

### NotePlayer.Instrument(Sound)

Sets the instrument of the noteplayer to _Sound_ (integer between 0 and 127 inclusive), which is also known as a "program" or a "patch" in MIDI terminology.

Useful for playing multiple notes using different instruments.

### NotePlayer.Delay(Length)

Delays playing of the next note for _Length_ milliseconds (integer or decimal) while the NotePlayer instance is playing.

Useful for adding a pause or delaying the playing of following notes. Additionally, using negative delays moves the offset backwards, which allows a note sequence to be played simultaneously with another.

### NotePlayer.Play(Index,Length,Sound,DownVelocity = 60,UpVelocity = 60)

Immediately begins playing a single note, determined by MIDI note number _Index_ (integer between 0 and 127 inclusive), which plays for _Length_ milliseconds (positive integer or decimal), with the instrument _Sound_ (also known as a "program" or "patch" in MIDI terminology), is pressed with a velocity of _DownVelocity_ (integer or decimal between 0 and 100 inclusive), and is released with a velocity of _UpVelocity_ (integer or decimal between 0 and 100 inclusive).

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