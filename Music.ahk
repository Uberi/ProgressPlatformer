#NoEnv

/*
Copyright 2011 Anthony Zhang <azhang9@gmail.com>

this file is part of ProgressPlatformer. Source code is available at <https://github.com/Uberi/ProgressPlatformer>.

ProgressPlatformer is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

this program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#Persistent

Notes := new NotePlayer(9)

Notes.Repeat := 1

Notes.Note(40,1000,70).Note(48,1000,70).Delay(1800)
Notes.Note(41,1000,70).Note(47,1000,70).Delay(1800)
Notes.Note(40,1000,70).Note(48,1000,70).Delay(1800)
Notes.Note(40,1000,70).Note(45,1000,70).Delay(1800)

Notes.Delay(500)

Notes.Note(41,1000,70).Note(48,1000,70).Delay(1800)
Notes.Note(41,1000,70).Note(47,1000,70).Delay(1800)
Notes.Note(41,1000,70).Note(48,1000,70).Delay(1800)
Notes.Note(41,1000,70).Note(45,1000,70).Delay(1800)

Notes.Delay(500)

Notes.Play()
Return

Loop, 3
{
    Notes.Note(45,2000,70).Note(48,2000,70).Note(42,2000,70).Delay(3000)
    Notes.Note(45,2000,60).Note(48,2000,60).Note(51,2000,60).Delay(3000)
}
ExitApp

Notes := new NotePlayer(28)

Loop, 2
{
    Notes.Note(49,2000,50).Note(52,2000,50).Delay(3200)
    Notes.Note(52,2000,70).Note(56,2000,70).Delay(3200)
    Notes.Note(47,2000,45).Note(51,2000,45).Delay(3000)
    Notes.Note(45,2000,40).Note(49,2000,40).Delay(3400)
}

Notes.Note(49,2000,50).Note(52,2000,50).Delay(3200)
Notes.Note(52,2000,70).Note(56,2000,70).Delay(3200)
Notes.Note(56,2000,45).Note(59,2000,45).Delay(3000)
Notes.Note(51,2000,40).Note(57,2000,40).Delay(3400)

Notes.Note(49,2000,50).Note(52,2000,50).Delay(3200)
Notes.Note(52,2000,70).Note(56,2000,70).Delay(3200)
Notes.Note(47,2000,45).Note(51,2000,45).Delay(3000)
Notes.Note(54,2000,40).Note(57,2000,40).Delay(3400)
ExitApp

Esc::ExitApp

class NotePlayer
{
    __New(Sound = 0)
    {
        this.Device := new MIDIOutputDevice
        this.Device.Sound := Sound
        this.Device.SetVolume(100)
        this.Actions := []
        this.pCallback := 0
        this.Timer := 0
    }

    Note(Index,Length = 500,DownVelocity = 60,UpVelocity = 60)
    {
        Action := Object()
        Action.Index := Index
        Action.Length := Length
        Action.DownVelocity := DownVelocity
        Action.UpVelocity := UpVelocity
        this.Actions.Insert(Action)
        Return, this
    }

    Delay(Length = 1000)
    {
        Action := Object()
        Action.Index := -1
        Action.Length := Length
        this.Actions.Insert(Action)
        Return, this
    }

    Play()
    {
        ;sort the notes into groups by their time offsets
        Positions := [], Offset := 0
        For Index, Action In this.Actions
        {
            If Action.Index = -1 ;delay
                Offset += Action.Length
            Else ;note
            {
                If !ObjHasKey(Positions,Offset)
                    Positions[Offset] := []
                Positions[Offset].Insert(Object("Type","NoteOn","Index",Action.Index,"Velocity",Action.DownVelocity))
                Temp1 := Offset + Action.Length
                If !ObjHasKey(Positions,Temp1)
                    Positions[Temp1] := []
                Positions[Temp1].Insert(Object("Type","NoteOff","Index",Action.Index,"Velocity",Action.UpVelocity))
            }
        }
        If !ObjHasKey(Positions,Offset) ;insert the ending delay
            Positions[Offset] := []

        this.Sequence := [], PreviousOffset := 0
        For Offset, Actions In Positions
        {
            Actions.Insert(1,Offset - PreviousOffset), PreviousOffset := Offset
            this.Sequence.Insert(Actions)
        }

        ;activate the first set of actions if it is present
        If ObjMaxIndex(this.Sequence)
        {
            this.pCallback := RegisterCallback("NotePlayerTimer","F","",&this)
            If !this.pCallback
                throw Exception("Could not register update callback.")
            this.Index := 1
            this.Timer := DllCall("SetTimer","UPtr",0,"UPtr",0,"UInt",this.Sequence[1][1],"UPtr",this.pCallback,"UPtr")
            If !this.Timer
                throw Exception("Could not create update timer.")
        }
        Return, this
    }

    Pause()
    {
        ;wip
    }

    Stop()
    {
        ;wip
    }
}

NotePlayerTimer(hWindow,Message,Event,TickCount)
{
    Critical
    NotePlayer := Object(A_EventInfo)
    If !DllCall("KillTimer","UPtr",0,"UInt",NotePlayer.Timer)
        throw Exception("Could not destroy update timer.")
    For Index, Action In NotePlayer.Sequence[NotePlayer.Index] ;perform the current action set
    {
        If Index != 1
        {
            If (Action.Type = "NoteOn")
                NotePlayer.Device.NoteOn(Action.Index,Action.Velocity)
            Else If (Action.Type = "NoteOff")
                NotePlayer.Device.NoteOff(Action.Index,Action.Velocity)
        }
    }
    If (NotePlayer.Index < ObjMaxIndex(NotePlayer.Sequence)) ;set the next timer if necessary
    {
        NotePlayer.Index ++
        NotePlayer.Timer := DllCall("SetTimer","UPtr",0,"UPtr",0,"UInt",NotePlayer.Sequence[NotePlayer.Index][1],"UPtr",NotePlayer.pCallback,"UPtr")
    }
    Else If NotePlayer.Repeat
    {
        NotePlayer.Index := 1
        NotePlayer.Timer := DllCall("SetTimer","UPtr",0,"UPtr",0,"UInt",NotePlayer.Sequence[1][1],"UPtr",NotePlayer.pCallback,"UPtr")
    }
}

class MIDIOutputDevice
{
    static DeviceCount := 0

    __New(DeviceID = 0)
    {
        If MIDIOutputDevice.DeviceCount = 0
        {
            this.hModule := DllCall("LoadLibrary","Str","winmm")
            If !this.hModule
                throw Exception("Could not load WinMM library.")
        }
        MIDIOutputDevice.DeviceCount ++

        ;open the MIDI output device
        hMIDIOutputDevice := 0
        Status := DllCall("winmm\midiOutOpen","UInt*",hMIDIOutputDevice,"UInt",DeviceID,"UPtr",0,"UPtr",0,"UInt",0) ;CALLBACK_NULL
        If Status != 0 ;MMSYSERR_NOERROR
            throw Exception("Could not open MIDI output device: " . DeviceID . ".")
        this.hMIDIOutputDevice := hMIDIOutputDevice

        this.Channel := 0
        this.Sound := 0
        this.Pitch := 0
    }

    __Get(Key)
    {
        Return, this["_" . Key]
    }

    __Set(Key,Value)
    {
        If (Key = "Channel")
        {
            If Value Not Between 0 And 15
                throw Exception("Invalid channel: " . Value . ".",-1)
        }
        Else If (Key = "Sound")
        {
            If Value Not Between 0 And 127
                throw Exception("Invalid sound: " . Value . ".",-1)
            If DllCall("winmm\midiOutShortMsg","UInt",this.hMIDIOutputDevice,"UInt",0xC0 | this.Channel | (Value << 8)) ;"Program Change" event
                throw Exception("Could not send ""Program Change"" message.")
        }
        Else If (Key = "Pitch")
        {
            If (Value < -100)
                Value := -100
            If (Value > 100)
                Value := 100
            TempValue := Round(((Value + 100) / 200) * 0x4000)
            If DllCall("winmm\midiOutShortMsg","UInt",this.hMIDIOutputDevice,"UInt",0xE0 | this.Channel | ((TempValue & 0x7F) << 8) | (TempValue << 9)) ;"Pitch Bend" event
                throw Exception("Could not send ""Pitch Bend"" message.")
        }
        ObjInsert(this,"_" . Key,Value)
        Return, Value
    }

    __Delete()
    {
        this.Reset()
        If DllCall("winmm\midiOutClose","UInt",this.hMIDIOutputDevice)
            throw Exception("Could not close MIDI output device.")

        MIDIOutputDevice.DeviceCount --
        If (MIDIOutputDevice.DeviceCount = 0)
            DllCall("FreeLibrary","UPtr",this.hModule)
    }

    GetVolume(Channel = "")
    {
        Volume := 0
        If DllCall("winmm\midiOutGetVolume","UInt",this.hMIDIOutputDevice,"UInt*",Volume) ;retrieve the device volume
            throw Exception("Could not retrieve device volume.")
        If (Channel = "" || Channel = "Left")
            Return, ((Volume & 0xFFFF) / 0xFFFF) * 100
        Else If (Channel = "Right")
            Return, ((Volume >> 16) / 0xFFFF) * 100
        Else
            throw Exception("Invalid channel:" . Channel . ".",-1)
    }

    SetVolume(Volume,Channel = "")
    {
        If Volume Not Between 0 And 100
            throw Exception("Invalid volume: " . Volume . ".",-1)
        If (Channel = "")
            Volume := Round((Volume / 100) * 0xFFFF), Volume |= Volume << 16
        Else If (Channel = "Left")
            Volume := Round((Volume / 100) * 0xFFFF)
        Else If (Channel = "Right")
            Volume := Round((Volume / 100) * 0xFFFF) << 16
        Else
            throw Exception("Invalid channel: " . Channel . ".",-1)
        DllCall("winmm\midiOutSetVolume","UInt",this.hMIDIOutputDevice,"UInt",Volume) ;set the device volume
    }

    NoteOn(Note,Velocity)
    {
        If Note Is Not Integer
            throw Exception("Invalid note: " . Note . ".",-1)
        If Velocity Not Between 0 And 100
            throw Exception("Invalid velocity: " . Velocity . ".",-1)
        Velocity := Round((Velocity / 100) * 127)
        If DllCall("winmm\midiOutShortMsg","UInt",this.hMIDIOutputDevice,"UInt",0x90 | this.Channel | (Note << 8) | (Velocity << 16)) ;"Note On" event
            throw Exception("Could not send ""Note On"" message.")
    }

    NoteOff(Note,Velocity)
    {
        If Note Is Not Integer
            throw Exception("Invalid note: " . Note . ".",-1)
        If Velocity Not Between 0 And 100
            throw Exception("Invalid velocity: " . Velocity . ".",-1)
        Velocity := Round((Velocity / 100) * 127)
        If DllCall("winmm\midiOutShortMsg","UInt",this.hMIDIOutputDevice,"UInt",0x80 | this.Channel | (Note << 8) | (Velocity << 16)) ;"Note Off" event
            throw Exception("Could not send ""Note Off"" message.")
    }

    UpdateNotePressure(Note,Pressure)
    {
        If Note Is Not Integer
            throw Exception("Invalid note: " . Note . ".",-1)
        If Pressure Not Between 0 And 100
            throw Exception("Invalid pressure: " . Pressure . ".",-1)
        Pressure := Round((Pressure / 100) * 127)
        If DllCall("winmm\midiOutShortMsg","UInt",this.hMIDIOutputDevice,"UInt",0xA0 | this.Channel | (Note << 8) | (Pressure << 16)) ;"Polyphonic Aftertouch" event
            throw Exception("Could not send ""Polyphonic Aftertouch"" message.")
    }

    Reset()
    {
        If DllCall("winmm\midiOutReset","UInt",this.hMIDIOutputDevice)
            throw Exception("Could not reset MIDI output device.")
    }
}