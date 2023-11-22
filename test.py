taps = [
  208,
  136,
  55,
  -145,
  -438,
  -739,
  -913,
  -812,
  -317,
  603,
  1869,
  3285,
  4588,
  5505,
  5836,
  5505,
  4588,
  3285,
  1869,
  603,
  -317,
  -812,
  -913,
  -739,
  -438,
  -145,
  55,
  136,
  208

]

# Open a file in write mode
with open('coefficients.txt', 'w') as file:
    for i, num in enumerate(taps):
        file.write(f'COEFFICIENTS[{i}] = {num};\n')
