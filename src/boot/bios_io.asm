; ---------------------------------------------------------------------
; I/O utility functions using BIOS ISRs
; ---------------------------------------------------------------------
;
; These set of functions depend on the strings_bios.asm library.

; The ISR at 0x13 is the BIOS Low Level Disk Services interrupt,
; which can perform various I/O related tasks.
%define BIOS_INTERRUPT_LOW_LEVEL_DISK_SERVICES 0x13

; The "0x02" mode is "Read Sectors Mode", which we
; can use to read a number of sectors from a drive.
; See https://en.wikipedia.org/wiki/BIOS_interrupt_call
%define BIOS_ISR_FUNCTION_READ_SECTORS 0x02

; ---------------------------------------------------------------------
; Read a number of sectors from a drive
; ---------------------------------------------------------------------
;
; This function expects the following parameters
;
; dl -> The drive number to read from
; dh -> The number of sectors to read, from 1 (0x01) to 128 (0x80)
;       Each sector consists of 512 bytes, so this function allows us
;       to read maximum of 64K
; bx -> The address to write the results to
;
; This function relies on CHS addressing:
;
; ah -> The head number to read from
; ch -> The cylinder number to read from
; cl -> The sector number to read from

bios_io_read_drive:
  ; The user specified the number of sectors to read at "dh".
  ; We need to keep that information to later ensure we got back
  ; the right amount of sectors, so pushing "dx" into the stack
  ; ensures we can get it back even if something else modified it
  push dx

  ; The ISR expects the number of sectors to read at "al"
  mov al, dh
  ; The ISR expects the head number at "ah"
  mov dh, ah

  ; Certain ISRs do many different tasks depending on the "mode"
  ; we set at the higher end of "ah".
  mov ah, BIOS_ISR_FUNCTION_READ_SECTORS
  int BIOS_INTERRUPT_LOW_LEVEL_DISK_SERVICES

  ; The BIOS will set the carry bit if there was an error
  ; on the above operation, so we jump to the error sub-routine
  ; if the carry bit is set
  jc bios_io_error_disk_read

  ; The BIOS call completed, so now we can get back our initial
  ; "dh" value for the sectors read comparison
  pop dx

  ; The BIOS operation we executed before sets the number of sectors
  ; read in the "al" register. If the amount of read sectors don't
  ; match the number of sectors that the client requested, then
  ; there was an error
  cmp al, dh
  jne bios_io_error_sector_read_mismatch

  ; Pop all the registers from the stack
  ; Pop the return address from the stack and jump to it
  ret

; ---------------------------------------------------------------------
; Error Sub-routines
; ---------------------------------------------------------------------
;
; The CPU goes into an infinite loop here on these.

bios_io_error_disk_read:
  mov bx, BIOS_IO_ERROR_MESSAGE_DISK_READ
  call bios_print_string_ascii
  call bios_print_ln
  jmp $
bios_io_error_sector_read_mismatch:
  mov bx, BIOS_IO_ERROR_MESSAGE_SECTOR_READ_MISMATCH
  call bios_print_string_ascii
  call bios_print_ln
  jmp $

; Our error messages
BIOS_IO_ERROR_MESSAGE_DISK_READ:
  db "Disk read error", 0
BIOS_IO_ERROR_MESSAGE_SECTOR_READ_MISMATCH:
  db "Incorrect number of sectors read", 0
