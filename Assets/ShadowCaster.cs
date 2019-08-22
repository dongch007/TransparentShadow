using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ShadowCaster : MonoBehaviour {

    private Camera transparentCamera;
    private Camera depthCamera;


    private RenderTexture depthTexture;

    private RenderTexture transparentTexture;

    private Matrix4x4 shadowBias;
    private Matrix4x4 shadowProjection;

    public float bias = 0.0f;

    // Use this for initialization
    void Start () {
        transparentCamera = this.GetComponent<Camera>();
        transparentCamera.allowHDR = false;
        transparentCamera.allowMSAA = false;
        transparentCamera.SetReplacementShader(Shader.Find("Hiden/TrasnparentShadow/TrasnparentShadow"), "RenderType");

        transparentTexture = new RenderTexture(1024, 1024, 16, RenderTextureFormat.ARGB32);
        //transparentTexture.wrapMode = TextureWrapMode.Clamp;
        transparentCamera.targetTexture = transparentTexture;


        GameObject depthCameraGo = new GameObject("DepthCamera");
        depthCamera = depthCameraGo.AddComponent<Camera>();
        depthCamera.CopyFrom(transparentCamera);
        depthCamera.SetReplacementShader(Shader.Find("Hiden/TrasnparentShadow/Depth"), "RenderType");
        depthTexture = new RenderTexture(1024, 1024, 16, RenderTextureFormat.Depth);
        depthCamera.targetTexture = depthTexture;

        Shader.SetGlobalTexture("_CustomDepthTexture", depthTexture);
        Shader.SetGlobalTexture("_TransparentTexture", transparentTexture);

        shadowBias = Matrix4x4.identity;
        shadowBias.m00 = 0.5f;
        shadowBias.m11 = 0.5f;
        shadowBias.m22 = 0.5f;
        shadowBias.m03 = 0.5f;
        shadowBias.m13 = 0.5f;
        shadowBias.m23 = 0.5f + bias;

        shadowProjection = transparentCamera.projectionMatrix;
        if (SystemInfo.usesReversedZBuffer)
        {
            shadowProjection[2, 0] = -shadowProjection[2, 0];
            shadowProjection[2, 1] = -shadowProjection[2, 1];
            shadowProjection[2, 2] = -shadowProjection[2, 2];
            shadowProjection[2, 3] = -shadowProjection[2, 3];
        }
    }
	
	// Update is called once per frame
	void Update ()
    {
        depthCamera.transform.position = transparentCamera.transform.position;
        depthCamera.transform.rotation = transparentCamera.transform.rotation;

        Shader.SetGlobalMatrix("_ShadowMatrix", shadowBias * shadowProjection * transparentCamera.worldToCameraMatrix);
    }

    private void OnDestroy()
    {
        if(this.depthTexture != null)
            GameObject.Destroy(this.depthTexture);

        if (this.transparentTexture != null)
            GameObject.Destroy(this.transparentTexture);
    }

    private void OnEnable()
    {
        Shader.EnableKeyword("SHADOW_ON");
    }

    private void OnDisable()
    {
        Shader.DisableKeyword("SHADOW_ON");
    }

    private void OnValidate()
    {
        shadowBias.m23 = 0.5f + bias; 
    }
}
