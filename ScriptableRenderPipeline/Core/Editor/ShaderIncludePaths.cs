using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;

public class ShaderIncludePaths : ScriptableObject, IShaderIncludePathGenerator
{
    [SerializeField]
    List<string> m_Paths = new List<string>();

    public void AddPaths(IEnumerable<string> paths)
    {
        m_Paths.AddRange(paths);
    }

    public void GetShaderIncludePaths(List<string> paths)
    {
        foreach (var path in m_Paths)
            paths.Add(Path.GetFullPath(path));
    }
}
