Shader "Water/NormalShader"
{

Properties
{
    _DispTex("Displacement Texture", 2D) = "white" {}
}

CGINCLUDE

#include "UnityCustomRenderTexture.cginc"

sampler2D _DispTex;

float4 frag(v2f_customrendertexture i) : SV_Target
{
    float2 coord = i.globalTexcoord;
    float2 delta = float2(1.0/_CustomRenderTextureWidth, 1.0/_CustomRenderTextureHeight);

    //* get vertex info */
    float4 info = tex2D(_DispTex, coord);
      
      //* update the normal */
      float3 dx = float3(delta.x, tex2D(_DispTex, float2(coord.x + delta.x, coord.y)).r - info.r, 0.0);
      float3 dy = float3(0.0, tex2D(_DispTex, float2(coord.x, coord.y + delta.y)).r - info.r, delta.y);

      info.ba = normalize(cross(dy, dx)).xz;
//      info.w = normalize(cross(dy, dx)).b;
      
      //gl_FragColor = info;

      return info;
    //return float4(p, c.r, 0, 1);
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