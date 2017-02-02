using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEditor;
using Object = UnityEngine.Object;

public class Scatterer
{
    static public GameObject[] m_ObjectsPrefab = new GameObject[4];
    static public Material[] m_MaterialPrefab = new Material[4];
    static public Texture2D[] m_TexturesPrefab = new Texture2D[4];


    [MenuItem("Arnaud/Generator")]
    public static void OpenEditor()
    {
        m_ObjectsPrefab[0] = (GameObject)AssetDatabase.LoadAssetAtPath("Assets/BasicRenderBatching/Prefabs/Cube.prefab", typeof(GameObject));
        m_ObjectsPrefab[1] = (GameObject)AssetDatabase.LoadAssetAtPath("Assets/BasicRenderBatching/Prefabs/Capsule.prefab", typeof(GameObject));
        m_ObjectsPrefab[2] = (GameObject)AssetDatabase.LoadAssetAtPath("Assets/BasicRenderBatching/Prefabs/cylinder.prefab", typeof(GameObject));
        m_ObjectsPrefab[3] = (GameObject)AssetDatabase.LoadAssetAtPath("Assets/BasicRenderBatching/Prefabs/sphere.prefab", typeof(GameObject));

        m_MaterialPrefab[0] = (Material)AssetDatabase.LoadAssetAtPath("Assets/TestScenes/HDTest/Material/BatchingTest/Materials/Iron50.mat", typeof(Material));
        m_MaterialPrefab[1] = (Material)AssetDatabase.LoadAssetAtPath("Assets/TestScenes/HDTest/Material/BatchingTest/Materials/Iron51.mat", typeof(Material));
        m_MaterialPrefab[2] = (Material)AssetDatabase.LoadAssetAtPath("Assets/TestScenes/HDTest/Material/BatchingTest/Materials/Iron52.mat", typeof(Material));
        m_MaterialPrefab[3] = (Material)AssetDatabase.LoadAssetAtPath("Assets/TestScenes/HDTest/Material/BatchingTest/Materials/Iron53.mat", typeof(Material));

        Material chromeMat = (Material)AssetDatabase.LoadAssetAtPath("Assets/TestScenes/HDTest/Material/BatchingTest/Materials/Chrome.mat", typeof(Material));

        m_TexturesPrefab[0] = (Texture2D)AssetDatabase.LoadAssetAtPath("Assets/BasicRenderBatching/Textures/Glass.tif", typeof(Texture2D));
        m_TexturesPrefab[1] = (Texture2D)AssetDatabase.LoadAssetAtPath("Assets/BasicRenderBatching/Textures/ColorGrid.png", typeof(Texture2D));
        m_TexturesPrefab[2] = (Texture2D)AssetDatabase.LoadAssetAtPath("Assets/BasicRenderBatching/Textures/cookieTest.png", typeof(Texture2D));
        m_TexturesPrefab[3] = (Texture2D)AssetDatabase.LoadAssetAtPath("Assets/BasicRenderBatching/Textures/fx_flame_01_d.tif", typeof(Texture2D));


        int m_GridLayers = 1;
        int m_GridWidth = 32;
        float m_Spacing = 0.6f;


        var toErase = (Object.FindObjectsOfType(typeof(GameObject)) as GameObject[]).Where(o => o.name.Contains("cube") || o.name.Contains("Capsule") || o.name.Contains("cylinder") || o.name.Contains("sphere"));
        foreach (var o in toErase)
            Object.DestroyImmediate(o);

        toErase = (Object.FindObjectsOfType(typeof(GameObject)) as GameObject[]).Where(o => o.name.Contains("Iron5") && o.name.Contains("(Clone)"));
        foreach (var o in toErase)
            Object.DestroyImmediate(o);

        Random.InitState(31415926);


//        GameObject root = GameObject.findob

        for (int y = 0; y < m_GridLayers; y++)
        {
            for (int z = 0; z < m_GridWidth; z++)
            {
                for (int x = 0; x < m_GridWidth; x++)
                {
                    //                    int i = z * m_CubesRow + x;

                    float fX = (x - (m_GridWidth / 2)) * 2;
                    float fY = (y - (m_GridLayers / 2)) * 2 + Random.Range(-0.5f, 0.5f);
                    float fZ = (z - (m_GridWidth / 2)) * 2;

                    Vector3 vPos = new Vector3(fX * m_Spacing, fY, fZ * m_Spacing);

                    int r = Random.Range(0, 3 + 1);

                    GameObject obj = GameObject.Instantiate(m_ObjectsPrefab[Random.Range(0, 4)], vPos, Quaternion.identity) as GameObject;

                    Renderer renderer = obj.GetComponent<Renderer>();

                     int matN = 0; // Random.Range(0, 4)
                     Material mat = Material.Instantiate(m_MaterialPrefab[matN]);

//                    Material mat = Material.Instantiate(chromeMat);

                     Color oColor = new Color(Random.value, Random.value, Random.value, 1.0f);
                     mat.SetColor("_BaseColor", oColor);

                    mat.SetTexture("_BaseColorMap", m_TexturesPrefab[Random.Range(0, 4)]);


                    renderer.material = mat;
//                    renderer.material.InitUniformBuffers();
                }
            }
        }


    }
}
