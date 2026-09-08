"""Original Cluck models. Run in Blender; exports compact, material-batched GLBs."""
import bpy, math, os
from mathutils import Vector
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT=os.path.join(ROOT,'assets','models')
os.makedirs(OUT,exist_ok=True)
# Keep any pre-existing user scene intact; work in a new scene.
scene=bpy.data.scenes.new('Cluck Asset Workshop')
bpy.context.window.scene=scene
M={}
for name,col in {'cream':'f5e7c3','white':'fff6de','red':'c83232','orange':'efa331','black':'201e2a','brown':'78513b','wood':'8d6442','pink':'db8290','grey':'696476','dark':'343342','fox':'d66b2e','leaf':'627d39','hay':'d2aa51','barn':'b44c3c','blue':'44d5eb','green':'79914a'}.items():
    m=bpy.data.materials.new('Cluck_'+name); m.diffuse_color=tuple(int(col[i:i+2],16)/255 for i in (0,2,4))+(1,); m.use_nodes=True
    m.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=m.diffuse_color
    m.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.82
    M[name]=m
parts=[]
def ball(name,p,s,mat):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=8,location=p)
    o=bpy.context.object;o.name=name;o.scale=s;o.data.materials.append(M[mat]);parts.append(o)
    for f in o.data.polygons:f.use_smooth=True
    return o
def box(name,p,s,mat,bevel=.06):
    bpy.ops.mesh.primitive_cube_add(size=1,location=p);o=bpy.context.object;o.name=name;o.scale=s
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(M[mat]);parts.append(o)
    if bevel:
        mod=o.modifiers.new('Soft edges','BEVEL');mod.width=bevel;mod.segments=1
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return o
def cone(name,a,b,r,mat,r2=0):
    d=Vector(b)-Vector(a);p=(Vector(a)+Vector(b))/2
    bpy.ops.mesh.primitive_cone_add(vertices=10,radius1=r,radius2=r2,depth=d.length,location=p)
    o=bpy.context.object;o.name=name;o.rotation_euler=d.to_track_quat('Z','Y').to_euler();o.data.materials.append(M[mat]);parts.append(o);return o
def eyes(x,y,z):
    for side in [-1,1]:
        ball('Eye',(side*x,y,z),(.13,.085,.16),'white');ball('Pupil',(side*x,y-.065,z),(.065,.045,.09),'black')
def export(name):
    global parts
    bpy.ops.object.select_all(action='DESELECT')
    for o in parts:o.select_set(True)
    bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join();o=bpy.context.object;o.name=name
    scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT,name+'.glb'),use_selection=True,export_format='GLB',export_yup=True)
    o.hide_set(True);parts=[]
ball('Body',(0,0,.88),(.53,.5,.64),'cream');ball('Head',(0,-.19,1.48),(.46,.42,.45),'white')
for side in [-1,1]:
    w=ball('Wing',(side*.5,0,.94),(.18,.35,.4),'white');w.rotation_euler[1]=side*.25
    cone('Leg',(side*.2,0,.45),(side*.2,-.03,.18),.08,'orange',.07)
    for dx in [-.1,0,.1]:cone('Toe',(side*.2,-.01,.12),(side*.2+dx,-.36,.1),.05,'orange',.025)
for i in range(3):ball('Comb',(0,-.35+i*.22,1.87),(.12,.15,.23-i*.025),'red')
cone('Beak',(0,-.52,1.46),(0,-.92,1.34),.2,'orange')
eyes(.22,-.54,1.6)
ball('Bandana',(0,-.06,1.17),(.44,.44,.11),'red')
cone('Scarf knot',(.35,.13,1.16),(.82,.43,.93),.17,'red')
for i in [-1,0,1]:cone('Tail',(i*.1,.3,.83),(i*.19,.85,1.33),.19,'white',.04)
export('chicken')
for animal,body,scale in [('rat','grey',.8),('fox','fox',1),('boar','brown',1.25),('cow','cream',1.4)]:
    ball('Body',(0,.12,.62),(.42,.64,.4),body);ball('Head',(0,-.47,.77),(.35,.37,.34),body)
    for x in [-.27,.27]:
        for y in [-.26,.49]:cone('Leg',(x,y,.53),(x,y,.1),.10,'dark' if animal=='cow' else body,.08)
    if animal=='rat':
        for x in [-.27,.27]:ball('Ear',(x,-.4,1.06),(.18,.1,.2),'pink')
        cone('Muzzle',(0,-.64,.7),(0,-.98,.66),.23,body,.05)
        cone('Tail',(0,.6,.55),(.25,1.3,.22),.065,'pink',.015)
    elif animal=='fox':
        for x in [-.24,.24]:cone('Ear',(x,-.43,.95),(x*1.25,-.44,1.39),.17,body)
        cone('Muzzle',(0,-.65,.7),(0,-1.05,.65),.22,'cream',.045)
        cone('Tail',(0,.53,.55),(.25,1.34,.72),.29,body,.16)
        cone('Tail tip',(.25,1.22,.69),(.35,1.65,.8),.19,'cream',.03)
    elif animal=='boar':
        ball('Snout',(0,-.81,.68),(.26,.16,.2),'pink')
        for x in [-.29,.29]:
            cone('Tusk',(x,-.68,.55),(x*1.15,-.87,.92),.10,'cream')
            cone('Ear',(x,-.36,.94),(x*1.25,-.22,1.18),.16,body)
        for y in [0,.2,.4]:cone('Bristle',(0,y,.96),(0,y+.1,1.19),.13,'dark')
    else:
        ball('Muzzle',(0,-.76,.63),(.32,.18,.22),'pink')
        for x in [-.3,.3]:
            cone('Horn',(x,-.35,.99),(x*1.6,-.25,1.32),.11,'cream')
            ball('Ear',(x*1.45,-.34,.93),(.23,.13,.10),'brown')
        for x,y in [(-.34,.1),(.34,.35),(-.2,.5)]:ball('Patch',(x,y,.79),(.13,.24,.19),'dark')
    eyes(.17,-.72,.88)
    for o in parts:o.location*=scale;o.scale*=scale
    export(animal)
box('Barn',(0,0,1.4),(4,3,2.8),'barn')
for x in [-1.8,1.8]:box('Corner',(x,-1.54,1.4),(.14,.12,2.8),'cream')
box('Door',(0,-1.55,1),(1.6,.12,2),'wood')
for x in [-.85,.85]:box('Door frame',(x,-1.65,1.05),(.12,.12,2.1),'cream')
for angle in [-.67,.67]:
    o=box('Roof',(math.sin(angle)*1.14,0,3.16),(2.9,3.5,.18),'dark');o.rotation_euler[1]=angle
box('Crossbeam',(0,-1.65,2.1),(1.8,.12,.12),'cream')
export('barn')
for x in [-1,1]:box('Post',(x,0,.55),(.18,.2,1.1),'wood')
for z in [.4,.83]:box('Rail',(0,0,z),(2.2,.13,.14),'wood')
export('fence')
box('Hay',(0,0,.42),(1.2,.85,.84),'hay',.12)
for x in [-.35,.35]:box('Binding',(x,0,.43),(.055,.88,.87),'brown',.01)
export('hay')
cone('Trunk',(0,0,0),(0,0,1.8),.18,'wood',.12)
for p,s in [((0,0,2.1),(.95,.9,1)),((.5,0,1.8),(.65,.65,.7)),((-.5,.1,1.9),(.6,.65,.7))]:ball('Canopy',p,s,'leaf')
export('tree')
cone('Stalk',(0,0,0),(0,0,1.3),.035,'green',.018)
for z in [.4,.7,1.]:
    for side in [-1,1]:cone('Leaf',(0,0,z),(side*.35,0,z+.18),.08,'leaf')
ball('Corn',(0,0,1.35),(.09,.09,.25),'hay')
export('corn')
# A display lineup in the editable source file.
for i,o in enumerate([o for o in scene.objects if o.type=='MESH']):o.hide_set(False);o.location=(i*3,0,0)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT,'art','cluck_assets.blend'))
print('CLUCK_ASSETS_EXPORTED',OUT)
