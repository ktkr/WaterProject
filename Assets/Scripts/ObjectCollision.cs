using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ObjectCollision : MonoBehaviour {


    private void OnCollisionEnter(Collision collision)
    {
        if(collision.collider.tag == "Water")
        {
            //collision.collider.GetComponent<RenderTextureController>().PerformActions(collision.contacts[0].point);
            //Debug.Log("collided");
        }
    }
}
