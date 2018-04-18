Shader "Refraction/RefractedLightShader"
{

Properties
{
	_refractionIndex("Refraction Index", Float) = 1
	_HFNormalTex ("HeightField Normal Texture", 2D) = "white" {}
}

CGINCLUDE

#include "UnityCustomRenderTexture.cginc"

float _refractionIndex;
sampler2D _HFNormalTex;

float4 frag(v2f_customrendertexture i) : SV_Target
{
    float4 lightDir = _WorldSpaceLightPos0;
    float2 uv = i.globalTexcoord;
    //float4 normals = tex2D(_HFNormalTex, uv);
    float4 normals = tex2D(_SelfTexture2D, uv);
    //float DN = dot(lightDir, normals);
    //float4 refrDir = (1 * (lightDir - normals*DN))/_refractionIndex - normals * sqrt(1 - DN*DN/(_refractionIndex*_refractionIndex));
    //return float4(normalize(refract(-lightDir.xyz, normals.rgb, _refractionIndex)),1);

    return float4(refract(normalize(float3(0.5,0,-1)), normals.rgb, _refractionIndex),1);
    //return float4(1, 0,0,1);
}


ENDCG

SubShader
{
    Cull Off ZWrite Off ZTest Always

    Pass
    {
        Name "Update"
        CGPROGRAM
        #pragma vertex CustomRenderTextureVertexShader
        #pragma fragment frag
        ENDCG
    }
}

}