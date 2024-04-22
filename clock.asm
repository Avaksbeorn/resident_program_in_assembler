.model small
.data
    msg db 'Hello, World!', 0

.code
start:
    mov ax, @data
    mov ds, ax

    mov ah, 25h    ; установить перехватчик клавиатуры
    mov al, 9      ; установить код перехватчика 9
    int 21h

    mov ah, 4ch    ; выйти из программы
    int 21h

proc9:
    mov ah, 9      ; вывод сообщения
    lea dx, msg
    int 21h
    iret           ; возврат из прерывания

end start
code segment para 'code'    ;определение кодового сегмента
    assume cs:code, ds:code, ss:code, es:code
    
    org 100h                ;размер PSP для COM программы


main: jmp init              ;переход на нерезидентную часть


;
; data
;

old_09h dd 0    ;старый обработчик 09h
mes1 db "Program installed!$"			; сообщение при установке резидента
mes2 db "Program already installed!$"	; сообщение при попытке повторной установки
;mes3 db "Program unload!$"			    ; сообщение при выгрузке программы

;
; обработчик прерывания от клавиатуры
;

new_09h proc
    jmp cont

    mes3 db "Program unload!$"			; сообщение при выгрузке программы

    cont:

    cmp ah, 0fah	; проверить номер функции прерывания от клавиатуры
    jne out_09h		; если не наша - обработка нажатой клавиши
    cmp al, 0		; это подфункция проверки на повторную установку?
    je inst			; если да, то сообщить о невозможности повторн.установки
    jmp out_09h		; неизвестная подфункция – обработка нажатой клавиши

inst:
    mov al,0ffh		; программа уже установлена
    iret			; выход из прерывания

do_signal:
    mov ah,02h
    push bx
    xor bh,bh
    push dx
    xor dx,dx
    int 10h

    pop dx
    pop bx
    pop ax
    jmp cs:old_09h	; переход к старому обработчику


out_09h:
    push ax
    in al,60H       ; читать ключ
    cmp al,38h      ; это кнопка подачи сигнала (left alt)?
    je do_signal    ; да, подать сигнал

    cmp al,2ah      ; это кнопка выгрузки резидента (left shift)?
    je rezoff       ; да, выгрузить резидент
                    ; нет, уйти на исходный обработчик
    pop ax
    jmp cs:old_09h	; переход к старому обработчику

rezoff:  
    push ds
    push es
    push dx

    mov ax, 2509h		; восстановим вектор 09h
    lds dx, cs:old_09h	; ds:dx – вектор старого 09h
    int  21h

    ;mov es, cs:2Ch		; выгрузка области окружения
    ;mov ah, 49h		; функция освобождения памяти
    ;int 21h

    push  cs
    pop  es			; выгрузка резидента 
    mov  ah,  49h
    int  21h

    pop dx
    pop es
    pop ds
    pop ax
    jmp cs:old_09h	; переход к старому обработчику

new_09h endp

resident=$			; смещение конца резидентной части программы

;
; процедура инициализации
;

init proc
                    ; проверить, не установлена ли уже данная программа
    mov ah,0fah		; установить номер функции и подфункции для проверки
    mov al, 0		; на наличие резидентной программы в оперативной памяти
    int 09h

    cmp al,0ffh		    ; программа установлена?
    je if_installed		; если да, то перейти к выводу предупрежд. сообщения
                        ; сохранить вектор 09h
	mov ax,3509h		; функция получения вектора 09h
	int 21h

    mov word ptr cs:old_09h,bx		; сохранить смещение системного обработчика
    mov word ptr cs:old_09h+2,es	; сохранить сегмент системного обработчика
                                    ; заполнить вектор 09h
    mov ax,2509h			; функция установления вектора прерывания 09h
    mov dx,offset new_09h	; смещение нового обработчика
    int 21h

    mov ah,09h			; функция вывода на экран
    lea dx,mes1;		; DS:DX - адрес строки
    int 21h
                        ; остаться резидентом
    mov ax,3100h		; функция «завершиться и остаться резидентом»
    mov dx,(resident-main+10Fh)/16	; размер в параграфах
    int 21h

    mov ax,4c00h
    int 21h

if_installed:
    mov ah,09h			; функция вывода на экран
    lea dx,mes2			; DS:DX - адрес строки
    int 21h
    
    mov ax,4c00h		; функция завершения с кодом возврата
    int 21h

init endp
    stack dw 100 dup(?)
code ends
end main