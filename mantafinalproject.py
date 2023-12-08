import time
from manta import Manta
m = Manta('finalproject.yml') # create manta python instance using yaml

counter = 0
while counter < 1280*720:
    print('here')
    #time.sleep(0.01) # wait a little amount...though honestly this is isn't needed since Python is slow.
    r = m.lab8_io_core.val1_in.get() # read in the output from our divider
    g = m.lab8_io_core.val2_in.get() # read in the output from our divider
    b = m.lab8_io_core.val3_in.get()
    hcount = m.lab8_io_core.hcount.get()
    vcount = m.lab8_io_core.vcount.get()
    print("R:",r)
    print("G:",g)
    print("B",b)
    print(hcount)
    print(vcount)
    counter += 1