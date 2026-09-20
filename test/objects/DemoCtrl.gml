#define Create_0
/*"/*'/**//* YYD ACTION
lib_id=1
action_id=603
applies_to=self
*/
image_speed=0
#define Mouse_4
/*"/*'/**//* YYD ACTION
lib_id=1
action_id=603
applies_to=self
*/
inst=sound_play(sound0_uncompressed)
#define Draw_0
/*"/*'/**//* YYD ACTION
lib_id=1
action_id=603
applies_to=self
*/
/*str=""

str+="sound name: "+sound_get_name(mus1)

str+="##sound length: "+string(sound_get_length(mus1))

str+="##sound position:#    unit: "+string(sound_get_pos(inst))+"#    secs: "+string(sound_get_pos(inst,unit_seconds))+"#    samp: "+string(sound_get_pos(inst,unit_samples))

draw_text(10,10,str)

image_index=sound_isplaying(sfx2)
               */
draw_self()
