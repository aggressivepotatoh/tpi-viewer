package core

import "./formats"

File_Info :: struct {
	name:        string,
	path:        string,
	is_dir:      bool,
	depth:       int,
	is_expanded: bool,
	asset_type:  Asset_Type,
}

File_Load_Status :: enum {
	Idle,
	Unsupported,
	Success,
	Failed,
}

Asset_Type :: enum {
	UNKNOWN,
	SAM,
	PNG,
	TGA,
}

asset_type_from_extension :: proc(extension: string) -> Asset_Type {
	switch extension {
	case ".sam":
		return .SAM
	case ".png":
		return .PNG
	case ".tga":
		return .TGA
	case:
		return .UNKNOWN
	}
}

Base_Result :: struct {
	path:    string,
	loading: bool,
	status:  File_Load_Status,
	type:    Asset_Type,
}

Sam_Result :: struct {
	using component: Base_Result,
	data:            []formats.Line,
	raw_data:        []byte,
}

Image_Result :: struct {
	using component: Base_Result,
	raw_data:        []byte,
}

Unknown_Result :: struct {
	using component: Base_Result,
}

File_Result :: union {
	Sam_Result,
	Image_Result,
	Unknown_Result,
}

get_base_result :: proc(result: File_Result) -> (Base_Result, bool) {
	switch v in result {
	case Sam_Result:
		return v.component, true
	case Image_Result:
		return v.component, true
	case Unknown_Result:
		return v.component, true
	}

	return {}, false
}
