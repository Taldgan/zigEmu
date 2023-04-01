const std = @import("std");
const print = std.debug.print;
const File = std.fs.File;

pub fn disassemble(buf: []u8, pc: u32) u8 {
    var op = buf[pc];
    switch (op) {
        0x00 => {
            print("\x1b[36mNOP\n\x1b[0m", .{});
            return 1;
        },
        0x01 => {
            print("\x1b[36mLXI B,D16\n\x1b[0m", .{});
            return 3;
        },
        0x02 => {
            print("\x1b[36mSTAX B\n\x1b[0m", .{});
            return 1;
        },
        0x03 => {
            print("\x1b[36mINX B\n\x1b[0m", .{});
            return 1;
        },
        0x04 => {
            print("\x1b[36mINR B\n\x1b[0m", .{});
            return 1;
        },
        0x05 => {
            print("\x1b[36mDCR B\n\x1b[0m", .{});
            return 1;
        },
        0x06 => {
            print("\x1b[36mMVI B, D8\n\x1b[0m", .{});
            return 2;
        },
        0x07 => {
            print("\x1b[36mRLC\n\x1b[0m", .{});
            return 1;
        },
        0x09 => {
            print("\x1b[36mDAD B\n\x1b[0m", .{});
            return 1;
        },
        0x0a => {
            print("\x1b[36mLDAX B\n\x1b[0m", .{});
            return 1;
        },
        0x0b => {
            print("\x1b[36mDCX B\n\x1b[0m", .{});
            return 1;
        },
        0x0c => {
            print("\x1b[36mINR C\n\x1b[0m", .{});
            return 1;
        },
        0x0d => {
            print("\x1b[36mDCR C\n\x1b[0m", .{});
            return 1;
        },
        0x0e => {
            print("\x1b[36mMVI C,D8\n\x1b[0m", .{});
            return 2;
        },
        0x0f => {
            print("\x1b[36mRRC\n\x1b[0m", .{});
            return 1;
        },
        0x11 => {
            print("\x1b[36mLXI D,D16\n\x1b[0m", .{});
            return 3;
        },
        0x12 => {
            print("\x1b[36mSTAX D\n\x1b[0m", .{});
            return 1;
        },
        0x13 => {
            print("\x1b[36mINX D\n\x1b[0m", .{});
            return 1;
        },
        0x14 => {
            print("\x1b[36mINR D\n\x1b[0m", .{});
            return 1;
        },
        0x15 => {
            print("\x1b[36mDCR D\n\x1b[0m", .{});
            return 1;
        },
        0x16 => {
            print("\x1b[36mMVI D, D8\n\x1b[0m", .{});
            return 2;
        },
        0x17 => {
            print("\x1b[36mRAL\n\x1b[0m", .{});
            return 1;
        },
        0x19 => {
            print("\x1b[36mDAD D\n\x1b[0m", .{});
            return 1;
        },
        0x1a => {
            print("\x1b[36mLDAX D\n\x1b[0m", .{});
            return 1;
        },
        0x1b => {
            print("\x1b[36mDCX D\n\x1b[0m", .{});
            return 1;
        },
        0x1c => {
            print("\x1b[36mINR E\n\x1b[0m", .{});
            return 1;
        },
        0x1d => {
            print("\x1b[36mDCR E\n\x1b[0m", .{});
            return 1;
        },
        0x1e => {
            print("\x1b[36mMVI E,D8\n\x1b[0m", .{});
            return 2;
        },
        0x1f => {
            print("\x1b[36mRAR\n\x1b[0m", .{});
            return 1;
        },
        0x21 => {
            print("\x1b[36mLXI H,D16\n\x1b[0m", .{});
            return 3;
        },
        0x22 => {
            print("\x1b[36mSHLD addr\n\x1b[0m", .{});
            return 3;
        },
        0x23 => {
            print("\x1b[36mINX H\n\x1b[0m", .{});
            return 1;
        },
        0x24 => {
            print("\x1b[36mINR H\n\x1b[0m", .{});
            return 1;
        },
        0x25 => {
            print("\x1b[36mDCR H\n\x1b[0m", .{});
            return 1;
        },
        0x26 => {
            print("\x1b[36mMVI H,D8\n\x1b[0m", .{});
            return 2;
        },
        0x27 => {
            print("\x1b[36mDAA\n\x1b[0m", .{});
            return 1;
        },
        0x29 => {
            print("\x1b[36mDAD H\n\x1b[0m", .{});
            return 1;
        },
        0x2a => {
            print("\x1b[36mLHLD addr\n\x1b[0m", .{});
            return 3;
        },
        0x2b => {
            print("\x1b[36mDCX H\n\x1b[0m", .{});
            return 1;
        },
        0x2c => {
            print("\x1b[36mINR L\n\x1b[0m", .{});
            return 1;
        },
        0x2d => {
            print("\x1b[36mDCR L\n\x1b[0m", .{});
            return 1;
        },
        0x2e => {
            print("\x1b[36mMVI L, D8\n\x1b[0m", .{});
            return 2;
        },
        0x2f => {
            print("\x1b[36mCMA\n\x1b[0m", .{});
            return 1;
        },
        0x31 => {
            print("\x1b[36mLXI SP, D16\n\x1b[0m", .{});
            return 3;
        },
        0x32 => {
            print("\x1b[36mSTA addr\n\x1b[0m", .{});
            return 3;
        },
        0x33 => {
            print("\x1b[36mINX SP\n\x1b[0m", .{});
            return 1;
        },
        0x34 => {
            print("\x1b[36mINR M\n\x1b[0m", .{});
            return 1;
        },
        0x35 => {
            print("\x1b[36mDCR M\n\x1b[0m", .{});
            return 1;
        },
        0x36 => {
            print("\x1b[36mMVI M,D8\n\x1b[0m", .{});
            return 2;
        },
        0x37 => {
            print("\x1b[36mSTC\n\x1b[0m", .{});
            return 1;
        },
        0x39 => {
            print("\x1b[36mDAD SP\n\x1b[0m", .{});
            return 1;
        },
        0x3a => {
            print("\x1b[36mLDA addr\n\x1b[0m", .{});
            return 3;
        },
        0x3b => {
            print("\x1b[36mDCX SP\n\x1b[0m", .{});
            return 1;
        },
        0x3c => {
            print("\x1b[36mINR A\n\x1b[0m", .{});
            return 1;
        },
        0x3d => {
            print("\x1b[36mDCR A\n\x1b[0m", .{});
            return 1;
        },
        0x3e => {
            print("\x1b[36mMVI A,D8\n\x1b[0m", .{});
            return 2;
        },
        0x3f => {
            print("\x1b[36mCMC\n\x1b[0m", .{});
            return 1;
        },
        0x40 => {
            print("\x1b[36mMOV B,B\n\x1b[0m", .{});
            return 1;
        },
        0x41 => {
            print("\x1b[36mMOV B,C\n\x1b[0m", .{});
            return 1;
        },
        0x42 => {
            print("\x1b[36mMOV B,D\n\x1b[0m", .{});
            return 1;
        },
        0x43 => {
            print("\x1b[36mMOV B,E\n\x1b[0m", .{});
            return 1;
        },
        0x44 => {
            print("\x1b[36mMOV B,H\n\x1b[0m", .{});
            return 1;
        },
        0x45 => {
            print("\x1b[36mMOV B,L\n\x1b[0m", .{});
            return 1;
        },
        0x46 => {
            print("\x1b[36mMOV B,M\n\x1b[0m", .{});
            return 1;
        },
        0x47 => {
            print("\x1b[36mMOV B,A\n\x1b[0m", .{});
            return 1;
        },
        0x48 => {
            print("\x1b[36mMOV C,B\n\x1b[0m", .{});
            return 1;
        },
        0x49 => {
            print("\x1b[36mMOV C,C\n\x1b[0m", .{});
            return 1;
        },
        0x4a => {
            print("\x1b[36mMOV C,D\n\x1b[0m", .{});
            return 1;
        },
        0x4b => {
            print("\x1b[36mMOV C,E\n\x1b[0m", .{});
            return 1;
        },
        0x4c => {
            print("\x1b[36mMOV C,H\n\x1b[0m", .{});
            return 1;
        },
        0x4d => {
            print("\x1b[36mMOV C,L\n\x1b[0m", .{});
            return 1;
        },
        0x4e => {
            print("\x1b[36mMOV C,M\n\x1b[0m", .{});
            return 1;
        },
        0x4f => {
            print("\x1b[36mMOV C,A\n\x1b[0m", .{});
            return 1;
        },
        0x50 => {
            print("\x1b[36mMOV D,B\n\x1b[0m", .{});
            return 1;
        },
        0x51 => {
            print("\x1b[36mMOV D,C\n\x1b[0m", .{});
            return 1;
        },
        0x52 => {
            print("\x1b[36mMOV D,D\n\x1b[0m", .{});
            return 1;
        },
        0x53 => {
            print("\x1b[36mMOV D,E\n\x1b[0m", .{});
            return 1;
        },
        0x54 => {
            print("\x1b[36mMOV D,H\n\x1b[0m", .{});
            return 1;
        },
        0x55 => {
            print("\x1b[36mMOV D,L\n\x1b[0m", .{});
            return 1;
        },
        0x56 => {
            print("\x1b[36mMOV D,M\n\x1b[0m", .{});
            return 1;
        },
        0x57 => {
            print("\x1b[36mMOV D,A\n\x1b[0m", .{});
            return 1;
        },
        0x58 => {
            print("\x1b[36mMOV E,B\n\x1b[0m", .{});
            return 1;
        },
        0x59 => {
            print("\x1b[36mMOV E,C\n\x1b[0m", .{});
            return 1;
        },
        0x5a => {
            print("\x1b[36mMOV E,D\n\x1b[0m", .{});
            return 1;
        },
        0x5b => {
            print("\x1b[36mMOV E,E\n\x1b[0m", .{});
            return 1;
        },
        0x5c => {
            print("\x1b[36mMOV E,H\n\x1b[0m", .{});
            return 1;
        },
        0x5d => {
            print("\x1b[36mMOV E,L\n\x1b[0m", .{});
            return 1;
        },
        0x5e => {
            print("\x1b[36mMOV E,M\n\x1b[0m", .{});
            return 1;
        },
        0x5f => {
            print("\x1b[36mMOV E,A\n\x1b[0m", .{});
            return 1;
        },
        0x60 => {
            print("\x1b[36mMOV H,B\n\x1b[0m", .{});
            return 1;
        },
        0x61 => {
            print("\x1b[36mMOV H,C\n\x1b[0m", .{});
            return 1;
        },
        0x62 => {
            print("\x1b[36mMOV H,D\n\x1b[0m", .{});
            return 1;
        },
        0x63 => {
            print("\x1b[36mMOV H,E\n\x1b[0m", .{});
            return 1;
        },
        0x64 => {
            print("\x1b[36mMOV H,H\n\x1b[0m", .{});
            return 1;
        },
        0x65 => {
            print("\x1b[36mMOV H,L\n\x1b[0m", .{});
            return 1;
        },
        0x66 => {
            print("\x1b[36mMOV H,M\n\x1b[0m", .{});
            return 1;
        },
        0x67 => {
            print("\x1b[36mMOV H,A\n\x1b[0m", .{});
            return 1;
        },
        0x68 => {
            print("\x1b[36mMOV L,B\n\x1b[0m", .{});
            return 1;
        },
        0x69 => {
            print("\x1b[36mMOV L,C\n\x1b[0m", .{});
            return 1;
        },
        0x6a => {
            print("\x1b[36mMOV L,D\n\x1b[0m", .{});
            return 1;
        },
        0x6b => {
            print("\x1b[36mMOV L,E\n\x1b[0m", .{});
            return 1;
        },
        0x6c => {
            print("\x1b[36mMOV L,H\n\x1b[0m", .{});
            return 1;
        },
        0x6d => {
            print("\x1b[36mMOV L,L\n\x1b[0m", .{});
            return 1;
        },
        0x6e => {
            print("\x1b[36mMOV L,M\n\x1b[0m", .{});
            return 1;
        },
        0x6f => {
            print("\x1b[36mMOV L,A\n\x1b[0m", .{});
            return 1;
        },
        0x70 => {
            print("\x1b[36mMOV M,B\n\x1b[0m", .{});
            return 1;
        },
        0x71 => {
            print("\x1b[36mMOV M,C\n\x1b[0m", .{});
            return 1;
        },
        0x72 => {
            print("\x1b[36mMOV M,D\n\x1b[0m", .{});
            return 1;
        },
        0x73 => {
            print("\x1b[36mMOV M,E\n\x1b[0m", .{});
            return 1;
        },
        0x74 => {
            print("\x1b[36mMOV M,H\n\x1b[0m", .{});
            return 1;
        },
        0x75 => {
            print("\x1b[36mMOV M,L\n\x1b[0m", .{});
            return 1;
        },
        0x76 => {
            print("\x1b[36mHLT\n\x1b[0m", .{});
            return 1;
        },
        0x77 => {
            print("\x1b[36mMOV M,A\n\x1b[0m", .{});
            return 1;
        },
        0x78 => {
            print("\x1b[36mMOV A,B\n\x1b[0m", .{});
            return 1;
        },
        0x79 => {
            print("\x1b[36mMOV A,C\n\x1b[0m", .{});
            return 1;
        },
        0x7a => {
            print("\x1b[36mMOV A,D\n\x1b[0m", .{});
            return 1;
        },
        0x7b => {
            print("\x1b[36mMOV A,E\n\x1b[0m", .{});
            return 1;
        },
        0x7c => {
            print("\x1b[36mMOV A,H\n\x1b[0m", .{});
            return 1;
        },
        0x7d => {
            print("\x1b[36mMOV A,L\n\x1b[0m", .{});
            return 1;
        },
        0x7e => {
            print("\x1b[36mMOV A,M\n\x1b[0m", .{});
            return 1;
        },
        0x7f => {
            print("\x1b[36mMOV A,A\n\x1b[0m", .{});
            return 1;
        },
        0x80 => {
            print("\x1b[36mADD B\n\x1b[0m", .{});
            return 1;
        },
        0x81 => {
            print("\x1b[36mADD C\n\x1b[0m", .{});
            return 1;
        },
        0x82 => {
            print("\x1b[36mADD D\n\x1b[0m", .{});
            return 1;
        },
        0x83 => {
            print("\x1b[36mADD E\n\x1b[0m", .{});
            return 1;
        },
        0x84 => {
            print("\x1b[36mADD H\n\x1b[0m", .{});
            return 1;
        },
        0x85 => {
            print("\x1b[36mADD L\n\x1b[0m", .{});
            return 1;
        },
        0x86 => {
            print("\x1b[36mADD M\n\x1b[0m", .{});
            return 1;
        },
        0x87 => {
            print("\x1b[36mADD A\n\x1b[0m", .{});
            return 1;
        },
        0x88 => {
            print("\x1b[36mADC B\n\x1b[0m", .{});
            return 1;
        },
        0x89 => {
            print("\x1b[36mADC C\n\x1b[0m", .{});
            return 1;
        },
        0x8a => {
            print("\x1b[36mADC D\n\x1b[0m", .{});
            return 1;
        },
        0x8b => {
            print("\x1b[36mADC E\n\x1b[0m", .{});
            return 1;
        },
        0x8c => {
            print("\x1b[36mADC H\n\x1b[0m", .{});
            return 1;
        },
        0x8d => {
            print("\x1b[36mADC L\n\x1b[0m", .{});
            return 1;
        },
        0x8e => {
            print("\x1b[36mADC M\n\x1b[0m", .{});
            return 1;
        },
        0x8f => {
            print("\x1b[36mADC A\n\x1b[0m", .{});
            return 1;
        },
        0x90 => {
            print("\x1b[36mSUB B\n\x1b[0m", .{});
            return 1;
        },
        0x91 => {
            print("\x1b[36mSUB C\n\x1b[0m", .{});
            return 1;
        },
        0x92 => {
            print("\x1b[36mSUB D\n\x1b[0m", .{});
            return 1;
        },
        0x93 => {
            print("\x1b[36mSUB E\n\x1b[0m", .{});
            return 1;
        },
        0x94 => {
            print("\x1b[36mSUB H\n\x1b[0m", .{});
            return 1;
        },
        0x95 => {
            print("\x1b[36mSUB L\n\x1b[0m", .{});
            return 1;
        },
        0x96 => {
            print("\x1b[36mSUB M\n\x1b[0m", .{});
            return 1;
        },
        0x97 => {
            print("\x1b[36mSUB A\n\x1b[0m", .{});
            return 1;
        },
        0x98 => {
            print("\x1b[36mSBB B\n\x1b[0m", .{});
            return 1;
        },
        0x99 => {
            print("\x1b[36mSBB C\n\x1b[0m", .{});
            return 1;
        },
        0x9a => {
            print("\x1b[36mSBB D\n\x1b[0m", .{});
            return 1;
        },
        0x9b => {
            print("\x1b[36mSBB E\n\x1b[0m", .{});
            return 1;
        },
        0x9c => {
            print("\x1b[36mSBB H\n\x1b[0m", .{});
            return 1;
        },
        0x9d => {
            print("\x1b[36mSBB L\n\x1b[0m", .{});
            return 1;
        },
        0x9e => {
            print("\x1b[36mSBB M\n\x1b[0m", .{});
            return 1;
        },
        0x9f => {
            print("\x1b[36mSBB A\n\x1b[0m", .{});
            return 1;
        },
        0xa0 => {
            print("\x1b[36mANA B\n\x1b[0m", .{});
            return 1;
        },
        0xa1 => {
            print("\x1b[36mANA C\n\x1b[0m", .{});
            return 1;
        },
        0xa2 => {
            print("\x1b[36mANA D\n\x1b[0m", .{});
            return 1;
        },
        0xa3 => {
            print("\x1b[36mANA E\n\x1b[0m", .{});
            return 1;
        },
        0xa4 => {
            print("\x1b[36mANA H\n\x1b[0m", .{});
            return 1;
        },
        0xa5 => {
            print("\x1b[36mANA L\n\x1b[0m", .{});
            return 1;
        },
        0xa6 => {
            print("\x1b[36mANA M\n\x1b[0m", .{});
            return 1;
        },
        0xa7 => {
            print("\x1b[36mANA A\n\x1b[0m", .{});
            return 1;
        },
        0xa8 => {
            print("\x1b[36mXRA B\n\x1b[0m", .{});
            return 1;
        },
        0xa9 => {
            print("\x1b[36mXRA C\n\x1b[0m", .{});
            return 1;
        },
        0xaa => {
            print("\x1b[36mXRA D\n\x1b[0m", .{});
            return 1;
        },
        0xab => {
            print("\x1b[36mXRA E\n\x1b[0m", .{});
            return 1;
        },
        0xac => {
            print("\x1b[36mXRA H\n\x1b[0m", .{});
            return 1;
        },
        0xad => {
            print("\x1b[36mXRA L\n\x1b[0m", .{});
            return 1;
        },
        0xae => {
            print("\x1b[36mXRA M\n\x1b[0m", .{});
            return 1;
        },
        0xaf => {
            print("\x1b[36mXRA A\n\x1b[0m", .{});
            return 1;
        },
        0xb0 => {
            print("\x1b[36mORA B\n\x1b[0m", .{});
            return 1;
        },
        0xb1 => {
            print("\x1b[36mORA C\n\x1b[0m", .{});
            return 1;
        },
        0xb2 => {
            print("\x1b[36mORA D\n\x1b[0m", .{});
            return 1;
        },
        0xb3 => {
            print("\x1b[36mORA E\n\x1b[0m", .{});
            return 1;
        },
        0xb4 => {
            print("\x1b[36mORA H\n\x1b[0m", .{});
            return 1;
        },
        0xb5 => {
            print("\x1b[36mORA L\n\x1b[0m", .{});
            return 1;
        },
        0xb6 => {
            print("\x1b[36mORA M\n\x1b[0m", .{});
            return 1;
        },
        0xb7 => {
            print("\x1b[36mORA A\n\x1b[0m", .{});
            return 1;
        },
        0xb8 => {
            print("\x1b[36mCMP B\n\x1b[0m", .{});
            return 1;
        },
        0xb9 => {
            print("\x1b[36mCMP C\n\x1b[0m", .{});
            return 1;
        },
        0xba => {
            print("\x1b[36mCMP D\n\x1b[0m", .{});
            return 1;
        },
        0xbb => {
            print("\x1b[36mCMP E\n\x1b[0m", .{});
            return 1;
        },
        0xbc => {
            print("\x1b[36mCMP H\n\x1b[0m", .{});
            return 1;
        },
        0xbd => {
            print("\x1b[36mCMP L\n\x1b[0m", .{});
            return 1;
        },
        0xbe => {
            print("\x1b[36mCMP M\n\x1b[0m", .{});
            return 1;
        },
        0xbf => {
            print("\x1b[36mCMP A\n\x1b[0m", .{});
            return 1;
        },
        0xc0 => {
            print("\x1b[36mRNZ\n\x1b[0m", .{});
            return 1;
        },
        0xc1 => {
            print("\x1b[36mPOP B\n\x1b[0m", .{});
            return 1;
        },
        0xc2 => {
            print("\x1b[36mJNZ addr\n\x1b[0m", .{});
            return 3;
        },
        0xc3 => {
            print("\x1b[36mJMP addr\n\x1b[0m", .{});
            return 3;
        },
        0xc4 => {
            print("\x1b[36mCNZ addr\n\x1b[0m", .{});
            return 3;
        },
        0xc5 => {
            print("\x1b[36mPUSH B\n\x1b[0m", .{});
            return 1;
        },
        0xc6 => {
            print("\x1b[36mADI D8\n\x1b[0m", .{});
            return 2;
        },
        0xc7 => {
            print("\x1b[36mRST 0\n\x1b[0m", .{});
            return 1;
        },
        0xc8 => {
            print("\x1b[36mRZ\n\x1b[0m", .{});
            return 1;
        },
        0xc9 => {
            print("\x1b[36mRET\n\x1b[0m", .{});
            return 1;
        },
        0xca => {
            print("\x1b[36mJZ addr\n\x1b[0m", .{});
            return 3;
        },
        0xcc => {
            print("\x1b[36mCZ addr\n\x1b[0m", .{});
            return 3;
        },
        0xcd => {
            print("\x1b[36mCALL addr\n\x1b[0m", .{});
            return 3;
        },
        0xce => {
            print("\x1b[36mACI D8\n\x1b[0m", .{});
            return 2;
        },
        0xcf => {
            print("\x1b[36mRST 1\n\x1b[0m", .{});
            return 1;
        },
        0xd0 => {
            print("\x1b[36mRNC\n\x1b[0m", .{});
            return 1;
        },
        0xd1 => {
            print("\x1b[36mPOP D\n\x1b[0m", .{});
            return 1;
        },
        0xd2 => {
            print("\x1b[36mJNC addr\n\x1b[0m", .{});
            return 3;
        },
        0xd3 => {
            print("\x1b[36mOUT D8\n\x1b[0m", .{});
            return 2;
        },
        0xd4 => {
            print("\x1b[36mCNC addr\n\x1b[0m", .{});
            return 3;
        },
        0xd5 => {
            print("\x1b[36mPUSH D\n\x1b[0m", .{});
            return 1;
        },
        0xd6 => {
            print("\x1b[36mSUI D8\n\x1b[0m", .{});
            return 2;
        },
        0xd7 => {
            print("\x1b[36mRST 2\n\x1b[0m", .{});
            return 1;
        },
        0xd8 => {
            print("\x1b[36mRC\n\x1b[0m", .{});
            return 1;
        },
        0xda => {
            print("\x1b[36mJC addr\n\x1b[0m", .{});
            return 3;
        },
        0xdb => {
            print("\x1b[36mIN D8\n\x1b[0m", .{});
            return 2;
        },
        0xdc => {
            print("\x1b[36mCC addr\n\x1b[0m", .{});
            return 3;
        },
        0xde => {
            print("\x1b[36mSBI D8\n\x1b[0m", .{});
            return 2;
        },
        0xdf => {
            print("\x1b[36mRST 3\n\x1b[0m", .{});
            return 1;
        },
        0xe0 => {
            print("\x1b[36mRPO\n\x1b[0m", .{});
            return 1;
        },
        0xe1 => {
            print("\x1b[36mPOP H\n\x1b[0m", .{});
            return 1;
        },
        0xe2 => {
            print("\x1b[36mJPO addr\n\x1b[0m", .{});
            return 3;
        },
        0xe3 => {
            print("\x1b[36mXTHL\n\x1b[0m", .{});
            return 1;
        },
        0xe4 => {
            print("\x1b[36mCPO addr\n\x1b[0m", .{});
            return 3;
        },
        0xe5 => {
            print("\x1b[36mPUSH H\n\x1b[0m", .{});
            return 1;
        },
        0xe6 => {
            print("\x1b[36mANI D8\n\x1b[0m", .{});
            return 2;
        },
        0xe7 => {
            print("\x1b[36mRST 4\n\x1b[0m", .{});
            return 1;
        },
        0xe8 => {
            print("\x1b[36mRPE\n\x1b[0m", .{});
            return 1;
        },
        0xe9 => {
            print("\x1b[36mPCHL\n\x1b[0m", .{});
            return 1;
        },
        0xea => {
            print("\x1b[36mJPE addr\n\x1b[0m", .{});
            return 3;
        },
        0xeb => {
            print("\x1b[36mXCHG\n\x1b[0m", .{});
            return 1;
        },
        0xec => {
            print("\x1b[36mCPE addr\n\x1b[0m", .{});
            return 3;
        },
        0xee => {
            print("\x1b[36mXRI D8\n\x1b[0m", .{});
            return 2;
        },
        0xef => {
            print("\x1b[36mRST 5\n\x1b[0m", .{});
            return 1;
        },
        0xf0 => {
            print("\x1b[36mRP\n\x1b[0m", .{});
            return 1;
        },
        0xf1 => {
            print("\x1b[36mPOP PSW\n\x1b[0m", .{});
            return 1;
        },
        0xf2 => {
            print("\x1b[36mJP addr\n\x1b[0m", .{});
            return 3;
        },
        0xf3 => {
            print("\x1b[36mDI\n\x1b[0m", .{});
            return 1;
        },
        0xf4 => {
            print("\x1b[36mCP addr\n\x1b[0m", .{});
            return 3;
        },
        0xf5 => {
            print("\x1b[36mPUSH PSW\n\x1b[0m", .{});
            return 1;
        },
        0xf6 => {
            print("\x1b[36mORI D8\n\x1b[0m", .{});
            return 2;
        },
        0xf7 => {
            print("\x1b[36mRST 6\n\x1b[0m", .{});
            return 1;
        },
        0xf8 => {
            print("\x1b[36mRM\n\x1b[0m", .{});
            return 1;
        },
        0xf9 => {
            print("\x1b[36mSPHL\n\x1b[0m", .{});
            return 1;
        },
        0xfa => {
            print("\x1b[36mJM addr\n\x1b[0m", .{});
            return 3;
        },
        0xfb => {
            print("\x1b[36mEI\n\x1b[0m", .{});
            return 1;
        },
        0xfc => {
            print("\x1b[36mCM addr\n\x1b[0m", .{});
            return 3;
        },
        0xfe => {
            print("\x1b[36mCPI D8\n\x1b[0m", .{});
            return 2;
        },
        0xff => {
            print("\x1b[36mRST 7\n\x1b[0m", .{});
            return 1;
        },
        0xfd, 0xed, 0x08, 0x10, 0xdd, 0xd9, 0xcb, 0x38, 0x30, 0x28, 0x20, 0x18 => {
            print("\x1b[36mINVALID OPCODE\n\x1b[0m", .{});
            return 0;
        },
    }
    return 0;
}

fn readEmuFile(file_name: []const u8, alloc: std.mem.Allocator) ![]u8 {
    const cwd = std.fs.cwd();
    var file = try cwd.openFile(file_name, .{});
    defer file.close();
    //const file_reader: std.io.Reader = file.reader();
    return try file.readToEndAlloc(alloc, std.math.maxInt(usize));
}

pub fn main() !void {
    var arg_it = std.process.args();
    _ = arg_it.skip();
    //ArgIterator.next() could possibly return a null value - which means
    //the type it will return must be an 'optional' ?[]const u8
    //To counteract this, we use an if
    //In the following if, we check if the 'file_name' that
    //came from the iterator is null
    //If it isn't, then it will execute the block and assign the
    //pointer value to |name|. Name is now NOT an optional, and also guaranteed
    //to have a non-null value ([]u8)
    const file_name = arg_it.next();
    if (file_name) |name| {
        print("Want to open {s}, but zig hates me.\n", .{name});
        //Create arena allocator 'arena'
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        const alloc = arena.allocator();
        //defer means execute at end of scope (main in this case)
        //Arena allocators deinit ALL memory allocated using it
        //once deinit() is called
        defer arena.deinit();
        var emuBuf = try readEmuFile(name, alloc);
        var i: u32 = 0;
        while (i <= emuBuf.len - 1) {
            print("0x{x}: ", .{i});
            var opSize = disassemble(emuBuf, i);
            i += opSize;
        }
    }
}
