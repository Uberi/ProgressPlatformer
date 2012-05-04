#NoEnv

/*
Song: ???
Found in: ???
Variable name: ???
Composer: Henry Lu

e-mail Anthony for the sheet music, 'til I decide to put my own address.
For now, the engine is screwy, and won't allow more then one NotePlayer to be used at the same time.
*/

Notes := new NotePlayer
Notes.Instrument(28)

Notes.Repeat := 1

Loop, 2
{
    Notes.Note(49,250,75).Note(52,250,75).Delay(250)
    Notes.Note(52,250,75).Note(56,250,75).Delay(250)
    Notes.Note(47,250,75).Note(51,250,75).Delay(250)
    Notes.Note(45,250,55).Note(49,250,55).Delay(500)
    Notes.Note(47,250,65).Note(51,250,65).Delay(500)
}

Notes.Note(49,500,70).Note(52,500,70).Delay(500)
Notes.Note(52,125,70).Note(56,125,70).Delay(125)
Notes.Note(56,125,70).Note(59,125,70).Delay(125)
Notes.Note(51,125,70).Note(57,125,70).Delay(125)
Notes.Note(49,125,70).Note(52,125,70).Delay(125)

Notes.Note(52,125,70).Note(56,125,70).Delay(125)
Notes.Note(47,125,70).Note(51,125,70).Delay(125)
Notes.Note(54,125,70).Note(57,125,70).Delay(125)
Notes.Note(49,125,70).Note(52,125,70).Delay(125)
Notes.Note(52,500,55).Note(56,500,55).Delay(500)

Notes.Note(47,250,65).Note(51,250,65).Delay(500)

Notes.Start()