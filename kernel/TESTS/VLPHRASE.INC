; VLPHRASE = very long phrase


		mov		eax, (0x07 shl 8) or 'J'
		callfun	PrintChar, EAX_REG
		callfun	PrintChar, EAX_REG
		callfun	PrintChar, EAX_REG
		callfun	PrintChar, EAX_REG
		callfun	PrintChar, EAX_REG
		callfun	PrintChar, EAX_REG
		callfun	PrintChar, EAX_REG
		callfun	PrintChar, EAX_REG
		callfun	PrintChar, EAX_REG
		
		mov		eax, (0x07 shl 8)
		mov		esi, VLPHRASE
		callfun	PrintString, 0
		mov		eax, (0x07 shl 8)
		mov		esi, ANOTHER_VLP
		callfun	PrintString, 0



VLPHRASE db LF, "The little brown fow jumps over the lazy dog!", LF , "The inherent ambiguity of many control characters, combined with their historical usage, created problems when transferring plain text files between systems.", LF, "The clearest example of this is the newline problem on various operating systems. On printing terminals there is no question that you terminate a line of text with both Carriage Return and Linefeed.", LF, "The first returns the printing carriage to the beginning of the line and the second advances to the next line without moving the carriage.", LF, LF, 0
ANOTHER_VLP db "The participation of Puerto Ricans in World War II as members of the United States armed forces included guarding U.S. military installations in the Caribbean and active combat participation in both the European and Pacific theatres of the war.", LF, LF, "Puerto Ricans had obtained U.S. citizenship as a result of the 1917 Jones-Shafroth Act and were expected to serve in the military. During World War II, more than 53,000 Puerto Ricans served in the U.S. military. Soldiers from the island, served in either the 65th Infantry Regiment or the Puerto Rican National Guard.", LF, LF, LF, LF, LF, LF, "One last line before scrolling...", LF, LF, LF, LF, "Those who resided in the mainland of the United States were assigned to regular units of the military. They were often subject to the racial discrimination that was widespread in the United States at the time. Puerto Rican women who served had their options restricted to nursing or administrative positions. In World War II some of the island`s men played active roles as commanders in the military. The military did not keep statistics in regard to the total number of Hispanics who served in the regular units of the Armed Forces, only of those who served in Puerto Rican units, therefore, it is impossible to determine the exact number of Puerto Ricans who served in World War II.", 0


