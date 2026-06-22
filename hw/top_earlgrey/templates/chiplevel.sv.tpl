// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
${gencmd}
<%
import re
import topgen.lib as lib
from reggen.params import Parameter

from copy import deepcopy

# Provide shortcuts for some commonly used variables
pinmux = top['pinmux']
pinout = top['pinout']

feature_info = {}
cio_info = {}

def get_dio_sig(pinmux: {}, pad: {}):
  '''Get DIO signal associated with this pad or return None'''
  for sig in pinmux["ios"]:
    if sig["connection"] == "direct" and pad["name"] == sig["pad"]:
      return sig
  else:
    return None

# Modify the pad lists on the fly, based on target config
maxwidth = 0
muxed_pads = []
dedicated_pads = []
k = 0
for pad in pinout["pads"]:
  if pad["connection"] == "muxed":
    if pad["name"] not in target["pinout"]["remove_pads"]:
      maxwidth = max(maxwidth, len(pad["name"]))
      muxed_pads.append(pad)
  else:
    k = pad["idx"]
    if pad["name"] not in target["pinout"]["remove_pads"]:
      maxwidth = max(maxwidth, len(pad["name"]))
      dedicated_pads.append(pad)

for pad in target["pinout"]["add_pads"]:
  # Since these additional pads have not been elaborated in the merge phase,
  # we need to add their global index here.
  amended_pad = deepcopy(pad)
  amended_pad.update({"idx" : k})
  dedicated_pads.append(pad)
  k += 1

# Bkdr loader targets
bkdr_loader_targets = ["cw340"]
gen_bkdr_loader = target["name"] in bkdr_loader_targets

removed_port_names = []
%>\
<%include file="/toplevel_snippets/info_dicts.tpl" args="top=top, feature_info=feature_info, cio_info=cio_info" />\

% if target["name"] == "verilator":
module chip_${top["name"]}_${target["name"]} (
  // Clock and Reset
  input clk_i,
  input rst_ni
);
% else:
%   if target["name"] != "asic":
%     if gen_bkdr_loader:
`include "bkdr_loader.svh"

%     endif
module chip_${top["name"]}_${target["name"]} #(
%     if top["name"] == "englishbreakfast":
  // Path to a VMEM file containing the contents of the boot ROM, which will be
  // baked into the FPGA bitstream.
  parameter BootRomInitFile = ""
%     else:
%       if gen_bkdr_loader:
  parameter bit BkdrLoaderEn = 1'b1,
%       endif
  // Path to a VMEM file containing the contents of the boot ROM, which will be
  // baked into the FPGA bitstream.
  parameter BootRomInitFile = "test_rom_fpga_${target["name"]}.32.vmem",
  // Path to a VMEM file containing the contents of the emulated OTP, which will be
  // baked into the FPGA bitstream.
  parameter OtpMacroMemInitFile = "otp_img_fpga_${target["name"]}.vmem"
%     endif
) (
%   else:
module chip_${top["name"]}_${target["name"]} #(
  parameter bit SecRomCtrlDisableScrambling = 1'b0
) (
%   endif
  // Dedicated Pads
% for pad in dedicated_pads:
<%
  sig = get_dio_sig(pinmux, pad)
  if pad["name"] in target["pinout"]["remove_ports"]:
    port_comment = "// Removed port: "
    removed_port_names.append(pad["name"])
  else:
    port_comment = ""
  if sig is not None:
    comment = "// Dedicated Pad for {}".format(sig["name"])
  else:
    comment = "// Manual Pad"
%>\
  ${port_comment}${pad["port_type"]} ${pad["name"]}, ${comment}
% endfor

  // Muxed Pads
% for pad in muxed_pads:
<%
  if pad["name"] in target["pinout"]["remove_ports"]:
    port_comment = "// Removed port: "
    removed_port_names.append(pad["name"])
  else:
    port_comment = ""
%>\
  ${port_comment}${pad["port_type"]} ${pad["name"]}${" " if loop.last else ","} // MIO Pad ${pad["idx"]}
% endfor
);
% endif

  import top_${top["name"]}_pkg::*;
  import prim_pad_wrapper_pkg::*;

% if target["pinmux"]["special_signals"]:
  ////////////////////////////
  // Special Signal Indices //
  ////////////////////////////

  % for entry in target["pinmux"]["special_signals"]:
<% param_name = (lib.Name.from_snake_case(entry["name"]) +
                 lib.Name(["pad", "idx"])).as_camel_case()
%>\
  localparam int ${param_name} = ${entry["idx"]};
  % endfor
% endif

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
<%
  pad_attr = []
  for sig in list(reversed(top["pinmux"]["ios"])):
    if sig["connection"] != "muxed":
      pad_attr.append((sig['name'], sig["attr"]))
%>\
% for name, attr in pad_attr:
      ${attr}${" " if loop.last else ","} // DIO ${name}
% endfor
    },
    mio_pad_type: {
<%
  pad_attr = []
  for pad in list(reversed(pinout["pads"])):
    if pad["connection"] == "muxed":
      pad_attr.append(pad["type"])
%>\
% for attr in pad_attr:
      ${attr}${" " if loop.last else ","} // MIO Pad ${len(pad_attr) - loop.index - 1}
% endfor
    },
    // Pad scan roles
    dio_scan_role: {
<%
  scan_roles = []
  for sig in list(reversed(top["pinmux"]["ios"])):
    if sig["connection"] != "muxed":
      if (len(sig['pad']) > 0) and (target["name"] != "cw305"):
        scan_string = lib.Name.from_snake_case('dio_pad_' + sig['pad'] + '_scan_role')
        scan_roles.append((f'scan_role_pkg::{scan_string.as_camel_case()}', sig['name']))
      else:
        scan_roles.append(('NoScan', sig['name']))
%>\
% for scan_role, name in list(scan_roles):
      ${scan_role}${"" if loop.last else ","} // DIO ${name}
% endfor
    },
    mio_scan_role: {
<%
  scan_roles = []
  for pad in list(reversed(pinout["pads"])):
    if pad["connection"] == "muxed":
      if target["name"] != "cw305":
        scan_string = lib.Name.from_snake_case('mio_pad_' + pad['name'] + '_scan_role')
        scan_roles.append(f'scan_role_pkg::{scan_string.as_camel_case()}')
      else:
        scan_roles.append('NoScan')
%>\
% for scan_role in list(scan_roles):
      ${scan_role}${"" if loop.last else ","}
% endfor
    }
  };

  ////////////////////////
  // Signal definitions //
  ////////////////////////

  % if removed_port_names:
  // Net definitions for removed ports
  % endif
  % for port in removed_port_names:
  wire ${port};
  % endfor

  pad_attr_t [pinmux_reg_pkg::NMioPads-1:0] mio_attr;
  pad_attr_t [pinmux_reg_pkg::NDioPads-1:0] dio_attr;

  logic [pinmux_reg_pkg::NMioPads-1:0] mio_out;
  logic [pinmux_reg_pkg::NMioPads-1:0] mio_oe;
  logic [pinmux_reg_pkg::NMioPads-1:0] mio_in;
  logic [pinmux_reg_pkg::NDioPads-1:0] dio_out;
  logic [pinmux_reg_pkg::NDioPads-1:0] dio_oe;
  logic [pinmux_reg_pkg::NDioPads-1:0] dio_in;

% if target["name"] != "verilator":
  logic                          [3:0] mux_iob_sel;
  logic [pinmux_reg_pkg::NMioPads-1:0] mio_in_raw;
  logic                         [${len(dedicated_pads)-1}:0] dio_in_raw;

  logic unused_mio_in_raw;
  logic unused_dio_in_raw;
  assign unused_mio_in_raw = ^mio_in_raw;
  assign unused_dio_in_raw = ^dio_in_raw;

  // Manual pads
% for pad in dedicated_pads:
<%
  pad_prefix = pad["name"].lower()
%>\
% if not get_dio_sig(pinmux, pad):
  logic manual_in_${pad_prefix}, manual_out_${pad_prefix}, manual_oe_${pad_prefix};
% endif
% endfor

% for pad in dedicated_pads:
<%
  pad_prefix = pad["name"].lower()
%>\
% if not get_dio_sig(pinmux, pad):
  pad_attr_t manual_attr_${pad_prefix};
% endif
% endfor
% endif

% if target["pinout"]["remove_pads"]:
  /////////////////////////
  // Stubbed pad tie-off //
  /////////////////////////

  // Only signals going to non-custom pads need to be tied off.
  logic [${len(pinout["pads"])-1}:0] unused_sig;
% for pad in pinout["pads"]:
  % if pad["connection"] == 'muxed':
    % if pad["name"] in target["pinout"]["remove_pads"]:
  assign mio_in[${pad["idx"]}] = 1'b0;
  assign mio_in_raw[${pad["idx"]}] = 1'b0;
  assign unused_sig[${loop.index}] = mio_out[${pad["idx"]}] ^ mio_oe[${pad["idx"]}];
    % endif
  % else:
    % if pad["name"] in target["pinout"]["remove_pads"]:
<%
    ## Only need to tie off if this is not a custom pad.
    sig = get_dio_sig(pinmux, pad)
    if sig is not None:
      sig_index = lib.get_io_enum_literal(sig, 'dio')
%>\
      % if sig is not None:
  assign dio_in[${lib.get_io_enum_literal(sig, 'dio')}] = 1'b0;
  assign unused_sig[${loop.index}] = dio_out[${sig_index}] ^ dio_oe[${sig_index}];
      % endif
    % endif
  % endif
% endfor
%endif\

  //////////////////////
  // Padring Instance //
  //////////////////////

% if target["name"] != "verilator":
  // AST control signals needed in the padring, driven by top_${top["name"]}
  ast_pkg::ast_clks_t ast_base_clks;
  prim_mubi_pkg::mubi4_t scanmode;

  padring #(
    // Padring specific counts may differ from pinmux config due
    // to custom, stubbed or added pads.
    .NDioPads(${len(dedicated_pads)}),
    .NMioPads(${len(muxed_pads)}),
% if target["name"] == "asic":
    .PhysicalPads(1),
    .NIoBanks(int'(IoBankCount)),
    .DioScanRole ({
% for pad in list(reversed(dedicated_pads)):
      scan_role_pkg::${lib.Name.from_snake_case('dio_pad_' + pad["name"] + '_scan_role').as_camel_case()}${"" if loop.last else ","}
% endfor
    }),
    .MioScanRole ({
% for pad in list(reversed(muxed_pads)):
      scan_role_pkg::${lib.Name.from_snake_case('mio_pad_' + pad["name"] + '_scan_role').as_camel_case()}${"" if loop.last else ","}
% endfor
    }),
    .DioPadBank ({
% for pad in list(reversed(dedicated_pads)):
      ${lib.Name.from_snake_case('io_bank_' + pad["bank"]).as_camel_case()}${" " if loop.last else ","} // ${pad['name']}
% endfor
    }),
    .MioPadBank ({
% for pad in list(reversed(muxed_pads)):
      ${lib.Name.from_snake_case('io_bank_' + pad["bank"]).as_camel_case()}${" " if loop.last else ","} // ${pad['name']}
% endfor
    }),
% endif
\
\
    .DioPadType ({
% for pad in list(reversed(dedicated_pads)):
      ${pad["type"]}${" " if loop.last else ","} // ${pad['name']}
% endfor
    }),
    .MioPadType ({
% for pad in list(reversed(muxed_pads)):
      ${pad["type"]}${" " if loop.last else ","} // ${pad['name']}
% endfor
    })
  ) u_padring (
    // This is only used for scan and DFT purposes
    .clk_scan_i(ast_base_clks.clk_sys),
    .scanmode_i(scanmode),

    .mux_iob_sel_i(mux_iob_sel),
    .dio_in_raw_o (dio_in_raw ),

    // Chip IOs
    .dio_pad_io ({
% for pad in list(reversed(dedicated_pads)):
  % if re.match(r"`INOUT_A?", pad["port_type"]):
`ifdef ANALOGSIM
      '0,
`else
      ${pad["name"]}${"" if loop.last else ","}
`endif
  % else:
      ${pad["name"]}${"" if loop.last else ","}
  % endif
% endfor
    }),

    .mio_pad_io ({
% for pad in list(reversed(muxed_pads)):
  % if re.match(r"`INOUT_A?", pad["port_type"]):
`ifdef ANALOGSIM
      '0,
`else
      ${pad["name"]}${"" if loop.last else ","}
`endif
  % else:
      ${pad["name"]}${"" if loop.last else ","}
  % endif
% endfor
    }),

    // Core-facing
% for port in ["in_o", "out_i", "oe_i", "attr_i"]:
    .dio_${port} ({
  % for pad in list(reversed(dedicated_pads)):
  <%
    sig = get_dio_sig(pinmux, pad)
  %>\
    % if sig is None:
      manual_${port[:-2]}_${pad["name"].lower()}${"" if loop.last else ","}
    % else:
      dio_${port[:-2]}[${lib.get_io_enum_literal(sig, 'dio')}]${"" if loop.last else ","}
    % endif
  % endfor
      }),
% endfor

% for port in ["in_o", "out_i", "oe_i", "attr_i", "in_raw_o"]:
<%
    sig_name = 'mio_' + port[:-2]
    indices = list(reversed(list(pad['idx'] for pad in muxed_pads)))
%>\
    .mio_${port} (${lib.make_bit_concatenation(sig_name, indices, 6)})${"" if loop.last else ","}
% endfor
  );
% else:
  // Padring substitute for the Verilator simulation top. The flat
  // per-peripheral cio_* pad signals live inside u_padring (see
  // padring_verilator.sv) and are driven and observed by the testbench DPI
  // models through hierarchical references.

  // USB signals routed directly to/from top_${top["name"]} (not via mio/dio)
  logic usb_dp_pullup_en;
  logic usb_dn_pullup_en;
  logic usb_rx_d;
  logic usb_tx_d;
  logic usb_tx_se0;
  logic usb_tx_use_d_se0;
  logic usb_rx_enable;

  padring_verilator u_padring (
    .mio_in_o  (mio_in ),
    .mio_out_i (mio_out),
    .mio_oe_i  (mio_oe ),
    .mio_attr_i(mio_attr),
    .dio_attr_i(dio_attr),

    .dio_in_o (dio_in ),
    .dio_out_i(dio_out),
    .dio_oe_i (dio_oe ),

    .usb_rx_d_o        (usb_rx_d        ),
    .usb_tx_d_i        (usb_tx_d        ),
    .usb_tx_se0_i      (usb_tx_se0      ),
    .usb_tx_use_d_se0_i(usb_tx_use_d_se0),
    .usb_rx_enable_i   (usb_rx_enable   ),
    .usb_dp_pullup_en_i(usb_dp_pullup_en),
    .usb_dn_pullup_en_i(usb_dn_pullup_en)
  );
% endif\

###################################################################
## USB for CW305                                                 ##
###################################################################
% if target["name"] == "cw305":
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

% endif
###################################################################
## USB for CW310 and CW340                                       ##
###################################################################
% if target["name"] in ["cw310", "cw340"]:
  // TODO: generalize this USB mux code and align with other tops.

  // Only use the UPHY on CW310, which does not support pin flipping.
  logic usb_dp_pullup_en;
  logic usb_rx_d;
  logic usb_rx_enable;

  // DioUsbdevUsbDn
  assign manual_attr_io_usb_dn_tx = '0;
  assign manual_out_io_usb_dn_tx = dio_out[DioUsbdevUsbDn];
  assign manual_oe_io_usb_dn_tx = 1'b1;
  assign dio_in[DioUsbdevUsbDn] = manual_in_io_usb_dn_rx;
  // DioUsbdevUsbDp
  assign manual_attr_io_usb_dp_tx = '0;
  assign manual_out_io_usb_dp_tx = dio_out[DioUsbdevUsbDp];
  assign manual_oe_io_usb_dp_tx = 1'b1;
  assign dio_in[DioUsbdevUsbDp] = manual_in_io_usb_dp_rx;

  assign manual_attr_io_usb_oe_n = '0;
  assign manual_out_io_usb_oe_n = ~dio_oe[DioUsbdevUsbDp];
  assign manual_oe_io_usb_oe_n = 1'b1;

  // DioUsbdevD
  assign manual_attr_io_usb_d_rx = '0;
  assign usb_rx_d = manual_in_io_usb_d_rx;

  // Pull-up / soft connect pin
  assign manual_attr_io_usb_connect = '0;
  assign manual_out_io_usb_connect = usb_dp_pullup_en;
  assign manual_oe_io_usb_connect = 1'b1;

  // Set SPD to full-speed
  assign manual_attr_io_usb_speed = '0;
  assign manual_out_io_usb_speed = 1'b1;
  assign manual_oe_io_usb_speed = 1'b1;

  // TUSB1106 low-power mode
  assign manual_attr_io_usb_suspend = '0;
  assign manual_out_io_usb_suspend = !usb_rx_enable;
  assign manual_oe_io_usb_suspend = 1'b1;

  logic unused_usb_sigs;
  assign unused_usb_sigs = ^{
    manual_in_io_usb_connect,
    manual_in_io_usb_oe_n,
    manual_in_io_usb_speed,
    manual_in_io_usb_suspend,
    // DP and DN are broken out into multiple unidirectional pins
    dio_oe[DioUsbdevUsbDp],
    dio_oe[DioUsbdevUsbDn],
    dio_attr[DioUsbdevUsbDp],
    dio_attr[DioUsbdevUsbDn]
  };
% endif

###################################################################
## ASIC                                                          ##
###################################################################
% if target["name"] == "asic":

  //////////////////////////////////
  // Manual Pad / Signal Tie-offs //
  //////////////////////////////////

  assign manual_out_por_n = 1'b0;
  assign manual_oe_por_n = 1'b0;

  assign manual_out_cc1 = 1'b0;
  assign manual_oe_cc1 = 1'b0;
  assign manual_out_cc2 = 1'b0;
  assign manual_oe_cc2 = 1'b0;

  assign manual_out_flash_test_mode0 = 1'b0;
  assign manual_oe_flash_test_mode0 = 1'b0;
  assign manual_out_flash_test_mode1 = 1'b0;
  assign manual_oe_flash_test_mode1 = 1'b0;
  assign manual_out_flash_test_volt = 1'b0;
  assign manual_oe_flash_test_volt = 1'b0;
  assign manual_out_otp_ext_volt = 1'b0;
  assign manual_oe_otp_ext_volt = 1'b0;

  // Enable schmitt trigger on POR for better signal integrity.
  assign manual_attr_por_n = '{schmitt_en: 1'b1, pull_en: 1'b1, pull_select: 1'b1, default: '0};

  // These pad attributes are controlled through sensor_ctrl.  Update the description of
  // `MANUAL_PAD_ATTR` in `sensor_ctrl.hjson` when you change or extend the mapping below.
  prim_pad_wrapper_pkg::pad_attr_t [3:0] sensor_ctrl_manual_pad_attr;
  assign manual_attr_cc1 = sensor_ctrl_manual_pad_attr[0];
  assign manual_attr_cc2 = sensor_ctrl_manual_pad_attr[1];
  assign manual_attr_flash_test_mode0 = sensor_ctrl_manual_pad_attr[2];
  assign manual_attr_flash_test_mode1 = sensor_ctrl_manual_pad_attr[3];

  // These pad attributes are currently tied off permanently (these are supply pads).
  assign manual_attr_flash_test_volt = '0;
  assign manual_attr_otp_ext_volt = '0;

  logic unused_manual_sigs;
  assign unused_manual_sigs = ^{
    manual_in_cc2,
    manual_in_cc1,
    manual_in_flash_test_volt,
    manual_in_flash_test_mode0,
    manual_in_flash_test_mode1,
    manual_in_otp_ext_volt
  };

  ///////////////////////////////
  // Differential USB Receiver //
  ///////////////////////////////

  // TODO: generalize this USB mux code and align with other tops.

  // Connect the D+ pad
  // Note that we use two pads in parallel for the D+ channel to meet electrical specifications.
  assign dio_in[DioUsbdevUsbDp] = manual_in_usb_p;
  assign manual_out_usb_p = dio_out[DioUsbdevUsbDp];
  assign manual_oe_usb_p = dio_oe[DioUsbdevUsbDp];
  assign manual_attr_usb_p = dio_attr[DioUsbdevUsbDp];

  // Connect the D- pads
  // Note that we use two pads in parallel for the D- channel to meet electrical specifications.
  assign dio_in[DioUsbdevUsbDn] = manual_in_usb_n;
  assign manual_out_usb_n = dio_out[DioUsbdevUsbDn];
  assign manual_oe_usb_n = dio_oe[DioUsbdevUsbDn];
  assign manual_attr_usb_n = dio_attr[DioUsbdevUsbDn];

  logic usb_rx_d;

  // Signals sourced by the AST inside top_${top["name"]}
  ast_pkg::ast_pwst_t                ast_pwst_h;
  logic [ast_pkg::UsbCalibWidth-1:0] usb_io_pu_cal;
  logic                              usb_diff_rx_obs;

  // Pullups and differential receiver enable
  logic usb_dp_pullup_en, usb_dn_pullup_en;
  logic usb_rx_enable;

  prim_usb_diff_rx #(
    .CalibW(ast_pkg::UsbCalibWidth)
  ) u_prim_usb_diff_rx (
    .input_pi         (USB_P             ),
    .input_ni         (USB_N             ),
    .input_en_i       (usb_rx_enable     ),
    .core_pok_h_i     (ast_pwst_h.aon_pok),
    .pullup_p_en_i    (usb_dp_pullup_en  ),
    .pullup_n_en_i    (usb_dn_pullup_en  ),
    .calibration_i    (usb_io_pu_cal     ),
    .usb_diff_rx_obs_o(usb_diff_rx_obs   ),
    .input_o          (usb_rx_d          )
  );

###################################################################
## FPGA shared                                                   ##
###################################################################
% elif target["name"] in ["cw305", "cw310", "cw340"]:
  //////////////////
  // PLL for FPGA //
  //////////////////

  assign manual_attr_io_clk = '0;
  assign manual_out_io_clk = 1'b0;
  assign manual_oe_io_clk = 1'b0;
  assign manual_attr_por_n = '0;
  assign manual_out_por_n = 1'b0;
  assign manual_oe_por_n = 1'b0;
  % if target["name"] in ["cw305", "cw310"]:
  assign manual_attr_por_button_n = '0;
  assign manual_out_por_button_n = 1'b0;
  assign manual_oe_por_button_n = 1'b0;

  % endif

  % if target["name"] == "cw305":
  // TODO: follow-up later and hardwire all ast connects that do not
  //       exist for this target
  assign otp_obs_o = '0;
  % endif

% endif

  /////////////////////////////////////////////
  // top_${top["name"]}: power domains + AST //
  /////////////////////////////////////////////
  top_${top["name"]}_${target["name"]} #(
% if gen_bkdr_loader:
    .BkdrLoaderEn(BkdrLoaderEn),
% endif
% if target["name"] == "asic":
    .SecRomCtrlDisableScrambling(SecRomCtrlDisableScrambling),
% elif target["name"] != "verilator":
    .BootRomInitFile(BootRomInitFile),
    .OtpMacroMemInitFile(OtpMacroMemInitFile),
% endif
    .PinmuxAonTargetCfg(PinmuxTargetCfg)
  ) top_${top["name"]} (
% if target["name"] == "verilator":
    // Clock and reset
    .clk_i,
    .rst_ni,

% endif
    // Multiplexed I/O to/from padring
    .mio_in_i  (mio_in  ),
    .mio_out_o (mio_out ),
    .mio_oe_o  (mio_oe  ),
    .dio_in_i  (dio_in  ),
    .dio_out_o (dio_out ),
    .dio_oe_o  (dio_oe  ),
    .mio_attr_o(mio_attr),
    .dio_attr_o(dio_attr),

% if target["name"] != "verilator":
    // AST control signals consumed by the padring
    .ast_base_clks_o(ast_base_clks),
    .scanmode_o     (scanmode     ),
    .mux_iob_sel_o  (mux_iob_sel  ),

% endif
% if target["name"] == "asic":
    .mio_in_raw_i(mio_in_raw),

    // Differential USB receiver interface
    .ast_pwst_h_o      (ast_pwst_h      ),
    .usb_io_pu_cal_o   (usb_io_pu_cal   ),
    .usb_diff_rx_obs_i (usb_diff_rx_obs ),
    .usb_dp_pullup_en_o(usb_dp_pullup_en),
    .usb_dn_pullup_en_o(usb_dn_pullup_en),
    .usb_rx_d_i        (usb_rx_d        ),
    .usb_rx_enable_o   (usb_rx_enable   ),

    // External POR
    .manual_in_por_n_i(manual_in_por_n),

    // Manual pad attributes from sensor_ctrl
    .sensor_ctrl_manual_pad_attr_o(sensor_ctrl_manual_pad_attr),

    // Direct connections to the chip pads
    .CC1             (CC1             ),
    .CC2             (CC2             ),
    .IOA2            (IOA2            ),
    .IOA3            (IOA3            ),
    .FLASH_TEST_MODE0(FLASH_TEST_MODE0),
    .FLASH_TEST_MODE1(FLASH_TEST_MODE1),
    .FLASH_TEST_VOLT (FLASH_TEST_VOLT ),
    .OTP_EXT_VOLT    (OTP_EXT_VOLT    )\
% else:
    // USB connections to USB mux glue
    .usb_dp_pullup_en_o(usb_dp_pullup_en),
%   if target["name"] == "verilator":
    .usb_dn_pullup_en_o(usb_dn_pullup_en),
    .usb_rx_d_i        (usb_rx_d        ),
    .usb_rx_enable_o   (usb_rx_enable   ),
    .usb_tx_d_o        (usb_tx_d        ),
    .usb_tx_se0_o      (usb_tx_se0      ),
    .usb_tx_use_d_se0_o(usb_tx_use_d_se0)\
%   elif target["name"] == "cw305":
    .usb_dn_pullup_en_o(usb_dn_pullup_en)\
%   elif target["name"] in ["cw310", "cw340"]:
    .usb_rx_d_i        (usb_rx_d        ),
    .usb_rx_enable_o   (usb_rx_enable   )\
%   endif
% endif
% if target["name"] in ["cw305", "cw310", "cw340"]:
,

    // POR and clock inputs feeding the FPGA clock generator
    .manual_in_por_n_i (manual_in_por_n ),
    .manual_in_io_clk_i(manual_in_io_clk)\
%   if target["name"] in ["cw305", "cw310"]:
,

    .manual_in_por_button_n_i(manual_in_por_button_n)
%   endif
% endif

  );

###################################################################
## CW310/305 capture board interface                             ##
###################################################################
% if target["name"] in ["cw340", "cw310", "cw305"]:

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

  % if target["name"] == "cw305":
  assign clk_trans_idle = top_${top["name"]}.${top["name"]}_pd_aon.u_clkmgr_aon.idle_i;
  % else:
  clkmgr_pkg::hint_names_e trigger_sel;
  always_comb begin : trigger_sel_mux
    unique case ({mio_out[MioOutGpioGpio11], mio_out[MioOutGpioGpio10]})
      2'b00:   trigger_sel = clkmgr_pkg::HintMainAes;
      2'b01:   trigger_sel = clkmgr_pkg::HintMainHmac;
      2'b10:   trigger_sel = clkmgr_pkg::HintMainKmac;
      2'b11:   trigger_sel = clkmgr_pkg::HintMainOtbn;
      default: trigger_sel = clkmgr_pkg::HintMainAes;
    endcase;
  end
  assign clk_trans_idle = top_${top["name"]}.${top["name"]}_pd_aon.u_clkmgr_aon.idle_i[trigger_sel];
  % endif

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
% endif\

endmodule
