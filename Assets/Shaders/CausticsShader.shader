Shader "Water/CausticsShader"
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
    _IOR_AIR("Air Index of Refraction", Float) = 1
    _IOR_WATER("Water Index of Refraction", Float) = 1.33
    _WaterTex ("Water Texture", 2D) = "white" {}
    light("Light", Vector) = (2,2,-1)
 }

CGINCLUDE

#include "UnityCustomRenderTexture.cginc"

half _S2;
half _Atten;
float _DeltaUV;
float3 oldPos;
float3 newPos;
float3 ray;
float poolHeight;
float IOR_AIR;
float IOR_WATER;
uniform float3 light;
sampler2D _WaterTex;



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
	float2 tcube = intersectCube(origin, ray, float3(-1.0, -poolHeight, -1.0), float3(1.0, 2.0, 1.0));
    origin += ray * tcube.y;
    float tplane = (-origin.y - 1.0) / refractedLight.y;
    return origin + refractedLight * tplane;
}

float3 dFdx(float3 vec, float3 gl_Vertex)
{
	return float3(1,1,1);
}

float4 frag(v2f_customrendertexture i) : SV_Target
{
	float4 gl_Position;
	float4 gl_FragColor;
	float3 gl_Vertex = i.globalTexcoord;
	float4 info = tex2D(_WaterTex, gl_Vertex.xy * 0.5 + 0.5);
    info.ba *= 0.5;
    float3 normal = float3(info.b, sqrt(1.0 - dot(info.ba, info.ba)), info.a);

    //* project the vertices along the refracted vertex ray */
    float3 refractedLight = refract(-light, float3(0.0, 1.0, 0.0), IOR_AIR / IOR_WATER);
    ray = refract(-light, normal, IOR_AIR / IOR_WATER);
    oldPos = project(gl_Vertex.xzy, refractedLight, refractedLight);
    newPos = project(gl_Vertex.xzy + float3(0.0, info.r, 0.0), ray, refractedLight);
      
    gl_Position = float4(0.75 * (newPos.xz + refractedLight.xz / refractedLight.y), 0.0, 1.0);

    gl_FragColor = float4(0.2, 0.2, 0.0, 0.0);

    //* if the triangle gets smaller, it gets brighter, and vice versa */
    //    float oldArea = length(dFdx(oldPos)) * length(dFdy(oldPos));
    //    float newArea = length(dFdx(newPos)) * length(dFdy(newPos));
    //    gl_FragColor = float4(oldArea / newArea * 0.2, 1.0, 0.0, 0.0);
    //
    //float3 refractedLight = refract(-light, float3(0.0, 1.0, 0.0), IOR_AIR / IOR_WATER);
      
      //* compute a blob shadow and make sure we only draw a shadow if the player is blocking the light */
      //float3 dir = (sphereCenter - newPos) / sphereRadius;
      //float3 area = cross(dir, refractedLight);
      //float shadow = dot(area, area);
      //float dist = dot(dir, -refractedLight);
      //shadow = 1.0 + (shadow - 1.0) / (0.05 + dist * 0.025);
      //shadow = clamp(1.0 / (1.0 + exp(-shadow)), 0.0, 1.0);
      //shadow = mix(1.0, shadow, clamp(dist * 2.0, 0.0, 1.0));
      //gl_FragColor.g = shadow;
      
      //* shadow for the rim of the pool */
      float2 t = intersectCube(newPos, -refractedLight, float3(-1.0, -poolHeight, -1.0), float3(1.0, 2.0, 1.0));
      gl_FragColor.r *= 1.0 / (1.0 + exp(-200.0 / (1.0 + 10.0 * (t.y - t.x)) * (newPos.y - refractedLight.y * t.y - 2.0 / 12.0)));
      //return float4(refractedLight, 1);
      return gl_FragColor;
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

}

}