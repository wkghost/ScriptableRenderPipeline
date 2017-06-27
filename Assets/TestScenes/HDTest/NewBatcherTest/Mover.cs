using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using Object = UnityEngine.Object;
using UnityEngine.Experimental.Rendering;

public class Mover : MonoBehaviour {


    Transform[] m_Transforms;
    Material[] m_Materials;
    float       m_Phase0;
    private bool m_Pause = false;
    private bool m_ChangeColor = false;

    void    OnEnable()
    {
        DebugMenuManager.instance.AddDebugItem<bool>("Arnaud", "Pause", () => m_Pause, (value) => m_Pause = (bool)value);
        DebugMenuManager.instance.AddDebugItem<bool>("Arnaud", "Change Color", () => m_ChangeColor, (value) => m_ChangeColor = (bool)value);
    }

    // Use this for initialization
    void Start ()
    {

        var list = FindObjectsOfType<GameObject>().Where(o => o.name.Contains("Cube") || o.name.Contains("Capsule") || o.name.Contains("Cylinder") || o.name.Contains("Sphere"));

        m_Transforms = list.Select(g => g.transform).ToArray();
        m_Materials = list.Select(g => g.GetComponent<MeshRenderer>().sharedMaterial).ToArray();

    }

    // Update is called once per frame
    void Update ()
    {
        if (( !m_Pause ) || (m_ChangeColor))
        {
            float innerPhase = m_Phase0;
            int count = m_Transforms.Length;

            for ( int i=0;i<count;i++)
            {
                if ( !m_Pause )
                {
                    Transform t = m_Transforms[i];
                    float yd = 2.0f * Mathf.Sin(innerPhase);
                    t.localPosition = new Vector3(t.localPosition.x, Mathf.Abs(yd), t.localPosition.z);
                    innerPhase += 0.01f;
                }

                if ( m_ChangeColor )
                {
                    Color oColor = new Color(Random.value, Random.value, Random.value, 1.0f);
                    m_Materials[i].SetColor("_BaseColor", oColor);
                }
            }
            m_Phase0 += Time.deltaTime * 2.0f;
        }
    }

}
