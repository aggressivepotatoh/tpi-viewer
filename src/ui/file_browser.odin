package ui

import clay "../../clay-odin"
import "../core"
import "./styles"
import "base:runtime"

FILE_BROWSER_MIN_SIZE :: 150.0
FILE_BROWSER_MAX_SIZE :: 600.0

sidebar_width: f32 = 250.0

handle_file_interaction :: proc "c" (
	id: clay.ElementId,
	ptr_data: clay.PointerData,
	user_data: rawptr,
) {
	context = runtime.default_context()

	if ptr_data.state == .PressedThisFrame {
		file_index := int(uintptr(user_data))
		if file_index >= 0 && file_index < len(files) {
			file := files[file_index]
			if file.is_dir {
				files[file_index].is_expanded = !file.is_expanded
			} else {
				select_file(file_index)
			}
		}
	}
}

icon_for_asset_type :: proc(asset_type: core.Asset_Type) -> int {
	switch asset_type {
	case .UNKNOWN:
		return styles.ICON_FILE_QUESTION_MARK
	case .SAM:
		return styles.ICON_FILE_COG
	case .PNG, .TGA:
		return styles.ICON_FILE_IMAGE
	case:
		return styles.ICON_FILE_QUESTION_MARK
	}
}

render_file_item :: proc(file: core.File_Info, file_index: int) {
	item_is_selected := selected_document_index == file_index
	item_bg_color: clay.Color = clay.Color{0, 0, 0, 0}
	if item_is_selected do item_bg_color = styles.COLOR_ACCENT
	if clay.UI(clay.ID("FileItem", u32(file_index)))(
	{
		backgroundColor = styles.COLOR_SURFACE if clay.Hovered() && !item_is_selected else item_bg_color,
		layout = {
			padding = clay.Padding {
				bottom = 12,
				top = 12,
				right = 16,
				left = u16(file.depth + 1) * 8,
			},
			sizing = {width = clay.SizingGrow()},
			childGap = 16,
		},
	},
	) {
		clay.OnHover(handle_file_interaction, rawptr(uintptr(file_index)))
		text_color := styles.COLOR_TEXT_SECONDARY
		if clay.Hovered() do text_color = styles.COLOR_ACCENT
		if file_index == selected_document_index do text_color = styles.COLOR_TEXT_PRIMARY
		if clay.UI(clay.ID("Chevron", u32(file_index)))(
		{
			layout = {sizing = {width = clay.SizingFixed(16), height = clay.SizingFixed(16)}},
			image = {imageData = styles.get_icon(styles.ICON_CHEVRON_DOWN_ID if file.is_expanded else styles.ICON_CHEVRON_RIGHT_ID)} if file.is_dir else {imageData = styles.get_icon(icon_for_asset_type(file.asset_type))},
		},
		) {}
		clay.TextDynamic(
			file.name,
			{fontId = styles.FONT_MONO_16, fontSize = 12, textColor = text_color},
		)
	}
}

render_file_browser :: proc() {
	if clay.UI(clay.ID("FileBrowser"))(
	{
		layout = {
			layoutDirection = .TopToBottom,
			sizing = {width = clay.SizingFixed(sidebar_width), height = clay.SizingGrow()},
		},
		clip = {vertical = true, horizontal = true, childOffset = clay.GetScrollOffset()},
	},
	) {
		current_dir_depth := 0
		is_dir_visible := false
		for file_index in 0 ..< len(files) {
			current_file := files[file_index]

			if !is_dir_visible && current_file.depth > current_dir_depth {
				continue
			}

			if current_file.is_dir {
				current_dir_depth = current_file.depth
				is_dir_visible = current_file.is_expanded
			}

			render_file_item(files[file_index], file_index)
		}
	}
}
