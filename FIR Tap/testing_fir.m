
a_final = round(fir1(28, 0.125)*1024);
plot(a_final);
dlmwrite("fir_many_taps.txt", a_final, ',');
