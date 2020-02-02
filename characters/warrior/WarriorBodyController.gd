extends Node2D

onready var parent = $'..'
onready var sprite = $AnimatedSprite
onready var warrior_node = load('res://characters/warrior/Warrior.tscn')

var anim_queue = []

func _ready():
	sprite.connect('animation_finished', self, '_on_animation_finished')

func is_facing_left():
	return scale.x==-1

func turn_left():
	scale.x = -1

func turn_right():
	scale.x = 1

func current_anim():
	return sprite.animation

func anim_playing():
	return sprite.playing

func anim_queued():
	return len(anim_queue)>0

#play animation immediately
func play_anim(next_anim):
	if current_anim()!=next_anim:
		sprite.play(next_anim)

#play animation when current one finished (FIFO queue)
func queue_anim(next_anim):
	anim_queue.append(next_anim)

func _on_animation_finished():
	#if animations are in the queue, process those first
	if anim_queued():
		sprite.play(anim_queue.pop_front())
		#play_anim(anim_queue.pop_front())
	else:
		#reset attack animation when finished
		var anim = current_anim()
		if anim=='attack1' or anim=='attack2':
			parent.stop_attacking()
		if anim=='hit':
			parent.is_hit = false
		if anim=='die':
			var new_player = warrior_node.instance()
			parent.get_parent().add_child(new_player)
			new_player.initialize()
			parent.queue_free()
