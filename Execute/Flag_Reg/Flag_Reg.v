module Flag_Reg(Z_in, N_in, V_in, en_Z, en_N, en_V, clk, rst, Z_out, N_out, V_out);
    input Z_in, N_in, V_in, en_Z, en_N, en_V, clk, rst;
    output Z_out, N_out, V_out;

    dff Z_reg(.q(Z_out), .d(Z_in), .wen(en_Z), .clk(clk), .rst(rst));  //dff for zero flag
    dff N_reg(.q(N_out), .d(N_in), .wen(en_N), .clk(clk), .rst(rst));  //dff for negative flag
    dff V_reg(.q(V_out), .d(V_in), .wen(en_V), .clk(clk), .rst(rst));  //dff for overflow flag

endmodule