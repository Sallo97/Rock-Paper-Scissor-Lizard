extends CharacterBody3D
class_name Lizard

#------------NODES---------------------------------
@onready var lizard_node : Node3D = get_node("Pivot/lizard")
@onready var body_node : MeshInstance3D = lizard_node.get_node("Body")
@onready var lips_node : MeshInstance3D = lizard_node.get_node("Lips")
@onready var ribbon_node : MeshInstance3D = lizard_node.get_node("Ribbon")

#--------VARIABLES--------------------------------

var sex: Constants.Sex
var morph:Constants.Morph
var size : int
var falling: bool = true
var alleles

#---------CONSTRUCTORS-------------------------
func _init(prob_sex:float = 0.5, prob_orange:float = 0.5,
		   prob_yellow:float = 0.5, prob_blue:float = 0.5):
	sex = randomSex(prob_sex)
	morph = randomMorph(sex, prob_orange,
						prob_blue,prob_yellow)
	alleles = Constants.set_random_alleles(morph,prob_orange,
								 prob_blue, prob_yellow)
	main_settings()

func _init_static(new_sex:Constants.Sex, new_morph:Constants.Morph):
	sex = new_sex
	morph = new_morph
	alleles = Constants.set_random_alleles(morph)
	main_settings()
	
func _init_child(papa:Lizard, mama:Lizard):
	sex = randomSex()
	alleles = Constants.set_alleles(papa.alleles, mama.alleles)
	morph = Constants.Alleles_Comb.ret_morph(alleles)
	main_settings()
	

func main_settings():
	male_mesh()
	set_body_color()
	set_lizard_size()
	change_velocity_state()
	self.add_to_group("Lizards")

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
	var is_yellow:bool = randf() <= yw_prob 
	var is_blue:bool
	if sex == Constants.Sex.MALE:
		is_blue = randf() <= bl_prob
	else:
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

#--------------MODIFY MESH FUNC------------

# This function sets the color of the body 
# ONLY on THIS instance of the lizard
func set_body_color():
	var material = StandardMaterial3D.new()
	material.albedo_color = Constants.Color_Values.ret_color(morph)
	body_node.material_override = material

# This function sets the size of the ONLY
# THIS instance of the lizard
func set_lizard_size():
	var scale_value : float = float(size) / float(Constants.min_size) # 1 : 20 = scale_value : size 
	lizard_node.global_scale( Vector3(scale_value,scale_value,scale_value) )

# This function removes the ribbon and the lips from the mesh
# if the current lizard is male
func male_mesh():
	if (sex == Constants.Sex.MALE) :
		lips_node.hide()
		ribbon_node.hide()

#------------INITIALIZE FUNC----------------------------------------
func initialize(other_lizard:Lizard = null):
	if other_lizard == null:
		rotate_y(randf_range(-2 * PI, 2 * PI))
	else:
		look_at_from_position(self.position, other_lizard.position, Vector3.UP)
	

#---------------API FUNC-------------------------------
	

func _process(delta: float) -> void:
	var raycast = %RayCast3D
	if falling and raycast.is_colliding():
		falling = false
		change_velocity_state()
		
func change_velocity_state():
	if falling == true:
		velocity.x = 0
		velocity.z = 0
	else:
		velocity = Vector3.FORWARD * randi_range(Constants.min_speed, Constants.max_speed)
		velocity = velocity.rotated(Vector3.UP, rotation.y)

func _on_area_3d_body_entered(body):
	if(body != self and body.is_in_group("Lizards")):
		%LizardInteracting.start_interaction(self, body)
		

func _physics_process(delta):
	if not is_on_floor():
		velocity.y = velocity.y - (Constants.fall_acceleration * delta)
		
	move_and_slide()
