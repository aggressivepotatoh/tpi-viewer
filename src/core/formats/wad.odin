package formats

import "core:encoding/endian"
import "core:os"
import "core:strings"

WadParseError :: union {
	os.Error,
}

Wad_Header :: struct #packed {
	magic:            [4]byte,
	version:          u32,
	padding:          [64]byte,
	file_count:       [4]byte,
	file_list_offset: [4]byte,
	file_list_length: [4]byte,
	end_padding:      [4]byte,
}

Wad_Entry :: struct #packed {
	category:          [4]byte,
	filename_offset:   [4]byte,
	filename_length:   [4]byte,
	data_offset:       [4]byte,
	file_length:       [4]byte,
	compression_type:  [4]byte,
	decompressed_size: [4]byte,
	padding:           [12]byte,
}

Wad_Asset :: struct {
	filename:          string,
	category:          u32,
	data_offset:       u32,
	file_length:       u32,
	compression_type:  u32,
	decompressed_size: u32,
}

parse_wad_file :: proc(file: string) -> (Wad_Header, []Wad_Asset, []byte, WadParseError) {
	data, err := os.read_entire_file(file, context.allocator)
	if err != nil {
		return {}, nil, nil, err
	}

	header := (^Wad_Header)(raw_data(data))^

	file_count, fc_ok := endian.get_u32(header.file_count[:], .Little)
	assets := make([]Wad_Asset, file_count)

	first_entry_offset := size_of(Wad_Header)
	entry_length := size_of(Wad_Entry)

	for i in 0 ..< file_count {
		entry_offset := first_entry_offset + (entry_length * int(i))
		entry_end := entry_offset + entry_length
		entry := (^Wad_Entry)(raw_data(data[entry_offset:entry_end]))^
		filename_offset, fo_ok := endian.get_u32(entry.filename_offset[:], .Little)
		filename_length, fnl_ok := endian.get_u32(entry.filename_length[:], .Little)
		cat, cat_ok := endian.get_u32(entry.category[:], .Little)
		data_offset, do_ok := endian.get_u32(entry.data_offset[:], .Little)
		file_length, fl_ok := endian.get_u32(entry.file_length[:], .Little)
		compression_type, ct_ok := endian.get_u32(entry.compression_type[:], .Little)
		decompressed_size, ds_ok := endian.get_u32(entry.decompressed_size[:], .Little)
		asset := Wad_Asset {
			filename          = strings.clone(
				string(data[filename_offset:filename_offset + filename_length - 1]),
			),
			category          = cat,
			data_offset       = data_offset,
			file_length       = file_length,
			compression_type  = compression_type,
			decompressed_size = decompressed_size,
		}
		assets[i] = asset
	}

	return header, assets, data, nil
}
