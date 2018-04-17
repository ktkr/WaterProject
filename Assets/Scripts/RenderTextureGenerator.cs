using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RenderTextureGenerator : MonoBehaviour {

    public Texture aTexture;
    public RenderTexture rTex;
    public Material m;
    void Start()
    {
        if (!aTexture || !rTex)
            Debug.LogError("A texture or a render texture are missing, assign them.");

    }
    void Update()
    {
        Graphics.Blit(aTexture, rTex,m,-1);
        m.SetTexture("_HeightMap",rTex);
        
    }
}

