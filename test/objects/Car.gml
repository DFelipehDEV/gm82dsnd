#define Create_0
/*"/*'/**//* YYD ACTION
lib_id=1
action_id=603
applies_to=self
*/
path_start(p3d,16,1,1)
xp=x yp=y
image_speed=0

sound_3d_set_sound_distance(sound1_3d,16,10000)

sound_loop(sound1_3d)
event_step()
#define Step_0
/*"/*'/**//* YYD ACTION
lib_id=1
action_id=603
applies_to=self
*/
sound_3d_set_sound_position(sound1_3d,x-mouse_x,0,y-mouse_y)
sound_3d_set_sound_velocity(sound1_3d,x-xp,0,y-yp)
image_angle=direction
xp=x
yp=y
