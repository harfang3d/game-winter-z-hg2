$input v_texcoord0

#include <bgfx_shader.sh>

SAMPLER2D(s_texTexture, 0);

uniform vec4 color;

void main() {
	gl_FragColor = texture2D(s_texTexture, v_texcoord0) * color;
}
