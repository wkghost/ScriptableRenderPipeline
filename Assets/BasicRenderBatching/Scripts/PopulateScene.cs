using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class PopulateScene : MonoBehaviour {


    public GameObject[] m_ObjectsPrefab = new GameObject[4];
    public Transform    m_CenterPoint;
    public Material m_Material;
    public Material m_MaterialFlat;

    public Texture2D[] m_Textures = new Texture2D[8];

    public int          m_GridWidth = 16;
    public int          m_GridLayers = 1;
    public float m_Spacing = 0.6f;

    public static bool m_Use8Textures = false;

    private GameObject[] m_Objects;               // 
    private Material[] m_Materials;               // 

    // Use this for initialization
    void Start()
    {


        m_Objects = new GameObject[m_GridWidth * m_GridWidth * m_GridLayers];
        m_Materials = new Material[m_GridWidth * m_GridWidth * m_GridLayers];

        int iIndex = 0;

        Random.InitState(31415926);

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
                    vPos += m_CenterPoint.position;

                    int r = Random.Range(0, 3 + 1);

                    m_Objects[iIndex] = Instantiate(m_ObjectsPrefab[r], vPos, m_CenterPoint.rotation) as GameObject;

                    Renderer renderer = m_Objects[iIndex].GetComponent<Renderer>();
                    Material mat;
                    if ( m_Use8Textures )
                        mat = Instantiate(m_Material);
                    else
                        mat = Instantiate(m_MaterialFlat);

                    Color oColor = new Color(Random.value, Random.value, Random.value, 1.0f);
                    mat.SetColor("myColor", oColor);

                    if (m_Use8Textures)
                    {
                        mat.SetTexture("myTexture1", m_Textures[Random.Range(0, 7 + 1)]);
                        mat.SetTexture("myTexture2", m_Textures[Random.Range(0, 7 + 1)]);
                        mat.SetTexture("myTexture3", m_Textures[Random.Range(0, 7 + 1)]);
                        mat.SetTexture("myTexture4", m_Textures[Random.Range(0, 7 + 1)]);
                        mat.SetTexture("myTexture5", m_Textures[Random.Range(0, 7 + 1)]);
                        mat.SetTexture("myTexture6", m_Textures[Random.Range(0, 7 + 1)]);
                        mat.SetTexture("myTexture7", m_Textures[Random.Range(0, 7 + 1)]);
                        mat.SetTexture("myTexture8", m_Textures[Random.Range(0, 7 + 1)]);
                    }

                    renderer.material = mat;
//                    renderer.material.InitUniformBuffers();
                    m_Materials[iIndex] = renderer.material;

                    iIndex++;
                }
            }
        }
    }

    // Update is called once per frame
    void Update ()
    {
/*
        if ( m_Use8Textures )
        {
            int r = Random.Range(0, m_GridWidth * m_GridWidth * m_GridLayers);
            m_Materials[r].SetTexture("myTexture1", m_Textures[Random.Range(0, 7 + 1)]);
            m_Materials[r].SetTexture("myTexture2", m_Textures[Random.Range(0, 7 + 1)]);
            m_Materials[r].SetTexture("myTexture3", m_Textures[Random.Range(0, 7 + 1)]);
            m_Materials[r].SetTexture("myTexture4", m_Textures[Random.Range(0, 7 + 1)]);
            m_Materials[r].SetTexture("myTexture5", m_Textures[Random.Range(0, 7 + 1)]);
            m_Materials[r].SetTexture("myTexture6", m_Textures[Random.Range(0, 7 + 1)]);
            m_Materials[r].SetTexture("myTexture7", m_Textures[Random.Range(0, 7 + 1)]);
            m_Materials[r].SetTexture("myTexture8", m_Textures[Random.Range(0, 7 + 1)]);
        }
*/

    }

    void OnGUI()
    {

        GUI.changed = false;
        m_Use8Textures = GUI.Toggle(new Rect(10, 10, 200, 20), m_Use8Textures, "change rand texture");

        if (GUI.changed)
        {
            SceneManager.LoadScene("BasicBatching");
        }

    }

}
