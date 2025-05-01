/* 
    one hot shifter for block enable 
    64 possible tags 
*/
module blockEnable(input[5:0] set_index, output[63:0] blockEn);

    wire [63:0] shift_32, shift_16, shift_8, shift_4, shift_2;
    assign shift_32 = (set_index[5]) ? {{63{1'b0}}, 1'b1} << 32 : {{63{1'b0}}, 1'b1};
    assign shift_16 = (set_index[4]) ? shift_32 << 16 : shift_32;
    assign shift_8 = (set_index[3]) ? shift_16 << 8 : shift_16;
    assign shift_4 = (set_index[2]) ? shift_8 << 4 : shift_8;
    assign shift_2 = (set_index[1]) ? shift_4 << 2 : shift_4;
    assign blockEn = (set_index[0]) ? shift_2 << 1: shift_2;

endmodule