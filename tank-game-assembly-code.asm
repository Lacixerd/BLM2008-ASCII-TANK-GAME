#make_COM#

ORG 100h

JMP main

VIDEO_SEG       EQU 0B800h
SCREEN_W        EQU 80
SCREEN_H        EQU 25
FIELD_TOP       EQU 3
FIELD_BOTTOM    EQU 22
FIELD_LEFT      EQU 1
FIELD_RIGHT     EQU 78

MAX_BULLETS     EQU 20
NUM_TARGETS     EQU 8

DIR_UP          EQU 0
DIR_RIGHT       EQU 1
DIR_DOWN        EQU 2
DIR_LEFT        EQU 3

ATTR_NORMAL     EQU 07h
ATTR_TITLE      EQU 0Eh
ATTR_MENU       EQU 0Bh
ATTR_TANK       EQU 0Eh
ATTR_BULLET     EQU 0Fh
ATTR_TARGET     EQU 0Ch
ATTR_OBSTACLE   EQU 08h
ATTR_BORDER     EQU 09h
ATTR_STATUS     EQU 0Ah
ATTR_WIN        EQU 0Ah
ATTR_LOSE       EQU 0Ch
ATTR_NEWBEST    EQU 0Eh
ATTR_PROMPT     EQU 0Fh

player_x        DB 40
player_y        DB 12
player_dir      DB DIR_UP
bullets_left    DB MAX_BULLETS
score           DW 0
best_score      DW 0
targets_left    DB NUM_TARGETS
won             DB 0
new_bullet_slot DB 0FFh
tick_counter    DB 0
active_bullets  DB 0

bullet_active   DB MAX_BULLETS DUP(0)
bullet_x        DB MAX_BULLETS DUP(0)
bullet_y        DB MAX_BULLETS DUP(0)
bullet_dx       DB MAX_BULLETS DUP(0)
bullet_dy       DB MAX_BULLETS DUP(0)

target_x        DB  6, 25, 45, 60, 15, 74, 70, 35
target_y        DB  4,  4,  6, 12, 14,  9, 19, 20
target_active   DB  1,  1,  1,  1,  1,  1,  1,  1
target_init     DB  1,  1,  1,  1,  1,  1,  1,  1

obstacle_data:
    DB 10,6, 11,6, 12,6, 13,6, 14,6
    DB 10,7, 10,8
    DB 30,9, 31,9, 32,9, 33,9, 34,9
    DB 50,11, 50,12, 50,13, 50,14
    DB 20,16, 21,16, 22,16, 23,16
    DB 58,5, 59,5, 60,5
    DB 65,18, 66,18, 67,18
    DB 40,19, 41,19, 42,19
    DB  5,18,  5,19
    DB 70,7, 71,7
    DB 55,17, 56,17, 57,17
    DB 25,11, 26,11
    DB 38,14, 38,15, 38,16
    DB 60,21, 61,21, 62,21
    DB 0FFh

title_bar  DB '=========================================', 0
title_txt  DB 'A S C I I   T A N K   O Y U N U', 0
menu_sub   DB 'Mikroislemciler Dersi - 8086 Assembly', 0
menu_k     DB '[ KONTROLLER ]', 0
menu_k1    DB 'Ok Tuslari / WASD : Hareket', 0
menu_k2    DB 'SPACE : Ates Et', 0
menu_k3    DB 'ESC : Cikis', 0
menu_s     DB '[ SIMGELER ]', 0
menu_s1    DB '^ v < > Tank   * Hedef   # Engel   . Mermi', 0
menu_a     DB '[ AMAC ]', 0
menu_a1    DB '20 mermi ile 8 hedefi vur!', 0
menu_best  DB 'EN IYI SKOR: ', 0
menu_go    DB '>>> ENTER: Basla    ESC: Cikis <<<', 0

st_mermi   DB 'MERMI:', 0
st_skor    DB 'SKOR:', 0
st_best    DB 'EN IYI:', 0
st_hedef   DB 'HEDEF:', 0
st_help    DB 'Ok/WASD:Hareket  SPACE:Ates  ESC:Cikis', 0
game_title DB 'A S C I I   T A N K   O Y U N U', 0

go_win     DB 'TEBRIKLER! TUM HEDEFLER VURULDU!', 0
go_lose    DB 'MERMILER BITTI! OYUN BITTI!', 0
go_quit    DB 'OYUN SONLANDIRILDI', 0
go_newbest DB '>>> YENI REKOR! <<<', 0
go_fscore  DB 'SKORUN : ', 0
go_bscore  DB 'EN IYI : ', 0
go_prompt  DB '[ R ] Tekrar Oyna     [ Q / ESC ] Cikis', 0

score_file DB 'TANK.DAT', 0

row_offsets DW 0,160,320,480,640,800,960,1120,1280,1440
            DW 1600,1760,1920,2080,2240,2400,2560,2720,2880,3040
            DW 3200,3360,3520,3680,3840

main:
    ; DS = CS (COM formatinda otomatik, ama garanti icin)
    PUSH CS
    POP DS
    
    ; String islemleri icin yon bayragi
    CLD
    
    ; 80x25 text modu
    MOV AX, 0003h
    INT 10h
    
    ; Imleci gizle
    MOV AH, 01h
    MOV CH, 26h
    MOV CL, 07h
    INT 10h
    
    CALL load_best_score

mm_loop:
    CALL show_menu
    CALL wait_menu_input
    CMP AL, 27
    JE mm_exit
    CALL init_game
    CALL play_game
    CALL update_best_score
    CALL save_best_score
    CALL show_gameover
    CALL wait_gameover_input
    CMP AL, 'Q'
    JE mm_exit
    CMP AL, 'q'
    JE mm_exit
    CMP AL, 27
    JE mm_exit
    JMP mm_loop

mm_exit:
    ; Imleci geri getir
    MOV AH, 01h
    MOV CH, 06h
    MOV CL, 07h
    INT 10h
    
    ; Ekrani temizle
    MOV AX, 0003h
    INT 10h
    
    ; DOS'a don
    MOV AX, 4C00h
    INT 21h

; clear_screen - Ekrani temizler
clear_screen:
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV AH, 06h
    MOV AL, 00h
    MOV BH, ATTR_NORMAL
    MOV CX, 0000h
    MOV DX, 184Fh
    INT 10h
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET

put_char:
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DI
    PUSH ES
    
    MOV CH, AL          ; CH = karakter
    MOV CL, BL          ; CL = renk
    MOV AX, VIDEO_SEG
    MOV ES, AX
    
    ; Offset = row_offsets[satir] + sutun*2
    XOR BX, BX
    MOV BL, DH
    SHL BX, 1
    MOV DI, [row_offsets + BX]
    XOR BX, BX
    MOV BL, DL
    SHL BX, 1
    ADD DI, BX
    
    MOV AL, CH
    MOV AH, CL
    MOV ES:[DI], AX
    
    POP ES
    POP DI
    POP CX
    POP BX
    POP AX
    RET

draw_string:
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DI
    PUSH SI
    PUSH ES
    
    MOV AX, VIDEO_SEG
    MOV ES, AX
    
    ; Baslangic offset = row_offsets[satir] + sutun*2
    XOR BX, BX
    MOV BL, DH
    SHL BX, 1
    MOV DI, [row_offsets + BX]
    XOR BX, BX
    MOV BL, DL
    SHL BX, 1
    ADD DI, BX
    
    MOV AH, BL
ds_loop:
    LODSB
    TEST AL, AL
    JZ ds_done
    STOSW
    JMP ds_loop
ds_done:
    POP ES
    POP SI
    POP DI
    POP CX
    POP BX
    POP AX
    RET

draw_centered:
    PUSH AX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    
    MOV DI, SI
    XOR CX, CX
dc_len:
    CMP BYTE PTR [SI], 0
    JE dc_len_done
    INC CX
    INC SI
    JMP dc_len
dc_len_done:
    MOV SI, DI
    MOV AX, SCREEN_W
    SUB AX, CX
    SHR AX, 1
    MOV DL, AL
    CALL draw_string
    
    POP DI
    POP SI
    POP DX
    POP CX
    POP AX
    RET

draw_num3:
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV CX, DX
    
    ; Yuzler basamagi
    XOR DX, DX
    PUSH BX
    MOV BX, 100
    DIV BX
    POP BX
    
    PUSH DX
    MOV DX, CX
    ADD AL, '0'
    CALL put_char
    INC DL
    
    ; Onlar basamagi
    POP AX
    XOR AH, AH
    MOV CL, 10
    DIV CL
    PUSH AX
    ADD AL, '0'
    CALL put_char
    INC DL
    
    ; Birler basamagi
    POP AX
    MOV AL, AH
    ADD AL, '0'
    CALL put_char
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET

draw_num2:
    PUSH AX
    PUSH CX
    PUSH DX
    
    XOR AH, AH
    MOV CL, 10
    DIV CL
    PUSH AX
    ADD AL, '0'
    CALL put_char
    INC DL
    POP AX
    MOV AL, AH
    ADD AL, '0'
    CALL put_char
    
    POP DX
    POP CX
    POP AX
    RET

show_menu:
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    
    CALL clear_screen
    
    MOV BL, ATTR_TITLE
    MOV DH, 2
    MOV SI, OFFSET title_bar
    CALL draw_centered
    MOV DH, 3
    MOV SI, OFFSET title_txt
    CALL draw_centered
    MOV DH, 4
    MOV SI, OFFSET title_bar
    CALL draw_centered
    
    MOV BL, ATTR_MENU
    MOV DH, 6
    MOV SI, OFFSET menu_sub
    CALL draw_centered
    
    MOV BL, ATTR_STATUS
    MOV DH, 8
    MOV SI, OFFSET menu_k
    CALL draw_centered
    MOV BL, ATTR_NORMAL
    MOV DH, 9
    MOV SI, OFFSET menu_k1
    CALL draw_centered
    MOV DH, 10
    MOV SI, OFFSET menu_k2
    CALL draw_centered
    MOV DH, 11
    MOV SI, OFFSET menu_k3
    CALL draw_centered
    
    MOV BL, ATTR_STATUS
    MOV DH, 13
    MOV SI, OFFSET menu_s
    CALL draw_centered
    MOV BL, ATTR_NORMAL
    MOV DH, 14
    MOV SI, OFFSET menu_s1
    CALL draw_centered
    
    MOV BL, ATTR_STATUS
    MOV DH, 16
    MOV SI, OFFSET menu_a
    CALL draw_centered
    MOV BL, ATTR_NORMAL
    MOV DH, 17
    MOV SI, OFFSET menu_a1
    CALL draw_centered
    
    MOV BL, ATTR_NEWBEST
    MOV DH, 19
    MOV DL, 32
    MOV SI, OFFSET menu_best
    CALL draw_string
    MOV DL, 45
    MOV AX, [best_score]
    CALL draw_num3
    
    MOV BL, ATTR_PROMPT
    MOV DH, 22
    MOV SI, OFFSET menu_go
    CALL draw_centered
    
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET

; wait_menu_input - ENTER veya ESC bekler
wait_menu_input:
wmi_lp:
    MOV AH, 00h
    INT 16h
    CMP AL, 0Dh
    JE wmi_ok
    CMP AL, 27
    JE wmi_ok
    JMP wmi_lp
wmi_ok:
    RET

init_game:
    PUSH AX
    PUSH CX
    PUSH SI
    PUSH DI
    
    MOV BYTE PTR [player_x], 40
    MOV BYTE PTR [player_y], 12
    MOV BYTE PTR [player_dir], DIR_UP
    MOV BYTE PTR [bullets_left], MAX_BULLETS
    MOV WORD PTR [score], 0
    MOV BYTE PTR [targets_left], NUM_TARGETS
    MOV BYTE PTR [won], 0
    MOV BYTE PTR [new_bullet_slot], 0FFh
    MOV BYTE PTR [tick_counter], 0
    MOV BYTE PTR [active_bullets], 0
    
    ; Mermileri sifirla
    XOR AL, AL
    MOV CX, MAX_BULLETS
    MOV DI, OFFSET bullet_active
ig_clr:
    MOV [DI], AL
    INC DI
    LOOP ig_clr
    
    ; Hedefleri resetle
    MOV CX, NUM_TARGETS
    MOV SI, OFFSET target_init
    MOV DI, OFFSET target_active
ig_rst:
    MOV AL, [SI]
    MOV [DI], AL
    INC SI
    INC DI
    LOOP ig_rst
    
    POP DI
    POP SI
    POP CX
    POP AX
    RET

play_game:
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    CALL draw_game_initial
    
    ; Klavye tamponunu bosalt
pg_flush:
    MOV AH, 01h
    INT 16h
    JZ pg_flush_done
    MOV AH, 00h
    INT 16h
    JMP pg_flush
pg_flush_done:

pg_loop:
    MOV AH, 01h
    INT 16h
    JZ pg_tick
    
    MOV AH, 00h
    INT 16h
    CALL map_key
    
    CMP AL, 27
    JE pg_esc
    CMP AL, 5
    JE pg_fire
    CMP AL, 0
    JE pg_tick
    
    ; Hareket (AL = 1..4)
    PUSH AX
    MOV DH, [player_y]
    MOV DL, [player_x]
    MOV AL, ' '
    MOV BL, ATTR_NORMAL
    CALL put_char
    POP AX
    
    CALL do_move
    CALL draw_tank
    JMP pg_check

pg_fire:
    CALL do_fire
    CMP BYTE PTR [new_bullet_slot], 0FFh
    JE pg_fire_st
    XOR BX, BX
    MOV BL, [new_bullet_slot]
    CMP BYTE PTR [bullet_active + BX], 0
    JE pg_fire_st
    MOV DH, [bullet_y + BX]
    MOV DL, [bullet_x + BX]
    MOV AL, '.'
    MOV BL, ATTR_BULLET
    CALL put_char
pg_fire_st:
    CALL draw_status
    JMP pg_check

pg_esc:
    MOV BYTE PTR [won], 2
    JMP pg_end

pg_tick:
    CMP BYTE PTR [active_bullets], 0
    JE pg_loop
    
    CALL erase_all_bullets
    CALL update_bullets
    CALL draw_all_bullets
    CALL draw_status
    CALL draw_tank

pg_check:
    CMP BYTE PTR [targets_left], 0
    JNE pg_chk_lose
    MOV BYTE PTR [won], 1
    JMP pg_end

pg_chk_lose:
    CMP BYTE PTR [bullets_left], 0
    JNE pg_loop
    CALL count_active_bullets
    TEST AL, AL
    JNZ pg_loop
    MOV BYTE PTR [won], 0

pg_end:
    POP DX
    POP CX
    POP BX
    POP AX
    RET

map_key:
    CMP AL, 27
    JE mk_esc
    CMP AL, ' '
    JE mk_fire
    CMP AL, 'w'
    JE mk_up
    CMP AL, 'W'
    JE mk_up
    CMP AL, 's'
    JE mk_dn
    CMP AL, 'S'
    JE mk_dn
    CMP AL, 'a'
    JE mk_lf
    CMP AL, 'A'
    JE mk_lf
    CMP AL, 'd'
    JE mk_rt
    CMP AL, 'D'
    JE mk_rt
    CMP AL, 0
    JNE mk_none
    CMP AH, 48h
    JE mk_up
    CMP AH, 50h
    JE mk_dn
    CMP AH, 4Bh
    JE mk_lf
    CMP AH, 4Dh
    JE mk_rt
mk_none:
    MOV AL, 0
    RET
mk_up:
    MOV AL, 1
    RET
mk_dn:
    MOV AL, 2
    RET
mk_lf:
    MOV AL, 3
    RET
mk_rt:
    MOV AL, 4
    RET
mk_fire:
    MOV AL, 5
    RET
mk_esc:
    MOV AL, 27
    RET

; do_move - Tank hareketini isler
do_move:
    PUSH AX
    PUSH BX
    PUSH DX
    
    MOV BL, [player_x]
    MOV BH, [player_y]
    
    CMP AL, 1
    JNE dm_n1
    MOV BYTE PTR [player_dir], DIR_UP
    DEC BH
    JMP dm_chk
dm_n1:
    CMP AL, 2
    JNE dm_n2
    MOV BYTE PTR [player_dir], DIR_DOWN
    INC BH
    JMP dm_chk
dm_n2:
    CMP AL, 3
    JNE dm_n3
    MOV BYTE PTR [player_dir], DIR_LEFT
    DEC BL
    JMP dm_chk
dm_n3:
    MOV BYTE PTR [player_dir], DIR_RIGHT
    INC BL

dm_chk:
    CMP BL, FIELD_LEFT
    JB dm_done
    CMP BL, FIELD_RIGHT
    JA dm_done
    CMP BH, FIELD_TOP
    JB dm_done
    CMP BH, FIELD_BOTTOM
    JA dm_done
    
    MOV DL, BL
    MOV DH, BH
    CALL is_obstacle
    TEST AL, AL
    JNZ dm_done
    
    CALL is_target_here
    TEST AL, AL
    JNZ dm_done
    
    MOV [player_x], BL
    MOV [player_y], BH

dm_done:
    POP DX
    POP BX
    POP AX
    RET

; do_fire - Yeni mermi olusturur
do_fire:
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV BYTE PTR [new_bullet_slot], 0FFh
    CMP BYTE PTR [bullets_left], 0
    JE df_done
    
    XOR BX, BX
    MOV CX, MAX_BULLETS
df_find:
    CMP BYTE PTR [bullet_active + BX], 0
    JE df_found
    INC BX
    LOOP df_find
    JMP df_done

df_found:
    MOV BYTE PTR [bullet_active + BX], 1
    MOV [new_bullet_slot], BL
    
    MOV AL, [player_x]
    MOV [bullet_x + BX], AL
    MOV AL, [player_y]
    MOV [bullet_y + BX], AL
    
    MOV AL, [player_dir]
    CMP AL, DIR_UP
    JNE df_nu
    MOV BYTE PTR [bullet_dx + BX], 0
    MOV BYTE PTR [bullet_dy + BX], -1
    JMP df_adv
df_nu:
    CMP AL, DIR_DOWN
    JNE df_nd
    MOV BYTE PTR [bullet_dx + BX], 0
    MOV BYTE PTR [bullet_dy + BX], 1
    JMP df_adv
df_nd:
    CMP AL, DIR_LEFT
    JNE df_nl
    MOV BYTE PTR [bullet_dx + BX], -1
    MOV BYTE PTR [bullet_dy + BX], 0
    JMP df_adv
df_nl:
    MOV BYTE PTR [bullet_dx + BX], 1
    MOV BYTE PTR [bullet_dy + BX], 0

df_adv:
    MOV AL, [bullet_x + BX]
    ADD AL, [bullet_dx + BX]
    MOV [bullet_x + BX], AL
    MOV AL, [bullet_y + BX]
    ADD AL, [bullet_dy + BX]
    MOV [bullet_y + BX], AL
    
    MOV DL, [bullet_x + BX]
    MOV DH, [bullet_y + BX]
    CALL bullet_collide_check
    TEST AL, AL
    JZ df_alive
    MOV BYTE PTR [bullet_active + BX], 0
    JMP df_count
df_alive:
    INC BYTE PTR [active_bullets]
df_count:
    DEC BYTE PTR [bullets_left]

df_done:
    POP DX
    POP CX
    POP BX
    POP AX
    RET

erase_all_bullets:
    PUSH AX
    PUSH BX
    PUSH DX
    
    XOR BX, BX
eab_lp:
    CMP BX, MAX_BULLETS
    JAE eab_done
    CMP BYTE PTR [bullet_active + BX], 0
    JE eab_next
    MOV DH, [bullet_y + BX]
    MOV DL, [bullet_x + BX]
    PUSH BX
    MOV AL, ' '
    MOV BL, ATTR_NORMAL
    CALL put_char
    POP BX
eab_next:
    INC BX
    JMP eab_lp
eab_done:
    POP DX
    POP BX
    POP AX
    RET

update_bullets:
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    XOR BX, BX
ub_lp:
    CMP BX, MAX_BULLETS
    JAE ub_done
    CMP BYTE PTR [bullet_active + BX], 0
    JE ub_next
    
    MOV AL, [bullet_x + BX]
    ADD AL, [bullet_dx + BX]
    MOV DL, AL
    MOV AL, [bullet_y + BX]
    ADD AL, [bullet_dy + BX]
    MOV DH, AL
    
    MOV [bullet_x + BX], DL
    MOV [bullet_y + BX], DH
    
    CALL bullet_collide_check
    TEST AL, AL
    JZ ub_next
    MOV BYTE PTR [bullet_active + BX], 0
    DEC BYTE PTR [active_bullets]
ub_next:
    INC BX
    JMP ub_lp
ub_done:
    POP DX
    POP CX
    POP BX
    POP AX
    RET

draw_all_bullets:
    PUSH AX
    PUSH BX
    PUSH DX
    
    XOR BX, BX
dab_lp:
    CMP BX, MAX_BULLETS
    JAE dab_done
    CMP BYTE PTR [bullet_active + BX], 0
    JE dab_next
    MOV DH, [bullet_y + BX]
    MOV DL, [bullet_x + BX]
    PUSH BX
    MOV AL, '.'
    MOV BL, ATTR_BULLET
    CALL put_char
    POP BX
dab_next:
    INC BX
    JMP dab_lp
dab_done:
    POP DX
    POP BX
    POP AX
    RET

bullet_collide_check:
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    
    CMP DL, FIELD_LEFT
    JB bc_hit
    CMP DL, FIELD_RIGHT
    JA bc_hit
    CMP DH, FIELD_TOP
    JB bc_hit
    CMP DH, FIELD_BOTTOM
    JA bc_hit
    
    CALL is_obstacle
    TEST AL, AL
    JNZ bc_hit
    
    CALL which_target
    TEST AL, AL
    JZ bc_miss
    
    DEC AL
    MOV BL, AL
    XOR BH, BH
    MOV BYTE PTR [target_active + BX], 0
    
    PUSH BX
    PUSH DX
    MOV DH, [target_y + BX]
    MOV DL, [target_x + BX]
    MOV AL, ' '
    MOV BL, ATTR_NORMAL
    CALL put_char
    POP DX
    POP BX
    
    DEC BYTE PTR [targets_left]
    ADD WORD PTR [score], 10
    JMP bc_hit

bc_miss:
    MOV AL, 0
    JMP bc_done
bc_hit:
    MOV AL, 1
bc_done:
    POP SI
    POP DX
    POP CX
    POP BX
    RET

is_obstacle:
    PUSH BX
    PUSH SI
    
    MOV SI, OFFSET obstacle_data
io_lp:
    MOV AL, [SI]
    CMP AL, 0FFh
    JE io_no
    CMP AL, DL
    JNE io_skip
    MOV AL, [SI + 1]
    CMP AL, DH
    JNE io_skip
    MOV AL, 1
    JMP io_end
io_skip:
    ADD SI, 2
    JMP io_lp
io_no:
    MOV AL, 0
io_end:
    POP SI
    POP BX
    RET

which_target:
    PUSH BX
    PUSH CX
    
    XOR BX, BX
    MOV CX, NUM_TARGETS
wt_lp:
    CMP BYTE PTR [target_active + BX], 0
    JE wt_next
    MOV AL, [target_x + BX]
    CMP AL, DL
    JNE wt_next
    MOV AL, [target_y + BX]
    CMP AL, DH
    JNE wt_next
    MOV AL, BL
    INC AL
    JMP wt_end
wt_next:
    INC BX
    LOOP wt_lp
    XOR AL, AL
wt_end:
    POP CX
    POP BX
    RET

is_target_here:
    CALL which_target
    TEST AL, AL
    JZ ith_z
    MOV AL, 1
ith_z:
    RET

count_active_bullets:
    PUSH BX
    PUSH CX
    
    XOR AL, AL
    MOV CX, MAX_BULLETS
    XOR BX, BX
cab_lp:
    CMP BYTE PTR [bullet_active + BX], 0
    JE cab_sk
    INC AL
cab_sk:
    INC BX
    LOOP cab_lp
    
    POP CX
    POP BX
    RET

draw_game_initial:
    PUSH AX
    PUSH BX
    PUSH DX
    PUSH SI
    
    CALL clear_screen
    
    MOV BL, ATTR_TITLE
    MOV DH, 0
    MOV SI, OFFSET game_title
    CALL draw_centered
    
    CALL draw_status_labels
    CALL draw_status
    CALL draw_border
    CALL draw_obstacles
    CALL draw_targets
    CALL draw_tank
    
    MOV BL, ATTR_MENU
    MOV DH, 24
    MOV SI, OFFSET st_help
    CALL draw_centered
    
    POP SI
    POP DX
    POP BX
    POP AX
    RET

draw_border:
    PUSH AX
    PUSH CX
    PUSH DI
    PUSH ES
    
    MOV AX, VIDEO_SEG
    MOV ES, AX
    MOV AH, ATTR_BORDER
    
    ; Ust kenar (satir 2)
    MOV DI, 320
    MOV AL, '+'
    STOSW
    MOV AL, '-'
    MOV CX, 78
    REP STOSW
    MOV AL, '+'
    STOSW
    
    ; Alt kenar (satir 23)
    MOV DI, 3680
    MOV AL, '+'
    STOSW
    MOV AL, '-'
    MOV CX, 78
    REP STOSW
    MOV AL, '+'
    STOSW
    
    ; Yan kenarlar
    MOV AL, '|'
    MOV DI, 480
    MOV CX, 20
db_side:
    MOV ES:[DI], AX
    MOV ES:[DI + 158], AX
    ADD DI, 160
    LOOP db_side
    
    POP ES
    POP DI
    POP CX
    POP AX
    RET

draw_obstacles:
    PUSH AX
    PUSH BX
    PUSH DX
    PUSH SI
    
    MOV BL, ATTR_OBSTACLE
    MOV SI, OFFSET obstacle_data
do_lp:
    MOV AL, [SI]
    CMP AL, 0FFh
    JE do_end
    MOV DL, AL
    MOV DH, [SI + 1]
    MOV AL, '#'
    CALL put_char
    ADD SI, 2
    JMP do_lp
do_end:
    POP SI
    POP DX
    POP BX
    POP AX
    RET

draw_targets:
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV CX, NUM_TARGETS
    XOR BX, BX
dt_lp:
    CMP BYTE PTR [target_active + BX], 0
    JE dt_sk
    MOV DH, [target_y + BX]
    MOV DL, [target_x + BX]
    PUSH BX
    MOV AL, '*'
    MOV BL, ATTR_TARGET
    CALL put_char
    POP BX
dt_sk:
    INC BX
    LOOP dt_lp
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET

draw_tank:
    PUSH AX
    PUSH BX
    PUSH DX
    
    MOV DL, [player_x]
    MOV DH, [player_y]
    MOV AL, [player_dir]
    
    CMP AL, DIR_UP
    JNE dtn_u
    MOV AL, '^'
    JMP dtn_go
dtn_u:
    CMP AL, DIR_DOWN
    JNE dtn_d
    MOV AL, 'v'
    JMP dtn_go
dtn_d:
    CMP AL, DIR_LEFT
    JNE dtn_l
    MOV AL, '<'
    JMP dtn_go
dtn_l:
    MOV AL, '>'
dtn_go:
    MOV BL, ATTR_TANK
    CALL put_char
    
    POP DX
    POP BX
    POP AX
    RET

draw_status_labels:
    PUSH AX
    PUSH BX
    PUSH DX
    PUSH SI
    
    MOV BL, ATTR_STATUS
    MOV DH, 1
    
    MOV DL, 1
    MOV SI, OFFSET st_mermi
    CALL draw_string
    
    MOV DL, 12
    MOV SI, OFFSET st_skor
    CALL draw_string
    
    MOV DL, 23
    MOV SI, OFFSET st_best
    CALL draw_string
    
    MOV DL, 36
    MOV SI, OFFSET st_hedef
    CALL draw_string
    
    POP SI
    POP DX
    POP BX
    POP AX
    RET

draw_status:
    PUSH AX
    PUSH BX
    PUSH DX
    
    MOV BL, ATTR_STATUS
    MOV DH, 1
    
    MOV DL, 7
    XOR AH, AH
    MOV AL, [bullets_left]
    CALL draw_num2
    
    MOV DL, 17
    MOV AX, [score]
    CALL draw_num3
    
    MOV DL, 30
    MOV AX, [best_score]
    CALL draw_num3
    
    MOV DL, 42
    XOR AH, AH
    MOV AL, [targets_left]
    CALL draw_num2
    
    POP DX
    POP BX
    POP AX
    RET

show_gameover:
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    
    CALL clear_screen
    
    MOV BL, ATTR_TITLE
    MOV DH, 3
    MOV SI, OFFSET title_bar
    CALL draw_centered
    MOV DH, 4
    MOV SI, OFFSET title_txt
    CALL draw_centered
    MOV DH, 5
    MOV SI, OFFSET title_bar
    CALL draw_centered
    
    MOV DH, 9
    MOV AL, [won]
    CMP AL, 1
    JE sg_win
    CMP AL, 2
    JE sg_quit
    MOV BL, ATTR_LOSE
    MOV SI, OFFSET go_lose
    JMP sg_msg
sg_win:
    MOV BL, ATTR_WIN
    MOV SI, OFFSET go_win
    JMP sg_msg
sg_quit:
    MOV BL, ATTR_MENU
    MOV SI, OFFSET go_quit
sg_msg:
    CALL draw_centered
    
    MOV AX, [score]
    CMP AX, [best_score]
    JBE sg_no_rec
    MOV BL, ATTR_NEWBEST
    MOV DH, 11
    MOV SI, OFFSET go_newbest
    CALL draw_centered
sg_no_rec:
    
    MOV BL, ATTR_MENU
    MOV DH, 13
    MOV DL, 34
    MOV SI, OFFSET go_fscore
    CALL draw_string
    MOV DL, 43
    MOV AX, [score]
    CALL draw_num3
    
    MOV BL, ATTR_NEWBEST
    MOV DH, 14
    MOV DL, 34
    MOV SI, OFFSET go_bscore
    CALL draw_string
    MOV DL, 43
    MOV AX, [best_score]
    CALL draw_num3
    
    MOV BL, ATTR_PROMPT
    MOV DH, 18
    MOV SI, OFFSET go_prompt
    CALL draw_centered
    
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET

wait_gameover_input:
wgo_lp:
    MOV AH, 00h
    INT 16h
    CMP AL, 'R'
    JE wgo_ok
    CMP AL, 'r'
    JE wgo_ok
    CMP AL, 'Q'
    JE wgo_ok
    CMP AL, 'q'
    JE wgo_ok
    CMP AL, 27
    JE wgo_ok
    JMP wgo_lp
wgo_ok:
    RET

; ============================================================================
; SKOR KAYIT (DOS INT 21h)
; ============================================================================

update_best_score:
    PUSH AX
    MOV AX, [score]
    CMP AX, [best_score]
    JBE ubs_sk
    MOV [best_score], AX
ubs_sk:
    POP AX
    RET

load_best_score:
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV AH, 3Dh
    MOV AL, 0
    MOV DX, OFFSET score_file
    INT 21h
    JC lbs_none
    
    MOV BX, AX
    MOV AH, 3Fh
    MOV CX, 2
    MOV DX, OFFSET best_score
    INT 21h
    
    MOV AH, 3Eh
    INT 21h
    JMP lbs_end
    
lbs_none:
    MOV WORD PTR [best_score], 0
lbs_end:
    POP DX
    POP CX
    POP BX
    POP AX
    RET

save_best_score:
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV AH, 3Ch
    XOR CX, CX
    MOV DX, OFFSET score_file
    INT 21h
    JC sbs_end
    
    MOV BX, AX
    MOV AH, 40h
    MOV CX, 2
    MOV DX, OFFSET best_score
    INT 21h
    
    MOV AH, 3Eh
    INT 21h
    
sbs_end:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
