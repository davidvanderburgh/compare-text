#Requires AutoHotkey v2.0
#SingleInstance Force

#Include Lib\Gdip_All.ahk
#Include Lib\OCR.ahk

; ── Globals ──────────────────────────────────────────────────────────────────
global Region1 := {x: 0, y: 0, w: 0, h: 0}
global Region2 := {x: 0, y: 0, w: 0, h: 0}
global Threshold := 128       ; grayscale threshold for binarization
global pToken := 0

; ── GDI+ Init ────────────────────────────────────────────────────────────────
pToken := Gdip_Startup()
if !pToken {
    MsgBox "Failed to start GDI+. Make sure Gdip_All.ahk is in the Lib folder."
    ExitApp
}
OnExit CleanUp

; ── GUI ──────────────────────────────────────────────────────────────────────
MainGui := Gui("+AlwaysOnTop", "Compare Screen Text")
MainGui.SetFont("s10")

MainGui.Add("GroupBox", "x10 y5 w320 h80", "Region 1")
MainGui.Add("Text", "x20 y25", "X:")
MainGui.Add("Edit", "x35 y22 w55 vR1X", "0")
MainGui.Add("Text", "x100 y25", "Y:")
MainGui.Add("Edit", "x115 y22 w55 vR1Y", "0")
MainGui.Add("Text", "x180 y25", "W:")
MainGui.Add("Edit", "x200 y22 w55 vR1W", "300")
MainGui.Add("Text", "x265 y25", "H:")
MainGui.Add("Edit", "x280 y22 w45 vR1H", "50")
MainGui.Add("Button", "x20 y52 w140 h25", "Pick Region 1").OnEvent("Click", (*) => PickRegion(1))
MainGui.Add("Button", "x170 y52 w150 h25", "Preview Region 1").OnEvent("Click", (*) => PreviewRegion(1))

MainGui.Add("GroupBox", "x10 y90 w320 h80", "Region 2")
MainGui.Add("Text", "x20 y110", "X:")
MainGui.Add("Edit", "x35 y107 w55 vR2X", "0")
MainGui.Add("Text", "x100 y110", "Y:")
MainGui.Add("Edit", "x115 y107 w55 vR2Y", "0")
MainGui.Add("Text", "x180 y110", "W:")
MainGui.Add("Edit", "x200 y107 w55 vR2W", "300")
MainGui.Add("Text", "x265 y110", "H:")
MainGui.Add("Edit", "x280 y107 w45 vR2H", "50")
MainGui.Add("Button", "x20 y137 w140 h25", "Pick Region 2").OnEvent("Click", (*) => PickRegion(2))
MainGui.Add("Button", "x170 y137 w150 h25", "Preview Region 2").OnEvent("Click", (*) => PreviewRegion(2))

MainGui.Add("GroupBox", "x10 y175 w320 h45", "Threshold (0-255)")
MainGui.Add("Slider", "x20 y192 w230 vThreshSlider Range0-255", Threshold)
MainGui.Add("Edit", "x260 y190 w60 vThreshEdit", Threshold)
MainGui["ThreshSlider"].OnEvent("Change", SyncThreshold)
MainGui["ThreshEdit"].OnEvent("Change", SyncThresholdFromEdit)

MainGui.Add("Button", "x10 y230 w320 h35", "Compare Now  (Ctrl+Shift+C)").OnEvent("Click", (*) => RunCompare())

MainGui.Add("GroupBox", "x10 y270 w320 h170", "Results")
MainGui.Add("Text", "x20 y290", "Region 1 text:")
MainGui.Add("Edit", "x20 y305 w300 h40 vResult1 ReadOnly Multi")
MainGui.Add("Text", "x20 y350", "Region 2 text:")
MainGui.Add("Edit", "x20 y365 w300 h40 vResult2 ReadOnly Multi")
MainGui.Add("Text", "x20 y415 w300 h20 vMatchResult cRed", "")

MainGui.Show("w340 h450")

; ── Hotkey ────────────────────────────────────────────────────────────────────
^+c::RunCompare()

; ── Functions ────────────────────────────────────────────────────────────────

SyncThreshold(ctrl, *) {
    MainGui["ThreshEdit"].Value := ctrl.Value
    global Threshold := ctrl.Value
}

SyncThresholdFromEdit(ctrl, *) {
    val := ctrl.Value
    if val is Number {
        val := Clamp(Integer(val), 0, 255)
        MainGui["ThreshSlider"].Value := val
        global Threshold := val
    }
}

Clamp(val, lo, hi) => Min(Max(val, lo), hi)

ReadRegionFromGui(n) {
    saved := MainGui.Submit(false)
    return {
        x: Integer(saved.%"R" n "X"%),
        y: Integer(saved.%"R" n "Y"%),
        w: Integer(saved.%"R" n "W"%),
        h: Integer(saved.%"R" n "H"%)
    }
}

; ── Pick region by dragging a rectangle on screen (snipping-tool style) ───────
PickRegion(n) {
    MainGui.Hide()
    Sleep 200

    ; Get virtual screen bounds (multi-monitor)
    vsX := SysGet(76)   ; SM_XVIRTUALSCREEN
    vsY := SysGet(77)   ; SM_YVIRTUALSCREEN
    vsW := SysGet(78)   ; SM_CXVIRTUALSCREEN
    vsH := SysGet(79)   ; SM_CYVIRTUALSCREEN

    ; Dark overlay covering all monitors
    overlay := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale")
    overlay.BackColor := "000000"
    overlay.Show("x" vsX " y" vsY " w" vsW " h" vsH)
    WinSetTransparent(120, overlay)  ; semi-transparent dark tint

    ; Transparent selection highlight window (drawn on top of overlay)
    selGui := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x20")
    selGui.BackColor := "FFFFFF"
    WinSetTransparent(1, selGui)  ; nearly invisible initially

    ; Border windows (4 thin bright borders around selection)
    borders := []
    Loop 4 {
        b := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x20")
        b.BackColor := "4A90D9"  ; blue accent like Windows snipping tool
        borders.Push(b)
    }

    ; Set crosshair cursor
    hCross := DllCall("LoadCursor", "Ptr", 0, "Ptr", 32515, "Ptr")  ; IDC_CROSS
    oldCursor := DllCall("SetCursor", "Ptr", hCross, "Ptr")
    DllCall("SetSystemCursor", "Ptr", DllCall("CopyImage", "Ptr", hCross, "UInt", 2, "Int", 0, "Int", 0, "UInt", 0, "Ptr"), "UInt", 32512)  ; OCR_NORMAL

    ToolTip "Click and drag to select Region " n "`nPress Escape to cancel"

    ; Wait for mouse down or Escape
    Loop {
        if GetKeyState("Escape", "P") {
            ToolTip
            for b in borders
                b.Destroy()
            selGui.Destroy()
            overlay.Destroy()
            RestoreCursors()
            MainGui.Show()
            return
        }
        if GetKeyState("LButton", "P")
            break
        Sleep 10
    }
    MouseGetPos &sx, &sy

    ; Track rubber-band with clear cutout
    while GetKeyState("LButton", "P") {
        MouseGetPos &cx, &cy
        rx := Min(sx, cx), ry := Min(sy, cy)
        rw := Abs(cx - sx), rh := Abs(cy - sy)

        if (rw > 2 && rh > 2) {
            ; Show bright selection area (cuts through the dark overlay visually)
            selGui.Show("x" rx " y" ry " w" rw " h" rh " NA")
            WinSetTransparent(1, selGui)

            ; Draw 2px blue borders around selection
            bdr := 2
            borders[1].Show("x" rx " y" (ry - bdr) " w" rw " h" bdr " NA")           ; top
            borders[2].Show("x" rx " y" (ry + rh) " w" rw " h" bdr " NA")             ; bottom
            borders[3].Show("x" (rx - bdr) " y" (ry - bdr) " w" bdr " h" (rh + bdr*2) " NA")  ; left
            borders[4].Show("x" (rx + rw) " y" (ry - bdr) " w" bdr " h" (rh + bdr*2) " NA")   ; right
        }

        ToolTip "Region " n ": " rx "," ry " " rw "x" rh
        Sleep 16
    }
    MouseGetPos &ex, &ey
    ToolTip

    ; Cleanup overlay
    for b in borders
        b.Destroy()
    selGui.Destroy()
    overlay.Destroy()
    RestoreCursors()

    fx := Min(sx, ex), fy := Min(sy, ey)
    fw := Abs(ex - sx), fh := Abs(ey - sy)

    if (fw < 5 || fh < 5) {
        MainGui.Show()
        MsgBox "Selection too small. Try again."
        return
    }

    MainGui["R" n "X"].Value := fx
    MainGui["R" n "Y"].Value := fy
    MainGui["R" n "W"].Value := fw
    MainGui["R" n "H"].Value := fh
    MainGui.Show()
}

; ── Restore default system cursors ───────────────────────────────────────────
RestoreCursors() {
    DllCall("SystemParametersInfo", "UInt", 0x0057, "UInt", 0, "Ptr", 0, "UInt", 0)  ; SPI_SETCURSORS
}

; ── Preview: show the normalized (binarized) capture ─────────────────────────
PreviewRegion(n) {
    r := ReadRegionFromGui(n)
    if (r.w < 5 || r.h < 5) {
        MsgBox "Region " n " is too small."
        return
    }
    pBitmap := CaptureAndNormalize(r.x, r.y, r.w, r.h)
    if !pBitmap {
        MsgBox "Capture failed."
        return
    }

    ; Save to temp file and show
    tmpFile := A_Temp "\compare_text_preview_" n ".png"
    Gdip_SaveBitmapToFile(pBitmap, tmpFile)
    Gdip_DisposeImage(pBitmap)
    Run tmpFile
}

; ── Capture screen region → grayscale → threshold → pBitmap ──────────────────
CaptureAndNormalize(x, y, w, h) {
    pBitmap := Gdip_BitmapFromScreen(x "|" y "|" w "|" h)
    if !pBitmap
        return 0

    ; Lock bits for direct pixel manipulation
    if Gdip_LockBits(pBitmap, 0, 0, w, h, &Stride, &Scan0, &BitmapData) {
        Gdip_DisposeImage(pBitmap)
        return 0
    }

    ; Grayscale + threshold
    Loop h {
        row := A_Index - 1
        rowOffset := row * Stride
        Loop w {
            col := A_Index - 1
            offset := rowOffset + (col * 4)

            b := NumGet(Scan0, offset,     "UChar")
            g := NumGet(Scan0, offset + 1, "UChar")
            r := NumGet(Scan0, offset + 2, "UChar")

            ; Luminance-weighted grayscale
            gray := (r * 299 + g * 587 + b * 114) // 1000

            ; Binarize: dark pixels → black text (0), light pixels → white bg (255)
            val := (gray >= Threshold) ? 255 : 0

            NumPut("UChar", val, Scan0, offset)
            NumPut("UChar", val, Scan0, offset + 1)
            NumPut("UChar", val, Scan0, offset + 2)
        }
    }

    Gdip_UnlockBits(pBitmap, &BitmapData)
    return pBitmap
}

; ── OCR a normalized bitmap ──────────────────────────────────────────────────
OcrFromBitmap(pBitmap) {
    hBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap)
    if !hBitmap
        return ""
    try {
        result := OCR.FromBitmap(hBitmap)
        text := result.Text
    } catch {
        text := ""
    }
    DeleteObject(hBitmap)
    return text
}

; ── Normalize text for comparison ────────────────────────────────────────────
NormalizeText(txt) {
    txt := Trim(txt)
    txt := StrLower(txt)
    ; Collapse all whitespace (spaces, tabs, newlines) to single space
    txt := RegExReplace(txt, "\s+", " ")
    return txt
}

; ── Main compare routine ─────────────────────────────────────────────────────
RunCompare(*) {
    r1 := ReadRegionFromGui(1)
    r2 := ReadRegionFromGui(2)

    if (r1.w < 5 || r1.h < 5 || r2.w < 5 || r2.h < 5) {
        MsgBox "Both regions must be at least 5x5 pixels."
        return
    }

    ; Briefly hide GUI so it doesn't get captured
    MainGui.Hide()
    Sleep 150

    pBmp1 := CaptureAndNormalize(r1.x, r1.y, r1.w, r1.h)
    pBmp2 := CaptureAndNormalize(r2.x, r2.y, r2.w, r2.h)

    MainGui.Show()

    if (!pBmp1 || !pBmp2) {
        if pBmp1
            Gdip_DisposeImage(pBmp1)
        if pBmp2
            Gdip_DisposeImage(pBmp2)
        MsgBox "Failed to capture one or both regions."
        return
    }

    text1 := OcrFromBitmap(pBmp1)
    text2 := OcrFromBitmap(pBmp2)
    Gdip_DisposeImage(pBmp1)
    Gdip_DisposeImage(pBmp2)

    MainGui["Result1"].Value := text1
    MainGui["Result2"].Value := text2

    norm1 := NormalizeText(text1)
    norm2 := NormalizeText(text2)

    if (norm1 = norm2 && norm1 != "") {
        MainGui["MatchResult"].Opt("cGreen")
        MainGui["MatchResult"].Value := "✓  MATCH"
    } else if (norm1 = "" && norm2 = "") {
        MainGui["MatchResult"].Opt("cRed")
        MainGui["MatchResult"].Value := "✗  No text detected in either region"
    } else {
        MainGui["MatchResult"].Opt("cRed")
        MainGui["MatchResult"].Value := "✗  NO MATCH"
    }
}

; ── Cleanup ──────────────────────────────────────────────────────────────────
CleanUp(*) {
    Gdip_Shutdown(pToken)
}
