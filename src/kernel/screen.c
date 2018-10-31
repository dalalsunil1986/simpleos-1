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

#include "screen.h"

inline static vga_position_t __screen_get_real_column(
  const vga_offset_t current_offset, const vga_position_t column)
{
  return column < 0 ? vga_get_column_from_offset(current_offset) : column;
}

inline static vga_position_t __screen_get_real_row(
  const vga_offset_t current_offset, const vga_position_t row)
{
  return row < 0 ? vga_get_row_from_offset(current_offset) : row;
}

static vga_offset_t __screen_print_character(
  const char character,
  const screen_position_t column, const screen_position_t row,
  const byte_t attributes)
{
  const vga_offset_t offset = vga_write_character(
    (byte_t * const) VGA_VIDEO_ADDRESS,
    character,
    column,
    row,
    attributes);
  vga_cursor_set_offset(offset);
  return offset;
}

void screen_print_character(
  const char character,
  const screen_position_t column, const screen_position_t row,
  const byte_t attributes)
{
  __screen_print_character(character, column, row, attributes);
}

void screen_print_at(
  const char * const message,
  const screen_position_t column, const screen_position_t row,
  const byte_t attributes)
{
  const vga_offset_t current_offset = vga_cursor_get_offset();
  vga_offset_t offset = vga_get_offset(
    __screen_get_real_column(current_offset, column),
    __screen_get_real_row(current_offset, row));
  int32_t index = 0;
  while (message[index] != NULL)
  {
    offset = __screen_print_character(
      message[index],
      vga_get_column_from_offset(offset),
      vga_get_row_from_offset(offset),
      attributes);
    index++;
  }
}

void screen_print(const char * const message, const byte_t attributes)
{
  screen_print_at(message, -1, -1, attributes);
}

void screen_clear()
{
  byte_t * const address = (byte_t * const) VGA_VIDEO_ADDRESS;
  vga_fill(address, ' ', ATTRIBUTE_WHITE_ON_BLACK);
  vga_cursor_set_offset(vga_get_offset(0, 0));
}
