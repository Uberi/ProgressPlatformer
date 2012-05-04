#NoEnv

/*
Copyright 2011-2012 Anthony Zhang <azhang9@gmail.com>, Henry Lu <redacted@redacted.com>

This file is part of ProgressPlatformer. Source code is available at <https://github.com/Uberi/ProgressPlatformer>.

ProgressPlatformer is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

/*
Song: Sunshower
Location: Title screen
Composer: Henry Lu
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