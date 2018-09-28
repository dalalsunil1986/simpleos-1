; ---------------------------------------------------------------------
; String utility functions using VGA Text Mode
; ---------------------------------------------------------------------
;
; On boot, we start with a 80x25 display table that map to a buffer
; in the VGA display device. There, each character is represented by
; two bytes: one byte for the ASCII code to be displayed, and another
; byte to control various character attributes.
;
; The formula to position a character on a certain coordinate is:
;
; VGA_TEXT_BUFFER + (2 * (row * 80 + col))

[bits 32]

; The VGA text buffer address
; See https://en.wikipedia.org/wiki/VGA-compatible_text_mode
%define VGA_TEXT_BUFFER 0xb8000

; Attributes consist of 1 byte where the first bit is the blink bit,
; the next 3 bits define the background color, and the remaining 4
; bits define to foreground color.
; White is 0xf and blue is 0x1, so white text on a blue background
; is represented as 0x1f, which equals 00001111.
;
; See https://en.wikipedia.org/wiki/Video_Graphics_Array#Color_palette
%define ATTRIBUTE_WHITE_ON_BLUE 00011111b

; ---------------------------------------------------------------------
; Print an ASCII string
; ---------------------------------------------------------------------
;
; This function expects the address of a null-terminated string in
; register "ebx". It will mutate "ebx" as it iterates through the string.
;
; Example:
;
; mov ebx, foo
; call vga_print_string_ascii
; foo:
;   db 'Hello World', 0
; ---------------------------------------------------------------------

vga_print_string_ascii:
  ; Push all the registers to the stack
  pusha
  mov edx, VGA_TEXT_BUFFER

vga_print_string_ascii_start:
  ; Move the address at "ebx" to the first 8 bits of "ax"
  mov al, [ebx]
  ; Set basic character attributes on the last 8 bits of "ax"
  mov ah, ATTRIBUTE_WHITE_ON_BLUE

  ; If the first 8 bits of "ax" equal 0
  cmp al, 0
  ; Then we're done, as it is the null-terminator
  je vga_print_string_ascii_done

  ; Store the combination of character and attributes to "edx",
  ; which contains the address to the VGA text bugger
  mov [edx], ax

  ; Increment the address at "bx" by 1 byte, effectively
  ; going to the next ASCII character in the string.
  add ebx, BYTE 1

  ; Increment the VGA text buffer address by 2 bytes, so
  ; we can print the next character (1 byte is for the letter
  ; and 1 byte for the attributes)
  add edx, BYTE 2

  ; Go back to the beginning
  jmp vga_print_string_ascii_start
vga_print_string_ascii_done:
  ; Pop all the registers from the stack
  popa
  ; Pop the return address from the stack and jump to it
  ret
