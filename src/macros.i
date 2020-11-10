basicup .macro
    *=$0801
; .word:    Include 16bit unsigned
; word constants
; the following includes the address
; of label ss and the string 2010
; representing a BASIC line number
	.word ss, 2010
; $9e represents the SYS command
	.byte $9e
; .null adds null ($00) at the end
; as and end of BASIC line marker
	.null " 4096"
ss
	.word 0 ; BASIC end marker
; actual program starts from $1000
; (SYS 4096)

	*= $1000
.endm