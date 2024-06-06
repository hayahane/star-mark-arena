class_name Character extends CharacterBody3D

enum{
	PLAYER_STATE_JUMPING,
	PLAYER_STATE_RUNNING,
	PLAYER_STATE_IDLING,
	PLAYER_STATE_ATTACK,
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
@export_range(0,10,1) var max_hp := 5
var current_hp := 5:
	set(value):
		var v = clamp(value,0,max_hp)
		hp_changed.emit(current_hp, v)
		current_hp = v

signal hp_changed(old: int, new: int)


func _enter_tree() -> void:
	set_multiplayer_authority(str(self.name).to_int())
	

func _ready() -> void:
	var gm := get_parent() as GameManager
	gm._player_count += 1
	cape_color = gm.colors[gm._player_count]
	character_cape.material_override = _cape_mat
	anim_player.play("Idle")
	if is_multiplayer_authority():
		cam.cam.current = true


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
	if Input.is_action_just_pressed("attack") and is_on_floor():
		attack.rpc()
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
	if _player_state == PLAYER_STATE_ATTACK:
		return
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


@rpc("call_local")
func attack() -> void:
	anim_player.speed_scale = 1
	_player_state = PLAYER_STATE_ATTACK
	anim_player.play("1H_Melee_Attack_Chop")
	anim_player.queue("Idle")


func _on_animation_player_animation_changed(old_name: StringName, new_name: StringName) -> void:
	if old_name == "1H_Melee_Attack_Chop":
		_player_state = PLAYER_STATE_IDLING


var _target: Character

func _on_area_3d_body_entered(body: Node3D) -> void:
	_target = body as Character
	if _target and _target != self and _player_state == PLAYER_STATE_ATTACK:
		_target.on_attack.rpc(1)

@rpc("call_local")
func on_attack(damage: int) -> void:
	current_hp -= damage
	print(name, " attacked")
