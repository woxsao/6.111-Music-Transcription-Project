
a_final = round(fir1(30, 0.25)*1024);
plot(a_final);
dlmwrite("fir_many_taps.txt", a_final, ',');
