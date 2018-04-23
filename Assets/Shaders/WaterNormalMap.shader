Shader "Water/NormalMap"
{
	Properties
	{
		_WaterTex ("WaterTex", 2D) = "white" {}
		_WaterTexWidth("WaterTexWidth",Float) = 256
		_WaterTexHeight("WaterTexHeight", Float) = 256
	}

		CGINCLUDE
		#include "UnityCustomRenderTexture.cginc"
		sampler2D _WaterTex;
		float _WaterTexWidth;
		float _WaterTexHeight;
	

		float4 frag(v2f_customrendertexture i) : SV_Target
	{

		float2 uv = i.globalTexcoord;

		//unit in the u,v direction
		float du = 1.0 / _WaterTexWidth;
		float dv = 1.0 / _WaterTexHeight;

		float v1y = tex2D(_WaterTex, uv).r;
		float v2y = tex2D(_WaterTex, uv + float2(du,0)).r;
		float v3y = tex2D(_WaterTex, uv + float2(0,dv)).r;
		float3 crossProduct = cross(float3(du, v2y - v1y, 0), float3(0, v3y - v1y, dv));
		//float3 crossProduct = cross(float3(0, v3y - v1y, dv), float3(du, v2y - v1y, 0));
		return float4(normalize(crossProduct), 1);
		
	}

	ENDCG

	SubShader
	{
		Cull Off ZWrite Off ZTest Always

			Pass
		{
			Name "Normal"
			CGPROGRAM
			#pragma vertex CustomRenderTextureVertexShader
			#pragma fragment frag
			ENDCG
		}
	}
		
}
