#ifndef DEBUGDISPLAY_CS_CUSTOM_HLSL
#define DEBUGDISPLAY_CS_CUSTOM_HLSL

//void PackScreenSpaceTracingDebug(ScreenSpaceTracingDebug input, out uint4 v01, out uint4 v02, out uint4 v03)
//{
//    v01 = uint4(input.startPositionSSX, input.startPositionSSY, input.cellSizeW, input.cellSizeH);
//    v02 = uint4(uint(input.positionTXS.x), uint(input.positionTXS.y), uint(input.positionTXS.z), uint(input.startLinearDepth));
//    v03 = uint4(input.level, input.levelMax, input.iteration, input.iterationMax);
//}
//
//void UnpackScreenSpaceTracingDebug(uint4 v01, uint4 v02, uint4 v03, out ScreenSpaceTracingDebug input)
//{
//    input.startPositionSSX = v01.x;
//    input.startPositionSSY = v01.y;
//    input.cellSizeW = v01.z;
//    input.cellSizeH = v01.w;
//    input.positionTXS.x = float(v02.x);
//    input.positionTXS.y = float(v02.y);
//    input.positionTXS.z = float(v02.z);
//    input.startLinearDepth = float(v02.w);
//    input.level = v03.x;
//    input.levelMax = v03.y;
//    input.iteration = v03.z;
//    input.iterationMax = v03.w;
//}

#endif
