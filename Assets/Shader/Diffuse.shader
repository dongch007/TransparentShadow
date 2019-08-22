Shader "TransparentShadow/Diffuse" {
	Properties{
		_Color("Main Color", Color) = (1,1,1,1)
		_MainTex("Base (RGB)", 2D) = "white" {}
	}
	
	SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 200

		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase nolightmap novertexlight noshadow
			#pragma multi_compile _ SHADOW_ON

			#define UNITY_PASS_FORWARDBASE
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			struct v2f
			{
				UNITY_POSITION(pos);
				float2 uv0 : TEXCOORD0; // _MainTex
				float3 worldPos : TEXCOORD1;
				fixed3 vlight : TEXCOORD2; // ambient/SH/vertexlights
				half3 worldNormal : TEXCOORD3;
			};

			float4 _MainTex_ST;

			float4x4  _ShadowMatrix;

			// vertex shader
			v2f vert(appdata_full v)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);

				o.uv0 = TRANSFORM_TEX(v.texcoord, _MainTex);

				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

				o.pos = UnityWorldToClipPos(worldPos);
				o.worldPos = worldPos;

				float3 worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldNormal = worldNormal;

				// SH/ambient and vertex lights
				#ifdef LIGHTPROBE_SH
					float3 shlight = ShadeSH9(float4(worldNormal, 1.0));
					o.vlight = shlight;
				#else
					o.vlight = 0.0;
				#endif

				return o;
			}

			sampler2D _MainTex;
			fixed4 _Color;

			sampler2D _CustomDepthTexture;
			sampler2D _TransparentTexture;



			// fragment shader
			fixed4 frag(v2f IN) : SV_Target
			{
				fixed4 albedo = tex2D(_MainTex, IN.uv0);
				albedo *= _Color;// * IN.color;

				float3 worldPos = IN.worldPos;

				UNITY_LIGHT_ATTENUATION(atten, IN, worldPos)

				half3 shadowCol = 1;
#ifdef SHADOW_ON
					float4 shadowSpacePos = mul(_ShadowMatrix, float4(worldPos, 1.0));
					float depth = tex2Dproj(_CustomDepthTexture, UNITY_PROJ_COORD(shadowSpacePos)).r;
					if ((shadowSpacePos.z / shadowSpacePos.w) < depth)
						shadowCol = 0;
					else
						shadowCol = tex2Dproj(_TransparentTexture, UNITY_PROJ_COORD(shadowSpacePos));
#endif


				fixed4 c = 0;

				fixed3 worldNormal = IN.worldNormal;

				//vertexlight
				c.rgb += albedo * IN.vlight;

				// realtime lighting: call lighting function
				#ifndef USING_DIRECTIONAL_LIGHT
					fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				#else
					fixed3 lightDir = _WorldSpaceLightPos0.xyz;
				#endif
				fixed diffuse = max(0, dot(worldNormal, lightDir));
				c.rgb += (albedo * _LightColor0.rgb) * (diffuse * shadowCol * atten);

				return c;
			}
			ENDCG
		}
	}
}