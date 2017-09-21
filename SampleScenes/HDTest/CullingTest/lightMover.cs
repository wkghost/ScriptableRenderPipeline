using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class lightMover : MonoBehaviour {

    private Vector3 m_pos;
    public float test = 0.0f;

	// Use this for initialization
	void Start ()
    {
        m_pos = transform.position;
	}

	// Update is called once per frame
	void Update ()
    {
        Vector3 pos = m_pos;
        pos.z = m_pos.z +  5.0f * Mathf.Sin(Time.time * test);
        transform.position = pos;
    }
}
