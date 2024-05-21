extends CharacterBody3D
class_name Lizard

#-------------SCRIPTS-----------------------------


#------------NODES---------------------------------
@onready var lizard_node : Node3D = get_node("Pivot/lizard")
@onready var animation_tree : AnimationTree = $AnimationTree

#-------------MESH NODES--------------------------
@onready var adult_lizard_mesh : MultiMeshInstance3D = %adult_lizard
@onready var baby_lizard_mesh : MultiMeshInstance3D = %baby_lizard

@onready var adult_body_node : MeshInstance3D = lizard_node.get_node("adult_lizard/Body")
@onready var adult_lips_node : MeshInstance3D = lizard_node.get_node("adult_lizard/Lips")
@onready var adult_ribbon_node : MeshInstance3D = lizard_node.get_node("adult_lizard/Ribbon")

@onready var baby_body_node : MeshInstance3D = %baby_lizard/Body
@onready var baby_lips_node : MeshInstance3D = %baby_lizard/Pacifier
@onready var baby_ribbon_node : MeshInstance3D = %baby_lizard/Ribbon

#--------VARIABLES--------------------------------

var sex: Constants.Sex = Constants.Sex.MALE
var morph:Constants.Morph = Constants.Morph.ORANGE
var size : int = Constants.min_size
var alleles = [Constants.Allele.O, Constants.Allele.O]
var current_territories: Array[Territory] = []
var cell_change_timer: Timer
var speed:float
var higher_point
var direction 
#------------FLAGS-------------------------------
var is_adult:bool = true 
var falling: bool = true
var found_territory: bool = false
var is_stopped: bool = false
var pattern_step: int = 1
#-------------TIMER VARIABLES---------------------
var death_timer:Timer
var lifetime: float
var grow_up_timer:Timer
var grow_up_time:float

#---------CONSTRUCTORS-------------------------
func set_lizard_prob(prob_sex:float = 0.5, prob_orange:float = 1/3.0,
		   prob_yellow:float = 1/3.0, prob_blue:float = 1/3.0):
	sex = randomSex(prob_sex)
	morph = randomMorph(sex, prob_orange,
						prob_blue, prob_yellow)
	if sex==Constants.Sex.MALE:
		morph = Constants.Morph.BLUE
	else:
		morph = Constants.Morph.YELLOW
	alleles = Constants.set_random_alleles(morph,prob_orange,
								 prob_blue, prob_yellow)
	# print("I arrived here with ", sex, morph, alleles)
	main_settings()

func set_lizard_fixed(new_sex:Constants.Sex, new_morph:Constants.Morph):
	sex = new_sex
	morph = new_morph
	alleles = Constants.set_random_alleles(morph)
	main_settings()
	
func set_lizard_child(papa:Lizard, mama:Lizard):
	sex = randomSex()
	sex = Constants.Sex.FEMALE
	alleles = Constants.set_alleles(sex, papa.alleles, mama.alleles)
	morph = Constants.Alleles_Comb.ret_morph(alleles)
	self.position = ((papa.position + mama.position)/2) + Vector3.UP
	is_adult = false
	set_grow_up_timer()
	main_settings()	

func main_settings():
	floor_constant_speed = true
	floor_max_angle = INF
	set_mesh()
	set_body_color()
	set_lizard_size()
	change_velocity_state()
	update_animation_parameters(0)
	lifetime = randi_range(Constants.min_lifetime, Constants.max_lifetime)
	speed = randi_range(Constants.min_speed, Constants.max_speed)
	set_death_timer()


#---------SETTING FUNC--------------------

# It chooses randomly the sex of the lizard.
# Getting a male or a female is equiprobable
static func randomSex(prob:float = 0.5):
	var is_male : bool = randf() <= prob 
	if is_male:
		return Constants.Sex.MALE
	else:
		return Constants.Sex.FEMALE


# It chooses randomly the morph of the lizard.
# all the colors are equiprobable
static func randomMorph(sex:Constants.Sex, or_prob=0.5,
						bl_prob=0.5, yw_prob=0.5):
	
	# Setting probabilities
	var morph
	var is_orange:bool = randf() <= or_prob
	var is_yellow:bool 
	var is_blue:bool
	if sex == Constants.Sex.MALE:
		is_yellow = randf() <= yw_prob + or_prob 
		is_blue = true
	else:
		is_yellow = true
		is_blue = false
	
	# Returing morph
	if is_orange:
		return Constants.Morph.ORANGE
	elif !is_orange && is_blue:
		return Constants.Morph.BLUE
	elif !is_blue && is_yellow:
		return Constants.Morph.YELLOW

# It chooses randomly the size of the lizard.
# baseSize = [20…30]mm
# size = baseSize + (male ? 10 : 0) + (orange ? 10 : 0))
# size cannot be > 60
static func randomSize(sex:Constants.Sex, morph:Constants.Morph):
	var baseSize : int = randi_range(Constants.min_size, Constants.max_size) 
	if(sex == Constants.Sex.MALE):
		baseSize += 10
	if (morph == Constants.Morph.ORANGE):
		baseSize += 10
	if (baseSize > 60):
		baseSize = 60
	return baseSize
	
func set_death_timer():
	death_timer = Timer.new()
	death_timer.autostart = true
	death_timer.one_shot = true
	death_timer.wait_time = lifetime
	self.add_child(death_timer)
	death_timer.start()
	death_timer.timeout.connect(play_death_animation) 
	
func set_grow_up_timer():
	grow_up_timer = Timer.new()
	grow_up_timer.autostart = true
	grow_up_timer.one_shot = true
	grow_up_time = randf_range(Constants.min_grow_up_timer, Constants.max_grow_up_timer) 
	grow_up_timer.wait_time = grow_up_time
	self.add_child(grow_up_timer)
	grow_up_timer.start()
	grow_up_timer.timeout.connect(becoming_adult)


#--------------MODIFY MESH FUNC------------

# This function sets the color of the body 
# ONLY on THIS instance of the lizard
func set_body_color():
	var material = StandardMaterial3D.new()
	material.albedo_color = Constants.Color_Values.ret_color(morph)
	adult_body_node.material_override = material
	baby_body_node.material_override = material

# This function sets the size of the ONLY
# THIS instance of the lizard
func set_lizard_size():
	var scale_value : float = float(size) / float(Constants.min_size) # 1 : 20 = scale_value : size 
	lizard_node.global_scale( Vector3(scale_value,scale_value,scale_value) )

# This function removes the ribbon and the lips from the mesh
# if the current lizard is male
func set_female_attribute():
	if (sex == Constants.Sex.MALE) :
		adult_lips_node.hide()
		adult_ribbon_node.hide()
		baby_ribbon_node.hide()
		
func set_adult_mesh():
	adult_lizard_mesh.show()
	baby_lizard_mesh.hide()
	
func set_child_mesh():
	baby_lizard_mesh.show()
	adult_lizard_mesh.hide()

func set_mesh():
	if(is_adult):
		set_adult_mesh()
	else:
		set_child_mesh()
	set_female_attribute()
	
func becoming_adult():
	is_adult = true
	remove_from_group("Children")
	add_to_group("Lizards")
	# (func (): print("becoming_adult!    lizard_group size: ", get_tree().get_nodes_in_group("Lizards").size(), ", children_group size: ", get_tree().get_nodes_in_group("Children").size())).call_deferred()
	set_mesh()

#------------INITIALIZE FUNC----------------------------------------
func initialize(other_lizard:Lizard = null):
	if other_lizard == null:
		rotate_y(randf_range(0, 2 * PI))
	else:
		# print("other_lizard.position = ", other_lizard.position)
		look_at_from_position(self.position, other_lizard.position, Vector3.UP)
	

#---------------API FUNC-------------------------------
		
func change_velocity_state():
	if falling == true:
		stop_velocity()
	else:
		normal_velocity()

func _on_area_3d_body_entered(body):
	if(is_adult and body != self and body.is_in_group("Lizards") ): #
		InteractionManager.start_interaction(self, body)

func _physics_process(delta):
	var raycast = %RayCast3D
	if falling and raycast.is_colliding():
		falling = false
		change_velocity_state()
	
	if !Grid.instance().territories.size() == 0:
		movement_pattern()
	
	velocity.y = velocity.y - (Constants.fall_acceleration * delta)
	
	# Clamp velocity to the max allowed velocity to avoid lizards shooting away into the void
	if velocity.length() > Constants.max_velocity:
		velocity = velocity.normalized() * Constants.max_velocity	
	
	
	if is_stopped:
		stop_velocity()
	move_and_slide()
	
func _ready():
	animation_tree.active = true
	
func stop_velocity():
	velocity.x = 0
	velocity.z = 0
	# velocity y = 0

func normal_velocity():
	velocity = Vector3.FORWARD * speed
	velocity = velocity.rotated(Vector3.UP, rotation.y)
	

func on_other_lizard_entered_territory(other: Lizard):
	print_debug(other.morph, " lizard entered ", self.morph, "'s territory")


func on_entered_territory(territory: Territory):
	pass

#-----------ANIMATIONS FUNC-------------------

func update_animation_parameters(animation:int): # 0 = idle
										   # 1 = attacking
										   # 2 = cuddling
										   # 3 = death
	if (animation==0):										
		animation_tree["parameters/conditions/is_idle"] = true
		animation_tree["parameters/conditions/is_attacking"] = false
		animation_tree["parameters/conditions/is_cuddling"] = false
		animation_tree["parameters/conditions/is_dead"] = false
	elif (animation==1):
		animation_tree["parameters/conditions/is_attacking"] = true
		animation_tree["parameters/conditions/is_idle"] = false
		animation_tree["parameters/conditions/is_cuddling"] = false
		animation_tree["parameters/conditions/is_dead"] = false
	
	elif (animation==2):
		animation_tree["parameters/conditions/is_cuddling"] = true
		animation_tree["parameters/conditions/is_idle"] = false
		animation_tree["parameters/conditions/is_attacking"] = false
		animation_tree["parameters/conditions/is_dead"] = false
	
	elif (animation==3):
		animation_tree["parameters/conditions/is_dead"] = true
		animation_tree["parameters/conditions/is_cuddling"] = false
		animation_tree["parameters/conditions/is_idle"] = false
		animation_tree["parameters/conditions/is_attacking"] = false
		
func play_death_animation():
	var animation_timer = Timer.new()
	animation_timer.autostart = true
	animation_timer.one_shot = true
	animation_timer.wait_time = 1
	self.add_child(animation_timer)
	animation_timer.start()
	update_animation_parameters(3)
	animation_timer.timeout.connect(LizardPool.instance().despawn.bind(self)) 


#-------------MOVEMENT FUNC--------------------
# 1 - Dal pt in cui mi trovo determino il punto piu' alto
# 2 - Mi giro nella dirzione di higher_point (delegato a look_at_from_position)
# 3 - Mi muovo verso quella direzione, fermandomi quando arrivo (delegato a arrive_at_point)
# 4 - Impostalo come territorio di quella lucertola
func movement_pattern():
	match (pattern_step):
		0:
			return
		1:
			pattern_step_1()
		2:
			pattern_step_2()
		3:
			pattern_step_3()
		#4:
			
	
	




func pattern_step_1():
	# STEP 1 - Dal pt in cui mi trovo determino il punto piu' alto
	is_stopped = true
	var current_cell = DistanceCalculator.instance().get_cell_at_position(self.position)
	if !DistanceCalculator.instance().is_valid_cell(current_cell):
		return
	var ret_array = DistanceCalculator.instance().max_height_in_circle(current_cell, 5)
	var absolute_position = DistanceCalculator.instance().get_position_of_cell(ret_array[0])

	#print_debug(DistanceCalculator.instance().get_cell_at_position(position))
	#print_debug(DistanceCalculator.instance().get_cell_at_position(DistanceCalculator.instance().get_position_of_cell(DistanceCalculator.instance().get_cell_at_position(position))))

	higher_point = Vector3(absolute_position[0], position.y, absolute_position[2])
	pattern_step = 2
	
func pattern_step_2():
	# STEP 2 - Mi giro nella direzione di higher_point
	look_at_from_position(self.position, higher_point)
	is_stopped = false
	pattern_step = 3
	speed = 20

func pattern_step_3():
	# print("higher_point = ", higher_point)
	# print("self.position = ", self.position)
	# look_at_from_position(self.position, higher_point)
	direction = global_position.direction_to(higher_point)
	velocity = direction * speed
	velocity.y = 0
	velocity += (Vector3.DOWN * velocity.y)
	# STEP 3 - Mi muovo verso higher_point, mi fermo quando lo raggiungo
	# Dentro l'if sarebbe meglio dire che se la distanza tra self.position e' higher point e' 
	# dentro un certo range, si ferma
	if(abs(self.position.x - higher_point.x) < 0.2 || abs(self.position.z - higher_point.z) < 0.2):
		is_stopped = true

	pattern_step = 3
	var timer: Timer = Timer.new()
	timer.autostart = false
	timer.one_shot = false
	timer.wait_time = 0.5
	timer.timeout.connect(func ():
		pattern_step = 1
		timer.queue_free())
	add_child(timer)
	timer.start()
	


