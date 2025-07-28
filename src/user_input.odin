package game

import "core:fmt"
import "core:math"
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

replace_matched_prefix :: proc(
	input: string,
	target: string,
) -> (
	new_str: cstring,
	is_match: bool,
) {
	input_len := len(input)
	target_len := len(target)
	min_len: int

	if input_len < target_len {
		min_len = input_len
	} else {
		min_len = target_len
	}

	diff_string := strings.builder_make(0, target_len)
	defer strings.builder_destroy(&diff_string)

	i := 0
	for i < min_len {
		if input[i] == target[i] {
			strings.write_string(&diff_string, "^")
			i += 1
			continue
		}
		break
	}

	if i == target_len {
		cstr, err := strings.to_cstring(&diff_string)

		return cstr, true
	}

	strings.write_string(&diff_string, string(target[i:]))
	cstr, err := strings.to_cstring(&diff_string)

	return cstr, false
}
