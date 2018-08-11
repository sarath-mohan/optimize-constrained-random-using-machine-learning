// TOP LEVEL
module top#(parameter width=3) ();

`include "uvm_macros.svh"
   import uvm_pkg::*;
   import env_pkg::*;

   logic clk             = 0;
   //logic reset           = 1;
   //training_set TS;

   dut_if#(.width(width)) dif  (
                                .clk(clk)
                                //.reset(reset)		                
              );

   dut#(.width(width)) dut (
                            .a(dif.a),
                            .b(dif.b),
                            .c(dif.c),
                            .clk(clk),
                            .reset(dif.reset)
                            //.TS(dif.TS)
           );

   rseed_interface rseed_interface (
                              .clk(clk),
                              .reset(dif.reset)
                              );

   // kill block
   initial begin
      #50000;
      `uvm_warning("TOP", $sformatf("REACHED TIMEOUT"))
      $finish();
   end

   // make clock
   initial begin
      forever begin
         #5;
         clk = ~clk;
      end
   end

   initial begin
      //#15;
      //reset  = 0;
      dif.drive_reset();
   end

   initial begin
      uvm_config_db#(virtual rseed_interface)::set(null, "uvm_test_top", "rseed_interface", rseed_interface);
      uvm_config_db#(virtual dut_if#(width))::set(null, "uvm_test_top", "dif", dif);

      if ($test$plusargs("UVM_TESTNAME")) begin
         run_test();
      end else begin
         `uvm_fatal("TOP", "NOT a UVM_TEST")
      end
   end

endmodule
