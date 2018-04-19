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
		_SpecularColor("Specular Color", Color) = (0.2,0.2,0.2,0)	
		_FloorTex ("FloorTex", 2D) = "white"{}
	}
	SubShader
	{
		Tags { "Queue"="Transparent" "RenderType"="Transparent" }
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
				float3 normalDir : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float3 normalDir : TEXCOORD1;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			sampler2D _FloorTex;
			float _MainTexWidth;
			float4 _SpecularColor;
			float _MainTexLength;
			float4 _MainTex_ST;
			float _HeightMultiplier;
			float3 _transmitted;
			float _refr_index_nt;
			float _refr_index;

			bool transmittedDirection( float3 n, float3 incoming, float index_n, float index_nt)
			{
				float sqrt_val = 1 - pow(index_n, 2)*(1 - pow(dot(incoming, n), 2)) / pow(index_nt, 2);
				if (sqrt_val < 0) { return false; }
				float3 t = index_n*(incoming - n*dot(incoming, n))/index_nt - n*sqrt(sqrt_val);
				_transmitted = normalize(t);
				return true;
			}

			v2f vert (appdata_base v)
			{
				v2f o;
				float4 temp = tex2Dlod(_MainTex, float4(v.texcoord.xy,0,0));

				float du = 1.0 / _MainTexWidth;
				float dv = 1.0 / _MainTexLength;
				float3 duv = float3(du, dv, 0);
				//float v2y = tex2Dlod(_MainTex, float4(v.texcoord.x, v.texcoord.y - dv, 0, 0)).r;
				//float v3y = tex2Dlod(_MainTex, float4(v.texcoord.x - du, v.texcoord.y, 0, 0)).r;
				//float3 crossProduct = cross(float3(0, v3y - temp.r, -1), float3(-1, v2y - temp.r, 0));
				//o.normalDir = UnityObjectToWorldNormal(normalize(crossProduct));//UnityObjectToWorldNormal(crossProduct);

				float v1 = tex2Dlod(_MainTex, float4(v.texcoord.xy - duv.xz, 0,0)).y;
				float v2 = tex2Dlod(_MainTex, float4(v.texcoord.xy + duv.xz,0,0)).y;
				float v3 = tex2Dlod(_MainTex, float4(v.texcoord.xy - duv.zy,0,0)).y;
				float v4 = tex2Dlod(_MainTex, float4(v.texcoord.xy + duv.zy,0,0)).y;
				o.normalDir = normalize(float3 (v1 - v2, v3 - v4, 0.3));

				v.vertex += float4(0, temp.x*_HeightMultiplier, 0, 0);
				o.vertex = UnityObjectToClipPos(v.vertex);

				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

				UNITY_TRANSFER_FOG(o, o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				
				// sample the texture
				float4 samplecol = tex2D(_MainTex, i.uv);
				//return float4(i.normalDir, 1);
				float4 col = float4(0,0,0.2,0);
				float3 lightDir = -normalize(_WorldSpaceLightPos0).xyz;//normalize(_WorldSpaceLightPos0).xyz;
				float4 c_refl = float4 (0.5,0.5,0.7,0);
				float4 c_refr;// = float4 (0.3, 0.3, 0.5, 0);
				//float4 c_refr = tex2D(_FloorTex, (i.uv + _transmitted.xz)*0.2);
				//float3 cameraPos = float3(_ScreenParams.x,_ScreenParams.y,0);
				float3 cameraPos = _WorldSpaceCameraPos.xyz;
				//return normalize(cameraPos);
				//if (i.vertex.x - cameraPos.x < 0)
				//{
				//	return float4(0,1,0,1);
				//}
				/*float3 diffuseReflection = *_LightColor0 * c_refr * max(0.0, dot(i.normalDir, lightDir));
*/
				col.a = 0.5 + clamp(0.5*samplecol,0,1).r;
				col.r = samplecol.r*0.5;
				col.g = samplecol.g*0.5;
				
				if (transmittedDirection(i.normalDir, lightDir, _refr_index, _refr_index_nt)) {
					// Schlick stuff
					//take surface position + travel distance
					c_refr = tex2D(_FloorTex, (i.uv + _transmitted.xz*0.2));
					c_refr.a = 0;
					c_refr *= _SpecularColor;
					
					float R0 = pow( ( _refr_index_nt - _refr_index )/( _refr_index_nt + _refr_index) , 2);
					float c;
					if (_refr_index <= _refr_index_nt) {
						c = abs(dot(normalize(i.vertex.xyz - cameraPos), i.normalDir));
					}
					else {
						c = abs(dot(_transmitted, i.normalDir));
					}
					float R = R0+(1.0-R0)*pow((1.0-c),5);
					col.a = 0.5 + clamp((1 - R),0,1);
					return col + R * c_refl + (1 - R)*c_refr;
				}
				 //apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				/*if(col.a < 0.1) discard;
            	else col.a = 0.3;*/
				
				return c_refl + col;
				//return c_refl + col;
			}
			ENDCG
		}
	}
}
