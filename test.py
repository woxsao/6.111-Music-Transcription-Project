taps = [
  18,
  -185,
  -374,
  26,
  392,
  -229,
  -514,
  578,
  554,
  -1150,
  -363,
  2060,
  -375,
  -3821,
  3327,
  16037,
  16037,
  3327,
  -3821,
  -375,
  2060,
  -363,
  -1150,
  554,
  578,
  -514,
  -229,
  392,
  26,
  -374,
  -185,
  18
]

# Open a file in write mode
with open('coefficients.txt', 'w') as file:
    for i, num in enumerate(taps):
        file.write(f'COEFFICIENTS[{i}] = {num};\n')
