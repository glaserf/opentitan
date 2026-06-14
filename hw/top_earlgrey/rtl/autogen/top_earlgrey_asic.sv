// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// ------------------- W A R N I N G: A U T O - G E N E R A T E D   C O D E !! -------------------//
// PLEASE DO NOT HAND-EDIT THIS FILE. IT HAS BEEN AUTO-GENERATED WITH THE FOLLOWING COMMAND:
//
// util/topgen.py -t hw/top_earlgrey/data/top_earlgrey.hjson
//                -o hw/top_earlgrey/


// This module bundles the earlgrey power domains together with the analog
// sensor top (AST). It exposes only the signals that need to cross to the
// chip-level: the pad-multiplexer interface for the padring, the AST control
// signals consumed by the padring, and the direct connections to the chip pads.
module top_earlgrey_asic #(
  parameter bit SecRomCtrlDisableScrambling = 1'b0,
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

  // Raw multiplexed pad inputs (tapped for the external clock and the
  // PAD2AST_WIRES macro)
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
  inout     OTP_EXT_VOLT
);

  import top_earlgrey_pkg::*;
  import prim_pad_wrapper_pkg::*;

  //////////////////////////////////////////////////////////////////////////
  // TODO Power-domain port-map nets                                             //
  // These signals cross to the chip-level through the auto-generated power- //
  // domain port map, whose connecting net names (signame_chip) are suffix-  //
  // free. Declare them here and alias them to the suffixed module ports.    //
  //////////////////////////////////////////////////////////////////////////
  logic                                  usb_diff_rx_obs;
  ast_pkg::ast_pwst_t                    ast_pwst_h;
  prim_pad_wrapper_pkg::pad_attr_t [3:0] sensor_ctrl_manual_pad_attr;
  // The PAD2AST_WIRES macro references the suffix-free net name.
  logic [pinmux_reg_pkg::NMioPads-1:0]   mio_in_raw;
  assign mio_in_raw                    = mio_in_raw_i;
  assign usb_diff_rx_obs               = usb_diff_rx_obs_i;
  assign ast_pwst_h_o                  = ast_pwst_h;
  assign sensor_ctrl_manual_pad_attr_o = sensor_ctrl_manual_pad_attr;

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

  // AST clocks and signals needed in the padring
  assign ast_base_clks_o = ast_base_clks;
  assign scanmode_o = scanmode;


  // external clock comes in at a fixed position
  assign ext_clk = mio_in_raw[MioPadIoc6];

  assign pad2ast = `PAD2AST_WIRES ;

  // AST does not use all clocks / resets forwarded to it
  logic unused_slow_clk_en;
  assign unused_slow_clk_en = pwrmgr_ast_req.slow_clk_en;

  logic unused_pwr_clamp;
  assign unused_pwr_clamp = pwrmgr_ast_req.pwr_clamp;


  prim_mubi_pkg::mubi4_t ast_init_done;

  ast u_ast (
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
    .clk_ast_tlul_i (clkmgr_aon_clocks.clk_io_div4_infra),
    .clk_ast_adc_i (clkmgr_aon_clocks.clk_aon_peri),
    .clk_ast_alert_i (clkmgr_aon_clocks.clk_io_div4_secure),
    .clk_ast_es_i (clkmgr_aon_clocks.clk_main_secure),
    .clk_ast_rng_i (clkmgr_aon_clocks.clk_main_secure),
    .clk_ast_usb_i (clkmgr_aon_clocks.clk_usb_peri),
    .rst_ast_tlul_ni (rstmgr_aon_resets.rst_lc_io_div4_n[rstmgr_pkg::DomainMainSel]),
    .rst_ast_adc_ni (rstmgr_aon_resets.rst_lc_aon_n[rstmgr_pkg::DomainAonSel]),
    .rst_ast_alert_ni (rstmgr_aon_resets.rst_lc_io_div4_n[rstmgr_pkg::DomainMainSel]),
    .rst_ast_es_ni (rstmgr_aon_resets.rst_lc_n[rstmgr_pkg::DomainMainSel]),
    .rst_ast_rng_ni (rstmgr_aon_resets.rst_lc_n[rstmgr_pkg::DomainMainSel]),
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
    .usb_obs_i             ( usb_diff_rx_obs ),
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
  logic [6:0] intr_vector_pd_aon;
  prim_alert_pkg::alert_tx_t [10:0] alert_tx_pd_aon;
  prim_alert_pkg::alert_rx_t [10:0] alert_rx_pd_aon;
  alert_handler_pkg::alert_crashdump_t       alert_handler_crashdump;
  prim_esc_pkg::esc_rx_t       alert_handler_esc_rx;
  prim_esc_pkg::esc_tx_t       alert_handler_esc_tx;
  logic       aon_timer_aon_nmi_wdog_timer_bark;
  otp_ctrl_pkg::sram_otp_key_req_t       otp_ctrl_sram_otp_key_req;
  otp_ctrl_pkg::sram_otp_key_rsp_t       otp_ctrl_sram_otp_key_rsp;
  pwrmgr_pkg::pwr_nvm_t       pwrmgr_aon_pwr_nvm;
  pwrmgr_pkg::pwr_otp_req_t       pwrmgr_aon_pwr_otp_req;
  pwrmgr_pkg::pwr_otp_rsp_t       pwrmgr_aon_pwr_otp_rsp;
  lc_ctrl_pkg::pwr_lc_req_t       pwrmgr_aon_pwr_lc_req;
  lc_ctrl_pkg::pwr_lc_rsp_t       pwrmgr_aon_pwr_lc_rsp;
  logic       pwrmgr_aon_strap;
  logic       pwrmgr_aon_low_power;
  lc_ctrl_pkg::lc_tx_t       pwrmgr_aon_fetch_en;
  rom_ctrl_pkg::pwrmgr_data_t       rom_ctrl_pwrmgr_data;
  prim_mubi_pkg::mubi4_t [3:0] clkmgr_aon_idle;
  lc_ctrl_pkg::lc_tx_t       lc_ctrl_lc_dft_en;
  lc_ctrl_pkg::lc_tx_t       lc_ctrl_lc_hw_debug_en;
  lc_ctrl_pkg::lc_tx_t       lc_ctrl_lc_escalate_en;
  lc_ctrl_pkg::lc_tx_t       lc_ctrl_lc_clk_byp_req;
  lc_ctrl_pkg::lc_tx_t       lc_ctrl_lc_clk_byp_ack;
  rv_core_ibex_pkg::cpu_crash_dump_t       rv_core_ibex_crash_dump;
  rv_core_ibex_pkg::cpu_pwrmgr_t       rv_core_ibex_pwrmgr;
  logic       rv_dm_ndmreset_req;
  logic [1:0] pwrmgr_aon_wakeups;
  tlul_pkg::tl_h2d_t       pwrmgr_aon_tl_req;
  tlul_pkg::tl_d2h_t       pwrmgr_aon_tl_rsp;
  tlul_pkg::tl_h2d_t       rstmgr_aon_tl_req;
  tlul_pkg::tl_d2h_t       rstmgr_aon_tl_rsp;
  tlul_pkg::tl_h2d_t       clkmgr_aon_tl_req;
  tlul_pkg::tl_d2h_t       clkmgr_aon_tl_rsp;
  tlul_pkg::tl_h2d_t       sensor_ctrl_aon_tl_req;
  tlul_pkg::tl_d2h_t       sensor_ctrl_aon_tl_rsp;
  tlul_pkg::tl_h2d_t       sram_ctrl_ret_aon_regs_tl_req;
  tlul_pkg::tl_d2h_t       sram_ctrl_ret_aon_regs_tl_rsp;
  tlul_pkg::tl_h2d_t       sram_ctrl_ret_aon_ram_tl_req;
  tlul_pkg::tl_d2h_t       sram_ctrl_ret_aon_ram_tl_rsp;
  tlul_pkg::tl_h2d_t       aon_timer_aon_tl_req;
  tlul_pkg::tl_d2h_t       aon_timer_aon_tl_rsp;
  tlul_pkg::tl_h2d_t       sysrst_ctrl_aon_tl_req;
  tlul_pkg::tl_d2h_t       sysrst_ctrl_aon_tl_rsp;
  tlul_pkg::tl_h2d_t       adc_ctrl_aon_tl_req;
  tlul_pkg::tl_d2h_t       adc_ctrl_aon_tl_rsp;
  logic       cio_sysrst_ctrl_aon_ec_rst_l_d2p;
  logic       cio_sysrst_ctrl_aon_ec_rst_l_en_d2p;
  logic       cio_sysrst_ctrl_aon_ec_rst_l_p2d;
  logic       cio_sysrst_ctrl_aon_flash_wp_l_d2p;
  logic       cio_sysrst_ctrl_aon_flash_wp_l_en_d2p;
  logic       cio_sysrst_ctrl_aon_flash_wp_l_p2d;
  logic       cio_sysrst_ctrl_aon_ac_present_p2d;
  logic       cio_sysrst_ctrl_aon_key0_in_p2d;
  logic       cio_sysrst_ctrl_aon_key1_in_p2d;
  logic       cio_sysrst_ctrl_aon_key2_in_p2d;
  logic       cio_sysrst_ctrl_aon_pwrb_in_p2d;
  logic       cio_sysrst_ctrl_aon_lid_open_p2d;
  logic       cio_sysrst_ctrl_aon_bat_disable_d2p;
  logic       cio_sysrst_ctrl_aon_bat_disable_en_d2p;
  logic       cio_sysrst_ctrl_aon_key0_out_d2p;
  logic       cio_sysrst_ctrl_aon_key0_out_en_d2p;
  logic       cio_sysrst_ctrl_aon_key1_out_d2p;
  logic       cio_sysrst_ctrl_aon_key1_out_en_d2p;
  logic       cio_sysrst_ctrl_aon_key2_out_d2p;
  logic       cio_sysrst_ctrl_aon_key2_out_en_d2p;
  logic       cio_sysrst_ctrl_aon_pwrb_out_d2p;
  logic       cio_sysrst_ctrl_aon_pwrb_out_en_d2p;
  logic       cio_sysrst_ctrl_aon_z3_wakeup_d2p;
  logic       cio_sysrst_ctrl_aon_z3_wakeup_en_d2p;
  logic [8:0] cio_sensor_ctrl_aon_ast_debug_out_d2p;
  logic [8:0] cio_sensor_ctrl_aon_ast_debug_out_en_d2p;

  ///////////////////////////
  // Top-level Main Domain //
  ///////////////////////////
  earlgrey_pd_main #(
    .I2c0InputDelayCycles(1),
    .I2c1InputDelayCycles(1),
    .I2c2InputDelayCycles(1),
    .SecAesAllowForcingMasks(1'b1),
    .SecRomCtrlDisableScrambling(SecRomCtrlDisableScrambling),
    .PinmuxAonTargetCfg(PinmuxAonTargetCfg)
  ) earlgrey_pd_main (
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

    .alert_tx_pd_aon_i(alert_tx_pd_aon),
    .alert_rx_pd_aon_o(alert_rx_pd_aon),

    // Ports to and from other power domains (auto-generated)
    .alert_handler_crashdump_o                 (alert_handler_crashdump  ),
    .alert_handler_esc_rx_i                    (alert_handler_esc_rx     ),
    .alert_handler_esc_tx_o                    (alert_handler_esc_tx     ),
    .aon_timer_aon_nmi_wdog_timer_bark_i       (aon_timer_aon_nmi_wdog_timer_bark),
    .otp_ctrl_sram_otp_key_req_i               (otp_ctrl_sram_otp_key_req),
    .otp_ctrl_sram_otp_key_rsp_o               (otp_ctrl_sram_otp_key_rsp),
    .pwrmgr_aon_pwr_nvm_o                      (pwrmgr_aon_pwr_nvm       ),
    .pwrmgr_aon_pwr_otp_req_i                  (pwrmgr_aon_pwr_otp_req   ),
    .pwrmgr_aon_pwr_otp_rsp_o                  (pwrmgr_aon_pwr_otp_rsp   ),
    .pwrmgr_aon_pwr_lc_req_i                   (pwrmgr_aon_pwr_lc_req    ),
    .pwrmgr_aon_pwr_lc_rsp_o                   (pwrmgr_aon_pwr_lc_rsp    ),
    .pwrmgr_aon_strap_i                        (pwrmgr_aon_strap         ),
    .pwrmgr_aon_low_power_i                    (pwrmgr_aon_low_power     ),
    .pwrmgr_aon_fetch_en_i                     (pwrmgr_aon_fetch_en      ),
    .rom_ctrl_pwrmgr_data_o                    (rom_ctrl_pwrmgr_data     ),
    .clkmgr_aon_idle_o                         (clkmgr_aon_idle          ),
    .lc_ctrl_lc_dft_en_o                       (lc_ctrl_lc_dft_en        ),
    .lc_ctrl_lc_hw_debug_en_o                  (lc_ctrl_lc_hw_debug_en   ),
    .lc_ctrl_lc_escalate_en_o                  (lc_ctrl_lc_escalate_en   ),
    .lc_ctrl_lc_clk_byp_req_o                  (lc_ctrl_lc_clk_byp_req   ),
    .lc_ctrl_lc_clk_byp_ack_i                  (lc_ctrl_lc_clk_byp_ack   ),
    .rv_core_ibex_crash_dump_o                 (rv_core_ibex_crash_dump  ),
    .rv_core_ibex_pwrmgr_o                     (rv_core_ibex_pwrmgr      ),
    .rv_dm_ndmreset_req_o                      (rv_dm_ndmreset_req       ),
    .pwrmgr_aon_wakeups_o                      (pwrmgr_aon_wakeups       ),
    .pwrmgr_aon_tl_req_o                       (pwrmgr_aon_tl_req        ),
    .pwrmgr_aon_tl_rsp_i                       (pwrmgr_aon_tl_rsp        ),
    .rstmgr_aon_tl_req_o                       (rstmgr_aon_tl_req        ),
    .rstmgr_aon_tl_rsp_i                       (rstmgr_aon_tl_rsp        ),
    .clkmgr_aon_tl_req_o                       (clkmgr_aon_tl_req        ),
    .clkmgr_aon_tl_rsp_i                       (clkmgr_aon_tl_rsp        ),
    .sensor_ctrl_aon_tl_req_o                  (sensor_ctrl_aon_tl_req   ),
    .sensor_ctrl_aon_tl_rsp_i                  (sensor_ctrl_aon_tl_rsp   ),
    .sram_ctrl_ret_aon_regs_tl_req_o           (sram_ctrl_ret_aon_regs_tl_req),
    .sram_ctrl_ret_aon_regs_tl_rsp_i           (sram_ctrl_ret_aon_regs_tl_rsp),
    .sram_ctrl_ret_aon_ram_tl_req_o            (sram_ctrl_ret_aon_ram_tl_req),
    .sram_ctrl_ret_aon_ram_tl_rsp_i            (sram_ctrl_ret_aon_ram_tl_rsp),
    .aon_timer_aon_tl_req_o                    (aon_timer_aon_tl_req     ),
    .aon_timer_aon_tl_rsp_i                    (aon_timer_aon_tl_rsp     ),
    .sysrst_ctrl_aon_tl_req_o                  (sysrst_ctrl_aon_tl_req   ),
    .sysrst_ctrl_aon_tl_rsp_i                  (sysrst_ctrl_aon_tl_rsp   ),
    .adc_ctrl_aon_tl_req_o                     (adc_ctrl_aon_tl_req      ),
    .adc_ctrl_aon_tl_rsp_i                     (adc_ctrl_aon_tl_rsp      ),
    .cio_sysrst_ctrl_aon_ec_rst_l_d2p_i        (cio_sysrst_ctrl_aon_ec_rst_l_d2p),
    .cio_sysrst_ctrl_aon_ec_rst_l_en_d2p_i     (cio_sysrst_ctrl_aon_ec_rst_l_en_d2p),
    .cio_sysrst_ctrl_aon_ec_rst_l_p2d_o        (cio_sysrst_ctrl_aon_ec_rst_l_p2d),
    .cio_sysrst_ctrl_aon_flash_wp_l_d2p_i      (cio_sysrst_ctrl_aon_flash_wp_l_d2p),
    .cio_sysrst_ctrl_aon_flash_wp_l_en_d2p_i   (cio_sysrst_ctrl_aon_flash_wp_l_en_d2p),
    .cio_sysrst_ctrl_aon_flash_wp_l_p2d_o      (cio_sysrst_ctrl_aon_flash_wp_l_p2d),
    .cio_sysrst_ctrl_aon_ac_present_p2d_o      (cio_sysrst_ctrl_aon_ac_present_p2d),
    .cio_sysrst_ctrl_aon_key0_in_p2d_o         (cio_sysrst_ctrl_aon_key0_in_p2d),
    .cio_sysrst_ctrl_aon_key1_in_p2d_o         (cio_sysrst_ctrl_aon_key1_in_p2d),
    .cio_sysrst_ctrl_aon_key2_in_p2d_o         (cio_sysrst_ctrl_aon_key2_in_p2d),
    .cio_sysrst_ctrl_aon_pwrb_in_p2d_o         (cio_sysrst_ctrl_aon_pwrb_in_p2d),
    .cio_sysrst_ctrl_aon_lid_open_p2d_o        (cio_sysrst_ctrl_aon_lid_open_p2d),
    .cio_sysrst_ctrl_aon_bat_disable_d2p_i     (cio_sysrst_ctrl_aon_bat_disable_d2p),
    .cio_sysrst_ctrl_aon_bat_disable_en_d2p_i  (cio_sysrst_ctrl_aon_bat_disable_en_d2p),
    .cio_sysrst_ctrl_aon_key0_out_d2p_i        (cio_sysrst_ctrl_aon_key0_out_d2p),
    .cio_sysrst_ctrl_aon_key0_out_en_d2p_i     (cio_sysrst_ctrl_aon_key0_out_en_d2p),
    .cio_sysrst_ctrl_aon_key1_out_d2p_i        (cio_sysrst_ctrl_aon_key1_out_d2p),
    .cio_sysrst_ctrl_aon_key1_out_en_d2p_i     (cio_sysrst_ctrl_aon_key1_out_en_d2p),
    .cio_sysrst_ctrl_aon_key2_out_d2p_i        (cio_sysrst_ctrl_aon_key2_out_d2p),
    .cio_sysrst_ctrl_aon_key2_out_en_d2p_i     (cio_sysrst_ctrl_aon_key2_out_en_d2p),
    .cio_sysrst_ctrl_aon_pwrb_out_d2p_i        (cio_sysrst_ctrl_aon_pwrb_out_d2p),
    .cio_sysrst_ctrl_aon_pwrb_out_en_d2p_i     (cio_sysrst_ctrl_aon_pwrb_out_en_d2p),
    .cio_sysrst_ctrl_aon_z3_wakeup_d2p_i       (cio_sysrst_ctrl_aon_z3_wakeup_d2p),
    .cio_sysrst_ctrl_aon_z3_wakeup_en_d2p_i    (cio_sysrst_ctrl_aon_z3_wakeup_en_d2p),
    .cio_sensor_ctrl_aon_ast_debug_out_d2p_i   (cio_sensor_ctrl_aon_ast_debug_out_d2p),
    .cio_sensor_ctrl_aon_ast_debug_out_en_d2p_i(cio_sensor_ctrl_aon_ast_debug_out_en_d2p),

    // Regular ports (auto-generated)
    .ast_edn_req_i            (ast_edn_req        ),
    .ast_edn_rsp_o            (ast_edn_rsp        ),
    .ast_lc_dft_en_o          (lc_dft_en          ),
    .obs_ctrl_i               (obs_ctrl           ),
    .ram_1p_cfg_i             (ram_1p_cfg         ),
    .sram_ctrl_main_cfg_i     ('{ram_1p_cfg}      ),
    .spi_ram_2p_cfg_i         (spi_ram_2p_cfg     ),
    .usb_ram_1p_cfg_i         (usb_ram_1p_cfg     ),
    .rom_cfg_i                (rom_cfg            ),
    .flash_bist_enable_i      (flash_bist_enable  ),
    .flash_power_down_h_i     (flash_power_down_h ),
    .flash_power_ready_h_i    (flash_power_ready_h),
    .flash_test_mode_a_io     ({FLASH_TEST_MODE1, FLASH_TEST_MODE0}),
    .flash_test_voltage_h_io  (FLASH_TEST_VOLT    ),
    .flash_obs_o              (flash_obs          ),
    .es_rng_enable_o          (es_rng_enable      ),
    .es_rng_valid_i           (es_rng_valid       ),
    .es_rng_bit_i             (es_rng_bit         ),
    .es_rng_fips_o            (es_rng_fips        ),
    .ast_tl_req_o             (ast_tl_req         ),
    .ast_tl_rsp_i             (ast_tl_rsp         ),
    .dft_strap_test_o         (dft_strap_test     ),
    .dft_hold_tap_sel_i       ('0                 ),
    .usb_dp_pullup_en_o       (usb_dp_pullup_en_o ),
    .usb_dn_pullup_en_o       (usb_dn_pullup_en_o ),
    .otp_macro_pwr_seq_o      (otp_macro_pwr_seq  ),
    .otp_macro_pwr_seq_h_i    (otp_macro_pwr_seq_h),
    .otp_ext_voltage_h_io     (OTP_EXT_VOLT       ),
    .otp_obs_o                (otp_obs            ),
    .fpga_info_i              ('0                 ),
    .sck_monitor_o            (sck_monitor        ),
    .usbdev_usb_rx_d_i        (usb_rx_d_i         ),
    .usbdev_usb_tx_d_o        (                   ),
    .usbdev_usb_tx_se0_o      (                   ),
    .usbdev_usb_tx_use_d_se0_o(                   ),
    .usbdev_usb_rx_enable_o   (usb_rx_enable_o    ),
    .usbdev_usb_ref_val_o     (usb_ref_val        ),
    .usbdev_usb_ref_pulse_o   (usb_ref_pulse      )
  );


  ////////////////////////////////
  // Top-level Always-On domain //
  ////////////////////////////////
  earlgrey_pd_aon earlgrey_pd_aon (
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

    .alert_tx_o(alert_tx_pd_aon),
    .alert_rx_i(alert_rx_pd_aon),

    // Ports to and from other power domains (auto-generated)
    .alert_handler_crashdump_i                 (alert_handler_crashdump  ),
    .alert_handler_esc_rx_o                    (alert_handler_esc_rx     ),
    .alert_handler_esc_tx_i                    (alert_handler_esc_tx     ),
    .aon_timer_aon_nmi_wdog_timer_bark_o       (aon_timer_aon_nmi_wdog_timer_bark),
    .otp_ctrl_sram_otp_key_req_o               (otp_ctrl_sram_otp_key_req),
    .otp_ctrl_sram_otp_key_rsp_i               (otp_ctrl_sram_otp_key_rsp),
    .pwrmgr_aon_pwr_nvm_i                      (pwrmgr_aon_pwr_nvm       ),
    .pwrmgr_aon_pwr_otp_req_o                  (pwrmgr_aon_pwr_otp_req   ),
    .pwrmgr_aon_pwr_otp_rsp_i                  (pwrmgr_aon_pwr_otp_rsp   ),
    .pwrmgr_aon_pwr_lc_req_o                   (pwrmgr_aon_pwr_lc_req    ),
    .pwrmgr_aon_pwr_lc_rsp_i                   (pwrmgr_aon_pwr_lc_rsp    ),
    .pwrmgr_aon_strap_o                        (pwrmgr_aon_strap         ),
    .pwrmgr_aon_low_power_o                    (pwrmgr_aon_low_power     ),
    .pwrmgr_aon_fetch_en_o                     (pwrmgr_aon_fetch_en      ),
    .rom_ctrl_pwrmgr_data_i                    (rom_ctrl_pwrmgr_data     ),
    .clkmgr_aon_idle_i                         (clkmgr_aon_idle          ),
    .lc_ctrl_lc_dft_en_i                       (lc_ctrl_lc_dft_en        ),
    .lc_ctrl_lc_hw_debug_en_i                  (lc_ctrl_lc_hw_debug_en   ),
    .lc_ctrl_lc_escalate_en_i                  (lc_ctrl_lc_escalate_en   ),
    .lc_ctrl_lc_clk_byp_req_i                  (lc_ctrl_lc_clk_byp_req   ),
    .lc_ctrl_lc_clk_byp_ack_o                  (lc_ctrl_lc_clk_byp_ack   ),
    .rv_core_ibex_crash_dump_i                 (rv_core_ibex_crash_dump  ),
    .rv_core_ibex_pwrmgr_i                     (rv_core_ibex_pwrmgr      ),
    .rv_dm_ndmreset_req_i                      (rv_dm_ndmreset_req       ),
    .pwrmgr_aon_wakeups_i                      (pwrmgr_aon_wakeups       ),
    .pwrmgr_aon_tl_req_i                       (pwrmgr_aon_tl_req        ),
    .pwrmgr_aon_tl_rsp_o                       (pwrmgr_aon_tl_rsp        ),
    .rstmgr_aon_tl_req_i                       (rstmgr_aon_tl_req        ),
    .rstmgr_aon_tl_rsp_o                       (rstmgr_aon_tl_rsp        ),
    .clkmgr_aon_tl_req_i                       (clkmgr_aon_tl_req        ),
    .clkmgr_aon_tl_rsp_o                       (clkmgr_aon_tl_rsp        ),
    .sensor_ctrl_aon_tl_req_i                  (sensor_ctrl_aon_tl_req   ),
    .sensor_ctrl_aon_tl_rsp_o                  (sensor_ctrl_aon_tl_rsp   ),
    .sram_ctrl_ret_aon_regs_tl_req_i           (sram_ctrl_ret_aon_regs_tl_req),
    .sram_ctrl_ret_aon_regs_tl_rsp_o           (sram_ctrl_ret_aon_regs_tl_rsp),
    .sram_ctrl_ret_aon_ram_tl_req_i            (sram_ctrl_ret_aon_ram_tl_req),
    .sram_ctrl_ret_aon_ram_tl_rsp_o            (sram_ctrl_ret_aon_ram_tl_rsp),
    .aon_timer_aon_tl_req_i                    (aon_timer_aon_tl_req     ),
    .aon_timer_aon_tl_rsp_o                    (aon_timer_aon_tl_rsp     ),
    .sysrst_ctrl_aon_tl_req_i                  (sysrst_ctrl_aon_tl_req   ),
    .sysrst_ctrl_aon_tl_rsp_o                  (sysrst_ctrl_aon_tl_rsp   ),
    .adc_ctrl_aon_tl_req_i                     (adc_ctrl_aon_tl_req      ),
    .adc_ctrl_aon_tl_rsp_o                     (adc_ctrl_aon_tl_rsp      ),
    .cio_sysrst_ctrl_aon_ec_rst_l_d2p_o        (cio_sysrst_ctrl_aon_ec_rst_l_d2p),
    .cio_sysrst_ctrl_aon_ec_rst_l_en_d2p_o     (cio_sysrst_ctrl_aon_ec_rst_l_en_d2p),
    .cio_sysrst_ctrl_aon_ec_rst_l_p2d_i        (cio_sysrst_ctrl_aon_ec_rst_l_p2d),
    .cio_sysrst_ctrl_aon_flash_wp_l_d2p_o      (cio_sysrst_ctrl_aon_flash_wp_l_d2p),
    .cio_sysrst_ctrl_aon_flash_wp_l_en_d2p_o   (cio_sysrst_ctrl_aon_flash_wp_l_en_d2p),
    .cio_sysrst_ctrl_aon_flash_wp_l_p2d_i      (cio_sysrst_ctrl_aon_flash_wp_l_p2d),
    .cio_sysrst_ctrl_aon_ac_present_p2d_i      (cio_sysrst_ctrl_aon_ac_present_p2d),
    .cio_sysrst_ctrl_aon_key0_in_p2d_i         (cio_sysrst_ctrl_aon_key0_in_p2d),
    .cio_sysrst_ctrl_aon_key1_in_p2d_i         (cio_sysrst_ctrl_aon_key1_in_p2d),
    .cio_sysrst_ctrl_aon_key2_in_p2d_i         (cio_sysrst_ctrl_aon_key2_in_p2d),
    .cio_sysrst_ctrl_aon_pwrb_in_p2d_i         (cio_sysrst_ctrl_aon_pwrb_in_p2d),
    .cio_sysrst_ctrl_aon_lid_open_p2d_i        (cio_sysrst_ctrl_aon_lid_open_p2d),
    .cio_sysrst_ctrl_aon_bat_disable_d2p_o     (cio_sysrst_ctrl_aon_bat_disable_d2p),
    .cio_sysrst_ctrl_aon_bat_disable_en_d2p_o  (cio_sysrst_ctrl_aon_bat_disable_en_d2p),
    .cio_sysrst_ctrl_aon_key0_out_d2p_o        (cio_sysrst_ctrl_aon_key0_out_d2p),
    .cio_sysrst_ctrl_aon_key0_out_en_d2p_o     (cio_sysrst_ctrl_aon_key0_out_en_d2p),
    .cio_sysrst_ctrl_aon_key1_out_d2p_o        (cio_sysrst_ctrl_aon_key1_out_d2p),
    .cio_sysrst_ctrl_aon_key1_out_en_d2p_o     (cio_sysrst_ctrl_aon_key1_out_en_d2p),
    .cio_sysrst_ctrl_aon_key2_out_d2p_o        (cio_sysrst_ctrl_aon_key2_out_d2p),
    .cio_sysrst_ctrl_aon_key2_out_en_d2p_o     (cio_sysrst_ctrl_aon_key2_out_en_d2p),
    .cio_sysrst_ctrl_aon_pwrb_out_d2p_o        (cio_sysrst_ctrl_aon_pwrb_out_d2p),
    .cio_sysrst_ctrl_aon_pwrb_out_en_d2p_o     (cio_sysrst_ctrl_aon_pwrb_out_en_d2p),
    .cio_sysrst_ctrl_aon_z3_wakeup_d2p_o       (cio_sysrst_ctrl_aon_z3_wakeup_d2p),
    .cio_sysrst_ctrl_aon_z3_wakeup_en_d2p_o    (cio_sysrst_ctrl_aon_z3_wakeup_en_d2p),
    .cio_sensor_ctrl_aon_ast_debug_out_d2p_o   (cio_sensor_ctrl_aon_ast_debug_out_d2p),
    .cio_sensor_ctrl_aon_ast_debug_out_en_d2p_o(cio_sensor_ctrl_aon_ast_debug_out_en_d2p),

    // Regular ports (auto-generated)
    .adc_req_o                    (adc_req           ),
    .adc_rsp_i                    (adc_rsp           ),
    .sram_ctrl_ret_aon_cfg_i      ('{ram_1p_cfg}     ),
    .clkmgr_aon_clocks_o          (clkmgr_aon_clocks ),
    .clkmgr_aon_cg_en_o           (clkmgr_aon_cg_en  ),
    .clk_main_jitter_en_o         (clk_main_jitter_en),
    .io_clk_byp_req_o             (io_clk_byp_req    ),
    .io_clk_byp_ack_i             (io_clk_byp_ack    ),
    .all_clk_byp_req_o            (all_clk_byp_req   ),
    .all_clk_byp_ack_i            (all_clk_byp_ack   ),
    .hi_speed_sel_o               (hi_speed_sel      ),
    .div_step_down_req_i          (div_step_down_req ),
    .calib_rdy_i                  (ast_init_done     ),
    .pwrmgr_ast_req_o             (pwrmgr_ast_req    ),
    .pwrmgr_ast_rsp_i             (pwrmgr_ast_rsp    ),
    .por_n_i                      (por_n             ),
    .rstmgr_aon_resets_o          (rstmgr_aon_resets ),
    .rstmgr_aon_rst_en_o          (rstmgr_aon_rst_en ),
    .sensor_ctrl_ast_alert_req_i  (ast_alert_req     ),
    .sensor_ctrl_ast_alert_rsp_o  (ast_alert_rsp     ),
    .sensor_ctrl_ast_status_i     (ast_pwst.io_pok   ),
    .ast2pinmux_i                 (ast2pinmux        ),
    .ast_init_done_i              (ast_init_done     ),
    .sensor_ctrl_manual_pad_attr_o(sensor_ctrl_manual_pad_attr)
  );

endmodule
