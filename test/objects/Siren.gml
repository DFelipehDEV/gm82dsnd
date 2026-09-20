#define Create_0
/*"/*'/**//* YYD ACTION
lib_id=1
action_id=603
applies_to=self
*/
snd=sound_add("folder\compressed sound effect.ogg",2,1)
sound_3d_set_sound_distance(snd,1,500)
sound_loop(snd)
event_step()
#define Step_0
/*"/*'/**//* YYD ACTION
lib_id=1
action_id=603
applies_to=self
*/
sound_3d_set_sound_position(snd,x-mouse_x,0,y-mouse_y)
