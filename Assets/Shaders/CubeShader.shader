Shader "Unlit/CubeShader"
{
	Properties
	{
		_FloorTex("FloorTexture", 2D) = "white" {}
		_WaterTex ("WaterTexture", 2D) = "white" {}
		_NormalTex("NormalTexture", 2D) = "white" {}
		_CausticTex("CausticTexture", 2D) = "white" {}
		_UnderWaterColor("UnderWater Color", Color) = (0.4,0.4,0.6,1)
		_PoolHeight ("PoolHeight", Float) = 5.0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		Cull Front
		LOD 100

		Pass
		{
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertexGlobal : TEXCOORD1;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D _WaterTex;
			sampler2D _FloorTex;
			sampler2D _NormalTex;
			sampler2D _CausticTex;
			float4 _WaterTex_ST;
			float4 _UnderWaterColor;
			float _PoolHeight;
			

			float2 intersectCube(float3 origin, float3 ray, float3 cubeMin, float3 cubeMax) {
				float3 tMin = (cubeMin - origin) / ray;
				float3 tMax = (cubeMax - origin) / ray;
				float3 t1 = min(tMin, tMax);
				float3 t2 = max(tMin, tMax);
				float tNear = max(max(t1.x, t1.y), t1.z);
				float tFar = min(min(t2.x, t2.y), t2.z);
				return float2(tNear, tFar);
			}

			float3 getWallColor(float3 wallPoint) {
				float scale = 0.5;
				float3 col;
				float3 norm;
				float refr_air = 1.0;
				float refr_water = 1.33;

				//only interior, must invert normals

				// DEBUG
				//				if (abs(wallPoint.x) > 2) {
				//					return float3(1,0,0);
				//				}
				//
				//				if (abs(wallPoint.z) > 2) {
				//					return float3(1,1,0);
				//				}

				//if x boundary hit
				if (abs(wallPoint.x) > 0.999) {
					col = tex2D(_FloorTex, wallPoint.yz *0.5 + float2(1.0, 0.5)).rgb;
					norm = float3(-wallPoint.x, 0, 0);
				}
				//if z boundary hit
				else if (abs(wallPoint.z) > 0.999) {
					col = tex2D(_FloorTex, wallPoint.yx*0.5 + float2(1.0, 0.5)).rgb;
					norm = float3(0, 0, -wallPoint.z);
				}
				else {
					col = tex2D(_FloorTex, wallPoint.xz*0.5 + float2(0.5, 0.5)).rgb;
					norm = float3(0, 1, 0);
				}

				//calc refracted light and diffuse light
				float3 refr = -refract(-_WorldSpaceLightPos0, float3(0, 1, 0), refr_air / refr_water);
				float diffuse = max(0, dot(refr, norm));

				float4 water = tex2D(_NormalTex, wallPoint.xz * 0.5 + float2(0.5, 0.5));

				//only render caustic when the wall portion is below the water
				if (wallPoint.y < water.r) {

					float4 caustic = tex2D(_CausticTex, 0.75*(wallPoint.xz - wallPoint.y * refr.xz / refr.y)* 0.5 + float2(0.5, 0.5));
					scale += diffuse * caustic.r * 2.0 * caustic.g;
				}
				else {
					float2 t = intersectCube(wallPoint, refr, float3(-1, -_PoolHeight, -1.0), float3(1, 2, 1));
					//wtf is this color calc
					diffuse *= 1.0 / (1.0 + exp(-200.0 / (1.0 + 10.0 * (t.y - t.x)) * (wallPoint.y + refr.y *t.y - 2.0 / 12.0)));

					scale += diffuse * 0.5;

				}

				return col * scale;

			}


			v2f vert (appdata v)
			{
				v2f o;
				//v.vertex.y = ((1.0 - v.vertex.y) * (9.0 / 12) - 1) * _PoolHeight;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.vertexGlobal = v.vertex;

				o.uv = TRANSFORM_TEX(v.uv, _WaterTex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				float4 info = tex2D(_WaterTex,i.uv);
				float4 col = float4(getWallColor(i.vertexGlobal.xyz),1);
				if (i.vertexGlobal.y < info.r) {
					col *= _UnderWaterColor;
				}
				col.a = 1;

				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}
