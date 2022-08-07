
; ASM FILE code\gameflow\battle\battleactions\createbattlesceneanimation-standard.asm :
; Standard reimplementation of battlescene animation creator function.

; =============== S U B R O U T I N E =======================================

; Load proper battlescene sprite/magic animation properties.
; 
;       In: a2 = battlescene script stack frame
;           a3 = pointer to action data in RAM
;           a4 = battlescene actor index in RAM

allCombatantsCurrentHpTable = -24
debugDodge = -23
debugCritical = -22
debugDouble = -21
debugCounter = -20
explodingActor = -17
explode = -16
specialCritical = -15
ineffectiveAttack = -14
doubleAttack = -13
counterAttack = -12
silencedActor = -11
stunInaction = -10
curseInaction = -9
muddledActor = -8
targetIsOnSameSide = -7
rangedAttack = -6
dodge = -5
targetDies = -4
criticalHit = -3
inflictAilment = -2
cutoff = -1

CreateBattlesceneAnimation:
                
                movem.l d0-d3/a0,-(sp)
                moveq   #BATTLEANIMATION_ATTACK,d5  ; regular attack animation by default
                
                ; Jump to module for battleaction
                move.w  (a3),d1
                cmpi.w  #BATTLEACTION_MUDDLE,d1
                beq.s   @Done
                
                bscHideTextBox
                move.b  (a4),d0
                add.w   d1,d1
                add.w   d1,d1
                jsr     @bt_Battleactions(pc,d1.w)
                
                ; Animate sprite
                bsr.w   WriteBattlesceneScript_AnimateAction
                cmpi.w  #BATTLEACTION_BURST_ROCK,(a3)
                bne.s   @Done
                
                ; Kill actor when it explodes (Burst Rock)
                move.w  #$8000,d2
                bsr.w   GetStatusEffects
                tst.b   d0
                bmi.s   @Enemy
                executeAllyReaction d2,#0,d1,#1 ; HP change (signed), MP change (signed), Status Effects, Flags
                bra.s   @Continue
@Enemy:         executeEnemyReaction d2,#0,d1,#1 ; HP change (signed), MP change (signed), Status Effects, Flags
@Continue:      moveq   #0,d1
                bsr.w   SetCurrentHP
@Done:          movem.l (sp)+,d0-d3/a0
@Return:        rts

    ; End of function CreateBattlesceneAnimation

@bt_Battleactions:
                bra.w   @Attack
                bra.w   @CastSpell
                bra.w   @UseItem
                bra.w   @Return     ; Stay
                bra.w   @Return     ; Burst Rock
                bra.w   @Return     ; Muddled
                bra.w   @Return     ; Prism Laser
; ---------------------------------------------------------------------------

@Attack:        module
                bsr.w   GetSpellAnimation
                moveq   #2,d2
                
                ; Check special critical hits
                tst.b   d0
                bmi.s   @Enemy1
                lea     tbl_SpecialCriticalHitsForClasses(pc), a0
                bsr.w   GetClass
                bra.s   @Continue1
@Enemy1:        lea     tbl_SpecialCriticalHitsForEnemies(pc), a0
                bsr.w   GetEnemyIndex
@Continue1:     jsr     (FindSpecialPropertyBytesAddressForObject).w
                bcs.s   @CheckUnarmed
                
                ; Determine special critical hit
                move.w  #256,d0
                jsr     (GenerateRandomOrDebugNumber).w
                cmp.b   (a0)+,d0
                bls.s   @CheckUnarmed
                move.b  (a0),d5
                move.b  #$FF,specialCritical(a2)
                bra.s   @Return
                
@CheckUnarmed:  move.b  (a4),d0
                bmi.s   @Enemy2
                lea     tbl_UnarmedAttackAnimationsForClasses(pc), a0
                bra.s   @Continue2
@Enemy2:        lea     tbl_UnarmedAttackAnimationsForEnemies(pc), a0
@Continue2:     jsr     (FindSpecialPropertyBytesAddressForObject).w
                bcs.s   @Return
                
                ; If not weapon equipped, return spell and battle animations -> d4.w, d5.w
                bsr.w   GetEquippedWeapon
                cmpi.w  #$FFFF,d1
                bne.s   @Return
                move.b  (a0)+,d4
                move.b  (a0),d5
@Return:        rts
                modend
; ---------------------------------------------------------------------------
                
@CastSpell:     module
                
                ; Decrease caster's MP
                move.w  BATTLEACTION_OFFSET_ITEM_OR_SPELL(a3),d1  
                bsr.w   GetSpellCost
                move.w  d1,d2
                neg.w   d2
                bsr.w   GetStatusEffects
                tst.b   d0
                bmi.s   @Enemy1
                executeAllyReaction #0,d2,d1,#0 ; HP change (signed), MP change (signed), Status Effects, Flags
                bra.s   @Continue1
@Enemy1:        executeEnemyReaction #0,d2,d1,#0 ; HP change (signed), MP change (signed), Status Effects, Flags
@Continue1:     moveq   #1,d2
                
                ; Determine spellcasting animation
                tst.b   d0
                bmi.s   @Enemy2
                lea     tbl_SpellcastAnimationsForClasses(pc), a0
                bsr.w   GetClass
                bra.s   @Continue2
@Enemy2:        lea     tbl_SpellcastAnimationsForEnemies(pc), a0
                bsr.w   GetEnemyIndex
@Continue2:     jsr     (FindSpecialPropertyBytesAddressForObject).w
                bcs.s   @Return
                move.b  (a0),d5
@Return:        rts
                modend
; ---------------------------------------------------------------------------

@UseItem:       module
                moveq   #BATTLEANIMATION_USE_ITEM,d5    ; regular item usage animation by default (unused)
                moveq   #1,d2
                
                ; Determine item usage animation
                tst.b   d0
                bmi.s   @Enemy2
                lea     tbl_UseItemAnimationsForClasses(pc), a0
                bsr.w   GetClass
                bra.s   @Continue2
@Enemy2:        lea     tbl_UseItemAnimationsForEnemies(pc), a0
                bsr.w   GetEnemyIndex
@Continue2:     jsr     (FindSpecialPropertyBytesAddressForObject).w
                bcs.s   @Return
                move.b  (a0),d5
@Return:        rts
                modend
