using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SpiderInit : MonoBehaviour {

    public Material  m_SpiderMaterial;


    // Use this for initialization
    void Start () {


        Renderer renderer = GetComponent<SkinnedMeshRenderer>();

        Material mat = Material.Instantiate(m_SpiderMaterial);

        Color oColor = Color.HSVToRGB(Random.value,1,1);
        mat.SetColor("_BaseColor", oColor);
        mat.SetFloat("_Metallic", Random.value);
        mat.SetFloat("_Smoothness", Random.value);

        renderer.material = mat;

    }

    // Update is called once per frame
    void Update () {

	}
}
