# Online Python compiler (interpreter) to run Python online.
# Write Python 3 code in this online editor and run it.
import math

def cosmf(i):
    return 2 * math.pi * i / (4096 - 1)

def analysis():
    for i in range(4096):
        s = str(int(cosmf(i) * 100000))
        
        print("i: ",i)
        print("cosin:", cosmf(i))
        shifted = (5-len(s))*"0" + s
        print("shifted:",  shifted )
        oneminus = 100000 - int(shifted)
        print("oneminus:", oneminus)
        half = oneminus >> 1
        print("half:", half)

        val = 0.5*(1-math.cos(cosmf(i)))
        print("val: {:.10f}".format(val))
        print("-------------")
        # print("half :", half*1280000)
        # print(half*-1280000)
        # print(half*10000)

def generate_mem():
    for i in range(4096):
        val = 0.5*(1-math.cos(cosmf(i)))
        scaled = round(val * (2**24))
        hex_pre = hex(scaled)
        #print(hex_pre)
        hex_str = str(hex_pre)
        if len(hex_str[2:]) < 6:
            hex_str = '0'*(6-len(hex_str[2:])) + hex_str[2:]
        else:
            hex_str = hex_str[2:]
        print(hex_str)

generate_mem()

