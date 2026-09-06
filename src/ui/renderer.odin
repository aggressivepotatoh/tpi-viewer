package ui

import clay "../../clay-odin"
import "base:runtime"
import "core:math"
import sdl "vendor:sdl3"
import sdl_ttf "vendor:sdl3/ttf"

clay_color_to_sdl_color :: proc(color: clay.Color) -> sdl.Color {
	return {u8(color.r), u8(color.g), u8(color.b), u8(color.a)}
}

sdl_fonts := [dynamic]^sdl_ttf.Font{}

measure_text :: proc "c" (
	text: clay.StringSlice,
	config: ^clay.TextElementConfig,
	userData: rawptr,
) -> clay.Dimensions {
	context = runtime.default_context()

	font := sdl_fonts[config.fontId]

	width: i32
	height: i32

	sdl_ttf.SetFontSize(font, f32(config.fontSize))

	if !sdl_ttf.GetStringSize(font, cstring(text.chars), uint(text.length), &width, &height) {
		sdl.LogError(i32(sdl.LogCategory.ERROR), "Failed to measure text: %s", sdl.GetError())
	}

	return {f32(width), f32(height)}
}

clay_sdl_render :: proc(
	render_commands: ^clay.ClayArray(clay.RenderCommand), // renderer_data: clay.rendererda,
	allocator := context.temp_allocator,
) {
	overlay_colors := make([dynamic]clay.Color, allocator)
	for i in 0 ..< render_commands.length {
		render_command := clay.RenderCommandArray_Get(render_commands, i)
		bounds := render_command.boundingBox
		rect := sdl.FRect {
			x = bounds.x,
			y = bounds.y,
			w = bounds.width,
			h = bounds.height,
		}

		switch render_command.commandType {
		case .None:
		case .Text:
			config := render_command.renderData.text

			font := sdl_fonts[config.fontId]

			sdl_ttf.SetFontSize(font, f32(config.fontSize))

			text := sdl_ttf.CreateText(
				text_engine,
				font,
				cstring(config.stringContents.chars),
				uint(config.stringContents.length),
			)

			sdl_color := clay_color_to_sdl_color(config.textColor)

			sdl_ttf.SetTextColor(text, sdl_color.r, sdl_color.g, sdl_color.b, sdl_color.a)

			sdl_ttf.DrawRendererText(text, rect.x, rect.y)

			sdl_ttf.DestroyText(text)
		case .Image:
			// TODO image tint
			texture := (^sdl.Texture)(render_command.renderData.image.imageData)
			dest := sdl.FRect{rect.x, rect.y, rect.w, rect.h}

			sdl.RenderTexture(renderer, texture, nil, &dest)
		case .ScissorStart:
			clipping_rectangle := sdl.Rect {
				x = i32(math.round(bounds.x)),
				y = i32(math.round(bounds.y)),
				w = i32(math.round(bounds.width)),
				h = i32(math.round(bounds.height)),
			}

			sdl.SetRenderClipRect(renderer, &clipping_rectangle)
		case .ScissorEnd:
			sdl.SetRenderClipRect(renderer, nil)
		case .Rectangle:
			config := render_command.renderData.rectangle
			sdl.SetRenderDrawBlendMode(renderer, {.BLEND})
			draw_color := clay_color_to_sdl_color(config.backgroundColor)
			sdl.SetRenderDrawColor(
				renderer,
				draw_color.r,
				draw_color.g,
				draw_color.b,
				draw_color.a,
			)
			if config.cornerRadius.topLeft > 0 {
				draw_rect_rounded(rect, config.cornerRadius.topLeft, config.backgroundColor)
			} else {
				sdl.RenderFillRect(renderer, &rect)
			}
		case .Border: // Unimplemented
		case .OverlayColorStart:
			config := render_command.renderData.overlayColor
			append(&overlay_colors, config.color)
		case .OverlayColorEnd:
			pop(&overlay_colors)
		case .Custom:
		// Implement custom element rendering here
		}
	}
}

NUM_CIRCLE_SEGMENTS :: 16

draw_rect_rounded :: proc(rect: sdl.FRect, corner_radius: f32, raw_color: clay.Color) {
	color := sdl.FColor{raw_color.r / 255, raw_color.g / 255, raw_color.b / 255, raw_color.a / 255}

	index_count: i32 = 0
	vertex_count: i32 = 0

	min_radius := sdl.min(rect.w, rect.h) / f32(2.0)
	clamped_radius := sdl.min(corner_radius, min_radius)

	num_circle_segments := sdl.max(NUM_CIRCLE_SEGMENTS, int(clamped_radius * 0.5))

	total_vertices := 4 + (4 * (num_circle_segments * 2)) + 2 * 4
	total_indices := 6 + (4 * (num_circle_segments * 3)) + 6 * 4

	vertices := make([]sdl.Vertex, total_vertices)
	indices := make([]i32, total_indices)

	vertices[vertex_count] = sdl.Vertex {
		{rect.x + clamped_radius, rect.y + clamped_radius},
		color,
		{0, 0},
	} //0 center TL
	vertex_count += 1
	vertices[vertex_count] = sdl.Vertex {
		{rect.x + rect.w - clamped_radius, rect.y + clamped_radius},
		color,
		{1, 0},
	} //1 center TR
	vertex_count += 1
	vertices[vertex_count] = sdl.Vertex {
		{rect.x + rect.w - clamped_radius, rect.y + rect.h - clamped_radius},
		color,
		{1, 1},
	} //2 center BR
	vertex_count += 1
	vertices[vertex_count] = sdl.Vertex {
		{rect.x + clamped_radius, rect.y + rect.h - clamped_radius},
		color,
		{0, 1},
	} //3 center BL
	vertex_count += 1

	indices[index_count] = 0
	index_count += 1
	indices[index_count] = 1
	index_count += 1
	indices[index_count] = 3
	index_count += 1
	indices[index_count] = 1
	index_count += 1
	indices[index_count] = 2
	index_count += 1
	indices[index_count] = 3
	index_count += 1

	//define rounded corners as triangle fans
	step := (math.PI / f32(2)) / f32(num_circle_segments)

	for i in 0 ..< num_circle_segments {
		angle1 := f32(i) * step
		angle2 := (f32(i + 1.0)) * step

		for j in 0 ..< 4 { 	// Iterate over four corners
			cx: f32
			cy: f32
			sign_x: f32
			sign_y: f32

			switch (j) {
			case 0:
				// Top-left
				sign_y = -1
				cx = rect.x + clamped_radius
				cy = rect.y + clamped_radius
				sign_x = -1
			case 1:
				// Top-right
				cx = rect.x + rect.w - clamped_radius
				cy = rect.y + clamped_radius
				sign_x = 1
				sign_y = -1
			case 2:
				// Bottom-right
				cx = rect.x + rect.w - clamped_radius
				cy = rect.y + rect.h - clamped_radius
				sign_x = 1
				sign_y = 1
			case 3:
				// Bottom-left
				cx = rect.x + clamped_radius
				cy = rect.y + rect.h - clamped_radius
				sign_x = -1
				sign_y = 1
			}

			vertices[vertex_count] = sdl.Vertex {
				{
					cx + sdl.cosf(angle1) * clamped_radius * sign_x,
					cy + sdl.sinf(angle1) * clamped_radius * sign_y,
				},
				color,
				{0, 0},
			}
			vertex_count += 1
			vertices[vertex_count] = sdl.Vertex {
				{
					cx + sdl.cosf(angle2) * clamped_radius * sign_x,
					cy + sdl.sinf(angle2) * clamped_radius * sign_y,
				},
				color,
				{0, 0},
			}
			vertex_count += 1

			indices[index_count] = i32(j) // Connect to corresponding central rectangle vertex
			index_count += 1
			indices[index_count] = vertex_count - 2
			index_count += 1
			indices[index_count] = vertex_count - 1
			index_count += 1
		}
	}

	//Define edge rectangles
	// Top edge
	vertices[vertex_count] = sdl.Vertex{{rect.x + clamped_radius, rect.y}, color, {0, 0}} //TL
	vertex_count += 1
	vertices[vertex_count] = sdl.Vertex{{rect.x + rect.w - clamped_radius, rect.y}, color, {1, 0}} //TR
	vertex_count += 1

	indices[index_count] = 0
	index_count += 1
	indices[index_count] = vertex_count - 2 //TL
	index_count += 1
	indices[index_count] = vertex_count - 1 //TR
	index_count += 1
	indices[index_count] = 1
	index_count += 1
	indices[index_count] = 0
	index_count += 1
	indices[index_count] = vertex_count - 1 //TR
	index_count += 1
	// Right edge
	vertices[vertex_count] = sdl.Vertex{{rect.x + rect.w, rect.y + clamped_radius}, color, {1, 0}} //RT
	vertex_count += 1
	vertices[vertex_count] = sdl.Vertex {
		{rect.x + rect.w, rect.y + rect.h - clamped_radius},
		color,
		{1, 1},
	} //RB
	vertex_count += 1

	indices[index_count] = 1
	index_count += 1
	indices[index_count] = vertex_count - 2 //RT
	index_count += 1
	indices[index_count] = vertex_count - 1 //RB
	index_count += 1
	indices[index_count] = 2
	index_count += 1
	indices[index_count] = 1
	index_count += 1
	indices[index_count] = vertex_count - 1 //RB
	index_count += 1
	// Bottom edge
	vertices[vertex_count] = sdl.Vertex {
		{rect.x + rect.w - clamped_radius, rect.y + rect.h},
		color,
		{1, 1},
	} //BR
	vertex_count += 1
	vertices[vertex_count] = sdl.Vertex{{rect.x + clamped_radius, rect.y + rect.h}, color, {0, 1}} //BL
	vertex_count += 1

	indices[index_count] = 2
	index_count += 1
	indices[index_count] = vertex_count - 2 //BR
	index_count += 1
	indices[index_count] = vertex_count - 1 //BL
	index_count += 1
	indices[index_count] = 3
	index_count += 1
	indices[index_count] = 2
	index_count += 1
	indices[index_count] = vertex_count - 1 //BL
	index_count += 1
	// Left edge
	vertices[vertex_count] = sdl.Vertex{{rect.x, rect.y + rect.h - clamped_radius}, color, {0, 1}} //LB
	vertex_count += 1
	vertices[vertex_count] = sdl.Vertex{{rect.x, rect.y + clamped_radius}, color, {0, 0}} //LT
	vertex_count += 1

	indices[index_count] = 3
	index_count += 1
	indices[index_count] = vertex_count - 2 //LB
	index_count += 1
	indices[index_count] = vertex_count - 1 //LT
	index_count += 1
	indices[index_count] = 0
	index_count += 1
	indices[index_count] = 3
	index_count += 1
	indices[index_count] = vertex_count - 1 //LT
	index_count += 1

	// Render everything
	sdl.RenderGeometry(
		renderer,
		nil,
		raw_data(vertices),
		vertex_count,
		raw_data(indices),
		index_count,
	)

	delete(vertices)
	delete(indices)
}
