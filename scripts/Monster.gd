extends Area2D

const MONSTER_TEXTURE = preload("res://assets/characters/monster.png")

var monster_type = ""
var health = 100
var max_health = 100
var damage = 10
var speed = 50
var exp_reward = 50

var state = "idle"
var target = null
var attack_cooldown = 0
var wander_timer = 0
var wander_direction = Vector2.ZERO
var velocity = Vector2.ZERO

func _ready():
    $Sprite2D.texture = MONSTER_TEXTURE
    $Sprite2D.modulate = Color.WHITE
    $HealthBar.max_value = max_health
    $HealthBar.value = health
    
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _physics_process(delta):
    update_state(delta)
    
    if state == "chase":
        chase_player(delta)
    elif state == "wander":
        wander(delta)
    
    attack_cooldown -= delta
    position += velocity * delta

func update_state(delta):
    if target:
        var dist = position.distance_to(target.position)
        if dist < 300:
            state = "chase"
        else:
            state = "idle"
    else:
        wander_timer += delta
        if wander_timer > 2:
            wander_timer = 0
            state = "wander"
            wander_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()

func chase_player(delta):
    if target:
        var direction = (target.position - position).normalized()
        velocity = direction * speed
        
        if position.distance_to(target.position) < 30:
            attack()

func wander(delta):
    velocity = wander_direction * speed

func attack():
    if attack_cooldown <= 0:
        attack_cooldown = 1.0
        if target and target.has_method("take_damage"):
            target.take_damage(damage)

func take_damage(amount):
    health -= amount
    $HealthBar.value = health
    
    if health <= 0:
        die()

func die():
    if target and target.has_method("add_experience"):
        target.add_experience(exp_reward)
    queue_free()

func _on_body_entered(body):
    if body.name == "Player":
        target = body
        state = "chase"

func _on_body_exited(body):
    if body.name == "Player":
        target = null
        state = "idle"
