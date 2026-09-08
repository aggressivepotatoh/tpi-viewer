package ui

import clay "../../clay-odin"
import "../core"
import "./styles"
import "base:runtime"

FILE_BROWSER_MIN_SIZE :: 150.0
FILE_BROWSER_MAX_SIZE :: 600.0

sidebar_width: f32 = 250.0

FILTER :: enum {
	All,
	Images,
	Configuration,
	Unknown,
}

current_filter := FILTER.All

handle_filter_button :: proc "c" (
	id: clay.ElementId,
	ptr_data: clay.PointerData,
	user_data: rawptr,
) {
	context = runtime.default_context()

	if ptr_data.state == .PressedThisFrame {
		// TODO in future allow multiple types to be selected (except all)
		filter := FILTER(uintptr(user_data))
		current_filter = filter
	}
}

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

is_file_in_filter :: proc(file: core.File_Info) -> bool {
	if current_filter == .All do return true

	switch file.asset_type {
	case .PNG, .TGA:
		return current_filter == .Images
	case .SAM:
		return current_filter == .Configuration
	case .UNKNOWN:
		return current_filter == .Unknown
	}

	return false
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

render_filter_button :: proc($text: string, filter: FILTER) {
	if clay.UI()({layout = {childGap = 12, sizing = {width = clay.SizingGrow()}}}) {
		is_filter_active := filter == current_filter
		text_color := styles.COLOR_TEXT_SECONDARY
		if clay.Hovered() do text_color = styles.COLOR_ACCENT
		if is_filter_active do text_color = styles.COLOR_TEXT_PRIMARY
		if clay.UI()(
		{
			layout = {sizing = {width = clay.SizingFixed(16), height = clay.SizingFixed(16)}},
			image = {imageData = styles.get_icon(styles.CHECK)} if is_filter_active else {},
		},
		) {}
		clay.OnHover(handle_filter_button, rawptr(uintptr(filter)))
		clay.TextStatic(
			text,
			{fontId = styles.FONT_MONO_16, fontSize = 12, textColor = text_color},
		)
	}
}

render_file_browser :: proc() {
	if clay.UI(clay.ID("FileBrowserContainer"))(
	{
		layout = {
			layoutDirection = .TopToBottom,
			sizing = {width = clay.SizingGrow(), height = clay.SizingGrow()},
		},
	},
	) {
		if clay.UI(clay.ID("FileBrowserControls"))(
		{
			layout = {
				sizing = {height = clay.SizingFixed(50)},
				padding = clay.PaddingAll(16),
				childAlignment = {y = .Center},
			},
		},
		) {
			if clay.UI(clay.ID("FilterButton"))(
			{
				layout = {
					sizing = {width = clay.SizingFixed(24), height = clay.SizingFixed(24)},
					padding = clay.PaddingAll(6),
				},
				cornerRadius = clay.CornerRadiusAll(5),
				border = {width = clay.BorderAll(2), color = styles.COLOR_SURFACE},
				backgroundColor = styles.COLOR_SURFACE if clay.Hovered() else clay.Color{0, 0, 0, 0},
			},
			) {
				if clay.UI(clay.ID("FilterButtonIcon"))(
				{
					layout = {sizing = {width = clay.SizingGrow(), height = clay.SizingGrow()}},
					image = {imageData = styles.get_icon(styles.LIST_FILTER)},
				},
				) {}

				filter_menu_visible :=
					clay.PointerOver(clay.ID("FilterButton")) ||
					clay.PointerOver(clay.ID("FilterMenu"))

				if filter_menu_visible {
					if clay.UI(clay.ID("FilterMenu"))(
					{
						floating = {
							attachment = {parent = .LeftBottom, element = .LeftTop},
							attachTo = .Parent,
						},
						backgroundColor = styles.COLOR_SURFACE,
						cornerRadius = clay.CornerRadiusAll(5),
						layout = {
							layoutDirection = .TopToBottom,
							sizing = {width = clay.SizingFixed(200)},
							padding = clay.PaddingAll(12),
							childGap = 12,
						},
					},
					) {
						render_filter_button("All", FILTER.All)
						render_filter_button("Images", FILTER.Images)
						render_filter_button("Configuration", FILTER.Configuration)
						render_filter_button("Unknown", FILTER.Unknown)
					}
				}
			}
		}
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
				} else if !is_file_in_filter(current_file) {
					continue
				}

				render_file_item(current_file, file_index)
			}
		}
	}
}
