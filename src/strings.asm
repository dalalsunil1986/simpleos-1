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
  ; The ISR at 0x10 is the BIOS Video Service interrupt, which
  ; can perform various tasks such as setting the cursor position,
  ; the border color, and much more.
  ; The "0x0e" mode is "Write Character in TTY Mode", which we
  ; can use to print a character from the lower end of "ax".
  ; See https://en.wikipedia.org/wiki/BIOS_interrupt_call
  mov ah, 0x0e
  int 0x10

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
