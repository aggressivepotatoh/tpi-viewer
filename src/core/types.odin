package core

import "./formats"

File_Info :: struct {
	name:        string,
	path:        string,
	is_dir:      bool,
	depth:       int,
	is_expanded: bool,
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

Unknown_Result :: struct {
	using component: Base_Result,
}

File_Result :: union {
	Sam_Result,
	Unknown_Result,
}

get_base_result :: proc(result: File_Result) -> (Base_Result, bool) {
	switch v in result {
	case Sam_Result:
		return v.component, true
	case Unknown_Result:
		return v.component, true
	}

	return {}, false
}
