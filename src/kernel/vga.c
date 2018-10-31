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

#define MAX(a, b) (((a) > (b)) ? (a) : (b))

static const vga_position_t VGA_ROWS = 25;
static const vga_position_t VGA_COLUMNS = 80;

// Screen device I/O ports
static const port_t REGISTRY_SCREEN_CTRL = 0x3D4;
static const port_t REGISTRY_SCREEN_DATA = 0x3D5;

// Impure
vga_offset_t vga_cursor_get_offset()
{
  port_byte_out(REGISTRY_SCREEN_CTRL, 14);
  const vga_offset_t offset = port_byte_in(REGISTRY_SCREEN_DATA) << 8;
  port_byte_out(REGISTRY_SCREEN_CTRL, 15);
  return (offset + port_byte_in(REGISTRY_SCREEN_DATA)) * 2;
}

// Impure
void vga_cursor_set_offset(const vga_offset_t offset)
{
  port_byte_out(REGISTRY_SCREEN_CTRL, 14);
  port_byte_out(REGISTRY_SCREEN_DATA, (unsigned char)((offset / 2) >> 8));
  port_byte_out(REGISTRY_SCREEN_CTRL, 15);
  port_byte_out(REGISTRY_SCREEN_DATA, (unsigned char)((offset / 2) & 0xff));
}

vga_offset_t vga_get_offset(const vga_position_t column, const vga_position_t row)
{
  return 2 * ((vga_row(row) * VGA_COLUMNS) + vga_column(column));
}

vga_position_t vga_get_row_from_offset(const vga_offset_t offset)
{
  return vga_row(offset / (2 * VGA_COLUMNS));
}

vga_position_t vga_get_column_from_offset(const vga_offset_t offset)
{
  return vga_column((offset - (vga_get_row_from_offset(offset) * 2 * VGA_COLUMNS)) / 2);
}

vga_position_t vga_column(const vga_position_t column)
{
  if (column >= VGA_COLUMNS)
  {
    return VGA_COLUMNS - 1;
  }

  return MAX(column, 0);
}

vga_position_t vga_row(const vga_position_t row)
{
  if (row >= VGA_ROWS)
  {
    return VGA_ROWS - 1;
  }

  return MAX(row, 0);
}

void vga_offset_write_character(
    byte_t * const address,
    const vga_offset_t offset,
    const char character,
    const byte_t attributes)
{
  address[offset] = character;
  address[offset + 1] = attributes;
}

vga_offset_t vga_write_character(
  byte_t * const address,
  const char character,
  const vga_position_t column, const vga_position_t row,
  const byte_t attributes)
{
  const vga_offset_t offset = vga_get_offset(column, row);
  if (character == '\n')
  {
    return vga_get_offset(0, row + 1);
  }

  vga_offset_write_character(address, offset, character, attributes);
  return offset + 2;
}

void vga_fill(byte_t * const address, const char character, const byte_t attributes)
{
  vga_position_t row;
  vga_position_t column;

  for (row = 0; row < VGA_ROWS; row++)
  {
    for (column = 0; column < VGA_COLUMNS; column++)
    {
      vga_write_character(address, character, column, row, attributes);
    }
  }
}
