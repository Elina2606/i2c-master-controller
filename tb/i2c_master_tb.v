module i2c_mastertb();
       reg clk;       
        reg rst;       
        reg start;     
        reg [6:0]slave_addr;
        reg rw; 
        reg [7:0] write_addr;      
        reg [7:0]din;  
        wire busy;
        wire done;
        wire sda;  
        wire scl ;
        
        pullup(sda);
        reg sda_en=1;
        
          
i2c_master dut(clk,rst,start,slave_addr,rw,write_addr,din,busy,done,sda,scl);

initial clk =0;
 always #500 clk = ~clk;
 
initial begin 
        rst=1;
        #1000;
        rst=0;
        end
initial begin 
        start       = 'd0;
        wait(rst);
        //#2000;
        repeat (2)@(posedge clk);
        start = 'd1;
        @(posedge clk);
        start = 'd0;
end
initial begin
        slave_addr  = 7'b1010_000;
        rw          = 'd0;
        write_addr  = 8'b0000_0101;
        din         = 8'b0001_0000;
        repeat (2)@(posedge clk);
//        #2000;
end

//        rw         = 'd1;

initial begin
repeat (2)@(posedge clk);
 $finish;
       end

endmodule

