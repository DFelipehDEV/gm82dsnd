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
  
- load sounds from runner memory, respecting the preload flag.
- ability to name sounds, and use the names where functions expect indexes.
  this means all gml functions must check the type of the index argument.
  sounds added from file are automatically named with the filename, just like
  the old sound extension. this is implemented via a dsmap in gml.
- "persistent" sounds that stay between rooms, any sounds that are not
  persistent will stop when changing rooms.
- ability to discard and restore sounds for memory management.
- full gm effect support.
- tracker support via libxmp.


  Notes
  -----
  
  "Effects might not work smoothly on very small buffers, and Microsoft DirectSound does not permit the creation of effects-capable buffers that hold less than 150 (BufferSize.FxMin) milliseconds of data."
  https://learn.microsoft.com/en-us/previous-versions/windows/desktop/ee418041(v=vs.85)
  
  "There is a known issue with volume levels of duplicated buffers. The duplicated buffer will play at full volume unless you change the volume to a different value than the original buffer's volume setting. If the volume stays the same (even if you explicitly set the same volume in the duplicated buffer with a IDirectSoundBuffer8::SetVolume call), the buffer will play at full volume regardless. To work around this problem, immediately set the volume of the duplicated buffer to something slightly different than what it was, even if you change it one millibel. The volume may then be immediately set back again to the original desired value."
  
  https://github.com/libxmp/libxmp
  
  
*/
//---------------------------------------------------------------------------//
//header

#include <stdio.h>
#include <stdint.h>
#include <windows.h>
#include <dsound.h>

#pragma comment(lib,"dsound.lib")
#pragma comment(lib,"Winmm.lib")

#define GMREAL extern "C" __declspec(dllexport) double __cdecl
#define GMSTR extern "C" __declspec(dllexport) char* __cdecl

#define REPEAT(x,n) for (int x = 0; x < (n); ++x)
    
#define ERROR_GENERIC     -1
#define ERROR_NON_EXIST   -2
#define ERROR_FAIL_LOAD   -3
#define ERROR_NO_SPACE    -4

#define ASSERT(var) if ((var) < 0) return (var)


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


//dsound
    LPDIRECTSOUND Device;
    LPDIRECTSOUNDBUFFER PrimaryBuffer;
    DSBUFFERDESC BufferDescriptor;
    WAVEFORMATEX FormatDescriptor;


//gm 8.1 sound memory structures
    struct TMemoryStream {
        uint32_t vfp;
        void* memory;
        uint32_t size;
        uint32_t position;
        uint32_t capacity;
    };

    struct GMSound {
        uint32_t vfp;
        uint32_t kind;
        char* extension;
        char* origname;
        TMemoryStream* memstream;
        uint32_t preload;
        uint32_t effects;
        double volume;
        double pan;
        uint32_t index;
        wchar_t* fname;
    };


//runner memory locations
    static GMSound*** gm_sound_mem = (GMSound***)0x6840c0;
    static uint32_t* gm_sound_count = (uint32_t*)0x6840c8;


//sound structs
    struct SoundResource {
        LPDIRECTSOUNDBUFFER buffer;
        int kind;
        bool loaded;
        float volume;
        float pan;
        float pitch;
        int loop_a;
        int loop_b;
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
        bool playing;
        bool looping;
    };


//constants
    #define THREAD_MS 15
    #define RESOURCE_COUNT 10000
    #define INSTANCE_COUNT 100


//global variables
    float global_volume;

    SoundResource* sound_resources[RESOURCE_COUNT];
    SoundInstance* sound_instances[4][INSTANCE_COUNT];


//---------------------------------------------------------------------------//
//function prototypes


void dll_init(HWND);
void CALLBACK timer_callback(UINT, UINT, DWORD, DWORD, DWORD);

void dsound_thread_update();
int dsound_add_file(char*);
int dsound_add_mem(char*, int);
void dsound_frame_update(int);
int dsound_get_free_resource();
int dsound_get_free_instance();
int dsound_play(int, bool);
void dsound_stop_inst(SoundInstance*);


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

GMREAL __dsound_add_file(char* fname) {
    return (double)dsound_add_file(fname);
}

GMREAL __dsound_add_mem(double buffer, double length) {
    return (double)dsound_add_mem((char*)(int)buffer, (int)length);
}

GMREAL __dsound_play(double index, double loop) {
    return (double)dsound_play((int)index, (loop>0.5));
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

int dsound_get_free_resource() {
    REPEAT(i, RESOURCE_COUNT) {
        if (sound_resources[i] == NULL) return i;
    }
    return ERROR_NO_SPACE;
}

int dsound_get_free_instance(int kind) {
    SoundInstance* inst;
    SoundInstance* oldest;
    int oldest_id;
    oldest = sound_instances[kind][0];
    REPEAT(i, INSTANCE_COUNT) {
        inst = sound_instances[kind][i];
        if (inst == NULL) return i;
        
        if (inst->age > oldest->age) {
            oldest = inst;
            oldest_id = i;
        }
    }
    dsound_stop_inst(oldest);
    return oldest_id;
}

int dsound_add_file(char* fname) {
    int id = dsound_get_free_resource();
    ASSERT(id);
    
    //load wav etc
    
    return id;
}

int dsound_add_mem(char* buffer, int length) {
    int id = dsound_get_free_resource();
    ASSERT(id);
    
    //load etc
    
    return id;
}

int dsound_play(int index, bool loop) {
    SoundResource* sound = sound_resources[index];
    int kind = sound->kind;
    
    int id = dsound_get_free_instance(kind);
    
    //instantiate etc.
    
    return id;
}

void dsound_stop_inst(SoundInstance* inst) {
    //todo
}

//---------------------------------------------------------------------------//