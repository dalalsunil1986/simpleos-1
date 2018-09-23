; The "0x0e" mode is "Write Character in TTY Mode", which we
; can use to print a character from the lower end of "ax".
; See https://en.wikipedia.org/wiki/BIOS_interrupt_call
%define BIOS_ISR_FUNCTION_DISPLAY_CHARACTER 0x0e

; The ISR at 0x10 is the BIOS Video Services interrupt, which
; can perform various tasks such as setting the cursor position,
; the border color, and much more.
%define BIOS_INTERRUPT_VECTOR_VIDEO_SERVICES 0x10

; See https://en.wikipedia.org/wiki/ASCII
%define ASCII_LINE_FEED 0x0a
%define ASCII_CARRIAGE_RETURN 0x0d

; ---------------------------------------------------------------------
; Print a string
; ---------------------------------------------------------------------
;
; This function expects the address of a null-terminated string in
; register "bx". It will mutate "bx" as it iterates through the string.
;
; Example:
;
; mov bx, foo
; call print_string
; foo:
;   db 'Hello World', 0
; ---------------------------------------------------------------------

print_string:
  ; Push all the registers to the stack
  pusha
print_string_start:
  ; Move the address at "bx" to "ax"
  mov ax, [bx]
  ; If the first 8 bits of "ax" equal 0
  cmp al, 0
  ; Then we're done, as it is the null-terminator
  je print_string_done

  ; Certain ISRs do many different tasks depending on the "mode"
  ; we set at the higher end of "ah".
  ; The "Write Character in TTY Mode" is used to print a character
  ; from the lower end of "ax".
  mov ah, BIOS_ISR_FUNCTION_DISPLAY_CHARACTER
  int BIOS_INTERRUPT_VECTOR_VIDEO_SERVICES

  ; Increment the address at "bx" by 1 byte, effectively
  ; going to the next ASCII character in the string.
  add bx, BYTE 1
  ; Go back to the beginning
  jmp print_string_start
print_string_done:
  ; Pop all the registers from the stack
  popa
  ; Pop the return address from the stack and jump to it
  ; The address was initially pushed by "call"
  ret

; ---------------------------------------------------------------------
; Go to a new line
; ---------------------------------------------------------------------
;
; This routine will not modify any registers.
;
; Example:
;
; mov bx, foo
; call print_string
; call print_ln
; call print_string
; foo:
;   db 'Hello World', 0
; ---------------------------------------------------------------------

print_ln:
  ; Push all the registers to the stack
  pusha
  ; Set the display character mode
  mov ah, BIOS_ISR_FUNCTION_DISPLAY_CHARACTER
  ; Print a '\n' new line character
  mov al, ASCII_LINE_FEED
  int BIOS_INTERRUPT_VECTOR_VIDEO_SERVICES
  ; Also print a '\r' carriage return, as otherwise the cursor
  ; goes one position down, but it will keep printing at the
  ; current column.
  mov al, ASCII_CARRIAGE_RETURN
  int BIOS_INTERRUPT_VECTOR_VIDEO_SERVICES
  ; Pop all the registers from the stack
  popa
  ; Pop the return address from the stack and jump to it
  ret
