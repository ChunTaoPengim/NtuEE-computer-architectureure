module ALU #(
    parameter DATA_W = 32
)
(
    input                       i_clk,   // clock
    input                       i_rst_n, // reset

    input                       i_valid, // input valid signal
    input [DATA_W - 1 : 0]      i_A,     // input operand A
    input [DATA_W - 1 : 0]      i_B,     // input operand B
    input [         2 : 0]      i_inst,  // instruction

    output [2*DATA_W - 1 : 0]   o_data,  // output value
    output                      o_done   // output valid signal
);
// Do not Modify the above part !!!

// Parameters
    // ======== choose your FSM style ==========
    // 1. FSM based on operation cycles
    // parameter S_IDLE           = 2'd0;
    // parameter S_ONE_CYCLE_OP   = 2'd1;
    // parameter S_MULTI_CYCLE_OP = 2'd2;
    // 2. FSM based on operation modes
    parameter IDLE = 4'd0;
    parameter ADD  = 4'd1;
    parameter SUB  = 4'd2;
    parameter AND  = 4'd3;
    parameter OR   = 4'd4;
    parameter SLT  = 4'd5;
    parameter SRA  = 4'd6;
    parameter MUL  = 4'd7;
    parameter DIV  = 4'd8;
    parameter OUT  = 4'd9;
    parameter max_value = 2**31-1;
    parameter min_value = -2**31;

// Wires & Regs
    // Todo
    // state
    reg  [         3: 0] state, state_nxt; // remember to expand the bit width if you want to add more states!
    // load input
    reg  [  DATA_W-1: 0] alu_in, alu_in_nxt;
    reg  [ 4:0] counter, counter_nxt;


    reg  [63:0] shiftRegister, shiftRegister_nxt;
    reg  [32:0] alu_out;
    
// Wire Assignments
    // Todo
    reg         dividend_flag;  
    reg         ready, ready_nxt;
    assign o_data = shiftRegister;
    assign o_done = ready;

// Always Combination
    always @(*) begin
        case(state)
            IDLE: begin
               ready_nxt = 0;
            end
            MUL : begin
                if(counter == 5'd31) ready_nxt = 1;
                else ready_nxt = 0;
            end
            DIV : begin
                if(counter == 5'd31) ready_nxt = 1;
                else ready_nxt = 0;
            end
            ADD : ready_nxt = 1;
            SUB : ready_nxt = 1;
            AND : ready_nxt = 1;
            OR : ready_nxt = 1;
            SLT : ready_nxt = 1;
            SRA : ready_nxt = 1;
            OUT : ready_nxt = 0;
            default : ready_nxt = 0;
        endcase
    end

 // Combinational always block // use "=" instead of "<=" in  always @(*) begin
    // Todo 1: Next-state logic of state machine
    always @(*) begin
        case(state)
            IDLE: begin
                if(!i_valid) state_nxt = IDLE; 
                else begin
                    case(i_inst)
                        3'd0: state_nxt = ADD;
                        3'd1: state_nxt = SUB;
                        3'd2: state_nxt = AND;
                        3'd3: state_nxt = OR;
                        3'd4: state_nxt = SLT;
                        3'd5: state_nxt = SRA;
                        3'd6: state_nxt = MUL;
                        3'd7: state_nxt = DIV;
                        default: state_nxt = IDLE;
                    endcase
                end
            end
            MUL : begin
                if(counter == 5'd31) state_nxt = OUT;
                else state_nxt = MUL;
            end
            DIV : begin
                if(counter == 5'd31) state_nxt = OUT;
                else state_nxt = DIV;
            end
            ADD : state_nxt = OUT;
            SUB : state_nxt = OUT;
            AND : state_nxt = OUT;
            OR: state_nxt = OUT;
            SLT : state_nxt = OUT;
            SRA : state_nxt = OUT;

            OUT : state_nxt = IDLE;
            default : state_nxt = IDLE;
        endcase
    end
    // inout
    
    // load in B, A will be loaded in shift register
    always @(*) begin
        case(state)
            IDLE: begin
                if (i_valid) alu_in_nxt = i_B;
                else       alu_in_nxt = 0;
            end
            OUT : alu_in_nxt = 0;
            default: alu_in_nxt = alu_in;
        endcase
    end


    
    // Todo: Counter
    // if we are in multiple or division, counter will add until it reaches 31
    always @(*) begin
        if(state == MUL || state == DIV) begin
            counter_nxt = counter + 1;
        end
        else counter_nxt = 0;
    end
    // Todo: ALU output
    always @(*) begin
        alu_out = 0;
        dividend_flag = 0;
        case(state)
            MUL: begin
                if(shiftRegister[0] == 1) begin
                    alu_out = shiftRegister[63:32] + alu_in;
                    // $signed(in_A) + $signed(in_B)
                end
                else begin
                    alu_out = shiftRegister[63:32];
                end

            end
            DIV: begin
                // if remainder goes < 0, add divisor back
                dividend_flag = (shiftRegister[63:32] >= alu_in);
                if(dividend_flag) begin
                    alu_out = shiftRegister[63:32] - alu_in;
                end 
                else begin
                    alu_out = shiftRegister[63:32];
                end
            end
            SRA: begin
                alu_out =$signed( shiftRegister[31:0]) >>> $signed( alu_in);
            end
            SLT: begin
                alu_out =$signed( shiftRegister[31:0]) < $signed( alu_in) ? 1 : 0 ;
            end  
            AND: begin
                alu_out = shiftRegister[31:0] & alu_in;
            end  
            OR: begin
                alu_out = shiftRegister[31:0] | alu_in;
            end  
            ADD: begin
		
                alu_out = $signed( shiftRegister[31:0]) + $signed( alu_in);
            end  
            SUB: begin
                
                alu_out = $signed(shiftRegister[31:0]) - $signed(alu_in);
            end  
        endcase
    end
    // Todo: output valid signal
    // first load i_A in shift register
    always @(*) begin
        case(state)
            IDLE: begin
                if(!i_valid) shiftRegister_nxt = 0; 
                else begin
                    if(i_inst == 3'd7)begin
                        shiftRegister_nxt = {{31{1'b0}}, i_A, {1'b0}}; 
                    end
                    else begin
                        shiftRegister_nxt = {{32{1'b0}}, i_A};
                    end
                end
            end
            MUL: begin
                shiftRegister_nxt = {alu_out, shiftRegister[31:1]};
            end
            DIV: begin
                if(counter == 31)begin
                    if(dividend_flag)begin
                        shiftRegister_nxt = {alu_out[31:0], shiftRegister[30:0], {1'b1}};
                    end
                    else begin
                        shiftRegister_nxt = {alu_out[31:0], shiftRegister[30:0], {1'b0}};
                    end
                end
                else begin
                    if(dividend_flag)begin
                        shiftRegister_nxt = {alu_out[30:0], shiftRegister[31:0], {1'b1}};
                    end
                    else begin
                        shiftRegister_nxt = {alu_out[30:0], shiftRegister[31:0], {1'b0}};
                    end
                end
            end
            ADD: begin
                shiftRegister_nxt = {32'b0, alu_out[31:0]};
                if ($signed(alu_out) > max_value ) begin
                    shiftRegister_nxt = 64'H000000007fffffff;
                end
                else if ($signed(alu_out) < min_value) begin
                    shiftRegister_nxt = 64'H0000000080000000;
                end
            end

            SUB: begin
                shiftRegister_nxt = {32'b0, alu_out[31:0]};
                if ($signed(alu_out) > max_value ) begin
                    shiftRegister_nxt = 64'H000000007fffffff;
                end
                else if ($signed(alu_out) < min_value) begin
                    shiftRegister_nxt = 64'H0000000080000000;
                end
            end
            AND: begin

                shiftRegister_nxt = {32'b0, alu_out[31:0]};
            end
            
            OR: begin
                shiftRegister_nxt = {32'b0, alu_out[31:0]};
            end  
            SLT: begin
                shiftRegister_nxt = {32'b0, alu_out[31:0]};
            end  
            SRA: begin
                shiftRegister_nxt = {32'b0, alu_out[31:0]};
            end  
            OUT: begin
                shiftRegister_nxt = shiftRegister;
            end
            default: begin
                shiftRegister_nxt = shiftRegister;
            end
        endcase
    end
    // Todo: Sequential always block
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            state <= IDLE;
            counter <= 0;
            shiftRegister <= 0;
            alu_in <= 0;
            ready <= 0;
        end
        else begin
            state <= state_nxt;
            counter <= counter_nxt;
            shiftRegister <= shiftRegister_nxt;
            alu_in <= alu_in_nxt;
            ready <= ready_nxt;
        end
    end

endmodule
