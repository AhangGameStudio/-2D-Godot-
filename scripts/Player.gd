extends CharacterBody2D

signal update_stats(stats)

const SPEED = 250.0
const RUN_SPEED = 400.0
const JOY_RADIUS = 80.0
const PLAYER_TEXTURE = preload("res://assets/characters/player.png")
const POTION_DRINK_SOUND = preload("res://assets/audio/music/41529_108319-lq.mp3")

const HUNGER_IDLE_DRAIN = 0.030
const THIRST_IDLE_DRAIN = 0.045
const HUNGER_MOVE_DRAIN = 0.025
const THIRST_MOVE_DRAIN = 0.035
const HUNGER_RUN_DRAIN = 0.070
const THIRST_RUN_DRAIN = 0.100
const MAX_INVENTORY_SLOTS = 20
const MANA_RESTORE_DURATION = 3.0
const MANA_POTION_ITEMS = {
	small_mana_potion = {name = "小蓝瓶", icon = "small_mana_potion", quantity = 1, type = "mana_potion", mana_restore = 15.0},
	super_mana_potion = {name = "超圣蓝瓶", icon = "super_mana_potion", quantity = 1, type = "mana_potion", mana_restore = 50.0},
	large_mana_potion = {name = "大蓝瓶", icon = "large_mana_potion", quantity = 1, type = "mana_potion", mana_restore = 35.0},
	medium_mana_potion = {name = "中蓝瓶", icon = "medium_mana_potion", quantity = 1, type = "mana_potion", mana_restore = 20.0}
}

var camera = null
var touch_dir = Vector2.ZERO
var touch_running = false
var joystick_active = false
var joystick_pointer_id = -1
var joystick_start = Vector2.ZERO
var joystick_center = Vector2.ZERO
var joy_knob = null
var joy_knob_origin = Vector2.ZERO
var stats = {
	health = 100.0,
	mana = 50.0,
	hunger = 100.0,
	thirst = 100.0,
	stamina = 100.0
}
var inventory = {
	items = [],
	max_slots = MAX_INVENTORY_SLOTS
}
var active_mana_restores = []
var potion_audio_player = null

func _ready():
	$Sprite2D.texture = PLAYER_TEXTURE
	$Sprite2D.scale = Vector2(2.0, 2.0)
	_create_potion_audio_player()
	_add_test_mana_potions()
	
	var cams = get_tree().get_nodes_in_group("main_camera")
	if cams.size() > 0:
		camera = cams[0]
	
	call_deferred("_create_touch_controls")
	update_stats.emit(stats)

func _create_touch_controls():
	var layer = CanvasLayer.new()
	layer.name = "TouchControls"
	layer.layer = 10
	var vs = get_viewport_rect().size
	
	var pad_tex = preload("res://assets/mobile-controls/Sprites/Style A/Default/joystick_polygon_pad_a.png")
	var nub_tex = preload("res://assets/mobile-controls/Sprites/Style A/Default/joystick_polygon_nub_a.png")
	var btn_tex = preload("res://assets/mobile-controls/Sprites/Style A/Default/button_circle.png")
	var sword_tex = preload("res://assets/mobile-controls/Sprites/Icons/Default/icon_sword.png")
	var hand_tex = preload("res://assets/mobile-controls/Sprites/Icons/Default/icon_hand.png")
	
	var pad_sz = Vector2(130, 130)
	var pad_pos = Vector2(35, vs.y - 165)
	if pad_tex:
		var jbg = TextureRect.new()
		jbg.name = "JoyBg"
		jbg.texture = pad_tex
		jbg.size = pad_sz
		jbg.position = pad_pos
		jbg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		jbg.modulate = Color(1, 1, 1, 0.5)
		jbg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(jbg)
	
	var nub_sz = Vector2(52, 52)
	var center = pad_pos + pad_sz / 2
	joystick_center = center
	joy_knob_origin = center - nub_sz / 2
	if nub_tex:
		joy_knob = TextureRect.new()
		joy_knob.name = "JoyKnob"
		joy_knob.texture = nub_tex
		joy_knob.size = nub_sz
		joy_knob.position = joy_knob_origin
		joy_knob.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		joy_knob.modulate = Color(1, 1, 1, 0.7)
		joy_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(joy_knob)
	
	if btn_tex:
		var atk = TextureButton.new()
		atk.name = "AttackBtn"
		atk.texture_normal = btn_tex
		atk.position = Vector2(vs.x - 130, vs.y - 170)
		atk.size = Vector2(85, 85)
		atk.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		atk.modulate = Color(1, 0.3, 0.3, 0.7)
		atk.pressed.connect(attack)
		layer.add_child(atk)
		if sword_tex:
			var si = TextureRect.new()
			si.texture = sword_tex
			si.position = atk.position + Vector2(18, 18)
			si.size = Vector2(48, 48)
			si.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			si.mouse_filter = Control.MOUSE_FILTER_IGNORE
			layer.add_child(si)
	
	if btn_tex:
		var inte = TextureButton.new()
		inte.name = "InteractBtn"
		inte.texture_normal = btn_tex
		inte.position = Vector2(vs.x - 215, vs.y - 135)
		inte.size = Vector2(75, 75)
		inte.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		inte.modulate = Color(0.3, 0.6, 1.0, 0.7)
		inte.pressed.connect(interact)
		layer.add_child(inte)
		if hand_tex:
			var hi = TextureRect.new()
			hi.texture = hand_tex
			hi.position = inte.position + Vector2(18, 18)
			hi.size = Vector2(40, 40)
			hi.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			hi.mouse_filter = Control.MOUSE_FILTER_IGNORE
			layer.add_child(hi)
	
	get_tree().current_scene.add_child(layer)

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			_start_joystick(event.position, event.index)
		else:
			_stop_joystick(event.index)
	if event is InputEventScreenDrag and joystick_active:
		if joystick_pointer_id == event.index:
			_update_joystick(event.position)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_joystick(event.position, -1)
		else:
			_stop_joystick(-1)
	if event is InputEventMouseMotion and joystick_active and joystick_pointer_id == -1:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_update_joystick(event.position)

func _start_joystick(screen_pos, pointer_id):
	if joystick_center == Vector2.ZERO:
		return
	if screen_pos.distance_to(joystick_center) > JOY_RADIUS * 1.15:
		return
	joystick_start = joystick_center
	joystick_pointer_id = pointer_id
	joystick_active = true
	_update_joystick(screen_pos)

func _update_joystick(screen_pos):
	var delta = screen_pos - joystick_start
	var dist = delta.length()
	if dist > JOY_RADIUS:
		delta = delta.normalized() * JOY_RADIUS
	touch_dir = delta.normalized() if dist > 15 else Vector2.ZERO
	touch_running = dist > JOY_RADIUS * 0.65
	if joy_knob:
		joy_knob.position = joy_knob_origin + delta

func _stop_joystick(pointer_id):
	if pointer_id != joystick_pointer_id:
		return
	joystick_active = false
	joystick_pointer_id = -1
	touch_dir = Vector2.ZERO
	touch_running = false
	if joy_knob:
		joy_knob.position = joy_knob_origin

func _physics_process(delta):
	var dir = Vector2.ZERO
	
	if Input.is_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"):
		dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"):
		dir.x += 1
	if Input.is_key_pressed(KEY_W) or Input.is_action_pressed("ui_up"):
		dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_action_pressed("ui_down"):
		dir.y += 1
	
	if touch_dir.length() > 0:
		dir = touch_dir
	
	var running = false
	if dir.length() > 0:
		dir = dir.normalized()
		running = Input.is_key_pressed(KEY_SHIFT) or touch_running
		velocity = dir * (RUN_SPEED if running else SPEED)
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()
	_update_survival(delta, dir.length() > 0, running)
	_update_mana_restores(delta)
	
	if camera:
		camera.position = position

func _update_survival(delta, is_moving, is_running):
	var hunger_drain = HUNGER_IDLE_DRAIN
	var thirst_drain = THIRST_IDLE_DRAIN
	if is_moving:
		hunger_drain += HUNGER_MOVE_DRAIN
		thirst_drain += THIRST_MOVE_DRAIN
	if is_running:
		hunger_drain += HUNGER_RUN_DRAIN
		thirst_drain += THIRST_RUN_DRAIN
	stats.hunger = max(stats.hunger - hunger_drain * delta, 0.0)
	stats.thirst = max(stats.thirst - thirst_drain * delta, 0.0)
	update_stats.emit(stats)

func _update_mana_restores(delta):
	if active_mana_restores.is_empty():
		return
	for i in range(active_mana_restores.size() - 1, -1, -1):
		var restore = active_mana_restores[i]
		var tick_amount = restore.rate * delta
		stats.mana = min(stats.mana + tick_amount, 100.0)
		restore.remaining -= delta
		active_mana_restores[i] = restore
		if restore.remaining <= 0.0 or stats.mana >= 100.0:
			active_mana_restores.remove_at(i)
	update_stats.emit(stats)

func attack():
	pass

func interact():
	pass

func add_item(item_data):
	for item in inventory.items:
		if item.name == item_data.name:
			item.quantity += item_data.get("quantity", 1)
			return true
	if inventory.items.size() >= inventory.max_slots:
		return false
	var new_item = item_data.duplicate(true)
	new_item.quantity = new_item.get("quantity", 1)
	inventory.items.append(new_item)
	return true

func remove_item(item_name, amount):
	for i in range(inventory.items.size()):
		var item = inventory.items[i]
		if item.name == item_name:
			item.quantity -= amount
			if item.quantity <= 0:
				inventory.items.remove_at(i)
			return true
	return false

func use_item(item_name):
	for item in inventory.items:
		if item.name == item_name:
			if item.get("type", "") == "mana_potion":
				_start_mana_restore(item.get("mana_restore", 0.0))
				_play_potion_drink_sound()
				remove_item(item_name, 1)
				return true
			return false
	return false

func _start_mana_restore(amount):
	if amount <= 0.0:
		return
	active_mana_restores.append({
		remaining = MANA_RESTORE_DURATION,
		rate = amount / MANA_RESTORE_DURATION
	})

func _create_potion_audio_player():
	potion_audio_player = AudioStreamPlayer2D.new()
	potion_audio_player.name = "PotionDrinkSound"
	potion_audio_player.stream = POTION_DRINK_SOUND
	potion_audio_player.volume_db = -10.0
	add_child(potion_audio_player)

func _play_potion_drink_sound():
	if not potion_audio_player:
		return
	potion_audio_player.stop()
	potion_audio_player.play()

func _add_test_mana_potions():
	for key in MANA_POTION_ITEMS:
		var item = MANA_POTION_ITEMS[key].duplicate(true)
		item.quantity = 3
		add_item(item)
