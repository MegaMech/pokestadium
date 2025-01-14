#include <ultra64.h>

extern void func_80000460(); // thread 1 function
extern void func_8002B330(); // thread 6 function

// entry .bss
u8 D_8007ED80[0xF180-0xED80]; // unknown, start of .bss
OSThread D_8007F180;
u8 unk_8007F330[0x400];
OSThread D_8007F730;
u8 unk_8007F8E0[0x720];
u8 D_80080000[0x18E0];
u8 D_800818E0[0x18];
u8 D_800818F8[0x8];

void func_80000460(s32 arg0) {
    osCreateViManager(0xFE);
    func_80001474(0, 1);
    osViBlack(1);
    func_80008F7C();
    func_80000D54();
    func_800052B4();
    func_8000D564();
    func_800019C8();
    func_800057C0();
    osCreateThread(&D_8007F730, 6, &func_8002B330, 0, &D_800818E0, 0x14);
    osStartThread(&D_8007F730);
    osSetThreadPri(0, 0);
    while(1);
}

void main(void) {
    osInitialize();
    osCartRomInit();
    func_8000B7D0(0);
    func_80002F58();
    osCreateThread(&D_8007F180, 1, &func_80000460, 0, &D_8007F730, 0x64);
    osStartThread(&D_8007F180);
}
