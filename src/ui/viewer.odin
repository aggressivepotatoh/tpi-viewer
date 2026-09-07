package ui

import clay "../../clay-odin"
import "../core"
import "./components"
import "./styles"
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

WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720

pending_scroll_delta_x: f32
pending_scroll_delta_y: f32
last_ticks: u64

files := []core.File_Info{}

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
				selected_document_index = file_index
				core.load_file(files[file_index])
			}
		}
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
		clay.TextDynamic(
			"D" if file.is_dir else "F",
			{fontId = styles.FONT_MONO_16, fontSize = 12, textColor = text_color},
		)
		clay.TextDynamic(
			file.name,
			{fontId = styles.FONT_MONO_16, fontSize = 12, textColor = text_color},
		)
	}
}

selected_document_index := -1

create_layout :: proc(frametime: f32) -> clay.ClayArray(clay.RenderCommand) {
	layout_expand := clay.Sizing {
		width  = clay.SizingGrow(),
		height = clay.SizingGrow(),
	}


	clay.BeginLayout()
	if clay.UI(clay.ID("OuterContainer"))(
	{
		backgroundColor = styles.COLOR_BACKGROUND,
		layout = {layoutDirection = .TopToBottom, sizing = layout_expand},
	},
	) {
		if clay.UI(clay.ID("HeaderBar"))(
		{
			backgroundColor = styles.COLOR_SURFACE,
			layout = {
				sizing = {width = clay.SizingGrow(), height = clay.SizingFixed(60)},
				padding = clay.PaddingAll(16),
				childGap = 16,
				childAlignment = {y = .Center},
			},
		},
		) {}
		if clay.UI(clay.ID("MainContent"))({layout = {sizing = layout_expand}}) {
			if clay.UI(clay.ID("FileBrowser"))(
			{
				layout = {
					layoutDirection = .TopToBottom,
					sizing = {width = clay.SizingFixed(250), height = clay.SizingGrow()},
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

			if clay.UI(clay.ID("ResizeBar"))(
			{
				layout = {sizing = {width = clay.SizingFixed(5), height = clay.SizingGrow()}},
				backgroundColor = styles.COLOR_ACCENT,
			},
			) {

			}

			if clay.UI(clay.ID("StageContainer"))(
			{
				layout = {
					sizing = layout_expand,
					padding = clay.PaddingAll(16),
					layoutDirection = .TopToBottom,
				},
			},
			) {
				selected_document: Maybe(core.File_Info) =
					files[selected_document_index] if selected_document_index >= 0 else nil

				if clay.UI(clay.ID("StageTitle"))(
				{layout = {sizing = {width = clay.SizingGrow()}, layoutDirection = .TopToBottom}},
				) {
					if file, ok := selected_document.?; ok {
						clay.Text(
							file.name,
							{
								fontId = styles.FONT_MONO_16,
								fontSize = 24,
								textColor = styles.COLOR_TEXT_SECONDARY,
							},
						)
						clay.Text(
							file.path,
							{
								fontId = styles.FONT_MONO_16,
								fontSize = 18,
								textColor = styles.COLOR_TEXT_SECONDARY,
							},
						)
					} else {
						clay.Text(
							"Select a file to view",
							{
								fontId = styles.FONT_MONO_16,
								fontSize = 24,
								textColor = styles.COLOR_TEXT_SECONDARY,
							},
						)
					}
				}

				if clay.UI(clay.ID("Stage"))(
				{
					layout = {
						sizing = layout_expand,
						childAlignment = {x = .Center, y = .Center},
						padding = clay.PaddingAll(16),
					},
					clip = {
						vertical = true,
						horizontal = true,
						childOffset = clay.GetScrollOffset(),
					},
				},
				) {
					if _, ok := selected_document.?; ok {
						base_result, ok_base_result := core.get_base_result(core.file_result)
						if !ok_base_result {
							fmt.eprintln("Something went wrong fetching base result!")
						}
						if base_result.loading {
							clay.Text(
								"Loading file...",
								{
									fontId = styles.FONT_SANS_16,
									fontSize = 16,
									textColor = styles.COLOR_TEXT_SECONDARY,
								},
							)
						} else {
							switch base_result.status {
							case .Success:
								components.display_data_component(core.file_result)
							case .Failed:
								clay.Text(
									"Failed to render file",
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
									"Unsupported file",
									{
										fontId = styles.FONT_SANS_16,
										fontSize = 16,
										textColor = styles.COLOR_TEXT_SECONDARY,
									},
								)
							}
						}
					}
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

	load_font(styles.FONT_MONO_16, 16, styles.MONO_REGULAR_BYTES)
	load_font(styles.FONT_SANS_16, 16, styles.SANS_REGULAR_BYTES)

	width, height: c.int
	sdl.GetWindowSize(window, &width, &height)

	clay.SetMaxElementCount(16_000)
	min_memory_size := clay.MinMemorySize()
	memory := make([^]u8, min_memory_size)
	arena: clay.Arena = clay.CreateArenaWithCapacityAndMemory(uint(min_memory_size), memory)
	clay.Initialize(arena, {cast(f32)width, cast(f32)height}, {handler = error_handler})
	clay.SetMeasureTextFunction(measure_text, nil)

	return .CONTINUE
}

app_iterate :: proc "c" (appstate: rawptr) -> sdl.AppResult {
	context = runtime.default_context()

	current_ticks := sdl.GetTicks()

	if last_ticks == 0 do last_ticks = current_ticks

	delta_time := f32(current_ticks - last_ticks) / 1000

	last_ticks = current_ticks

	mouse_x: f32
	mouse_y: f32

	buttons := sdl.GetMouseState(&mouse_x, &mouse_y)

	clay.SetPointerState({mouse_x, mouse_y}, sdl.MouseButtonFlag.LEFT in buttons)
	clay.UpdateScrollContainers(
		false,
		{pending_scroll_delta_x, pending_scroll_delta_y},
		delta_time,
	)
	pending_scroll_delta_x = 0
	pending_scroll_delta_y = 0

	render_commands := create_layout(f32(delta_time))
	sdl.SetRenderDrawColor(renderer, 0, 0, 0, 255)
	sdl.RenderClear(renderer)

	clay_sdl_render(&render_commands)

	sdl.RenderPresent(renderer)

	free_all(context.temp_allocator)

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
		pending_scroll_delta_x += event.wheel.x
		pending_scroll_delta_y += event.wheel.y
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
