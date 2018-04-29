Shader "Water/CausticsShader"
{

Properties
{

	//Unit distance from current location
    _DeltaUV("Delta UV", Float) = 3
    _IOR_AIR("Air Index of Refraction", Float) = 1
    _IOR_WATER("Water Index of Refraction", Float) = 1.33
    _WaterTex ("Water Texture", 2D) = "white" {}
	_NormalTex("Normal Texture", 2D) = "white"{}
 }

CGINCLUDE
#include "UnityCG.cginc"

#include "UnityCustomRenderTexture.cginc"

half _S2;
half _Atten;
float _DeltaUV;
float3 oldPos;
float3 newPos;
float3 ray;
float _PoolHeight;
float _IOR_AIR;
float _IOR_WATER;
//uniform float3 light;
sampler2D _WaterTex;
sampler2D _NormalTex;



float2 intersectCube(float3 origin, float3 ray, float3 cubeMin, float3 cubeMax) {
    float3 tMin = (cubeMin - origin) / ray;
    float3 tMax = (cubeMax - origin) / ray;
    float3 t1 = min(tMin, tMax);
    float3 t2 = max(tMin, tMax);
    float tNear = max(max(t1.x, t1.y), t1.z);
    float tFar = min(min(t2.x, t2.y), t2.z);
    return float2(tNear, tFar);
}

// project ray onto plane
float3 project(float3 origin, float3 ray, float3 refractedLight)
{
	float2 tcube = intersectCube(origin, ray, float3(-5.0, -_PoolHeight, -5.0), float3(5.0, _PoolHeight, 5.0));
    origin += ray * tcube.y;
    float tplane = (-origin.y - 2.5) / refractedLight.y;
    return origin + refractedLight * tplane;
}

//float3 dFdx(float3 vec, float3 gl_Vertex)
//{
//	return float3(1,1,1);
//}

float4 frag(v2f_customrendertexture i) : SV_Target
{
	float4 gl_Position;
	float4 gl_FragColor;
	float3 uv = i.globalTexcoord;
	float4 info = tex2D(_WaterTex, uv.xy);//gl_Vertex.xy * 0.5 + 0.5);
    //info.ba *= 0.5;
    //float3 normal = float3(info.b, sqrt(1.0 - dot(info.ba, info.ba)), info.a);
	float3 normal = tex2D(_NormalTex, uv.xy);
    //* project the vertices along the refracted vertex ray */
    float3 refractedLight = refract(normalize(info.xyz-_WorldSpaceLightPos0), float3(0.0, 1.0, 0.0), _IOR_AIR / _IOR_WATER);
    ray = refract(normalize(info.xyz-_WorldSpaceLightPos0), normal, _IOR_AIR / _IOR_WATER);
    oldPos = project(info.xyz, refractedLight, refractedLight);//float3(uv.x,uv.y,0)
    newPos = project(info.xyz, ray, refractedLight);//uv.xzy + float3(0.0, info.r, 0.0)
	//return float4(uv,1);
    //gl_Position = float4(0.75 * (newPos.xz + refractedLight.xz / refractedLight.y), 0.0, 1.0);
	//return float4(newPos, 1);
	return float4(newPos.xz,0, 1);
    //if the triangle gets smaller, it gets brighter, and vice versa
    float oldArea = ddx(oldPos) * ddy(oldPos);
	//return float4(oldArea, 0, 0, 1);
    float newArea = ddx(newPos) *ddy(newPos);
	//return float4(newPos*0.5, 1);
	//return float4(0.3*oldArea / newArea, 0.5, 0.0, 1);// *oldArea / newArea;
	//return float4(oldArea/newArea*0.5, 0, 0, 1);
    //gl_FragColor = float4(oldArea / newArea*0.4, 1.0,0, 1.0);
	//return gl_FragColor;
    
    //* shadow for the rim of the pool */
    //float2 t = intersectCube(newPos, refractedLight, float3(-5.0, -_PoolHeight, -5.0), float3(5.0, _PoolHeight, 5.0));
    //gl_FragColor.r *= 1.0 / (1.0 + exp(-200.0 / (1.0 + 10.0 * (uv.y - uv.x)) * (newPos.y - refractedLight.y * uv.y -2.5)));
    //return float4(refractedLight, 1);
    return gl_FragColor;
}

ENDCG

SubShader
{
    Cull Off ZWrite Off ZTest Always

    Pass
    {
        Name "Caustic"
        CGPROGRAM
        #pragma vertex CustomRenderTextureVertexShader
        #pragma fragment frag
        ENDCG
    }

}

}