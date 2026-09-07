package components

import clay "../../../clay-odin"
import "../../core"
import "../styles"

ROW_HEIGHT :: 44
OVERSCAN :: 8
INITIAL_WINDOW :: 100

render_table :: proc(result: core.Sam_Result) {
	row_count := len(result.data)

	first_index := 0
	last_index := min(row_count, INITIAL_WINDOW)

	scroll_data := clay.GetScrollContainerData(clay.ID("Stage"))

	if scroll_data.found && scroll_data.scrollContainerDimensions.height > 0 {
		scroll_offset_y := -scroll_data.scrollPosition.y
		viewport_height := scroll_data.scrollContainerDimensions.height

		first_index = int(scroll_offset_y / ROW_HEIGHT) - OVERSCAN
		last_index = int((scroll_offset_y + viewport_height) / ROW_HEIGHT) + 1 + OVERSCAN

		first_index = clamp(first_index, 0, row_count)
		last_index = clamp(last_index, 0, row_count)
	}

	top_spacer_height := f32(first_index) * ROW_HEIGHT
	bottom_spacer_height := f32(row_count - last_index) * ROW_HEIGHT

	if clay.UI(clay.ID("Table"))(
	{
		layout = {
			layoutDirection = .TopToBottom,
			sizing = {width = clay.SizingGrow(), height = clay.SizingGrow()},
		},
		border = {width = clay.BorderAll(2), color = styles.COLOR_ACCENT},
	},
	) {
		if top_spacer_height > 0 {
			if clay.UI(clay.ID("TableTopSpacer"))(
			{
				layout = {
					sizing = {
						width = clay.SizingGrow(),
						height = clay.SizingFixed(top_spacer_height),
					},
				},
			},
			) {}
		}


		for i in first_index ..< last_index {
			entry := result.data[i]
			if clay.UI(clay.ID("TableRow", u32(i)))(
			{
				layout = {
					padding = clay.Padding{top = 12, left = 16, right = 16, bottom = 12} if entry.type == .Comment else clay.PaddingAll(16),
					sizing = {width = clay.SizingGrow()},
				},
				backgroundColor = styles.COLOR_ACCENT if entry.type == .Comment else styles.COLOR_SURFACE,
			},
			) {
				if clay.UI()({layout = {sizing = {width = clay.SizingGrow()}}}) {
					clay.Text(
						entry.line,
						{
							fontId = styles.FONT_MONO_16,
							fontSize = 12,
							textColor = styles.COLOR_TEXT_PRIMARY,
						},
					)
				}

				if entry.type == .Value {
					if clay.UI()({}) {
						clay.Text(
							entry.value,
							{
								fontId = styles.FONT_MONO_16,
								fontSize = 12,
								textColor = styles.COLOR_TEXT_SECONDARY,
							},
						)
					}
				}
			}
		}

		if bottom_spacer_height > 0 {
			if clay.UI(clay.ID("TableBottomSpacer"))(
			{
				layout = {
					sizing = {
						width = clay.SizingGrow(),
						height = clay.SizingFixed(bottom_spacer_height),
					},
				},
			},
			) {}
		}
	}
}
