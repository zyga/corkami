; PE with corrupted delay imports, all set to zero

; Ange Albertini, BSD LICENCE 2009-2011

%include 'consts.inc'

IMAGEBASE equ 400000h
org IMAGEBASE
bits 32

SECTIONALIGN equ 1000h
FILEALIGN equ 200h

istruc IMAGE_DOS_HEADER
    at IMAGE_DOS_HEADER.e_magic, db 'MZ'
    at IMAGE_DOS_HEADER.e_lfanew, dd NT_Signature - IMAGEBASE
iend

NT_Signature:
istruc IMAGE_NT_HEADERS
    at IMAGE_NT_HEADERS.Signature, db 'PE', 0, 0
iend
istruc IMAGE_FILE_HEADER
    at IMAGE_FILE_HEADER.Machine,               dw IMAGE_FILE_MACHINE_I386
    at IMAGE_FILE_HEADER.NumberOfSections,      dw NUMBEROFSECTIONS
    at IMAGE_FILE_HEADER.SizeOfOptionalHeader,  dw SIZEOFOPTIONALHEADER
    at IMAGE_FILE_HEADER.Characteristics,       dw IMAGE_FILE_EXECUTABLE_IMAGE | IMAGE_FILE_32BIT_MACHINE
iend

OptionalHeader:
istruc IMAGE_OPTIONAL_HEADER32
    at IMAGE_OPTIONAL_HEADER32.Magic,                     dw IMAGE_NT_OPTIONAL_HDR32_MAGIC
    at IMAGE_OPTIONAL_HEADER32.AddressOfEntryPoint,       dd EntryPoint - IMAGEBASE
    at IMAGE_OPTIONAL_HEADER32.ImageBase,                 dd IMAGEBASE
    at IMAGE_OPTIONAL_HEADER32.SectionAlignment,          dd SECTIONALIGN
    at IMAGE_OPTIONAL_HEADER32.FileAlignment,             dd FILEALIGN
    at IMAGE_OPTIONAL_HEADER32.MajorSubsystemVersion,     dw 4
    at IMAGE_OPTIONAL_HEADER32.SizeOfImage,               dd 2 * SECTIONALIGN
    at IMAGE_OPTIONAL_HEADER32.SizeOfHeaders,             dd SIZEOFHEADERS
    at IMAGE_OPTIONAL_HEADER32.Subsystem,                 dw IMAGE_SUBSYSTEM_WINDOWS_CUI
    at IMAGE_OPTIONAL_HEADER32.NumberOfRvaAndSizes,       dd 16
iend

DataDirectory:
istruc IMAGE_DATA_DIRECTORY_16
    at IMAGE_DATA_DIRECTORY_16.ImportsVA,   dd Import_Descriptor - IMAGEBASE
    at IMAGE_DATA_DIRECTORY_16.DelayImportsVA, dd delay_imports - IMAGEBASE
    at IMAGE_DATA_DIRECTORY_16.DelayImportsSize, dd DELAY_IMPORTS_SIZE
iend

SIZEOFOPTIONALHEADER equ $ - OptionalHeader
SectionHeader:
istruc IMAGE_SECTION_HEADER
    at IMAGE_SECTION_HEADER.VirtualSize,      dd 1 * SECTIONALIGN
    at IMAGE_SECTION_HEADER.VirtualAddress,   dd 1 * SECTIONALIGN
    at IMAGE_SECTION_HEADER.SizeOfRawData,    dd 1 * FILEALIGN
    at IMAGE_SECTION_HEADER.PointerToRawData, dd 1 * FILEALIGN
    at IMAGE_SECTION_HEADER.Characteristics,  dd IMAGE_SCN_MEM_EXECUTE | IMAGE_SCN_MEM_WRITE
iend
NUMBEROFSECTIONS equ ($ - SectionHeader) / IMAGE_SECTION_HEADER_size

SIZEOFHEADERS equ $ - IMAGEBASE

section progbits vstart=IMAGEBASE + SECTIONALIGN align=FILEALIGN

EntryPoint:
    push Msg
    call [__imp__printf]
    add esp, 1 * 4
_
DelayImportLoad:
    push 0
    call [__imp__ExitProcess]
_c

Msg db " * delay imports with empty values", 0ah, 0
_d

Import_Descriptor:
;kernel32.dll_DESCRIPTOR:
    dd kernel32_int - IMAGEBASE
    dd 0, 0
    dd kernel32.dll - IMAGEBASE
    dd kernel32.dll_iat - IMAGEBASE
;terminator
    dd 0, 0, 0, 0, 0
_d

kernel32_int:
    dd hnExitProcess - IMAGEBASE
    dd hnLoadLibraryA - IMAGEBASE
    dd hnGetProcAddress - IMAGEBASE
    dd 0

;msvcrt_int:
    dd hnprintf - IMAGEBASE
    dd 0
_d

hnExitProcess:
    dw 0
    db 'ExitProcess', 0
hnLoadLibraryA:
    dw 0
    db 'LoadLibraryA', 0
hnGetProcAddress:
    dw 0
    db 'GetProcAddress', 0
_d

kernel32.dll_iat:
__imp__ExitProcess:
    dd hnExitProcess - IMAGEBASE
__imp__LoadLibraryA:
    dd hnLoadLibraryA - IMAGEBASE
__imp__GetProcAddress:
    dd hnGetProcAddress - IMAGEBASE
    dd 0
    
msvcrt.dll_iat:
    dd hnprintf - IMAGEBASE
    dd 0
_d

msvcrt_int:
    dd hnprintf - IMAGEBASE
    dd 0
_d
hnprintf:
    dw 0
    db 'printf',0

kernel32.dll db 'kernel32.dll', 0
msvcrt.dll db 'msvcrt.dll', 0
_d

struc _IMAGE_DELAY_IMPORT_DESCRIPTOR
    .grAttrs       resd 1  ; attributes
    .rvaDLLName    resd 1  ; RVA to dll name
    .rvaHmod       resd 1  ; RVA of module handle
    .rvaIAT        resd 1  ; RVA of the IAT
    .rvaINT        resd 1  ; RVA of the INT
    .rvaBoundIAT   resd 1  ; RVA of the optional bound IAT
    .rvaUnloadIAT  resd 1  ; RVA of optional copy of original IAT
    .dwTimeStamp   resd 1  ; 0 if not bound
endstruc

delay_imports:
istruc _IMAGE_DELAY_IMPORT_DESCRIPTOR
iend
istruc _IMAGE_DELAY_IMPORT_DESCRIPTOR
iend

delay_iat:
__imp__printf:
    dd __delay__printf
    dd 0
_d

__delay__printf:
    push msvcrt.dll
    call [__imp__LoadLibraryA]
    push hnprintf + 2
    push eax
    call [__imp__GetProcAddress]
    push eax
    retn
_c

DELAY_IMPORTS_SIZE equ $ - delay_imports

align FILEALIGN, db 0