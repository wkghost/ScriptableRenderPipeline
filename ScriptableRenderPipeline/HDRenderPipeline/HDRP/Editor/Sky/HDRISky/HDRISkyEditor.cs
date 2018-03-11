using UnityEngine;
using UnityEditor;
using UnityEngine.Experimental.Rendering.HDPipeline;

namespace UnityEditor.Experimental.Rendering.HDPipeline
{
    [CanEditMultipleObjects]
    [VolumeComponentEditor(typeof(HDRISky))]
    public class HDRISkyEditor
        : SkySettingsEditor
    {
        SerializedDataParameter m_HdriSky;
        SerializedDataParameter m_Intensity;
        SerializedDataParameter m_EnableIntensity;

        public override void OnEnable()
        {
            base.OnEnable();

            var o = new PropertyFetcher<HDRISky>(serializedObject);
            m_HdriSky = Unpack(o.Find(x => x.hdriSky));
            m_Intensity = Unpack(o.Find(x => x.intensity));
            m_EnableIntensity = Unpack(o.Find(x => x.enableIntensity));
        }

        public override void OnInspectorGUI()
        {
            EditorGUI.BeginChangeCheck();
            PropertyField(m_HdriSky);
            PropertyField(m_EnableIntensity);
            using (new UnityEditor.EditorGUI.DisabledScope(m_EnableIntensity.value.boolValue))
            {
                PropertyField(m_Intensity);
            }
            if (EditorGUI.EndChangeCheck())
            {
              //  target. NeedComputeMultiplier();
            }

            EditorGUILayout.Space();

            base.CommonSkySettingsGUI();
        }
    }
}
