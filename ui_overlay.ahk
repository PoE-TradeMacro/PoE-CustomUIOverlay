; gdi+ ahk tutorial 3 written by tic (Tariq Porter)
; Requires Gdip.ahk either in your Lib folder as standard library or using #Include
;
; Tutorial to take make a gui from an existing image on disk
; For the example we will use png as it can handle transparencies. The image will also be halved in size

/*
	Author: Eruyome
	Tutorial used as template to show PoE UI overlay
	Overlay images created by https://www.reddit.com/user/Musti_A, reddit post https://www.reddit.com/r/pathofexile/comments/5x9pgt/i_made_some_poe_twitch_stream_overlays_free/
*/

#SingleInstance, Force
#NoEnv
SetBatchLines, -1

; Uncomment if Gdip.ahk is not in your standard library
#Include, Gdip_All.ahk

; Start gdi+
If !pToken := Gdip_Startup()
	{
	   MsgBox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
	}
OnExit, Exit

global image := "malachai.png"
global GuiOn := 0
global poeWindowName = "Path of Exile ahk_class POEWindowClass"

; Create a layered window (+E0x80000 : must be used for UpdateLayeredWindow to work!) that is always on top (+AlwaysOnTop), has no taskbar entry or caption
Gui, 1: +E0x20 -Caption +E0x80000 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs

If (GuiON = 0) {
	Gosub, CheckWinActivePOE
	SetTimer, CheckWinActivePOE, 100
	GuiON = 1
	
	; Show the window
	Gui, 1: Show, NA
}
Else {
	SetTimer, CheckWinActivePOE, Off      
	Gui, 1: Hide	
	GuiON = 0
}

; Get a handle to this window we have created in order to update it later
hwnd1 := WinExist()

; If the image we want to work with does not exist on disk, then download it...

; Get a bitmap from the image
pBitmap := Gdip_CreateBitmapFromFile(image)

; Check to ensure we actually got a bitmap from the file, in case the file was corrupt or some other error occured
If !pBitmap
{
	MsgBox, 48, File loading error!, Could not load the image specified
	ExitApp
}

; Get the width and height of the bitmap we have just created from the file
; This will be the dimensions that the file is
Width := Gdip_GetImageWidth(pBitmap), Height := Gdip_GetImageHeight(pBitmap)

; Create a gdi bitmap with width and height of what we are going to draw into it. This is the entire drawing area for everything
hbm := CreateDIBSection(Width, Height)

; Get a device context compatible with the screen
hdc := CreateCompatibleDC()

; Select the bitmap into the device context
obm := SelectObject(hdc, hbm)

; Get a pointer to the graphics of the bitmap, for use with drawing functions
G := Gdip_GraphicsFromHDC(hdc)

; We do not need SmoothingMode as we did in previous examples for drawing an image
; Instead we must set InterpolationMode. This specifies how a file will be resized (the quality of the resize)
; Interpolation mode has been set to HighQualityBicubic = 7
Gdip_SetInterpolationMode(G, 7)

; DrawImage will draw the bitmap we took from the file into the graphics of the bitmap we created
; The source height and width are specified, and also the destination width and height
; Gdip_DrawImage(pGraphics, pBitmap, dx, dy, dw, dh, sx, sy, sw, sh, Matrix)
; d is for destination and s is for source. We will not talk about the matrix yet (this is for changing colours when drawing)
Gdip_DrawImage(G, pBitmap, 0, 0, Width, Height, 0, 0, Width, Height)

; Update the specified window we have created (hwnd1) with a handle to our bitmap (hdc), specifying the x,y,w,h we want it positioned on our screen
; So this will position our gui at (0,0) with the Width and Height specified earlier
UpdateLayeredWindow(hwnd1, hdc, 0, 0, Width, Height)

; Select the object back into the hdc
SelectObject(hdc, obm)

; Now the bitmap may be deleted
DeleteObject(hbm)

; Also the device context related to the bitmap may be deleted
DeleteDC(hdc)

; The graphics may now be deleted
Gdip_DeleteGraphics(G)

; The bitmap we made from the image may be deleted
Gdip_DisposeImage(pBitmap)
Return
;#######################################################################

CheckWinActivePOE:
	GuiControlGet, focused_control, focus
	If(WinActive(poeWindowName))
		If (GuiON = 0) {
			Gui, 1: Show, NA
			GuiON := 1
		}
	If(!WinActive(poeWindowName))
		If (GuiON = 1)
		{
			Gui, 1: Hide
			GuiON := 0
		}
Return


Exit:
; gdi+ may now be shutdown on exiting the program
Gdip_Shutdown(pToken)
ExitApp
Return