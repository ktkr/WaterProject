Shader "Custom/TransparentLightMeshSurf" {
	Properties
{
	
}

CGINCLUDE

#include "UnityCustomRenderTexture.cginc"

float4 frag(v2f_customrendertexture i) : SV_Target
{
    float4 lightDir = _WorldSpaceLightPos0;
    return float4(p, c.r, 0, 1);
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
