package main

import "./core"
import "./ui"
import "core:fmt"
import "core:os"

main :: proc() {
	if len(os.args) == 2 {
		target_dir := os.args[1]
		fmt.println("Scanning directory: ", target_dir)


		files, success := core.walk_directory(target_dir)

		if !success {
			fmt.eprintln("Failed to read directory.")
			os.exit(1)
		}

		fmt.printfln("Found %d files", len(files))

		ui.boot(files)
	} else if len(os.args) == 3 {
		if os.args[1] != "--wad" {
			os.exit(1)
		}

		target_file := os.args[2]

		file_info := core.get_file_info_from_path(target_file)

		// fmt.printfln("File Info: %v", file_info)

		core.load_file(file_info)

		wad_result := core.file_result.(core.Wad_Result)

		core.load_asset(2)

		asset_result := core.asset_result.(core.Sam_Result)

		if asset_result.status != .Success {
			fmt.eprintln("Error parsing asset")
			os.exit(1)
		}
	} else {
		fmt.eprintln("Usage: tpi-viewer <path-to-install>")
		os.exit(1)
	}

}
