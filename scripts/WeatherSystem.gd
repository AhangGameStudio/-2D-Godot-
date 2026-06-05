extends Node2D

var weathers = {
	sunny  = {name="晴天", rain=0, snow=0},
	cloudy = {name="多云", rain=0, snow=0},
	rainy  = {name="雨天", rain=1, snow=0},
	stormy = {name="暴风雨", rain=2, snow=0},
	snowy  = {name="雪天", rain=0, snow=1}
}
var current = "sunny"
var timer = 0
var duration = 300

func _ready():
	randomize_weather()

func _process(delta):
	timer += delta
	if timer >= duration:
		timer = 0; randomize_weather()

func randomize_weather():
	var list = ["sunny", "cloudy", "rainy", "stormy", "snowy"]
	current = list[randi() % list.size()]
	duration = 180 + randi() % 300

func get_current():
	return weathers.get(current, weathers.sunny)