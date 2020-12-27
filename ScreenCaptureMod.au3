#include <WinAPIGdiDC.au3>
#include <WinAPIIcons.au3>
#include <WinAPISysWin.au3>
#include <ScreenCapture.au3>

; #FUNCTION# ====================================================================================================================
; Author ........: Paul Campbell (PaulIA)
; Modified.......: chimp
;
; modified version of the _ScreenCapture_CaptureWnd() function
; It uses the _WinAPI_PrintWindow() to capture the window
; ===============================================================================================================================
Func _ScreenCapture_CaptureWnd_mod($sFileName, $hWin, $bCursor = True)
    Local $bRet = False

    Local $iSize = WinGetPos($hWin)

    Local $iW = $iSize[2]
    Local $iH = $iSize[3]
    Local $hWnd = _WinAPI_GetDesktopWindow()
    Local $hDDC = _WinAPI_GetDC($hWnd)
    Local $hCDC = _WinAPI_CreateCompatibleDC($hDDC)
    Local $hBMP = _WinAPI_CreateCompatibleBitmap($hDDC, $iW, $iH)

    ; $hCDC Identifies the device context
    ; $hBMP Identifies the object to be selected
    _WinAPI_SelectObject($hCDC, $hBMP)
    _WinAPI_PrintWindow($hWin, $hCDC)

    If $bCursor Then
        Local $aCursor = _WinAPI_GetCursorInfo()
        If Not @error And $aCursor[1] Then
            $bCursor = True ; Cursor info was found.
            Local $hIcon = _WinAPI_CopyIcon($aCursor[2])
            Local $aIcon = _WinAPI_GetIconInfo($hIcon)
            If Not @error Then
                _WinAPI_DeleteObject($aIcon[4]) ; delete bitmap mask return by _WinAPI_GetIconInfo()
                If $aIcon[5] <> 0 Then _WinAPI_DeleteObject($aIcon[5]); delete bitmap hbmColor return by _WinAPI_GetIconInfo()
                _WinAPI_DrawIcon($hCDC, $aCursor[3] - $aIcon[2] - $iSize[0], $aCursor[4] - $aIcon[3] - $iSize[1], $hIcon)
            EndIf
            _WinAPI_DestroyIcon($hIcon)
        EndIf
    EndIf

    _WinAPI_ReleaseDC($hWnd, $hDDC)
    _WinAPI_DeleteDC($hCDC)
    If $sFileName = "" Then Return $hBMP

    $bRet = _ScreenCapture_SaveImage($sFileName, $hBMP, True)
    Return SetError(@error, @extended, $bRet)
EndFunc   ;==>_ScreenCapture_CaptureWnd_mod