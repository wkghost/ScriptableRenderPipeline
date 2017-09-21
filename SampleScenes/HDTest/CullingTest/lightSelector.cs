using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class lightSelector : MonoBehaviour
{
    [NonSerialized]
    public bool[] testBool = new bool[128];

    [NonSerialized]
    public int m_count;

    void Start()
    {
//         ToggleTest toggleTest = camera.GetComponent<ToggleTest>();
//         toggleTest.testBool[]
    }

    void OnGUI()
    {
        for (int i = 0; i < m_count; i++)
            testBool[i] = GUI.Toggle(new Rect(0, i * 20f, 100, 20), testBool[i], "Checkbox");
    }
}
