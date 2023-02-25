# AmigaDemoTemplate
## by Rich/Defekt - www.defekt.tk
### a template for Amiga demoscene productions using [amiga-assembly](https://github.com/prb28/vscode-amiga-assembly) VSCode extension

This is my personal template that I use to get going quickly with a production and has a library of commonly used routines that end up being in almost every one.

### To install

```
git clone --recurse-submodules git@github.com:asimilon/AmigaDemoTemplate.git
```

### To use

`cd` into `AmigaDemoTemplate` and run the BASH script `newdemo.sh` to create a new demo based on the template and optionally set up `git` repository (with "main" as the default branch name).
On Windows use [Git BASH](https://gitforwindows.org/), macOS and Linux can use the built in BASH.

---

## Built in routines

The following routines are available for use in your demos, for some of them you will need to enable them with a define.

* [System teardown/restore](#system-teardownrestore)
* [Copper Interrupt Handler](#copper-interrupt-handler)
* [Set Copperlist Bitplane Pointers](#set-copperlist-bitplane-pointers)
* [Colour fading](#colour-fading)
* [Random numbers](#random-numbers)
* [Macros](#macros)
* [Copperlist Macros](#copperlist-macros)

---

### System teardown/restore

```
ADT_TakeSystem
; disable AmigaOS ready for hardware bashing! \m/
; trashes: d0/a1/a4/a6
```
After taking the system you can check `ADT_SetupSuccess` word being non-zero to indicate an error occurred during `ADT_TakeSystem`.

eg.
```
    tst.w   ADT_SetupSuccess
    bne     .error
```

---

```
ADT_RestoreSystem
; bring back AmigaOS
; trashes: d0/a0-a1/a5-a6
```

Will probably be a really bad idea to call `ADT_RestoreSystem` without having called `ADT_TakeSystem` previously or if it had failed.

---

```
ADT_SetInterruptHandler
; install a Level 3 interrupt handler
; a0 = new interrupt address
; trashes a1
```

On 68010+ will also be a really bad idea to call `ADT_SetInterruptHandler` without having called `ADT_TakeSystem` previously or if it had failed.

---

### Copper Interrupt Handler

To use copper interrupt handler define `ADT_UseInterruptHandler = 1` before the `INCLUDE "xrefs.i"` when including that file.  Optionally define `ADT_PlayLSPTick = 1` if you want the LightSpeedPlayer tick routine to be called at the start of the interrupt.  You may also define `ADT_SHOW_RASTER = 1` to show the raster time taken by your routines.

```
ADT_SetupInterruptHandler
; expects CUSTOM register base in a6
; a0 - list of setup/VBL routine addresses, -1 signifies end of list
; eg.
; dc.l  setupIntro,introVBL
; dc.l  setupMain,mainVBL
; dc.l  -1
; trashes a1
```

This sets up the copper interrupt handler, `a0` should be a pointer to a list of setup and VBL routine addresses that you want to call, the first setup in the list will be called by `ADT_SetupInterruptHandler` and the first VBL routine will be called when [triggering a copper interrupt](#copperlist-macros) (which you should ideally do at the end of the screen to avoid any tearing if not double buffering).  The template code is set up such that left mouse button will exit immediately and right mouse button will advance to the next part in the list.  Setup routines are the place where you should setup your copperlist or whatever is needed for your next routine, VBL routines are free to trash whichever registers you please.

```
ADT_NextPart
```

This will advance to the next part, calling the setup routine immediately and installing the VBL routine to be called upon the next copper interrupt.  All registers are preserved.  If the last part has already been played then the template code is set up to exit at that point.

---

### Set Copperlist Bitplane Pointers

```
ADT_SetBPLPtrs
; a0 = address of image
; a1 = address of BPL1PTH in copper list
; d0 = size of plane
; d1 = number of planes
```

eg.
```
; ...copperlist...
copperBplPtrs:
    dc.w    BPL1PTH,0
    dc.w    BPL1PTL,0
    dc.w    BPL2PTH,0
    dc.w    BPL2PTL,0
; ...more copperlist...

; code:
    lea     myImage,a0
    lea     copperBplPtrs,a1
    move.l  #(320/8)*256,d0
    moveq.l #2,d1
    jsr     ADT_SetBPLPtrs
```

---

### Colour fading

There are two versions of colour fading routines.  Define `ADT_UseFade = 1` before the `INCLUDE "xrefs.i"` when including that file.
To use the "fast" versions (saves some cycles, at the expense of memory) define `ADT_UseFadeFast = 1` instead.

```
ADT_FadeColoursFromBlack
; a0 = colour table
; a1 = copperlist ptr
; d7 = number of colours
; d6 = fade amount 0-255 (fast version 0-15)
; trashes d0-d2 (fast version also trashes a2)
```

Use this is you just want to fade in/out from/to black.

```
ADT_FadeColours:
; a0 = source colour table
; a1 = target colour table
; a2 = copperlist ptr
; d7 = number of colours
; d6 = fade amount 0-255 (fast version 0-15)
; trashes d0-d4 (fast version also trashes a3)
```

Use this when you want to fade between a source palette and a destination palette.

```
ADT_FadeColour:
; d1 = source colour
; d2 = target colour
; d6 = fade amount 0-255 (fast version 0-15)
; returns faded colour in d0
; trashes d3-d4 (fast version also trashes a3)
```

Use this if you just want to fade a single colour.

---

### Random numbers

To use the random routine define `ADT_UseRandom = 1` before the `INCLUDE "xrefs.i"` when including that file.

```
ADT_GetRandomBits16
; expects CUSTOM register base in a6
; returns a word of random bit in d0, upper 16 bits unaffected
; trashes d1
; 158 cycles on 68k
```

---

```
ADT_GetRandomBits32
; expects CUSTOM register base in a6
; returns a longword of random bits in d0
; trashes d1
; 192 cycles on 68k
```

---

Before calling these you should call once:
```
ADT_InitRandom
; expects CUSTOM register base in a6
; trashes d0
```

---

### Macros

You can also use the following macros:

```
ADT_WaitVBL
; wait for the vertical blank period to start
; trashes d0
```

```
ADT_WaitLine <line_number>
; wait for the specified scanline
; trashes d0
```

```
ADT_BlitWait
; wait for the blitter to finish
```

### Copperlist macros

```
COPPER_HALT               ; use at the end of your copperlist
```

```
COPPER_EOL_255            ; wait until the end of line 255,
                          ; used to access lines beyond 255 on PAL systems
```

```
COPPER_WAIT_LINE <line>   ; wait for the start of specified line
```

```
COPPER_INTERRUPT          ; trigger copper interrupt
```

These can be used as follows:
```
copperList:
    dc.w    COLOR00,$000    ; set background black
    COPPER_WAIT_LINE 100    ; wait for line 100
    dc.w    COLOR00,$f00    ; set background red
    COPPER_WAIT_LINE 200    ; wait for line 200
    dc.w    COLOR00,$0f0    ; set background green
    COPPER_EOL_255
    COPPER_WAIT_LINE 55     ; waiting for line 255+55 = 300
    dc.w    COLOR00,$00f    ; set background blue
    COPPER_INTERRUPT        ; trigger copper interrupt
    COPPER_HALT
    COPPER_HALT
```

---

## Acknowledgements

A greet would be nice if you used this template/any routines. 😁

The system tear down/restore code is based on the C code provided in [Amiga C/C++ Compile, Debug & Profile](https://marketplace.visualstudio.com/items?itemName=BartmanAbyss.amiga-debug) by Bartman^Abyss, but that extension is Windows only and for whatever nostalgic/masochistic reason I prefer writing 68k assembler by hand, and using macOS!

[LightSpeedPlayer](https://github.com/arnaud-carre/LSPlayer) by Leonard/Oxygene is included as a git submodule because who wants to spend more than 2 raster lines playing music? 😂

[Shrinkler](https://github.com/askeksa/Shrinkler) by Blueberry/Loonies is included as a git submodule for when you need to decrunch stuff in your production.

## Contributing

I will gladly accept pull requests for any improvements that can be made and credit accordingly.