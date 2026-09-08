#define __gm82dsound_gml_init
    globalvar __gm82dsound_version; __gm82dsound_version=010
    
    object_event_add(gm82core_object,ev_create,0,"__dsound_init(window_handle())")
    object_event_add(gm82core_object,ev_step,ev_step_end,"__dsound_update(1000/room_speed)")


#define sound_add
    ///sound_add(fname,kind,preload)
    return __dsound_add_file(argument0,argument1)


#define sound_background_tempo
    ///sound_background_tempo(factor)
    
#define sound_delete
    ///sound_delete(index)
    
#define sound_discard
    ///sound_discard(index)
    
#define sound_exists
    ///sound_exists(ind)
    
#define sound_fade
    ///sound_fade(index,value,time)
    
#define sound_get_kind
    ///sound_get_kind(ind)
    
#define sound_get_name
    ///sound_get_name(ind)
    
#define sound_get_preload
    ///sound_get_preload(ind)
    
#define sound_global_volume
    ///sound_global_volume(value)
    
#define sound_isplaying
    ///sound_isplaying(index)
    
#define sound_loop
    ///sound_loop(index)
    
    __dsound_play(argument0,1,1,0,0)
    
#define sound_pan
    ///sound_pan(index,value)
    
#define sound_play
    ///sound_play(index)
    
    __dsound_play(argument0,0,1,0,0)
    
#define sound_replace
    ///sound_replace(index,fname,kind,preload)
    
#define sound_restore
    ///sound_restore(index)
    
#define sound_set_search_directory
    ///sound_set_search_directory(dir)
    
#define sound_stop
    ///sound_stop(index)
    
#define sound_stop_all
    ///sound_stop_all()
    
#define sound_volume
    ///sound_volume(index,value)

#define sound_pitch
#define sound_get_pos
#define sound_set_pos
#define sound_set_loop


#define sound_effect_chorus
#define sound_effect_compressor
#define sound_effect_echo
#define sound_effect_equalizer
#define sound_effect_flanger
#define sound_effect_gargle
#define sound_effect_reverb
#define sound_effect_set

#define sound_3d_set_sound_cone
#define sound_3d_set_sound_distance
#define sound_3d_set_sound_position
#define sound_3d_set_sound_velocity
//
//