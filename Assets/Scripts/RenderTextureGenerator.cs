using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RenderTextureGenerator : MonoBehaviour {

    //public Texture aTexture;
    //public RenderTexture rTex;
    //public Material m;
    [SerializeField]
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

        _texture.ClearUpdateZones();
        UpdateZones();
        _texture.Update(2);
    }

    void UpdateZones()
    {
        if (Input.GetMouseButton(0))
        {
            RaycastHit hit;

            Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);
            //cast a ray to see if hit surface, apply deformation if hit water
            if (Physics.Raycast(ray, out hit))
            {
                if (hit.collider.gameObject.tag == "Water")
                {
                    CustomRenderTextureUpdateZone zone = new CustomRenderTextureUpdateZone();
                    zone.needSwap = true;
                    zone.passIndex = 0;
                    zone.rotation = 0.0f;
                    zone.updateZoneCenter = new Vector2(0.5f, 0.5f);
                    zone.updateZoneSize = new Vector2(1.0f, 1.0f);

                    CustomRenderTextureUpdateZone clickZone = new CustomRenderTextureUpdateZone();

                    clickZone.needSwap = true;
                    clickZone.passIndex = 1; // Path to buffer buffer at 1 or -1 
                    clickZone.rotation = 0.0f;
                    //update the "event" in the list
                    clickZone.updateZoneCenter = new Vector2(hit.textureCoord.x, 1f - hit.textureCoord.y);
                    clickZone.updateZoneSize = new Vector2(0.01f, 0.01f);


                    _texture.SetUpdateZones(new CustomRenderTextureUpdateZone[] { zone, clickZone });
                }
            }
        }

        
    }
    
}

