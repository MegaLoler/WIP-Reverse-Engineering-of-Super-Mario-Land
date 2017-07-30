; vram locations
.define chr0 $8000
.define chr1 $8800
.define chr2 $9000
.define map0 $9800
.define map1 $9c00

; wram locations
.define oam_mirror $c000
.define character_entity_table $c200
.define entity_table $d100
.define level_state $da00
.define music_table $df00

.define mario_sprite_0 $c00c
.define score $c0a0
.define request_life_change $c0a3
.define state $c0a4 ; ?????????
.define column $c0b0
.define top_score $c0c0
.define demo_counter $c0d7
.define death_y $c0dd
.define credits $c0de
.define credits_scroll $c0df

.define time_remaining_divider $da00
.define time_remaining $da01 ; word
.define timers1 $da03 ; 4 timer bytes
.define timers2 $da07 ; 4 timer bytes
.define timer_index $da0b
.define timers3 $da0c ; 4 timer bytes
.define timers4 $da10 ; 4 timer bytes
.define lives $da15

.define play_sfx $dfe0

; hram locations

.define r_pad $80
.define r_pending_pad $81
.define r_engine_loop_request $85
.define r_playing $9f ; in title screen/demo or in game?
.define r_entity_copy $86
.define r_vulnerability $99
.define r_scroll $a4
.define r_countdown1 $a6
.define r_countdown2 $a7
.define r_countup $ac
.define r_update_score $b1
.define r_paused $b2
.define r_state $b3
.define r_world $b4
.define r_fire $b5
.define r_routine $b6
.define r_request_sfx $d3
.define r_music_divider $d5
.define r_music_measure $d7
.define r_music_odd_panning $d9 
.define r_music_even_panning $da
.define r_pause_unpause_request $df
.define r_previous_bank $e1
.define r_level $e4
.define r_map_page $e5
.define r_level_scroll $e6
.define r_map_load_dest $e9
.define r_block_update_request $ee
.define r_block_address_high $ef
.define r_block_address_low $f0
.define r_coins $fa
.define r_current_bank $fd
.define r_get_coin_request $fe
