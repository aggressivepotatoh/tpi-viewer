package styles

import sdl "vendor:sdl3"
import "vendor:sdl3/image"

Icon :: struct {
	bytes:   []u8,
	texture: ^sdl.Texture,
}

ICON_CHEVRON_RIGHT_ID :: 0
ICON_CHEVRON_DOWN_ID :: 1

icons: []Icon = {
	{bytes = #load("../../../resources/lucide-icons/chevron-right.svg")},
	{bytes = #load("../../../resources/lucide-icons/chevron-down.svg")},
}

get_icon :: proc(id: int) -> ^sdl.Texture {
	return icons[id].texture
}

load_all_icons :: proc(renderer: ^sdl.Renderer) {
	for i in 0 ..< len(icons) {
		icon := icons[i]
		icons[i].texture = image.LoadTexture_IO(
			renderer,
			sdl.IOFromConstMem(raw_data(icon.bytes), len(icon.bytes)),
			true,
		)
	}
}

free_all_icons :: proc() {
	for icon in icons {
		sdl.DestroyTexture(icon.texture)
	}
}
