; ---------------------------------------------------------------------
; Kernel Entry
; ---------------------------------------------------------------------
;
; We are compiling the kernel C source code and making the boot loader
; jump to first instruction in the kernel. If the "main" function is
; defined as the first symbol in the kernel, then the jump will get
; us to the right place, but that's not something we can ensure, also
; given that the C compiler might decide to place things differently.
;
; In order to ensure we jump to the right place, we will prepend this
; small piece of assembly in the kernel code, which ensures that we
; always jump to the function symbol called "main", no matter where
; it is.

; The kernel is compiled as a 32-bit program, so this entry point
; should do the same
[bits 32]

; This directive defines a symbol that is not present on the module
; being assembled, but that we promise that will be resolved by the
; linker. When we call the linker with both our C kernel code and
; this file, the linker will find this "extern" directive, try to
; find a symbol with the same name (which will be found on the C
; code), and will replace the symbol with the right address in all
; its ocurrences.
[extern main]

; Lets jump to the entry point of the kernel
call main

; An infinite loop, as we should never continue from here
jmp $
