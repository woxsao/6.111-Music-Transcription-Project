taps = [
 -1,-2,-3,-5,-6,-5,0,10,25,45,67,90,110,123,128,123,110,90,67,45,25,10,0,-5,-6,-5,-3,-2,-1

]

# Open a file in write mode
with open('coefficients.txt', 'w') as file:
    for i, num in enumerate(taps):
        file.write(f'COEFFICIENTS[{i}] = {num};\n')
