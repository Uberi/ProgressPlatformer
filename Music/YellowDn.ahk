#NoEnv

/*
Song: Sunshower
Found in: The title screen
Variable name: YellowUp, Notes
Composer: Henry Lu

e-mail Anthony for the sheet music, 'til I decide to put my own address.
*/

Notes := new NotePlayer
Notes.Instrument(9)

Notes.Repeat := 1

Notes.Note(33,1000,32).Delay(4000)
Notes.Note(33,1000,32).Note(36,1000,32).Note(40,1000,32).Delay(1000)
Notes.Note(33,1000,32).Note(36,1000,32).Note(40,1000,32).Delay(1000)

Notes.Note(36,750,18).Delay(1000)
Notes.Note(35,750,18).Delay(1000)
Notes.Note(36,750,18).Delay(1000)

Notes.Note(41,750,22).Delay(166)
Notes.Note(45,750,22).Delay(166)
Notes.Note(47,750,22).Delay(167)

Notes.Start()