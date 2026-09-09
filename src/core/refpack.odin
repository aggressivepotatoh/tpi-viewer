// Implementation gratefully adapted from http://wiki.niotso.org/RefPack
package core

import "core:encoding/endian"
import "core:fmt"

RefPack_Error :: enum {
	NONE,
	READ_OVERFLOW, // -1
	READ_WRITE_OVERFLOW, // -2
}

Scanner :: struct {
	data:     []byte,
	ptr:      int,
	overflow: bool,
}

position :: proc(ctx: ^Scanner) -> int {
	return ctx.ptr
}

remaining :: proc(ctx: ^Scanner) -> int {
	return len(ctx.data) - ctx.ptr
}

overflowed :: proc(ctx: ^Scanner) -> bool {
	return ctx.overflow
}

read_u8 :: proc(ctx: ^Scanner) -> u8 {
	if len(ctx.data) == ctx.ptr {
		ctx.overflow = true
		return 0
	}

	result := ctx.data[ctx.ptr]
	ctx.ptr += 1

	return result
}

read_u16 :: proc(ctx: ^Scanner) -> u16 {
	if remaining(ctx) < 2 {
		ctx.ptr = len(ctx.data)
		ctx.overflow = true
		return 0
	}

	result, ok := endian.get_u16(ctx.data[ctx.ptr:], .Big)

	if !ok {
		fmt.printfln("read_u16 :: error getting value")
	}

	ctx.ptr += 2
	return result
}

read_u24 :: proc(ctx: ^Scanner) -> u32 {
	if remaining(ctx) < 3 {
		ctx.ptr = len(ctx.data)
		ctx.overflow = true
		return 0
	}

	result, ok := endian.get_u32(ctx.data[ctx.ptr:], .Big)

	if !ok {
		fmt.printfln("read_u24 :: error getting value")
	}

	// TODO very small bug here - we blindly read 32bytes when we've only checked for 24
	// Blank out last bytes of value (big endian) - we only want 24 not 32
	result = result >> 8

	ctx.ptr += 3
	return result
}

scanner_append :: proc(output: ^Scanner, input: ^Scanner, length: int) {
	if length == 0 {
		return
	}

	in_remaining := remaining(input)
	out_remaining := remaining(output)

	if in_remaining < length || out_remaining < length {
		fmt.printfln(
			"Scanner_Append :: $v < $v OR $v < $v",
			in_remaining,
			length,
			out_remaining,
			length,
		)
		if in_remaining < length {
			input.ptr = len(input.data)
			input.overflow = true
		}
		if out_remaining < length {
			output.ptr = len(output.data)
			output.overflow = true
		}

		return
	}

	copy(output.data[output.ptr:output.ptr + length], input.data[input.ptr:input.ptr + length])

	output.ptr += length
	input.ptr += length
}

self_copy :: proc(ctx: ^Scanner, distance: int, length: int) {
	pos := position(ctx)
	rem := remaining(ctx)

	if pos < distance || rem < length {
		fmt.printfln("SelfCopy :: %v < %v or %v < %v", pos, distance, rem, length)
		ctx.ptr = len(ctx.data)
		ctx.overflow = true
		return
	}

	src := ctx.ptr - distance
	dst := ctx.ptr

	for i in 0 ..< length {
		ctx.data[dst + i] = ctx.data[src + i]
	}

	ctx.ptr += length
}

decompress :: proc(input: []u8, output: []u8) -> (u32, u32, RefPack_Error) {
	input_scanner := Scanner {
		data = input,
	}

	output_scanner := Scanner {
		data = output,
	}

	signature := read_u16(&input_scanner)

	compressed_size := read_u24(&input_scanner) if (signature & 0x0100) != 0 else 0
	decompressed_size := read_u24(&input_scanner)


	byte_0, byte_1, byte_2, byte_3: u8
	proc_len, ref_dis, ref_len: u32

	for !overflowed(&input_scanner) && !overflowed(&output_scanner) {
		byte_0 = read_u8(&input_scanner)
		if (byte_0 & 0x80) == 0 {
			// 2-byte command: 0DDRRRPP DDDDDDDD
			byte_1 = read_u8(&input_scanner)
			proc_len = u32(byte_0) & 0x03
			scanner_append(&output_scanner, &input_scanner, int(proc_len))

			ref_dis = ((u32(byte_0) & 0x60) << 3) + u32(byte_1) + 1
			ref_len = ((u32(byte_0) >> 2) & 0x07) + 3

			self_copy(&output_scanner, int(ref_dis), int(ref_len))
		} else if (byte_0 & 0x40) == 0 {
			// 3-byte command: 10RRRRRR PPDDDDDD DDDDDDDD
			byte_1 = read_u8(&input_scanner)
			byte_2 = read_u8(&input_scanner)

			proc_len = u32(byte_1) >> 6
			scanner_append(&output_scanner, &input_scanner, int(proc_len))

			ref_dis = ((u32(byte_1) & 0x3f) << 8) + u32(byte_2) + 1
			ref_len = (u32(byte_0) & 0x3f) + 4

			self_copy(&output_scanner, int(ref_dis), int(ref_len))
		} else if (byte_0 & 0x20) == 0 {
			// 4-byte command: 110DRRPP DDDDDDDD DDDDDDDD RRRRRRRR
			byte_1 = read_u8(&input_scanner)
			byte_2 = read_u8(&input_scanner)
			byte_3 = read_u8(&input_scanner)

			proc_len = u32(byte_0) & 0x03
			scanner_append(&output_scanner, &input_scanner, int(proc_len))

			ref_dis = ((u32(byte_0) & 0x10) << 12) + (u32(byte_1) << 8) + u32(byte_2) + 1
			ref_len = ((u32(byte_0) & 0x0c) << 6) + u32(byte_3) + 5

			self_copy(&output_scanner, int(ref_dis), int(ref_len))
		} else {
			// 1-byte command
			proc_len = (u32(byte_0) & 0x1f) * 4 + 4

			if proc_len <= 0x70 {
				scanner_append(&output_scanner, &input_scanner, int(proc_len))
			} else {
				proc_len = u32(byte_0) & 0x3
				scanner_append(&output_scanner, &input_scanner, int(proc_len))

				break
			}
		}
	}

	if overflowed(&input_scanner) {
		return compressed_size, decompressed_size, .READ_OVERFLOW
	} else if overflowed(&output_scanner) {
		return compressed_size, decompressed_size, .READ_WRITE_OVERFLOW
	}

	return compressed_size, decompressed_size, nil
}
