package core

import "./formats/"
import "core:fmt"
import "core:path/filepath"
import "core:slice"

asset_result: File_Result

load_asset :: proc(asset_index: int) {
	file := file_result.(Wad_Result)
	asset := file.assets[asset_index]

	fmt.printfln("Loading asset %v", asset)

	free_file_result(asset_result)

	ext := filepath.ext(asset.filename)
	asset_type := asset_type_from_extension(ext)

	switch asset_type {
	case .SAM:
		sam_result := Sam_Result {
			path    = asset.filename,
			loading = true,
			type    = asset_type,
		}
		asset_result = sam_result

		data := slice.clone(file.raw_data[asset.data_offset:asset.data_offset + asset.file_length])

		lines, raw_data, err := formats.parse_sam_file_bytes(data)

		if err != nil {
			fmt.eprintfln("Failed to parse .sam asset %s: %v", asset.filename, err)
			sam_result.loading = false
			sam_result.status = .Failed
			asset_result = sam_result
			return
		}

		sam_result.data = lines
		sam_result.raw_data = raw_data
		sam_result.status = .Success
		sam_result.loading = false
		asset_result = sam_result
	case .WAD:
		fmt.printfln("Nested WADs? Who'd have thought.")
		fallthrough
	case .TGA:
		fallthrough
	case .PNG:
		fallthrough
	case .UNKNOWN:
		fmt.printfln("Asset type is unsupported: %s", asset.filename)
		unknown_result := Unknown_Result {
			loading = false,
			status  = .Unsupported,
			path    = asset.filename,
			type    = .UNKNOWN,
		}
		asset_result = unknown_result
	}
}
