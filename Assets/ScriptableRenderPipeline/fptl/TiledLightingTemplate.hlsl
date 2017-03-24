#ifndef __TILEDLIGHTINGTEMPLATE_H__
#define __TILEDLIGHTINGTEMPLATE_H__

#include "LightingTemplate.hlsl" // change order to get access to unity_StereoEyeIndex
#include "TiledLightingUtils.hlsl"




float3 ExecuteLightList(out uint numLightsProcessed, uint2 pixCoord, float3 vP, float3 vPw, float3 Vworld)
{
    uint start = 0, numLights = 0;
    GetCountAndStart(start, numLights, pixCoord, vP.z, DIRECT_LIGHT);

    numLightsProcessed = numLights;     // mainly for debugging/heat maps
    return ExecuteLightList(start, numLights, vP, vPw, Vworld);
}

#endif
