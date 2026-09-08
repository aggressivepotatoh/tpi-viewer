package formats

import "core:os"
import "core:strings"

ParseError :: union {
	os.Error,
}

Line_Type :: enum {
	Comment,
	Value,
}

Line :: struct {
	type:  Line_Type,
	line:  string,
	value: string,
}

parse_sam_file :: proc(file: string) -> ([]Line, []byte, ParseError) {
	lines: [dynamic]Line
	data, err := os.read_entire_file(file, context.allocator)
	if err != nil {
		return nil, nil, err
	}

	it := string(data)

	for l in strings.split_lines_iterator(&it) {
		if len(strings.trim(l, " \t")) == 0 {
			continue
		}

		if strings.starts_with(l, "#") {
			append(&lines, Line{type = .Comment, line = l})
			continue
		}

		first_tab := strings.index_byte(l, '\t')
		field0 := l if first_tab < 0 else l[:first_tab]

		line := Line {
			type = .Value,
			line = field0,
		}

		if first_tab >= 0 {
			rest := l[first_tab + 1:]
			for {
				next_tab := strings.index_byte(rest, '\t')
				field := rest if next_tab < 0 else rest[:next_tab]
				if len(field) > 0 {
					line.value = field
					break
				}
				if next_tab < 0 {
					break
				}
				rest = rest[next_tab + 1:]
			}
		}

		append(&lines, line)
	}

	return lines[:], data, nil
}
