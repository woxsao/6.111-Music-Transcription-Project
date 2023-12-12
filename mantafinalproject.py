import time
from manta import Manta
import numpy as np
m = Manta('finalproject.yml') # create manta python instance using yaml
import matplotlib.pyplot as plt

counter = 0
store = np.ndarray((720,1280))
hcount = 0
vcount = 0
store2 = np.ndarray((720,1280))
while vcount <720 :
    #time.sleep(0.01) # wait a little amount...though honestly this is isn't needed since Python is slow.
    m.lab8_io_core.ready.set(1)
    m.lab8_io_core.ready.set(0)
    
    m.lab8_io_core.hcount.set((hcount)*16)
    row = m.lab8_io_core.val1_in.get() # read in the output from our divider
    print("row: ",row)
    if(hcount < 80):
        hcount += 1
    else:
        hcount = 0
        vcount += 1
        m.lab8_io_core.vcount.set(vcount)

    
    #store2[vcount,hcount] = 1
print("DONE")
print(store)
array = np.array([
    [0, 1, 0, 1],
    [1, 0, 1, 0],
    [0, 1, 0, 1],
    [1, 0, 1, 0]
])
plt.imshow(store, cmap='binary', interpolation='nearest')
plt.colorbar()  # Add a colorbar to show values correspondence
plt.title('Binary Image')
plt.show()