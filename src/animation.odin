package game

Animation :: struct {
	atlas_anim:    Animation_Name,
	current_frame: Texture_Name,
	timer:         f32,
}

animation_create :: proc(anim: Animation_Name, custom_duration: Maybe(f32)) -> Animation {
	a := atlas_animations[anim]

	if custom_duration != nil {
		atlas_textures[a.first_frame].duration = custom_duration.(f32)
	}

	return {
		current_frame = a.first_frame,
		atlas_anim = anim,
		timer = atlas_textures[a.first_frame].duration,
	}
}

animation_update :: proc(a: ^Animation, dt: f32) -> bool {
	a.timer -= dt
	looped := false

	if a.timer <= 0 {
		a.current_frame = Texture_Name(int(a.current_frame) + 1)
		anim := atlas_animations[a.atlas_anim]

		if a.current_frame > anim.last_frame {
			a.current_frame = anim.first_frame
			looped = true
		}

		a.timer = atlas_textures[a.current_frame].duration
	}

	return looped
}

animation_length :: proc(anim: Animation_Name) -> f32 {
	l: f32
	aa := atlas_animations[anim]

	for i in aa.first_frame ..= aa.last_frame {
		t := atlas_textures[i]
		l += t.duration
	}

	return l
}
