%include "gdt.asm"

; Some handy macros for the locations of our
; code and data segment descriptors.
%define SEGMENT_CODE (gdt_code - gdt_start)
%define SEGMENT_DATA (gdt_data - gdt_start)

; ---------------------------------------------------------------------
; Switch from Real Mode to Protected Mode
; ---------------------------------------------------------------------
;
; This function will load a basic flat model GDT and switch to 32-bit
; protected mode. The switch will take you to a PROTECTED_MODE_BEGIN
; label that you have to define before calling this function.
; Notice that if the switch happened correctly, then this function
; never returns
;
; Example:
;
; call protected_mode_switch
; PROTECTED_MODE_BEGIN:
;   ...
;   ...
; ---------------------------------------------------------------------

protected_mode_switch:
  ; Disable all interrupts, as any 16-bit interrupt will not be able
  ; to run on protected mode (i.e. BIOS interrupts)
  cli
  ; Load the GDT descriptor directly into the CPU's GDT register
  ; Notice this instruction loads the GDT, but doesn't make the switch
  ; yet
  lgdt [gdt_descriptor]

  ; CR0 is a "control register", a register that controls the behaviour
  ; of the CPU. This particular control register is 32-bit long on 386
  ; and higher processors, and 64-bit long on x86-64 processors.
  ; The first bit is called "Protected Mode Enable" (PE) and puts the
  ; CPU on protected mode if set to 1.
  ; See https://en.wikipedia.org/wiki/Control_register.
  ;
  ; We can set a bit on a register using the "or" instruction, but this
  ; instruction is only able to act on general purpose registers.
  ; Therefore we have to copy CR0 into a general purpose register,
  ; modify it there, and set it back.
  ;
  ; Once this completes, we're officially in protected mode.
  ;
  ; Notice EAX is a 32-bit general purpose register already, and we can
  ; use it even though we're not in 32-bit mode yet. These registers
  ; are available on 32-bit capable CPUs even on real mode.
  mov eax, cr0
  or eax, 0x1
  mov cr0, eax

  ; CPUs have an optimization mechanism called "pipelining". Executing
  ; an instruction involves several steps:
  ;
  ; - Fetching the instruction
  ; - Decoding the instruction
  ; - Executing the instruction
  ; - Accessing memory
  ; - Writing back the results
  ;
  ; In order the keep every part of the CPU busy at any given point,
  ; the processor might i.e. start fetching the next instructions while
  ; decoding the current one, which can cause problems in the middle of
  ; a mode switch.
  ;
  ; For safety, we can issue a far jump. This is a workaround that
  ; exploits the fact that CPUs flush the pipeline in these cases,
  ; as they can't predict what will happen next.
  ; The difference between a jump and a far jump is the fact that we
  ; provide a target segment (before the colon).
  ;
  ; A "near" jump jumps to a location on the current code segment. A
  ; "far" jump potentially jumps to a location on another code segment,
  ; even though it might still be the same one. Still, the mechanisms
  ; used under the hood differ.
  ;
  ; A far jump flushes the pipeline because the segment that you are
  ; jumping to may be affected by previous instructions, and therefore
  ; the CPU can't be smart about it, as the segment address might still
  ; change on the fly until right before executing the jump.
  ;
  ; A far jump automatically changes the "cs" (code segment) register
  ; to the segment that we jumped to (basically it always points to the
  ; current segment), which means we don't have to manually update "cs"
  ; afterwards.
  jmp SEGMENT_CODE:protected_mode_init

; This is a directive to tell the assembler to encode 32-bit
; instructions from now on.
[bits 32]

protected_mode_init:
  ; At this point, the code segment register (cs) was updating to
  ; SEGMENT_CODE by our previous far jump.
  ; Here we update all other segment registers to point to the data
  ; segment
  mov ax, SEGMENT_DATA
  ; The current data segment
  mov ds, ax
  ; The current stack segment
  mov ss, ax
  ; The "extra" segment
  mov es, ax
  ; The two unspecified "fs" and "gs" segments
  mov fs, ax
  mov gs, ax
  ; Go to the user's specified label
  jmp PROTECTED_MODE_BEGIN
