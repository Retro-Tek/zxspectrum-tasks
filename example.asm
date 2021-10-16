                    DEVICE ZXSPECTRUM48

                    ORG #8000


channel_open        EQU #1601
print_char          EQU #0010
.stack_depth        EQU 6*2  ; +2 for a CALL
print_string        EQU #203C
.stack_depth        EQU 7*2  ; +2 for a CALL
print_number        EQU #1A1B
.stack_depth        EQU 10*2 ; +2 for a CALL

                    MACRO print_char_inline CHAR
                        LD A,CHAR
                        RST #10
                    ENDM


start               DI
                    LD SP,$

                    LD A,2
                    CALL channel_open

                    LD DE,.header
                    LD BC,.header_length
                    CALL print_string

                    LD BC,task_index
                    LD DE,1
                    LD HL,task_index.stack
                    CALL task.start_args1

                    LD BC,task_fibonacci
                    LD HL,task_fibonacci.stack
                    CALL task.start_args0

                    LD BC,task_countdown
                    LD DE,10
                    LD HL,task_countdown.stack
                    CALL task.start_args1

                    LD B,20
.loop
                    PUSH BC
                    print_char_inline 13
                    CALL task.yield
                    POP BC
                    DJNZ .loop

                    HALT
.header
                    DB "No\\Fibonacci\\Countdown\r--------------------------------"
.header_length      EQU $-.header


task_index
                    POP BC
.loop
                    PUSH BC
                    CALL print_number
                    print_char_inline #20
                    CALL task.yield
                    POP BC

                    INC BC

                    JP .loop
                    DS 4 + (print_char.stack_depth>?print_number.stack_depth)
.stack


task_fibonacci
                    LD BC,0
                    LD HL,1
.loop
                    PUSH HL
                    ADD HL,BC
                    PUSH HL

                    CALL print_number
                    print_char_inline #20
                    CALL task.yield

                    POP HL
                    POP BC

                    JP .loop
                    DS 6 + (print_char.stack_depth>?print_number.stack_depth)
.stack


task_countdown
                    POP BC
.loop
                    PUSH BC
                    CALL print_number
                    print_char_inline #20
                    CALL task.yield
                    POP BC

                    DEC BC
                    LD A,B
                    OR C
                    JP NZ,.loop

                    LD DE,.message
                    LD BC,.message_length
                    CALL print_string

                    JP task.exit
.message            DB "BOOM!!"
.message_length     EQU $-.message
                    DS (4 + (print_char.stack_depth>?print_number.stack_depth)) >? (2 + print_string.stack_depth)
.stack


                    INCLUDE "task.asm"

                    SAVESNA "example.sna", start
                    LABELSLIST "example.l"
