// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Water/asd"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_MainTexWidth("Width", Float) = 256
		_MainTexLength("Length", Float) = 256
		_HeightMultiplier("HeightMultiplier", Range(0.1,0.8)) = 0.5
		_refr_index("Air Refraction Index", Float) = 1
		_refr_index_nt("Water Refraction Index", Float) = 1.33
		_DiffuseColor("Diffuse Color", Color) = (0.2,0.2,1.0,0)
		_SpecularColor("Specular Color", Color) = (0.5,0.5,0.5,0)	
		_FloorTex ("FloorTex", 2D) = "white"{}
		_CausticTex("CausticTex", 2D) = "white" {}
		_NormalTex("NormalTex",2D) = "white"{}
		_PoolHeight("Pool Height", Float) = 5.0
		_eye("Eye Position", Vector) = (1,1,1)
		_aboveWaterColor("above water color", Color) = (0.6,0.8,1.0,0)
		_numUniqueXTiles("Number of tiles along the width", Range(1,10)) = 4
		_numUniqueYTiles("Number of tiles along the height", Range(1,10)) = 3
	}
	SubShader
	{
		Tags { "Queue"="Transparent"} //"RenderType"="Transparent" }
		Blend SrcAlpha OneMinusSrcAlpha
        AlphaTest Greater 0.1
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			struct appdata
			{
				float4 vertex : POSITION;
				//float3 normalDir : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float3 normalDir : TEXCOORD2;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
				float3 vertexGlobal : TEXCOORD1;
			};

			sampler2D _MainTex;
			sampler2D _FloorTex;
			sampler2D _CausticTex;
			sampler2D _NormalTex;
			float _MainTexWidth;
			float4 _SpecularColor;
			float4 _DiffuseColor;
			float _MainTexLength;
			float4 _MainTex_ST;
			float _HeightMultiplier;
			float3 _transmitted;
			float _refr_index_nt;
			float _refr_index;
			float _numUniqueXTiles;
			float _numUniqueYTiles;
			float _PoolHeight;
			float3 _eye;
			float4 _aboveWaterColor;

			bool transmittedDirection( float3 n, float3 incoming, float index_n, float index_nt)
			{
				float sqrt_val = 1 - pow(index_n, 2)*(1 - pow(dot(incoming, n), 2)) / pow(index_nt, 2);
				if (sqrt_val < 0) { return false; }
				float3 t = index_n*(incoming - n*dot(incoming, n))/index_nt - n*sqrt(sqrt_val);
				_transmitted = normalize(t);
				return true;
			}


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
			float3 getWallColor(float2 wallPoint, int face, float height, float4 water, float3 waterNorm) {
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


				//floor
				if (face == 6) {

					col = tex2D(_FloorTex, float2(wallPoint.x*xoff + xoff, wallPoint.y*yoff + yoff));
					norm = float3(0, -1, 0);

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
					float2 t = intersectCube(float3(wallPoint, face), refr, float3(-5, -_PoolHeight, -5.0), float3(5, _PoolHeight, 5));
					//TODO the 7/12 should be changed to the height of the cube
					diffuse *= 1.0 / (1.0 + exp(-200.0 / (1.0 + 10.0 * (t.y - t.x)) * (height + refr.y *t.y - 2.5)));

					scale += diffuse * 0.5;

				}

				return col * scale;

			}
			//assume pool is centered at 0, cube is scaled to 10x5x10
			int getFace(float3 hit) {
				if (hit.x > 4.99) {
					return 2;
				}

				else if (hit.x < -4.99) {
					return 5;
				}
				else if (hit.z > 4.99) {
					return 3;
				}
				else if (hit.z < -4.99) {
					return 4;
				}
				//floor
				else if (hit.y < -4.99) {
					return 6;
				}
				//ceiling
				else if (hit.y > 4.99) {
					return 1;
				}

				return 0;
				//else if (hit.x < -4.99) {
				//	return 
				//}

			}


			float3 getSurfaceRayColor(float3 origin, float3 ray, float3 waterColor,float3 norm) {
				float3 color = float3(0, 0, 0);
				
//        		if (ray.y < -0.8) {
//        			return (1,0,1);
//        		}
				float2 t = intersectCube(origin, ray, float3(-5.0, -_PoolHeight, -5.0), float3(5.0, _PoolHeight, 5.0));
				//color = getWallColor(origin + ray * t.y);
				float3 hit = origin + ray * t.y;
				int face = getFace(hit);
				//reflections and refractions
				//sorry... this is hard-coded due to lack of time. there's a face order mistake.
				
				if (face == 1) {
					color = getWallColor(float2(-hit.x + 5,-hit.z+5)*0.1, face, (hit.y + 5)*0.1, float4(origin, 1), norm);
				}
				else if (face == 2) {
					color = getWallColor(float2(hit.z + 5, hit.y + 5)*0.1, 3, (hit.x + 5)*0.1, float4(origin, 1), norm);
				}
				else if (face == 3) {
					color = getWallColor(float2(5-hit.x, hit.y + 5)*0.1, 2, (hit.x + 5)*0.1, float4(origin, 1), norm);
				}
				else if (face == 4) {
					color = getWallColor(float2(-hit.x + 5, -hit.y + 5)*0.1, 5, (hit.x + 5)*0.1, float4(origin, 1), norm);
				}
				else if (face == 5) {
					color = getWallColor(float2(-hit.z + 5, hit.y + 5)*0.1, 4, (hit.x + 5)*0.1, float4(origin, 1), norm);
				}
				else if (face == 6) {
					color = getWallColor(float2(hit.x + 5, hit.z + 5)*0.1, face, (hit.x + 5)*0.1, float4(origin, 1), norm);
				}
				
					//color *= 10;
				
				
				//use different hit.xz,hit.xy etc values to compute uv then done.
				/*if (face == 2) {
					color = getWallColor(float2(hit.y + 5, hit.z + 5)*0.1,face, (hit.x + 5)*0.1, float4(origin, 1), norm);
				}
				else if (face == 3) {
					color = getWallColor(float2(hit.z + 5, -hit.y + 5)*0.1, face, (hit.y + 5)*0.1, float4(origin, 1), norm);
				}*/
				//if (face == 2 || face == 5) {
				//	color = getWallColor((hit.xz + 5)*0.1, face, (hit.y + 5)*0.1, float4(origin, 1), norm);
				//}
				//else if (face == 3 || face == 4) {
				//	color = getWallColor((hit.zx + 5)*0.1, face, (hit.y + 5)*0.1, float4(origin, 1), norm);
				//}
				//else if (face == 6){
				//	color = getWallColor(float2(-hit.x + 5,hit.z+5)*0.1, face, (hit.y + 5)*0.1, float4(origin, 1), norm);
				//}
				//else if (face == 1) {
				//	//color = getWallColor((hit.xz - 5)*0.1, face, (hit.y + 5)*0.1, float4(origin, 1), norm)*1.5;
				//	color = getWallColor((hit.xz + 5)*0.1, 1, (hit.y + 5)*0.1, float4(origin, 1), norm)*10;
				//}
				//if going into water
				if (ray.y < 0.0) {
					color *= waterColor;
				}
				
				return color;

      		}

			v2f vert (appdata v)
			{
				v2f o;
				float4 temp = tex2Dlod(_MainTex, float4(v.uv.xy,0,0));

				float du = 1.0 / _MainTexWidth;
				float dv = 1.0 / _MainTexLength;
				float3 duv = float3(du, dv, 0);
				//float v2y = tex2Dlod(_MainTex, float4(v.texcoord.x, v.texcoord.y - dv, 0, 0)).r;
				//float v3y = tex2Dlod(_MainTex, float4(v.texcoord.x - du, v.texcoord.y, 0, 0)).r;
				//float3 crossProduct = cross(float3(0, v3y - temp.r, -1), float3(-1, v2y - temp.r, 0));
				//o.normalDir = UnityObjectToWorldNormal(normalize(crossProduct));//UnityObjectToWorldNormal(crossProduct);

				//float v1 = tex2Dlod(_MainTex, float4(v.texcoord.xy - duv.xz, 0,0)).y;
				//float v2 = tex2Dlod(_MainTex, float4(v.texcoord.xy + duv.xz,0,0)).y;
				//float v3 = tex2Dlod(_MainTex, float4(v.texcoord.xy - duv.zy,0,0)).y;
				//float v4 = tex2Dlod(_MainTex, float4(v.texcoord.xy + duv.zy,0,0)).y;
				//o.normalDir = UnityObjectToWorldNormal(normalize(float3 (v1 - v2, v3 - v4, 0.5)));
				

				o.normalDir = UnityObjectToWorldNormal(tex2Dlod(_NormalTex, float4(v.uv.xy, 0, 0)));
				v.vertex.y += temp.r;
				v.vertex.y *= _HeightMultiplier;
				//v.vertex.y *= _HeightMultiplier;
				//v.vertex += float4(0, temp.r*_HeightMultiplier, 0, 0);
				o.vertexGlobal = v.vertex;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);

				UNITY_TRANSFER_FOG(o, o.vertex);
				return o;
			}

//				//return float4(i.normalDir,1.0)	;
//				// sample the texture
//				float4 samplecol = tex2D(_MainTex, i.uv)* _DiffuseColor;
//				//return float4(i.normalDir, 1);
//				float4 col = float4(0,0,0.2,0);
//				float3 lightDir = normalize(_WorldSpaceLightPos0).xyz;//normalize(_WorldSpaceLightPos0).xyz;
//				float4 c_refl = float4 (0.7,0.7,0.7,0);
//				float4 c_refr = float4 (0.5, 0.5, 0.7, 0);
//				//float4 c_refr = tex2D(_FloorTex, (i.uv + _transmitted.xz)*0.2);
//				//float3 cameraPos = float3(_ScreenParams.x,_ScreenParams.y,0);
//				float3 cameraPos = _WorldSpaceCameraPos.xyz;
//				//return normalize(cameraPos);
//				//if (i.vertex.x - cameraPos.x < 0)
//				//{
//				//	return float4(0,1,0,1);
//				//}
//				//float3 diffuseReflection = *_LightColor0 * c_refr * max(0.0, dot(i.normalDir, lightDir));
//
//				col.a = 0.5 + clamp(0.5*samplecol,0,1).r;
//				/*col.r = samplecol.r*0.5;
//				col.g = samplecol.g*0.5;
//				*/
//				col.r = samplecol.r;
//				col.g = samplecol.g;
//
//				if (transmittedDirection(i.normalDir, lightDir, _refr_index, _refr_index_nt)) {
//					// Schlick stuff
//					//take surface position + travel distance
//					//c_refr = tex2D(_FloorTex, (i.uv + _transmitted.xz*0.05));
//					//c_refr.a = 0;
//					//c_refr *= _SpecularColor;
//					
//					float R0 = pow( ( _refr_index_nt - _refr_index )/( _refr_index_nt + _refr_index) , 2);
//					float c;
//					if (_refr_index <= _refr_index_nt) {
//						c = abs(dot(normalize(i.vertex.xyz - cameraPos), i.normalDir));
//					}
//					else {
//						c = abs(dot(_transmitted, i.normalDir));
//					}
//					float R = R0+(1.0-R0)*pow((1.0-c),5);
//					//col.a = 0.5 + clamp((1 - R),0,1);
//					return col + (R * c_refl + (1 - R)*c_refr)*_SpecularColor;
//				}
//				 //apply fog
//				UNITY_APPLY_FOG(i.fogCoord, col);
//				/*if(col.a < 0.1) discard;
//            	else col.a = 0.3;*/
//				
//				return c_refl*_SpecularColor + col;
//				//return c_refl + col;
//			}

			fixed4 frag (v2f i) : SV_Target
			{
				float3 position = i.vertexGlobal;
				float2 coord = i.uv.xy;//position.xz * 0.5 + 0.5;
				float4 info = tex2D(_NormalTex, coord);
				float4 waveCol = tex2D(_MainTex, i.uv);// i.vertexGlobal.xy;//(i.vertexGlobal,0);
				float3 n = normalize(info.rgb);
				//float3 n = float3(info.b, sqrt(1.0 - dot(info.ba, info.ba)), info.a);
				float3 incomingRay = mul(unity_WorldToObject, float4(normalize(position - _WorldSpaceCameraPos.xyz),1)).xyz;//float4(normalize(position - _WorldSpaceCameraPos.xyz),1).xyz;
				//if (waterHeight.r > 1) {
				//	return float4(1, 0, 0, 1);
				//}
				float3 reflectedRay = reflect(incomingRay, n);
				float3 refractedRay = refract(incomingRay, n, 1.0 / 1.33);
				float R0 =  pow((1/7), 2);
				//TODO set c value if nt > n as well.
				float c = abs(dot(incomingRay, n));
				float fresnel = R0 + (1.0 - R0)*pow((1.0 - c), 5);
				//float d = pow(1.0 - dot(n, -incomingRay), 3.0);
				//float fresnel = (1-d)*0.25 + 1.0 * d;
				//c = abs(dot(normalize(i.vertexGlobal.xyz - cameraPos), i.normalDir));
				
				float3 reflectedColor = getSurfaceRayColor(position, reflectedRay, _aboveWaterColor.rgb,n);
          		float3 refractedColor = getSurfaceRayColor(position, refractedRay, _aboveWaterColor.rgb,n);
				//reflectedColor = float3(0, 0, 0);
				//refractedColor = float3(0, 0, 0);
				//AMBIENT HACK by me
				//waterHeight *= float4(0.0001,0.0001,0.0,1.0);
				
				//float ndotl = dot(n, -_WorldSpaceLightPos0);
          		float3 rgb = waveCol.rgb*0.1 + _DiffuseColor.rgb + ((1-fresnel)*refractedColor.rgb + reflectedColor.rgb*fresnel)*_SpecularColor.rgb;

          		return float4(rgb, 1.0);

				//return float4(i.normalDir,1.0)	;
				// sample the texture
//				float4 samplecol = tex2D(_MainTex, i.uv)* _DiffuseColor;
//				//return float4(i.normalDir, 1);
//				float4 col = float4(0,0,0.2,0);
//				float3 lightDir = normalize(_WorldSpaceLightPos0).xyz;//normalize(_WorldSpaceLightPos0).xyz;
//				float4 c_refl = float4 (0.7,0.7,0.7,0);
//				float4 c_refr = float4 (0.5, 0.5, 0.7, 0);
//				//float4 c_refr = tex2D(_FloorTex, (i.uv + _transmitted.xz)*0.2);
//				//float3 cameraPos = float3(_ScreenParams.x,_ScreenParams.y,0);
//				float3 cameraPos = _WorldSpaceCameraPos.xyz;//_WorldSpaceCameraPos.xyz;
//				//return float4(0,i.globalVertex.z,0,1);
//				//return normalize(cameraPos);
//				//if (i.vertex.x - cameraPos.x < 0)
//				//{
//				//	return float4(0,1,0,1);
//				//}
//				/*float3 diffuseReflection = *_LightColor0 * c_refr * max(0.0, dot(i.normalDir, lightDir));
//*/
//				col.a = 0.5 + clamp(0.5*samplecol,0,1).r;
//				/*col.r = samplecol.r*0.5;
//				col.g = samplecol.g*0.5;
//				*/
//				col.r = samplecol.r;
//				col.g = samplecol.g;
//
//				if (transmittedDirection(i.normalDir, lightDir, _refr_index, _refr_index_nt)) {
//					// Schlick stuff
//					//take surface position + travel distance
//					//c_refr = tex2D(_FloorTex, (i.uv + _transmitted.xz*0.05));
//					//c_refr.a = 0;
//					//c_refr *= _SpecularColor;
//					
//					float R0 = pow( ( _refr_index_nt - _refr_index )/( _refr_index_nt + _refr_index) , 2);
//					float c;
//					if (_refr_index <= _refr_index_nt) {
//						c = abs(dot(normalize(i.vertexGlobal.xyz - cameraPos), i.normalDir));
//					}
//					else {
//						c = abs(dot(_transmitted, i.normalDir));
//					}
//					float R = R0+(1.0-R0)*pow((1.0-c),5);
//					//col.a = 0.5 + clamp((1 - R),0,1);
//					col.a = 0.2 + R;
//					return col + (R * c_refl + (1 - R)*c_refr)*_SpecularColor;
//				}
//				 //apply fog
//				UNITY_APPLY_FOG(i.fogCoord, col);
//				/*if(col.a < 0.1) discard;
//            	else col.a = 0.3;*/
//				
//				return c_refl*_SpecularColor + col;
//				//return c_refl + col;

			}
			ENDCG
		}
	}
}
