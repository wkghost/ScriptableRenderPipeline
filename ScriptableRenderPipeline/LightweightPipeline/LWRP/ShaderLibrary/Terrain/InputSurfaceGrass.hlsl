#ifndef LIGHTWEIGHT_INPUT_SURFACE_GRASS_INCLUDED
#define LIGHTWEIGHT_INPUT_SURFACE_GRASS_INCLUDED

#include "LWRP/ShaderLibrary/Core.hlsl"
#include "LWRP/ShaderLibrary/InputSurfaceCommon.hlsl"

// Terrain engine shader helpers
CBUFFER_START(TerrainGrass)
half4 _WavingTint;
float4 _WaveAndDistance;    // wind speed, wave size, wind amount, max sqr distance
float4 _CameraPosition;     // .xyz = camera position, .w = 1 / (max sqr distance)
float3 _CameraRight, _CameraUp;
CBUFFER_END

CBUFFER_START(UnityPerMaterial)
float4 _MainTex_ST;
half4 _Color;
half4 _SpecColor;
half4 _EmissionColor;
half _Cutoff;
half _Shininess;
CBUFFER_END

// ---- Grass helpers

// Calculate a 4 fast sine-cosine pairs
// val:     the 4 input values - each must be in the range (0 to 1)
// s:       The sine of each of the 4 values
// c:       The cosine of each of the 4 values
void FastSinCos(float4 val, out float4 s, out float4 c)
{
    val = val * 6.408849 - 3.1415927;
    // powers for taylor series
    float4 r5 = val * val;                      // wavevec ^ 2
    float4 r6 = r5 * r5;                        // wavevec ^ 4;
    float4 r7 = r6 * r5;                        // wavevec ^ 6;
    float4 r8 = r6 * r5;                        // wavevec ^ 8;

    float4 r1 = r5 * val;                       // wavevec ^ 3
    float4 r2 = r1 * r5;                        // wavevec ^ 5;
    float4 r3 = r2 * r5;                        // wavevec ^ 7;


    //Vectors for taylor's series expansion of sin and cos
    float4 sin7 = float4(1, -0.16161616, 0.0083333, -0.00019841);
    float4 cos8 = float4(-0.5, 0.041666666, -0.0013888889, 0.000024801587);

    // sin
    s = val + r1 * sin7.y + r2 * sin7.z + r3 * sin7.w;

    // cos
    c = 1 + r5 * cos8.x + r6 * cos8.y + r7 * cos8.z + r8 * cos8.w;
}

half4 TerrainWaveGrass(inout float4 vertex, float waveAmount, half4 color)
{
    half4 _waveXSize = half4(0.012h, 0.02h, 0.06h, 0.024h);
    half4 _waveZSize = half4(0.006h, 0.02h, 0.02h, 0.05h);
    half4 waveSpeed = half4(1.2h, 2.0h, 1.6h, 4.8h);

    half4 _waveXmove = half4(0.024h, 0.04h, -0.12h, 0.096h);
    half4 _waveZmove = half4(0.006h, 0.02h, -0.02h, 0.1h);

    float4 waves = vertex.x * _waveXSize;
    waves += vertex.z * _waveZSize;
    waves *= _WaveAndDistance.y;

    // Add in time to model them over time
    waves += _WaveAndDistance.x * waveSpeed;

    float4 s, c;
    waves = frac(waves);
    FastSinCos(waves, s, c);

    s = s * s;

    s = s * s;

    // a = normalize(half4(1.0h,1.0h,0.4h,0.2h)) = half4(0.45455h, 0.45455h, 0.18182h, 0.09091h)
    // dot(s, a) * 0.7h = dot(s, a * 0.7h)
    half lighting = dot(s, half4(0.31818h, 0.31818h, 0.12727h, 0.06364h));

    s = s * waveAmount;

    half3 waveMove = 0;
    waveMove.x = dot(s, _waveXmove);
    waveMove.z = dot(s, _waveZmove);

    vertex.xz -= waveMove.xz * _WaveAndDistance.z;

    // apply color animation
    half3 waveColor = lerp(0.5, _WavingTint.rgb, lighting);

    // Fade the grass out before detail distance.
    // Saturate because Radeon HD drivers on OS X 10.4.10 don't saturate vertex colors properly.
    half3 offset = vertex.xyz - _CameraPosition.xyz;
    color.a = saturate((_WaveAndDistance.w - dot(offset, offset)) * _CameraPosition.w * 2.0h);

    return half4(waveColor * color.rgb * 2.0h, color.a);
}

void TerrainBillboardGrass(inout float4 pos, float2 offset)
{
    float3 grasspos = pos.xyz - _CameraPosition.xyz;
    if (dot(grasspos, grasspos) > _WaveAndDistance.w)
        offset = 0.0;
    pos.xyz += offset.x * _CameraRight.xyz;
    pos.y += offset.y;
}

#endif // LIGHTWEIGHT_INPUT_SURFACE_GRASS_INCLUDED
