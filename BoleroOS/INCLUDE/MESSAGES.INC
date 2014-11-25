
KERNEL_MESSAGES:
	.init_paging				db "Paging enabled.", 0
	.init_pageframe_allocator	db "Page frame allocator initialized.", 0
	.init_tss					db "TSS configured.", 0
	.cpu_init_done				db "CPU initialization is done. Now initializing kernel proper.", 0
	
	

	; Temporary warnings (will be replaced by exceptions or removed at all)...
	.no_memory_left				db	"FATAL: memory exausted.", 0
	.page_already_present		db	"FATAL: a request was made to map something at a "
								db	"virtual address whose page is already present.", 0
	.no_space_for_heap			db	"FATAL: no space to expand heap.", 0
	.pid_carry_out				db	"FATAL: PID counter carried out", 0
	
	.event_delivery_bug			db	"FATAL: there must be a bug somewhere in the "
								db	"event-delivering code, cause a thread was awaken "
								db	"with no event having been delivered.", 0
	
	.runtime_error				db	"A process requested something weird.", 0
	.double_fault				db	"Double Fault occured.", 0
	.gen_prot_fault				db	"General Protection Fault occured.", 0
	.page_fault					db	"Page Fault occured.", 0








