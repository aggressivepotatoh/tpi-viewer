package components

import clay "../../../clay-odin"
import "../../core"
import "../styles"

display_data_component :: proc(result: core.File_Result) {
	switch v in result {
	case core.Sam_Result:
		render_table(v)
	case core.Unknown_Result:
		clay.Text(
			"Cannot display data",
			{fontId = styles.FONT_SANS_16, fontSize = 16, textColor = styles.COLOR_TEXT_SECONDARY},
		)
	}
}
