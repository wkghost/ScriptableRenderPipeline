using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class PopulateScene : MonoBehaviour {


    public GameObject[] m_ObjectsPrefab = new GameObject[4];
    public Transform    m_CenterPoint;
    public Material     m_Material;

    public int          m_GridWidth = 16;
    public float m_Spacing = 0.6f;

    public static bool m_DifferentColors = true;

    private GameObject[] m_Objects;               // 

    // Use this for initialization
    void Start()
    {


        m_Objects = new GameObject[m_GridWidth * m_GridWidth];

        int iIndex = 0;
        for (int z = 0; z < m_GridWidth; z++)
        {
            for (int x = 0; x < m_GridWidth; x++)
            {
                //                    int i = z * m_CubesRow + x;

                float fX = (x - (m_GridWidth / 2)) * 2;
                float fY = Random.Range(-0.5f, 0.5f);
                float fZ = (z - (m_GridWidth / 2)) * 2;

                Vector3 vPos = new Vector3(fX * m_Spacing, fY, fZ * m_Spacing);
                vPos += m_CenterPoint.position;

                int r = Random.Range(0, 3);

                m_Objects[iIndex] = Instantiate(m_ObjectsPrefab[r], vPos, m_CenterPoint.rotation) as GameObject;

                if (m_DifferentColors)
                {
                    Renderer renderer = m_Objects[iIndex].GetComponent<Renderer>();
                    Material mat = Instantiate(m_Material);
                    Color oColor = new Color(Random.value, Random.value, Random.value, 1.0f);
                    mat.SetColor("myColor", oColor);

                    mat.InitUniformBuffers();

                    renderer.material = mat;
                }
                iIndex++;
            }
        }
    }

    // Update is called once per frame
    void Update ()
    {
		
	}

    void OnGUI()
    {

        GUI.changed = false;
        m_DifferentColors = GUI.Toggle(new Rect(10, 10, 200, 20), m_DifferentColors, "One color per object");

        if (GUI.changed)
        {
            SceneManager.LoadScene("BasicBatching");
        }

    }

}
