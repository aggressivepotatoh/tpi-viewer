package components

import clay "../../../clay-odin"
import "../../core"
import "../styles"
import "core:fmt"
import "vendor:sdl3"
import "vendor:sdl3/image"

INITIAL_ZOOM :: 100

image_texture: ^sdl3.Texture
width: f32
height: f32
texture_errored: bool

render_image :: proc(renderer: ^sdl3.Renderer, result: core.Image_Result) {
	if clay.UI(clay.ID("ImageContainer"))({layout = {layoutDirection = .TopToBottom}}) {
		if image_texture == nil {
			if !texture_errored {
				clay.Text(
					"No texture loaded",
					{
						fontId = styles.FONT_MONO_16,
						fontSize = 12,
						textColor = styles.COLOR_TEXT_PRIMARY,
					},
				)

				// SDL3/Image seems to have some issues with tga files, so we need this explicitly here
				if result.type == .TGA {
					image_texture = image.LoadTextureTyped_IO(
						renderer,
						sdl3.IOFromConstMem(raw_data(result.raw_data), len(result.raw_data)),
						true,
						"TGA",
					)
				} else {
					image_texture = image.LoadTexture_IO(
						renderer,
						sdl3.IOFromConstMem(raw_data(result.raw_data), len(result.raw_data)),
						true,
					)
				}

				if image_texture == nil {
					fmt.eprintfln("Image failed to load: %v", sdl3.GetError())
					texture_errored = true
				}

				success := sdl3.GetTextureSize(image_texture, &width, &height)
				if !success {
					fmt.eprintfln("Could not get width and height of texture")
					texture_errored = true
				}

				fmt.printfln("Loaded image texture, width: %v, height: %v", width, height)
			} else {
				clay.Text(
					"Texture could not be rendered",
					{
						fontId = styles.FONT_MONO_16,
						fontSize = 12,
						textColor = styles.COLOR_TEXT_PRIMARY,
					},
				)
			}
		} else {
			if clay.UI(clay.ID("Image"))(
			{
				layout = {
					sizing = {width = clay.SizingFixed(width), height = clay.SizingFixed(height)},
				},
				image = {imageData = image_texture},
			},
			) {}
		}
	}
}

clear_image :: proc() {
	sdl3.DestroyTexture(image_texture)
	image_texture = nil
	texture_errored = false
}
