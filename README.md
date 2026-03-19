# Ward 9

A single-player, first-person psychological horror game built in **Godot 4**.

## Premise
You are a night attendant in Ward 9. Your job is simple: check the patients. If they're normal, check "Normal". If something is wrong, check "Something Wrong". 

Don't let them notice you noticing them.

## Technical Constraints
- **Engine**: Godot 4.2+
- **Platform**: PC (Windows)
- **Scope**: ~20 minutes gameplay
- **Rooms**: 3 max
- **System**: Observation-based decision loop

## Project Structure
- `assets/`: 3D models, audio, textures.
- `scenes/`: Godot scene files (.tscn).
- `scripts/`: GDScript logic logic.
  - `player/`: Movement and interaction.
  - `entities/`: Managers and patient nodes.
  - `systems/`: Global events.
  - `ui/`: Interface logic.

## Distribution
Targeted for itch.io.
