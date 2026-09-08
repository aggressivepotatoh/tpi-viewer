package core

import "./formats"
import "core:fmt"
import "core:os"
import "core:path/filepath"

file_result: File_Result

load_file :: proc(file: File_Info) {
	fmt.printfln("Loading %s", file.path)

	free_file_result(file_result)

	ext := filepath.ext(file.path)

	switch ext {
	case ".sam":
		sam_result := Sam_Result {
			path    = file.path,
			loading = true,
			type    = .SAM,
		}
		file_result = sam_result
		lines, raw_data, err := formats.parse_sam_file(file.path)

		if err != nil {
			fmt.eprintfln("Failed to parse .sam file %s: %v", file.path, err)
			sam_result.loading = false
			sam_result.status = .Failed
			file_result = sam_result
			return
		}

		sam_result.data = lines
		sam_result.raw_data = raw_data
		sam_result.status = .Success
		sam_result.loading = false
		file_result = sam_result
	case ".tga", ".png":
		image_result := Image_Result {
			path    = file.path,
			loading = true,
			type    = asset_type_from_extension(ext),
		}
		file_result = image_result

		data, err := os.read_entire_file(file.path, context.allocator)
		if err != nil {
			fmt.eprintfln("Failed to load %s file %s: %v", ext, file.path, err)
			image_result.loading = false
			image_result.status = .Failed
			file_result = image_result
			return
		}

		image_result.raw_data = data

		image_result.status = .Success
		image_result.loading = false

		file_result = image_result
	case:
		fmt.printfln("Extension %s is unsupported", ext)
		unknown_result := Unknown_Result {
			loading = false,
			status  = .Unsupported,
			path    = file.path,
			type    = .UNKNOWN,
		}
		file_result = unknown_result
	}
}

free_file_result :: proc(result: File_Result) {
	switch v in result {
	case Sam_Result:
		delete(v.data)
		delete(v.raw_data)
	case Image_Result:
		delete(v.raw_data)
	case Unknown_Result:
	}
}
