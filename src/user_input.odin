package game

import "core:fmt"
import "core:slice"
import "core:strings"

import rl "vendor:raylib"

handle_input :: proc(string_builder: ^strings.Builder) {
	key_pressed := rl.GetKeyPressed()

	char: string
	#partial switch key_pressed {
	case .A:
		char = "a"
	case .B:
		char = "b"
	case .C:
		char = "c"
	case .D:
		char = "d"
	case .E:
		char = "e"
	case .F:
		char = "f"
	case .G:
		char = "g"
	case .H:
		char = "h"
	case .I:
		char = "i"
	case .J:
		char = "j"
	case .K:
		char = "k"
	case .L:
		char = "l"
	case .M:
		char = "m"
	case .N:
		char = "n"
	case .O:
		char = "o"
	case .P:
		char = "p"
	case .Q:
		char = "q"
	case .R:
		char = "r"
	case .S:
		char = "s"
	case .T:
		char = "t"
	case .U:
		char = "u"
	case .V:
		char = "v"
	case .W:
		char = "w"
	case .X:
		char = "x"
	case .Y:
		char = "y"
	case .Z:
		char = "z"
	case .SLASH:
		char = "/"
	case .SPACE:
		char = " "
	case .BACKSPACE:
		if rl.IsKeyDown(.LEFT_CONTROL) || rl.IsKeyDown(.RIGHT_CONTROL) {
			last_byte := strings.pop_byte(string_builder)
			for last_byte != 0 && !strings.is_space(rune(last_byte)) {
				last_byte = strings.pop_byte(string_builder)
			}
		} else {
			strings.pop_byte(string_builder)
		}
	case:
		return
	}

	if key_pressed == .SLASH {
		strings.builder_reset(string_builder)
		return
	}

	strings.write_string(string_builder, char)
}
