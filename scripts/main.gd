extends Node2D
@onready var btn_king = $UI/ActionPanel/InventoryKutusu/BtnKingCard # Yolunu kendi hiyerarşine göre ayarla
@onready var btn_laser = $UI/ActionPanel/InventoryKutusu/BtnLaserCard
@onready var notif_area = $UI/NotificationArea
@onready var ap_container = $UI/APContainer
@onready var ap_1 = $UI/APContainer/AP_1
@onready var ap_2 = $UI/APContainer/AP_2
@onready var tilemap = $Board/TileMap
@onready var laser_layer = $LaserLayer # Lazerleri buraya çizeceğiz
@onready var preview_img = $UI/ActionPanel/PreviewBox/PreviewRect
@onready var turn_label = $UI/TurnPanel/TurnLabel
@onready var turn_panel = $UI/TurnPanel
@onready var game_over_panel = $UI/GameOverPanel
@onready var winner_label = $UI/GameOverPanel/WinnerLabel
@onready var restart_button = $UI/GameOverPanel/RestartButton
@onready var info_button = $UI/Info
@onready var turn_banner = $UI/TurnBannerController
@onready var turn_banner_bg = $UI/TurnBannerController/BannerBackground
@onready var turn_banner_label = $UI/TurnBannerController/BannerLabel
var is_placing_mode : bool = false # Kart seçildi mi?
var selected_piece_type = null    # Hangi kart seçildi?
var preview_rotation : int = 0    # Koymadan önceki dönüş açısı

@onready var action_panel = $UI/ActionPanel
@onready var status_label = $UI/ActionPanel/StatusLabel

@onready var btn_mirror = $UI/ActionPanel/InventoryKutusu/BtnMirrorCard
@onready var btn_blocker = $UI/ActionPanel/InventoryKutusu/BtnBlockerCard
@onready var btn_splitter = $UI/ActionPanel/InventoryKutusu/BtnSplitterCard
@onready var btn_rotate_pre = $UI/ActionPanel/ControlKutusu/BtnRotatePre
@onready var btn_cancel = $UI/ActionPanel/ControlKutusu/BtnCancel
var is_game_over = false # Oyunun bitip bitmediğini tutacak
enum PieceType { King, Mirror, Blocker, Splitter, Laser }
enum Direction { UP, RIGHT, DOWN, LEFT }
enum Team { PLAYER_1, PLAYER_2 }
enum GameState { SETUP, PLAYING } # YENİ: Oyun evreleri

var current_state = GameState.SETUP # Oyun kurulum evresiyle başlar
var piece_to_place = PieceType.Mirror # UI'dan seçilen aktif taş (Varsayılan: Ayna)
var inventory = {
	Team.PLAYER_1: { PieceType.King: 1, PieceType.Laser: 2, PieceType.Mirror: 2, PieceType.Blocker: 2, PieceType.Splitter: 1 },
	Team.PLAYER_2: { PieceType.King: 1, PieceType.Laser: 2, PieceType.Mirror: 2, PieceType.Blocker: 2, PieceType.Splitter: 1 }
}
# Yeni UI elementlerimizi koda bağlıyoruz
@onready var setup_panel = $UI/SetupPanel
#@onready var btn_mirror = $UI/SetupPanel/BtnMirror
#@onready var btn_blocker = $UI/SetupPanel/BtnBlocker
#@onready var btn_splitter = $UI/SetupPanel/BtnSplitter
@onready var btn_finish_setup = $UI/ActionPanel/BtnFinishSetup
var current_turn = Team.PLAYER_1
var current_ap : int = 2 # YENİ: Başlangıç Hamle Puanı
var max_ap : int = 2
var cell_size
var board_state = {}
var board_width = 10
var board_height = 10

@onready var btn_close_panel = $UI/InfoPanel/ClosePanel
func _ready() -> void:
	cell_size = tilemap.tile_set.tile_size
	center_board()
	initialize_board()
	#setup_starting_board()
	
	
	# Butona tıklandığında _on_restart_pressed fonksiyonunu çalıştır
	restart_button.pressed.connect(_on_restart_pressed)
	btn_mirror.pressed.connect(func(): select_card(PieceType.Mirror))
	btn_blocker.pressed.connect(func(): select_card(PieceType.Blocker))
	btn_splitter.pressed.connect(func(): select_card(PieceType.Splitter))
	
	btn_king.pressed.connect(func(): select_card(PieceType.King))
	btn_laser.pressed.connect(func(): select_card(PieceType.Laser))
	# YENİ: Kontrol Butonları
	btn_rotate_pre.pressed.connect(_on_rotate_pre_pressed)
	btn_cancel.pressed.connect(cancel_placement)
	
	btn_finish_setup.pressed.connect(_on_finish_setup_pressed)
	
	# Arayüzü ilk kez güncelle
	update_inventory_ui()
	update_turn_label()
	show_turn_animation()
	ap_container.visible = false
	update_ap_display() # EKSİK OLAN SATIR BURASI! (İlk renkleri atar)
	btn_rotate_pre.visible = false
	btn_cancel.visible = false
func _on_pressed_close_button():
	info_panel.visible = false
	action_panel.visible = true
	info_button.visible = true
@onready var info_panel = $UI/InfoPanel
func _on_pressed_info_button():
	info_panel.visible = true
	action_panel.visible = false
	info_button.visible = false
	
# YENİ: Animasyonlu Bildirim (Toast) Sistemi
func log_msg(msg):
	print(msg) # Konsola yazmaya devam etsin (Hata ayıklamak için iyi olur)
	
	# 1. Yeni bir kutu (PanelContainer) oluştur
	var panel = PanelContainer.new()
	
	# 2. Kutuya kodla şık bir tasarım (StyleBox) verelim
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.85) # Koyu lacivert/gri şeffaf arkaplan
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 15 # İç boşluklar
	style.content_margin_right = 15
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.border_width_left = 2 # Sol tarafa havalı bir çizgi
	style.border_color = Color(0.3, 0.6, 1.0) # Çizgi rengi (Mavi)
	panel.add_theme_stylebox_override("panel", style)
	
	# 3. İçine yazıyı (Label) ekle
	var label = Label.new()
	label.text = msg
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# label.add_theme_font_size_override("font_size", 16) # İstersen fontu büyütebilirsin
	
	# 4. Yazıyı kutuya, kutuyu da sağ üstteki NotificationArea'ya ekle
	panel.add_child(label)
	notif_area.add_child(panel)
	
	# --- 5. TWEEN ANİMASYONU (Görünme ve Kaybolma) ---
	panel.modulate = Color(1, 1, 1, 0) # Başlangıçta tamamen görünmez olsun
	var tween = get_tree().create_tween()
	
	# 1. Aşama: 0.3 saniyede yavaşça belir (Fade-in)
	tween.tween_property(panel, "modulate", Color(1, 1, 1, 1), 0.3).set_ease(Tween.EASE_OUT)
	
	# 2. Aşama: Ekranda 2.5 saniye bekle
	tween.tween_interval(4.5)
	
	# 3. Aşama: 0.5 saniyede yavaşça silinerek kaybol (Fade-out)
	tween.tween_property(panel, "modulate", Color(1, 1, 1, 0), 0.5).set_ease(Tween.EASE_IN)
	
	# 4. Aşama: Animasyon bitince kutuyu hafızadan tamamen sil!
	tween.tween_callback(panel.queue_free)
func _on_finish_setup_pressed():
	if inventory[current_turn][PieceType.King] > 0:
		log_msg("DİKKAT: Dizilimi bitirmeden önce KRAL'ı sahaya koymalısın!")
		return # İşlemi durdur, bitirmesine izin verme
		
	if inventory[current_turn][PieceType.Laser] > 0:
		log_msg("DİKKAT: Tüm Lazer kulelerini sahaya yerleştirmelisin!")
		return # İşlemi durdur
	if current_turn == Team.PLAYER_1:
		end_turn()
		log_msg("Mavi kurulumu bitirdi, sıra Kırmızıda.")
	else:
		current_state = GameState.PLAYING
		ap_container.visible = true
		# Hatalı yol yerine direkt değişkeni kullan:
		btn_finish_setup.visible = false 
		# Eğer setup_panel komple kapansın istersen:
		# setup_panel.visible = false
		
		lazerleri_guncelle()
		end_turn()
		cancel_placement()
		log_msg("SAVAŞ BAŞLADI!")
		show_turn_animation() # YENİ EKLENDİ
		
#func update_preview():
	#if is_placing_mode and selected_piece_type != null:
		#preview_img.visible = true
		#
		## Resmi yükle
		#var tex_path = "res://sprites/" + str(PieceType.keys()[selected_piece_type]).to_lower() + ".png"
		#preview_img.texture = load(tex_path)
		#
		## Rotation doğru şekilde
		#preview_img.rotation = deg_to_rad(preview_rotation)
		#
		## TextureRect boyutu resmi kapsayacak şekilde ayarlanmalı
		#preview_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		#preview_img.size = preview_img.texture.get_size() if preview_img.texture else Vector2.ZERO
		#
		#status_label.text = "KOYULACAK: " + str(PieceType.keys()[selected_piece_type]) + " (" + str(preview_rotation) + "°)"
	#else:
		#preview_img.visible = false
func update_preview():
	if is_placing_mode and selected_piece_type != null:
		preview_img.visible = true
		var tex_path = "res://sprites/" + str(PieceType.keys()[selected_piece_type]).to_lower() + ".png"
		var tex = load(tex_path)
		preview_img.texture = tex
		
		# --- DÜZELTME BURADA ---
		# Resmi önce kendi boyutuna oturmaya zorluyoruz (Kutu içindeki yamulmaları engeller)
		preview_img.size = tex.get_size()
		
		# Sonra iğneyi (pivot_offset) TextureRect'in milimetrik merkezine batırıyoruz!
		preview_img.pivot_offset = preview_img.size / 2.0 
		# -----------------------
		
		preview_img.rotation = deg_to_rad(preview_rotation)
		
		# Layout ayarları
		preview_img.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		status_label.text = "KOYULACAK: " + str(PieceType.keys()[selected_piece_type])
	else:
		preview_img.visible = false
func update_turn_label():
	var ap_text = " (AP: " + str(current_ap) + ")" if current_state == GameState.PLAYING else " (Kurulum)"
	
	if current_turn == Team.PLAYER_1:
		turn_label.text = "SIRA: MAVİ TAKIM" + ap_text
		turn_panel.modulate = Color(0.3, 0.6, 1.0)
	else:
		turn_label.text = "SIRA: KIRMIZI TAKIM" + ap_text
		turn_panel.modulate = Color(1.0, 0.3, 0.3)

func game_over(losing_team: Team):
	if current_state == GameState.SETUP:
		return
	is_game_over = true
	game_over_panel.visible = true 
	
	ap_container.visible = false
	action_panel.visible = false
	# 1. Yazıyı ve Rengi Ayarla
	if losing_team == Team.PLAYER_1:
		winner_label.text = "ŞAH MAT! KIRMIZI TAKIM KAZANDI!"
		winner_label.modulate = Color(1.0, 0.3, 0.3)
	else:
		winner_label.text = "ŞAH MAT! MAVİ TAKIM KAZANDI!"
		winner_label.modulate = Color(0.3, 0.6, 1.0)
		
	# --- SİNEMATİK TWEEN ANİMASYONU ---
	var tween = get_tree().create_tween()
	
	# 1. Aşama: Arka plan karanlığının yavaşça çökmesi (Fade in)
	game_over_panel.modulate = Color(1, 1, 1, 0) # Önce tamamen saydam yap
	tween.tween_property(game_over_panel, "modulate", Color(1, 1, 1, 1), 0.5)
	
	# 2. Aşama: Yazının merkezden büyüyerek ve sekerek (Bounce) ekrana çarpması
	winner_label.scale = Vector2(0.1, 0.1) # Küçücük başlat
	# DİKKAT: Büyümenin merkezden olması için pivot noktasını ayarlıyoruz
	winner_label.pivot_offset = winner_label.size / 2 
	
	tween.tween_property(winner_label, "scale", Vector2(1.0, 1.0), 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	# 3. Aşama: Yeniden Başlat (Restart) butonunun gecikmeli olarak belirmesi
	restart_button.modulate = Color(1, 1, 1, 0) # Önce görünmez yap
	# Yazı ekrana çarptıktan yarım saniye sonra yavaşça belirsin
	tween.tween_property(restart_button, "modulate", Color(1, 1, 1, 1), 0.5).set_delay(0.5)
		
func _on_restart_pressed():
	# Sahneyi baştan yükle (Oyunu sıfırla)
	get_tree().reload_current_scene()
func initialize_board():
	for x in range(board_width):
		for y in range(board_height):
			board_state[Vector2i(x,y)] = null

func center_board():
	var map_size = tilemap.get_used_rect().size
	var board_pixel_size = map_size * cell_size
	tilemap.position = -board_pixel_size / 2

func setup_starting_board():
	# --- PLAYER 1 (MAVİ TAKIM) ---
	place_piece(Vector2i(4, 0), PieceType.King, 180, Team.PLAYER_1)
	place_piece(Vector2i(0, 0), PieceType.Laser, 180, Team.PLAYER_1)
	place_piece(Vector2i(4, 1), PieceType.Blocker, 0, Team.PLAYER_1)
	place_piece(Vector2i(5, 0), PieceType.Mirror, 270, Team.PLAYER_1)
	
	# --- PLAYER 2 (KIRMIZI TAKIM) ---
	place_piece(Vector2i(5, 9), PieceType.King, 0, Team.PLAYER_2)
	place_piece(Vector2i(9, 9), PieceType.Laser, 0, Team.PLAYER_2)
	place_piece(Vector2i(5, 8), PieceType.Blocker, 0, Team.PLAYER_2)
	place_piece(Vector2i(4, 9), PieceType.Mirror, 90, Team.PLAYER_2)
# GODOT 4 GÜNCELLEMESİ: Fare pozisyonunu doğru şekilde Grid'e çevirme
func get_mouse_grid_position() -> Vector2i:
	var local_mouse_pos = tilemap.to_local(get_global_mouse_position())
	return tilemap.local_to_map(local_mouse_pos)


		
# Fonksiyona "rot" parametresi ekledik, varsayılan olarak 0 verdik ki eski kodlar bozulmasın
func place_piece(grid_pos: Vector2i, piece_type, rot: int = 0, team: Team = Team.PLAYER_1):
	if !is_inside_board(grid_pos):
		log_msg("Tahta dışına koyamazsın!")
		return

	if is_cell_occupied(grid_pos):
		log_msg("Bu kare dolu!")
		return

	var piece_scene = preload("res://scenes/Piece.tscn")
	var piece = piece_scene.instantiate()

	piece.tile_size = cell_size
	piece.piece_type = piece_type
	piece.rotation_angle = rot 
	
	# İŞTE EKSİK OLAN HAYATİ SATIR BURASI! 👇
	piece.team = team 
	
	# Taşa takımını söyledikten SONRA görselini güncelliyoruz ki rengini bilsin
	piece.update_sprite()

	# Yerleştirme
	var local_pos = tilemap.map_to_local(grid_pos)
	piece.position = local_pos

	tilemap.add_child(piece)
	board_state[grid_pos] = piece
	lazerleri_guncelle()

func is_cell_occupied(grid_pos : Vector2i) -> bool:
	return board_state.get(grid_pos) != null
	
func get_piece_at(grid_pos : Vector2i):
	return board_state.get(grid_pos)

func direction_to_vector(dir : Direction) -> Vector2i:
	match dir:
		Direction.UP: return Vector2i(0, -1)
		Direction.RIGHT: return Vector2i(1, 0)
		Direction.DOWN: return Vector2i(0, 1)
		Direction.LEFT: return Vector2i(-1, 0)
	return Vector2i.ZERO
	
func is_inside_board(pos : Vector2i) -> bool:
	return pos.x >= 0 and pos.x < board_width and pos.y >= 0 and pos.y < board_height

# YENİ: 'laser_team : Team' parametresi eklendi
func fire_laser(start_pos : Vector2i, direction : Direction, laser_team : Team):
	var initial_line = create_new_laser_line(laser_team)
	_fire_laser_recursive(start_pos, direction, initial_line, false, laser_team)

# Yeni Line2D üreten yardımcı fonksiyon
# YENİ: 'laser_team' parametresi eklendi ve kalınlık inceltildi
func create_new_laser_line(laser_team: Team) -> Line2D:
	var line = Line2D.new()
	
	line.width = 2.0 # 4.0'dan 2.0'a düşürdük (Daha ince ve keskin)
	
	# Takıma göre lazer rengi
	if laser_team == Team.PLAYER_1:
		line.default_color = Color(0.2, 1.0, 0.2) # MAVİ TAKIMIN LAZERİ: Fosforlu Yeşil
	else:
		line.default_color = Color(1.0, 0.2, 0.2) # KIRMIZI TAKIMIN LAZERİ: Kırmızı
		
	laser_layer.add_child(line)
	return line
	
# YENİ: Parametrelere 'has_bounced : bool' eklendi
func _fire_laser_recursive(current_pos : Vector2i, direction : Direction, current_line : Line2D, has_bounced : bool, laser_team : Team):
	var dir_vector = direction_to_vector(direction)
	
	var tile_local_pos = tilemap.map_to_local(current_pos)
	var global_pos = tilemap.to_global(tile_local_pos)
	var line_local_pos = laser_layer.to_local(global_pos)
	
	current_line.add_point(line_local_pos)
	
	var max_steps = 50 
	var steps = 0
	
	while steps < max_steps:
		steps += 1
		current_pos += dir_vector

		if !is_inside_board(current_pos):
			# Tahtanın dışındaki 11. karenin merkezine GİTME!
			# Onun yerine, tahtadaki en son geçerli karenin kenarında dur.
			var last_valid_pos = current_pos - dir_vector
			var last_tile_local = tilemap.map_to_local(last_valid_pos)
			
			# Lazerin yönüne doğru, hücre boyutunun tam yarısı kadar (kenara) uzat
			var offset = Vector2(dir_vector) * (Vector2(cell_size) / 2.0)
			var edge_local = last_tile_local + offset
			var edge_global = tilemap.to_global(edge_local)
			
			current_line.add_point(laser_layer.to_local(edge_global))
			break
		
		var step_tile_pos = tilemap.map_to_local(current_pos)
		var step_global_pos = tilemap.to_global(step_tile_pos)
		current_line.add_point(laser_layer.to_local(step_global_pos))
		
		var piece = get_piece_at(current_pos)
		if piece != null:
			match int(piece.piece_type):
				PieceType.Mirror:
					if can_reflect(direction, piece.rotation_angle):
						direction = reflect_direction(direction, piece.rotation_angle)
						dir_vector = direction_to_vector(direction)
						
						# YENİ: Lazer sektiği için artık ÖLÜMCÜL oldu!
						has_bounced = true 
						continue 
					else:
						# Arkadan vuruldu! Ama ölümcül mü?
						if has_bounced:
							log_msg("ŞIRAAAK! Ayna kırıldı!")
							steal_mirror(current_pos, laser_team)
						else:
							log_msg("Zararsız lazer aynaya çarptı ve durdu.")
						break
				PieceType.Blocker:
					break
				PieceType.Splitter:
					var bounce_dir = reflect_direction(direction, piece.rotation_angle)
					var split_line = create_new_laser_line(laser_team)
					
					var split_tile_pos = tilemap.map_to_local(current_pos)
					var split_global = tilemap.to_global(split_tile_pos)
					split_line.add_point(laser_layer.to_local(split_global))
					
					# İçinden geçen lazer düz devam eder (Ölümcül değilse zararsız kalır)
					_fire_laser_recursive(current_pos + direction_to_vector(direction), direction, split_line, has_bounced, laser_team)
					
					# Seken lazer ise anında ÖLÜMCÜL olur!
					direction = bounce_dir
					dir_vector = direction_to_vector(direction)
					has_bounced = true 
					continue
				PieceType.King:
					# 1. Önce Kalkan kontrolü yapıyoruz
					if can_king_reflect(direction, piece.rotation_angle):
						direction = reflect_king(direction)
						dir_vector = direction_to_vector(direction)
						has_bounced = true # Kalkandan seken lazer de ölümcül olur
						log_msg("DZZZT! Lazer Kralın kalkanından sekti!")
						continue
					
					# 2. Kalkan dışı bir yerden vurulduysa:
					else:
						if has_bounced: # Lazer daha önce aynadan sektiği için ölümcül!
							log_msg("ŞAH MAT! OYUN BİTTİ!")
							destroy_piece(current_pos)
						else:
							log_msg("Kral zararsız lazere siper oldu, hasar almadı.")
						break
				PieceType.Laser:
					break

# Lazerin parlak yüze çarptıktan sonra HANGİ YÖNE sekeceğini hesaplar
func reflect_direction(current_dir : Direction, mirror_rotation : int) -> Direction:
	match int(mirror_rotation):
		0: # (\) Şekli -> Önü SOL-ALT
			if current_dir == Direction.UP: return Direction.LEFT
			if current_dir == Direction.RIGHT: return Direction.DOWN
		90: # (/) Şekli -> Önü SOL-ÜST
			if current_dir == Direction.DOWN: return Direction.LEFT
			if current_dir == Direction.RIGHT: return Direction.UP
		180: # (\) Şekli -> Önü SAĞ-ÜST
			if current_dir == Direction.DOWN: return Direction.RIGHT
			if current_dir == Direction.LEFT: return Direction.UP
		270: # (/) Şekli -> Önü SAĞ-ALT
			if current_dir == Direction.UP: return Direction.RIGHT
			if current_dir == Direction.LEFT: return Direction.DOWN
			
	return current_dir
			
var selected_piece : Node = null

func select_piece_at(grid_pos: Vector2i):
	var piece = get_piece_at(grid_pos)
	if piece != null:
		# Takım kontrolü (int casting ile garantiye alıyoruz)
		if int(piece.team) == int(current_turn):
			selected_piece = piece
			log_msg("✅ Taş Seçildi: " + str(piece.piece_type))
		else:
			log_msg("❌ Rakibin taşına dokunamazsın!")
			selected_piece = null
	else:
		selected_piece = null
		log_msg("Boşluğa tıklandı.")
		
func rotate_selected_piece():
	if selected_piece == null:
		return
		
	# Açıyı 90 derece artır
	selected_piece.rotation_angle += 90
	
	# 360'ı geçerse sıfırlamak yerine animasyonun sapıtmaması için 360 çıkarıyoruz
	if selected_piece.rotation_angle >= 360:
		selected_piece.rotation_angle -= 360 

	# --- TWEEN ANIMASYONU (YAYLANARAK DÖNME) ---
	var tween = get_tree().create_tween()
	var sprite_node = selected_piece.get_node("pieceSprite") # Taşın içindeki resmi bul
	
	# 0.3 saniyede, hedefe ulaştığında hafifçe sekerek (Back) dönsün
	tween.tween_property(sprite_node, "rotation_degrees", float(selected_piece.rotation_angle), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	selected_piece.update_sprite() # Rengi vs. günceller (ama artık açıyı anında bozmaz)
	lazerleri_guncelle()
	selected_piece = null 
	use_ap(1) # Hamle puanını düş



# Oyun başladığında ilk lazeri çizmesi için _ready() fonksiyonunun EN ALTINA şunu ekle:
# lazerleri_guncelle()

#func _unhandled_input(event):
	## Eğer oyun bittiyse hiçbir girdiyi işleme
	#if is_game_over:
		#return
		#
	#if event is InputEventMouseButton and event.pressed:
		#var grid = get_mouse_grid_position()
		#
		## --- SOL TIK İŞLEMLERİ ---
		#if event.button_index == MOUSE_BUTTON_LEFT:
			#
			## 1. DURUM: KURULUM EVRESİ (SETUP)
			#if current_state == GameState.SETUP:
				## Oyuncu kendi bölgesine mi tıklıyor?
				#if is_in_player_territory(grid, current_turn):
					## Seçtiği taştan elinde kalmış mı?
					#if inventory[current_turn][piece_to_place] > 0:
						## Tıkladığı yer boş mu?
						#if not is_cell_occupied(grid):
							## Taşı koy
							#place_piece(grid, piece_to_place, 0, current_turn)
							## Envanterden bir tane düş
							#inventory[current_turn][piece_to_place] -= 1
							## Buton yazılarını güncelle (Kalan sayıları göster)
							#update_inventory_ui()
							#log_msg("Taş yerleştirildi! Kalan: "+ str(inventory[current_turn][piece_to_place]))
						#else:
							#log_msg("Burası dolu!")
					#else:
						#log_msg("Bu taştan kalmadı!")
				#else:
					#log_msg("Sadece kendi bölgene taş koyabilirsin!")
#
			## 2. DURUM: SAVAŞ EVRESİ (PLAYING)
			#elif current_state == GameState.PLAYING:
				#if selected_piece == null:
					## Elimde taş yoksa seçmeye çalış
					#select_piece_at(grid)
				#else:
					## Elimde taş varsa ve boş yere tıkladıysam yürü
					#if is_inside_board(grid) and not is_cell_occupied(grid):
						#var old_grid = get_piece_grid_pos(selected_piece)
						## Sadece 1 kare kuralı
						#if is_valid_move(old_grid, grid):
							#move_piece(selected_piece, grid)
						#else:
							#log_msg("Geçersiz hamle! Sadece 1 kare gidebilirsin.")
							#selected_piece = null
					#else:
						## Başka bir taşa tıkladıysam (Seçim değiştirme)
						#var clicked_piece = get_piece_at(grid)
						#if clicked_piece != null and int(clicked_piece.team) == int(current_turn):
							#select_piece_at(grid)
						#else:
							#selected_piece = null
							#log_msg("Seçim iptal edildi.")
#
		## --- SAĞ TIK İŞLEMLERİ ---
		#elif event.button_index == MOUSE_BUTTON_RIGHT:
			## Döndürme sadece Savaş evresinde hamle sayılır
			#if current_state == GameState.PLAYING:
				#rotate_selected_piece()
			#else:
				#log_msg("Kurulum evresinde döndürme kapalı (İstersen açabiliriz)")
#
	## --- TEST/KLAVYE TUŞLARI (Hala çalışsın istersen) ---
	#if event is InputEventKey and event.pressed:
		#if event.keycode == KEY_SPACE: # Test için direkt oyun evresine geçiş
			#_on_finish_setup_pressed()
func _unhandled_input(event):
	if is_game_over: return

	if event is InputEventMouseButton and event.pressed:
		var grid = get_mouse_grid_position()
		
		# --- SOL TIK ---
		if event.button_index == MOUSE_BUTTON_LEFT:
			if is_placing_mode:
				# Kart yerleştirme kontrolü
				if is_cell_occupied(grid):
					log_msg("Bu kare dolu! Başka yere koy.")
					return
				handle_card_placement(grid)
			
			elif current_state == GameState.PLAYING:
				# HAREKET: Buraya 'occupied' kontrolü koymuyoruz! 
				# Çünkü taşı seçmek için önce üzerine tıklaman lazım (yani dolu kareye).
				handle_piece_movement(grid)

		# --- SAĞ TIK (Geri Alma Sistemi) ---
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if current_state == GameState.SETUP:
				var piece_to_recall = get_piece_at(grid)
				if piece_to_recall and int(piece_to_recall.team) == int(current_turn):
					# KRİTİK KONTROL: Sadece envanterde olan taşları geri al
					if piece_to_recall.piece_type in inventory[current_turn]:
						inventory[current_turn][piece_to_recall.piece_type] += 1
						destroy_piece(grid)
						update_inventory_ui()
						update_preview()
						log_msg("Taş geri alındı.")
					else:
						log_msg("Bu taşı geri alamazsın (Kral/Lazer)!")
			
			elif current_state == GameState.PLAYING:
				rotate_selected_piece()

# Tahtada bir şey değiştiğinde bu fonksiyonu çağıracağız
func lazerleri_guncelle():
	# 1. Önce ekrandaki tüm eski lazerleri temizle
	for child in laser_layer.get_children():
		child.queue_free()
		
	# 2. Tahtadaki tüm kareleri gez ve BÜTÜN Laser taşlarını bul
	for pos in board_state.keys():
		var piece = board_state[pos]
		# int() ile cast ediyoruz çünkü enum bazen integer olarak gelebiliyor
		if piece != null and int(piece.piece_type) == PieceType.Laser: 
			
			# Lazer taşının açısına göre ateşleme yönünü belirle
			var start_dir = Direction.UP
			match piece.rotation_angle:
				0: start_dir = Direction.UP
				90: start_dir = Direction.RIGHT
				180: start_dir = Direction.DOWN
				270: start_dir = Direction.LEFT
				
			# O lazer taşı için ateşlemeyi başlat (YENİ: Takım bilgisini de gönderiyoruz)
			fire_laser(pos, start_dir, piece.team)


func destroy_piece(grid_pos: Vector2i):
	var piece = get_piece_at(grid_pos)
	if piece != null:
		if selected_piece == piece:
			selected_piece = null
			
		# YENİ EKLENDİ: Silmeden önce taşın tipini ve takımını al
		var killed_type = piece.piece_type
		var killed_team = piece.team
			
		piece.queue_free()
		board_state[grid_pos] = null
		
		
		log_msg("GÜÜÜM! Taş yok edildi: "+ str(grid_pos))
		call_deferred("lazerleri_guncelle")
		
		# YENİ EKLENDİ: Eğer ölen taş Kral ise oyunu bitir!
		if killed_type == PieceType.King:
			game_over(killed_team)

# Lazerin aynanın PARLAK yüzüne çarpıp çarpmadığını kontrol eder
func can_reflect(laser_dir: Direction, mirror_rot: int) -> bool:
	match int(mirror_rot):
		0: # (\) Şekli -> Önü SOL-ALT'a bakıyor
			# Lazer aşağıdan (UP) veya soldan (RIGHT) gelirse yansır
			return laser_dir == Direction.UP or laser_dir == Direction.RIGHT
		90: # (/) Şekli -> Önü SOL-ÜST'e bakıyor
			# Lazer yukarıdan (DOWN) veya soldan (RIGHT) gelirse yansır
			return laser_dir == Direction.DOWN or laser_dir == Direction.RIGHT
		180: # (\) Şekli -> Önü SAĞ-ÜST'e bakıyor
			# Lazer yukarıdan (DOWN) veya sağdan (LEFT) gelirse yansır
			return laser_dir == Direction.DOWN or laser_dir == Direction.LEFT
		270: # (/) Şekli -> Önü SAĞ-ALT'a bakıyor
			# Lazer aşağıdan (UP) veya sağdan (LEFT) gelirse yansır
			return laser_dir == Direction.UP or laser_dir == Direction.LEFT
			
	return false


# Sırayı rakibe geçirir ve konsola yazdırır
func end_turn():
	if current_turn == Team.PLAYER_1:
		current_turn = Team.PLAYER_2
	else:
		current_turn = Team.PLAYER_1
		
	current_ap = max_ap # YENİ: Tur geçince AP'yi doldur
	
	update_turn_label()
	update_ui_colors()
	update_inventory_ui()
	update_preview()    # Önizleme yazısını tazele
	update_ap_display()
	show_turn_animation()
# Bir taşın tahtadaki (x,y) koordinatını bulur
func get_piece_grid_pos(piece: Node) -> Vector2i:
	for pos in board_state.keys():
		if board_state[pos] == piece:
			return pos
	return Vector2i(-1, -1)


# Taşı eski yerinden silip yeni yerine kaydırır
# Taşı eski yerinden silip yeni yerine KAYDIRIR (Tween ile)
func move_piece(piece: Node, new_grid: Vector2i):
	var old_grid = get_piece_grid_pos(piece)
	
	# 1. Hafızayı anında güncelle (Oyun mantığı beklemez)
	board_state[old_grid] = null
	board_state[new_grid] = piece
	
	# 2. Gidilecek gerçek (piksel) konumu hesapla
	var target_pos = tilemap.map_to_local(new_grid)
	
	# --- TWEEN ANIMASYONU BAŞLIYOR ---
	var tween = get_tree().create_tween()
	# Taşı mevcut yerinden target_pos'a 0.3 saniyede, yumuşak (Sine) bir şekilde kaydır
	tween.tween_property(piece, "position", target_pos, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	log_msg("Taş kayarak hareket etti: "+ str(old_grid) + " -> "+ str(new_grid))
	
	# 3. İşlemleri tamamla
	lazerleri_guncelle()
	selected_piece = null
	use_ap(1) # Hamle puanını düş


# Taşın sadece 1 kare uzağa (çapraz dahil) gitmesine izin verir
# YENİ: 'piece_type' parametresi eklendi
func is_valid_move(old_pos: Vector2i, new_pos: Vector2i, piece_type: int) -> bool:
	var diff_x = abs(new_pos.x - old_pos.x)
	var diff_y = abs(new_pos.y - old_pos.y)
	
	# YENİ KURAL: Hedef kare 0. veya 9. satır mı (Lazer Satırı mı)?
	var is_target_laser_row = (new_pos.y == 0 or new_pos.y == 9)
	
	# EĞER TAŞ LAZER İSE SADECE YATAY (SAĞA/SOLA) GİDEBİLİR
	if piece_type == PieceType.Laser:
		if diff_x == 1 and diff_y == 0:
			return true
		return false
	else:
		# EĞER TAŞ LAZER DEĞİLSE VE LAZER SATIRINA GİRMEYE ÇALIŞIYORSA:
		# Hareketi anında reddet! (Kutsal bölge koruması)
		if is_target_laser_row:
			# İstersen buraya log_msg("Lazer satırına sadece lazerler girebilir!") de ekleyebilirsin
			# Ancak bu fonksiyon oyun motoru tarafından çok sık çağrıldığı için log ekranını spamlayabilir,
			# O yüzden sadece 'false' döndürmek en güvenlisidir.
			return false
	
	# DİĞER TAŞLAR HER YÖNE (ÇAPRAZ DAHİL) 1 KARE GİDEBİLİR
	if diff_x <= 1 and diff_y <= 1 and (diff_x != 0 or diff_y != 0):
		return true
		
	return false


func is_in_player_territory(grid_pos: Vector2i, team: Team) -> bool:
	if team == Team.PLAYER_1:
		# Mavi takım (Üst) -> 0, 1, 2, 3, 4. satırlar
		return grid_pos.y >= 0 and grid_pos.y <= 4
	else:
		# Kırmızı takım (Alt) -> 5, 6, 7, 8, 9. satırlar
		return grid_pos.y >= 5 and grid_pos.y <= 9

func update_inventory_ui():
	var cur_inv = inventory[current_turn]
	var not_enough_ap = (current_state == GameState.PLAYING and current_ap < 2)
	
	# YENİ: Kral ve Lazer butonları
	btn_king.text = "King (" + str(cur_inv[PieceType.King]) + ")"
	btn_king.disabled = (cur_inv[PieceType.King] <= 0) or not_enough_ap
	
	btn_laser.text = "Laser (" + str(cur_inv[PieceType.Laser]) + ")"
	btn_laser.disabled = (cur_inv[PieceType.Laser] <= 0) or not_enough_ap
	
	# KURULUMDA AYNA YASAKTIR KURALI:
	btn_mirror.text = "Mirror (" + str(cur_inv[PieceType.Mirror]) + ")"
	if current_state == GameState.SETUP:
		btn_mirror.disabled = true # Kurulum aşamasında ayna kilitli!
	else:
		btn_mirror.disabled = (cur_inv[PieceType.Mirror] <= 0) or not_enough_ap
		
	btn_blocker.text = "Blocker (" + str(cur_inv[PieceType.Blocker]) + ")"
	btn_blocker.disabled = (cur_inv[PieceType.Blocker] <= 0) or not_enough_ap
	
	btn_splitter.text = "Splitter (" + str(cur_inv[PieceType.Splitter]) + ")"
	btn_splitter.disabled = (cur_inv[PieceType.Splitter] <= 0) or not_enough_ap


func select_card(type):
	# YENİ: Eğer oyun içindeyse ve AP 2'den azsa, hiçbir şey yapma!
	if current_state == GameState.PLAYING and current_ap < 2:
		log_msg("Kart koymak için tam tur (2 AP) gerekir!")
		return
	is_placing_mode = true
	selected_piece_type = type
	selected_piece = null # Eğer yürütmek için bir taş seçiliyse onu bırak
	status_label.text = "Yerleştirilecek: " + str(type)
	preview_rotation = 0
	log_msg("Kart seçildi, yerleştirme modu aktif.")
	btn_rotate_pre.visible = true
	btn_cancel.visible = true
	update_preview()
# 2. Yerleştirmeden Önce Döndürme Fonksiyonu (Hata veren fonksiyon buydu!)
func _on_rotate_pre_pressed():
	if is_placing_mode:
		preview_rotation = (preview_rotation + 90) % 360
		update_preview() # Görüntüyü tazele
		
func cancel_placement():
	is_placing_mode = false
	selected_piece_type = null
	preview_rotation = 0
	btn_rotate_pre.visible = false
	btn_cancel.visible = false
	update_preview() # Önizlemeyi gizler
	status_label.text = "Hamle Sırası Sizde"
	log_msg("Kart yerleştirme iptal edildi.")

func update_ui_colors():
	if current_turn == Team.PLAYER_1:
		action_panel.self_modulate = Color(0.3, 0.6, 1.0) # Mavi
		status_label.text = "MAVİ: Hamle Yap"
	else:
		action_panel.self_modulate = Color(1.0, 0.3, 0.3) # Kırmızı
		status_label.text = "KIRMIZI: Hamle Yap"

func handle_card_placement(grid: Vector2i):
	if inventory[current_turn][selected_piece_type] > 0:
		if is_inside_board(grid) and not is_cell_occupied(grid):
			
			var can_place = true
			
			# --- 1. KURULUM AŞAMASI (BÖLGE KONTROLÜ) ---
			if current_state == GameState.SETUP:
				if not is_in_player_territory(grid, current_turn):
					log_msg("Sadece kendi bölgene taş koyabilirsin!")
					can_place = false
			
			# --- 2. LAZER SATIRI (KUTSAL BÖLGE) KONTROLÜ ---
			# DİKKAT: Bu kuralı Setup'ın dışına aldık. Savaşta da (Ayna koyarken vs) geçerli!
			var is_laser_row = (grid.y == 0 or grid.y == 9)
			
			if selected_piece_type == PieceType.Laser and not is_laser_row:
				log_msg("Lazerler sadece en arka satıra (Lazer Satırı) konulabilir!")
				can_place = false
			elif selected_piece_type != PieceType.Laser and is_laser_row:
				log_msg("Lazer satırına Lazer harici taş KESİNLİKLE konulamaz!")
				can_place = false
			
			# Eğer kurallara uyuyorsa taşı koy!
			if can_place:
				place_piece(grid, selected_piece_type, preview_rotation, current_turn)
				inventory[current_turn][selected_piece_type] -= 1
				update_inventory_ui()
				update_preview() 
				
				if current_state == GameState.PLAYING:
					is_placing_mode = false
					btn_rotate_pre.visible = false
					btn_cancel.visible = false
					update_preview()
					use_ap(2)
				else:
					log_msg("Setup: Taş koyuldu, dizmeye devam...")
	else:
		log_msg("Kartın bitti!")
		
		
func handle_piece_movement(grid: Vector2i):
	if selected_piece == null:
		select_piece_at(grid)
	else:
		var old_grid = get_piece_grid_pos(selected_piece)
		
		# DÜZELTME: is_valid_move içine 'selected_piece.piece_type' gönderiyoruz
		if is_valid_move(old_grid, grid, selected_piece.piece_type) and not is_cell_occupied(grid):
			move_piece(selected_piece, grid)
		else:
			var clicked_piece = get_piece_at(grid)
			if clicked_piece != null and int(clicked_piece.team) == int(current_turn):
				select_piece_at(grid)
			else:
				selected_piece = null
				log_msg("Geçersiz hamle veya hedef kare dolu!")


func use_ap(cost: int):
	if current_state != GameState.PLAYING:
		return 
		
	current_ap -= cost
	log_msg(str(cost) + " AP harcandı. Kalan AP: " + str(current_ap))
	update_turn_label()
	update_ap_display() 
	
	# YENİ EKLENDİ: AP harcandığı an butonları kontrol et (1 AP kaldıysa kartları kilitler)
	update_inventory_ui() 
	
	if current_ap <= 0:
		end_turn()

# --- V2.0 YENİ FONKSİYONLAR ---

# Aynayı tahtadan silip vuranın cebine koyan fonksiyon
func steal_mirror(grid_pos: Vector2i, attacking_team: Team):
	var piece = get_piece_at(grid_pos)
	if piece == null or piece.piece_type != PieceType.Mirror:
		return
		
	var victim_team = piece.team
	
	# 1. Vuran takıma +1 ayna ekle
	inventory[attacking_team][PieceType.Mirror] += 1
	update_inventory_ui()
	
	# 2. Taşı sahadan sil
	piece.queue_free()
	board_state[grid_pos] = null
	if selected_piece == piece:
		selected_piece = null
		
	log_msg(str(victim_team) + " takımının aynası ÇALINDI!")
	call_deferred("lazerleri_guncelle")
	
	# 3. Kurban takımın aynası bitti mi diye kontrol et
	call_deferred("check_mirror_win_condition", victim_team)

# Hükmen mağlubiyet kontrolü (Hiç aynası kalmadı mı?)
func check_mirror_win_condition(team_to_check: Team):
	# Önce envantere bak, elde ayna var mı?
	if inventory[team_to_check][PieceType.Mirror] > 0:
		return # Hala umut var!
		
	# Envanterde yoksa, tahtaya bak!
	var has_mirror_on_board = false
	for pos in board_state.keys():
		var p = board_state[pos]
		if p != null and int(p.team) == int(team_to_check) and int(p.piece_type) == PieceType.Mirror:
			has_mirror_on_board = true
			break
			
	# Tahtada da ayna kalmamışsa oyun anında biter!
	if not has_mirror_on_board:
		log_msg("AYNASIZ KALDI! HÜKMEN MAĞLUBİYET!")
		game_over(team_to_check) # Aynasız kalan takımı kaybeden olarak yolla


# Kralın kalkanına mı denk geldi? (0 derece = Kalkan YUKARI bakıyor varsayıyoruz)
func can_king_reflect(laser_dir: Direction, king_rot: int) -> bool:
	match int(king_rot):
		0: return laser_dir == Direction.DOWN # Kalkan YUKARI bakıyorsa, lazer AŞAĞI iniyorken kalkan karşılar
		90: return laser_dir == Direction.LEFT # Kalkan SAĞA bakıyorsa, lazer SOLA gidiyorken kalkan karşılar
		180: return laser_dir == Direction.UP
		270: return laser_dir == Direction.RIGHT
	return false

# Kral kalkanından seken lazer 180 derece geri döner
func reflect_king(laser_dir: Direction) -> Direction:
	match laser_dir:
		Direction.UP: return Direction.DOWN
		Direction.DOWN: return Direction.UP
		Direction.LEFT: return Direction.RIGHT
		Direction.RIGHT: return Direction.LEFT
	return laser_dir


# Ekrana kayarak giren ve çıkan animasyonlu sıra bildirimi
func show_turn_animation():
	# Ekranın genişliğini al (Örn: 1152)
	var screen_width = get_viewport_rect().size.x

	# Yazıyı ve rengi sıradaki takıma göre ayarla
	if current_turn == Team.PLAYER_1:
		turn_banner_label.text = "MAVİ TAKIMIN SIRASI"
		turn_banner_bg.color = Color(0.1, 0.4, 0.8, 0.8) # Yarı saydam Mavi
	else:
		turn_banner_label.text = "KIRMIZI TAKIMIN SIRASI"
		turn_banner_bg.color = Color(0.8, 0.1, 0.1, 0.8) # Yarı saydam Kırmızı

	# 0. Başlangıç pozisyonu: Afişi ekranın tamamen SAĞINA, dışarıya sakla
	turn_banner.position.x = screen_width
	turn_banner.visible = true

	# --- TWEEN SİHRİ BAŞLIYOR ---
	var tween = get_tree().create_tween()
	
	# 1. Aşama: Ekranın ortasına hızla ve yavaşlayarak (Ease Out) kay
	tween.tween_property(turn_banner, "position:x", 0.0, 0.4).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	# 2. Aşama: Ortada 1.2 saniye bekle (Oyuncu okusun)
	tween.tween_interval(1.2)
	
	# 3. Aşama: Ekranın SOLUNA doğru hızlanarak (Ease In) çık git
	tween.tween_property(turn_banner, "position:x", -screen_width, 0.4).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	
	# 4. Aşama: Animasyon bitince düğümü gizle (Performans ve güvenlik için)
	#tween.tween_callback(func(): turn_banner.visible = false)


# AP kristallerini güncelleyen fonksiyon
func update_ap_display():
	var active_color = Color(0.3, 0.6, 1.0) # Varsayılan Mavi
	var empty_color = Color(0.2, 0.2, 0.2, 0.5) # Sönük Gri (Yarı saydam)

	# Sıra kimdeyse kristaller o renkte parlasın
	if current_turn == Team.PLAYER_2:
		active_color = Color(1.0, 0.3, 0.3) # Kırmızı

	# 1. Kristalin Durumu (AP 1 veya 2 ise yanar)
	if current_ap >= 1:
		ap_1.modulate = active_color
	else:
		ap_1.modulate = empty_color

	# 2. Kristalin Durumu (Sadece AP 2 ise yanar)
	if current_ap == 2:
		ap_2.modulate = active_color
	else:
		ap_2.modulate = empty_color





func _on_exit_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")
