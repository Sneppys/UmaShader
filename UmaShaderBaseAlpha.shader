
Shader "Uma/Base (Alpha)" {
    Properties {
        _MainTex ("Diffuse (_diff)", 2D) = "white" {}
        _ShadTex ("Shaded (_shad_c)", 2D) = "black" {}
        _BaseTex ("Base Map (_base)", 2D) = "white" {}
        _CtrlTex ("Control Map (_ctrl)", 2D) = "white" {}
    }
    SubShader {
        Tags {
            "Queue"="Transparent"
            "RenderType"="Transparent"
            "VRCFallback"="ToonCutout"
        }

        Pass {
            Name "Forward"
            Tags {
                "LightMode"="ForwardBase"
            }
            Cull Back
            Blend SrcAlpha OneMinusSrcAlpha, SrcAlpha OneMinusSrcAlpha
            BlendOp Add, Max

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
            // Red: Ambient Occlusion, Green: Specular, Blue: Clip
            uniform sampler2D _BaseTex;
            uniform float4 _BaseTex_ST;
            // Red: Unused?, Green: Metal?, Blue: Some sort of shading? Rimlight?
            uniform sampler2D _CtrlTex;
            uniform float4 _CtrlTex_ST;

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
                float4 base = tex2D(_BaseTex, TRANSFORM_TEX(i.uv0, _BaseTex));
                float4 ctrl = tex2D(_CtrlTex, TRANSFORM_TEX(i.uv0, _CtrlTex));

                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                float facing = dot(i.normalDir, viewDirection);

                // Lighting
                float3 defaultLightDirection = normalize(UNITY_MATRIX_V[2].xyz + UNITY_MATRIX_V[1].xyz);
                float3 lightDirection = normalize(lerp(defaultLightDirection, _WorldSpaceLightPos0.xyz, any(_WorldSpaceLightPos0.xyz)));
                // float3 lightDirection = normalize(lerp(_WorldSpaceLightPos0.xyz, _WorldSpaceLightPos0.xyz - i.posWorld.xyz, _WorldSpaceLightPos0.w));
                float halfLambert = 0.5 * dot(i.normalDir, lightDirection) + 0.5;
                float shadowLerp = saturate(1 + ((base.r * 2 * halfLambert - 0.2) * 100));
                float3 lightColor = saturate(max(_LightColor0, max(ShadeSH9(half4(0, 0, 0, 1)).rgb, ShadeSH9(half4(0, -1, 0, 1)).rgb)));
                float4 shadedDiff = lerp(shad, diff, shadowLerp) * fixed4(lightColor, 1);

                // Specular
                float specularMult = 1 + saturate(base.g * 50 * (facing - 0.6));

                // Rim
                float rimLerp = (1 - saturate(facing * 8)) * ctrl.b;
                float4 rimColor = diff * 10;

                return shadedDiff * specularMult * lerp(float4(1, 1, 1, 1), rimColor, rimLerp) * float4(1, 1, 1, base.b - 0.1);
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

            uniform sampler2D _BaseTex;
            uniform float4 _BaseTex_ST;

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
                float4 base = tex2D(_BaseTex, TRANSFORM_TEX(i.uv0, _BaseTex));

                clip(base.b - 0.5);

                SHADOW_CASTER_FRAGMENT(i);
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
}