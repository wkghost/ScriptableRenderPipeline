using System.Collections.Generic;

namespace UnityEngine.Experimental.Rendering
{
    [RequireComponent(typeof(Light))]
    [ExecuteInEditMode]
    public class AdditionalShadowData : MonoBehaviour
    {
#pragma warning disable 414 // CS0414 The private field '...' is assigned but its value is never used
        // We can't rely on Unity for our additional data, we need to version it ourself.
        [SerializeField]
        float m_Version = 1.0f;
#pragma warning restore 414

        public const int DefaultShadowResolution = 512;

        public int shadowResolution = DefaultShadowResolution;

        public static int GetShadowResolution(AdditionalShadowData shadowData)
        {
            if (shadowData != null)
                return shadowData.shadowResolution;
            else
                return DefaultShadowResolution;
        }

        [Range(0.0f, 1.0f)]
        public float shadowSoftness = 0.5f;
        [Range(0.0f, 0.001f)]
        public float shadowBaseFilterWidth = 0.0f;

        [Range(0.0f, 1.0f)]
        public float shadowDimmer = 1.0f;
        public float shadowFadeDistance = 10000.0f;
        // bias control
        public float viewBiasMin        = 0.5f;
        public float viewBiasMax        = 10.0f;
        [Range(0.0F, 15.0F)]
        public float viewBiasScale      = 1.0f;
        public float normalBiasMin      = 0.2f;
        public float normalBiasMax      = 4.0f;
        [Range(0.0F, 10.0F)]
        public float normalBiasScale    = 1.0f;
        public bool sampleBiasScale     = true;
        public bool edgeLeakFixup       = true;
        public bool edgeToleranceNormal = true;
        [Range(0.0F, 1.0F)]
        public float edgeTolerance      = 1.0f;


        // shadow related parameters
        [System.Serializable]
        public struct ShadowData
        {
            public int format;
            public int[] data;
        };

        [HideInInspector, SerializeField]
        private int shadowCascadeCount = 4;
        [HideInInspector, SerializeField]
        private float[] shadowCascadeRatios = new float[3] { 0.05f, 0.2f, 0.3f };
        [HideInInspector, SerializeField]
        private float[] shadowCascadeBorders = new float[4] { 0.2f, 0.2f, 0.2f, 0.2f };
        [HideInInspector, SerializeField]
        private int shadowAlgorithm;
        [HideInInspector, SerializeField]
        private int shadowVariant;
        [HideInInspector, SerializeField]
        private int shadowPrecision;
        [HideInInspector, SerializeField]
        private ShadowData shadowData;
        [HideInInspector, SerializeField]
        private ShadowData[] shadowDatas = new ShadowData[0];

        public int cascadeCount { get { return shadowCascadeCount; } }
        public void GetShadowCascades(out int cascadeCount, out float[] cascadeRatios, out float[] cascadeBorders) { cascadeCount = shadowCascadeCount; cascadeRatios = shadowCascadeRatios; cascadeBorders = shadowCascadeBorders; }
        public void SetShadowCascades(int cascadeCount, float[] cascadeRatios, float[] cascadeBorders) { shadowCascadeCount = cascadeCount; shadowCascadeRatios = cascadeRatios; shadowCascadeBorders = cascadeBorders; }
        public void GetShadowAlgorithm(out int algorithm, out int variant, out int precision) { algorithm = shadowAlgorithm; variant = shadowVariant; precision = shadowPrecision; }
        public void SetShadowAlgorithm(int algorithm, int variant, int precision, int format, int[] data)
        {
            shadowAlgorithm = algorithm;
            shadowVariant = variant;
            shadowPrecision = precision;
            shadowData.format = format;
            shadowData.data = data;

            int idx = FindShadowData(format);
            if (idx < 0)
            {
                idx = shadowDatas.Length;
                ShadowData[] tmp = new ShadowData[idx + 1];
                for (int i = 0; i < idx; ++i)
                    tmp[i] = shadowDatas[i];
                shadowDatas = tmp;
            }
            shadowDatas[idx].format = format;
            shadowDatas[idx].data = data != null ? data : new int[0];
        }
        // Load a specific shadow data. Returns null if requested data is not present.
        public int[] GetShadowData(int shadowDataFormat)
        {
            if (shadowData.format == shadowDataFormat)
                return shadowData.data;

            int idx = FindShadowData(shadowDataFormat);
            return idx >= 0 ? shadowDatas[idx].data : null;
        }
        // Returns the currently set shadow data and format. Can return null.
        public int[] GetShadowData(out int shadowDataFormat)
        {
            shadowDataFormat = shadowData.format;
            return shadowData.data;
        }
#if UNITY_EDITOR
        public void CompactShadowData()
        {
            shadowDatas = new ShadowData[0];
            UnityEditor.EditorUtility.SetDirty(this);
        }
#endif
        private int FindShadowData(int shadowDataFormat)
        {
            for (int i = 0; i < shadowDatas.Length; ++i)
            {
                if (shadowDatas[i].format == shadowDataFormat)
                    return i;
            }
            return -1;
        }

        // Shadow Planes
        [HideInInspector, SerializeField]
        private ShadowPlane[] m_ShadowPlanes; // serialized to handle copy/paste
        private ShadowPlane.Params[] m_ShadowPlaneParams;

        public ShadowPlane[] ShadowPlanes { get { ValidateShadowPlanes(); return m_ShadowPlanes; } }
        public ShadowPlane.Params[] ShadowPlaneParams { get { ValidateShadowPlanes(); return m_ShadowPlaneParams; } }

        void InvalidateShadowPlanes() { m_ShadowPlanes = null; }
        void ValidateShadowPlanes()
        {
            if (m_ShadowPlanes != null)
            {
#if UNITY_EDITOR
                // Did we just get copy/pasted?
                if (m_ShadowPlanes.Length > 0 && m_ShadowPlanes[0].transform.parent != transform)
                {
                    var newPlanes = new ShadowPlane[m_ShadowPlanes.Length];
                    m_ShadowPlanes.CopyTo(newPlanes, 0);
                    m_ShadowPlanes = null;
                    var oldPlanes = GetComponents<ShadowPlane>();
                    foreach (var p in oldPlanes)
                        UnityEditor.Undo.DestroyObjectImmediate(p.gameObject);
                    foreach (var p in newPlanes)
                        AddShadowPlane(p);
                }
                else
#endif
                    return;
            }
            List<ShadowPlane> planes = new List<ShadowPlane>();
            GetComponentsInChildren(planes);
            for (int i = planes.Count-1; i >= 0; --i)
                if (planes[i].transform.parent != transform)
                    planes.RemoveAt(i);
            foreach (var p in planes)
            m_ShadowPlanes = planes.ToArray();
            if (m_ShadowPlanes == null)
                m_ShadowPlanes = new ShadowPlane[0];
            m_ShadowPlaneParams = new ShadowPlane.Params[m_ShadowPlanes.Length];
            for (int i = 0; i < m_ShadowPlanes.Length; ++i)
			    m_ShadowPlaneParams[i] = m_ShadowPlanes[i].ShadowParams;
        }

        public ShadowPlane AddShadowPlane(ShadowPlane copyFrom = null)
        {
            GameObject go = new GameObject("Shadow Plane", typeof(ShadowPlane));
#if UNITY_EDITOR
            UnityEditor.Undo.RegisterCreatedObjectUndo(go, "Add Shadow Plane");
            UnityEditor.Undo.SetTransformParent(go.transform, transform, "Add Shadow Plane");
            UnityEditor.EditorUtility.SetDirty(this);
#else
            go.transform.parent = transform.parent;
#endif
            var plane = go.GetComponent<ShadowPlane>();
            if (copyFrom == null)
            {
                plane.transform.localPosition = Vector3.zero;
                plane.transform.localRotation = Quaternion.identity;
                plane.m_Feather = 1;
            }
            else
            {
                plane.transform.localPosition = copyFrom.transform.localPosition;
                plane.transform.localRotation = copyFrom.transform.localRotation;
                plane.m_Feather = copyFrom.m_Feather;
            }
            return plane;
        }

        void OnTransformChildrenChanged() { InvalidateShadowPlanes(); }
    }

#if UNITY_EDITOR
    [UnityEditor.CustomEditor(typeof(AdditionalShadowData))]
    [UnityEditor.CanEditMultipleObjects]
    public class AdditionalShadowDataEditor : UnityEditor.Editor
    {
        static ShadowRegistry m_ShadowRegistry;

#pragma warning disable 414 // CS0414 The private field '...' is assigned but its value is never used
        UnityEditor.SerializedProperty m_ShadowAlgorithm;
        UnityEditor.SerializedProperty m_ShadowVariant;
        UnityEditor.SerializedProperty m_ShadowData;
        UnityEditor.SerializedProperty m_ShadowDatas;
#pragma warning restore 414
        UnityEditor.SerializedProperty m_ShadowCascadeCount;
        UnityEditor.SerializedProperty m_ShadowCascadeRatios;
        UnityEditor.SerializedProperty m_ShadowCascadeBorders;

        public static void SetRegistry( ShadowRegistry registry ) { m_ShadowRegistry = registry; }

        void OnEnable()
        {
            m_ShadowAlgorithm = serializedObject.FindProperty( "shadowAlgorithm" );
            m_ShadowVariant   = serializedObject.FindProperty( "shadowVariant" );
            m_ShadowData      = serializedObject.FindProperty( "shadowData" );
            m_ShadowDatas     = serializedObject.FindProperty( "shadowDatas" );
            m_ShadowCascadeCount  = serializedObject.FindProperty( "shadowCascadeCount" );
            m_ShadowCascadeRatios = serializedObject.FindProperty( "shadowCascadeRatios" );
            m_ShadowCascadeBorders = serializedObject.FindProperty( "shadowCascadeBorders" );
        }
        public override void OnInspectorGUI()
        {
            base.OnInspectorGUI();

            if( m_ShadowRegistry == null )
                return;

            AdditionalShadowData asd = (AdditionalShadowData) target;
            if( asd == null )
                return;

            UnityEditor.EditorGUI.BeginChangeCheck();

            m_ShadowRegistry.Draw( asd.gameObject.GetComponent<Light>() );
            serializedObject.Update();

            // cascade code
            if( asd.gameObject.GetComponent<Light>().type == LightType.Directional )
            {
                UnityEditor.EditorGUI.BeginChangeCheck();
                UnityEditor.EditorGUILayout.PropertyField( m_ShadowCascadeCount );
                if( UnityEditor.EditorGUI.EndChangeCheck() )
                {
                    const int kMaxCascades = (int) ShadowAtlas.k_MaxCascadesInShader; // depending on where you look this is either 32 or 4, so we're limiting it to 4 for now
                    int newcnt = m_ShadowCascadeCount.intValue <= 0 ? 1 : (m_ShadowCascadeCount.intValue > kMaxCascades ? kMaxCascades : m_ShadowCascadeCount.intValue);
                    m_ShadowCascadeCount.intValue = newcnt;
                    m_ShadowCascadeRatios.arraySize = newcnt-1;
                    m_ShadowCascadeBorders.arraySize = newcnt;
                }
                UnityEditor.EditorGUI.indentLevel++;
                for( int i = 0; i < m_ShadowCascadeRatios.arraySize; i++ )
                {
                    UnityEditor.EditorGUILayout.Slider( m_ShadowCascadeRatios.GetArrayElementAtIndex( i ), 0.0f, 1.0f, new GUIContent( "Cascade " + i ) );
                }
                for (int i = 0; i < m_ShadowCascadeBorders.arraySize; i++)
                {
                    UnityEditor.EditorGUILayout.Slider( m_ShadowCascadeBorders.GetArrayElementAtIndex( i ), 0.0f, 1.0f, new GUIContent( "Transition " + i ) );
                }
                UnityEditor.EditorGUI.indentLevel--;
            }

            if( UnityEditor.EditorGUI.EndChangeCheck() )
            {
                UnityEditor.EditorUtility.SetDirty( asd );
                UnityEditor.SceneManagement.EditorSceneManager.MarkAllScenesDirty();
                UnityEditor.SceneView.RepaintAll();
            }
            serializedObject.ApplyModifiedProperties();
        }
    }
#endif
}
