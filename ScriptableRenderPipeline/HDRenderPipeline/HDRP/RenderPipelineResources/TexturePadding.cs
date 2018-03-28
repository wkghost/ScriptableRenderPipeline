using System;
using System.Collections.Generic;
using UnityEngine.Rendering;

namespace UnityEngine.Experimental.Rendering.HDPipeline
{
    class TexturePadding
    {
        static readonly int _RectOffset = Shader.PropertyToID("_RectOffset");
        static readonly int _Source = Shader.PropertyToID("_Source");

        ComputeShader m_CS;
        int m_KMainTopRight;
        int m_KMainTop;
        int m_KMainRight;

        public TexturePadding(ComputeShader cs)
        {
            m_CS = cs;
            m_KMainTopRight     = m_CS.FindKernel("KMainTopRight");
            m_KMainTop          = m_CS.FindKernel("KMainTop");
            m_KMainRight        = m_CS.FindKernel("KMainRight");
        }

        public void PadTextureTopRow(CommandBuffer cmd, RTHandle source, int width, int y)
        {
            cmd.SetComputeTextureParam(m_CS, m_KMainTop, _Source, source);
            cmd.SetComputeIntParams(m_CS, _RectOffset, 0, y);
            cmd.DispatchCompute(m_CS, m_KMainTop, width, 8, 1);
        }

        public void PadTextureTopRight(CommandBuffer cmd, RTHandle source, int x, int y)
        {
            cmd.SetComputeIntParams(m_CS, _RectOffset, x, y);
            cmd.SetComputeTextureParam(m_CS, m_KMainTopRight, _Source, source);
            cmd.DispatchCompute(m_CS, m_KMainTopRight, 8, 8, 1);
        }

        public void PadTextureRightCol(CommandBuffer cmd, RTHandle source, int x, int height)
        {
            cmd.SetComputeIntParams(m_CS, _RectOffset, x, 0);
            cmd.SetComputeTextureParam(m_CS, m_KMainRight, _Source, source);
            cmd.DispatchCompute(m_CS, m_KMainRight, 8, height, 1);
        }
    }
}
