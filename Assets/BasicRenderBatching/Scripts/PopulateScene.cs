using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PopulateScene : MonoBehaviour {


    public GameObject   m_ObjectPrefab;             // 
    public Transform    m_CenterPoint;
    public int          m_GridWidth = 16;
    public float m_Spacing = 0.6f;


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
                float fY = 0.0f;
                float fZ = (z - (m_GridWidth / 2)) * 2;

                Vector3 vPos = new Vector3(fX * m_Spacing, fY, fZ * m_Spacing);
                vPos += m_CenterPoint.position;

                m_Objects[iIndex] = Instantiate(m_ObjectPrefab, vPos, m_CenterPoint.rotation) as GameObject;
                iIndex++;

            }
        }
    }

    // Update is called once per frame
    void Update ()
    {
		
	}

}
