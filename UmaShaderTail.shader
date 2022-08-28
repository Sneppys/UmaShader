
Shader "Uma/Tail" {
    Properties {
        _MainTex ("Diffuse (_diff)", 2D) = "white" {}
        _ShadTex ("Shaded (_shad_c)", 2D) = "black" {}
        _OutlineWidth ("Outline Width", float) = 1.0
        [HideInInspector] _OutlineColor ("Outline Color", Color) = (0.125,0.047,0,0.098)
    }
    SubShader {
        Tags {
            "RenderType"="Transparent"
            "VRCFallback"="ToonCutout"
        }

        Pass {
            Name "Forward"
            Tags {
                "LightMode"="ForwardBase"
            }
            Cull Back

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"

            // Standard diffuse
            uniform sampler2D _MainTex;
            uniform float4 _MainTex_ST;
            // Shaded version of diffuse
            uniform sampler2D _ShadTex;
            uniform float4 _ShadTex_ST;

            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 texcoord0 : TEXCOORD0;
            };
            struct VertexOutput {
                float4 pos: SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float4 posWorld : TEXCOORD1;
                float3 normalDir : TEXCOORD2;
            };

            VertexOutput vert (VertexInput v) {
                VertexOutput o;
                o.uv0 = v.texcoord0;
                o.pos = UnityObjectToClipPos(v.vertex.xyz);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                o.normalDir = UnityObjectToWorldNormal(v.normal);
                TRANSFER_VERTEX_TO_FRAGMENT(o)
                return o;
            }

            float4 frag (VertexOutput i): COLOR {
                float4 diff = tex2D(_MainTex, TRANSFORM_TEX(i.uv0, _MainTex));
                float4 shad = tex2D(_ShadTex, TRANSFORM_TEX(i.uv0, _ShadTex));

                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                float facing = dot(i.normalDir, viewDirection);

                // Lighting
                float3 defaultLightDirection = normalize(UNITY_MATRIX_V[2].xyz + UNITY_MATRIX_V[1].xyz);
                float3 lightDirection = normalize(lerp(defaultLightDirection, _WorldSpaceLightPos0.xyz, any(_WorldSpaceLightPos0.xyz)));
                // float3 lightDirection = normalize(lerp(_WorldSpaceLightPos0.xyz, _WorldSpaceLightPos0.xyz - i.posWorld.xyz, _WorldSpaceLightPos0.w));
                float halfLambert = 0.5 * dot(i.normalDir, lightDirection) + 0.5;
                float shadowLerp = saturate(1 + ((2 * halfLambert - 0.2) * 100));
                float3 lightColor = saturate(max(_LightColor0, max(ShadeSH9(half4(0, 0, 0, 1)).rgb, ShadeSH9(half4(0, -1, 0, 1)).rgb)));
                float4 shadedDiff = lerp(shad, diff, shadowLerp) * fixed4(lightColor, 1);

                return shadedDiff;
            }

            ENDCG
        }

        Pass {
            Name "Outline"
            Tags {
            }
            Offset 1, 1
            Cull Front

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            uniform sampler2D _MainTex;
            uniform float4 _MainTex_ST;

            uniform float _OutlineWidth;
            uniform float4 _OutlineColor;

            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 texcoord0 : TEXCOORD0;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float4 posWorld : TEXCOORD1;
            };

            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                float outlineScale = _OutlineWidth * 0.001;
                o.pos = UnityObjectToClipPos(float4(v.vertex.xyz + v.normal * outlineScale, 1));
                o.uv0 = v.texcoord0;
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            float4 frag(VertexOutput i): COLOR {
                float4 diff = tex2D(_MainTex, TRANSFORM_TEX(i.uv0, _MainTex));

                float3 lightColor = saturate(max(_LightColor0, max(ShadeSH9(half4(0, 0, 0, 1)).rgb, ShadeSH9(half4(0, -1, 0, 1)).rgb)));
                float4 outlineColor = lerp(_OutlineColor, diff, 0.2) * fixed4(lightColor, 1);

                return fixed4(outlineColor.rgb, 1);
            }
            ENDCG
        }

        Pass {
            Name "ShadowCaster"
            Tags {
                "LightMode"="ShadowCaster"
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define UNITY_PASS_SHADOWCASTER
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct VertexInput {
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
            };
            struct VertexOutput {
                V2F_SHADOW_CASTER;
                float2 uv0 : TEXCOORD1;
            };

            VertexOutput vert (VertexInput v) {
                VertexOutput o;
                o.uv0 = v.texcoord0;
                o.pos = UnityObjectToClipPos(v.vertex);
                TRANSFER_SHADOW_CASTER(o);
                return o;
            }

            float4 frag(VertexOutput i): COLOR {
                SHADOW_CASTER_FRAGMENT(i);
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
}