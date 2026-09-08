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
	case core.Unknown_Result:
		clay.Text(
			"Cannot display data",
			{fontId = styles.FONT_SANS_16, fontSize = 16, textColor = styles.COLOR_TEXT_SECONDARY},
		)
	}
}
