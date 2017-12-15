using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using UnityEditor.Experimental.Rendering.HDPipeline;
using UnityEditorInternal;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Experimental.Rendering.HDPipeline;
using UnityEngine.SceneManagement;

namespace UnityEditor.Experimental.Rendering
{
    [CustomEditorForRenderPipeline(typeof(ReflectionProbe), typeof(HDRenderPipelineAsset))]
    [CanEditMultipleObjects]
    partial class HDReflectionProbeEditor : Editor
    {
        static Dictionary<ReflectionProbe, HDReflectionProbeEditor> s_ReflectionProbeEditors = new Dictionary<ReflectionProbe, HDReflectionProbeEditor>();

        static HDReflectionProbeEditor GetEditorFor(ReflectionProbe p)
        {
            HDReflectionProbeEditor e;
            if (s_ReflectionProbeEditors.TryGetValue(p, out e) 
                && e != null 
                && !e.Equals(null)
                && ArrayUtility.IndexOf(e.targets, p) != -1)
                return e;

            return null;
        }

        SerializedReflectionProbe m_SerializedReflectionProbe;
        SerializedObject m_AdditionalDataSerializedObject;
        UIState m_UIState = new UIState();

        public bool sceneViewEditing
        {
            get { return IsReflectionProbeEditMode(EditMode.editMode) && EditMode.IsOwner(this); }
        }

        void OnEnable()
        {
            var additionalData = CoreEditorUtils.GetAdditionalData<HDAdditionalReflectionData>(targets);
            m_AdditionalDataSerializedObject = new SerializedObject(additionalData);
            m_SerializedReflectionProbe = new SerializedReflectionProbe(serializedObject, m_AdditionalDataSerializedObject);
            m_UIState.Reset(
                this,
                Repaint,
                m_SerializedReflectionProbe);

            foreach (var t in targets)
            {
                var p = (ReflectionProbe)t;
                s_ReflectionProbeEditors[p] = this;
            }
        }

        public override void OnInspectorGUI()
        {
            serializedObject.Update();
            m_AdditionalDataSerializedObject.Update();

            var s = m_UIState;
            var p = m_SerializedReflectionProbe;

            k_PrimarySection.Draw(s, p, this);
            k_InfluenceVolumeSection.Draw(s, p, this);
            k_SeparateProjectionVolumeSection.Draw(s, p, this);
            k_CaptureSection.Draw(s, p, this);
            //k_AdditionalSection.Draw(s, p, this);
            k_BakingActions.Draw(s, p, this);

            PerformOperations(s, p, this);

            m_AdditionalDataSerializedObject.ApplyModifiedProperties();
            serializedObject.ApplyModifiedProperties();

            HideAdditionalComponents(false);
        }

        static void PerformOperations(UIState s, SerializedReflectionProbe p, HDReflectionProbeEditor o)
        {
            if (s.HasAndClearOperation(Operation.UpdateOldLocalSpace))
                s.UpdateOldLocalSpace((ReflectionProbe)p.so.targetObject);
            if (s.HasAndClearOperation(Operation.FitVolumeToSurroundings))
                FitProbe(s, p, o);
        }

        void HideAdditionalComponents(bool visible)
        {
            var adds = CoreEditorUtils.GetAdditionalData<HDAdditionalReflectionData>(targets);
            var flags = visible ? HideFlags.None : HideFlags.HideInInspector;
            for (var i = 0 ; i < targets.Length; ++i)
            {
                var target = targets[i];
                var addData = adds[i];
                var p = (ReflectionProbe)target;
                var meshRenderer = p.GetComponent<MeshRenderer>();
                var meshFilter = p.GetComponent<MeshFilter>();

                addData.hideFlags = flags;
                meshRenderer.hideFlags = flags;
                meshFilter.hideFlags = flags;
            }
        }

        static Matrix4x4 GetLocalSpace(ReflectionProbe probe)
        {
            var t = probe.transform.position;
            return Matrix4x4.TRS(t, GetLocalSpaceRotation(probe), Vector3.one);
        }

        static Quaternion GetLocalSpaceRotation(ReflectionProbe probe)
        {
            var supportsRotation = (SupportedRenderingFeatures.active.reflectionProbeSupportFlags & SupportedRenderingFeatures.ReflectionProbeSupportFlags.Rotation) != 0;
            return supportsRotation 
                ? probe.transform.rotation 
                : Quaternion.identity;
        }

        // Ensures that probe's AABB encapsulates probe's position
        // Returns true, if center or size was modified
        static bool ValidateAABB(ReflectionProbe p, ref Vector3 center, ref Vector3 size)
        {
            var localSpace = GetLocalSpace(p);
            var localTransformPosition = localSpace.inverse.MultiplyPoint3x4(p.transform.position);

            var b = new Bounds(center, size);

            if (b.Contains(localTransformPosition))
                return false;

            b.Encapsulate(localTransformPosition);

            center = b.center;
            size = b.size;
            return true;
        }

        static bool IsCollidingWithOtherProbes(string targetPath, ReflectionProbe targetProbe, out ReflectionProbe collidingProbe)
        {
            ReflectionProbe[] probes = FindObjectsOfType<ReflectionProbe>().ToArray();
            collidingProbe = null;
            foreach (var probe in probes)
            {
                if (probe == targetProbe || probe.customBakedTexture == null)
                    continue;
                string path = AssetDatabase.GetAssetPath(probe.customBakedTexture);
                if (path == targetPath)
                {
                    collidingProbe = probe;
                    return true;
                }
            }
            return false;
        }

        static bool IsReflectionProbeEditMode(EditMode.SceneViewEditMode editMode)
        {
            return editMode == EditMode.SceneViewEditMode.ReflectionProbeBox || editMode == EditMode.SceneViewEditMode.Collider || editMode == EditMode.SceneViewEditMode.GridBox ||
                editMode == EditMode.SceneViewEditMode.ReflectionProbeOrigin;
        }

        static void BakeCustomReflectionProbe(ReflectionProbe probe, bool usePreviousAssetPath, bool custom)
        {
            if (!custom && probe.bakedTexture != null)
                probe.customBakedTexture = probe.bakedTexture;

            string path = "";
            if (usePreviousAssetPath)
                path = AssetDatabase.GetAssetPath(probe.customBakedTexture);

            string targetExtension = probe.hdr ? "exr" : "png";
            if (string.IsNullOrEmpty(path) || Path.GetExtension(path) != "." + targetExtension)
            {
                // We use the path of the active scene as the target path
                var targetPath = SceneManager.GetActiveScene().path;
                targetPath = Path.Combine(Path.GetDirectoryName(targetPath), Path.GetFileNameWithoutExtension(targetPath));
                if (string.IsNullOrEmpty(targetPath))
                    targetPath = "Assets";
                else if (Directory.Exists(targetPath) == false)
                    Directory.CreateDirectory(targetPath);

                string fileName = probe.name + (probe.hdr ? "-reflectionHDR" : "-reflection") + "." + targetExtension;
                fileName = Path.GetFileNameWithoutExtension(AssetDatabase.GenerateUniqueAssetPath(Path.Combine(targetPath, fileName)));

                path = EditorUtility.SaveFilePanelInProject("Save reflection probe's cubemap.", fileName, targetExtension, "", targetPath);
                if (string.IsNullOrEmpty(path))
                    return;

                ReflectionProbe collidingProbe;
                if (IsCollidingWithOtherProbes(path, probe, out collidingProbe))
                {
                    if (!EditorUtility.DisplayDialog("Cubemap is used by other reflection probe",
                        string.Format("'{0}' path is used by the game object '{1}', do you really want to overwrite it?",
                            path, collidingProbe.name), "Yes", "No"))
                    {
                        return;
                    }
                }
            }

            EditorUtility.DisplayProgressBar("Reflection Probes", "Baking " + path, 0.5f);
            if (!UnityEditor.Lightmapping.BakeReflectionProbe(probe, path))
                Debug.LogError("Failed to bake reflection probe to " + path);
            EditorUtility.ClearProgressBar();
        }

        static MethodInfo k_Lightmapping_BakeReflectionProbeSnapshot = typeof(UnityEditor.Lightmapping).GetMethod("BakeReflectionProbeSnapshot", BindingFlags.Static | BindingFlags.NonPublic);
        static bool BakeReflectionProbeSnapshot(ReflectionProbe probe)
        {
            return (bool)k_Lightmapping_BakeReflectionProbeSnapshot.Invoke(null, new object[] { probe });
        }

        static MethodInfo k_Lightmapping_BakeAllReflectionProbesSnapshots = typeof(UnityEditor.Lightmapping).GetMethod("BakeAllReflectionProbesSnapshots", BindingFlags.Static | BindingFlags.NonPublic);
        static bool BakeAllReflectionProbesSnapshots()
        {
            return (bool)k_Lightmapping_BakeAllReflectionProbesSnapshots.Invoke(null, new object[0]);
        }

        static void ResetProbeSceneTextureInMaterial(ReflectionProbe p)
        {
            var renderer = p.GetComponent<Renderer>();
            renderer.sharedMaterial.SetTexture(_Cubemap, p.texture);
        }

        static void ResetAllProbeSceneTextureInMaterial()
        {
            foreach (var data in HDAdditionalReflectionData.AllDatas)
            {
                var p = data.GetComponent<ReflectionProbe>();
                ResetProbeSceneTextureInMaterial(p);
            }
        }

        class Entry
        {
            internal float v;
            internal int c;
        }
        static readonly Vector3[] k_Orientations = { Vector3.right, -Vector3.right, Vector3.up, -Vector3.up, Vector3.forward, -Vector3.forward };
        static void FitProbe(UIState s, SerializedReflectionProbe p, HDReflectionProbeEditor o)
        {
            var rp = (ReflectionProbe)p.so.targetObject;

            var go = new GameObject("Camera");
            var cam = go.AddComponent<Camera>();
            var rt = RenderTexture.GetTemporary(128, 128, 24);
            cam.SetTargetBuffers(rt.colorBuffer, rt.depthBuffer);
            cam.depthTextureMode = DepthTextureMode.Depth;
            cam.aspect = 1;
            cam.fieldOfView = 90;
            var tr = cam.transform;
            tr.position = rp.transform.position;

            var t = new Texture2D(rt.width, rt.height, TextureFormat.RGBAFloat, false, true);

            var shader = AssetDatabase.LoadAssetAtPath<Shader>(HDEditorUtils.GetHDRenderPipelinePath() + "RenderPipelineResources/RenderDepth.shader");

            var size = rt.width * rt.height;
            var pixels = new float[size * 6];

            for (var i = 0; i < k_Orientations.Length; i++)
            {
                tr.forward = k_Orientations[i];
                cam.RenderWithShader(shader, null);
                var tmp = RenderTexture.active;
                t.ReadPixels(new Rect(0, 0, rt.width, rt.height), 0, 0, false);
                RenderTexture.active = tmp;

                var pixs = t.GetPixels(0);
                var offset = size * i;
                for (var j = 0; j < pixs.Length; ++j)
                    pixels[j + offset] = pixs[j].r;
            }

            RenderTexture.ReleaseTemporary(rt);
            DestroyImmediate(go);

            Array.Sort(pixels);

            var step = 0.01f;
            var vs = new List<Entry>();
            vs.Add(new Entry { v = pixels[0], c = 0 });
            var last = vs[0];
            for (var i = 0; i < pixels.Length; i++)
            {
                var d = pixels[i];
                if (d >= last.v + step)
                {
                    last = new Entry
                    {
                        v = d,
                        c = 1
                    };
                    vs.Add(last);
                }
                else
                    ++last.c;
            }

            var percent = 0;

            p.boxSize.vector3Value = Vector3.one * pixels[percent];
        }
    }
}
