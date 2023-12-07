`timescale 1ns / 1ps
`default_nettype none

module rick(
  output logic [159:0][5:0] ricky
  );
  assign ricky[0] = 6'b1_01101;
  assign ricky[1] = 6'b1_01101;
  assign ricky[2] = 6'b1_01101;
  assign ricky[3] = 6'b1_01111;
  assign ricky[4] = 6'b1_01111;
  assign ricky[5] = 6'b1_01111;
  assign ricky[6] = 6'b1_01111;
  assign ricky[7] = 6'b1_01111;

  assign ricky[8] = 6'b1_01111;
  assign ricky[9] = 6'b1_01111;
  assign ricky[10] = 6'b1_01111;
  assign ricky[11] = 6'b1_10001;
  assign ricky[12] = 6'b1_10001;
  assign ricky[13] = 6'b1_10100;
  assign ricky[14] = 6'b1_10010;
  assign ricky[15] = 6'b1_10001;
  
  assign ricky[16] = 6'b1_01101;
  assign ricky[17] = 6'b1_01101;
  assign ricky[18] = 6'b1_01101;
  assign ricky[19] = 6'b1_01111;
  assign ricky[20] = 6'b1_01111;
  assign ricky[21] = 6'b1_01111;
  assign ricky[22] = 6'b1_01000;
  assign ricky[23] = 6'b1_01000;
  
  assign ricky[24] = 6'b1_01000;
  assign ricky[25] = 6'b1_01000;
  assign ricky[26] = 6'b1_01000;
  assign ricky[27] = 6'b1_01000;
  assign ricky[28] = 6'b1_01000;
  assign ricky[29] = 6'b1_01000;
  assign ricky[30] = 6'b1_01000;
  assign ricky[31] = 6'b1_01000;

  assign ricky[32] = 6'b1_01101;
  assign ricky[33] = 6'b1_01101;
  assign ricky[34] = 6'b1_01101;
  assign ricky[35] = 6'b1_01111;
  assign ricky[36] = 6'b1_01111;
  assign ricky[37] = 6'b1_01111;
  assign ricky[38] = 6'b1_01111;
  assign ricky[39] = 6'b1_01111;

  assign ricky[40] = 6'b1_01111;
  assign ricky[41] = 6'b1_01111;
  assign ricky[42] = 6'b1_01111;
  assign ricky[43] = 6'b1_10001;
  assign ricky[44] = 6'b1_10001;
  assign ricky[45] = 6'b1_10100;
  assign ricky[46] = 6'b1_10010;
  assign ricky[47] = 6'b1_10001;
  
  assign ricky[48] = 6'b1_01101;
  assign ricky[49] = 6'b1_01101;
  assign ricky[50] = 6'b1_01101;
  assign ricky[51] = 6'b1_01111;
  assign ricky[52] = 6'b1_01111;
  assign ricky[53] = 6'b1_01111;
  assign ricky[54] = 6'b1_01000;
  assign ricky[55] = 6'b1_01000;
  
  assign ricky[56] = 6'b1_01000;
  assign ricky[57] = 6'b1_01000;
  assign ricky[58] = 6'b1_01000;
  assign ricky[59] = 6'b1_01000;
  assign ricky[60] = 6'b1_01000;
  assign ricky[61] = 6'b1_01000;
  assign ricky[62] = 6'b1_01000;
  assign ricky[63] = 6'b1_01000;
  assign ricky[159:64] = 0;
endmodule