module i2c_master(
    input  wire clk,//1Mhz
    input  wire rst,
    input  wire start,
    input  wire [6:0]slave_addr,
    input  wire rw,
    input  wire [7:0] write_addr,
    input  wire [7:0]din,
    output reg  busy,
    output reg  done,
    inout  wire sda,
    output reg  scl
    );
    
    //open drain Serial data
     reg sda_out;
     reg sda_en;
     assign sda = (sda_en) ? sda_out : 1'bz;
//     wire sda_in = sda;
     
     reg scl_st,scl_en;
     reg [2:0]clk_count;
     reg scl_reg; //100KHz
     //clock didvider we are using to convert the 1MHz clk into the 100kHz clk freq.
     
     always @(posedge clk) begin
        if(rst) begin
            clk_count <= 1'b0;
            scl       <= 1'b0;
        end
        else if(!scl_st)begin
            clk_count <= 1'b0;
            scl        <= 1'b1;        
        end 
        else if(!scl_en) begin 
            clk_count <= 1'b0;
            scl <= 1'b1;        
        end
        else begin
            if(clk_count == 4)begin 
                clk_count <= 1'b0;
                scl      <= ~scl;
            end 
            else begin 
                clk_count <= clk_count + 1'b1;
                scl <= scl;
            end
        end
     end
    //reg scl_en;
    //reg scl_st;
    reg [3:0] startup_cnt;
         always @(posedge clk or posedge rst) begin
        if(rst) begin
            startup_cnt  <= 0;
            scl_st <= 0;
        end
        else if(!scl_st) begin
    
            if(startup_cnt == 10) begin
                scl_st <= 1;
            end
            else begin
                startup_cnt <= startup_cnt + 1;
            end
        end
    end
         
     
     
//      wire scl_posedge = (clk_count == 4 && scl_reg == 0);
//      wire scl_negedge = (clk_count == 4 && scl_reg == 1);
//     assign scl = scl_reg;

       
        


    reg [2:0] bit_count;
    reg ack_received;
    reg bit_cnt_en, bit_cnt_load;
    
    //bit_count to track the bit transfer properly in the states
    always @(posedge scl or posedge rst) begin 
        if(rst)
            bit_count <= 3'd7;
        else if (bit_cnt_load)
            bit_count <= 3'd7;
        else if(bit_cnt_en)
            bit_count <= bit_count - 1;
        else
            bit_count <= bit_count;
    end


    
    
    reg shift_en,read_en;
    reg load_slave_addr,load_write_addr , load_data;
    reg [7:0] slave_addr_rw;
    reg [7:0] write_addr_reg;
    reg [7:0] data_reg;
    reg [7:0] shift_reg;
    //storing the addrs AND  data in the register
    always @(posedge clk or posedge rst) begin
    if (rst) begin
        slave_addr_rw  <= 1'b0;
        write_addr_reg <= 1'b0;
        data_reg <= 0;
    end else begin
        if (load_slave_addr)begin
            slave_addr_rw <= {slave_addr, rw};
        end
        if (load_write_addr)begin
            write_addr_reg <= write_addr;
        end
        if (load_data)begin 
            data_reg <= din;
        end
    end
   end
   
   
   //shifting the reg addrs and data into the shift_reg
    always @(posedge scl or posedge rst) begin
        if (rst)
            shift_reg <= 'd0;
    
        // Load Slave Address
        else if (load_slave_addr)
            shift_reg <= slave_addr_rw;
    
        // Load Write Address
        else if (load_write_addr)
            shift_reg <= write_addr_reg;
    
        // Load Data
        else if (load_data)
            shift_reg <= data_reg;
    
        // Shift for the write operation
        else if (shift_en)
            shift_reg <= {shift_reg[6:0], 1'b0};
            
        else 
            shift_reg <= shift_reg;
    
        // Shift for Read operation
    //    else if (read_en)
    //        shift_reg <= {shift_reg[6:0], sda_in};
    end    
    

    //state machine
    //states
    localparam IDLE                 = 4'b0000;
    localparam START                = 4'b0001;
    localparam SLAVE_ADDR           = 4'b0010;
    localparam WAIT_SLAVE_ADDR_ACK  = 4'b0011;
    localparam WRITE_ADDR           = 4'b0100;
    localparam WRITE_ADDR_ACK       = 4'b0101;
    localparam WRITE_DATA           = 4'b0110;
    localparam WAIT_DATA_ACK        = 4'b0111;
    localparam STOP                 = 4'b1000;
    
    reg [3:0] state,next_state;



   //fsm
    //sequential logic 
    always @(posedge scl or posedge rst )begin
        if(rst) 
            state <= IDLE;
            
        else 
            state <= next_state;
    end
    
   //combinational logic
    always @(*)begin 

        next_state      = state;
        scl_en          = 1'b1;
        sda_en          = 1'b1;
        sda_out         = 1'b1;
        bit_cnt_en      = 1'b0;
        bit_cnt_load    = 1'b0;
        shift_en        = 1'b0;
        load_slave_addr = 1'b0;
        load_write_addr = 1'b0;
        load_data       = 1'b0;
        
       
        case(state)
            
            IDLE : begin 
                sda_en  = 1'b1;
                sda_out = 1'b1;
                scl_en = 1'b0;
                
                // start condition
               
                if(start)begin           
                                         
                    next_state = START;  
                end                      
                else begin               
                    next_state = IDLE; 
                end   
           end                      
            START : begin 

                sda_out         = 1'b0;
                next_state      = SLAVE_ADDR;
                bit_cnt_load    = 1'b1;
                load_slave_addr = 1'b1;
                scl_en          = 1'b1;           

            end
                       
            SLAVE_ADDR : begin
                shift_en = 1'b1;
                sda_out = shift_reg[7];
                
                if(scl == 0 )begin
                
                    bit_cnt_en =1'b1;

                    if(bit_count == 0)begin 
                        next_state = WAIT_SLAVE_ADDR_ACK;
                    end
                    else begin 
                        next_state      = SLAVE_ADDR;
                    end 
                end

            end
                  
            WAIT_SLAVE_ADDR_ACK : begin
                sda_en  = 1'b0;
                if(scl == 0) 
                    next_state = WRITE_ADDR;
                    load_write_addr = 1'b1;
                end
            
            WRITE_ADDR : begin
                sda_out  = 1'b0;
                shift_en = 1'b1;
                sda_out = shift_reg[7];
                if ( scl == 0)begin 
                    bit_cnt_en = 1'b1;
                        if(bit_count == 0)
                            next_state = WRITE_ADDR_ACK;
                        else
                            next_state = WRITE_ADDR;
                            
                end
            end

            WRITE_ADDR_ACK : begin
             sda_en  = 1'b0;
             load_data = 1'b1;
                if(scl == 0)begin
                    next_state = WRITE_DATA; 

                end
                else begin 
                    next_state = WRITE_ADDR_ACK;   
                end
            end 

            
            WRITE_DATA : begin
               sda_out = shift_reg[7];
                
                shift_en = 1'b1;
                
                if ( scl == 0)begin
                    bit_cnt_en = 1'b1;
                    
                    if(bit_count == 0)begin 
                         next_state = WAIT_DATA_ACK;
                    end
                 end
            end

                
            WAIT_DATA_ACK : begin
            
                sda_en  = 1'b0;
                if(scl == 0)begin
                    next_state = STOP; 

            end 
            end
              
            STOP : begin 
            sda_out = 1'b1;
            scl_en  = 1'b0;
            done    = 1'b1;
//                if(scl == 1)begin 
//                    next_state = IDLE;
//                end
            end            
            
            default : next_state = IDLE;
          
        endcase             
    end
    
    
endmodule
