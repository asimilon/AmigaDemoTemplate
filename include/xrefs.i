; AmigaDemoTemplate
; (c)2023 Rich/Defekt
; this just declares all the subroutines available in common.i

    XREF    ADT_TakeSystem
    XREF    ADT_RestoreSystem
    XREF    ADT_SetInterruptHandler
    XREF    ADT_SetupSuccess

    IFD ADT_UseInterruptHandler
    XREF    ADT_SetupInterruptHandler
    XREF    ADT_NextPart
    XREF    ADT_IsFinished
    ENDIF

    XREF    ADT_SetBPLPtrs

    IFD ADT_UseRandom
    XREF    ADT_InitRandom
    XREF    ADT_GetRandomBits16
    XREF    ADT_GetRandomBits32
    ENDIF

    IFD ADT_UseFade
    XREF    ADT_FadeColoursFromBlack
    XREF    ADT_FadeColours
    XREF    ADT_FadeColour
    ENDIF

    IFD ADT_UseFadeFast
    XREF    ADT_FadeColoursFromBlackFast
    XREF    ADT_FadeColoursFast
    XREF    ADT_FadeColourFast
    ENDIF