/* 
    8 bit shifter to select specific word
*/
module wordEnable (input[2:0] b_offset, output[7:0] wordEn);

    wire [7:0] shift_4, shift_2;

    assign shift_4 = (b_offset[2]) ? {{7{1'b0}}, 1'b1} << 4 : {{7{1'b0}}, 1'b1};
    assign shift_2 = (b_offset[1]) ? shift_4 << 2 : shift_4;
    assign wordEn = (b_offset[0]) ? shift_2 << 1: shift_2;

endmodule