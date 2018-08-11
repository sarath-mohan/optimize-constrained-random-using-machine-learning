interface dut_if(
    input Clock
    //input Reset
    );
    
    logic Reset = 1;
    logic [2:0] A;
    logic [2:0] B; 
    logic Output1, Output2;
    logic [2:0] Status;

    task drive(logic [2:0] iA, logic [2:0] iB);
	A = iA;
	B = iB;
	`uvm_info("dut_if",$sformatf("AFTER drive regs A: %b B: %b", iA, iB), UVM_LOW);
    endtask
    

    task drive_reset();
       `uvm_info("dut_if","Pulse on Reset Generated", UVM_LOW);
       Reset = 1;
       `uvm_info("dut_if",$sformatf("DEBUG Reset Asserted; Reset = %b", Reset), UVM_LOW);
       #15 Reset = 0;
       `uvm_info("dut_if",$sformatf("DEBUG Reset Deasserted; Reset = %b", Reset), UVM_LOW);
    endtask
    
endinterface

module dut(
    input wire Clock,
    input wire Reset,
    input wire [2:0] A,
    input wire [2:0] B,

    output wire Output1,
    output wire Output2,
    output reg[2:0] Status
    );

localparam STATE_Initial = 3'd0,
           STATE_1 = 3'd1,                
           STATE_2 = 3'd2,
           STATE_3 = 3'd3,
           STATE_4 = 3'd4,
           STATE_5_PlaceHolder = 3'd5,
           STATE_6_PlaceHolder = 4'd6,
           STATE_7_PlaceHolder = 3'd7;

reg [2:0] CurrentState;
reg [2:0] NextState;


covergroup objective_cg;
  coverpoint CurrentState {
	bins state_initial = {STATE_Initial};
	bins state1 = {STATE_1};
	bins state2 = {STATE_2};
	bins state3 = {STATE_3};
	bins state4 = {STATE_4};
	ignore_bins states567 = {STATE_5_PlaceHolder, STATE_6_PlaceHolder, STATE_7_PlaceHolder};
	}
endgroup

objective_cg objective;

initial begin
	objective = new();
end

assign Output1 = (CurrentState == STATE_1) | (CurrentState == STATE_2);
assign Output2 = (CurrentState == STATE_2);

always@(*) begin
    Status = 3'b000;
    case (CurrentState) 
        STATE_Initial: Status = 3'b010;
        STATE_1:       Status = 3'b011; 
        STATE_2:       Status = 3'b010;
        STATE_3:       Status = 3'b011;
        STATE_4:       Status = 3'b100;
    endcase
end

always@(posedge Clock) begin
    if(Reset) CurrentState <= STATE_Initial;
    else CurrentState <= NextState;
    #1 objective.sample();
end

always@(*) begin
    NextState = CurrentState;
    case(CurrentState)
        STATE_Initial: begin
		NextState = STATE_1;
       		`uvm_info("dut","Current State: STATE_Initial", UVM_LOW)
		end
        STATE_1: begin
		if((A==3'b111)&&(B==3'b111)) NextState = STATE_2;
                else NextState = STATE_4;
		`uvm_info("dut","Current State: STATE_1", UVM_LOW)
                end
        STATE_2: begin
		if ((A==3'b111)&&(B==3'b111)) NextState = STATE_3;
		else NextState = STATE_4;
		`uvm_info("dut","Current State: STATE_2", UVM_LOW)
                end
        STATE_3: begin
		if((A==3'b111)&&(B==3'b111)) NextState = STATE_4;
                else NextState = STATE_Initial;
		`uvm_info("dut","Current State: STATE_3", UVM_LOW)
                end
        STATE_4: begin
		`uvm_info("dut","Current State: STATE_4", UVM_LOW)
        	end
        STATE_5_PlaceHolder: begin
		NextState = STATE_Initial;
		`uvm_info("dut","Current State: STATE_5_PlaceHolder", UVM_LOW)
                end
        STATE_6_PlaceHolder: begin
		NextState = STATE_Initial;
		`uvm_info("dut","Current State: STATE_6_PlaceHolder", UVM_LOW)
                end
        STATE_7_PlaceHolder: begin
		NextState = STATE_Initial;
		`uvm_info("dut","Current State: STATE_7_PlaceHolder", UVM_LOW)
                end
    endcase
end

endmodule
