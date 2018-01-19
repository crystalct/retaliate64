;===============================================================================
;  gameFlow.asm - Game Flow Control
;
;  Copyright (C) 2017,2018 Marcelo Lv Cabral - <https://lvcabral.com>
;
;  Distributed under the MIT software license, see the accompanying
;  file LICENSE or https://opensource.org/licenses/MIT
;
;===============================================================================
; Constants

FlowNumLives    = 1
FlowStateMenu   = 0
FlowStateAlive  = 1
FlowStateDying  = 2

;===============================================================================
; Variables

flowScoreX      byte 7
flowScoreNumX   byte 0
flowScoreY      byte 0
score1          byte 0
score2          byte 0
score3          byte 0

time1           byte 0
time2           byte 0

lives           byte 0

flowHiScoreX    byte 24
flowHiScoreNumX byte 0
flowHiScoreY    byte 0
hiscore1        byte 0
hiscore2        byte 0
hiscore3        byte 0
statsHiScore    byte 0

flowGaugeX      byte 1
flowGaugeOneX   byte 2
flowGaugePctX   byte 4
flowGaugeBarX   byte 5
flowGaugeY      byte 24
energy          byte 0
flowGaugeCnt    byte 0
flowGaugeClr    byte 0

flowAmmoX       byte 32
flowAmmoNumX    byte 0
flowAmmoY       byte 24
bullets         byte 0
bullets1        byte 0
bullets2        byte 0
aliens1         byte 0
aliens2         byte 0

flowScoreText   text 'score:'
                byte 0
flowHiScoreText text 'hi:'
                byte 0
flowAmmoText    text 'ammo:'
                byte 0
flowAmmoClear   dcb 8, SpaceCharacter
                byte 0
flowGaugeSpc    byte $20
flowGaugeOne    byte $31
flowGaugeBar    byte $50
flowGaugeTxt    byte $31, $00
flowGaugePct    byte $25, $00

flowGaugeClear  dcb 19, SpaceCharacter
                byte 0
flowState       byte FlowStateMenu

;===============================================================================
; Jump Tables

gameFlowJumpTableLow
        byte <gameFlowUpdateMenu
        byte <gameFlowUpdateAlive
        byte <gameFlowUpdateDying

gameFlowJumpTableHigh
        byte >gameFlowUpdateMenu
        byte >gameFlowUpdateAlive
        byte >gameFlowUpdateDying

;===============================================================================
; Macros/Subroutines

gameFlowInit
        LIBSCREEN_DRAWTEXT_AAAV flowScoreX, flowScoreY, flowScoreText, White
        jsr gameFlowScoreDisplay

        LIBSCREEN_DRAWTEXT_AAAV flowHiScoreX, flowHiScoreY, flowHiScoreText, White
        jsr gameFlowHiScoreDisplay

        rts

;===============================================================================
gameFlowUpdateMenu
        lda menuDisplayed
        bne gFUMCheckFire
        jsr gameMenuShowLogo
        jsr gameMenuShowText
        jsr gameMenuLevelDisplay

gFUMCheckFire
        LIBINPUT_GETFIREPRESSED
        beq gFUMStartGame

        lda screenColumn
        cmp #MenuCredits
        beq gFUMDecScreenTimer
        cmp #MenuGameOver
        beq gFUMDecScreenTimer
        cmp #MenuHangar
        beq gFUMHangarKeys

        ; Main Menu Key handling
        jsr SCNKEY
        jsr GETIN
        cmp #0
        beq gFUMReturn
        cmp #KEY_F1
        beq gFUMLevel
        cmp #KEY_F3
        beq gFUMHangarMenu
        cmp #KEY_F5
        beq gFUMShowCredits
        jmp gFUMReturn

gFUMStartGame
        jsr gameMenuClearText
        jsr gameFlowShowGameStatus

        ; reset
        lda #MenuGameOver
        sta screenColumn
        jsr gameFlowResetScore
        jsr gameFlowResetLives
        jsr gameAliensReset
        jsr gamePlayerReset

        ; change state
        lda #FlowStateAlive
        sta flowState
gFUMReturn
        rts

gFUMLevel
        jsr gameMenuLevelChange
        jsr gameMenuLevelDisplay
        jmp gFUMEnd

gFUMHangarMenu
        lda #MenuHangar
        sta screenColumn
        jsr gameMenuShowText
        jsr gameMenuSfxDisplay
        jsr gameMenuModelReset
        jmp gFUMModelDisplay

gFUMShowCredits
        jsr gameFlowResetCreditsTime
        lda #MenuCredits
        sta screenColumn
        jsr gameMenuShowText
        jmp gFUMEnd

gFUMDecScreenTimer
        jsr gameFlowDecreaseTime
        lda time2
        bne gFUMReturn
        jmp gFUMShowStory

gFUMHangarKeys
        lda messageFlag
        bne gFUMDecMsgTimer

        ; Hangar Menu Key handling
        jsr SCNKEY
        jsr GETIN
        cmp #0
        beq gFUMReturn
        cmp #KEY_LEFT
        beq gFUMPrevModel
        cmp #KEY_RIGHT
        beq gFUMNextModel
        cmp #KEY_F1
        beq gFUMShipColor
        cmp #KEY_F2
        beq gFUMShieldColor
        cmp #KEY_F3
        beq gFUMShowStory
        cmp #KEY_F5
        beq gFUMSfxSwitch
        cmp #KEY_F7
        beq gFUMSaveData
        jmp gFUMEnd

gFUMDecMsgTimer
        jsr gameFlowDecreaseTime
        lda time2
        bne gFUMEnd
        jsr gameMenuRestore
        jsr gameMenuSfxDisplay
        jmp gFUMEnd

gFUMShipColor
        jsr gameMenuShipColorNext
        jmp gFUMModelDisplay

gFUMShieldColor
        jsr gameMenuShieldColorNext
        jsr gameMenuColorDisplay
        jmp gFUMEnd

gFUMPrevModel
        jsr gameMenuModelPrevious
        jmp gFUMModelDisplay

gFUMNextModel
        jsr gameMenuModelNext
        jmp gFUMModelDisplay

gFUMSfxSwitch
        jsr gameMenuSfxSwitch
        jmp gFUMEnd

gFUMSaveData
        jsr gameDataSave
        jsr gameMenuSaveDisplay
        jsr gameFlowResetMsgTime
        jmp gFUMEnd

gFUMShowStory
        lda #MenuStory
        sta screenColumn
        jsr gameMenuModelHide
        jsr gameMenuShowLogo
        jsr gameMenuShowText
        jsr gameMenuLevelDisplay
        jmp gFUMEnd

gFUMModelDisplay
        jsr gameMenuColorDisplay
        jsr gameMenuModelDisplay

gFUMEnd
        rts

;===============================================================================
gameFlowShowGameStatus
        jsr gameflowShieldGaugeDisplay

        LIBSCREEN_DRAWTEXT_AAAV flowAmmoX, flowAmmoY, flowAmmoText, White
        jsr gameflowBulletsDisplay

        rts

;===============================================================================
gameFlowUpdateAlive
        rts

;===============================================================================
gameFlowUpdateDying
        LIBSPRITE_ISANIMPLAYING_A playerSprite
        bne gFUDEnd

        lda lives
        bne gFUDHasLives

        jsr gameAliensWaveReset
        jsr gameFlowClearStatusLine
        jsr gameFlowResetGameOverTime

        ; change state
        lda #FlowStateMenu
        sta flowState
        jsr gameMenuShowText
        jsr gameMenuShowStats

        jmp gFUDEnd

gFUDHasLives
        LIBINPUT_GETFIREPRESSED
        bne gFUDEnd

        ; reset 
        jsr gamePlayerReset

        ; change state
        lda #FlowStateAlive
        sta flowState
        
gFUDEnd
        rts

;===============================================================================
gameFlowClearStatusLine

        LIBSCREEN_DRAWTEXT_AAAV flowGaugeX, flowGaugeY, flowGaugeClear, White
        LIBSCREEN_DRAWTEXT_AAAV flowAmmoX, flowAmmoY, flowAmmoClear, White

        rts

;===============================================================================
gameFlowUpdate

        ; get the current state
        ldy flowState 

        ; write the subroutine address to a zeropage location
        lda gameFlowJumpTableLow,y
        sta ZeroPageLow
        lda gameFlowJumpTableHigh,y
        sta ZeroPageHigh

        ; jump to the subroutine the zeropage location points to
        jmp (ZeroPageLow)

;===============================================================================
gameFlowIncreaseScore
        
        sed             ;set decimal mode
        clc
        lda aliensScore ;points scored
        adc score1      ;ones and tens
        sta score1
        lda score2      ;hundreds and thousands
        adc #00
        sta score2
        lda score3      ;ten-thousands and hundred-thousands
        adc #00
        sta score3
        clc
        lda #1          ;alien destroyed
        adc aliens1     ;ones and tens
        sta aliens1
        lda aliens2     ;hundreds and thousands
        adc #00
        sta aliens2
        cld             ;clear decimal mode

        jsr gameFlowScoreDisplay

        rts

;===============================================================================
gameFlowResetScore
        
        lda #0
        sta score1
        sta score2
        sta score3
        sta statsHiScore

        jsr gameFlowScoreDisplay 

        rts

;===============================================================================
gameFlowResetCreditsTime

        lda #$60
        sta time1

        lda #CreditsTime
        sta time2
        rts

;===============================================================================
gameFlowResetGameOverTime

        lda #$60
        sta time1

        lda #GameOverTime
        sta time2
        rts

;===============================================================================
gameFlowResetMsgTime

        lda #$60
        sta time1

        lda #MessageTime
        sta time2
        rts

;===============================================================================
gameFlowDecreaseTime

        lda time2
        beq gFDTDone

        sed             ;set decimal mode
        sec             ; sec is the same as clear borrow
        lda time1       ; Get first number
        sbc #1          ; Subtract 1
        sta time1       ; Store in first number
        lda time2       ; Get 2nd first number
        sbc #0          ; Subtract borrow
        sta time2       ; Store 2nd number
        cld              ;clear decimal mode

gFDTDone
        rts

;===============================================================================
gameFlowAddBullet
        
        ; Check if Ammo reached 99 (maximum)
        lda bullets
        cmp #$99
        beq gFABDone

        sed             ;set decimal mode
        clc
        lda #1          ;1 bullet added
        adc bullets
        sta bullets
        clc
        lda #1          ;add to statistics
        adc bullets1    ;ones and tens
        sta bullets1
        lda bullets2    ;hundreds and thousands
        adc #00
        sta bullets2
        cld             ;clear decimal mode

        jsr gameflowBulletsDisplay

gFABDone
        rts

;===============================================================================
gameFlowUseBullet
        
        sed             ;set decimal mode
        sec
        lda bullets
        sbc #1          ;1 bullet used
        sta bullets
        cld             ;clear decimal mode

        jsr gameflowBulletsDisplay

        rts

;===============================================================================
gameFlowUpdateGauge
        
        sed             ;set decimal mode
        clc
        lda #0
        adc shieldEnergy
        sta energy
        cld             ;clear decimal mode

        jsr gameflowShieldGaugeDisplay

        rts

;===============================================================================
gameFlowResetLives

        lda #FlowNumLives
        sta lives

        lda #0
        sta bullets
        sta bullets1
        sta bullets2
        sta aliens1
        sta aliens2

        jsr gameflowBulletsDisplay

        rts

;===============================================================================
gameFlowPlayerDied

        jsr gameBulletsReset ; stops in flight bullets from scoring

        dec lives
        bne gFPDHasLivesLeft 
        
        jsr gameFlowUpdateHiScore

gFPDHasLivesLeft
        jsr gameflowBulletsDisplay

        ; change state
        lda #FlowStateDying
        sta flowState

        rts

;===============================================================================
gameFlowUpdateHiScore
        ; Do not update if same score
        lda score1
        cmp hiscore1
        bne gFUCheckHi
        lda score2
        cmp hiscore2
        bne gFUCheckHi
        lda score3
        cmp hiscore3
        beq gFUHNotHi

gFUCheckHi
        ; http://6502.org/tutorials/decimal_mode.html#4.2
        ; a common technique for comparing multi-byte numbers
        lda score1
        cmp hiscore1
        lda score2
        sbc hiscore2
        lda score3
        sbc hiscore3
        bcc gFUHNotHi

        lda score1
        sta hiscore1
        lda score2
        sta hiscore2
        lda score3
        sta hiscore3
        
        lda #True
        sta statsHiScore

        jsr gameFlowHiScoreDisplay

gFUHNotHi
        rts

;===============================================================================
gameFlowScoreDisplay

        LIBMATH_ADD8BIT_AVA flowScoreX, 6, flowScoreNumX
        LIBSCREEN_DRAWDECIMAL_AAAV flowScoreNumX, flowScoreY, score3, White

        LIBMATH_ADD8BIT_AVA flowScoreX, 8, flowScoreNumX
        LIBSCREEN_DRAWDECIMAL_AAAV flowScoreNumX, flowScoreY, score2, White

        LIBMATH_ADD8BIT_AVA flowScoreX, 10, flowScoreNumX
        LIBSCREEN_DRAWDECIMAL_AAAV flowScoreNumX, flowScoreY, score1, White

        rts

;===============================================================================
gameFlowHiScoreDisplay

        LIBMATH_ADD8BIT_AVA flowHiScoreX, 3, flowHiScoreNumX
        LIBSCREEN_DRAWDECIMAL_AAAV flowHiScoreNumX, flowHiScoreY, hiscore3, White

        LIBMATH_ADD8BIT_AVA flowHiScoreX, 5, flowHiScoreNumX
        LIBSCREEN_DRAWDECIMAL_AAAV flowHiScoreNumX, flowHiScoreY, hiscore2, White

        LIBMATH_ADD8BIT_AVA flowHiScoreX, 7, flowHiScoreNumX
        LIBSCREEN_DRAWDECIMAL_AAAV flowHiScoreNumX, flowHiScoreY, hiscore1, White

        rts

;===============================================================================
gameflowBulletsDisplay

        LIBMATH_ADD8BIT_AVA flowAmmoX, 5, flowAmmoNumX
        LIBSCREEN_DRAWDECIMAL_AAAV flowAmmoNumX, flowAmmoY, bullets, White

        rts
;===============================================================================
gameflowShieldGaugeDisplay
        
        lda shieldEnergy
        cmp #ShieldMaxEnergy
        bne gFSGDNoHundred

        lda flowGaugeOne
        jmp gFSGDGauge

gFSGDNoHundred
        lda flowGaugeSpc

gFSGDGauge
        sta flowGaugeTxt
        LIBSCREEN_DRAWTEXT_AAAV flowGaugeX, flowGaugeY, flowGaugeTxt, White
        LIBSCREEN_DRAWDECIMAL_AAAV flowGaugeOneX, flowGaugeY, energy, White
        LIBSCREEN_DRAWTEXT_AAAV flowGaugePctX, flowGaugeY, flowGaugePct, White
        lda #1
        sta flowGaugeCnt

gFSGDLoop
        jsr gameflowSelectGaugeColor
        lda flowGaugeCnt
        jsr gameflowMultiplyByTen
        cmp shieldEnergy
        bcc gFSGDBar
        lda flowGaugeSpc
        jmp gFSGDDraw

gFSGDBar
        lda flowGaugeBar

gFSGDDraw
        sta flowGaugeTxt
        LIBMATH_ADD8BIT_AAA flowGaugePctX, flowGaugeCnt, flowGaugeBarX
        LIBSCREEN_DRAWTEXT_AAAA flowGaugeBarX, flowGaugeY, flowGaugeTxt, flowGaugeClr
        inc flowGaugeCnt
        lda flowGaugeCnt
        cmp #15
        bne gFSGDLoop

        rts

;===============================================================================
gameflowSelectGaugeColor
        ldy shieldEnergy
        cpy #45         ; if shield is critically low change color to red
        bcc gFSGCRed
        lda shieldColor
        sta flowGaugeClr
        jmp gFSGCDone

gFSGCRed
        lda #Red
        sta flowGaugeClr

gFSGCDone
        rts

;===============================================================================
gameflowMultiplyByTen
; Code from: http://codebase64.org/doku.php?id=base:multiplication_with_a_constant

        sta ZeroPageTemp
        asl              ; Shifting something left three times multiplies it by eight
        asl 
        asl  
        asl ZeroPageTemp ; Shifting something left one time multiplies it by two
        clc              ; Clear carry
        adc ZeroPageTemp ; Add the two results together

        rts
