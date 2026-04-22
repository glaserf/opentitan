## Copyright lowRISC contributors (OpenTitan project).
## Licensed under the Apache License, Version 2.0, see LICENSE for details.
## SPDX-License-Identifier: Apache-2.0
<%page args="top, phys_pd, alert_handler_signals"/>\
% for name, plic in top["plic_info"].items():
<% prefix = "_" + name if len(top["plic_info"]) > 1 else "" %>\
% if plic["phys_pd"] == phys_pd:
  % for pd in top["power"]["physical"]:
<% if pd == phys_pd: continue %>\
    % if plic["count_pd"][pd] > 0:
<% chiplevel_sig = f"intr_vector{prefix}_pd_{pd}" %>\
    .${chiplevel_sig}_i(${chiplevel_sig}),
    % endif
  % endfor
% else:
  % if plic["count_pd"][phys_pd] > 0:
<% chiplevel_sig = f"intr_vector{prefix}_pd_{phys_pd}" %>\
    .intr_vector${prefix}_o(${chiplevel_sig}),
  % endif
% endif
% endfor

% for name, ah in top["alert_handler_info"].items():
<% signals = alert_handler_signals(name) %>\
% if ah["phys_pd"] == phys_pd:
  % for pd in top["power"]["physical"]:
<% if pd == phys_pd: continue %>\
<% pd_len = ah["count_pd"][pd] - 1 %>\
    % if pd_len >= 0:
<% chiplevel_sigs = (f"{signals[0]}_pd_{pd}", f"{signals[1]}_pd_{pd}") %>\
    .${chiplevel_sigs[0]}_i(${chiplevel_sigs[0]}),
    .${chiplevel_sigs[1]}_o(${chiplevel_sigs[1]}),
    % endif
  % endfor
% else:
<% pd_len = ah["count_pd"][phys_pd] - 1 %>\
  % if pd_len >= 0:
<% chiplevel_sigs = (f"{signals[0]}_pd_{phys_pd}", f"{signals[1]}_pd_{phys_pd}") %>\
    .${signals[0]}_o(${chiplevel_sigs[0]}),
    .${signals[1]}_i(${chiplevel_sigs[1]}),
  % endif
% endif
% endfor