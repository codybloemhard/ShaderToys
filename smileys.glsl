#define PI 3.1415f
//shapes---------------------------------------------------------------------------
float circle(vec2 uv, vec2 pos, float r, float blur){
    float d = length(uv - pos);
    return smoothstep(r, r-blur, d);
}

float band(float t, float start, float end, float blur){
    float s0 = smoothstep(start-blur, start+blur, t);
    float s1 = smoothstep(end+blur, end-blur, t);
    return s0*s1;
}

float rect(vec2 uv, float l, float r, float t, float b, float blur){
    float s0 = band(uv.x, l, r, blur);
    float s1 = band(uv.y, t, b, blur);
    return s0*s1;
}
//other----------------------------------------------------------------------------
float smiley(vec2 uv, vec2 pos, float r){
    uv -= pos;
    uv /= r * 2.5f;
    
    float mask = circle(uv, vec2(0.0f, 0.0f), 0.4f, 0.05f);
    mask -= circle(uv, vec2(-0.13f, 0.16f), 0.05f, 0.01f);
    mask -= circle(uv, vec2(+0.13f, 0.16f), 0.05f, 0.01f);
    
    float mouth = circle(uv, vec2(0.0f, 0.0f), 0.3f, 0.02f);
    mouth -= circle(uv, vec2(0.0f, 0.3f), 0.5f, 0.02f);
    mouth = max(mouth, 0.0f);
    
    mask -= mouth;
    mask -= rect(uv, -0.03f, +0.03f, -0.1f, +0.05f, 0.01f);
        
    return mask;
}
//main----------------------------------------------------------------------------
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 rawuv = fragCoord.xy / iResolution.xy;
    vec2 uv = fragCoord.xy / iResolution.xy;  
    uv -= 0.5f;//set origen to the middle of the screen.
    uv.x *= iResolution.x / iResolution.y;//aspect ratio
    
    float mask = 0.0f;
    
    mask += smiley(uv, vec2(0.0f, 0.0f), 0.3f);
    for(int i = 0; i < 10; i++){
        float rot = (float(i) * (2.0f*PI/10.0f)) + (iTime * 0.3f);
        mask += smiley(uv, vec2(sin(rot)*0.4f, cos(rot)*0.4f), 0.05f);
    }
    
    vec3 backg = vec3(rawuv,0.5+0.5*sin(iTime));
    vec3 col = backg * mask;
    fragColor = vec4(col, 1.0);
}
