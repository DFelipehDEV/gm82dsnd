//---------------------------------------------------------------------------//
/*

    Game Maker 8.2 DirectSound
    ==========================
    v0.1
    4 Sep 2026
  
  
  A modern audio engine for Game Maker 8.2.

*/
//---------------------------------------------------------------------------//
/*

  Changelog
  ---------
  
- 

*/
//---------------------------------------------------------------------------//  
/*

  Todo
  ----
  
- everything

*/
//---------------------------------------------------------------------------//
//header

#include <windows.h>
#include <dsound.h>
#include <stdio.h>
#include <math.h>

#pragma comment(lib,"dsound.lib")
#pragma comment(lib,"Winmm.lib")

#define GMREAL extern "C" __declspec(dllexport) double __cdecl
#define GMSTR extern "C" __declspec(dllexport) char* __cdecl

#define REPEAT(x,n) for (int x = 0; x < (n); ++x)


//---------------------------------------------------------------------------//
//debug helpers 🖐


#define WIDE2(x) L##x
#define WIDE1(x) WIDE2(x)

extern bool __vibe_check(const wchar_t* file, int line, HRESULT hr) {
    if (SUCCEEDED(hr)) return false;
    wchar_t buf[1024];
    _snwprintf_s(
        buf, 1024,
        L"DirectSound error in file %s at line %i:\nHRESULT = 0x%08X",
        file, line, hr
    );
    MessageBoxW(0, buf, L"Warning", 0);
    exit(1);
    return true;
}

#define vibe_check(a) __vibe_check(WIDE1(__FILE__),__LINE__,a)

extern void debug_message(const wchar_t* msg) {    
    MessageBoxW(0, msg, L"Debug message", 0);
}

extern void debug_message(const wchar_t* msg, int value) {    
    wchar_t buf[1024];
    _snwprintf_s(buf, 1024, msg, value);
    MessageBoxW(0, buf, L"Debug message", 0);
}


//---------------------------------------------------------------------------//
//types and globals


LPDIRECTSOUND Device;
LPDIRECTSOUNDBUFFER PrimaryBuffer;
DSBUFFERDESC BufferDescriptor;
WAVEFORMATEX FormatDescriptor;

#define THREAD_MS 15
#define RESOURCE_COUNT 10000
#define INSTANCE_COUNT 100

struct SoundResource {
    LPDIRECTSOUNDBUFFER buffer;
    int type;
    float volume;
    float pan;
    float pitch;
};

struct SoundInstance {
    SoundResource sound;
    float volume;
    float pan;
    float pitch;
    float volume_from;
    float volume_to;
    int fade_length;
    int fade_amount;
    int age;
    int playing;
};

float global_volume;

SoundResource* sound_resources[RESOURCE_COUNT];
SoundInstance* sound_instances[4][INSTANCE_COUNT];


//---------------------------------------------------------------------------//
//function prototypes


void dll_init(HWND);
void CALLBACK timer_callback(UINT, UINT, DWORD, DWORD, DWORD);

void dsound_thread_update();
void dsound_frame_update(int);


//---------------------------------------------------------------------------//
//system boilerplate


DSBUFFERDESC* describe_buffer(DWORD flags,WAVEFORMATEX* format,DWORD size) {
    //fills and returns a directsound buffer descriptor structure
    
    memset(&BufferDescriptor,0,sizeof(BufferDescriptor));
    BufferDescriptor.dwFlags = flags;
    BufferDescriptor.dwBufferBytes = size;
    BufferDescriptor.lpwfxFormat = format;
    BufferDescriptor.dwReserved = 0;
    BufferDescriptor.dwSize = sizeof(DSBUFFERDESC);
    return &BufferDescriptor;
}


WAVEFORMATEX* describe_format(int sample_rate) {
    //fills and returns a directsound format descriptor structure
    
    memset(&FormatDescriptor,0,sizeof(FormatDescriptor));
    FormatDescriptor.wFormatTag = WAVE_FORMAT_PCM;
    FormatDescriptor.nChannels = 2;
    FormatDescriptor.nSamplesPerSec = (DWORD)sample_rate;
    FormatDescriptor.wBitsPerSample = 8;
    FormatDescriptor.nBlockAlign =
        (FormatDescriptor.wBitsPerSample / 8) * FormatDescriptor.nChannels;
    FormatDescriptor.nAvgBytesPerSec =
        FormatDescriptor.nSamplesPerSec * FormatDescriptor.nBlockAlign;
    FormatDescriptor.cbSize = 0;
    return &FormatDescriptor;
}


void dll_init(HWND hwnd) {
    //initializes all systems
    
    
    //directsound
        vibe_check(DirectSoundCreate(NULL, &Device, NULL));
        
        vibe_check(Device -> SetCooperativeLevel(hwnd, DSSCL_PRIORITY));
    
        vibe_check(Device -> CreateSoundBuffer(
            describe_buffer(
                DSBCAPS_PRIMARYBUFFER,
                NULL,
                0
            ),
            &PrimaryBuffer,
            NULL
        ));
        vibe_check(PrimaryBuffer -> Play(0, 0, DSBPLAY_LOOPING));
        
    
    //initialize data
        REPEAT(i,RESOURCE_COUNT) {
            sound_resources[i] = NULL;
        }
        REPEAT(type,4) REPEAT(i,INSTANCE_COUNT) {
            sound_instances[type][i] = NULL;
        }
    
    //set up timer callback
        timeSetEvent(
            THREAD_MS,
            THREAD_MS,
            timer_callback,
            0,
            TIME_PERIODIC
        );    
}

void CALLBACK timer_callback(UINT, UINT, DWORD, DWORD, DWORD) {
    //called in the multimedia timer thread
    
    dsound_thread_update();
}


//---------------------------------------------------------------------------//
//Game Maker interface


GMREAL __dsound_init(double hwnd_real) {
    dll_init((HWND)(int)hwnd_real);
    
    return 0;
}


GMREAL __dsound_update(double frame_ms) {    
    dsound_frame_update((int)frame_ms);
    
    return 0;
}


//---------------------------------------------------------------------------//
//internals


void dsound_thread_update() {
    //thread; use THREAD_MS increments
    //update all loop points and instance fading here
}

void dsound_frame_update(int frame_ms) {
    //gml frame
    //update instance life and cleanup here
}


//---------------------------------------------------------------------------//