extends Area2D

@export var damage = 3
@export var growth_time = 0.1 #Time for the laser to appear

const remain_time = 0.4 #Time laser remains between the grow tween and shrink tween

@onready var laser: Line2D = $Line2D #combining two LIne2D's to get a stronger laser
@onready var laser_width = laser.width
@onready var laser2: Line2D = $Line2D2
@onready var laser_width2 = laser2.width
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var speed = 4500 
var direction: Vector2
var target_position: Vector2 # uses a target to track position instead of angle 
var laser_finished = false
var ready_to_fire = false
var tween_start: Tween # tween grow
var tween_end: Tween # tween shrink
var tween_flash: Tween #flash of light on enemy hit
var flicker_strength := 0.5  
var terrain: TerrainGrid
# chain upgrade
var chain := 0
# chain starting point
var target_enemy := 0
const CHAIN_RANGE := 140.0 # how far chain can reach
const CHAIN_DAMAGE_FACTOR := 0.75 # each jump does 75% of the previous hit
const CHAIN_DELAY := 0.06 # seconds between jumps


func _ready() -> void:
	terrain = get_tree().get_first_node_in_group("terrain") as TerrainGrid
	
func setup(startpos, endpos):
	global_position = startpos
	
	collision_shape.shape = SegmentShape2D.new()
	collision_shape.shape.a = Vector2.ZERO
	collision_shape.shape.b = Vector2.ZERO
	
	target_position = to_local(endpos)
	direction = target_position.normalized()
	ready_to_fire = true
	
func _process(delta: float) -> void:
	if not ready_to_fire or laser_finished:
		return
		
	var segment := collision_shape.shape as SegmentShape2D
	var tip:= global_position + segment.b
	var move = direction * speed * delta
	
	if terrain:
		var blocked := terrain.segment_blocked(tip, tip + move)
		var out_of_bounds := not terrain.world_rect().grow(300.0).has_point(tip)
		if blocked or out_of_bounds:
			target_position = segment.b
			laser_finished = true
			_vanish_soon()
			return
	
	segment.b += move
 
	if segment.b.distance_to(target_position) <= speed * delta:
		segment.b = target_position
		laser_finished = true
		disappear_tween()
		_vanish_soon()
 
	var line_points := PackedVector2Array([segment.a, segment.b])
	laser.points = line_points
	laser2.points = line_points
	
	#var b := randf_range(1.0 - flicker_strength, 1.0 + flicker_strength)
	#laser.modulate = Color(b, b, b, 1.0)
	#laser2.modulate = Color(b, b, b, 1.0)
	
	start_tween()
	
func fire_sparks() -> void:
	$Sparks.position = target_position
	$Sparks.emitting = true
	
func fire_light() -> void:
	$LightFlash.position = target_position
	tween_flash = create_tween()
	$LightFlash.energy = 50
	tween_flash.tween_property($LightFlash,"energy",0.0,0.1)
	
func start_tween() -> void:
	if tween_start:
		tween_start.kill()
	tween_start = create_tween()
	tween_start.tween_property(laser, "width", laser_width, growth_time*0.5).from(0.0)
	tween_start.tween_property(laser2, "width", laser_width2, growth_time*0.5).from(0.0)
	
func disappear_tween() -> void:
	if tween_end:
		tween_end.kill()
	tween_end = create_tween()
	tween_end.tween_property(laser, "width",0.0, growth_time)
	tween_end.tween_property(laser2, "width",0.0, growth_time)
	
func _vanish_soon() -> void:
	fire_light()
	fire_sparks()
	
	await get_tree().create_timer(remain_time).timeout
	collision_shape.set_deferred("disabled", true)

	queue_free()

func finish(t: Tween) -> void:
	if t and t.is_running():
		await t.finished
