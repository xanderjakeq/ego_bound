package game

import rl "vendor:raylib"


get_font :: proc() -> rl.Font {
	num_glyphs := len(atlas_glyphs)
	font_rects := make([]Rect, num_glyphs)
	glyphs := make([]rl.GlyphInfo, num_glyphs)

	for ag, idx in atlas_glyphs {
		font_rects[idx] = ag.rect
		glyphs[idx] = {
			value    = ag.value,
			offsetX  = i32(ag.offset_x),
			offsetY  = i32(ag.offset_y),
			advanceX = i32(ag.advance_x),
		}
	}

	font := rl.Font {
		baseSize     = ATLAS_FONT_SIZE,
		glyphCount   = i32(num_glyphs),
		glyphPadding = 0,
		texture      = atlas,
		recs         = raw_data(font_rects),
		glyphs       = raw_data(glyphs),
	}

	return font
}
