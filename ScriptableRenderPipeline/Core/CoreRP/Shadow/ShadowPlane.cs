namespace UnityEngine.Experimental.Rendering
{
    public class ShadowPlane : MonoBehaviour
    {
        [Tooltip("How much to feather the edge of the plane")]
	    public float m_Feather = 1.0f;

	    public struct Params
	    {
		    public Vector4 plane;
		    public float feather;
	    }
        public Params ShadowParams
        { 
            get 
            { 
                return new Params 
                { 
                    plane = GetShadowPlaneVector(), 
                    feather = m_Feather * 0.1f
                };
            }
        }

	    Vector4 GetShadowPlaneVector()
	    {
		    Transform t = transform;
		    Vector3 v = t.forward;
		    float d = Vector3.Dot(t.position, v);
		    return new Vector4(v.x, v.y, v.z, d);
	    }

        private void OnValidate()
        {
            m_Feather = Mathf.Max(0, m_Feather);
        }

        void OnDrawGizmosSelected()
	    {
		    Matrix4x4 m = Matrix4x4.zero;
		    Transform t = transform;
		    m.SetTRS(t.position, t.rotation, new Vector3(1, 1, 0));
		    Gizmos.matrix = m;
		    Gizmos.DrawWireSphere(Vector3.zero, 1);
	    }
    }
}
