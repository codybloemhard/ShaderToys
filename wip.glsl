#define MAX_STEPS 100
#define MAX_DIST 1000.
#define EPSILON 0.01
#define AMBIENT 0.05

float raymarch_d(vec3, vec3);

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
	vec3 n = calc_normal(p);
    vec3 lpos = vec3(1, 5, 2);
    vec3 tol = lpos - p;
    float dist = length(tol);
    vec3 ldir = tol / dist;
    float str = max(AMBIENT,dot(n, ldir));
    float e = str * 5. / dist;
    if(e <= AMBIENT) return vec3(AMBIENT);
    float shadow = raymarch_d(p + n * EPSILON * 2., ldir);
    if(shadow < dist) return vec3(AMBIENT);
    return vec3(e);
}

float raymarch_d(vec3 ro, vec3 rd){
	float dO = 0.;
    vec3 p;
    for(int i = 0; i < MAX_STEPS; i++){
    	p = ro + rd*dO;
        float dS = scene_dist(p);
        dO += dS;
        if(dO > MAX_DIST || dS < EPSILON)
            break;
    }
    return dO;
}

vec3 raymarch_p(vec3 ro, vec3 rd){
	float dO = raymarch_d(ro, rd);
    return ro + rd * dO;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord-0.5*iResolution.xy) / iResolution.y;
	
    vec3 col = vec3(0);
    
    vec3 ro = vec3(0, 1, 0);
    vec3 rd = normalize(vec3(uv.x, uv.y, 1));
    vec3 p = raymarch_p(ro, rd);
    col = calc_light(p);
    
    fragColor = vec4(col,1.0);
}