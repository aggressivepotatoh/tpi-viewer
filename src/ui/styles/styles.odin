package styles

import clay "../../../clay-odin"

FONT_MONO_16 :: 0
FONT_SANS_16 :: 1

MONO_REGULAR_BYTES :: #load("../../../resources/JetBrains_Mono/static/JetBrainsMono-Regular.ttf")
SANS_REGULAR_BYTES :: #load("../../../resources/Open_Sans/static/OpenSans-Regular.ttf")

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
