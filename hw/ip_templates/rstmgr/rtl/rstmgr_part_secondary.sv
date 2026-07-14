// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Secondary partition of the split reset manager.
//
// This partition hosts the alert and CPU crash-dump capture logic and lives in
// a separate power domain from the primary partition (which hosts the register
// file and reset generation). It receives the crash-dump sources directly and
// exchanges the crash-dump register interface with the primary partition over
// the inter-partition p2s / s2p structs.

`include "prim_assert.sv"

module rstmgr_part_secondary
  import rstmgr_pkg::*;
#(
  // The secondary partition hosts a single alert (fatal_sec_test).
  parameter logic AlertAsyncOn = 1'b1,
  parameter int unsigned AlertSkewCycles = 1
) (
  // Secondary partition clock and reset
  input clk_sec_i,
  input rst_sec_ni,

  // Alert
  input  prim_alert_pkg::alert_rx_t alert_rx_i,
  output prim_alert_pkg::alert_tx_t alert_tx_o,

  // Interface to alert handler crash dump
  input alert_handler_pkg::alert_crashdump_t alert_dump_i,

  // Interface to cpu crash dump
  input rv_core_ibex_pkg::cpu_crash_dump_t cpu_dump_i,

  // Inter-partition signalling to/from the primary partition
  input  rstmgr_pkg::rstmgr_interpart_p2s_t interpart_p2s_i,
  output rstmgr_pkg::rstmgr_interpart_s2p_t interpart_s2p_o
);

  ////////////////////////////////////////////////////
  // Crash info capture                             //
  ////////////////////////////////////////////////////

  logic dump_capture;
  assign dump_capture = interpart_p2s_i.dump_capture;

  rstmgr_crash_info #(
    .CrashDumpWidth($bits(alert_handler_pkg::alert_crashdump_t))
  ) u_alert_info (
    .clk_i(clk_sec_i),
    .rst_ni(rst_sec_ni),
    .dump_i(alert_dump_i),
    .dump_capture_i(dump_capture & interpart_p2s_i.alert_info_en),
    .slot_sel_i(interpart_p2s_i.alert_info_index),
    .slots_cnt_o(interpart_s2p_o.alert_info_attr),
    .slot_o(interpart_s2p_o.alert_info)
  );

  rstmgr_crash_info #(
    .CrashDumpWidth($bits(rv_core_ibex_pkg::cpu_crash_dump_t))
  ) u_cpu_info (
    .clk_i(clk_sec_i),
    .rst_ni(rst_sec_ni),
    .dump_i(cpu_dump_i),
    .dump_capture_i(dump_capture & interpart_p2s_i.cpu_info_en),
    .slot_sel_i(interpart_p2s_i.cpu_info_index),
    .slots_cnt_o(interpart_s2p_o.cpu_info_attr),
    .slot_o(interpart_s2p_o.cpu_info)
  );

  // once dump is captured, no more information is captured until
  // re-enabled by software. The '.en.d' side is constant 0 and is tied off in
  // the primary partition, so only the '.en.de' (write-enable) crosses back.
  assign interpart_s2p_o.alert_info_ctrl_en_de = interpart_p2s_i.dump_capture_halt;
  assign interpart_s2p_o.cpu_info_ctrl_en_de   = interpart_p2s_i.dump_capture_halt;

  ////////////////////////////////////////////////////
  // Alerts                                         //
  ////////////////////////////////////////////////////

  // Pseudo alert (fatal_sec_test) used to bring up the split-IP tooling. Its
  // source is tied off for now (the alert never fires); wiring it to a real
  // fault/test source is future work.
  prim_alert_sender #(
    .AsyncOn(AlertAsyncOn),
    .SkewCycles(AlertSkewCycles),
    .IsFatal(1'b1)
  ) u_prim_alert_sender (
    .clk_i(clk_sec_i),
    .rst_ni(rst_sec_ni),
    .alert_test_i  ( 1'b0        ),
    .alert_req_i   ( 1'b0        ),
    .alert_ack_o   (             ),
    .alert_state_o (             ),
    .alert_rx_i    ( alert_rx_i  ),
    .alert_tx_o    ( alert_tx_o  )
  );

  // Assertions
  `ASSERT_KNOWN(AlertsKnownO_A, alert_tx_o)
  `ASSERT_KNOWN(S2pKnownO_A, interpart_s2p_o)

endmodule // rstmgr_part_secondary
