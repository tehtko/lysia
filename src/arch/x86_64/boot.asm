global start

section .text
bits 32
start:
    mov esp, stack_top

    call check_multiboot
    call check_cpuid
    call check_long_mode

    ; print `OK` to the screen
    mov dword [0xb8000], 0x2f4b2f4f
    hlt

check_multiboot:            
    cmp eax, 0x36d76289     ; magic value (multiboot 1.6 spec)
    jne .no_multiboot
    ret
.no_multiboot:              ; not multiboot compliant
    mov al, "0"             
    jmp error

check_cpuid:                
    ; OSDev Wiki `Detection of CPUID` from `Setting up Long Mode`
    ; Check if CPUID is supported by attempting to flip the ID bit (bit 21) in
    ; the FLAGS register. If we can flip it, CPUID is available.

    ; Copy FLAGS in to EAX via stack
    pushfd
    pop eax

    ; Copy to ECX as well for comparing later on
    mov ecx, eax

    ; Flip the ID bit
    xor eax, 1 << 21

    ; Copy EAX to FLAGS via the stack
    push eax
    popfd

    ; Copy FLAGS back to EAX (with the flipped bit if CPUID is supported)
    pushfd
    pop eax

    ; Restore FLAGS from the old version stored in ECX (i.e. flipping the ID bit
    ; back if it was ever flipped).
    push ecx
    popfd

    ; Compare EAX and ECX. If they are equal then that means the bit wasn't
    ; flipped, and CPUID isn't supported.
    cmp eax, ecx
    je .no_cpuid
    ret
.no_cpuid:
    mov al, "1"
    jmp error

check_long_mode:
    mov eax, 0x80000000    ; Set the A-register to 0x80000000.
    cpuid                  ; CPU identification.
    cmp eax, 0x80000001    ; Compare the A-register with 0x80000001.
    jb .no_long_mode       ; It is less, there is no long mode.

    mov eax, 0x80000001    ; Set the A-register to 0x80000001.
    cpuid                  ; CPU identification.
    test edx, 1 << 29      ; Test if the LM-bit, which is bit 29, is set in the D-register.
    jz .no_long_mode       ; They aren't, there is no long mode.
.no_long_mode:
    mov al, "2"
    jmp error

error:
    ; print `ERR:` followed by the error code
    mov dword [0xb8000], 0x4f524f45
    mov dword [0xb8000], 0x4f3a4f52
    mov dword [0xb8000], 0x4f204f20
    mov byte  [0xb800a], al
    hlt

section .bss
stack_bottom:
    ; reserve 64 bytes
    resb 64 
stack_top: