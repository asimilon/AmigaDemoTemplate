; AmigaDemoTemplate (c)2023 Rich/Defekt

    MACRO   ADT_WaitVBL
.vblwait1\@:
    move.l  CUSTOM+VPOSR,d0
    and.l   #$1ff00,d0
    cmp.l   #311<<8,d0
    bne.s   .vblwait1\@
.vblwait2\@:
    move.l  CUSTOM+VPOSR,d0
    and.l   #$1ff00,d0
    cmp.l   #311<<8,d0
    beq.s   .vblwait2\@
    ENDM

    MACRO   ADT_WaitLine
.vblline1\@:
    move.l  CUSTOM+VPOSR,d0
    and.l   #$1ff00,d0
    cmp.l   #\1<<8,d0
    bne.s   .vblline1\@
.vblline2\@:
    move.l  CUSTOM+VPOSR,d0
    and.l   #$1ff00,d0
    cmp.l   #\1<<8,d0
    beq.s   .vblline2\@
    ENDM

    MACRO   ADT_BlitWait
.bltwait\@:
    btst    #14,CUSTOM+DMACONR
    bne.s   .bltwait\@
    ENDM
