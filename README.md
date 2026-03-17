# Compare Text

A Windows utility that reads text from two screen regions using OCR and compares them for a match. Captures are normalized to black-and-white before OCR so the comparison works regardless of text color or background color.

Uses the Windows built-in UWP OCR engine — no external OCR software or API keys required.

## Installation

### Option A: Installer (recommended)

1. Download `CompareText_Setup.exe` from the [latest release](https://github.com/davidvanderburgh/compare-text/releases/latest).
2. Run the installer. It will install to `C:\Program Files\Compare Text` by default.
3. Launch from the Start Menu or Desktop shortcut.

The installer bundles a portable AutoHotkey v2 runtime — no separate AutoHotkey installation is needed.

### Option B: Manual setup

1. Install [AutoHotkey v2](https://www.autohotkey.com/) (or download the portable zip).
2. Clone this repository:
   ```
   git clone https://github.com/davidvanderburgh/compare-text.git
   cd compare-text
   ```
3. Download the required libraries into `Lib/`:
   - [OCR.ahk](https://raw.githubusercontent.com/Descolada/OCR/main/Lib/OCR.ahk) (by Descolada)
   - [Gdip_All.ahk](https://raw.githubusercontent.com/buliasz/AHKv2-Gdip/master/Gdip_All.ahk) (by buliasz)
   ```
   mkdir Lib
   curl -sL -o Lib/OCR.ahk "https://raw.githubusercontent.com/Descolada/OCR/main/Lib/OCR.ahk"
   curl -sL -o Lib/Gdip_All.ahk "https://raw.githubusercontent.com/buliasz/AHKv2-Gdip/master/Gdip_All.ahk"
   ```
4. Run `CompareText.ahk` with AutoHotkey v2.

## Usage

### Selecting regions

Use **Pick Region 1** / **Pick Region 2** to select screen areas:

- A dark overlay covers the screen (like the Windows Snipping Tool).
- Click and drag to draw a rectangle around the text you want to capture.
- Press **Escape** to cancel.

You can also type coordinates manually into the X, Y, W, H fields.

### Comparing

- Click **Compare Now** or press **Ctrl+Shift+C** to run the comparison.
- The OCR'd text from each region is shown in the results area.
- The result displays **MATCH** (green) or **NO MATCH** (red).

The comparison is case-insensitive and ignores differences in whitespace.

### Threshold

The threshold slider (0–255) controls how the captured image is binarized before OCR:

- Each pixel is converted to grayscale, then turned black (below threshold) or white (at/above threshold).
- This normalizes away differences in text color and background color between the two regions.
- **Lower values** = more pixels become black (use for light-colored text).
- **Higher values** = more pixels become white (use for dark backgrounds with bright text).
- Default is **128**, which works well for most standard text.

Use the **Preview** buttons to see the binarized image and verify the text is readable before comparing.

## How it works

1. **Capture** — Each screen region is captured to a bitmap via GDI+.
2. **Normalize** — The bitmap is converted to grayscale using luminance weights (0.299R + 0.587G + 0.114B), then thresholded to pure black and white.
3. **OCR** — The normalized bitmap is passed to the Windows UWP OCR engine (`Windows.Media.Ocr`).
4. **Compare** — Both text results are lowercased, whitespace-collapsed, and compared for equality.

## Requirements

- Windows 10 or later (64-bit)
- No additional software needed when using the installer

## License

The bundled AutoHotkey runtime is licensed under the [GNU GPL v2](https://www.autohotkey.com/docs/v2/license.htm). The OCR and GDI+ libraries are open-source community projects; see their respective repositories for license details.
