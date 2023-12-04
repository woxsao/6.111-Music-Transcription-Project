module bto7s(
        input wire [3:0]   x_in,
        output logic [6:0] s_out
        );

        // array of bits that are "one hot" with numbers 0 through 15
        logic [15:0] num;
        assign num[0] = ~x_in[3] && ~x_in[2] && ~x_in[1] && ~x_in[0];
        assign num[1] = ~x_in[3] && ~x_in[2] && ~x_in[1] && x_in[0];
        assign num[2] = x_in == 4'd2;
        assign num[3] = x_in == 4'd3;
        assign num[4] = x_in == 4'd4;
        assign num[5] = x_in == 4'd5;
        assign num[6] = x_in == 4'd6;
        assign num[7] = x_in == 4'd7;
        assign num[8] = x_in == 4'd8;
        assign num[9] = x_in == 4'd9;
        assign num[10] = x_in == 4'd10;
        assign num[11] = x_in == 4'd11;
        assign num[12] = x_in == 4'd12;
        assign num[13] = x_in == 4'd13;
        assign num[14] = x_in == 4'd14;

        // you do the rest...

        assign num[15] = x_in == 4'd15;

        /* assign the seven output segments, sa through sg, using a "sum of products"
         * approach and the diagram above.
         *
         * assign sa =
         * assign sb =
         * assign sc =
         * assign sd =
         * assign se =
         * assign sf =
         * assign sg =
         */
        logic sa,sb,sc,sd,se,sf,sg;
        assign sa = ~(num[1] || num[4] || num[11] || num[13]);
        assign sb = ~(num[5] || num[6] || num[11] || num[12] || num[14] || num[15]);
        assign sc = ~(num[2] || num[12] || num[14] || num[15]);
        assign sd = ~(num[1] || num[4] || num[7] || num[10] || num[15]);
        assign se = ~(num[1] || num[3] || num[4] || num[5] || num[7] || num[9]);
        assign sf = ~(num[1] || num[2] || num[3] || num[7] || num[13]);
        assign sg = ~(num[0] || num[1] || num[7] || num[12]);
        
  assign s_out = {sg,sf,se,sd,sc,sb,sa};

endmodule
