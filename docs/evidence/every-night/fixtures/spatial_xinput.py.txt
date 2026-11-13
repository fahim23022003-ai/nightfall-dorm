import ctypes as c,ctypes.util,sys,time
x=c.CDLL(ctypes.util.find_library('X11'));t=c.CDLL(ctypes.util.find_library('Xtst'))
x.XOpenDisplay.restype=c.c_void_p;d=x.XOpenDisplay(None);assert d
x.XFlush.argtypes=[c.c_void_p];x.XStringToKeysym.argtypes=[c.c_char_p];x.XStringToKeysym.restype=c.c_ulong;x.XKeysymToKeycode.argtypes=[c.c_void_p,c.c_ulong];x.XKeysymToKeycode.restype=c.c_uint
t.XTestFakeMotionEvent.argtypes=[c.c_void_p,c.c_int,c.c_int,c.c_int,c.c_ulong];t.XTestFakeButtonEvent.argtypes=[c.c_void_p,c.c_uint,c.c_int,c.c_ulong];t.XTestFakeKeyEvent.argtypes=[c.c_void_p,c.c_uint,c.c_int,c.c_ulong]
x.XSetInputFocus.argtypes=[c.c_void_p,c.c_ulong,c.c_int,c.c_ulong]
if sys.argv[1]=='focus':x.XSetInputFocus(d,int(sys.argv[2]),1,0)
elif sys.argv[1] in ['click','motion']:
 t.XTestFakeMotionEvent(d,-1,int(sys.argv[2]),int(sys.argv[3]),0)
 if sys.argv[1]=='click':t.XTestFakeButtonEvent(d,1,1,0);t.XTestFakeButtonEvent(d,1,0,40)
else:
 key=x.XKeysymToKeycode(d,x.XStringToKeysym(sys.argv[2].encode()));t.XTestFakeKeyEvent(d,key,1,0);t.XTestFakeKeyEvent(d,key,0,40)
x.XFlush(d)
time.sleep(.12)
