/* Copyright (c) 2018, Juan Cruz Viotti
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the <organization> nor the
 *       names of its contributors may be used to endorse or promote products
 *     # derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "vga.h"

static const int16_t VGA_ROWS = 25;
static const int16_t VGA_COLUMNS = 80;
static byte_t * const VGA_VIDEO_ADDRESS = (byte_t *) 0xb8000;

// Screen device I/O ports
static const port_t REGISTRY_SCREEN_CTRL = 0x3D4;
static const port_t REGISTRY_SCREEN_DATA = 0x3D5;

inline int32_t vga_get_offset(const int32_t column, const int32_t row)
{
  return 2 * ((vga_row(row) * VGA_COLUMNS) + vga_column(column));
}

inline int32_t vga_get_row_from_offset(const int32_t offset)
{
  return offset / (2 * VGA_COLUMNS);
}

inline int32_t vga_get_column_from_offset(const int32_t offset)
{
  return (offset - (vga_get_row_from_offset(offset) * 2 * VGA_COLUMNS)) / 2;
}

inline int32_t vga_column(const int32_t column)
{
  return column > VGA_COLUMNS ? VGA_COLUMNS : column;
}

inline int32_t vga_row(const int32_t row)
{
  return row > VGA_ROWS ? VGA_ROWS : row;
}

int32_t vga_cursor_get_offset()
{
  port_byte_out(REGISTRY_SCREEN_CTRL, 14);
  const int32_t offset = port_byte_in(REGISTRY_SCREEN_DATA) << 8;
  port_byte_out(REGISTRY_SCREEN_CTRL, 15);
  return (offset + port_byte_in(REGISTRY_SCREEN_DATA)) * 2;
}

void vga_cursor_set_offset(const int32_t offset)
{
  port_byte_out(REGISTRY_SCREEN_CTRL, 14);
  port_byte_out(REGISTRY_SCREEN_DATA, (byte_t)((offset / 2) >> 8));
  port_byte_out(REGISTRY_SCREEN_CTRL, 15);
  port_byte_out(REGISTRY_SCREEN_DATA, (byte_t)((offset / 2) & 0xff));
}

void vga_offset_write_character(
    const int32_t offset, const char character, const byte_t attributes)
{
  VGA_VIDEO_ADDRESS[offset] = character;
  VGA_VIDEO_ADDRESS[offset + 1] = attributes;
}
