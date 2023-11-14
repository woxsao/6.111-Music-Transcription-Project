a_10 = round(fir1(10, 3000/2000000)*1024);
dlmwrite("fir_10_taps.txt", a_10, ' ');

a_30 = round(fir1(30, 3000/2000000)*1024);
dlmwrite("fir_30_taps.txt", a_30, ' ');
plot(fir1(30, 3000/2000000));

a_60 = round(fir1(60, 3000/2000000)*1024);
dlmwrite("fir_60_taps.txt", a_60, ' ');