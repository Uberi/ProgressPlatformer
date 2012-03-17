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

class NotePlayer
{
    __New(Sound = 0)
    {
        this.Device := new MIDIOutputDevice
        this.Device.Sound := Sound
        this.Device.SetVolume(100)

        this.pCallback := RegisterCallback("NotePlayerPlayTimer","F","",&this)

        this.Actions := []
        this.Playing := 0
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

    Play(Index,Length,DownVelocity = 60,UpVelocity = 60)
    {
        ;play the note
        this.Device.NoteOn(Index,DownVelocity)

        ;set up the data the timer will need to do its task
        TimerData := Object()
        ObjAddRef(&TimerData)
        TimerData.Index := Index
        TimerData.Velocity := UpVelocity
        TimerData.Device := this.Device

        ;set up a timer to turn off the note
        pCallback := RegisterCallback("NotePlayerNoteTimer","F","",&TimerData)
        hTimer := DllCall("SetTimer","UPtr",0,"UPtr",0,"UInt",Length,"UPtr",pCallback,"UPtr")
        If !hTimer
            throw Exception("Could not create update timer.")
        TimerData.pCallback := pCallback
        TimerData.hTimer := hTimer

        Return, this
    }

    Start()
    {
        If this.Playing ;note player is already playing
            Return, this

        ;sort the notes into groups by their time offsets
        Timeline := [], Offset := 0
        For Index, Action In this.Actions
        {
            If Action.Index = -1 ;delay
                Offset += Action.Length
            Else ;note
            {
                If !ObjHasKey(Timeline,Offset)
                    Timeline[Offset] := []
                Timeline[Offset].Insert(Object("Type","NoteOn","Index",Action.Index,"Velocity",Action.DownVelocity))
                Temp1 := Offset + Action.Length
                If !ObjHasKey(Timeline,Temp1)
                    Timeline[Temp1] := []
                Timeline[Temp1].Insert(Object("Type","NoteOff","Index",Action.Index,"Velocity",Action.UpVelocity))
            }
        }
        If !ObjHasKey(Timeline,Offset) ;insert the ending delay
            Timeline[Offset] := []

        ;convert the timeline into a set of actions
        this.Sequence := [], PreviousOffset := 0
        For Offset, Actions In Timeline
        {
            Actions.Insert(1,Offset - PreviousOffset), PreviousOffset := Offset
            this.Sequence.Insert(Actions)
        }

        ;activate the first set of actions if it is present
        If ObjMaxIndex(this.Sequence)
        {
            this.ActiveNotes := []
            this.Playing := 1
            this.Index := 1

            ;set up a timer to execute the action set
            this.hTimer := DllCall("SetTimer","UPtr",0,"UPtr",0,"UInt",this.Sequence[1][1],"UPtr",this.pCallback,"UPtr")
            If !this.hTimer
                throw Exception("Could not create update timer.")
        }
        Return, this
    }

    Stop()
    {
        If !this.Playing
            Return

        ;clean up timers
        If !DllCall("KillTimer","UPtr",0,"UPtr",this.hTimer)
            throw Exception("Could not destroy update timer.")

        ;turn off any active notes
        For Index In this.ActiveNotes
            this.Device.NoteOff(Index,100)
        this.Playing := 0
    }

    Reset()
    {
        this.Stop()
        this.Actions := []
        this.Sequence := []
    }

    __Delete()
    {
        this.Stop()
        DllCall("GlobalFree","UPtr",this.pCallback) ;free callback
    }
}

NotePlayerNoteTimer(hWindow,Message,Event,TickCount)
{
    TimerData := Object(A_EventInfo) ;retrieve the note player object
    ObjRelease(A_EventInfo) ;release the extra reference created before

    If !DllCall("KillTimer","UPtr",0,"UPtr",TimerData.hTimer)
        throw Exception("Could not destroy update timer.")
    DllCall("GlobalFree","UPtr",TimerData.pCallback) ;free callback

    TimerData.Device.NoteOff(TimerData.Index,TimerData.Velocity)
}

NotePlayerPlayTimer(hWindow,Message,Event,TickCount)
{
    NotePlayer := Object(A_EventInfo) ;retrieve the note player object

    ;remove the currently active timer
    If !DllCall("KillTimer","UPtr",0,"UPtr",NotePlayer.hTimer)
        throw Exception("Could not destroy update timer.")

    ;execute the set of actions
    For Index, Action In NotePlayer.Sequence[NotePlayer.Index] ;perform the current action set
    {
        If Index != 1 ;skip over the first field, which is the time offset
        {
            If (Action.Type = "NoteOn") ;note on action
            {
                NotePlayer.Device.NoteOn(Action.Index,Action.Velocity)
                NotePlayer.ActiveNotes[Action.Index] := 1
            }
            Else If (Action.Type = "NoteOff") ;note off action
            {
                NotePlayer.Device.NoteOff(Action.Index,Action.Velocity)
                NotePlayer.ActiveNotes.Remove(Action.Index,"")
            }
        }
    }

    If (NotePlayer.Index < ObjMaxIndex(NotePlayer.Sequence)) ;set the next timer if available
    {
        NotePlayer.Index ++
        NotePlayer.hTimer := DllCall("SetTimer","UPtr",0,"UPtr",0,"UInt",NotePlayer.Sequence[NotePlayer.Index][1],"UPtr",NotePlayer.pCallback,"UPtr")
    }
    Else If NotePlayer.Repeat ;repeat note sequence
    {
        NotePlayer.Index := 1
        NotePlayer.hTimer := DllCall("SetTimer","UPtr",0,"UPtr",0,"UInt",NotePlayer.Sequence[1][1],"UPtr",NotePlayer.pCallback,"UPtr")
    }
    Else ;stop playing
    {
        ;turn off any active notes
        For Index In NotePlayer.ActiveNotes
            this.Device.NoteOff(Index,100)
        this.Playing := 0
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
        If MIDIOutputDevice.DeviceCount = 0
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