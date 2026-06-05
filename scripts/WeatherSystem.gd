extends Node2D

var weather_types = {
    sunny = {name = "晴天", brightness = 1.0, rain = 0, wind = 0},
    cloudy = {name = "多云", brightness = 0.8, rain = 0, wind = 0.2},
    rainy = {name = "雨天", brightness = 0.6, rain = 1, wind = 0.5},
    stormy = {name = "暴风雨", brightness = 0.4, rain = 2, wind = 0.8, lightning = true},
    snowy = {name = "雪天", brightness = 0.7, rain = 0, snow = 1, wind = 0.3}
}

var current_weather = "sunny"
var weather_timer = 0
var weather_duration = 300

var rain_particles = null
var snow_particles = null
var lightning_flash = null

func _ready():
    rain_particles = $RainParticles
    snow_particles = $SnowParticles
    lightning_flash = $LightningFlash
    
    randomize_weather()

func _process(delta):
    weather_timer += delta
    
    if weather_timer >= weather_duration:
        weather_timer = 0
        randomize_weather()
    
    update_weather_effects()

func randomize_weather():
    var weather_list = ["sunny", "cloudy", "rainy", "stormy", "snowy"]
    current_weather = weather_list[randi() % weather_list.size()]
    weather_duration = 180 + randi() % 300

func update_weather_effects():
    var weather = weather_types[current_weather]
    
    if rain_particles:
        rain_particles.visible = weather.rain > 0
        if weather.rain > 0:
            rain_particles.emitting = true
        else:
            rain_particles.emitting = false
    
    if snow_particles:
        snow_particles.visible = "snow" in weather and weather.snow > 0
        if "snow" in weather and weather.snow > 0:
            snow_particles.emitting = true
        else:
            snow_particles.emitting = false

func trigger_lightning():
    if lightning_flash:
        lightning_flash.visible = true
        lightning_flash.modulate = Color(1, 1, 1)
        await get_tree().create_timer(0.1).timeout
        lightning_flash.visible = false