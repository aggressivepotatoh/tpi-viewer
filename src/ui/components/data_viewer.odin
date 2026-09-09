package components

import clay "../../../clay-odin"
import "../../core"
import "../styles"
import "core:fmt"
import sdl "vendor:sdl3"

display_data_component :: proc(renderer: ^sdl.Renderer, result: core.File_Result) {
	switch v in result {
	case core.Sam_Result:
		render_table(v)
	case core.Image_Result:
		render_image(renderer, v)
	case core.Wad_Result:
		if core.asset_result == nil {
			clay.Text(
				"WAD is a directory - check the file list in the file browser",
				{
					fontId = styles.FONT_SANS_16,
					fontSize = 16,
					textColor = styles.COLOR_TEXT_SECONDARY,
				},
			)
		} else {
			base_result, ok_base_result := core.get_base_result(core.asset_result)
			if !ok_base_result {
				fmt.eprintln("Something went wrong fetching base result!")
			}
			clay.Text(
				base_result.path,
				{
					fontId = styles.FONT_SANS_16,
					fontSize = 16,
					textColor = styles.COLOR_TEXT_SECONDARY,
				},
			)
			if base_result.loading {
				clay.Text(
					"Loading asset...",
					{
						fontId = styles.FONT_SANS_16,
						fontSize = 16,
						textColor = styles.COLOR_TEXT_SECONDARY,
					},
				)
			} else {
				switch base_result.status {
				case .Success:
					display_data_component(renderer, core.asset_result)
				case .Failed:
					clay.Text(
						"Failed to render asset",
						{
							fontId = styles.FONT_SANS_16,
							fontSize = 16,
							textColor = styles.COLOR_TEXT_SECONDARY,
						},
					)
				case .Idle:
					fallthrough
				case .Unsupported:
					clay.Text(
						"Unsupported asset",
						{
							fontId = styles.FONT_SANS_16,
							fontSize = 16,
							textColor = styles.COLOR_TEXT_SECONDARY,
						},
					)
				}
			}
		}

	case core.Unknown_Result:
		clay.Text(
			"Cannot display data",
			{fontId = styles.FONT_SANS_16, fontSize = 16, textColor = styles.COLOR_TEXT_SECONDARY},
		)
	}
}
