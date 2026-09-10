#define __gm82dsound_gml_init
    globalvar __gm82dsound_version; __gm82dsound_version=010
    
    object_event_add(gm82core_object,ev_step,ev_step_end,"__dsound_update(1000/room_speed)")
    
    globalvar __dsound_error,__dsound_map,__dsound_rev_map,__dsound_search_dir;
    
    __dsound_error[1]="Generic DirectSound error."
    __dsound_error[2]="Non-existing index."
    __dsound_error[3]="Failure loading sound."
    __dsound_error[4]="No more space to add sounds. You may have a memory leak."
    
    __dsound_map=ds_map_create()
    __dsound_rev_map=ds_map_create()
    __dsound_search_dir=""


#define __dsound_name_parser
    //converts a string name to sound index, for "filename" sound id support
    if (is_string(argument0)) {
        if (ds_map_exists(__dsound_map,argument0))
            return ds_map_find_value(__dsound_map,argument0)
        return noone
    }
    return argument0


#define sound_add
    ///sound_add(fname,kind,preload)
    var __index,__name;
    
    if (__dsound_search_dir!="")
        __index=__dsound_add_file(__dsound_search_dir+argument0,argument1)
    else
        __index=__dsound_add_file(argument0,argument1)
    
    if (__index<0) {
        show_error("8.2 DirectSound error: "+chr(13)+chr(10)+__dsound_error[-__index],false)
    } else {
        __name=filename_change_ext(filename_name(argument0),"")
        ds_map_add(__dsound_map,__name,__index)
        ds_map_add(__dsound_rev_map,__index,__name)
    }
    
    return __index


#define sound_background_tempo
    ///sound_background_tempo(factor)
    

#define sound_exists
    ///sound_exists(ind)
    return __dsound_exists(__dsound_name_parser(argument0))


#define sound_get_kind
    ///sound_get_kind(ind)    
    return __dsound_getkind(__dsound_name_parser(argument0))


#define sound_get_name
    ///sound_get_name(ind)
    if (is_string(argument0)) {
        if (ds_map_exists(__dsound_map,argument0))
            return argument0
    } else {
        if (ds_map_exists(__dsound_rev_map,argument0))
            return ds_map_find_value(__dsound_rev_map,argument0)
    }
    return ""


#define sound_get_preload
    ///sound_get_preload(ind)
    

#define sound_get_pos
#define sound_set_pos
#define sound_set_loop
#define sound_set_persistent
    ///sound_set_persistent(index,persistent)

#define sound_global_volume
    ///sound_global_volume(value)
    __dsound_glob_vol(argument0)


#define sound_loop
    ///sound_loop(index)    
    __dsound_play(__dsound_name_parser(argument0),1,1,0,1)


#define sound_loop_ext
    ///sound_loop_ext(index,vol,pan,pitch)    
    __dsound_play(__dsound_name_parser(argument0),1,argument1,argument2,argument3)


#define sound_play
    ///sound_play(index)    
    __dsound_play(__dsound_name_parser(argument0),0,1,0,1)


#define sound_play_ext
    ///sound_play_ext(index,vol,pan,pitch)    
    __dsound_play(__dsound_name_parser(argument0),0,argument1,argument2,argument3)


#define sound_isplaying
    ///sound_isplaying(index)
    return __dsound_insts(__dsound_name_parser(argument0))


#define sound_volume
    ///sound_volume(index,value)


#define sound_pan
    ///sound_pan(index,value)
    

#define sound_pitch


#define sound_fade
    ///sound_fade(index,value,time)
    

#define sound_stop
    ///sound_stop(index)

    
#define sound_stop_all
    ///sound_stop_all()


#define sound_delete
    ///sound_delete(index)
    
#define sound_discard
    ///sound_discard(index)
    
#define sound_replace
    ///sound_replace(index,fname,kind,preload)
    
#define sound_restore
    ///sound_restore(index)
    
#define sound_set_search_directory
    ///sound_set_search_directory(dir)
    __dsound_search_dir=string_replace_all(string(argument0),"/","\")
    if (__dsound_search_dir!="")
        if (!string_ends_with(__dsound_search_dir,"\"))
            __dsound_search_dir+="\"


#define __dsound_error_effects
    show_error("8.2 DirectSound error: Effects are not supported.",false)

#define sound_effect_chorus
    __dsound_error_effects()
#define sound_effect_compressor
    __dsound_error_effects()
#define sound_effect_echo
    __dsound_error_effects()
#define sound_effect_equalizer
    __dsound_error_effects()
#define sound_effect_flanger
    __dsound_error_effects()
#define sound_effect_gargle
    __dsound_error_effects()
#define sound_effect_reverb
    __dsound_error_effects()
#define sound_effect_set
    __dsound_error_effects()

#define sound_3d_set_sound_cone
#define sound_3d_set_sound_distance
#define sound_3d_set_sound_position
#define sound_3d_set_sound_velocity
//
//