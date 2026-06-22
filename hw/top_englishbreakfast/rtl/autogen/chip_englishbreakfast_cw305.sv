// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// ------------------- W A R N I N G: A U T O - G E N E R A T E D   C O D E !! -------------------//
// PLEASE DO NOT HAND-EDIT THIS FILE. IT HAS BEEN AUTO-GENERATED WITH THE FOLLOWING COMMAND:
//
// util/topgen.py -t hw/top_englishbreakfast/data/top_englishbreakfast.hjson
//                -o hw/top_englishbreakfast/


module chip_englishbreakfast_cw305 #(
  // Path to a VMEM file containing the contents of the boot ROM, which will be
  // baked into the FPGA bitstream.
  parameter BootRomInitFile = ""
) (
  // Dedicated Pads
  inout POR_N, // Manual Pad
  inout USB_P, // Manual Pad
  inout USB_N, // Manual Pad
  inout SPI_DEV_D0, // Dedicated Pad for spi_device_sd
  inout SPI_DEV_D1, // Dedicated Pad for spi_device_sd
  inout SPI_DEV_CLK, // Dedicated Pad for spi_device_sck
  inout SPI_DEV_CS_L, // Dedicated Pad for spi_device_csb
  inout IO_CLK, // Manual Pad
  inout POR_BUTTON_N, // Manual Pad
  inout IO_USB_SENSE0, // Manual Pad
  inout IO_USB_DNPULLUP0, // Manual Pad
  inout IO_USB_DPPULLUP0, // Manual Pad
  inout IO_CLKOUT, // Manual Pad
  inout IO_TRIGGER, // Manual Pad

  // Muxed Pads
  inout IOA0, // MIO Pad 0
  inout IOA1, // MIO Pad 1
  inout IOA2, // MIO Pad 2
  inout IOA3, // MIO Pad 3
  inout IOA4, // MIO Pad 4
  inout IOA5, // MIO Pad 5
  inout IOA6, // MIO Pad 6
  inout IOA7, // MIO Pad 7
  inout IOA8, // MIO Pad 8
  inout IOB0, // MIO Pad 9
  inout IOB1, // MIO Pad 10
  inout IOB2, // MIO Pad 11
  inout IOB3, // MIO Pad 12
  inout IOB4, // MIO Pad 13
  inout IOB5, // MIO Pad 14
  inout IOB6, // MIO Pad 15
  inout IOC0, // MIO Pad 22
  inout IOC1, // MIO Pad 23
  inout IOC2, // MIO Pad 24
  inout IOC3, // MIO Pad 25
  inout IOC4, // MIO Pad 26
  inout IOC5, // MIO Pad 27
  inout IOC8, // MIO Pad 30
  inout IOR4  // MIO Pad 39
);

  import top_englishbreakfast_pkg::*;
  import prim_pad_wrapper_pkg::*;

  ////////////////////////////
  // Special Signal Indices //
  ////////////////////////////

  localparam int Tap0PadIdx = 30;
  localparam int Tap1PadIdx = 27;
  localparam int Dft0PadIdx = 40;
  localparam int Dft1PadIdx = 42;
  localparam int TckPadIdx = 57;
  localparam int TmsPadIdx = 58;
  localparam int TrstNPadIdx = 39;
  localparam int TdiPadIdx = 51;
  localparam int TdoPadIdx = 52;

  // DFT and Debug signal positions in the pinout.
  localparam pinmux_pkg::target_cfg_t PinmuxTargetCfg = '{
    tck_idx:           TckPadIdx,
    tms_idx:           TmsPadIdx,
    trst_idx:          TrstNPadIdx,
    tdi_idx:           TdiPadIdx,
    tdo_idx:           TdoPadIdx,
    tap_strap0_idx:    Tap0PadIdx,
    tap_strap1_idx:    Tap1PadIdx,
    dft_strap0_idx:    Dft0PadIdx,
    dft_strap1_idx:    Dft1PadIdx,
    // TODO: check whether there is a better way to pass these USB-specific params
    usb_dp_idx:        DioUsbdevUsbDp,
    usb_dn_idx:        DioUsbdevUsbDn,
    usb_sense_idx:     MioInUsbdevSense,
    // Pad types for attribute WARL behavior
    dio_pad_type: {
      BidirStd, // DIO spi_host0_csb
      BidirStd, // DIO spi_host0_sck
      InputStd, // DIO spi_device_csb
      InputStd, // DIO spi_device_sck
      BidirStd, // DIO usbdev_usb_dn
      BidirStd, // DIO usbdev_usb_dp
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
      BidirOd, // MIO Pad 46
      BidirOd, // MIO Pad 45
      BidirOd, // MIO Pad 44
      BidirOd, // MIO Pad 43
      BidirStd, // MIO Pad 42
      BidirStd, // MIO Pad 41
      BidirStd, // MIO Pad 40
      BidirStd, // MIO Pad 39
      BidirStd, // MIO Pad 38
      BidirStd, // MIO Pad 37
      BidirStd, // MIO Pad 36
      BidirStd, // MIO Pad 35
      BidirOd, // MIO Pad 34
      BidirOd, // MIO Pad 33
      BidirOd, // MIO Pad 32
      BidirStd, // MIO Pad 31
      BidirStd, // MIO Pad 30
      BidirStd, // MIO Pad 29
      BidirStd, // MIO Pad 28
      BidirStd, // MIO Pad 27
      BidirStd, // MIO Pad 26
      BidirStd, // MIO Pad 25
      BidirStd, // MIO Pad 24
      BidirStd, // MIO Pad 23
      BidirStd, // MIO Pad 22
      BidirOd, // MIO Pad 21
      BidirOd, // MIO Pad 20
      BidirOd, // MIO Pad 19
      BidirOd, // MIO Pad 18
      BidirStd, // MIO Pad 17
      BidirStd, // MIO Pad 16
      BidirStd, // MIO Pad 15
      BidirStd, // MIO Pad 14
      BidirStd, // MIO Pad 13
      BidirStd, // MIO Pad 12
      BidirStd, // MIO Pad 11
      BidirStd, // MIO Pad 10
      BidirStd, // MIO Pad 9
      BidirOd, // MIO Pad 8
      BidirOd, // MIO Pad 7
      BidirOd, // MIO Pad 6
      BidirStd, // MIO Pad 5
      BidirStd, // MIO Pad 4
      BidirStd, // MIO Pad 3
      BidirStd, // MIO Pad 2
      BidirStd, // MIO Pad 1
      BidirStd  // MIO Pad 0
    },
    // Pad scan roles
    dio_scan_role: {
      NoScan, // DIO spi_host0_csb
      NoScan, // DIO spi_host0_sck
      NoScan, // DIO spi_device_csb
      NoScan, // DIO spi_device_sck
      NoScan, // DIO usbdev_usb_dn
      NoScan, // DIO usbdev_usb_dp
      NoScan, // DIO spi_device_sd
      NoScan, // DIO spi_device_sd
      NoScan, // DIO spi_device_sd
      NoScan, // DIO spi_device_sd
      NoScan, // DIO spi_host0_sd
      NoScan, // DIO spi_host0_sd
      NoScan, // DIO spi_host0_sd
      NoScan // DIO spi_host0_sd
    },
    mio_scan_role: {
      NoScan,
      NoScan,
      NoScan,
      NoScan,
      NoScan,
      NoScan,
      NoScan,
      NoScan,
      NoScan,
      NoScan,
      NoScan,
      NoScan,
      NoScan,
      NoScan,
      NoScan,
      NoScan,
      NoScan,
      NoScan,
      NoScan,
      NoScan,
      NoScan,
      NoScan,
      NoScan,
      NoScan,
      NoScan,
      NoScan,
      NoScan,
      NoScan,
      NoScan,
      NoScan,
      NoScan,
      NoScan,
      NoScan,
      NoScan,
      NoScan,
      NoScan,
      NoScan,
      NoScan,
      NoScan,
      NoScan,
      NoScan,
      NoScan,
      NoScan,
      NoScan,
      NoScan,
      NoScan,
      NoScan
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
  logic [pinmux_reg_pkg::NDioPads-1:0] dio_out;
  logic [pinmux_reg_pkg::NDioPads-1:0] dio_oe;
  logic [pinmux_reg_pkg::NDioPads-1:0] dio_in;

  logic                          [3:0] mux_iob_sel;
  logic [pinmux_reg_pkg::NMioPads-1:0] mio_in_raw;
  logic                         [13:0] dio_in_raw;

  logic unused_mio_in_raw;
  logic unused_dio_in_raw;
  assign unused_mio_in_raw = ^mio_in_raw;
  assign unused_dio_in_raw = ^dio_in_raw;

  // Manual pads
  logic manual_in_por_n, manual_out_por_n, manual_oe_por_n;
  logic manual_in_usb_p, manual_out_usb_p, manual_oe_usb_p;
  logic manual_in_usb_n, manual_out_usb_n, manual_oe_usb_n;
  logic manual_in_io_clk, manual_out_io_clk, manual_oe_io_clk;
  logic manual_in_por_button_n, manual_out_por_button_n, manual_oe_por_button_n;
  logic manual_in_io_usb_sense0, manual_out_io_usb_sense0, manual_oe_io_usb_sense0;
  logic manual_in_io_usb_dnpullup0, manual_out_io_usb_dnpullup0, manual_oe_io_usb_dnpullup0;
  logic manual_in_io_usb_dppullup0, manual_out_io_usb_dppullup0, manual_oe_io_usb_dppullup0;
  logic manual_in_io_clkout, manual_out_io_clkout, manual_oe_io_clkout;
  logic manual_in_io_trigger, manual_out_io_trigger, manual_oe_io_trigger;

  pad_attr_t manual_attr_por_n;
  pad_attr_t manual_attr_usb_p;
  pad_attr_t manual_attr_usb_n;
  pad_attr_t manual_attr_io_clk;
  pad_attr_t manual_attr_por_button_n;
  pad_attr_t manual_attr_io_usb_sense0;
  pad_attr_t manual_attr_io_usb_dnpullup0;
  pad_attr_t manual_attr_io_usb_dppullup0;
  pad_attr_t manual_attr_io_clkout;
  pad_attr_t manual_attr_io_trigger;

  /////////////////////////
  // Stubbed pad tie-off //
  /////////////////////////

  // Only signals going to non-custom pads need to be tied off.
  logic [66:0] unused_sig;
  assign dio_in[DioSpiHost0Sd0] = 1'b0;
  assign unused_sig[8] = dio_out[DioSpiHost0Sd0] ^ dio_oe[DioSpiHost0Sd0];
  assign dio_in[DioSpiHost0Sd1] = 1'b0;
  assign unused_sig[9] = dio_out[DioSpiHost0Sd1] ^ dio_oe[DioSpiHost0Sd1];
  assign dio_in[DioSpiHost0Sd2] = 1'b0;
  assign unused_sig[10] = dio_out[DioSpiHost0Sd2] ^ dio_oe[DioSpiHost0Sd2];
  assign dio_in[DioSpiHost0Sd3] = 1'b0;
  assign unused_sig[11] = dio_out[DioSpiHost0Sd3] ^ dio_oe[DioSpiHost0Sd3];
  assign dio_in[DioSpiHost0Sck] = 1'b0;
  assign unused_sig[12] = dio_out[DioSpiHost0Sck] ^ dio_oe[DioSpiHost0Sck];
  assign dio_in[DioSpiHost0Csb] = 1'b0;
  assign unused_sig[13] = dio_out[DioSpiHost0Csb] ^ dio_oe[DioSpiHost0Csb];
  assign dio_in[DioSpiDeviceSd2] = 1'b0;
  assign unused_sig[16] = dio_out[DioSpiDeviceSd2] ^ dio_oe[DioSpiDeviceSd2];
  assign dio_in[DioSpiDeviceSd3] = 1'b0;
  assign unused_sig[17] = dio_out[DioSpiDeviceSd3] ^ dio_oe[DioSpiDeviceSd3];
  assign mio_in[16] = 1'b0;
  assign mio_in_raw[16] = 1'b0;
  assign unused_sig[36] = mio_out[16] ^ mio_oe[16];
  assign mio_in[17] = 1'b0;
  assign mio_in_raw[17] = 1'b0;
  assign unused_sig[37] = mio_out[17] ^ mio_oe[17];
  assign mio_in[18] = 1'b0;
  assign mio_in_raw[18] = 1'b0;
  assign unused_sig[38] = mio_out[18] ^ mio_oe[18];
  assign mio_in[19] = 1'b0;
  assign mio_in_raw[19] = 1'b0;
  assign unused_sig[39] = mio_out[19] ^ mio_oe[19];
  assign mio_in[20] = 1'b0;
  assign mio_in_raw[20] = 1'b0;
  assign unused_sig[40] = mio_out[20] ^ mio_oe[20];
  assign mio_in[21] = 1'b0;
  assign mio_in_raw[21] = 1'b0;
  assign unused_sig[41] = mio_out[21] ^ mio_oe[21];
  assign mio_in[28] = 1'b0;
  assign mio_in_raw[28] = 1'b0;
  assign unused_sig[48] = mio_out[28] ^ mio_oe[28];
  assign mio_in[29] = 1'b0;
  assign mio_in_raw[29] = 1'b0;
  assign unused_sig[49] = mio_out[29] ^ mio_oe[29];
  assign mio_in[31] = 1'b0;
  assign mio_in_raw[31] = 1'b0;
  assign unused_sig[51] = mio_out[31] ^ mio_oe[31];
  assign mio_in[32] = 1'b0;
  assign mio_in_raw[32] = 1'b0;
  assign unused_sig[52] = mio_out[32] ^ mio_oe[32];
  assign mio_in[33] = 1'b0;
  assign mio_in_raw[33] = 1'b0;
  assign unused_sig[53] = mio_out[33] ^ mio_oe[33];
  assign mio_in[34] = 1'b0;
  assign mio_in_raw[34] = 1'b0;
  assign unused_sig[54] = mio_out[34] ^ mio_oe[34];
  assign mio_in[35] = 1'b0;
  assign mio_in_raw[35] = 1'b0;
  assign unused_sig[55] = mio_out[35] ^ mio_oe[35];
  assign mio_in[36] = 1'b0;
  assign mio_in_raw[36] = 1'b0;
  assign unused_sig[56] = mio_out[36] ^ mio_oe[36];
  assign mio_in[37] = 1'b0;
  assign mio_in_raw[37] = 1'b0;
  assign unused_sig[57] = mio_out[37] ^ mio_oe[37];
  assign mio_in[38] = 1'b0;
  assign mio_in_raw[38] = 1'b0;
  assign unused_sig[58] = mio_out[38] ^ mio_oe[38];
  assign mio_in[40] = 1'b0;
  assign mio_in_raw[40] = 1'b0;
  assign unused_sig[60] = mio_out[40] ^ mio_oe[40];
  assign mio_in[41] = 1'b0;
  assign mio_in_raw[41] = 1'b0;
  assign unused_sig[61] = mio_out[41] ^ mio_oe[41];
  assign mio_in[42] = 1'b0;
  assign mio_in_raw[42] = 1'b0;
  assign unused_sig[62] = mio_out[42] ^ mio_oe[42];
  assign mio_in[43] = 1'b0;
  assign mio_in_raw[43] = 1'b0;
  assign unused_sig[63] = mio_out[43] ^ mio_oe[43];
  assign mio_in[44] = 1'b0;
  assign mio_in_raw[44] = 1'b0;
  assign unused_sig[64] = mio_out[44] ^ mio_oe[44];
  assign mio_in[45] = 1'b0;
  assign mio_in_raw[45] = 1'b0;
  assign unused_sig[65] = mio_out[45] ^ mio_oe[45];
  assign mio_in[46] = 1'b0;
  assign mio_in_raw[46] = 1'b0;
  assign unused_sig[66] = mio_out[46] ^ mio_oe[46];
  //////////////////////
  // Padring Instance //
  //////////////////////

  // AST control signals needed in the padring, driven by top_englishbreakfast
  ast_pkg::ast_clks_t ast_base_clks;
  prim_mubi_pkg::mubi4_t scanmode;

  padring #(
    // Padring specific counts may differ from pinmux config due
    // to custom, stubbed or added pads.
    .NDioPads(14),
    .NMioPads(24),
    .DioPadType ({
      BidirStd, // IO_TRIGGER
      BidirStd, // IO_CLKOUT
      BidirStd, // IO_USB_DPPULLUP0
      BidirStd, // IO_USB_DNPULLUP0
      BidirStd, // IO_USB_SENSE0
      InputStd, // POR_BUTTON_N
      InputStd, // IO_CLK
      InputStd, // SPI_DEV_CS_L
      InputStd, // SPI_DEV_CLK
      BidirStd, // SPI_DEV_D1
      BidirStd, // SPI_DEV_D0
      BidirTol, // USB_N
      BidirTol, // USB_P
      InputStd  // POR_N
    }),
    .MioPadType ({
      BidirStd, // IOR4
      BidirStd, // IOC8
      BidirStd, // IOC5
      BidirStd, // IOC4
      BidirStd, // IOC3
      BidirStd, // IOC2
      BidirStd, // IOC1
      BidirStd, // IOC0
      BidirStd, // IOB6
      BidirStd, // IOB5
      BidirStd, // IOB4
      BidirStd, // IOB3
      BidirStd, // IOB2
      BidirStd, // IOB1
      BidirStd, // IOB0
      BidirOd, // IOA8
      BidirOd, // IOA7
      BidirOd, // IOA6
      BidirStd, // IOA5
      BidirStd, // IOA4
      BidirStd, // IOA3
      BidirStd, // IOA2
      BidirStd, // IOA1
      BidirStd  // IOA0
    })
  ) u_padring (
    // This is only used for scan and DFT purposes
    .clk_scan_i(ast_base_clks.clk_sys),
    .scanmode_i(scanmode),

    .mux_iob_sel_i(mux_iob_sel),
    .dio_in_raw_o (dio_in_raw ),

    // Chip IOs
    .dio_pad_io ({
      IO_TRIGGER,
      IO_CLKOUT,
      IO_USB_DPPULLUP0,
      IO_USB_DNPULLUP0,
      IO_USB_SENSE0,
      POR_BUTTON_N,
      IO_CLK,
      SPI_DEV_CS_L,
      SPI_DEV_CLK,
      SPI_DEV_D1,
      SPI_DEV_D0,
      USB_N,
      USB_P,
      POR_N
    }),

    .mio_pad_io ({
      IOR4,
      IOC8,
      IOC5,
      IOC4,
      IOC3,
      IOC2,
      IOC1,
      IOC0,
      IOB6,
      IOB5,
      IOB4,
      IOB3,
      IOB2,
      IOB1,
      IOB0,
      IOA8,
      IOA7,
      IOA6,
      IOA5,
      IOA4,
      IOA3,
      IOA2,
      IOA1,
      IOA0
    }),

    // Core-facing
    .dio_in_o ({
        manual_in_io_trigger,
        manual_in_io_clkout,
        manual_in_io_usb_dppullup0,
        manual_in_io_usb_dnpullup0,
        manual_in_io_usb_sense0,
        manual_in_por_button_n,
        manual_in_io_clk,
        dio_in[DioSpiDeviceCsb],
        dio_in[DioSpiDeviceSck],
        dio_in[DioSpiDeviceSd1],
        dio_in[DioSpiDeviceSd0],
        manual_in_usb_n,
        manual_in_usb_p,
        manual_in_por_n
      }),
    .dio_out_i ({
        manual_out_io_trigger,
        manual_out_io_clkout,
        manual_out_io_usb_dppullup0,
        manual_out_io_usb_dnpullup0,
        manual_out_io_usb_sense0,
        manual_out_por_button_n,
        manual_out_io_clk,
        dio_out[DioSpiDeviceCsb],
        dio_out[DioSpiDeviceSck],
        dio_out[DioSpiDeviceSd1],
        dio_out[DioSpiDeviceSd0],
        manual_out_usb_n,
        manual_out_usb_p,
        manual_out_por_n
      }),
    .dio_oe_i ({
        manual_oe_io_trigger,
        manual_oe_io_clkout,
        manual_oe_io_usb_dppullup0,
        manual_oe_io_usb_dnpullup0,
        manual_oe_io_usb_sense0,
        manual_oe_por_button_n,
        manual_oe_io_clk,
        dio_oe[DioSpiDeviceCsb],
        dio_oe[DioSpiDeviceSck],
        dio_oe[DioSpiDeviceSd1],
        dio_oe[DioSpiDeviceSd0],
        manual_oe_usb_n,
        manual_oe_usb_p,
        manual_oe_por_n
      }),
    .dio_attr_i ({
        manual_attr_io_trigger,
        manual_attr_io_clkout,
        manual_attr_io_usb_dppullup0,
        manual_attr_io_usb_dnpullup0,
        manual_attr_io_usb_sense0,
        manual_attr_por_button_n,
        manual_attr_io_clk,
        dio_attr[DioSpiDeviceCsb],
        dio_attr[DioSpiDeviceSck],
        dio_attr[DioSpiDeviceSd1],
        dio_attr[DioSpiDeviceSd0],
        manual_attr_usb_n,
        manual_attr_usb_p,
        manual_attr_por_n
      }),

    .mio_in_o ({
        mio_in[39],
        mio_in[30],
        mio_in[27:22],
        mio_in[15:0]
      }),
    .mio_out_i ({
        mio_out[39],
        mio_out[30],
        mio_out[27:22],
        mio_out[15:0]
      }),
    .mio_oe_i ({
        mio_oe[39],
        mio_oe[30],
        mio_oe[27:22],
        mio_oe[15:0]
      }),
    .mio_attr_i ({
        mio_attr[39],
        mio_attr[30],
        mio_attr[27:22],
        mio_attr[15:0]
      }),
    .mio_in_raw_o ({
        mio_in_raw[39],
        mio_in_raw[30],
        mio_in_raw[27:22],
        mio_in_raw[15:0]
      })
  );
  logic usb_dp_pullup_en;
  logic usb_dn_pullup_en;

  // Connect the DP pad
  assign dio_in[DioUsbdevUsbDp] = manual_in_usb_p;
  assign manual_out_usb_p = dio_out[DioUsbdevUsbDp];
  assign manual_oe_usb_p = dio_oe[DioUsbdevUsbDp];
  assign manual_attr_usb_p = dio_attr[DioUsbdevUsbDp];

  // Connect the DN pad
  assign dio_in[DioUsbdevUsbDn] = manual_in_usb_n;
  assign manual_out_usb_n = dio_out[DioUsbdevUsbDn];
  assign manual_oe_usb_n = dio_oe[DioUsbdevUsbDn];
  assign manual_attr_usb_n = dio_attr[DioUsbdevUsbDn];

  // Connect DN pullup
  assign manual_out_io_usb_dnpullup0 = usb_dn_pullup_en;
  assign manual_oe_io_usb_dnpullup0 = 1'b1;
  assign manual_attr_io_dnpullup0 = '0;

  // Connect DP pullup
  assign manual_out_io_usb_dppullup0 = usb_dp_pullup_en;
  assign manual_oe_io_usb_dppullup0 = 1'b1;
  assign manual_attr_io_dppullup0 = '0;


  //////////////////
  // PLL for FPGA //
  //////////////////

  assign manual_attr_io_clk = '0;
  assign manual_out_io_clk = 1'b0;
  assign manual_oe_io_clk = 1'b0;
  assign manual_attr_por_n = '0;
  assign manual_out_por_n = 1'b0;
  assign manual_oe_por_n = 1'b0;
  assign manual_attr_por_button_n = '0;
  assign manual_out_por_button_n = 1'b0;
  assign manual_oe_por_button_n = 1'b0;


  // TODO: follow-up later and hardwire all ast connects that do not
  //       exist for this target
  assign otp_obs_o = '0;


  /////////////////////////////////////////////
  // top_englishbreakfast: power domains + AST //
  /////////////////////////////////////////////
  top_englishbreakfast_cw305 #(
    .BootRomInitFile(BootRomInitFile),
    .OtpMacroMemInitFile(OtpMacroMemInitFile),
    .PinmuxAonTargetCfg(PinmuxTargetCfg)
  ) top_englishbreakfast (
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
    .mux_iob_sel_o  (mux_iob_sel  ),

    // USB connections to USB mux glue
    .usb_dp_pullup_en_o(usb_dp_pullup_en),
    .usb_dn_pullup_en_o(usb_dn_pullup_en),

    // POR and clock inputs feeding the FPGA clock generator
    .manual_in_por_n_i (manual_in_por_n ),
    .manual_in_io_clk_i(manual_in_io_clk),

    .manual_in_por_button_n_i(manual_in_por_button_n)

  );


  /////////////////////////////////////////////////////
  // ChipWhisperer CW310/305 Capture Board Interface //
  /////////////////////////////////////////////////////
  // This is used to interface OpenTitan as a target with a capture board trough the ChipWhisperer
  // 20-pin connector. This is used for SCA/FI experiments only.

  logic unused_inputs;
  assign unused_inputs = manual_in_io_clkout ^ manual_in_io_trigger;

  // Synchronous clock output to capture board.
  assign manual_out_io_clkout = manual_in_io_clk;
  assign manual_oe_io_clkout = 1'b1;

  // Capture trigger.
  // We use the clkmgr_aon_idle signal of the IP of interest to form a precise capture trigger.
  // GPIO[11:10] is used for selecting the IP of interest. The encoding is as follows (see
  // hint_names_e enum in clkmgr_pkg.sv for details).
  //
  // IP              - GPIO[11:10] - Index for clkmgr_aon_idle
  // -------------------------------------------------------------
  //  AES            -   00       -  0
  //  HMAC           -   01       -  1 - not implemented on CW305
  //  KMAC           -   10       -  2 - not implemented on CW305
  //  OTBN           -   11       -  3 - not implemented on CW305
  //
  // GPIO9 is used for gating the selected capture trigger in software. Alternatively, GPIO8
  // can be used to implement a less precise but fully software-controlled capture trigger
  // similar to what can be done on ASIC.
  //
  // Note that on the CW305, GPIO[9,8] are connected to LED[5(Green),7(Red)].

  prim_mubi_pkg::mubi4_t clk_trans_idle, manual_in_io_clk_idle;

  assign clk_trans_idle = top_englishbreakfast.englishbreakfast_pd_aon.u_clkmgr_aon.idle_i;

  logic clk_io_div4_trigger_hw_en, manual_in_io_clk_trigger_hw_en;
  logic clk_io_div4_trigger_hw_oe, manual_in_io_clk_trigger_hw_oe;
  logic clk_io_div4_trigger_sw_en, manual_in_io_clk_trigger_sw_en;
  logic clk_io_div4_trigger_sw_oe, manual_in_io_clk_trigger_sw_oe;
  assign clk_io_div4_trigger_hw_en = mio_out[MioOutGpioGpio9];
  assign clk_io_div4_trigger_hw_oe = mio_oe[MioOutGpioGpio9];
  assign clk_io_div4_trigger_sw_en = mio_out[MioOutGpioGpio8];
  assign clk_io_div4_trigger_sw_oe = mio_oe[MioOutGpioGpio8];

  // Synchronize signals to manual_in_io_clk.
  prim_flop_2sync #(
    .Width ($bits(clk_trans_idle) + 4)
  ) u_sync_trigger (
    .clk_i (manual_in_io_clk),
    .rst_ni(manual_in_por_n),
    .d_i   ({clk_trans_idle,
             clk_io_div4_trigger_hw_en,
             clk_io_div4_trigger_hw_oe,
             clk_io_div4_trigger_sw_en,
             clk_io_div4_trigger_sw_oe}),
    .q_o   ({manual_in_io_clk_idle,
             manual_in_io_clk_trigger_hw_en,
             manual_in_io_clk_trigger_hw_oe,
             manual_in_io_clk_trigger_sw_en,
             manual_in_io_clk_trigger_sw_oe})
  );

  // Generate the actual trigger signal as trigger_sw OR trigger_hw.
  assign manual_attr_io_trigger = '0;
  assign manual_oe_io_trigger  =
      manual_in_io_clk_trigger_sw_oe | manual_in_io_clk_trigger_hw_oe;
  assign manual_out_io_trigger =
      manual_in_io_clk_trigger_sw_en | (manual_in_io_clk_trigger_hw_en &
          prim_mubi_pkg::mubi4_test_false_strict(manual_in_io_clk_idle));
endmodule
