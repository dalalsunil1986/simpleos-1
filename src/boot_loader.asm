; ---------------------------------------------------------------------
; Boot Loader
; ---------------------------------------------------------------------
;
; When the computer is turned on, it starts executing a firmware
; pre-installed on the system board called BIOS (Basic Input/Output
; System). The BIOS runs a "Power-On Self-Test" routine (POST) which
; checks, identifies, and initializes the CPU, RAM, video display,
; card, etc.
;
; Once all checks complete, the BIOS will go through each boot device
; (these devices and their priorities are usually configurable
; through the BIOS menu) in an attempt to find the "boot loader"
; software.
;
; In order to do so, the BIOS loads the first device's sector (the boot
; sector) (Cylinder 0, Head 0, Sector 0), 512 bytes, into memory at
; address 0x7c00. It uses previous addresses to setup its ISRs
; (interrupt service routines) and more.  Each interrupt is represented
; by an index to the interrupt vector table, added by the BIOS at
; address 0x0.
;
; If read was successful, it checks the bytes 511 (offset 0x1FE) and
; 512 (offset 0x1FF) are 0x55 and 0xAA respectively. This is known as
; the MBR signature.
;
; If the BIOS recognised a valid boot loader software, it will transfer
; control by executing a jump instruction to the boot loader's first
; byte in memory.
;
; The last 66 bytes of the 512-byte MBR are reserved for the  partition
; table and other information, so the MBR boot sector program must be
; small enough to fit within 446 bytes of memory or less.

; This boot loader is written in Intel x86 Assembly
; See http://www.cs.virginia.edu/~evans/cs216/guides/x86.html
; x86 CPUs have 4 general purpose registers: "ax", "bx", "cx", "dx",
; all of which can hold 2 bytes of data.

; ---------------------------------------------------------------------
; Real Mode
; ---------------------------------------------------------------------

; "org" is an abbreviation for "origin address", and sets the
; "assembler location counter". It is used to specify the address that
; we expect a raw assembly program to be loaded at, so that, for
; convenience, all addresses we specify in the remaining program are
; offseted automatically from there.
; See https://www.nasm.us/xdoc/2.13.03/html/nasmdoc7.html#section-7.1.1
[org ORIGIN_ADDRESS]

; The BIOS stores the drive number being booted from on this register.
; Here we save it into a memorable location for later use.
; We can then use this number when doing BIOS I/O operations.
mov [BOOT_DRIVE], dl

; BP and SP are registers that control the stack. BP points to the base
; of the stack, and SP points to the top of the stack.
; The stack grows down, and the SP register changes every time we push
; or pop the stack.
; Here we configure the stack to start a bit above the address where
; BIOS loads the boot loader so we have some room to breathe when
; growing down
%define REAL_MODE_STACK_ADDRESS (ORIGIN_ADDRESS + STACK_SIZE)
mov bp, REAL_MODE_STACK_ADDRESS
mov sp, bp

; Initial boot messages
mov bx, welcome_message
call bios_print_string_ascii
call bios_print_ln
mov bx, real_mode_start_message
call bios_print_string_ascii
call bios_print_ln

; Load the kernel into memory. We do this while still on real mode
; as we can use the BIOS I/O utilities. This simplifies the task
; as we don't have to write custom I/O drivers in assembly
call boot_loader_kernel_load

; This function will switch to protected mode and then jump to the
; PROTECTED_MODE_SWITCH. We will never return from this function
call protected_mode_switch
; An infinite loop. We should never get here if the switch went fine
jmp $

; Utilities
%include "strings_bios.asm"
%include "bios_io.asm"
%include "protected_mode.asm"
%include "strings_vga.asm"

; Declare 1 byte that we can later use to store the boot drive.
; We initially set it to zero
BOOT_DRIVE:
  db 0

; Just to be safe, as some utilities might have changed it
[bits 16]

boot_loader_kernel_load:
  ; Read 15 bytes from the known kernel location from the boot drive
  ; TODO: Where is it getting loaded? Looks like bios_io_read_drive
  ; hardcodes information about this.
  ; TODO: Why just 15 sectors? Can this be precomputed?
  mov bx, KERNEL_OFFSET
  mov dh, 15
  mov dl, [BOOT_DRIVE]
  call bios_io_read_drive

  ; Informational message
  mov bx, kernel_loaded_message
  call bios_print_string_ascii
  call bios_print_ln

  ; Go back to where we were before
  ret

; ---------------------------------------------------------------------
; Protected Mode
; ---------------------------------------------------------------------

[bits 32]

PROTECTED_MODE_BEGIN:
  ; Re-configure the 32-bit stack pointers to the same stack
  ; address as before
  ; In real mode, addressing works by multiplying the value in the
  ; segment register by 16 and then adding the offset address. This
  ; means that we have to multiply the stack address we calculated
  ; before while on real mode by 16 in order to get the absolute one
  mov ebp, (REAL_MODE_STACK_ADDRESS * 16)
  mov esp, ebp

  mov ebx, protected_mode_start_message
  call vga_print_string_ascii

  ; Jump to the address where we loaded the kernel
  call KERNEL_OFFSET

  jmp $

; ---------------------------------------------------------------------
; Messages
; ---------------------------------------------------------------------

; "db" defines an array of 1 byte elements. The assembler automatically
; converts strings to ASCII when using quotes. The trailing zero is a
; null-terminator so we can know where the string ends.

welcome_message:
  db 'Welcome to SimpleOS', 0
kernel_loaded_message:
  db 'Kernel loaded', 0
real_mode_start_message:
  db "Started in 16-bit Real Mode", 0
protected_mode_start_message:
  db "Started in 32-bit Protected Mode", 0

; ---------------------------------------------------------------------
; Fill the remaining code, until offset 510, with zeroes
; ---------------------------------------------------------------------

; "times" is a generic instruction provided by NASM that causes an
; instruction to be assembled multiple times. See
; https://www.nasm.us/doc/nasmdoc3.html
; The syntax is "times TO-FROM", and "$-$$" is a special symbol
; denoting the beginning of the current section. So this expression
; writes zeroes 510 times from the current section offset.

; The "db" directive declares 1 byte of data. So "db 0" is one byte of
; zeroes. Similarly, "dw 0" is two bytes of zeroes, and "dd" is four
; bytes of zeroes.
times 510-($-$$) db 0

; ---------------------------------------------------------------------
; Magic number
; ---------------------------------------------------------------------

; The "dw" instruction writes 2 bytes of data
dw 0xaa55
