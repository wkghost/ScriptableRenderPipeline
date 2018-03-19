#ifndef UNITY_SCREEN_SPACE_RAYMARCHING_INCLUDED
#define UNITY_SCREEN_SPACE_RAYMARCHING_INCLUDED

struct ScreenSpaceRaymarchInput
{
    float3 startPositionVS;
    float startLinearDepth;
    float3 dirVS;
    float4x4 projectionMatrix;
    int2 bufferSize;
    int minLevel;
    int maxLevel;

#ifdef DEBUG_DISPLAY
    bool writeStepDebug;
    uint2 sourcePositionSS;
    float sourceDepth;
#endif
};

struct ScreenSpaceRayHit
{
    float distance;
    float linearDepth;
    float2 positionSS;

#ifdef DEBUG_DISPLAY
    float3 debugOutput;
#endif
};

float _SSTCrossingOffset = 1;

void CalculateRayTXS(ScreenSpaceRaymarchInput input, out float3 positionTXS, out float3 rayTXS)
{
    float3 positionVS = input.startPositionVS;
    float3 rayEndVS = input.startPositionVS + input.dirVS * 10;

    float4 positionCS = ComputeClipSpacePosition(positionVS, input.projectionMatrix);
    float4 rayEndCS = ComputeClipSpacePosition(rayEndVS, input.projectionMatrix);

    float2 positionNDC = ComputeNormalizedDeviceCoordinates(positionVS, input.projectionMatrix);
    float2 rayEndNDC = ComputeNormalizedDeviceCoordinates(rayEndVS, input.projectionMatrix);

    float3 rayStartTXS = float3(
        positionNDC.xy * input.bufferSize,
        1.0 / positionCS.w); // Screen space depth interpolate properly in 1/z

    float3 rayEndTXS = float3(
        rayEndNDC.xy * input.bufferSize,
        1.0 / rayEndCS.w); // Screen space depth interpolate properly in 1/z

    positionTXS = rayStartTXS;
    rayTXS = rayEndTXS - rayStartTXS;
}

bool IsPositionAboveDepth(float rayDepth, float invLinearDepth)
{
    // as depth is inverted, we must invert the check as well
    // rayZ > HiZ <=> 1/rayZ < 1/HiZ
    return rayDepth > invLinearDepth;
}

bool ScreenSpaceRaymarch(
    ScreenSpaceRaymarchInput input,
    out ScreenSpaceRayHit hit)
{
    const float2 CROSS_OFFSET = float2(1, 1);
    const int MAX_ITERATIONS = 32;

    ZERO_INITIALIZE(ScreenSpaceRayHit, hit);

    // Caclulate TXS ray
    float3 startPositionTXS;
    float3 rayTXS;
    CalculateRayTXS(input, startPositionTXS, rayTXS);

#ifdef DEBUG_DISPLAY
    int maxUsedLevel = input.minLevel;

    ScreenSpaceTracingDebug debug;
    ZERO_INITIALIZE(ScreenSpaceTracingDebug, debug);
    debug.startPositionSSX = uint(startPositionTXS.x);
    debug.startPositionSSY = uint(startPositionTXS.y);
    debug.startLinearDepth = 1 / startPositionTXS.z;
#endif

    bool hitSuccessful = true;
    int iteration = 0;
    if (!any(rayTXS.xy))
    {
        hit.distance = 1 / startPositionTXS.z;
        hit.linearDepth = 1 / startPositionTXS.z;
        hit.positionSS = uint2(startPositionTXS.xy);
    }
    else
    {
        float2 invRayTXS = float2(1, 1) / rayTXS.xy;

        // Calculate planes to intersect for each cell
        int2 cellPlanes = sign(rayTXS.xy);
        float2 crossOffset = CROSS_OFFSET * cellPlanes * _SSTCrossingOffset;
        cellPlanes = clamp(cellPlanes, 0, 1);

        // Initialize loop
        int currentLevel = input.minLevel;
        uint2 cellCount = input.bufferSize >> currentLevel;
        uint2 cellSize = uint2(1, 1) << currentLevel;

        float3 positionTXS = startPositionTXS;

        while (currentLevel >= input.minLevel)
        {
            if (iteration >= MAX_ITERATIONS)
            {
                hitSuccessful = false;
                break;
            }

#ifdef DEBUG_DISPLAY
            if (_DebugStep == iteration)
            {
                debug.cellSizeW = cellSize.x;
                debug.cellSizeH = cellSize.y;
                debug.positionTXS = positionTXS;
                debug.hitLinearDepth = 1 / positionTXS.z;
                debug.hitPositionSS = uint2(positionTXS.xy);
                debug.iteration = iteration;
                debug.level = currentLevel;
            }
#endif

            // 1. Calculate hit in this HiZ cell
            int2 cellId = int2(positionTXS.xy) / cellSize;

            // Planes to check
            int2 planes = (cellId + cellPlanes) * cellSize;
            // Hit distance to each planes
            float2 distanceToCellAxes = float2(planes - positionTXS.xy) * invRayTXS; // (distance to x axis, distance to y axis)
            float distanceToCell = min(distanceToCellAxes.x, distanceToCellAxes.y);
            // Interpolate screen space to get next test point
            float3 testHitPositionTXS = positionTXS + rayTXS * distanceToCell;

            // Offset the proper axis to enforce cell crossing
            // https://gamedev.autodesk.com/blogs/1/post/5866685274515295601
            testHitPositionTXS.xy += (distanceToCellAxes.x < distanceToCellAxes.y)
                ? float2(crossOffset.x, 0)
                : float2(0, crossOffset.y);

            // Check if we are out of the buffer
            if (any(testHitPositionTXS.xy > input.bufferSize)
                || any(testHitPositionTXS.xy < 0))
            {
                hitSuccessful = false;
                break;
            }

            // 2. Sample the HiZ cell
            float pyramidDepth = LOAD_TEXTURE2D_LOD(_PyramidDepthTexture, int2(testHitPositionTXS.xy) >> currentLevel, currentLevel).r;
            float hiZLinearDepth = LinearEyeDepth(pyramidDepth, _ZBufferParams);
            float invHiZLinearDepth = 1 / hiZLinearDepth;

            if (IsPositionAboveDepth(testHitPositionTXS.z, invHiZLinearDepth))
            {
                currentLevel = min(input.maxLevel, currentLevel + 1);
#ifdef DEBUG_DISPLAY
                maxUsedLevel = max(maxUsedLevel, currentLevel);
#endif
                positionTXS = testHitPositionTXS;
                hit.distance += distanceToCell;
            }
            else
            {
                float rayOffsetLength = (invHiZLinearDepth - positionTXS.z) / rayTXS.z;
                positionTXS += rayTXS * rayOffsetLength;
                hit.distance += rayOffsetLength;
                --currentLevel;
            }

            cellCount = input.bufferSize >> currentLevel;
            cellSize = uint2(1, 1) << currentLevel;

            ++iteration;
        }

        hit.linearDepth = 1 / positionTXS.z;
        hit.positionSS = float2(positionTXS.xy) / float2(input.bufferSize);
    }
    
#ifdef DEBUG_DISPLAY
    debug.levelMax = maxUsedLevel;
    debug.iterationMax = iteration;
    debug.hitDistance = hit.distance;

    if (input.writeStepDebug)
    {
        _DebugScreenSpaceTracingData[0] = debug;
    }

    if (_DebugLightingMode == DEBUGLIGHTINGMODE_SCREEN_SPACE_TRACING_REFRACTION)
    {
        switch (_DebugLightingSubMode)
        {
            case DEBUGSCREENSPACETRACING_POSITION_NDC:
                hit.debugOutput = float3(float2(startPositionTXS.xy) / input.bufferSize, 0);
                break;
            case DEBUGSCREENSPACETRACING_DIR_VS:
                hit.debugOutput = input.dirVS * 0.5 + 0.5;
                break;
            case DEBUGSCREENSPACETRACING_DIR_NDC:
                hit.debugOutput = float3(rayTXS.xy * 0.5 + 0.5, frac(0.1 / rayTXS.z));
                break;
            case DEBUGSCREENSPACETRACING_HIT_DISTANCE:
                hit.debugOutput = frac(hit.distance * 0.1);
                break;
            case DEBUGSCREENSPACETRACING_HIT_DEPTH:
                hit.debugOutput = frac(hit.linearDepth * 0.1);
                break;
            case DEBUGSCREENSPACETRACING_HIT_SUCCESS:
                hit.debugOutput = hitSuccessful;
                break;
            case DEBUGSCREENSPACETRACING_ITERATION_COUNT:
                hit.debugOutput = float(iteration) / float(MAX_ITERATIONS);
                break;
            case DEBUGSCREENSPACETRACING_MAX_USED_LEVEL:
                hit.debugOutput = float(maxUsedLevel) / float(input.maxLevel);
                break;
        }
    }
#endif

    return hitSuccessful;
}

#endif
