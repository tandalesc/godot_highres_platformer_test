extends RigidBody2D

export (float, 0, 100) var damage = 10
export (float, 0, 100) var speed = 50

func _ready():
	connect('body_entered', self, 'body_entered')

func body_entered(body):
	if body.has_method('hit'):
		#calculate energy per hit
		var ke1 = mass*linear_velocity.length_squared()
		var ke2 = body.mass*body.linear_velocity.length_squared()
		var energy_per_mass = (ke1 + ke2)/2/mass
		#calculate hit quality
		var projection_score = linear_velocity.length_squared()-linear_velocity.dot(body.linear_velocity)
		#only deal damage if parameters are above thresholds
		if projection_score > 9000 and energy_per_mass > 5000:
			body.hit(damage)
