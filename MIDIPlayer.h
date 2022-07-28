//----------------------------------------------------------------------------------------------------
//
//	MIDI Player library using Win32 WinMM MIDI streaming API
//
//	Copyright (c) 1998-2022 Samuel Gomes
//	https://github.com/a740g
//
//-----------------------------------------------------------------------------------------------------

#pragma comment(lib, "winmm")

#define MIDI_TRACKS 32

/* A MIDI file */
typedef struct
{
	int divisions; /* number of ticks per quarter note */
	struct
	{
		unsigned char *data; /* MIDI message stream */
		int len;			 /* length of the track data */
	} track[MIDI_TRACKS];
} MIDI;

static MIDI mididata;
static BOOL MusicLoaded = FALSE;
static BOOL MusicLoop = FALSE;

static HMIDISTRM hMidiStream;
static MIDIEVENT *MidiEvents[MIDI_TRACKS];
static MIDIHDR MidiStreamHdr;
static MIDIEVENT *NewEvents;
static int NewSize;
static int NewPos;
static int BytesRecorded[MIDI_TRACKS];
static int BufferSize[MIDI_TRACKS];
static int CurrentTrack;
static int CurrentPos;

// Some strings of bytes used in the MIDI format
static BYTE midikey[] = {0x00, 0xff, 0x59, 0x02, 0x00, 0x00};				// C major
static BYTE miditempo[] = {0x00, 0xff, 0x51, 0x03, 0x09, 0xa3, 0x1a};		// uS/qnote
static BYTE midihdr[] = {'M', 'T', 'h', 'd', 0, 0, 0, 6, 0, 1, 0, 0, 0, 0}; // header (length 6, format 1)
static BYTE trackhdr[] = {'M', 'T', 'r', 'k'};								// track header

//-----------------------------------------------------------------------------------------------------
// INTERNAL LIBRARY FUNCTIONS
//-----------------------------------------------------------------------------------------------------
// Reads the length of a chunk in a midi buffer, advancing the pointer 4 bytes, bigendian
// Passed a pointer to the pointer to a MIDI buffer
// Returns the chunk length at the pointer position
static size_t ReadLength(BYTE **mid)
{
	BYTE *midptr = *mid;
	size_t length = (size_t)(*midptr++) << 24;
	length += (size_t)(*midptr++) << 16;
	length += (size_t)(*midptr++) << 8;
	length += *midptr++;
	*mid = midptr;

	return length;
}

// Convert an in-memory copy of a MIDI format 0 or 1 file to our custom MIDI structure, that is valid or has been zeroed
// Passed a pointer to a memory buffer with MIDI format music in it
// Returns TRUE if successful, FALSE if the buffer is not MIDI format
static BOOL ConvertMIDI(BYTE *mid)
{
	int i;
	int ntracks;

	// read the midi header

	if (memcmp(mid, midihdr, 4))
		return FALSE;

	mididata.divisions = (mid[12] << 8) + mid[13];
	ntracks = (mid[10] << 8) + mid[11];

	if (ntracks >= MIDI_TRACKS)
		return FALSE;

	mid += 4;
	mid += ReadLength(&mid); // seek past header

	// now read each track

	for (i = 0; i < ntracks; i++)
	{
		while (memcmp(mid, trackhdr, 4))
		{ // simply skip non-track data
			mid += 4;
			mid += ReadLength(&mid);
		}
		mid += 4;
		mididata.track[i].len = (int)ReadLength(&mid); // get length, move mid past it

		// read a track
		unsigned char *tmp = (unsigned char *)realloc(mididata.track[i].data, mididata.track[i].len);
		if (tmp != nullptr)
		{
			mididata.track[i].data = tmp;
		}
		else
		{
			return FALSE;
		}

		memcpy(mididata.track[i].data, mid, mididata.track[i].len);
		mid += mididata.track[i].len;
	}
	for (; i < MIDI_TRACKS; i++)
	{
		if (mididata.track[i].len)
		{
			free(mididata.track[i].data);
			mididata.track[i].data = NULL;
			mididata.track[i].len = 0;
		}
	}

	return TRUE;
}

static int GetVL(void)
{
	int l = 0;
	BYTE c;

	for (;;)
	{
		c = mididata.track[CurrentTrack].data[CurrentPos];
		CurrentPos++;
		l += (c & 0x7f);
		if (!(c & 0x80))
			return l;
		l <<= 7;
	}
}

static void AddEvent(DWORD at, DWORD type, BYTE event, BYTE a, BYTE b)
{
	MIDIEVENT *CurEvent;

	if ((BytesRecorded[CurrentTrack] + (int)sizeof(MIDIEVENT)) >= BufferSize[CurrentTrack])
	{
		BufferSize[CurrentTrack] += 100 * sizeof(MIDIEVENT);

		MIDIEVENT *tmp = (MIDIEVENT *)realloc(MidiEvents[CurrentTrack], BufferSize[CurrentTrack]);
		if (tmp != nullptr)
		{
			MidiEvents[CurrentTrack] = tmp;
		}
		else
		{
			return; // this should be handled in a better way
		}
	}
	CurEvent = (MIDIEVENT *)((BYTE *)MidiEvents[CurrentTrack] + BytesRecorded[CurrentTrack]);
	memset(CurEvent, 0, sizeof(MIDIEVENT));
	CurEvent->dwDeltaTime = at;
	CurEvent->dwEvent = event + (a << 8) + (b << 16) + (type << 24);
	BytesRecorded[CurrentTrack] += 3 * sizeof(DWORD);
}

static void TrackToStream(void)
{
	DWORD atime, len;
	BYTE event, type, a, b, c;
	BYTE laststatus, lastchan;

	CurrentPos = 0;
	laststatus = 0;
	lastchan = 0;
	atime = 0;
	for (;;)
	{
		if (CurrentPos >= mididata.track[CurrentTrack].len)
			return;
		atime += GetVL();
		event = mididata.track[CurrentTrack].data[CurrentPos];
		CurrentPos++;
		if (event == 0xF0 || event == 0xF7)
		{ /* SysEx event */
			len = GetVL();
			CurrentPos += len;
		}
		else if (event == 0xFF)
		{ /* Meta event */
			type = mididata.track[CurrentTrack].data[CurrentPos];
			CurrentPos++;
			len = GetVL();

			switch (type)
			{
			case 0x2f:
				return;
			case 0x51: /* Tempo */
				a = mididata.track[CurrentTrack].data[CurrentPos];
				CurrentPos++;
				b = mididata.track[CurrentTrack].data[CurrentPos];
				CurrentPos++;
				c = mididata.track[CurrentTrack].data[CurrentPos];
				CurrentPos++;
				AddEvent(atime, MEVT_TEMPO, c, b, a);
				break;
			default:
				CurrentPos += len;
				break;
			}
		}
		else
		{
			a = event;
			if (a & 0x80)
			{ /* status byte */
				lastchan = a & 0x0F;
				laststatus = (a >> 4) & 0x07;
				a = mididata.track[CurrentTrack].data[CurrentPos];
				CurrentPos++;
				a &= 0x7F;
			}
			switch (laststatus)
			{
			case 0: /* Note off */
				b = mididata.track[CurrentTrack].data[CurrentPos];
				CurrentPos++;
				b &= 0x7F;
				AddEvent(atime, MEVT_SHORTMSG, (BYTE)((laststatus << 4) + lastchan + 0x80), a, b);
				break;

			case 1: /* Note on */
				b = mididata.track[CurrentTrack].data[CurrentPos];
				CurrentPos++;
				b &= 0x7F;
				AddEvent(atime, MEVT_SHORTMSG, (BYTE)((laststatus << 4) + lastchan + 0x80), a, b);
				break;

			case 2: /* Key Pressure */
				b = mididata.track[CurrentTrack].data[CurrentPos];
				CurrentPos++;
				b &= 0x7F;
				AddEvent(atime, MEVT_SHORTMSG, (BYTE)((laststatus << 4) + lastchan + 0x80), a, b);
				break;

			case 3: /* Control change */
				b = mididata.track[CurrentTrack].data[CurrentPos];
				CurrentPos++;
				b &= 0x7F;
				AddEvent(atime, MEVT_SHORTMSG, (BYTE)((laststatus << 4) + lastchan + 0x80), a, b);
				break;

			case 4: /* Program change */
				a &= 0x7f;
				AddEvent(atime, MEVT_SHORTMSG, (BYTE)((laststatus << 4) + lastchan + 0x80), a, 0);
				break;

			case 5: /* Channel pressure */
				a &= 0x7f;
				AddEvent(atime, MEVT_SHORTMSG, (BYTE)((laststatus << 4) + lastchan + 0x80), a, 0);
				break;

			case 6: /* Pitch wheel */
				b = mididata.track[CurrentTrack].data[CurrentPos];
				CurrentPos++;
				b &= 0x7F;
				AddEvent(atime, MEVT_SHORTMSG, (BYTE)((laststatus << 4) + lastchan + 0x80), a, b);
				break;

			default:
				break;
			}
		}
	}
}

static void BlockOut(void)
{
	MMRESULT err;
	int BlockSize;

	if ((MusicLoaded) && (NewEvents))
	{
		if (NewPos >= NewSize)
		{
			if (MusicLoop)
			{
				NewPos = 0;
			}
			else
			{
				return;
			}
		}
		BlockSize = (NewSize - NewPos);
		if (BlockSize > 36000)
			BlockSize = 36000;
		MidiStreamHdr.lpData = (LPSTR)((BYTE *)NewEvents + NewPos);
		NewPos += BlockSize;
		MidiStreamHdr.dwBufferLength = BlockSize;
		MidiStreamHdr.dwBytesRecorded = BlockSize;
		MidiStreamHdr.dwFlags = 0;
		err = midiOutPrepareHeader((HMIDIOUT)hMidiStream, &MidiStreamHdr, sizeof(MIDIHDR));
		if (err != MMSYSERR_NOERROR)
			return;
		err = midiStreamOut(hMidiStream, &MidiStreamHdr, sizeof(MIDIHDR));
	}
}

static void MIDItoStream(void)
{
	int BufferPos[MIDI_TRACKS];
	MIDIEVENT *CurEvent;
	MIDIEVENT *NewEvent;
	int lTime;
	int Dummy;
	int Track;

	if (!hMidiStream)
		return;
	NewSize = 0;
	for (CurrentTrack = 0; CurrentTrack < MIDI_TRACKS; CurrentTrack++)
	{
		if (MidiEvents[CurrentTrack])
		{
			free(MidiEvents[CurrentTrack]);
			MidiEvents[CurrentTrack] = NULL;
		}
		BytesRecorded[CurrentTrack] = 0;
		BufferSize[CurrentTrack] = 0;
		TrackToStream();
		NewSize += BytesRecorded[CurrentTrack];
		BufferPos[CurrentTrack] = 0;
	}

	MIDIEVENT *tmp = (MIDIEVENT *)realloc(NewEvents, NewSize);
	if (tmp != nullptr)
	{
		NewEvents = tmp;
	}
	else
	{
		return; // this should be handled better
	}

	if (NewEvents)
	{
		NewPos = 0;
		for (;;)
		{
			lTime = INT_MAX;
			Track = -1;
			for (CurrentTrack = MIDI_TRACKS - 1; CurrentTrack >= 0; CurrentTrack--)
			{
				if ((BytesRecorded[CurrentTrack] > 0) && (BufferPos[CurrentTrack] < BytesRecorded[CurrentTrack]))
					CurEvent = (MIDIEVENT *)((BYTE *)MidiEvents[CurrentTrack] + BufferPos[CurrentTrack]);
				else
					continue;
				if ((int)CurEvent->dwDeltaTime <= lTime)
				{
					lTime = CurEvent->dwDeltaTime;
					Track = CurrentTrack;
				}
			}
			if (Track == -1)
				break;
			else
			{
				CurEvent = (MIDIEVENT *)((BYTE *)MidiEvents[Track] + BufferPos[Track]);
				BufferPos[Track] += 12;
				NewEvent = (MIDIEVENT *)((BYTE *)NewEvents + NewPos);
				memcpy(NewEvent, CurEvent, 12);
				NewPos += 12;
			}
		}
		NewPos = 0;
		lTime = 0;
		while (NewPos < NewSize)
		{
			NewEvent = (MIDIEVENT *)((BYTE *)NewEvents + NewPos);
			Dummy = NewEvent->dwDeltaTime;
			NewEvent->dwDeltaTime -= lTime;
			lTime = Dummy;
			NewPos += 12;
		}
		NewPos = 0;
		MusicLoaded = TRUE;
		BlockOut();
	}
	for (CurrentTrack = 0; CurrentTrack < MIDI_TRACKS; CurrentTrack++)
	{
		if (MidiEvents[CurrentTrack])
		{
			free(MidiEvents[CurrentTrack]);
			MidiEvents[CurrentTrack] = NULL;
		}
	}
}

static void CALLBACK MidiProc(HMIDIIN hMidi, UINT uMsg, DWORD dwInstance, DWORD dwParam1, DWORD dwParam2)
{
	switch (uMsg)
	{
	case MOM_DONE:
		BlockOut();
		break;
	default:
		break;
	}
}
//-----------------------------------------------------------------------------------------------------

//-----------------------------------------------------------------------------------------------------
// PUBLIC LIBRARY FUNCTIONS
//-----------------------------------------------------------------------------------------------------
// Kickstarts MIDI stream playback
void MIDIPlay(BOOL looping)
{
	if (hMidiStream)
	{
		MusicLoop = looping;
		midiStreamRestart(hMidiStream);
	}
}

// Pauses a MIDI stream
void MIDIPause(void)
{
	if (hMidiStream)
		midiStreamPause(hMidiStream);
}

// Resumes a paused MIDI stream
void MIDIResume(void)
{
	if (hMidiStream)
		midiStreamRestart(hMidiStream);
}

// Stops playing the MIDI file - this does not free resources!
void MIDIStop(void)
{
	if (!hMidiStream)
		return;

	midiStreamStop(hMidiStream);
	midiOutReset((HMIDIOUT)hMidiStream);
}

// Closes the WinMM MIDI stream
void MIDIUnregister(void)
{
	if (!hMidiStream)
		return;

	MusicLoaded = FALSE;
	midiStreamStop(hMidiStream);
	midiOutReset((HMIDIOUT)hMidiStream);
	midiStreamClose(hMidiStream);
	hMidiStream = 0;
}

// Sets up and opens the WinMM MIDI stream
BOOL MIDIRegister(char *data)
{
	MMRESULT merr;
	MIDIPROPTIMEDIV mptd;
	UINT MidiDevice = MIDI_MAPPER;

	if (!ConvertMIDI((BYTE *)data))
		return FALSE;

	memset(&MidiStreamHdr, 0, sizeof(MIDIHDR));
	merr = midiStreamOpen(&hMidiStream, &MidiDevice, 1, (DWORD_PTR)&MidiProc, 0, CALLBACK_FUNCTION);
	if (merr != MMSYSERR_NOERROR)
		hMidiStream = 0;
	if (hMidiStream == 0)
		return FALSE;
	mptd.cbStruct = sizeof(MIDIPROPTIMEDIV);
	mptd.dwTimeDiv = mididata.divisions;
	merr = midiStreamProperty(hMidiStream, (LPBYTE)&mptd, MIDIPROP_SET | MIDIPROP_TIMEDIV);
	MIDItoStream();
	MusicLoaded = TRUE;

	return TRUE;
}

// Frees allocated memory - this must be called once we are done with the MIDI (or else we will leak memory)
void MIDIDone(void)
{
	int i;

	MIDIUnregister();

	for (i = 0; i < MIDI_TRACKS; i++)
	{
		if (mididata.track[i].data != NULL && mididata.track[i].len)
		{
			free(mididata.track[i].data);
			mididata.track[i].data = NULL;
			mididata.track[i].len = 0;
		}
		if (MidiEvents[i])
		{
			free(MidiEvents[i]);
			MidiEvents[i] = NULL;
		}
	}

	if (NewEvents)
	{
		free(NewEvents);
		NewEvents = NULL;
	}
}

// Initializes stuff - call this before using the library
void MIDIInit(void)
{
	int i;

	for (i = 0; i < MIDI_TRACKS; i++)
	{
		mididata.track[i].data = NULL;
		mididata.track[i].len = 0;
		MidiEvents[i] = NULL;
	}

	NewEvents = NULL;
	hMidiStream = 0;
}
//-----------------------------------------------------------------------------------------------------
