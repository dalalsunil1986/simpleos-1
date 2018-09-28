; ---------------------------------------------------------------------
; Global Descriptor Table
; ---------------------------------------------------------------------
;
; The GDT is an Intel x86 data structure to define various memory areas
; and switch from real mode to protected mode.
;
; Intel x86 processors start executing in real mode, the original 16-bit
; operating mode for x86 CPUs without any notion of memory protection.
; Intel ensures that all their CPUs remain fully compatible with earlier
; CPUs so that older software can run natively, and unaltered in all
; modern CPUs. By starting in real mode, Intel x86 processors behave
; exactly like the oldest CPU in the family: the Intel 8086. Modern x86
; programs must explicitly switch to 32-bit or 64-bit protected mode, and
; thus backwards compatibility is preserved.

; The protected mode was introduced on the Intel 80286 (1982) and
; extended on the Intel 80386 (1985). The differences between real mode
; and protected mode are:
;
; - Registers in real mode can hold 16-bit values, while registers in
;   protected mode can hold 32-bit or 64-bit values
; - Protected mode adds two general purpose registers for convenience
; - Protected mode supports a more complex way of segmenting memory,
;   where the programmer can define the attributes and permissions of
;   each segment
; - Protected mode offers built-in support for virtual memory and
;   paging
; - Protected mode can't access BIOS ISRs, as they only work on real
;   mode
;
; The GDT data structure consists of a "GDT descriptor", a 6-byte data
; structure defining the size of the GDT (2 bytes) , and a pointer to
; the actual table (4 bytes):
;
; |----------------|--------------------------|
; | SIZE (16 bits) | POINTER (32 bits)        |
; |----------------|--------------------------|
;
; The table is a sequence of 8 bytes sections defining different
; segments. The first segment should always be the "null descriptor",
; a completely blank (zero bytes) segment, used to catch mistakes where
; we forget to set a segment register before accessing an address.
;
; |------------------------|------------------------|------------------------|
; | NULL SEGMENT (8 bytes) | SEGMENT 1 (8 bytes)    | SEGMENT 2 (8 bytes)    |
; |------------------------|------------------------|------------------------|
;
; Each segment (64 bits) consists of:
;
; - (16 bits) First 2 bytes of the segment limit
; - (24 bits) First 3 bytes of the base address
; - (8 bits) Access settings
; - (4 bits) Last 4 bits of the segment limit
; - (4 bits) Flags
; - (8 bits) Last 1 byte of the base address
;
; The access settings byte (8 bits) consits of:
;
; - (4 bits) Segment type (accessed, readable, conforming, code)
; - (1 bit) Descriptor type (0 for system, 1 otherwise)
; - (2 bits) Descriptor privilege level (0 is the higher level)
; - (1 bit) Segment present (whether the segment is present in memory)
;
; The flags 4 bits consists of
;
; - (1 bit) Available for user usage
; - (1 bit) 64-bit code segment
; - (1 bit) Default operation size
; - (1 bit) Granularity
;
; See https://wiki.osdev.org/Global_Descriptor_Table for more details.
;
; ---------------------------------------------------------------------
; Basic Flat Model
; ---------------------------------------------------------------------
;
; This is the simplest working configuration for a GDT, where we define
; two overlapping segments (code and data) to cover the full 4 GBs of
; addressable memory, without attempting to protect one segment from the
; other, nor to use any paging features.
;
; The purpose is to start simple so can load the kernel, and then we can
; customize the GDT with more advanced settings once we are in C land.

gdt_start:

; ---------------------------------------------------------------------
; Null descriptor
; ---------------------------------------------------------------------

gdt_null:
  ; The "dq" instruction writes a quad-word (8 bytes)
  dq 0x0

; ---------------------------------------------------------------------
; Code segment descriptor
; ---------------------------------------------------------------------
;
; From 0x0 to 0xffff (same as the data segment, thus overlapping)

gdt_code:
  ; First 2 bytes of limit address
  dw 0xffff
  ; First 3 bytes of base address
  dw 0x0
  db 0x0

  ; First, various access settings:
  ;
  ; - Segment present = 1, since the segment will be present in memory
  ; - Descriptor privilege level = 0, the higher level
  ; - Descriptor type = 1, which should be set to 1 for code
  ;
  ; Then, the 4 bits for the type:
  ;
  ; - Code = 1, since this is a code segment
  ; - Conforming = 0, which means that a segment with lower privilege
  ;   may not call code in this segment
  ; - Readable = 1, to read constants defined in the code
  ; - Accessed = 0, since the CPU will set this bit when it a accesses
  ;   the segment
  db 10011010b

  ; First, the flags 4 bits:
  ;
  ; - Granularity = 1, which means multiplying our limit (0xffff) by 4K,
  ;   so that the limit becomes 0xffff0000 (4 GB of memory)
  ; - Default operation size = 1, which sets the default data unit size
  ;   for operations to 32-bit numbers
  ; - 64-bit code segment = 0, since we will target 32 bits processors
  ; - User usage bit = 0, which we don't use
  ;
  ; Then, last 4 bits of limit address (1111)
  db 11001111b

  ; Last byte of base address
  db 0x0

; ---------------------------------------------------------------------
; Data segment descriptor
; ---------------------------------------------------------------------
;
; From 0x0 to 0xffff (same as the code segment, thus overlapping)

gdt_data:
  ; Same as in the code segment
  dw 0xffff
  dw 0x0
  db 0x0
  ; Same as in the code segment, with the exception of the
  ; "code" type bit (the 5th bit), which is set to 0 here
  db 10010010b
  ; Same as in the code segment
  db 11001111b
  db 0x0

; ---------------------------------------------------------------------
; GDT Descriptor
; ---------------------------------------------------------------------

; A handy label to we can automatically calculate the size of the GDT
gdt_end:

gdt_descriptor:
  ; The size of the GDT (2 bytes)
  dw gdt_end - gdt_start - 1
  ; A pointer to the start of the table (4 bytes)
  dd gdt_start
