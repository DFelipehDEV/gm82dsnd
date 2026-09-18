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

  Todo
  ----
  
  - implement functions:
    - sound_get_preload
    - sound_volume
    - sound_pan
    - sound_fade
    - sound_stop
    - sound_stop_all
    - sound_delete
    - sound_discard
    - sound_replace
    - sound_restore
    - sound_pitch
    - sound_add_directory
    - sound_add_included
    - sound_get_voices
    - sound_get_frequency
    - sound_get_instance_list
    - sound_get_length
    - sound_get_pan
    - sound_get_pitch
    - sound_get_volume
    - sound_get_pos
    - sound_set_pos
    - sound_set_loop
    - sound_pause_all
    - sound_resume_all
    - sound_background_layer
    - sound_kind_instance_list
    - sound_kind_...
  
*/
//---------------------------------------------------------------------------//
//internals


#define __gm82dsound_gml_init
    globalvar __gm82dsound_version; __gm82dsound_version=010
    
    object_event_add(gm82core_object,ev_step,ev_step_end,"__dsound_update(1000/room_speed)")
    object_event_add(gm82core_object,ev_other,ev_room_end,"__dsound_roomend()")
    
    globalvar __dsound_error,__dsound_map,__dsound_rev_map,__dsound_prs_map,__dsound_search_dir;
    
    __dsound_error[1]="Generic DirectSound error."
    __dsound_error[2]="Non-existing index."
    __dsound_error[3]="Failure loading sound."
    __dsound_error[4]="No more space to add sounds. You may have a memory leak."
    
    __dsound_map=ds_map_create()
    __dsound_rev_map=ds_map_create()
    __dsound_prs_map=ds_map_create()
    __dsound_search_dir=""


#define __dsound_roomend
    //stop all non-persistent instances
    __dsound_stop_nonpersist()


#define __dsound_name_parser
    //(index,funcname)
    //converts a string name to sound index,
    //for "filename" sound id support à la 8.2 Sound
    
    if (is_string(argument0)) {
        if (ds_map_exists(__dsound_map,argument0)) return ds_map_find_value(__dsound_map,argument0)
        show_error("In function "+argument1+": Sound name ("+argument0+") doesn't exist.",0)
        return noone
    }
    
    if (!sound_exists(argument0)) show_error("In function "+argument1+": Sound index ("+string(argument0)+") doesn't exist.",0)
    return argument0


#define __dsound_error_effects
    //show_error("8.2 DirectSound error: Effects are not currently available.",false)


//---------------------------------------------------------------------------//
//sound shims


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
    
    if (is_string(argument0)) {
        return ds_map_exists(__dsound_map,argument0)
    }
    return __dsound_exists(argument0)


#define sound_get_kind
    ///sound_get_kind(ind)  
    
    return __dsound_getkind(__dsound_name_parser(argument0,"sound_get_kind"))


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


#define sound_global_volume
    ///sound_global_volume(value)
    
    __dsound_glob_vol(argument0)


#define sound_loop
    ///sound_loop(index)
    
    __dsound_play(__dsound_name_parser(argument0,"sound_loop"),1,1,0,1,0)


#define sound_play
    ///sound_play(index)   
    
    __dsound_play(__dsound_name_parser(argument0,"sound_play"),0,1,0,1,0)


#define sound_isplaying
    ///sound_isplaying(index)
    
    return __dsound_insts(__dsound_name_parser(argument0,"sound_isplaying"))


#define sound_volume
    ///sound_volume(index,value)


#define sound_pan
    ///sound_pan(index,value)
    

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


//---------------------------------------------------------------------------//
//new api


#define sound_set_name
    ///sound_set_name(index,name)
    //index: old sound name, or resource index
    //name: new name to use
    //Renames a sound such that it can be addressed by the new name string.
    
    var __index,__name;
    
    __index=__dsound_name_parser(argument0,"sound_set_name")
    if (__index!=noone) {
        __name=ds_map_find_value(__dsound_rev_map,__index)
        if (ds_map_exists(__dsound_map,argument1)) {
            show_error("In function sound_set_name: Trying to rename sound ("+__name+"), but sound name ("+argument1+") already exists.",0)
            exit
        }
        ds_map_delete(__dsound_map,__name)
        ds_map_delete(__dsound_rev_map,__index)
        
        __name=argument1
        ds_map_add(__dsound_map,__name,__index)
        ds_map_add(__dsound_rev_map,__index,__name)
    }
    

#define sound_set_persistent
    ///sound_set_persistent(index,persistent)
    
    var __index;
    __index=__dsound_name_parser(argument0,"sound_set_persistent")
    if (__index!=noone) {
        ds_map_set(__dsound_prs_map,__index,!!argument1)
    }

#define sound_loop_ext
    ///sound_loop_ext(index,vol,pan,pitch,paused)
    
    __dsound_play(__dsound_name_parser(argument0,"sound_loop_ext"),1,argument1,argument2,argument3,argument4)


#define sound_play_ext
    ///sound_play_ext(index,vol,pan,pitch,paused)  
    
    __dsound_play(__dsound_name_parser(argument0,"sound_play_ext"),0,argument1,argument2,argument3,argument4)


#define sound_play_single
    ///sound_play_single(index)
    //Plays a sound, ensuring only one copy of it is playing at a time.
    
    sound_stop(argument0)
    sound_play(argument0)
    
    
#define sound_loop_single
    ///sound_loop_single(index)
    //Loops a sound, ensuring only one copy of it is playing at a time.
    
    sound_stop(argument0)
    sound_loop(argument0)


#define sound_pitch
    ///sound_pitch(index,value)


#define sound_add_directory
#define sound_add_included

#define sound_background_instance
    ///sound_background_instance()
    //Returns the instance id of the currently playing background music, or noone if there isn't one.
    //If there are multiple layers of music currently active, the function returns the newest one.
    
    return __dsound_getbgid()


#define sound_get_frequency
#define sound_get_instance_count
#define sound_get_instance_list
#define sound_get_length
#define sound_get_pan
#define sound_get_pitch
#define sound_get_volume
#define sound_get_pos
    ///sound_get_pos(index)
    
#define sound_set_pos
    ///sound_set_pos(index,pos)
    
#define sound_set_loop
    ///sound_set_loop(index,a,b,[unit])

#define sound_pause
    ///sound_pause(index)
    //Pauses a sound instance. If a sound index is passed, all instances of the sound will be paused.
    __dsound_setpause(__dsound_name_parser(argument0,"sound_pause"),1)


#define sound_resume
    ///sound_resume(index)
    //Resumes a sound instance. If a sound index is passed, all instances of the sound will be resumed.
    __dsound_setpause(__dsound_name_parser(argument0,"sound_resume"),0)


#define sound_pause_all
#define sound_resume_all
//
//