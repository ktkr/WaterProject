Shader "Unlit/FakeCausticShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_MainTex ("TextureWidth", Float) = 256
		_MainTex ("TextureLength",Float) = 256
		_BaseTex ("BaseTexture", 2D) = "white" {}
		_DiffuseCol ("Diffuse Color", Color) = (0.5,0.5,1,1)
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
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
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			sampler2D _BaseTex;
			float _MainTexWidth;
			float _MainTexLength;
			float4 _MainTex_ST;
			float4 _DiffuseCol;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				float4 col = tex2D(_MainTex, i.uv);

				float du = 1.0 / _MainTexWidth;
				float dv = 1.0 / _MainTexLength;
				float3 duv = float3(du, dv, 0);
				float4 colx1 = tex2D(_MainTex, i.uv - duv.zy);
				float4 colx2 = tex2D(_MainTex, i.uv + duv.zy);
				float4 coly1 = tex2D(_MainTex, i.uv - duv.xz);
				float4 coly2 = tex2D(_MainTex, i.uv + duv.xz);

				float4 avCol = (col*0.5 + colx1*0.125 + colx2*0.125 + coly1*0.125 + coly2*0.125) *0.2;
				//float4 avCol = (col*0.5 + colx1 * 0.125 + colx2 * 0.125 + coly1 * 0.125 + coly2 * 0.125);
				float4 basecol = tex2D(_BaseTex, i.uv);
				
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				return avCol + basecol * _DiffuseCol;
			}
			ENDCG
		}
	}
}
