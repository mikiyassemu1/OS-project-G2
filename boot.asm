[org 0x7C00]
[bits 16]

; ----------------------------------------
; Stage 1 Bootloader (512 bytes)
; Loads Stage 2 to 0x7E00 and jumps
; ----------------------------------------
start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    ; Save boot drive number
    mov [boot_drive], dl

    ; ✅ Display initial boot message using BIOS
    mov si, msg_loading
    call print_string

    ; ✅ Load Stage 2 (2 sectors) to 0x7E00 using BIOS INT 13h
    mov bx, 0x7E00
    mov ah, 0x02        ; BIOS: Read Sectors
    mov al, 2           ; Read 2 sectors
    mov ch, 0
    mov cl, 2           ; Starting from sector 2
    mov dh, 0
    mov dl, [boot_drive]
    int 0x13
    jc disk_error
    cmp al, 2
    jne disk_error

    ; ✅ Jump to Stage 2 code at 0x7E00
    jmp 0x0000:0x7E00

; ----------------------------------------
; Print string from DS:SI using BIOS
; ----------------------------------------
print_string:
    mov ah, 0x0E
.next:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .next
.done:
    ret

; ----------------------------------------
; Handle disk load error
; ----------------------------------------
disk_error:
    mov si, msg_error
    call print_string
    jmp $

; ----------------------------------------
; Strings and Boot Signature
; ----------------------------------------
msg_loading: db "Group2 Bootloader...", 0x0D, 0x0A, 0
msg_error:   db "Disk Error!", 0x0D, 0x0A, 0
boot_drive:  db 0

; Pad to 510 bytes, add 0xAA55 boot signature
times 510-($-$$) db 0
dw 0xAA55
