Shader "Unlit/HeightFieldShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_HeightMap("Heightmap (R)", 2D) = "grey" {}
		_HeightmapDimX("Heightmap Width", Float) = 2048
		_HeightmapDimY("Heightmap Height", Float) = 2048

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
			//#pragma multi_compile_fog
			#pragma glsl
			
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

			sampler2D _MainTex, _HeightMap;
			float4 _MainTex_ST;
			float _HeightmapDimY, _HeightmapDimX;


			v2f vert (appdata v)
			{
				v2f o;

				float4 info = tex2Dlod(_HeightMap, float4(v.uv.x,v.uv.y,0,1));

				float spd = (
					tex2Dlod(_HeightMap, float4(v.uv.x, (v.uv.y + 1.0 / _HeightmapDimY),0,0)).g +
					tex2Dlod(_HeightMap, float4(v.uv.x, (v.uv.y - 1.0 / _HeightmapDimY),0,0)).g +
					tex2Dlod(_HeightMap, float4((v.uv.x + 1.0/ _HeightmapDimX), v.uv.y,0,0)).g +
					tex2Dlod(_HeightMap, float4((v.uv.x - 1.0/ _HeightmapDimX), v.uv.y,0,0)).g
					)* 0.25;
				info.g = (info.g + (spd - v.vertex) * 2.0) * 0.995;
				info.r += info.g;
				o.vertex = v.vertex;
				o.vertex = UnityObjectToClipPos(o.vertex);
				o.uv = v.uv;
				//o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				//UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				return fixed4(i.vertex.xy / _ScreenParams.xy,0.0,1.0);
				//fixed4 col = tex2D(_MainTex, i.uv);
				//float4 col = i.uv;
				// apply fog
				//UNITY_APPLY_FOG(i.fogCoord, col);
				//return col;
			}
			ENDCG
		}
	}
}
