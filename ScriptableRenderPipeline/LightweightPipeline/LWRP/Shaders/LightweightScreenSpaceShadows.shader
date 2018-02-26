Shader "Hidden/LightweightPipeline/ScreenSpaceShadows"
{
    SubShader
    {
        Tags{ "RenderPipeline" = "LightweightPipeline" }

        HLSLINCLUDE

        //#pragma enable_d3d11_debug_symbols

        //Keep compiler quiet about Shadows.hlsl. 
        #include "CoreRP/ShaderLibrary/Common.hlsl"
        #include "CoreRP/ShaderLibrary/EntityLighting.hlsl"
        #include "CoreRP/ShaderLibrary/ImageBasedLighting.hlsl"
        #include "LWRP/ShaderLibrary/Core.hlsl"
        #include "LWRP/ShaderLibrary/Shadows.hlsl"

#if defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED)
        TEXTURE2D_ARRAY(_CameraDepthTexture);
        SAMPLER(sampler_CameraDepthTexture);
#else
        TEXTURE2D(_CameraDepthTexture);
        SAMPLER(sampler_CameraDepthTexture);
#endif
        //struct FragInfo
        //{
        //    uint eyeIndex;
        //    half4 pos;
        //    half4 texcoord;
        //};
        //AppendStructuredBuffer<FragInfo> FragInfoAppendBuffer;

        struct VertexInput
        {
            float4 vertex   : POSITION;
            float2 texcoord : TEXCOORD0;
            UNITY_VERTEX_INPUT_INSTANCE_ID
        };

        struct Interpolators
        {
            half4  pos      : SV_POSITION;
            half4  texcoord : TEXCOORD0;
            UNITY_VERTEX_OUTPUT_STEREO
            //UNITY_VERTEX_INPUT_INSTANCE_ID
#if defined(UNITY_STEREO_INSTANCING_ENABLED)
            //uint testSlice : SV_RenderTargetArrayIndex;
#endif
        };

        Interpolators Vertex(VertexInput i)
        {
            Interpolators o;
            UNITY_SETUP_INSTANCE_ID(i);
            //UNITY_TRANSFER_INSTANCE_ID(i, o);
            UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

#if defined(UNITY_STEREO_INSTANCING_ENABLED)
            //o.stereoEyeIndex = 1;
#endif
            o.pos = TransformObjectToHClip(i.vertex.xyz);

            float4 projPos = o.pos * 0.5;
            projPos.xy = projPos.xy + projPos.w;

            //o.texcoord.xy = i.texcoord;
            // Doesn't seem like saturate messes anything up here...
            o.texcoord.xy = UnityStereoTransformScreenSpaceTex(i.texcoord.xy);
            o.texcoord.zw = projPos.xy;

            return o;
        }

        half Fragment(Interpolators i) : SV_Target
        {
            //UNITY_SETUP_INSTANCE_ID(i);
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

            //FragInfo debugInfo;
            //debugInfo.eyeIndex = unity_StereoEyeIndex;
            //debugInfo.pos = i.pos;
            //debugInfo.texcoord = i.texcoord;
            //FragInfoAppendBuffer.Append(debugInfo);

            // TODO
            // declare texture correctly as tex2darray
            // pass in stereo eye index in correctly so it can sample texture
            // Fix up sampling from a depth texture array
#if defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED)
            //float deviceDepth = SAMPLE_TEXTURE2D_ARRAY(_CameraDepthTexture, sampler_CameraDepthTexture, i.texcoord.xy, unity_StereoEyeIndex).r;
            //deviceDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.texcoord.xy);
            float deviceDepth = SAMPLE_TEXTURE2D_ARRAY(_CameraDepthTexture, sampler_CameraDepthTexture, i.texcoord.xy, 0).r;
#else
            float deviceDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.texcoord.xy);
#endif

#if UNITY_REVERSED_Z
            deviceDepth = 1 - deviceDepth;
#endif
            deviceDepth = 2 * deviceDepth - 1; //NOTE: Currently must massage depth before computing CS position. 

            float3 vpos = ComputeViewSpacePosition(i.texcoord.zw, deviceDepth, unity_CameraInvProjection);
            float3 wpos = mul(unity_CameraToWorld, float4(vpos, 1)).xyz;
            
            //Fetch shadow coordinates for cascade.
            float4 coords  = ComputeScreenSpaceShadowCoords(wpos);

            //return SampleShadowmap(coords);
            //return deviceDepth;
            return i.texcoord.x;
            //return unity_StereoEyeIndex;
        }

        ENDHLSL

        Pass
        {           
            ZTest Always
            ZWrite Off
            Cull Off

            HLSLPROGRAM
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _SHADOWS_CASCADE
            
            #pragma vertex   Vertex
            #pragma fragment Fragment
            ENDHLSL
        }
    }
}
