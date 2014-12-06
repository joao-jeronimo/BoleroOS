;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;!                                                         !
;!  BoleroOS                                               !
;!  By Joao Jeronimo - j_j_b_o_j@yahoo.com.br              !
;!                                                         !
;!  BoleroOS comes with NO WARANTY. Use at your own risk.  !
;!  In case of problem caused by Bolero, you can           !
;!  you can always contact Jeronimo for help, but no       !
;!  solution or assistance is warrantied.                  !
;!                                                         !
;!      Purpose: Idle Task (i.e. the very first process)   !
;!      History: 23/06/2008 - Preliminary dumb one         !
;!                                                         !
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


; Basic algorithm:
;  - Execute first useful program
;  - Yield Time slice to task switcher
;  (now, control only returns to Idle if nothing is to be done)
;  - Flush caches/buffers/etc
;  - Increment Idle counter (used by
;    kernel to compute CPU usage)
; 
; NOTE: none of these stages are already implemented,
;       for the task manager doesn't alread exist...
;       Also, IdleOne will eventually run in kernel mode
;       (only process behaving like this)
;
IDLE_TASK:
		
		
		jmp $





