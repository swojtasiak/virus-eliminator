*******************************************
**** Copyright (C) 1998-2018  S?awomir Wojtasiak
****
**** This program is free software
**** modify it under the terms of the GNU General Public License
**** as published by the Free Software Foundation
**** of the License, or (at your option) any later version.
****
**** This program is distributed in the hope that it will be useful,
**** but WITHOUT ANY WARRANTY
**** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
**** GNU General Public License for more details.
****
**** You should have received a copy of the GNU General Public License
**** along with this program
**** Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
********************************

 INCDIR  "INCLUDE:"
 INCLUDE "intuition/intuition.i"
 INCLUDE "intuition/intuition_lib.i"
 INCLUDE "intuition/screens.i"
 INCLUDE "exec/exec_lib.i"
 INCLUDE "exec/exec.i"
 INCLUDE "dos/dos.i"
 INCLUDE "dos/dos_lib.i"
 INCLUDE "libraries/diskfont_lib.i"
 INCLUDE "graphics/graphics_lib.i"
 INCLUDE "libraries/gadtools.i"
 INCLUDE "devices/trackdisk.i"
 INCLUDE "workbench/icon_lib.i"
 INCLUDE "xvs/xvs.i"
 INCLUDE "xvs/xvs_lib.i"
 INCLUDE "libraries/reqtools.i"
 INCLUDE "libraries/reqtools_lib.i"
 
**** STA?E ****

EXEC	equ	4
USER	equ	$80000000

_LVOGetVisualInfoA	equ	-126
_LVOFreeVisualInfo	equ	-132
_LVOCreateConText	equ	-114
_LVOFreeGadgets		equ	-36
_LVOCreateGadget	equ	-30
_LVORefreshWindow	equ	-84
_LVOGetIMsg		equ	-72
_LVOReplyIMsg		equ	-78
_LVOCreateMenusA	equ	-48
_LVOLayoutMenusA	equ	-66
_LVOFreeMenus		equ	-54
_LVOAddAppIconA		equ	-60
_LVORemoveAppIcon	equ	-66
_LVOGBeginRefresh	equ	-$5a
_LVOGEndRefresh		equ	-$60
_LVOGSetGadgetAttrsA	equ	-$2a

**** Start ****

PROGRAM:
	move.l	EXEC.W,a6
	lea	ProcName,a1
	jsr	_LVOFindTask(a6)
	tst.l	d0
	beq	NieUruchomiony
	move.l	#1,TASK_S
	bra	DALEJ
NieUruchomiony:
	move.l	EXEC.W,a6
	move.l	$114(a6),a0
	tst.l	$ac(a0)
	bne	Runit
DALEJ:	movem.l	d0/a0,-(a7)
	clr.l	ReturnMsg
	movea.w	#0,a1
	move.l	$4.W,a6
	jsr	_LVOFindTask(a6)
	movea.l	d0,a4
	lea	$5c(a4),a0
	jsr	_LVOWaitPort(a6)
	lea	$5c(a4),a0
	jsr	_LVOGetMsg(a6)
	move.l	d0,ReturnMsg
	movem.l	(a7)+,d0/a0
	tst.l	TASK_S
	bne	SKOK
	bsr	Runit
SKOK:
	move.l	d0,-(a7)
	move.l	$4.W,a6
	jsr	_LVOForbid(a6)
	move.l	ReturnMsg,a1
	jsr	_LVOReplyMsg(a6)
	move.l	(a7)+,d0
	rts	

Runit:
	lea	PROGRAM,a1
	move.l	-4(a1),d3
	clr.l	-4(a1)
	lea	$17a(a6),a0
	lea	DosName,a1
	jsr	_LVOFindName(a6)
	move.l	$114(a6),a0
	move.l	d0,a6
	move.l	$98(a0),d1
	jsr	-$60(a6)
	move.l	d0,-(sp)
	move.l	a6,-(sp)
	move.l	4,a6
	jsr	_LVOForbid(a6)
	move.l	(sp)+,a6
	lea	ProcName,a5
	move.l	a5,d1
	clr.l	d2
	move.l	#END_CODE-START,d4
	jsr	_LVOCreateProc(a6)
	move.l	d0,a0
	move.l	(sp)+,$3c(a0)
	move.l	EXEC.W,a6
	jsr	_LVOPermit(a6)
	moveq	#0,d0
	rts

TASK_S:		dc.l	0
ReturnMsg:	dc.l	0
ProcName:	dc.b	'VirusEliminator v2.2a by S?awomir Wojtasiak',0

	SECTION VE,CODE_C

START:	movem.l	d0-a6,-(sp)
	bsr	VirusEliminator
	movem.l	(sp)+,d0-a6
	tst.l	ICONIFY
	bne	ICONIFY_PROC
	rts

VirusEliminator:
	bsr	CreateGadgetCHB
	bsr	CreateGadgetDRIVE
	move.l	#42,LINE_NR
	bsr	OpenIntuition
	beq	ErrorInt
	bsr     OpenBootBlock
	beq	ErrorBoot
	bsr	_CheckDrive
	move.w	#0,DRIVE_NR
	bsr	OpenReqTools
	beq	ErrorReq
	bsr	OpenDiskFont
	beq	ErrorDF
	bsr	OpenGadTools
	beq	ErrorGadTools
	bsr	OpenDos
	beq	ErrorDos
	bsr	OpenGr
	beq	ErrorGr
	bsr	OpenVIREXFont
	beq	ErrorFont
	bsr	LockPubScreen
	beq	ErrorLock
	bsr	GetDrawInfo
	beq	ErrorDraw
	bsr	OpenScreen
	beq	ErrorScreen
	bsr	GetVisual
	beq	ErrorVisual
	bsr	CreateGadget
	beq	ErrorGadget
	bsr	OpenWindow
	beq	ErrorWindow
	bsr	DrawLine
	bsr	FontToRastPort
	bsr	CrMenu
	bne	ErrorMenu
	bsr	Memory
	bsr	Memory_Refresh
	bsr	OpenTrackDisk
	bne	ErrorTrackDisk
	bsr	OpenXVS
	beq	ErrorXVS
	bsr	LoadLibrary
	move.l	#0,_ICONIFY

**** Loop ****

Loop:	bsr	MenuRefresh
	bsr	ClrReg
	bsr	Memory_Refresh
	move.l	WindowBase,a0
	bsr	_GetMsg
	cmp.l	#MENUPICK,d1
	bne	Gadgety
	cmp.w	#$f821,d2
	beq	CheckFile
	cmp.w	#$f8a7,d2
	beq	MemoryCheck
	cmp.w	#$f887,d2
	beq	ZapisMem
	cmp.w	#$f867,d2
	beq	KopjujMem
	cmp.w	#$f807,d2
	beq	ReqATTR
	cmp.w	#$f827,d2
	beq	ReqATTR
	cmp.w	#$0047,d2
	beq	Zapisz_PHEX
	cmp.w	#$0847,d2
	beq	Zapisz_PASCII
	cmp.w	#$f805,d2
	beq	HardReset
	cmp.w	#$f825,d2
	beq	ColdReboot
	cmp.w	#$f864,d2
	beq	ZerujCOOL
	cmp.w	#$f884,d2
	beq	ZerujCOLD
	cmp.w	#$f8A4,d2
	beq	ZerujWARM
	cmp.w	#$f8C4,d2
	beq	ZerujTag
	cmp.w	#$f8E4,d2
	beq	ZerujMem
	cmp.w	#$f824,d2
	beq	SprawdzajWektory
	cmp.w	#$0004,d2
	beq	WektorHEX
	cmp.w	#$0804,d2
	beq	WektorASCII
	cmp.w	#$f883,d2
	beq	FreeLibrary_LABEL
	cmp.w	#$f8a3,d2
	beq	PrintBootName
	cmp.w	#$f843,d2
	beq	WriteLibrary
	cmp.w	#$f803,d2
	beq	AddBootBlock
	cmp.w	#$f823,d2
	beq	LoadLibrary_MENU
	cmp.w	#$f8A0,d2
	beq	Koniec
	cmp.w	#$f800,d2
	beq	About
	cmp.w	#$f802,d2
	beq	BootBlock_Buffor
	move.l	#LibList,VIEWATTR
	cmp.w	#$f806,d2
	beq	Libraries_LIST
	move.l	#DeviceList,VIEWATTR
	cmp.w	#$f826,d2
	beq	Libraries_LIST
	cmp.w	#$f822,d2
	beq	Plik_Buffor
	cmp.w	#$f820,d2
	beq	ICONIFY_INIT
	cmp.w	#$f801,d2
	beq	CHECK_BOOTBLOCK
	moveq	#XVSLIST_BOOTVIRUSES,d3
	cmp.w	#$0060,d2
	beq	VIRUS_LIST
	moveq	#XVSLIST_FILEVIRUSES,d3
	cmp.w	#$0860,d2
	beq	VIRUS_LIST
	moveq	#XVSLIST_LINKVIRUSES,d3
	cmp.w	#$1060,d2
	beq	VIRUS_LIST
	cmp.w	#$f840,d2
	beq	STATUS
	cmp.w	#$f842,d2
	beq	BUFFOR_PLIK
	cmp.w	#$f862,d2
	beq	KasujBuffor
	cmp.w	#$f8a2,d2
	beq	Czysty
	cmp.w	#$f8c2,d2
	beq	Standard
	cmp.w	#$f8e2,d2
	beq	Buffor
	cmp.w	#$f922,d2
	beq	Format
	cmp.w	#$f902,d2
	beq	InstallVEBoot
	cmp.w	#$f962,d2
	beq	Ascii
	cmp.w	#$f982,d2
	beq	HexRead
	cmp.w	#$f9a2,d2
	beq	Analizuj
Gadgety:
	cmp.l	#GADGETUP,d1
	bne	NieGadget
	cmp.w	#1,d0
	beq	Requstery_PROC
	cmp.w	#2,d0
	beq	TestDrive_PROC
	cmp.w	#3,d0
	beq	KillWirus_PROC
NieGadget:
	cmp.l	#GADGETDOWN,d1
	bne	NieGADDOWN
	move.w	d2,DRIVE_NR
NieGADDOWN:
	cmp.l	#GADGETUP,d1
	bne	NieGADUP
	cmp.w	#5,d0
	beq	Koniec
	cmp.w	#6,d0
	beq	ICONIFY_INIT
	cmp.w	#7,d0
	beq	STATUS
NieGADUP:
	cmp.l	#MOUSEBUTTONS,d1
	bne	NieMysz
	bra	Loop
NieMysz:
	cmp.l	#DISKINSERTED,d1
	bne	NieDysk
	tst.l	TestDrive
	beq	Loop
	move.l	#1,d2
	lea	CheckDrive.txt,a0
	bsr	PrintLine
	bsr	FreeMsg
	lea	Buffor_Roboczy,a0
	bsr	ReadBoot
	bne	ErrorBoot_check
	lea	Buffor_Roboczy,a0
	add.l	#1,CheckDrive
	bra	OkBuff_CBB
NieDysk:
	bra	Loop

ErrorBoot_check:
	move.l	#2,d2
	lea	ReadError,a0
	bsr	PrintLine
	bra	Loop

**************

FreeMsg:
	move.l	$4.W,a6
	move.l	WindowBase,a0
	move.l	wd_UserPort(a0),a0
	move.l	a0,a5
	jsr	_LVOWaitPort(a6)
	move.l	a5,a0
	jsr	_LVOGetMsg(a6)
	tst.l	d0
	beq	EndMsg
	move.l	d0,a1
	jsr	_LVOReplyMsg(a6)
EndMsg:	rts

*************

Koniec:	tst.l	ICONIFY
	bne	SkokReq_0
	cmp.w	#0,Requstery
	beq	SkokReq_0
	lea	Koniec.txt,a1
	lea	Koniec.gad,a0
	bsr	ReqRequestGAD
	tst.l	d0
	beq	Loop
SkokReq_0:
	bsr	FreeLibrary
	bsr	CloseXVS
LOCK.XVS:
	bsr	CloseTrackDisk
LOCK.TD:
	bsr	CloseMenu
LOCK.MN:
	bsr	CloseWindow
LOCK.WA:
	bsr	FreeGadget
LOCK.FR:
	bsr	FreeVisual
LOCK.VI:
	bsr	CloseScreen
LOCK.SR:
	bsr	FreeDrawInfo
LOCH.DI:
	bsr	UnLockPubScreen
LOCK.ET:
	bsr	CloseFont
CloseLibraries:
	bsr	CloseGr
	bsr	CloseDos
	bsr	CloseGadTools
	bsr	CloseDiskFont
	bsr	CloseReqTools
LOCK.BOT:
	bsr	CloseIntuition
	rts

ICONIFY_INIT:
	move.l	#1,ICONIFY
	bra	Koniec

**************************
* 	Procedury	 *
**************************

_CheckDrive:
	lea	Buffor_Roboczy,a0
	move.w	#3,DRIVE_NR
	bsr	ReadBoot
	cmp.l	#33,d0
	bne	Ok4stacje
	move.w	#2,DRIVE_NR
	bsr	ReadBoot
	cmp.l	#33,d0
	bne	Ok3stacje
	move.w	#1,DRIVE_NR
	bsr	ReadBoot
	cmp.l	#33,d0
	bne	Ok2stacje
	move.w	#0,DRIVE_NR
	bsr	ReadBoot
	cmp.l	#33,d0
	bne	Ok1stacje
	rts

Ok4stacje:
	rts

Ok3stacje:
 	move.l	#DriveTable+3*4,a0
 	move.l	#0,(a0)
	rts

Ok2stacje:
 	move.l	#DriveTable+2*4,a0
 	move.l	#0,(a0)
	rts

Ok1stacje:
 	move.l	#DriveTable+1*4,a0
 	move.l	#0,(a0)
	rts

**************************

COPY_MEM_0:
	movem.l	d0-a6,-(sp)
	subq.l	#1,d0
Loop_COPYSTR:
	move.b	(a0)+,(a1)+
	dbne	d0,Loop_COPYSTR
	suba.l	#1,a1
	move.b	#' ',(a1)
	movem.l	(sp)+,d0-a6
	rts

*************************

CheckFile:
	lea	CoSpr.gad,a0
	lea	CoSpr.txt,a1
	bsr	ReqRequestGAD
	tst.l	d0
	beq	Loop
	cmp.l	#2,d0
	beq	KatAlog
	cmp.l	#1,d0
	beq	PlIk
	bra	Loop

KatAlog:
	bsr	DirReq
	tst.l	d0
	beq	Loop
	move.l	DosBase,a6
	move.l	#FullName,d1
	move.l	#ACCESS_READ,d2
	jsr	_LVOLock(a6)
	tst.l	d0
	beq	Lock_Error
	move.l	d0,LOCK
	move.l	LOCK,d1
	move.l	#Buffor_FILE,d2
	jsr	_LVOExamine(a6)
	tst.l	d0
	beq	Error_Examine
Loop_READ:
	move.l	DosBase,a6
	move.l	LOCK,d1				
	move.l	#Buffor_FILE,d2
	jsr	_LVOExNext(a6)
	tst.l	d0
	beq	UnLock
	move.l	#Buffor_FILE+fib_FileName,a0
	tst.l	Buffor_FILE+fib_DirEntryType
	bpl	Katalog
	moveq	#1,d2
	bra	Plik
Katalog:					
	moveq	#2,d2				
	bsr	PrintLine
	sub.l	#8,LINE_NR
	moveq	#1,d2
	move.l	#500,d1
	lea	Katalog.txt,a0
	bsr	PrintLine_X
	bra	Loop_READ



PlIk:	bsr	FileReq
	tst.l	d0
	beq	Loop
	move.l	DosBase,a6
	move.l	#FullName,d1
	move.l	#ACCESS_READ,d2
	jsr	_LVOLock(a6)
	tst.l	d0
	beq	FileError_LOCK.err
	move.l	d0,d3
	move.l	d0,d1
	move.l	#Buffor_FILE,d2
	jsr	_LVOExamine(a6)
	move.l	d3,d1
	jsr	_LVOUnLock(a6)
	move.l	#0,LOCK
	move.l	#FileName,a0
	moveq	#1,d2

Plik:	bsr	PrintLine		
	add.l	#1,CheckFiles

	move.l	#Buffor_FILE+fib_Size,a0
	move.l	(a0),FileSize

	tst.l	LOCK
	beq	SKIP_Current1
	move.l	DosBase,a6		
	move.l	LOCK,d1
	jsr	_LVOCurrentDir(a6)
	move.l	d0,LOCK_SAVE
SKIP_Current1:

	move.l	XVSBase,a6		
	move.l	#XVSOBJ_FILEINFO,d0
	jsr	_LVOxvsAllocObject(a6)
	tst.l	d0
	bne	OkAllocObj
	move.l	#AllocError2.txt,a1
	bsr	ReqRequest
	bra	EndPlik_CHECK
OkAllocObj:
	move.l	d0,FileInfo
	
	move.l	EXEC.W,a6		
	move.l	FileSize,d0
	move.l	#MEMF_ANY,d1
	jsr	_LVOAllocMem(a6)
	beq	AllocError
	move.l	d0,FileData
	
	move.l	DosBase,a6			
	move.l	#Buffor_FILE+fib_FileName,d1
	tst.l	LOCK
	bne	JestLock
	move.l	#FullName,d1
JestLock:
	move.l	#MODE_OLDFILE,d2
	jsr	_LVOOpen(a6)
	tst.l	d0
	beq	OpenError_FCH
	move.l	d0,FileHandle_FCH
	move.l	d0,d1
	move.l	FileData,d2
	move.l	FileSize,d3
	jsr	_LVORead(a6)
	tst.l	d0
	beq	ReadError_FCH
	move.l	FileHandle_FCH,d1
	jsr	_LVOClose(a6)

	move.l	XVSBase,a6			
	move.l	FileInfo,a0
	move.l	FileData,xvsfi_File(a0)
	move.l	FileSize,xvsfi_FileLen(a0)
	jsr	_LVOxvsCheckFile(a6)
	cmp.l	#XVSFT_EMPTYFILE,d0
	beq	EMPTYFILE
	cmp.l	#XVSFT_DATAFILE,d0
	beq	DATAFILE
	cmp.l	#XVSFT_EXEFILE,d0
	beq	EXEFILE
	cmp.l	#XVSFT_DATAVIRUS,d0
	beq	DATAVIRUS
	cmp.l	#XVSFT_FILEVIRUS,d0
	beq	FILEVIRUS
	cmp.l	#XVSFT_LINKVIRUS,d0
	beq	LINKVIRUS
	
	move.l	#NieWiem.txt,a0		
	move.l	#500,d1
	move.l	#2,d1
	bsr	PrintLine_X

FreeMem:				
	move.l	EXEC.W,a6
	move.l	FileSize,d0
	move.l	FileData,a1
	jsr	_LVOFreeMem(a6)
FreeFileInfo:				
	move.l	XVSBase,a6
	move.l	FileInfo,a1
	jsr	_LVOxvsFreeObject(a6)
EndPlik_CHECK:
	tst.l	LOCK
	beq	Loop
	move.l	DosBase,a6		
	move.l	LOCK_SAVE,d1
	jsr	_LVOCurrentDir(a6)
	bra	Loop_READ		

***** Obs?uga wirusa ******

EMPTYFILE:				
	lea	EmptyFile.txt,a0
	moveq	#3,d2
	move.l	#500,d1
	sub.l	#8,LINE_NR
	bsr	PrintLine_X
	bra	FreeMem
DATAFILE:				
	lea	DataFile.txt,a0
	moveq	#1,d2
	move.l	#500,d1
	sub.l	#8,LINE_NR
	bsr	PrintLine_X
	bra	FreeMem
EXEFILE:				
	lea	ExeFile.txt,a0
	moveq	#1,d2
	move.l	#500,d1
	sub.l	#8,LINE_NR
	bsr	PrintLine_X
	bra	FreeMem
DATAVIRUS:				
	lea	DataWirus.txt,a0
	moveq	#1,d2
	move.l	#500,d1
	sub.l	#8,LINE_NR
	bsr	PrintLine_X
	bra	FreeMem
FILEVIRUS:				
	add.l	#1,VirusFound
	lea	FileVirus.txt,a0
	moveq	#3,d2
	sub.l	#8,LINE_NR
	move.l	#500,d1
	bsr	PrintLine_X
	move.l	FileInfo,a0
	move.l	xvsfi_Name(a0),a1
	lea	FileWirus.txt+21,a0
Copy_FV_Loop:
	move.b	(a1)+,(a0)+
	bne	Copy_FV_Loop
	lea	FileWirus.txt,a1
	lea	Del_Nie.gad,a0
	bsr	ReqRequestGAD
	tst.l	d0
	beq	FreeMem
	move.l	DosBase,a6
	move.l	#FullName,d1
	tst.l	LOCK
	beq	LOCKJest0
	move.l	#Buffor_FILE+fib_FileName,d1
LOCKJest0:
	jsr	_LVODeleteFile(a6)
	tst.l	d0
	bne	OkSKASOWANY
	lea	ErrorDel.err,a0
	moveq	#2,d2
	bsr	PrintLine
	bra	FreeMem
OkSKASOWANY:
	lea	SKASOWANY,a0
	moveq	#1,d2
	bsr	PrintLine
	bra	FreeMem

LINKVIRUS:				
	lea	LinkVirus.txt,a0
	moveq	#1,d2
	move.l	#500,d1
	sub.l	#8,LINE_NR
	bsr	PrintLine_X
	cmp.w	#1,KillWirus
	beq	OKKILL
	lea	Link.txt,a1
	lea	Link.gad,a0
	jsr	ReqRequestGAD
	tst.l	d0
	beq	FreeMem
OKKILL:
	move.l	FileInfo,a0
	move.l	XVSBase,a6
	jsr	_LVOxvsRepairFile(a6)
	tst.l	d0
	beq	ErrorRepair
	move.l	#FullName,d1
	move.l	DosBase,a6
	move.l	#MODE_NEWFILE,d0
	jsr	_LVOOpen(a6)
	tst.l	d0
	bne	OkRead_
	lea	WriteError.txt,a0
	moveq	#2,d2
	bsr	PrintLine
	bra	FreeMem
OkRead_:
	bra	FreeMem
	move.l	d0,d7
	move.l	d0,d1
	move.l	FileInfo,a0
	move.l	xvsfi_Fixed(a0),d2
	move.l	xvsfi_FixedLen(a0),d3
	jsr	_LVOWrite(a6)
	tst.l	d0
	beq	ErrorW
	move.l	d7,d1
	jsr	_LVOClose
	lea	OkRepair.txt,a0
	moveq	#1,d2
	bsr	PrintLine
	bra	FreeMem

ErrorW:
	move.l	d7,d1
	jsr	_LVOClose
	lea	WriteError.txt,a0
	moveq	#2,d2
	bsr	PrintLine
	bra	FreeMem
ErrorRepair:
	lea	NotRepair.txt,a0
	moveq	#2,d2
	bsr	PrintLine
	bra	FreeMem

***** Errory FCH *****

FileError_LOCK.err:
	lea	ReadError_FCH.err,a0
	moveq	#2,d2
	move.l	#500,d1
	sub.l	#8,LINE_NR
	bsr	PrintLine_X
	bra	Loop

ReadError_FCH:
	move.l	DosBase,a6
	move.l	FileHandle_FCH,d1
	jsr	_LVOClose(a6)
OpenError_FCH:	
	lea	ReadError_FCH.err,a0
	moveq	#2,d2
	move.l	#500,d1
	sub.l	#8,LINE_NR
	bsr	PrintLine_X
	bra	FreeMem

AllocError:
	lea	LibOpenERR,a0
	moveq	#2,d2
	move.l	#500,d1
	sub.l	#8,LINE_NR
	bsr	PrintLine_X
	bra	FreeFileInfo

UnLock:
	move.l	DosBase,a6
	move.l	LOCK,d1
	jsr	_LVOUnLock(a6)
	bra	Loop

Error_Examine:
	lea	Lock.err,a1
	bsr	ReqRequest
	bra	UnLock

Lock_Error:
	lea	Lock.err,a1
	bsr	ReqRequest
	bra	Loop

	even
LOCK:		dc.l	0
LOCK_SAVE:	dc.l	0
FileInfo:	dc.l	0
FileData:	dc.l	0
FileHandle_FCH:	dc.l	0
KATALOG:	dc.l	0
FileSize:	dc.l	0
Lock.err:	dc.b	'Nie mog? otworzy? katalogu...',0
ReadError_FCH.err:dc.b	'B??d odczytu!',0
Katalog.txt:	dc.b	'Katalog',0
NieWiem.txt	dc.b	'???',0
EmptyFile.txt:	dc.b	'Pusty plik!',0
DataFile.txt:	dc.b	'Plik z danymi',0
ExeFile.txt:	dc.b	'Plik wykonywalny',0
DataWirus.txt:	dc.b	'Plik z danymi wir.',0
FileVirus.txt:	dc.b	'Virus plikowy!',0
LinkVirus.txt:	dc.b	'Virus linker !',0
OkRepair.txt:	dc.b	'Plik naprawiony !!!',0
NotRepair.txt:	dc.b	'Nie uda?o si? naprawi? pliku !!!',0
FileWirus.txt:	dc.b	'Uwaga wirus plikowy:',10
		blk.b	50
Del_Nie.gad:	dc.b	'Kasuj|Dalej',0
ErrorDel.err:	dc.b	'Nie mog? skasowa? pliku !!!',0
SKASOWANY:	dc.b	'Plik skasowany !!!',0
	even

**************************

MemoryCheck:
	move.l	XVSBase,a6
	move.l	#XVSOBJ_MEMORYINFO,d0
	jsr	_LVOxvsAllocObject(a6)
	tst.l	d0
	bne	OkALocate
	lea	AllocError.txt,a1
	bsr	ReqRequest
	bra	Loop
OkALocate:
	move.l	d0,MemoryInfo
	lea	TestMem.txt,a0
	moveq	#1,d2
	bsr	PrintLine

	move.l	MemoryInfo,a0
	move.w	xvsmi_Count(a0),d0
	tst.w	d0
	bne	OkNie0
	lea	NicPod.txt,a0
	moveq	#1,d2
	bsr	PrintLine
	bra	FreeMemInfo
OkNie0:
FreeMemInfo:
	move.l	XVSBase,a6
	move.l	MemoryInfo,a1
	jsr	_LVOxvsFreeObject(a6)
	bra	Loop

**************************

ZapisMem:
	bsr	AdresReq
	beq	Loop
	move.l	d0,d5			
	lea	TITLE_LongByte,a0
	bsr	GetLongREQ
	cmp.l	#-1,d0
	beq	Loop
	move.l	d0,ILE_MEM			
	bsr	FileReq
	tst.l	d0
	beq	Loop

	tst.w	Requstery
	beq	OK_PLIKU_BRAK
	move.l	DosBase,a6
	move.l	#FullName,d1
	move.l	#MODE_OLDFILE,d2
	jsr	_LVOOpen(a6)
	tst.l	d0
	beq	OK_PLIKU_BRAK
	move.l	d0,d1
	jsr	_LVOClose(a6)
	move.l	#JestPlik1.txt,a1
	move.l	#JestPlik1.gad,a0
	bsr	ReqRequestGAD
	tst.l	d0
	beq	Loop
OK_PLIKU_BRAK:

	move.l	DosBase,a6
	move.l	#FullName,d1
	move.l	#MODE_NEWFILE,d2
	jsr	_LVOOpen(a6)
	tst.l	d0
	bne	OkPlikStworzony
	lea	WOpen.err,a1
	bsr	ReqRequest
	bra	Loop
OkPlikStworzony:
	move.l	DosBase,a6
	move.l	d0,d7
	move.l	d0,d1
	move.l	d5,d2
	move.l	ILE_MEM,d3
	jsr	_LVOWrite(a6)
	tst.l	d0
	bne	OkWriteFileMem
	move.l	d7,d1
	jsr	_LVOClose(a6)
	lea	WriteError.txt,a1
	bsr	ReqRequest
	bra	Loop
OkWriteFileMem:
	move.l	d7,d1
	jsr	_LVOClose(a6)
	lea	PlikZapisany.txt,a0
	moveq	#1,d2
	bsr	PrintLine
	bra	Loop

**************************

GetLongREQ:
	movem.l	d1-a6,-(sp)
	move.l	#0,_LONG
	move.l	ReqBase,a6
	lea	_LONG,a1
	move.l	a0,a2
	move.l	#0,a3
	lea	GetLong_TAGLIST,a0
	move.l	#TextATTR,3*4(a0)
	move.l	ScreenBase,1*4(a0)
	jsr	_LVORtGetLongA(a6)
	tst.l	d0
	bne	Ok_REQ
	move.l	#-1,_LONG
Ok_REQ:	movem.l	(sp)+,d1-a6
	move.l	_LONG,d0
	rts
_LONG:	dc.l	0

**************************

KopjujMem:
	lea	ZRUDLO,a0
	bsr	AdresReq1
	beq	Loop
	move.l	d0,d2
	lea	DOCELOWY,a0
	bsr	AdresReq1
	beq	Loop
	move.l	d0,d3
	move.l	d2,d0
	move.l	d3,d1
	sub.l	d0,d1
	tst.l	d1
	bne	OkAdres2
	lea	Adres0,a1
	bsr	ReqRequest
	bra	Loop
OkAdres2:
	lea	TITLE_LongByte,a0
	bsr	GetLongREQ
	cmp.l	#-1,d0
	beq	Loop
	cmp.l	#0,d0
	beq	Loop
	move.l	EXEC.W,a6
	move.l	d2,a0
	move.l	d3,a1
	jsr	_LVOCopyMem(a6)
	lea	Copy_ok.txt,a0
	moveq	#1,d2
	bsr	PrintLine
	bra	Loop

****************************

Zapisz_PHEX:
	bsr	AdresReq
	beq	Loop
	move.l	d0,d2
Loop_PrintHEX:
	move.l	d2,d0
	bsr	PrintHexMem22
	add.l	#336,d2
	move.l	#Kont.gad,a0
	move.l	#Kont.txt,a1
	bsr	ReqRequestGAD_1
	tst.l	d0
	bne	Loop_PrintHEX
	bra	Loop

*************************

Zapisz_PASCII:
	bsr	AdresReq
	beq	Loop
	move.l	d0,d2
Loop_PrintASCII:
	move.l	d2,d0
	bsr	PrintAsciiMem22
	add.l	#336,d2
	move.l	#Kont.gad,a0
	move.l	#Kont.txt,a1
	bsr	ReqRequestGAD_1
	tst.l	d0
	bne	Loop_PrintASCII
	bra	Loop

**************************

PrintHexMem22:				
	movem.l	d0-a6,-(sp)
	move.l	EXEC.W,a6
	move.l	#Buffor_Roboczy,a1
	move.l	d0,a0
	move.l	#23*16,d0
	jsr	_LVOCopyMem(a6)
	move.l	#Buffor_Roboczy,a0
	moveq	#22,d2
PrintHex_Loop:
	bsr	PrintHexMem
	adda.l	#16,a0
	dbra	d2,PrintHex_Loop
	movem.l	(sp)+,d0-a6
	rts

PrintAsciiMem22:			
	movem.l	d0-a6,-(sp)
	moveq	#22,d2
	move.l	d0,a0
PrintAscii_Loop:
	bsr	PrintAscii
	adda.l	#64,a0
	dbra	d2,PrintAscii_Loop
	movem.l	(sp)+,d0-a6
	rts

**************************

ReqATTR:move.w	d2,D2_SAVE1
	move.l	ReqBase,a6			
	lea	_STRING,a1
	move.l	#9,d0
	bsr	CLR_STR				
	move.l	#WINDOWTITLE_HEX,a2
	move.l	#0,a3
	move.l	#TAGLIST_STRING_HEX_P,a0
	move.l	#TextATTR,3*4(a0)
	move.l	ScreenBase,1*4(a0)
	jsr	_LVORtGetStringA(a6)
	tst.l	d0
	beq	Loop
	lea	_STRING,a0
	move.b	(a0),d0
	tst.l	d0
	beq	Loop

	lea	_STRING_H,a0
	bsr	CONWERTER
	cmp.l	#-1,d0
	beq	ReqATTR
	move.l	d0,POCZ

Search_K:
	move.l	ReqBase,a6			
	lea	_STRING,a1
	move.l	#9,d0
	bsr	CLR_STR				
	move.l	#WINDOWTITLE_HEX,a2
	move.l	#0,a3
	move.l	#TAGLIST_STRING_HEX_K,a0
	move.l	#TextATTR,3*4(a0)
	move.l	ScreenBase,1*4(a0)
	jsr	_LVORtGetStringA(a6)
	tst.l	d0
	beq	Loop
	lea	_STRING,a0
	move.b	(a0),d0
	tst.l	d0
	beq	Loop

	lea	_STRING_H,a0
	bsr	CONWERTER
	cmp.l	#-1,d0
	beq	Search_K
	move.l	d0,KONI

	move.l	POCZ,d0			
	move.l	KONI,d1
	sub.l	d0,d1
	bpl	OkAdres
	lea	AdresMaly,a1
	bsr	ReqRequest
	bra	Loop
OkAdres:
	tst.l	d1			
	bne	OkAdres1
	lea	Adres0,a1
	bsr	ReqRequest
	bra	Loop
OkAdres1:

	move.l	d1,D7			
	


	move.w	D2_SAVE1,d2
	cmp.w	#$f807,d2
	beq	SEARCH
	cmp.w	#$f827,d2
	beq	Zeruj_MEM
	bra	Loop

*******************************

AdresReq:
	movem.l	d1-a6,-(sp)
AdresReq_ER:
	move.l	ReqBase,a6			
	lea	_STRING,a1
	move.l	#9,d0
	bsr	CLR_STR				
	move.l	#WINDOWTITLE_HEX,a2
	move.l	#0,a3
	move.l	#TAGLIST_ADRES,a0
	move.l	#TextATTR,3*4(a0)
	move.l	ScreenBase,1*4(a0)
	jsr	_LVORtGetStringA(a6)
	tst.l	d0
	beq	Error_AR
	lea	_STRING,a0
	move.b	(a0),d0
	tst.l	d0
	beq	Error_AR
	lea	_STRING_H,a0
	bsr	CONWERTER
	cmp.l	#-1,d0
	beq	AdresReq_ER
	movem.l	(sp)+,d1-a6
	rts
Error_AR:
	movem.l	(sp)+,d1-a6
	moveq	#0,d0
	rts

AdresReq1:
	movem.l	d1-a6,-(sp)
	move.l	a0,a5
AdresReq_ER1:
	move.l	ReqBase,a6			
	lea	_STRING,a1
	move.l	#9,d0
	bsr	CLR_STR				
	move.l	#WINDOWTITLE_HEX,a2
	move.l	#0,a3
	move.l	#TAGLIST_ADRES1,a0
	move.l	#TextATTR,3*4(a0)
	move.l	ScreenBase,1*4(a0)
	move.l	a5,9*4(a0)
	jsr	_LVORtGetStringA(a6)
	tst.l	d0
	beq	Error_AR1
	lea	_STRING,a0
	move.b	(a0),d0
	tst.l	d0
	beq	Error_AR1
	lea	_STRING_H,a0
	bsr	CONWERTER
	cmp.l	#-1,d0
	beq	AdresReq_ER1
	movem.l	(sp)+,d1-a6
	rts
Error_AR1:
	movem.l	(sp)+,d1-a6
	moveq	#0,d0
	rts

*******************************

Zeruj_MEM:
	tst.w	Requstery
	beq	Zeruj_LET
	lea	MemClear.txt,a1
	lea	TakNie.gad,a0
	bsr	ReqRequestGAD
	tst.l	d0
	beq	NieZeruj
Zeruj_LET:
	subq.l	#1,d7
	move.l	POCZ,a0
ClearLoop_MEM:
	move.b	#0,(a0)+
	dbra	d7,ClearLoop_MEM
	lea	MemCleared.txt,a0
	moveq	#1,d2
	bsr	PrintLine
NieZeruj:
	bra	Loop


*******************************

SEARCH:
	

	move.l	ReqBase,a6			
	lea	_STRING_SEARCH,a1
	move.l	#100,d0
	bsr	CLR_STR				
	move.l	#TITLE.INTREQ,a2
	move.l	#0,a3
	move.l	#TAGLIST_SEARCH,a0
	move.l	#TextATTR,3*4(a0)
	move.l	ScreenBase,1*4(a0)
	jsr	_LVORtGetStringA(a6)
	tst.l	d0
	beq	Loop
	lea	_STRING_SEARCH,a0
	move.b	(a0),d0
	tst.l	d0
	beq	Loop

	lea	TakNie.gad,a0
	lea	AdresPrint.txt,a1
	bsr	ReqRequestGAD
	tst.l	d0
	bne	SEARCH2

SEARCH1:
	bsr	PrintLine0
	lea	Szukam.txt,a0
	moveq	#1,d2
	bsr	PrintLine
	move.b	_STRING_SEARCH,d6
	move.l	POCZ,a0
Searh_LOOP1:
	move.l	a0,d0
	move.b	(a0),d1
	cmp.b	d6,d1
	bne	NieMa1
	movem.l	a0-a1/d2,-(sp)
	lea	_STRING_SEARCH,a0
	move.l	d0,a1
	bsr	SEARCH_PROC
	tst.l	d3
	bne	NieMA1
	moveq	#1,d2
	lea	Adres.txt+8,a0
	bsr	Hex
	lea	Adres.txt+8,a0
	moveq	#1,d2
	bsr	PrintLine
NieMA1:	movem.l	(sp)+,a0-a1/d2
NieMa1:
	adda.l	#1,a0
	dbra	d7,Searh_LOOP1
	lea	QSzukam.txt,a0
	moveq	#1,d2
	bsr	PrintLine
	bra	Loop



SEARCH2:bsr	PrintLine0
	lea	Szukam.txt,a0
	moveq	#1,d2
	bsr	PrintLine
	move.b	_STRING_SEARCH,d6
	move.l	POCZ,a0
	subq.l	#1,d7
Searh_LOOP:
	movem.l	d0-a6,-(sp)
	move.l	EXEC.W,a6
	move.l	WindowBase,a0
	move.l	wd_UserPort(a0),a0
	jsr	_LVOGetMsg(a6)
	tst.l	d0
	beq	BrakLMB
	move.l	d0,a1
	move.l	d0,a4
	jsr	_LVOReplyMsg(a6)
	move.l	im_Class(a4),d0
	move.w	im_Code(a4),d1
	cmp.l	#MOUSEBUTTONS,d0
	bne	BrakLMB
	cmp.w	#$68,d1
	bne	BrakLMB
	movem.l	(sp)+,d0-a6
	bra	QUIT_SEARCH1
BrakLMB:movem.l	(sp)+,d0-a6
	move.l	a0,d0
	movem.l	a0,-(sp)
	lea	Adres.txt,a0
	bsr	Hex
	lea	Adres.txt,a0
	moveq	#1,d2
	bsr	PrintLine
	movem.l	(sp)+,a0
	move.b	(a0),d1
	cmp.b	d6,d1
	bne	NieMa
	movem.l	a0-a1/d2,-(sp)
	lea	_STRING_SEARCH,a0
	move.l	d0,a1
	bsr	SEARCH_PROC
	tst.l	d3
	bne	NieMA
	moveq	#1,d2
	lea	Adres.txt+8,a0
	bsr	Hex
	lea	Adres.txt+8,a0
	moveq	#1,d2
	sub.l	#8,LINE_NR
	bsr	PrintLine
	add.l	#8,LINE_NR
NieMA:	movem.l	(sp)+,a0-a1/d2
NieMa:	adda.l	#1,a0
	sub.l	#8,LINE_NR
	dbra	d7,Searh_LOOP
QUIT_SEARCH1:
	lea	QSzukam.txt,a0
	moveq	#1,d2
	bsr	PrintLine
	bra	Loop

****************************

SEARCH_PROC:			
	movem.l	d0-a6,-(sp)
SearchLOOP:
	move.b	(a0)+,d0
	move.b	(a1)+,d1
	tst.b	d0
	beq	TRUE_SEARCH
	cmp.b	d0,d1
	bne	FALSE_SEARCH
	bra	SearchLOOP
TRUE_SEARCH:
	movem.l	(sp)+,d0-a6
	moveq	#0,d3
	tst.l	d3
	rts
FALSE_SEARCH:
	movem.l	(sp)+,d0-a6
	moveq	#-1,d3
	tst.l	d3
	rts

****************************

CONWERTER:				
	movem.l	d1-a6,-(sp)
Loop_S0:move.b	(a0)+,d0
	tst.b	d0
	bne	Loop_S0
	suba.l	#1,a0			
	moveq	#0,d2			
	moveq	#0,d3			
Loop_CONWERT:
	moveq	#0,d0
	move.b	-(a0),d0
	bsr	Conw_AHB
	cmp.b	#-1,d0
	beq	KONIEC_AH
	cmp.b	#'$',d0
	beq	KONIEC_NA
	or.b	d0,d2
	ror.l	#4,d2
	addq.l	#1,d3
	bra	Loop_CONWERT
KONIEC_NA:
	mulu.l	#4,d3
	rol.l	d3,d2
	move.l	d2,d0
KONIEC_AH:
	movem.l	(sp)+,d1-a6
	rts
Conw_AHB:
	movem.l	d1-a6,-(sp)
	cmp.b	#'$',d0
	beq	K_AHB
	sub.b	#$30,d0
	cmp.b	#$09,d0
	bgt	WiencejNIZ10
	bra	K_AHB
WiencejNIZ10:
	add.b	#$30,d0
	cmp.b	#'a',d0
	bne	NIEa
	move.l	#$0a,d0
	bra	K_AHB
NIEa:	cmp.b	#'A',d0
	bne	NIEA
	move.l	#$0a,d0
	bra	K_AHB
NIEA:	cmp.b	#'b',d0
	bne	NIEb
	move.l	#$0b,d0
	bra	K_AHB
NIEb:	cmp.b	#'B',d0
	bne	NIEB
	move.l	#$0b,d0
	bra	K_AHB
NIEB:	cmp.b	#'c',d0
	bne	NIEc
	move.l	#$0c,d0
	bra	K_AHB
NIEc:	cmp.b	#'C',d0
	bne	NIEC
	move.l	#$0c,d0
	bra	K_AHB
NIEC:	cmp.b	#'d',d0
	bne	NIEd
	move.l	#$0d,d0
	bra	K_AHB
NIEd:	cmp.b	#'D',d0
	bne	NIED
	move.l	#$0d,d0
	bra	K_AHB
NIED:	cmp.b	#'e',d0
	bne	NIEe
	move.l	#$0e,d0
	bra	K_AHB
NIEe:	cmp.b	#'E',d0
	bne	NIEE
	move.l	#$0e,d0
	bra	K_AHB
NIEE:	cmp.b	#'f',d0
	bne	NIEf
	move.l	#$0f,d0
	bra	K_AHB
NIEf:	cmp.b	#'F',d0
	bne	NIEF
	move.l	#$0f,d0
	bra	K_AHB
NIEF:	moveq	#-1,d0
K_AHB:	movem.l	(sp)+,d1-a6
	rts

***************************

CLR_STR:movem.l	d0-a6,-(sp)	
	subq.l	#1,d0
Loop_CLR:
	move.b	#0,(a1)+
	dbra	d0,Loop_CLR
	movem.l	(sp)+,d0-a6
	rts

CLR_STR_STRING:
	movem.l	d0-a6,-(sp)	
	subq.l	#1,d0
Loop_CLR1:
	move.b	#' ',(a1)+
	dbra	d0,Loop_CLR1
	movem.l	(sp)+,d0-a6
	rts

**************************

PrintBootName:
	tst.l	BIBLIOTEKA
	bne	OkJestLib_PRINT
	lea	BrakBiblioteki,a1
	bsr	ReqRequest
	bra	Loop
OkJestLib_PRINT:
	bsr	PrintLine0
	move.l	BIBLIOTEKA,a0
	move.l	(a0)+,d0
	move.l	d0,d3			
	moveq	#0,d4
	subq	#1,d3
Loop_PRINTBB:
	moveq	#1,d2
	addq	#1,d4
	bsr	PrintLine
	adda.l	#100,a0

	cmp.l	#20,d4	
	bne	Ok_PRINT
	movem.l	d0-d6/a0-a6,-(sp)
	lea	Kont.txt,a1
	lea	Kont.gad,a0
	bsr	ReqRequestGAD_1
	move.l	d0,d7
	movem.l	(sp)+,d0-d6/a0-a6
	tst.l	d7
	beq	OK_ILE
	moveq	#0,d4
Ok_PRINT:

	dbra	d3,Loop_PRINTBB
OK_ILE:	lea	IlleBoot.txt+32,a1
	moveq	#0,d7
	bsr	Conwert
	moveq	#3,d2
	lea	IlleBoot.txt,a0
	bsr	PrintLine
	bra	Loop

ColdReboot:
	lea	Reset.txt,a1
	lea	Reset.gad,a0
	bsr	ReqRequestGAD
	tst.l	d0
	beq	Loop
	move.l	EXEC.W,a6
	jsr	_LVOColdReboot(a6)
	bra	Loop

HardReset:
	lea	Reset.txt,a1
	lea	Reset.gad,a0
	bsr	ReqRequestGAD
	tst.l	d0
	beq	Loop
Reset   move.l	EXEC.W,A6
        lea	Reset_P(PC),A5
        jsr	-$001E(A6)
Reset_P clr.l	4.W
	lea	2.W,A0
	reset	
	jmp	(A0)

**************************

ZerujCOOL:
	move.l	EXEC.W,a6
	tst.l	CoolCapture(a6)
	bne	OkZeruj_COOL
	lea	WektorJest0.txt,a1
	bsr	ReqRequest
	bra	Loop
OkZeruj_COOL:
	move.l	#0,CoolCapture(a6)
	lea	WyzerowalemCool,a0
	moveq	#1,d2
	bsr	PrintLine
	bra	Loop

ZerujCOLD:
	move.l	EXEC.W,a6
	tst.l	ColdCapture(a6)
	bne	OkZeruj_COLD
	lea	WektorJest0.txt,a1
	bsr	ReqRequest
	bra	Loop
OkZeruj_COLD:
	move.l	#0,ColdCapture(a6)
	lea	WyzerowalemCold,a0
	moveq	#1,d2
	bsr	PrintLine
	bra	Loop

ZerujWARM:
	move.l	EXEC.W,a6
	tst.l	WarmCapture(a6)
	bne	OkZeruj_WARM
	lea	WektorJest0.txt,a1
	bsr	ReqRequest
	bra	Loop
OkZeruj_WARM:
	move.l	#0,WarmCapture(a6)
	lea	WyzerowalemWarm,a0
	moveq	#1,d2
	bsr	PrintLine
	bra	Loop

ZerujTag:
	move.l	EXEC.W,a6
	tst.l	KickTagPtr(a6)
	bne	OkZeruj_TAG
	lea	WektorJest0.txt,a1
	bsr	ReqRequest
	bra	Loop
OkZeruj_TAG:
	move.l	#0,KickTagPtr(a6)
	lea	WyzerowalemTag,a0
	moveq	#1,d2
	bsr	PrintLine
	bra	Loop

ZerujMem:
	move.l	EXEC.W,a6
	tst.l	KickMemPtr(a6)
	bne	OkZeruj_MEM
	lea	WektorJest0.txt,a1
	bsr	ReqRequest
	bra	Loop
OkZeruj_MEM:
	move.l	#0,KickMemPtr(a6)
	lea	WyzerowalemMem,a0
	moveq	#1,d2
	bsr	PrintLine
	bra	Loop

**************************

SprawdzajWektory:
	move.l	#0,ZMIANA
	bsr	PrintLine0
	move.l	#1,d2
	lea	Spr.txt,a0
	bsr	PrintLine
	move.l	EXEC.W,a6
	move.l	CoolCapture(a6),d0
	lea	ZmianaCool+14,a0
	bsr	Hex
	lea	ZmianaCool,a0
	tst.l	d0
	beq	Skok1
	move.l	#3,d2
	bsr	PrintLine
	move.l	#1,ZMIANA
	bra	Skok1_1
Skok1:	move.l	#1,d2
	bsr	PrintLine
Skok1_1:
	move.l	ColdCapture(a6),d0
	lea	ZmianaCold+14,a0
	bsr	Hex
	lea	ZmianaCold,a0
	tst.l	d0
	beq	Skok2
	move.l	#3,d2
	bsr	PrintLine
	move.l	#1,ZMIANA
	bra	Skok2_1
Skok2:	move.l	#1,d2
	bsr	PrintLine
Skok2_1:
	move.l	WarmCapture(a6),d0
	lea	ZmianaWarm+14,a0
	bsr	Hex
	lea	ZmianaWarm,a0
	tst.l	d0
	beq	Skok3
	move.l	#3,d2
	bsr	PrintLine
	move.l	#1,ZMIANA
	bra	Skok3_1
Skok3:	move.l	#1,d2
	bsr	PrintLine
Skok3_1:
	move.l	KickTagPtr(a6),d0
	lea	ZmianaKickT+14,a0
	bsr	Hex
	lea	ZmianaKickT,a0
	tst.l	d0
	beq	Skok4
	move.l	#3,d2
	bsr	PrintLine
	move.l	#1,ZMIANA
	bra	Skok4_1
Skok4:	move.l	#1,d2
	bsr	PrintLine
Skok4_1:
	move.l	KickMemPtr(a6),d0
	lea	ZmianaKickM+14,a0
	bsr	Hex
	lea	ZmianaKickM,a0
	tst.l	d0
	beq	Skok5
	move.l	#3,d2
	bsr	PrintLine
	move.l	#1,ZMIANA
	bra	Skok5_1
Skok5:	move.l	#1,d2
	bsr	PrintLine
Skok5_1:
	tst.l	ZMIANA
	beq	OKWEKTOROK
	bsr	PrintLine0
	moveq	#2,d2
	lea	Wektory.err,a0
	bsr	PrintLine
	bra	Loop
OKWEKTOROK:
	moveq	#1,d2
	lea	_Wektory.txt,a0
	bsr	PrintLine
	bra	Loop

**************************

WektorASCII:
	lea	GADGETW.gad,a0
	lea	GADGETW.txt,a1
	bsr	ReqRequestGAD
	move.l	EXEC.W,a6
	move.l	CoolCapture(a6),d1
	cmp.l	#1,d0
	beq	OK_AsciiWektor
	move.l	ColdCapture(a6),d1
	cmp.l	#2,d0
	beq	OK_AsciiWektor
	move.l	WarmCapture(a6),d1
	cmp.l	#3,d0
	beq	OK_AsciiWektor
	move.l	KickTagPtr(a6),d1
	cmp.l	#4,d0
	beq	OK_AsciiWektor
	move.l	KickMemPtr(a6),d1
	cmp.l	#5,d0
	beq	OK_AsciiWektor
	bra	Loop
OK_AsciiWektor:
	tst.l	d1
	bne	OkNie0_Wek1
	lea	WektorJest0.txt,a1
	bsr	ReqRequest
	bra	Loop
OkNie0_Wek1:
	move.l	d1,a0
OK_AsciiWektor_1:
	move.l	#22,d2
Loop_PAscii:
	bsr	PrintAscii	
	adda.l	#64,a0
	dbra	d2,Loop_PAscii
	move.l	a0,a2
	move.l	#Kont.gad,a0
	move.l	#Kont.txt,a1
	bsr	ReqRequestGAD_1
	move.l	a2,a0
	tst.l	d0
	bne	OK_AsciiWektor_1
	bra	Loop

**************************

PrintAscii:			
	movem.l	d0-a6,-(sp)
	move.l	EXEC.W,a6
	move.l	#AsciiBuffor,a1
	move.l	#64,d0
	jsr	_LVOCopyMem(a6)
	lea	AsciiBuffor,a0
	move.l	#64-1,d1
	bsr	Conw
	move.l	#1,d2
	lea	AsciiBuffor,a0
	bsr	PrintLine
	movem.l	(sp)+,d0-a6
	rts

**************************

WektorHEX:
	lea	GADGETW.gad,a0
	lea	GADGETW.txt,a1
	bsr	ReqRequestGAD
	move.l	EXEC.W,a6
	move.l	CoolCapture(a6),d1
	cmp.l	#1,d0
	beq	OK_HexWektor
	move.l	ColdCapture(a6),d1
	cmp.l	#2,d0
	beq	OK_HexWektor
	move.l	WarmCapture(a6),d1
	cmp.l	#3,d0
	beq	OK_HexWektor
	move.l	KickTagPtr(a6),d1
	cmp.l	#4,d0
	beq	OK_HexWektor
	move.l	KickMemPtr(a6),d1
	cmp.l	#5,d0
	beq	OK_HexWektor
	bra	Loop
OK_HexWektor:
	tst.l	d1
	bne	OkNie0_Wek
	lea	WektorJest0.txt,a1
	bsr	ReqRequest
	bra	Loop
OkNie0_Wek:
	move.l	d1,a3
Loop_PH_0:
	move.l	EXEC.W,a6
	move.l	#Buffor_Roboczy,a1
	move.l	a3,a0
	move.l	#23*16,d0
	jsr	_LVOCopyMem(a6)
	move.l	#Buffor_Roboczy,a0
	move.l	#22,d2
Loop_PH:
	movem.l	d0-a6,-(sp)
	bsr	PrintHexMem
	movem.l	(sp)+,d0-a6
	adda.l	#16,a0
	adda.l	#16,a3
	dbra	d2,Loop_PH
	move.l	a0,a2
	move.l	#Kont.gad,a0
	move.l	#Kont.txt,a1
	bsr	ReqRequestGAD_1
	move.l	#22,d2
	tst.l	d0
	bne	Loop_PH_0
	bra	Loop

**************************

FreeLibrary_LABEL:
	tst.l	BIBLIOTEKA
	beq	BrakBibliotekiBOOT
	tst.w	Requstery
	beq	FreLib
	lea	TakNie.gad,a0
	lea	UWAGALib,a1
	bsr	ReqRequestGAD
	tst.l	d0
	beq	Loop
FreLib:
	bsr	FreeLibrary
	lea	BibliotekaUSU.txt,a0
	moveq	#1,d2
	bsr	PrintLine
	bra	Loop
BrakBibliotekiBOOT:
	lea	BrakBiblioteki,a1
	bsr	ReqRequest
	move.l	a1,a0
	moveq	#2,d2
	bsr	PrintLine
	bra	Loop

**************************

WriteLibrary:
	tst.l	BIBLIOTEKA
	bne	OkJestBiblioteka
	lea	BrakBiblioteki,a1
	bsr	ReqRequest
	move.l	a1,a0
	moveq	#2,d2
	bsr	PrintLine
	Bra	Loop
OkJestBiblioteka:
	move.l	DosBase,a6
	move.l	#LibraryName,d1
	move.l	#MODE_NEWFILE,d2
	jsr	_LVOOpen(a6)
	tst.l	d0
	bne	OkOpenLIB
	lea	WriteError.txt,a1
	bsr	ReqRequest
	moveq	#2,d2
	move.l	a1,a0
	bsr	PrintLine
	bra	Loop
OkOpenLIB:
	move.l	d0,d4
	move.l	d0,d1
	move.l	BIBLIOTEKA,d2
	move.l	LIBSIZE,d3
	jsr	_LVOWrite(a6)
	tst.l	d0
	bne	OkWriteLIB1
	lea	WriteError.txt,a1
	bsr	ReqRequest
	moveq	#2,d2
	move.l	a1,a0
	bsr	PrintLine
	move.l	DosBase,a6
	move.l	d4,d1
	jsr	_LVOClose(a6)
OkWriteLIB1:
	move.l	d4,d1
	jsr	_LVOClose(a6)
	moveq	#1,d2
	lea	OkWriteLib,a0
	bsr	PrintLine
	move.w	#0,BIBLIOTEKA_S
	bra	Loop

**************************

AddBootBlock:
	lea	Gadgety_BootB,a0
	lea	Text_BootBlock,a1
	bsr	ReqRequestGAD
	lea	Buffor_1,a1
	lea	StanBuffora_1,a0
	cmp.l	#1,d0
	beq	AddBootblock
	lea	Buffor_2,a1
	lea	StanBuffora_2,a0
	cmp.l	#2,d0
	beq	AddBootblock
	lea	Buffor_3,a1
	lea	StanBuffora_3,a0
	cmp.l	#3,d0
	beq	AddBootblock
	lea	Buffor_4,a1
	lea	StanBuffora_4,a0
	cmp.l	#4,d0
	beq	AddBootblock
	lea	Buffor_5,a1
	lea	StanBuffora_5,a0
	cmp.l	#5,d0
	beq	AddBootblock
	cmp.l	#6,d0
	beq	ReadBootAdd
	bra	QUIT_AB
AddBootblock:
	tst.l	(a0)			
	bne	OkBufforADD
	lea	BufforyError.txt,a1
	bsr	ReqRequest
	bra	Loop
OkBufforADD:	
	move.l	a1,A1_SAVE		
	tst.l	BIBLIOTEKA
	bne	ADDBB

	move.l	XVSBase,a6
	move.l	#XVSOBJ_BOOTINFO,d0
	jsr	_LVOxvsAllocObject(a6)		
	tst.l	d0
	bne	OkALLOK
	lea	AllocError.txt,a1
	jsr	ReqRequest
	bra	Loop
OkALLOK:move.l	d0,BootInfo

	move.l	XVSBase,a6			
	move.l	BootInfo,a0
	move.l	A1_SAVE,xvsbi_Bootblock(a0)
	jsr	_LVOxvsCheckBootblock(a6)
	cmp.l	#0,d0
	beq	OkNieznanyBoot_1
	cmp.l	#1,d0
	beq	NoDosDisk
	cmp.l	#2,d0
	beq	STANDARD13
	cmp.l	#3,d0
	beq	STANDARD20
	cmp.l	#4,d0
	beq	Wirus
	cmp.l	#5,d0
	beq	UnInstalled
OkNieznanyBoot_1:
	move.l	XVSBase,a6
	move.l	BootInfo,a1
	move.l	#0,a0
	jsr	_LVOxvsFreeObject(a6)	

	bsr	CzyVEBoot
	tst.l	d0
	beq	NieVEBoot2
	move.l	a0,a1
	bsr	ReqRequest
	moveq	#2,d2
	lea	VERozTB.txt,a0
	bsr	PrintLine
	bra	Loop
NieVEBoot2:

	move.l	ReqBase,a6			
	lea	_STRING,a1
	move.l	#30,d0
	bsr	CLR_STR				
	move.l	#WINDOWTITLE,a2
	move.l	#0,a3
	move.l	#TAGLIST_STRING,a0
	move.l	#TextATTR,3*4(a0)
	move.l	ScreenBase,1*4(a0)
	jsr	_LVORtGetStringA(a6)
	tst.l	d0
	beq	Loop
	lea	_STRING,a0
	move.b	(a0),d0
	tst.l	d0
	beq	Loop
					
	move.l	EXEC.W,a6
	move.l	#4+70+30,d0
	move.l	#MEMF_FAST,d1
	jsr	_LVOAllocMem(a6)
	tst.l	d0
	bne	OkAlloc_AB
	move.l	#4+70+30,d0
	move.l	#MEMF_CHIP,d1
	jsr	_LVOAllocMem(a6)
z	tst.l	d0
	bne	OkAlloc_AB
	lea	Memory.err,a1
	bsr	ReqRequest
	bra	QUIT_AB
OkAlloc_AB:
	move.l	d0,BIBLIOTEKA
	move.l	BIBLIOTEKA,a0
	move.l	#1,(a0)
	adda.l	#4,a0			

	lea	_STRING,a1		
	moveq	#30-1,d0		
Loop_CSTR:
	move.b	(a1)+,(a0)+
	dbra	d0,Loop_CSTR

	move.l	A1_SAVE,a1
	move.l	#70-1,d0
Loop_CBOOT:
	move.b	(a1)+,(a0)+
	dbra	d0,Loop_CBOOT
	move.l	#4+30+70,LIBSIZE	
	move.w	#1,BIBLIOTEKA_S
	move.l	#DodalemBoot.txt,a0
	moveq	#1,d2
	bsr	PrintLine
	bra	Loop
ADDBB:
	move.l	XVSBase,a6
	move.l	#XVSOBJ_BOOTINFO,d0
	jsr	_LVOxvsAllocObject(a6)		
	tst.l	d0
	bne	OkAllok
	lea	AllocError.txt,a1
	jsr	ReqRequest
	bra	Loop
OkAllok:move.l	d0,BootInfo

	move.l	XVSBase,a6			
	move.l	BootInfo,a0
	move.l	A1_SAVE,xvsbi_Bootblock(a0)
	jsr	_LVOxvsCheckBootblock(a6)
	cmp.l	#0,d0
	beq	OkNieznanyBoot_
	cmp.l	#1,d0
	beq	NoDosDisk
	cmp.l	#2,d0
	beq	STANDARD13
	cmp.l	#3,d0
	beq	STANDARD20
	cmp.l	#4,d0
	beq	Wirus
	cmp.l	#5,d0
	beq	UnInstalled
OkNieznanyBoot_:
	move.l	XVSBase,a6
	move.l	BootInfo,a1
	move.l	#0,a0
	jsr	_LVOxvsFreeObject(a6)	

	bsr	CzyVEBoot
	tst.l	d0
	beq	NieVEBoot1
	move.l	a0,a1
	bsr	ReqRequest
	moveq	#2,d2
	lea	VERozTB.txt,a0
	bsr	PrintLine
	bra	Loop
NieVEBoot1:

	bsr	CzyJestTakiBootBlock
	beq	Niema
	lea	JestBoot.txt,a1
	bsr	ReqRequest
	moveq	#2,d2
	move.l	a1,a0
	bsr	PrintLine
	bra	Loop
Niema:
	move.l	ReqBase,a6		
	lea	_STRING,a1
	move.l	#30,d0
	move.l	#WINDOWTITLE,a2
	move.l	#0,a3
	move.l	#TAGLIST_STRING,a0
	move.l	#TextATTR,3*4(a0)
	move.l	ScreenBase,1*4(a0)
	jsr	_LVORtGetStringA(a6)
	tst.l	d0
	beq	Loop
	lea	_STRING,a0
	move.b	(a0),d0
	tst.l	d0
	beq	Loop

	move.l	EXEC.W,a6
	move.l	LIBSIZE,d0
	add.l	#30+70,d0
	move.l	#MEMF_FAST,d1
	jsr	_LVOAllocMem(a6)
	tst.l	d0
	bne	OkAlloc_AB1
	move.l	LIBSIZE,d0
	add.l	#30+70,d0
	move.l	#MEMF_CHIP,d1
	jsr	_LVOAllocMem(a6)
	tst.l	d0
	bne	OkAlloc_AB1
	lea	Memory.err,a1
	bsr	ReqRequest
	bra	QUIT_AB
OkAlloc_AB1:
	move.l	BIBLIOTEKA,d7
	move.l	d0,BIBLIOTEKA	

	move.l	LIBSIZE,d1		
	subq	#1,d1
	move.l	d7,a0
	move.l	BIBLIOTEKA,a1
Loop_COPYLIB:
	move.b	(a0)+,(a1)+
	dbra	d1,Loop_COPYLIB

	movem.l	d0-a6,-(sp)
	move.l	EXEC.W,a6		
	move.l	d7,a1
	move.l	LIBSIZE,d0
	jsr	_LVOFreeMem(a6)
	movem.l	(sp)+,d0-a6

	move.l	BIBLIOTEKA,a2
	add.l	#1,(a2)			

	lea	_STRING,a0		
	move.l	#30-1,d0
Loop_COSTR:
	move.b	(a0)+,(a1)+
	dbra	d0,Loop_COSTR

	move.l	A1_SAVE,a0		
	move.l	#70-1,d0
Loop_COB:
	move.b	(a0)+,(a1)+
	dbra	d0,Loop_COB
	add.l	#100,LIBSIZE		
	move.w	#1,BIBLIOTEKA_S
	move.l	#DodalemBoot.txt,a0
	moveq	#1,d2
	bsr	PrintLine
QUIT_AB:bra	Loop

*****************************

CzyJestTakiBootBlock:
	movem.l	d0-a6,-(sp)
	move.l	A1_SAVE,a1
	move.l	BIBLIOTEKA,a0
	move.l	(a0)+,d0		
	sub.l	#1,d0
	bra	OK_OD
Test_LooP:
	tst.l	d4
	beq	TAKISAM
OK_OD:	adda.l	#30,a0
	move.l	A1_SAVE,a1
	move.l	#70-1,d1
	moveq	#0,d4
Test_LoOP:
	move.b	(a0)+,d2
	move.b	(a1)+,d3
	cmp.b	d2,d3
	beq	OK_J
	moveq	#1,d4
OK_J:
	dbra	d1,Test_LoOP
	dbra	d0,Test_LooP
	tst.l	d4
	beq	TAKISAM
	movem.l	(sp)+,d0-a6
	moveq	#0,d0
	rts

TAKISAM:
	suba.l	#100,a0
	move.l	a0,BOOTNAME
	movem.l	(sp)+,d0-a6
	moveq	#1,d0
	rts
	
*****************************

ReadBootAdd:
	lea	Buffor_Roboczy,a0
	bsr	ReadBoot
	beq	OkNotError_ADD
	lea	ReadError,a1
	bsr	ReqRequest
	moveq	#2,d2
	move.l	a1,a0
	bsr	PrintLine
	bra	Loop
OkNotError_ADD:
	lea	BootBlockOK.txt,a0
	moveq	#1,d2
	bsr	PrintLine
	lea	Buffor_Roboczy,a1
	bra	OkBufforADD

**************************

LoadLibrary_MENU:
	bsr	LoadLibrary
	bra	Loop

LoadLibrary:
	movem.l	d0-a6,-(sp)
	tst.l	_ICONIFY
	bne	QUIT_LL
	tst.w	BIBLIOTEKA_S
	beq	OkWCZYTUJ
	lea	GadgetTAKNIE,a0
	lea	UWAGALib,a1
	bsr	ReqRequestGAD
	tst.l	d0
	beq	QUIT_LL
OkWCZYTUJ:
	move.l	#LibraryName,d0
	bsr	SIZE
	tst.l	d0
	beq	CantOpenLIB
	move.l	d0,LIBSIZE
	move.l	EXEC.W,a6		
	move.l	LIBSIZE,d0
	move.l	#MEMF_FAST,d1
	jsr	_LVOAllocMem(a6)
	tst.l	d0
	bne	OKAlloc
	move.l	LIBSIZE,d0
	move.l	#MEMF_CHIP,d1
	jsr	_LVOAllocMem(a6)
	tst.l	d0
	bne	OKAlloc
	lea	Memory.err,a1
	bsr	ReqRequest
	bra	QUIT_LL
OKAlloc:move.l	d0,BIBLIOTEKA

	move.l	DosBase,a6		
	move.l	#LibraryName,d1
	move.l	#MODE_OLDFILE,d2
	jsr	_LVOOpen(a6)
	tst.l	d0
	beq	FileError_LL
	move.l	d0,d7
	move.l	d0,d1
	move.l	BIBLIOTEKA,d2
	move.l	LIBSIZE,d3
	jsr	_LVORead(a6)
	tst.l	d0
	beq	FileError_LL_C
	move.l	DosBase,a6
	move.l	d7,d1
	jsr	_LVOClose(a6)

	move.l	BIBLIOTEKA,a0
	move.l	(a0),d0
	move.l	d0,d1
	mulu.l	#100,d1
	add.l	#4,d1
	cmp.l	LIBSIZE,d1
	beq	OkLIBRARY
	moveq	#2,d2
	lea	OnLib.txt,a0
	bsr	PrintLine
	bra	ERRLIB
OkLIBRARY:
					
	moveq	#1,d2
	lea	OkLibRead,a0
	bsr	PrintLine
	bra	QUIT_LL
FileError_LL_C:				
	move.l	DosBase,a6
	move.l	d7,d1
	jsr	_LVOClose(a6)
FileError_LL:
	lea	LibOpenERR,a1
	bsr	ReqRequest
ERRLIB:	bsr	FreeLibrary
	bra	QUIT_LL
CantOpenLIB:
	lea	LibOpen.err,a1
	bsr	ReqRequest
QUIT_LL:movem.l	(sp)+,d0-a6
	rts

***************************

FreeLibrary:
	movem.l	d0-a6,-(sp)
	tst.l	BIBLIOTEKA
	beq	QUIT_FL
	tst.l	ICONIFY
	bne	QUIT_FL
	move.l	EXEC.W,a6
	move.l	LIBSIZE,d0
	move.l	BIBLIOTEKA,a1
	jsr	_LVOFreeMem(a6)
	move.l	#0,BIBLIOTEKA
	move.w	#0,BIBLIOTEKA_S
	move.l	#0,LIBSIZE
QUIT_FL:movem.l	(sp)+,d0-a6
	rts

***************************

SIZE:				
	movem.l	d1-a6,-(sp)
	move.l	DosBase,a6
	move.l	d0,d1
	move.l	#MODE_OLDFILE,d2
	jsr	_LVOOpen(a6)
	tst.l	d0
	beq.b	ErrorKoniecFS
	move.l	d0,d7
	move.l	d0,d1
	move.l	DosBase,a6		
	moveq	#0,d2
	move.l	#1,d3
	jsr	_LVOSeek(a6)
	move.l	d7,d1
	moveq	#0,d2
	moveq	#1,d3
	jsr	_LVOSeek(a6)			
	move.l	d0,d6
	move.l	d7,d1
	jsr	_LVOClose(a6)
	move.l	d6,d0
	movem.l	(sp)+,d1-a6
	rts
ErrorKoniecFS:
	movem.l	(sp)+,d1-a6
	moveq	#0,d0
	rts

**************************

CreateGadgetDRIVE:			
	movem.l	d0-a6,-(sp)
	lea	MX_TAGLIST,a0
	move.w	DRIVE_NR,6(a0)
	movem.l	(sp)+,d0-a6
	rts

CreateGadgetCHB:			
	movem.l	d0-a6,-(sp)
	lea	TAGLISTMX1,a0
	move.w	Requstery,6(a0)
	lea	TAGLISTMX2,a0
	move.w	TestDrive,6(a0)
	lea	TAGLISTMX3,a0
	move.w	KillWirus,6(a0)
	movem.l	(sp)+,d0-a6
	rts

**************************

GROZNY		dc.l	0

TextWirus:	dc.b	'Wirus = '
BufforWirus:		blk.b	12

TextIntro:	dc.b	'Intro = '
BufforIntro:	blk.b	12

TextLoader:	dc.b	'Loader = '
BufforLoader:	blk.b	12

TextFormat:	dc.b	'Formatowanie dysku = '
BufforFormat:	blk.b	12

TextZapis:	dc.b	'Zapis bootblocku = '
BufforZapis:	blk.b	12

TextAntyWirus:	dc.b	'AntyWirus = '
BufforAntyWirus:blk.b	12

Grozny0.txt	dc.b	'Nieszkodliwy bootblock...',0
Grozny1.txt:	dc.b	'Nie wygl?da zbyt gro?nie...',0
Grozny2.txt:	dc.b	'Mo?e by? gro?ny...',0
Grozny3.txt:	dc.b	'Wygl?da dosy? gro?nie...',0
Grozny4.txt:	dc.b	'Wygl?da gro?nie...',0
Grozny5.txt:	dc.b	'UWAGA !!! Wygl?da bardzo gro?nie...',0
 even

Analizuj:
	move.l	#0,WIRUS
	move.l	#0,ANTYWIRUS
	move.l	#0,LOADER
	move.l	#0,INTRO
	move.l	#0,ZAPIS
	move.l	#0,WIRUS_FORMAT
	move.l	#0,MOJ
	lea	Analiza.gad,a0
	lea	Analizuj.txt,a1
	jsr	ReqRequestGAD
	tst.l	d0
	beq	Loop
	cmp.l	#1,d0
	beq	Analizuj_2		
	cmp.l	#2,d0
	beq	Analizuj_1		
Analizuj_Back:
	bsr	PrintLine0		

	lea	BufforWirus,a1
	move.l	WIRUS,d0
	move.l	#0,d7
	bsr	Conwert
	lea	TextWirus,a0
	moveq	#1,d2
	bsr	PrintLine

	lea	BufforIntro,a1
	move.l	INTRO,d0
	move.l	#0,d7
	bsr	Conwert
	lea	TextIntro,a0
	moveq	#1,d2
	bsr	PrintLine

	lea	BufforAntyWirus,a1
	move.l	ANTYWIRUS,d0
	move.l	#0,d7
	bsr	Conwert
	lea	TextAntyWirus,a0
	moveq	#1,d2
	bsr	PrintLine

	lea	BufforLoader,a1
	move.l	LOADER,d0
	move.l	#0,d7
	bsr	Conwert
	lea	TextLoader,a0
	moveq	#1,d2
	bsr	PrintLine

	lea	BufforZapis,a1
	move.l	ZAPIS,d0
	move.l	#0,d7
	bsr	Conwert
	lea	TextZapis,a0
	moveq	#1,d2
	bsr	PrintLine

	lea	BufforFormat,a1
	move.l	WIRUS_FORMAT,d0
	move.l	#0,d7
	bsr	Conwert
	lea	TextFormat,a0
	moveq	#1,d2
	bsr	PrintLine

	bsr	CzyGrozny

	bsr	PrintLine0
	move.l	#1,d2
	lea	KoniecAnalizuj.txt,a0
	bsr	PrintLine
	bra	Loop

CzyGrozny:
	move.l	#0,GROZNY
	tst.l	WIRUS
	beq	.jmp
	move.l	WIRUS,d0
	add.l	d0,GROZNY
.jmp	tst.l	ZAPIS
	beq	.jmp1
	add.l	#5,GROZNY
.jmp1	tst.l	ANTYWIRUS
	beq	.jmp2
	sub.l	#1,GROZNY
.jmp2	tst.l	WIRUS_FORMAT
	beq	.jmp3
	add.l	#5,GROZNY
.jmp3	tst.l	MOJ
	beq	.jmp4
	move.l	#0,GROZNY
.jmp4
	cmp.l	#0,GROZNY
	bgt	.jmp5
	move.l	#0,GROZNY
.jmp5
	cmp.l	#0,GROZNY
	bne	.jmp6
	lea	Grozny0.txt,a0
	bra	Pisz
.jmp6	cmp.l	#1,GROZNY
	bne	.jmp7
	lea	Grozny1.txt,a0
	bra	Pisz
.jmp7	cmp.l	#2,GROZNY
	bne	.jmp8
	lea	Grozny2.txt,a0
	bra	Pisz
.jmp8	cmp.l	#3,GROZNY
	bne	.jmp9
	lea	Grozny3.txt,a0
	bra	Pisz
.jmp9	cmp.l	#4,GROZNY
	bne	.jmp10
	lea	Grozny4.txt,a0
	bra	Pisz
.jmp10	lea	Grozny4.txt,a0
	bra	Pisz
Pisz:

	bsr	PrintLine0
	move.l	a0,a1
	moveq	#1,d2
	bsr	PrintLine
	rts

Analizuj_1:
	lea	Gadgety_BootB,a0
	lea	Text_BootBlock,a1
	bsr	ReqRequestGAD
	lea	Buffor_1,a1
	lea	StanBuffora_1,a0
	cmp.l	#1,d0
	beq	OkAna_START1
	lea	Buffor_2,a1
	lea	StanBuffora_2,a0
	cmp.l	#2,d0
	beq	OkAna_START1
	lea	Buffor_3,a1
	lea	StanBuffora_3,a0
	cmp.l	#3,d0
	beq	OkAna_START1
	lea	Buffor_4,a1
	lea	StanBuffora_4,a0
	cmp.l	#4,d0
	beq	OkAna_START1
	lea	Buffor_5,a1
	lea	StanBuffora_5,a0
	cmp.l	#5,d0
	beq	OkAna_START1
	cmp.l	#6,d0
	beq	ReadBootAna1
	bra	Loop

OkAna_START1:				
	tst.l	(a0)
	bne	OkBufforZap_Ana1
	lea	BufforyError.txt,a1
	bsr	ReqRequest
	bra	Loop
OkBufforZap_Ana1:
	bsr	PrintLine0		
	lea	Analiza.txt,a0	
	moveq	#1,d2		
	bsr	PrintLine		
	bsr	PrintLine0		
	movem.l	d0-a6,-(sp)	
	lea	Dos_STR,a0		
	bsr	Analizuj_PROC	
	lea	Gr_STR,a0		
	bsr	Analizuj_PROC	
	lea	Init_STR,a0		
	bsr	Analizuj_PROC	
	lea	Exp_STR,a0		
	bsr	Analizuj_PROC	
	lea	TAS_STR,a0		
	bsr	Analizuj_PROC	
	movem.l	(sp)+,d0-a6
	move.l	#1024-1,d5		
Analizuj_LOOP_1024:
	move.b	(a1),d0			
	lea	TrackD_STR,a0
	bsr	Analizuj_K_PROC		
	lea	DoIo_STR,a0
	bsr	Analizuj_K_PROC
	lea	Dal_STR,a0
	bsr	Analizuj_K_PROC
	lea	Fre_STR,a0
	bsr	Analizuj_K_PROC
	lea	Alm_STR,a0
	bsr	Analizuj_K_PROC
	lea	Alr_STR,a0
	bsr	Analizuj_K_PROC
	lea	Opf_STR,a0
	bsr	Analizuj_K_PROC
	lea	Fal_STR,a0
	bsr	Analizuj_K_PROC
	lea	Opl_STR,a0
	bsr	Analizuj_K_PROC
	lea	Cll_STR,a0
	bsr	Analizuj_K_PROC
	lea	LMB_STR,a0
	bsr	Analizuj_K_PROC
	lea	RMB_STR,a0
	bsr	Analizuj_K_PROC
	lea	rmb_STR,a0
	bsr	Analizuj_K_PROC
	lea	KEY_STR,a0
	bsr	Analizuj_K_PROC
	lea	COLOR_0,a0
	bsr	Analizuj_K_PROC
	lea	BLT_STR,a0
	bsr	Analizuj_K_PROC
	lea	BPL_STR,a0
	bsr	Analizuj_K_PROC
	lea	MOUSE_STR,a0
	bsr	Analizuj_K_PROC
	lea	Cool_STR,a0		
	bsr	Analizuj_K_PROC
	lea	Cold_STR,a0
	bsr	Analizuj_K_PROC
	lea	Warm_STR,a0
	bsr	Analizuj_K_PROC
	lea	KickT_STR,a0
	bsr	Analizuj_K_PROC
	lea	KickM_STR,a0
	bsr	Analizuj_K_PROC
	lea	CLR_Cool_STR,a0		
	bsr	Analizuj_K_PROC
	lea	CLR_Cold_STR,a0
	bsr	Analizuj_K_PROC
	lea	CLR_Warm_STR,a0
	bsr	Analizuj_K_PROC
	lea	CLR_KickT_STR,a0
	bsr	Analizuj_K_PROC
	lea	CLR_KickM_STR,a0
	bsr	Analizuj_K_PROC
	lea	RESET_STR,a0
	bsr	Analizuj_K_PROC
	lea	RES_STR,a0
	bsr	Analizuj_K_PROC
	lea	Zmiana_Cold,a0	
	lea	Zmiana_Cold_BUF,a2
	bsr	Analizuj_K_PROC1
	lea	Zmiana_Cool,a0
	lea	Zmiana_Cool_BUF,a2
	bsr	Analizuj_K_PROC1
	lea	Zmiana_Warm,a0
	lea	Zmiana_Warm_BUF,a2
	bsr	Analizuj_K_PROC1
	lea	Zmiana_KickT,a0
	lea	Zmiana_KickT_BUF,a2
	bsr	Analizuj_K_PROC1
	lea	Zmiana_KickM,a0
	lea	Zmiana_KickM_BUF,a2
	bsr	Analizuj_K_PROC1
	lea	Zmiana_DoIO,a0
	lea	Zmiana_DoIO_BUF,a2
	bsr	Analizuj_K_PROC1
	lea	DoIOLength,a0		
	lea	DoIOLength_BUF,a2
	bsr	Analizuj_K_PROC1
	lea	DoIOData,a0
	lea	DoIOData_BUF,a2
	bsr	Analizuj_K_PROC1
	lea	DoIOOffset,a0
	lea	DoIOOffset_BUF,a2
	bsr	Analizuj_K_PROC1
	lea	IoCOM1_STR,a0		
	bsr	Analizuj_K_PROC
	lea	IoCOM2_STR,a0
	bsr	Analizuj_K_PROC
	lea	IoCOM3_STR,a0
	bsr	Analizuj_K_PROC
	lea	IoCOM4_STR,a0
	bsr	Analizuj_K_PROC
	lea	IoCOM5_STR,a0
	bsr	Analizuj_K_PROC
	lea	IoCOM6_STR,a0
	bsr	Analizuj_K_PROC
	lea	IoCOM7_STR,a0
	bsr	Analizuj_K_PROC
	lea	IoCOM8_STR,a0
	bsr	Analizuj_K_PROC
	lea	IoCOM9_STR,a0
	bsr	Analizuj_K_PROC
	lea	IoCOM10_STR,a0
	bsr	Analizuj_PROC
	lea	IoCOM11_STR,a0
	bsr	Analizuj_K_PROC
	lea	IoCOM12_STR,a0
	bsr	Analizuj_K_PROC
	lea	IoCOM13_STR,a0
	bsr	Analizuj_K_PROC
	lea	IoCOM14_STR,a0
	bsr	Analizuj_K_PROC
	lea	IoCOM15_STR,a0
	bsr	Analizuj_K_PROC
	lea	IoCOM16_STR,a0
	bsr	Analizuj_K_PROC
	lea	IoCOM17_STR,a0
	bsr	Analizuj_K_PROC
	lea	IoCOM18_STR,a0
	bsr	Analizuj_K_PROC
	lea	IoCOM19_STR,a0
	bsr	Analizuj_K_PROC
	lea	IoCOM20_STR,a0
	bsr	Analizuj_K_PROC
	lea	IoCOM21_STR,a0
	bsr	Analizuj_K_PROC
	lea	IoCOM22_STR,a0
	bsr	Analizuj_K_PROC
	adda.l	#1,a1
	dbra	d5,Analizuj_LOOP_1024
	bra	Analizuj_Back

Analizuj_K_PROC1:
	movem.l	d0-a6,-(sp)
	move.l	a2,A1_SAVE
	move.l	a1,a2
	moveq	#0,d5
	move.l	(a0)+,a3
	move.b	(a0)+,d5
	bsr	TEST_PROC1
	tst.l	d0
	beq	EXIT_A2
	movem.l	a0/d0,-(sp)
	move.l	LICZBA,d0
	move.l	A1_SAVE,a0
	bsr	Hex
	movem.l	(sp)+,a0/d0
	adda.l	d5,a0
	move.l	#1,d3
	bsr	PrintLine
	cmpa.l	#0,a3
	beq	.jmp
	add.l	#1,(a3)
.jmp:
EXIT_A2:movem.l	(sp)+,d0-a6
	rts

Analizuj_K_PROC:
	movem.l	d0-a6,-(sp)
	move.l	a1,a2
	moveq	#0,d5
	move.l	(a0)+,a3
	move.b	(a0)+,d5
	bsr	TEST_PROC
	tst.l	d0
	beq	EXIT_A1
	adda.l	d5,a0
	move.l	#1,d3
	bsr	PrintLine
	cmpa.l	#0,a3
	beq	.jmp
	add.l	#1,(a3)
.jmp:
EXIT_A1:movem.l	(sp)+,d0-a6
	rts


ReadBootAna1:
	lea	Buffor_Roboczy,a0
	bsr	ReadBoot
	beq	OkNotError_AN1
	lea	ReadError,a1
	bsr	ReqRequest
	moveq	#2,d2
	move.l	a1,a0
	bsr	PrintLine
	bra	Loop
OkNotError_AN1:
	lea	BootBlockOK.txt,a0
	moveq	#1,d2
	bsr	PrintLine
	lea	Buffor_Roboczy,a1
	bra	OkBufforZap_Ana1

Analizuj_PROC1:			
	movem.l	d0-a6,-(sp)	
	move.l	a2,A1_SAVE
	move.l	a0,a4
	add.l	#4,a4
	move.l	(a0)+,a3
	move.b	(a0)+,d5	
	move.b	(a0),d4		
	moveq	#0,d3		
Search_LOOP:			
	addq.l	#1,d3
	cmp.l	#1024,d3
	beq	Koniec_LET
	move.b	(a1)+,d0	
	cmp.b	d4,d0		
	bne	Search_LOOP	
	suba.l	#1,a1		
	move.l	a1,a2
	bsr	TEST_PROC1
	tst.l	d0
	beq	Search_LOOP
	move.l	LICZBA,d0
	move.l	A1_SAVE,a0
	bsr	Hex
	move.l	a4,a0
	adda.l	d5,a0
	adda.l	#1,a0
	move.l	#1,d2
	bsr	PrintLine
	cmpa.l	#0,a3
	beq	.jmp
	add.l	#1,(a3)
.jmp:
	movem.l	(sp)+,d0-a6
	moveq	#0,d0
	rts
Koniec_LET:
	movem.l	(sp)+,d0-a6
	moveq	#-1,d0
	rts

TEST_PROC1:			
	movem.l	d0-a6,-(sp)
	sub.l	#2,d5
Test_LOOP1:
	move.b	(a0)+,d0
	move.b	(a2)+,d1
	cmp.b	#-1,d0
	bne	NieUjemny
	suba.l	#1,a2
	move.b	(a2)+,ANAL
	move.b	(a2)+,ANAL+1
	move.b	(a2)+,ANAL+2
	move.b	(a2)+,ANAL+3
	move.l	ANAL,LICZBA
	move.b	(a2)+,d1
	move.b	(a0)+,d0
NieUjemny:
	cmp.b	d0,d1
	bne	NieMa_L1
	dbra	d5,Test_LOOP1
	movem.l	(sp)+,d0-a6
	moveq	#1,d0
	rts
NieMa_L1:
	movem.l	(sp)+,d0-a6
	adda.l	#1,a1
	moveq	#0,d0
	rts

ANAL:	dc.l	0
LICZBA:	dc.l	0
KoniecAnalizuj.txt:	dc.b	'Koniec analizy !!!',0
 even


Analizuj_2:
	lea	Gadgety_BootB,a0
	lea	Text_BootBlock,a1
	bsr	ReqRequestGAD
	lea	Buffor_1,a1
	lea	StanBuffora_1,a0
	cmp.l	#1,d0
	beq	OkAna_START
	lea	Buffor_2,a1
	lea	StanBuffora_2,a0
	cmp.l	#2,d0
	beq	OkAna_START
	lea	Buffor_3,a1
	lea	StanBuffora_3,a0
	cmp.l	#3,d0
	beq	OkAna_START
	lea	Buffor_4,a1
	lea	StanBuffora_4,a0
	cmp.l	#4,d0
	beq	OkAna_START
	lea	Buffor_5,a1
	lea	StanBuffora_5,a0
	cmp.l	#5,d0
	beq	OkAna_START
	cmp.l	#6,d0
	beq	ReadBootAna
	bra	Loop

OkAna_START:
	tst.l	(a0)
	bne	OkBufforZap_Ana
	lea	BufforyError.txt,a1
	bsr	ReqRequest
	bra	Loop
OkBufforZap_Ana:
	bsr	PrintLine0
	lea	Analiza.txt,a0
	moveq	#1,d2
	bsr	PrintLine
	bsr	PrintLine0
	lea	Library.txt,a0
	moveq	#3,d2
	bsr	PrintLine		
	lea	Dos_STR,a0
	bsr	Analizuj_PROC
	lea	Gr_STR,a0
	bsr	Analizuj_PROC
	lea	Init_STR,a0
	bsr	Analizuj_PROC
	lea	Exp_STR,a0
	bsr	Analizuj_PROC
	lea	Funkcje.txt,a0
	moveq	#3,d2
	bsr	PrintLine		
	lea	DoIo_STR,a0
	bsr	Analizuj_PROC
	lea	Dal_STR,a0
	bsr	Analizuj_PROC
	lea	Fre_STR,a0
	bsr	Analizuj_PROC
	lea	Alm_STR,a0
	bsr	Analizuj_PROC
	lea	Alr_STR,a0
	bsr	Analizuj_PROC
	lea	Opf_STR,a0
	bsr	Analizuj_PROC
	lea	Fal_STR,a0
	bsr	Analizuj_PROC
	lea	Opl_STR,a0
	bsr	Analizuj_PROC
	lea	Cll_STR,a0
	bsr	Analizuj_PROC
	lea	Hardware.txt,a0
	moveq	#3,d2
	bsr	PrintLine		
	lea	LMB_STR,a0
	bsr	Analizuj_PROC
	lea	RMB_STR,a0
	bsr	Analizuj_PROC
	lea	rmb_STR,a0
	bsr	Analizuj_PROC
	lea	KEY_STR,a0
	bsr	Analizuj_PROC
	lea	COLOR_0,a0
	bsr	Analizuj_PROC
	lea	BLT_STR,a0
	bsr	Analizuj_PROC
	lea	BPL_STR,a0
	bsr	Analizuj_PROC
	lea	MOUSE_STR,a0
	bsr	Analizuj_PROC
	lea	Wektory.txt,a0
	moveq	#3,d2
	bsr	PrintLine		
	lea	Cool_STR,a0
	bsr	Analizuj_PROC
	lea	Cold_STR,a0
	bsr	Analizuj_PROC
	lea	Warm_STR,a0
	bsr	Analizuj_PROC
	lea	KickT_STR,a0
	bsr	Analizuj_PROC
	lea	KickM_STR,a0
	bsr	Analizuj_PROC
	lea	CLR_Cool_STR,a0
	bsr	Analizuj_PROC
	lea	CLR_Cold_STR,a0
	bsr	Analizuj_PROC
	lea	CLR_Warm_STR,a0
	bsr	Analizuj_PROC
	lea	CLR_KickT_STR,a0
	bsr	Analizuj_PROC
	lea	CLR_KickM_STR,a0
	bsr	Analizuj_PROC
	lea	Zmiana_Cold,a0		
	lea	Zmiana_Cold_BUF,a2	
	bsr	Analizuj_PROC1		
	lea	Zmiana_Cool,a0
	lea	Zmiana_Cool_BUF,a2
	bsr	Analizuj_PROC1
	lea	Zmiana_Warm,a0
	lea	Zmiana_Warm_BUF,a2
	bsr	Analizuj_PROC1
	lea	Zmiana_KickT,a0
	lea	Zmiana_KickT_BUF,a2
	bsr	Analizuj_PROC1
	lea	Zmiana_KickM,a0
	lea	Zmiana_KickM_BUF,a2
	bsr	Analizuj_PROC1
	lea	Zmiana_DoIO,a0
	lea	Zmiana_DoIO_BUF,a2
	bsr	Analizuj_PROC1
	lea	Inne.txt,a0
	moveq	#3,d2
	bsr	PrintLine		
	lea	RESET_STR,a0
	bsr	Analizuj_PROC
	lea	RES_STR,a0
	bsr	Analizuj_PROC
	lea	DoIOLength,a0		
	lea	DoIOLength_BUF,a2	
	bsr	Analizuj_PROC1		
	lea	DoIOData,a0
	lea	DoIOData_BUF,a2
	bsr	Analizuj_PROC1
	lea	DoIOOffset,a0
	lea	DoIOOffset_BUF,a2
	bsr	Analizuj_PROC1
	lea	IoCOM1_STR,a0
	bsr	Analizuj_PROC
	lea	IoCOM2_STR,a0
	bsr	Analizuj_PROC
	lea	IoCOM3_STR,a0
	bsr	Analizuj_PROC
	lea	IoCOM4_STR,a0
	bsr	Analizuj_PROC
	lea	IoCOM5_STR,a0
	bsr	Analizuj_PROC
	lea	IoCOM6_STR,a0
	bsr	Analizuj_PROC
	lea	IoCOM7_STR,a0
	bsr	Analizuj_PROC
	lea	IoCOM8_STR,a0
	bsr	Analizuj_PROC
	lea	IoCOM9_STR,a0
	bsr	Analizuj_PROC
	lea	IoCOM10_STR,a0
	bsr	Analizuj_PROC
	lea	IoCOM11_STR,a0
	bsr	Analizuj_PROC
	lea	IoCOM12_STR,a0
	bsr	Analizuj_PROC
	lea	IoCOM13_STR,a0
	bsr	Analizuj_PROC
	lea	IoCOM14_STR,a0
	bsr	Analizuj_PROC
	lea	IoCOM15_STR,a0
	bsr	Analizuj_PROC
	lea	IoCOM16_STR,a0
	bsr	Analizuj_PROC
	lea	IoCOM17_STR,a0
	bsr	Analizuj_PROC
	lea	IoCOM18_STR,a0
	bsr	Analizuj_PROC
	lea	IoCOM19_STR,a0
	bsr	Analizuj_PROC
	lea	IoCOM20_STR,a0
	bsr	Analizuj_PROC
	lea	IoCOM21_STR,a0
	bsr	Analizuj_PROC
	lea	IoCOM22_STR,a0
	bsr	Analizuj_PROC
	bra	Analizuj_Back

Analizuj_PROC:
	movem.l	d0-a6,-(sp)	
	move.l	a0,a4
	add.l	#4,a4
	move.l	(a0)+,a3
	move.b	(a0)+,d5	
	move.b	(a0),d4		
	moveq	#0,d3		
Search_LOOP1:			
	addq.l	#1,d3
	cmp.l	#1024,d3
	beq	Koniec_LET1
	move.b	(a1)+,d0	
	cmp.b	d4,d0		
	bne	Search_LOOP1	
	suba.l	#1,a1		
	move.l	a1,a2
	bsr	TEST_PROC
	tst.l	d0
	beq	Search_LOOP1
	move.l	a4,a0
	adda.l	d5,a0
	adda.l	#1,a0
	move.l	#1,d2
	bsr	PrintLine
	cmpa.l	#0,a3
	beq	.jmp
	add.l	#1,(a3)
.jmp:
	movem.l	(sp)+,d0-a6
	moveq	#0,d0
	rts
Koniec_LET1:
	movem.l	(sp)+,d0-a6
	moveq	#-1,d0
	rts

TEST_PROC:			
	movem.l	d0-a6,-(sp)
	sub.l	#1,d5
Test_LOOP:
	move.b	(a0)+,d0
	move.b	(a2)+,d1
	cmp.b	d0,d1
	bne	NieMa_L
	dbra	d5,Test_LOOP
	movem.l	(sp)+,d0-a6
	moveq	#1,d0
	rts
NieMa_L:
	movem.l	(sp)+,d0-a6
	adda.l	#1,a1
	moveq	#0,d0
	rts

ReadBootAna:
	lea	Buffor_Roboczy,a0
	bsr	ReadBoot
	beq	OkNotError_AN
	lea	ReadError,a1
	bsr	ReqRequest
	moveq	#2,d2
	move.l	a1,a0
	bsr	PrintLine
	bra	Loop
OkNotError_AN:
	lea	BootBlockOK.txt,a0
	moveq	#1,d2
	bsr	PrintLine
	lea	Buffor_Roboczy,a1
	bra	OkBufforZap_Ana

**************************

HexRead:
	lea	Gadgety_BootB,a0
	lea	Text_BootBlock,a1
	bsr	ReqRequestGAD
	lea	Buffor_1,a0
	lea	StanBuffora_1,a1
	cmp.l	#1,d0
	beq	OkHex_START
	lea	Buffor_2,a0
	lea	StanBuffora_2,a1
	cmp.l	#2,d0
	beq	OkHex_START
	lea	Buffor_3,a0
	lea	StanBuffora_3,a1
	cmp.l	#3,d0
	beq	OkHex_START
	lea	Buffor_4,a0
	lea	StanBuffora_4,a1
	cmp.l	#4,d0
	beq	OkHex_START
	lea	Buffor_5,a0
	lea	StanBuffora_5,a1
	cmp.l	#5,d0
	beq	OkHex_START
	cmp.l	#6,d0
	beq	ReadBootHex
	bra	Loop

OkHex_START:
	tst.l	(a1)
	bne	OkBufforZap_HEX
	lea	BufforyError.txt,a1
	bsr	ReqRequest
	bra	Loop
OkBufforZap_HEX:
	cmp.l	#Buffor_Roboczy,a0
	beq	Ok_NoCopyHEX
	lea	Buffor_Roboczy,a1	
	move.l	#(1024/4)-1,d0
CopRobHEX.LOOP:
	move.l	(a0)+,(a1)+
	dbra	d0,CopRobHEX.LOOP
	lea	Buffor_Roboczy,a0
Ok_NoCopyHEX:
	move.l	#(16+7)-1,d0
PrintLoop:
	bsr	PrintHexMem		
	adda.l	#16,a0
	dbra	d0,PrintLoop
	move.l	a0,a2
	lea	Kont.gad,a0
	lea	Kont.txt,a1
	bsr	ReqRequestGAD_1
	tst.l	d0
	beq	Loop
	move.l	#(16+7)-1,d0
	move.l	a2,a0
PrintLoop_1:
	bsr	PrintHexMem		
	adda.l	#16,a0
	dbra	d0,PrintLoop_1
	move.l	a0,a2
	lea	Kont.gad,a0
	lea	Kont.txt,a1
	bsr	ReqRequestGAD_1
	tst.l	d0
	beq	Loop
	move.l	#(16+2)-1,d0
	move.l	a2,a0
PrintLoop_2:
	bsr	PrintHexMem		
	adda.l	#16,a0
	dbra	d0,PrintLoop_2
	bra	Loop

PrintHexMem:			
	movem.l	d0-a6,-(sp)
	move.l	a0,a1
	move.l	a0,a2
	move.l	(a1)+,d0
	lea	Hex_Buffor,a0
	bsr	_Hex_
	adda.l	#8,a0
	move.b	#' ',(a0)+
	move.l	(a1)+,d0
	bsr	_Hex_
	adda.l	#8,a0
	move.b	#' ',(a0)+
	move.l	(a1)+,d0
	bsr	_Hex_
	adda.l	#8,a0
	move.b	#' ',(a0)+
	move.l	(a1)+,d0
	bsr	_Hex_
	adda.l	#8,a0
	move.b	#' ',(a0)+
	move.b	#'"',(a0)+
	move.l	a0,a3
	move.l	a2,a0
	move.l	#16-1,d1
	bsr	Conw

	move.l	#16-1,d0
ConwCopyLoop:
	move.b	(a2)+,(a3)+
	dbra	d0,ConwCopyLoop
	move.b	#'"',(a3)+
	move.b	#0,(a3)

	lea	Hex_Buffor,a0
	moveq	#1,d2
	bsr	PrintLine
	movem.l	(sp)+,d0-a6
	rts

_Hex_:	movem.l	d0-a6,-(sp)	
	moveq	#0,d1
	move.l	d0,d6
	rol.l	#4,d6
	move.l	#7,d5
_LoopHex:
	move.b	d6,d1
	and.b	#$0F,d1
	cmpi.b	#$9,d1
	ble	_SkokHex
	add.b	#$37,d1	
	bra	_Min9
_SkokHex:add.b	#$30,d1
_Min9:
	move.b	d1,(a0)+
	rol.l	#4,d6
	dbra	d5,_LoopHex
	move.b	#0,(a0)
	movem.l	(sp)+,d0-a6
	rts

ReadBootHex:
	lea	Buffor_Roboczy,a0
	bsr	ReadBoot
	beq	OkNotError_HS
	lea	ReadError,a1
	bsr	ReqRequest
	moveq	#2,d2
	move.l	a1,a0
	bsr	PrintLine
	bra	Loop
OkNotError_HS:
	lea	BootBlockOK.txt,a0
	moveq	#1,d2
	bsr	PrintLine
	lea	Buffor_Roboczy,a0
	bra	OkBufforZap_HEX
Conw:
	movem.l	d0-a6,-(sp)
ConwertLoopHEX:				
	move.b	(a0),d0
	cmp.b	#0,d0
	bne	Nie_0_ASCHEX
	move.b	#'.',(a0)	
Nie_0_ASCHEX:
	cmp.b	#10,d0
	bne	Nie_10_ASCHHEX
	move.b	#'.',(a0)	
Nie_10_ASCHHEX:
	adda.l	#1,a0
	dbra	d1,ConwertLoopHEX
	movem.l	(sp)+,d0-a6
	rts

**************************

Ascii:
	lea	Gadgety_BootB,a0
	lea	Text_BootBlock,a1
	bsr	ReqRequestGAD
	lea	Buffor_1,a0
	lea	StanBuffora_1,a1
	cmp.l	#1,d0
	beq	OkAscii_START
	lea	Buffor_2,a0
	lea	StanBuffora_2,a1
	cmp.l	#2,d0
	beq	OkAscii_START
	lea	Buffor_3,a0
	lea	StanBuffora_3,a1
	cmp.l	#3,d0
	beq	OkAscii_START
	lea	Buffor_4,a0
	lea	StanBuffora_4,a1
	cmp.l	#4,d0
	beq	OkAscii_START
	lea	Buffor_5,a0
	lea	StanBuffora_5,a1
	cmp.l	#5,d0
	beq	OkAscii_START
	cmp.l	#6,d0
	beq	ReadBootAscii
	bra	Loop
OkAscii_START:
	tst.l	(a1)
	bne	OkBufforZap_ASCII
	lea	BufforyError.txt,a1
	bsr	ReqRequest
	bra	Loop
OkBufforZap_ASCII:
	cmp.l	#Buffor_Roboczy,a0
	beq	Ok_NoCopy
	lea	Buffor_Roboczy,a1	
	move.l	#(1024/4)-1,d0
CopRob.LOOP:
	move.l	(a0)+,(a1)+
	dbra	d0,CopRob.LOOP
	lea	Buffor_Roboczy,a0
Ok_NoCopy:
	move.l	a0,a1
	move.l	#1024-1,d1
ConwertLoop:				
	move.b	(a0),d0
	cmp.b	#0,d0
	bne	Nie_0_ASC
	move.b	#'.',(a0)	
Nie_0_ASC:
	cmp.b	#10,d0
	bne	Nie_10_ASC
	move.b	#'.',(a0)	
Nie_10_ASC:
	adda.l	#1,a0
	dbra	d1,ConwertLoop
	move.l	#15,d1
PrinTNexTlinE:
	move.l	a1,a0			
	bsr	CopyLine
	lea	AsciiBuffor,a0
	moveq	#1,d2
	bsr	PrintLine
	adda.l	#64,a1
	dbra	d1,PrinTNexTlinE
	bsr	PrintLine0
	bra	Loop

CopyLine:
	movem.l	d0-a6,-(sp)
	move.l	#63,d0
	lea	AsciiBuffor,a1
CopyLine.LOOP:
	move.b	(a0)+,(a1)+
	dbra	d0,CopyLine.LOOP
	move.b	#0,(a1)
	movem.l	(sp)+,d0-a6
	rts

ReadBootAscii:
	lea	Buffor_Roboczy,a0
	bsr	ReadBoot
	beq	OkNotError_AS
	lea	ReadError,a1
	bsr	ReqRequest
	moveq	#2,d2
	move.l	a1,a0
	bsr	PrintLine
	bra	Loop
OkNotError_AS:
	lea	BootBlockOK.txt,a0
	moveq	#1,d2
	bsr	PrintLine
	lea	Buffor_Roboczy,a0
	bra	OkBufforZap_ASCII

PrintLine0:
	movem.l	d0-a6,-(sp)
	lea	Line0.txt,a0
	moveq	#0,d2
	bsr	PrintLine
	movem.l	(sp)+,d0-a6
	rts

**************************

InstallVEBoot:
	tst.w	Requstery
	beq	SkokRQ_V
	bsr	ReqRequestTAKNIE
	tst.l	d0
	beq	Loop
SkokRQ_V:

	lea	VEBoot.txt,a1
	lea	VEBoot.gad,a0
	bsr	ReqRequestGAD
	lea	VE13_Buffor,a0
	cmp.l	#1,d0
	beq	WriteVE
	lea	VE20_Buffor,a0
	cmp.l	#2,d0
	beq	WriteVE
	bra	Loop
WriteVE:
	bsr	WriteBoot
	beq	OkWrite_V
	lea	BootWError.txt,a1
	bsr	ReqRequest
	lea	BootWError.txt,a0
	moveq	#2,d2
	bsr	PrintLine
	bra	Loop
OkWrite_V:
	lea	BBInstal.txt,a0
	moveq	#1,d2
	bsr	PrintLine
	bra	Loop

**************************

Format:
	tst.w	Requstery
	beq	SkokRQ_F
	bsr	ReqRequestTAKNIE
	tst.l	d0
	beq	Loop
SkokRQ_F:
	lea	Buffor_Roboczy,a0
	move.l	#(1024/4)-1,d0
ClearLoop_F:
	move.l	#0,(a0)+
	dbra	d0,ClearLoop_F
	lea	Buffor_Roboczy,a0
	bsr	WriteBoot
	beq	OkWrite_F
	lea	BootWError.txt,a1
	bsr	ReqRequest
	lea	BootWError.txt,a0
	moveq	#2,d2
	bsr	PrintLine
	bra	Loop
OkWrite_F:
	lea	BBInstal.txt,a0
	moveq	#1,d2
	bsr	PrintLine
	bra	Loop

**************************

Czysty:
	tst.w	Requstery
	beq	SkokRQ_C
	bsr	ReqRequestTAKNIE
	tst.l	d0
	beq	Loop
SkokRQ_C:
	lea	Buffor_Roboczy,a0
	move.l	#(1024/4)-1,d0
ClearLoop:
	move.l	#0,(a0)+
	dbra	d0,ClearLoop
	lea	Buffor_Roboczy,a0
	move.l	#$444f5300,(a0)
	bsr	WriteBoot
	beq	OkWrite_C
	lea	BootWError.txt,a1
	bsr	ReqRequest
	lea	BootWError.txt,a0
	moveq	#2,d2
	bsr	PrintLine
	bra	Loop
OkWrite_C:
	lea	BBInstal.txt,a0
	moveq	#1,d2
	bsr	PrintLine
	bra	Loop

**************************

Standard:
	tst.w	Requstery
	beq	SkokRQ_S
	bsr	ReqRequestTAKNIE
	tst.l	d0
	beq	Loop
SkokRQ_S:
	lea	InstalText.txt,a1
	lea	GadgetIns.gad,a0
	bsr	ReqRequestGAD
	move.l	#XVSBT_STANDARD13,d1
	cmp.l	#1,d0
	beq	OkJestTyp_SII
	move.l	#XVSBT_STANDARD20,d1
	cmp.l	#2,d0
	beq	OkJestTyp_SII
	bra	Loop
OkJestTyp_SII:
	move.l	XVSBase,a6
	move.l	d1,d0
	move.l	#0,d1
	lea	Buffor_XVS,a0
	jsr	_LVOxvsInstallBootblock(a6)
	lea	Buffor_XVS,a0
	bsr	WriteBoot
	beq	OkWrite_S
	lea	BootWError.txt,a1
	bsr	ReqRequest
	lea	BootWError.txt,a0
	moveq	#2,d2
	bsr	PrintLine
	bra	Loop
OkWrite_S:
	lea	BBInstal.txt,a0
	moveq	#1,d2
	bsr	PrintLine
	bra	Loop

**************************

Buffor:	lea	Text_BootBlock,a1
	lea	Gadgety_BootBlock,a0
	bsr	ReqRequestGAD
	lea	StanBuffora_1,a0
	lea	Buffor_1,a1
	cmp.l	#1,d0
	beq	OkBuffor_BB
	lea	StanBuffora_2,a0
	lea	Buffor_2,a1
	cmp.l	#2,d0
	beq	OkBuffor_BB
	lea	StanBuffora_3,a0
	lea	Buffor_3,a1
	cmp.l	#3,d0
	beq	OkBuffor_BB
	lea	StanBuffora_4,a0
	lea	Buffor_4,a1
	cmp.l	#4,d0
	beq	OkBuffor_BB
	lea	StanBuffora_5,a0
	lea	Buffor_5,a1
	cmp.l	#5,d0
	beq	OkBuffor_BB
	bra	Loop
OkBuffor_BB:
	move.l	a1,A1_SAVE
	tst.l	(a0)
	bne	OkBufforzap
	lea	BufforyError.txt,a1
	bsr	ReqRequest
	bra	Loop
OkBufforzap:
	tst.w	Requstery
	beq	SkokRQ_BB
	bsr	ReqRequestTAKNIE
	tst.l	d0
	beq	Loop
SkokRQ_BB:
	move.l	A1_SAVE,a0
	bsr	WriteBoot
	beq	OkWrite_BB
	lea	BootWError.txt,a1
	bsr	ReqRequest
	lea	BootWError.txt,a0
	moveq	#2,d2
	bsr	PrintLine
	bra	Loop
OkWrite_BB:
	lea	BBInstal.txt,a0
	moveq	#1,d2
	bsr	PrintLine
	bra	Loop

**************************

KasujBuffor:
	lea	Text_BootBlock,a1
	lea	Gadgety_BootBlock,a0
	bsr	ReqRequestGAD
	tst.l	d0
	beq	Loop
	move.l	#StanBuffora_1,a0
	cmp.l	#1,d0
	beq	OkKasuj_KB
	move.l	#StanBuffora_2,a0
	cmp.l	#2,d0
	beq	OkKasuj_KB
	move.l	#StanBuffora_3,a0
	cmp.l	#3,d0
	beq	OkKasuj_KB
	move.l	#StanBuffora_4,a0
	cmp.l	#4,d0
	beq	OkKasuj_KB
	move.l	#StanBuffora_5,a0
	cmp.l	#5,d0
	beq	OkKasuj_KB
	bra	Loop

OkKasuj_KB:
	tst.l	(a0)
	bne	OkBrak0
	lea	BufforyError.txt,a1
	bsr	ReqRequest
	bra	Loop
OkBrak0:
	tst.w	Requstery
	beq	NieRequest_KB
	bsr	ReqRequestTAKNIE
	tst.l	d0
	beq	Loop
NieRequest_KB:
	move.l	#0,(a0)
	bra	Loop

**************************

MenuRefresh
	tst.l	StanBuffora_1
	bne	OkJest1_MR
	tst.l	StanBuffora_2
	bne	OkJest1_MR
	tst.l	StanBuffora_3
	bne	OkJest1_MR
	tst.l	StanBuffora_4
	bne	OkJest1_MR
	tst.l	StanBuffora_5
	bne	OkJest1_MR
	move.l	#$f842,d0		
	bsr	MENU_OFF
	move.l	#$f862,d0		
	bsr	MENU_OFF
	move.l	#$f8e2,d0		
	bsr	MENU_OFF
	rts
OkJest1_MR:
	move.l	#$f842,d0		
	bsr	MENU_ON
	move.l	#$f862,d0		
	bsr	MENU_ON
	move.l	#$f8e2,d0		
	bsr	MENU_ON
	rts

**************************

BUFFOR_PLIK:
	lea	Gadgety_BootBlock,a0
	lea	Text_BootBlock,a1
	bsr	ReqRequestGAD
	move.l	#StanBuffora_1,a0
	lea	Buffor_1,a1
	cmp.l	#1,d0
	beq	WriteBuffor_
	move.l	#StanBuffora_2,a0
	lea	Buffor_2,a1
	cmp.l	#2,d0
	beq	WriteBuffor_
	move.l	#StanBuffora_3,a0
	lea	Buffor_3,a1
	cmp.l	#3,d0
	beq	WriteBuffor_
	move.l	#StanBuffora_4,a0
	lea	Buffor_4,a1
	cmp.l	#4,d0
	beq	WriteBuffor_
	move.l	#StanBuffora_5,a0
	lea	Buffor_5,a1
	cmp.l	#5,d0
	beq	WriteBuffor_
	bra	Loop

WriteBuffor_:
	move.l	a1,A1_SAVE
	move.l	(a0),d0
	tst.l	d0
	bne	OkZap_WB
	lea	BufforyError.txt,a1
	bsr	ReqRequest
	bra	Loop
OkZap_WB:
	bsr	FileReq
	tst.l	d0
	beq	Loop
	move.l	DosBase,a6		
	move.l	#FullName,d1
	move.l	#MODE_OLDFILE,d2
	jsr	_LVOOpen(a6)
	tst.l	d0
	beq	OkBrakPliku
	move.l	d0,d7
	tst.w	Requstery
	beq	CloseFile_WB
	lea	JestPlik.txt,a1
	lea	JestPlik.gad,a0
	bsr	ReqRequestGAD
	tst.l	d0
	bne	CloseFile_WB
	move.l	DosBase,a6
	move.l	d7,d1
	jsr	_LVOClose(a6)
	bra	Loop
CloseFile_WB:
	move.l	DosBase,a6
	move.l	d7,d1
	jsr	_LVOClose(a6)
OkBrakPliku:
	move.l	DosBase,a6
	move.l	#FullName,d1
	move.l	#MODE_NEWFILE,d2
	jsr	_LVOOpen(a6)
	tst.l	d0
	bne	OkNoWriteError
	lea	WriteError.txt,a1
	jsr	ReqRequest
	bra	Loop
OkNoWriteError:
	move.l	d0,d7
	move.l	d0,d1
	move.l	A1_SAVE,d2
	move.l	#1024,d3
	jsr	_LVOWrite(a6)
	tst.l	d0
	bne	OkNoWriteError1
	move.l	DosBase,a6
	move.l	d7,d1
	jsr	_LVOClose(a6)
	lea	WriteError.txt,a1
	bsr	ReqRequest
	bra	Loop
OkNoWriteError1:
	move.l	DosBase,a6
	move.l	d7,d1
	jsr	_LVOClose(a6)
	bra	Loop

*************************

BAR:	movem.l	d0-a6,-(sp)
	move.l	GrBase,a6
	movem.l	d0-a6,-(sp)
	move.l	#0,d0
	jsr	_LVOSetAPen(a6)
	movem.l	(sp)+,d0-a6
	jsr	_LVORectFill(a6)
	movem.l	(sp)+,d0-a6
	rts

**************************

FillBitMap:
	lea	BitMap_4,a0
	move.l	#(256/2)-1,d1
LoopPN:	move.l	#79,d0
Pazyste:move.b	#%01010101,(a0)+
	dbra	d0,Pazyste
	move.l	#79,d0
NPazyste:
	move.b	#%10101010,(a0)+	
	dbra	d0,NPazyste
	dbra	d1,LoopPN
	rts

*************************

MENU_OFF:
	movem.l	d0-a6,-(sp)
	move.l	InitBase,a6
	move.l	WindowBase,a0
	jsr	_LVOOffMenu(a6)
	movem.l	(sp)+,d0-a6
	rts

MENU_ON:movem.l	d0-a6,-(sp)
	move.l	InitBase,a6
	move.l	WindowBase,a0
	jsr	_LVOOnMenu(a6)
	movem.l	(sp)+,d0-a6
	rts

GADGETY_OFF:
	move.l	GADGET_NR1,a0
	bsr	GADGET_OFF
	move.l	GADGET_NR2,a0
	bsr	GADGET_OFF
	move.l	GADGET_NR3,a0
	bsr	GADGET_OFF
	move.l	GADGET_NR4,a0
	bsr	GADGET_OFF
	move.l	GADGET_NR5,a0
	bsr	GADGET_OFF
	move.l	GADGET_NR6,a0
	bsr	GADGET_OFF
	move.l	GADGET_NR7,a0
	bsr	GADGET_OFF
	rts

GADGETY_ON:
	move.l	GADGET_NR1,a0
	bsr	GADGET_ON
	move.l	GADGET_NR2,a0
	bsr	GADGET_ON
	move.l	GADGET_NR3,a0
	bsr	GADGET_ON
	move.l	GADGET_NR4,a0
	bsr	GADGET_ON
	move.l	GADGET_NR5,a0
	bsr	GADGET_ON
	move.l	GADGET_NR6,a0
	bsr	GADGET_ON
	move.l	GADGET_NR7,a0
	bsr	GADGET_ON
	rts

GADGET_OFF:
	movem.l	d0-a6,-(sp)
	move.l	GadBase,a6
	move.l	WindowBase,a1
	move.l	#0,a2
	move.l	#TAGLIST_OFF,a3
	jsr	_LVOGSetGadgetAttrsA(a6)
	movem.l	(sp)+,d0-a6
	rts
	
GADGET_ON:
	movem.l	d0-a6,-(sp)
	move.l	GadBase,a6
	move.l	WindowBase,a1
	move.l	#0,a2
	move.l	#TAGLIST_ON,a3
	jsr	_LVOGSetGadgetAttrsA(a6)
	movem.l	(sp)+,d0-a6
	rts

**************************

STATUS:	movem.l	d0-a6,-(sp)
	bsr	GADGETY_OFF
	lea	Buff_ST1,a0
	move.l	#$20202020,(a0)+
	move.l	#$20202020,(a0)+
	move.l	#$20202020,(a0)+
	lea	Buff_ST1,a1
	move.l	CheckDrive,d0
	moveq	#$20,d7
	bsr	Conwert

	lea	Buff_ST2,a0
	move.l	#$20202020,(a0)+
	move.l	#$20202020,(a0)+
	move.l	#$20202020,(a0)+
	lea	Buff_ST2,a1
	move.l	CheckFiles,d0
	moveq	#$20,d7
	bsr	Conwert

	lea	Buff_ST3,a0
	move.l	#$20202020,(a0)+
	move.l	#$20202020,(a0)+
	move.l	#$20202020,(a0)+
	lea	Buff_ST3,a1
	move.l	VirusFound,d0
	moveq	#$20,d7
	bsr	Conwert

	lea	B_1,a0
	move.l	StanBuffora_1,d0
	add.l	#$30,d0
	move.b	d0,20(a0)

	lea	B_2,a0
	move.l	StanBuffora_2,d0
	add.l	#$30,d0
	move.b	d0,20(a0)
	
	lea	B_3,a0
	move.l	StanBuffora_3,d0
	add.l	#$30,d0
	move.b	d0,20(a0)

	lea	B_4,a0
	move.l	StanBuffora_4,d0
	add.l	#$30,d0
	move.b	d0,20(a0)

	lea	B_5,a0
	move.l	StanBuffora_5,d0
	add.l	#$30,d0
	move.b	d0,20(a0)

	lea	STATUS.txt,a1
	bsr	ReqRequest
	bsr	GADGETY_ON
	movem.l	(sp)+,d0-a6
	bra	Loop

**************************

VIRUS_LIST:
	bsr	GADGETY_OFF
	bsr	FillBitMap
	move.l	d3,d7
	move.l	GadBase,a6
	lea	Gadget_LAB,a0
	moveq	#0,d0
	jsr	_LVOCreateConText(a6)
	tst.l	d0
	bne	OKCreateGad
	lea	GadgetError.txt,a1
	bsr	ReqRequest
	bra	QUIT_VL
OKCreateGad:
	move.l	d0,CONTEXT_VL
	move.l	XVSBase,a6
	move.l	d7,d0
	jsr	_LVOxvsCreateVirusList(a6)
	tst.l	d0
	bne	OkVirusList_CR
	lea	VirusLError.txt,a1
	bsr	ReqRequest
	bra	FreeGadget
OkVirusList_CR:
	move.l	d0,VirusList

	move.l	GadBase,a6
	move.l	#BUTTON_KIND,d0
	move.l	CONTEXT_VL,a0
	lea	BUTTON_KIND_OK,a1
	move.l	Visual,d1
	move.l	d1,22(a1)
	move.l	#0,a2
	jsr	_LVOCreateGadget(a6)
	tst.l	d0
	beq	GadgetError_LV
	move.l	d0,d7

	move.l	#LISTVIEW_KIND,d0
	move.l	d7,a0
	lea	BUTTON_LISTVIEW_OK,a1
	move.l	Visual,d1
	move.l	d1,22(a1)
	move.l	#LV_TAGLIST,a2
	move.l	VirusList,4(a2)
	jsr	_LVOCreateGadget(a6)
	tst.l	d0
	beq	GadgetError_LV

	move.l	InitBase,a6
	lea	Window_LV.taglist,a1
	move.l	#0,a0
	jsr	_LVOOpenWindowTagList(a6)
	tst.l	d0
	bne	OkWindow_1
	lea	WindowError.txt,a1
	bsr	ReqRequest
	bra	FreeVirusList
OkWindow_1:
	move.l	d0,WindowBaseLV

	move.l	WindowBaseLV,a0
	move.l	wd_RPort(a0),d7

	move.l	GadBase,a6
	move.l	WindowBaseLV,a0
	move.l	#0,a1
	jsr	_LVORefreshWindow(a6)

	

	moveq	#8,d0
	moveq	#15,d1
	move.l	#186,d2
	moveq	#15,d3
	move.l	d7,a1
	bsr	BAR

	moveq	#7,d0
	moveq	#120,d1
	move.l	#186,d2
	moveq	#120,d3
	move.l	d7,a1
	bsr	BAR

	move.l	#191,d0
	move.l	#15,d1
	move.l	#192,d2
	move.l	#104,d3
	move.l	d7,a1
	bsr	BAR

	move.l	#201,d0
	move.l	#15,d1
	move.l	#202,d2
	move.l	#104,d3
	move.l	d7,a1
	bsr	BAR

	move.l	#191,d0
	move.l	#15,d1
	move.l	#202,d2
	move.l	#15,d3
	move.l	d7,a1
	bsr	BAR

	move.l	#191,d0
	move.l	#104,d1
	move.l	#202,d2
	move.l	#104,d3
	move.l	d7,a1
	bsr	BAR

	

Loop_LV:bsr	ClrReg
	move.l	WindowBaseLV,a0
	bsr	_GetMsg
	cmp.w	#1,d0
	beq	CloseWindow_LV
	cmp.l	#CLOSEWINDOW,d1
	beq	CloseWindow_LV
	cmp.l	#IDCMP_REFRESHWINDOW,d1
	bne	Loop_LV
	move.l	GadBase,a6
	move.l	WindowBaseLV,a0
	jsr	_LVOGBeginRefresh(a6)
	move.l	WindowBaseLV,a0
	moveq	#1,d0
	jsr	_LVOGEndRefresh(a6)
	bra	Loop_LV

CloseWindow_LV:
	move.l	InitBase,a6
	move.l	WindowBaseLV,a0
	jsr	_LVOCloseWindow(a6)
	bra	FreeVirusList
GadgetError_LV:
	lea	GadgetError.txt,a1
	bsr	ReqRequest
FreeVirusList:
	move.l	XVSBase,a6
	move.l	VirusList,a1
	jsr	_LVOxvsFreeVirusList(a6)
FreeGadget_VL:
	move.l	GadBase,a6
	move.l	CONTEXT_VL,a0
	jsr	_LVOFreeGadgets(a6)
QUIT_VL:bsr	GADGETY_ON
	bra	Loop

**********************************

CHECK_BOOTBLOCK:
	move.l	#Text_BootBlock,a1
	move.l	#Gadgety_BootB,a0
	bsr	ReqRequestGAD
	lea	Buffor_1,a0
	move.l	StanBuffora_1,d1
	cmp.l	#1,d0
	beq	OKJestBuf_CBB
	lea	Buffor_2,a0
	move.l	StanBuffora_2,d1
	cmp.l	#2,d0
	beq	OKJestBuf_CBB
	lea	Buffor_3,a0
	move.l	StanBuffora_3,d1
	cmp.l	#3,d0
	beq	OKJestBuf_CBB
	lea	Buffor_4,a0
	move.l	StanBuffora_4,d1
	cmp.l	#4,d0
	beq	OKJestBuf_CBB
	lea	Buffor_5,a0
	move.l	StanBuffora_5,d1
	cmp.l	#5,d0
	beq	OKJestBuf_CBB
	cmp.l	#6,d0
	beq	DFx_BootBlock
	bra	Loop
OKJestBuf_CBB:
	tst.l	d1				
	bne	OkBuff_CBB
	lea	BufforyError.txt,a1
	bsr	ReqRequest
	bra	Loop
OkBuff_CBB:	
	move.l	a0,a5
	move.l	a0,A1_SAVE
	move.l	XVSBase,a6
	move.l	#XVSOBJ_BOOTINFO,d0
	jsr	_LVOxvsAllocObject(a6)		
	tst.l	d0
	bne	Okllok
	lea	AllocError.txt,a1
	jsr	ReqRequest
	bra	QUIT_CBB
Okllok: move.l	d0,BootInfo

	move.l	XVSBase,a6			
	move.l	BootInfo,a0
	move.l	a5,xvsbi_Bootblock(a0)
	jsr	_LVOxvsCheckBootblock(a6)
	cmp.l	#0,d0
	beq	NieznanyBootBlock
	cmp.l	#1,d0
	beq	NoDosDisk
	cmp.l	#2,d0
	beq	STANDARD13
	cmp.l	#3,d0
	beq	STANDARD20
	cmp.l	#4,d0
	beq	Wirus
	cmp.l	#5,d0
	beq	UnInstalled
	bra	NieznanyBootBlock
	
*** Procedury obs?ugi bootblock?w ***

DFx_BootBlock:
	lea	Buffor_Roboczy,a0
	bsr	ReadBoot
	beq	OkReadBoot_DFx
	lea	ReadError,a1
	bsr	ReqRequest
	bra	Loop
OkReadBoot_DFx:
	add.l	#1,CheckDrive
	lea	Buffor_Roboczy,a0
	moveq	#1,d1
	bra	OKJestBuf_CBB

NoDosDisk:
	lea	NoDos.txt,a1
	bsr	ReqRequest
	bra	KoniecCBB

NieznanyBootBlock:
	tst.l	BIBLIOTEKA
	beq	_BrakBiblioteki
	move.l	a5,A1_SAVE
	bsr	CzyJestTakiBootBlock
	tst.l	d0
	beq	_BrakBiblioteki

	move.l	EXEC.W,a6
	lea	LibBootblock+13,a1
	move.l	BOOTNAME,a0
	moveq	#30,d0
	jsr	_LVOCopyMem(a6)

	lea	LibBootblock,a1
	bsr	ReqRequest
	bra	KoniecCBB
_BrakBiblioteki:
	bsr	CzyVEBoot
	tst.l	d0
	beq	NieVEBoot
	move.l	a0,a1
	bsr	ReqRequest
	bra	KoniecCBB
NieVEBoot:
	lea	Nieznany.txt,a1
	lea	UnIns.gad,a0
	bsr	ReqRequestGAD
	tst.l	d0
	bne	Instal
	bra	KoniecCBB

UnInstalled:
	lea	UnIns.txt,a1
	bsr	ReqRequest
	bra	KoniecCBB

Wirus:
	lea	WirusBuffor,a1
	move.l	BootInfo,a0
	move.l	xvsbi_Name(a0),a0
CWN:	move.b	(a0)+,d0
	move.b	d0,(a1)+
	cmp.b	#0,d0
	bne	CWN
	lea	Wirus.txt,a1	
	bsr	ReqRequest
	add.l	#1,VirusFound
	bra	KoniecCBB

STANDARD13:
	lea	STAN_13.txt,a1
	bsr	ReqRequest
	bra	KoniecCBB

STANDARD20:
	lea	STAN_20.txt,a1
	bsr	ReqRequest
	bra	KoniecCBB
	
*************************************

CzyVEBoot:
	movem.l	d1-d7/a1-a6,-(sp)
	lea	VE13_Buffor,a0
	move.l	A1_SAVE,a1
	move.l	#1023,d2
Czy1.3:
	move.b	(a0)+,d0
	move.b	(a1)+,d1
	cmp.b	d0,d1
	bne	Nie1.3
	dbra	d2,Czy1.3
	lea	VE1.3,a0
	move.l	#1,d0
	bra	QUIT_VE
Nie1.3:
	lea	VE20_Buffor,a0
	move.l	A1_SAVE,a1
	move.l	#1023,d2
Czy2.0:
	move.b	(a0)+,d0
	move.b	(a1)+,d1
	cmp.b	d0,d1
	bne	Nie2.0
	dbra	d2,Czy2.0
	lea	VE2.0,a0
	move.l	#1,d0
	bra	QUIT_VE
Nie2.0:
	moveq	#0,d0
	move.l	#0,a0
QUIT_VE:movem.l	(sp)+,d1-d7/a1-a6
	rts

*************************************

CopyMem:
	movem.l	d0-a6,-(sp)
	subq	#1,d0
CopyMLoop:
	move.b	(a0)+,(a1)+
	dbra	d0,CopyMLoop
	movem.l	(sp)+,d0-a6
	rts

*************************************

KoniecCBB:
FreeObject:
	move.l	XVSBase,a6			
	move.l	BootInfo,a1
	move.l	#0,a0
	jsr	_LVOxvsFreeObject(a6)	
QUIT_CBB:
	bra	Loop

*************************************

Instal_XVS:
	move.l	XVSBase,a6			
	move.l	BootInfo,a1
	move.l	#0,a0
	jsr	_LVOxvsFreeObject(a6)
	bsr	ClrReg
Instal:
	tst.w	Requstery
	beq	SKOK_INN
	lea	UWAGAInstal.txt,a1
	lea	TAKNIE.gad,a0
	bsr	ReqRequestGAD
	tst.l	d0
	beq	Loop
SKOK_INN:
	lea	InstalText.txt,a1
	lea	GadgetIns.gad,a0
	bsr	ReqRequestGAD
	move.l	#XVSBT_STANDARD13,d1
	cmp.l	#1,d0
	beq	OkJestTyp_BII
	move.l	#XVSBT_STANDARD20,d1
	cmp.l	#2,d0
	beq	OkJestTyp_BII
	bra	Loop
OkJestTyp_BII:
	move.l	XVSBase,a6
	move.l	d1,d0
	move.l	#0,d1
	lea	Buffor_XVS,a0
	jsr	_LVOxvsInstallBootblock(a6)
	lea	Buffor_XVS,a0
	bsr	WriteBoot
	beq	Loop
	lea	BootWError.txt,a1
	bsr	ReqRequest
	bra	Loop

*************************************

ICONIFY_PROC:
	movem.l	d0-a6,-(sp)
	move.l	EXEC.W,a6			
	lea	WBenchNAME,a1
	moveq	#37,d0
	jsr	_LVOOldOpenLibrary(a6)
	tst.l	d0
	bne	OkWbenchLib
	lea	WBenchError.txt,a0
	bsr	IntRequest
	bra	IconQ
OkWbenchLib:
	move.l	d0,WBenchBase

	move.l	EXEC.W,a6
	lea	IconLibName,a1			
	moveq	#0,d0
	jsr	_LVOOldOpenLibrary(a6)
	tst.l	d0
	bne	OkIconLib
	lea	IconLibError.txt,a0
	bsr	IntRequest
	bra	CloseWBLib
OkIconLib:
	move.l	d0,IconLibBase
	
	move.l	IconLibBase,a6			
	lea	IconName,a0
	jsr	_LVOGetDiskObject(a6)
	tst.l	d0
	bne	OkIcon
	lea	IconError.txt,a0
	bsr	IntRequest
	bra	CloseIconLib
OkIcon:	move.l	d0,IconBase

	move.l	EXEC.W,a6			
	moveq	#0,d0
	move.l	#0,a0
	jsr	_LVOCreateMsgPort(a6)
	tst.l	d0
	bne	OkPort
	lea	PortIconEr.txt,a0
	bsr	IntRequest
	bra	FreeIcon
OkPort:	move.l	d0,IconPort

	move.l	WBenchBase,a6			
	moveq	#1,d0
	moveq	#1,d1
	lea	DownIconText,a0
	move.l	IconPort,a1
	move.l	#0,a2
	move.l	IconBase,a3
	move.l	#0,a4
	jsr	_LVOAddAppIconA(a6)
	tst.l	d0
	bne	OkAppIcons
	lea	AppIcon.txt,a0
	bsr	IntRequest
	bra	FreeIcon
OkAppIcons:
	move.l	d0,AppIconsBase

Wait_Icon:
	move.l	EXEC.W,a6
	move.l	IconPort,a0
	jsr	_LVOWaitPort(a6)
	tst.l	d0
	beq	Wait_Icon

RemoveAppIcons:
	move.l	WBenchBase,a6
	move.l	AppIconsBase,a0
	jsr	_LVORemoveAppIcon(a6)	
FreeIcon:
	move.l	IconLibBase,a6			
	move.l	IconBase,a0
	jsr	_LVOFreeDiskObject(a6)
CloseIconLib:
	move.l	EXEC.W,a6
	move.l	IconLibBase,a1
	jsr	_LVOCloseLibrary(a6)
CloseWBLib:
	move.l	EXEC.W,a6
	move.l	WBenchBase,a1
	jsr	_LVOCloseLibrary(a6)
IconQ:	movem.l	(sp)+,d0-a6
	move.l	#0,ICONIFY
	move.l	#1,_ICONIFY
	bra	START

Plik_Buffor:
	bsr	FileReq
	tst.l	d0
	beq	Loop
	lea	Text_BootBlock,a1
	lea	Gadgety_BootBlock,a0
	bsr	ReqRequestGAD
	lea	Buffor_1,a0
	move.l	#StanBuffora_1,a1
	bra	ReadBootFile
	lea	Buffor_2,a0
	move.l	#StanBuffora_2,a1
	bra	ReadBootFile
	lea	Buffor_3,a0
	move.l	#StanBuffora_3,a1
	bra	ReadBootFile
	lea	Buffor_4,a0
	move.l	#StanBuffora_4,a1
	bra	ReadBootFile
	lea	Buffor_5,a0
	move.l	#StanBuffora_5,a1
	bra	ReadBootFile
	bra	Loop

ReadBootFile:
	move.l	a0,A0_SAVE
	move.l	a1,A1_SAVE
	move.l	(a1),d0
	tst.l	d0
	beq	NieZap_PB
	lea	ZapBuf,a1
	lea	Gadget_Buffor,a0
	bsr	ReqRequestGAD
	tst.l	d0
	beq	Loop
NieZap_PB:
	move.l	DosBase,a6
	move.l	#FullName,d1
	move.l	#MODE_OLDFILE,d2
	jsr	_LVOOpen(a6)
	tst.l	d0
	bne	OkOpenFile_PB
	lea	OpenError.txt,a1
	bsr	ReqRequest
	bra	Loop
OkOpenFile_PB:
	move.l	d0,d7
	move.l	d0,d1
	move.l	A0_SAVE,d2
	move.l	#1024,d3
	jsr	_LVORead(a6)
	tst.l	d0
	bne	OkReadFile_PB
	lea	ReadError.txt,a1
	bsr	ReqRequest
	move.l	d7,d1
	jsr	_LVOClose(a6)
	bra	Loop
OkReadFile_PB:
	move.l	d7,d1
	jsr	_LVOClose(a6)

	move.l	A0_SAVE,a0
	move.l	(a0),d0
	lsr.l	#8,d0
	lsr.l	#8,d0
	cmp.w	#$444f,d0
	beq	OkBoot_PB
NieBoot:lea	BootblockE.txt,a1
	bsr	ReqRequest
	bra	Loop
OkBoot_PB:
	move.l	(a0),d0
	lsr.l	#8,d0
	cmp.b	#$53,d0
	bne	NieBoot
	move.l	A1_SAVE,a1
	move.l	#1,(a1)
	bra	Loop

*****************************

BootBlock_Buffor:
	move.l	#Text_BootBlock,a1
	move.l	#Gadgety_BootBlock,a0
	bsr	ReqRequestGAD
	cmp.l	#1,d0
	beq	ReadBootBlock_Buffor1
	cmp.l	#2,d0
	beq	ReadBootBlock_Buffor2
	cmp.l	#3,d0
	beq	ReadBootBlock_Buffor3
	cmp.l	#4,d0
	beq	ReadBootBlock_Buffor4
	cmp.l	#5,d0
	beq	ReadBootBlock_Buffor5
	bra	Loop

ReadBootBlock_Buffor1:			
	cmp.w	#1,Requstery
	bne	OkStan0_B1
	cmp.l	#1,StanBuffora_1
	bne	OkStan0_B1
	lea	Buffor_1_ZAP,a1
	lea	Gadget_Buffor,a0
	bsr	ReqRequestGAD
	tst.l	d0
	beq	Loop
OkStan0_B1:
	lea	Buffor_1,a0
	bsr	ReadBoot
	beq	NotError1
	lea	ReadError,a1
	bsr	ReqRequest
	bra	Loop
NotError1
	move.l	#1,StanBuffora_1
	bra	Loop

ReadBootBlock_Buffor2:			
	cmp.w	#1,Requstery
	bne	OkStan0_B2
	cmp.l	#1,StanBuffora_2
	bne	OkStan0_B2
	lea	Buffor_2_ZAP,a1
	lea	Gadget_Buffor,a0
	bsr	ReqRequestGAD
	tst.l	d0
	beq	Loop
OkStan0_B2:
	lea	Buffor_2,a0
	bsr	ReadBoot
	beq	NotError2
	lea	ReadError,a1
	bsr	ReqRequest
	bra	Loop
NotError2
	move.l	#1,StanBuffora_2
	bra	Loop

ReadBootBlock_Buffor3:			
	cmp.w	#1,Requstery
	bne	OkStan0_B3
	cmp.l	#1,StanBuffora_3
	bne	OkStan0_B3
	lea	Buffor_3_ZAP,a1
	lea	Gadget_Buffor,a0
	bsr	ReqRequestGAD
	tst.l	d0
	beq	Loop
OkStan0_B3:
	lea	Buffor_3,a0
	bsr	ReadBoot
	beq	NotError3
	lea	ReadError,a1
	bsr	ReqRequest
	bra	Loop
NotError3
	move.l	#1,StanBuffora_3
	bra	Loop

ReadBootBlock_Buffor4:			
	cmp.w	#1,Requstery
	bne	OkStan0_B4
	cmp.l	#1,StanBuffora_4
	bne	OkStan0_B4
	lea	Buffor_4_ZAP,a1
	lea	Gadget_Buffor,a0
	bsr	ReqRequestGAD
	tst.l	d0
	beq	Loop
OkStan0_B4:
	lea	Buffor_4,a0
	bsr	ReadBoot
	beq	NotError4
	lea	ReadError,a1
	bsr	ReqRequest
	bra	Loop
NotError4
	move.l	#1,StanBuffora_4
	bra	Loop

ReadBootBlock_Buffor5:			
	cmp.w	#1,Requstery
	bne	OkStan0_B5
	cmp.l	#1,StanBuffora_5
	bne	OkStan0_B5
	lea	Buffor_5_ZAP,a1
	lea	Gadget_Buffor,a0
	bsr	ReqRequestGAD
	tst.l	d0
	beq	Loop
OkStan0_B5:
	lea	Buffor_5,a0
	bsr	ReadBoot
	beq	NotError5
	lea	ReadError,a1
	bsr	ReqRequest
	bra	Loop
NotError5
	move.l	#1,StanBuffora_5
	bra	Loop

***** Dla trackdisk.device ****

OpenTrackDisk:
	move.l	EXEC.W,a6
	sub.l	a1,a1
	jsr	_LVOFindTask(a6)
	lea	MsgPort,a1
	move.l	d0,MP_SIGTASK(a1)
	move.b	#4,LN_TYPE(a1)
	lea	IORequest,a1
	move.b	#5,LN_TYPE(a1)
	move.l	#MsgPort,MN_REPLYPORT(a1)
	move.l	EXEC.W,a6
	lea	DevName,a0
	moveq.l #0,d0
	moveq.l #0,d1
	jsr	_LVOOpenDevice(a6)
	tst.l	d0
	bne	ErrorTrack
	moveq	#0,d0
	tst.l	d0
	rts
ErrorTrack
	moveq	#-1,d0
	tst.l	d0
	rts

CloseTrackDisk:
	move.l	EXEC.W,a6
	move.l	#0,a0
	lea	IORequest,a1
	jsr	_LVOCloseDevice(a6)
	rts

ReadBoot:
	movem.l	d1-a6,-(sp)
	move.l	BootBase,a6
	moveq	#0,d0
	move.w	DRIVE_NR,d0
	jsr	-60(a6)
	movem.l	(sp)+,d1-a6
	tst.b	d0
	rts

MotorOff:
	lea	IORequest,a1
	move.w	#9,IO_COMMAND(a1)
	clr.l	IO_LENGTH(a1)
	move.l	EXEC.W,a6
	jsr	_LVODoIO(a6)
	rts

Write_Buffor_TRACK:
	movem.l	d0-a6,-(sp)
	lea	IORequest,a1
	move.w	#4,IO_COMMAND(a1)
	move.l	EXEC.W,a6
	jsr	_LVODoIO(a6)
	movem.l	(sp)+,d0-a6
	rts

Clear_Buffor_TRACK:
	movem.l	d0-a6,-(sp)
	lea	IORequest,a1
	move.w	#5,IO_COMMAND(a1)
	move.l	EXEC.W,a6
	jsr	_LVODoIO(a6)
	movem.l	(sp)+,d0-a6
	rts

WriteBoot:
	movem.l	d1-a6,-(sp)
	move.l	BootBase,a6
	moveq	#0,d0
	move.w	DRIVE_NR,d0
	jsr	-66(a6)
	movem.l	(sp)+,d1-a6
	tst.l	d0
	rts
	
***** Gadgety ****

About:	movem.l	d0-a6,-(sp)
	lea	About.txt,a1
	lea	About.gad,a0
	bsr	ReqRequestGAD
	movem.l	(sp)+,d0-a6
	bra	Loop

Requstery_PROC:
	move.w	d2,Requstery
	bra	Loop

TestDrive_PROC:
	move.w	d2,TestDrive
	bra	Loop

KillWirus_PROC:
	move.w	d2,KillWirus
	bra	Loop

***** Kontrola systemu *****

_GetMsg:move.l	$4.W,a6
	move.l	wd_UserPort(a0),a0
	move.l	a0,a5
	jsr	_LVOWaitPort(a6)
	tst.l	d0
	beq	_GetMsg
	move.l	GadBase,a6
	move.l	a5,a0
	jsr	_LVOGetIMsg(a6)
	move.l	d0,a4			
	move.l	a4,a1
	jsr	_LVOReplyIMsg(a6)
	move.l	im_Class(a4),d1		
	move.w	im_Code(a4),d2		
	move.l	im_IAddress(a4),a3
	move.w	gg_GadgetID(a3),d0
	rts

***** Memory *****

Libraries_LIST:
	movem.l	d0-a6,-(sp)
	move.l	#42,LINE_NR
	bsr	CLW
	move.l	EXEC.W,a6
	move.l	VIEWATTR,d4
	move.l	0(a6,d4.l),LibraryBase	
	moveq	#0,d4
LibraryLoop:
	cmp.l	#23,d4
	bne	OKPrintuj
	lea	WaitStrona,a1
	bsr	ReqRequest
	moveq	#0,d4
OKPrintuj:
	move.l	LibraryBase,a1
	move.l	LIB_IDSTRING(a1),a0	
	cmpa.l	#0,a0
	beq	BrakASCIIInfo
	move.b	(a0),d0
	tst.b	d0
	beq	BrakASCIIInfo
	bsr	ClearTextBuffor
	lea	TextBuffor,a1
CopyLoop_LIB:
	move.b	(a0)+,d0
	cmp.b	#'$',d0
	beq	CZYWERSJA
NIEWERSJA:
	cmp.b	#' ',d0
	beq	OK_LIB
	cmp.b	#10,d0
	beq	OK_LIB
	cmp.b	#$0D,d0
	beq	OK_LIB
	cmp.b	#0,d0
	beq	OK_LIB
	move.b	d0,(a1)+
	bra	CopyLoop_LIB
OK_LIB:	
	lea	TextBuffor+20,a0
	move.b	#' ',(a0)+
	move.l	LibraryBase,d0
	bsr	Hex
	lea	TextBuffor,a0
	moveq	#1,d2
	moveq	#0,d3
	bsr	PrintLine
	addq	#1,d4
BrakASCIIInfo:
	move.l	LibraryBase,a1
	move.l	(a1),LibraryBase
	move.l	(a1),d0
	tst.l	d0
	bne	LibraryLoop
	movem.l	(sp)+,d0-a6
	bra	Loop

CZYWERSJA:
	movem.l	d0-a6,-(sp)
	move.l	a0,SAVE			
	move.b	(a0)+,d0
	cmp.b	#'V',d0
	bne	EXiT_V
	move.b	(a0)+,d0
	cmp.b	#'E',d0
	bne	EXiT_V
	move.b	(a0)+,d0
	cmp.b	#'R',d0
	bne	EXiT_V
	move.b	(a0)+,d0
	cmp.b	#':',d0
	bne	EXiT_V
Loop_SPACE:
	move.b	(a0)+,d0
	cmp.b	#' ',d0
	beq	Loop_SPACE
	suba.l	#1,a0
	move.l	a0,SAVE
EXiT_V:	movem.l	(sp)+,d0-a6
	move.l	SAVE,a0
	move.b	(a0)+,d0
	bra	NIEWERSJA

***** R??ne *****

FileReq:
	movem.l	d1-d5/a0-a6,-(sp)
	move.l	ReqBase,a6
	moveq	#0,d0
	lea	$0,a0
	jsr	-30(a6)
	move.l	d0,FilReq
	tst	d0
	bne	Skok_Ful
	lea	FileReqError.TX,a1
	bsr	ReqRequest
	movem.l	(sp)+,d1-d5/a0-a6
	move.l	#0,d0
	rts
Skok_Ful:
	move.l	FilReq,a1
	lea	FileName,a2
	lea	FileReqName,a3
	lea	tags,a0
	move.l	ScreenBase,4(a0)
	jsr	-54(a6)
	move.l	#0,d6
	tst.l	d0
	beq	Koniec_FileReq
	move.l	#1,d6
	lea	FullName,a2
	move.l	FilReq,a1
	move.l	$10(a1),a1
Loop_Katalog:
	move.b	(a1)+,(a2)+
	bne	Loop_Katalog
	suba.l	#2,a2
	move.b	(a2)+,d0
	cmpi.b	#0,d0
	beq	Kopiuj_Plik
	cmpi.b	#$3a,d0
	beq	Kopiuj_Plik
	move.b	#$2f,(a2)+
Kopiuj_Plik:
	lea	FileName,a0
Kopiuj_Plik_:
	move.b	(a0)+,(a2)+
	bne	Kopiuj_Plik_
	move.b	#0,(a2)+
Koniec_FileReq:	
	move.l	FilReq,a1
	jsr	-36(a6)
	movem.l	(sp)+,d1-d5/a0-a6
	move.l	d6,d0
	rts

*******************************

DirReq:
	movem.l	d1-d5/a0-a6,-(sp)
	move.l	#FileName,a1
	move.l	#400,d0
	bsr	CLR_STR
	move.l	ReqBase,a6
	moveq	#0,d0
	lea	$0,a0
	jsr	-30(a6)
	move.l	d0,FilReq
	tst	d0
	bne	Skok_Ful1
	lea	FileReqError.TX,a1
	bsr	ReqRequest
	movem.l	(sp)+,d1-d5/a0-a6
	move.l	#0,d0
	rts
Skok_Ful1:
	move.l	FilReq,a1
	lea	FileName,a2
	lea	FileReqName,a3
	lea	tags1,a0
	move.l	ScreenBase,4(a0)
	jsr	-54(a6)
	move.l	#0,d6
	tst.l	d0
	beq	Koniec_FileReq1
	move.l	#1,d6
	lea	FullName,a2
	move.l	FilReq,a1
	move.l	$10(a1),a1
Loop_Katalog1:
	move.b	(a1)+,(a2)+
	bne	Loop_Katalog1
	suba.l	#2,a2
	move.b	(a2)+,d0
	cmpi.b	#0,d0
	beq	Kopiuj_Plik1
	cmpi.b	#$3a,d0
	beq	Kopiuj_Plik1
	move.b	#$2f,(a2)+
Kopiuj_Plik1:
	lea	FileName,a0
Kopiuj_Plik_1:
	move.b	(a0)+,(a2)+
	bne	Kopiuj_Plik_1
	move.b	#0,(a2)+
Koniec_FileReq1:	
	move.l	FilReq,a1
	jsr	-36(a6)
	movem.l	(sp)+,d1-d5/a0-a6
	move.l	d6,d0
	rts

*******************************

CreateGadget:
	movem.l	d1-a6,-(sp)
	move.l	GadBase,a6
	lea	GadList,a0
	jsr	_LVOCreateConText(a6)
	tst.l	d0
	beq	ErrorCreate.PROC
	move.l	d0,d7
	move.l	d0,CONTEXT_WP



	move.l	#CHECKBOX_KIND,d0
	move.l	d7,a0
	lea	BUTTON_1,a1
	move.l	Visual,d1
	move.l	d1,22(a1)
	lea	TAGLISTMX1,a2
	jsr	_LVOCreateGadget(a6)
	tst.l	d0
	beq	ErrorCreate.PROC
	move.l	d0,d7
	move.l	d0,GADGET_NR1

	move.l	#CHECKBOX_KIND,d0
	move.l	d7,a0
	lea	BUTTON_2,a1
	move.l	Visual,d1
	move.l	d1,22(a1)
	lea	TAGLISTMX2,a2
	jsr	_LVOCreateGadget(a6)
	tst.l	d0
	beq	ErrorCreate.PROC
	move.l	d0,d7
	move.l	d0,GADGET_NR2

	move.l	#CHECKBOX_KIND,d0
	move.l	d7,a0
	lea	BUTTON_3,a1
	move.l	Visual,d1
	move.l	d1,22(a1)
	lea	TAGLISTMX3,a2
	jsr	_LVOCreateGadget(a6)
	tst.l	d0
	beq	ErrorCreate.PROC
	move.l	d0,d7
	move.l	d0,GADGET_NR3

	move.l	#MX_KIND,d0
	move.l	d7,a0
	lea	BUTTON_4,a1
	move.l	Visual,d1
	move.l	d1,22(a1)
	lea	MX_TAGLIST,a2
	jsr	_LVOCreateGadget(a6)
	tst.l	d0
	beq	ErrorCreate.PROC
	move.l	d0,d7
	move.l	d0,GADGET_NR4

	move.l	#BUTTON_KIND,d0
	move.l	d7,a0
	lea	BUTTON_5,a1
	move.l	Visual,d1
	move.l	d1,22(a1)
	lea	$0,a2
	jsr	_LVOCreateGadget(a6)
	tst.l	d0
	beq	ErrorCreate.PROC
	move.l	d0,d7
	move.l	d0,GADGET_NR5

	move.l	#BUTTON_KIND,d0
	move.l	d7,a0
	lea	BUTTON_6,a1
	move.l	Visual,d1
	move.l	d1,22(a1)
	lea	$0,a2
	jsr	_LVOCreateGadget(a6)
	tst.l	d0
	beq	ErrorCreate.PROC
	move.l	d0,d7
	move.l	d0,GADGET_NR6

	move.l	#BUTTON_KIND,d0
	move.l	d7,a0
	lea	BUTTON_7,a1
	move.l	Visual,d1
	move.l	d1,22(a1)
	lea	$0,a2
	jsr	_LVOCreateGadget(a6)
	tst.l	d0
	beq	ErrorCreate.PROC
	move.l	d0,d7
	move.l	d0,GADGET_NR7

	bra	OK.CCT
ErrorCreate.PROC:
	moveq	#0,d0
OK.CCT:	movem.l	(sp)+,d1-a6
	tst.l	d0
	rts

FreeGadget:
	movem.l	d0-a6,-(sp)
	move.l	GadBase,a6
	move.l	CONTEXT_WP,a0
	jsr	_LVOFreeGadgets(a6)
	movem.l	(sp)+,d0-a6
	rts

ClrReg:	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
	moveq	#0,d3
	moveq	#0,d4
	moveq	#0,d5
	moveq	#0,d6
	moveq	#0,d7
	move.l	#0,a0
	move.l	#0,a1
	move.l	#0,a2
	move.l	#0,a3
	move.l	#0,a4
	move.l	#0,a5
	move.l	#0,a6
	rts

ClearTextBuffor:
	movem.l	d0-a6,-(sp)
	lea	TextBuffor,a0
	move.l	#79,d0
CTB_Loop:
	move.b	#' ',(a0)+
	dbra	d0,CTB_Loop
	movem.l	(sp)+,d0-a6
	rts

CLL:	movem.l	d0-a6,-(sp)
	moveq	#0,d2
	moveq	#1,d3
	lea	Cll.txt,a0
	bsr	PrintText
	movem.l	(sp)+,d0-a6
	rts

Memory_Refresh:
	movem.l	d0-a6,-(sp)
	move.l	EXEC.W,a6		
	move.l	#MEMF_CHIP,d1
	moveq	#0,d0
	jsr	_LVOAvailMem(a6)
	move.l	d0,d7
	move.l	#MEMF_FAST,d1		
	moveq	#0,d0
	jsr	_LVOAvailMem(a6)
	move.l	d0,d6

	move.l	d7,d0
	lea	ChipBuffor,a1
	move.l	#0,(a1)+
	move.l	#0,(a1)+
	move.l	#0,(a1)
	lea	ChipBuffor,a1
	movem.l	d7,-(sp)
	moveq	#0,d7
	bsr	Conwert
	movem.l	(sp)+,d7
	moveq	#120,d0
	moveq	#9,d1
	bsr	CLL
	moveq	#1,d2
	moveq	#0,d3
	lea	ChipBuffor,a0
	bsr	PrintText

	move.l	d6,d0
	lea	FastBuffor,a1
	move.l	#0,(a1)+
	move.l	#0,(a1)+
	move.l	#0,(a1)
	lea	FastBuffor,a1
	movem.l	d7,-(sp)
	moveq	#0,d7
	bsr	Conwert
	movem.l	(sp)+,d7
	moveq	#120,d0
	moveq	#19,d1
	bsr	CLL
	moveq	#1,d2
	moveq	#0,d3
	lea	FastBuffor,a0
	bsr	PrintText

	move.l	d7,d0
	add.l	d6,d0
	lea	RazemBuffor,a1
	move.l	#0,(a1)+
	move.l	#0,(a1)+
	move.l	#0,(a1)
	lea	RazemBuffor,a1
	movem.l	d7,-(sp)
	moveq	#0,d7
	bsr	Conwert
	movem.l	(sp)+,d7
	moveq	#120,d0
	moveq	#29,d1
	bsr	CLL
	moveq	#1,d2
	moveq	#0,d3
	lea	RazemBuffor,a0
	bsr	PrintText

	movem.l	(sp)+,d0-a6
	rts

Memory:	movem.l	d0-a6,-(sp)
	moveq	#20,d0
	moveq	#10,d1
	moveq	#1,d2
	moveq	#0,d3
	lea	MemCHIP,a0
	bsr	PrintText
	moveq	#20,d0
	moveq	#20,d1
	moveq	#1,d2
	moveq	#0,d3
	lea	MemFAST,a0
	bsr	PrintText
	moveq	#20,d0
	moveq	#30,d1
	moveq	#1,d2
	moveq	#0,d3
	lea	MemRAZEM,a0
	bsr	PrintText
	moveq	#20,d0
	moveq	#9,d1
	moveq	#2,d2
	moveq	#0,d3
	lea	MemCHIP,a0
	bsr	PrintText
	moveq	#20,d0
	moveq	#19,d1
	moveq	#2,d2
	moveq	#0,d3
	lea	MemFAST,a0
	bsr	PrintText
	moveq	#20,d0
	moveq	#29,d1
	moveq	#2,d2
	moveq	#0,d3
	lea	MemRAZEM,a0
	bsr	PrintText
	movem.l	(sp)+,d0-a6
	rts

Hex:	movem.l	d0-a6,-(sp)	
	moveq	#0,d1
	move.l	d0,d6
	rol.l	#4,d6
	move.l	#7,d5
	move.b	#'$',(a0)+
LoopHex:
	move.b	d6,d1
	and.b	#$0F,d1
	cmpi.b	#$9,d1
	ble	SkokHex
	add.b	#$37,d1	
	bra	Min9
SkokHex:add.b	#$30,d1
Min9:
	move.b	d1,(a0)+
	rol.l	#4,d6
	dbra	d5,LoopHex
	move.b	#0,(a0)
	movem.l	(sp)+,d0-a6
	rts

Conwert:movem.l	d0-a6,-(sp)		
	tst.l	d0
	bne	OkNie0_CON
	move.b	#$30,(a1)+
	move.b	d7,(a1)+
	bra	_0QUIT
OkNie0_CON:
	lea	DiwTable,a0
	move.l	a1,a2
	lea	BufforAscii,a1
	move.l	d0,d1
	moveq	#0,d3
	moveq	#0,d4
AsciiKonLoop:
	move.l	(a0)+,d2
	move.l	#0,d3
AsciiLoop:
	move.l	d1,d4
	sub.l	d2,d1
	bmi	OkJestMinus
	addq.b	#1,d3
	bra	AsciiLoop
OkJestMinus:
	move.l	d4,d1
	cmpi.l	#1,d2
	beq	KoniecAsciiKon2
	add.b	#'0',d3
	move.b	d3,(a1)+
	bra	AsciiKonLoop
KoniecAsciiKon2:
	add.b	#'0',d3
	move.b	d3,(a1)+
	cmp.b	#1,d2
	bne	AsciiKonLoop
	move.b	#10,(a1)+
	move.b	#0,(a1)+
	move.l	a2,a0
	lea	BufforAscii,a1
LoopCzy0:
	move.b	(a1)+,d0
	cmp.b	#'0',d0
	bne	OkJuzMamy
	bra	LoopCzy0
OkJuzMamy:
	suba.l	#1,a1
CopyLoopAscii:
	move.b	(a1)+,d0
	cmp.b	#10,d0
	beq	KoniecToJuz10
	move.b	d0,(a0)+
	bra	CopyLoopAscii
KoniecToJuz10:
	move.b	d7,(a0)+
_0QUIT:	movem.l	(sp)+,d0-a6
	rts
DiwTable:
	dc.l	1000000000,100000000,10000000,1000000,100000,10000,1000,100,10,1
BufforAscii:
	dc.b	0,0,0,0,0,0,0,0,0,0,0,0


FontToRastPort:
	movem.l	d0-a6,-(sp)
	move.l	GrBase,a6
	move.l	Font,a0
	move.l	RPort,a1
	jsr	_LVOSetFont(a6)
	movem.l	(sp)+,d0-a6
	rts

GetVisual:
	movem.l	d1-a6,-(sp)
	move.l	GadBase,a6
	move.l	WBBase,a0
	move.l	#0,a1
	jsr	_LVOGetVisualInfoA(a6)
	move.l	d0,Visual
	movem.l	(sp)+,d1-a6
	tst.l	d0
	rts

FreeVisual:
	movem.l	d0-a6,-(sp)
	move.l	GadBase,a6
	move.l	Visual,a0
	jsr	_LVOFreeVisualInfo(a6)
	movem.l	(sp)+,d0-a6
	rts

CrMenu:	movem.l	d1-a6,-(sp)
	move.l	GadBase,a6
	lea	MenuStructure,a0	
	move.l	#0,a1
	jsr	_LVOCreateMenusA(a6)
	move.l	d0,MenuADR
	tst.l	d0
	beq	ErrMen
	move.l	MenuADR,a0		
	move.l	Visual,a1
	lea	TagListMenu,a2
	cmp.l	#39,SYSTEM
	beq	System39
	move.l	#0,TagListMenu
System39:
	jsr	_LVOLayoutMenusA(a6)
	cmp.l	#1,d0
	bne	ErrMFR
	move.l	InitBase,a6		
	move.l	WindowBase,a0
	move.l	MenuADR,a1
	jsr	_LVOSetMenuStrip(a6)
OKMenu:	movem.l	(sp)+,d1-a6
	moveq	#0,d0
	tst.l	d0
	rts
ErrMFR:	move.l	GadBase,a6
	move.l	MenuADR,a0
	jsr	_LVOFreeMenus(a6)
ErrMen:	movem.l	(sp)+,d1-a6
	moveq	#-1,d0	
	tst.l	d0
	rts

CloseMenu:
	movem.l	d0-a6,-(sp)
	move.l	InitBase,a6
	move.l	WindowBase,a0
	jsr	_LVOClearMenuStrip(a6)
	move.l	GadBase,a6
	move.l	MenuADR,a0
	jsr	_LVOFreeMenus(a6)
	movem.l	(sp)+,d0-a6
	rts

PrintLine_X:				
	movem.l	d0-a6,-(sp)
	add.l	#8,LINE_NR
	cmp.l	#42+(24*8),LINE_NR
	beq	SCROLL_LINE_X
	move.l	d1,d0
	move.l	LINE_NR,d1
	moveq	#1,d3
	bsr	PrintText
	movem.l	(sp)+,d0-a6
	rts

SCROLL_LINE_X:
	bsr	SCROLL
	move.l	d1,d0
	move.l	LINE_NR,d1
	moveq	#1,d3
	bsr	PrintText
	movem.l	(sp)+,d0-a6
	rts

PrintLine:				
	movem.l	d0-a6,-(sp)
	add.l	#8,LINE_NR
	cmp.l	#42+(24*8),LINE_NR
	beq	SCROLL_LINE
	moveq	#10,d0
	move.l	LINE_NR,d1
	moveq	#1,d3
	bsr	PrintText
	movem.l	(sp)+,d0-a6
	rts
SCROLL_LINE:
	bsr	SCROLL
	moveq	#10,d0
	move.l	LINE_NR,d1
	moveq	#1,d3
	bsr	PrintText
	movem.l	(sp)+,d0-a6
	rts
SCROLL:	movem.l	d0-a6,-(sp)
	lea	BitMap_1+(69*80),a0
	lea	BitMap_2+(69*80),a1
	lea	BitMap_1+(61*80),a2
	lea	BitMap_2+(61*80),a3
	move.l	#(256*20)-(69*20)-1,d0
SCROLL_LOOP:
	move.l	(a0)+,(a2)+
	move.l	(a1)+,(a3)+
	dbf	d0,SCROLL_LOOP
	move.l	#10*20,d0
	lea	BitMap_1+(241*80),a0
	lea	BitMap_2+(241*80),a1
SCROLL_LOOP2:
	move.l	#0,(a0)+
	move.l	#0,(a1)+
	dbf	d0,SCROLL_LOOP2
	sub.l	#8,LINE_NR
	movem.l	(sp)+,d0-a6
	rts

CLW:	movem.l	d0-a6,-(sp)
	lea	BitMap_1+(61*80),a2
	lea	BitMap_2+(61*80),a3
	move.l	#(256*20)-(69*20)-1,d0
Loop_CLW:
	move.l	#0,(a2)+
	move.l	#0,(a3)+
	dbra	d0,Loop_CLW
	movem.l	(sp)+,d0-a6
	rts

PrintText:
	movem.l	d0-a6,-(sp)
	lea	Text.STR,a1
	move.b	d2,(a1)
	move.b	d3,2(a1)
	move.l	a0,12(a1)
	move.l	InitBase,a6
	move.l	RPort,a0
	lea	Text.STR,a1
	jsr	_LVOPrintIText(a6)
	movem.l	(sp)+,d0-a6
	rts

WaitMouse:
	btst	#6,$bfe001
	bne	WaitMouse
WaitMouse.
	btst	#6,$bfe001
	beq	WaitMouse.
	rts

DrawLine:
	movem.l	d0-a6,-(sp)
	move.l	InitBase,a6
	moveq	#0,d0
	moveq	#50-4,d1
	lea	_Border,a1
	move.l	RPort,a0
	jsr	_LVODrawBorder(a6)
	movem.l	(sp)+,d0-a6
	rts

OpenWindow:
	movem.l	d1-a6,-(sp)
	move.l	InitBase,a6
	move.l	#0,a0
	lea	WindowTagList,a1
	cmp.l	#39,SYSTEM
	beq	System39_1
	lea	WindowTagList36,a1
System39_1:
	jsr	_LVOOpenWindowTagList(a6)
	move.l	d0,WindowBase
	move.l	d0,a0
	move.l	wd_RPort(a0),RPort
	movem.l	(sp)+,d1-a6
	tst.l	d0
	rts	

CloseWindow:
	movem.l	d1-a6,-(sp)
	move.l	InitBase,a6
	move.l	WindowBase,a0
	jsr	_LVOCloseWindow(a6)
	movem.l	(sp)+,d1-a6
	rts

OpenScreen:
	movem.l	d1-a6,-(sp)
	move.l	InitBase,a6
	move.l	_DrawInfo,a1
	move.l	dri_Pens(a1),a1
	lea	ScreenTagList,a0
	move.l	a1,15*4(a0)
	move.l	#0,a0
	lea	ScreenTagList,a1
	jsr	_LVOOpenScreenTagList(a6)
	move.l	d0,ScreenBase
	move.l	d0,ScreenBase_1
	move.l	d0,ScreenBase_2
	movem.l	(sp)+,d1-a6
	tst.l	d0
	rts

CloseScreen:
	movem.l	d0-a6,-(sp)
	move.l	InitBase,a6
	move.l	ScreenBase,a0
	jsr	_LVOCloseScreen(a6)
	movem.l	(sp)+,d0-a6
	rts

GetDrawInfo:
	movem.l	d1-a6,-(sp)
	move.l	InitBase,a6
	move.l	WBBase,a0
	jsr	_LVOGetScreenDrawInfo(a6)
	move.l	d0,_DrawInfo
	movem.l	(sp)+,d1-a6
	tst.l	d0
	rts

FreeDrawInfo:
	movem.l	d0-a6,-(sp)
	move.l	InitBase,a6
	move.l	_DrawInfo,a1
	move.l	#0,a0
	jsr	_LVOFreeScreenDrawInfo(a6)
	movem.l	(sp)+,d0-a6
	rts

LockPubScreen:
	movem.l	d1-a6,-(sp)
	move.l	InitBase,a6
	lea	WBName,a0
	jsr	_LVOLockPubScreen(a6)
	move.l	d0,WBBase
	movem.l	(sp)+,d1-a6
	tst.l	d0
	rts

UnLockPubScreen:
	movem.l	d1-a6,-(sp)
	move.l	InitBase,a6
	move.l	#0,a0
	move.l	WBBase,a1
	jsr	_LVOUnlockPubScreen(a6)
	movem.l	(sp)+,d1-a6
	rts

CloseFont:
	movem.l	d0-a6,-(sp)
	move.l	GrBase,a6
	move.l	Font,a1
	jsr	_LVOCloseFont(a6)
	movem.l	(sp)+,d0-a6
	rts

OpenVIREXFont:
	movem.l	d1-a6,-(sp)
	move.l	DFBase,a6
	lea	TextATTR,a0
	lea	FontName,a1
	move.l	a1,(a0)
	jsr	_LVOOpenDiskFont(a6)
	move.l	d0,Font
	movem.l	(sp)+,d1-a6
	tst.l	d0
	rts	

OpenIntuition:
	movem.l	d1-a6,-(sp)
	move.l	EXEC.W,a6
	lea	InitName,a1
	moveq	#39,d0
	jsr	_LVOOldOpenLibrary(a6)
	tst.l	d0
	bne	OkSystem39
	lea	InitName,a1
	moveq	#36,d0
	jsr	_LVOOldOpenLibrary(a6)
	move.l	#36,SYSTEM
	bra	OkSystem36
OkSystem39:
	move.l	#39,SYSTEM
OkSystem36:
	move.l	d0,InitBase
	movem.l	(sp)+,d1-a6
	tst.l	d0
	rts

CloseIntuition:
	movem.l	d0-a6,-(sp)
	move.l	EXEC.W,a6
	move.l	InitBase,a1
	jsr	_LVOCloseLibrary(a6)
	movem.l	(sp)+,d0-a6
	rts

OpenReqTools:
	movem.l	d1-a6,-(sp)
	move.l	EXEC.W,a6
	lea	ReqName,a1
	moveq	#0,d0
	jsr	_LVOOldOpenLibrary(a6)
	move.l	d0,ReqBase
	movem.l	(sp)+,d1-a6
	tst.l	d0
	rts

OpenXVS:movem.l	d1-a6,-(sp)
	move.l	EXEC.W,a6
	lea	XVSName,a1
	moveq	#0,d0
	jsr	_LVOOldOpenLibrary(a6)
	move.l	d0,XVSBase
	movem.l	(sp)+,d1-a6
	tst.l	d0
	rts

CloseXVS:
	movem.l	d0-a6,-(sp)
	move.l	EXEC.W,a6
	move.l	XVSBase,a1
	jsr	_LVOCloseLibrary(a6)
	movem.l	(sp)+,d0-a6
	rts

CloseReqTools:
	movem.l	d0-a6,-(sp)
	move.l	EXEC.W,a6
	move.l	ReqBase,a1
	jsr	_LVOCloseLibrary(a6)
	movem.l	(sp)+,d0-a6
	rts

OpenDiskFont:
	movem.l	d1-a6,-(sp)
	move.l	EXEC.W,a6
	lea	DFName,a1
	moveq	#0,d0
	jsr	_LVOOldOpenLibrary(a6)
	move.l	d0,DFBase
	movem.l	(sp)+,d1-a6
	tst.l	d0
	rts

CloseDiskFont:
	movem.l	d0-a6,-(sp)
	move.l	EXEC.W,a6
	move.l	DFBase,a1
	jsr	_LVOCloseLibrary(a6)
	movem.l	(sp)+,d0-a6
	rts

OpenGadTools:
	movem.l	d1-a6,-(sp)
	move.l	EXEC.W,a6
	lea	GadName,a1
	moveq	#0,d0
	jsr	_LVOOldOpenLibrary(a6)
	move.l	d0,GadBase
	movem.l	(sp)+,d1-a6
	tst.l	d0
	rts

CloseGadTools:
	movem.l	d0-a6,-(sp)
	move.l	EXEC.W,a6
	move.l	GadBase,a1
	jsr	_LVOCloseLibrary(a6)
	movem.l	(sp)+,d0-a6
	rts

OpenDos:
	movem.l	d1-a6,-(sp)
	move.l	EXEC.W,a6
	lea	DosName,a1
	moveq	#0,d0
	jsr	_LVOOldOpenLibrary(a6)
	move.l	d0,DosBase
	movem.l	(sp)+,d1-a6
	tst.l	d0
	rts

OpenBootBlock:
	movem.l	d1-a6,-(sp)
	move.l	EXEC.W,a6
	lea	BootName,a1
	moveq	#0,d0
	jsr	_LVOOldOpenLibrary(a6)
	move.l	d0,BootBase
	movem.l	(sp)+,d1-a6
	tst.l	d0
	rts

CloseBootBlock:
	movem.l	d0-a6,-(sp)
	move.l	EXEC.W,a6
	move.l	BootBase,a1
	jsr	_LVOCloseLibrary(a6)
	movem.l	(sp)+,d0-a6
	rts

CloseDos:
	movem.l	d0-a6,-(sp)
	move.l	EXEC.W,a6
	move.l	DosBase,a1
	jsr	_LVOCloseLibrary(a6)
	movem.l	(sp)+,d0-a6
	rts

OpenGr:
	movem.l	d1-a6,-(sp)
	move.l	EXEC.W,a6
	lea	GrName,a1
	moveq	#0,d0
	jsr	_LVOOldOpenLibrary(a6)
	move.l	d0,GrBase
	movem.l	(sp)+,d1-a6
	tst.l	d0
	rts

CloseGr:
	movem.l	d0-a6,-(sp)
	move.l	EXEC.W,a6
	move.l	GrBase,a1
	jsr	_LVOCloseLibrary(a6)
	movem.l	(sp)+,d0-a6
	rts

IntRequest:
	movem.l	d0-a6,-(sp)
	move.l	InitBase,a6
	lea	_EasyStruct,a1
	move.l	a0,3*4(a1)
	moveq	#0,d0
	move.l	#0,a0
	lea	_EasyStruct,a1
	move.l	#0,a2
	move.l	#0,a3
	jsr	_LVOEasyRequestArgs(a6)
	movem.l	(sp)+,d0-a6
	rts	

ReqRequestTAKNIE:
	movem.l	d1-a6,-(sp)
	move.l	ReqBase,a6
	lea	TakNie.txt,a1
	lea	TAGS,a0
	move.l	ScreenBase,9*4(a0)
	move.l	#TextATTR,11*4(a0)
	lea	TakNie.gad,a2
	move.l	#0,a3
	move.l	#0,a4
	jsr	-66(a6)
	movem.l	(sp)+,d1-a6
	rts

ReqRequest:
	movem.l	d0-a6,-(sp)
	move.l	ReqBase,a6
	lea	TAGS,a0
	move.l	ScreenBase,9*4(a0)
	move.l	#TextATTR,11*4(a0)
	lea	GAD.OK,a2
	move.l	#0,a3
	move.l	#0,a4
	jsr	-66(a6)
	movem.l	(sp)+,d0-a6
	rts

ReqRequestGAD:
	movem.l	d1-a6,-(sp)
	move.l	ReqBase,a6
	move.l	a0,a2
	lea	TAGS,a0
	move.l	ScreenBase,9*4(a0)
	move.l	#TextATTR,11*4(a0)
	move.l	#0,a3
	move.l	#0,a4
	jsr	-66(a6)
	movem.l	(sp)+,d1-a6
	rts

ReqRequestGAD_1:
	movem.l	d1-a6,-(sp)
	move.l	ReqBase,a6
	move.l	a0,a2
	lea	TAGS_1,a0
	move.l	ScreenBase,9*4(a0)
	move.l	#TextATTR,11*4(a0)
	move.l	#0,a3
	move.l	#0,a4
	jsr	-66(a6)
	movem.l	(sp)+,d1-a6
	rts

**************************
*    Procedury Error	 *
**************************

ErrorInt:
	rts
ErrorReq:
	lea	ReqError.txt,a0
	bsr	IntRequest
	bsr	CloseIntuition
	bsr	CloseBootBlock
	rts

ErrorDF:
	lea	DFError.txt,a0
	bsr	IntRequest
	bsr	CloseIntuition
	bsr	CloseBootBlock
	bsr	CloseReqTools
	rts

ErrorGadTools:
	lea	GadError.txt,a0
	bsr	IntRequest
	bsr	CloseIntuition
	bsr	CloseBootBlock
	bsr	CloseReqTools
	bsr	CloseDiskFont
	rts

ErrorDos:
	lea	DosError.txt,a0
	bsr	IntRequest
	bsr	CloseIntuition
	bsr	CloseBootBlock
	bsr	CloseReqTools
	bsr	CloseDiskFont
	bsr	CloseGadTools
	rts

ErrorGr:
	lea	GrError.txt,a0
	bsr	IntRequest
	bsr	CloseIntuition
	bsr	CloseBootBlock
	bsr	CloseReqTools
	bsr	CloseDiskFont
	bsr	CloseGadTools
	bsr	CloseDos
	rts

ErrorFont:
	lea	FontError.txt,a0
	bsr	IntRequest
	bra	CloseLibraries

ErrorLock:
	lea	LockError.txt,a0
	bsr	IntRequest
	bra	LOCK.ET

ErrorDraw:
	lea	LockError.txt,a0
	bsr	IntRequest
	bra	LOCH.DI

ErrorScreen:
	lea	ScreenError.txt,a0
	bsr	IntRequest
	bra	LOCK.SR

ErrorWindow:
	lea	WindowError.txt,a0
	bsr	IntRequest
	bra	LOCK.WA

ErrorMenu:
	lea	MenuError.txt,a1
	bsr	ReqRequest
	bra	LOCK.MN

ErrorVisual:
	lea	VisualError.txt,a1
	bsr	ReqRequest
	bra	LOCK.MN

ErrorGadget:
	lea	GadgetError.txt,a1
	bsr	ReqRequest
	bra	LOCK.FR

ErrorTrackDisk:
	lea	TrackDError.txt,a1
	bsr	ReqRequest
	bra	LOCK.TD

ErrorXVS:
	lea	XVSError.txt,a1
	bsr	ReqRequest
	bra	LOCK.XVS

ErrorBoot:
	lea	BootError.txt,a1
	bsr	IntRequest
	bra	LOCK.BOT

END_CODE:

*******************
*    Struktury	  *
*******************

	SECTION DANE,DATA_C

BUTTON_1:
	dc.w	200,5,20,10
	dc.l	BUTTON_1.txt,TextATTR
	dc.w	1
	dc.l	PLACETEXT_RIGHT
	dc.l	0
	dc.l	1,0	

BUTTON_2:
	dc.w	200,17,20,10
	dc.l	BUTTON_2.txt,TextATTR
	dc.w	2
	dc.l	PLACETEXT_RIGHT
	dc.l	0
	dc.l	1,0

BUTTON_3:
	dc.w	200,29,20,10
	dc.l	BUTTON_3.txt,TextATTR
	dc.w	3
	dc.l	PLACETEXT_RIGHT
	dc.l	0
	dc.l	1,0

BUTTON_4:
	dc.w	480,5,10,50
	dc.l	0,TextATTR
	dc.w	4
	dc.l	PLACETEXT_RIGHT
	dc.l	0
	dc.l	1,0

BUTTON_5:
	dc.w	555,4,70,12
	dc.l	BUTTON_5.txt,TextATTR
	dc.w	5
	dc.l	PLACETEXT_IN
	dc.l	0
	dc.l	1,0

BUTTON_6:
	dc.w	555,17,70,12
	dc.l	BUTTON_6.txt,TextATTR
	dc.w	6
	dc.l	PLACETEXT_IN
	dc.l	0
	dc.l	1,0

BUTTON_7:
	dc.w	555,30,70,12
	dc.l	BUTTON_7.txt,TextATTR
	dc.w	7
	dc.l	PLACETEXT_IN
	dc.l	0
	dc.l	1,0

BUTTON_KIND_OK:
	dc.w	(210/2)-(70/2),140-12-5+1,70,12
	dc.l	BUTTON_8.txt,TextATTR
	dc.w	1
	dc.l	PLACETEXT_IN
	dc.l	0
	dc.l	1,0

BUTTON_LISTVIEW_OK:
	dc.w	5,14,200,110
	dc.l	0,TextATTR
	dc.w	2
	dc.l	0
	dc.l	0
	dc.l	0,0

LV_TAGLIST:
	dc.l	GTLV_Labels,0
	dc.l	0,0

TAGLISTMX1:
	dc.l	GTCB_Checked,1
	dc.l	GA_Disabled,0
	dc.l	0,0

TAGLISTMX2:
	dc.l	GTCB_Checked,1
	dc.l	GA_Disabled,0
	dc.l	0,0

TAGLISTMX3:
	dc.l	GTCB_Checked,0
	dc.l	GA_Disabled,0
	dc.l	0,0

TAGLIST_ON:
	dc.l	GA_Disabled,0
	dc.l	0,0

TAGLIST_OFF:
	dc.l	GA_Disabled,1
	dc.l	0,0

MX_TAGLIST:
	dc.l	GTMX_Active,0
	dc.l	GTMX_Labels,DriveTable
	dc.l	0,0


MenuStructure:
	dc.b	NM_TITLE,0
	dc.l	MTitle1,0
	dc.w	0
	dc.l	0,0
	dc.b	NM_ITEM,0
	dc.l	MItem1,Key1
	dc.w	0
	dc.l	0,0
	dc.b	NM_ITEM,0
	dc.l	MItem2,Key2
	dc.w	0
	dc.l	0,0
	dc.b	NM_ITEM,0
	dc.l	MItem2_1,Key2_1
	dc.w	0
	dc.l	0,0
	dc.b	NM_ITEM,0
	dc.l	MItem2_2,0
	dc.w	0
	dc.l	0,0
	dc.b	NM_SUB,0
	dc.l	MSubItem6,0
	dc.w	0
	dc.l	0,0
	dc.b	NM_SUB,0
	dc.l	MSubItem7,0
	dc.w	0
	dc.l	0,0
	dc.b	NM_SUB,0
	dc.l	MSubItem8,0
	dc.w	0
	dc.l	0,0

	dc.b	NM_ITEM,0
	dc.l	$FFFFFFFF,0
	dc.w	0
	dc.l	0,0
	dc.b	NM_ITEM,0
	dc.l	MItem3,Key3
	dc.w	0
	dc.l	0,0

	dc.b	NM_TITLE,0
	dc.l	MTitle8,0
	dc.w	0
	dc.l	0,0
	dc.b	NM_ITEM,0
	dc.l	MItem49,Key49
	dc.w	0
	dc.l	0,0
	dc.b	NM_ITEM,0
	dc.l	MItem50,Key50
	dc.w	0
	dc.l	0,0

	dc.b	NM_TITLE,0
	dc.l	MTitle2,0
	dc.w	0
	dc.l	0,0
	dc.b	NM_ITEM,0
	dc.l	MItem4,Key4
	dc.w	0
	dc.l	0,0
	dc.b	NM_ITEM,0
	dc.l	MItem5,Key5
	dc.w	0
	dc.l	0,0
	dc.b	NM_ITEM,0
	dc.l	MItem6,Key6
	dc.w	0
	dc.l	0,0
	dc.b	NM_ITEM,0
	dc.l	MItem16,Key16
	dc.w	0
	dc.l	0,0
	dc.b	NM_ITEM,0
	dc.l	$FFFFFFFF,0
	dc.w	0
	dc.l	0,0
	dc.b	NM_ITEM,0
	dc.l	MItem7,Key7
	dc.w	0
	dc.l	0,0
	dc.b	NM_ITEM,0
	dc.l	MItem8,Key8
	dc.w	0
	dc.l	0,0
	dc.b	NM_ITEM,0
	dc.l	MItem9,0
	dc.w	0
	dc.l	0,0
	dc.b	NM_ITEM,0
	dc.l	MItem10,Key10
	dc.w	0
	dc.l	0,0
	dc.b	NM_ITEM,0
	dc.l	MItem11,Key11
	dc.w	0
	dc.l	0,0
	dc.b	NM_ITEM,0
	dc.l	$FFFFFFFF,0
	dc.w	0
	dc.l	0,0
	dc.b	NM_ITEM,0
	dc.l	MItem12,Key12
	dc.w	0
	dc.l	0,0
	dc.b	NM_ITEM,0
	dc.l	MItem13,Key13
	dc.w	0
	dc.l	0,0
	dc.b	NM_ITEM,0
	dc.l	MItem14,Key14
	dc.w	0
	dc.l	0,0

	dc.b	NM_TITLE,0
	dc.l	MTitle3,0
	dc.w	0
	dc.l	0,0
	dc.b	NM_ITEM,0
	dc.l	MItem17,Key17
	dc.w	0
	dc.l	0,0
	dc.b	NM_ITEM,0
	dc.l	MItem18,Key18
	dc.w	0
	dc.l	0,0
	dc.b	NM_ITEM,0
	dc.l	MItem20,Key20
	dc.w	0
	dc.l	0,0
	dc.b	NM_ITEM,0
	dc.l	$FFFFFFFF,0
	dc.w	0
	dc.l	0,0
	dc.b	NM_ITEM,0
	dc.l	MItem21,Key21
	dc.w	0
	dc.l	0,0
	dc.b	NM_ITEM,0
	dc.l	MItem52,Key52
	dc.w	0
	dc.l	0,0

	dc.b	NM_TITLE,0
	dc.l	MTitle4,0
	dc.w	0
	dc.l	0,0
	dc.b	NM_ITEM,0
	dc.l	MItem22,0
	dc.w	0
	dc.l	0,0

	dc.b	NM_SUB,0
	dc.l	MSubItem4,Key47
	dc.w	0
	dc.l	0,0
	dc.b	NM_SUB,0
	dc.l	MSubItem5,Key48
	dc.w	0
	dc.l	0,0

	dc.b	NM_ITEM,0
	dc.l	MItem23,Key23
	dc.w	0
	dc.l	0,0
	dc.b	NM_ITEM,0
	dc.l	$FFFFFFFF,0
	dc.w	0
	dc.l	0,0
	dc.b	NM_ITEM,0
	dc.l	MItem24,Key24
	dc.w	0
	dc.l	0,0
	dc.b	NM_ITEM,0
	dc.l	MItem25,Key25
	dc.w	0
	dc.l	0,0
	dc.b	NM_ITEM,0
	dc.l	MItem26,Key26
	dc.w	0
	dc.l	0,0
	dc.b	NM_ITEM,0
	dc.l	MItem27,Key27
	dc.w	0
	dc.l	0,0
	dc.b	NM_ITEM,0
	dc.l	MItem28,Key28
	dc.w	0
	dc.l	0,0
	
	dc.b	NM_TITLE,0
	dc.l	MTitle5,0
	dc.w	0
	dc.l	0,0
	dc.b	NM_ITEM,0
	dc.l	MItem29,Key29
	dc.w	0
	dc.l	0,0
	dc.b	NM_ITEM,0
	dc.l	MItem30,Key30
	dc.w	0
	dc.l	0,0

	dc.b	NM_TITLE,0
	dc.l	MTitle6,0
	dc.w	0
	dc.l	0,0
	dc.b	NM_ITEM,0
	dc.l	MItem33,Key33
	dc.w	0
	dc.l	0,0
	dc.b	NM_ITEM,0
	dc.l	MItem34,Key34
	dc.w	0
	dc.l	0,0

	dc.b	NM_TITLE,0
	dc.l	MTitle7,0
	dc.w	0
	dc.l	0,0
	dc.b	NM_ITEM,0
	dc.l	MItem38,Key38
	dc.w	0
	dc.l	0,0
	dc.b	NM_ITEM,0
	dc.l	MItem39,Key39
	dc.w	0
	dc.l	0,0
	dc.b	NM_ITEM,0
	dc.l	MItem40,0
	dc.w	0
	dc.l	0,0

	dc.b	NM_SUB,0
	dc.l	MSubItem1,Key44
	dc.w	0
	dc.l	0,0
	dc.b	NM_SUB,0
	dc.l	MSubItem2,Key45
	dc.w	0
	dc.l	0,0

	dc.b	NM_ITEM,0
	dc.l	MItem41,Key41
	dc.w	0
	dc.l	0,0
	dc.b	NM_ITEM,0
	dc.l	MItem42,Key42
	dc.w	0
	dc.l	0,0
	dc.b	NM_ITEM,0
	dc.l	MItem43,Key43
	dc.w	0
	dc.l	0,0

	dc.b	NM_END
	dc.l	0,0
	dc.w	0
	dc.l	0,0

TextATTR:
	dc.l	0
	dc.w	8
	dc.b	0
	dc.b	0
	dc.w	8

TagListMenu:
	dc.l	GTMN_NewLookMenus,1
	dc.l	0,0

ScreenTagList:
	dc.l	SA_Width,640
	dc.l	SA_Height,256
	dc.l	SA_Depth,2
	dc.l	SA_Title,ScreenTitle
	dc.l	SA_Type,PUBLICSCREEN
	dc.l	SA_PubName,PubScreenName
	dc.l	SA_DisplayID,DEFAULT_MONITOR_ID!HIRES_KEY
	dc.l	SA_Pens,0
	dc.l	SA_Font,TextATTR
	dc.l	SA_BitMap,_BitMap
	dc.l	0,0

WindowTagList:
	dc.l	WA_Left,0
	dc.l	WA_Top,11
	dc.l	WA_Width,640
	dc.l	WA_Height,256-11
	dc.l	WA_IDCMP,GADGETUP!GADGETDOWN!MENUPICK!MOUSEBUTTONS!IDCMP_DISKINSERTED
	dc.l	WA_Gadgets,GadList
	dc.l	WA_Title,0
	dc.l	WA_DragBar,0
	dc.l	WA_DepthGadget,0
	dc.l	WA_CloseGadget,0
	dc.l	WA_Activate,1
	dc.l	WA_Backdrop,1
	dc.l	WA_Borderless,1
	dc.l	WA_ScreenTitle,ScreenTitle
	dc.l	WA_PubScreen
ScreenBase:
	dc.l	0
	dc.l	WA_NewLookMenus,1
	dc.l	0,0

WindowTagList36:
	dc.l	WA_Left,0
	dc.l	WA_Top,11
	dc.l	WA_Width,640
	dc.l	WA_Height,256-11
	dc.l	WA_IDCMP,GADGETUP!GADGETDOWN!MENUPICK!MOUSEBUTTONS!IDCMP_DISKINSERTED
	dc.l	WA_Gadgets,GadList
	dc.l	WA_Title,0
	dc.l	WA_DragBar,0
	dc.l	WA_DepthGadget,0
	dc.l	WA_CloseGadget,0
	dc.l	WA_Activate,1
	dc.l	WA_Backdrop,1
	dc.l	WA_Borderless,1
	dc.l	WA_ScreenTitle,ScreenTitle
	dc.l	WA_PubScreen
ScreenBase_2:
	dc.l	0
	dc.l	0,0

Window_LV.taglist:
	dc.l	WA_Left,(640/2)-105
	dc.l	WA_Top,(256/2)-(70-11)
	dc.l	WA_Width,210
	dc.l	WA_Height,140
	dc.l	WA_IDCMP,GADGETUP!CLOSEWINDOW!SCROLLERIDCMP!VANILLAKEY
	dc.l	WA_Gadgets,Gadget_LAB
	dc.l	WA_Title,WindowLV.title
	dc.l	WA_RMBTrap,1
	dc.l	WA_DragBar,1
	dc.l	WA_DepthGadget,1
	dc.l	WA_CloseGadget,1
	dc.l	WA_Activate,1
	dc.l	WA_ScreenTitle,ScreenTitle
	dc.l	WA_PubScreen
ScreenBase_1:
	dc.l	0
	dc.l	WA_SuperBitMap,_BitMap_WINDOW
	dc.l	0,0

_BitMap_WINDOW:
	dc.w	80
	dc.w	256
	dc.b	0,2
	dc.w	0
	dc.l	BitMap_3
	dc.l	BitMap_4
	dc.l	0,0,0,0,0,0

_BitMap:
	dc.w	80
	dc.w	256
	dc.b	0,2
	dc.w	0
	dc.l	BitMap_1
	dc.l	BitMap_2
	dc.l	0,0,0,0,0,0

_EasyStruct:
GADGET	dc.l	4*4
	dc.l	0
	dc.l	TITLE.INTREQ
	dc.l	0
	dc.l	GADGET.INTREQ

_Border: dc.w	0,0
	dc.b	2,0,0,2
	dc.l	LineTab_1,BorderNext
BorderNext:
	dc.w	0,0
	dc.b	1,0,0,2
	dc.l	LineTab_2,0
LineTab_1:
	dc.w	0,00
	dc.w	640,00
LineTab_2:
	dc.w	0,2
	dc.w	640,2

Text.STR:
	dc.b	3,0,2,0
	dc.w	0,0
	dc.l	0
	dc.l	0		
	dc.l	0

**** Zmienne ****

WIRUS:		dc.l	0
ANTYWIRUS:	dc.l	0
INTRO:		dc.l	0
LOADER:		dc.l	0
WIRUS_FORMAT:	dc.l	0
ZAPIS:		dc.l	0
MOJ:		dc.l	0

SYSTEM:		dc.l	0
BootBase:	dc.l	0
InitBase:	dc.l	0
ReqBase:	dc.l	0
DFBase:		dc.l	0
GadBase:	dc.l	0
DosBase:	dc.l	0
GrBase:		dc.l	0
Font:		dc.l	0
WBBase:		dc.l	0
_DrawInfo:	dc.l	0
WindowBase:	dc.l	0
RPort:		dc.l	0
LINE_NR:	dc.l	42
MenuADR:	dc.l	0
Visual:		dc.l	0
SAVE:		dc.l	0
LibraryBase:	dc.l	0
Requstery:	dc.w	1
TestDrive:	dc.w	1
KillWirus:	dc.w	0
DRIVE_NR:	dc.w	0
StanBuffora_1	dc.l	0
StanBuffora_2	dc.l	0
StanBuffora_3	dc.l	0
StanBuffora_4	dc.l	0
StanBuffora_5	dc.l	0
FilReq:		dc.l	0
FileList:	dc.l	0
ICONIFY:	dc.l	0
_ICONIFY:	dc.l	0
WBenchBase:	dc.l	0
IconLibBase:	dc.l	0
IconBase:	dc.l	0
AppIconsBase:	dc.l	0
IconPort:	dc.l	0
XVSBase:	dc.l	0
BootInfo:	dc.l	0
VirusList:	dc.l	0
WindowBaseLV:	dc.l	0
VirusFound:	dc.l	0
CheckFiles:	dc.l	0
CheckDrive:	dc.l	0
GADGET_NR1:	dc.l	0
GADGET_NR2:	dc.l	0
GADGET_NR3:	dc.l	0
GADGET_NR4:	dc.l	0
GADGET_NR5:	dc.l	0
GADGET_NR6:	dc.l	0
GADGET_NR7:	dc.l	0
A0_SAVE:	dc.l	0
A1_SAVE:	dc.l	0
CONTEXT_VL:	dc.l	0
CONTEXT_WP:	dc.l	0
BIBLIOTEKA:	dc.l	0
BIBLIOTEKA_S:	dc.w	0
LIBSIZE:	dc.l	0
BOOTNAME:	dc.l	0
ZMIANA:		dc.l	0
VIEWATTR:	dc.l	0
POCZ:		dc.l	0
KONI:		dc.l	0
D2_SAVE1:	dc.w	0
ILE_MEM:	dc.l	0
MemoryInfo:	dc.l	0
	
IORequest:	dcb.b	48,0
MsgPort:	dcb.b	34,0

**** Texty ****

Cll.txt:	dc.b	$20,$20,$20,$20,$20,$20,$20,$20,$20,0

WINDOWTITLE:
PubScreenName:	dc.b	'VirusEliminator2.2a',0
ScreenTitle:	dc.b	'VirusEliminator2.2a (? 1998-99 by Slawomir Wojtasiak) Wersja Niezarejestrowana',0
TITLE.INTREQ:	dc.b	'VirusEliminator request...',0
WindowLV.title:	dc.b	'Lista roz. wirus?w...',0
WINDOWTITLE_HEX:dc.b	'Podaj adres...',0
ZRUDLO:		dc.b	'?R?D?OWY',0
DOCELOWY:	dc.b	'DOCELOWY',0
TITLE_LongByte:	dc.b	'Ile Bajt?w ???',0

BootName:	dc.b	'Bootblock.library',0
InitName:	dc.b	'intuition.library',0
ReqName:	dc.b	'reqtools.library',0
DFName:		dc.b	'diskfont.library',0
GadName:	dc.b	'gadtools.library',0
DosName:	dc.b	'dos.library',0
GrName:		dc.b	'graphics.library',0
WBenchNAME:	dc.b	'workbench.library',0
IconLibName:	dc.b	'icon.library',0
XVSName:	dc.b	'xvs.library',0

DevName:	dc.b	'trackdisk.device',0

LibraryName:	dc.b	'VirusEliminator:VirusEliminator.lib',0
FontName:	dc.b	'topazpl.font',0
IconName:	dc.b	'VirusEliminator:ICON/appiconVE',0

WBName:		dc.b	'Workbench',0
DownIconText:	dc.b	'VirusEliminator2.2a appicon',0

ReqError.txt:	dc.b	'Nie mog? otworzy? reqtools.library',0
DFError.txt:	dc.b	'Nie mog? otworzy? diskfont.library',0
GadError.txt:	dc.b	'Nie mog? otworzy? gadtools.library',0
DosError.txt:	dc.b	'Nie mog? otworzy? dos.library',0
GrError.txt:	dc.b	'Nie mog? otworzy? graphisc.library',0
IconLibError.txt:dc.b	'Nie mog? otworzy? icon.library',0
WBenchError.txt:dc.b	'Nie mog? otworzy? workbench.library',0
FontError.txt:	dc.b	'Nie mog? otworzy? fontu topazpl.font',0
LockError.txt:	dc.b	"Nie mog? dosta? si? do ekranu Workbench'a",0
UWAGALib:	dc.b	'Czy jeste? pewny !!!',0
ScreenError.txt:dc.b	'Nie mog? otworzy? ekranu',0
Memory.err:	dc.b	'Nie mog? wczyta? biblioteki,masz za ma?o pami?ci',0
WindowError.txt:dc.b	'Nie mog? otworzy? okna',0
MenuError.txt:	dc.b	'Nie mog? utworzy? menu',0
LibOpenERR:	dc.b	'Brak pami?ci',0
VisualError.txt:dc.b	'Nie mog? utworzy? str. VisualInfo',0
GadgetError.txt:dc.b	'Nie mog? utworzy? gadget?w',0
ReadError:	dc.b	'B??d odczytu bootblocku !!!',0
TrackDError.txt:dc.b	'Nie mog? otworzy? trackdisk.device',0
IconError.txt:	dc.b	'Nie mog? wczyta? appiconVE.info.',10
		dc.b	'Ta ikonka powinna si? znajdowa? w katalogu',10
		dc.b	'VirusEliminator/ICON/appiconVE.info',0
AppIcon.txt:	dc.b	"Nie mog? wrzuci? ikony na blat wbench'a",0
PortIconEr.txt:	dc.b	"Nie mog? stworzy? portu dla appicon'y",0
XVSError.txt:	dc.b	'Nie mog? otworzy? xvs.library',0
AllocError.txt:	dc.b	'B??d allokacji str. BootInfo !!!',0
AllocError1.txt:dc.b	'B??d allokacji str. MemoryInfo !!!',0
AllocError2.txt:dc.b	'B??d allokacji str. FileInfo !!!',0
BufforyError.txt:dc.b	'Ten buffor jest niezapisany !!!',0
ZapBuf:		dc.b	'Ten buffor jest zapisany...',0
NoDos.txt:	dc.b	'Dysk niedosowy !!!',0
UnIns.txt:	dc.b	'Dysk niezainstalowany...',0
BootWError.txt:	dc.b	'B??d zapisu bootblocku !!!',0
Wirus.txt:	dc.b	'Uwaga Wirus (bootblock)!!!',10
WirusBuffor:	blk.b	100
VirusLError.txt:dc.b	'Nie mog? utworzy? struktury dla ListViev (gadtools)',0
OpenError.txt:	dc.b	'Nie ma takiego pliku !!!',0
ReadError.txt	dc.b	'Wyst?pi? b??d podczas odczytywania pliku !!!',0
BootblockE.txt:	dc.b	"W tym pliku nie ma bootblock'u",0
JestPlik.txt:	dc.b	'Taki plik ju? istnieje !!!',0
WriteError.txt:	dc.b	'B??d zapisu pliku !!!',0
VEBoot.txt:	dc.b	'Kt?ry bootblock wybierasz ?',0
Kont.txt:	dc.b	'Co mam robi? ?',0
LibOpen.err:	dc.b	'Nie znalaz?em biblioteki !!!',0
OkLibRead:	dc.b	'Wczyta?em bibliotek? bootblock?w...',0
OkWriteLib:	dc.b	'Biblioteka zapisana...',0
BrakBiblioteki:	dc.b	'Nie ma biblioteki !!!',0
JestBoot.txt:	dc.b	'Ten bootblock jest ju? w bibliotece !!!',0
OnLib.txt:	dc.b	'To nie jest biblioteka VirusEliminatora !!!',0
BootError.txt:	dc.b	'Nie mog? otworzy? bootblock.library',0
LibBootblock:	dc.b	'(biblioteka)',10
		blk.b	31
WOpen.err:	dc.b	'Nie mog? otworzy? pliku !!!',0

TestMem.txt:	dc.b	'Sprawdzam czy w pami?ci nie ma wirusa...',0

VERozTB.txt:	dc.b	'VirusEliminator rozpoznaje ten bootblock...',0
BibliotekaUSU.txt:dc.b	'Biblioteka usuni?ta...',0
ZmianaCool:	dc.b	'CoolCapture = '
		blk.b	10
ZmianaCold:	dc.b	'ColdCapture = '
		blk.b	10
ZmianaWarm:	dc.b	'WarmCapture = '
		blk.b	10
ZmianaKickT:	dc.b	'KickTagPtr  = '
		blk.b	10
ZmianaKickM:	dc.b	'KickMemPtr  = '
		blk.b	10
Spr.txt:	dc.b	'Sprawdzam wektory systemowe...',0

Analiza.txt:	dc.b	'Analizuje bootblock...',0
Library.txt:	dc.b	'*** U?ywane biblioteki ***',0
Funkcje.txt:	dc.b	'*** Funkcje biblioteczne ***',0
Hardware.txt:	dc.b	'*** Hardware ***',0
Wektory.txt:	dc.b	'*** Operacje na wektorach sys. ***',0
Inne.txt:	dc.b	'*** Inne wa?niejsze operacje ***',0
Koniec.txt:	dc.b	"Czy na pewno chcesz wyj?? z VirusEliminator'a",0
Nieznany.txt:	dc.b	'Nieznany bootblock...',0
InstalText.txt	dc.b	'Wybierz bootblock...',0
UWAGAInstal.txt:dc.b	'UWAGA !!! bootblock zostanie bozpowrotnie stracony',0
TakNie.txt:	dc.b	'Czy jeste? pewny !!!',0
BBInstal.txt:	dc.b	'Bootblock zapisany...',0
BootBlockOK.txt:dc.b	'Bootblock wczytany...',0
Line0.txt:	dc.b	0
Analizuj.txt:	dc.b	'Wybierz rodzaj analizy...',0
DodalemBoot.txt:dc.b	'Doda?em bootblock do biblioteki...',0
GADGETW.txt:	dc.b	'Wybierz wektor...',0
WektorJest0.txt:dc.b	'Ten wektor nie zawiera ?ednego adresu...',0
Wektory.err:	dc.b	'Wektory systemowe ustawione na niestandardowe warto?ci...',0
_Wektory.txt:	dc.b	'Wszystko ok...',0
WyzerowalemCool:dc.b	'Wyzerowa?em wektor CoolCapture...',0
WyzerowalemCold:dc.b	'Wyzerowa?em wektor ColdCapture...',0
WyzerowalemWarm:dc.b	'Wyzerowa?em wektor WarmCapture...',0
WyzerowalemTag:	dc.b	'Wyzerowa?em wektor KickTagPtr...',0
WyzerowalemMem:	dc.b	'Wyzerowa?em wektor KickMemPtr...',0
Reset.txt:	dc.b	'Czy na pewno chcesz zresetowa? komputer...',0
IlleBoot.txt:	dc.b	'Ilo?? bootblock?w w bibliotece: '
		blk.b	12
Adres.txt:	blk.b	10
AdresMaly:	dc.b	'Poda?e? adres ko?cowy mniejszy ni? pocz?tkowy !!!',0
Adres0:		dc.b	'Podane adresy s? r?wne !!!',0
AdresPrint.txt:	dc.b	'Czy pokazywa? aktualny adres !!!',0
Szukam.txt:	dc.b	'Szukam...',0
QSzukam.txt:	dc.b	'Szukanie zako?czone.',0
MemCleared.txt:	dc.b	'Pami?? wyczyszczona...',0
MemClear.txt:	dc.b	'Czy jeste? tego pewien !!!',10
		dc.b	'Ta operacja jest bardzo ryzykowna',0
Copy_ok.txt:	dc.b	'Operacja kopiowania zako?czona sukcesem...',0
JestPlik1.txt:	dc.b	'Taki plik ju? istnieje !!!',0
PlikZapisany.txt:dc.b	'Pami?? zapisana do pliku...',0
NicPod.txt:	dc.b	'Nie stwierdzi?em nic podejrzanego...',0
CoSpr.txt:	dc.b	'Co mam sprawdzi? ???',0
CheckDrive.txt:	dc.b	'Sprawdzam bootblock w?o?onego dysku...',0

DoIo_STR:	dc.l	0
		dc.b	4,$4e,$ae,$fe,$38,'?? Wywo?anie funkcji "DoIO" z exec.library',0
Dal_STR:	dc.l	ANTYWIRUS
		dc.b	4,$4e,$ae,$ff,$a6,'?? Wywo?anie funkcji "DisplayAlert" z intuition.library',0
Fre_STR:	dc.l	0
		dc.b	4,$4e,$ae,$ff,$a0,'?? Wywo?anie funkcji "FindResident" z exec.library',0
Alm_STR:	dc.l	0
		dc.b	4,$4e,$ae,$ff,$3a,'?? Wywo?anie funkcji "AllocMem" z exec.library',0
Fal_STR:	dc.l	0
		dc.b	4,$4e,$ae,$fe,$2e,'?? Wywo?anie funkcji "FreeMem" z exec.library',0
Alr_STR:	dc.l	INTRO
		dc.b	4,$4e,$ae,$fe,$14,'?? Wywo?anie funkcji "AllocRaster" z exec.library',0
Opf_STR:	dc.l	INTRO
		dc.b	4,$4e,$ae,$ff,$B8,'?? Wywo?anie funkcji "OpenFont" z graphics.library',0
Opl_STR:	dc.l	0
		dc.b	4,$4e,$ae,$fe,$68,'?? Wywo?anie funkcji "OpenLibrary" z exec.library',0
Cll_STR:	dc.l	0
		dc.b	4,$4e,$ae,$fe,$62,'?? Wywo?anie funkcji "CloseLibrary" z exec.library',0
LMB_STR:	dc.l	INTRO
		dc.b	8,$08,$39,$00,$06,$00,$bf,$e0,$01,'?? Test lewego klawisza myszki...',0
RMB_STR:	dc.l	INTRO
		dc.b	8,$08,$39,$00,$02,$00,$df,$f0,$16,'?? Test prawego klawisza myszki...',0
rmb_STR:	dc.l	INTRO
		dc.b	8,$08,$39,$00,$0a,$00,$df,$f0,$16,'?? Test prawego klawisza myszki...',0
Cool_STR:	dc.l	ANTYWIRUS
		dc.b	4,$4a,$ae,$00,$2e,'?? Test wektora CoolCapture...',0
Cold_STR:	dc.l	ANTYWIRUS
		dc.b	4,$4a,$ae,$00,$2a,'?? Test wektora ColdCapture...',0
Warm_STR:	dc.l	ANTYWIRUS
		dc.b	4,$4a,$ae,$00,$32,'?? Test wektora WarmCapture...',0
KickT_STR:	dc.l	ANTYWIRUS
		dc.b	4,$4a,$ae,$02,$26,'?? Test wektora KickTagPtr...',0
KickM_STR:	dc.l	ANTYWIRUS
		dc.b	4,$4a,$ae,$02,$22,'?? Test wektora KickMemPtr...',0
CLR_Cool_STR:	dc.l	ANTYWIRUS
		dc.b	4,$42,$ae,$00,$2e,'?? Zerowanie wektora CoolCapture...',0
CLR_Cold_STR:	dc.l	ANTYWIRUS
		dc.b	4,$42,$ae,$00,$2a,'?? Zerowanie wektora ColdCapture...',0
CLR_Warm_STR:	dc.l	ANTYWIRUS
		dc.b	4,$42,$ae,$00,$32,'?? Zerowanie wektora WarmCapture...',0
CLR_KickT_STR:	dc.l	ANTYWIRUS
		dc.b	4,$42,$ae,$02,$26,'?? Zerowanie wektora KickTagPtr...',0
CLR_KickM_STR:	dc.l	ANTYWIRUS
		dc.b	4,$42,$ae,$02,$22,'?? Zerowanie wektora KickMemPtr...',0
KEY_STR:	dc.l	WIRUS
		dc.b	3,$bf,$ec,$01,'?? Odczyt klawiatury...',0
RESET_STR:	dc.l	ANTYWIRUS
		dc.b	6,$4e,$f9,$00,$fc,$00,$00,'?? Skok do procedury (RESET) w Rom ...',0
RES_STR:	dc.l	ANTYWIRUS
		dc.b	2,$4e,$70,'?? Instrukcja "RESET"...',0
COLOR_0:	dc.l	ANTYWIRUS
		dc.b	3,$df,$f1,$80,'?? Zmiana koloru t?a...',0
BLT_STR:	dc.l	INTRO
		dc.b	3,$df,$f0,$58,'?? U?ywa blitera...',0
BPL_STR:	dc.l	INTRO
		dc.b	3,$df,$f0,$80,'?? Otwiera w?asny playfield...',0
MOUSE_STR:	dc.l	INTRO
		dc.b	3,$df,$f0,$0a,'?? Pobiera pozycj? myszki...',0
Zmiana_Cold:	dc.l	WIRUS
		dc.b	5,$2d,$7c,-1,$0,$2a,'?? Zmiana wektora ColdCapture na: '
Zmiana_Cold_BUF:blk.b	10
Zmiana_Cool:	dc.l	WIRUS
		dc.b	5,$2d,$7c,-1,$0,$2e,'?? Zmiana wektora CoolCapture na: '
Zmiana_Cool_BUF:blk.b	10
Zmiana_Warm:	dc.l	WIRUS
		dc.b	5,$2d,$7c,-1,$0,$32,'?? Zmiana wektora WarmCapture na: '
Zmiana_Warm_BUF:blk.b	10
Zmiana_KickT:	dc.l	WIRUS
		dc.b	5,$2d,$7c,-1,$02,$26,'?? Zmiana wektora KickTagPtr na: '
Zmiana_KickT_BUF:blk.b	10
Zmiana_KickM:	dc.l	WIRUS
		dc.b	5,$2d,$7c,-1,$02,$22,'?? Zmiana wektora KickMemPtr na: '
Zmiana_KickM_BUF:blk.b	10
Zmiana_DoIO:	dc.l	WIRUS
		dc.b	5,$ad,$7c,-1,$fe,$3a,'?? Zmiana wektora biblioteki -456 na: '
Zmiana_DoIO_BUF:blk.b	10
DoIOLength:	dc.l	0
		dc.b	5,$23,$7c,-1,$00,$24,'?? io_Length = '
DoIOLength_BUF: blk.b	10
DoIOData:	dc.l	0
		dc.b	5,$23,$7c,-1,$00,$28,'?? io_Data   = '
DoIOData_BUF:	blk.b	10
DoIOOffset:	dc.l	0
		dc.b	5,$23,$7c,-1,$00,$2c,'?? io_Offset = '
DoIOOffset_BUF:	blk.b	10

IoCOM1_STR:	dc.l	LOADER
		dc.b	6,$33,$7c,$00,$01,$00,$1c,'?? io_Command 1 (Reset u??dzenia)...',0
IoCOM2_STR:	dc.l	LOADER
		dc.b	6,$33,$7c,$00,$02,$00,$1c,'?? io_Command 2 (Odczyt)...',0
IoCOM3_STR:	dc.l	ZAPIS
		dc.b	6,$33,$7c,$00,$03,$00,$1c,'?? io_Command 3 (Zapis)...',0
IoCOM4_STR:	dc.l	WIRUS
		dc.b	6,$33,$7c,$00,$04,$00,$1c,'?? io_Command 4 (Zapis buffor?w)...',0
IoCOM5_STR:	dc.l	LOADER
		dc.b	6,$33,$7c,$00,$05,$00,$1c,'?? io_Command 5 (Reset buffor?w)...',0
IoCOM6_STR:	dc.l	0
		dc.b	6,$33,$7c,$00,$06,$00,$1c,'?? io_Command 6 (Zatrzymanie operacji)...',0
IoCOM7_STR:	dc.l	0
		dc.b	6,$33,$7c,$00,$07,$00,$1c,'?? io_Command 7 (Wznowienie operacji)...',0
IoCOM8_STR:	dc.l	0
		dc.b	6,$33,$7c,$00,$08,$00,$1c,'?? io_Command 8 (Definitywne przerwanie op.)...',0
IoCOM9_STR:	dc.l	LOADER
		dc.b	6,$33,$7c,$00,$09,$00,$1c,'?? io_Command 9 (Kontrola silnika)...',0
IoCOM10_STR:	dc.l	0
		dc.b	6,$33,$7c,$00,$0a,$00,$1c,'?? io_Command 10 (Do testowania)...',0
IoCOM11_STR:	dc.l	WIRUS_FORMAT
		dc.b	6,$33,$7c,$00,$0b,$00,$1c,'?? io_Command 11 (UWAGA !!! formatowanie dysku)...',0
IoCOM12_STR:	dc.l	0
		dc.b	6,$33,$7c,$00,$0c,$00,$1c,'?? io_Command 12...',0
IoCOM13_STR:	dc.l	0
		dc.b	6,$33,$7c,$00,$0d,$00,$1c,'?? io_Command 13...',0
IoCOM14_STR:	dc.l	WIRUS
		dc.b	6,$33,$7c,$00,$0e,$00,$1c,'?? io_Command 14 (Wykrywanie dysku)...',0
IoCOM15_STR:	dc.l	WIRUS
		dc.b	6,$33,$7c,$00,$0f,$00,$1c,'?? io_Command 15 (Czy dysk jest zabespieczony)...',0
IoCOM16_STR:	dc.l	0
		dc.b	6,$33,$7c,$00,$10,$00,$1c,'?? io_Command 16...',0
IoCOM17_STR:	dc.l	0
		dc.b	6,$33,$7c,$00,$11,$00,$1c,'?? io_Command 17...',0
IoCOM18_STR:	dc.l	0
		dc.b	6,$33,$7c,$00,$12,$00,$1c,'?? io_Command 18 (Typ dysku)...',0
IoCOM19_STR:	dc.l	0
		dc.b	6,$33,$7c,$00,$13,$00,$1c,'?? io_Command 19 (ilo?? ?cie?ek na dysku)...',0
IoCOM20_STR:	dc.l	0
		dc.b	6,$33,$7c,$00,$14,$00,$1c,'?? io_Command 20...',0
IoCOM21_STR:	dc.l	0
		dc.b	6,$33,$7c,$00,$15,$00,$1c,'?? io_Command 21...',0
IoCOM22_STR:	dc.l	0
		dc.b	6,$33,$7c,$00,$16,$00,$1c,'?? io_Command 22...',0

Dos_STR:	dc.l	0
		dc.b	11,'dos.library','?? U?ywa "dos.library"',0
TAS_STR:	dc.l	MOJ
		dc.b	3,'TAS','?? Sk?d ja znam ten bootblock ??? :)',0
TrackD_STR:	dc.l	WIRUS
		dc.b	16,'trackdisk.device','?? Fa?szywa obs?uga trackdisk.device',0
Init_STR:	dc.l	ANTYWIRUS
		dc.b	17,'intuition.library','?? U?ywa "intuition.library"',0
Gr_STR:		dc.l	INTRO
		dc.b	16,'graphics.library','?? U?ywa "graphics.library"',0
Exp_STR:	dc.l	0
		dc.b	17,'expansion.library','?? U?ywa "expansion.library"',0

MemCHIP:	dc.b	'Wolny Chip:',0
MemFAST:	dc.b	'Wolny Fast:',0
MemRAZEM:	dc.b	'Ca?a Wolna:',0

MTitle1:	dc.b	'Projekt',0
MTitle2:	dc.b	'Bootblock',0
MTitle3:	dc.b	'Biblioteka',0
MTitle4:	dc.b	'Wektory',0
MTitle5:	dc.b	'Reset',0
MTitle6:	dc.b	'System',0
MTitle7:	dc.b	'Pami??',0
MTitle8:	dc.b	'Virus',0

MItem1:		dc.b	'Od Autora  ',0
MItem2:		dc.b	'Iconify',0
MItem2_1:	dc.b	'Status',0
MItem2_2:	dc.b	'Poka? Wir.',0
MItem3:		dc.b	'Exit',0
MItem4:		dc.b	'Bootblock do buffora ',0
MItem5:		dc.b	'Plik do buffora',0
MItem6:		dc.b	'Buffor do pliku',0
MItem7:		dc.b	'Czysty',0
MItem8:		dc.b	'Standard',0
MItem9:		dc.b	'Buffor',0
MItem10:	dc.b	'VirusElim.Boot',0
MItem11:	dc.b	'Formatuj Boot',0
MItem12:	dc.b	'Ascii',0
MItem13:	dc.b	'Hex',0
MItem14:	dc.b	'Analizuj',0
MItem15:	dc.b	'BootBlock',0
MItem16:	dc.b	'Kasuj Buffor',0
MItem17:	dc.b	'Dodaj bootblock',0
MItem18:	dc.b	'Wczytaj bibliotek?',0
MItem20:	dc.b	'Zapisz Bibliotek?',0
MItem21:	dc.b	'Usu? Bibliotek?',0
MItem22:	dc.b	'Wektor',0
MItem23:	dc.b	'Sprawdzaj Wektory',0
MItem24:	dc.b	'Zeruj CoolCapture ',0
MItem25:	dc.b	'Zeruj ColdCapture',0
MItem26:	dc.b	'Zeruj WarmCapture',0
MItem27:	dc.b	'Zeruj KickTagPtr',0
MItem28:	dc.b	'Zeruj KickMemPtr',0
MItem29:	dc.b	'Hard Reset ',0
MItem30:	dc.b	'ColdReboot',0
MItem33:	dc.b	'Libraries',0
MItem34:	dc.b	'Devices',0
MItem38:	dc.b	'Szukaj',0
MItem39:	dc.b	'Czy??',0
MItem40:	dc.b	'Poka?',0
MItem41:	dc.b	'Kopiuj',0
MItem42:	dc.b	'Zapis',0
MItem43:	dc.b	'Szukaj wirusa',0
MItem49:	dc.b	'bootblock',0
MItem50:	dc.b	'Plik',0
MItem52:	dc.b	'Poka? bootblocki ',0

MSubItem1:	dc.b	'Hex',0
MSubItem2:	dc.b	'Ascii',0
MSubItem4:	dc.b	'Hex',0
MSubItem5:	dc.b	'Ascii',0
MSubItem6:	dc.b	'Bootblokowe',0
MSubItem7:	dc.b	'Plikowe',0
MSubItem8:	dc.b	'Linkery',0

Key1:		dc.b	'A',0
Key2:		dc.b	'i',0
Key2_1:		dc.b	's',0
Key3:		dc.b	'E',0
Key4:		dc.b	'B',0
Key5:		dc.b	'P',0
Key6:		dc.b	'Y',0
Key7:		dc.b	'C',0
Key8:		dc.b	'S',0
Key10:		dc.b	'V',0
Key11:		dc.b	'F',0
Key12:		dc.b	'\',0
Key13:		dc.b	'|',0
Key14:		dc.b	'T',0
Key15:		dc.b	'^',0
Key16:		dc.b	'K',0
Key17:		dc.b	'D',0
Key18:		dc.b	'U',0
Key19:		dc.b	'{',0
Key20:		dc.b	'Z',0
Key21:		dc.b	'u',0
Key23:		dc.b	'X',0
Key24:		dc.b	'c',0
Key25:		dc.b	'o',0
Key26:		dc.b	'w',0
Key27:		dc.b	'/',0
Key28:		dc.b	'm',0
Key29:		dc.b	'H',0
Key30:		dc.b	'r',0
Key33:		dc.b	'1',0
Key34:		dc.b	'2',0
Key38:		dc.b	'?',0
Key39:		dc.b	'0',0
Key41:		dc.b	'>',0
Key42:		dc.b	'(',0
Key43:		dc.b	'!',0
Key44:		dc.b	'$',0
Key45:		dc.b	'#',0
Key47:		dc.b	':',0
Key48:		dc.b	'
Key49:		dc.b	'+',0
Key50:		dc.b	'-',0
Key52:		dc.b	'l',0

BUTTON_1.txt:	dc.b	'Requstery ostrzegawcze',0
BUTTON_2.txt:	dc.b	"Automatyczne spr. bootblock'u",0
BUTTON_3.txt:	dc.b	'Automatyczne naprawianie pliku',0
BUTTON_5.txt:	dc.b	'Exit',0
BUTTON_6.txt:	dc.b	'Iconify',0
BUTTON_7.txt:	dc.b	'Status',0
BUTTON_8.txt:	dc.b	'OK',0

About.txt:	dc.b	'VirusEliminator 2.2a (21.III.99)',10
		dc.b	'********************************',10
		dc.b	'U?ywa xvs.library',10,10
		dc.b	'Code by S?awomir Wojtasiak',10,10
		dc.b	'Kontakt:',10
		dc.b	'S?awomir Wojtasiak',10
		dc.b	'****',10
		dc.b	'****',10
		dc.b	'****',10,10
		dc.b	'*** shareware ***',10,10
		dc.b	'Przeczytaj dokumentacj? !!!',0


STATUS.txt:	dc.b	'VirusEliminator2.2a (STATUS)',10,10
		dc.b	'Sprawdzone dyski  : '
Buff_ST1	dc.b	32,32,32,32,32,32,32,32,32,32,32,32,10
		dc.b	'Sprawdzone pliki  : '
Buff_ST2	dc.b	32,32,32,32,32,32,32,32,32,32,32,32,10
		dc.b	'Znalezione Wirusy : '
Buff_ST3	dc.b	32,32,32,32,32,32,32,32,32,32,32,32,10,10
B_1:		dc.b	'Stan Buffora nr.1 : ',32,32,32,32,32,32,32,32,32,32,32,32,10
B_2:		dc.b	'Stan Buffora nr.2 : ',32,32,32,32,32,32,32,32,32,32,32,32,10
B_3:		dc.b	'Stan Buffora nr.3 : ',32,32,32,32,32,32,32,32,32,32,32,32,10
B_4:		dc.b	'Stan Buffora nr.4 : ',32,32,32,32,32,32,32,32,32,32,32,32,10
B_5:		dc.b	'Stan Buffora nr.5 : ',32,32,32,32,32,32,32,32,32,32,32,32,0
		
STAN_20.txt:	dc.b	'Standardowy bootblock systemu 2.0',0
STAN_13.txt:	dc.b	'Standardowy bootblock systemu 1.3',0

WaitStrona:	dc.b	'W celu kontynuacji wci?nij "OK"...',0

Buffor_1_ZAP:	dc.b	'Uwaga buffor 1 jest zapisany',0
Buffor_2_ZAP:	dc.b	'Uwaga buffor 2 jest zapisany',0
Buffor_3_ZAP:	dc.b	'Uwaga buffor 3 jest zapisany',0
Buffor_4_ZAP:	dc.b	'Uwaga buffor 4 jest zapisany',0
Buffor_5_ZAP:	dc.b	'Uwaga buffor 5 jest zapisany',0

	even

DriveTable:	dc.l	DF0
		dc.l	DF1
		dc.l	DF2
		dc.l	DF3
		dc.l	0,0

DF0:		dc.b	'DF0:',0
DF1:		dc.b	'DF1:',0
DF2:		dc.b	'DF2:',0
DF3:		dc.b	'DF3:',0

**** Gadgety.txt ****

GADGET.INTREQ:	dc.b	'   OK   ',0
Koniec.gad:	dc.b	'tak|nie',0
About.gad:	dc.b	'          OK          ',0
Text_BootBlock:	dc.b	'Wybierz buffor...',0
Gadgety_BootBlock:dc.b	'1|2|3|4|5|Anuluj',0
Gadgety_BootB:	dc.b	'1|2|3|4|5|DFx:|Anuluj',0
Gadget_Buffor:	dc.b	'Zapisz ponownie|Anuluj',0
FileReqError.TX:dc.b	'Nie mog? otworzy? filerequstera',0
FileReqName:	dc.b	'Wybierz plik...',0
UnIns.gad:	dc.b	'Instaluj|OK',0
GadgetIns.gad:	dc.b	'OS1.3|OS2.0|Anuluj',0
TAKNIE.gad	dc.b	'OK|Niech zostanie...',0
JestPlik.gad:	dc.b	'Zast?p|Anuluj',0
Kasuj.gad:	dc.b	'Kasuj|Anuluj',0
GadgetTAKNIE:
TakNie.gad:	dc.b	'TAK|NIE',0
VEBoot.gad:	dc.b	'Dla OS1.3|Dla OS2.0+|Anuluj',0
Kont.gad:	dc.b	'Dalej|Stop',0
Analiza.gad:	dc.b	'Og?lna|W Kolejno?ci|Anuluj',0
GADGETW.gad:	dc.b	'CoolC.|ColdC.|WarmC.|KickTagPtr|KickMemPtr|Anuluj',0
Reset.gad:	dc.b	'Reset !!!|Nie',0
JestPlik1.gad:	dc.b	'Zast?p|Poniechaj',0
CoSpr.gad	dc.b	'Plik|Katalog|Anuluj',0
Link.txt:	dc.b	'Co mam zrobi? z tym plikiem !!!',0
Link.gad:	dc.b	'Spr?buj naprawi?|Niech zostanie',0

**** Reqtools ****

	even

TAGS_1:	dc.l	USER+3,0
	dc.l	USER+10,1
	dc.l	USER+20,TITLE.INTREQ
	dc.l	USER+22,$4
	dc.l	USER+7,0
	dc.l	USER+15,0
	dc.l	0,0

TAGS:	dc.l	USER+3,2
	dc.l	USER+10,1
	dc.l	USER+20,TITLE.INTREQ
	dc.l	USER+22,$4
	dc.l	USER+7,0
	dc.l	USER+15,0
	dc.l	0,0

tags1:	dc.l	USER+7,0	
	dc.l	$80000000+3,2
	dc.l	$80000000+40,$4!$8
	dc.l	$80000000+42,GAD.OK
	dc.l	0,0

tags:	dc.l	USER+7,0	
	dc.l	$80000000+3,2
	dc.l	$80000000+40,$4
	dc.l	$80000000+42,GAD.OK
	dc.l	0,0

TAGLIST_STRING:
	dc.l	USER+7,0
	dc.l	$80000000+15,0
	dc.l	$80000000+3,2
	dc.l	RTGS_GadFmt,GAD.OKCANEL
	dc.l	RTGS_TextFmt,TEXT_IN
	dc.l	0,0

TAGLIST_STRING_HEX_P:
	dc.l	USER+7,0
	dc.l	$80000000+15,0
	dc.l	$80000000+3,2
	dc.l	RTGS_GadFmt,GAD.OKCANEL
	dc.l	RTGS_TextFmt,TEXT_HEX_P
	dc.l	0,0

TAGLIST_STRING_HEX_K:
	dc.l	USER+7,0
	dc.l	$80000000+15,0
	dc.l	$80000000+3,2
	dc.l	RTGS_GadFmt,GAD.OKCANEL
	dc.l	RTGS_TextFmt,TEXT_HEX_K
	dc.l	0,0

TAGLIST_SEARCH:
	dc.l	USER+7,0
	dc.l	$80000000+15,0
	dc.l	$80000000+3,2
	dc.l	RTGS_GadFmt,GAD.OKCANEL
	dc.l	RTGS_TextFmt,TEXT_SEARCH
	dc.l	0,0

TAGLIST_EXECUTE:
	dc.l	USER+7,0
	dc.l	$80000000+15,0
	dc.l	$80000000+3,2
	dc.l	RTGS_GadFmt,GAD.OKCANEL
	dc.l	RTGS_TextFmt,TEXT_EXECUTE
	dc.l	0,0

TAGLIST_ADRES:
	dc.l	USER+7,0
	dc.l	$80000000+15,0
	dc.l	$80000000+3,2
	dc.l	RTGS_GadFmt,GAD.OKCANEL
	dc.l	0,0

GetLong_TAGLIST:
	dc.l	USER+7,0
	dc.l	$80000000+15,0
	dc.l	$80000000+3,2
	dc.l	RTGS_GadFmt,GAD.OKCANEL
	dc.l	0,0

TAGLIST_ADRES1:
	dc.l	USER+7,0
	dc.l	$80000000+15,0
	dc.l	$80000000+3,2
	dc.l	RTGS_GadFmt,GAD.OKCANEL
	dc.l	RTGS_TextFmt,0
	dc.l	0,0

GAD.OK:		dc.b	'OK',0
GAD.OKCANEL:	dc.b	'OK|Anuluj',0
TEXT_IN:	dc.b	'Podaj nazwe dla tego bootblocku...',0
TEXT_HEX_P:	dc.b	'POCZ?TKOWY',0
TEXT_HEX_K:	dc.b	'KO',$cf,'COWY',0
TEXT_SEARCH:	dc.b	'Podaj ci?g kt?ry mam odszuka?...',0
TEXT_EXECUTE:	dc.b	"Wpisz tu komend? AmigaDOS'u kt?r? mam uruchomi?...",0

VE2.0:		dc.b	'VEBoot dla OS2.0+',0
VE1.3:		dc.b	'VEBoot dla OS1.3',0

_STRING_H:	dc.b	'$'
_STRING:	blk.b	31

	SECTION TABLE,DATA_C
 even
VE13_Buffor:	INCBIN	'dh1:programy/assemblery/bootblocki/VE13.boot'
VE20_Buffor:	INCBIN	'dh1:programy/assemblery/bootblocki/VE20.boot'

	SECTION TABLICE,BSS_C

BitMap_1:	ds.b	256*80
BitMap_2:	ds.b	256*80
BitMap_3:	ds.b	256*80
BitMap_4:	ds.b	256*80
ChipBuffor:	ds.b	12
FastBuffor:	ds.b	12
RazemBuffor:	ds.b	12
TextBuffor:	ds.b	80
GadList:	ds.b	1000
Gadget_LAB:	ds.b	200
Buffor_1:	ds.b	1024
Buffor_2:	ds.b	1024
Buffor_3:	ds.b	1024
Buffor_4:	ds.b	1024
Buffor_5:	ds.b	1024
Buffor_XVS:	ds.b	1024
Buffor_Roboczy:	ds.b	1024
FileName:	ds.b	400
FullName:	ds.b	400
AsciiBuffor:	ds.b	65
 even
Hex_Buffor:	ds.b	80
_STRING_SEARCH:	ds.b	101
 even
Buffor_FILE:	ds.l	260
Sector_buff:	ds.l	512*22
_STRING_EXECUTE:ds.b	200
