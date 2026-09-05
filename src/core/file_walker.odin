package core

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"

walk_directory :: proc(dir_path: string) -> ([dynamic]File_Info, bool) {
	results: [dynamic]File_Info

	w := os.walker_create_path(strings.join([]string{dir_path, "Data"}, "/"))
	defer os.walker_destroy(&w)

	for walk in os.walker_walk(&w) {
		if path, err := os.walker_error(&w); err != nil {
			fmt.eprintfln("failed walking %s: %s", path, err)
			continue
		}

		if walk.type != .Regular && walk.type != .Directory {
			continue
		}

		file_path, join_err := filepath.join([]string{}, context.temp_allocator)
		if join_err != nil {
			fmt.eprintfln("Failed to get file path for file %s", walk.name)
			continue
		}

		file := File_Info {
			name   = strings.clone(walk.name),
			path   = file_path,
			is_dir = walk.type == .Directory,
		}
		append(&results, file)
	}

	return results, true
}
