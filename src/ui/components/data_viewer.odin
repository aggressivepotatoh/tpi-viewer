package components

import clay "../../../clay-odin"
import "../../core"
import "../styles"
import sdl "vendor:sdl3"

display_data_component :: proc(renderer: ^sdl.Renderer, result: core.File_Result) {
	switch v in result {
	case core.Sam_Result:
		render_table(v)
	case core.Image_Result:
		render_image(renderer, v)
	case core.Wad_Result:
		clay.Text(
			"WAD is a directory - check the file list in the file browser",
			{fontId = styles.FONT_SANS_16, fontSize = 16, textColor = styles.COLOR_TEXT_SECONDARY},
		)
	case core.Unknown_Result:
		clay.Text(
			"Cannot display data",
			{fontId = styles.FONT_SANS_16, fontSize = 16, textColor = styles.COLOR_TEXT_SECONDARY},
		)
	}
}
