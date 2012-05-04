#NoEnv

/*
Song: Sunshower
Found in: The title screen
Variable name: Notes, YellowDn
Composer: Henry Lu

e-mail Anthony for the sheet music, 'til I decide to put my own address.
For now, the engine is screwy, and won't allow more then one NotePlayer to be used at the same time.
*/

Notes := new NotePlayer
Notes.Instrument(9)

Notes.Repeat := 1

Notes.Note(48,500,40).Note(36,500,40).Delay(500)
Notes.Note(47,500,40).Note(35,500,40).Delay(500)
Notes.Note(48,500,40).Note(36,500,40).Delay(500)
Notes.Note(45,500,40).Note(41,500,40).Delay(500)

Notes.Note(48,500,40).Note(36,500,40).Delay(500)
Notes.Note(47,500,40).Note(35,500,40).Delay(500)
Notes.Note(48,500,40).Note(36,500,40).Delay(500)
Notes.Note(45,500,40).Note(41,500,40).Delay(500)

Notes.Note(48,500,40).Note(36,500,40).Note(33,1000,32).Note(36,1000,32).Note(40,1000,32).Delay(500)
Notes.Note(47,500,40).Note(35,500,40).Delay(500)
Notes.Note(48,500,40).Note(36,500,40).Delay(500)
Notes.Note(45,500,40).Note(41,500,40).Delay(500)

Notes.Note(48,500,40).Note(36,500,40).Note(33,1000,32).Note(36,1000,32).Note(40,1000,32).Delay(500)
Notes.Note(47,500,40).Note(35,500,40).Delay(500)
Notes.Note(48,500,40).Note(36,500,40).Delay(500)
Notes.Note(45,500,40).Note(36,500,40).Delay(500)

Notes.Note(36,750,18).Delay(500)
Notes.Note(48,250,22).Note(36,250,22).Delay(250)
Notes.Note(45,750,22).Note(33,750,22).Delay(250)
Notes.Note(35,750,18).Delay(1000)

Notes.Note(48,250,22).Note(36,250,22).Note(36,750,18).Delay(250)
Notes.Note(45,750,22).Note(33,750,22).Delay(750)
Notes.Note(41,750,22).Delay(166)
Notes.Note(45,750,22).Delay(166)
Notes.Note(47,750,22).Delay(167)

Notes.Start()