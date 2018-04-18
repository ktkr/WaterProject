using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Refract : MonoBehaviour {

	// Use this for initialization
	[SerializeField]
	public CustomRenderTexture _texture;
	void Start () {
		_texture.Initialize();
	}
	
	// Update is called once per frame
	void Update () {
		_texture.Update(2);
	}
}
