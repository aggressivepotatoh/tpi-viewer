package core

import "./formats"
import "core:fmt"
import "core:os"


file_result: File_Result

load_file :: proc(file: File_Info) {
	fmt.printfln("Loading %s", file.path)

	free_file_result(file_result)
	free_file_result(asset_result)

	switch file.asset_type {
	case .SAM:
		sam_result := Sam_Result {
			path    = file.path,
			loading = true,
			type    = file.asset_type,
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
	case .TGA, .PNG:
		image_result := Image_Result {
			path    = file.path,
			loading = true,
			type    = file.asset_type,
		}
		file_result = image_result

		data, err := os.read_entire_file(file.path, context.allocator)
		if err != nil {
			fmt.eprintfln("Failed to load file %s: %v", file.path, err)
			image_result.loading = false
			image_result.status = .Failed
			file_result = image_result
			return
		}

		image_result.raw_data = data

		image_result.status = .Success
		image_result.loading = false

		file_result = image_result
	case .WAD:
		wad_result := Wad_Result {
			path    = file.path,
			loading = true,
			type    = file.asset_type,
		}
		file_result = wad_result

		header, assets, data, err := formats.parse_wad_file(file.path)

		if err != nil {
			fmt.eprintfln("Failed to parse .wad file %s: %v", file.path, err)
			wad_result.loading = false
			wad_result.status = .Failed
			file_result = wad_result
			return
		}

		wad_result.header = header
		wad_result.assets = assets
		wad_result.raw_data = data

		wad_result.status = .Success
		wad_result.loading = false

		file_result = wad_result
	case .UNKNOWN:
		fmt.printfln("Asset type is unsupported: %s", file.path)
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
	case Wad_Result:
		delete(v.raw_data)
		// TODO do we need to delete the strings for each entry name or does this cascade?
		delete(v.assets)
	case Unknown_Result:
	}
}
