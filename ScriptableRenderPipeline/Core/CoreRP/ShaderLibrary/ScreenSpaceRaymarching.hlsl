#ifndef UNITY_SCREEN_SPACE_RAYMARCHING_INCLUDED
#define UNITY_SCREEN_SPACE_RAYMARCHING_INCLUDED

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
    float3 startPositionVS,
    float startLinearDepth,
    float3 dirVS,
    float4x4 projectionMatrix,
    int2 bufferSize,
    int minLevel,
    int maxLevel,
    out ScreenSpaceRayHit hit)
{
    // dirVS must be normalized

    const float2 CROSS_OFFSET = float2(1, 1);
    const int MAX_ITERATIONS = 32;

    float4 startPositionCS = mul(projectionMatrix, float4(startPositionVS, 1));
    float4 dirCS = mul(projectionMatrix, float4(dirVS, 0));
#if UNITY_UV_STARTS_AT_TOP
    // Our clip space is correct, but the NDC is flipped.
    // Conceptually, it should be (positionNDC.y = 1.0 - positionNDC.y), but this is more efficient.
    startPositionCS.y = -startPositionCS.y;
    dirCS.y = -dirCS.y;
#endif

    float2 startPositionNDC = (startPositionCS.xy * rcp(startPositionCS.w)) * 0.5 + 0.5;
    // store linear depth in z
    float3 dirNDC = float3(normalize((dirCS.xy * rcp(dirCS.w)) * 0.5 + 0.5), -dirVS.z /*RHS convention for VS*/);
    float2 invDirNDC = 1 / dirNDC.xy;
    int2 cellPlanes = clamp(sign(dirNDC.xy), 0, 1);

    int2 startPositionTXS = int2(startPositionNDC * bufferSize);

    ZERO_INITIALIZE(ScreenSpaceRayHit, hit);

    int currentLevel = minLevel;
    int2 cellCount = bufferSize >> minLevel;
    int2 cellSize = int2(1 / float2(cellCount));

    // store linear depth in z
    float3 positionTXS = float3(float2(startPositionTXS), startLinearDepth);
    int iteration = 0;

    bool hitSuccessful = true;

    while (currentLevel >= minLevel)
    {
        if (++iteration < MAX_ITERATIONS)
        {
            hitSuccessful = false;
            break;
        }

        // 1. Calculate hit in this HiZ cell
        int2 cellId = int2(positionTXS.xy) / cellCount;

        // Planes to check
        int2 planes = (cellId + cellPlanes) * cellSize;
        // Hit distance to each planes
        float2 planeHits = (planes - positionTXS.xy) * invDirNDC;

        float rayOffsetTestLength = min(planeHits.x, planeHits.y);
        float3 testHitPositionTXS = positionTXS + dirNDC * rayOffsetTestLength;

        // Offset the proper axis to enforce cell crossing
        // https://gamedev.autodesk.com/blogs/1/post/5866685274515295601
        testHitPositionTXS.xy += (planeHits.x < planeHits.y) ? float2(CROSS_OFFSET.x, 0) : float2(0, CROSS_OFFSET.y);

        if (any(testHitPositionTXS.xy > bufferSize)
            || any(testHitPositionTXS.xy < 0))
        {
            hitSuccessful = false;
            break;
        }

        // 2. Sample the HiZ cell
        float pyramidDepth = LOAD_TEXTURE2D_LOD(_PyramidDepthTexture, int2(testHitPositionTXS.xy) >> currentLevel, currentLevel).r;
        float hiZLinearDepth = LinearEyeDepth(pyramidDepth, _ZBufferParams);

        if (hiZLinearDepth > testHitPositionTXS.z)
        {
            currentLevel = min(maxLevel, currentLevel + 1);
            positionTXS = testHitPositionTXS;
            hit.distance += rayOffsetTestLength;
        }
        else
        {
            float rayOffsetLength = (hiZLinearDepth - positionTXS.z) / dirNDC.z;
            positionTXS += dirNDC * rayOffsetLength;
            hit.distance += rayOffsetLength;
        }
    }

    hit.linearDepth = positionTXS.z;
    hit.positionSS = float2(positionTXS.xy) / float2(bufferSize);

#ifdef DEBUG_DISPLAY
    if (_DebugLightingMode == DEBUGLIGHTINGMODE_SCREEN_SPACE_TRACING_REFRACTION)
    {
        switch (_DebugLightingSubMode)
        {
            case DEBUGSCREENSPACETRACING_POSITION_VS:
                hit.debugOutput = float3(startPositionNDC.xy, 0);
                break;
            case DEBUGSCREENSPACETRACING_HIT_DISTANCE:
                hit.debugOutput = hit.distance;
                break;
            case DEBUGSCREENSPACETRACING_HIT_DEPTH:
                hit.debugOutput = hit.linearDepth;
                break;
        }
    }
#endif

    return hitSuccessful;
}

#endif
