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

#include <unity.h>
#include "src/kernel/vga.h"

void test_vga_get_offset_0_0()
{
  const vga_offset_t offset = vga_get_offset(0, 0);
  TEST_ASSERT_EQUAL_HEX32(0, offset);
}

void test_vga_get_offset_1_0()
{
  const vga_offset_t offset = vga_get_offset(1, 0);
  TEST_ASSERT_EQUAL_HEX32(2, offset);
}

void test_vga_get_offset_2_0()
{
  const vga_offset_t offset = vga_get_offset(2, 0);
  TEST_ASSERT_EQUAL_HEX32(4, offset);
}

void test_vga_get_offset_3_0()
{
  const vga_offset_t offset = vga_get_offset(3, 0);
  TEST_ASSERT_EQUAL_HEX32(6, offset);
}

void test_vga_get_offset_79_0()
{
  const vga_offset_t offset = vga_get_offset(79, 0);
  TEST_ASSERT_EQUAL_HEX32(0x9E, offset);
}

void test_vga_get_offset_column_79_eq_80_eq_81()
{
  const vga_offset_t offset1 = vga_get_offset(79, 0);
  const vga_offset_t offset2 = vga_get_offset(80, 0);
  const vga_offset_t offset3 = vga_get_offset(81, 0);
  TEST_ASSERT_EQUAL_HEX32(offset1, offset2);
  TEST_ASSERT_EQUAL_HEX32(offset2, offset3);
}

int main()
{
  UNITY_BEGIN();
  RUN_TEST(test_vga_get_offset_0_0);
  RUN_TEST(test_vga_get_offset_1_0);
  RUN_TEST(test_vga_get_offset_2_0);
  RUN_TEST(test_vga_get_offset_3_0);
  RUN_TEST(test_vga_get_offset_79_0);
  RUN_TEST(test_vga_get_offset_column_79_eq_80_eq_81);
  return UNITY_END();
}
