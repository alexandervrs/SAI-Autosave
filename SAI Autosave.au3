#include <MsgBoxConstants.au3>
#include <TrayConstants.au3>
#include <FileConstants.au3>
#include <WinAPIFiles.au3>
#include <AutoItConstants.au3>
#include <Misc.au3>
#include <WinAPI.au3>
#include <WindowsConstants.au3>

Global $timeint = 60000
Global $runcount = 0
Global $saveinterval = "15"
Global $saititle = "SAI"
Global $configfile = "Autosave Settings.ini"
Global $pidfile = "Autosave PID.dat"
Global $saipath = "."
Global $sainame = "sai.exe"
Global $autolaunch = "1"
Global $silent = "0"
Global $blink = "1"
Global $version = "1.0.3"
Global $ispaused = "0"
Global $remaining = ""

Opt("TrayMenuMode", 3)
Opt("TrayOnEventMode", 1)

TraySetToolTip("SAI Autosave")

$idStatus = TrayCreateItem("SAI Autosave is active")
TrayItemSetState ( $idStatus, $TRAY_DISABLE )
$idPause = TrayCreateItem("Pause")
TrayItemSetOnEvent($idPause, "TrayPause") 

TrayCreateItem("")
$idVersion = TrayCreateItem("About...")
TrayCreateItem("")
$idExit = TrayCreateItem("Quit")
TraySetState($TRAY_ICONSTATE_SHOW)

TrayItemSetOnEvent($idExit, "TrayExit") 
TrayItemSetOnEvent($idVersion, "TrayAbout") 

$fhandle = FileOpen($pidfile, $FO_READ)
	$previouspid = FileRead($fhandle)
FileClose($fhandle)

ProcessClose($previouspid)

If FileExists($configfile) Then
	$saveinterval = IniRead($configfile, "Settings", "Interval", $saveinterval )
	$saipath = IniRead($configfile, "Settings", "Path", $saipath)
	$autolaunch = IniRead($configfile, "Settings", "Autolaunch", $autolaunch)
	$sainame = IniRead($configfile, "Settings", "FileName", $sainame)
	$silent = IniRead($configfile, "Settings", "Silent", $silent)
	$blink = IniRead($configfile, "Settings", "Blink", $blink)
	$ispaused = IniRead($configfile, "Settings", "PausedOnStart", $ispaused)
Else
	$fhandle = FileOpen($configfile, $FO_READ + $FO_OVERWRITE)
	FileWrite($fhandle, "[Settings]" & @CRLF)
	FileWrite($fhandle, "Interval=" & $saveinterval & @CRLF)
	FileWrite($fhandle, "Autolaunch=" & $autolaunch & @CRLF)
	FileWrite($fhandle, "Path=" & $saipath & @CRLF)
	FileWrite($fhandle, "FileName=" & $sainame & @CRLF)
	FileWrite($fhandle, "Silent=" & $silent & @CRLF)
	FileWrite($fhandle, "Blink=" & $blink & @CRLF)
	FileWrite($fhandle, "PausedOnStart=" & "0" & @CRLF)
	FileClose($fhandle)
EndIf

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

$remaining = GetRemainingTime()

;SoundPlay(@WindowsDir & "\media\tada.wav", 1)
Func MonitorUntilSave()

	Sleep($timeint)
	
	$remaining = GetRemainingTime()
	TrayItemSetText($idStatus, "SAI Autosave is active - Next save in " & $remaining &"")
	TraySetToolTip("SAI Autosave is active - Next save in " & $remaining & "")
	
	Call("CheckIfActive")
EndFunc

Func GetRemainingTime()
	Return String($saveinterval - $runcount) & " minute(s)"
EndFunc

Func CheckIfActive()
	
	If Not ProcessExists($sainame) Then
		Exit
	EndIf
	
	If WinExists($saititle) = 1 Then
		
		If $ispaused = "0" Then
		
			$runcount = $runcount + 1
		
			If $runcount = $saveinterval Then
			
				$runcount = 0
				
				If WinActive($saititle) = 1 Then
					Call("SaveFile")
				Else
					If $blink = "1" Then
						TraySetState($TRAY_ICONSTATE_FLASH)
					EndIf
					
					TrayItemSetText($idStatus, "SAI Autosave is active - Next save imminent...")
					TraySetToolTip("SAI Autosave is active - Next save imminent...")
					
					WinWaitActive($saititle)
					Call("SaveFile")
				EndIf
				
			Else
				Call("MonitorUntilSave")
			EndIf
		
		Else
			Call("MonitorUntilSave")
		EndIf
		
	Else
		Exit
	EndIf
	
	
EndFunc

Func SaveFile()
	
	If $ispaused = "0" Then
		
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
			;SoundPlay(@WindowsDir & "\media\tada.wav", 1)
		EndIf
		
		If $blink = "1" Then
			TraySetState($TRAY_ICONSTATE_STOPFLASH)
		EndIf
		
		;$hWnd = WinGetHandle($saititle)
		;WinSetTrans($hWnd, "", 250)
		;WinSetTrans($hWnd, "", 255)
		Sleep(250)
		
		TrayItemSetText($idStatus, "SAI Autosave is active - Next save in " & $saveinterval &" minute(s)")
		TraySetToolTip("SAI Autosave is active - Next save in " & $saveinterval &" minute(s)")
		
		Call("MonitorUntilSave")
		
	Else

		$runcount = $runcount-1
		
		TrayItemSetText($idStatus, "SAI Autosave is active - Next save in " & $remaining &"")
		TraySetToolTip("SAI Autosave is active - Next save in " & $remaining & "")
		
		Call("MonitorUntilSave")
	
	EndIf
EndFunc


Func TrayExit()
    BlockInput(0)
	Exit
EndFunc

Func TrayAbout()
	MsgBox($MB_ICONINFORMATION, "About", "Paint Tool SAI Autosave" & @CRLF & "Version " & $version & @CRLF & @CRLF & "A free AutoIt powered script to autosave your SAI work on set intervals," & @CRLF & "by Alexander Vourtsis" & @CRLF & @CRLF & "Follow my Twitter (@alexandervrs) for updates")
EndFunc

Func TrayPause()
	If $ispaused = "1" Then
		
		$remaining = GetRemainingTime()
	
		TrayItemSetText($idStatus, "SAI Autosave is active - Next save in " & $remaining & "")
		TraySetToolTip("SAI Autosave is active - Next save in " & $remaining & "")
		TrayItemSetText($idPause, "Pause")
		
		If $silent = "0" Then
			TrayTip("Paint Tool SAI", "Autosave is resumed & will save every " & $saveinterval & " minutes! - Next save in " & $remaining & "", 3, $TIP_ICONASTERISK)
		EndIf
		
		If $blink = "1" Then
			TraySetState($TRAY_ICONSTATE_STOPFLASH)
		EndIf
		
		$ispaused = "0"
		;$runcount = 0
		
	Else
		
		TrayItemSetText($idStatus, "SAI Autosave is paused")
		TraySetToolTip("SAI Autosave is paused")
		TrayItemSetText($idPause, "Resume")
		
		If $silent = "0" Then
			TrayTip("Paint Tool SAI", "Autosave is now paused", 3, $TIP_ICONASTERISK)
		EndIf
		If $blink = "1" Then
			TraySetState($TRAY_ICONSTATE_STOPFLASH)
		EndIf
		
		$ispaused = "1"
		
	EndIf
EndFunc

TrayItemSetText($idStatus, "SAI Autosave is active - Next save in " & $remaining &"")
TraySetToolTip("SAI Autosave is active - Next save in " & $remaining & "")

if $ispaused = "0" Then
	If $silent = "0" Then
		TrayTip("Paint Tool SAI", "Autosave is active & will save every " & $saveinterval & " minutes! ", 3, $TIP_ICONASTERISK)
	EndIf
EndIf

Call("MonitorUntilSave")

