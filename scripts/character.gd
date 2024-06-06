class_name Character extends CharacterBody3D

enum{
	PLAYER_STATE_JUMPING,
	PLAYER_STATE_RUNNING,
	PLAYER_STATE_IDLING,
}

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@onready var cam: PlayerCam = $Cam
@onready var anim_player: AnimationPlayer = $CharacterModel/AnimationPlayer
@onready var character_model: Node3D = $CharacterModel
@onready var character_cape: MeshInstance3D = $CharacterModel/Rig/Skeleton3D/Knight_Cape/Knight_Cape
var _cape_mat := StandardMaterial3D.new()
@export var cape_color := Color(.2,.2,.2,1):
	set(value):
		cape_color = value
		_cape_mat.albedo_color = value
var _player_state := PLAYER_STATE_IDLING


func _enter_tree() -> void:
	set_multiplayer_authority(str(self.name).to_int())
	print("Enter Tree: ", name, "  on  ", multiplayer.get_unique_id())
	

func _ready() -> void:
	var gm := get_parent() as GameManager
	gm._player_count += 1
	cape_color = gm.colors[gm._player_count]
	character_cape.material_override = _cape_mat
	anim_player.play("Idle")
	if is_multiplayer_authority():
		cam.cam.current = true
	print("Ready: ", name, "  on  ", multiplayer.get_unique_id(), " pl count: ", gm._player_count)


func _process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	if cam:
		character_model.global_rotation.y = cam.global_rotation.y + deg_to_rad(180)


func _physics_process(delta: float) -> void:		
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	if not is_multiplayer_authority():
		move_and_slide()
		return
	
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := (cam.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	set_anim.rpc(direction, is_on_floor())
	move_and_slide()


@rpc("call_local")
func set_anim(direction: Vector3, is_grounded: bool) -> void:
	if is_grounded:
		if direction.length_squared() <= 0:
			anim_player.speed_scale = 1
			anim_player.play("Idle")
		else:
			anim_player.play("Walking_A")
			anim_player.speed_scale = -1
	else:
		anim_player.play("Jump_Idle")
		anim_player.speed_scale = 1
