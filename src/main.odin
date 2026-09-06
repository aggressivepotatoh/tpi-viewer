package main

import "./core"
import "./ui"
import "core:fmt"
import "core:os"

main :: proc() {
	if len(os.args) != 2 {
		fmt.eprintln("Usage: tpi-viewer <path-to-install>")
		os.exit(1)
	}

	target_dir := os.args[1]
	fmt.println("Scanning directory: ", target_dir)


	files, success := core.walk_directory(target_dir)

	if !success {
		fmt.eprintln("Failed to read directory.")
		os.exit(1)
	}

	fmt.printfln("Found %d files", len(files))

	ui.boot(files)
}
