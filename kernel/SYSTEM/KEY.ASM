

current_keymap		dd	DEFAULT_KEYMAP


; Delivers a char or VK code to the current foreground thread, if
; it's waiting for text input.
;   EAX - VK code
;   EBX - modifier state (bit 0 is shift, bit 1 is control, bit 2 is alt, bit 3)
function DeliverKey, 0
		
		
		ret


; Converts VKs to chars.
DEFAULT_KEYMAP:
		dw	'\'






