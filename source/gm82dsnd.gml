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
  
  - vanilla api
    - sound_fade
    - sound_stop_all
    - sound_delete
    - sound_discard
    - sound_replace
    - sound_restore
    - sound_background_tempo
    - sound_effect_*
    - sound_3d_*
  
  - extended api
    - sound_get_instance_count
    - sound_add_raw
    - sound_add_buffer
    - sound_add_buffer_raw
    - sound_add_directory
    - sound_get_instance_list
    - sound_get_frequency
    - sound_get_length
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
    
    __dsound_error[1]="Generic DirectSound error. Please tell renex about this error."
    __dsound_error[2]="Non-existing sound or instance index."
    __dsound_error[3]="Failure loading sound data from file or buffer."
    __dsound_error[4]="No more space to add sounds (100000 sounds). Check if you have a memory leak, otherwise if this is intentionally happening due to external asset loading, please enable dsound_reuse_sound_ids using sound_settings."
    
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
//shims


#define sound_add
    ///sound_add(fname,kind,preload)
    
    var __index,__name;
    
    if (!file_exists(argument0)) {
        show_error("8.2 DirectSound error: "+chr(13)+chr(10)+"in function sound_add: file ("+string(argument0)+") doesn't exist.",0)
        return noone
    }
    
    if (argument1<0 or argument1>7) {
        show_error("8.2 DirectSound error: "+chr(13)+chr(10)+"in function sound_add: invalid kind ("+string(argument1)+").",0)
        return noone
    }
    
    if (__dsound_search_dir!="")
        __index=__dsound_add_file(__dsound_search_dir+argument0,argument1)
    else
        __index=__dsound_add_file(argument0,argument1)
    
    if (__index<0) {
        show_error("8.2 DirectSound error: "+chr(13)+chr(10)+__dsound_error[-__index],false)
        return noone
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
    
    return __dsound_getter(__dsound_name_parser(argument0,"sound_get_kind"),4)


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
    
    return __dsound_getter(__dsound_name_parser(argument0,"sound_get_preload"),3)


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
    
    __dsound_setter(__dsound_name_parser(argument0,"sound_volume"),0,argument1)


#define sound_pan
    ///sound_pan(index,value)
    
    __dsound_setter(__dsound_name_parser(argument0,"sound_pan"),1,argument1)


#define sound_fade
    ///sound_fade(index,value,time)
    

#define sound_stop
    ///sound_stop(index)
    
    __dsound_stop(__dsound_name_parser(argument0,"sound_stop"))

    
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


#define sound_settings
    ///sound_settings(setting,value)
    //Changes extension configuration. All settings are on by default. Turning all settings off emulates vanilla Game Maker behavior.
    //dsound_use_linear_volume - Game Maker's volume scale is a logarithmic attenuation value, from 30 to 100, where half loudness is somewhere around 85, and 60 is inaudible. Our extension instead uses a more intuitive linear volume scale where 50 is half as loud, and 0 is inaudible. If your project uses logarithmic volume, you can disable this option to restore the vanilla volume scale. Note that the volume value from the slider in the sound resource window is always logarithmic.
    //dsound_use_scheduler - Game maker sound functions act immediately upon call. Sometimes this is undesirable, such as when you want to play a sound and then immediately change the settings for it somewhere else within the same frame - if your game is laggy, you could hear a spike as the sound plays at full volume for a very short period of time. In order to mitigate this, our extension uses a system where newly played sounds and changes to sound instances are only executed once per step, in a way where sound operations are more consistent and predictable. Turning this option off will instead apply sound operations immediately.
    //dsound_reuse_sound_ids - Normally, Game Maker assigns incrementing ids to newly added sounds, but this means you will eventually run out of space for sounds at 100000 where our extension's instance ids start. Here we provide an option to reuse dead sound indexes for newly added resources. If your code is not designed to handle that, you can disable this option to use incrementing ids only and leave deleted sounds permanently deleted. Additionally, sound resource id 0 is never used.
    
    __dsound_settings(argument0,argument1)


#define sound_add_ext
    ///sound_add_ext(fname,kind,name,vol,pan,pitch,persistent)
    //Adds a sound, and sets its internal name and properties.
    var __snd;
    
    if (!file_exists(argument0)) {
        show_error("8.2 DirectSound error: "+chr(13)+chr(10)+"in function sound_add_ext: file ("+string(argument0)+") doesn't exist.",0)
        return noone
    }
    
    if (argument1<0 or argument1>7) {
        show_error("8.2 DirectSound error: "+chr(13)+chr(10)+"in function sound_add_ext: invalid kind ("+string(argument1)+").",0)
        return noone
    }
    
    __snd=sound_add(argument0,argument1,1)
    
    sound_set_properties(__snd,argument2,argument3,argument4,argument5,argument6)
    
    return __snd
    
    
#define sound_add_included
    ///sound_add_included(fname,kind)
    //Adds a sound from an included file.
    
    var __fname;
    
    if (kind<0 or kind>7) {
        show_error("8.2 DirectSound error: "+chr(13)+chr(10)+"in function sound_add_included: invalid kind ("+string(argument1)+").",0)
        return noone
    }    
    
    __fname=temp_directory+"\gm82\sound\"+argument0
    export_include_file_location(argument0,__fname)
    
    if (!file_exists(__fname)) {
        show_error("8.2 DirectSound error: "+chr(13)+chr(10)+"in function sound_add_included: included file ("+string(argument0)+") failed to export.",0)
        return noone
    }
    
    return sound_add(__fname,argument1,1)


#define sound_add_included_ext
    ///sound_add_included_ext(fname,kind,name,vol,pan,pitch,persistent)
    //Adds a sound from an included file.
    
    var __fname,__snd;
    
    if (kind<0 or kind>7) {
        show_error("8.2 DirectSound error: "+chr(13)+chr(10)+"in function sound_add_included_ext: invalid kind ("+string(argument1)+").",0)
        return noone
    }    
    
    __fname=temp_directory+"\gm82\sound\"+argument0
    export_include_file_location(argument0,__fname)
    
    if (!file_exists(__fname)) {
        show_error("8.2 DirectSound error: "+chr(13)+chr(10)+"in function sound_add_included_ext: included file ("+string(argument0)+") failed to export.",0)
        return noone
    }
    
    __snd=sound_add(__fname,argument1,1)
    
    sound_set_properties(__snd,argument2,argument3,argument4,argument5,argument6)
    
    return __snd


#define sound_add_directory

#define sound_set_properties
    ///sound_set_properties(index,vol,pitch,pan,persistent)
    
    sound_set_name(argument0,argument1)
    sound_volume(argument0,argument2)
    sound_pan(argument0,argument3)
    sound_pitch(argument0,argument4)
    sound_set_persistent(argument0,argument5)


#define sound_set_name
    ///sound_set_name(index,name)
    //index: old sound name, or resource index
    //name: new name to use
    //Renames a sound such that it can be addressed by the new name string.
    
    var __index,__name;
    
    __index=__dsound_name_parser(argument0,"sound_set_name")
    if (__index!=noone) {
        __name=ds_map_find_value(__dsound_rev_map,__index)
        if (ds_map_exists(__dsound_map,string(argument1))) {
            show_error("In function sound_set_name: Trying to rename sound ("+__name+"), but sound name ("+argument1+") already exists.",0)
            exit
        }
        ds_map_delete(__dsound_map,__name)
        ds_map_delete(__dsound_rev_map,__index)
        
        __name=string(argument1)
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


#define sound_background_instance
    ///sound_background_instance()
    //Returns the instance id of the currently playing background music, or noone if there isn't one.
    //If there are multiple layers of music currently active, the function returns the newest one.
    
    return __dsound_getbgid()


#define sound_pitch
    ///sound_pitch(index,value)
    
    __dsound_setter(__dsound_name_parser(argument0,"sound_pitch"),2,argument1)


#define sound_get_frequency
#define sound_get_instance_count
#define sound_get_instance_list
#define sound_get_length

#define sound_get_volume
    ///sound_get_volume(ind)
    
    return __dsound_getter(__dsound_name_parser(argument0,"sound_get_volume"),0)


#define sound_get_pan
    ///sound_get_pan(ind)
    
    return __dsound_getter(__dsound_name_parser(argument0,"sound_get_volume"),1)


#define sound_get_pitch
    ///sound_get_pitch(ind)
    
    return __dsound_getter(__dsound_name_parser(argument0,"sound_get_volume"),2)


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