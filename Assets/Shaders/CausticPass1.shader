Shader "Unlit/CausticPass1"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
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

            const static int N = 7;
		    const static int N_HALF = 3;
		    int h = 5;
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct Pass1Out
			{
				float4 color0 : COLOR0;
				float3 color1 : COLOR1;
			};

			struct Pass1In
			{
				float2 P_C:TEXCOORD1;
				float2 P_G:TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			Pass1In vert (appdata v)
			{
				Pass1In input;
				input.P_G = v.uv;
				// refraction direction below should be from a rest heightfield a.k.a flat one
				input.P_C = input.P_G + h; //*L_refr_dir;
				return input;
				//v2f o;
				//o.vertex = UnityObjectToClipPos(v.vertex);
				//o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				//UNITY_TRANSFER_FOG(o,o.vertex);
				//return o;
			}

			float2 GetIntersection (sampler2D s, float2 coord)
			{
				fixed4 hfPos = tex2D( s, coord);
				// here we must know how to intersect the refracted light direction above to the ground plane, maybe use plane equation?
				return float2(1,0);
			}

			Pass1Out frag (Pass1In l)
			{
				Pass1Out Out;
				// initialize output intensities
				float intensity[N];

				for ( int i=0; i<N; i++ ) {
					intensity[i] = 0;
				};

				// initialize caustic-receiving pixel positions
				float P_Gy[N];
				for ( int x=-N_HALF; x<=N_HALF; x++ ) {
        			P_Gy[x+N_HALF] = l.P_G.y + x;
   				};

				// for each sample on the height field
				for ( int k=0; k<N; k++ ) {

					// find the intersection with the ground plane
					float2 pN = l.P_C + ( k - N_HALF ) * float2(1,0);
					// MainTex should contain refracted light direction from the current heightfield
					float2 intersection = GetIntersection( _MainTex, pN );

					// ax is the overlapping distance along x-direction
					float ax = max(0, 1 - abs(l.P_G.x - intersection.x));

					// for each caustic-receiving pixel position
					for ( int j=0; j<N; j++ ) {
						// ay is the overlapping distance along y-direction
						float ay = max(0, 1 - abs(P_Gy[j] - intersection.y));

						// increase the intensity by the overlapping area
						intensity[j] += ax*ay;
					}
				}
				// copy the output intensities to the color channels
				Out.color0 = float4( intensity[0], intensity[1],
				intensity[2], intensity[3] );
				Out.color1 = float3( intensity[4], intensity[5],
				intensity[6] );
				return Out;
			}
			
			//fixed4 frag (v2f i) : SV_Target
			//{
				// sample the texture
				//fixed4 col = tex2D(_MainTex, i.uv);
				// apply fog
				//UNITY_APPLY_FOG(i.fogCoord, col);
				//return col;
			//}
			ENDCG
		}
	}
}
