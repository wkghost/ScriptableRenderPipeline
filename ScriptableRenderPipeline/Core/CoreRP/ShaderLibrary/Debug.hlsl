#ifndef UNITY_DEBUG_INCLUDED
#define UNITY_DEBUG_INCLUDED

// Given an enum (represented by an int here), return a color.
// Use for DebugView of enum
real3 GetIndexColor(int index)
{
    real3 outColor = real3(1.0, 0.0, 0.0);

    if (index == 0)
        outColor = real3(1.0, 0.5, 0.5);
    else if (index == 1)
        outColor = real3(0.5, 1.0, 0.5);
    else if (index == 2)
        outColor = real3(0.5, 0.5, 1.0);
    else if (index == 3)
        outColor = real3(1.0, 1.0, 0.5);
    else if (index == 4)
        outColor = real3(1.0, 0.5, 1.0);
    else if (index == 5)
        outColor = real3(0.5, 1.0, 1.0);
    else if (index == 6)
        outColor = real3(0.25, 0.75, 1.0);
    else if (index == 7)
        outColor = real3(1.0, 0.75, 0.25);
    else if (index == 8)
        outColor = real3(0.75, 1.0, 0.25);
    else if (index == 9)
        outColor = real3(0.75, 0.25, 1.0);
    else if (index == 10)
        outColor = real3(0.25, 1.0, 0.75);
    else if (index == 11)
        outColor = real3(0.75, 0.75, 0.25);
    else if (index == 12)
        outColor = real3(0.75, 0.25, 0.75);
    else if (index == 13)
        outColor = real3(0.25, 0.75, 0.75);
    else if (index == 14)
        outColor = real3(0.25, 0.25, 0.75);
    else if (index == 15)
        outColor = real3(0.75, 0.25, 0.25);

    return outColor;
}

bool SampleDebugFont(int2 pixCoord, uint digit)
{
    if (pixCoord.x < 0 || pixCoord.y < 0 || pixCoord.x >= 5 || pixCoord.y >= 9 || digit > 9)
        return false;

#define PACK_BITS25(_x0,_x1,_x2,_x3,_x4,_x5,_x6,_x7,_x8,_x9,_x10,_x11,_x12,_x13,_x14,_x15,_x16,_x17,_x18,_x19,_x20,_x21,_x22,_x23,_x24) (_x0|(_x1<<1)|(_x2<<2)|(_x3<<3)|(_x4<<4)|(_x5<<5)|(_x6<<6)|(_x7<<7)|(_x8<<8)|(_x9<<9)|(_x10<<10)|(_x11<<11)|(_x12<<12)|(_x13<<13)|(_x14<<14)|(_x15<<15)|(_x16<<16)|(_x17<<17)|(_x18<<18)|(_x19<<19)|(_x20<<20)|(_x21<<21)|(_x22<<22)|(_x23<<23)|(_x24<<24))
#define _ 0
#define x 1
    uint fontData[9][2] = {
        { PACK_BITS25(_,_,x,_,_,        _,_,x,_,_,      _,x,x,x,_,      x,x,x,x,x,      _,_,_,x,_), PACK_BITS25(x,x,x,x,x,      _,x,x,x,_,      x,x,x,x,x,      _,x,x,x,_,      _,x,x,x,_) },
        { PACK_BITS25(_,x,_,x,_,        _,x,x,_,_,      x,_,_,_,x,      _,_,_,_,x,      _,_,_,x,_), PACK_BITS25(x,_,_,_,_,      x,_,_,_,x,      _,_,_,_,x,      x,_,_,_,x,      x,_,_,_,x) },
        { PACK_BITS25(x,_,_,_,x,        x,_,x,_,_,      x,_,_,_,x,      _,_,_,x,_,      _,_,x,x,_), PACK_BITS25(x,_,_,_,_,      x,_,_,_,_,      _,_,_,x,_,      x,_,_,_,x,      x,_,_,_,x) },
        { PACK_BITS25(x,_,_,_,x,        _,_,x,_,_,      _,_,_,_,x,      _,_,x,_,_,      _,x,_,x,_), PACK_BITS25(x,_,x,x,_,      x,_,_,_,_,      _,_,_,x,_,      x,_,_,_,x,      x,_,_,_,x) },
        { PACK_BITS25(x,_,_,_,x,        _,_,x,_,_,      _,_,_,x,_,      _,x,x,x,_,      _,x,_,x,_), PACK_BITS25(x,x,_,_,x,      x,x,x,x,_,      _,_,x,_,_,      _,x,x,x,_,      _,x,x,x,x) },
        { PACK_BITS25(x,_,_,_,x,        _,_,x,_,_,      _,_,x,_,_,      _,_,_,_,x,      x,_,_,x,_), PACK_BITS25(_,_,_,_,x,      x,_,_,_,x,      _,_,x,_,_,      x,_,_,_,x,      _,_,_,_,x) },
        { PACK_BITS25(x,_,_,_,x,        _,_,x,_,_,      _,x,_,_,_,      _,_,_,_,x,      x,x,x,x,x), PACK_BITS25(_,_,_,_,x,      x,_,_,_,x,      _,x,_,_,_,      x,_,_,_,x,      _,_,_,_,x) },
        { PACK_BITS25(_,x,_,x,_,        _,_,x,_,_,      x,_,_,_,_,      x,_,_,_,x,      _,_,_,x,_), PACK_BITS25(x,_,_,_,x,      x,_,_,_,x,      _,x,_,_,_,      x,_,_,_,x,      x,_,_,_,x) },
        { PACK_BITS25(_,_,x,_,_,        x,x,x,x,x,      x,x,x,x,x,      _,x,x,x,_,      _,_,_,x,_), PACK_BITS25(_,x,x,x,_,      _,x,x,x,_,      _,x,_,_,_,      _,x,x,x,_,      _,x,x,x,_) }
    };
#undef _
#undef x
#undef PACK_BITS25
    return (fontData[8 - pixCoord.y][digit >= 5] >> ((digit % 5) * 5 + pixCoord.x)) & 1;
}

bool SampleDebugLetter(int2 pixCoord, uint asciiChar)
{
    if (pixCoord.x < 0 || pixCoord.y < 0 || pixCoord.x >= 5 || pixCoord.y >= 9 || asciiChar < 32 || asciiChar >= 127)
        return false;

#define PACK_BITS25(_x0,_x1,_x2,_x3,_x4,_x5,_x6,_x7,_x8,_x9,_x10,_x11,_x12,_x13,_x14,_x15,_x16,_x17,_x18,_x19,_x20,_x21,_x22,_x23,_x24) (_x0|(_x1<<1)|(_x2<<2)|(_x3<<3)|(_x4<<4)|(_x5<<5)|(_x6<<6)|(_x7<<7)|(_x8<<8)|(_x9<<9)|(_x10<<10)|(_x11<<11)|(_x12<<12)|(_x13<<13)|(_x14<<14)|(_x15<<15)|(_x16<<16)|(_x17<<17)|(_x18<<18)|(_x19<<19)|(_x20<<20)|(_x21<<21)|(_x22<<22)|(_x23<<23)|(_x24<<24))
#define _ 0
#define x 1
    uint fontData[90][2] = {
    { PACK_BITS25(_,_,_,_,_,        _,_,x,_,_,      _,x,_,x,_,      _,_,_,_,_,      _,_,x,_,_), PACK_BITS25(_,x,_,_,x,      _,_,x,_,_,      _,_,x,_,_,      _,_,_,x,_,      _,x,_,_,_) },
    { PACK_BITS25(_,_,_,_,_,        _,_,x,_,_,      _,x,_,x,_,      _,_,_,_,_,      _,x,x,x,_), PACK_BITS25(x,_,x,_,x,      _,x,_,x,_,      _,_,x,_,_,      _,_,x,_,_,      _,_,x,_,_) },
    { PACK_BITS25(_,_,_,_,_,        _,_,x,_,_,      _,x,_,x,_,      _,x,_,x,_,      x,_,x,_,_), PACK_BITS25(_,x,_,x,_,      x,_,_,_,x,      _,_,x,_,_,      _,_,x,_,_,      _,_,x,_,_) },
    { PACK_BITS25(_,_,_,_,_,        _,_,x,_,_,      _,_,_,_,_,      x,x,x,x,x,      x,_,x,_,_), PACK_BITS25(_,_,x,_,_,      x,_,_,_,x,      _,_,_,_,_,      _,x,_,_,_,      _,_,_,x,_) },
    { PACK_BITS25(_,_,_,_,_,        _,_,x,_,_,      _,_,_,_,_,      _,x,_,x,_,      _,x,x,x,_), PACK_BITS25(_,_,x,_,_,      x,_,_,x,_,      _,_,_,_,_,      _,x,_,_,_,      _,_,_,x,_) },
    { PACK_BITS25(_,_,_,_,_,        _,_,x,_,_,      _,_,_,_,_,      x,x,x,x,x,      _,_,x,_,x), PACK_BITS25(_,_,x,_,_,      _,x,x,_,_,      _,_,_,_,_,      _,x,_,_,_,      _,_,_,x,_) },
    { PACK_BITS25(_,_,_,_,_,        _,_,x,_,_,      _,_,_,_,_,      _,x,_,x,_,      _,_,x,_,x), PACK_BITS25(_,x,_,x,_,      _,x,x,_,x,      _,_,_,_,_,      _,_,x,_,_,      _,_,x,_,_) },
    { PACK_BITS25(_,_,_,_,_,        _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_,      _,x,x,x,_), PACK_BITS25(x,_,x,_,x,      x,_,_,x,_,      _,_,_,_,_,      _,_,x,_,_,      _,_,x,_,_) },
    { PACK_BITS25(_,_,_,_,_,        _,_,x,_,_,      _,_,_,_,_,      _,_,_,_,_,      _,_,x,_,_), PACK_BITS25(x,_,_,x,_,      _,x,x,_,x,      _,_,_,_,_,      _,_,_,x,_,      _,x,_,_,_) },

    { PACK_BITS25(_,_,_,_,_,         _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_), PACK_BITS25(_,_,_,_,x,       _,_,x,_,_,      _,_,x,_,_,      _,x,x,x,_,      x,x,x,x,x) },
    { PACK_BITS25(_,_,x,_,_,         _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_), PACK_BITS25(_,_,_,x,_,       _,x,_,x,_,      _,x,x,_,_,      x,_,_,_,x,      _,_,_,_,x) },
    { PACK_BITS25(x,_,x,_,x,         _,_,x,_,_,      _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_), PACK_BITS25(_,_,_,x,_,       x,_,_,x,x,      x,_,x,_,_,      x,_,_,_,x,      _,_,_,x,_) },
    { PACK_BITS25(_,x,x,x,_,         _,_,x,_,_,      _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_), PACK_BITS25(_,_,x,_,_,       x,_,_,x,x,      _,_,x,_,_,      _,_,_,_,x,      _,_,x,_,_) },
    { PACK_BITS25(x,x,x,x,x,         x,x,x,x,x,      _,_,_,_,_,      x,x,x,x,x,      _,_,_,_,_), PACK_BITS25(_,_,x,_,_,       x,_,x,_,x,      _,_,x,_,_,      _,_,_,x,_,      _,x,x,x,_) },
    { PACK_BITS25(_,x,x,x,_,         _,_,x,_,_,      _,_,_,x,x,      _,_,_,_,_,      _,_,_,_,_), PACK_BITS25(_,_,x,_,_,       x,x,_,_,x,      _,_,x,_,_,      _,_,x,_,_,      _,_,_,_,x) },
    { PACK_BITS25(x,_,x,_,x,         _,_,x,_,_,      _,_,_,x,x,      _,_,_,_,_,      _,_,_,_,_), PACK_BITS25(_,x,_,_,_,       x,x,_,_,x,      _,_,x,_,_,      _,x,_,_,_,      _,_,_,_,x) },
    { PACK_BITS25(_,_,x,_,_,         _,_,_,_,_,      _,_,x,x,_,      _,_,_,_,_,      _,_,x,x,_), PACK_BITS25(_,x,_,_,_,       _,x,_,x,_,      _,_,x,_,_,      x,_,_,_,_,      x,_,_,_,x) },
    { PACK_BITS25(_,_,_,_,_,         _,_,_,_,_,      _,x,_,_,_,      _,_,_,_,_,      _,_,x,x,_), PACK_BITS25(x,_,_,_,_,       _,_,x,_,_,      x,x,x,x,x,      x,x,x,x,x,      _,x,x,x,_) },

    { PACK_BITS25(_,_,_,x,_,         x,x,x,x,x,      _,x,x,x,_,      x,x,x,x,x,      _,x,x,x,_), PACK_BITS25(_,x,x,x,_,       _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,x,      _,_,_,_,_) },
    { PACK_BITS25(_,_,_,x,_,         x,_,_,_,_,      x,_,_,_,x,      _,_,_,_,x,      x,_,_,_,x), PACK_BITS25(x,_,_,_,x,       _,_,_,_,_,      _,_,_,_,_,      _,_,_,x,_,      _,_,_,_,_) },
    { PACK_BITS25(_,_,x,x,_,         x,_,_,_,_,      x,_,_,_,_,      _,_,_,x,_,      x,_,_,_,x), PACK_BITS25(x,_,_,_,x,       _,_,x,x,_,      _,_,x,x,_,      _,_,x,_,_,      _,_,_,_,_) },
    { PACK_BITS25(_,x,_,x,_,         x,_,x,x,_,      x,_,_,_,_,      _,_,_,x,_,      x,_,_,_,x), PACK_BITS25(x,_,_,_,x,       _,_,x,x,_,      _,_,x,x,_,      _,x,_,_,_,      x,x,x,x,x) },
    { PACK_BITS25(_,x,_,x,_,         x,x,_,_,x,      x,x,x,x,_,      _,_,x,_,_,      _,x,x,x,_), PACK_BITS25(_,x,x,x,x,       _,_,_,_,_,      _,_,_,_,_,      x,_,_,_,_,      _,_,_,_,_) },
    { PACK_BITS25(x,_,_,x,_,         _,_,_,_,x,      x,_,_,_,x,      _,_,x,_,_,      x,_,_,_,x), PACK_BITS25(_,_,_,_,x,       _,_,x,x,_,      _,_,x,x,_,      _,x,_,_,_,      x,x,x,x,x) },
    { PACK_BITS25(x,x,x,x,x,         _,_,_,_,x,      x,_,_,_,x,      _,x,_,_,_,      x,_,_,_,x), PACK_BITS25(_,_,_,_,x,       _,_,x,x,_,      _,_,x,x,_,      _,_,x,_,_,      _,_,_,_,_) },
    { PACK_BITS25(_,_,_,x,_,         x,_,_,_,x,      x,_,_,_,x,      _,x,_,_,_,      x,_,_,_,x), PACK_BITS25(x,_,_,_,x,       _,_,_,_,_,      _,x,x,_,_,      _,_,_,x,_,      _,_,_,_,_) },
    { PACK_BITS25(_,_,_,x,_,         _,x,x,x,_,      _,x,x,x,_,      _,x,_,_,_,      _,x,x,x,_), PACK_BITS25(_,x,x,x,_,       _,_,_,_,_,      x,x,_,_,_,      _,_,_,_,x,      _,_,_,_,_) },

    { PACK_BITS25(x,_,_,_,_,         _,x,x,x,_,      _,_,_,_,_,      _,_,x,_,_,      x,x,x,x,_), PACK_BITS25(_,x,x,x,x,       x,x,x,_,_,      x,x,x,x,x,      x,x,x,x,x,      _,x,x,x,_) },
    { PACK_BITS25(_,x,_,_,_,         x,_,_,_,x,      _,x,x,x,_,      _,x,_,x,_,      x,_,_,_,x), PACK_BITS25(x,_,_,_,_,       x,_,_,x,_,      x,_,_,_,_,      x,_,_,_,_,      x,_,_,_,x) },
    { PACK_BITS25(_,_,x,_,_,         x,_,_,_,x,      x,_,_,_,x,      _,x,_,x,_,      x,_,_,_,x), PACK_BITS25(x,_,_,_,_,       x,_,_,_,x,      x,_,_,_,_,      x,_,_,_,_,      x,_,_,_,x) },
    { PACK_BITS25(_,_,_,x,_,         _,_,_,x,_,      x,_,x,_,x,      x,_,_,_,x,      x,_,_,_,x), PACK_BITS25(x,_,_,_,_,       x,_,_,_,x,      x,_,_,_,_,      x,_,_,_,_,      x,_,_,_,_) },
    { PACK_BITS25(_,_,_,_,x,         _,_,x,x,_,      x,_,x,_,x,      x,_,_,_,x,      x,x,x,x,_), PACK_BITS25(x,_,_,_,_,       x,_,_,_,x,      x,x,x,x,_,      x,x,x,x,_,      x,_,x,x,_) },
    { PACK_BITS25(_,_,_,x,_,         _,_,x,_,_,      x,_,x,_,x,      x,x,x,x,x,      x,_,_,_,x), PACK_BITS25(x,_,_,_,_,       x,_,_,_,x,      x,_,_,_,_,      x,_,_,_,_,      x,_,x,_,x) },
    { PACK_BITS25(_,_,x,_,_,         _,_,_,_,_,      x,_,_,x,_,      x,_,_,_,x,      x,_,_,_,x), PACK_BITS25(x,_,_,_,_,       x,_,_,_,x,      x,_,_,_,_,      x,_,_,_,_,      x,_,_,_,x) },
    { PACK_BITS25(_,x,_,_,_,         _,_,x,_,_,      _,x,_,_,_,      x,_,_,_,x,      x,_,_,_,x), PACK_BITS25(x,_,_,_,_,       x,_,_,x,_,      x,_,_,_,_,      x,_,_,_,_,      x,_,_,_,x) },
    { PACK_BITS25(x,_,_,_,_,         _,_,x,_,_,      _,_,x,x,x,      x,_,_,_,x,      x,x,x,x,x), PACK_BITS25(_,x,x,x,x,       x,x,x,_,_,      x,x,x,x,x,      x,_,_,_,_,      _,x,x,x,x) },

    { PACK_BITS25(x,_,_,_,x,         x,x,x,x,x,      x,x,x,x,x,      x,_,_,_,x,      x,_,_,_,_), PACK_BITS25(x,_,_,_,x,       x,_,_,_,x,      _,x,x,x,_,      x,x,x,x,_,      _,x,x,x,_) },
    { PACK_BITS25(x,_,_,_,x,         _,_,x,_,_,      _,_,_,x,_,      x,_,_,x,_,      x,_,_,_,_), PACK_BITS25(x,x,_,x,x,       x,x,_,_,x,      x,_,_,_,x,      x,_,_,_,x,      x,_,_,_,x) },
    { PACK_BITS25(x,_,_,_,x,         _,_,x,_,_,      _,_,_,x,_,      x,_,x,_,_,      x,_,_,_,_), PACK_BITS25(x,x,x,x,x,       x,x,_,_,x,      x,_,_,_,x,      x,_,_,_,x,      x,_,_,_,x) },
    { PACK_BITS25(x,_,_,_,x,         _,_,x,_,_,      _,_,_,x,_,      x,x,_,_,_,      x,_,_,_,_), PACK_BITS25(x,_,x,_,x,       x,_,x,_,x,      x,_,_,_,x,      x,_,_,_,x,      x,_,_,_,x) },
    { PACK_BITS25(x,x,x,x,x,         _,_,x,_,_,      _,_,_,x,_,      x,_,_,_,_,      x,_,_,_,_), PACK_BITS25(x,_,_,_,x,       x,_,x,_,x,      x,_,_,_,x,      x,x,x,x,_,      x,_,_,_,x) },
    { PACK_BITS25(x,_,_,_,x,         _,_,x,_,_,      _,_,_,x,_,      x,x,_,_,_,      x,_,_,_,_), PACK_BITS25(x,_,_,_,x,       x,_,x,_,x,      x,_,_,_,x,      x,_,_,_,_,      x,_,_,_,x) },
    { PACK_BITS25(x,_,_,_,x,         _,_,x,_,_,      x,_,_,x,_,      x,_,x,_,_,      x,_,_,_,_), PACK_BITS25(x,_,_,_,x,       x,_,_,x,x,      x,_,_,_,x,      x,_,_,_,_,      _,x,x,x,_) },
    { PACK_BITS25(x,_,_,_,x,         _,_,x,_,_,      x,_,_,x,_,      x,_,_,x,_,      x,_,_,_,_), PACK_BITS25(x,_,_,_,x,       x,_,_,x,x,      x,_,_,_,x,      x,_,_,_,_,      _,_,x,_,_) },
    { PACK_BITS25(x,_,_,_,x,         x,x,x,x,x,      _,x,x,_,_,      x,_,_,_,x,      x,x,x,x,x), PACK_BITS25(x,_,_,_,x,       x,_,_,_,x,      _,x,x,x,_,      x,_,_,_,_,      _,_,_,x,x) },

    { PACK_BITS25(x,x,x,x,_,         _,x,x,x,x,      x,x,x,x,x,      _,_,_,_,_,      x,_,_,_,x), PACK_BITS25(x,_,_,_,x,       x,_,_,_,x,      x,_,_,_,x,      x,x,x,x,x,      _,x,x,x,_) },
    { PACK_BITS25(x,_,_,_,x,         x,_,_,_,_,      _,_,x,_,_,      x,_,_,_,x,      x,_,_,_,x), PACK_BITS25(x,_,_,_,x,       _,x,_,x,_,      _,x,_,x,_,      _,_,_,_,x,      _,x,_,_,_) },
    { PACK_BITS25(x,_,_,_,x,         x,_,_,_,_,      _,_,x,_,_,      x,_,_,_,x,      x,_,_,_,x), PACK_BITS25(x,_,_,_,x,       _,x,_,x,_,      _,x,_,x,_,      _,_,_,_,x,      _,x,_,_,_) },
    { PACK_BITS25(x,_,_,_,x,         x,_,_,_,_,      _,_,x,_,_,      x,_,_,_,x,      x,_,_,_,x), PACK_BITS25(x,_,_,_,x,       _,_,x,_,_,      _,_,x,_,_,      _,_,_,x,_,      _,x,_,_,_) },
    { PACK_BITS25(x,x,x,x,_,         _,x,x,x,_,      _,_,x,_,_,      x,_,_,_,x,      _,x,_,x,_), PACK_BITS25(x,_,_,_,x,       _,_,x,_,_,      _,_,x,_,_,      _,_,x,_,_,      _,x,_,_,_) },
    { PACK_BITS25(x,x,_,_,_,         _,_,_,_,x,      _,_,x,_,_,      x,_,_,_,x,      _,x,_,x,_), PACK_BITS25(x,_,x,_,x,       _,_,x,_,_,      _,_,x,_,_,      _,x,_,_,_,      _,x,_,_,_) },
    { PACK_BITS25(x,_,x,_,_,         _,_,_,_,x,      _,_,x,_,_,      x,_,_,_,x,      _,x,_,x,_), PACK_BITS25(x,_,x,_,x,       _,x,_,x,_,      _,_,x,_,_,      x,_,_,_,_,      _,x,_,_,_) },
    { PACK_BITS25(x,_,_,x,_,         _,_,_,_,x,      _,_,x,_,_,      x,_,_,_,x,      _,x,_,x,_), PACK_BITS25(_,x,_,x,_,       _,x,_,x,_,      _,_,x,_,_,      x,_,_,_,_,      _,x,_,_,_) },
    { PACK_BITS25(x,_,_,_,x,         x,x,x,x,_,      _,_,x,_,_,      _,x,x,x,_,      _,_,x,_,_), PACK_BITS25(_,x,_,x,_,       x,_,_,_,x,      _,_,x,_,_,      x,x,x,x,x,      _,x,x,x,_) },

    { PACK_BITS25(x,_,_,_,_,         _,x,x,x,_,      _,_,x,_,_,      _,_,_,_,_,      _,x,_,_,_), PACK_BITS25(_,_,_,_,_,       _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_) },
    { PACK_BITS25(_,x,_,_,_,         _,_,_,x,_,      _,x,_,x,_,      _,_,_,_,_,      _,_,x,_,_), PACK_BITS25(_,_,_,_,_,       _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_) },
    { PACK_BITS25(_,x,_,_,_,         _,_,_,x,_,      x,_,_,_,x,      _,_,_,_,_,      _,_,_,x,_), PACK_BITS25(_,_,_,_,_,       x,_,_,_,_,      _,_,_,_,_,      _,_,_,_,x,      _,_,_,_,_) },
    { PACK_BITS25(_,_,x,_,_,         _,_,_,x,_,      _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_), PACK_BITS25(_,x,x,x,_,       x,_,_,_,_,      _,_,_,_,_,      _,_,_,_,x,      _,_,_,_,_) },
    { PACK_BITS25(_,_,x,_,_,         _,_,_,x,_,      _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_), PACK_BITS25(_,_,_,_,x,       x,_,_,_,_,      _,_,_,_,_,      _,_,_,_,x,      _,x,x,x,_) },
    { PACK_BITS25(_,_,x,_,_,         _,_,_,x,_,      _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_), PACK_BITS25(_,x,x,x,x,       x,x,x,x,_,      _,x,x,x,_,      _,x,x,x,x,      x,_,_,_,x) },
    { PACK_BITS25(_,_,_,x,_,         _,_,_,x,_,      _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_), PACK_BITS25(x,_,_,_,x,       x,_,_,_,x,      x,_,_,_,_,      x,_,_,_,x,      x,_,x,x,x) },
    { PACK_BITS25(_,_,_,x,_,         _,_,_,x,_,      _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_), PACK_BITS25(x,_,_,_,x,       x,_,_,_,x,      x,_,_,_,_,      x,_,_,_,x,      x,_,_,_,_) },
    { PACK_BITS25(_,_,_,_,x,         _,x,x,x,_,      _,_,_,_,_,      x,x,x,x,x,      _,_,_,_,_), PACK_BITS25(_,x,x,x,x,       x,x,x,x,_,      _,x,x,x,_,      _,x,x,x,x,      _,x,x,x,_) },

    { PACK_BITS25(_,_,_,_,_,         _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_), PACK_BITS25(_,_,_,_,_,       _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_) },
    { PACK_BITS25(_,_,_,_,_,         _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_), PACK_BITS25(_,_,_,_,_,       _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_) },
    { PACK_BITS25(_,_,x,x,x,         _,_,_,_,_,      x,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_), PACK_BITS25(x,_,_,_,_,       _,_,x,_,_,      _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_) },
    { PACK_BITS25(_,x,_,_,_,         _,x,x,x,x,      x,_,_,_,_,      _,_,x,_,_,      _,_,_,x,_), PACK_BITS25(x,_,_,x,_,       _,_,x,_,_,      _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_) },
    { PACK_BITS25(_,x,_,_,_,         x,_,_,x,_,      x,_,_,_,_,      _,_,_,_,_,      _,_,_,x,_), PACK_BITS25(x,_,x,_,_,       _,_,x,_,_,      _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_) },
    { PACK_BITS25(_,x,x,x,_,         _,x,x,x,_,      x,x,x,x,_,      _,_,x,_,_,      _,_,_,x,_), PACK_BITS25(x,x,_,_,_,       _,_,x,_,_,      _,x,_,x,_,      x,_,_,_,_,      _,x,x,x,_) },
    { PACK_BITS25(_,x,_,_,_,         _,x,_,_,x,      x,_,_,_,x,      _,_,x,_,_,      _,_,_,x,_), PACK_BITS25(x,_,x,_,_,       _,_,x,_,_,      x,_,x,_,x,      x,x,x,x,_,      x,_,_,_,x) },
    { PACK_BITS25(_,x,_,_,_,         x,_,_,_,x,      x,_,_,_,x,      _,_,x,_,_,      _,x,_,x,_), PACK_BITS25(x,_,_,x,_,       _,_,x,_,_,      x,_,x,_,x,      x,_,_,_,x,      x,_,_,_,x) },
    { PACK_BITS25(_,x,_,_,_,         _,x,x,x,_,      x,_,_,_,x,      _,_,x,_,_,      _,_,x,_,_), PACK_BITS25(x,_,_,_,x,       _,_,x,_,_,      x,_,x,_,x,      x,_,_,_,x,      _,x,x,x,_) },

    { PACK_BITS25(_,_,_,_,_,         _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_), PACK_BITS25(_,_,_,_,_,       _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_) },
    { PACK_BITS25(_,_,_,_,_,         _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_), PACK_BITS25(_,_,_,_,_,       _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_) },
    { PACK_BITS25(x,x,x,x,_,         _,x,x,_,x,      _,_,_,_,_,      _,_,_,_,_,      _,x,_,_,_), PACK_BITS25(_,_,_,_,_,       _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_,      _,x,_,_,x) },
    { PACK_BITS25(x,_,_,_,x,         x,_,_,x,x,      _,_,_,_,_,      _,_,_,_,_,      _,x,_,_,_), PACK_BITS25(_,_,_,_,_,       _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_,      _,x,_,_,x) },
    { PACK_BITS25(x,_,_,_,x,         x,_,_,x,x,      x,_,_,_,_,      _,x,x,x,_,      _,x,x,_,_), PACK_BITS25(_,_,_,_,_,       _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_,      _,x,_,_,x) },
    { PACK_BITS25(x,x,x,x,_,         _,x,x,_,x,      x,_,x,x,x,      x,_,_,_,_,      _,x,_,_,_), PACK_BITS25(x,_,_,_,x,       x,_,_,_,x,      x,_,_,_,x,      x,x,_,x,x,      _,_,x,x,x) },
    { PACK_BITS25(x,_,_,_,_,         _,_,_,_,x,      x,x,_,_,_,      _,x,x,_,_,      _,x,_,_,_), PACK_BITS25(x,_,_,_,x,       x,_,_,_,x,      x,_,_,_,x,      _,_,x,_,_,      _,_,_,_,x) },
    { PACK_BITS25(x,_,_,_,_,         _,_,_,_,x,      x,_,_,_,_,      _,_,_,x,_,      _,x,_,_,_), PACK_BITS25(x,_,_,_,x,       _,x,_,x,_,      x,_,x,_,x,      _,_,x,_,_,      _,_,_,_,x) },
    { PACK_BITS25(x,_,_,_,_,         _,_,_,_,x,      x,_,_,_,_,      x,x,x,_,_,      _,_,x,x,_), PACK_BITS25(_,x,x,x,_,       _,_,x,_,_,      _,x,_,x,_,      x,x,_,x,x,      _,_,x,x,_) },

    { PACK_BITS25(_,_,_,_,_,         _,_,_,x,x,      _,_,x,_,_,      x,x,_,_,_,      _,_,_,_,_), PACK_BITS25(_,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_) },
    { PACK_BITS25(_,_,_,_,_,         _,_,x,_,_,      _,_,x,_,_,      _,_,x,_,_,      _,_,_,_,_), PACK_BITS25(_,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_) },
    { PACK_BITS25(_,_,_,_,_,         _,_,x,_,_,      _,_,x,_,_,      _,_,x,_,_,      _,_,_,_,_), PACK_BITS25(_,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_) },
    { PACK_BITS25(_,_,_,_,_,         _,_,x,_,_,      _,_,x,_,_,      _,_,x,_,_,      _,_,_,x,_), PACK_BITS25(_,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_) },
    { PACK_BITS25(_,_,_,_,_,         _,x,_,_,_,      _,_,x,_,_,      _,_,_,x,_,      _,x,_,x,_), PACK_BITS25(_,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_) },
    { PACK_BITS25(x,x,x,x,_,         _,_,x,_,_,      _,_,x,_,_,      _,_,x,_,_,      x,_,x,_,_), PACK_BITS25(_,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_) },
    { PACK_BITS25(_,_,x,_,_,         _,_,x,_,_,      _,_,x,_,_,      _,_,x,_,_,      x,_,_,_,_), PACK_BITS25(_,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_) },
    { PACK_BITS25(_,x,_,_,_,         _,_,x,_,_,      _,_,x,_,_,      _,_,x,_,_,      _,_,_,_,_), PACK_BITS25(_,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_) },
    { PACK_BITS25(x,x,x,x,_,         _,_,_,x,x,      _,_,x,_,_,      x,x,_,_,_,      _,_,_,_,_), PACK_BITS25(_,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_,      _,_,_,_,_) }
    };
#undef _
#undef x
#undef PACK_BITS25

    uint index = asciiChar - 32u;
    uint row = index / 10;
    uint col = index % 10;

    return (fontData[8 - pixCoord.y + row * 9][col >= 5] >> ((col % 5) * 5 + pixCoord.x)) & 1;
}

#define SAMPLE_DEBUG_STRING(pixCoord, stringValue, isValid)\
{\
    int2 pixCoordValue = pixCoord;\
    for (int i = 0; i < 256; ++i)\
    {\
        uint charValue = stringValue[i];\
        if (charValue == 0)\
        {\
            isValid = false;\
            break;\
        }\
\
        if (SampleDebugLetter(pixCoordValue, charValue))\
        {\
            isValid = true;\
            break;\
        }\
        pixCoordValue -= int2(6, 0);\
    }\
}

bool SampleDebugFloatNumber(int2 pos, float value)
{
    int exp = int(log10(abs(value)));
    float expValue = pow(10, exp);
    float mantissa = value / expValue;

    if (SampleDebugLetter(pos, value < 0 ? '-' : '+'))
        return true;
    pos -= int2(6, 0);

    float absMantissa = abs(mantissa);
    // first mantissa digit
    uint digit = uint(absMantissa);
    if (SampleDebugFont(pos, digit))
        return true;
    absMantissa = (absMantissa - digit) * 10;
    pos -= int2(6, 0);

    if (SampleDebugLetter(pos, '.'))
        return true;
    pos -= int2(6, 0);

    // Other mantissa digit
    int i = 0;
    for (i = 1; i < 7; ++i)
    {
        uint digit = uint(absMantissa);
        if (SampleDebugFont(pos, digit))
            return true;

        absMantissa = (absMantissa - digit) * 10;
        pos -= int2(6, 0);
    }

    // Exponent
    if (SampleDebugLetter(pos, 'E'))
        return true;
    pos -= int2(6, 0);

    if (SampleDebugLetter(pos, exp < 0 ? '-' : '+'))
        return true;
    pos -= int2(6, 0);

    uint absExponent = abs(exp);
    // max 3 digits for exponent
    uint d = 100u;
    for (i = 0; i < 3; ++i)
    {
        uint digit = absExponent / d;
        if (SampleDebugFont(pos, digit))
            return true;

        absExponent = (absExponent - digit * d);
        d /= 10u;
        pos -= int2(6, 0);
    }

    return false;
}

bool SampleDebugFontNumber(int2 pixCoord, uint number)
{
    // Maximum 10 digits
    for (int i = 10; i >= 0; --i)
    {
        uint toTest = number % 10;
        if (SampleDebugFont(pixCoord, toTest))
            return true;

        if (number <= 9)
            return false;

        number = number / 10;
        pixCoord += int2(6, 0);
    }

    return false;
}

float4 GetStreamingMipColor(uint mipCount, float4 mipInfo)
{
    // alpha is amount to blend with source color (0.0 = use original, 1.0 = use new color)

    // mipInfo :
    // x = quality setings minStreamingMipLevel
    // y = original mip count for texture
    // z = desired on screen mip level
    // w = 0
    uint originalTextureMipCount = uint(mipInfo.y);

    // If material/shader mip info (original mip level) has not been set its not a streamed texture
    if (originalTextureMipCount == 0)
        return float4(1.0, 1.0, 1.0, 0.0);

    uint desiredMipLevel = uint(mipInfo.z);
    uint mipCountDesired = uint(originalTextureMipCount)-uint(desiredMipLevel);
    if (mipCount == 0)
    {
        // Magenta if mip count invalid
        return float4(1.0, 0.0, 1.0, 1.0);
    }
    else if (mipCount < mipCountDesired)
    {
        // red tones when not at the desired mip level (reduction due to budget). Brighter is further from original, alpha 0 when at desired
        float ratioToDesired = float(mipCount) / float(mipCountDesired);
        return float4(1.0, 0.0, 0.0, 1.0 - ratioToDesired);
    }
    else if (mipCount >= originalTextureMipCount)
    {
        // original color when at (or beyond) original mip count
        return float4(1.0, 1.0, 1.0, 0.0);
    }
    else
    {
        // green tones when not at the original mip level. Brighter is closer to original, alpha 0 when at original
        float ratioToOriginal = float(mipCount) / float(originalTextureMipCount);
        return float4(0.0, 1.0, 0.0, 1.0 - ratioToOriginal);
    }
}

float4 GetSimpleMipCountColor(uint mipCount)
{
    // Grey scale for mip counts where mip count of 12 = white
    float mipCountColor = float(mipCount) / 12.0;
    float4 color = float4(mipCountColor, mipCountColor, mipCountColor, 1.0f);

    // alpha is amount to blend with source color (0.0 = use original, 1.0 = use new color)
    // Magenta is no valid mip count
    // Original colour if greater than 12
    return mipCount==0 ? float4(1.0, 0.0, 1.0, 1.0) : (mipCount > 12 ? float4(1.0, 1.0, 1.0, 0.0) : color );
}

float4 GetMipLevelColor(float2 uv, float4 texelSize)
{
    // Push down into colors list to "optimal level" in following table.
    // .zw is texture width,height so *2 is down one mip, *4 is down two mips
    texelSize.zw *= 4.0;

    float mipLevel = ComputeTextureLOD(uv, texelSize.wz);
    mipLevel = clamp(mipLevel, 0.0, 5.0 - 0.0001);

    float4 colors[6] = {
        float4(0.0, 0.0, 1.0, 0.8), // 0 BLUE = too little texture detail
        float4(0.0, 0.5, 1.0, 0.4), // 1
        float4(1.0, 1.0, 1.0, 0.0), // 2 = optimal level
        float4(1.0, 0.7, 0.0, 0.2), // 3 (YELLOW tint)
        float4(1.0, 0.3, 0.0, 0.6), // 4 (clamped mipLevel 4.9999)
        float4(1.0, 0.0, 0.0, 0.8)  // 5 RED = too much texture detail (max blended value)
    };

    int mipLevelInt = floor(mipLevel);
    float t = frac(mipLevel);
    float4 a = colors[mipLevelInt];
    float4 b = colors[mipLevelInt + 1];
    float4 color = lerp(a, b, t);

    return color;
}

float3 GetDebugMipColor(float3 originalColor, Texture2D tex, float4 texelSize, float2 uv)
{
    // https://aras-p.info/blog/2011/05/03/a-way-to-visualize-mip-levels/
    float4 mipColor= GetMipLevelColor(uv, texelSize);
    return lerp(originalColor, mipColor.rgb, mipColor.a);
}

float3 GetDebugMipCountColor(float3 originalColor, Texture2D tex)
{
    uint mipCount = GetMipCount(tex);

    float4 mipColor = GetSimpleMipCountColor(mipCount);
    return lerp(originalColor, mipColor.rgb, mipColor.a);
}

float3 GetDebugStreamingMipColor(Texture2D tex, float4 mipInfo)
{
    uint mipCount = GetMipCount(tex);
    return GetStreamingMipColor(mipCount, mipInfo).xyz;
}

float3 GetDebugStreamingMipColorBlended(float3 originalColor, Texture2D tex, float4 mipInfo)
{
    uint mipCount = GetMipCount(tex);
    float4 mipColor = GetStreamingMipColor(mipCount, mipInfo);
    return lerp(originalColor, mipColor.rgb, mipColor.a);
}

float3 GetDebugMipColorIncludingMipReduction(float3 originalColor, Texture2D tex, float4 texelSize, float2 uv, float4 mipInfo)
{
    uint originalTextureMipCount = uint(mipInfo.y);
    if (originalTextureMipCount != 0)
    {
        // mipInfo :
        // x = quality setings minStreamingMipLevel
        // y = original mip count for texture
        // z = desired on screen mip level
        // w = 0

        // Mip count has been reduced but the texelSize was not updated to take that into account
        uint mipCount = GetMipCount(tex);
        uint mipReductionLevel = originalTextureMipCount - mipCount;
        uint mipReductionFactor = 1 << mipReductionLevel;
        if (mipReductionFactor)
        {
            float oneOverMipReductionFactor = 1.0 / mipReductionFactor;
            // texelSize.xy *= mipReductionRatio;   // Unused in GetDebugMipColor so lets not re-calculate it
            texelSize.zw *= oneOverMipReductionFactor;
        }
    }
    return GetDebugMipColor(originalColor, tex, texelSize, uv);
}

// mipInfo :
// x = quality setings minStreamingMipLevel
// y = original mip count for texture
// z = desired on screen mip level
// w = 0
float3 GetDebugMipReductionColor(Texture2D tex, float4 mipInfo)
{
    float3 outColor = float3(1.0, 0.0, 1.0); // Can't calculate without original mip count - return magenta

    uint originalTextureMipCount = uint(mipInfo.y);
    if (originalTextureMipCount != 0)
    {
        // Mip count has been reduced but the texelSize was not updated to take that into account
        uint mipCount = GetMipCount(tex);
        uint mipReductionLevel = originalTextureMipCount - mipCount;

        float mipCol = float(mipReductionLevel) / 12.0;
        outColor = float3(0, mipCol, 0);
    }

    return outColor;
}

// Convert an arbitrary range to color base on threshold provide to the function, threshold must be in growing order
real3 GetColorCodeFunction(real value, real4 threshold)
{
    const real3 red = { 1.0, 0.0, 0.0 };
    const real3 lightGreen = { 0.5, 1.0, 0.5 };
    const real3 darkGreen = { 0.1, 1.0, 0.1 };
    const real3 yellow = { 1.0, 1.0, 0.0 };

    real3 outColor = red;
    if (value < threshold[0])
    {
        outColor = red;
    }
    else if (value >= threshold[0] && value < threshold[1])
    {
        real scale = (value - threshold[0]) / (threshold[1] - threshold[0]);
        outColor = lerp(red, darkGreen, scale);
    }
    else if (value >= threshold[1] && value < threshold[2])
    {
        real scale = (value - threshold[1]) / (threshold[2] - threshold[1]);
        outColor = lerp(darkGreen, lightGreen, scale);
    }
    else if (value >= threshold[2] && value < threshold[3])
    {
        real scale = (value - threshold[2]) / (threshold[2] - threshold[2]);
        outColor = lerp(lightGreen, yellow, scale);
    }
    else
    {
        outColor = yellow;
    }

    return outColor;
}

#endif // UNITY_DEBUG_INCLUDED
