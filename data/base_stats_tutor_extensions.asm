; FORM-5.27.00: sparse stock Move Tutor compatibility for Tutor 17-32.
;
; Compact stock BaseStats keep Tutor 1-16 inline. Current stock data use no
; Tutor 17-32 flags, so storing two zero bytes in all 208 records is wasteful.
; Future high Tutor compatibility remains independently expressible here:
;
;   db PIKACHU
;   m_tutor 17,20,24 ; Tutor 17-24
;   m_tutor 25,32    ; Tutor 25-32
;
; A species absent from this table receives zero for both high Tutor bytes.

BaseStatsTutorHighCompat::
	db 0 ; terminator: species id 0 is never valid
