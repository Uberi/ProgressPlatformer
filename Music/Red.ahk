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
Notes.Instrument(0)

Notes.Repeat := 1

Notes.Delay(1000)
Notes.Note(33,3000,55).Note(41,3000,55).Note(48,3000,55).Note(56,3000,55).Delay(3500)
Notes.Note(36,3000,60).Note(48,3000,60).Note(51,3000,60).Note(60,3000,60).Delay(3000)
Notes.Note(30,3500,70).Note(39,3500,70).Note(56,3500,70).Note(60,3500,70).Delay(3500)
Notes.Note(33,4000,45).Note(41,4000,45).Note(49,4000,45).Note(58,4000,45).Delay(4000)

Notes.Start()