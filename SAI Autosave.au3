#include <MsgBoxConstants.au3>
#include <TrayConstants.au3>
#include <FileConstants.au3>
#include <File.au3>
#Include <WinAPI.au3>
#include <WinAPIFiles.au3>
#include <AutoItConstants.au3>
#include <Misc.au3>
#include <Date.au3>
#include <WinAPI.au3>
#include <WindowsConstants.au3>
#Include <ScreenCapture.au3>
#include <ComboConstants.au3>
#include <GuiComboBox.au3>
#include <GuiScrollBars.au3>
#include <GUIConstantsEx.au3>
#include <ButtonConstants.au3>
#include <GuiEdit.au3>
#include <ColorConstants.au3>
#include <SendMessage.au3>


Global $timeint = 60000
Global $runcount = 0
Global $savefileinterval = "15"
Global $saititle = "SAI"
Global $configfile = "SAI Autosave Settings.ini"
Global $pidfile = "Autosave PID.dat"
Global $saipath = "."
Global $sainame = "sai.exe"
Global $autolaunch = "1"
Global $silent = "0"
Global $blink = "1"
Global $version = "2.0.0"
Global $ispaused = "0"
Global $remaining = ""
Global $remaining2 = ""
Global $askbeforesave = "0"
Global $snapshotinterval = "180000" ; 180000 = 3 minutes
Global $snapshotfolder = "~SAIAutosave.Snapshots"
Global $backupfolder = "~SAIAutosave.Backups"
Global $runcount2 = 0
Global $savemode = "0"
Global $keepbackups = "1"
Global $isbackingup = 0

If Not FileExists(@ScriptDir & "\" & $snapshotfolder) Then
	DirCreate(@ScriptDir & "\" & $snapshotfolder)
EndIf

If Not FileExists(@ScriptDir & "\" & $backupfolder) Then
	DirCreate(@ScriptDir & "\" & $backupfolder)
EndIf

Opt("TrayMenuMode", 3)
Opt("TrayOnEventMode", 1)

TraySetToolTip("SAI Autosave")

; allow only single instance
$fhandle = FileOpen($pidfile, $FO_READ)
	$previouspid = FileRead($fhandle)
FileClose($fhandle)
ProcessClose($previouspid)

; load ini settings
ReadOrCreateConfig()

; start timers
Global $timersnapshot = TimerInit()
Global $timersavefile = TimerInit()

If $ispaused = "1" Then
	TrayItemSetText($idStatus, "SAI Autosave is paused")
	TraySetToolTip("SAI Autosave is paused")
	TrayItemSetText($idPause, "Resume")
EndIf

If $autolaunch = "1" Then
	$pid = Run($saipath & "\" & $sainame, "", @SW_SHOWMAXIMIZED)
EndIf

$fhandle = FileOpen($pidfile, $FO_READ + $FO_OVERWRITE)
	FileWrite($fhandle, @AutoItPID)
FileClose($fhandle)

; -----------------------------------------
;   Main Loop
;------------------------------------------

Func Main()

	While 1
	
		Sleep(250)
		
		If Not ProcessExists($sainame) Then
			Exit
		EndIf

		If WinExists($saititle) = 0 Then
		
			Sleep(100)
			
		Else
		
			if Not SAIHasNoFileLoaded() Then
		
				; capture screenshot
				If $savemode = "0" Or $savemode = "2" Or $savemode = "3" Then
				
					If TimerDiff($timersnapshot) > $snapshotinterval Then
						If WinActive($saititle) Then
						
							SaveSnapshot()
							
							Sleep(10)
							
							If $savemode = "3" Then
								TrayTip("Paint Tool SAI", "Remember to Save your work!", 2, $TIP_ICONEXCLAMATION)
							EndIf
							
							$timersnapshot = TimerInit()
							
						Else
						
							; autosave wants to save but needs focus
							If $blink = "1" Then
								TraySetState($TRAY_ICONSTATE_FLASH)
							EndIf
						
						EndIf
						
					EndIf
					
				EndIf
				
				; save file
				If $savemode = "0" Or $savemode = "1" Then
				
					If TimerDiff($timersavefile) > $savefileinterval*60000 Then
						If WinActive($saititle) Then
							
							SaveFile()
							
							If $keepbackups = "1" Then
								SaveBackup()
							EndIf
							
							$timersavefile = TimerInit()
							
						Else
						
							; autosave wants to save but needs focus
							If $blink = "1" Then
								TraySetState($TRAY_ICONSTATE_FLASH)
							EndIf
						
						EndIf
						
					EndIf
					
				EndIf
				
				; reminder
				If $savemode = "4" Then
				
					TrayTip("Paint Tool SAI", "Remember to Save your work!", 2, $TIP_ICONEXCLAMATION)
					
					$timersavefile = TimerInit()
					
				EndIf
				
			
			Else
			
				Sleep(100)
			
			EndIf
		
		EndIf
		
	WEnd
	Exit
	
EndFunc


Func SAIHasNoFileLoaded()
	Return Not StringRegExp(WinGetTitle( WinGetHandle($saititle) ), "(\.+)")
EndFunc

; -----------------------------------------
;   Save Operations
;------------------------------------------

Func SaveSnapshot()

	Local $DTString = StringReplace(_NowCalc(), ":", ".")
	$DTString = StringReplace($DTString, "/", "-")

	;WinActivate($saititle)
	$hWnd = WinGetHandle($saititle)
	Sleep(200)
	Local $hBmp
	$hBmp = _ScreenCapture_CaptureWnd("", $hWnd)
	_ScreenCapture_SaveImage(@ScriptDir & "\" & $snapshotfolder & "\Snapshot " & $DTString & ".jpg", $hBmp)
	
	If $blink = "1" Then
		TraySetState($TRAY_ICONSTATE_STOPFLASH)
	EndIf
	
	Return True

	
EndFunc


Func SaveFile()

	If $ispaused = "0" Then
		
		; User has SAI open but without a file
		if Not StringRegExp(WinGetTitle( WinGetHandle($saititle) ), "(\.+)") Then 
			;TrayTip("Paint Tool SAI", "Cannot save! File is not saved yet! Please save the .sai file first!", 2, $TIP_ICONEXCLAMATION)
			Return False
		EndIf
		
		If _IsPressed(1) Then 
			While _IsPressed(1)
				Sleep(250)
			WEnd
		EndIf
		
		If _IsPressed(2) Then 
			While _IsPressed(2)
				Sleep(250)
			WEnd
		EndIf
		
		Sleep(250)
		
		BlockInput(1)
		Send("^{s}")
		BlockInput(0)
		
		If $silent = "0" Then
			TrayTip("Paint Tool SAI", "Autosaving...", 3, $TIP_ICONASTERISK)
		EndIf
		
		If $blink = "1" Then
			TraySetState($TRAY_ICONSTATE_STOPFLASH)
		EndIf
		
		Sleep(250)
		
		Return True
	
	
	EndIf

EndFunc


Func SaveBackup()

	If $isbackingup = "1" Then
		TrayTip("Paint Tool SAI", "Cannot perform backup, another backup process is in progress!", 2, $TIP_ICONEXCLAMATION)
		Return False
	EndIf

	Local $DTString = StringReplace(_NowCalc(), ":", ".")
	$DTString = StringReplace($DTString, "/", "-")

	; File is not saved yet
	; check if window has (Not Saved)
	If StringRegExp(WinGetTitle( WinGetHandle($saititle) ), "(\(\Not Saved\)+)", "") Then
	
		TrayTip("Paint Tool SAI", "Cannot backup! File is not saved yet! Please save the .sai file first!", 2, $TIP_ICONEXCLAMATION)
		Return False
		
	EndIf
	
	; User has SAI open but without a file
	if SAIHasNoFileLoaded() Then 
		TrayTip("Paint Tool SAI", "Cannot backup! File is not saved yet! Please save the .sai file first!", 2, $TIP_ICONEXCLAMATION)
		Return False
	EndIf
	
	TrayItemSetState( $trayBackup, $TRAY_DISABLE )
	$isbackingup = "1"

	Local $workingfilename[2]
	$workingfilename = StringRegExp(WinGetTitle( WinGetHandle($saititle) ), '(SAI -) (.+)', 3) ; split after dash ; or (SAI -) (.+) (\(\*\))
	$workingfilename[1] = StringRegExpReplace($workingfilename[1], " (\(\*\))", ""); remove (*)
	
	;TrayTip("Paint Tool SAI", $workingfilename[1], 2, $TIP_ICONEXCLAMATION)
	
	Local $sDrive = "", $sDir = "", $sFileName = "", $sExtension = ""
	_PathSplit($workingfilename[1], $sDrive, $sDir, $sFileName, $sExtension)
	
	;TrayTip("Paint Tool SAI", @ScriptDir & "\" & $backupfolder & "\Backup " & $DTString & " " & $sFileName & $sExtension, 1, $TIP_ICONEXCLAMATION)
	
	If $silent = "0" Then
		TrayTip("Paint Tool SAI", "Saving backup of " & $sFileName & $sExtension & "...", 2, $TIP_ICONASTERISK)
	EndIf
	
	FileCopy($workingfilename[1], @ScriptDir & "\" & $backupfolder & "\Backup " & $DTString & " " & $sFileName & $sExtension)
	
	If $silent = "0" Then
		TrayTip("Paint Tool SAI", "Backup saved in " & @ScriptDir & "\" & $backupfolder & "\Backup " & $DTString & " " & $sFileName & $sExtension, 2, $TIP_ICONASTERISK)
	EndIf
	
	TrayItemSetState( $trayBackup, $TRAY_ENABLE )
	$isbackingup = "0"
	
	Return True
	
	
EndFunc



; -----------------------------------------
;   Tray Pause
;------------------------------------------
Func TrayPause()

	If $ispaused = "1" Then
		
		TrayItemSetText($idStatus, "SAI Autosave is active")
		TraySetToolTip("SAI Autosave is active")
		TrayItemSetText($idPause, "Pause")
		
		If $silent = "0" Then
			TrayTip("Paint Tool SAI", "Autosave is resumed", 1, $TIP_ICONASTERISK)
		EndIf
		
		If $blink = "1" Then
			TraySetState($TRAY_ICONSTATE_STOPFLASH)
		EndIf
		
		$ispaused = "0"
		
	Else
		
		TrayItemSetText($idStatus, "Autosave is paused")
		TraySetToolTip("SAI Autosave is paused")
		TrayItemSetText($idPause, "Resume")
		
		If $silent = "0" Then
			TrayTip("Paint Tool SAI", "Autosave is now paused", 1, $TIP_ICONASTERISK)
		EndIf
		If $blink = "1" Then
			TraySetState($TRAY_ICONSTATE_STOPFLASH)
		EndIf
		
		$ispaused = "1"
		
	EndIf
EndFunc


; -----------------------------------------
;   Tray Settings
;------------------------------------------

Func ShowSettingsDialog()

	TrayItemSetState($traySettings, $TRAY_DISABLE)

	; load ini settings
	ReadOrCreateConfig()
	
	; create window
	Local $windowwidth = 240
	Local $windowheight = 430
	Local $GUIHandle = GUICreate("Settings", $windowwidth, $windowheight, @DesktopWidth / 2 - ($windowwidth/2), @DesktopHeight / 2 - ($windowheight/2), -1, $WS_EX_OVERLAPPEDWINDOW)
	
	; Save Mode
	Local $LabelHandle = GUICtrlCreateLabel("Save Mode", 16, 10, 100, 20)
	GUICtrlSetFont($LabelHandle, 11, $FW_NORMAL, -1, "Arial", $CLEARTYPE_QUALITY)
	Local $ComboBoxHandle = GUICtrlCreateCombo("Save File & Snapshot", 16, 30, 210, 24, $CBS_DROPDOWNLIST)
	GUICtrlSetFont($ComboBoxHandle, 11, $FW_NORMAL, -1, "Arial", $CLEARTYPE_QUALITY)
	GUICtrlSetData($ComboBoxHandle, "Save File Only|Snapshot Only|Snapshot & Reminder|Reminder Only")
	GUICtrlSetTip($LabelHandle, "Either to save the SAI file or capture screenshots or both when the timer ends")
	
	If $savemode = "0" Then
		_GUICtrlComboBox_SetCurSel($ComboBoxHandle, 0)
	EndIf
	If $savemode = "1" Then
		_GUICtrlComboBox_SetCurSel($ComboBoxHandle, 1)
	EndIf
	If $savemode = "2" Then
		_GUICtrlComboBox_SetCurSel($ComboBoxHandle, 2)
	EndIf
	If $savemode = "3" Then
		_GUICtrlComboBox_SetCurSel($ComboBoxHandle, 3)
	EndIf
	If $savemode = "4" Then
		_GUICtrlComboBox_SetCurSel($ComboBoxHandle, 4)
	EndIf
	
	; Save File Interval
	Local $LabelHandle2 = GUICtrlCreateLabel("Save File Interval", 16, 70, 140, 17)
	GUICtrlSetFont($LabelHandle2, 11, $FW_NORMAL, -1, "Arial", $CLEARTYPE_QUALITY)
	GUICtrlSetTip($LabelHandle2, "This is the minutes interval that the autosave occurs at")
	Local $TextInputHandle = GUICtrlCreateInput(String($savefileinterval), 16, 90, 120, 24, $ES_NUMBER)
	Local $TextUpDown = GUICtrlCreateUpdown($TextInputHandle)
	GUICtrlSetFont($TextInputHandle, 11, $FW_NORMAL, -1, "Arial", $CLEARTYPE_QUALITY)
	GUICtrlSetLimit($TextUpDown, 240, 1) ; max, min
	Local $LabelHandle3 = GUICtrlCreateLabel("minutes", 145, 95, 100, 20)
	GUICtrlSetFont($LabelHandle3, 11, $FW_NORMAL, -1, "Arial", $CLEARTYPE_QUALITY)

	; Snapshot Interval
	Local $LabelHandle2 = GUICtrlCreateLabel("Snapshot Interval", 16, 130, 140, 17)
	GUICtrlSetFont($LabelHandle2, 11, $FW_NORMAL, -1, "Arial", $CLEARTYPE_QUALITY)
	GUICtrlSetTip($LabelHandle2, "This is the interval in milliseconds that the snapshot capture occurs at")
	Local $TextInputHandle2 = GUICtrlCreateInput(String($snapshotinterval), 16, 150, 120, 24, $ES_NUMBER)
	Local $TextUpDown = GUICtrlCreateUpdown($TextInputHandle2)
	GUICtrlSetFont($TextInputHandle2, 11, $FW_NORMAL, -1, "Arial", $CLEARTYPE_QUALITY)
	GUICtrlSetLimit($TextUpDown, 3600000, 1000) ; max, min
	Local $LabelHandle4 = GUICtrlCreateLabel("milliseconds", 145, 155, 100, 20)
	GUICtrlSetFont($LabelHandle4, 11, $FW_NORMAL, -1, "Arial", $CLEARTYPE_QUALITY)
	GUICtrlSetTip($LabelHandle4, "In Milliseconds:" & @CRLF & "1000 = 1 sec" & @CRLF & "30000 = 30 sec" & @CRLF & "60000 = 1 minute" & @CRLF & "180000 = 3 minutes" & @CRLF & "300000 = 5 minutes" & @CRLF & "600000 = 10 minutes" & @CRLF & "1800000 = 30 minutes")
	
	; Paused On Start
	Local $CheckboxHandle = GUICtrlCreateCheckbox("Paused On Start", 16, 190, 185, 25)
	GUICtrlSetFont($CheckboxHandle, 11, $FW_NORMAL, -1, "Arial", $CLEARTYPE_QUALITY)
	GUICtrlSetTip($CheckboxHandle, "When checked then the Autosave feature will be paused when the utility starts and you will need to enable it via the option in the system tray icon")
	if $ispaused = "1" Then
		GUICtrlSetState($CheckboxHandle, $GUI_CHECKED)
	EndIf
	
	; Silent
	Local $CheckboxHandle2 = GUICtrlCreateCheckbox("Silent Mode", 16, 220, 185, 25)
	GUICtrlSetFont($CheckboxHandle2, 11, $FW_NORMAL, -1, "Arial", $CLEARTYPE_QUALITY)
	GUICtrlSetTip($CheckboxHandle2, "Whether the utility will not display any notifications while starting up and saving")
	if $silent = "1" Then
		GUICtrlSetState($CheckboxHandle2, $GUI_CHECKED)
	EndIf
	
	; Blink Icon
	Local $CheckboxHandle3 = GUICtrlCreateCheckbox("Blink Icon", 16, 250, 185, 25)
	GUICtrlSetFont($CheckboxHandle3, 11, $FW_NORMAL, -1, "Arial", $CLEARTYPE_QUALITY)
	GUICtrlSetTip($CheckboxHandle3, "The tray icon will blink if SAI does not have focus when the utility is trying to save, in order to remind you")
	if $blink = "1" Then
		GUICtrlSetState($CheckboxHandle3, $GUI_CHECKED)
	EndIf
	
	; Autolaunch SAI
	Local $CheckboxHandle4 = GUICtrlCreateCheckbox("Autolaunch SAI", 16, 280, 185, 25)
	GUICtrlSetFont($CheckboxHandle4, 11, $FW_NORMAL, -1, "Arial", $CLEARTYPE_QUALITY)
	GUICtrlSetTip($CheckboxHandle4, "If checked, it will also auto-launch sai.exe, useful if you want to make a shortcut to SAI Autosave.exe so that the Autosave functionality is available every time you open SAI through that shortcut. Uncheck it if you want to start SAI & the autosave utility manually instead")
	if $autolaunch = "1" Then
		GUICtrlSetState($CheckboxHandle4, $GUI_CHECKED)
	EndIf
	
	; Keep Backups
	Local $CheckboxHandle6 = GUICtrlCreateCheckbox("Keep Backups", 16, 310, 185, 25)
	GUICtrlSetFont($CheckboxHandle6, 11, $FW_NORMAL, -1, "Arial", $CLEARTYPE_QUALITY)
	GUICtrlSetTip($CheckboxHandle6, "If checked, when set to save the file it will also keep copies of your working file (might be slow with large files)")
	if $keepbackups = "1" Then
		GUICtrlSetState($CheckboxHandle6, $GUI_CHECKED)
	EndIf
	
	; Close Button
	Local $ButtonClose = GUICtrlCreateButton("Save && Close", 16, 355, 210, 65)
	GUICtrlSetFont($ButtonClose, 11, $FW_NORMAL, -1, "Arial", $CLEARTYPE_QUALITY)
	
	_GUIScrollBars_Init($GUIHandle)
	_GUIScrollBars_ShowScrollBar($GUIHandle, $SB_BOTH, False)
	GUISetState(@SW_SHOW, $GUIHandle)
	
	While 1
        Switch GUIGetMsg()
	
			Case $GUI_EVENT_CLOSE, $ButtonClose
                
				If FileExists($configfile) Then
				
					; Save Mode
					$savemode = String( GUICtrlRead($ComboBoxHandle) )
					If $savemode = "Save File & Snapshot" Then
						$savemode = "0"
						IniWrite($configfile, "Settings", "SaveMode", "0")
					EndIf
					If $savemode = "Save File Only" Then
						$savemode = "1"
						IniWrite($configfile, "Settings", "SaveMode", "1")
					EndIf
					If $savemode = "Snapshot Only" Then
						$savemode = "2"
						IniWrite($configfile, "Settings", "SaveMode", "2")
					EndIf
					If $savemode = "Snapshot & Reminder" Then
						$savemode = "3"
						IniWrite($configfile, "Settings", "SaveMode", "3")
					EndIf
					If $savemode = "Reminder Only" Then
						$savemode = "4"
						IniWrite($configfile, "Settings", "SaveMode", "4")
					EndIf

					; Save File Interval
					$savefileinterval = StringReplace( String( GUICtrlRead($TextInputHandle) ), ",", "")
					$savefileinterval = StringReplace( $savefileinterval, ".", "")
					IniWrite($configfile, "Settings", "SaveFileInterval", $savefileinterval)
					
					; Snapshot Interval
					$snapshotinterval = StringReplace( String( GUICtrlRead($TextInputHandle2) ), ",", "")
					$snapshotinterval = StringReplace( $snapshotinterval, ".", "")
					IniWrite($configfile, "Settings", "SnapshotInterval", $snapshotinterval)
				
					; Silent
					If GUICtrlRead($CheckboxHandle2) = $GUI_CHECKED Then
					   $silent = "1"
					Else
					   $silent = "0"
					EndIf
					IniWrite($configfile, "Settings", "Silent", $silent)
				
					; Blink Icon
					If GUICtrlRead($CheckboxHandle3) = $GUI_CHECKED Then
					   $blink = "1"
					Else
					   $blink = "0"
					EndIf
					IniWrite($configfile, "Settings", "Blink", $blink)
					
					; Autolaunch SAI
					If GUICtrlRead($CheckboxHandle4) = $GUI_CHECKED Then
					   $autolaunch = "1"
					Else
					   $autolaunch = "0"
					EndIf
					IniWrite($configfile, "Settings", "Autolaunch", $autolaunch)
					
					; Keep Backups
					If GUICtrlRead($CheckboxHandle6) = $GUI_CHECKED Then
					   $keepbackups = "1"
					Else
					   $keepbackups = "0"
					EndIf
					IniWrite($configfile, "Settings", "KeepBackups", $keepbackups)
					
					TrayTip("Paint Tool SAI", "Settings saved", 1, $TIP_ICONASTERISK)
					
					UpdateTray()
				
				Else
				
					TrayTip("Paint Tool SAI", "Settings were not saved. Cannot write to Settings file or file not found", 1, $TIP_ICONHAND)
				
				EndIf
				
				TrayItemSetState($traySettings, $TRAY_ENABLE)
				
				ExitLoop
	
		EndSwitch
	WEnd
	
	GUIDelete($GUIHandle)

EndFunc


; -----------------------------------------
;   Tray About
;------------------------------------------

Func TrayAbout()
	MsgBox($MB_ICONINFORMATION, "About", "Paint Tool SAI Autosave" & @CRLF & "Version " & $version & @CRLF & @CRLF & "A free AutoIt powered script to autosave your SAI work on set intervals," & @CRLF & "by Alexander Vourtsis" & @CRLF & @CRLF & "Follow my Twitter (@alexandervrs) for updates")
EndFunc


; -----------------------------------------
;   Tray Exit
;------------------------------------------

Func TrayExit()
    BlockInput(0)
	Exit
EndFunc


; -----------------------------------------
;   Update Tray Info
;------------------------------------------

Func UpdateTray()
	

EndFunc

; -----------------------------------------
;   Ini Settings
;------------------------------------------

Func ReadOrCreateConfig()

	If FileExists($configfile) Then
		$savemode = IniRead($configfile, "Settings", "SaveMode", $savemode )
		$savefileinterval = IniRead($configfile, "Settings", "SaveFileInterval", $savefileinterval )
		$snapshotinterval = IniRead($configfile, "Settings", "SnapshotInterval", $snapshotinterval )
		$saipath = IniRead($configfile, "Settings", "Path", $saipath)
		$autolaunch = IniRead($configfile, "Settings", "Autolaunch", $autolaunch)
		$sainame = IniRead($configfile, "Settings", "FileName", $sainame)
		$silent = IniRead($configfile, "Settings", "Silent", $silent)
		$blink = IniRead($configfile, "Settings", "Blink", $blink)
		$ispaused = IniRead($configfile, "Settings", "PausedOnStart", $ispaused)
		$keepbackups = IniRead($configfile, "Settings", "KeepBackups", $keepbackups)
		
	Else
		$fhandle = FileOpen($configfile, $FO_READ + $FO_OVERWRITE)
		FileWrite($fhandle, "[Settings]" & @CRLF)
		FileWrite($fhandle, "SaveMode=" & $savemode & @CRLF)
		FileWrite($fhandle, "SaveFileInterval=" & $savefileinterval & @CRLF)
		FileWrite($fhandle, "SnapshotInterval=" & $snapshotinterval & @CRLF)
		FileWrite($fhandle, "Autolaunch=" & $autolaunch & @CRLF)
		FileWrite($fhandle, "Path=" & $saipath & @CRLF)
		FileWrite($fhandle, "FileName=" & $sainame & @CRLF)
		FileWrite($fhandle, "Silent=" & $silent & @CRLF)
		FileWrite($fhandle, "Blink=" & $blink & @CRLF)
		FileWrite($fhandle, "PausedOnStart=" & "0" & @CRLF)
		FileWrite($fhandle, "KeepBackups=" & "1" & @CRLF)
		
		FileClose($fhandle)
	EndIf

EndFunc

$idStatus = TrayCreateItem("SAI Autosave is active")
TrayItemSetState($idStatus, $TRAY_DISABLE)

$idPause = TrayCreateItem("Pause")
TrayCreateItem("")

$trayBackup = TrayCreateItem("Backup Now")
TrayCreateItem("")

$traySettings = TrayCreateItem("Settings...")
TrayCreateItem("")

$idVersion = TrayCreateItem("About...")
TrayCreateItem("")

$idExit = TrayCreateItem("Quit")

TrayItemSetOnEvent($idStatus, "TrayCancelSave") s
TrayItemSetOnEvent($idPause, "TrayPause") 
TrayItemSetOnEvent($traySettings, "ShowSettingsDialog") 
TrayItemSetOnEvent($trayBackup, "SaveBackup") 
TrayItemSetOnEvent($idVersion, "TrayAbout") 
TrayItemSetOnEvent($idExit, "TrayExit") 

TraySetState($TRAY_ICONSTATE_SHOW)

If Not ProcessExists($sainame) Then
	MsgBox($MB_ICONERROR + $MB_OK, "Error", "SAI is not running! Please launch SAI first or place the application inside the SAI folder with the autolaunch option enabled")
	Exit
EndIf
		
if $ispaused = "0" Then
	If $silent = "0" Then
		TrayTip("Paint Tool SAI", "Autosave is active & will save every " & $savefileinterval & " minutes! ", 3, $TIP_ICONASTERISK)
	EndIf
EndIf

UpdateTray()

Call("Main")
