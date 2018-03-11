namespace UnityEngine.Experimental.Rendering.HDPipeline
{
    [SkyUniqueID((int)SkyType.HDRISky)]
    public class HDRISky : SkySettings
    {
        [Tooltip("Cubemap used to render the sky.")]
        public CubemapParameter hdriSky = new CubemapParameter(null);
        [Tooltip("Desired intensity in Lux for the upper hemisphere of the HDRI")]
        public float intensity = 10000;
        [Tooltip("If enabled the HDRI will be calibrated based on the desired intensity provided")]
        public bool enableIntensity = false;

        public bool NeedComputeMultiplier()
        {
            return m_needComputeMultiplier;
        }

        bool m_needComputeMultiplier = false;

        public override SkyRenderer CreateRenderer()
        {
            return new HDRISkyRenderer(this);
        }

        public override int GetHashCode()
        {
            int hash = base.GetHashCode();

            unchecked
            {
                hash = hdriSky.value != null ? hash * 23 + hdriSky.GetHashCode() : hash;
            }

            return hash;
        }
    }
}
