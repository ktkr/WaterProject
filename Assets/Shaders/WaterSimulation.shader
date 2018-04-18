Shader "Water/Simulation"
{

Properties
{
	//Speed of the wave
    _S2("PhaseVelocity^2", Range(0.0, 0.5)) = 0.2
    [PowerSlider(0.01)]
	//Attenuation value causes dropoff in wave energy
    _Atten("Attenuation", Range(0.0, 1.0)) = 0.995
	//Unit distance from current location
    _DeltaUV("Delta UV", Float) = 3
}

CGINCLUDE

#include "UnityCustomRenderTexture.cginc"

half _S2;
half _Atten;
float _DeltaUV;

float4 frag(v2f_customrendertexture i) : SV_Target
{
    float2 uv = i.globalTexcoord;

	//unit in the u,v direction
    float du = 1.0 / _CustomRenderTextureWidth;
    float dv = 1.0 / _CustomRenderTextureHeight;
    float3 duv = float3(du, dv, 0) * _DeltaUV;

	//get color value at the point
    float2 c = tex2D(_SelfTexture2D, uv);
	//color value to update texture
    float p = (2 * c.r - c.g + _S2 * (
        tex2D(_SelfTexture2D, uv - duv.zy).r +
        tex2D(_SelfTexture2D, uv + duv.zy).r +
        tex2D(_SelfTexture2D, uv - duv.xz).r +
        tex2D(_SelfTexture2D, uv + duv.xz).r - 4 * c.r)) * _Atten;

	//float spd = (tex2D(_SelfTexture2D, uv - duv.zy).r +
	//	tex2D(_SelfTexture2D, uv + duv.zy).r +
	//	tex2D(_SelfTexture2D, uv - duv.xz).r +
	//	tex2D(_SelfTexture2D, uv + duv.xz).r) *0.25;
	//	//tex2D(_SelfTexture2D,uv -)
	//c.g += (spd - c.r)*_S2;
	//c.g *= _Atten;
	//c.r += c.g;

	//return float4(c.r,c.g,0,1);
    return float4(p, c.r, 0, 1);
}

float4 frag_left_click(v2f_customrendertexture i) : SV_Target
{
    return float4(1, 0, 0, 1);
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

    Pass
    {
        Name "LeftClick"
        CGPROGRAM
        #pragma vertex CustomRenderTextureVertexShader
        #pragma fragment frag_left_click
        ENDCG
    }

}

}