#ifndef UNITY_SCREEN_SPACE_RAYMARCHING_INCLUDED
#define UNITY_SCREEN_SPACE_RAYMARCHING_INCLUDED

CBUFFER_START(ScreenSpaceRaymarching)
int _SSRayMinLevel;
int _SSRayMaxLevel;
CBUFFER_END

struct ScreenSpaceHiZRaymarchInput
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

struct ScreenSpaceLinearRaymarchInput
{
    float3 startPositionVS;
    float startLinearDepth;
    float3 dirVS;
    float4x4 projectionMatrix;
    int2 bufferSize;

#ifdef DEBUG_DISPLAY
    bool writeStepDebug;
#endif
};

struct ScreenSpaceRayHit
{
    float distance;
    float linearDepth;
    uint2 positionSS;
    float2 positionNDC;

#ifdef DEBUG_DISPLAY
    float3 debugOutput;
#endif
};

void CalculateRayTXS(
    float3 startPositionVS,
    float3 dirVS,
    float4x4 projectionMatrix,
    uint2 bufferSize,
    out float3 positionTXS,
    out float3 rayTXS)
{
    float3 positionVS = startPositionVS;
    float3 rayEndVS = startPositionVS + dirVS * 10;

    float4 positionCS = ComputeClipSpacePosition(positionVS, projectionMatrix);
    float4 rayEndCS = ComputeClipSpacePosition(rayEndVS, projectionMatrix);

    float2 positionNDC = ComputeNormalizedDeviceCoordinates(positionVS, projectionMatrix);
    float2 rayEndNDC = ComputeNormalizedDeviceCoordinates(rayEndVS, projectionMatrix);

    float3 rayStartTXS = float3(
        positionNDC.xy * bufferSize,
        1.0 / positionCS.w); // Screen space depth interpolate properly in 1/z

    float3 rayEndTXS = float3(
        rayEndNDC.xy * bufferSize,
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

float SampleHiZDepth(float2 positionTXS, int level)
{
    float pyramidDepth = LOAD_TEXTURE2D_LOD(_PyramidDepthTexture, int2(positionTXS.xy) >> level, level).r;
    float hiZLinearDepth = LinearEyeDepth(pyramidDepth, _ZBufferParams);
    float invHiZLinearDepth = 1 / hiZLinearDepth;
    return invHiZLinearDepth;
}

// positionTXS.z is 1/depth
// rayTXS.z is 1/depth
float3 IntersectDepthPlane(float3 positionTXS, float3 rayTXS, float invDepth, out float distance)
{
    const float EPSILON = 1E-5;

    // The depth of the intersection with the depth plane is: positionTXS.z + rayTXS.z * t = invDepth
    distance = (invDepth - positionTXS.z) / rayTXS.z;

    // (t<0) When the ray is going away from the depth plane,
    //  put the intersection away.
    // Instead the intersection with the next tile will be used.
    // (t>=0) Add a small distance to go through the depth plane.
    distance = distance >= 0.0f ? (distance + EPSILON) : 1E5;

    // Return the point on the ray
    return positionTXS + rayTXS * distance;
}

bool CellAreEquals(int2 cellA, int2 cellB)
{
    return cellA.x == cellB.x && cellA.y == cellB.y;
}

float3 IntersectCellPlanes(
    float3 positionTXS,
    float3 rayTXS,
    float2 invRayTXS,
    int2 cellId,
    uint2 cellSize,
    int2 cellPlanes,
    float2 crossOffset,
    out float distance)
{
    // Planes to check
    int2 planes = (cellId + cellPlanes) * cellSize;
    // Hit distance to each planes
    float2 distanceToCellAxes = float2(planes - positionTXS.xy) * invRayTXS; // (distance to x axis, distance to y axis)
    distance = min(distanceToCellAxes.x, distanceToCellAxes.y);
    // Interpolate screen space to get next test point
    float3 testHitPositionTXS = positionTXS + rayTXS * distance;

    // Offset the proper axis to enforce cell crossing
    // https://gamedev.autodesk.com/blogs/1/post/5866685274515295601
    testHitPositionTXS.xy += (distanceToCellAxes.x < distanceToCellAxes.y)
        ? float2(crossOffset.x, 0)
        : float2(0, crossOffset.y);

    return testHitPositionTXS;
}

#ifdef DEBUG_DISPLAY
void FillScreenSpaceRaymarchingHitDebug(
    uint2 bufferSize,
    float3 dirVS,
    float3 rayTXS,
    float3 startPositionTXS,
    bool hitSuccessful,
    int iteration,
    int maxIterations,
    int maxUsedLevel,
    int maxLevel,
    inout ScreenSpaceRayHit hit)
{
    float3 debugOutput = float3(0, 0, 0);
    if (_DebugLightingMode == DEBUGLIGHTINGMODE_SCREEN_SPACE_TRACING_REFRACTION)
    {
        switch (_DebugLightingSubMode)
        {
        case DEBUGSCREENSPACETRACING_POSITION_NDC:
            debugOutput =  float3(float2(startPositionTXS.xy) / bufferSize, 0);
            break;
        case DEBUGSCREENSPACETRACING_DIR_VS:
            debugOutput =  dirVS * 0.5 + 0.5;
            break;
        case DEBUGSCREENSPACETRACING_DIR_NDC:
            debugOutput =  float3(rayTXS.xy * 0.5 + 0.5, frac(0.1 / rayTXS.z));
            break;
        case DEBUGSCREENSPACETRACING_HIT_DISTANCE:
            debugOutput =  frac(hit.distance * 0.1);
            break;
        case DEBUGSCREENSPACETRACING_HIT_DEPTH:
            debugOutput =  frac(hit.linearDepth * 0.1);
            break;
        case DEBUGSCREENSPACETRACING_HIT_SUCCESS:
            debugOutput =  hitSuccessful;
            break;
        case DEBUGSCREENSPACETRACING_ITERATION_COUNT:
            debugOutput =  float(iteration) / float(maxIterations);
            break;
        case DEBUGSCREENSPACETRACING_MAX_USED_LEVEL:
            debugOutput =  float(maxUsedLevel) / float(maxLevel);
            break;
        }
    }
    hit.debugOutput = debugOutput;
}

void FillScreenSpaceRaymarchingPreLoopDebug(
    float3 startPositionTXS,
    inout ScreenSpaceTracingDebug debug)
{
    debug.startPositionSSX = uint(startPositionTXS.x);
    debug.startPositionSSY = uint(startPositionTXS.y);
    debug.startLinearDepth = 1 / startPositionTXS.z;
}

void FillScreenSpaceRaymarchingPostLoopDebug(
    int maxUsedLevel,
    int iteration,
    float3 rayTXS,
    ScreenSpaceRayHit hit,
    inout ScreenSpaceTracingDebug debug)
{
    debug.levelMax = maxUsedLevel;
    debug.iterationMax = iteration;
    debug.hitDistance = hit.distance;
    debug.rayTXS = rayTXS;
}

void FillScreenSpaceRaymarchingPreIterationDebug(
    int iteration,
    int currentLevel,
    inout ScreenSpaceTracingDebug debug)
{
    if (_DebugStep == iteration)
        debug.level = currentLevel;
}

void FillScreenSpaceRaymarchingPostIterationDebug(
    int iteration,
    uint2 cellSize,
    float3 positionTXS,
    float iterationDistance,
    float invHiZDepth,
    inout ScreenSpaceTracingDebug debug)
{
    if (_DebugStep == iteration)
    {
        debug.cellSizeW = cellSize.x;
        debug.cellSizeH = cellSize.y;
        debug.positionTXS = positionTXS;
        debug.hitLinearDepth = 1 / positionTXS.z;
        debug.hitPositionSS = uint2(positionTXS.xy);
        debug.iteration = iteration;
        debug.iterationDistance = iterationDistance;
        debug.hiZLinearDepth = 1 / invHiZDepth;
    }
}
#endif

bool ScreenSpaceHiZRaymarch(
    ScreenSpaceHiZRaymarchInput input,
    out ScreenSpaceRayHit hit)
{
    const float2 CROSS_OFFSET = float2(1, 1);
    const int MAX_ITERATIONS = 32;

    // Initialize loop
    ZERO_INITIALIZE(ScreenSpaceRayHit, hit);
    bool hitSuccessful = true;
    int iteration = 0;
    int minLevel = max(input.minLevel, _SSRayMinLevel);
    int maxLevel = min(input.maxLevel, _SSRayMaxLevel);

    float3 startPositionTXS;
    float3 rayTXS;
    CalculateRayTXS(
        input.startPositionVS,
        input.dirVS,
        input.projectionMatrix,
        input.bufferSize,
        startPositionTXS,
        rayTXS);

#ifdef DEBUG_DISPLAY
    int maxUsedLevel = input.minLevel;
    ScreenSpaceTracingDebug debug;
    ZERO_INITIALIZE(ScreenSpaceTracingDebug, debug);
    FillScreenSpaceRaymarchingPreLoopDebug(startPositionTXS, debug);
#endif

    {
        // Initialize raymarching
        float2 invRayTXS = float2(1, 1) / rayTXS.xy;

        // Calculate planes to intersect for each cell
        int2 cellPlanes = sign(rayTXS.xy);
        float2 crossOffset = CROSS_OFFSET * cellPlanes;
        cellPlanes = clamp(cellPlanes, 0, 1);

        int currentLevel = minLevel;
        uint2 cellCount = input.bufferSize >> currentLevel;
        uint2 cellSize = uint2(1, 1) << currentLevel;

        float3 positionTXS = startPositionTXS;

        while (currentLevel >= minLevel)
        {
            if (iteration >= MAX_ITERATIONS)
            {
                hitSuccessful = false;
                break;
            }

            cellCount = input.bufferSize >> currentLevel;
            cellSize = uint2(1, 1) << currentLevel;

#ifdef DEBUG_DISPLAY
            FillScreenSpaceRaymarchingPreIterationDebug(iteration, currentLevel, debug);
#endif

            // Go down in HiZ levels by default
            int mipLevelDelta = -1;

            // Sampled as 1/Z so it interpolate properly in screen space.
            const float invHiZDepth = SampleHiZDepth(positionTXS.xy, currentLevel);
            float iterationDistance = 0;

            if (IsPositionAboveDepth(positionTXS.z, invHiZDepth))
            {
                float3 candidatePositionTXS = IntersectDepthPlane(positionTXS, rayTXS, invHiZDepth, iterationDistance);

                const int2 cellId = int2(positionTXS.xy) / cellSize;
                const int2 candidateCellId = int2(candidatePositionTXS.xy) / cellSize;

                // If we crossed the current cell
                if (!CellAreEquals(cellId, candidateCellId))
                {
                    candidatePositionTXS = IntersectCellPlanes(
                        positionTXS,
                        rayTXS,
                        invRayTXS,
                        cellId,
                        cellSize,
                        cellPlanes,
                        crossOffset,
                        iterationDistance);

                    // Go up a level to go faster
                    mipLevelDelta = 1;
                }

                positionTXS = candidatePositionTXS;
            }

            hit.distance += iterationDistance;

            currentLevel = min(currentLevel + mipLevelDelta, maxLevel);
            
#ifdef DEBUG_DISPLAY
            maxUsedLevel = max(maxUsedLevel, currentLevel);
            FillScreenSpaceRaymarchingPostIterationDebug(
                iteration,
                cellSize,
                positionTXS,
                iterationDistance,
                invHiZDepth,
                debug);
#endif

            // Check if we are out of the buffer
            if (any(positionTXS.xy > input.bufferSize)
                || any(positionTXS.xy < 0))
            {
                hitSuccessful = false;
                break;
            }

            ++iteration;
        }

        hit.linearDepth = 1 / positionTXS.z;
        hit.positionNDC = float2(positionTXS.xy) / float2(input.bufferSize);
        hit.positionSS = uint2(positionTXS.xy);
    }
    
#ifdef DEBUG_DISPLAY
    FillScreenSpaceRaymarchingPostLoopDebug(
        maxUsedLevel,
        iteration,
        rayTXS,
        hit,
        debug);
    FillScreenSpaceRaymarchingHitDebug(
        input.bufferSize, input.dirVS, rayTXS, startPositionTXS, hitSuccessful, iteration, MAX_ITERATIONS, maxLevel, maxUsedLevel,
        hit);
    if (input.writeStepDebug)
        _DebugScreenSpaceTracingData[0] = debug;
#endif

    return hitSuccessful;
}

// Based on DDA
bool ScreenSpaceLinearRaymarch(
    ScreenSpaceLinearRaymarchInput input,
    out ScreenSpaceRayHit hit)
{
    const float2 CROSS_OFFSET = float2(1, 1);
    const int MAX_ITERATIONS = 1024;

    // Initialize loop
    ZERO_INITIALIZE(ScreenSpaceRayHit, hit);
    bool hitSuccessful = true;
    int iteration = 0;
    int level = _SSRayMinLevel;

    float3 startPositionTXS;
    float3 rayTXS;
    CalculateRayTXS(
        input.startPositionVS,
        input.dirVS,
        input.projectionMatrix,
        input.bufferSize,
        startPositionTXS,
        rayTXS);

#ifdef DEBUG_DISPLAY
    ScreenSpaceTracingDebug debug;
    ZERO_INITIALIZE(ScreenSpaceTracingDebug, debug);
    FillScreenSpaceRaymarchingPreLoopDebug(startPositionTXS, debug);
#endif

    // No need to raymarch if the ray is along camera's foward
    if (!any(rayTXS.xy))
    {
        hit.distance = 1 / startPositionTXS.z;
        hit.linearDepth = 1 / startPositionTXS.z;
        hit.positionSS = uint2(startPositionTXS.xy);
    }
    else
    {
        // DDA step
        rayTXS /= max(abs(rayTXS.x), abs(rayTXS.y));
        rayTXS *= _SSRayMinLevel;

        float3 positionTXS = startPositionTXS;
        // TODO: We should have a for loop from the starting point to the far/near plane
        while (iteration < MAX_ITERATIONS)
        {
#ifdef DEBUG_DISPLAY
            FillScreenSpaceRaymarchingPreIterationDebug(iteration, 0, debug);
#endif

            positionTXS += rayTXS;
            float invHiZDepth = SampleHiZDepth(positionTXS.xy, _SSRayMinLevel);

#ifdef DEBUG_DISPLAY
            FillScreenSpaceRaymarchingPostIterationDebug(
                iteration,
                uint2(0, 0),
                positionTXS,
                1 / rayTXS.z,
                invHiZDepth,
                debug);
#endif

            if (!IsPositionAboveDepth(positionTXS.z, invHiZDepth))
            {
                hitSuccessful = true;
                break;
            }

            // Check if we are out of the buffer
            if (any(positionTXS.xy > input.bufferSize)
                || any(positionTXS.xy < 0))
            {
                hitSuccessful = false;
                break;
            }

            ++iteration;
        }

        hit.linearDepth = 1 / positionTXS.z;
        hit.positionNDC = float2(positionTXS.xy) / float2(input.bufferSize);
        hit.positionSS = uint2(positionTXS.xy);
    }

#ifdef DEBUG_DISPLAY
    FillScreenSpaceRaymarchingPostLoopDebug(
        0,
        iteration,
        rayTXS,
        hit,
        debug);
    FillScreenSpaceRaymarchingHitDebug(
        input.bufferSize, input.dirVS, rayTXS, startPositionTXS, hitSuccessful, iteration, MAX_ITERATIONS, 0, 0,
        hit);
    if (input.writeStepDebug)
        _DebugScreenSpaceTracingData[0] = debug;
#endif

    return hitSuccessful;
}

#endif
