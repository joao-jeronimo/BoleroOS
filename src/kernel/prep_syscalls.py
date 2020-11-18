#! /usr/bin/python

import sys


MODE = sys.argv[1]
INPUT = sys.argv[2]
OUTPUT = sys.argv[3]



inputfile = open(INPUT, "r")
outputfile = open(OUTPUT, "w")



if   MODE == "GEN_TRAMP":
 outputfile.write("SYSTEM_TRAMPOLINE:\n")
 
 for thisline in inputfile.readlines():
  properline = thisline.lstrip().rstrip()

  if properline == "" or properline[0] == "#":
   continue

  if properline.rfind(" ") != -1:
   print "ERROR! System call names must not have spaces.\n"
   outputfile.write("display \"ERROR: Inconsistent system call table.\"\nHALT\n")
   break

  outputfile.write("\tdd\t%s\n"%(properline,))
 
 outputfile.write("\n")
elif MODE == "GEN_HEADER":
 outputfile.write("; Auto generated wrappers for calling system calls.\n\n")
 
 function_counter = 0

 for thisline in inputfile.readlines():
  properline = thisline.lstrip().rstrip()
  
  if properline == "" or properline[0] == "#":
   continue

  if properline.rfind(" ") != -1:
   print "ERROR! System call names must not have spaces.\n"
   outputfile.write("display \"ERROR: Inconsistent system call table.\"\nHALT\n")
   break

  outputfile.write(
    "function %(fname)s, EBP_REG\n"
	"\tmov\t\tebp, %(fnumber)d\n"
	"\tint\t\t48\n"
	"ret\n\n"
	% { "fname":properline, "fnumber":function_counter }
  )

  function_counter += 1

else:
 print "ERROR! Invalid mode"



inputfile.close()
outputfile.close()



