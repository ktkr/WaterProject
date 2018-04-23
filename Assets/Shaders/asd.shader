// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Unlit/asd"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_MainTexWidth("Width", Float) = 256
		_MainTexLength("Length", Float) = 256
		_HeightMultiplier("HeightMultiplier", Range(0.1,0.8)) = 0.5
		_refr_index("Air Refraction Index", Float) = 1
		_refr_index_nt("Water Refraction Index", Float) = 1.33
		_DiffuseColor("Diffuse Color", Color) = (0.6,0.8,1.0,0)
		_SpecularColor("Specular Color", Color) = (0.2,0.2,0.2,0)	
		_FloorTex ("FloorTex", 2D) = "white"{}
		_CausticTex("CausticTex", 2D) = "white" {}
		_NormalTex("NormalTex",2D) = "white"{}
		_PoolHeight("Pool Height", Float) = 1.0
		_eye("Eye Position", Vector) = (1,1,1)
		_aboveWaterColor("above water color", Color) = (0.6,0.8,1.0,0)
	}
	SubShader
	{
		Tags { "Queue"="Geometry"} //"RenderType"="Transparent" }
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
				float3 normalDir : TEXCOORD1;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
				float3 vertexGlobal : TEXCOORD2;
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

			float3 getWallColor(float3 wallPoint) {
				float scale = 0.5;
				float3 col;
				float3 norm;
				float refr_air = 1.0;
				float refr_water = 1.33;
				
				//only interior, must invert normals

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
					col = tex2D(_FloorTex, wallPoint.xz*0.5 + float2(0.5,0.5)).rgb;
					norm = float3(0, 1, 0);
				}
				
				//calc refracted light and diffuse light
				float3 refr = -refract(-_WorldSpaceLightPos0, float3(0, 1, 0), refr_air / refr_water);
				float diffuse = max(0, dot(refr, norm));

				float4 water = tex2D(_NormalTex, wallPoint.xz * 0.5 + float2(0.5,0.5));

				//only render caustic when the wall portion is below the water
				if (wallPoint.y < water.r) {
					
					float4 caustic = tex2D(_CausticTex, 0.75*(wallPoint.xz - wallPoint.y * refr.xz / refr.y)* 0.5 + float2(0.5,0.5));
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

			float3 getSurfaceRayColor(float3 origin, float3 ray, float3 waterColor) {
        		float3 color;
        		if (ray.y < 2.5) {
          			float2 t = intersectCube(origin, ray, float3(-1.0, -_PoolHeight, -1.0), float3(1.0, 2.0, 1.0));
          			color = getWallColor(origin + ray * t.y);
        		} else {
          			float2 t = intersectCube(origin, ray, float3(-1.0, -_PoolHeight, -1.0), float3(1.0, 2.0, 1.0));
          			float3 hit = origin + ray * t.y;
          			if (hit.y < 2.0 / 12.0) {
            			color = getWallColor(hit);
          			} else {
          				color = float3(1,0,0); // random red
          				return waterColor;
//            			color = texCube(sky, ray).rgb;
//            			color += float3(pow(max(0.0, dot(light, ray)), 5000.0)) * float3(10.0, 8.0, 6.0);
          			}
        		}

        		if (ray.y < 0.0) color *= waterColor;
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
				
				o.normalDir = tex2Dlod(_NormalTex, float4(v.uv.xy, 0, 0));
				o.vertexGlobal = v.vertex;
				v.vertex += float4(0, temp.x*_HeightMultiplier, 0, 0);
				o.vertex = UnityObjectToClipPos(v.vertex);

				o.uv = TRANSFORM_TEX(v.uv, _MainTex);

				UNITY_TRANSFER_FOG(o, o.vertex);
				return o;
			}
			
//			fixed4 frag (v2f i) : SV_Target
//			{
//			//	float2 coordinate = i.vertex.xz;
//			//	float4 samplecol = tex2D(_MainTex,i.uv);
//
//			//	float3 norm = float3(samplecol.b, sqrt(1.0 - dot()))
//
//			//	void main() {
//			//	
//			//		vec2 coord = position.xz * 0.5 + 0.5; 
//			//		vec4 info = texture2D(water, coord); 
//			//		
//			//		/* make water look more "peaked" */
//			//		for (int i = 0; i < 5; i++) {
//			//			
//			//				coord += info.ba * 0.005; 
//			//				info = texture2D(water, coord); 
//			//		}
//			//			
//			//				vec3 normal = vec3(info.b, sqrt(1.0 - dot(info.ba, info.ba)), info.a); 
//			//				vec3 incomingRay = normalize(position - eye); 
//			//				
//			//				' + (i ? /* underwater */ '
//			//				normal = -normal; 
//			//				vec3 reflectedRay = reflect(incomingRay, normal); 
//			//				vec3 refractedRay = refract(incomingRay, normal, IOR_WATER / IOR_AIR); 
//			//				float fresnel = mix(0.5, 1.0, pow(1.0 - dot(normal, -incomingRay), 3.0)); 
//			//				
//			//				vec3 reflectedColor = getSurfaceRayColor(position, reflectedRay, underwaterColor); 
//			//				vec3 refractedColor = getSurfaceRayColor(position, refractedRay, vec3(1.0)) * vec3(0.8, 1.0, 1.1); 
//			//				
//			//				gl_FragColor = vec4(mix(reflectedColor, refractedColor, (1.0 - fresnel) * length(refractedRay)), 1.0); 
//			//				' : /* above water */ '
//			//				vec3 reflectedRay = reflect(incomingRay, normal); 
//			//				vec3 refractedRay = refract(incomingRay, normal, IOR_AIR / IOR_WATER); 
//			//				float fresnel = mix(0.25, 1.0, pow(1.0 - dot(normal, -incomingRay), 3.0)); 
//			//				
//			//				vec3 reflectedColor = getSurfaceRayColor(position, reflectedRay, abovewaterColor); 
//			//				vec3 refractedColor = getSurfaceRayColor(position, refractedRay, abovewaterColor); 
//			//				
//			//				gl_FragColor = vec4(mix(refractedColor, reflectedColor, fresnel), 1.0); 
//			//				') + '
//			//}
//
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
				float2 coord = position.xz * 0.5 + 0.5;
				float4 info = tex2D(_NormalTex, coord);
				float3 n = float3(info.b, sqrt(1.0 - dot(info.ba, info.ba)), info.a);
				float3 incomingRay = normalize(position - _WorldSpaceCameraPos.xyz);

				float3 reflectedRay = reflect(incomingRay, n);
				float3 refractedRay = refract(incomingRay, n, 1.0 / 1.33);

				float d = pow(1.0 - dot(n, -incomingRay), 3.0);
				float fresnel = (1-d)*0.25 + 1.0 * d;

				float3 reflectedColor = getSurfaceRayColor(position, reflectedRay, _aboveWaterColor.rgb);
          		float3 refractedColor = getSurfaceRayColor(position, refractedRay, _aboveWaterColor.rgb);

          		return float4(refractedColor,1);

          		float3 rgb = (1-fresnel)*refractedColor + reflectedColor * 0;

          		return float4(rgb, 0.3);
			}
			ENDCG
		}
	}
}
