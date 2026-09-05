package ui

import clay "../../clay-odin"
import "../core"
import "base:runtime"
import "core:fmt"
import rl "vendor:raylib"

error_handler :: proc "c" (errorData: clay.ErrorData) {
	context = runtime.default_context()
	fmt.eprintfln("Clay Error %e", errorData)
}

FONT_MONO_16 :: 0
FONT_SANS_16 :: 1

MONO_REGULAR_BYTES :: #load("../../resources/JetBrains_Mono/static/JetBrainsMono-Regular.ttf")
SANS_REGULAR_BYTES :: #load("../../resources/Open_Sans/static/OpenSans-Regular.ttf")

WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720

COLOR_LIGHT :: clay.Color{224, 215, 210, 255}
COLOR_RED :: clay.Color{168, 66, 28, 255}
COLOR_ORANGE :: clay.Color{225, 138, 50, 255}
COLOR_BLACK :: clay.Color{0, 0, 0, 255}

COLOR_BACKGROUND :: clay.Color{18, 18, 18, 255}
COLOR_SURFACE := clay.Color{30, 30, 34, 255}
COLOR_BORDER := clay.Color{48, 48, 56, 255}
COLOR_TEXT_PRIMARY := clay.Color{240, 240, 245, 255}
COLOR_TEXT_SECONDARY := clay.Color{160, 160, 175, 255}
COLOR_ACCENT := clay.Color{0, 122, 204, 255}
COLOR_HIGHLIGHT := clay.Color{46, 204, 113, 255}

files := []core.File_Info{}

handle_file_interaction :: proc "c" (
	id: clay.ElementId,
	ptr_data: clay.PointerData,
	user_data: rawptr,
) {
	if ptr_data.state == .PressedThisFrame {
		file_index := int(uintptr(user_data))
		if file_index >= 0 && file_index < len(files) {
			selected_document_index = file_index
		}
	}
}

render_file_item :: proc(file: core.File_Info, file_index: int) {
	if clay.UI()(
	{
		backgroundColor = COLOR_ACCENT if file_index == selected_document_index else clay.Color{0, 0, 0, 0},
		cornerRadius = clay.CornerRadiusAll(10),
		layout = {
			padding = clay.PaddingAll(16),
			sizing = {width = clay.SizingGrow()},
			childGap = 16,
		},
	},
	) {
		clay.OnHover(handle_file_interaction, rawptr(uintptr(file_index)))
		text_color := COLOR_TEXT_SECONDARY
		if clay.Hovered() do text_color = COLOR_ACCENT
		if file_index == selected_document_index do text_color = COLOR_TEXT_PRIMARY
		clay.TextDynamic(
			"D" if file.is_dir else "F",
			{fontId = FONT_MONO_16, fontSize = 16, textColor = text_color},
		)
		clay.TextDynamic(file.name, {fontId = FONT_MONO_16, fontSize = 16, textColor = text_color})
	}
}

selected_document_index := 0

createLayout :: proc(frametime: f32) -> clay.ClayArray(clay.RenderCommand) {
	layout_expand := clay.Sizing {
		width  = clay.SizingGrow(),
		height = clay.SizingGrow(),
	}


	clay.BeginLayout()
	if clay.UI(clay.ID("OuterContainer"))(
	{
		backgroundColor = COLOR_BACKGROUND,
		layout = {layoutDirection = .TopToBottom, sizing = layout_expand, childGap = 16},
	},
	) {
		if clay.UI(clay.ID("HeaderBar"))(
		{
			backgroundColor = COLOR_SURFACE,
			layout = {
				sizing = {width = clay.SizingGrow(), height = clay.SizingFixed(60)},
				padding = clay.PaddingAll(16),
				childGap = 16,
				childAlignment = {y = .Center},
			},
		},
		) {}
		if clay.UI(clay.ID("MainContent"))({layout = {sizing = layout_expand, childGap = 16}}) {
			if clay.UI(clay.ID("FileBrowser"))(
			{
				layout = {
					layoutDirection = .TopToBottom,
					sizing = {width = clay.SizingFixed(250), height = clay.SizingGrow()},
					padding = clay.PaddingAll(16),
				},
			},
			) {
				for file_index in 0 ..< len(files) {
					render_file_item(files[file_index], file_index)
				}
			}
			if clay.UI(clay.ID("StageContainer"))(
			{layout = {sizing = layout_expand, padding = clay.PaddingAll(16)}},
			) {
				if clay.UI(clay.ID("Stage"))({layout = {sizing = layout_expand}}) {
					selected_document := files[selected_document_index]
					clay.Text(
						selected_document.name,
						{fontId = FONT_MONO_16, fontSize = 24, textColor = COLOR_TEXT_SECONDARY},
					)
					clay.Text(
						selected_document.path,
						{fontId = FONT_MONO_16, fontSize = 18, textColor = COLOR_TEXT_SECONDARY},
					)
				}
			}
		}
	}
	return clay.EndLayout(frametime)
}

load_font :: proc {
	load_font_from_embed,
	load_font_from_path,
}

load_font_from_embed :: proc(fontId: u16, fontSize: u16, bytes: []u8) {
	assign_at(
		&raylib_fonts,
		fontId,
		Raylib_Font {
			font = rl.LoadFontFromMemory(
				".ttf",
				raw_data(bytes),
				i32(len(bytes)),
				cast(i32)fontSize * 2,
				nil,
				0,
			),
			fontId = cast(u16)fontId,
		},
	)
	rl.SetTextureFilter(raylib_fonts[fontId].font.texture, rl.TextureFilter.TRILINEAR)
}

load_font_from_path :: proc(fontId: u16, fontSize: u16, path: cstring) {
	assign_at(
		&raylib_fonts,
		fontId,
		Raylib_Font {
			font = rl.LoadFontEx(path, cast(i32)fontSize * 2, nil, 0),
			fontId = cast(u16)fontId,
		},
	)
	rl.SetTextureFilter(raylib_fonts[fontId].font.texture, rl.TextureFilter.TRILINEAR)
}

boot :: proc(loaded_files: [dynamic]core.File_Info) {
	files = loaded_files[:] // yeah this is probably bad
	min_memory_size := clay.MinMemorySize()
	memory := make([^]u8, min_memory_size)
	arena: clay.Arena = clay.CreateArenaWithCapacityAndMemory(uint(min_memory_size), memory)
	clay.Initialize(
		arena,
		{cast(f32)rl.GetScreenWidth(), cast(f32)rl.GetScreenHeight()},
		{handler = error_handler},
	)
	clay.SetMeasureTextFunction(measure_text, nil)

	rl.SetConfigFlags({.VSYNC_HINT, .WINDOW_RESIZABLE, .MSAA_4X_HINT})

	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Theme Park Inc. Viewer")
	defer rl.CloseWindow()

	load_font(FONT_MONO_16, 16, MONO_REGULAR_BYTES)
	load_font(FONT_SANS_16, 16, SANS_REGULAR_BYTES)

	rl.SetTargetFPS(rl.GetMonitorRefreshRate(0))

	debug_mode_enabled: bool = false

	for !rl.WindowShouldClose() {
		defer free_all(context.temp_allocator)

		if rl.IsKeyPressed(.D) {
			debug_mode_enabled = !debug_mode_enabled
			clay.SetDebugModeEnabled(debug_mode_enabled)
		}

		clay.SetPointerState(rl.GetMousePosition(), rl.IsMouseButtonDown(.LEFT))
		clay.SetLayoutDimensions({cast(f32)rl.GetScreenWidth(), cast(f32)rl.GetScreenHeight()})
		render_commands := createLayout(rl.GetFrameTime())

		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)
		clay_raylib_render(&render_commands)
		rl.EndDrawing()
	}
}
