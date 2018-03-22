#ifndef UNITY_SCREEN_SPACE_RAYMARCHING_INCLUDED
#define UNITY_SCREEN_SPACE_RAYMARCHING_INCLUDED

// -------------------------------------------------
// Algorithm uniform parameters
// -------------------------------------------------

CBUFFER_START(ScreenSpaceRaymarching)
// HiZ      : Min mip level
// Linear   : Mip level
// Estimate : Mip Level
int _SSRayMinLevel;
// HiZ      : Max mip level
int _SSRayMaxLevel;
CBUFFER_END

// -------------------------------------------------
// Output
// -------------------------------------------------

struct ScreenSpaceRayHit
{
    float distanceSS;       // Distance raymarched (SS)
    float linearDepth;      // Linear depth of the hit point
    uint2 positionSS;       // Position of the hit point (SS)
    float2 positionNDC;     // Position of the hit point (NDC)

#ifdef DEBUG_DISPLAY
    float3 debugOutput;
#endif
};

// -------------------------------------------------
// Utilities
// -------------------------------------------------

// Calculate the ray origin and direction in SS
// out positionSS  : (x, y, 1/depth)
// out raySS       : (x, y, 1/depth)
void CalculateRaySS(
    float3 rayOriginVS,
    float3 rayDirVS,
    float4x4 projectionMatrix,
    uint2 bufferSize,
    out float3 positionSS,
    out float3 raySS)
{
    float3 positionVS = rayOriginVS;
    float3 rayEndVS = rayOriginVS + rayDirVS * 10;

    float4 positionCS = ComputeClipSpacePosition(positionVS, projectionMatrix);
    float4 rayEndCS = ComputeClipSpacePosition(rayEndVS, projectionMatrix);

    float2 positionNDC = ComputeNormalizedDeviceCoordinates(positionVS, projectionMatrix);
    float2 rayEndNDC = ComputeNormalizedDeviceCoordinates(rayEndVS, projectionMatrix);

    float3 rayStartSS = float3(
        positionNDC.xy * bufferSize,
        1.0 / positionCS.w); // Screen space depth interpolate properly in 1/z

    float3 rayEndSS = float3(
        rayEndNDC.xy * bufferSize,
        1.0 / rayEndCS.w); // Screen space depth interpolate properly in 1/z

    positionSS = rayStartSS;
    raySS = rayEndSS - rayStartSS;
}

// Check whether the depth of the ray is above the sampled depth
// Arguments are inversed linear depth
bool IsPositionAboveDepth(float rayDepth, float invLinearDepth)
{
    // as depth is inverted, we must invert the check as well
    // rayZ > HiZ <=> 1/rayZ < 1/HiZ
    return rayDepth > invLinearDepth;
}

// Sample the Depth buffer at a specific mip and linear depth
float LoadDepth(float2 positionSS, int level)
{
    float pyramidDepth = LOAD_TEXTURE2D_LOD(_PyramidDepthTexture, int2(positionSS.xy) >> level, level).r;
    float linearDepth = LinearEyeDepth(pyramidDepth, _ZBufferParams);
    return linearDepth;
}

// Sample the Depth buffer at a specific mip and return 1/linear depth
float LoadInvDepth(float2 positionSS, int level)
{
    float linearDepth = LoadDepth(positionSS, level);
    float invLinearDepth = 1 / linearDepth;
    return invLinearDepth;
}

bool CellAreEquals(int2 cellA, int2 cellB)
{
    return cellA.x == cellB.x && cellA.y == cellB.y;
}

// Calculate intersection between the ray and the depth plane
// positionSS.z is 1/depth
// raySS.z is 1/depth
float3 IntersectDepthPlane(float3 positionSS, float3 raySS, float invDepth)
{
    const float EPSILON = 1E-5;

    // The depth of the intersection with the depth plane is: positionSS.z + raySS.z * t = invDepth
    float t = (invDepth - positionSS.z) / raySS.z;

    // (t<0) When the ray is going away from the depth plane,
    //  put the intersection away.
    // Instead the intersection with the next tile will be used.
    // (t>=0) Add a small distance to go through the depth plane.
    t = t >= 0.0f ? (t + EPSILON) : 1E5;

    // Return the point on the ray
    return positionSS + raySS * t;
}

// Calculate intersection between a ray and a cell
float3 IntersectCellPlanes(
    float3 positionSS,
    float3 raySS,
    float2 invRaySS,
    int2 cellId,
    uint2 cellSize,
    int2 cellPlanes,
    float2 crossOffset)
{
    const float SQRT_2 = sqrt(2);

    // Planes to check
    int2 planes = (cellId + cellPlanes) * cellSize;
    // Hit distance to each planes
    float2 distanceToCellAxes = float2(planes - positionSS.xy) * invRaySS; // (distance to x axis, distance to y axis)
    float t = min(distanceToCellAxes.x, distanceToCellAxes.y)
        // Offset by 1E-3 to ensure cell boundary crossing
        // This assume that length(raySS.xy) == 1;
        + 1E-2;
    // Interpolate screen space to get next test point
    float3 testHitPositionSS = positionSS + raySS * t;

    return testHitPositionSS;
}

#ifdef DEBUG_DISPLAY
// -------------------------------------------------
// Debug Utilities
// -------------------------------------------------

void FillScreenSpaceRaymarchingHitDebug(
    uint2 bufferSize,
    float3 rayDirVS,
    float3 raySS,
    float3 startPositionSS,
    bool hitSuccessful,
    int iteration,
    int maxIterations,
    int maxUsedLevel,
    int maxMipLevel,
    inout ScreenSpaceRayHit hit)
{
    float3 debugOutput = float3(0, 0, 0);
    if (_DebugLightingMode == DEBUGLIGHTINGMODE_SCREEN_SPACE_TRACING_REFRACTION)
    {
        switch (_DebugLightingSubMode)
        {
        case DEBUGSCREENSPACETRACING_POSITION_NDC:
            debugOutput =  float3(float2(startPositionSS.xy) / bufferSize, 0);
            break;
        case DEBUGSCREENSPACETRACING_DIR_VS:
            debugOutput =  rayDirVS * 0.5 + 0.5;
            break;
        case DEBUGSCREENSPACETRACING_DIR_NDC:
            debugOutput =  float3(raySS.xy * 0.5 + 0.5, frac(0.1 / raySS.z));
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
            debugOutput =  float(maxUsedLevel) / float(maxMipLevel);
            break;
        }
    }
    hit.debugOutput = debugOutput;
}

void FillScreenSpaceRaymarchingPreLoopDebug(
    float3 startPositionSS,
    inout ScreenSpaceTracingDebug debug)
{
    debug.startPositionSSX = uint(startPositionSS.x);
    debug.startPositionSSY = uint(startPositionSS.y);
    debug.startLinearDepth = 1 / startPositionSS.z;
}

void FillScreenSpaceRaymarchingPostLoopDebug(
    int maxUsedLevel,
    int iteration,
    float3 raySS,
    bool hitSuccess,
    ScreenSpaceRayHit hit,
    inout ScreenSpaceTracingDebug debug)
{
    debug.levelMax = maxUsedLevel;
    debug.iterationMax = iteration;
    debug.raySS = raySS;
    debug.resultHitDepth = hit.linearDepth;
    debug.endPositionSSX = hit.positionSS.x;
    debug.endPositionSSY = hit.positionSS.y;
    debug.hitSuccess = hitSuccess;
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
    float3 positionSS,
    float invHiZDepth,
    inout ScreenSpaceTracingDebug debug)
{
    if (_DebugStep == iteration)
    {
        debug.cellSizeW = cellSize.x;
        debug.cellSizeH = cellSize.y;
        debug.positionSS = positionSS;
        debug.hitLinearDepth = 1 / positionSS.z;
        debug.iteration = iteration;
        debug.hiZLinearDepth = 1 / invHiZDepth;
    }
}
#endif

// -------------------------------------------------
// Algorithm: rough estimate
// -------------------------------------------------

struct ScreenSpaceEstimateRaycastInput
{
    float2 referencePositionNDC;            // Position of the reference (NDC)
    float3 referencePositionWS;             // Position of the reference (WS)
    float referenceLinearDepth;             // Linear depth of the reference
    float3 rayOriginWS;                     // Origin of the ray (WS)
    float3 rayDirWS;                        // Direction of the ray (WS)
    float3 depthNormalWS;                   // Depth plane normal (WS)
    float4x4 viewProjectionMatrix;          // View Projection matrix of the camera

#ifdef DEBUG_DISPLAY
    bool writeStepDebug;
#endif
};

// Fast but very rough estimation of scene screen space raycasting.
// * We approximate the scene as a depth plane and raycast against that plane.
// * The reference position is usually the pixel being evaluated in front of opaque geometry
// * So the reference position is used to sample and get the depth plane
// * The reference depth is usually, the depth of the transparent object being evaluated
bool ScreenSpaceEstimateRaycast(
    ScreenSpaceEstimateRaycastInput input,
    out ScreenSpaceRayHit hit)
{
    uint mipLevel = clamp(_SSRayMinLevel, 0, int(_PyramidDepthMipSize.z));
    uint2 bufferSize = uint2(_PyramidDepthMipSize.xy);
    uint2 referencePositionSS = input.referencePositionNDC * bufferSize;

    // Get the depth plane
    float depth = LoadDepth(referencePositionSS >> mipLevel, mipLevel);

    // Calculate projected distance from the ray origin to the depth plane
    float depthFromReference = depth - input.referenceLinearDepth;
    float offset = dot(input.depthNormalWS, input.rayOriginWS - input.referencePositionWS);
    float depthFromRayOrigin = depthFromReference - offset;

    // Calculate actual distance from ray origin to depth plane
    float hitDistance = depthFromRayOrigin / dot(input.depthNormalWS, input.rayDirWS);
    float3 hitPositionWS = input.rayOriginWS + input.rayDirWS * hitDistance;

    hit.positionNDC = ComputeNormalizedDeviceCoordinates(hitPositionWS, input.viewProjectionMatrix);
    hit.positionSS = hit.positionNDC * bufferSize;
    hit.linearDepth = LoadDepth(hit.positionSS, 0);
    hit.distanceSS = length(hit.positionSS - referencePositionSS);


#ifdef DEBUG_DISPLAY
    FillScreenSpaceRaymarchingHitDebug(
        bufferSize, 
        float3(0, 0, 0),    // rayDirVS
        float3(0, 0, 0),    // raySS
        float3(0, 0, 0),    // startPositionSS
        true,               // hitSuccessful
        1,                  // iteration
        1,                  // iterationMax
        0,                  // maxMipLevel
        0,                  // maxUsedLevel
        hit);
    if (input.writeStepDebug)
    {
        ScreenSpaceTracingDebug debug;
        ZERO_INITIALIZE(ScreenSpaceTracingDebug, debug);
        FillScreenSpaceRaymarchingPreLoopDebug(float3(0, 0, 0), debug);
        FillScreenSpaceRaymarchingPreIterationDebug(1, mipLevel, debug);
        FillScreenSpaceRaymarchingPostIterationDebug(
            1,                              // iteration
            uint2(1, 1),                    // cellSize
            float3(0, 0, 0),                // positionSS
            1 / hit.linearDepth,            // 1 / sampled depth
            debug);
        FillScreenSpaceRaymarchingPostLoopDebug(
            1,                              // maxUsedLevel
            1,                              // iteration
            float3(0, 0, 0),                // raySS
            true,                           // hitSuccess
            hit,
            debug);
        _DebugScreenSpaceTracingData[0] = debug;
    }
#endif


    return true;
}

// -------------------------------------------------
// Algorithm: HiZ raymarching
// -------------------------------------------------

// Based on Yasin Uludag, 2014. "Hi-Z Screen-Space Cone-Traced Reflections", GPU Pro5: Advanced Rendering Techniques

struct ScreenSpaceHiZRaymarchInput
{
    float3 rayOriginVS;         // Ray origin (VS)
    float3 rayDirVS;            // Ray direction (VS)
    float4x4 projectionMatrix;  // Projection matrix of the camera

#ifdef DEBUG_DISPLAY
    bool writeStepDebug;
#endif
};

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
    int minMipLevel = max(_SSRayMinLevel, 0);
    int maxMipLevel = min(_SSRayMaxLevel, int(_PyramidDepthMipSize.z));
    uint2 bufferSize = uint2(_PyramidDepthMipSize.xy);

    float3 startPositionSS;
    float3 raySS;
    CalculateRaySS(
        input.rayOriginVS,
        input.rayDirVS,
        input.projectionMatrix,
        bufferSize,
        startPositionSS,
        raySS);

#ifdef DEBUG_DISPLAY
    int maxUsedLevel = minMipLevel;
    ScreenSpaceTracingDebug debug;
    ZERO_INITIALIZE(ScreenSpaceTracingDebug, debug);
    FillScreenSpaceRaymarchingPreLoopDebug(startPositionSS, debug);
#endif

    {
        float raySSLength = length(raySS.xy);
        raySS /= raySSLength;
        // Initialize raymarching
        float2 invRaySS = float2(1, 1) / raySS.xy;

        // Calculate planes to intersect for each cell
        int2 cellPlanes = sign(raySS.xy);
        float2 crossOffset = CROSS_OFFSET * cellPlanes;
        cellPlanes = clamp(cellPlanes, 0, 1);

        int currentLevel = minMipLevel;
        uint2 cellCount = bufferSize >> currentLevel;
        uint2 cellSize = uint2(1, 1) << currentLevel;

        float3 positionSS = startPositionSS;

        while (currentLevel >= minMipLevel)
        {
            if (iteration >= MAX_ITERATIONS)
            {
                hitSuccessful = false;
                break;
            }

            cellCount = bufferSize >> currentLevel;
            cellSize = uint2(1, 1) << currentLevel;

#ifdef DEBUG_DISPLAY
            FillScreenSpaceRaymarchingPreIterationDebug(iteration, currentLevel, debug);
#endif

            // Go down in HiZ levels by default
            int mipLevelDelta = -1;

            // Sampled as 1/Z so it interpolate properly in screen space.
            const float invHiZDepth = LoadInvDepth(positionSS.xy, currentLevel);

            if (IsPositionAboveDepth(positionSS.z, invHiZDepth))
            {
                float3 candidatePositionSS = IntersectDepthPlane(positionSS, raySS, invHiZDepth);

                const int2 cellId = int2(positionSS.xy) / cellSize;
                const int2 candidateCellId = int2(candidatePositionSS.xy) / cellSize;

                // If we crossed the current cell
                if (!CellAreEquals(cellId, candidateCellId))
                {
                    candidatePositionSS = IntersectCellPlanes(
                        positionSS,
                        raySS,
                        invRaySS,
                        cellId,
                        cellSize,
                        cellPlanes,
                        crossOffset);

                    // Go up a level to go faster
                    mipLevelDelta = 1;
                }

                positionSS = candidatePositionSS;
            }

            currentLevel = min(currentLevel + mipLevelDelta, maxMipLevel);
            
#ifdef DEBUG_DISPLAY
            maxUsedLevel = max(maxUsedLevel, currentLevel);
            FillScreenSpaceRaymarchingPostIterationDebug(
                iteration,
                cellSize,
                positionSS,
                invHiZDepth,
                debug);
#endif

            // Check if we are out of the buffer
            if (any(int2(positionSS.xy) > int2(bufferSize))
                || any(positionSS.xy < 0))
            {
                hitSuccessful = false;
                break;
            }

            ++iteration;
        }

        hit.linearDepth = 1 / positionSS.z;
        hit.positionNDC = float2(positionSS.xy) / float2(bufferSize);
        hit.positionSS = uint2(positionSS.xy);
    }
    
#ifdef DEBUG_DISPLAY
    FillScreenSpaceRaymarchingPostLoopDebug(
        maxUsedLevel,
        iteration,
        raySS,
        hitSuccessful,
        hit,
        debug);
    FillScreenSpaceRaymarchingHitDebug(
        bufferSize, input.rayDirVS, raySS, startPositionSS, hitSuccessful, iteration, MAX_ITERATIONS, maxMipLevel, maxUsedLevel,
        hit);
    if (input.writeStepDebug)
        _DebugScreenSpaceTracingData[0] = debug;
#endif

    return hitSuccessful;
}

// -------------------------------------------------
// Algorithm: Linear raymarching
// -------------------------------------------------
// Based on DDA (https://en.wikipedia.org/wiki/Digital_differential_analyzer_(graphics_algorithm))
// Based on Morgan McGuire and Michael Mara, 2014. "Efficient GPU Screen-Space Ray Tracing", Journal of Computer Graphics Techniques (JCGT), 235-256

struct ScreenSpaceLinearRaymarchInput
{
    float3 rayOriginVS;         // Ray origin (VS)
    float3 rayDirVS;            // Ray direction (VS)
    float4x4 projectionMatrix;  // Projection matrix of the camera

#ifdef DEBUG_DISPLAY
    bool writeStepDebug;
#endif
};

// Basically, perform a raycast with DDA technique on a specific mip level of the Depth pyramid.
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
    int level = clamp(_SSRayMinLevel, 0, int(_PyramidDepthMipSize.z));
    uint2 bufferSize = uint2(_PyramidDepthMipSize.xy);

    float3 startPositionSS;
    float3 raySS;
    CalculateRaySS(
        input.rayOriginVS,
        input.rayDirVS,
        input.projectionMatrix,
        bufferSize,
        startPositionSS,
        raySS);

#ifdef DEBUG_DISPLAY
    ScreenSpaceTracingDebug debug;
    ZERO_INITIALIZE(ScreenSpaceTracingDebug, debug);
    FillScreenSpaceRaymarchingPreLoopDebug(startPositionSS, debug);
#endif

    float maxAbsAxis = max(abs(raySS.x), abs(raySS.y));
    // No need to raymarch if the ray is along camera's foward
    if (maxAbsAxis < 1E-7)
    {
        hit.distanceSS = 1 / startPositionSS.z;
        hit.linearDepth = 1 / startPositionSS.z;
        hit.positionSS = uint2(startPositionSS.xy);
    }
    else
    {
        // DDA step
        raySS /= max(abs(raySS.x), abs(raySS.y));
        raySS *= _SSRayMinLevel;

        float distanceStepSS = length(raySS.xy);

        float3 positionSS = startPositionSS;
        // TODO: We should have a for loop from the starting point to the far/near plane
        while (iteration < MAX_ITERATIONS)
        {
#ifdef DEBUG_DISPLAY
            FillScreenSpaceRaymarchingPreIterationDebug(iteration, 0, debug);
#endif

            positionSS += raySS;
            hit.distanceSS += distanceStepSS;
            float invHiZDepth = LoadInvDepth(positionSS.xy, _SSRayMinLevel);

#ifdef DEBUG_DISPLAY
            FillScreenSpaceRaymarchingPostIterationDebug(
                iteration,
                uint2(0, 0),
                positionSS,
                invHiZDepth,
                debug);
#endif

            if (!IsPositionAboveDepth(positionSS.z, invHiZDepth))
            {
                hitSuccessful = true;
                break;
            }

            // Check if we are out of the buffer
            if (any(int2(positionSS.xy) > int2(bufferSize))
                || any(positionSS.xy < 0))
            {
                hitSuccessful = false;
                break;
            }

            ++iteration;
        }

        hit.linearDepth = 1 / positionSS.z;
        hit.positionNDC = float2(positionSS.xy) / float2(bufferSize);
        hit.positionSS = uint2(positionSS.xy);
    }

#ifdef DEBUG_DISPLAY
    FillScreenSpaceRaymarchingPostLoopDebug(
        0,
        iteration,
        raySS,
        hitSuccessful,
        hit,
        debug);
    FillScreenSpaceRaymarchingHitDebug(
        bufferSize, input.rayDirVS, raySS, startPositionSS, hitSuccessful, iteration, MAX_ITERATIONS, 0, 0,
        hit);
    if (input.writeStepDebug)
        _DebugScreenSpaceTracingData[0] = debug;
#endif

    return hitSuccessful;
}

#endif
