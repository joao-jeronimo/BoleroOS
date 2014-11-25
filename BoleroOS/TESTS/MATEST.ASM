; Runs in kernel mode


buffer: times 10 db ?


memory_allocation_test:
		
		mov		ecx, 90
		callfun	PoolAlloc, 0
		
		mov		eax, edi
		mov		ebp, buffer
		callfun	WriteHex, EDI_REG
		callfun	klog, EDI_REG
		
		mov		ecx, 8*90
		cld
		clear	eax
		rep		stosb
		
		
		mov		ecx, 290
		callfun	PoolAlloc, 0
		
		mov		eax, edi
		mov		ebp, buffer
		callfun	WriteHex, EDI_REG
		callfun	klog, EDI_REG
		
		mov		ecx, 8*290
		cld
		clear	eax
		rep		stosb
		
		
		mov		ecx, 2046
		callfun	PoolAlloc, 0
		
		mov		eax, edi
		mov		ebp, buffer
		callfun	WriteHex, EDI_REG
		callfun	klog, EDI_REG
		
		mov		ecx, 8*2046
		cld
		clear	eax
		rep		stosb
		
		
		mov		ecx, 2046543
		callfun	PoolAlloc, 0
		
		mov		eax, edi
		mov		ebp, buffer
		callfun	WriteHex, EDI_REG
		callfun	klog, EDI_REG
		
		mov		ecx, 8*2046543
		cld
		clear	eax
		rep		stosb
		
		
		mov		ecx, 3
		callfun	PoolAlloc, 0
		
		mov		eax, edi
		mov		ebp, buffer
		callfun	WriteHex, EDI_REG
		callfun	klog, EDI_REG
		
		mov		ecx, 8*3
		cld
		clear	eax
		rep		stosb
		
		jmp		$


