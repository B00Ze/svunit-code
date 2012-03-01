//###############################################################
//
//  Licensed to the Apache Software Foundation (ASF) under one
//  or more contributor license agreements.  See the NOTICE file
//  distributed with this work for additional information
//  regarding copyright ownership.  The ASF licenses this file
//  to you under the Apache License, Version 2.0 (the
//  "License"); you may not use this file except in compliance
//  with the License.  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing,
//  software distributed under the License is distributed on an
//  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//  KIND, either express or implied.  See the License for the
//  specific language governing permissions and limitations
//  under the License.
//
//###############################################################

`ifndef __SVUNIT_UVM_TEST_SV__
`define __SVUNIT_UVM_TEST_SV__

`include "uvm_macros.svh"
`include "svunit_idle_uvm_domain.sv"


import uvm_pkg::*;

//------------------------------------------------------------
// this test sets up the jump from post_shutdown to pre_reset
// and defines the static methods used to gate the progress
// at pre_reset (start) and main (finish)
//------------------------------------------------------------
class svunit_uvm_test extends uvm_test;

  `uvm_component_utils(svunit_uvm_test)

  static local event m_start;
  static local bit   m_start_e;

  static local event m_finish;
  static local bit   m_finish_e;

  function new(string name = "", uvm_component parent = null);
    super.new(name, parent);

    m_start_e = 0;
    m_finish_e = 0;
  endfunction

  static function void start();
    -> m_start;
    m_start_e = 1;
  endfunction

  static function void finish();
    -> m_finish;
    m_finish_e = 1;
  endfunction

  task pre_reset_phase(uvm_phase phase);
    phase.raise_objection(null);
    if (!m_start_e) @m_start;
    m_start_e = 0;
    phase.drop_objection(null);
  endtask

  task main_phase(uvm_phase phase);
    phase.raise_objection(null);
    if (!m_finish_e) @m_finish;
    m_finish_e = 0;
    phase.drop_objection(null);
  endtask

  task post_shutdown_phase(uvm_phase phase);
    phase.jump(uvm_pre_reset_phase::get());
  endtask
endclass


//------------------------------------------------------
// global help methods for calling start and finish for
// the svunit_uvm_test
//------------------------------------------------------
task svunit_uvm_test_start();
  if ($time == 0) #1;
  #0 svunit_uvm_test::start();
  #0;
endtask
task svunit_uvm_test_finish();
  #0 svunit_uvm_test::finish();
  #0;
endtask


//------------------------------------------------------------
// global to instantiate and invoke the test. only happens on
// the initial call. for subsequent calls, nothing happens.
//------------------------------------------------------------
task svunit_uvm_test_inst(string test_name = "svunit_uvm_test");
  fork
    begin
      uvm_root top;
      uvm_component test;

$display("WIDGET");
      top = uvm_root::get();
$display("GOOFY");
      void'(svunit_idle_uvm_domain::get_common_domain());
$display("GUMBO");

      test = top.get_child("uvm_test_top");

      //--------------------------------------------------------------------------------------
      // if no test is running yet (i.e this is the first call to svunit_uvm_test_inst), setup
      // the svunit_idle_uvm_domain and invoke the svunit_uvm_test. Breeze by this otherwise.
      //--------------------------------------------------------------------------------------
      if (test == null) begin
        top.run_test("svunit_uvm_test");
      end
    end
  join_none
endtask

`endif