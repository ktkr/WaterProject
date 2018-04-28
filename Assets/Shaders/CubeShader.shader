Shader "Unlit/CubeShader"
{
	Properties
	{
		_FloorTex("FloorTexture", 2D) = "white" {}
		_WaterTex ("WaterTexture", 2D) = "white" {}
		_NormalTex("NormalTexture", 2D) = "white" {}
		_CausticTex("CausticTexture", 2D) = "white" {}
		_UnderWaterColor("UnderWater Color", Color) = (0.4,0.4,0.6,1)
		_PoolHeight("PoolHeight", Float) = 5.0
		_numUniqueXTiles("Number of tiles along the width", Range(1,10)) = 4
		_numUniqueYTiles("Number of tiles along the height", Range(1,10)) = 3
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
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float3 vertexGlobal : TEXCOORD1;
				float3 normalDir: TEXCOORD2;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D _FloorTex;
			float4 _FloorTex_ST;
			sampler2D _WaterTex;
			sampler2D _NormalTex;
			sampler2D _CausticTex;
			float _numUniqueXTiles;
			float _numUniqueYTiles;
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

			//get the texture required using global vertex values
			float3 getWallColor(float2 wallPoint,int face,float height,float4 water,float3 waterNorm) {
				float scale = 0.5;
				float3 col = float3(0, 0, 0);
				float3 norm = float3(0, 1, 0);
				float refr_air = 1.0;
				float refr_water = 1.33;
				float xoff = 1.0 / _numUniqueXTiles;
				float yoff = 1.0 / _numUniqueYTiles;
				//only interior, must invert normals

				// DEBUG
				//				if (abs(wallPoint.x) > 2) {
				//					return float3(1,0,0);
				//				}
				//
				//				if (abs(wallPoint.z) > 2) {
				//					return float3(1,1,0);
				//				}


				//wtf did we manage to do!?!
				//if x boundary hit
				//if (abs(wallPoint.x) > 0.499) {
				//	//col = tex2D(_FloorTex, wallPoint.yz*0.5 + float2(1.0,0.5));// *0.5 + float2(1.0, 0.5)).rgb;
				//	col = tex2D(_FloorTex, wallPoint.yz);
				//	norm = float3(-wallPoint.x, 0, 0);
				//}
				////if z boundary hit
				//else if (abs(wallPoint.z) > 0.499) {
				//	col = tex2D(_FloorTex, wallPoint.yx);// *0.5 + float2(1.0, 0.5)).rgb;
				//	norm = float3(0, 0, -wallPoint.z);
				//}
				//else {
				//	col = tex2D(_FloorTex, wallPoint.xz);//*0.5 + float2(0.5, 0.5)).rgb;
				//	if (abs(wallPoint.y) > 0.499) {
				//		norm = float3(0, -1, 0);
				//	}
				//	else {
				//		norm = float3(0, 1, 0);
				//	}
				//}
				
				//floor
				if (face == 6) {

					col = tex2D(_FloorTex, float2(wallPoint.x*xoff + xoff, wallPoint.y*yoff + yoff));
					norm = float3(0,-1, 0);

				}

				//walls
				else if (face > 1) {

					//col = tex2D(_FloorTex, float2(wallPoint.x * xoff + xoff * (wallPoint.z - 1), wallPoint.y*(yoff)+yoff));
					if (face == 2) {
						col = tex2D(_FloorTex, float2(wallPoint.x * xoff + xoff, wallPoint.y*yoff));
						norm = float3(0, 0, -1);
					}
					//back wall
					else if (face == 3) {
						col = tex2D(_FloorTex, float2(wallPoint.x*xoff, wallPoint.y*yoff + yoff));
						norm = float3(-1, 0, 0);
					}
					//front wall
					else if (face == 4) {
						col = tex2D(_FloorTex, float2(wallPoint.x*xoff + (xoff * 2), wallPoint.y*yoff + yoff));
						norm = float3(1, 0, 0);
					}

					else if (face == 5) {
						col = tex2D(_FloorTex, float2(1 - (wallPoint.x*xoff + (xoff * 2)), 1 - (wallPoint.y*yoff)));
						norm = float3(0, 0, 1);
					}

				}
				//ceiling
				else if (face == 1) {
					col = tex2D(_FloorTex, float2(wallPoint.x * xoff + xoff * 3, wallPoint.y*(yoff)+yoff));
					norm = float3(0, 1, 0);
				}


				/*col = tex2D(_FloorTex, wallPoint.xy);
				norm = float3(0, 1, 0);*/
				//float4 normal123 = tex2D(_NormalTex, wallPoint.xy);
				//calc refracted light and diffuse light
				float3 refr = -refract(-_WorldSpaceLightPos0, waterNorm, refr_air / refr_water);
				float diffuse = max(0, dot(refr, norm.xyz));

				//float4 water = tex2D(_WaterTex, wallPoint.xy);// * 0.5 + float2(0.5, 0.5));

				//only render caustic when the wall portion is below the water
				if (height < water.g*0.05) {

					float4 caustic = tex2D(_CausticTex, 0.75*(wallPoint.xy - wallPoint.y * refr.xz / refr.y)* 0.5 + float2(0.5, 0.5));
					scale += diffuse * caustic.r * 2.0 * caustic.g;
					
				}
				else {
					float2 t = intersectCube(float3(wallPoint,face), refr, float3(-5, -_PoolHeight, -5.0), float3(5, 5, 5));
					//wtf is this color calc
					diffuse *= 1.0 / (1.0 + exp(-200.0 / (1.0 + 10.0 * (t.y - t.x)) * (height + refr.y *t.y - 2.5)));

					scale += diffuse * 0.5;

				}

				return col * scale;

			}


			v2f vert (appdata v)
			{
				v2f o;
				//v.vertex.y = ((1.0 - v.vertex.y) * (9.0 / 12) - 1) * _PoolHeight;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.vertexGlobal = v.vertex.xyz;
				o.normalDir = v.normal;
				o.uv = TRANSFORM_TEX(v.uv, _FloorTex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{

				int face = 1;
				float4 info;
				float3 waterNorm;
				//floor
				if (i.normalDir.y > 0.999) {
					face = 1;
					info = tex2D(_WaterTex, float2(i.vertexGlobal.x, i.vertexGlobal.z));
					waterNorm = tex2D(_NormalTex, float2(i.vertexGlobal.x, i.vertexGlobal.z));
				}
				//ceiling
				else if (i.normalDir.y < -0.999) {
					face = 6;
					info = tex2D(_WaterTex, float2(i.vertexGlobal.x, i.vertexGlobal.z));
					waterNorm = tex2D(_NormalTex, float2(i.vertexGlobal.x, i.vertexGlobal.z));
				}
				//back wall
				else if (i.normalDir.z > 0.999) {
					face = 2;
					info = tex2D(_WaterTex, float2(i.vertexGlobal.x - 0.5, 0));
					waterNorm = tex2D(_NormalTex, float2(i.vertexGlobal.x - 0.5, 0));
				}
				//front wall
				else if (i.normalDir.z < -0.999) {
					face = 5;
					info = tex2D(_WaterTex, float2(i.vertexGlobal.x - 0.5, 1));
					waterNorm = tex2D(_NormalTex, float2(i.vertexGlobal.x - 0.5, 1));
				}
				//right wall
				else if (i.normalDir.x > 0.999) {
					face = 3;
					info = tex2D(_WaterTex, float2(0, i.vertexGlobal.z - 0.5));
					waterNorm = tex2D(_NormalTex, float2(0, i.vertexGlobal.z - 0.5));
				}
				//left wall
				else if (i.normalDir.x < -0.999) {
					face = 4;
					info = tex2D(_WaterTex, float2(1, i.vertexGlobal.z - 0.5));
					waterNorm = tex2D(_NormalTex, float2(1, i.vertexGlobal.z - 0.5));
				}
				else {
					face = 1;
					info = tex2D(_WaterTex, float2(i.vertexGlobal.x, i.vertexGlobal.z));
					waterNorm = tex2D(_NormalTex, float2(i.vertexGlobal.x, i.vertexGlobal.z));
				}
				

				float4 col = float4(getWallColor(i.uv.xy,face, i.vertexGlobal.y, info, waterNorm), 1);

				if (i.vertexGlobal.y < info.g*0.05) {
					col *= _UnderWaterColor;
				}
				/*if (i.vertexGlobal.y< info.r) {
					col *= _UnderWaterColor;
				}*/
				

				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}
