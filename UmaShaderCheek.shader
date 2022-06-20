
Shader "Uma/Cheek" {
    Properties {
        _MainTex ("Cheek Diff (_cheek0)", 2D) = "white" {}
        _BlushTex ("Cheek Blush (_cheek1)", 2D) = "white" {}
        _BlushAmount ("Blush Amount", Range(0, 1)) = 0.5
        _BlushBlend ("Blush Blend", Range(0, 1)) = 0.0
    }
    SubShader {
        Tags {
            "FORCENOSHADOWCASTING" = "true"
            "Queue" = "AlphaTest-150"
            "RenderType"="Transparent"
            "VRCFallback"="Hidden"
        }

        Pass {
            Name "Forward"
            Tags {
                "FORCENOSHADOWCASTING" = "true"
                "Queue" = "AlphaTest-150"
                "LightMode"="ForwardBase"
            }
            Cull Off
            Blend DstColor Zero, DstColor Zero
            ColorMask RGB 0
            ZWrite Off
            Cull Off
            Offset -1, -1
            Fog {
                Mode Off
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"

            uniform sampler2D _MainTex;
            uniform float4 _MainTex_ST;
            uniform sampler2D _BlushTex;
            uniform float4 _BlushTex_ST;

            float _BlushAmount;
            float _BlushBlend;

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
                float4 blush = tex2D(_BlushTex, TRANSFORM_TEX(i.uv0, _BlushTex));

                return lerp(fixed4(1, 1, 1, 1), lerp(diff, blush, _BlushBlend), _BlushAmount);
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
}