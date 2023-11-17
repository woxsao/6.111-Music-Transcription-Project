taps = [
  -1,-2,-2,0,5,10,10,-0,-19,-37,-36,0,70,157,229,257,229,157,70,0,-36,-37,-19,-0,10,10,5,0,-2,-2,-1
]

# Open a file in write mode
with open('coefficients.txt', 'w') as file:
    for i, num in enumerate(taps):
        file.write(f'COEFFICIENTS[{i}] = {num};\n')
