; Description: Becoming more familiar with system services and 
;               processing images
; ***********************************************************************
;  Data declarations
;	Note, the error message strings should NOT be changed.
;	All other variables may changed or ignored...

; ***********************************************************************
;  Data declarations
;	Note, the error message strings should NOT be changed.
;	All other variables may changed or ignored...

section	.data

; -----
;  Define standard constants.

LF		equ	10			; line feed
NULL		equ	0			; end of string
SPACE		equ	0x20			; space

TRUE		equ	1
FALSE		equ	0

SUCCESS		equ	0			; Successful operation
NOSUCCESS	equ	1			; Unsuccessful operation

STDIN		equ	0			; standard input
STDOUT		equ	1			; standard output
STDERR		equ	2			; standard error

SYS_read	equ	0			; system call code for read
SYS_write	equ	1			; system call code for write
SYS_open	equ	2			; system call code for file open
SYS_close	equ	3			; system call code for file close
SYS_fork	equ	57			; system call code for fork
SYS_exit	equ	60			; system call code for terminate
SYS_creat	equ	85			; system call code for file open/create
SYS_time	equ	201			; system call code for get time

O_CREAT		equ	0x40
O_TRUNC		equ	0x200
O_APPEND	equ	0x400

O_RDONLY	equ	000000q			; file permission - read only
O_WRONLY	equ	000001q			; file permission - write only
O_RDWR		equ	000002q			; file permission - read and write

S_IRUSR		equ	00400q
S_IWUSR		equ	00200q
S_IXUSR		equ	00100q

; -----
;  Define program specific constants.

GRAYSCALE	equ	0
BRIGHTEN	equ	1
DARKEN		equ	2

MIN_FILE_LEN	equ	5
BUFF_SIZE	equ	1000000			; buffer size

; -----
;  Local variables for getArguments() function.

eof		db	FALSE

usageMsg	db	"Usage: ./imageCvt <-gr|-br|-dk> <inputFile.bmp> "
		db	"<outputFile.bmp>", LF, NULL
errIncomplete	db	"Error, incomplete command line arguments.", LF, NULL
errExtra	db	"Error, too many command line arguments.", LF, NULL
errOption	db	"Error, invalid image processing option.", LF, NULL
errReadName	db	"Error, invalid source file name.  Must be '.bmp' file.", LF, NULL
errWriteName	db	"Error, invalid output file name.  Must be '.bmp' file.", LF, NULL
errReadFile	db	"Error, unable to open input file.", LF, NULL
errWriteFile	db	"Error, unable to open output file.", LF, NULL

inFileName   dq 0            ; input filename
outFileName  dq 0            ; output filename
; -----
;  Local variables for processHeaders() function.

HEADER_SIZE	equ	54

errReadHdr	db	"Error, unable to read header from source image file."
		db	LF, NULL
errFileType	db	"Error, invalid file signature.", LF, NULL
errDepth	db	"Error, unsupported color depth.  Must be 24-bit color."
		db	LF, NULL
errCompType	db	"Error, only non-compressed images are supported."
		db	LF, NULL
errSize		db	"Error, bitmap block size inconsistent.", LF, NULL
errWriteHdr	db	"Error, unable to write header to output image file.", LF,
		db	"Program terminated.", LF, NULL

signature dw 0
fileSize dd 0
skip dd 0
headerSize dd 0
skip2 dd 0
width dd 0
height dd 0
skip3 dw 0
depth dw 0
compression dd 0
pixData dd 0
misc dq 0
misc2 dq 0

; -----
;  Local variables for getRow() function.

buffMax		dq	BUFF_SIZE
curr		dq	BUFF_SIZE
wasEOF		db	FALSE
pixelCount	dq	0

errRead		db	"Error, reading from source image file.", LF,
		db	"Program terminated.", LF, NULL

; -----
;  Local variables for writeRow() function.

errWrite	db	"Error, writting to output image file.", LF,
		db	"Program terminated.", LF, NULL


; ------------------------------------------------------------------------
;  Unitialized data

section	.bss

localBuffer	resb	BUFF_SIZE
header		resb	HEADER_SIZE


; ############################################################################

section	.text

; ***************************************************************
;  Routine to get arguments.
;	Check image conversion options
;	Verify files by atemptting to open the files (to make
;	sure they are valid and available).

;  NOTE:
;	ENUM vaiables are 32-bits.

;  Command Line format:
;	./imageCvt <-gr|-br|-dk> <inputFileName> <outputFileName>

; -----
;  Arguments:
;	rdi - argc (value) 
;	rsi - argv table (address)
;	rdx - image option variable, ENUM type, (address) 
;	rcx - read file descriptor (address) 
;	r8 - write file descriptor (address) 
;  Returns:
;	TRUE or FALSE


;	YOUR CODE GOES HERE
global getArguments
getArguments:

;----------------------------------------------------	
;Pushes
;----------------------------------------------------
	push rbx
	push r12
	push r13
	push r14
	push r15

; all addresses
; r12 = rsi = argv(addr)
	mov r12, rsi
; r13 = rdx = image option variable 
	mov r13, rdx 
; r14 = rcx = read file desc
	mov r14, rcx
; r15 = r8 = write file decriptor
	mov r15, r8
;----------------------------------------------------
; ERROR CHECKING BEGIN
;----------------------------------------------------	
;check usageMsg (one arg entered)
;----------------------------------------------------
	;need cmp argc value to 1
	cmp rdi , 1
	je usageMsg1
;----------------------------------------------------	
;check errIncomplete 2-3 args
;----------------------------------------------------
	;need cmp argc value to 1
	cmp rdi, 2
	je errIncomplete1
	cmp rdi, 3
	je errIncomplete1
;----------------------------------------------------
;check errExtra; too many comman line args > 4
;----------------------------------------------------
	;need to cmp argc value to 11
	cmp rdi, 4
	ja errExtra1
	
;----------------------------------------------------
;check errOption if not -gr -bk -dk
;----------------------------------------------------
	; How to check argv[1] = 
	mov rbx, qword[rsi + 8]
; check "-"
	mov al, byte[rbx]
	cmp al, "-"
	jne errOption1
; check second chr
	; is=g?
	mov al, byte[rbx + 1] 
	cmp al, "g"
	je thirdChr
	;is=b?
	mov al, byte[rbx + 1] 
	cmp al, "b"
	je thirdChr
	;is=d?
	mov al, byte[rbx + 1] 
	cmp al, "d"
	je thirdChr

	jmp errOption1
thirdChr:
	;is = r
	mov al, byte[rbx + 2] 
	cmp al, "r"
	je fourthChr
	;is = k
	mov al, byte[rbx + 2] 
	cmp al, "k"
	je fourthChr

	jmp errOption1
fourthChr:
	; check null
	mov al, byte[rbx + 3]
	cmp al, NULL
	jne errOption1
; is good (need to send value to r13)
	mov rbx, qword[rsi + 8]
	mov al, byte [rbx + 1]
	cmp al, "g"
	je setGr

	cmp al , "b"
	je setBk

	cmp al , "d"
	je setDk
setGr:
	mov rbx, 0
	mov rbx, GRAYSCALE
	mov qword[r13], rbx
	jmp errOptionDone
setBk:
	mov rbx, 0
	mov rbx, BRIGHTEN
	mov qword[r13], rbx
	jmp errOptionDone
setDk:
	mov rbx, 0
	mov rbx, DARKEN
	mov qword[r13], rbx

errOptionDone:
;----------------------------------------------------
; ErrReadName (ending in .bmp)
;----------------------------------------------------
	;clear rbx
	mov rbx, 0
	;set rbx = qword[r12+16] ; rbx now equal to entered file
	mov rbx, qword[r12 + 16]
	;need to find size of the argument
	mov rax, 0; temp
	mov rcx, 0; i
findlength:
	    ;iterate until null is found incrementing each time
		;start from [0]
		mov al,byte[rbx + rcx]
		;cmp to null
		cmp al, NULL
		je lengthFound
		;inc i 
		inc rcx
		;if !null, start again 
		jmp findlength
		
; check last four chars (len in rcx)
lengthFound: 
	;dec i to account for null
		dec rcx
		;check rbx + len for 'p'
		mov al, byte[rbx + rcx ] 
		cmp al, "p"
		jne errReadName1
		dec rcx
		;check rbx + len -1 for 'm'
		mov al, byte[rbx + rcx ] 
		cmp al, "m"
		jne errReadName1
		dec rcx
		;check rbx + len -2 for 'b'
		mov al, byte[rbx + rcx] 
		cmp al, "b"
		jne errReadName1
		dec rcx
		;check rbx + len -3 for '.'
		mov al, byte[rbx + rcx ] 
		cmp al, "."
		jne errReadName1
;is good
;----------------------------------------------------
; ErrWriteName
;----------------------------------------------------
	;clear rbx
	mov rbx, 0
	;set rbx = qword[r12+16] ; rbx now equal to entered file
	mov rbx, qword[r12 + 24]
	;need to find size of the argument
	mov rax, 0; temp
	mov rcx, 0; i
findlength1:
	    ;iterate until null is found incrementing each time
		;start from [0]
		mov al,byte[rbx + rcx]
		;cmp to null
		cmp al, NULL
		je lengthFound1
		;inc i ; this way the null isnt included in len
		inc rcx
		;if !null, start again 
		jmp findlength1
		
; check last four chars (len in rcx)
lengthFound1: 
	;dec i to account for null
		dec rcx
		;check rbx + len for 'p'
		mov al, byte[rbx + rcx ] 
		cmp al, "p"
		jne errWriteName1
		dec rcx
		;check rbx + len -1 for 'm'
		mov al, byte[rbx + rcx ] 
		cmp al, "m"
		jne errWriteName1
		dec rcx
		;check rbx + len -2 for 'b'
		mov al, byte[rbx + rcx] 
		cmp al, "b"
		jne errWriteName1
		dec rcx
		;check rbx + len -3 for '.'
		mov al, byte[rbx + rcx ] 
		cmp al, "."
		jne errWriteName1
;is good

;----------------------------------------------------
; errReadFile
;----------------------------------------------------
	mov rax, qword [r12 + 16]  
    mov qword [inFileName], rax
	;desc = fOpen(inFileName, AccMode)
    mov rax, SYS_open
    mov rdi, qword[inFileName]
    mov rsi, O_RDONLY
    syscall
    cmp rax, 0
    jl errReadFile1
    mov qword[r14], rax
;----------------------------------------------------
; errWriteFile
;----------------------------------------------------	
	mov rax, qword [r12 + 24] 
    mov qword [outFileName], rax
;desc = fOpen/Create(outFileName, Accmode);
    mov rax, SYS_creat
    mov rdi, qword[outFileName]
    mov rsi, S_IRUSR | S_IWUSR
    syscall
    cmp rax, 0
    jl errWriteFile1
    mov qword[r15], rax

	jmp endGetArguments
;----------------------------------------------------
; Error Handling
;----------------------------------------------------
usageMsg1:
	mov rdi, usageMsg
	jmp printIt
errIncomplete1:	
	mov rdi, errIncomplete
	jmp printIt
errExtra1:
	mov rdi, errExtra
	jmp printIt
errOption1:
	mov rdi, errOption
	jmp printIt
errReadName1:
	mov rdi, errReadName
	jmp printIt
errWriteName1:
	mov rdi, errWriteName
	jmp printIt	
errReadFile1:
	mov rdi, errReadFile
	jmp printIt
errWriteFile1:
	mov rdi, errWriteFile
	jmp printIt

printIt:
	call printString
;----------------------------------------------------
; Error Pops
;----------------------------------------------------
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbx 

	mov rax, 0
	mov rax, FALSE
	ret
endGetArguments:
;----------------------------------------------------
; isGood Pops
;----------------------------------------------------
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbx 

	mov rax, 0
	mov rax, TRUE
	ret


; ***************************************************************
;  Read and verify header information
;	status = processHeaders(readFileDesc, writeFileDesc,
;				fileSize, picWidth, picHeight)

; -----
;  2 -> BM				(+0)
;  4 file size				(+2)
;  4 skip				(+6)
;  4 header size			(+10)
;  4 skip				(+14)
;  4 width				(+18)
;  4 height				(+22)
;  2 skip				(+26)
;  2 depth (16/24/32)			(+28)
;  4 compression method code		(+30)
;  4 bytes of pixel data		(+34)
;  skip remaing header entries

; -----
;   Arguments:
;	rdi- read file descriptor (value)
;	rsi - write file descriptor (value)
;	rdx - file size (address)
;	rcx - image width (address)
;	r8 -image height (address)

;  Returns:
;	file size (via reference)
;	image width (via reference)
;	image height (via reference)
;	TRUE or FALSE


;	YOUR CODE GOES HERE
global processHeaders
processHeaders:

;----------------------------------------------------
; Pushes
;----------------------------------------------------
	push r12
	push r13
	push r14
	push r15

; r12 = rsi = write desc
	mov r12d, esi
;r13 = rdx => file size
	mov r13, rdx
;r14 = rcx =>  image width 
	mov r14, rcx
;r15 = r8 => image height
	mov r15, r8
;----------------------------------------------------
; Begin Error Checking
;----------------------------------------------------

;----------------------------------------------------
;errReadHdr if error in open
;----------------------------------------------------
	mov rax, SYS_read      
    ;mov rdi, rdi      ; file descriptor already set
    mov rsi, signature     ; address
    mov rdx, HEADER_SIZE    ; how much to get
    syscall
;----------------------------------------------------
;errFileType (a) 
;----------------------------------------------------
	;cmp signature to BM
	cmp word[signature], 'BM'
    jne errFileType1
;----------------------------------------------------
;errDepth (b)word [addr + 28]
;----------------------------------------------------
	;cmp depth to 24
	cmp word[depth], 24
    jne errDepth1
;----------------------------------------------------
;errCompType (c) dword[addr + 30]
;----------------------------------------------------
	;cmp to 0
	cmp dword[compression], 0
    jne errCompType1
;----------------------------------------------------
;errSize (d) ensure the following
; dword[addr + 2] = dword[addr +10] + dword[addr + 34]
;----------------------------------------------------
	;add headerSize to pixData
	;cmp result to fileSize
	mov rax, 0
	mov eax, dword[headerSize]
    add eax, dword[pixData]
    cmp eax, dword[fileSize]
    jne errSize1
;----------------------------------------------------
;errWriteHdr write file error
;----------------------------------------------------
	mov rax, SYS_write     
    mov rdi, r12    ; output file descriptor
    mov rsi, signature ; address 
    mov rdx, HEADER_SIZE ; number of bytes to write
    syscall
;----------------------------------------------------
; Assign return values
;----------------------------------------------------
	;image width 
	; r14 = width
	mov rax, 0 ; clearing 
	mov eax, dword[width]
    mov [r14], eax
	;image height
	; r15 = height
	mov rax, 0 ; clearing 
	mov eax, dword[height]
    mov [r15], eax

; is good 
	jmp endProcessHeaders


;----------------------------------------------------
; Error Handling
;----------------------------------------------------
errReadHdr1:
	mov rdi, errReadHdr
	jmp printIt1
errFileType1:
	mov rdi, errFileType
	jmp printIt1
errDepth1:
	mov rdi, errDepth
	jmp printIt1
errCompType1:
	mov rdi, errCompType
	jmp printIt1
errSize1:
	mov rdi, errSize
	jmp printIt1

printIt1:
	call printString
;----------------------------------------------------
; Erroneous pops
;----------------------------------------------------
	pop r15
	pop r14
	pop r13 
	pop r12

	mov rax, 0
	mov rax, FALSE

	ret
;----------------------------------------------------
;Pops
;----------------------------------------------------
endProcessHeaders:
	pop r15
	pop r14
	pop r13 
	pop r12

	mov rax, 0
	mov rax, TRUE

	ret

; ***************************************************************
;  Return a row from read buffer
;	This routine performs all buffer management

; ----
;  HLL Call:
;	status = getRow(readFileDesc, picWidth, rowBuffer);

;   Arguments:
;	rdi - read file descriptor (value)
;	rsi - image width (value)
;	rdx - row buffer (address)
;  Returns:
;	TRUE or FALSE

; -----
;  This routine returns TRUE when row has been returned
;	and returns FALSE only if there is an
;	error on read (which would not normally occur)
;	or the end of file.

;  The read buffer itself and some misc. variables are used
;  ONLY by this routine and as such are not passed.

global getRow
getRow:
;----------------------------------------------------
;Pushes
;----------------------------------------------------
	push r12
	push r13
	push r14
	push r15
	push rbx 

; r12 = rdi = read file desc
	mov r12, rdi
; r13 = rsi = image width
	mov r13, rsi
	add r13 , rsi
	add r13 , rsi
; rbx = rdx => rowBuffer
	mov rbx, rdx 
;-----------------------------------
; But what if we didn't
;initializations:
;    eof = false
	;mov byte[wasEOF], FALSE
;    currIdx = BUFFSIZE
	;mov qword[curr], BUFF_SIZE
;    buffMax = BUFFSIZE
	;mov qword[buffMax], BUFF_SIZE
;-------------------------------------
;i = 0
	mov r14, 0 ; r14 is i
;getNextByte:
getNextByte:
;    if(currIdx >= buffMax)
	mov rax, qword[curr]
	cmp rax, qword[buffMax]
	jb next
;        if(eof)
		cmp byte[wasEOF], TRUE
		jne read
		mov rax, 0
		mov rax, FALSE
		jmp endGetRow
;            return false
;        readFile(BUFFSIZE in bytes)
read:
		mov rax, SYS_read      
    	mov rdi, r12      ; file descriptor already set
    	mov rsi, localBuffer; ?????     ; address 
    	mov rdx, BUFF_SIZE    ; how much to get
    	syscall
;        if(read error)
;            display error msg
;            return false
		cmp rax, 0
		jb errRead1
;        if(actualRd< request rd)
		cmp rax, qword[buffMax]
		jae setCurr
;            eof = true
;            buffMax = actualRd
			mov byte[wasEOF], TRUE
			mov qword[buffMax], rax ; actualrd in rax
setCurr:
;        currIdx = 0
		mov qword[curr], 0
next:
	mov r15, 0 ; r 15 = chr
	mov rsi, localBuffer
    mov rcx, 0
    mov rcx, qword[curr]
;    chr = buffer[currIdx]
	mov r15b, byte[rsi + rcx]; need to change 1 back to curr
;    currIdx ++
	inc qword[curr]

;    rowBuffer[i]= chr
	mov [rbx + r14], r15b
;    i++
	inc r14
;    ;is i> picwidth

;    if (i<picwidth *3)
	cmp r14, r13
	jl	getNextByte

    
;return true 
	mov rax, 0
	mov rax, TRUE
	jmp endGetRow
;----------------------------------------------------
;Error handling 
;----------------------------------------------------
errRead1:
	mov rdi, errReadHdr
	call printString
	mov rax, FALSE
endGetRow:
;----------------------------------------------------
;Pops
;----------------------------------------------------
	pop rbx
	pop r15
	pop r14
	pop r13
	pop r12

	ret
; ***************************************************************
;  Write image row to output file.
;	Writes exactly (width*3) bytes to file.
;	No requirement to buffer here.

; -----
;  HLL Call:
;	status = writeRow(writeFileDesc, pciWidth, rowBuffer);

;  Arguments are:
;	rdi - write file descriptor (value)
;	rsi - image width (value)
;	rdx - row buffer (address)

;  Returns:
;	TRUE or FALSE

; -----
;  This routine returns TRUE when row has been written
;	and returns FALSE only if there is an
;	error on write (which would not normally occur).



global writeRow
writeRow:
;----------------------------------------------------
;Pushes
;----------------------------------------------------
	push r12
	push r13
	push r14

;	r12 = rdi - write file descriptor (value)
	mov r12, rdi
;	r13 = rsi - image width (value)
	mov r13, rsi 
	add r13, rsi 
	add r13, rsi
;	r14 => rdx - row buffer (address)
	mov r14, rdx

; Write to opened file
	mov rax, SYS_write     
    mov rdi, r12    ; output file descriptor
    mov rsi, r14 ; address 
    mov rdx, r13 ; number of bytes to write
    syscall
    cmp rax, 0
    jl errWrite1


	mov rax, 0
	mov rax, TRUE
	jmp endWriteRow
;----------------------------------------------------
;error handling
;----------------------------------------------------
errWrite1:
	mov rdi, errWrite
	call printString
	mov rax, FALSE
;----------------------------------------------------
;Pops
;----------------------------------------------------
endWriteRow:
	pop r14
	pop r13
	pop r12

	ret
; ***************************************************************
;  Convert pixels to grayscale.

; -----
;  HLL Call:
;	status = imageCvtToBW(picWidth, rowBuffer);

;  Arguments are:
;	rdi - image width (value)
;	rsi - row buffer (address)
;  Returns:
;	updated row buffer (via reference)

global imageCvtToBW
imageCvtToBW:
;newRed=newGreen=newBlue= (oldRed+oldGreen+oldBlue)/3
	;mul picwidth by 3 (rdi)
	mov rax , rdi
	add rdi,  rax
	add rdi , rax
	
;initializations 
	mov rax, 0
	mov rbx, 0
	mov rcx, 0
	mov rdx, 0
	dec rdi ; rdi - 1
cvtToBW:
; loop (while (i(rcx) < rdi))
	cmp rcx, rdi
	jae imageCvtToBWdone
	;getChr
		; rowBuffer[i] = al
		mov al, byte [rsi + rcx] ;
		inc rcx
		; rowBuffer[i + 1] = bl
		mov bl, byte [rsi + rcx] ;
		inc rcx
		; rowBuffer[i + 2] = dl
		mov dl, byte [rsi + rcx] ;
		; dec rcx back to initial
		sub rcx, 2
	;cvtChr
		; ax + bx + dx (in ax)
		add ax, bx
		add ax, dx 
		mov dx, 0
		; div eax by 3
		mov bx, 3
		div bx
		; answer in al
	;setChr 
		
		; rowBuffer[i] = eax
		mov byte[rsi + rcx], al ; 
		inc rcx
		; rowBuffer[i + 1] = eax
		mov byte[rsi + rcx], al ; 
		inc rcx
		; rowBuffer[i + 2] = eax
		mov byte[rsi + rcx], al;  

	inc rcx ; for next pixel
	; restart loop 
	jmp cvtToBW
imageCvtToBWdone:
	ret 
; ***************************************************************
;  Update pixels to increase brightness

; -----
;  HLL Call:
;	status = imageBrighten(picWidth, rowBuffer);

;  Arguments are:
;	rdi - image width (value)
;	rsi - row buffer (address)
;  Returns:
;	updated row buffer (via reference)

global imageBrighten
imageBrighten:
;newBrightenedColorValue = (oldColorValue)\2 + oldColorValue

	;mul picwidth by 3 (rdi)
	mov rax , rdi
	add rdi,  rax
	add rdi , rax
	
;initializations 
	mov rax, 0
	mov rbx, 0
	mov rcx, 0

cvtToBrighten:
; loop (while (i(rcx) < rdi))
	cmp rcx, rdi
	jae imageCvtToBrightenDone
	;getChr
		; rowBuffer[i] = al
		mov al, byte [rsi + rcx] ;
	;cvtChr
		; al / 2
		mov bx,  ax
		shr bx, 1 
		; al /2 + al
		add ax, bx
		; answer in al
		; if al >255, al = 255
		cmp ax , 256
		jb setChrBrighten
		mov ax, 255
		;setChr
setChrBrighten: 
		
		; rowBuffer[i] = eax
		mov byte[rsi + rcx], al ; 

	inc rcx ; for next pixel
	; restart loop 
	jmp cvtToBrighten
imageCvtToBrightenDone:
	ret 


; ***************************************************************
;  Update pixels to darken (decrease brightness)

; -----
;  HLL Call:
;	status = imageDarken(picWidth, rowBuffer);

;  Arguments are:
;	rdi - image width (value)
;	rsi - row buffer (address)
;  Returns:
;	updated row buffer (via reference)

global imageDarken
imageDarken:
;oldColorValue/2

	;mul picwidth by 3 (rdi)
	mov rax , rdi
	add rdi,  rax
	add rdi , rax
	
;initializations 
	mov rax, 0
	mov rbx, 0
	mov rcx, 0

cvtToDarken:
; loop (while (i(rcx) < rdi))
	cmp rcx, rdi
	jae imageCvtDarkenDone
	;getChr
		; rowBuffer[i] = al
		mov al, byte [rsi + rcx] ;
	;cvtChr
		; al / 2
		shr al, 1
	;setChr 
		; rowBuffer[i] = eax
		mov byte[rsi + rcx], al ; 

	inc rcx ; for next pixel
	; restart loop 
	jmp cvtToDarken
imageCvtDarkenDone:
	ret 

; ******************************************************************
;  Generic function to display a string to the screen.
;  String must be NULL terminated.

;  Algorithm:
;	Count characters in string (excluding NULL)
;	Use syscall to output characters

;  Arguments:
;	- address, string
;  Returns:
;	nothing

global	printString
printString:
	push	rbx

; -----
;  Count characters in string.

	mov	rbx, rdi			; str addr
	mov	rdx, 0
strCountLoop:
	cmp	byte [rbx], NULL
	je	strCountDone
	inc	rbx
	inc	rdx
	jmp	strCountLoop
strCountDone:

	cmp	rdx, 0
	je	prtDone

; -----
;  Call OS to output string.

	mov	rax, SYS_write			; system code for write()
	mov	rsi, rdi			; address of characters to write
	mov	rdi, STDOUT			; file descriptor for standard in
						; EDX=count to write, set above
	syscall					; system call

; -----
;  String printed, return to calling routine.

prtDone:
	pop	rbx
	ret

; ******************************************************************

