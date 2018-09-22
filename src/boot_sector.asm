; ---------------------------------------------------------------------
; Boot Sector
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

; ---------------------------------------------------------------------
; Boot loader program
; ---------------------------------------------------------------------

; "org" is an abbreviation for "origin address", and sets the 
; "assembler location counter". It is used to specify the address that 
; we expect a raw assembly program to be loaded at, so that, for 
; convenience, all addresses we specify in the remaining program are 
; offseted automatically from there.
; See https://www.nasm.us/xdoc/2.13.03/html/nasmdoc7.html#section-7.1.1

[org 0x7c00]

mov bx, welcome_message
call print_string

; Infinite loop
jmp $

; Utility functions
%include "strings.asm"

; "db" defines an array of 1 byte elements. The assembler automatically 
; converts strings to ASCII when using quotes. The trailing zero is a 
; null-terminator so we can know where the string ends.
welcome_message:
  db 'Welcome to SimpleOS', 0

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
