; AmigaDemoTemplate (c)2023 Rich/Defekt

    INCDIR  "include"
    INCLUDE "hw.i"
    INCLUDE "hardware/cia.i"
    INCLUDE "funcdef.i"
    INCLUDE "exec/execbase.i"
    INCLUDE "exec/exec_lib.i"
    INCLUDE "graphics/gfxbase.i"
    INCLUDE "graphics/graphics_lib.i"
    INCLUDE "macros.i"

;----------------------------------------
;-                                      -
;-       System teardown/restore        -
;-                                      -
;----------------------------------------

Lev3Int = $6c

    EVEN
ADT_TakeSystem:
; disable AmigaOS ready for hardware bashing! \m/
; trashes: d0/a1/a4/a6
    move.l  $4.w,a6                 ; execbase
    lea     ADT_graphicslib,a1      ; open graphics.library
    jsr     _LVOOpenLibrary(a6)
    tst.l   d0
    bne.s   .graphics_ok
    move.w  #1,ADT_SetupSuccess     ; could not open graphics.library
    rts
.graphics_ok
    move.l  d0,ADT_gfxbase

    jsr     _LVOForbid(a6)          ; shut down task scheduler
    lea     CUSTOM,a6               ; save interrupts & dma
    move.w  ADKCONR(a6),ADT_adkcon
    move.w  INTENAR(a6),ADT_intena
    move.w  DMACONR(a6),ADT_dmacon
    move.w  POTGOR(a6),ADT_potgor
    move.l  ADT_gfxbase,a6          ; save the system view
    move.l  gb_ActiView(a6),ADT_systemview

    sub.l   a1,a1                   ; clear a1 for LoadView
    jsr     _LVOLoadView(a6)
    jsr     _LVOWaitTOF(a6)
    jsr     _LVOWaitTOF(a6)
    ADT_WaitVBL
    ADT_WaitVBL

    jsr     _LVOWaitBlit(a6)        ; take ownership of blitter
    jsr     _LVOOwnBlitter(a6)
    jsr     _LVOWaitBlit(a6)
    move.l  $4.w,a6
    jsr     _LVODisable(a6)         ; disable system interrupts

    lea     CUSTOM,a6               ; clear hardware interrupts and dma
    move.w  #$7fff,INTENA(a6)
    move.w  #$7fff,INTREQ(a6)
    move.w  #$7fff,DMACON(a6)
    move.w  #$0,POTGO(a6)

    ADT_WaitVBL
    ADT_WaitVBL

    jsr     ADT_GetVectorBase       ; get the VBR if necessary
    move.l  Lev3Int(a4),ADT_SysIRQ  ; save interrupt handler address
    rts

ADT_RestoreSystem:
; bring back AmigaOS
; trashes: d0/a0-a1/a5-a6
    lea     CUSTOM,a6               ; clear interrupts & dma
    move.w  #$7fff,INTENA(a6)
    move.w  #$7fff,INTREQ(a6)
    move.w  #$7fff,DMACON(a6)

    move.l  ADT_gfxbase,a6          ; make sure blitter finished
    jsr     _LVOWaitBlit(a6)

    ADT_WaitVBL

    lea     CUSTOM,a6               ; clear sprite data
    move.l  #0,SPR0DATA(a6)
    move.l  #0,SPR1DATA(a6)
    move.l  #0,SPR2DATA(a6)
    move.l  #0,SPR3DATA(a6)
    move.l  #0,SPR4DATA(a6)
    move.l  #0,SPR5DATA(a6)
    move.l  #0,SPR6DATA(a6)
    move.l  #0,SPR7DATA(a6)

    move.l  ADT_SysIRQ,a0           ; restore system interrupt handler address
    jsr     ADT_SetInterruptHandler

    lea     CUSTOM,a6               ; restore system copper lists
    move.l  ADT_gfxbase,a5
    move.l  gb_copinit(a5),COP1LC(a6)
    move.l  gb_LOFlist(a5),COP2LC(a6)
    move.w  #$7fff,COPJMP1(a6)

    move.w  ADT_intena,d0           ; restore system interrupts & dma
    or.w    #$8000,d0
    move.w  d0,INTENA(a6)
    move.w  ADT_dmacon,d0
    or.w    #$8000,d0
    move.w  d0,DMACON(a6)
    move.w  ADT_adkcon,d0
    or.w    #$8000,d0
    move.w  d0,ADKCON(a6)
    move.w  ADT_potgor,POTGO(a6)

    move.l  ADT_gfxbase,a6
    jsr     _LVOWaitBlit(a6)        ; disown the blitter
    jsr     _LVODisownBlitter(a6)
    move.l  $4.w,a6                 ; re-enable system intterupts
    jsr     _LVOEnable(a6)

    move.l  ADT_gfxbase,a6
    move.l  ADT_systemview,a1       ; reload the system view
    jsr     _LVOLoadView(a6)
    jsr     _LVOWaitTOF(a6)
    jsr     _LVOWaitTOF(a6)

    move.l  $4.w,a6                 ; restart task scheduler
    jsr     _LVOPermit(a6)

    move.l  ADT_gfxbase,a1
    jsr     _LVOCloseLibrary(a6)    ; close graphics.library
    rts

ADT_SetInterruptHandler:
; install a Level 3 interrupt handler
; a0 = new interrupt address
; trashes a1
    move.l  ADT_VBR,a1
    move.l  a0,Lev3Int(a1)
    rts

ADT_GetVectorBase:
    move.l  $4.w,a6                 ; execbase
    sub.l   a4,a4                   ; clear a4 as vector base on 68k is at $0
    move.w  AttnFlags(a6),d0
    and.w   #1,d0                   ; 68010+ CPU?
    beq.s   .is68k
    lea     ADT_GetVBR(pc),a5       ; address of code to fetch vector base address to a4
    jsr     _LVOSupervisor(a6)      ; enter Supervisor mode
.is68k
    move.l  a4,ADT_VBR
    rts

ADT_GetVBR:
    dc.w    $4e7a,$c801             ; hex for "movec VBR,a4"
    rte

ADT_VBR:
    dc.l    0
ADT_SysIRQ:
    dc.l    0
ADT_adkcon:
    dc.w    0
ADT_intena:
    dc.w    0
ADT_dmacon:
    dc.w    0
ADT_potgor:
    dc.w    0
ADT_gfxbase:
    dc.l    0
ADT_systemview:
    dc.l    0
ADT_graphicslib:
    dc.b    "graphics.library",0
    EVEN
ADT_SetupSuccess:
    dc.w    0

;----------------------------------------
;-                                      -
;-         INTERRUPT HANDLER            -
;-                                      -
;----------------------------------------
    IFD ADT_UseInterruptHandler
ADT_SetupInterruptHandler:
; expects CUSTOM register base in a6
; a0 - list of setup/VBL routine addresses, -1 signifies end of list
; eg.
; dc.l  setupIntro,introVBL
; dc.l  setupMain,mainVBL
; dc.l  -1
; setup routine *MUST* preserve a0
; trashes a1
    clr.w   ADT_IsFinished
    move.l  a0,ADT_CurrentListPtr
    jsr     ADT_NextPart
    lea     ADT_CopperInterrupt,a0
    jsr     ADT_SetInterruptHandler
    move.w  #$c010,INTENA(a6)
    rts

ADT_CopperInterrupt:
    movem.l d0-a6,-(sp)                     ; save all registers
    lea     CUSTOM,a6
    moveq.l #$10,d0                         ; copper IRQ bit
    move.w  INTREQR(a6),d1
    and.w   d0,d1
    beq.s   .notCopperInt

    move.w  d0,INTREQ(a6)                   ; clear copper IRQ
    move.w  d0,INTREQ(a6)

    IFD     ADT_SHOW_RASTER
    move.w  #$0f0,COLOR00(a6)
    ENDIF

    IFD     ADT_PlayLSPTick
    lea     $dff0a0,a6                      ; LSP player
    jsr     LSP_MusicPlayTick
    ENDIF

    move.l  ADT_RoutineAddress,a0
    jsr     (a0)                            ; call VBL routine

    IFD     ADT_SHOW_RASTER
    move.w  #$f00,CUSTOM+COLOR00
    ENDIF
.notCopperInt
    movem.l (sp)+,d0-a6                     ; restore all registers
    rte

ADT_NextPart:
    movem.l d0-a6,-(sp)                     ; save all registers
    move.l  ADT_CurrentListPtr,a0
    move.l  (a0)+,d0                        ; get setup address
    cmp.l   #-1,d0                          ; check if last part?
    bne.s   .notFinished
    move.w  #1,ADT_IsFinished               ; we're finished
    movem.l (sp)+,d0-a6                     ; restore all registers
    rts
.notFinished
    move.l  d0,a1                           ; save setup address ready to call
    move.l  (a0)+,d0                        ; get VBL routine address
    move.l  a0,ADT_CurrentListPtr           ; store update list ptr
    move.l  d0,ADT_RoutineAddress           ; store VBL routine address
    jsr     (a1)                            ; call setup routine
    movem.l (sp)+,d0-a6                     ; restore all registers
    rts

ADT_RoutineAddress:
    dc.l    0
ADT_CurrentListPtr:
    dc.l    0
ADT_IsFinished:
    dc.w    0
    ENDIF

;----------------------------------------
;-                                      -
;-              RANDOM                  -
;-                                      -
;----------------------------------------

    IFD ADT_UseRandom
ADT_InitRandom:
; expects CUSTOM register base in a6
; trashes d0
    move.w      VHPOSR(a6),d0
    swap        d0
    move.b      CIAA+ciatodlow,d0
    lsl.w       #8,d0
    move.b      CIAB+ciatodlow,d0
    add.l       JOY0DAT(a6),d0
    eor.l       #$deadbeef,d0
    addi.l      #$4a5be021,d0
    move.l      d0,ADT_RandomSeed
    rts

ADT_GetRandomBits32:
; expects CUSTOM register base in a6
; returns a longword of random bits in d0
; trashes d1
; 192 cycles on 68k
    move.l      ADT_RandomSeed,d0
    move.w      VHPOSR(a6),d1
    swap        d1
    move.b      CIAA+ciatodlow,d1
    lsl.w       #8,d1
    move.b      CIAB+ciatodlow,d1
    add.l       d1,d0
    addi.l      #$deadbeef,d1
    add.l       d1,d0
    addi.l      #$4a5be021,d0
    ror.l       #5,d0
    move.l      d0,ADT_RandomSeed
    rts

ADT_GetRandomBits16:
; expects CUSTOM register base in a6
; returns a word of random bit in d0, upper 16 bits unaffected
; trashes d1
; 158 cycles on 68k
    move.w      VHPOSR(a6),d1
    move.b      CIAA+ciatodlow,d0
    lsl.w       #8,d0
    move.b      CIAB+ciatodlow,d0
    eor.w       d0,d1
    move.w      ADT_RandomSeed,d0
    add.w       d1,d0
    addi.w      #$deaf,d1
    add.w       d1,d0
    addi.w      #$4ab5,d0
    ror.w       #5,d0
    move.w      d0,ADT_RandomSeed
    rts

ADT_RandomSeed:
    dc.l       0
    ENDIF

;----------------------------------------
;-                                      -
;-              COPPER                  -
;-                                      -
;----------------------------------------

ADT_SetBPLPtrs:
; a0 = address of image
; a1 = address of BPL1PTH in copper list
; d0 = size of plane
; d1 = number of planes
    subq.w      #1,d1
.SetBPLPtrsLoop
    move.l      a0,d2
    move.w      d2,6(a1)
    swap        d2
    move.w      d2,2(a1)
    add.l       d0,a0
    addq.l      #8,a1
    dbra.w      d1,.SetBPLPtrsLoop
    rts

;----------------------------------------
;-                                      -
;-            FADE COLOURS              -
;-                                      -
;----------------------------------------
    IFD ADT_UseFade
ADT_FadeColoursFromBlack:
; a0 = colour table
; a1 = copperlist ptr
; d7 = number of colours
; d6 = fade amount 0-255
; trashes d0-d2
    subq.w      #1,d7
.fctbLoop:
    moveq.l     #0,d0
    move.w      (a0)+,d1         ; get colour from table
    move.w      d1,d2
    and.w       #$00f,d2         ; blue component
    mulu.w      d6,d2
    lsr.w       #8,d2
    or.w        d2,d0

    move.w      d1,d2
    and.w       #$0f0,d2         ; green component
    lsr.w       #4,d2
    mulu.w      d6,d2
    lsr.w       #4,d2
    and.w       #$0f0,d2
    or.w        d2,d0

    move.w      d1,d2
    and.w       #$f00,d2         ; red component
    lsr.w       #8,d2
    mulu.w      d6,d2
    and.w       #$f00,d2
    or.w        d2,d0

    move.w      d0,2(a1)
    lea         4(a1),a1

    dbra        d7,.fctbLoop
    rts

ADT_FadeColours:
; a0 = source colour table
; a1 = target colour table
; a2 = copperlist ptr
; d7 = number of colours
; d6 = fade amount 0-255
; trashes d0-d4
.fadeColsLoop:
    move.w      (a0)+,d1         ; source
    move.w      (a1)+,d2         ; target

    bsr.s       ADT_FadeColour

    move.w      d0,2(a2)
    lea         4(a2),a2

    subq.w      #1,d7
    bne.s       .fadeColsLoop
    rts

ADT_FadeColour:
; d1 = source colour
; d2 = target colour
; d6 = fade amount 0-255
; returns faded colour in d0
; trashes d3-d4
    moveq.l     #0,d0

    move.w      d1,d3
    move.w      d2,d4
    and.w       #$00f,d3         ; source blue component
    and.w       #$00f,d4         ; target blue component

    sub.w       d3,d4            ; delta
    muls.w      d6,d4
    asr.w       #8,d4
    add.w       d4,d3
    or.w        d3,d0

    move.w      d1,d3
    move.w      d2,d4
    and.w       #$0f0,d3         ; source green component
    and.w       #$0f0,d4         ; target green component
    lsr.w       #4,d3
    lsr.w       #4,d4

    sub.w       d3,d4            ; delta
    muls.w      d6,d4
    asr.w       #8,d4
    add.w       d4,d3
    lsl.w       #4,d3
    or.w        d3,d0

    move.w      d1,d3
    move.w      d2,d4
    and.w       #$f00,d3         ; source red component
    and.w       #$f00,d4         ; target red component
    lsr.w       #8,d3
    lsr.w       #8,d4

    sub.w       d3,d4            ; delta
    muls.w      d6,d4
    asr.w       #8,d4
    add.w       d4,d3
    lsl.w       #8,d3
    or.w        d3,d0
    rts
    ENDIF

    IFD ADT_UseFadeFast
ADT_FadeColoursFromBlackFast:
; a0 = colour table
; a1 = copperlist ptr
; d7 = number of colours
; d6 = fade amount 0-15
; trashes d0-d4,a2
    subq.w      #1,d7
    tst.w       d6
    beq.s       ADT_FadeColoursFromBlackFastAllBlack
    lea         ADT_FadeBlackMulTab,a2
    subq.w      #1,d6
    lsl.w       #5,d6
    lea         0(a2,d6.w),a2
.fctbLoop:
    moveq.l     #0,d0
    move.w      (a0)+,d1         ; get colour from table
    move.w      d1,d2
    and.w       #$00f,d2         ; blue component
    add.w       d2,d2
    move.w      0(a2,d2.w),d2
    or.w        d2,d0

    move.w      d1,d2
    and.w       #$0f0,d2         ; green component
    lsr.w       #3,d2
    move.w      0(a2,d2.w),d2
    lsl.w       #4,d2
    or.w        d2,d0

    move.w      d1,d2
    and.w       #$f00,d2         ; red component
    lsr.w       #7,d2
    move.w      0(a2,d2.w),d2
    lsl.w       #8,d2
    or.w        d2,d0

    move.w      d0,2(a1)
    lea         4(a1),a1
    dbra        d7,.fctbLoop
    rts
ADT_FadeColoursFromBlackFastAllBlack
    moveq.l     #0,d0
.fctbLoop
    move.w      d0,2(a1)
    lea         4(a1),a1
    dbra        d7,.fctbLoop
    rts

ADT_FadeColoursFast:
; a0 = source colour table
; a1 = target colour table
; a2 = copperlist ptr
; d7 = number of colours
; d6 = fade amount 0-15
; trashes d0-d4,a3
.fadeColsLoop:
    move.w      (a0)+,d1         ; source
    move.w      (a1)+,d2         ; target
 
    bsr.s       ADT_FadeColourFast

    move.w      d0,2(a2)
    lea         4(a2),a2

    subq.w      #1,d7
    bne.s       .fadeColsLoop
    rts

ADT_FadeColourFast:
; d1 = source colour
; d2 = target colour
; d6 = fade amount 0-15
; returns faded colour in d0
; trashes d3-d5,a3
    move.w      d6,d4
    bne.s       .needToFade
    move.w      d1,d0
    rts
.needToFade
    moveq.l     #0,d0
    moveq.l     #15,d5
    subq.w      #1,d4
    lsl.w       #5,d4
    lea         ADT_FadeMulTab,a3
    lea         0(a3,d4.w),a3

    move.w      d1,d3
    move.w      d2,d4
    and.w       #$00f,d3         ; source blue component
    and.w       #$00f,d4         ; target blue component

    sub.w       d3,d4            ; delta
    beq.s       .noBlueChange
    add.w       d5,d4
    add.b       0(a3,d4.w),d3
.noBlueChange
    or.w        d3,d0

    move.w      d1,d3
    move.w      d2,d4
    and.w       #$0f0,d3         ; source green component
    and.w       #$0f0,d4         ; target green component
    lsr.w       #4,d3
    lsr.w       #4,d4

    sub.w       d3,d4            ; delta
    beq.s       .noGreenChange
    add.w       d5,d4
    add.b       0(a3,d4.w),d3
.noGreenChange
    lsl.w       #4,d3
    or.w        d3,d0

    move.w      d1,d3
    move.w      d2,d4
    and.w       #$f00,d3         ; source red component
    and.w       #$f00,d4         ; target red component
    lsr.w       #8,d3
    lsr.w       #8,d4

    sub.w       d3,d4            ; delta
    beq.s       .noRedChange
    add.w       d5,d4
    add.b       0(a3,d4.w),d3
.noRedChange
    lsl.w       #8,d3
    or.w        d3,d0
    rts

ADT_FadeBlackMulTab:
        dc.w    0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1
        dc.w    0,0,0,0,1,1,1,1,1,1,1,1,2,2,2,2
        dc.w    0,0,0,1,1,1,1,1,2,2,2,2,2,3,3,3
        dc.w    0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4
        dc.w    0,0,1,1,1,2,2,2,3,3,3,4,4,4,5,5
        dc.w    0,0,1,1,2,2,2,3,3,4,4,4,5,5,6,6
        dc.w    0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7
        dc.w    0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8
        dc.w    0,1,1,2,2,3,4,4,5,5,6,7,7,8,8,9
        dc.w    0,1,1,2,3,3,4,5,5,6,7,7,8,9,9,10
        dc.w    0,1,1,2,3,4,4,5,6,7,7,8,9,10,10,11
        dc.w    0,1,2,2,3,4,5,6,6,7,8,9,10,10,11,12
        dc.w    0,1,2,3,3,4,5,6,7,8,9,10,10,11,12,13
        dc.w    0,1,2,3,4,5,6,7,7,8,9,10,11,12,13,14
        dc.w    0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
ADT_FadeMulTab:
        dc.b    -1,-1,-1,-1,-1,-1,-1,-1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1
        dc.b    -2,-2,-2,-2,-1,-1,-1,-1,-1,-1,-1,-1,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,2,2,2,2,2
        dc.b    -3,-3,-3,-2,-2,-2,-2,-2,-1,-1,-1,-1,-1,0,0,0,0,0,1,1,1,1,1,2,2,2,2,2,3,3,3,3
        dc.b    -4,-4,-3,-3,-3,-3,-2,-2,-2,-2,-1,-1,-1,-1,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4
        dc.b    -5,-5,-4,-4,-4,-3,-3,-3,-2,-2,-2,-1,-1,-1,0,0,0,1,1,1,2,2,2,3,3,3,4,4,4,5,5,5
        dc.b    -6,-6,-5,-5,-4,-4,-4,-3,-3,-2,-2,-2,-1,-1,0,0,0,1,1,2,2,2,3,3,4,4,4,5,5,6,6,6
        dc.b    -7,-7,-6,-6,-5,-5,-4,-4,-3,-3,-2,-2,-1,-1,0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,7
        dc.b    -8,-7,-7,-6,-6,-5,-5,-4,-4,-3,-3,-2,-2,-1,-1,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,9
        dc.b    -9,-8,-8,-7,-7,-6,-5,-5,-4,-4,-3,-2,-2,-1,-1,0,1,1,2,2,3,4,4,5,5,6,7,7,8,8,9,10
        dc.b    -10,-9,-9,-8,-7,-7,-6,-5,-5,-4,-3,-3,-2,-1,-1,0,1,1,2,3,3,4,5,5,6,7,7,8,9,9,10,11
        dc.b    -11,-10,-10,-9,-8,-7,-7,-6,-5,-4,-4,-3,-2,-1,-1,0,1,1,2,3,4,4,5,6,7,7,8,9,10,10,11,12
        dc.b    -12,-11,-10,-10,-9,-8,-7,-6,-6,-5,-4,-3,-2,-2,-1,0,1,2,2,3,4,5,6,6,7,8,9,10,10,11,12,13
        dc.b    -13,-12,-11,-10,-10,-9,-8,-7,-6,-5,-4,-3,-3,-2,-1,0,1,2,3,3,4,5,6,7,8,9,10,10,11,12,13,14
        dc.b    -14,-13,-12,-11,-10,-9,-8,-7,-7,-6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6,7,7,8,9,10,11,12,13,14,15
        dc.b    -15,-14,-13,-12,-11,-10,-9,-8,-7,-6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16
    ENDIF