#+feature dynamic-literals
package game

import "core:mem"
import "core:fmt"
import "core:encoding/json"
import "core:os"
import "core:slice"

import rl "vendor:raylib"
import ase "ext:odin-aseprite"

Vec2 :: rl.Vector2
Rect :: rl.Rectangle

ATLAS_DATA :: #load("../assets/atlas.png")



atlas: rl.Texture

Animation_Name_Main :: enum {
	Idle,
	Run,
}

AnimationMain :: struct {
	texture:       rl.Texture2D,
	num_frames:    int,
	frame_timer:   f32,
	current_frame: int,
	frame_length:  f32,
	name:          Animation_Name_Main,
}

update_animation :: proc(a: ^AnimationMain) {
	a.frame_timer += rl.GetFrameTime()

	//NOTE: opt for low framerate or high animation rate
	for a.frame_timer > a.frame_length {
		a.current_frame += 1
		a.frame_timer -= a.frame_length

		if a.current_frame == a.num_frames {
			a.current_frame = 0
		}
	}
}

draw_animation :: proc(a: AnimationMain, pos: Vec2, flip: bool) {
	width := f32(a.texture.width)
	height := f32(a.texture.height)

	source := rl.Rectangle {
		x      = f32(a.current_frame) * width / f32(a.num_frames),
		y      = 0,
		width  = width / f32(a.num_frames),
		height = height,
	}

	if flip {
		source.width = -source.width
	}

	dest := rl.Rectangle {
		x      = pos.x,
		y      = pos.y,
		width  = width / f32(a.num_frames),
		height = height,
	}

	rl.DrawTexturePro(a.texture, source, dest, {dest.width / 2, dest.height}, 0, rl.WHITE)
}

animation_draw :: proc(anim: Animation, pos: rl.Vector2) {
	if anim.current_frame == .None {
		return
	}

	texture := atlas_textures[anim.current_frame]

	// The texture has four offset fields: offset_top, right, bottom and left. The offsets records
	// the distance between the pixels in the atlas and the edge of the original document in the
	// image editing software. Since the atlas is tightly packed, any empty pixels are removed.
	// These offsets can be used to correct for that removal.
	//
	// This can be especially obvious in animations where different frames can have different
	// amounts of empty pixels around it. By adding the offsets everything will look OK.
	//
	// If you ever flip the animation in X or Y direction, then you might need to add the right or
	// bottom offset instead.
	offset_pos := pos + {texture.offset_left, texture.offset_top}

	rl.DrawTextureRec(atlas, texture.rect, offset_pos, rl.WHITE)
}

PixelWindowHeight :: 180

Level :: struct {
	platforms: [dynamic]Vec2,
}

platform_collider :: proc(pos: Vec2) -> rl.Rectangle {
	return {pos.x, pos.y, 96, 16}
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


    // font := get_font()

	player_pos: Vec2
	player_vel: Vec2
	player_grounded: bool
	player_flip: bool

    anim := animation_create(.Mc_Idle)

	// player_idle := Animation {
	// 	texture      = rl.LoadTexture("./assets/cat_idle.png"),
	// 	num_frames   = 2,
	// 	frame_length = 0.5,
	// 	name         = .Idle,
	// }
	//
	// player_run := Animation {
	// 	texture      = rl.LoadTexture("./assets/cat_run.png"),
	// 	num_frames   = 4,
	// 	frame_length = 0.1,
	// 	name         = .Run,
	// }

	current_anim := anim

    level: Level

    if level_data, ok := os.read_entire_file("level.json",
    context.temp_allocator); ok {
        if json.unmarshal(level_data, &level) != nil {
            append(&level.platforms, Vec2{-20, 20})
        }
    } else {
        append(&level.platforms, Vec2{-20, 20})
    }

	platform_texture := atlas_textures[.Platform]


    is_editing := false

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		// rl.ClearBackground({110, 184, 168, 255})
		rl.SetTargetFPS(500)

		if rl.IsKeyDown(.LEFT) {
			player_vel.x = -100
			player_flip = true

			// if current_anim.name != .Run {
			// 	current_anim = player_run
			// }
		} else if rl.IsKeyDown(.RIGHT) {
			player_vel.x = 100
			player_flip = false

			// if current_anim.name != .Run {
			// 	current_anim = player_run
			// }
		} else {
			player_vel.x = 0
			// if current_anim.name != .Idle {
			// 	current_anim = player_idle
			// }
		}

        //gravity
		// player_vel.y += 1000 * rl.GetFrameTime()

		if player_grounded && rl.IsKeyPressed(.SPACE) {
			player_vel.y = -300
		}

		//TODO: fix time step
		player_pos += player_vel * rl.GetFrameTime()

		player_feet_collider := rl.Rectangle{player_pos.x - 4, player_pos.y - 4, 8, 4}

		player_grounded = false

		for platform in level.platforms {
			if rl.CheckCollisionRecs(
                player_feet_collider, platform_collider(platform)
            ) && player_vel.y > 0 {
				player_vel.y = 0
				player_pos.y = platform.y
				player_grounded = true
			}
		}


		// update_animation(&current_anim)

		screen_height := f32(rl.GetScreenHeight())

		camera := rl.Camera2D {
			zoom   = screen_height / PixelWindowHeight,
			offset = {f32(rl.GetScreenWidth()) / 2, f32(rl.GetScreenHeight() / 2)},
			target = player_pos,
		}

        animation_update(&anim, rl.GetFrameTime())

		rl.BeginMode2D(camera)
		// draw_animation(current_anim, player_pos, player_flip)

        //test animation render
        fmt.println("should draw animation")
        animation_draw(anim, player_pos)


		for platform in level.platforms {
			rl.DrawTextureRec(atlas, platform_texture.rect, {platform.x, platform.y}, rl.WHITE)
		}

		{ 	// Debug
			rl.DrawRectangleRec(player_feet_collider, {0, 255, 0, 100})
		}

        if rl.IsKeyPressed(.F2) {
            is_editing = !is_editing
        }

        if is_editing {
            mp := rl.GetScreenToWorld2D(rl.GetMousePosition(), camera)

            rl.DrawTextureRec(atlas, platform_texture.rect, mp, rl.WHITE)

            if rl.IsMouseButtonPressed(.LEFT){
                append(&level.platforms, mp)
            }

            if rl.IsMouseButtonPressed(.RIGHT) {
                for p, idx in level.platforms {
                    if rl.CheckCollisionPointRec(mp, platform_collider(p)) {
                        unordered_remove(&level.platforms, idx)
                        break
                    }
                }
            }
        }

        // rl.DrawTextEx(font, "Draw call 1: This text + player + background graphics + tiles", {-140, 20}, 15, 0, rl.WHITE)

		rl.EndMode2D()
		rl.EndDrawing()
	}

	rl.CloseWindow()

    if level_data, err := json.marshal(level, allocator = context.temp_allocator); err == nil {
        os.write_entire_file("level.json", level_data)
    }

    free_all(context.temp_allocator)
    delete(level.platforms)
}
