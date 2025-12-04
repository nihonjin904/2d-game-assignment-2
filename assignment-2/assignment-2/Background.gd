extends TextureRect

func _process(delta):
	var player = get_parent().get_node_or_null("Player")
	if not player:
		return
		
	if not texture:
		return
		
	# Calculate the size of one tile in world space
	var tile_size = texture.get_size() * scale
	
	# We want the rect to be centered on the player, but snapped to the tile grid
	# so the texture pattern doesn't jitter or slide.
	
	# Calculate the top-left position if we were perfectly centered
	var target_pos = player.global_position - (size * scale) / 2.0
	
	# Snap this position to the nearest tile grid
	global_position = (target_pos / tile_size).floor() * tile_size
