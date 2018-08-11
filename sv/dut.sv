interface dut_if #(parameter width=3, parameter no_of_TS_required=2) (
          input clk
          );

   import env_pkg::*;
   logic reset;
   logic [width-1:0] a;
   logic [width-1:0] b;
   logic             c;
   logic [width-1:0] TS_a_0;
   logic [width-1:0] TS_b_0;
   logic [width-1:0] TS_match_0;
   logic [width-1:0] TS_a_1;
   logic [width-1:0] TS_b_1;
   logic [width-1:0] TS_match_1;
   logic TS_ready_0;
   logic TS_ready_1;
   //training_set TS [no_of_TS_required-1:0];
   
   // TODO: Have to generalize for "n" TS's
   assign TS_a_0 = TS[0].a;
   assign TS_b_0 = TS[0].b;
   assign TS_match_0 = TS[0].match;
   assign TS_ready_0 = TS[0].TS_ready;
   assign TS_a_1 = TS[1].a;
   assign TS_b_1 = TS[1].b;
   assign TS_match_1 = TS[1].match;
   assign TS_ready_1 = TS[1].TS_ready;
   
   assign TS_ready = TS_ready_0 & TS_ready_1;
   

   task drive(logic [width-1:0] ia, logic [width-1:0] ib);
      // `uvm_info("dut_if", $sformatf("BEFORE drive regs a: %d b: %d", ia, ib), UVM_LOW)
      a = ia;
      b = ib;
      `uvm_info("dut_if", $sformatf("AFTER drive regs a: %d b: %d", ia, ib), UVM_LOW)
   endtask

   task get_TS();
     for(int i=0; i<no_of_TS_required; i++)
     begin
       `uvm_info("dut_if", $sformatf("DEBUG Training Set Index: %d a: %d b: %d match:%d", i, TS[i].a, TS[i].b, TS[i].match), UVM_HIGH)
     end
   endtask

   task drive_reset();
     `uvm_info("dut_if","Pulse generated on Reset ", UVM_LOW);
      reset = 1;
      `uvm_info("dut_if",$sformatf("DEBUG Reset Asserted; Reset = %b", reset), UVM_HIGH);
      #10 reset = 0;
      `uvm_info("dut_if",$sformatf("DEBUG Reset Deasserted; Reset = %b", reset), UVM_HIGH);
   endtask

   // always @(negedge clk) begin
   // DEPRECATED original way without pre_randomize call for reference
   // c_a.srandom(seed);
   // c_b.srandom(seed + 1);
   // randomize class txns using re-seed value
   // c_a.rprint();
   // c_b.rprint();
   // assign class txns to pins
   // a = c_a.get_num();
   // b = c_b.get_num();
   // end

endinterface

module dut #(parameter width=3, parameter no_of_TS_required=2) (
       input [width-1:0] a,
       input [width-1:0] b,
       input            clk,
       input            reset,
       output           c
       //output           TS [no_of_TS_required-1:0]      
       );

   import env_pkg::*;
   //training_set     TS [no_of_TS_required-1:0];
   reg [width-1:0]  match;
   integer i=0;

   // grab coverage automatically
   covergroup objective_cg;
      coverpoint match{
        option.auto_bin_max = 2**width;
      }
   endgroup

   objective_cg objective;

   // EX 1. DEFAULT a == b match
   assign c = (a == b);

   // EX2. b is all 1s cross with all values of a
   // assign c  = (&b);

   // EX3. free form
   // assign c  = (a[0] && b[0]) && (a[1] && b[1]) && (a[2] && b[2]);

   // assign match to value of a
   always @(posedge clk) begin
      if (reset) begin
         match <= 0;
      end
      else if (c) begin
         match <= a;
         // `uvm_info("DUT", $sformatf("!!!MATCH"), UVM_DEBUG)

         // not good but need to wait just after posedge clk to sample register
         #1;
         objective.sample();
         // Function defined in env_pkg;
         generate_TS_and_track_hit_bins(a,b,match);         
      end 
      else begin
         match <= '0;
      end


   end

   // initialize covergroup
   initial begin
      objective = new();
   end

endmodule
