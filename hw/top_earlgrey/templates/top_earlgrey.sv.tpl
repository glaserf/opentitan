// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
${gencmd}
<%
import re
import topgen.lib as lib
from reggen.params import Parameter

feature_info = {}
cio_info = {}

# Bkdr loader targets
bkdr_loader_targets = ["cw340"]
gen_bkdr_loader = target["name"] in bkdr_loader_targets

ast = [m for m in top["module"] if m["name"] == "ast"]
assert(len(ast) == 1)
ast = ast[0]
%>\
<%include file="/toplevel_snippets/info_dicts.tpl" args="top=top, feature_info=feature_info, cio_info=cio_info" />\
% if gen_bkdr_loader:
`include "bkdr_loader.svh"
% endif

// This wrapper bundles the ${top["name"]} power domain wrapper together with the
// analog sensor top (AST) and any target-specific glue logic like FPGA clock generators.
// It exposes only the signals that need to cross to the chip-level (mio/dio interface
// to the padring, a few AST control signals consumed by the padring, and some special
// bi-directional direct connections to physical pads for the ASIC target.
module top_${top["name"]}_${target["name"]} #(
% if target["name"] == "asic":
  parameter bit SecRomCtrlDisableScrambling = 1'b0,
% elif target["name"] != "verilator":
%   if gen_bkdr_loader:
  parameter bit BkdrLoaderEn = 1'b1,
%   endif
  parameter BootRomInitFile = "",
  parameter OtpMacroMemInitFile = "",
% endif
  parameter pinmux_pkg::target_cfg_t PinmuxAonTargetCfg = pinmux_pkg::DefaultTargetCfg
) (
% if target["name"] == "verilator":
  // Clock and Reset
  input  logic clk_i,
  input  logic rst_ni,

% endif
  // Multiplexed I/O to/from padring
  input  logic [pinmux_reg_pkg::NMioPads-1:0] mio_in_i,
  output logic [pinmux_reg_pkg::NMioPads-1:0] mio_out_o,
  output logic [pinmux_reg_pkg::NMioPads-1:0] mio_oe_o,

  // Dedicated I/O to/from padring
  input  logic [pinmux_reg_pkg::NDioPads-1:0] dio_in_i,
  output logic [pinmux_reg_pkg::NDioPads-1:0] dio_out_o,
  output logic [pinmux_reg_pkg::NDioPads-1:0] dio_oe_o,

  // Pad attributes to padring
  output prim_pad_wrapper_pkg::pad_attr_t [pinmux_reg_pkg::NMioPads-1:0] mio_attr_o,
  output prim_pad_wrapper_pkg::pad_attr_t [pinmux_reg_pkg::NDioPads-1:0] dio_attr_o,

% if target["name"] != "verilator":
  // AST clocks and signals needed in the padring
  output ast_pkg::ast_clks_t    ast_base_clks_o,
  output prim_mubi_pkg::mubi4_t scanmode_o,
  output logic [3:0]            mux_iob_sel_o,

% endif
% if target["name"] == "asic":
  // Raw multiplexed pad inputs (tapped for the external clock and the PAD2AST_WIRES macro)
  input  logic [pinmux_reg_pkg::NMioPads-1:0] mio_in_raw_i,

  // Differential USB receiver interface (prim_usb_diff_rx lives at chip-level)
  output ast_pkg::ast_pwst_t                ast_pwst_h_o,
  output logic [ast_pkg::UsbCalibWidth-1:0] usb_io_pu_cal_o,
  input  logic                              usb_diff_rx_obs_i,
  output logic                              usb_dp_pullup_en_o,
  output logic                              usb_dn_pullup_en_o,
  input  logic                              usb_rx_d_i,
  output logic                              usb_rx_enable_o,

  // External POR (also feeds the AST directly)
  input  logic manual_in_por_n_i,

  // Manual pad attributes driven by sensor_ctrl
  output prim_pad_wrapper_pkg::pad_attr_t [3:0] sensor_ctrl_manual_pad_attr_o,

  // Direct connections to the chip pads
  `INOUT_AI CC1,
  `INOUT_AI CC2,
  `INOUT_AO IOA2,
  `INOUT_AO IOA3,
  inout     FLASH_TEST_MODE0,
  inout     FLASH_TEST_MODE1,
  inout     FLASH_TEST_VOLT,
  inout     OTP_EXT_VOLT\
% else:
  // USB connections to the chip-level USB mux glue
  output logic usb_dp_pullup_en_o,
%   if target["name"] == "verilator":
  output logic usb_dn_pullup_en_o,
  input  logic usb_rx_d_i,
  output logic usb_rx_enable_o,
  output logic usb_tx_d_o,
  output logic usb_tx_se0_o,
  output logic usb_tx_use_d_se0_o\
%   elif target["name"] == "cw305":
  output logic usb_dn_pullup_en_o\
%   elif target["name"] in ["cw310", "cw340"]:
  input  logic usb_rx_d_i,
  output logic usb_rx_enable_o\
%   endif
%   if target["name"] in ["cw305", "cw310", "cw340"]:
,

  // POR and clock inputs feeding the FPGA clock generator
  input  logic manual_in_por_n_i,
  input  logic manual_in_io_clk_i\
% endif
%   if target["name"] in ["cw305", "cw310"]:
,

  input  logic manual_in_por_button_n_i

%   endif
% endif

);

  import top_${top["name"]}_pkg::*;
  import prim_pad_wrapper_pkg::*;

  //////////////////////////////////
  // AST - Common for all targets //
  //////////////////////////////////

  // pwrmgr interface
  pwrmgr_pkg::pwr_ast_req_t pwrmgr_ast_req;
  pwrmgr_pkg::pwr_ast_rsp_t pwrmgr_ast_rsp;

  // assorted ast status
  ast_pkg::ast_pwst_t ast_pwst;

  // TLUL interface
  tlul_pkg::tl_h2d_t ast_tl_req;
  tlul_pkg::tl_d2h_t ast_tl_rsp;

  // Generated clocks, resets, and enable signals
  ast_pkg::ast_clks_t         ast_base_clks;
  clkmgr_pkg::clkmgr_out_t    clkmgr_aon_clocks;
  clkmgr_pkg::clkmgr_cg_en_t  clkmgr_aon_cg_en;
  rstmgr_pkg::rstmgr_out_t    rstmgr_aon_resets;
  rstmgr_pkg::rstmgr_rst_en_t rstmgr_aon_rst_en;

  // external clock
  logic ext_clk;

  // monitored clock
  logic sck_monitor;

  // observe interface
  logic [7:0] flash_obs;
  logic [7:0] otp_obs;
  ast_pkg::ast_obs_ctrl_t obs_ctrl;

  // otp power sequence
  otp_macro_pkg::otp_ast_req_t otp_macro_pwr_seq;
  otp_macro_pkg::otp_ast_rsp_t otp_macro_pwr_seq_h;

  logic usb_ref_pulse;
  logic usb_ref_val;

  // adc
  ast_pkg::adc_ast_req_t adc_req;
  ast_pkg::adc_ast_rsp_t adc_rsp;

  // entropy source interface
  logic es_rng_enable, es_rng_valid;
  logic [ast_pkg::EntropyStreams-1:0] es_rng_bit;
  logic es_rng_fips;

  // entropy distribution network
  edn_pkg::edn_req_t ast_edn_req;
  edn_pkg::edn_rsp_t ast_edn_rsp;

  // alerts interface
  ast_pkg::ast_alert_rsp_t ast_alert_rsp;
  ast_pkg::ast_alert_req_t ast_alert_req;

  // Flash connections
  prim_mubi_pkg::mubi4_t flash_bist_enable;
  logic flash_power_down_h;
  logic flash_power_ready_h;

  // clock bypass req/ack
  prim_mubi_pkg::mubi4_t io_clk_byp_req;
  prim_mubi_pkg::mubi4_t io_clk_byp_ack;
  prim_mubi_pkg::mubi4_t all_clk_byp_req;
  prim_mubi_pkg::mubi4_t all_clk_byp_ack;
  prim_mubi_pkg::mubi4_t hi_speed_sel;
  prim_mubi_pkg::mubi4_t div_step_down_req;

  // DFT connections
  logic scan_en;
  logic scan_rst_n;
  prim_mubi_pkg::mubi4_t scanmode;
  lc_ctrl_pkg::lc_tx_t lc_dft_en;
  pinmux_pkg::dft_strap_test_req_t dft_strap_test;

  // Debug connections
  logic [ast_pkg::Ast2PadOutWidth-1:0] ast2pinmux;
  logic [ast_pkg::Pad2AstInWidth-1:0] pad2ast;

  // Jitter enable for main clock
  prim_mubi_pkg::mubi4_t clk_main_jitter_en;

  // Memory configuration connections
  ast_pkg::spm_rm_t ast_ram_1p_cfg;
  ast_pkg::spm_rm_t ast_rf_cfg;
  ast_pkg::spm_rm_t ast_rom_cfg;
  ast_pkg::dpm_rm_t ast_ram_2p_fcfg;
  ast_pkg::dpm_rm_t ast_ram_2p_lcfg;

  prim_ram_1p_pkg::ram_1p_cfg_t ram_1p_cfg;
  prim_ram_2p_pkg::ram_2p_cfg_t spi_ram_2p_cfg;
  prim_ram_1p_pkg::ram_1p_cfg_t usb_ram_1p_cfg;
  prim_rom_pkg::rom_cfg_t rom_cfg;

  // conversion from ast structure to memory centric structures
  assign ram_1p_cfg = '{
    ram_cfg: '{
                test:   ast_ram_1p_cfg.test,
                cfg_en: ast_ram_1p_cfg.marg_en,
                cfg:    ast_ram_1p_cfg.marg
              },
    rf_cfg:  '{
                test:   ast_rf_cfg.test,
                cfg_en: ast_rf_cfg.marg_en,
                cfg:    ast_rf_cfg.marg
              }
  };

  assign usb_ram_1p_cfg = '{
    ram_cfg: '{
                test:   ast_ram_1p_cfg.test,
                cfg_en: ast_ram_1p_cfg.marg_en,
                cfg:    ast_ram_1p_cfg.marg
              },
    rf_cfg:  '{
                test:   ast_rf_cfg.test,
                cfg_en: ast_rf_cfg.marg_en,
                cfg:    ast_rf_cfg.marg
              }
  };

  // this maps as follows:
  // assign spi_ram_2p_cfg = {10'h000, ram_2p_cfg_i.a_ram_lcfg, ram_2p_cfg_i.b_ram_lcfg};
  assign spi_ram_2p_cfg = '{
    a_ram_lcfg: '{
                   test:   ast_ram_2p_lcfg.test_a,
                   cfg_en: ast_ram_2p_lcfg.marg_en_a,
                   cfg:    ast_ram_2p_lcfg.marg_a
                 },
    b_ram_lcfg: '{
                   test:   ast_ram_2p_lcfg.test_b,
                   cfg_en: ast_ram_2p_lcfg.marg_en_b,
                   cfg:    ast_ram_2p_lcfg.marg_b
                 },
    default: '0
  };

  assign rom_cfg = '{
    test:   ast_rom_cfg.test,
    cfg_en: ast_rom_cfg.marg_en,
    cfg:    ast_rom_cfg.marg
  };

  // unused cfg bits
  logic unused_ram_cfg;
  assign unused_ram_cfg = ^ast_ram_2p_fcfg;

  //////////////////////////////////
  // AST - Custom for targets     //
  //////////////////////////////////

  assign pwrmgr_ast_rsp.main_pok = ast_pwst.main_pok;

  logic [rstmgr_pkg::PowerDomains-1:0] por_n;
  assign por_n = {ast_pwst.main_pok, ast_pwst.aon_pok};

% if target["name"] != "verilator":
  // AST clocks and signals needed in the padring
  assign ast_base_clks_o = ast_base_clks;
  assign scanmode_o = scanmode;

% endif\

% if target["name"] == "asic":

  // external clock comes in at a fixed position
  assign ext_clk = mio_in_raw_i[MioPadIoc6];

  // Raw pad signals required by the ast
  assign pad2ast = `PAD2AST_WIRES ;

  // AST does not use all clocks / resets forwarded to it
  logic unused_slow_clk_en;
  assign unused_slow_clk_en = pwrmgr_ast_req.slow_clk_en;

  logic unused_pwr_clamp;
  assign unused_pwr_clamp = pwrmgr_ast_req.pwr_clamp;

% elif target["name"] in ["cw305", "cw310"] and not gen_bkdr_loader:
  // TODO: Hook this up when FPGA pads are updated
  assign ext_clk = '0;
  assign pad2ast = '0;

  logic clk_main, clk_usb_48mhz, clk_aon, rst_n, srst_n;
  assign srst_n = manual_in_por_button_n_i;
  clkgen_xil7series # (
    .AddClkBuf(0)
  ) clkgen (
    .clk_i(manual_in_io_clk_i),
    .rst_ni(manual_in_por_n_i),
    .srst_ni(srst_n),
    .clk_main_o(clk_main),
    .clk_48MHz_o(clk_usb_48mhz),
    .clk_aon_o(clk_aon),
    .rst_no(rst_n)
  );

  logic [31:0] fpga_info;
  usr_access_xil7series u_info (
    .info_o(fpga_info)
  );

  ast_pkg::clks_osc_byp_t clks_osc_byp;
  assign clks_osc_byp = '{
    usb: clk_usb_48mhz,
    sys: clk_main,
    io:  clk_main,
    aon: clk_aon
  };

% elif target["name"] in ["cw305", "cw310"] and gen_bkdr_loader:
  // TODO: Hook this up when FPGA pads are updated
  assign ext_clk = '0;
  assign pad2ast = '0;

  logic bkdr_rst_n;
  logic clk_main, clk_usb_48mhz, clk_aon, rst_n, srst_n;
  assign srst_n = manual_in_por_button_n_i;
  clkgen_xil7series # (
    .AddClkBuf(0)
  ) clkgen (
    .clk_i(manual_in_io_clk_i),
    .rst_ni(manual_in_por_n_i),
    .srst_ni(srst_n),
    .clk_main_o(clk_main),
    .clk_48MHz_o(clk_usb_48mhz),
    .clk_aon_o(clk_aon),
    .rst_no(bkdr_rst_n)
  );

  logic [31:0] fpga_info;
  usr_access_xil7series u_info (
    .info_o(fpga_info)
  );

  ast_pkg::clks_osc_byp_t clks_osc_byp;
  assign clks_osc_byp = '{
    usb: clk_usb_48mhz,
    sys: clk_main,
    io:  clk_main,
    aon: clk_aon
  };

% elif target["name"] == "verilator":
  assign ext_clk = '0;
  assign pad2ast = '0;

  // AON clock divider. Reset is not used because verilator uses only sync
  // resets (and does not model 'x'); if the divider below were reset, clk_aon
  // would be silenced and the clk_aon logic inside top_${top["name"]} would not
  // get reset.

  logic clk_aon;
  prim_clock_div #(
    .Divisor(4)
  ) u_aon_div (
    .clk_i,
    .rst_ni(1'b1),
    .step_down_req_i('0),
    .step_down_ack_o(),
    .test_en_i('0),
    .clk_o(clk_aon)
  );

  // POR for the AST comes directly from the reset input.
  logic rst_n;
  assign rst_n = rst_ni;

  ast_pkg::clks_osc_byp_t clks_osc_byp;
  assign clks_osc_byp = '{
    usb: clk_i,
    sys: clk_i,
    io:  clk_i,
    aon: clk_aon
  };

  // Target (Verilator) specific supply manipulation to create a synthetic POR condition.
  logic [3:0] cnt;
  logic vcc_supp;
  // keep incrementing until saturation
  always_ff @(posedge clk_aon) begin
    if (cnt < 4'hf) begin
      cnt <= cnt + 1'b1;
    end
  end
  assign vcc_supp = cnt < 4'h4 ? 1'b0 :
                    cnt < 4'h8 ? 1'b1 :
                    cnt < 4'hc ? 1'b0 : 1'b1;

  // AST does not use all clocks / resets forwarded to it
  logic unused_slow_clk_en;
  assign unused_slow_clk_en = pwrmgr_ast_req.slow_clk_en;

  logic unused_pwr_clamp;
  assign unused_pwr_clamp = pwrmgr_ast_req.pwr_clamp;

% else:
  // TODO: Hook this up when FPGA pads are updated
  assign ext_clk = '0;
  assign pad2ast = '0;

  logic bkdr_rst_n;
  logic clk_main, clk_io, clk_usb_48mhz, clk_aon, rst_n;
  clkgen_xil_ultrascale # (
    .AddClkBuf(0)
  ) clkgen (
    .clk_i(manual_in_io_clk_i),
    .rst_ni(manual_in_por_n_i),
    .clk_main_o(clk_main),
    .clk_io_o(clk_io),
    .clk_48MHz_o(clk_usb_48mhz),
    .clk_aon_o(clk_aon),
    .rst_no(bkdr_rst_n)
  );

  logic [31:0] fpga_info;
  usr_access_xil7series u_info (
    .info_o(fpga_info)
  );

  ast_pkg::clks_osc_byp_t clks_osc_byp;
  assign clks_osc_byp = '{
    usb: clk_usb_48mhz,
    sys: clk_main,
    io:  clk_io,
    aon: clk_aon
  };

% endif

  prim_mubi_pkg::mubi4_t ast_init_done;\

% if top["name"] == "englishbreakfast":

  // Englishbreakfast doesn't use many AST signals
  assign otp_macro_pwr_seq = '0;
  assign adc_req           = '0;
  assign es_rng_enable     = '0;
  assign es_rng_fips       = '0;
  assign ast_edn_rsp       = '0;
  assign ast_alert_rsp     = '0;
  assign lc_dft_en         = '0;
  assign otp_obs           = '0;

  logic unused_ast;

  assign unused_ast = ^{
    ast_init_done,
    otp_macro_pwr_seq_h,
    adc_rsp,
    es_rng_valid,
    es_rng_bit,
    ast_edn_req,
    ast_alert_req,
    ast2pinmux
  };
% endif

  ast u_ast (
% if target["name"] == "asic":
    // external POR
    .por_ni                ( manual_in_por_n_i ),

    // USB IO Pull-up Calibration Setting
    .usb_io_pu_cal_o       ( usb_io_pu_cal_o ),

    // adc
    .adc_a0_ai             ( CC1 ),
    .adc_a1_ai             ( CC2 ),

    // Direct short to PAD
    .ast2pad_t0_ao         ( IOA2 ),
    .ast2pad_t1_ao         ( IOA3 ),

% else:
    // external POR
    .por_ni                ( rst_n ),

    // USB IO Pull-up Calibration Setting
    .usb_io_pu_cal_o       ( ),

    // clocks' oscillator bypass for FPGA
    .clk_osc_byp_i         ( clks_osc_byp ),

    // adc
    .adc_a0_ai             ( '0 ),
    .adc_a1_ai             ( '0 ),

    // Direct short to PAD
    .ast2pad_t0_ao         (  ),
    .ast2pad_t1_ao         (  ),

% endif
    // clocks and resets supplied for detection
    .sns_clks_i            ( clkmgr_aon_clocks    ),
    .sns_rsts_i            ( rstmgr_aon_resets    ),
    .sns_spi_ext_clk_i     ( sck_monitor          ),
    // tlul
    .tl_i                  ( ast_tl_req ),
    .tl_o                  ( ast_tl_rsp ),
    // init done indication
    .ast_init_done_o       ( ast_init_done ),
    // buffered clocks & resets
    % for port, clk in ast["clock_srcs"].items():
    .${port} (${lib.get_clock_prefixes(top)["top"]}clk_${clk["clock"]}_${clk["group"]}),
    % endfor
    % for port, reset in ast["reset_connections"].items():
    .${port} (${lib.get_reset_path(top, reset)}),
    % endfor
    .clk_ast_ext_i         ( ext_clk ),

    // pok test for FPGA
% if target["name"] == "verilator":
    .vcc_supp_i            ( vcc_supp ),
% else:
    .vcc_supp_i            ( 1'b1 ),
% endif
    .vcaon_supp_i          ( 1'b1 ),
    .vcmain_supp_i         ( 1'b1 ),
    .vioa_supp_i           ( 1'b1 ),
    .viob_supp_i           ( 1'b1 ),
    // pok
    .ast_pwst_o            ( ast_pwst ),
% if target["name"] == "asic":
    .ast_pwst_h_o          ( ast_pwst_h_o ),
% else:
    .ast_pwst_h_o          (  ),
% endif
    // main regulator
    .main_env_iso_en_i     ( pwrmgr_ast_req.pwr_clamp_env ),
    .main_pd_ni            ( pwrmgr_ast_req.main_pd_n ),
    // pdm control (flash)/otp
    .flash_power_down_h_o  ( flash_power_down_h ),
    .flash_power_ready_h_o ( flash_power_ready_h ),
    .otp_power_seq_i       ( otp_macro_pwr_seq ),
    .otp_power_seq_h_o     ( otp_macro_pwr_seq_h ),
    // system source clock
    .clk_src_sys_en_i      ( pwrmgr_ast_req.core_clk_en ),
    // need to add function in clkmgr
    .clk_src_sys_jen_i     ( clk_main_jitter_en ),
    .clk_src_sys_o         ( ast_base_clks.clk_sys  ),
    .clk_src_sys_val_o     ( pwrmgr_ast_rsp.core_clk_val ),
    // aon source clock
    .clk_src_aon_o         ( ast_base_clks.clk_aon ),
    .clk_src_aon_val_o     ( pwrmgr_ast_rsp.slow_clk_val ),
    // io source clock
    .clk_src_io_en_i       ( pwrmgr_ast_req.io_clk_en ),
    .clk_src_io_o          ( ast_base_clks.clk_io ),
    .clk_src_io_val_o      ( pwrmgr_ast_rsp.io_clk_val ),
    .clk_src_io_48m_o      ( div_step_down_req ),
    // usb source clock
    .usb_ref_pulse_i       ( usb_ref_pulse ),
    .usb_ref_val_i         ( usb_ref_val ),
    .clk_src_usb_en_i      ( pwrmgr_ast_req.usb_clk_en ),
    .clk_src_usb_o         ( ast_base_clks.clk_usb ),
    .clk_src_usb_val_o     ( pwrmgr_ast_rsp.usb_clk_val ),
    // adc
    .adc_pd_i              ( adc_req.pd ),
    .adc_chnsel_i          ( adc_req.channel_sel ),
    .adc_d_o               ( adc_rsp.data ),
    .adc_d_val_o           ( adc_rsp.data_valid ),
    // rng
    .rng_en_i              ( es_rng_enable ),
    .rng_fips_i            ( es_rng_fips ),
    .rng_val_o             ( es_rng_valid ),
    .rng_b_o               ( es_rng_bit ),
    // entropy
    .entropy_rsp_i         ( ast_edn_rsp ),
    .entropy_req_o         ( ast_edn_req ),
    // alerts
    .alert_rsp_i           ( ast_alert_rsp  ),
    .alert_req_o           ( ast_alert_req  ),
    // dft
    .dft_strap_test_i      ( dft_strap_test   ),
    .lc_dft_en_i           ( lc_dft_en        ),
    .fla_obs_i             ( flash_obs ),
    .otp_obs_i             ( otp_obs ),
    .otm_obs_i             ( '0 ),
% if target["name"] == "asic":
    .usb_obs_i             ( usb_diff_rx_obs_i ),
% else:
    .usb_obs_i             ( '0 ),
% endif
    .obs_ctrl_o            ( obs_ctrl ),
    // pinmux related
    .padmux2ast_i          ( pad2ast    ),
    .ast2padmux_o          ( ast2pinmux ),
% if target["name"] != "verilator":
    .mux_iob_sel_o         ( mux_iob_sel_o ),
% else:
    .mux_iob_sel_o         (  ),
% endif
    .ext_freq_is_96m_i     ( hi_speed_sel ),
    .all_clk_byp_req_i     ( all_clk_byp_req  ),
    .all_clk_byp_ack_o     ( all_clk_byp_ack  ),
    .io_clk_byp_req_i      ( io_clk_byp_req   ),
    .io_clk_byp_ack_o      ( io_clk_byp_ack   ),
    .flash_bist_en_o       ( flash_bist_enable ),
    // Memory configuration connections
    .dpram_rmf_o           ( ast_ram_2p_fcfg ),
    .dpram_rml_o           ( ast_ram_2p_lcfg ),
    .spram_rm_o            ( ast_ram_1p_cfg  ),
    .sprgf_rm_o            ( ast_rf_cfg      ),
    .sprom_rm_o            ( ast_rom_cfg     ),
    // scan
    .dft_scan_md_o         ( scanmode   ),
    .scan_shift_en_o       ( scan_en    ),
    .scan_reset_no         ( scan_rst_n )
  );

% if gen_bkdr_loader:
  /////////////////////
  // Memory Backdoor //
  /////////////////////

  // Multiplexed I/O routed through the backdoor loader
  pad_attr_t [pinmux_reg_pkg::NMioPads-1:0] mio_bkdr_attr;
  logic [pinmux_reg_pkg::NMioPads-1:0]      mio_bkdr_out;
  logic [pinmux_reg_pkg::NMioPads-1:0]      mio_bkdr_oe;
  logic [pinmux_reg_pkg::NMioPads-1:0]      mio_bkdr_in;

  if (BkdrLoaderEn) begin : gen_bkdr

    // Get TAP strap signals from pad frame
    logic tap_strap0;
    logic tap_strap1;
    logic bkdr_ena;

    // Main JTAG port
    jtag_pkg::jtag_req_t jtag_req_i;
    jtag_pkg::jtag_rsp_t jtag_rsp_o;

    // D/S JTAG port
    jtag_pkg::jtag_req_t jtag_req_o;
    jtag_pkg::jtag_rsp_t jtag_rsp_i;

    // Backdoor ports
    bkdr_loader_pkg::bkdr_req_t [bkdr_loader_reg_pkg::NumBkdrTgts-1:0] bkdr_req;
    bkdr_loader_pkg::bkdr_rsp_t [bkdr_loader_reg_pkg::NumBkdrTgts-1:0] bkdr_rsp;

    bkdr_loader i_bkdr_loader (
      .clk_i      (clk_main),
      .rst_ni     (bkdr_rst_n),
      .bkdr_ena_i (bkdr_ena),
      .jtag_req_i (jtag_req_i),
      .jtag_rsp_o (jtag_rsp_o),
      .jtag_req_o (jtag_req_o),
      .jtag_rsp_i (jtag_rsp_i),
      .fpga_info_i(fpga_info),
      .bkdr_req_o (bkdr_req),
      .bkdr_rsp_i (bkdr_rsp),
      .rst_no     (rst_n)
    );

    // Connect requests
    `BKDR_LOADER_CONNECT_REQS

    // Connect responses
    `BKDR_LOADER_CONNECT_RSPS

    always_comb begin : proc_conn_bkdr
      // Through-connection
      mio_attr_o    = mio_bkdr_attr;
      mio_out_o     = mio_bkdr_out;
      mio_oe_o      = mio_bkdr_oe;
      mio_bkdr_in = mio_in_i;

      // Connect backdoor JTAG input
      jtag_req_i.tck      = mio_in_i[PinmuxAonTargetCfg.tck_idx];
      jtag_req_i.tms      = mio_in_i[PinmuxAonTargetCfg.tms_idx];
      jtag_req_i.trst_n   = mio_in_i[PinmuxAonTargetCfg.trst_idx];
      jtag_req_i.tdi      = mio_in_i[PinmuxAonTargetCfg.tdi_idx];
      mio_out_o[PinmuxAonTargetCfg.tdo_idx]  = jtag_rsp_o.tdo;
      mio_oe_o[PinmuxAonTargetCfg.tdo_idx]   = jtag_rsp_o.tdo_oe;
      mio_attr_o[PinmuxAonTargetCfg.tdo_idx] = '0;

      // Connect backdoor JTAG output
      mio_bkdr_in[PinmuxAonTargetCfg.tck_idx]  = jtag_req_o.tck;
      mio_bkdr_in[PinmuxAonTargetCfg.tms_idx]  = jtag_req_o.tms;
      mio_bkdr_in[PinmuxAonTargetCfg.trst_idx] = jtag_req_o.trst_n;
      mio_bkdr_in[PinmuxAonTargetCfg.tdi_idx]  = jtag_req_o.tdi;
      jtag_rsp_i.tdo    = mio_bkdr_out[PinmuxAonTargetCfg.tdo_idx];
      jtag_rsp_i.tdo_oe = mio_bkdr_oe[PinmuxAonTargetCfg.tdo_idx];
    end

    // Connect TAP strap signals to pad frame
    assign tap_strap0 = mio_in_i[PinmuxAonTargetCfg.tap_strap0_idx];
    assign tap_strap1 = mio_in_i[PinmuxAonTargetCfg.tap_strap1_idx];

    // Bkdr loader is activated if both tap_strap signals are set to 1'b1.
    assign bkdr_ena = tap_strap0 && tap_strap1;

  end else begin : gen_no_bkdr
    assign mio_attr_o    = mio_bkdr_attr;
    assign mio_out_o     = mio_bkdr_out;
    assign mio_oe_o      = mio_bkdr_oe;
    assign mio_bkdr_in = mio_in_i;
    assign bkdr_rst_n  = manual_in_por_n_i;
  end

% endif
  // Inter-Power Domain signals
% for sig in top["inter_pd"]["definitions"]:
  % if isinstance(sig["width"], Parameter):
  ${lib.im_defname(sig)} [${sig["width"].name_top}-1:0] ${sig["signame"]};
  % else:
  ${lib.im_defname(sig)} ${lib.bitarray(sig["width"],1)} ${sig["signame"]};
  % endif
% endfor

% if top["name"] == "englishbreakfast":
  // Outgoing alerts are currently unused
  assign alertenglishbreakfast_rx_pd_main = '{default: prim_alert_pkg::ALERT_RX_DEFAULT};
  assign alertenglishbreakfast_rx_pd_aon  = '{default: prim_alert_pkg::ALERT_RX_DEFAULT};

  logic unused_alertenglishbreakfast_tx;
  assign unused_alertenglishbreakfast_tx = ^{
    alertenglishbreakfast_tx_pd_main,
    alertenglishbreakfast_tx_pd_aon
  };

  logic unused_outgoing_lpg_englishbreakfast;
  assign unused_outgoing_lpg_englishbreakfast = ^{
    outgoing_lpg_cg_en_englishbreakfast,
    outgoing_lpg_rst_en_englishbreakfast
  };

% endif\

  ///////////////////////////
  // Top-level Main Domain //
  ///////////////////////////
  ${top["name"]}_pd_main #(
% if target["name"] == "cw310":
    .EntropySrcStub(1'b1), // Stub ENTROPY_SRC to reduce resource usage on CW310. See #30062.
    .OtbnStub(1'b1), // Stub OTBN to reduce resource usage on CW310. See #30062.
    .UsbdevStub(1'b1), // Stub USBDEV to reduce resource usage on CW310. See #30062.
    .SecAesMasking(1'b0), // Disable AES masking on the CW310, where we are constrained by area.
    .SecAesSBoxImpl(aes_pkg::SBoxImplLut),
    .RvCoreIbexPMPEnable(1'b0),
    .RvCoreIbexRV32B(ibex_pkg::RV32BNone),
    .RvCoreIbexRV32ZC(ibex_pkg::RV32Zca),
    .RvCoreIbexBranchTargetALU(1'b0),
    .RvCoreIbexWritebackStage(1'b0),
    .RvCoreIbexICache(1'b0),
% elif target["name"]  == "cw340":
    .SecAesMasking(1'b1),
    .SecAesSBoxImpl(aes_pkg::SBoxImplDom),
% endif
% if target["name"] in ["cw310", "cw340"]:
    .SecAesStartTriggerDelay(0),
    .SecAesAllowForcingMasks(1'b1),
    .CsrngSBoxImpl(aes_pkg::SBoxImplLut),
    .OtbnRegFile(otbn_pkg::RegFileFPGA),
    .SecOtbnMuteUrnd(1'b0),
    .SecOtbnSkipUrndReseedAtStart(1'b0),
    .OtpMacroMemInitFile(OtpMacroMemInitFile),
    .RvCoreIbexPipeLine(1),
    .UsbdevRcvrWakeTimeUs(10000),
% elif target["name"] == "cw305":
    .RvCoreIbexPipeLine(0),
    .SecAesMasking(1'b1),
    .SecAesSBoxImpl(aes_pkg::SBoxImplDom),
    .SecAesStartTriggerDelay(320),
    .SecAesAllowForcingMasks(1'b1),
    .SecAesSkipPRNGReseeding(1'b1),
    .UsbdevStub(1'b1),
    .RvCoreIbexSecureIbex(0),
% endif
% if target["name"] == "cw340":
    .KmacEnMasking(1),
    .KmacSwKeyMasked(1),
    .KeymgrKmacEnMasking(1),
    .RvCoreIbexSecureIbex(1),
% elif target["name"] == "cw310":
    .KmacEnMasking(0),
    .KmacSwKeyMasked(1),
    .KeymgrKmacEnMasking(0),
    .SecKmacCmdDelay(0),
    .SecKmacIdleAcceptSwMsg(1'b0),
    .RvCoreIbexSecureIbex(0),
% endif
% if target["name"] == "asic":
    .I2c0InputDelayCycles(1),
    .I2c1InputDelayCycles(1),
    .I2c2InputDelayCycles(1),
    .SecAesAllowForcingMasks(1'b1),
    .SecRomCtrlDisableScrambling(SecRomCtrlDisableScrambling),
% elif target["name"] == "verilator":
%   if top["name"] == "englishbreakfast":
    .SecAesMasking(1'b1),
    .SecAesSBoxImpl(aes_pkg::SBoxImplDom),
    .SecAesStartTriggerDelay(320),
    .SecAesSkipPRNGReseeding(1'b1),
    .UsbdevStub(1'b1),
    .RvCoreIbexICache(0),
%   endif
    .SecAesAllowForcingMasks(1'b1),
    .SramCtrlMainInstrExec(1),
% else:
    .RomCtrlBootRomInitFile(BootRomInitFile),
    .RvCoreIbexRegFile(ibex_pkg::RegFileFPGA),
    .SramCtrlMainInstrExec(1),
% endif
    .PinmuxAonTargetCfg(PinmuxAonTargetCfg)
  ) ${top["name"]}_pd_main (
<%include file="/chiplevel_snippets/special_signals_portmap.tpl" args="top=top, feature_info=feature_info, cio_info=cio_info, gen_bkdr_loader=gen_bkdr_loader, domain='Main'" />\

<%include file="/chiplevel_snippets/intermodule_portmap.tpl" args="top=top, target=target, domain='Main', inter_pd=True, last_snippet=False" />\

<%include file="/chiplevel_snippets/intermodule_portmap.tpl" args="top=top, target=target, domain='Main', inter_pd=False, last_snippet=True" />\
  );


  ////////////////////////////////
  // Top-level Always-On domain //
  ////////////////////////////////
  % if target["name"] in ["cw310", "cw340"] or (target["name"] == "verilator" and top["name"] != "englishbreakfast"):
  ${top["name"]}_pd_aon #(
    .SramCtrlRetAonInstrExec(0)
  ) ${top["name"]}_pd_aon (
  % else:
  ${top["name"]}_pd_aon ${top["name"]}_pd_aon (
  % endif
<%include file="/chiplevel_snippets/special_signals_portmap.tpl" args="top=top, feature_info=feature_info, cio_info=cio_info, gen_bkdr_loader=gen_bkdr_loader, domain='Aon'" />\

<%include file="/chiplevel_snippets/intermodule_portmap.tpl" args="top=top, target=target, domain='Aon', inter_pd=True, last_snippet=False" />\

<%include file="/chiplevel_snippets/intermodule_portmap.tpl" args="top=top, target=target, domain='Aon', inter_pd=False, last_snippet=True" />\
  );

endmodule
