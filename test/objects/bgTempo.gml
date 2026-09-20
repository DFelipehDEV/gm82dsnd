#define Create_0
/*"/*'/**//* YYD ACTION
lib_id=1
action_id=603
applies_to=self
*/
image_xscale=200/32

tempo=1
#define Mouse_0
/*"/*'/**//* YYD ACTION
lib_id=1
action_id=603
applies_to=self
*/
tempo=(mouse_x-x)/100
sound_background_tempo(tempo)
#define Draw_0
/*"/*'/**//* YYD ACTION
lib_id=1
action_id=603
applies_to=self
*/
draw_self()

draw_set_color(0)
draw_text(x,y,"bg tempo: "+string(tempo))
