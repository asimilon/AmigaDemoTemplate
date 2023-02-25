;  ▄▄▄▄▄▄▄ ▄▄   ▄▄ ▄▄▄ ▄▄▄▄▄▄▄ ▄▄▄▄▄▄    ▄▄▄▄▄▄  ▄▄▄▄▄▄▄ ▄▄   ▄▄ ▄▄▄▄▄▄▄
; █       █  █▄█  █   █       █      █  █      ██       █  █▄█  █       █
; █   ▄   █       █   █   ▄▄▄▄█  ▄   █  █  ▄    █    ▄▄▄█       █   ▄   █
; █  █▄█  █       █   █  █  ▄▄█ █▄█  █  █ █ █   █   █▄▄▄█       █  █ █  █
; █       █       █   █  █ █  █      █  █ █▄█   █    ▄▄▄█       █  █▄█  █
; █   ▄   █ ██▄██ █   █  █▄▄█ █  ▄   █  █       █   █▄▄▄█ ██▄██ █       █
; █▄▄█ █▄▄█▄█   █▄█▄▄▄█▄▄▄▄▄▄▄█▄█ █▄▄█  █▄▄▄▄▄▄██▄▄▄▄▄▄▄█▄█   █▄█▄▄▄▄▄▄▄█
;      ▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄ ▄▄   ▄▄ ▄▄▄▄▄▄▄ ▄▄▄     ▄▄▄▄▄▄ ▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄
;     █       █       █  █▄█  █       █   █   █      █       █       █
;     █▄     ▄█    ▄▄▄█       █    ▄  █   █   █  ▄   █▄     ▄█    ▄▄▄█
;       █   █ █   █▄▄▄█       █   █▄█ █   █   █ █▄█  █ █   █ █   █▄▄▄
;       █   █ █    ▄▄▄█       █    ▄▄▄█   █▄▄▄█      █ █   █ █    ▄▄▄█
;       █   █ █   █▄▄▄█ ██▄██ █   █   █       █  ▄   █ █   █ █   █▄▄▄
;       █▄▄▄█ █▄▄▄▄▄▄▄█▄█   █▄█▄▄▄█   █▄▄▄▄▄▄▄█▄█ █▄▄█ █▄▄▄█ █▄▄▄▄▄▄▄█
;                           (c) 2023 Rich/Defekt

    INCDIR  "include"
    INCLUDE "hw.i"
    INCLUDE "hardware/cia.i"

; define extra routines to be included here
ADT_UseFadeFast = 1
ADT_PlayLSPTick = 1
ADT_UseInterruptHandler = 1

    INCLUDE "xrefs.i"

SHOW_RASTER = 0

    SECTION ".demo_code",CODE
    movem.l d0-d7/a0-a6,-(sp)

    jsr     ADT_TakeSystem
    tst.w   ADT_SetupSuccess
    bne     .error

    lea     routinesList,a0
    lea     CUSTOM,a6
    jsr     ADT_SetupInterruptHandler
.loop
    move.b  CIAA+ciapra,d0                  ; test left mouse
    and.b   #$40,d0
    beq.s   .exit                           ; it's down, exit demo

    move.w  POTINP(a6),d0                   ; test right mouse
    and.w   #$400,d0
    bne.s   .noRightMouseDown
    jsr     ADT_NextPart                    ; it's down, advance to next part
.noRightMouseDown
    tst.w   ADT_IsFinished
    beq.s   .loop
.exit
    jsr     ADT_RestoreSystem
.error
    movem.l (sp)+,d0-d7/a0-a6
    rts

    INCLUDE "common.i"

routinesList:
    dc.l    setupDemo,demoVBL
    dc.l    -1

setupDemo:
    move.l  a0,-(sp)
    lea     imageData,a0
    lea     copperBplPtrs,a1
    move.l  #(320/8)*256,d0
    moveq.l #5,d1
    jsr     ADT_SetBPLPtrs

    lea     CUSTOM,a6
    move.w  #%1000001110000000,DMACON(a6)
    move.l  #copperList,COP1LC(a6)
    move.w  d0,COPJMP1(a6)                  ; start copper

    lea     modData,a0
    lea     modSamples,a1
    lea     copperDMAConPatch+3,a2
    jsr     LSP_MusicInit
    move.l  (sp)+,a0
    rts

demoVBL:
    lea     sourceColours,a0
    lea     colourPalette,a1
    lea     copperColours,a2
    moveq.l #32,d7
    move.w  fadeValue,d6
    addq.w  #1,d6
    cmpi.w  #16,d6
    blt.s   .doFade
    moveq.l #15,d6
.doFade
    move.w  d6,fadeValue
    jmp     ADT_FadeColoursFast             ; tail call optimisation

fadeValue:
    dc.w    0

sourceColours:
    dcb.w   32,$fff

colourPalette:
	dc.w	$0000,$0322,$0200,$0433,$0444,$0544,$0633,$0654
	dc.w	$0555,$0655,$0766,$0755,$0876,$0977,$0a98,$0789
	dc.w	$0caa,$0dcc,$0da9,$0b87,$0ecb,$0edd,$0966,$0fee
	dc.w	$0eed,$0511,$0844,$0c76,$0944,$0b55,$0822,$0a33

    INCDIR "LSPlayer"
    INCLUDE "LightSpeedPlayer.asm"

    INCDIR "include_binary"
modData:
    INCBIN "ScrewLevity.lsmusic"        ; amazing MOD by Synesthesia/Defekt

    SECTION ".data_chip", data_c, chip
copperList:
    dc.w        $01fC,$0                ; AGA compat.
    dc.w        DIWSTRT,$2c81           ; for widescreen use DIWSTRT,$5281
    dc.w        DIWSTOP,$2cc1           ; for widescreen use DIWSTOP,$06c1
    dc.w        DDFSTRT,$0038
    dc.w        DDFSTOP,$00d0

    dc.w        BPLCON0,$5200
    dc.w        BPLCON1,$0000
    dc.w        BPLCON2,$0024
    dc.w        $106,$0                 ; AGA compat. BPLCON3
copperBplPtrs:
    dc.w        BPL1PTH,$0
    dc.w        BPL1PTL,$0
    dc.w        BPL2PTH,$0
    dc.w        BPL2PTL,$0
    dc.w        BPL3PTH,$0
    dc.w        BPL3PTL,$0
    dc.w        BPL4PTH,$0
    dc.w        BPL4PTL,$0
    dc.w        BPL5PTH,$0
    dc.w        BPL5PTL,$0

copperColours:
    dc.w        COLOR00,$fff,COLOR01,$fff,COLOR02,$fff,COLOR03,$fff
    dc.w        COLOR04,$fff,COLOR05,$fff,COLOR06,$fff,COLOR07,$fff
    dc.w        COLOR08,$fff,COLOR09,$fff,COLOR10,$fff,COLOR11,$fff
    dc.w        COLOR12,$fff,COLOR13,$fff,COLOR14,$fff,COLOR15,$fff
    dc.w        COLOR16,$fff,COLOR17,$fff,COLOR18,$fff,COLOR19,$fff
    dc.w        COLOR20,$fff,COLOR21,$fff,COLOR22,$fff,COLOR23,$fff
    dc.w        COLOR24,$fff,COLOR25,$fff,COLOR26,$fff,COLOR27,$fff
    dc.w        COLOR28,$fff,COLOR29,$fff,COLOR30,$fff,COLOR31,$fff

    COPPER_EOL_255
    COPPER_WAIT_LINE 45
    COPPER_INTERRUPT
    COPPER_WAIT_LINE 56
copperDMAConPatch:
	dc.l	    $00968000
    COPPER_HALT
    COPPER_HALT

    INCDIR "include_binary"
imageData:
    INCBIN "Rise-of-the-machine_bitplanes.bin"      ; Stable Diffusion demo image

modSamples:
    INCBIN "ScrewLevity.lsbank"                     ; amazing MOD by Synesthesia/Defekt