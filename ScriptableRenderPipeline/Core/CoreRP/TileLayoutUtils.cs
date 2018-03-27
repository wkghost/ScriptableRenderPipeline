namespace UnityEngine.Experimental.Rendering
{
    public static class TileLayoutUtils
    {
        public static bool TryLayoutByTiles(
            RectUInt src, 
            uint tileSize, 
            out RectUInt main, 
            out RectUInt topRow, 
            out RectUInt rightCol, 
            out RectUInt topRight)
        {
            if (src.width < tileSize || src.height < tileSize)
            {
                main = RectUInt.zero;
                topRow = RectUInt.zero;
                rightCol = RectUInt.zero;
                topRight = RectUInt.zero;
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

        public static bool TryLayoutByRow(
            RectUInt src, 
            uint tileSize, 
            out RectUInt main, 
            out RectUInt other)
        {
            if (src.height < tileSize)
            {
                main = RectUInt.zero;
                other = RectUInt.zero;
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

        public static bool TryLayoutByCol(
            RectUInt src, 
            uint tileSize, 
            out RectUInt main, 
            out RectUInt other)
        {
            if (src.width < tileSize)
            {
                main = RectUInt.zero;
                other = RectUInt.zero;
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
    }
}