package ui

import clay "../../clay-odin"
import "../core"
import "base:runtime"
import "core:c"
import "core:fmt"
import sdl "vendor:sdl3"
import sdl_ttf "vendor:sdl3/ttf"

window: ^sdl.Window = nil
renderer: ^sdl.Renderer = nil
text_engine: ^sdl_ttf.TextEngine = nil
debug_mode_enabled: bool = false

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

create_layout :: proc(frametime: f32) -> clay.ClayArray(clay.RenderCommand) {
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
}

load_font_from_embed :: proc(fontId: u16, fontSize: u16, bytes: []u8) {
	assign_at(
		&sdl_fonts,
		fontId,
		sdl_ttf.OpenFontIO(sdl.IOFromConstMem(raw_data(bytes), len(bytes)), true, f32(fontSize)),
	)
}

boot :: proc(loaded_files: [dynamic]core.File_Info) {
	files = loaded_files[:] // yeah this is probably bad
	sdl.EnterAppMainCallbacks(0, nil, app_init, app_iterate, app_event, app_quit)
}

app_init :: proc "c" (appstate: ^rawptr, argc: c.int, argv: [^]cstring) -> sdl.AppResult {
	context = runtime.default_context()

	if !sdl.SetAppMetadata("Theme Park Inc. Viewer", "0.1", "com.aggressivepotato.tpi-viewer") {
		return .FAILURE
	}

	if !sdl.Init({.VIDEO}) {
		sdl.Log("Couldn't initialize SDL: %s", sdl.GetError())
		return .FAILURE
	}

	if !sdl_ttf.Init() {
		sdl.Log("Couldn't initialize SDL_ttf: %s", sdl.GetError())
		return .FAILURE
	}

	if !sdl.CreateWindowAndRenderer(
		"Theme Park Inc. Viewer",
		WINDOW_WIDTH,
		WINDOW_HEIGHT,
		{.RESIZABLE},
		&window,
		&renderer,
	) {
		sdl.Log("Couldn't create window/renderer: %s", sdl.GetError())
		return .FAILURE
	}

	sdl.SetRenderVSync(renderer, 1)

	text_engine = sdl_ttf.CreateRendererTextEngine(renderer)
	if text_engine == nil {
		sdl.Log("Failed to create text engine from renderer: %s", sdl.GetError())
		return .FAILURE
	}

	load_font(FONT_MONO_16, 16, MONO_REGULAR_BYTES)
	load_font(FONT_SANS_16, 16, SANS_REGULAR_BYTES)

	width, height: c.int
	sdl.GetWindowSize(window, &width, &height)

	min_memory_size := clay.MinMemorySize()
	memory := make([^]u8, min_memory_size)
	arena: clay.Arena = clay.CreateArenaWithCapacityAndMemory(uint(min_memory_size), memory)
	clay.Initialize(arena, {cast(f32)width, cast(f32)height}, {handler = error_handler})
	clay.SetMeasureTextFunction(measure_text, nil)

	return .CONTINUE
}

app_iterate :: proc "c" (appstate: rawptr) -> sdl.AppResult {
	context = runtime.default_context()

	mouse_x: f32
	mouse_y: f32

	buttons := sdl.GetMouseState(&mouse_x, &mouse_y)

	clay.SetPointerState({mouse_x, mouse_y}, sdl.MouseButtonFlag.LEFT in buttons)

	render_commands := create_layout(f32(sdl.GetTicksNS()))
	sdl.SetRenderDrawColor(renderer, 0, 0, 0, 255)
	sdl.RenderClear(renderer)

	clay_sdl_render(&render_commands)

	sdl.RenderPresent(renderer)

	return .CONTINUE
}

app_event :: proc "c" (appsttate: rawptr, event: ^sdl.Event) -> sdl.AppResult {
	context = runtime.default_context()

	#partial switch event.type {
	case .QUIT:
		return .SUCCESS
	case .WINDOW_RESIZED:
		clay.SetLayoutDimensions({f32(event.window.data1), f32(event.window.data2)})
	case .MOUSE_WHEEL:
		clay.UpdateScrollContainers(true, {event.wheel.x, event.wheel.y}, 0.01)
	case .KEY_DOWN:
		fmt.println("Key pressed this frame", event.key.scancode)
		if event.key.scancode == .D {
			debug_mode_enabled = !debug_mode_enabled
			clay.SetDebugModeEnabled(debug_mode_enabled)
		}
	}

	return .CONTINUE
}

app_quit :: proc "c" (appstate: rawptr, result: sdl.AppResult) {
	for font in sdl_fonts {
		sdl_ttf.CloseFont(font)
	}

	sdl_ttf.DestroyRendererTextEngine(text_engine)

	sdl.DestroyRenderer(renderer)
	sdl.DestroyWindow(window)

	sdl_ttf.Quit()
	sdl.Quit()
}
