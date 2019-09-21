#define MAX_STEPS 50
#define MAX_DIST 1000.
#define HIT_DIST 0.01

float scene_dist(vec3 p){
    vec4 s = vec4(0, 1, 6, 1);
    float sphere_dist = length(p-s.xyz)-s.w;
    float plane_dist = p.y;
    return min(sphere_dist, plane_dist);
}

vec3 calc_normal(vec3 p) {
    float d = scene_dist(p);
    vec2 e = vec2(.01, 0);
    vec3 n = d - vec3(
        scene_dist(p-e.xyy),
        scene_dist(p-e.yxy),
        scene_dist(p-e.yyx));
    return normalize(n);
}

vec3 calc_light(vec3 p){
    return calc_normal(p);
}

vec3 raymarch(vec3 ro, vec3 rd){
    float dO = 0.;
    vec3 p;
    for(int i = 0; i < MAX_STEPS; i++){
        p = ro + rd*dO;
        float dS = scene_dist(p);
        dO += dS;
        if(dO > MAX_DIST || dS < HIT_DIST)
            break;
    }
    return p;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord-0.5*iResolution.xy) / iResolution.y;
    
    vec3 col = vec3(0);
    
    vec3 ro = vec3(0, 1, 0);
    vec3 rd = normalize(vec3(uv.x, uv.y, 1));
    vec3 p = raymarch(ro, rd);
    col = calc_light(p);
    
    fragColor = vec4(col,1.0);
}
