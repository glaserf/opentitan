// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//

package rstmgr_pkg;

  // Power domain parameters
  parameter int PowerDomains = 2;
  parameter int DomainAonSel = 0;
  parameter int DomainMainSel = 1;

  // Number of non-always-on domains
  parameter int OffDomains = PowerDomains-1;

  // Split-IP inter-partition signalling. These structs carry the crash-dump
  // register interface between the primary partition (which hosts reg_top) and
  // the secondary partition (which hosts the crash-dump capture logic).
  typedef struct packed {
    logic                                dump_capture;
    logic                                dump_capture_halt;
    logic                                alert_info_en;
    logic [rstmgr_reg_pkg::IdxWidth-1:0] alert_info_index;
    logic                                cpu_info_en;
    logic [rstmgr_reg_pkg::IdxWidth-1:0] cpu_info_index;
  } rstmgr_interpart_p2s_t;

  typedef struct packed {
    logic [rstmgr_reg_pkg::RdWidth-1:0]  alert_info;
    logic [rstmgr_reg_pkg::IdxWidth-1:0] alert_info_attr;
    logic [rstmgr_reg_pkg::RdWidth-1:0]  cpu_info;
    logic [rstmgr_reg_pkg::IdxWidth-1:0] cpu_info_attr;
    logic                                alert_info_ctrl_en_de;
    logic                                cpu_info_ctrl_en_de;
  } rstmgr_interpart_s2p_t;

  // positions of software controllable reset bits
  parameter int SPI_DEVICE = 0;
  parameter int SPI_HOST0 = 1;
  parameter int SPI_HOST1 = 2;
  parameter int USB = 3;
  parameter int USB_AON = 4;
  parameter int I2C0 = 5;
  parameter int I2C1 = 6;
  parameter int I2C2 = 7;

  // resets generated and broadcast
  // SEC_CM: LEAF.RST.SHADOW
  typedef struct packed {
    logic [PowerDomains-1:0] rst_por_aon_n;
    logic [PowerDomains-1:0] rst_por_n;
    logic [PowerDomains-1:0] rst_por_io_n;
    logic [PowerDomains-1:0] rst_por_io_div2_n;
    logic [PowerDomains-1:0] rst_por_io_div4_n;
    logic [PowerDomains-1:0] rst_por_usb_n;
    logic [PowerDomains-1:0] rst_lc_shadowed_n;
    logic [PowerDomains-1:0] rst_lc_n;
    logic [PowerDomains-1:0] rst_lc_aon_n;
    logic [PowerDomains-1:0] rst_lc_io_n;
    logic [PowerDomains-1:0] rst_lc_io_div2_n;
    logic [PowerDomains-1:0] rst_lc_io_div4_shadowed_n;
    logic [PowerDomains-1:0] rst_lc_io_div4_n;
    logic [PowerDomains-1:0] rst_lc_usb_n;
    logic [PowerDomains-1:0] rst_sys_n;
    logic [PowerDomains-1:0] rst_sys_io_div4_n;
    logic [PowerDomains-1:0] rst_spi_device_n;
    logic [PowerDomains-1:0] rst_spi_host0_n;
    logic [PowerDomains-1:0] rst_spi_host1_n;
    logic [PowerDomains-1:0] rst_usb_n;
    logic [PowerDomains-1:0] rst_usb_aon_n;
    logic [PowerDomains-1:0] rst_i2c0_n;
    logic [PowerDomains-1:0] rst_i2c1_n;
    logic [PowerDomains-1:0] rst_i2c2_n;
  } rstmgr_out_t;

  // reset indication for alert handler
  typedef struct packed {
    prim_mubi_pkg::mubi4_t [PowerDomains-1:0] por_aon;
    prim_mubi_pkg::mubi4_t [PowerDomains-1:0] por;
    prim_mubi_pkg::mubi4_t [PowerDomains-1:0] por_io;
    prim_mubi_pkg::mubi4_t [PowerDomains-1:0] por_io_div2;
    prim_mubi_pkg::mubi4_t [PowerDomains-1:0] por_io_div4;
    prim_mubi_pkg::mubi4_t [PowerDomains-1:0] por_usb;
    prim_mubi_pkg::mubi4_t [PowerDomains-1:0] lc_shadowed;
    prim_mubi_pkg::mubi4_t [PowerDomains-1:0] lc;
    prim_mubi_pkg::mubi4_t [PowerDomains-1:0] lc_aon;
    prim_mubi_pkg::mubi4_t [PowerDomains-1:0] lc_io;
    prim_mubi_pkg::mubi4_t [PowerDomains-1:0] lc_io_div2;
    prim_mubi_pkg::mubi4_t [PowerDomains-1:0] lc_io_div4_shadowed;
    prim_mubi_pkg::mubi4_t [PowerDomains-1:0] lc_io_div4;
    prim_mubi_pkg::mubi4_t [PowerDomains-1:0] lc_usb;
    prim_mubi_pkg::mubi4_t [PowerDomains-1:0] sys;
    prim_mubi_pkg::mubi4_t [PowerDomains-1:0] sys_io_div4;
    prim_mubi_pkg::mubi4_t [PowerDomains-1:0] spi_device;
    prim_mubi_pkg::mubi4_t [PowerDomains-1:0] spi_host0;
    prim_mubi_pkg::mubi4_t [PowerDomains-1:0] spi_host1;
    prim_mubi_pkg::mubi4_t [PowerDomains-1:0] usb;
    prim_mubi_pkg::mubi4_t [PowerDomains-1:0] usb_aon;
    prim_mubi_pkg::mubi4_t [PowerDomains-1:0] i2c0;
    prim_mubi_pkg::mubi4_t [PowerDomains-1:0] i2c1;
    prim_mubi_pkg::mubi4_t [PowerDomains-1:0] i2c2;
  } rstmgr_rst_en_t;

  parameter int NumOutputRst = 24 * PowerDomains;

  // cpu reset requests and status
  typedef struct packed {
    logic ndmreset_req;
  } rstmgr_cpu_t;

  // exported resets

  // default value for rstmgr_ast_rsp_t (for dangling ports)
  parameter rstmgr_cpu_t RSTMGR_CPU_DEFAULT = '{
    ndmreset_req: '0
  };

  // Enumeration for pwrmgr hw reset inputs
  import rstmgr_reg_pkg::NumTotalResets;
  localparam int ResetWidths = $clog2(NumTotalResets);
  typedef enum logic [ResetWidths-1:0] {
    ReqPeriResetIdx[0:1],
    ReqMainPwrResetIdx,
    ReqEscResetIdx,
    ReqNdmResetIdx
  } reset_req_idx_e;

  // Enumeration for reset info bit idx
  typedef enum logic [ResetWidths-1:0] {
    InfoPorIdx,
    InfoLowPowerExitIdx,
    InfoSwResetIdx,
    InfoPeriResetIdx[0:1],
    InfoMainPwrResetIdx,
    InfoEscResetIdx,
    InfoNdmResetIdx
  } reset_info_idx_e;


endpackage // rstmgr_pkg
