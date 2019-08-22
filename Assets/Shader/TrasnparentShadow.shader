Shader "Hiden/TrasnparentShadow/TrasnparentShadow"
{
	SubShader
	{
		Tags { "RenderType" = "Opaque" }

		Pass
		{
			ZWrite On
			ColorMask 0
		}
	}

	SubShader
	{
		Tags {"Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent"}
		Pass
		{
			ZWrite Off
			Blend DstColor Zero

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;

			struct appdata_t {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 position : SV_POSITION;
				float2 texcoord : TEXCOORD0;
			};

			v2f vert(appdata_t v) {
				v2f o;
				o.position = UnityObjectToClipPos(v.vertex);
				o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
				return o;
			}

			fixed4 _Color;
			fixed4 frag(v2f i) : COLOR{
				fixed4 col = tex2D(_MainTex, i.texcoord) * _Color;
				col.rgb = lerp(col.rgb*(1 - col.a), 1, 1-col.a);
				return col;
			}

			ENDCG
		}
	}
}
