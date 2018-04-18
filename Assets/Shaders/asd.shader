Shader "Unlit/asd"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_HeightMultiplier ("HeightMultiplier", Range(0.1,0.5)) = 0.5
		_refr_index ("Air Refraction Index", Float) = 1
		_refr_index_nt ("Water Refraction Index", Float) = 1.33
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
			float4 _MainTex_ST;
			float _HeightMultiplier;
			float3 _transmitted;
			float _refr_index_nt;
			float _refr_index;

			bool transmittedDirection( float3 n, float3 incoming, float index_n, float index_nt)
			{
				float sqrt_val = 1 - pow(index_n, 2)*(1 - pow(dot(incoming, n), 2)) / pow(index_nt, 2);
				if (sqrt_val < 0) { return false; }
				float t = index_n*(incoming - n*dot(incoming, n))/index_nt - n*sqrt(sqrt_val);
				_transmitted = normalize(t);
				return true;
			}

			v2f vert (appdata_base v)
			{
				v2f o;
				float4 temp = tex2Dlod(_MainTex, float4(v.texcoord.xy,0,0));
				v.vertex += float4(0, temp.x*_HeightMultiplier, 0, 0);
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.normalDir = normalize(v.normal);
				UNITY_TRANSFER_FOG(o, o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				float4 col = tex2D(_MainTex, i.uv);
				col += float4(0,0,0,0);
            	float3 lightDir = normalize(_WorldSpaceLightPos0).xyz;
				float4 c_refl = float4 (1,1,1,0);
				float4 c_refr = float4 (0,0,1,0);
				float3 cameraPos = _WorldSpaceCameraPos;
				if (transmittedDirection(i.normalDir, lightDir, _refr_index, _refr_index_nt)) {
					// Schlick stuff
					float R0 = pow( ( _refr_index_nt - _refr_index )/( _refr_index_nt + _refr_index) , 2);
					float c;
					if (_refr_index <= _refr_index_nt) {
						c = abs(dot(normalize(i.vertex - cameraPos), i.normalDir));
					}
					else {
						c = abs(dot(_transmitted, i.normalDir));
					}
					float R = R0+(1.0-R0)*pow((1.0-c),5);

					return col + R * c_refl + (1 - R)*c_refr;
				}
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				if(col.a < 0.1) discard;
            	else col.a = 0.3;
				//return col;
				return c_refl + col;
			}
			ENDCG
		}
	}
}
