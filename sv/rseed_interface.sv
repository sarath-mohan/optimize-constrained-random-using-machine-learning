interface rseed_interface (
                     input clk,
                     input reset
                     );

   bit                     trigger                = 0;
   bit                     code_coverage_trigger  = 0;
   time                    start_time             = 7;
   time                    interval_time          = 10;
   bit                     final_report           = 0;
   real                    coverage_value         = 0;
   int                     client_index           = 0;
   int                     max_objective          = 100;
   bit                     coverage_dump          = 0;
   real                    code_coverage_value    = -1;

   int                     unsigned seed;

   irand::master_seed      ms;

   string                  server  = "top_default_server";
   int                     port    = 9999; 
   bit                     generate_pulse_on_reset = 0;
   int                     beta_a = 0;
   int                     beta_b = 0;
   int                     beta_ready = 0;
   bit                     trigger_enable = 1;
   int                     max_rand_sim_count = 10;
   int                     ml_enabled = 0;
   int                     fsm_opt_enable = 0;
   int                     trigger_runDNN = 0;
   int                     in=1;
   int                     in_a=1;
   int                     in_b=1;
   int                     out=1;
   int                     out_to_update_queue=1;
   int                     DNN_train_done=0;

   function void get_instance();
      ms.get_instance();
      `uvm_info("MS", $sformatf("get_instance called"), UVM_DEBUG)
   endfunction

   // set the seed of the singleton
   function void set_seed(int unsigned s);

      // this is the atomic option of forcing the seed index to start over - replaced with pre_randomize version
      // `uvm_info("MS", $sformatf("removing the uvm_random_seed_table and setting uvm_global_random_seed"), UVM_HIGH)
      // uvm_pkg::uvm_random_seed_table_lookup.delete();

      seed  = s;
      ms.set_seed(s);
   endfunction

   function void set_code_coverage(real c);
      code_coverage_value  = c;
   endfunction

   function void print();
      // `uvm_info("TOP", $sformatf("master seed is %d", seed), UVM_DEBUG)
      `uvm_info("TOP", $sformatf("master coverage value is %d", coverage_value), UVM_MEDIUM)
   endfunction

   function real get_coverage_value();
      return ms.get_coverage_value();
   endfunction

   // Function to Generate Pulse on Reset; Called by TCL script when no improvement in Objective Function
   function void generate_reset();
      generate_pulse_on_reset  = 1;
   endfunction

   // Function to run DNN
   function runDNN(input int i);
      //`uvm_info("RSEED", "DEBUG: ENTERED Rseed: Check 1", UVM_LOW)
      in_b = i;
      //`uvm_info("RSEED", "DEBUG: ENTERED Rseed: Check 2", UVM_LOW)
      trigger_runDNN = ~trigger_runDNN;
      //`uvm_info("RSEED", "DEBUG: ENTERED Rseed: Check 3", UVM_LOW)
      //runDNN = out;
   endfunction


   initial begin
      #0;

      ms                 = irand::master_seed::get_instance();
      server             = ms.server;
      port               = ms.port;
      max_objective      = ms.max_objective;
      seed               = ms.return_seed();
      `uvm_info("RS", $sformatf("DEBUG ntb_random_seed: %d, server: %s, port: %d, max_objective: %d, max_rand_sim_count: %d, ml_enabled: %d, fsm_opt_enable: %d ", seed, server, port, max_objective, max_rand_sim_count, ml_enabled, fsm_opt_enable), UVM_LOW)
      `uvm_info("RS", $sformatf("master coverage value is %d", coverage_value), UVM_MEDIUM)

   end

   initial begin
      $value$plusargs("start_time=%d", start_time);
      $value$plusargs("interval_time=%d", interval_time);
      $value$plusargs("client_index=%d", client_index);
      $value$plusargs("coverage_dump=%d", coverage_dump);
      $value$plusargs("max_rand_sim_count=%d", max_rand_sim_count);
      $value$plusargs("ml_enabled=%d", ml_enabled);
      $value$plusargs("fsm_opt_enable=%d", fsm_opt_enable);

      // if we want to dump coverage dump it here
      if (coverage_dump) begin
         $coverage_dump();
         `uvm_info("RS", $sformatf("coverage_dump for previous"), UVM_LOW)
      end

      #(start_time);
      forever begin

         fork

            begin
               #(interval_time - 1);

               // coverage_dump is only valid is the postpone region which is problematic
               // kick off this loop to end just before the eval below
               if (coverage_dump) begin
                  $coverage_dump($sformatf("client_index_%0d", client_index));
                  `uvm_info("RS", $sformatf("coverage_dump for previous"), UVM_LOW)
               end

            end

            begin
               #(interval_time);


               // use variable instead of file to pass over coverage value
               coverage_value                 = dut.objective.match.get_coverage();
               ms.set_coverage_value(coverage_value);

               `uvm_info("TOP", $sformatf("INFO STATUS :  SV : %0t : a = %d, b = %d, c = %d, match = %d, seed = %d, cg = %f, cc = %f",
                                          $time,
                                          dut.a,
                                          dut.b,
                                          dut.c,
                                          dut.match,
                                          ms.return_seed(),
                                          ms.get_coverage_value(),
                                          code_coverage_value
                                          ), UVM_HIGH)

               if (coverage_dump && (reset==0)) begin
                  `uvm_info("RS", $sformatf("coverage_dump"), UVM_LOW)
                  code_coverage_trigger  = ~code_coverage_trigger;
               end

               if (reset == 0)
                  // trigger_enable prevents the triggering of TCL script when not expected;
                  // For Example, when traversing previous hit stages in an FSM after reset;
                  // TODO: Generate count to generalize trigger_enable for all designs !
                  if (trigger_enable) trigger  = ~trigger;
                  //else trigger_enable = 1;

               if (ms.get_coverage_value() >= ms.max_objective && (reset==0)) begin
                  `uvm_info("RS", $sformatf("COVERAGE GOAL MET coverage: %d max_objective: %d", ms.get_coverage_value(), ms.max_objective), UVM_LOW)
                  // $finish();
                  final_report  = 1;
               end
            end
         join
      end
   end

endinterface
