package core

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:slice"
import "core:strings"

walk_directory :: proc(dir_path: string) -> ([dynamic]File_Info, bool) {
	results: [dynamic]File_Info

	walk_recursive(dir_path, 0, &results)

	return results, true
}

file_sort :: proc(i, j: os.File_Info) -> bool {
	is_i_dir := i.type == .Directory
	is_j_dir := j.type == .Directory

	if is_i_dir && !is_j_dir do return true
	if is_j_dir && !is_i_dir do return false
	return i.fullpath < j.fullpath
}

walk_recursive :: proc(path: string, depth: int, results: ^[dynamic]File_Info) {
	files, read_err := os.read_directory_by_path(path, 0, context.allocator)

	if read_err != nil {
		fmt.eprintfln("Error reading %s: %v", path, read_err)
	}

	slice.sort_by(files, file_sort)

	for file in files {
		if file.type != .Directory && file.type != .Regular {
			continue
		}

		ext := filepath.ext(file.fullpath)

		file_info := File_Info {
			name        = strings.clone(file.name),
			path        = file.fullpath,
			is_dir      = file.type == .Directory,
			depth       = depth,
			is_expanded = true,
			asset_type  = asset_type_from_extension(ext),
		}

		append(results, file_info)

		if file.type == .Directory {
			walk_recursive(file.fullpath, depth + 1, results)
		}
	}
}
