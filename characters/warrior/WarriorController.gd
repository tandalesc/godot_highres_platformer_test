extends RigidBody2D

const EPS = 0.000001
const MAX_SPEED_X = 400
const MOVE_ACCELERATION = 5000
const MOVE_ACCELERATION_AIR = 50
const JUMP_ACCELERATION = 120000
const PUSHING_FORCE = 50
const MAX_ATTACK_COMBO = 2

export var hang_time = 0.15

onready var body = $PhysicalBody
onready var hang_timer = $HangTimer
onready var air_timer = $AirTimer
onready var hud = $"../../HUD"

var velocity = Vector2()
var grounded = false
var ground_normal = Vector2.UP
var is_dead = false
var is_attacking = false
var is_hit = false
var attack_combo = 0

func initialize():
	hud.health_bar.value = 100

func attack():
	if !is_attacking:
		is_attacking = true
	if attack_combo == 0:
		body.play_anim('attack1')
	elif attack_combo == 1:
		#queue anim so first attack completes
		body.queue_anim('attack2')
	if attack_combo < MAX_ATTACK_COMBO:
		attack_combo += 1

func stop_attacking():
	is_attacking = false
	attack_combo = 0

func hit(dmg):
	if !is_hit:
		hud.health_bar.value -= dmg
		if hud.health_bar.value > 0:
			is_hit = true
			body.play_anim('hit')
		elif !is_dead:
			die()

func die():
	hud.health_bar.value = 0
	is_dead = true
	body.play_anim('die')

func _process_inputs(state):
	var right_pressed = Input.is_action_pressed('ui_right')
	var left_pressed = Input.is_action_pressed('ui_left')
	var jump_pressed = Input.is_action_pressed('jump')
	var attack_pressed = Input.is_action_just_pressed('attack')
	var h_speed = abs(velocity.x)
	var truly_grounded = grounded and air_timer.is_stopped()
	var hang_time_jump_allowed = air_timer.is_stopped() and not hang_timer.is_stopped()
	#horizontal movement
	if right_pressed and h_speed<MAX_SPEED_X:
		state.apply_central_impulse(Vector2.RIGHT * MOVE_ACCELERATION * state.step)
		if body.is_facing_left(): body.turn_right()
	if left_pressed and h_speed<MAX_SPEED_X:
		state.apply_central_impulse(Vector2.LEFT * MOVE_ACCELERATION * state.step)
		if !body.is_facing_left(): body.turn_left()
	if !right_pressed and !left_pressed and h_speed>1:
		var fixed_vel = Vector2(lerp(velocity.x, 0, 0.12), velocity.y)
		if truly_grounded:
			fixed_vel = Vector2(lerp(velocity.x, 0, 0.05), velocity.y)
		state.set_linear_velocity(fixed_vel)
	#vertical movement (and attacking)
	if truly_grounded or hang_time_jump_allowed:
		if jump_pressed:
			body.play_anim('jump')
			air_timer.start()
			grounded = false
			if not hang_timer.is_stopped():
				hang_timer.stop()
			#jump according to your ground normal
			state.apply_central_impulse(ground_normal * JUMP_ACCELERATION * state.step)
		if attack_pressed:
			attack()
	else:
		if (velocity.y < -EPS and !jump_pressed) or (velocity.y > EPS):
			state.apply_central_impulse(state.get_total_gravity() * mass * state.step)
	#fall off bottom of world
	if global_position.y > 1000:
		die()

func _update_animations():
	if grounded and air_timer.is_stopped():
		if air_timer.is_stopped() and !is_attacking and !is_hit and !is_dead:
			if abs(velocity.x) > 50:
				body.play_anim('run')
			else:
				body.play_anim('idle')
	elif air_timer.is_stopped():
		#fall after reaching peak of jump
		if velocity.y > EPS:
			if is_attacking: stop_attacking()
			if is_hit: is_hit = false
			if !is_dead:
				body.play_anim('fall')

func _process(_delta):
	_update_animations()

func _integrate_forces(state):
	var step = state.step
	var found_floor = false;
	velocity = state.get_linear_velocity()
	if state.get_contact_count()>0:
		#check contact points for collision normal
		for contact in range(state.get_contact_count()):
			var contact_normal = state.get_contact_local_normal(contact)
			if contact_normal.normalized().y < -0.55:
				#align transformation with surface normal
				transform.x = contact_normal.rotated(PI/2)
				transform.y = -contact_normal
				ground_normal = contact_normal
				found_floor = true
	if found_floor and !air_timer.is_stopped():
		#detected collision with floor, but we just left the floor
		found_floor = false
	#if we used to be on the ground, just left, and not due to a jump, start the hang time clock
	if grounded and !found_floor and air_timer.is_stopped() and hang_timer.is_stopped():
		hang_timer.start(hang_time)
	grounded = found_floor
	#only process state inputs if not dead
	if !is_dead: _process_inputs(state)
	state.apply_central_impulse(state.get_total_gravity() * mass * step)
