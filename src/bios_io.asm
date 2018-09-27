# Read X sectors from drive Y
# TODO: Explain in more detail
bios_io_read_drive:
  pusha
  ; reading from disk requires setting specific values in all registers
  ; so we will overwrite our input parameters from 'dx'. Let's save it
  ; to the stack for later use.
  push dx

  mov ah, 0x02 ; ah <- int 0x13 function. 0x02 = 'read'
  mov al, dh   ; al <- number of sectors to read (0x01 .. 0x80)
  mov cl, 0x02 ; cl <- sector (0x01 .. 0x11)
               ; 0x01 is our boot sector, 0x02 is the first 'available' sector
  mov ch, 0x00 ; ch <- cylinder (0x0 .. 0x3FF, upper 2 bits in 'cl')
  ; dl <- drive number. Our caller sets it as a parameter and gets it from BIOS
  ; (0 = floppy, 1 = floppy2, 0x80 = hdd, 0x81 = hdd2)
  mov dh, 0x00 ; dh <- head number (0x0 .. 0xF)

  ; [es:bx] <- pointer to buffer where the data will be stored
  ; caller sets it up for us, and it is actually the standard location for int 13h
  int 0x13      ; BIOS interrupt
  jc bios_io_error_disk_read ; if error (stored in the carry bit)

  pop dx
  cmp al, dh    ; BIOS also sets 'al' to the # of sectors read. Compare it.
  jne bios_io_error_sector_read_mismatch
  popa
  ret

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

BIOS_IO_ERROR_MESSAGE_DISK_READ:
  db "Disk read error", 0
BIOS_IO_ERROR_MESSAGE_SECTOR_READ_MISMATCH:
  db "Incorrect number of sectors read", 0
