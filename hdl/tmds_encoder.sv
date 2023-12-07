module tmds_encoder(
  input wire clk_in,
  input wire rst_in,
  input wire [7:0] data_in,  // video data (red, green or blue)
  input wire [1:0] control_in, //for blue set to {vs,hs}, else will be 0
  input wire ve_in,  // video data enable, to choose between control or video signal
  output logic [9:0] tmds_out
);

  logic [8:0] q_m;
  //you can assume a functioning (version of tm_choice for you.)
  tm_choice mtm(
    .data_in(data_in),
    .qm_out(q_m));

  //your code here.
  logic [3:0] ones;
  logic [3:0] zeros;
  logic [4:0] tally;
  always_comb begin
    ones = $countbits(q_m[7:0],1'b1);
    zeros = $countbits(q_m[7:0],1'b0);
  end
    
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      tmds_out <= 0;
      tally <= 0;
    end else if (~ve_in) begin
      tally <= 0;
      case (control_in) 
        2'b00: tmds_out <= 10'b1101010100;
        2'b01: tmds_out <= 10'b0010101011;
        2'b10: tmds_out <= 10'b0101010100;
        2'b11: tmds_out <= 10'b1010101011;
      endcase
    end else begin
      if (ones==zeros || tally==0) begin
        tmds_out[9] <= ~q_m[8];
        tmds_out[8] <= q_m[8];
        tmds_out[7:0] <= (q_m[8])? q_m[7:0]:~q_m[7:0];
        if (q_m[8]==0) begin
          tally = tally+(zeros-ones);
        end else begin
          tally = tally+(ones-zeros);
        end
      end else begin
        if ((tally[4]==0 && ones>zeros) || (tally[4]==1 && zeros>ones)) begin
          tmds_out[9] <= 1;
          tmds_out[8] <= q_m[8];
          tmds_out[7:0] <= ~(q_m[7:0]);
          tally <= tally+{q_m[8],1'b0}+(zeros-ones);
        end else begin
          tmds_out[9] <= 0;
          tmds_out[8] <= q_m[8];
          tmds_out[7:0] <= q_m[7:0];
          tally <= tally-{~q_m[8],1'b0}+(ones-zeros);
        end
      end       
    end
  end
endmodule //end tmds_encoder

module tm_choice (
  input wire [7:0] data_in,
  output logic [8:0] qm_out
  );



  //your code here, friend
  integer i;
  integer ones;
  logic [8:0] op1;
  logic [8:0] op2;
  logic [3:0] ch1;
  logic [3:0] ch2;
  always_comb begin
    op1[0] = data_in[0];
    for (i=1;i<8;i=i+1) begin
      op1[i] = op1[i-1]^data_in[i];
    end
    op1[8] = 1;
    
    op2[0] = data_in[0];
    for (i=1;i<8;i=i+1) begin
      op2[i] = ~(op2[i-1]^data_in[i]);
    end
    op2[8] = 0;
    
    ones = 0;
    for (i=0;i<8;i=i+1) begin
      if (data_in[i]) begin
        ones = ones+1;
      end
    end
    if(ones>4 || (ones==4 && ~data_in[0])) begin
      qm_out = op2;
    end else begin
      qm_out = op1;
    end
  end
endmodule //end tm_choice