# processing experiments

My generative art sketches written in Processing (Java). Most generate SVG artwork for pen plotting with an [AxiDraw](https://axidraw.com/). Sketch-specific keyboard controls are listed below.

## Running the sketches

Install [Processing](https://processing.org/download/), then open the folder for a sketch in Processing and run its main `.pde` file (the one with the same name as the folder). Each sketch runs independently.

## Sketches

### Flow field
Press **S** to export an SVG; use **Up/Down** to increase or decrease the number of path steps.

<p align="center">
  <img src="output/neon_flow_field.jpg" width="450" alt="Noise-driven flow field artwork">
</p>

### Differential line growth
Press **S** to export the current line as an SVG, or **R** to start a new line.

<p align="center">
  <img src="output/differential_line_purple_1.jpg" width="450" alt="Purple differential line growth artwork">
</p>

### Drift
- Move the mouse to rotate the view.
- Press **R** to export an SVG.
- **+/-** to change noise octaves.
- **[/]** to decrease/increase the height displacement.

<p align="center">
  <img src="output/drift_gamboge_coral_4.jpg" width="450" alt="Drift artwork with a fragmented noise-driven grid">
</p>

### Arachne
Press **R** to export an SVG, **Up/Down** to adjust droop, and **[/]** to decrease/increase web spacing.

<p align="center">
  <img src="arachne/preview.jpg" width="450" alt="Arachne sketch preview">
</p>

### 3D fern
- Move the mouse to rotate the view.
- Press **F** to cycle fern source files.
- **R** to export an SVG, and **P** to save a preview PNG.
- **Space** randomizes parameters
- **Q/A** adjusts bend radius
- **W/S** spiral angle
- **E/D** frond count
- **T/G** distance
- **Left/Right** ring angle

<p align="center">
  <img src="sketch_3d_fern/preview.png" width="450" alt="3D fern sketch preview">
</p>
