[org 0x7E00]
[bits 16]

; ----------------------------------------
; Stage 2 Entry - Real Mode
; ----------------------------------------
start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    ; Load GDT for Protected Mode
    lgdt [gdt32_descriptor]

    ; ✅ Enter Protected Mode (question 2)
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; Far jump to flush prefetch queue and enter 32-bit mode
    db 0xEA
    dw protected_mode
    dw 0x08

; ----------------------------------------
; Protected Mode Setup - 32-bit
; ----------------------------------------
[bits 32]
protected_mode:
    ; Set segment registers to flat data selector
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov esp, 0x7C00

    ; ✅ Set up PAE paging (question 3)
    call setup_paging

    ; Enable PAE in CR4
    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax

    ; ✅ Enable Long Mode (set LME bit in EFER MSR) (question 4)
    mov ecx, 0xC0000080      ; IA32_EFER MSR
    xor edx, edx
    rdmsr                    ; read EFER
    or eax, 1 << 8           ; set LME bit
    wrmsr                    ; write back

    ; ✅ Enable Paging (question 5)
    mov eax, cr0
    or eax, 0x80000000       ; set PG bit
    mov cr0, eax

    ; Load 64-bit GDT and jump to long mode
    lgdt [gdt64_descriptor]
    jmp 0x08:long_mode

; ----------------------------------------
; Paging Setup - for Long Mode (PAE structures)
; ----------------------------------------
setup_paging:
    mov edi, 0x1000
    xor eax, eax
    mov ecx, 4096
    rep stosd               ; zero memory for page tables

    mov dword [0x1000], 0x2003   ; PML4 -> PDPT (addr 0x2000 | present + write)
    mov dword [0x1004], 0
    mov dword [0x2000], 0x83     ; PDPT -> 1GB identity map (present + write + 1GB page)
    mov dword [0x2004], 0

    mov eax, 0x1000
    mov cr3, eax            ; set PML4 base
    ret

; ----------------------------------------
; Long Mode - 64-bit
; ----------------------------------------
[bits 64]
long_mode:
    ; Clear segments
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax

    ; Disable cursor blinking
    mov dx, 0x3D4
    mov al, 0x0A
    out dx, al
    inc dx
    mov al, 0x20
    out dx, al

    ; ✅ Print confirmation of Protected Mode (text printed in long mode)
    mov rsi, msg_pm
    mov rdi, 0xB8000 + 160 * 10
    call print

    ; ✅ Print confirmation of Long Mode (question 6)
    mov rsi, msg_lm
    mov rdi, 0xB8000 + 160 * 11
    call print

    ; ✅ Execute 64-bit instruction: move and print RAX
    mov rdi, 0xB8000 + 160 * 12
    mov rsi, msg_rax
    call print

    mov rsi, 0x123456789ABCDEF0
    call print_hex

    hlt
    jmp $

; ----------------------------------------
; Print null-terminated string (RSI = string, RDI = video mem addr)
; ----------------------------------------
print:
    mov ah, 0x0F
.loop:
    lodsb
    test al, al
    jz .done
    stosw
    jmp .loop
.done:
    ret

; ----------------------------------------
; Print 64-bit value in RSI as hex at RDI
; ----------------------------------------
print_hex:
    mov rcx, 16
    mov ah, 0x0F
.hex_loop:
    rol rsi, 4
    mov al, sil
    and al, 0x0F
    cmp al, 10
    jl .digit
    add al, 'A' - 10
    jmp .write
.digit:
    add al, '0'
.write:
    stosw
    loop .hex_loop
    ret

; ----------------------------------------
; GDT Definitions
; ----------------------------------------
gdt32:
    dq 0
gdt32_code: dq 0x00CF9A000000FFFF
gdt32_data: dq 0x00CF92000000FFFF
gdt32_end:

gdt32_descriptor:
    dw gdt32_end - gdt32 - 1
    dd gdt32

gdt64:
    dq 0
gdt64_code: dq 0x0020980000000000
gdt64_end:

gdt64_descriptor:
    dw gdt64_end - gdt64 - 1
    dq gdt64

; ----------------------------------------
; Displayed Messages
; ----------------------------------------
msg_pm:  db "Entered Protected Mode", 0
msg_lm:  db "Entered 64-bit Mode", 0
msg_rax: db "RAX=", 0

times 1024 - ($ - $$) db 0
