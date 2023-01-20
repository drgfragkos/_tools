#define WIN32_LEAN_AND_MEAN
#define WINWER 0x0610
#define _WIN32_WINNT 0x0610
#include <windows.h>

int main(void)
{
	INPUT i;
	while (1)
	{
		i.type = INPUT_MOUSE;
		i.mi.dx = 0;
		i.mi.dy = 0;
		i.mi.mouseData = 0;
		i.mi.dwFlags = (MOUSEEVENTF_MOVE || MOUSEEVENTF_ABSOLUTE);
		i.mi.time = 0;
		i.mi.dwExtraInfo = GetMessageExtraInfo();
		SendInput(1, &i, sizeof(i));
		Sleep(1000);
	}
	return 0;
}
