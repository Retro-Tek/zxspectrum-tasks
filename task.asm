                    MODULE task

                    IFNDEF TASKS_MAX
                    DEFINE TASKS_MAX 127 ; including 'main' task
                    ENDIF

                    ASSERT (TASKS_MAX) <= 127


; Runs a task with an arbitrary number of arguments.
; Size += 18
; Time += 16 + [29 + 52*N if N > 0]
; Input: HL      = task SP
;        BC      = task PC
;        A       = (N)umber of arguments
;       (SP-2)   = arg #1
;        ...
;       (SP-2*N) = arg #N
; Preserves F, BC', DE', HL', IY.
start_argsN          IFUSED
                    OR A
                    JR Z,start_args0

                    POP IX
.loop
                    POP DE

                    DEC HL
                    LD (HL),D
                    DEC HL
                    LD (HL),E

                    DEC A
                    JR NZ,.loop

                    PUSH IX
                    JP start_args0
                    ENDIF


; Runs a new task with a single argument.
; Size += 4
; Time += 26
; Input: HL = task SP
;        BC = task PC
;        DE = arg
; Preserves F, BC', DE', HL', IX, IY.
start_args1          IFUSED
                    DEC HL
                    LD (HL),D
                    DEC HL
                    LD (HL),E
                    ; fall through
.dummy              EQU start_args0 ; mark as used
                    ENDIF


; Runs a new task with no arguments.
; Size += 4
; Time += 26
; Input: HL = task SP
;        BC = task PC
; Preserves F, BC', DE', HL', IX, IY.
start_args0          IFUSED
                    DEC HL
                    LD (HL),B
                    DEC HL
                    LD (HL),C
                    ; fall through
                    ENDIF


; Adds a new task to the tasks chain, just before the current one.
; New task will be started on the next tasks cycle.
; Size = 33
; Time = 140 + [-6 + 42*N if N > 0], where N = random[0, tasks count not including new one)
; Input: HL  = task SP
;       (HL) = task PC
; Preserves F, BC', DE', HL', IX, IY.
start
                    LD DE,(tasks.cur)
                    ; DE = cur                  
                    LD A,L
                    EX AF,AF'
                    ; A' = LOW(task SP)
                    LD A,(tasks.end)
                    LD L,A
                    ; L = A = end
                    SUB E
                    LD B,0
                    LD C,A
                    ; BC = end - LOW(cur) = bytes to copy + 1
                    LD A,L
                    ADD 2
                    LD E,A
                    LD (tasks.end),A
                    ; DE = base + end + 2
                    ; new_end = end + 2
                    LD A,H
                    ; A = HIGH(task SP)
                    DEC C
                    JR Z,.skip_move
                    ; BC = end - LOW(cur) - 1 = bytes to copy
                    LD H,D
                    ; HL = base + end
                    LDDR ; move [cur + 2, base + end] 2 bytes right
.skip_move          ; DE = cur + 3
                    LD (DE),A
                    DEC E
                    EX AF,AF'
                    LD (DE),A
                    ; (cur + 2) = task SP
                    RET


; Switches tasks: current task is suspended and its SP is stored, then the next task SP is restored and procedure exits into that task.
; From the callers point of view, it is effectively a 'pause until the next cycle'.
; Size = 22
; Time = 104 + [7 once per cycle]
; Preserves NOTHING except SP.
yield
                    LD (tasks),SP
.cur                EQU $-2
.next
                    LD HL,(.cur)
                    DEC L
                    JP NZ,$+5
                    LD L,2
.end                EQU $-1
                    LD D,(HL)
                    DEC L
                    LD E,(HL)
                    LD (.cur),HL

                    EX DE,HL
                    LD SP,HL
                    RET


; Terminates current task. Will not return. Can`t terminate the last task.
; Size = 26
; Time = 172 + [7 once per cycle] + [5 + 42*N if N > 0], where N = random[0, tasks count)
exit
                    LD HL,(tasks.cur)
                    LD D,H
                    LD E,L
                    ; DE = HL = cur
                    LD A,(tasks.end)
                    INC L
                    SUB L
                    JR Z,.skip_move
                    INC L
                    LD B,0
                    LD C,A
                    ; HL = cur + 2, BC = end - LOW(cur) - 1
                    LDIR
.skip_move          ; E = end - 1
                    LD A,E
                    DEC A
                    LD (tasks.end),A
                    ; new_end = end - 2
                    JP yield.next


                    ALIGN 256
                    DB 0
tasks               DS 2*(TASKS_MAX)
.cur                EQU yield.cur
.end                EQU yield.end

                    ENDMODULE
