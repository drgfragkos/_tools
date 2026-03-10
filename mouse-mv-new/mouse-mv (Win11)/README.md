# mouse-mv: Mouse Mover Utility

A simple, lightweight Windows application that simulates mouse movements to prevent the system from going idle or sleeping. It runs silently in the background and is designed for long-running tasks where you need to keep your machine awake without manual intervention.

## Purpose
This utility generates periodic mouse "jiggle" events (zero-displacement moves) at random intervals to reset the Windows idle timer. It also includes occasional real cursor movements to the screen center and back for added robustness against potential future idle detection changes. Built as a GUI application (no console window), it targets Windows 10/11.

## Features
- **Randomized Jiggle Intervals**: Simulates mouse moves every 1337–314159 ms (about 1.3 seconds to 5.2 minutes) to mimic natural activity and avoid detection patterns.
- **Periodic Real Moves**: Every 5–10 minutes (randomized), briefly moves the cursor to the screen center for 50 ms and back to its original position, ensuring verifiable position changes.
- **Global Hotkey for Exit**: Registers CTRL+SHIFT+Q for graceful termination (falls back to running indefinitely if registration fails).
- **Low Resource Usage**: Efficient waiting loop with minimal CPU impact.
- **Embedded Metadata**: Includes version info, description, and icon for easy identification in File Properties.
- **Cross-Compilation Support**: Can be built on Linux/WSL using MinGW-w64 for Windows targets.

## Requirements
- **For Building**:
  - MinGW-w64 (on Windows or Linux/WSL): Includes `x86_64-w64-mingw32-g++`, `x86_64-w64-mingw32-windres`, and `x86_64-w64-mingw32-strip`.
  - On Ubuntu/WSL: Install with `sudo apt install mingw-w64 g++-mingw-w64-x86-64 make`.
- **For Running**: Windows 10/11 (x64).
- **Files Needed**: `main.cpp`, `resource.rc`, `Makefile.txt`, and `mouse-mv.ico` (custom icon file).

## Building
1. Place all files (`main.cpp`, `resource.rc`, `Makefile.txt`, `mouse-mv.ico`) in one directory.
2. If building on Linux/WSL, ensure Unix-style line endings: `sed -i 's/\r$//' *.cpp *.rc *.txt`.
3. Run: `make -f Makefile.txt`.
4. The output is `mouse-mv.exe` (stripped for smaller size).

If building natively on Windows with MinGW, adjust the Makefile to use `g++`, `windres`, and `strip` without prefixes.

## Usage
- Double-click `mouse-mv.exe` or run from Command Prompt—it starts silently in the background.
- It will keep sending mouse events until terminated.
- Verify it's running via Task Manager (look for "mouse-mv.exe").
- Test: Set a short sleep timeout in Windows Power & Sleep settings; the system should stay awake.

## Termination
- If the hotkey registered successfully, press CTRL+SHIFT+Q to quit.
- Otherwise, use Task Manager: Find "mouse-mv.exe" and End Task.

## Notes
- **Compatibility**: Tested on Windows 11; uses standard WinAPI calls that should work on Win10+.
- **Version Info**: File version 3.14.15.92, Product version 3.14.0.0 (view in Properties > Details).
- **Description**: "mouse-move events generator for MS Windows(TM) to keep the system awake. Use CTRL+SHIFT+Q to Quit"
- **Customization**: Edit intervals or behavior in `main.cpp`; adjust metadata in `resource.rc`.
- **Potential Issues**: Antivirus may flag as a "jiggler" tool (benign). In monitored environments, randomness helps evade detection.
- **Implementation**: Compiled on WSL (as embedded in metadata).

## License
MIT License (as specified in resource metadata).

Copyright (c) @drgfragkos