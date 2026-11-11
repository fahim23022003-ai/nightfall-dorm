"""Small XTest input helper for the documented :99 cloud smoke display."""
import ctypes,sys,time
x=ctypes.CDLL('libX11.so.6'); t=ctypes.CDLL('libXtst.so.6')
x.XOpenDisplay.restype=ctypes.c_void_p
x.XOpenDisplay.argtypes=[ctypes.c_char_p]
d=x.XOpenDisplay(b':99')
if not d:
 raise SystemExit('X display :99 is unavailable; start documented Xorg dummy display first.')
t.XTestFakeMotionEvent.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_int,ctypes.c_int,ctypes.c_ulong]
t.XTestFakeButtonEvent.argtypes=[ctypes.c_void_p,ctypes.c_uint,ctypes.c_int,ctypes.c_ulong]
t.XTestFakeKeyEvent.argtypes=[ctypes.c_void_p,ctypes.c_uint,ctypes.c_int,ctypes.c_ulong]
x.XFlush.argtypes=[ctypes.c_void_p]
x.XStringToKeysym.argtypes=[ctypes.c_char_p]; x.XStringToKeysym.restype=ctypes.c_ulong
x.XKeysymToKeycode.argtypes=[ctypes.c_void_p,ctypes.c_ulong]; x.XKeysymToKeycode.restype=ctypes.c_uint
if sys.argv[1]=='move':
 t.XTestFakeMotionEvent(d,0,int(sys.argv[2]),int(sys.argv[3]),0)
elif sys.argv[1]=='click':
 t.XTestFakeMotionEvent(d,0,int(sys.argv[2]),int(sys.argv[3]),0)
 t.XTestFakeButtonEvent(d,1,1,0); t.XTestFakeButtonEvent(d,1,0,0)
else:
 code=x.XKeysymToKeycode(d,x.XStringToKeysym(sys.argv[2].encode()))
 t.XTestFakeKeyEvent(d,code,1,0); x.XFlush(d)
 time.sleep(float(sys.argv[3]) if len(sys.argv)>3 else .1)
 t.XTestFakeKeyEvent(d,code,0,0)
x.XFlush(d)
