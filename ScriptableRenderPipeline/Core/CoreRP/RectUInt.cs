namespace UnityEngine.Experimental.Rendering
{
    public struct RectUInt 
    {
        public static readonly RectUInt zero = new RectUInt { x = 0u, y = 0u, width = 0u, height = 0u };

        public uint x;
        public uint y;
        public uint width;
        public uint height;

        public RectUInt(uint x, uint y, uint width, uint height)
        {
            this.x = x;
            this.y = y;
            this.width = width;
            this.height = height;
        }
    }
}