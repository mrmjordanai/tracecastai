# Test Images for TraceCast Development

This directory contains test pattern images for AI vectorization testing.

## Required Test Images

| Filename | Description | Purpose |
|----------|-------------|---------|
| `geometric_shape.png` | Simple rectangular bodice pattern piece | Happy path / basic test |
| `sleeve_pattern.png` | Sleeve pattern with notches and grain line | Pattern marking detection |
| `quilting_template.png` | Hexagon or Dresden wedge template | Mode-specific test |
| `reference_grid.png` | Cutting mat with credit card for scale | Scale reference detection |
| `multi_piece_pattern.png` | Multiple pattern pieces in frame | Complex scene handling |

## AI Image Generation Prompts (Nano Banana Pro)

Use these highly detailed prompts to generate optimal test assets. These are tuned for technical accuracy and computer vision readability.

### 1. geometric_shape.png
**Visual Reference:**
```
     +---------------------------+
     |   ---------------------   |  <-- Dashed stitching line
     |   |                   |   |
     |   |         ^         |   |
  T--|---|         |         |---|--T <-- Notch mark
     |   |         |         |   |
     |   |         |         |   |
     |   |                   |   |
     |   ---------------------   |
     +---------------------------+
         Rectangular Bodice Block
```
**Prompt:**
> "Technical product photography, flat lay, directly overhead 90-degree view. A single sheet of matte white paper centered on a dark grey self-healing cutting mat. On the paper is a precise black ink line drawing of a simple rectangular sewing pattern bodice block. accurately drawn dashed stitching lines 15mm from the edge. A straight grainline arrow in the center. distinct T-shaped notch marks on the side seams. High contrast, sharp focus, even studio lighting, no shadows, no wrinkles, orthographic projection style, 8k resolution."

### 2. sleeve_pattern.png
**Visual Reference:**
```
            /-----\
           /       \
          /    ^    \  <-- Grainline arrow
Double   |     |     |
notch -> =     |     = <- Single notch
         |     |     |
         \     |     /
          \    |    /
           \---|---/
               |
          Fold line (dashed)
```
**Prompt:**
> "Technical sewing pattern diagram, macro photography, top-down view. A white paper pattern piece for a shirt sleeve lying flat. Clean solid black cutting outlines. A dashed fold line running down the center. Double notches on the back curve, single notch on the front curve. A 'grainline' arrow running parallel to the fold line. Text labels 'SLEEVE - CUT 2'. The background is a blurred workshop table. The pattern lines are crisp, uniform 2px width, high contrast, wide dynamic range, no distortion."

### 3. quilting_template.png
**Visual Reference:**
```
          / \
         /   \
        /  O  \  <-- Corner hole
       /       \
      |---------| <-- 1/4" seam allowance (dashed)
      |         |
      |         |
       \       /
        \     /
         \___/
        Hexagon
```
**Prompt:**
> "Geometric vector graphic style photograph. A perfectly shaped Hexagon quilting template on plain white cardstock. The hexagon has an inner dashed line indicating 1/4 inch seam allowance. Small circular holes at the corners for seam marking. Extreme close-up, flat lighting, absolutely no perspective distortion, sharp edges, minimalist composition, black on white, high fidelity."

### 4. reference_grid.png
**Visual Reference:**
```
    +------------------------+
    |  |  |  |  |  |  |  |   |
    |--+--+--+--+--+--+--+---| <-- 1-inch grid
    |  | [CREDIT CARD] |  |  |
    |--+--+--+--+--+--+--+---|
    |  |  |  |  |  |  |  |   |
    +------------------------+
           Cutting Mat
```
**Prompt:**
> "Overhead technical shot of a green self-healing cutting mat with a precise yellow 1-inch grid pattern. A standard credit card is placed in the center for scale reference. The grid lines are sharp and straight. The lighting is perfectly even diffuse light to eliminate glare on the mat. The camera is perfectly parallel to the surface to ensure no keystone effect. Realist texture, 8k, engineering standard."

### 5. multi_piece_pattern.png
**Visual Reference:**
```
    +-------+      /--\
    |Bodice |     |Col-|
    | Front |     |lar |
    +-------+      \--/

          /-----\
         |Pocket |
          \-----/
```
**Prompt:**
> "Flat lay arrangement of multiple sewing pattern pieces on a large white table. Includes a bodice front, a collar piece, and a pocket piece. Each piece has distinct black cutting lines, grainline arrows, and size numbers. The pieces are arranged neatly but not touching. Top-down orthographic view, soft shadowless lighting, high contrast monochromatic scheme with black lines on white paper, crisp details, computer vision training data style."

## Image Sources & Licenses

| Filename | Source | License |
|----------|--------|---------|
| `geometric_shape.png` | AI Generated (Nano Banana Pro) | CC0 Public Domain |
| `sleeve_pattern.png` | AI Generated (Nano Banana Pro) | CC0 Public Domain |
| `quilting_template.png` | AI Generated (Nano Banana Pro) | CC0 Public Domain |
| `reference_grid.png` | AI Generated (Nano Banana Pro) | CC0 Public Domain |
| `multi_piece_pattern.png` | AI Generated (Nano Banana Pro) | CC0 Public Domain |

## License

All AI-generated images in this directory are released under **CC0 1.0 Universal (Public Domain Dedication)**.

Generated specifically for the TraceCast project development and testing.

## Image Technical Specifications

For the best results with TraceCast's AI vectorization:

- **Resolution**:
  - **Minimum**: 2048px on the shortest side (e.g., 2048x2048 or 2048x2732).
  - **Ideal**: 12MP or higher (approx. 3000x4000px), matching standard smartphone camera output.
  - *Why? High resolution is critical for detecting fine dashed lines and small text markings.*

- **Format**:
  - **PNG** (Preferred for generated images): Lossless, no compression artifacts.
  - **JPEG**: High quality (80%+), minimal compression. Avoid low-quality JPEGs where lines become blurry.

- **Aspect Ratio**:
  - **1:1 (Square)**: Best for Nano Banana Pro / AI generation.
  - **4:3 (Portrait)**: Standard for real-world phone camera tests.

## Image Requirements

For optimal vectorization testing, images should:
- Be high contrast (black lines on white background)
- Include clear pattern markings (notches, grain lines)
- Be captured from directly overhead (minimal perspective distortion)
- Have good, even lighting

---

*Last updated: December 2024*
