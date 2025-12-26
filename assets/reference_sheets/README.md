# Reference Sheets for TraceCast

This directory contains printable reference sheets for scale calibration.

## Required Reference Sheets

| Filename | Description | Purpose |
|----------|-------------|---------|
| `aruco_4x4_50_sheet.pdf` | ArUco marker grid (4x4 dictionary, ID 0-3) | Primary scale reference |
| `credit_card_reference.pdf` | Credit card outline template | Fallback scale reference |

## ArUco Marker Generation

Generate ArUco markers using OpenCV's ArUco module or online tools:
- Dictionary: `DICT_4X4_50`
- Marker Size: 50mm recommended
- IDs to include: 0, 1, 2, 3 (corners)

### Online Generator
- https://chev.me/arucogen/

## Usage

1. Print reference sheet at 100% scale (no fit-to-page)
2. Place printed sheet next to pattern being captured
3. App will detect markers and calculate true scale

## License

Reference sheet designs are CC0 Public Domain.

---

*TODO: Add actual PDF reference sheets*
