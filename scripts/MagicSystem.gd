extends Node2D

var magic_types = {
    fire = {name = "火焰", color = Color(1, 0.3, 0), damage = 20, mana_cost = 10},
    ice = {name = "冰霜", color = Color(0.3, 0.6, 1), damage = 15, mana_cost = 12, slow_effect = true},
    lightning = {name = "雷电", color = Color(1, 1, 0), damage = 25, mana_cost = 15, stun_effect = true},
    wind = {name = "疾风", color = Color(0.8, 0.9, 1), damage = 10, mana_cost = 5, knockback = true},
    earth = {name = "岩石", color = Color(0.6, 0.5, 0.4), damage = 18, mana_cost = 12, defense_up = true}
}

var player = null
var current_magic = "fire"

func _ready():
    player = get_parent().get_node("Player")
    cast_magic_signal.connect(_on_cast_magic)

signal cast_magic_signal(magic_type)

func cast_magic(magic_type):
    if magic_type in magic_types:
        var magic = magic_types[magic_type]
        if player.stats.mana >= magic.mana_cost:
            player.stats.mana -= magic.mana_cost
            var projectile = MagicProjectile.new()
            projectile.set_magic(magic, player.position, get_global_mouse_position())
            get_parent().get_node("World").add_child(projectile)
            player.add_experience(5)
            emit_signal("cast_magic_signal", magic_type)
            return true
    return false

func _on_cast_magic(magic_type):
    print("Magic cast: ", magic_type)

class MagicProjectile extends Area2D:
    var magic = null
    var speed = 500
    var direction = Vector2.ZERO
    var sprite = null
    
    func _init():
        sprite = Sprite2D.new()
        sprite.size = Vector2(24, 24)
        add_child(sprite)
        
        var shape = CircleShape2D.new()
        shape.radius = 12
        var collider = CollisionShape2D.new()
        collider.shape = shape
        add_child(collider)
    
    func set_magic(magic_data, start_pos, target_pos):
        magic = magic_data
        position = start_pos
        direction = (target_pos - start_pos).normalized()
        sprite.modulate = magic.color
    
    func _physics_process(delta):
        position += direction * speed * delta
        
        if position.distance_to(get_parent().get_node("Player").position) > 1000:
            queue_free()
    
    func _on_body_entered(body):
        if body.name != "Player":
            if body.has_method("take_damage"):
                body.take_damage(magic.damage)
            queue_free()