package env_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"

parameter width = 4;
parameter no_of_TS_required = 2;
typedef struct { 
   bit [width-1:0] a;
   bit [width-1:0] b;
   bit [width-1:0] match;
   bit TS_ready;
} training_set; 

typedef bit [width-1:0] bin;
//typedef bin output_bins_hit[integer];
typedef integer output_bins_hit[bin];

training_set TS [no_of_TS_required-1:0];
output_bins_hit OUT_HIT;
output_bins_hit IN_to_update_queue;

integer i = 0;
integer j = no_of_TS_required;
integer TS_index = 0;

function void generate_TS_and_track_hit_bins(bit [width-1:0] a, bit [width-1:0] b, bit [width-1:0] match);
   `uvm_info("ENV_PKG", "A and B matching", UVM_LOW)
   `uvm_info("ENV_PKG", "Generate training sets; Track output bins hit", UVM_LOW)
   //[Input=0 and Match = 0] cannot be used for solving the linear equation 
   if(i<no_of_TS_required && (match!=0))
      begin
        TS[i].a     = a;
   	TS[i].b     = b;
    	TS[i].match = match;
        TS[i].TS_ready = 1;
        TS_index = i;
        //OUT_HIT[i] = match;
        OUT_HIT[match] = 1;
        //`uvm_info("ENV_PKG", $sformatf("Match is: %d; OUT_HIT[i]= %d", match, OUT_HIT[i]), UVM_LOW)
        `uvm_info("ENV_PKG", $sformatf("Match is: %d; OUT_HIT[match]= %d", match, OUT_HIT[match]), UVM_HIGH)
        i = i+1;  
      end
   else 
   begin 
      //OUT_HIT[j] = match;
      OUT_HIT[match] = 1;
      //`uvm_info("ENV_PKG", $sformatf("Match is: %d; OUT_HIT[i]= %d", match, OUT_HIT[j]), UVM_LOW)
      `uvm_info("ENV_PKG", $sformatf("Match is: %d; OUT_HIT[match]= %d", match, OUT_HIT[match]), UVM_HIGH)
      //j = j+1;
   end
endfunction

class ms_sequence_item extends uvm_sequence_item;

   irand::master_seed ms;
   bit ms_enable = 1;

   function new();
      ms = irand::master_seed::get_instance();
   endfunction

   function void pre_randomize();

      if (ms_enable) begin
         `uvm_info("pre_randomize", $sformatf("pre_randomize started"), UVM_DEBUG)
         ms_run();
      end

   endfunction

   function void ms_run();
      // TODO using the UVM seeding mechanism
      // string s;
      // string b;

      string inst_id;
      string type_id;
      string type_id2;

      // use generic method to reseed - needed for non-uvm things
      // this.srandom(ms.get_seed());

      if (get_full_name() == "") begin
         inst_id  = "__global__";
      end else begin
         inst_id           = get_full_name();
      end

      type_id           = get_type_name();
      type_id2          = {uvm_instance_scope(), type_id};

      if(uvm_pkg::uvm_random_seed_table_lookup.exists(inst_id)) begin
         // `uvm_info("pre_randomize", $sformatf("found inst_id: %s", inst_id), UVM_LOW)
         if(uvm_pkg::uvm_random_seed_table_lookup[inst_id].seed_table.exists(type_id2)) begin
            // remove the seed_table - debug below shows that count keeps it unique
            // `uvm_info("pre_randomize",
            //           $sformatf("removing the uvm_random_seed_table for inst_id: %s and type_id2: %s count: %d",
            //                     inst_id,
            //                     type_id2,
            //                     uvm_pkg::uvm_random_seed_table_lookup[inst_id].count[type_id2]
            //                     ),
            //           UVM_LOW)
            uvm_pkg::uvm_random_seed_table_lookup[inst_id].seed_table.delete(type_id2);
         end
      end else begin
         // `uvm_info("pre_randomize", $sformatf("did not find inst_id: %s and type_id2: %s", inst_id, type_id2), UVM_LOW)
      end

      // TODO using the UVM seeding mechanism it is possible to be better with random stability
      // reseed using the uvm built-in$sformatf("num is: %d", num)
      reseed();

      // DEBUG TO PRINT seed table tree
      // if ( uvm_pkg::uvm_random_seed_table_lookup.first(s) ) begin
      //    do
      //      begin
      //         `uvm_info("MS_ITEM", $sformatf("%s get_type_name: %s get_full_name: %s", s, get_type_name(), get_full_name()), UVM_LOW)
      //         if ( uvm_pkg::uvm_random_seed_table_lookup[s].seed_table.first(b) ) begin
      //            do
      //              begin
      //                 `uvm_info("MS_ITEM", $sformatf("%s", b), UVM_LOW)
      //              end
      //                   while (uvm_pkg::uvm_random_seed_table_lookup[s].seed_table.next(b));
      //         end
      //      end
      //    while (uvm_pkg::uvm_random_seed_table_lookup.next(s));
      // end

      // `uvm_info("CB", $sformatf("class base for %i running pre_randomize"), UVM_DEBUG)
   endfunction

endclass

// the txn
class num_sequence_item extends ms_sequence_item;
   // `uvm_object_param_utils(num_sequence_item#(width));
   //virtual rseed_interface rseed_interface;
   rand logic [(width-1):0] num;
   //logic [(width-1):0] num_inside_queue[$]='{3'd0,3'd1,3'd2,3'd3,3'd4,3'd5,3'd6,3'd7};
   logic [(width-1):0] num_inside_queue[$];
   logic [(width-1):0] feed_num_inside_queue[$];
   logic [(width-1):0] temp;
   logic [(width-1):0] i = 0;
   logic [(width-1):0] num_range_dyn_array[];
   int beta_a_local;
   int out;

   function new();
      super.new();
      repeat(2**width) num_inside_queue.push_back(i++); 
   endfunction

   // not needed handled by parent class
   // function void pre_randomize();
   //    super.pre_randomize();
   // endfunction

   // randomize and print
   function void rprint();
      this.randomize() with {(num inside num_inside_queue);};
      `uvm_info("CR", $sformatf("num is: %d", num), UVM_HIGH)
   endfunction

   function logic [(width-1):0] get_num();
      return num;
   endfunction

   //function void update_constraint(const ref logic [6:0][(width-1):0] input_array);
   function void update_constraint(integer beta_value);
      num_inside_queue = {};
      i = 0;
      `uvm_info("ENV_PKG", "Updating Constraints", UVM_LOW)
      `uvm_info("ENV_PKG", $sformatf("BEFORE UPDATE num_inside_queue contains: %0p", num_inside_queue), UVM_LOW)
      repeat(2**width) 
        if(!(OUT_HIT.exists(i))) begin 
           num_inside_queue.push_back(i++/beta_value);
           break;
        end
        else i++;
      //`uvm_info("ENV_PKG", $sformatf("DEBUG BEFORE feed_num_inside_queue contains: %0p", feed_num_inside_queue), UVM_LOW)
      
      //repeat(2**width) feed_num_inside_queue.push_back(i++);
      //`uvm_info("ENV_PKG", "Updating Constraints", UVM_LOW)
      //`uvm_info("ENV_PKG", $sformatf("BEFORE UPDATE num_inside_queue contains: %0p", num_inside_queue), UVM_LOW)
      //`uvm_info("ENV_PKG", $sformatf("DEBUG BEFORE feed_num_inside_queue contains: %0p", feed_num_inside_queue), UVM_LOW)
      //foreach(OUT_HIT[i]) begin
      //   temp = 3'd0;
      //   feed_num_inside_queue.delete(int'(temp));  //feed_num_inside_queue.find_first_index(x) with (x == 0)));
      //end
      //uvm_info("ENV_PKG", $sformatf("DEBUG AFTER feed_num_inside_queue contains: %0p", feed_num_inside_queue), UVM_LOW)
      // TODO: Divide OUT_HIT/beta; Pass Beta Value as input to Function for A and B!
      //foreach(OUT_HIT[i]) IN_to_update_queue[i]=OUT_HIT[i]/beta_value;
      //foreach(IN_to_update_queue[i]) num_inside_queue.push_back(IN_to_update_queue[i]);
      //foreach(OUT_HIT[i]) IN_to_update_queue[i]=OUT_HIT[i]/beta_value;
      //foreach(IN_to_update_queue[i]) num_inside_queue.push_back(IN_to_update_queue[i]);
      //foreach(OUT_HIT[i]) num_inside_queue.push_back(OUT_HIT[i]);  
      `uvm_info("ENV_PKG", $sformatf("AFTER UPDATE num_inside_queue contain: %0p", num_inside_queue), UVM_LOW)
   endfunction

   function int update_constraint_dnn();
      //num_inside_queue = {};
      i = 0;
      out = 0;
      `uvm_info("ENV_PKG", "Updating Constraints (using ANN)", UVM_LOW)
      //`uvm_info("ENV_PKG", $sformatf("BEFORE UPDATE num_inside_queue contains: %0p", num_inside_queue), UVM_LOW)
      repeat(2**width) 
        //`uvm_info("ENV_PKG", "DEBUG Check 1", UVM_LOW)
        if(!(OUT_HIT.exists(i))) begin 
           `uvm_info("ENV_PKG", $sformatf("Output Bin NOT HIT: %0d", i), UVM_LOW)
           //out=rseed_interface.runDNN(i);
           //rseed_interface.in=i;
           //out=rseed_interface.out;
           return i;
           //`uvm_info("ENV_PKG", "DEBUG Check 2", UVM_LOW)
           //num_inside_queue.push_back(out);
           break;
        end
        else i++;
      //`uvm_info("ENV_PKG", $sformatf("AFTER UPDATE num_inside_queue contain: %0p", num_inside_queue), UVM_LOW)
   endfunction

   
endclass

class test0 extends uvm_test;
   `uvm_component_utils(test0)

   //parameter width  = 3;

   time interval_time;

   num_sequence_item c_a, c_b;
   
   logic [6:0][(width-1):0] array_to_update_queue;   
   logic [width-1:0] i;
   int in_DNN_run_a,in_DNN_run_b,out_to_update_queue;

   virtual rseed_interface rseed_interface;
   virtual dut_if dif;

   function new(string name = "test0", uvm_component parent = null);
      super.new(name, parent);

      if (!uvm_config_db#(virtual rseed_interface)::get(this, "", "rseed_interface", rseed_interface)) begin
         `uvm_fatal("test0", "Failed to get rseed_interface")
      end
      if (!uvm_config_db#(virtual dut_if)::get(this, "", "dif", dif)) begin
         `uvm_fatal("test0", "Failed to get dut_if")
      end

      // get interval time
      $value$plusargs("interval_time=%d", interval_time);
      
      c_a  = new();
      c_b  = new();

   endfunction

   virtual task run_phase(uvm_phase phase);
      phase.raise_objection(this);
      `uvm_info("STATUS", "starting test", UVM_MEDIUM)

      fork
         begin
            // this is the forever loop that represents the uvm driver
            forever begin
               @(negedge dif.clk);
               if (rseed_interface.generate_pulse_on_reset == 1) begin
	          //rseed_interface.trigger_enable = 0;       // Debug Purpose !! Double Check !!
                  `uvm_info("ENV_PKG", $sformatf("DEBUG Before Reset; generate_pulse_on_reset= %b", rseed_interface.generate_pulse_on_reset), UVM_HIGH)
	          //`uvm_info("ENV_PKG", "DEBUG Pulse on Reset Generated", UVM_LOW)
                  dif.drive_reset;
                  rseed_interface.generate_pulse_on_reset = 0;
                  
                  `uvm_info("ENV_PKG", $sformatf("DEBUG After Reset; generate_pulse_on_reset= %b", rseed_interface.generate_pulse_on_reset), UVM_HIGH)
                  `uvm_info("ENV_PKG", $sformatf("DEBUG ENV_PKG BETA_A= %d; BETA_B = %d; BETA_ready = %d", rseed_interface.beta_a, rseed_interface.beta_b, rseed_interface.beta_ready), UVM_HIGH)
                  //array_to_update_queue = '{3'b000,3'b001,3'b010,3'b011,3'b100,3'b101,3'b110 };
                  //if (rseed_interface.beta_ready) begin
                  //  c_a.update_constraint(rseed_interface.beta_a);
                  //  c_b.update_constraint(rseed_interface.beta_b);
                  //end
	       end
               //if(dif.reset == 1)
               //   `uvm_info("ENV_PKG", "Reset Asserted: No signals driven on inputs", UVM_LOW)
               else begin
                  // randomize class txns using re-seed value
                  dif.get_TS();
                  if (rseed_interface.beta_ready) begin
                    c_a.update_constraint(rseed_interface.beta_a);
                    c_b.update_constraint(rseed_interface.beta_b);
                  end
                  //rseed_interface.in_a = c_a.update_constraint_dnn();
                  //rseed_interface.in_b = c_b.update_constraint_dnn();
                  if (rseed_interface.DNN_train_done) begin
                    rseed_interface.runDNN(c_b.update_constraint_dnn());
                    #1;
                    //in_DNN_run_a = c_a.update_constraint_dnn();
                    //in_DNN_run_b = c_b.update_constraint_dnn();
                    //out_to_update_queue=rseed_interface.runDNN(in_DNN_run_a);
                    c_a.num_inside_queue = {};
                    c_b.num_inside_queue = {};
                    c_a.num_inside_queue.push_back(rseed_interface.out_to_update_queue);
                    c_b.num_inside_queue.push_back(rseed_interface.out_to_update_queue);
                    `uvm_info("ENV_PKG", $sformatf("AFTER UPDATE num_inside_queue contain: %0p", c_a.num_inside_queue), UVM_LOW)
                    `uvm_info("ENV_PKG", $sformatf("AFTER UPDATE num_inside_queue contain: %0p", c_b.num_inside_queue), UVM_LOW)
                  end
                  c_a.rprint();
                  c_b.rprint();
                  //`uvm_info("test0", $sformatf("DEBUG drive with a: %d b: %d", c_a.get_num(), c_b.get_num()), UVM_LOW)
                  
                  // TODO making this work would be closer to a driver  
                  dif.drive(c_a.get_num(), c_b.get_num());
               end
            end
         end
         // this exits the fork if the test reaches its goal
         wait (rseed_interface.final_report == 1);
      join_any
      disable fork;

      // wait just a little to run any other cleanup things
      #(interval_time);
      #(interval_time);
      phase.drop_objection(this);
   endtask

endclass
endpackage
