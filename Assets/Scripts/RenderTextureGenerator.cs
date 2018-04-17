using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RenderTextureGenerator : MonoBehaviour {

    //public Texture aTexture;
    //public RenderTexture rTex;
    //public Material m;
	public CustomRenderTexture _texture;
    void Start()
    {
        //if (!aTexture || !rTex)
            //Debug.LogError("A texture or a render texture are missing, assign them.");
		_texture.Initialize();

    }
    void Update()
    {
        //Graphics.Blit(aTexture, rTex,m,-1);
        //m.SetTexture("_HeightMap",rTex);
		_texture.Update(2);
    }
}

