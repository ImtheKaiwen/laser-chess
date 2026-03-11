extends Node2D

enum PieceType { King, Mirror, Blocker, Splitter, Laser }
enum Team { PLAYER_1, PLAYER_2 } # YENİ: Takımları buraya da ekledik!

@export var piece_type : PieceType = PieceType.King
@export var rotation_angle : int = 0
@export var team : Team = Team.PLAYER_1 # YENİ: Taşın hangi takıma ait olduğu
var tile_size : Vector2
var sprite: Sprite2D

func _ready():
	sprite = get_node("pieceSprite") as Sprite2D
	if sprite == null:
		print("ERROR: Sprite node not found!")
		
	# --- EKSİK OLAN HAYATİ SATIR BURASI ---
	# Taş sahneye ilk eklendiğinde animasyon beklemeden anında doğru açıya dönsün
	sprite.rotation_degrees = rotation_angle
	update_sprite()

func update_sprite():
	if sprite == null:
		return 
	match piece_type:
		PieceType.King:
			sprite.texture = preload("res://sprites/king.png")
		PieceType.Mirror:
			sprite.texture = preload("res://sprites/mirror.png")
		PieceType.Blocker:
			sprite.texture = preload("res://sprites/blocker.png")
		PieceType.Splitter:
			sprite.texture = preload("res://sprites/splitter.png")
		PieceType.Laser:
			sprite.texture = preload("res://sprites/laser.png")
	
	if sprite.texture and tile_size != Vector2.ZERO:
		sprite.scale = Vector2(
			tile_size.x / sprite.texture.get_width(),
			tile_size.y / sprite.texture.get_height()
		)

	#sprite.rotation_degrees = rotation_angle
	
	# YENİ EKLENEN: Takıma göre taşı renklendiriyoruz!
	if team == Team.PLAYER_1:
		sprite.modulate = Color(0.3, 0.6, 1.0) # PLAYER 1 = MAVİ (Üst taraf)
	else:
		sprite.modulate = Color(1.0, 0.3, 0.3) # PLAYER 2 = KIRMIZI (Alt taraf)
