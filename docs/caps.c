
// this allows for toggling caplock on Windows_NT
// just note that there should be newer equivalet of keybd_event
// also I'm wondering if there is a way to just set the caps natively
// because current aproach check if caps is up and then toggles it
// should compile fine with mingw:
//     $ cc caps.c -o caps && ./caps.exe


#include <windows.h>
#include <stdlib.h>
#include <stdbool.h>


bool caps_get(void);
void caps_set(bool new);
void caps_toggle(void);
int main(void);


bool
caps_get()
{
	BYTE keboard_state[256];
	GetKeyboardState((LPBYTE)(&keboard_state));
	return (keboard_state[VK_CAPITAL] & 1);
}

void
caps_set(bool new)
{
	const bool current = caps_get();
	if(new != current)
		caps_toggle();
}

void
caps_toggle(void)
{
	keybd_event(VK_CAPITAL, 0, KEYEVENTF_EXTENDEDKEY, 0);
	keybd_event(VK_CAPITAL, 0, KEYEVENTF_EXTENDEDKEY | KEYEVENTF_KEYUP, 0);
}

int
main(void)
{
	caps_set(false);
	return EXIT_SUCCESS;
}

