TITLE RESIDENT (COM) Резидентная программа для очистки
; экрана и установки цвета при нажатии
; Alt+Left Shift
;----------------------------------------------------------
INTTAB SEGMENT AT 0H ;Таблица векторов прерываний:
 ORG 9H*4 ; адрес для Int 9H,
KBADDR LABEL DWORD ; двойное слово
INTTAB ENDS
;----------------------------------------------------------
ROMAREA SEGMENT AT 400H ;Область параметров BIOS:
 ORG 17H ; адрес флага клавиатуры,
KBFLAG DB ? ; состояние Alt + Shift
ROMAREA ENDS
;----------------------------------------------------------
CSEG SEGMENT PARA ;Сегмент кода
 ASSUME CS:CS
 ORG 100H
BEGIN: JMP INITZ ;Выполняется только один раз
KBSAVE DD ? ;Для адреса INT 9 BIOS
; Очистка экрана и установка цветов:
; ---------------------------------
COLORS PROC NEAR ;Процедура выполняется
 PUSH AX ; при нажатии Alt+Left Shift
 PUSH BX
 PUSH CX ;Сохранить регистры
 PUSH DX
 PUSH SI
 PUSH DI
 PUSH DS
 PUSH ES
 PUSHF
 CALL KBSAV ;Обработать прерывание
 ASSUME DS:ROMAREA
 MOV AX,ROMAREA ;Установить DS для
 MOV DS,AX ; доступа к состоянию
 MOV AL,KB AG ; Alt+Left Shift
 CMP AL,00001010B ;Alt+Left Shift нажаты?
 JNE EXIT ; нет - выйти
 MOV AX,0600H ;Функция прокрутки
 MOV BH,61H ;Установить цвет
 MOV CX,00
 MOV DX,18 FH
 INT 10H
EXIT:
 POP ES ;Восстановить регистры
 POP DS
 POP DI
 POP SI
 POP DX
 POP CX
 POP BX
 POP AX
 IRET ;Вернуться
COLORS ENDP
; Подпрограмма инициализации:
; --------------------------
INITZE PROC NEAR ;Выполнять только один раз
 ASSUME DS:INTTAB
281
 PUSH DS ;Обеспечить возврат в DOS
 MOV AX,INTTAB ;Установить сегмент данных
 MOV DS,AX
 CLI ;Запретить прерывания
 ;Замена адреса обработчика:
 MOV AX,WORD PTR KBADDR ;Сохранить адрес
 MOV WORD PTR KBSAVE,AX ; BIOS
 MOV AX,WORD PTR BADDR+2
 MOV WORD PTR KBSAVE+2,AX
 MOV WORD PTR KBADDR,OFFSET COLORS ;Заменить
 MOV WORD PTR KBADDR+2,CS ; адрес BIOS
 STI ;Разрешить прерывания
 MOV DX,OFFSET INITZE ;Размер программы
 INT 27H ;Завершить и остаться
INITZE ENDP ; резидентом
CSEG ENDS
 END BEGIN
____________________________