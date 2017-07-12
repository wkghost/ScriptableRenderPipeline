using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using Object = UnityEngine.Object;
using UnityEngine.Experimental.Rendering;

public class Mover : MonoBehaviour {


    private Transform[] m_Transforms;
    private Material[] m_Materials;
    private MeshRenderer[] m_MeshRenderers;

    private float   m_Phase0;
    private bool    m_Pause = false;
    private bool    m_ChangeColor = false;

    private MaterialPropertyBlock[] m_PropertyBlocks;               // A collection of managers for enabling and disabling different aspects of the tanks.


    void OnEnable()
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
        m_MeshRenderers = list.Select(g => g.GetComponent<MeshRenderer>()).ToArray();

        int count = m_Transforms.Length;

        m_PropertyBlocks = new MaterialPropertyBlock[count];


    }

    // Update is called once per frame
    void Update ()
    {
        int count = m_Transforms.Length;

        if (!m_Pause)
        {
            float innerPhase = m_Phase0;
            for (int i = 0; i < count; i++)
            {
                Transform t = m_Transforms[i];
                float yd = 2.0f * Mathf.Sin(innerPhase);
                t.localPosition = new Vector3(t.localPosition.x, Mathf.Abs(yd), t.localPosition.z);
                innerPhase += 0.01f;
            }
            m_Phase0 += Time.deltaTime * 2.0f;
        }


        if (m_ChangeColor)
        {
            int tagID = Shader.PropertyToID("_BaseColor");

            for (int i = 0; i < count; i++)
            {
                Color oColor = new Color(Random.value, Random.value, Random.value, 1.0f);
                m_Materials[i].SetColor("_BaseColor", oColor);

/*
                MaterialPropertyBlock block = new MaterialPropertyBlock();
                block.SetColor(tagID, oColor);
                m_MeshRenderers[i].SetPropertyBlock(block);
*/
            }
        }
    }

}
