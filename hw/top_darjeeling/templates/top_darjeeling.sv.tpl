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

ast = [m for m in top["module"] if m["name"] == "ast"]
assert(len(ast) == 1)
ast = ast[0]
%>\
<%include file="/toplevel_snippets/info_dicts.tpl" args="top=top, feature_info=feature_info, cio_info=cio_info" />\

// This module bundles the ${top["name"]} power domains together with the analog
// sensor top (AST) and the remaining "core" glue logic (the JTAG TAP and the
// CTN interconnect). It exposes only the signals that need to cross to the
// chip-level: the pad-multiplexer interface for the padring, the AST control
// signals consumed by the padring, the JTAG pad signals, and the direct
// connections to the chip pads.
module top_${top["name"]}_${target["name"]} #(
  parameter bit SecRomCtrl0DisableScrambling = 1'b0,
  parameter bit SecRomCtrl1DisableScrambling = 1'b0,
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
  // AST clock needed in the padring (scan/DFT) and scanmode
  output ast_pkg::ast_clks_t    ast_base_clks_o,
  output prim_mubi_pkg::mubi4_t scanmode_o,

% endif
  // JTAG interface to/from the chip-level JTAG pads
  input  logic jtag_tck_i,
  input  logic jtag_tms_i,
  input  logic jtag_trst_n_i,
  input  logic jtag_tdi_i,
  output logic jtag_tdo_o,
  output logic jtag_tdo_oe_o\
% if target["name"] == "asic":
,

  // External POR (also feeds the AST directly)
  input  logic manual_in_por_n_i,

  // Direct connection to the chip pad
  inout        OTP_EXT_VOLT\
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
  pwrmgr_pkg::pwr_boot_status_t pwrmgr_boot_status;

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

  // monitored clock
  logic sck_monitor;

  // debug policy bus
  soc_dbg_ctrl_pkg::soc_dbg_policy_t soc_dbg_policy_bus;

  // observe interface
  logic [7:0] otp_obs;
  ast_pkg::ast_obs_ctrl_t obs_ctrl;

  // otp power sequence
  otp_macro_pkg::otp_ast_req_t otp_macro_pwr_seq;
  otp_macro_pkg::otp_ast_rsp_t otp_macro_pwr_seq_h;

  // OTP DFT configuration
  otp_macro_pkg::otp_cfg_t otp_cfg;
  assign otp_cfg = otp_macro_pkg::OTP_CFG_DEFAULT;

  // entropy source interface
  logic es_rng_enable, es_rng_valid;
  logic [ast_pkg::EntropyStreams-1:0] es_rng_bit;

  // alerts interface
  ast_pkg::ast_alert_rsp_t ast_alert_rsp;
  ast_pkg::ast_alert_req_t ast_alert_req;
  assign ast_alert_rsp = '0;

  // DFT connections
  logic scan_en;
  logic scan_rst_n;
  prim_mubi_pkg::mubi4_t scanmode;
  lc_ctrl_pkg::lc_tx_t lc_dft_en;

  // Jitter enable
  prim_mubi_pkg::mubi4_t clk_main_jitter_en;

  // reset domain connections
  import rstmgr_pkg::PowerDomains;
  import rstmgr_pkg::DomainAonSel;
  import rstmgr_pkg::DomainMainSel;

  // Memory configuration connections
  ast_pkg::spm_rm_t ast_ram_1p_cfg;
  ast_pkg::spm_rm_t ast_rf_cfg;
  ast_pkg::spm_rm_t ast_rom_cfg;
  ast_pkg::dpm_rm_t ast_ram_2p_fcfg;
  ast_pkg::dpm_rm_t ast_ram_2p_lcfg;

  // conversion from ast structure to memory centric structures
  prim_ram_1p_pkg::ram_1p_cfg_t ram_1p_cfg;
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

  // this maps as follows:
  // assign spi_ram_2p_cfg = {10'h000, ram_2p_cfg_i.a_ram_lcfg, ram_2p_cfg_i.b_ram_lcfg};
  prim_ram_2p_pkg::ram_2p_cfg_t spi_ram_2p_cfg;
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

  prim_rom_pkg::rom_cfg_t rom_ctrl0_cfg;
  prim_rom_pkg::rom_cfg_t rom_ctrl1_cfg;

  assign rom_ctrl0_cfg = '{
    test: ast_rom_cfg.test,
    cfg_en: ast_rom_cfg.marg_en,
    cfg: ast_rom_cfg.marg
  };
  assign rom_ctrl1_cfg = '{
    test: ast_rom_cfg.test,
    cfg_en: ast_rom_cfg.marg_en,
    cfg: ast_rom_cfg.marg
  };

% if target["name"] != "verilator":
  // AST control signals needed in the padring
  assign ast_base_clks_o = ast_base_clks;
  assign scanmode_o      = scanmode;

% endif
  //////////////////////////////////
  // AST - Custom for targets     //
  //////////////////////////////////

  assign pwrmgr_ast_rsp.main_pok = ast_pwst.main_pok;

  logic [rstmgr_pkg::PowerDomains-1:0] por_n;
  assign por_n = {ast_pwst.main_pok, ast_pwst.aon_pok};

  wire unused_t0, unused_t1;
  assign unused_t0 = 1'b0;
  assign unused_t1 = 1'b0;

  // AST does not use all clocks / resets forwarded to it
  logic unused_slow_clk_en;
  assign unused_slow_clk_en = pwrmgr_ast_req.slow_clk_en;

  logic unused_pwr_clamp;
  assign unused_pwr_clamp = pwrmgr_ast_req.pwr_clamp;

% if target["name"] == "verilator":
  // Clock and power-on-reset generation specific to the Verilator top.
  // AON clock divider. Reset is not used because verilator uses only sync
  // resets (and does not model 'x'); resetting the divider would silence
  // clk_aon and the clk_aon logic inside top_${top["name"]} would not reset.
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

  ast_pkg::clks_osc_byp_t clks_osc_byp;
  assign clks_osc_byp = '{
    sys: clk_i,
    io:  clk_i,
    aon: clk_aon
  };

  // Target (Verilator) specific supply manipulation to create a synthetic POR condition.
  logic [3:0] cnt;
  logic vcc_supp;
  always_ff @(posedge clk_aon) begin
    if (cnt < 4'hf) begin
      cnt <= cnt + 1'b1;
    end
  end
  assign vcc_supp = cnt < 4'h4 ? 1'b0 :
                    cnt < 4'h8 ? 1'b1 :
                    cnt < 4'hc ? 1'b0 : 1'b1;
% endif

  ast #(
    .Ast2PadOutWidth(ast_pkg::Ast2PadOutWidth),
    .Pad2AstInWidth(ast_pkg::Pad2AstInWidth)
  ) u_ast (
    // external POR
% if target["name"] == "verilator":
    .por_ni                ( rst_ni ),
% else:
    .por_ni                ( manual_in_por_n_i ),
% endif

    // Direct short to PAD
    .ast2pad_t0_ao         ( unused_t0 ),
    .ast2pad_t1_ao         ( unused_t1 ),

    // clocks and resets supplied for detection
    .sns_clks_i            ( clkmgr_aon_clocks    ),
    .sns_rsts_i            ( rstmgr_aon_resets    ),
    .sns_spi_ext_clk_i     ( sck_monitor          ),
% if target["name"] == "verilator":
    // clocks' oscillator bypass for verilator
    .clk_osc_byp_i         ( clks_osc_byp ),
% endif
    // tlul
    .tl_i                  ( ast_tl_req ),
    .tl_o                  ( ast_tl_rsp ),
    // init done indication
    .ast_init_done_o       ( ),
    // buffered clocks & resets
    % for port, clk in ast["clock_srcs"].items():
    .${port} (${lib.get_clock_prefixes(top)["top"]}clk_${clk["clock"]}_${clk["group"]}),
    % endfor
    % for port, reset in ast["reset_connections"].items():
    .${port} (${lib.get_reset_path(top, reset)}),
    % endfor

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
    .ast_pwst_h_o          ( ),
    // main regulator
    .main_env_iso_en_i     ( pwrmgr_ast_req.pwr_clamp_env ),
    .main_pd_ni            ( pwrmgr_ast_req.main_pd_n ),
    // pdm control (otp)
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
    // rng
    .rng_en_i              ( es_rng_enable ),
    .rng_fips_i            ( es_rng_fips   ),
    .rng_val_o             ( es_rng_valid  ),
    .rng_b_o               ( es_rng_bit    ),
    // alerts
    .alert_rsp_i           ( ast_alert_rsp  ),
    .alert_req_o           ( ast_alert_req  ),
    // dft
    .lc_dft_en_i           ( lc_dft_en        ),
    .otp_obs_i             ( otp_obs ),
    .otm_obs_i             ( '0 ),
    .obs_ctrl_o            ( obs_ctrl ),
    // pinmux related
    .padmux2ast_i          ( '0         ),
    .ast2padmux_o          (            ),
    // Memory configuration connections
    .dpram_rmf_o           ( ast_ram_2p_fcfg ),
    .dpram_rml_o           ( ast_ram_2p_lcfg ),
    .spram_rm_o            ( ast_ram_1p_cfg  ),
    .sprgf_rm_o            ( ast_rf_cfg      ),
    .sprom_rm_o            ( ast_rom_cfg     ),
    // scan
    .dft_scan_md_o         ( scanmode ),
    .scan_shift_en_o       ( scan_en ),
    .scan_reset_no         ( scan_rst_n )
  );

  //////////////////
  // TAP Instance //
  //////////////////

  tlul_pkg::tl_h2d_t dmi_req;
  tlul_pkg::tl_d2h_t dmi_rsp;
  jtag_pkg::jtag_req_t jtag_req;
  jtag_pkg::jtag_rsp_t jtag_rsp;

  assign jtag_req.tck    = jtag_tck_i;
  assign jtag_req.tms    = jtag_tms_i;
  assign jtag_req.trst_n = jtag_trst_n_i;
  assign jtag_req.tdi    = jtag_tdi_i;

  assign jtag_tdo_o    = jtag_rsp.tdo;
  assign jtag_tdo_oe_o = jtag_rsp.tdo_oe;

  tlul_jtag_dtm #(
    .IdcodeValue(jtag_id_pkg::LC_DM_COMBINED_JTAG_IDCODE),
    // Notes:
    // - one RV_DM instance uses 9bits
    // - our crossbar tooling expects individual IPs to be spaced apart by 12bits at the moment
    // - the DMI address shifted through jtag is a word address and hence 2bits smaller than this
    // - setting this to 18bits effectively gives us 2^6 = 64 addressable 12bit ranges
    .NumDmiByteAbits(18)
  ) u_tlul_jtag_dtm (
    .clk_i      (clkmgr_aon_clocks.clk_main_infra),
    .rst_ni     (rstmgr_aon_resets.rst_sys_n[rstmgr_pkg::DomainMainSel]),
    .jtag_i     (jtag_req),
    .jtag_o     (jtag_rsp),
    .scan_rst_ni(scan_rst_n),
    .scanmode_i (scanmode),
    .tl_h2d_o   (dmi_req),
    .tl_d2h_i   (dmi_rsp)
  );

  // TODO: Resolve this and wire it up.
  tlul_pkg::tl_h2d_t ctn_misc_tl_h2d_i;
  assign ctn_misc_tl_h2d_i = tlul_pkg::TL_H2D_DEFAULT;
  tlul_pkg::tl_d2h_t ctn_misc_tl_d2h_o;

  // TODO: Over/ride/ all access range checks for now.
  prim_mubi_pkg::mubi8_t ac_range_check_overwrite_i;
  assign ac_range_check_overwrite_i = prim_mubi_pkg::MuBi8True;

  // TODO: External RACL error input.
  top_racl_pkg::racl_error_log_t ext_racl_error;
  assign ext_racl_error = '0;

  ////////////////
  // CTN M-to-1 //
  ////////////////

  tlul_pkg::tl_h2d_t ctn_tl_h2d[2];
  tlul_pkg::tl_d2h_t ctn_tl_d2h[2];
  //TODO: Resolve this and wire it up.
  assign ctn_tl_h2d[1] = tlul_pkg::TL_H2D_DEFAULT;

  tlul_pkg::tl_h2d_t ctn_sm1_to_s1n_tl_h2d;
  tlul_pkg::tl_d2h_t ctn_sm1_to_s1n_tl_d2h;

  tlul_socket_m1 #(
    .M         (2),
    .HReqPass  ({2{1'b1}}),
    .HRspPass  ({2{1'b1}}),
    .HReqDepth ({2{4'd0}}),
    .HRspDepth ({2{4'd0}}),
    .DReqPass  (1'b1),
    .DRspPass  (1'b1),
    .DReqDepth (4'd0),
    .DRspDepth (4'd0)
  ) u_ctn_sm1 (
    .clk_i  (clkmgr_aon_clocks.clk_main_infra),
    .rst_ni (rstmgr_aon_resets.rst_lc_n[rstmgr_pkg::DomainMainSel]),
    .tl_h_i (ctn_tl_h2d),
    .tl_h_o (ctn_tl_d2h),
    .tl_d_o (ctn_sm1_to_s1n_tl_h2d),
    .tl_d_i (ctn_sm1_to_s1n_tl_d2h)
  );

  ////////////////////////////////////////////
  // CTN Address decoding and SRAM Instance //
  ////////////////////////////////////////////

  localparam int CtnSramDw = top_pkg::TL_DW + tlul_pkg::DataIntgWidth;

  tlul_pkg::tl_h2d_t ctn_s1n_tl_h2d[1];
  tlul_pkg::tl_d2h_t ctn_s1n_tl_d2h[1];

  // Steering signal for address decoding.
  logic [0:0] ctn_dev_sel_s1n;

  logic sram_req, sram_we, sram_rvalid;
  logic [top_pkg::CtnSramAw-1:0] sram_addr;
  logic [CtnSramDw-1:0] sram_wdata, sram_wmask, sram_rdata;

  // Steering of requests.
  // Addresses leaving the RoT through the CTN port are mapped to an internal 1G address space of
  // 0x4000_0000 - 0x8000_0000. However, the CTN RAM only covers a 1MB region inside that space,
  // and hence additional decoding and steering logic is needed here.
  // TODO: this should in the future be replaced by an automatically generated crossbar.
  always_comb begin
    // Default steering to generate error response if address is not within the range
    ctn_dev_sel_s1n = 1'b1;
    // Steering to CTN SRAM.
    if ((ctn_sm1_to_s1n_tl_h2d.a_address & ~(TOP_DARJEELING_SOC_PROXY_RAM_CTN_SIZE_BYTES-1)) ==
        (TOP_DARJEELING_SOC_PROXY_RAM_CTN_BASE_ADDR - TOP_DARJEELING_SOC_PROXY_CTN_BASE_ADDR)) begin
      ctn_dev_sel_s1n = 1'd0;
    end
  end

  tlul_socket_1n #(
    .HReqDepth (4'h0),
    .HRspDepth (4'h0),
    .DReqDepth (8'h0),
    .DRspDepth (8'h0),
    .N         (1)
  ) u_ctn_s1n (
    .clk_i        (clkmgr_aon_clocks.clk_main_infra),
    .rst_ni       (rstmgr_aon_resets.rst_lc_n[rstmgr_pkg::DomainMainSel]),
    .tl_h_i       (ctn_sm1_to_s1n_tl_h2d),
    .tl_h_o       (ctn_sm1_to_s1n_tl_d2h),
    .tl_d_o       (ctn_s1n_tl_h2d),
    .tl_d_i       (ctn_s1n_tl_d2h),
    .dev_select_i (ctn_dev_sel_s1n)
  );

  tlul_adapter_sram #(
    .SramAw(top_pkg::CtnSramAw),
    .SramDw(CtnSramDw - tlul_pkg::DataIntgWidth),
    .Outstanding(2),
    .ByteAccess(1),
    .CmdIntgCheck(1),
    .EnableRspIntgGen(1),
    .EnableDataIntgGen(0),
    .EnableDataIntgPt(1),
    .SecFifoPtr      (0)
  ) u_tlul_adapter_sram_ctn (
    .clk_i       (clkmgr_aon_clocks.clk_main_infra),
    .rst_ni      (rstmgr_aon_resets.rst_lc_n[rstmgr_pkg::DomainMainSel]),
    .tl_i        (ctn_s1n_tl_h2d[0]),
    .tl_o        (ctn_s1n_tl_d2h[0]),
    // Ifetch is explicitly allowed
    .en_ifetch_i (prim_mubi_pkg::MuBi4True),
    .req_o       (sram_req),
    .req_type_o  (),
    // SRAM can always accept a request.
    .gnt_i       (1'b1),
    .we_o        (sram_we),
    .addr_o      (sram_addr),
    .wdata_o     (sram_wdata),
    .wmask_o     (sram_wmask),
    .intg_error_o(),
    .user_rsvd_o (),
    .rdata_i     (sram_rdata),
    .rvalid_i    (sram_rvalid),
    .rerror_i    ('0),
    .compound_txn_in_progress_o(),
    .readback_en_i(prim_mubi_pkg::MuBi4False),
    .readback_error_o(),
    .wr_collision_i(1'b0),
    .write_pending_i(1'b0)
  );

  prim_ram_1p_adv #(
    .Depth(top_pkg::CtnSramDepth),
    .Width(CtnSramDw),
    .DataBitsPerMask(CtnSramDw),
    .EnableECC(0),
    .EnableParity(0),
    .EnableInputPipeline(1),
    .EnableOutputPipeline(1)
  ) u_prim_ram_1p_adv_ctn (
    .clk_i    (clkmgr_aon_clocks.clk_main_infra),
    .rst_ni   (rstmgr_aon_resets.rst_lc_n[rstmgr_pkg::DomainMainSel]),
    .req_i    (sram_req),
    .write_i  (sram_we),
    .addr_i   (sram_addr),
    .wdata_i  (sram_wdata),
    .wmask_i  (sram_wmask),
    .rdata_o  (sram_rdata),
    .rvalid_o (sram_rvalid),
    // No error detection is enabled inside SRAM.
    // Bus ECC is checked at the consumer side.
    .rerror_o (),
    .cfg_i    (ram_1p_cfg),
    .cfg_rsp_o(),
    .alert_o()
  );

  // The power manager waits until the external reset request is removed by the SoC before
  // proceeding to boot after an internal reset request. DV may also drive this signal briefly and
  // asynchronously to request a reset on behalf of the simulated SoC.
  //
  // Note that since the signal is filtered inside the SoC proxy it must be of at least 5
  // AON clock periods in duration.
  logic soc_rst_req_async;
  assign soc_rst_req_async = 1'b0;

  // Inter-Power Domain signals
% for sig in top["inter_pd"]["definitions"]:
  % if isinstance(sig["width"], Parameter):
  ${lib.im_defname(sig)} [${sig["width"].name_top}-1:0] ${sig["signame"]};
  % else:
  ${lib.im_defname(sig)} ${lib.bitarray(sig["width"],1)} ${sig["signame"]};
  % endif
% endfor

  ///////////////////////////
  // Top-level Main Domain //
  ///////////////////////////
  ${top["name"]}_pd_main #(
    .PinmuxAonTargetCfg(PinmuxAonTargetCfg),
    .SecAesAllowForcingMasks(1'b1),
    .SecRomCtrl0DisableScrambling(SecRomCtrl0DisableScrambling),
    .SecRomCtrl1DisableScrambling(SecRomCtrl1DisableScrambling)
  ) ${top["name"]}_pd_main (
<%include file="/chiplevel_snippets/special_signals_portmap.tpl" args="top=top, feature_info=feature_info, cio_info=cio_info, gen_bkdr_loader=False, domain='Main'" />\

<%include file="/chiplevel_snippets/intermodule_portmap.tpl" args="top=top, target=target, domain='Main', inter_pd=True, last_snippet=False" />\

<%include file="/chiplevel_snippets/intermodule_portmap.tpl" args="top=top, target=target, domain='Main', inter_pd=False, last_snippet=True" />\
  );


  ////////////////////////////////
  // Top-level Always-On domain //
  ////////////////////////////////
  ${top["name"]}_pd_aon ${top["name"]}_pd_aon (
<%include file="/chiplevel_snippets/special_signals_portmap.tpl" args="top=top, feature_info=feature_info, cio_info=cio_info, gen_bkdr_loader=False, domain='Aon'" />\

<%include file="/chiplevel_snippets/intermodule_portmap.tpl" args="top=top, target=target, domain='Aon', inter_pd=True, last_snippet=False" />\

<%include file="/chiplevel_snippets/intermodule_portmap.tpl" args="top=top, target=target, domain='Aon', inter_pd=False, last_snippet=True" />\
  );

  logic unused_signals;
  assign unused_signals = ^{pwrmgr_boot_status.clk_status,
                            pwrmgr_boot_status.cpu_fetch_en,
                            pwrmgr_boot_status.lc_done,
                            pwrmgr_boot_status.otp_done,
                            pwrmgr_boot_status.rom_ctrl_status,
                            pwrmgr_boot_status.strap_sampled};

endmodule
