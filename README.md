# Laser Chess

A two-player strategy game built with Godot 4 and GDScript. Players place and move laser-themed pieces on a 10×10 board, redirect beams with mirrors and splitters, and try to defeat the opposing king.

## Gameplay represented in the source

- Separate setup turns for the blue and red teams
- Kings, lasers, mirrors, blockers, and splitters
- Laser reflection, splitting, shields, and piece destruction
- Two action points per turn during the playing phase
- Team territories and restricted laser rows
- Restart, information, and game-over interfaces

The interface and in-game messages are primarily in Turkish.

## Controls

- Left click: select/place a card or select/move a piece
- Right click during setup: return one of your placed inventory pieces
- Right click during play: rotate the selected piece
- UI buttons: rotate/cancel placement, finish setup, restart, show information, or exit

## Run locally

1. Open this directory as a project in Godot 4.6 or a compatible Godot 4 release.
2. Let Godot import the project assets.
3. Run the project; [`scenes/Menu.tscn`](scenes/Menu.tscn) is configured as the main scene.

The repository also contains a Windows Desktop export preset, but no exported executable is included.

## Project structure

```text
.
├── project.godot       # Godot project and main-scene configuration
├── scenes/             # Menu, game, information, and reusable piece scenes
├── scripts/            # GDScript gameplay and UI logic
├── assets/board/       # Board tile textures
└── sprites/            # Piece textures
```

## Validation status

Scene/script/resource paths were checked statically. The project was not launched during this refresh because a Godot executable was not available in the environment. Two already tracked temporary scene snapshots remain in `scenes/`; new `*.tmp` files are ignored, but the existing files were not deleted automatically.
