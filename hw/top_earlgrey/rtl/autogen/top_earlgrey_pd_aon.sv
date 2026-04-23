// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// ------------------- W A R N I N G: A U T O - G E N E R A T E D   C O D E !! -------------------//
// PLEASE DO NOT HAND-EDIT THIS FILE. IT HAS BEEN AUTO-GENERATED WITH THE FOLLOWING COMMAND:
//
// util/topgen.py -t hw/top_earlgrey/data/top_earlgrey.hjson
//                -o hw/top_earlgrey/


module top_earlgrey_pd_aon #(
  // Auto-inferred parameters
  // parameters for uart1
  // parameters for aon_timer_aon
) (

  // Inter-module Signal External type
  output logic       aon_timer_aon_nmi_wdog_timer_bark_o,
  input  logic       pwrmgr_aon_low_power_i,
  input  lc_ctrl_pkg::lc_tx_t       lc_ctrl_lc_escalate_en_i,
  output logic       pwrmgr_aon_wakeups_o,
  output logic       pwrmgr_aon_rstreqs_o,
  input  tlul_pkg::tl_h2d_t       uart1_tl_req_i,
  output tlul_pkg::tl_d2h_t       uart1_tl_rsp_o,
  input  tlul_pkg::tl_h2d_t       aon_timer_aon_tl_req_i,
  output tlul_pkg::tl_d2h_t       aon_timer_aon_tl_rsp_o,
  input  logic       cio_uart1_rx_p2d_i,
  output logic       cio_uart1_tx_d2p_o,
  output logic       cio_uart1_tx_en_d2p_o,

  output logic [10:0] intr_vector_o,

  output logic [1:0] alert_tx_o,
  input  logic [1:0] alert_rx_i,

  // Manual DFT signals 
  input                        scan_rst_ni, // reset used for test mode
  input                        scan_en_i,
  input prim_mubi_pkg::mubi4_t scanmode_i   // lc_ctrl_pkg::On for Scan
);

  import tlul_pkg::*;
  import top_pkg::*;
  import tl_main_pkg::*;
  import top_earlgrey_pkg::*;
  // Compile-time random constants
  import top_earlgrey_rnd_cnst_pkg::*;

  // Local Parameters

  // Signals

  // Interrupt source list
  logic intr_uart1_tx_watermark;
  logic intr_uart1_rx_watermark;
  logic intr_uart1_tx_done;
  logic intr_uart1_rx_overflow;
  logic intr_uart1_rx_frame_err;
  logic intr_uart1_rx_break_err;
  logic intr_uart1_rx_timeout;
  logic intr_uart1_rx_parity_err;
  logic intr_uart1_tx_empty;
  logic intr_aon_timer_aon_wkup_timer_expired;
  logic intr_aon_timer_aon_wdog_timer_bark;

  // Peripheral Instantiation

  uart #(
    .AlertAsyncOn(alert_handler_reg_pkg::AsyncOn[0]),
    .AlertSkewCycles(top_pkg::AlertSkewCycles)
  ) u_uart1 (

    // Input
    .cio_rx_i   (cio_uart1_rx_p2d_i),

    // Output
    .cio_tx_o   (cio_uart1_tx_d2p_o),
    .cio_tx_en_o(cio_uart1_tx_en_d2p_o),

    // Interrupt
    .intr_tx_watermark_o (intr_uart1_tx_watermark),
    .intr_rx_watermark_o (intr_uart1_rx_watermark),
    .intr_tx_done_o      (intr_uart1_tx_done),
    .intr_rx_overflow_o  (intr_uart1_rx_overflow),
    .intr_rx_frame_err_o (intr_uart1_rx_frame_err),
    .intr_rx_break_err_o (intr_uart1_rx_break_err),
    .intr_rx_timeout_o   (intr_uart1_rx_timeout),
    .intr_rx_parity_err_o(intr_uart1_rx_parity_err),
    .intr_tx_empty_o     (intr_uart1_tx_empty),

    // alert_handler[1]: fatal_fault
    .alert_tx_o(alert_tx_o[0]),
    .alert_rx_i(alert_rx_i[0]),

    // Inter-module signals
    .lsio_trigger_o(),
    .racl_policies_i(top_racl_pkg::RACL_POLICY_VEC_DEFAULT),
    .racl_error_o(),
    .tl_i(uart1_tl_req_i),
    .tl_o(uart1_tl_rsp_o),

    // Clock and reset connections
    .clk_i (clkmgr_aon_clocks.clk_io_div4_peri),
    .rst_ni (rstmgr_aon_resets.rst_lc_io_div4_n[rstmgr_pkg::Domain0Sel])
  );

  aon_timer #(
    .AlertAsyncOn(alert_handler_reg_pkg::AsyncOn[1]),
    .AlertSkewCycles(top_pkg::AlertSkewCycles)
  ) u_aon_timer_aon (

    // Interrupt
    .intr_wkup_timer_expired_o(intr_aon_timer_aon_wkup_timer_expired),
    .intr_wdog_timer_bark_o   (intr_aon_timer_aon_wdog_timer_bark),

    // alert_handler[31]: fatal_fault
    .alert_tx_o(alert_tx_o[1]),
    .alert_rx_i(alert_rx_i[1]),

    // Inter-module signals
    .nmi_wdog_timer_bark_o(aon_timer_aon_nmi_wdog_timer_bark_o),
    .wkup_req_o(pwrmgr_aon_wakeups_o),
    .aon_timer_rst_req_o(pwrmgr_aon_rstreqs_o),
    .lc_escalate_en_i(lc_ctrl_lc_escalate_en_i),
    .sleep_mode_i(pwrmgr_aon_low_power_i),
    .racl_policies_i(top_racl_pkg::RACL_POLICY_VEC_DEFAULT),
    .racl_error_o(),
    .tl_i(aon_timer_aon_tl_req_i),
    .tl_o(aon_timer_aon_tl_rsp_o),

    // Clock and reset connections
    .clk_i (clkmgr_aon_clocks.clk_io_div4_timers),
    .clk_aon_i (clkmgr_aon_clocks.clk_aon_timers),
    .rst_ni (rstmgr_aon_resets.rst_lc_io_div4_n[rstmgr_pkg::DomainAonSel]),
    .rst_aon_ni (rstmgr_aon_resets.rst_lc_aon_n[rstmgr_pkg::DomainAonSel])
  );


  // Interrupt assignments
  // Interrupt vector to PLIC rv_plic in power domain main
  assign intr_vector_o = {
    intr_aon_timer_aon_wdog_timer_bark,
    intr_aon_timer_aon_wkup_timer_expired,
    intr_uart1_tx_empty,
    intr_uart1_rx_parity_err,
    intr_uart1_rx_timeout,
    intr_uart1_rx_break_err,
    intr_uart1_rx_frame_err,
    intr_uart1_rx_overflow,
    intr_uart1_tx_done,
    intr_uart1_rx_watermark,
    intr_uart1_tx_watermark
  };

endmodule

