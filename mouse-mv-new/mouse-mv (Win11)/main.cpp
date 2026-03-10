/*
    mouse-mv: Mouse Mover Application
    ----------------------------------
    Purpose:
      This program generates mouse move events at random intervals (1337-314159 ms) to keep the Windows system awake.
      It runs silently in the background (compiled as a Windows GUI application) and simulates
      mouse movement without actual displacement, except for periodic real moves to screen center every 5-10 min.
	  
    Technical Details:
      - Uses the Windows API function SendInput() to simulate a mouse movement.
      - Zero movement (dx = 0, dy = 0) is used with the flag MOUSEEVENTF_MOVE.
      - Attempts to register a global hotkey (CTRL+SHIFT+Q) for graceful termination.
        If registration fails, the application will continue to run without a hotkey.
      - Employs MsgWaitForMultipleObjects() to wait for a specified period while processing
        any incoming messages (e.g., the hotkey event).

    Graceful Termination:
      - If the hotkey is successfully registered, press CTRL+SHIFT+Q at any time to signal
        the application to terminate gracefully.
      - If the hotkey is not registered, the application will run indefinitely. You must use
        an external method (like Task Manager) to terminate the process.

    Compilation Instructions:
    ---------------------------
    Required Files:
      1. main.cpp        - This source file.
      2. resource.rc     - Resource file containing version information and icon.
      3. Makefile.txt    - Makefile for building the project.

    Steps:
      1. Ensure you have MinGW installed with its 'bin' directory added to your system PATH.
      2. Open a command prompt in the directory containing these files.
      3. Run the command:
             make -f Makefile.txt
         This will compile the program using g++ with the necessary resource file and options.
      4. The resulting executable (mouse-mv.exe) will run in the background and send mouse events.

    Notes:
      - The program is compiled as a Windows subsystem application (using -mwindows).
      - It targets Windows 10/11 (WINVER and _WIN32_WINNT set to 0x0A00).
      - If the hotkey (CTRL+SHIFT+Q) cannot be registered, the program still runs.
*/


#define WINVER 0x0A00
#define _WIN32_WINNT 0x0A00
#include <windows.h>
#include <stdbool.h>
#include <cstdlib>  // For rand() and srand()
#include <ctime>    // For time()

int main(void)
{
    srand(static_cast<unsigned int>(time(NULL)));  // Seed RNG once

    // Attempt to register global hotkey: CTRL + SHIFT + Q (virtual-key 'Q')
    // If registration fails, hotkeyRegistered remains false.
    bool hotkeyRegistered = (RegisterHotKey(NULL, 1, MOD_CONTROL | MOD_SHIFT, 'Q') != 0);

    bool running = true;
    INPUT input;  // Structure for simulating input events

    // For periodic real mouse move
    DWORD last_real_move = GetTickCount();
    DWORD next_real_interval = 300000 + rand() % (600000 - 300000 + 1);  // 5-10 min in ms

    while (running)
    {
        // Zero out the structure to avoid uninitialized fields.
        ZeroMemory(&input, sizeof(INPUT));
        input.type = INPUT_MOUSE;
        input.mi.dx = 0;
        input.mi.dy = 0;
        input.mi.mouseData = 0;
        // Use only MOUSEEVENTF_MOVE to simulate a "jiggle" (zero movement).
        input.mi.dwFlags = MOUSEEVENTF_MOVE;
        input.mi.time = 0;
        input.mi.dwExtraInfo = GetMessageExtraInfo();
        SendInput(1, &input, sizeof(INPUT));

        // Check for periodic real move
        DWORD current_time = GetTickCount();
        if (current_time - last_real_move >= next_real_interval)
        {
            POINT original_pos;
            GetCursorPos(&original_pos);

            int screen_width = GetSystemMetrics(SM_CXSCREEN);
            int screen_height = GetSystemMetrics(SM_CYSCREEN);
            SetCursorPos(screen_width / 2, screen_height / 2);

            Sleep(50);

            SetCursorPos(original_pos.x, original_pos.y);

            last_real_move = GetTickCount();
            next_real_interval = 300000 + rand() % (600000 - 300000 + 1);  // Reset random interval
        }

        // Random jiggle delay: 1337-314159 ms
        int jiggle_delay = 1337 + rand() % (314159 - 1337 + 1);
        DWORD result = MsgWaitForMultipleObjects(0, NULL, FALSE, jiggle_delay, QS_ALLINPUT);
        if (result == WAIT_OBJECT_0)
        {
            MSG msg;
            // Process all pending messages.
            while (PeekMessage(&msg, NULL, 0, 0, PM_REMOVE))
            {
                // If hotkey was registered and the hotkey event is detected, terminate the loop.
                if (hotkeyRegistered && msg.message == WM_HOTKEY && msg.wParam == 1)
                {
                    running = false;
                }
                TranslateMessage(&msg);
                DispatchMessage(&msg);
            }
        }
    }

    // Unregister the hotkey if it was successfully registered.
    if (hotkeyRegistered)
    {
        UnregisterHotKey(NULL, 1);
    }

    return 0;
}