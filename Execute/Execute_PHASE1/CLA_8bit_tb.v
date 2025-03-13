module CLA_8bit_tb();
logic [8:0] S;
logic [7:0] A,B;
logic [8:0] i; //itterator
CLA_8bit iDUT(.A(A), .B(B), .Sum(S));
initial begin
for (i=0; i<8'hFF; i=i+8'h01) begin
    A = $random;
    B = $random;
    #5;
    if(S != (A+B)) begin
        $display("Addition incorrect");
        $stop();

    end

end
$display("YAHOO ALL TEST PASSED!!!");
$stop();
end
endmodule
