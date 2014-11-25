; Auto generated wrappers for calling system calls.

function GetDisplay, EBP_REG
	mov		ebp, 0
	int		48
ret

function UpDisplay, EBP_REG
	mov		ebp, 1
	int		48
ret

function ConfigEvents, EBP_REG
	mov		ebp, 2
	int		48
ret

function WaitForEvent, EBP_REG
	mov		ebp, 3
	int		48
ret

function GetKey, EBP_REG
	mov		ebp, 4
	int		48
ret

