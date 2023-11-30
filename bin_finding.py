import math 
bin_width = 4.15
num_bins = 4096
frequencies = [261.63, 277.18, 293.66, 311.13, 329.63, 349.23, 369.99, 392.00, 415.30, 440.00,
                                    466.16, 493.88, 523.25, 554.37, 587.33, 622.25, 659.25, 698.46, 739.99, 783.99,
                                    830.61, 880.00 ]
floored_bins = []
for freq in frequencies:
    floored = math.floor(freq/bin_width)
    floored_bins.append(floored)
print(len(floored_bins))

with open('bins.txt', 'w') as file:
    for i, b in enumerate(floored_bins):
        file.write(f'bin_floor[{i}] = {b};\n')