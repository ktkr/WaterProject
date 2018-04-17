using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RayCaster : MonoBehaviour {

    Camera cam;

    private void Start()
    {
        cam = GetComponent<Camera>();
    }

    private void Update()
    {
        //if holding left click
        if (Input.GetMouseButton(0))
        {

            RaycastHit hit;
            
            Ray ray = cam.ScreenPointToRay(Input.mousePosition);
            //cast a ray to see if hit surface, apply deformation if hit water
            if(Physics.Raycast(ray,out hit))
            {
                GameObject target = hit.collider.gameObject;
                if(target.tag == "Water")
                {
                    
                    CustomRenderTexture texture = (CustomRenderTexture)target.GetComponent<Material>().mainTexture;
                    CustomRenderTextureUpdateZone zone = new CustomRenderTextureUpdateZone();
                    zone.needSwap = true;
                    zone.passIndex = 0;
                    zone.rotation = 0.0f;
                    zone.updateZoneCenter = new Vector2(0.5f, 0.5f);
                    zone.updateZoneSize = new Vector2(1.0f, 1.0f);

                    CustomRenderTextureUpdateZone clickZone = new CustomRenderTextureUpdateZone();
                    
                    clickZone.needSwap = true;
                    clickZone.passIndex = 1;//leftClick ? 1 : 2; // Path to buffer buffer at 1 or -1 
                    clickZone.rotation = 0.0f;
                    clickZone.updateZoneCenter = new Vector2(hit.textureCoord.x, 1f - hit.textureCoord.y);
                    clickZone.updateZoneSize = new Vector2(0.01f, 0.01f);
                    texture.SetUpdateZones(new CustomRenderTextureUpdateZone[] { zone, clickZone });

                }
            }

        }
    }
}
