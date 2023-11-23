taps = [
  42,  
-70,
-206,
-415,
-652,
-833,
-853,
-603,
-18,
904,
2074,
3325,
4443,
5218,
5495,
5218,
4443,
3325,
2074,
904,
-18,
-603,
-853,
-833,
-652,
-415,
-206,
-70,
42



]

# Open a file in write mode
with open('coefficients.txt', 'w') as file:
    for i, num in enumerate(taps):
        file.write(f'COEFFICIENTS[{i}] = {num};\n')
