//
// This file was automatically generated. Please don't edit by hand.
//

#ifndef DEBUGDISPLAY_CS_HLSL
#define DEBUGDISPLAY_CS_HLSL
//
// UnityEngine.Experimental.Rendering.HDPipeline.FullScreenDebugMode:  static fields
//
#define FULLSCREENDEBUGMODE_NONE (0)
#define FULLSCREENDEBUGMODE_MIN_LIGHTING_FULL_SCREEN_DEBUG (1)
#define FULLSCREENDEBUGMODE_SSAO (2)
#define FULLSCREENDEBUGMODE_DEFERRED_SHADOWS (3)
#define FULLSCREENDEBUGMODE_PRE_REFRACTION_COLOR_PYRAMID (4)
#define FULLSCREENDEBUGMODE_DEPTH_PYRAMID (5)
#define FULLSCREENDEBUGMODE_FINAL_COLOR_PYRAMID (6)
#define FULLSCREENDEBUGMODE_SCREEN_SPACE_TRACING_REFRACTION (7)
#define FULLSCREENDEBUGMODE_MAX_LIGHTING_FULL_SCREEN_DEBUG (8)
#define FULLSCREENDEBUGMODE_MIN_RENDERING_FULL_SCREEN_DEBUG (9)
#define FULLSCREENDEBUGMODE_MOTION_VECTORS (10)
#define FULLSCREENDEBUGMODE_NAN_TRACKER (11)
#define FULLSCREENDEBUGMODE_MAX_RENDERING_FULL_SCREEN_DEBUG (12)

// Generated from UnityEngine.Experimental.Rendering.HDPipeline.ScreenSpaceTracingDebug
// PackingRules = Exact
struct ScreenSpaceTracingDebug
{
    uint startPositionSSX;
    uint startPositionSSY;
    uint cellSizeW;
    uint cellSizeH;
    float3 positionTXS;
    float startLinearDepth;
    uint level;
    uint levelMax;
    uint iteration;
    uint iterationMax;
    float hitDistance;
    float hitLinearDepth;
    float2 hitPositionSS;
};

//
// Accessors for UnityEngine.Experimental.Rendering.HDPipeline.ScreenSpaceTracingDebug
//
uint GetStartPositionSSX(ScreenSpaceTracingDebug value)
{
	return value.startPositionSSX;
}
uint GetStartPositionSSY(ScreenSpaceTracingDebug value)
{
	return value.startPositionSSY;
}
uint GetCellSizeW(ScreenSpaceTracingDebug value)
{
	return value.cellSizeW;
}
uint GetCellSizeH(ScreenSpaceTracingDebug value)
{
	return value.cellSizeH;
}
float3 GetPositionTXS(ScreenSpaceTracingDebug value)
{
	return value.positionTXS;
}
float GetStartLinearDepth(ScreenSpaceTracingDebug value)
{
	return value.startLinearDepth;
}
uint GetLevel(ScreenSpaceTracingDebug value)
{
	return value.level;
}
uint GetLevelMax(ScreenSpaceTracingDebug value)
{
	return value.levelMax;
}
uint GetIteration(ScreenSpaceTracingDebug value)
{
	return value.iteration;
}
uint GetIterationMax(ScreenSpaceTracingDebug value)
{
	return value.iterationMax;
}
float GetHitDistance(ScreenSpaceTracingDebug value)
{
	return value.hitDistance;
}
float GetHitLinearDepth(ScreenSpaceTracingDebug value)
{
	return value.hitLinearDepth;
}
float2 GetHitPositionSS(ScreenSpaceTracingDebug value)
{
	return value.hitPositionSS;
}


#endif
#include "DebugDisplay.cs.custom.hlsl"