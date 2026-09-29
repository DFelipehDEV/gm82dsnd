#define Create_0
/*"/*'/**//* YYD ACTION
lib_id=1
action_id=603
applies_to=self
*/
snd=sound_add_included("included file.wav",2)

sound_3d_set_sound_distance(snd,32,10000)
sound_3d_set_sound_cone(snd,1,0,0,45,50,10000)

sound_loop(snd)

image_speed=0.075
#define Step_0
/*"/*'/**//* YYD ACTION
lib_id=1
action_id=603
applies_to=self
*/
sound_3d_set_sound_position(snd,x-mouse_x,0,y-mouse_y)
#define Draw_0
/*"/*'/**//* YYD ACTION
lib_id=1
action_id=603
applies_to=self
*/
draw_circle_color(x,y,100,$ff,background_color,0)

draw_rectangle_color(x-100,y-100,x,y+100,background_color,background_color,background_color,background_color,0)
draw_triangle_color(x,y,x,y+100,x+100,y+100,background_color,background_color,background_color,0)
draw_triangle_color(x,y,x,y-100,x+100,y-100,background_color,background_color,background_color,0)
draw_self()
