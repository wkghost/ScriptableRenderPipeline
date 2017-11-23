using System.Globalization;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEditor.Experimental.AssetImporters;
using UnityEngine;

[ScriptedImporter(1, kExtension)]
public class ShaderIncludePathsImporter : ScriptedImporter
{
    public const string kExtension = "ShaderIncludePaths";
	public override void OnImportAsset(AssetImportContext ctx)
	{
		var pathStrings = File.ReadAllLines(ctx.assetPath);
		var paths = ScriptableObject.CreateInstance<ShaderIncludePaths>();
		paths.hideFlags |= HideFlags.NotEditable;
		paths.AddPaths(pathStrings);
		ctx.AddObjectToAsset("MainAsset", paths);
		ctx.SetMainObject(paths);
	}
}

class ShaderIncludePostProcess : AssetPostprocessor
{
    static void OnPostprocessAllAssets(string[] importedAssets, string[] deletedAssets, string[] movedAssets, string[] movedFromAssetPaths)
    {
        if (importedAssets.Any(x => x.EndsWith(ShaderIncludePathsImporter.kExtension, true, CultureInfo.InvariantCulture))
            || deletedAssets.Any(x => x.EndsWith(ShaderIncludePathsImporter.kExtension, true, CultureInfo.InvariantCulture))
            || movedAssets.Any(x => x.EndsWith(ShaderIncludePathsImporter.kExtension, true, CultureInfo.InvariantCulture)))
        {
            ShaderUtil.UpdateShaderIncludePaths();

            AssetDatabase.StartAssetEditing();
            string[] allAssetPaths = AssetDatabase.GetAllAssetPaths();
            foreach (string assetPath in allAssetPaths)
            {
                var shader = AssetDatabase.LoadAssetAtPath(assetPath, typeof(Shader)) as Shader;
                if (shader != null)
                    AssetDatabase.ImportAsset(assetPath);
            }
            AssetDatabase.StopAssetEditing();
        }
    }
}
