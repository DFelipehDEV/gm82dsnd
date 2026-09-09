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
  
- load sounds from runner memory.
- ability to name sounds, and use the names where functions expect indexes.
  this means all gml functions must check the type of the index argument.
  sounds added from file are automatically named with the filename, just like
  the old sound extension. this is implemented via a dsmap in gml.
- "persistent" sounds that stay between rooms, any sounds that are not
  persistent will stop when changing rooms.
- tracker support via libxmp.


  Notes
  -----
  
  instance values for vol pan pitch are multiplied with the sound resource's values.
  this means that a sound that has a volume of 0.5, when played at half volume, will create
  an instance with 0.25 volume.
  
  https://github.com/libxmp/libxmp
  
  HRESULT hr;
  DWORD dwResults;
  LPDIRECTSOUNDBUFFER8 secbuffer8 = (LPDIRECTSOUNDBUFFER8)secbuffer;       
  DSEFFECTDESC dsEffect;
  memset(&dsEffect, 0, sizeof(DSEFFECTDESC));
  dsEffect.dwSize = sizeof(DSEFFECTDESC);
  dsEffect.dwFlags = 0;
  dsEffect.guidDSFXClass = GUID_DSFX_STANDARD_ECHO;
  vibe_check(secbuffer8->SetFX(1, &dsEffect, &dwResults));
  vibe_check(secbuffer8->Play(0, 0, 0));
  
  
*/
//---------------------------------------------------------------------------//
//header

#include <stdio.h>
#include <stdint.h>
#include <cmath>
#include <windows.h>
#include <dsound.h>

#pragma comment(lib,"dsound.lib")
#pragma comment(lib,"Dxguid.lib")
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
    LPDIRECTSOUND8 Device;
    LPDIRECTSOUNDBUFFER PrimaryBuffer;
    DSBUFFERDESC BufferDescriptor;
    WAVEFORMATEX FormatDescriptor;


//wave format
    #pragma pack(push, 1)
    struct RiffWaveFmt {
        char RIFF[4];
        uint32_t size;
        char WaveFmt[8];
        uint32_t FormatLength;
        uint16_t Format;
        uint16_t Channels;
        uint32_t SampleRate;
        uint32_t BytesPerSec;
        uint16_t BlockAlign;
        uint16_t BitsPerSample;
    };
    #pragma pack(pop)


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
        bool exists = 0;
        bool loaded;
        bool persistent;
        float volume;
        float pan;
        float pitch;
        int loop_a;
        int loop_b;
        int inst_count;
        int frequency;
    };

    struct SoundInstance {
        SoundResource* sound;
        LPDIRECTSOUNDBUFFER clone_buffer;
        int index;
        float volume;
        float pan;
        float pitch;
        float volume_from;
        float volume_to;
        int fade_length;
        int fade_amount;
        int age;
        bool exists;
        bool playing;
        bool looping;        
    };


//constants
    #define THREAD_MS 15
    #define RESOURCE_COUNT 100000
    #define INSTANCE_COUNT 64


//global variables
    double global_volume = 0.7;
    int last_instance_id = RESOURCE_COUNT;

    SoundResource sound_resources[RESOURCE_COUNT];
    SoundInstance sound_instances[4][INSTANCE_COUNT];


//---------------------------------------------------------------------------//
//function prototypes


void dll_init();
void CALLBACK timer_callback(UINT, UINT, DWORD, DWORD, DWORD);

void dsound_thread_update();
int dsound_add_file(char*, int);
int dsound_add_mem(char*, int, int);
void dsound_frame_update(int);
int dsound_get_free_resource();
int dsound_get_free_instance();
int dsound_play(int, bool, double, double, double);
void dsound_stop_inst(int);
void dsound_inst_free(SoundInstance*);
LONG dsound_volume_formula(double);
LONG dsound_pan_formula(double);
void dsound_set_global_volume(double);


//---------------------------------------------------------------------------//
//system boilerplate


DSBUFFERDESC* describe_buffer(DWORD flags, WAVEFORMATEX* format, DWORD size) {
    //fills and returns a directsound buffer descriptor structure
    
    memset(&BufferDescriptor,0,sizeof(BufferDescriptor));
    BufferDescriptor.dwFlags = flags;
    BufferDescriptor.dwBufferBytes = size;
    BufferDescriptor.lpwfxFormat = format;
    BufferDescriptor.dwReserved = 0;
    BufferDescriptor.dwSize = sizeof(DSBUFFERDESC);
    return &BufferDescriptor;
}

WAVEFORMATEX* describe_format(int samplerate, int channels, int bits) {
    //fills and returns a directsound format descriptor structure
    
    memset(&FormatDescriptor,0,sizeof(FormatDescriptor));
    FormatDescriptor.wFormatTag = WAVE_FORMAT_PCM;
    FormatDescriptor.nChannels = (WORD)channels;
    FormatDescriptor.nSamplesPerSec = (DWORD)samplerate;
    FormatDescriptor.wBitsPerSample = (WORD)bits;
    FormatDescriptor.nBlockAlign =
        (FormatDescriptor.wBitsPerSample / 8) * FormatDescriptor.nChannels;
    FormatDescriptor.nAvgBytesPerSec =
        FormatDescriptor.nSamplesPerSec * FormatDescriptor.nBlockAlign;
    FormatDescriptor.cbSize = 0;
    return &FormatDescriptor;
}

void dll_init() {
    //initializes all systems
    
    
    //directsound
        vibe_check(DirectSoundCreate8(NULL, &Device, NULL));
        
        //you're supposed to use your application's window here but the
        //desktop window works and i haven't been able to find any problems.
        //using the desktop prevents the extension from having to wait for
        //the runner to create a window, which allows full extension usage
        //during the first room's create events.
        vibe_check(Device->SetCooperativeLevel(
            GetDesktopWindow(),
            DSSCL_PRIORITY
        ));
    
        vibe_check(Device->CreateSoundBuffer(
            describe_buffer(
                DSBCAPS_PRIMARYBUFFER,
                NULL,
                0
            ),
            &PrimaryBuffer,
            NULL
        ));
        vibe_check(PrimaryBuffer->Play(0, 0, DSBPLAY_LOOPING));
    
    
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


GMREAL __dsound_init() {
    dll_init();    
    return 0;
}

GMREAL __dsound_update(double frame_ms) {    
    dsound_frame_update((int)frame_ms);    
    return 0;
}

GMREAL __dsound_add_file(char* fname, double kind) {
    return (double)dsound_add_file(fname, (int)kind);
}

GMREAL __dsound_add_mem(double buffer, double length, double kind) {
    return (double)dsound_add_mem((char*)(int)buffer, (int)length, (int) kind);
}

GMREAL __dsound_play(double index, double loop, double vol, double pan, double pitch) {
    return (double)dsound_play((int)index, (loop>0.5), vol, pan, pitch);
}

GMREAL __dsound_glob_vol(double vol) {
    dsound_set_global_volume(vol);
    return 0;
}

GMREAL __dsound_exists(double index) {
    if (index < 0 || index >= RESOURCE_COUNT) return false;
    return sound_resources[(int)index].exists;
}

GMREAL __dsound_getkind(double index) {
    if (index < 0 || index >= RESOURCE_COUNT) return false;
    if (!sound_resources[(int)index].exists) return (double)ERROR_NON_EXIST;
    return (double)sound_resources[(int)index].kind;
}

GMREAL __dsound_insts(double index) {
    if (index < 0 || index >= RESOURCE_COUNT) return false;
    return sound_resources[(int)index].inst_count;
}

GMREAL __dsound_get_builtin_count() {
    return (double)*gm_sound_count;
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
    
    SoundInstance* inst;
    
    REPEAT(i,INSTANCE_COUNT) {
        REPEAT(kind,4) {
            inst = &sound_instances[kind][i];
            if (inst->exists) {            
                inst->age++;
                if (inst->playing && !inst->looping) {
                    DWORD status = 0;
                    inst->clone_buffer->GetStatus(&status);
                    if (!(status & DSBSTATUS_PLAYING)) {
                        dsound_inst_free(inst);
                    }
                }
            }
        }
    }
}

int dsound_get_free_resource() {
    REPEAT(i, RESOURCE_COUNT) {
        if (!sound_resources[i].exists) return i;
    }
    return ERROR_NO_SPACE;
}

int dsound_get_free_instance(int kind) {
    SoundInstance* inst;
    SoundInstance* oldest;
    int oldest_id = 0;
    oldest = &sound_instances[kind][oldest_id];
    REPEAT(i, INSTANCE_COUNT) {
        inst = &sound_instances[kind][i];
        if (!inst->exists) return i;
        
        if (inst->age > oldest->age) {
            oldest = inst;
            oldest_id = i;
        }
    }
    dsound_inst_free(oldest);
    return oldest_id;
}

int dsound_add_file(char* fname, int kind) {
    FILE* file = fopen(fname, "rb");
    if (file == NULL) return ERROR_NON_EXIST;
    
    fseek(file, 0, SEEK_END);
    int size = ftell(file);
    fseek(file, 0, SEEK_SET);        
    char* buffer = (char*)malloc(size);
    fread(buffer, size, 1, file);
    fclose(file);
    
    int id = dsound_add_mem(buffer, size, kind);
    
    free(buffer);
    
    return id;
}

int dsound_add_mem(char* buffer, int length, int kind) {
    int id = dsound_get_free_resource();
    ASSERT(id);
    
    LPDIRECTSOUNDBUFFER secbuffer;
    int samplerate, channels, bits;
    uint32_t data_length;
    char* data;
    
    //find file type from magic number
    if (memcmp("RIF",buffer,3)==0) {
        //read wav properties
            RiffWaveFmt* format = (RiffWaveFmt*)buffer;
        
            samplerate = format->SampleRate;
            channels = format->Channels;
            bits = format->BitsPerSample;
        
        //navigate wav blocks until we get to the data block
            data = (char*)(buffer + 16);
            data_length = format->FormatLength;
            do {        
                data += data_length + 8;
                data_length = *(uint32_t*)(data);
            } while (memcmp("data", data - 4, 4) != 0 && data-buffer < length - 16);
            data += 4;            
    } else if (memcmp("Ogg",buffer,3)==0) {
        //read ogg
    } else if (memcmp("ID3",buffer,3)==0) {
        //read mp3
    } else {
        //unrecognized file type
        return ERROR_FAIL_LOAD;
    }
    
    //debug_message(L"sample rate %i",samplerate);
    //debug_message(L"channels %i",channels);
    //debug_message(L"bits %i",bits);        
    //debug_message(L"data length %i",data_length);
    
    //create the secondary buffer and fill it with pcm data
        vibe_check(Device->CreateSoundBuffer(
            describe_buffer(
                DSBCAPS_GLOBALFOCUS | DSBCAPS_GETCURRENTPOSITION2 | DSBCAPS_CTRLPAN | DSBCAPS_CTRLVOLUME | DSBCAPS_CTRLFREQUENCY,
                describe_format(samplerate, channels, bits),
                data_length
            ),
            &secbuffer,
            NULL
        ));
        
        void* lock_chunk;
        DWORD lock_size;
        vibe_check(secbuffer->Lock(
            0, data_length,
            &lock_chunk, &lock_size,
            NULL, NULL, 0
        ));
        
        memcpy(lock_chunk, data, lock_size);
        
        vibe_check(secbuffer->Unlock(
            lock_chunk, lock_size,
            NULL, NULL
        ));
    
    //create the sound resource
        SoundResource* sound = &sound_resources[id];    
        sound->buffer = secbuffer;
        sound->kind = kind;
        sound->exists = true;
        sound->loaded = true;
        sound->persistent = false;
        sound->frequency = samplerate;
        sound->volume = 1.0;
        sound->pan = 0.0;
        sound->pitch = 1.0;
        sound->loop_a = 0;
        sound->loop_b = 0;
        sound->inst_count = 0;
    
    return id;
}

LONG dsound_volume_formula(double vol) {
    //decode log volume used by directsound
    return (LONG)(3333.3 * log10(max(0.001,min(1.0,vol))));
}

LONG dsound_pan_formula(double pan) {
    //decode log volume used by directsound
    if (pan>=0) return (LONG)(-3333.3 * log10(max(0.001,min(1.0,1.0-pan))));
    else return (LONG)(3333.3 * log10(max(0.001,min(1.0,1.0+pan))));
}

int dsound_play(int index, bool loop, double vol, double pan, double pitch) {
    SoundResource* sound = &sound_resources[index];
    if (!sound->exists) return ERROR_NON_EXIST;
    
    LPDIRECTSOUNDBUFFER clone;
    vibe_check(Device->DuplicateSoundBuffer(sound->buffer, &clone));
    
    double volume_final = sound->volume * vol * global_volume;
    double pan_final = sound->pan + pan;
    double pitch_final = sound->pitch * pitch;
    
    clone->SetVolume(dsound_volume_formula(volume_final));
    clone->SetPan(dsound_pan_formula(pan_final));
    clone->SetFrequency((DWORD)(pitch_final * sound->frequency));

    int kind = sound->kind;
    SoundInstance* inst = &sound_instances[kind][dsound_get_free_instance(kind)];
    
    inst->sound = sound;
    inst->clone_buffer = clone;
    inst->index = last_instance_id;
    inst->volume = volume_final;
    inst->pan = pan_final;
    inst->pitch = pitch_final;
    inst->volume_from = volume_final;
    inst->volume_to = volume_final;
    inst->fade_length = 0;
    inst->fade_amount = 0;
    inst->age = 0;
    inst->exists = true;
    inst->playing = true;
    inst->looping = loop;
    
    sound->inst_count++;
    
    last_instance_id++;
    
    if (loop) {
        vibe_check(clone->Play(0, 0, DSBPLAY_LOOPING));
    } else {
        vibe_check(clone->Play(0, 0, 0));
    }
    
    return last_instance_id;
}

bool dsound_find_instance_from_iid(int iid, int* get_kind, int* get_index,SoundInstance* get_inst) {
    *get_kind = ERROR_NON_EXIST;
    *get_index = ERROR_NON_EXIST;
    
    SoundInstance* inst;
    
    REPEAT(kind, 4) REPEAT(i, INSTANCE_COUNT) {
        inst = &sound_instances[kind][i];
        if (inst->exists && inst->index == iid) {
            *get_kind = kind;
            *get_index = i;
            get_inst = inst;
            return true;
        }
    }
    
    return false;
}

void dsound_set_global_volume(double vol) {
    global_volume = min(1.0,max(0.0,vol));
}

void dsound_stop_inst(int iid) {
    int kind,index;
    SoundInstance* inst = NULL;
    
    if (dsound_find_instance_from_iid(iid, &kind, &index, inst)) {
        dsound_inst_free(inst);
    }
}

void dsound_inst_free(SoundInstance* inst) {
    if (inst->exists) {
        inst->sound->inst_count--;
        inst->clone_buffer->Stop();
        inst->clone_buffer->Release();
        inst->exists = false;
    }
}


//---------------------------------------------------------------------------//