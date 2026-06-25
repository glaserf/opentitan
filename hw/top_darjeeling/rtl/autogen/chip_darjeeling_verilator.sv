// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// ------------------- W A R N I N G: A U T O - G E N E R A T E D   C O D E !! -------------------//
// PLEASE DO NOT HAND-EDIT THIS FILE. IT HAS BEEN AUTO-GENERATED WITH THE FOLLOWING COMMAND:
//
// util/topgen.py -t hw/top_darjeeling/data/top_darjeeling.hjson
//                -o hw/top_darjeeling/


module chip_darjeeling_verilator #(
  parameter bit SecRomCtrl0DisableScrambling = 1'b0,
  parameter bit SecRomCtrl1DisableScrambling = 1'b0
) (
  // Clock and Reset
  input clk_i,
  input rst_ni
);

  import top_darjeeling_pkg::*;
  import prim_pad_wrapper_pkg::*;


  // DFT and Debug signal positions in the pinout.
  localparam pinmux_pkg::target_cfg_t PinmuxTargetCfg = '{
    // Pad types for attribute WARL behavior
    dio_pad_type: {
      BidirStd, // DIO soc_proxy_soc_gpo
      BidirStd, // DIO soc_proxy_soc_gpo
      BidirStd, // DIO soc_proxy_soc_gpo
      BidirStd, // DIO soc_proxy_soc_gpo
      BidirStd, // DIO soc_proxy_soc_gpo
      BidirStd, // DIO soc_proxy_soc_gpo
      BidirStd, // DIO soc_proxy_soc_gpo
      BidirStd, // DIO soc_proxy_soc_gpo
      BidirStd, // DIO soc_proxy_soc_gpo
      BidirStd, // DIO soc_proxy_soc_gpo
      BidirStd, // DIO soc_proxy_soc_gpo
      BidirStd, // DIO soc_proxy_soc_gpo
      BidirStd, // DIO uart0_tx
      BidirStd, // DIO spi_host0_csb
      BidirStd, // DIO spi_host0_sck
      InputStd, // DIO soc_proxy_soc_gpi
      InputStd, // DIO soc_proxy_soc_gpi
      InputStd, // DIO soc_proxy_soc_gpi
      InputStd, // DIO soc_proxy_soc_gpi
      InputStd, // DIO soc_proxy_soc_gpi
      InputStd, // DIO soc_proxy_soc_gpi
      InputStd, // DIO soc_proxy_soc_gpi
      InputStd, // DIO soc_proxy_soc_gpi
      InputStd, // DIO soc_proxy_soc_gpi
      InputStd, // DIO soc_proxy_soc_gpi
      InputStd, // DIO soc_proxy_soc_gpi
      InputStd, // DIO soc_proxy_soc_gpi
      InputStd, // DIO uart0_rx
      InputStd, // DIO spi_device_tpm_csb
      InputStd, // DIO spi_device_csb
      InputStd, // DIO spi_device_sck
      BidirStd, // DIO gpio_gpio
      BidirStd, // DIO gpio_gpio
      BidirStd, // DIO gpio_gpio
      BidirStd, // DIO gpio_gpio
      BidirStd, // DIO gpio_gpio
      BidirStd, // DIO gpio_gpio
      BidirStd, // DIO gpio_gpio
      BidirStd, // DIO gpio_gpio
      BidirStd, // DIO gpio_gpio
      BidirStd, // DIO gpio_gpio
      BidirStd, // DIO gpio_gpio
      BidirStd, // DIO gpio_gpio
      BidirStd, // DIO gpio_gpio
      BidirStd, // DIO gpio_gpio
      BidirStd, // DIO gpio_gpio
      BidirStd, // DIO gpio_gpio
      BidirStd, // DIO gpio_gpio
      BidirStd, // DIO gpio_gpio
      BidirStd, // DIO gpio_gpio
      BidirStd, // DIO gpio_gpio
      BidirStd, // DIO gpio_gpio
      BidirStd, // DIO gpio_gpio
      BidirStd, // DIO gpio_gpio
      BidirStd, // DIO gpio_gpio
      BidirStd, // DIO gpio_gpio
      BidirStd, // DIO gpio_gpio
      BidirStd, // DIO gpio_gpio
      BidirStd, // DIO gpio_gpio
      BidirStd, // DIO gpio_gpio
      BidirStd, // DIO gpio_gpio
      BidirStd, // DIO gpio_gpio
      BidirStd, // DIO gpio_gpio
      BidirStd, // DIO i2c0_sda
      BidirStd, // DIO i2c0_scl
      BidirStd, // DIO spi_device_sd
      BidirStd, // DIO spi_device_sd
      BidirStd, // DIO spi_device_sd
      BidirStd, // DIO spi_device_sd
      BidirStd, // DIO spi_host0_sd
      BidirStd, // DIO spi_host0_sd
      BidirStd, // DIO spi_host0_sd
      BidirStd  // DIO spi_host0_sd
    },
    mio_pad_type: {
      BidirStd, // MIO Pad 11
      BidirStd, // MIO Pad 10
      BidirStd, // MIO Pad 9
      BidirStd, // MIO Pad 8
      BidirStd, // MIO Pad 7
      BidirStd, // MIO Pad 6
      BidirStd, // MIO Pad 5
      BidirStd, // MIO Pad 4
      BidirStd, // MIO Pad 3
      BidirStd, // MIO Pad 2
      BidirStd, // MIO Pad 1
      BidirStd  // MIO Pad 0
    },
    // Pad scan roles
    dio_scan_role: {
      scan_role_pkg::DioPadSocGpo11ScanRole, // DIO soc_proxy_soc_gpo
      scan_role_pkg::DioPadSocGpo10ScanRole, // DIO soc_proxy_soc_gpo
      scan_role_pkg::DioPadSocGpo9ScanRole, // DIO soc_proxy_soc_gpo
      scan_role_pkg::DioPadSocGpo8ScanRole, // DIO soc_proxy_soc_gpo
      scan_role_pkg::DioPadSocGpo7ScanRole, // DIO soc_proxy_soc_gpo
      scan_role_pkg::DioPadSocGpo6ScanRole, // DIO soc_proxy_soc_gpo
      scan_role_pkg::DioPadSocGpo5ScanRole, // DIO soc_proxy_soc_gpo
      scan_role_pkg::DioPadSocGpo4ScanRole, // DIO soc_proxy_soc_gpo
      scan_role_pkg::DioPadSocGpo3ScanRole, // DIO soc_proxy_soc_gpo
      scan_role_pkg::DioPadSocGpo2ScanRole, // DIO soc_proxy_soc_gpo
      scan_role_pkg::DioPadSocGpo1ScanRole, // DIO soc_proxy_soc_gpo
      scan_role_pkg::DioPadSocGpo0ScanRole, // DIO soc_proxy_soc_gpo
      scan_role_pkg::DioPadUartTxScanRole, // DIO uart0_tx
      scan_role_pkg::DioPadSpiHostCsLScanRole, // DIO spi_host0_csb
      scan_role_pkg::DioPadSpiHostClkScanRole, // DIO spi_host0_sck
      scan_role_pkg::DioPadSocGpi11ScanRole, // DIO soc_proxy_soc_gpi
      scan_role_pkg::DioPadSocGpi10ScanRole, // DIO soc_proxy_soc_gpi
      scan_role_pkg::DioPadSocGpi9ScanRole, // DIO soc_proxy_soc_gpi
      scan_role_pkg::DioPadSocGpi8ScanRole, // DIO soc_proxy_soc_gpi
      scan_role_pkg::DioPadSocGpi7ScanRole, // DIO soc_proxy_soc_gpi
      scan_role_pkg::DioPadSocGpi6ScanRole, // DIO soc_proxy_soc_gpi
      scan_role_pkg::DioPadSocGpi5ScanRole, // DIO soc_proxy_soc_gpi
      scan_role_pkg::DioPadSocGpi4ScanRole, // DIO soc_proxy_soc_gpi
      scan_role_pkg::DioPadSocGpi3ScanRole, // DIO soc_proxy_soc_gpi
      scan_role_pkg::DioPadSocGpi2ScanRole, // DIO soc_proxy_soc_gpi
      scan_role_pkg::DioPadSocGpi1ScanRole, // DIO soc_proxy_soc_gpi
      scan_role_pkg::DioPadSocGpi0ScanRole, // DIO soc_proxy_soc_gpi
      scan_role_pkg::DioPadUartRxScanRole, // DIO uart0_rx
      scan_role_pkg::DioPadSpiDevTpmCsLScanRole, // DIO spi_device_tpm_csb
      scan_role_pkg::DioPadSpiDevCsLScanRole, // DIO spi_device_csb
      scan_role_pkg::DioPadSpiDevClkScanRole, // DIO spi_device_sck
      scan_role_pkg::DioPadGpio31ScanRole, // DIO gpio_gpio
      scan_role_pkg::DioPadGpio30ScanRole, // DIO gpio_gpio
      scan_role_pkg::DioPadGpio29ScanRole, // DIO gpio_gpio
      scan_role_pkg::DioPadGpio28ScanRole, // DIO gpio_gpio
      scan_role_pkg::DioPadGpio27ScanRole, // DIO gpio_gpio
      scan_role_pkg::DioPadGpio26ScanRole, // DIO gpio_gpio
      scan_role_pkg::DioPadGpio25ScanRole, // DIO gpio_gpio
      scan_role_pkg::DioPadGpio24ScanRole, // DIO gpio_gpio
      scan_role_pkg::DioPadGpio23ScanRole, // DIO gpio_gpio
      scan_role_pkg::DioPadGpio22ScanRole, // DIO gpio_gpio
      scan_role_pkg::DioPadGpio21ScanRole, // DIO gpio_gpio
      scan_role_pkg::DioPadGpio20ScanRole, // DIO gpio_gpio
      scan_role_pkg::DioPadGpio19ScanRole, // DIO gpio_gpio
      scan_role_pkg::DioPadGpio18ScanRole, // DIO gpio_gpio
      scan_role_pkg::DioPadGpio17ScanRole, // DIO gpio_gpio
      scan_role_pkg::DioPadGpio16ScanRole, // DIO gpio_gpio
      scan_role_pkg::DioPadGpio15ScanRole, // DIO gpio_gpio
      scan_role_pkg::DioPadGpio14ScanRole, // DIO gpio_gpio
      scan_role_pkg::DioPadGpio13ScanRole, // DIO gpio_gpio
      scan_role_pkg::DioPadGpio12ScanRole, // DIO gpio_gpio
      scan_role_pkg::DioPadGpio11ScanRole, // DIO gpio_gpio
      scan_role_pkg::DioPadGpio10ScanRole, // DIO gpio_gpio
      scan_role_pkg::DioPadGpio9ScanRole, // DIO gpio_gpio
      scan_role_pkg::DioPadGpio8ScanRole, // DIO gpio_gpio
      scan_role_pkg::DioPadGpio7ScanRole, // DIO gpio_gpio
      scan_role_pkg::DioPadGpio6ScanRole, // DIO gpio_gpio
      scan_role_pkg::DioPadGpio5ScanRole, // DIO gpio_gpio
      scan_role_pkg::DioPadGpio4ScanRole, // DIO gpio_gpio
      scan_role_pkg::DioPadGpio3ScanRole, // DIO gpio_gpio
      scan_role_pkg::DioPadGpio2ScanRole, // DIO gpio_gpio
      scan_role_pkg::DioPadGpio1ScanRole, // DIO gpio_gpio
      scan_role_pkg::DioPadGpio0ScanRole, // DIO gpio_gpio
      scan_role_pkg::DioPadI2cSdaScanRole, // DIO i2c0_sda
      scan_role_pkg::DioPadI2cSclScanRole, // DIO i2c0_scl
      scan_role_pkg::DioPadSpiDevD3ScanRole, // DIO spi_device_sd
      scan_role_pkg::DioPadSpiDevD2ScanRole, // DIO spi_device_sd
      scan_role_pkg::DioPadSpiDevD1ScanRole, // DIO spi_device_sd
      scan_role_pkg::DioPadSpiDevD0ScanRole, // DIO spi_device_sd
      scan_role_pkg::DioPadSpiHostD3ScanRole, // DIO spi_host0_sd
      scan_role_pkg::DioPadSpiHostD2ScanRole, // DIO spi_host0_sd
      scan_role_pkg::DioPadSpiHostD1ScanRole, // DIO spi_host0_sd
      scan_role_pkg::DioPadSpiHostD0ScanRole // DIO spi_host0_sd
    },
    mio_scan_role: {
      scan_role_pkg::MioPadMio11ScanRole,
      scan_role_pkg::MioPadMio10ScanRole,
      scan_role_pkg::MioPadMio9ScanRole,
      scan_role_pkg::MioPadMio8ScanRole,
      scan_role_pkg::MioPadMio7ScanRole,
      scan_role_pkg::MioPadMio6ScanRole,
      scan_role_pkg::MioPadMio5ScanRole,
      scan_role_pkg::MioPadMio4ScanRole,
      scan_role_pkg::MioPadMio3ScanRole,
      scan_role_pkg::MioPadMio2ScanRole,
      scan_role_pkg::MioPadMio1ScanRole,
      scan_role_pkg::MioPadMio0ScanRole
    }
  };

  ////////////////////////
  // Signal definitions //
  ////////////////////////


  pad_attr_t [pinmux_reg_pkg::NMioPads-1:0] mio_attr;
  pad_attr_t [pinmux_reg_pkg::NDioPads-1:0] dio_attr;
  logic [pinmux_reg_pkg::NMioPads-1:0] mio_out;
  logic [pinmux_reg_pkg::NMioPads-1:0] mio_oe;
  logic [pinmux_reg_pkg::NMioPads-1:0] mio_in;
  logic [pinmux_reg_pkg::NMioPads-1:0] mio_in_raw;
  logic [80-1:0] dio_in_raw;
  logic [pinmux_reg_pkg::NDioPads-1:0] dio_out;
  logic [pinmux_reg_pkg::NDioPads-1:0] dio_oe;
  logic [pinmux_reg_pkg::NDioPads-1:0] dio_in;

  logic unused_mio_in_raw;
  logic unused_dio_in_raw;
  assign unused_mio_in_raw = ^mio_in_raw;
  assign unused_dio_in_raw = ^dio_in_raw;

  // Manual pads
  logic manual_in_por_n, manual_out_por_n, manual_oe_por_n;
  logic manual_in_jtag_tck, manual_out_jtag_tck, manual_oe_jtag_tck;
  logic manual_in_jtag_tms, manual_out_jtag_tms, manual_oe_jtag_tms;
  logic manual_in_jtag_tdi, manual_out_jtag_tdi, manual_oe_jtag_tdi;
  logic manual_in_jtag_tdo, manual_out_jtag_tdo, manual_oe_jtag_tdo;
  logic manual_in_jtag_trst_n, manual_out_jtag_trst_n, manual_oe_jtag_trst_n;
  logic manual_in_otp_ext_volt, manual_out_otp_ext_volt, manual_oe_otp_ext_volt;

  pad_attr_t manual_attr_por_n;
  pad_attr_t manual_attr_jtag_tck;
  pad_attr_t manual_attr_jtag_tms;
  pad_attr_t manual_attr_jtag_tdi;
  pad_attr_t manual_attr_jtag_tdo;
  pad_attr_t manual_attr_jtag_trst_n;
  pad_attr_t manual_attr_otp_ext_volt;


  //////////////////////
  // Padring Instance //
  //////////////////////

  // Padring substitute for the Verilator simulation top. The flat
  // per-peripheral `cio_*` pad signals live inside `u_padring` (see
  // padring_verilator.sv) and are driven and observed by the testbench DPI
  // models through hierarchical references.
  padring_verilator u_padring (
    .mio_in_o  (mio_in ),
    .mio_out_i (mio_out),
    .mio_oe_i  (mio_oe ),
    .mio_attr_i(mio_attr),

    .dio_in_o (dio_in ),
    .dio_out_i(dio_out),
    .dio_oe_i (dio_oe )
  );

  //////////////////////////////////
  // Manual Pad / Signal Tie-offs //
  //////////////////////////////////

  assign manual_out_por_n = 1'b0;
  assign manual_oe_por_n = 1'b0;

  assign manual_out_otp_ext_volt = 1'b0;
  assign manual_oe_otp_ext_volt = 1'b0;

  // These pad attributes currently tied off permanently (these are all input-only pads).
  assign manual_attr_por_n = '0;
  assign manual_attr_otp_ext_volt = '0;

  logic unused_manual_sigs;
  assign unused_manual_sigs = ^{
    manual_in_otp_ext_volt
  };

  ////////////////////////////////
  // JTAG Pad / Signal Tie-offs //
  ////////////////////////////////

  // The JTAG TAP lives inside top_darjeeling. The JTAG pad signals are
  // forwarded there and the TDO response is driven back onto the pad.
  assign manual_out_jtag_tck     = '0;
  assign manual_out_jtag_tms     = '0;
  assign manual_out_jtag_trst_n  = '0;
  assign manual_out_jtag_tdi     = '0;
  assign manual_oe_jtag_tck      = '0;
  assign manual_oe_jtag_tms      = '0;
  assign manual_oe_jtag_trst_n   = '0;
  assign manual_oe_jtag_tdi      = '0;
  assign manual_attr_jtag_tck    = '0;
  assign manual_attr_jtag_tms    = '0;
  assign manual_attr_jtag_trst_n = '0;
  assign manual_attr_jtag_tdi    = '0;
  assign manual_attr_jtag_tdo    = '0;

  logic unused_manual_jtag_sigs;
  assign unused_manual_jtag_sigs = ^{
    manual_in_jtag_tdo
  };

  /////////////////////////////////////////////
  // top_darjeeling: power domains + AST //
  /////////////////////////////////////////////
  top_darjeeling_verilator #(
    .SecRomCtrl0DisableScrambling(SecRomCtrl0DisableScrambling),
    .SecRomCtrl1DisableScrambling(SecRomCtrl1DisableScrambling),
    .PinmuxAonTargetCfg(PinmuxTargetCfg)
  ) top_darjeeling (
    // Clock and reset
    .clk_i,
    .rst_ni,

    // Multiplexed I/O to/from padring
    .mio_in_i  (mio_in  ),
    .mio_out_o (mio_out ),
    .mio_oe_o  (mio_oe  ),
    .dio_in_i  (dio_in  ),
    .dio_out_o (dio_out ),
    .dio_oe_o  (dio_oe  ),
    .mio_attr_o(mio_attr),
    .dio_attr_o(dio_attr),

    // JTAG interface
    .jtag_tck_i   (manual_in_jtag_tck   ),
    .jtag_tms_i   (manual_in_jtag_tms   ),
    .jtag_trst_n_i(manual_in_jtag_trst_n),
    .jtag_tdi_i   (manual_in_jtag_tdi   ),
    .jtag_tdo_o   (manual_out_jtag_tdo  ),
    .jtag_tdo_oe_o(manual_oe_jtag_tdo   )
  );

endmodule
