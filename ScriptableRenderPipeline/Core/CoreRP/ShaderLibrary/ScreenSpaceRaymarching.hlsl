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

bool ScreenSpaceRaymarch(
    ScreenSpaceRaymarchInput input,
    out ScreenSpaceRayHit hit)
{
    // dirVS must be normalized

    const float2 CROSS_OFFSET = float2(2, 2);
    const int MAX_ITERATIONS = 32;

    float4 startPositionCS = mul(input.projectionMatrix, float4(input.startPositionVS, 1));
    float4 dirCS = mul(input.projectionMatrix, float4(input.dirVS, 1));
#if UNITY_UV_STARTS_AT_TOP
    // Our clip space is correct, but the NDC is flipped.
    // Conceptually, it should be (positionNDC.y = 1.0 - positionNDC.y), but this is more efficient.
    startPositionCS.y = -startPositionCS.y;
    dirCS.y = -dirCS.y;
#endif

    float2 startPositionNDC = (startPositionCS.xy * rcp(startPositionCS.w)) * 0.5 + 0.5;
    // store linear depth in z
    float l = length(dirCS.xy);
    float3 dirNDC = dirCS.xyz / l;

    float2 invDirNDC = float2(1, 1) / dirNDC.xy;
    int2 cellPlanes = sign(dirNDC.xy);
    float2 crossOffset = CROSS_OFFSET * cellPlanes;
    cellPlanes = clamp(cellPlanes, 0, 1);

    uint2 startPositionTXS = uint2(startPositionNDC * input.bufferSize);

    ZERO_INITIALIZE(ScreenSpaceRayHit, hit);

    int currentLevel = input.minLevel;
    uint2 cellCount = input.bufferSize >> currentLevel;
    uint2 cellSize = uint2(1, 1) << currentLevel;

    // store linear depth in z
    float3 positionTXS = float3(float2(startPositionTXS), input.startLinearDepth);
    int iteration = 0;

    bool hitSuccessful = true;

#ifdef DEBUG_DISPLAY
    int maxUsedLevel = currentLevel;

    ScreenSpaceTracingDebug debug;
    ZERO_INITIALIZE(ScreenSpaceTracingDebug, debug);
    debug.startPositionSSX = startPositionTXS.x;
    debug.startPositionSSY = startPositionTXS.y;
    debug.startLinearDepth = input.startLinearDepth;
    debug.levelMax = input.maxLevel;
    debug.iterationMax = MAX_ITERATIONS;
#endif

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
        }
#endif

        // 1. Calculate hit in this HiZ cell
        int2 cellId = int2(positionTXS.xy) / cellCount;

        // Planes to check
        int2 planes = (cellId + cellPlanes) * cellSize;
        // Hit distance to each planes
        float2 distanceToCellAxes = float2(planes - positionTXS.xy) * invDirNDC; // (distance to x axis, distance to y axis)

        float distanceToCell = min(distanceToCellAxes.x, distanceToCellAxes.y);
        float3 testHitPositionTXS = positionTXS + dirNDC * distanceToCell;

        // Offset the proper axis to enforce cell crossing
        // https://gamedev.autodesk.com/blogs/1/post/5866685274515295601
        testHitPositionTXS.xy += (distanceToCellAxes.x < distanceToCellAxes.y)
            ? float2(crossOffset.x, 0)
            : float2(0, crossOffset.y);

        if (any(testHitPositionTXS.xy > input.bufferSize)
            || any(testHitPositionTXS.xy < 0))
        {
            hitSuccessful = false;
            break;
        }

        // 2. Sample the HiZ cell
        float pyramidDepth = LOAD_TEXTURE2D_LOD(_PyramidDepthTexture, int2(testHitPositionTXS.xy) >> currentLevel, currentLevel).r;
        float hiZLinearDepth = LinearEyeDepth(pyramidDepth, _ZBufferParams);

        if (hiZLinearDepth < testHitPositionTXS.z)
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
            float rayOffsetLength = (hiZLinearDepth - positionTXS.z) / dirNDC.z;
            positionTXS += dirNDC * rayOffsetLength;
            hit.distance += rayOffsetLength;
            --currentLevel;
        }

        cellCount = input.bufferSize >> currentLevel;
        cellSize = uint2(1, 1) << currentLevel;

        ++iteration;
    }

    hit.linearDepth = positionTXS.z;
    hit.positionSS = float2(positionTXS.xy) / float2(input.bufferSize);

#ifdef DEBUG_DISPLAY
    debug.level = maxUsedLevel;
    debug.iteration = iteration;

    //if (input.writeStepDebug)
    {
        debug.cellSizeW = 16;
        debug.cellSizeH = 16;

        uint4 v01 = 0;
        uint4 v02 = 0;
        uint4 v03 = 0;
        PackScreenSpaceTracingDebug(debug, v01, v02, v03);
        _DebugScreenSpaceTracing[uint2(0, 0)] = v01;
        _DebugScreenSpaceTracing[uint2(1, 0)] = v02;
        _DebugScreenSpaceTracing[uint2(0, 1)] = v03;
    }

    if (_DebugLightingMode == DEBUGLIGHTINGMODE_SCREEN_SPACE_TRACING_REFRACTION)
    {
        switch (_DebugLightingSubMode)
        {
            case DEBUGSCREENSPACETRACING_POSITION_NDC:
                hit.debugOutput = float3(startPositionNDC.xy, 0);
                break;
            case DEBUGSCREENSPACETRACING_DIR_VS:
                hit.debugOutput = input.dirVS * 0.5 + 0.5;
                break;
            case DEBUGSCREENSPACETRACING_DIR_NDC:
                hit.debugOutput = float3(dirNDC.xy * 0.5 + 0.5, dirNDC.z);
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
