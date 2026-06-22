// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// ------------------- W A R N I N G: A U T O - G E N E R A T E D   C O D E !! -------------------//
// PLEASE DO NOT HAND-EDIT THIS FILE. IT HAS BEEN AUTO-GENERATED WITH THE FOLLOWING COMMAND:
//
// util/topgen.py -t hw/top_englishbreakfast/data/top_englishbreakfast.hjson
//                -o hw/top_englishbreakfast/


// This module bundles the englishbreakfast power domains together with the analog
// sensor top (AST). It exposes only the signals that need to cross to the
// chip-level: the pad-multiplexer interface for the padring, the AST control
// signals consumed by the padring, and the direct connections to the chip pads.
module top_englishbreakfast_cw305 #(
  parameter BootRomInitFile = "",
  parameter OtpMacroMemInitFile = "",
  parameter pinmux_pkg::target_cfg_t PinmuxAonTargetCfg = pinmux_pkg::DefaultTargetCfg
) (
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

  // AST clocks and signals needed in the padring
  output ast_pkg::ast_clks_t    ast_base_clks_o,
  output prim_mubi_pkg::mubi4_t scanmode_o,
  output logic [3:0]            mux_iob_sel_o,

  // USB connections to the chip-level USB mux glue
  output logic usb_dp_pullup_en_o,
  output logic usb_dn_pullup_en_o,

  // POR and clock inputs feeding the FPGA clock generator
  input  logic manual_in_por_n_i,
  input  logic manual_in_io_clk_i,

  input  logic manual_in_por_button_n_i


);

  import top_englishbreakfast_pkg::*;
  import prim_pad_wrapper_pkg::*;

  //////////////////////////////////////////////////////////////////////////
  // TODO Power-domain port-map nets                                             //
  // These signals cross to the chip-level through the auto-generated power- //
  // domain port map, whose connecting net names (signame_chip) are suffix-  //
  // free. Declare them here and alias them to the suffixed module ports.    //
  //////////////////////////////////////////////////////////////////////////

  //////////////////////////////////
  // AST - Common for all targets //
  //////////////////////////////////

  // pwrmgr interface
  pwrmgr_pkg::pwr_ast_req_t pwrmgr_ast_req;
  pwrmgr_pkg::pwr_ast_rsp_t pwrmgr_ast_rsp;

  // assorted ast status
  ast_pkg::ast_pwst_t ast_pwst;
  ast_pkg::ast_pwst_t ast_pwst_h;

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

  // AST clocks and signals needed in the padring
  assign ast_base_clks_o = ast_base_clks;
  assign scanmode_o = scanmode;

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


  prim_mubi_pkg::mubi4_t ast_init_done;

  ast u_ast (
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
    .clk_ast_tlul_i (clkmgr_aon_clocks.clk_io_div4_secure),
    .clk_ast_adc_i (clkmgr_aon_clocks.clk_aon_secure),
    .clk_ast_alert_i (clkmgr_aon_clocks.clk_io_div4_secure),
    .clk_ast_es_i (clkmgr_aon_clocks.clk_main_secure),
    .clk_ast_rng_i (clkmgr_aon_clocks.clk_main_secure),
    .clk_ast_usb_i (clkmgr_aon_clocks.clk_usb_peri),
    .rst_ast_tlul_ni (rstmgr_aon_resets.rst_lc_io_div4_n[rstmgr_pkg::DomainMainSel]),
    .rst_ast_adc_ni (rstmgr_aon_resets.rst_sys_aon_n[rstmgr_pkg::DomainMainSel]),
    .rst_ast_alert_ni (rstmgr_aon_resets.rst_lc_io_div4_n[rstmgr_pkg::DomainMainSel]),
    .rst_ast_es_ni (rstmgr_aon_resets.rst_sys_n[rstmgr_pkg::DomainMainSel]),
    .rst_ast_rng_ni (rstmgr_aon_resets.rst_sys_n[rstmgr_pkg::DomainMainSel]),
    .rst_ast_usb_ni (rstmgr_aon_resets.rst_usb_n[rstmgr_pkg::DomainMainSel]),
    .clk_ast_ext_i         ( ext_clk ),

    // pok test for FPGA
    .vcc_supp_i            ( 1'b1 ),
    .vcaon_supp_i          ( 1'b1 ),
    .vcmain_supp_i         ( 1'b1 ),
    .vioa_supp_i           ( 1'b1 ),
    .viob_supp_i           ( 1'b1 ),
    // pok
    .ast_pwst_o            ( ast_pwst ),
    .ast_pwst_h_o          ( ast_pwst_h ),
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
    .usb_obs_i             ( '0 ),
    .obs_ctrl_o            ( obs_ctrl ),
    // pinmux related
    .padmux2ast_i          ( pad2ast    ),
    .ast2padmux_o          ( ast2pinmux ),
    .mux_iob_sel_o         ( mux_iob_sel_o ),
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

  // Inter-Power Domain signals
  logic [2:0] intr_vector_pd_aon;
  prim_alert_pkg::alert_tx_t [5:0] alertenglishbreakfast_tx_pd_aon;
  prim_alert_pkg::alert_rx_t [5:0] alertenglishbreakfast_rx_pd_aon;
  prim_alert_pkg::alert_tx_t [21:0] alertenglishbreakfast_tx_pd_main;
  prim_alert_pkg::alert_rx_t [21:0] alertenglishbreakfast_rx_pd_main;
  pwrmgr_pkg::pwr_nvm_t       pwrmgr_aon_pwr_nvm;
  logic       pwrmgr_aon_strap;
  logic       pwrmgr_aon_low_power;
  lc_ctrl_pkg::lc_tx_t       pwrmgr_aon_fetch_en;
  prim_mubi_pkg::mubi4_t       clkmgr_aon_idle;
  rv_core_ibex_pkg::cpu_crash_dump_t       rv_core_ibex_crash_dump;
  rv_core_ibex_pkg::cpu_pwrmgr_t       rv_core_ibex_pwrmgr;
  logic [1:0] pwrmgr_aon_wakeups;
  tlul_pkg::tl_h2d_t       pwrmgr_aon_tl_req;
  tlul_pkg::tl_d2h_t       pwrmgr_aon_tl_rsp;
  tlul_pkg::tl_h2d_t       rstmgr_aon_tl_req;
  tlul_pkg::tl_d2h_t       rstmgr_aon_tl_rsp;
  tlul_pkg::tl_h2d_t       clkmgr_aon_tl_req;
  tlul_pkg::tl_d2h_t       clkmgr_aon_tl_rsp;

  ///////////////////////////
  // Top-level Main Domain //
  ///////////////////////////
  englishbreakfast_pd_main #(
    .RvCoreIbexPipeLine(0),
    .SecAesMasking(1'b1),
    .SecAesSBoxImpl(aes_pkg::SBoxImplDom),
    .SecAesStartTriggerDelay(320),
    .SecAesAllowForcingMasks(1'b1),
    .SecAesSkipPRNGReseeding(1'b1),
    .UsbdevStub(1'b1),
    .RvCoreIbexSecureIbex(0),
    .RomCtrlBootRomInitFile(BootRomInitFile),
    .RvCoreIbexRegFile(ibex_pkg::RegFileFPGA),
    .SramCtrlMainInstrExec(1),
    .PinmuxAonTargetCfg(PinmuxAonTargetCfg)
  ) englishbreakfast_pd_main (
    // Clocks and clock gating control from clkmgr_aon
    .clkmgr_aon_clocks_i(clkmgr_aon_clocks),
    .clkmgr_aon_cg_en_i (clkmgr_aon_cg_en),

    // Resets and reset assert info from rstmgr_aon
    .rstmgr_aon_resets_i(rstmgr_aon_resets),
    .rstmgr_aon_rst_en_i(rstmgr_aon_rst_en),

    // Manual DFT signals
    .scan_rst_ni(scan_rst_n),
    .scan_en_i  (scan_en   ),
    .scanmode_i (scanmode  ),

    // Multiplexed I/O
    .mio_in_i (mio_in_i ),
    .mio_out_o(mio_out_o),
    .mio_oe_o (mio_oe_o ),

    // Dedicated I/O
    .dio_in_i (dio_in_i ),
    .dio_out_o(dio_out_o),
    .dio_oe_o (dio_oe_o ),

    // Pad attributes
    .mio_attr_o(mio_attr_o),
    .dio_attr_o(dio_attr_o),

    // Special inter-power domain signals (interrupts, alerts)
    .intr_vector_pd_aon_i(intr_vector_pd_aon),


    // Ports to and from other power domains (auto-generated)
    .pwrmgr_aon_pwr_nvm_o     (pwrmgr_aon_pwr_nvm     ),
    .pwrmgr_aon_strap_i       (pwrmgr_aon_strap       ),
    .pwrmgr_aon_low_power_i   (pwrmgr_aon_low_power   ),
    .pwrmgr_aon_fetch_en_i    (pwrmgr_aon_fetch_en    ),
    .clkmgr_aon_idle_o        (clkmgr_aon_idle        ),
    .rv_core_ibex_crash_dump_o(rv_core_ibex_crash_dump),
    .rv_core_ibex_pwrmgr_o    (rv_core_ibex_pwrmgr    ),
    .pwrmgr_aon_wakeups_o     (pwrmgr_aon_wakeups     ),
    .pwrmgr_aon_tl_req_o      (pwrmgr_aon_tl_req      ),
    .pwrmgr_aon_tl_rsp_i      (pwrmgr_aon_tl_rsp      ),
    .rstmgr_aon_tl_req_o      (rstmgr_aon_tl_req      ),
    .rstmgr_aon_tl_rsp_i      (rstmgr_aon_tl_rsp      ),
    .clkmgr_aon_tl_req_o      (clkmgr_aon_tl_req      ),
    .clkmgr_aon_tl_rsp_i      (clkmgr_aon_tl_rsp      ),

    // Regular ports (auto-generated)
    .flash_bist_enable_i      (flash_bist_enable ),
    .flash_power_down_h_i     (1'b0              ),
    .flash_power_ready_h_i    (1'b1              ),
    .obs_ctrl_i               (obs_ctrl          ),
    .flash_obs_o              (flash_obs         ),
    .ast_tl_req_o             (ast_tl_req        ),
    .ast_tl_rsp_i             (ast_tl_rsp        ),
    .dft_strap_test_o         (                  ),
    .dft_hold_tap_sel_i       ('0                ),
    .usb_dp_pullup_en_o       (usb_dp_pullup_en_o),
    .usb_dn_pullup_en_o       (usb_dn_pullup_en_o),
    .fpga_info_i              (fpga_info         ),
    .usbdev_usb_rx_d_i        (1'b0              ),
    .usbdev_usb_tx_d_o        (                  ),
    .usbdev_usb_tx_se0_o      (                  ),
    .usbdev_usb_tx_use_d_se0_o(                  ),
    .usbdev_usb_rx_enable_o   (                  ),
    .usbdev_usb_ref_val_o     (usb_ref_val       ),
    .usbdev_usb_ref_pulse_o   (usb_ref_pulse     ),
    .sck_monitor_o            (sck_monitor       )
  );


  ////////////////////////////////
  // Top-level Always-On domain //
  ////////////////////////////////
  englishbreakfast_pd_aon englishbreakfast_pd_aon (
    // All externally supplied clocks
    .clk_main_i(ast_base_clks.clk_sys),
    .clk_io_i  (ast_base_clks.clk_io ),
    .clk_usb_i (ast_base_clks.clk_usb),
    .clk_aon_i (ast_base_clks.clk_aon),

    // Manual DFT signals
    .scan_rst_ni(scan_rst_n),
    .scanmode_i (scanmode  ),

    // Special inter-power domain signals (interrupts, alerts)
    .intr_vector_o(intr_vector_pd_aon),


    // Ports to and from other power domains (auto-generated)
    .pwrmgr_aon_pwr_nvm_i     (pwrmgr_aon_pwr_nvm     ),
    .pwrmgr_aon_strap_o       (pwrmgr_aon_strap       ),
    .pwrmgr_aon_low_power_o   (pwrmgr_aon_low_power   ),
    .pwrmgr_aon_fetch_en_o    (pwrmgr_aon_fetch_en    ),
    .clkmgr_aon_idle_i        (clkmgr_aon_idle        ),
    .rv_core_ibex_crash_dump_i(rv_core_ibex_crash_dump),
    .rv_core_ibex_pwrmgr_i    (rv_core_ibex_pwrmgr    ),
    .pwrmgr_aon_wakeups_i     (pwrmgr_aon_wakeups     ),
    .pwrmgr_aon_tl_req_i      (pwrmgr_aon_tl_req      ),
    .pwrmgr_aon_tl_rsp_o      (pwrmgr_aon_tl_rsp      ),
    .rstmgr_aon_tl_req_i      (rstmgr_aon_tl_req      ),
    .rstmgr_aon_tl_rsp_o      (rstmgr_aon_tl_rsp      ),
    .clkmgr_aon_tl_req_i      (clkmgr_aon_tl_req      ),
    .clkmgr_aon_tl_rsp_o      (clkmgr_aon_tl_rsp      ),

    // Regular ports (auto-generated)
    .clkmgr_aon_clocks_o (clkmgr_aon_clocks ),
    .clkmgr_aon_cg_en_o  (clkmgr_aon_cg_en  ),
    .clk_main_jitter_en_o(clk_main_jitter_en),
    .hi_speed_sel_o      (hi_speed_sel      ),
    .div_step_down_req_i (div_step_down_req ),
    .all_clk_byp_req_o   (all_clk_byp_req   ),
    .all_clk_byp_ack_i   (all_clk_byp_ack   ),
    .io_clk_byp_req_o    (io_clk_byp_req    ),
    .io_clk_byp_ack_i    (io_clk_byp_ack    ),
    .pwrmgr_ast_req_o    (pwrmgr_ast_req    ),
    .pwrmgr_ast_rsp_i    (pwrmgr_ast_rsp    ),
    .por_n_i             (por_n             ),
    .rstmgr_aon_resets_o (rstmgr_aon_resets ),
    .rstmgr_aon_rst_en_o (rstmgr_aon_rst_en )
  );

endmodule
