#+feature dynamic-literals
package game

import "core:encoding/json"
import "core:fmt"
import "core:math"
import "core:math/rand"
import "core:mem"
import "core:os"
import "core:slice"
import "core:strings"

import rl "vendor:raylib"

Vec2 :: rl.Vector2
Rect :: rl.Rectangle

// globals
PixelWindowHeight :: 180
ATLAS_DATA :: #load("../assets/atlas.png")

atlas: rl.Texture
FPS := f32(1) / 12

animation_draw :: proc(anim: Animation, pos: rl.Vector2) {
	if anim.current_frame == .None {
		return
	}

	texture := atlas_textures[anim.current_frame]

	//NOTE: offset from texture source file
	offset_pos := pos + {texture.offset_left, texture.offset_top}

	// if flip {
	// 	source.width = -source.width
	// }

	dest := rl.Rectangle {
		x      = pos.x,
		y      = pos.y,
		width  = texture.rect.width,
		height = texture.rect.height,
	}

	rl.DrawTexturePro(atlas, texture.rect, dest, {dest.width / 2, dest.height}, 0, rl.WHITE)
}

Target :: struct {
	word: cstring,
	pos:  Vec2,
}

Level :: struct {
	scary_words: [dynamic]Target,
	speed:       f32,
}

platform_collider :: proc(pos: Vec2) -> rl.Rectangle {
	return {pos.x, pos.y, 96, 16}
}

move_point_to :: proc(from: ^Vec2, to: Vec2, speed: f32) {
	angle := math.atan2_f32(to.y - from.y, to.x - from.x)
	sin := math.sin_f32(angle) * speed
	cos := math.cos_f32(angle) * speed

	from.y += sin
	from.x += cos
}

generate_enemy_origin :: proc(origin: Vec2, radius: f32) -> Vec2 {
	angle := rand.float32_range(0, 2 * math.PI)

	x := (origin.x + radius) * math.cos_f32(angle)
	y := (origin.y + radius) * math.sin_f32(angle)

	return {x, y}
}


Game_Config :: struct {
	word_list: [dynamic]cstring,
}


main :: proc() {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	context.allocator = mem.tracking_allocator(&track)

	defer {
		for _, entry in track.allocation_map {
			fmt.eprintf("%v leaked %v bytes\n", entry.location, entry.size)
		}

		for entry in track.bad_free_array {
			fmt.eprintf("%v bad free\n", entry.location)
		}
		mem.tracking_allocator_destroy(&track)
	}

	rl.InitWindow(1280, 720, "ego:bound")
	rl.SetWindowState({.WINDOW_RESIZABLE})

	atlas_image := rl.LoadImageFromMemory(".png", raw_data(ATLAS_DATA), i32(len(ATLAS_DATA)))
	atlas = rl.LoadTextureFromImage(atlas_image)
	rl.UnloadImage(atlas_image)

	font := get_font()

	player_pos: Vec2
	player_vel: Vec2
	player_grounded: bool
	player_flip: bool

	anim := animation_create(.Mc_Idle, FPS * 2)
	current_anim := anim
	level := Level {
		speed = .5,
	}

	// if level_data, ok := os.read_entire_file("level.json", context.temp_allocator); ok {
	// 	if json.unmarshal(level_data, &level) != nil {
	// 		append(&level.scary_words, Target{"mana", Vec2{-20, 20}})
	// 	}
	// } else {
	// 	append(&level.scary_words, Target{"mana", Vec2{-20, 20}})
	// }

	config: Game_Config

	if config_data, ok := os.read_entire_file("config.json", context.temp_allocator); ok {
		if json.unmarshal(config_data, &config) != nil {
			append(&config.word_list, "mana")
		}
	} else {
		append(&config.word_list, "mana")
	}

	for _ in 0 ..= 10 {
		append(
			&level.scary_words,
			Target{rand.choice(config.word_list[:]), generate_enemy_origin(player_pos, 200)},
		)
	}

	platform_texture := atlas_textures[.Platform]

	is_editing := false

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground({110, 184, 168, 255})
		rl.SetTargetFPS(60)
		rl.DrawFPS(10, 10)

		// movement
		// if rl.IsKeyDown(.LEFT) {
		// 	player_vel.x = -100
		// 	player_flip = true
		//
		// } else if rl.IsKeyDown(.RIGHT) {
		// 	player_vel.x = 100
		// 	player_flip = false
		//
		// } else if rl.IsKeyDown(.UP) {
		// 	player_vel.y = -100
		//
		// } else if rl.IsKeyDown(.DOWN) {
		// 	player_vel.y = 100
		//
		// } else {
		// 	player_vel = {0, 0}
		// }

		//gravity
		// player_vel.y += 1000 * rl.GetFrameTime()

		if player_grounded && rl.IsKeyPressed(.SPACE) {
			player_vel.y = -300
		}

		//TODO: fix time step
		player_pos += player_vel * rl.GetFrameTime()
		player_feet_collider := rl.Rectangle{player_pos.x - 4, player_pos.y - 4, 8, 4}

		player_grounded = false

		// {-140, 20}


		// for platform in level.platforms {
		// 	if rl.CheckCollisionRecs(
		//               player_feet_collider, platform_collider(platform)
		//           ) && player_vel.y > 0 {
		// 		player_vel.y = 0
		// 		player_pos.y = platform.y
		// 		player_grounded = true
		// 	}
		// }

		screen_height := f32(rl.GetScreenHeight())

		camera := rl.Camera2D {
			zoom   = screen_height / PixelWindowHeight,
			offset = {f32(rl.GetScreenWidth()) / 2, f32(rl.GetScreenHeight() / 2)},
			target = player_pos,
		}

		animation_update(&anim, rl.GetFrameTime())

		// update position
		for &target in level.scary_words {

			move_point_to(
				&target.pos,
				player_pos,
				rand.float32_range(level.speed / 2, level.speed),
			)

			player_world_pos := rl.GetScreenToWorld2D(player_pos, camera)
			target_world_pos := rl.GetScreenToWorld2D(target.pos, camera)

			if u32(target_world_pos.x) == u32(player_world_pos.x) &&
			   u32(target_world_pos.y) == u32(player_world_pos.y) {
				target.word = rand.choice(config.word_list[:])
				target.pos = generate_enemy_origin(player_pos, 200)
			}
		}


		rl.BeginMode2D(camera)
		//test animation render
		animation_draw(anim, player_pos)

		for target in level.scary_words {
			pos := target.pos
			rect := Rect {
				x      = pos.x,
				y      = pos.y,
				width  = 40,
				height = 10,
			}
			rl.DrawRectangleRec(rect, rl.RED)

			// builder := strings.builder_make(allocator = context.temp_allocator)

			// strings.write_string(&builder, target.word)
			// rl.DrawTextEx(font, strings.to_cstring(&builder), pos, 5, 0, rl.WHITE)

			rl.DrawTextEx(font, target.word, pos, 5, 0, rl.WHITE)

			free_all(context.temp_allocator)
		}

		{ 	// Debug
			rl.DrawRectangleRec(player_feet_collider, {0, 255, 0, 100})
		}

		if rl.IsKeyPressed(.F2) {
			is_editing = !is_editing
		}

		// rl.DrawTextEx(font, "Draw call 1: This text + player + background graphics + tiles", {-140, 20}, 8, 0, rl.WHITE)
		// rl.DrawTextEx(font, fmt.printf("%f, %f", player_pos.x, player_pos.y), {-140, 20}, 8, 0, rl.WHITE)

		rl.EndMode2D()
		rl.EndDrawing()
	}

	rl.CloseWindow()

	// if level_data, err := json.marshal(level, allocator = context.temp_allocator); err == nil {
	// 	os.write_entire_file("level.json", level_data)
	// }


	// if config_data, err := json.marshal(config, allocator = context.temp_allocator);
	//    err == nil {
	// 	os.write_entire_file("config.json", config_data)
	// }

	free_all(context.temp_allocator)
	delete(level.scary_words)
	delete(config.word_list)
}
