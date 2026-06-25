// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// ------------------- W A R N I N G: A U T O - G E N E R A T E D   C O D E !! -------------------//
// PLEASE DO NOT HAND-EDIT THIS FILE. IT HAS BEEN AUTO-GENERATED WITH THE FOLLOWING COMMAND:
//
// util/topgen.py -t hw/top_darjeeling/data/top_darjeeling.hjson
//                -o hw/top_darjeeling/


module chip_darjeeling_asic #(
  parameter bit SecRomCtrl0DisableScrambling = 1'b0,
  parameter bit SecRomCtrl1DisableScrambling = 1'b0
) (
  // Dedicated Pads
  inout POR_N, // Manual Pad
  inout JTAG_TCK, // Manual Pad
  inout JTAG_TMS, // Manual Pad
  inout JTAG_TDI, // Manual Pad
  inout JTAG_TDO, // Manual Pad
  inout JTAG_TRST_N, // Manual Pad
  inout OTP_EXT_VOLT, // Manual Pad
  inout SPI_HOST_D0, // Dedicated Pad for spi_host0_sd
  inout SPI_HOST_D1, // Dedicated Pad for spi_host0_sd
  inout SPI_HOST_D2, // Dedicated Pad for spi_host0_sd
  inout SPI_HOST_D3, // Dedicated Pad for spi_host0_sd
  inout SPI_HOST_CLK, // Dedicated Pad for spi_host0_sck
  inout SPI_HOST_CS_L, // Dedicated Pad for spi_host0_csb
  inout SPI_DEV_D0, // Dedicated Pad for spi_device_sd
  inout SPI_DEV_D1, // Dedicated Pad for spi_device_sd
  inout SPI_DEV_D2, // Dedicated Pad for spi_device_sd
  inout SPI_DEV_D3, // Dedicated Pad for spi_device_sd
  inout SPI_DEV_CLK, // Dedicated Pad for spi_device_sck
  inout SPI_DEV_CS_L, // Dedicated Pad for spi_device_csb
  inout SPI_DEV_TPM_CS_L, // Dedicated Pad for spi_device_tpm_csb
  inout UART_RX, // Dedicated Pad for uart0_rx
  inout UART_TX, // Dedicated Pad for uart0_tx
  inout I2C_SCL, // Dedicated Pad for i2c0_scl
  inout I2C_SDA, // Dedicated Pad for i2c0_sda
  inout GPIO0, // Dedicated Pad for gpio_gpio
  inout GPIO1, // Dedicated Pad for gpio_gpio
  inout GPIO2, // Dedicated Pad for gpio_gpio
  inout GPIO3, // Dedicated Pad for gpio_gpio
  inout GPIO4, // Dedicated Pad for gpio_gpio
  inout GPIO5, // Dedicated Pad for gpio_gpio
  inout GPIO6, // Dedicated Pad for gpio_gpio
  inout GPIO7, // Dedicated Pad for gpio_gpio
  inout GPIO8, // Dedicated Pad for gpio_gpio
  inout GPIO9, // Dedicated Pad for gpio_gpio
  inout GPIO10, // Dedicated Pad for gpio_gpio
  inout GPIO11, // Dedicated Pad for gpio_gpio
  inout GPIO12, // Dedicated Pad for gpio_gpio
  inout GPIO13, // Dedicated Pad for gpio_gpio
  inout GPIO14, // Dedicated Pad for gpio_gpio
  inout GPIO15, // Dedicated Pad for gpio_gpio
  inout GPIO16, // Dedicated Pad for gpio_gpio
  inout GPIO17, // Dedicated Pad for gpio_gpio
  inout GPIO18, // Dedicated Pad for gpio_gpio
  inout GPIO19, // Dedicated Pad for gpio_gpio
  inout GPIO20, // Dedicated Pad for gpio_gpio
  inout GPIO21, // Dedicated Pad for gpio_gpio
  inout GPIO22, // Dedicated Pad for gpio_gpio
  inout GPIO23, // Dedicated Pad for gpio_gpio
  inout GPIO24, // Dedicated Pad for gpio_gpio
  inout GPIO25, // Dedicated Pad for gpio_gpio
  inout GPIO26, // Dedicated Pad for gpio_gpio
  inout GPIO27, // Dedicated Pad for gpio_gpio
  inout GPIO28, // Dedicated Pad for gpio_gpio
  inout GPIO29, // Dedicated Pad for gpio_gpio
  inout GPIO30, // Dedicated Pad for gpio_gpio
  inout GPIO31, // Dedicated Pad for gpio_gpio
  inout SOC_GPI0, // Dedicated Pad for soc_proxy_soc_gpi
  inout SOC_GPI1, // Dedicated Pad for soc_proxy_soc_gpi
  inout SOC_GPI2, // Dedicated Pad for soc_proxy_soc_gpi
  inout SOC_GPI3, // Dedicated Pad for soc_proxy_soc_gpi
  inout SOC_GPI4, // Dedicated Pad for soc_proxy_soc_gpi
  inout SOC_GPI5, // Dedicated Pad for soc_proxy_soc_gpi
  inout SOC_GPI6, // Dedicated Pad for soc_proxy_soc_gpi
  inout SOC_GPI7, // Dedicated Pad for soc_proxy_soc_gpi
  inout SOC_GPI8, // Dedicated Pad for soc_proxy_soc_gpi
  inout SOC_GPI9, // Dedicated Pad for soc_proxy_soc_gpi
  inout SOC_GPI10, // Dedicated Pad for soc_proxy_soc_gpi
  inout SOC_GPI11, // Dedicated Pad for soc_proxy_soc_gpi
  inout SOC_GPO0, // Dedicated Pad for soc_proxy_soc_gpo
  inout SOC_GPO1, // Dedicated Pad for soc_proxy_soc_gpo
  inout SOC_GPO2, // Dedicated Pad for soc_proxy_soc_gpo
  inout SOC_GPO3, // Dedicated Pad for soc_proxy_soc_gpo
  inout SOC_GPO4, // Dedicated Pad for soc_proxy_soc_gpo
  inout SOC_GPO5, // Dedicated Pad for soc_proxy_soc_gpo
  inout SOC_GPO6, // Dedicated Pad for soc_proxy_soc_gpo
  inout SOC_GPO7, // Dedicated Pad for soc_proxy_soc_gpo
  inout SOC_GPO8, // Dedicated Pad for soc_proxy_soc_gpo
  inout SOC_GPO9, // Dedicated Pad for soc_proxy_soc_gpo
  inout SOC_GPO10, // Dedicated Pad for soc_proxy_soc_gpo
  inout SOC_GPO11, // Dedicated Pad for soc_proxy_soc_gpo

  // Muxed Pads
  inout MIO0, // MIO Pad 0
  inout MIO1, // MIO Pad 1
  inout MIO2, // MIO Pad 2
  inout MIO3, // MIO Pad 3
  inout MIO4, // MIO Pad 4
  inout MIO5, // MIO Pad 5
  inout MIO6, // MIO Pad 6
  inout MIO7, // MIO Pad 7
  inout MIO8, // MIO Pad 8
  inout MIO9, // MIO Pad 9
  inout MIO10, // MIO Pad 10
  inout MIO11  // MIO Pad 11
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

  // AST control signals needed in the padring, driven by top_darjeeling
  ast_pkg::ast_clks_t ast_base_clks;
  prim_mubi_pkg::mubi4_t scanmode;

  padring #(
    // Padring specific counts may differ from pinmux config due
    // to custom, stubbed or added pads.
    .NDioPads(80),
    .NMioPads(12),
    .PhysicalPads(1),
    .NIoBanks(int'(IoBankCount)),
    .DioScanRole ({
      scan_role_pkg::DioPadSocGpo11ScanRole,
      scan_role_pkg::DioPadSocGpo10ScanRole,
      scan_role_pkg::DioPadSocGpo9ScanRole,
      scan_role_pkg::DioPadSocGpo8ScanRole,
      scan_role_pkg::DioPadSocGpo7ScanRole,
      scan_role_pkg::DioPadSocGpo6ScanRole,
      scan_role_pkg::DioPadSocGpo5ScanRole,
      scan_role_pkg::DioPadSocGpo4ScanRole,
      scan_role_pkg::DioPadSocGpo3ScanRole,
      scan_role_pkg::DioPadSocGpo2ScanRole,
      scan_role_pkg::DioPadSocGpo1ScanRole,
      scan_role_pkg::DioPadSocGpo0ScanRole,
      scan_role_pkg::DioPadSocGpi11ScanRole,
      scan_role_pkg::DioPadSocGpi10ScanRole,
      scan_role_pkg::DioPadSocGpi9ScanRole,
      scan_role_pkg::DioPadSocGpi8ScanRole,
      scan_role_pkg::DioPadSocGpi7ScanRole,
      scan_role_pkg::DioPadSocGpi6ScanRole,
      scan_role_pkg::DioPadSocGpi5ScanRole,
      scan_role_pkg::DioPadSocGpi4ScanRole,
      scan_role_pkg::DioPadSocGpi3ScanRole,
      scan_role_pkg::DioPadSocGpi2ScanRole,
      scan_role_pkg::DioPadSocGpi1ScanRole,
      scan_role_pkg::DioPadSocGpi0ScanRole,
      scan_role_pkg::DioPadGpio31ScanRole,
      scan_role_pkg::DioPadGpio30ScanRole,
      scan_role_pkg::DioPadGpio29ScanRole,
      scan_role_pkg::DioPadGpio28ScanRole,
      scan_role_pkg::DioPadGpio27ScanRole,
      scan_role_pkg::DioPadGpio26ScanRole,
      scan_role_pkg::DioPadGpio25ScanRole,
      scan_role_pkg::DioPadGpio24ScanRole,
      scan_role_pkg::DioPadGpio23ScanRole,
      scan_role_pkg::DioPadGpio22ScanRole,
      scan_role_pkg::DioPadGpio21ScanRole,
      scan_role_pkg::DioPadGpio20ScanRole,
      scan_role_pkg::DioPadGpio19ScanRole,
      scan_role_pkg::DioPadGpio18ScanRole,
      scan_role_pkg::DioPadGpio17ScanRole,
      scan_role_pkg::DioPadGpio16ScanRole,
      scan_role_pkg::DioPadGpio15ScanRole,
      scan_role_pkg::DioPadGpio14ScanRole,
      scan_role_pkg::DioPadGpio13ScanRole,
      scan_role_pkg::DioPadGpio12ScanRole,
      scan_role_pkg::DioPadGpio11ScanRole,
      scan_role_pkg::DioPadGpio10ScanRole,
      scan_role_pkg::DioPadGpio9ScanRole,
      scan_role_pkg::DioPadGpio8ScanRole,
      scan_role_pkg::DioPadGpio7ScanRole,
      scan_role_pkg::DioPadGpio6ScanRole,
      scan_role_pkg::DioPadGpio5ScanRole,
      scan_role_pkg::DioPadGpio4ScanRole,
      scan_role_pkg::DioPadGpio3ScanRole,
      scan_role_pkg::DioPadGpio2ScanRole,
      scan_role_pkg::DioPadGpio1ScanRole,
      scan_role_pkg::DioPadGpio0ScanRole,
      scan_role_pkg::DioPadI2cSdaScanRole,
      scan_role_pkg::DioPadI2cSclScanRole,
      scan_role_pkg::DioPadUartTxScanRole,
      scan_role_pkg::DioPadUartRxScanRole,
      scan_role_pkg::DioPadSpiDevTpmCsLScanRole,
      scan_role_pkg::DioPadSpiDevCsLScanRole,
      scan_role_pkg::DioPadSpiDevClkScanRole,
      scan_role_pkg::DioPadSpiDevD3ScanRole,
      scan_role_pkg::DioPadSpiDevD2ScanRole,
      scan_role_pkg::DioPadSpiDevD1ScanRole,
      scan_role_pkg::DioPadSpiDevD0ScanRole,
      scan_role_pkg::DioPadSpiHostCsLScanRole,
      scan_role_pkg::DioPadSpiHostClkScanRole,
      scan_role_pkg::DioPadSpiHostD3ScanRole,
      scan_role_pkg::DioPadSpiHostD2ScanRole,
      scan_role_pkg::DioPadSpiHostD1ScanRole,
      scan_role_pkg::DioPadSpiHostD0ScanRole,
      scan_role_pkg::DioPadOtpExtVoltScanRole,
      scan_role_pkg::DioPadJtagTrstNScanRole,
      scan_role_pkg::DioPadJtagTdoScanRole,
      scan_role_pkg::DioPadJtagTdiScanRole,
      scan_role_pkg::DioPadJtagTmsScanRole,
      scan_role_pkg::DioPadJtagTckScanRole,
      scan_role_pkg::DioPadPorNScanRole
    }),
    .MioScanRole ({
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
    }),
    .DioPadOrient ({
      pad_orient_pkg::DioPadSocGpo11PadOrient,
      pad_orient_pkg::DioPadSocGpo10PadOrient,
      pad_orient_pkg::DioPadSocGpo9PadOrient,
      pad_orient_pkg::DioPadSocGpo8PadOrient,
      pad_orient_pkg::DioPadSocGpo7PadOrient,
      pad_orient_pkg::DioPadSocGpo6PadOrient,
      pad_orient_pkg::DioPadSocGpo5PadOrient,
      pad_orient_pkg::DioPadSocGpo4PadOrient,
      pad_orient_pkg::DioPadSocGpo3PadOrient,
      pad_orient_pkg::DioPadSocGpo2PadOrient,
      pad_orient_pkg::DioPadSocGpo1PadOrient,
      pad_orient_pkg::DioPadSocGpo0PadOrient,
      pad_orient_pkg::DioPadSocGpi11PadOrient,
      pad_orient_pkg::DioPadSocGpi10PadOrient,
      pad_orient_pkg::DioPadSocGpi9PadOrient,
      pad_orient_pkg::DioPadSocGpi8PadOrient,
      pad_orient_pkg::DioPadSocGpi7PadOrient,
      pad_orient_pkg::DioPadSocGpi6PadOrient,
      pad_orient_pkg::DioPadSocGpi5PadOrient,
      pad_orient_pkg::DioPadSocGpi4PadOrient,
      pad_orient_pkg::DioPadSocGpi3PadOrient,
      pad_orient_pkg::DioPadSocGpi2PadOrient,
      pad_orient_pkg::DioPadSocGpi1PadOrient,
      pad_orient_pkg::DioPadSocGpi0PadOrient,
      pad_orient_pkg::DioPadGpio31PadOrient,
      pad_orient_pkg::DioPadGpio30PadOrient,
      pad_orient_pkg::DioPadGpio29PadOrient,
      pad_orient_pkg::DioPadGpio28PadOrient,
      pad_orient_pkg::DioPadGpio27PadOrient,
      pad_orient_pkg::DioPadGpio26PadOrient,
      pad_orient_pkg::DioPadGpio25PadOrient,
      pad_orient_pkg::DioPadGpio24PadOrient,
      pad_orient_pkg::DioPadGpio23PadOrient,
      pad_orient_pkg::DioPadGpio22PadOrient,
      pad_orient_pkg::DioPadGpio21PadOrient,
      pad_orient_pkg::DioPadGpio20PadOrient,
      pad_orient_pkg::DioPadGpio19PadOrient,
      pad_orient_pkg::DioPadGpio18PadOrient,
      pad_orient_pkg::DioPadGpio17PadOrient,
      pad_orient_pkg::DioPadGpio16PadOrient,
      pad_orient_pkg::DioPadGpio15PadOrient,
      pad_orient_pkg::DioPadGpio14PadOrient,
      pad_orient_pkg::DioPadGpio13PadOrient,
      pad_orient_pkg::DioPadGpio12PadOrient,
      pad_orient_pkg::DioPadGpio11PadOrient,
      pad_orient_pkg::DioPadGpio10PadOrient,
      pad_orient_pkg::DioPadGpio9PadOrient,
      pad_orient_pkg::DioPadGpio8PadOrient,
      pad_orient_pkg::DioPadGpio7PadOrient,
      pad_orient_pkg::DioPadGpio6PadOrient,
      pad_orient_pkg::DioPadGpio5PadOrient,
      pad_orient_pkg::DioPadGpio4PadOrient,
      pad_orient_pkg::DioPadGpio3PadOrient,
      pad_orient_pkg::DioPadGpio2PadOrient,
      pad_orient_pkg::DioPadGpio1PadOrient,
      pad_orient_pkg::DioPadGpio0PadOrient,
      pad_orient_pkg::DioPadI2cSdaPadOrient,
      pad_orient_pkg::DioPadI2cSclPadOrient,
      pad_orient_pkg::DioPadUartTxPadOrient,
      pad_orient_pkg::DioPadUartRxPadOrient,
      pad_orient_pkg::DioPadSpiDevTpmCsLPadOrient,
      pad_orient_pkg::DioPadSpiDevCsLPadOrient,
      pad_orient_pkg::DioPadSpiDevClkPadOrient,
      pad_orient_pkg::DioPadSpiDevD3PadOrient,
      pad_orient_pkg::DioPadSpiDevD2PadOrient,
      pad_orient_pkg::DioPadSpiDevD1PadOrient,
      pad_orient_pkg::DioPadSpiDevD0PadOrient,
      pad_orient_pkg::DioPadSpiHostCsLPadOrient,
      pad_orient_pkg::DioPadSpiHostClkPadOrient,
      pad_orient_pkg::DioPadSpiHostD3PadOrient,
      pad_orient_pkg::DioPadSpiHostD2PadOrient,
      pad_orient_pkg::DioPadSpiHostD1PadOrient,
      pad_orient_pkg::DioPadSpiHostD0PadOrient,
      pad_orient_pkg::DioPadOtpExtVoltPadOrient,
      pad_orient_pkg::DioPadJtagTrstNPadOrient,
      pad_orient_pkg::DioPadJtagTdoPadOrient,
      pad_orient_pkg::DioPadJtagTdiPadOrient,
      pad_orient_pkg::DioPadJtagTmsPadOrient,
      pad_orient_pkg::DioPadJtagTckPadOrient,
      pad_orient_pkg::DioPadPorNPadOrient
    }),
    .MioPadOrient ({
      pad_orient_pkg::MioPadMio11PadOrient,
      pad_orient_pkg::MioPadMio10PadOrient,
      pad_orient_pkg::MioPadMio9PadOrient,
      pad_orient_pkg::MioPadMio8PadOrient,
      pad_orient_pkg::MioPadMio7PadOrient,
      pad_orient_pkg::MioPadMio6PadOrient,
      pad_orient_pkg::MioPadMio5PadOrient,
      pad_orient_pkg::MioPadMio4PadOrient,
      pad_orient_pkg::MioPadMio3PadOrient,
      pad_orient_pkg::MioPadMio2PadOrient,
      pad_orient_pkg::MioPadMio1PadOrient,
      pad_orient_pkg::MioPadMio0PadOrient
    }),
    .DioPadBank ({
      IoBankVio, // SOC_GPO11
      IoBankVio, // SOC_GPO10
      IoBankVio, // SOC_GPO9
      IoBankVio, // SOC_GPO8
      IoBankVio, // SOC_GPO7
      IoBankVio, // SOC_GPO6
      IoBankVio, // SOC_GPO5
      IoBankVio, // SOC_GPO4
      IoBankVio, // SOC_GPO3
      IoBankVio, // SOC_GPO2
      IoBankVio, // SOC_GPO1
      IoBankVio, // SOC_GPO0
      IoBankVio, // SOC_GPI11
      IoBankVio, // SOC_GPI10
      IoBankVio, // SOC_GPI9
      IoBankVio, // SOC_GPI8
      IoBankVio, // SOC_GPI7
      IoBankVio, // SOC_GPI6
      IoBankVio, // SOC_GPI5
      IoBankVio, // SOC_GPI4
      IoBankVio, // SOC_GPI3
      IoBankVio, // SOC_GPI2
      IoBankVio, // SOC_GPI1
      IoBankVio, // SOC_GPI0
      IoBankVio, // GPIO31
      IoBankVio, // GPIO30
      IoBankVio, // GPIO29
      IoBankVio, // GPIO28
      IoBankVio, // GPIO27
      IoBankVio, // GPIO26
      IoBankVio, // GPIO25
      IoBankVio, // GPIO24
      IoBankVio, // GPIO23
      IoBankVio, // GPIO22
      IoBankVio, // GPIO21
      IoBankVio, // GPIO20
      IoBankVio, // GPIO19
      IoBankVio, // GPIO18
      IoBankVio, // GPIO17
      IoBankVio, // GPIO16
      IoBankVio, // GPIO15
      IoBankVio, // GPIO14
      IoBankVio, // GPIO13
      IoBankVio, // GPIO12
      IoBankVio, // GPIO11
      IoBankVio, // GPIO10
      IoBankVio, // GPIO9
      IoBankVio, // GPIO8
      IoBankVio, // GPIO7
      IoBankVio, // GPIO6
      IoBankVio, // GPIO5
      IoBankVio, // GPIO4
      IoBankVio, // GPIO3
      IoBankVio, // GPIO2
      IoBankVio, // GPIO1
      IoBankVio, // GPIO0
      IoBankVio, // I2C_SDA
      IoBankVio, // I2C_SCL
      IoBankVio, // UART_TX
      IoBankVio, // UART_RX
      IoBankVio, // SPI_DEV_TPM_CS_L
      IoBankVio, // SPI_DEV_CS_L
      IoBankVio, // SPI_DEV_CLK
      IoBankVio, // SPI_DEV_D3
      IoBankVio, // SPI_DEV_D2
      IoBankVio, // SPI_DEV_D1
      IoBankVio, // SPI_DEV_D0
      IoBankVio, // SPI_HOST_CS_L
      IoBankVio, // SPI_HOST_CLK
      IoBankVio, // SPI_HOST_D3
      IoBankVio, // SPI_HOST_D2
      IoBankVio, // SPI_HOST_D1
      IoBankVio, // SPI_HOST_D0
      IoBankVio, // OTP_EXT_VOLT
      IoBankVio, // JTAG_TRST_N
      IoBankVio, // JTAG_TDO
      IoBankVio, // JTAG_TDI
      IoBankVio, // JTAG_TMS
      IoBankVio, // JTAG_TCK
      IoBankVio  // POR_N
    }),
    .MioPadBank ({
      IoBankVio, // MIO11
      IoBankVio, // MIO10
      IoBankVio, // MIO9
      IoBankVio, // MIO8
      IoBankVio, // MIO7
      IoBankVio, // MIO6
      IoBankVio, // MIO5
      IoBankVio, // MIO4
      IoBankVio, // MIO3
      IoBankVio, // MIO2
      IoBankVio, // MIO1
      IoBankVio  // MIO0
    }),
    .DioPadType ({
      BidirStd, // SOC_GPO11
      BidirStd, // SOC_GPO10
      BidirStd, // SOC_GPO9
      BidirStd, // SOC_GPO8
      BidirStd, // SOC_GPO7
      BidirStd, // SOC_GPO6
      BidirStd, // SOC_GPO5
      BidirStd, // SOC_GPO4
      BidirStd, // SOC_GPO3
      BidirStd, // SOC_GPO2
      BidirStd, // SOC_GPO1
      BidirStd, // SOC_GPO0
      InputStd, // SOC_GPI11
      InputStd, // SOC_GPI10
      InputStd, // SOC_GPI9
      InputStd, // SOC_GPI8
      InputStd, // SOC_GPI7
      InputStd, // SOC_GPI6
      InputStd, // SOC_GPI5
      InputStd, // SOC_GPI4
      InputStd, // SOC_GPI3
      InputStd, // SOC_GPI2
      InputStd, // SOC_GPI1
      InputStd, // SOC_GPI0
      BidirStd, // GPIO31
      BidirStd, // GPIO30
      BidirStd, // GPIO29
      BidirStd, // GPIO28
      BidirStd, // GPIO27
      BidirStd, // GPIO26
      BidirStd, // GPIO25
      BidirStd, // GPIO24
      BidirStd, // GPIO23
      BidirStd, // GPIO22
      BidirStd, // GPIO21
      BidirStd, // GPIO20
      BidirStd, // GPIO19
      BidirStd, // GPIO18
      BidirStd, // GPIO17
      BidirStd, // GPIO16
      BidirStd, // GPIO15
      BidirStd, // GPIO14
      BidirStd, // GPIO13
      BidirStd, // GPIO12
      BidirStd, // GPIO11
      BidirStd, // GPIO10
      BidirStd, // GPIO9
      BidirStd, // GPIO8
      BidirStd, // GPIO7
      BidirStd, // GPIO6
      BidirStd, // GPIO5
      BidirStd, // GPIO4
      BidirStd, // GPIO3
      BidirStd, // GPIO2
      BidirStd, // GPIO1
      BidirStd, // GPIO0
      BidirStd, // I2C_SDA
      BidirStd, // I2C_SCL
      BidirStd, // UART_TX
      InputStd, // UART_RX
      InputStd, // SPI_DEV_TPM_CS_L
      InputStd, // SPI_DEV_CS_L
      InputStd, // SPI_DEV_CLK
      BidirStd, // SPI_DEV_D3
      BidirStd, // SPI_DEV_D2
      BidirStd, // SPI_DEV_D1
      BidirStd, // SPI_DEV_D0
      BidirStd, // SPI_HOST_CS_L
      BidirStd, // SPI_HOST_CLK
      BidirStd, // SPI_HOST_D3
      BidirStd, // SPI_HOST_D2
      BidirStd, // SPI_HOST_D1
      BidirStd, // SPI_HOST_D0
      AnalogIn1, // OTP_EXT_VOLT
      InputStd, // JTAG_TRST_N
      BidirStd, // JTAG_TDO
      InputStd, // JTAG_TDI
      InputStd, // JTAG_TMS
      InputStd, // JTAG_TCK
      InputStd  // POR_N
    }),
    .MioPadType ({
      BidirStd, // MIO11
      BidirStd, // MIO10
      BidirStd, // MIO9
      BidirStd, // MIO8
      BidirStd, // MIO7
      BidirStd, // MIO6
      BidirStd, // MIO5
      BidirStd, // MIO4
      BidirStd, // MIO3
      BidirStd, // MIO2
      BidirStd, // MIO1
      BidirStd  // MIO0
    })
  ) u_padring (
  // This is only used for scan and DFT purposes
    .clk_scan_i   ( ast_base_clks.clk_sys ),
    .scanmode_i   ( scanmode              ),
    .dio_in_raw_o ( dio_in_raw ),
    // Chip IOs
    .dio_pad_io ({
      SOC_GPO11,
      SOC_GPO10,
      SOC_GPO9,
      SOC_GPO8,
      SOC_GPO7,
      SOC_GPO6,
      SOC_GPO5,
      SOC_GPO4,
      SOC_GPO3,
      SOC_GPO2,
      SOC_GPO1,
      SOC_GPO0,
      SOC_GPI11,
      SOC_GPI10,
      SOC_GPI9,
      SOC_GPI8,
      SOC_GPI7,
      SOC_GPI6,
      SOC_GPI5,
      SOC_GPI4,
      SOC_GPI3,
      SOC_GPI2,
      SOC_GPI1,
      SOC_GPI0,
      GPIO31,
      GPIO30,
      GPIO29,
      GPIO28,
      GPIO27,
      GPIO26,
      GPIO25,
      GPIO24,
      GPIO23,
      GPIO22,
      GPIO21,
      GPIO20,
      GPIO19,
      GPIO18,
      GPIO17,
      GPIO16,
      GPIO15,
      GPIO14,
      GPIO13,
      GPIO12,
      GPIO11,
      GPIO10,
      GPIO9,
      GPIO8,
      GPIO7,
      GPIO6,
      GPIO5,
      GPIO4,
      GPIO3,
      GPIO2,
      GPIO1,
      GPIO0,
      I2C_SDA,
      I2C_SCL,
      UART_TX,
      UART_RX,
      SPI_DEV_TPM_CS_L,
      SPI_DEV_CS_L,
      SPI_DEV_CLK,
      SPI_DEV_D3,
      SPI_DEV_D2,
      SPI_DEV_D1,
      SPI_DEV_D0,
      SPI_HOST_CS_L,
      SPI_HOST_CLK,
      SPI_HOST_D3,
      SPI_HOST_D2,
      SPI_HOST_D1,
      SPI_HOST_D0,
      OTP_EXT_VOLT,
      JTAG_TRST_N,
      JTAG_TDO,
      JTAG_TDI,
      JTAG_TMS,
      JTAG_TCK,
      POR_N
    }),

    .mio_pad_io ({
      MIO11,
      MIO10,
      MIO9,
      MIO8,
      MIO7,
      MIO6,
      MIO5,
      MIO4,
      MIO3,
      MIO2,
      MIO1,
      MIO0
    }),

    // Core-facing
    .dio_in_o ({
        dio_in[DioSocProxySocGpo11],
        dio_in[DioSocProxySocGpo10],
        dio_in[DioSocProxySocGpo9],
        dio_in[DioSocProxySocGpo8],
        dio_in[DioSocProxySocGpo7],
        dio_in[DioSocProxySocGpo6],
        dio_in[DioSocProxySocGpo5],
        dio_in[DioSocProxySocGpo4],
        dio_in[DioSocProxySocGpo3],
        dio_in[DioSocProxySocGpo2],
        dio_in[DioSocProxySocGpo1],
        dio_in[DioSocProxySocGpo0],
        dio_in[DioSocProxySocGpi11],
        dio_in[DioSocProxySocGpi10],
        dio_in[DioSocProxySocGpi9],
        dio_in[DioSocProxySocGpi8],
        dio_in[DioSocProxySocGpi7],
        dio_in[DioSocProxySocGpi6],
        dio_in[DioSocProxySocGpi5],
        dio_in[DioSocProxySocGpi4],
        dio_in[DioSocProxySocGpi3],
        dio_in[DioSocProxySocGpi2],
        dio_in[DioSocProxySocGpi1],
        dio_in[DioSocProxySocGpi0],
        dio_in[DioGpioGpio31],
        dio_in[DioGpioGpio30],
        dio_in[DioGpioGpio29],
        dio_in[DioGpioGpio28],
        dio_in[DioGpioGpio27],
        dio_in[DioGpioGpio26],
        dio_in[DioGpioGpio25],
        dio_in[DioGpioGpio24],
        dio_in[DioGpioGpio23],
        dio_in[DioGpioGpio22],
        dio_in[DioGpioGpio21],
        dio_in[DioGpioGpio20],
        dio_in[DioGpioGpio19],
        dio_in[DioGpioGpio18],
        dio_in[DioGpioGpio17],
        dio_in[DioGpioGpio16],
        dio_in[DioGpioGpio15],
        dio_in[DioGpioGpio14],
        dio_in[DioGpioGpio13],
        dio_in[DioGpioGpio12],
        dio_in[DioGpioGpio11],
        dio_in[DioGpioGpio10],
        dio_in[DioGpioGpio9],
        dio_in[DioGpioGpio8],
        dio_in[DioGpioGpio7],
        dio_in[DioGpioGpio6],
        dio_in[DioGpioGpio5],
        dio_in[DioGpioGpio4],
        dio_in[DioGpioGpio3],
        dio_in[DioGpioGpio2],
        dio_in[DioGpioGpio1],
        dio_in[DioGpioGpio0],
        dio_in[DioI2c0Sda],
        dio_in[DioI2c0Scl],
        dio_in[DioUart0Tx],
        dio_in[DioUart0Rx],
        dio_in[DioSpiDeviceTpmCsb],
        dio_in[DioSpiDeviceCsb],
        dio_in[DioSpiDeviceSck],
        dio_in[DioSpiDeviceSd3],
        dio_in[DioSpiDeviceSd2],
        dio_in[DioSpiDeviceSd1],
        dio_in[DioSpiDeviceSd0],
        dio_in[DioSpiHost0Csb],
        dio_in[DioSpiHost0Sck],
        dio_in[DioSpiHost0Sd3],
        dio_in[DioSpiHost0Sd2],
        dio_in[DioSpiHost0Sd1],
        dio_in[DioSpiHost0Sd0],
        manual_in_otp_ext_volt,
        manual_in_jtag_trst_n,
        manual_in_jtag_tdo,
        manual_in_jtag_tdi,
        manual_in_jtag_tms,
        manual_in_jtag_tck,
        manual_in_por_n
      }),
    .dio_out_i ({
        dio_out[DioSocProxySocGpo11],
        dio_out[DioSocProxySocGpo10],
        dio_out[DioSocProxySocGpo9],
        dio_out[DioSocProxySocGpo8],
        dio_out[DioSocProxySocGpo7],
        dio_out[DioSocProxySocGpo6],
        dio_out[DioSocProxySocGpo5],
        dio_out[DioSocProxySocGpo4],
        dio_out[DioSocProxySocGpo3],
        dio_out[DioSocProxySocGpo2],
        dio_out[DioSocProxySocGpo1],
        dio_out[DioSocProxySocGpo0],
        dio_out[DioSocProxySocGpi11],
        dio_out[DioSocProxySocGpi10],
        dio_out[DioSocProxySocGpi9],
        dio_out[DioSocProxySocGpi8],
        dio_out[DioSocProxySocGpi7],
        dio_out[DioSocProxySocGpi6],
        dio_out[DioSocProxySocGpi5],
        dio_out[DioSocProxySocGpi4],
        dio_out[DioSocProxySocGpi3],
        dio_out[DioSocProxySocGpi2],
        dio_out[DioSocProxySocGpi1],
        dio_out[DioSocProxySocGpi0],
        dio_out[DioGpioGpio31],
        dio_out[DioGpioGpio30],
        dio_out[DioGpioGpio29],
        dio_out[DioGpioGpio28],
        dio_out[DioGpioGpio27],
        dio_out[DioGpioGpio26],
        dio_out[DioGpioGpio25],
        dio_out[DioGpioGpio24],
        dio_out[DioGpioGpio23],
        dio_out[DioGpioGpio22],
        dio_out[DioGpioGpio21],
        dio_out[DioGpioGpio20],
        dio_out[DioGpioGpio19],
        dio_out[DioGpioGpio18],
        dio_out[DioGpioGpio17],
        dio_out[DioGpioGpio16],
        dio_out[DioGpioGpio15],
        dio_out[DioGpioGpio14],
        dio_out[DioGpioGpio13],
        dio_out[DioGpioGpio12],
        dio_out[DioGpioGpio11],
        dio_out[DioGpioGpio10],
        dio_out[DioGpioGpio9],
        dio_out[DioGpioGpio8],
        dio_out[DioGpioGpio7],
        dio_out[DioGpioGpio6],
        dio_out[DioGpioGpio5],
        dio_out[DioGpioGpio4],
        dio_out[DioGpioGpio3],
        dio_out[DioGpioGpio2],
        dio_out[DioGpioGpio1],
        dio_out[DioGpioGpio0],
        dio_out[DioI2c0Sda],
        dio_out[DioI2c0Scl],
        dio_out[DioUart0Tx],
        dio_out[DioUart0Rx],
        dio_out[DioSpiDeviceTpmCsb],
        dio_out[DioSpiDeviceCsb],
        dio_out[DioSpiDeviceSck],
        dio_out[DioSpiDeviceSd3],
        dio_out[DioSpiDeviceSd2],
        dio_out[DioSpiDeviceSd1],
        dio_out[DioSpiDeviceSd0],
        dio_out[DioSpiHost0Csb],
        dio_out[DioSpiHost0Sck],
        dio_out[DioSpiHost0Sd3],
        dio_out[DioSpiHost0Sd2],
        dio_out[DioSpiHost0Sd1],
        dio_out[DioSpiHost0Sd0],
        manual_out_otp_ext_volt,
        manual_out_jtag_trst_n,
        manual_out_jtag_tdo,
        manual_out_jtag_tdi,
        manual_out_jtag_tms,
        manual_out_jtag_tck,
        manual_out_por_n
      }),
    .dio_oe_i ({
        dio_oe[DioSocProxySocGpo11],
        dio_oe[DioSocProxySocGpo10],
        dio_oe[DioSocProxySocGpo9],
        dio_oe[DioSocProxySocGpo8],
        dio_oe[DioSocProxySocGpo7],
        dio_oe[DioSocProxySocGpo6],
        dio_oe[DioSocProxySocGpo5],
        dio_oe[DioSocProxySocGpo4],
        dio_oe[DioSocProxySocGpo3],
        dio_oe[DioSocProxySocGpo2],
        dio_oe[DioSocProxySocGpo1],
        dio_oe[DioSocProxySocGpo0],
        dio_oe[DioSocProxySocGpi11],
        dio_oe[DioSocProxySocGpi10],
        dio_oe[DioSocProxySocGpi9],
        dio_oe[DioSocProxySocGpi8],
        dio_oe[DioSocProxySocGpi7],
        dio_oe[DioSocProxySocGpi6],
        dio_oe[DioSocProxySocGpi5],
        dio_oe[DioSocProxySocGpi4],
        dio_oe[DioSocProxySocGpi3],
        dio_oe[DioSocProxySocGpi2],
        dio_oe[DioSocProxySocGpi1],
        dio_oe[DioSocProxySocGpi0],
        dio_oe[DioGpioGpio31],
        dio_oe[DioGpioGpio30],
        dio_oe[DioGpioGpio29],
        dio_oe[DioGpioGpio28],
        dio_oe[DioGpioGpio27],
        dio_oe[DioGpioGpio26],
        dio_oe[DioGpioGpio25],
        dio_oe[DioGpioGpio24],
        dio_oe[DioGpioGpio23],
        dio_oe[DioGpioGpio22],
        dio_oe[DioGpioGpio21],
        dio_oe[DioGpioGpio20],
        dio_oe[DioGpioGpio19],
        dio_oe[DioGpioGpio18],
        dio_oe[DioGpioGpio17],
        dio_oe[DioGpioGpio16],
        dio_oe[DioGpioGpio15],
        dio_oe[DioGpioGpio14],
        dio_oe[DioGpioGpio13],
        dio_oe[DioGpioGpio12],
        dio_oe[DioGpioGpio11],
        dio_oe[DioGpioGpio10],
        dio_oe[DioGpioGpio9],
        dio_oe[DioGpioGpio8],
        dio_oe[DioGpioGpio7],
        dio_oe[DioGpioGpio6],
        dio_oe[DioGpioGpio5],
        dio_oe[DioGpioGpio4],
        dio_oe[DioGpioGpio3],
        dio_oe[DioGpioGpio2],
        dio_oe[DioGpioGpio1],
        dio_oe[DioGpioGpio0],
        dio_oe[DioI2c0Sda],
        dio_oe[DioI2c0Scl],
        dio_oe[DioUart0Tx],
        dio_oe[DioUart0Rx],
        dio_oe[DioSpiDeviceTpmCsb],
        dio_oe[DioSpiDeviceCsb],
        dio_oe[DioSpiDeviceSck],
        dio_oe[DioSpiDeviceSd3],
        dio_oe[DioSpiDeviceSd2],
        dio_oe[DioSpiDeviceSd1],
        dio_oe[DioSpiDeviceSd0],
        dio_oe[DioSpiHost0Csb],
        dio_oe[DioSpiHost0Sck],
        dio_oe[DioSpiHost0Sd3],
        dio_oe[DioSpiHost0Sd2],
        dio_oe[DioSpiHost0Sd1],
        dio_oe[DioSpiHost0Sd0],
        manual_oe_otp_ext_volt,
        manual_oe_jtag_trst_n,
        manual_oe_jtag_tdo,
        manual_oe_jtag_tdi,
        manual_oe_jtag_tms,
        manual_oe_jtag_tck,
        manual_oe_por_n
      }),
    .dio_attr_i ({
        dio_attr[DioSocProxySocGpo11],
        dio_attr[DioSocProxySocGpo10],
        dio_attr[DioSocProxySocGpo9],
        dio_attr[DioSocProxySocGpo8],
        dio_attr[DioSocProxySocGpo7],
        dio_attr[DioSocProxySocGpo6],
        dio_attr[DioSocProxySocGpo5],
        dio_attr[DioSocProxySocGpo4],
        dio_attr[DioSocProxySocGpo3],
        dio_attr[DioSocProxySocGpo2],
        dio_attr[DioSocProxySocGpo1],
        dio_attr[DioSocProxySocGpo0],
        dio_attr[DioSocProxySocGpi11],
        dio_attr[DioSocProxySocGpi10],
        dio_attr[DioSocProxySocGpi9],
        dio_attr[DioSocProxySocGpi8],
        dio_attr[DioSocProxySocGpi7],
        dio_attr[DioSocProxySocGpi6],
        dio_attr[DioSocProxySocGpi5],
        dio_attr[DioSocProxySocGpi4],
        dio_attr[DioSocProxySocGpi3],
        dio_attr[DioSocProxySocGpi2],
        dio_attr[DioSocProxySocGpi1],
        dio_attr[DioSocProxySocGpi0],
        dio_attr[DioGpioGpio31],
        dio_attr[DioGpioGpio30],
        dio_attr[DioGpioGpio29],
        dio_attr[DioGpioGpio28],
        dio_attr[DioGpioGpio27],
        dio_attr[DioGpioGpio26],
        dio_attr[DioGpioGpio25],
        dio_attr[DioGpioGpio24],
        dio_attr[DioGpioGpio23],
        dio_attr[DioGpioGpio22],
        dio_attr[DioGpioGpio21],
        dio_attr[DioGpioGpio20],
        dio_attr[DioGpioGpio19],
        dio_attr[DioGpioGpio18],
        dio_attr[DioGpioGpio17],
        dio_attr[DioGpioGpio16],
        dio_attr[DioGpioGpio15],
        dio_attr[DioGpioGpio14],
        dio_attr[DioGpioGpio13],
        dio_attr[DioGpioGpio12],
        dio_attr[DioGpioGpio11],
        dio_attr[DioGpioGpio10],
        dio_attr[DioGpioGpio9],
        dio_attr[DioGpioGpio8],
        dio_attr[DioGpioGpio7],
        dio_attr[DioGpioGpio6],
        dio_attr[DioGpioGpio5],
        dio_attr[DioGpioGpio4],
        dio_attr[DioGpioGpio3],
        dio_attr[DioGpioGpio2],
        dio_attr[DioGpioGpio1],
        dio_attr[DioGpioGpio0],
        dio_attr[DioI2c0Sda],
        dio_attr[DioI2c0Scl],
        dio_attr[DioUart0Tx],
        dio_attr[DioUart0Rx],
        dio_attr[DioSpiDeviceTpmCsb],
        dio_attr[DioSpiDeviceCsb],
        dio_attr[DioSpiDeviceSck],
        dio_attr[DioSpiDeviceSd3],
        dio_attr[DioSpiDeviceSd2],
        dio_attr[DioSpiDeviceSd1],
        dio_attr[DioSpiDeviceSd0],
        dio_attr[DioSpiHost0Csb],
        dio_attr[DioSpiHost0Sck],
        dio_attr[DioSpiHost0Sd3],
        dio_attr[DioSpiHost0Sd2],
        dio_attr[DioSpiHost0Sd1],
        dio_attr[DioSpiHost0Sd0],
        manual_attr_otp_ext_volt,
        manual_attr_jtag_trst_n,
        manual_attr_jtag_tdo,
        manual_attr_jtag_tdi,
        manual_attr_jtag_tms,
        manual_attr_jtag_tck,
        manual_attr_por_n
      }),

    .mio_in_o (mio_in[11:0]),
    .mio_out_i (mio_out[11:0]),
    .mio_oe_i (mio_oe[11:0]),
    .mio_attr_i (mio_attr[11:0]),
    .mio_in_raw_o (mio_in_raw[11:0])
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
  top_darjeeling_asic #(
    .SecRomCtrl0DisableScrambling(SecRomCtrl0DisableScrambling),
    .SecRomCtrl1DisableScrambling(SecRomCtrl1DisableScrambling),
    .PinmuxAonTargetCfg(PinmuxTargetCfg)
  ) top_darjeeling (
    // Multiplexed I/O to/from padring
    .mio_in_i  (mio_in  ),
    .mio_out_o (mio_out ),
    .mio_oe_o  (mio_oe  ),
    .dio_in_i  (dio_in  ),
    .dio_out_o (dio_out ),
    .dio_oe_o  (dio_oe  ),
    .mio_attr_o(mio_attr),
    .dio_attr_o(dio_attr),

    // AST control signals consumed by the padring
    .ast_base_clks_o(ast_base_clks),
    .scanmode_o     (scanmode     ),

    // JTAG interface
    .jtag_tck_i   (manual_in_jtag_tck   ),
    .jtag_tms_i   (manual_in_jtag_tms   ),
    .jtag_trst_n_i(manual_in_jtag_trst_n),
    .jtag_tdi_i   (manual_in_jtag_tdi   ),
    .jtag_tdo_o   (manual_out_jtag_tdo  ),
    .jtag_tdo_oe_o(manual_oe_jtag_tdo   ),

    // External POR
    .manual_in_por_n_i(manual_in_por_n),

    // Direct connection to the chip pad
    .OTP_EXT_VOLT(OTP_EXT_VOLT)
  );

endmodule
