using System;
using System.Collections.Generic;
using UnityEngine.Rendering;

namespace UnityEngine.Experimental.Rendering.HDPipeline
{
    class BufferPyramid
    {
        static readonly int _Size = Shader.PropertyToID("_Size");
        static readonly int _Source = Shader.PropertyToID("_Source");
        static readonly int _Result = Shader.PropertyToID("_Result");
        static readonly int _SrcSize = Shader.PropertyToID("_SrcSize");
        const int k_DepthBlockSize = 4;

        GPUCopy m_GPUCopy;
        ComputeShader m_ColorPyramidCS;

        RTHandle m_ColorPyramidBuffer;
        List<RTHandle> m_ColorPyramidMips = new List<RTHandle>();
        int m_ColorPyramidKernel;

        ComputeShader m_DepthPyramidCS;
        RTHandle m_DepthPyramidBuffer;
        List<RTHandle> m_DepthPyramidMips = new List<RTHandle>();
        int[] m_DepthKernels = null;
        int depthKernel8 { get { return m_DepthKernels[0]; } }
        

        public RTHandle colorPyramid { get { return m_ColorPyramidBuffer; } }
        public RTHandle depthPyramid { get { return m_DepthPyramidBuffer; } }

        public BufferPyramid(
            ComputeShader colorPyramidCS,
            ComputeShader depthPyramidCS, GPUCopy gpuCopy)
        {
            m_ColorPyramidCS = colorPyramidCS;
            m_ColorPyramidKernel = m_ColorPyramidCS.FindKernel("KMain");

            m_DepthPyramidCS = depthPyramidCS;
            m_GPUCopy = gpuCopy;
            m_DepthKernels = new int[]
            {
                m_DepthPyramidCS.FindKernel("KDepthDownSample8"),
                m_DepthPyramidCS.FindKernel("KDepthDownSample2_0"),
                m_DepthPyramidCS.FindKernel("KDepthDownSample2_1"),
                m_DepthPyramidCS.FindKernel("KDepthDownSample2_2"),
                m_DepthPyramidCS.FindKernel("KDepthDownSample2_3"),
            };
        }

        int GetDepthKernel2(int pattern)
        {
            return m_DepthKernels[pattern + 1];
        }

        float GetXRscale()
        {
            // for stereo double-wide, each half of the texture will represent a single eye's pyramid
            float scale = 1.0f;
            //if (m_Asset.renderPipelineSettings.supportsStereo && (desc.dimension != TextureDimension.Tex2DArray))
            //    scale = 2.0f; // double-wide
            return scale;
        }

        public void CreateBuffers()
        {
            m_ColorPyramidBuffer = RTHandle.Alloc(size => CalculatePyramidSize(size), filterMode: FilterMode.Trilinear, colorFormat: RenderTextureFormat.ARGBHalf, sRGB: false, useMipMap: true, autoGenerateMips: false, name: "ColorPymarid");
            m_DepthPyramidBuffer = RTHandle.Alloc(size => CalculatePyramidSize(size), filterMode: FilterMode.Trilinear, colorFormat: RenderTextureFormat.RFloat, sRGB: false, useMipMap: true, autoGenerateMips: false, enableRandomWrite: true, name: "DepthPyramid"); // Need randomReadWrite because we downsample the first mip with a compute shader.
        }

        public void ClearBuffers(HDCamera hdCamera, CommandBuffer cmd)
        {
            HDUtils.SetRenderTarget(cmd, hdCamera, m_ColorPyramidBuffer, ClearFlag.Color, Color.clear);
            HDUtils.SetRenderTarget(cmd, hdCamera, m_DepthPyramidBuffer, ClearFlag.Color, Color.clear);
        }

        public void DestroyBuffers()
        {
            RTHandle.Release(m_ColorPyramidBuffer);
            RTHandle.Release(m_DepthPyramidBuffer);

            foreach (var rth in m_ColorPyramidMips)
            {
                RTHandle.Release(rth);
            }

            foreach (var rth in m_DepthPyramidMips)
            {
                RTHandle.Release(rth);
            }
        }

        public int GetPyramidLodCount(HDCamera camera)
        {
            var minSize = Mathf.Min(camera.actualWidth, camera.actualHeight);
            return Mathf.FloorToInt(Mathf.Log(minSize, 2f));
        }

        Vector2Int CalculatePyramidMipSize(Vector2Int baseMipSize, int mipIndex)
        {
            return new Vector2Int(baseMipSize.x >> mipIndex, baseMipSize.y >> mipIndex);
        }

        Vector2Int CalculatePyramidSize(Vector2Int size)
        {
            // Instead of using the screen size, we round up to the next power of 2 because currently some platforms don't support NPOT Render Texture with mip maps (PS4 for example)
            // Then we render in a Screen Sized viewport.
            // Note that even if PS4 supported POT Mips, the buffers would be padded to the next power of 2 anyway (TODO: check with other platforms...)
            int pyramidSize = (int)Mathf.NextPowerOfTwo(Mathf.Max(size.x, size.y));
            return new Vector2Int((int)(pyramidSize * GetXRscale()), pyramidSize);
            
            // int pyramidSize = (int)Mathf.NextPowerOfTwo(Mathf.Max(size.x, size.y));
            // return new Vector2Int((int)(size.x * GetXRscale()), size.y);
        }

        void UpdatePyramidMips(HDCamera camera, RenderTextureFormat format, List<RTHandle> mipList, int lodCount)
        {
            int currentLodCount = mipList.Count;
            if (lodCount > currentLodCount)
            {
                for (int i = currentLodCount; i < lodCount; ++i)
                {
                    int mipIndexCopy = i + 1; // Don't remove this copy! It's important for the value to be correctly captured by the lambda.
                    RTHandle newMip = RTHandle.Alloc(size => CalculatePyramidMipSize(CalculatePyramidSize(size), mipIndexCopy), colorFormat: format, sRGB: false, enableRandomWrite: true, useMipMap: false, filterMode: FilterMode.Bilinear, name: string.Format("PyramidMip{0}", i));
                    mipList.Add(newMip);
                }
            }
        }

        public Vector2 GetPyramidToScreenScale(HDCamera camera)
        {
            return new Vector2((float)camera.actualWidth / m_DepthPyramidBuffer.rt.width, (float)camera.actualHeight / m_DepthPyramidBuffer.rt.height);
        }

        struct RectUInt 
        {
            public static readonly RectUInt Zero = new RectUInt { x = 0u, y = 0u, width = 0u, height = 0u };

            public uint x;
            public uint y;
            public uint width;
            public uint height;
        }

        static bool TryLayoutByTiles(RectUInt src, uint tileSize, out RectUInt main, out RectUInt topRow, out RectUInt rightCol, out RectUInt topRight)
        {
            if (src.width < tileSize || src.height < tileSize)
            {
                main = RectUInt.Zero;
                topRow = RectUInt.Zero;
                rightCol = RectUInt.Zero;
                topRight = RectUInt.Zero;
                return false;
            }

            uint mainRows = src.height / tileSize;
            uint mainCols = src.width / tileSize;
            uint mainWidth = mainCols * tileSize;
            uint mainHeight = mainRows * tileSize;

            main = new RectUInt
            {
                x = src.x,
                y = src.y,
                width = mainWidth,
                height = mainHeight,
            };
            topRow = new RectUInt
            {
                x = src.x,
                y = src.y + mainHeight,
                width = mainWidth,
                height = src.height - mainHeight
            };
            rightCol = new RectUInt
            {
                x = src.x + mainWidth,
                y = src.y,
                width = src.width - mainWidth,
                height = mainHeight
            };
            topRight = new RectUInt
            {
                x = src.x + mainWidth,
                y = src.y + mainHeight,
                width = src.width - mainWidth,
                height = src.height - mainHeight
            };

            return true;
        }

        static bool TryLayoutByRow(RectUInt src, uint tileSize, out RectUInt main, out RectUInt other)
        {
            if (src.height < tileSize)
            {
                main = RectUInt.Zero;
                other = RectUInt.Zero;
                return false;
            }

            uint mainRows = src.height / tileSize;
            uint mainHeight = mainRows * tileSize;

            main = new RectUInt
            {
                x = src.x,
                y = src.y,
                width = src.width,
                height = mainHeight,
            };
            other = new RectUInt
            {
                x = src.x,
                y = src.y + mainHeight,
                width = src.width,
                height = src.height - mainHeight
            };

            return true;
        }

        static bool TryLayoutByCol(RectUInt src, uint tileSize, out RectUInt main, out RectUInt other)
        {
            if (src.width < tileSize)
            {
                main = RectUInt.Zero;
                other = RectUInt.Zero;
                return false;
            }

            uint mainCols = src.width / tileSize;
            uint mainWidth = mainCols * tileSize;

            main = new RectUInt
            {
                x = src.x,
                y = src.y,
                width = mainWidth,
                height = src.height,
            };
            other = new RectUInt
            {
                x = src.x + mainWidth,
                y = src.y,
                width = src.width - mainWidth,
                height = src.height
            };

            return true;
        }

        public void RenderDepthPyramid(
            HDCamera hdCamera,
            CommandBuffer cmd,
            ScriptableRenderContext renderContext,
            RTHandle depthTexture)
        {
            int lodCount = GetPyramidLodCount(hdCamera);
            UpdatePyramidMips(hdCamera, m_DepthPyramidBuffer.rt.format, m_DepthPyramidMips, lodCount);

            Vector2 scale = GetPyramidToScreenScale(hdCamera);
            cmd.SetGlobalVector(HDShaderIDs._DepthPyramidSize, new Vector4(hdCamera.actualWidth, hdCamera.actualHeight, 1f / hdCamera.actualWidth, 1f / hdCamera.actualHeight));
            cmd.SetGlobalVector(HDShaderIDs._DepthPyramidScale, new Vector4(scale.x, scale.y, lodCount, 0.0f));

            m_GPUCopy.SampleCopyChannel_xyzw2x(cmd, depthTexture, m_DepthPyramidBuffer, new Vector2(hdCamera.actualWidth, hdCamera.actualHeight));

            RTHandle src = m_DepthPyramidBuffer;
            for (var i = 0; i < lodCount; i++)
            {
                RTHandle dest = m_DepthPyramidMips[i];

                var srcMipWidth = hdCamera.actualWidth >> i;
                var srcMipHeight = hdCamera.actualHeight >> i;
                var dstMipWidth = srcMipWidth >> 1;
                var dstMipHeight = srcMipHeight >> 1;

                cmd.SetComputeVectorParam(m_DepthPyramidCS, _SrcSize, new Vector4(srcMipWidth, srcMipHeight, (1.0f / srcMipWidth) * scale.x, (1.0f / srcMipHeight) * scale.y));

                var srcRect = new RectUInt { x = 0u, y = 0u, width = (uint)srcMipWidth, height = (uint)srcMipHeight };
                RectUInt main, topRow, rightCol, topRight;

                // we use unsafe block to allocate struct arrays on the stack
                // unsafe 
                // {
                //     // Calculate rects to dispatch

                //     var dispatch2Rects = stackalloc RectUInt[8];
                //     // Patterns for partial kernels (must match DepthPyramid.compute)
                //     //  0.  |x|x|       1.  |x|o|       2.  |o|o|       3.  |o|o|
                //     //      |x|x|           |x|o|           |x|x|           |x|o|
                //     var dispatch2Patterns = stackalloc int[8];
                //     var dispatch2Index = 0;
                //     var dispatch16Rect = RectUInt.Zero;

                //     if (TryLayoutByTiles(srcRect, 16, out main, out topRow, out rightCol, out topRight))
                //     {
                //         // Dispatch 16x16 full kernel on main
                //         dispatch16Rect = main;

                //         if (TryLayoutByRow(topRow, 2, out main, out topRow))
                //         {
                //             // Dispatch 2x2 full kernel on main
                //             dispatch2Rects[dispatch2Index] = main;
                //             dispatch2Patterns[dispatch2Index] = 0;
                //             ++dispatch2Index;
                //         }
                //         // Dispatch 2x2 partial kernel on topRow
                //         dispatch2Rects[dispatch2Index] = topRow;
                //         dispatch2Patterns[dispatch2Index] = 2;
                //         ++dispatch2Index;


                //         if (TryLayoutByCol(rightCol, 2, out main, out rightCol))
                //         {
                //             // Dispatch 2x2 full kernel on main
                //             dispatch2Rects[dispatch2Index] = main;
                //             dispatch2Patterns[dispatch2Index] = 0;
                //             ++dispatch2Index;
                //         }
                //         // Dispatch 2x2 partial kernel on rightCol
                //         dispatch2Rects[dispatch2Index] = rightCol;
                //         dispatch2Patterns[dispatch2Index] = 1;
                //         ++dispatch2Index;

                //         if (TryLayoutByTiles(srcRect, 2, out main, out topRow, out rightCol, out topRight))
                //         {
                //             // Dispatch 2x2 full kernel on main
                //             dispatch2Rects[dispatch2Index] = main;
                //             dispatch2Patterns[dispatch2Index] = 0;
                //             ++dispatch2Index;

                //             // Dispatch 2x2 partial kernel on topRow
                //             dispatch2Rects[dispatch2Index] = topRow;
                //             dispatch2Patterns[dispatch2Index] = 2;
                //             ++dispatch2Index;
                            
                //             // Dispatch 2x2 partial kernel on rightCol
                //             dispatch2Rects[dispatch2Index] = rightCol;
                //             dispatch2Patterns[dispatch2Index] = 1;
                //             ++dispatch2Index;
                //         }

                //         // Dispatch 2x2 partial kernel on topRight
                //         dispatch2Rects[dispatch2Index] = rightCol;
                //         dispatch2Patterns[dispatch2Index] = 3;
                //         ++dispatch2Index;
                //     }
                //     else if (TryLayoutByTiles(srcRect, 2, out main, out topRow, out rightCol, out topRight))
                //     {
                //         // Dispatch 2x2 full kernel on main
                //         dispatch2Rects[dispatch2Index] = main;
                //         dispatch2Patterns[dispatch2Index] = 0;
                //         ++dispatch2Index;

                //         // Dispatch 2x2 partial kernel on topRow
                //         dispatch2Rects[dispatch2Index] = topRow;
                //         dispatch2Patterns[dispatch2Index] = 2;
                //         ++dispatch2Index;
                        
                //         // Dispatch 2x2 partial kernel on rightCol
                //         dispatch2Rects[dispatch2Index] = rightCol;
                //         dispatch2Patterns[dispatch2Index] = 1;
                //         ++dispatch2Index;

                //         // Dispatch 2x2 partial kernel on topRight
                //         dispatch2Rects[dispatch2Index] = rightCol;
                //         dispatch2Patterns[dispatch2Index] = 3;
                //         ++dispatch2Index;
                //     }

                //     // Send dispatchs
                //     if (dispatch16Rect.width > 0 && dispatch16Rect.height > 0)
                //     {
                //         var kernel = depthKernel8;
                //         var x = dispatch16Rect.width >> 4;
                //         var y = dispatch16Rect.height >> 4;
                //         cmd.SetComputeIntParams(m_DepthPyramidCS, HDShaderIDs._RectOffset, (int)dispatch16Rect.x, (int)dispatch16Rect.y);
                //         cmd.SetComputeTextureParam(m_DepthPyramidCS, kernel, _Source, src);
                //         cmd.SetComputeTextureParam(m_DepthPyramidCS, kernel, _Result, dest);
                //         cmd.DispatchCompute(m_DepthPyramidCS, kernel, (int)x, (int)y, 1);
                //     }

                //     for (int j = 0, c = dispatch2Index; j < c; ++j)
                //     {
                //         var kernel = GetDepthKernel2(dispatch2Patterns[j]);
                //         var rect = dispatch2Rects[j];
                //         var x = Mathf.Max(rect.width >> 1, 1);
                //         var y = Mathf.Max(rect.height >> 1, 1);
                //         cmd.SetComputeIntParams(m_DepthPyramidCS, HDShaderIDs._RectOffset, (int)rect.x, (int)rect.y);
                //         cmd.SetComputeTextureParam(m_DepthPyramidCS, kernel, _Source, src);
                //         cmd.SetComputeTextureParam(m_DepthPyramidCS, kernel, _Result, dest);
                //         cmd.DispatchCompute(m_DepthPyramidCS, kernel, (int)x, (int)y, 1);
                //     }
                // }

                {
                    var kernel = GetDepthKernel2(0);
                    var rect = srcRect;
                    var x = Mathf.Max(rect.width >> 1, 1);
                    var y = Mathf.Max(rect.height >> 1, 1);
                    cmd.SetComputeIntParams(m_DepthPyramidCS, HDShaderIDs._RectOffset, (int)rect.x, (int)rect.y);
                    cmd.SetComputeTextureParam(m_DepthPyramidCS, kernel, _Source, src);
                    cmd.SetComputeTextureParam(m_DepthPyramidCS, kernel, _Result, dest);
                    cmd.DispatchCompute(m_DepthPyramidCS, kernel, (int)x, (int)y, 1);
                }

                if ((srcRect.width & 1) != 0)
                {
                    var kernel = GetDepthKernel2(1);
                    var rect = new RectUInt { x = srcRect.width - 1, y = 0, width = 1, height = srcRect.height };
                    var x = 1;
                    var y = Mathf.Max(rect.height >> 1, 1);
                    cmd.SetComputeIntParams(m_DepthPyramidCS, HDShaderIDs._RectOffset, (int)rect.x, (int)rect.y);
                    cmd.SetComputeTextureParam(m_DepthPyramidCS, kernel, _Source, src);
                    cmd.SetComputeTextureParam(m_DepthPyramidCS, kernel, _Result, dest);
                    cmd.DispatchCompute(m_DepthPyramidCS, kernel, (int)x, (int)y, 1);
                }

                if ((srcRect.height & 1) != 0)
                {
                    var kernel = GetDepthKernel2(2);
                    var rect = new RectUInt { x = 0, y = srcRect.height - 1, width = srcRect.width, height = 1 };
                    var x = Mathf.Max(rect.width >> 1, 1);
                    var y = 1;
                    cmd.SetComputeIntParams(m_DepthPyramidCS, HDShaderIDs._RectOffset, (int)rect.x, (int)rect.y);
                    cmd.SetComputeTextureParam(m_DepthPyramidCS, kernel, _Source, src);
                    cmd.SetComputeTextureParam(m_DepthPyramidCS, kernel, _Result, dest);
                    cmd.DispatchCompute(m_DepthPyramidCS, kernel, (int)x, (int)y, 1);
                }

                if ((srcRect.height & 1) != 0 && (srcRect.width & 1) != 0)
                {
                    var kernel = GetDepthKernel2(3);
                    var rect = new RectUInt { x = srcRect.width - 1, y = srcRect.height - 1, width = 1, height = 1 };
                    var x = 1;
                    var y = 1;
                    cmd.SetComputeIntParams(m_DepthPyramidCS, HDShaderIDs._RectOffset, (int)rect.x, (int)rect.y);
                    cmd.SetComputeTextureParam(m_DepthPyramidCS, kernel, _Source, src);
                    cmd.SetComputeTextureParam(m_DepthPyramidCS, kernel, _Result, dest);
                    cmd.DispatchCompute(m_DepthPyramidCS, kernel, (int)x, (int)y, 1);
                }

                // If we could bind texture mips as UAV we could avoid this copy...(which moreover copies more than the needed viewport if not fullscreen)
                cmd.CopyTexture(m_DepthPyramidMips[i], 0, 0, 0, 0, dstMipWidth, dstMipHeight, m_DepthPyramidBuffer, 0, i + 1, 0, 0);
                src = dest;
            }

            cmd.SetGlobalTexture(HDShaderIDs._DepthPyramidTexture, m_DepthPyramidBuffer);
        }

        public void RenderColorPyramid(
            HDCamera hdCamera,
            CommandBuffer cmd, 
            ScriptableRenderContext renderContext,
            RTHandle colorTexture)
        {
            int lodCount = GetPyramidLodCount(hdCamera);
            UpdatePyramidMips(hdCamera, m_ColorPyramidBuffer.rt.format, m_ColorPyramidMips, lodCount);

            Vector2 scale = GetPyramidToScreenScale(hdCamera);
            cmd.SetGlobalVector(HDShaderIDs._ColorPyramidSize, new Vector4(hdCamera.actualWidth, hdCamera.actualHeight, 1f / hdCamera.actualWidth, 1f / hdCamera.actualHeight));
            cmd.SetGlobalVector(HDShaderIDs._ColorPyramidScale, new Vector4(scale.x, scale.y, lodCount, 0.0f));

            // Copy mip 0
            // Here we blit a "camera space" texture into a square texture but we want to keep the original viewport.
            // Other BlitCameraTexture version will setup the viewport based on the destination RT scale (square here) so we need override it here.
            HDUtils.BlitCameraTexture(cmd, hdCamera, colorTexture, m_ColorPyramidBuffer, new Rect(0.0f, 0.0f, hdCamera.actualWidth, hdCamera.actualHeight));

            RTHandle src = m_ColorPyramidBuffer;
            for (var i = 0; i < lodCount; i++)
            {
                RTHandle dest = m_ColorPyramidMips[i];

                var srcMipWidth = hdCamera.actualWidth >> i;
                var srcMipHeight = hdCamera.actualHeight >> i;
                var dstMipWidth = srcMipWidth >> 1;
                var dstMipHeight = srcMipHeight >> 1;

                // TODO: Add proper stereo support to the compute job

                cmd.SetComputeTextureParam(m_ColorPyramidCS, m_ColorPyramidKernel, _Source, src);
                cmd.SetComputeTextureParam(m_ColorPyramidCS, m_ColorPyramidKernel, _Result, dest);
                // _Size is used as a scale inside the whole render target so here we need to keep the full size (and not the scaled size depending on the current camera)
                cmd.SetComputeVectorParam(m_ColorPyramidCS, _Size, new Vector4(dest.rt.width, dest.rt.height, 1f / dest.rt.width, 1f / dest.rt.height));
                cmd.DispatchCompute(
                    m_ColorPyramidCS,
                    m_ColorPyramidKernel,
                    Mathf.CeilToInt(dstMipWidth / 8f),
                    Mathf.CeilToInt(dstMipHeight / 8f),
                    1);
                // If we could bind texture mips as UAV we could avoid this copy...(which moreover copies more than the needed viewport if not fullscreen)
                cmd.CopyTexture(m_ColorPyramidMips[i], 0, 0, 0, 0, dstMipWidth, dstMipHeight, m_ColorPyramidBuffer, 0, i + 1, 0, 0);

                src = dest;
            }

            cmd.SetGlobalTexture(HDShaderIDs._ColorPyramidTexture, m_ColorPyramidBuffer);
        }
    }
}
