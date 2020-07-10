// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// This vseq randomly programs memory protection and performs a bunch of read / program / erase
// operations. It is encouraged to extend this vseq to a custom vseq that constrains the
// randomization by overriding the `configure_vseq()` function. See `flash_ctrl_sanity_vseq` for
// example.
class flash_ctrl_rand_ops_vseq extends flash_ctrl_base_vseq;
  `uvm_object_utils(flash_ctrl_rand_ops_vseq)

  // Number of times we run a random flash operation with a fully configured flash ctrl.
  rand uint num_flash_ops_per_cfg;

  constraint num_flash_ops_per_cfg_c {
    num_flash_ops_per_cfg inside {[1:cfg.seq_cfg.max_flash_ops_per_cfg]};
  }

  // A single randomized flash ctrl operation.
  rand flash_ctrl_single_op_t flash_ctrl_op;

  constraint flash_ctrl_op_c {
    flash_ctrl_op.addr inside {[0:FLASH_CTRL_SIZE_BYTES-1]};

    (flash_ctrl_op.op == FlashCtrlOpErase) ->
        flash_ctrl_op.erase_type dist {
          FlashCtrlErasePage :/ (100 - cfg.seq_cfg.op_erase_type_bank_pc),
          FlashCtrlEraseBank :/ cfg.seq_cfg.op_erase_type_bank_pc
        };

    flash_ctrl_op.partition dist {
      FlashCtrlPartitionData :/ cfg.seq_cfg.op_on_data_partition_pc,
      FlashCtrlPartitionInfo :/ (100 - cfg.seq_cfg.op_on_data_partition_pc)
    };

    if (flash_ctrl_op.op inside {FlashCtrlOpRead, FlashCtrlOpProgram}) {
      flash_ctrl_op.num_words inside {
        [1:FLASH_CTRL_NUM_BUS_WORDS - flash_ctrl_op.addr[TL_AW-1:TL_SZW]]
      };
      flash_ctrl_op.num_words <= cfg.seq_cfg.op_max_words;
    }
  }

  // Flash ctrl op data - use for programing or reading the flash.
  rand bit [TL_DW-1:0] flash_ctrl_op_data[$];

  constraint flash_ctrl_op_data_c {
    solve flash_ctrl_op before flash_ctrl_op_data;
    if (flash_ctrl_op.op inside {FlashCtrlOpRead, FlashCtrlOpProgram}) {
      flash_ctrl_op_data.size() == flash_ctrl_op.num_words;
    } else {
      flash_ctrl_op_data.size() == 0;
    }
  }

  // Bit vector representing which of the mp region cfg CSRs to enable.
  rand bit [FLASH_CTRL_NUM_MP_REGIONS-1:0] en_mp_regions;

  constraint en_mp_regions_c {
    $countones(en_mp_regions) == cfg.seq_cfg.num_en_mp_regions;
  }

  // Memory protection regions settings.
  rand flash_ctrl_mp_region_t mp_regions[FLASH_CTRL_NUM_MP_REGIONS];

  constraint mp_regions_c {
    solve en_mp_regions before mp_regions;

    foreach (mp_regions[i]) {
      mp_regions[i].en == en_mp_regions[i];

      mp_regions[i].read_en dist {
        0 :/ (100 - cfg.seq_cfg.mp_region_read_en_pc),
        1 :/ cfg.seq_cfg.mp_region_read_en_pc
      };

      mp_regions[i].program_en dist {
        0 :/ (100 - cfg.seq_cfg.mp_region_program_en_pc),
        1 :/ cfg.seq_cfg.mp_region_program_en_pc
      };

      mp_regions[i].erase_en dist {
        0 :/ (100 - cfg.seq_cfg.mp_region_erase_en_pc),
        1 :/ cfg.seq_cfg.mp_region_erase_en_pc
      };

      mp_regions[i].start_page inside {[0:FLASH_CTRL_NUM_PAGES - 1]};
      mp_regions[i].num_pages inside {[1:FLASH_CTRL_NUM_PAGES - mp_regions[i].start_page]};
      mp_regions[i].num_pages <= cfg.seq_cfg.mp_region_max_pages;

      // If overlap not allowed, then each configured region is uniquified.
      // This creates an ascending order of mp_regions that are configured, so we shuffle it in
      // post_randomize.
      if (!cfg.seq_cfg.allow_mp_region_overlap) {
        foreach (mp_regions[j]) {
          if (i != j) {
            !mp_regions[i].start_page inside {
              [mp_regions[j].start_page:mp_regions[j].start_page + mp_regions[j].num_pages]
            };
          }
        }
      }

      mp_regions[i].partition dist {
        FlashCtrlPartitionData :/ cfg.seq_cfg.mp_region_data_partition_pc,
        FlashCtrlPartitionInfo :/ (100 - cfg.seq_cfg.mp_region_data_partition_pc)
      };
    }
  }

  // Default flash ctrl region settings.
  rand bit default_region_read_en;
  rand bit default_region_program_en;
  rand bit default_region_erase_en;

  constraint default_region_read_en_c {
    default_region_read_en dist {
      1 :/ cfg.seq_cfg.default_region_read_en_pc,
      0 :/ (100 - cfg.seq_cfg.default_region_read_en_pc)
    };
  }

  constraint default_region_program_en_c {
    default_region_program_en dist {
      1 :/ cfg.seq_cfg.default_region_program_en_pc,
      0 :/ (100 - cfg.seq_cfg.default_region_program_en_pc)
    };
  }

  constraint default_region_erase_en_c {
    default_region_erase_en dist {
      1 :/ cfg.seq_cfg.default_region_erase_en_pc,
      0 :/ (100 - cfg.seq_cfg.default_region_erase_en_pc)
    };
  }

  // Bank erasability.
  rand bit [FLASH_CTRL_NUM_BANKS-1:0] bank_erase_en;

  constraint bank_erase_en_c {
    foreach (bank_erase_en[i]) {
      bank_erase_en[i] dist {
        1 :/ (100 - cfg.seq_cfg.bank_erase_en_pc),
        0 :/ cfg.seq_cfg.bank_erase_en_pc
      };
    }
  }

  // Fifo levels.
  rand uint program_fifo_intr_level;
  rand uint read_fifo_intr_level;

  constraint program_fifo_intr_level_c {
    program_fifo_intr_level dist {
      0                            :/ 1,
      [1:4]                        :/ 1,
      [5:10]                       :/ 1,
      [11:FLASH_CTRL_FIFO_DEPTH-2] :/ 1,
      FLASH_CTRL_FIFO_DEPTH-1      :/ 1
    };
  }

  constraint program_fifo_intr_level_max_c {
    program_fifo_intr_level < FLASH_CTRL_FIFO_DEPTH;
  }

  constraint read_fifo_intr_level_c {
    read_fifo_intr_level dist {
      0                            :/ 1,
      [1:4]                        :/ 1,
      [5:10]                       :/ 1,
      [11:FLASH_CTRL_FIFO_DEPTH-2] :/ 1,
      FLASH_CTRL_FIFO_DEPTH-1      :/ 1
    };
  }

  constraint read_fifo_intr_level_max_c {
    read_fifo_intr_level < FLASH_CTRL_FIFO_DEPTH;
  }

  `uvm_object_new

  task body();
    for (int i = 1; i <= num_trans; i++) begin
      `uvm_info(`gfn, $sformatf("Configuring flash_ctrl %0d/%0d", i, num_trans),
                UVM_MEDIUM)
      `DV_CHECK_RANDOMIZE_FATAL(this)

      // Configure the flash based on the randomized settings.
      foreach (mp_regions[i]) begin
        flash_ctrl_mp_region_cfg(i, mp_regions[i]);
      end

      flash_ctrl_default_region_cfg(.read_en   (default_region_read_en),
                                    .program_en(default_region_program_en),
                                    .erase_en  (default_region_erase_en));

      flash_ctrl_bank_erase_cfg(.bank_erase_en(bank_erase_en));

      // TODO: randomly enable interrupts.

      // Send num_flash_ops_per_cfg number of ops with this configuration.
      for (int j = 1; j <= num_flash_ops_per_cfg; j++) begin
        `DV_CHECK_MEMBER_RANDOMIZE_FATAL(flash_ctrl_op)
        `DV_CHECK_MEMBER_RANDOMIZE_FATAL(flash_ctrl_op_data)

        `uvm_info(`gfn, $sformatf("Starting flash_ctrl op: %0d/%0d: %p",
                                  j, num_flash_ops_per_cfg, flash_ctrl_op), UVM_MEDIUM)

        // Bkdr initialize the flash mem based on op.
        flash_ctrl_prep_mem(flash_ctrl_op);

        flash_ctrl_start_op(flash_ctrl_op);
        case (flash_ctrl_op.op)
          FlashCtrlOpRead: begin
            flash_ctrl_read(flash_ctrl_op.num_words, flash_ctrl_op_data);
            wait_flash_ctrl_op_done();
            flash_mem_bkdr_read_check(flash_ctrl_op, flash_ctrl_op_data);
          end
          FlashCtrlOpProgram: begin
            flash_ctrl_write(flash_ctrl_op_data);
            wait_flash_ctrl_op_done();
            flash_mem_bkdr_read_check(flash_ctrl_op, flash_ctrl_op_data);
          end
          FlashCtrlOpErase: begin
            wait_flash_ctrl_op_done();
            flash_mem_bkdr_erase_check(flash_ctrl_op);
          end
          default: begin
            // TODO: V2 test item.
          end
        endcase
      end
    end
  endtask : body

  // Prep the flash mem via bkdr before an op for enhanced checks.
  virtual function void flash_ctrl_prep_mem(flash_ctrl_single_op_t flash_ctrl_op);
    // Invalidate the flash mem contents. We do this because we operate on and check a specific
    // chunk of space. The rest of the flash mem is essentially dont-care. If the flash ctrl
    // does not work correctly, the check will result in an access from the invalidated mem
    // region exposing the issue.
    flash_mem_bkdr_init(flash_ctrl_op.partition, FlashMemInitInvalidate);
    case (flash_ctrl_op.op)
      FlashCtrlOpRead: begin
        // Initialize the targeted mem region with random data.
        flash_mem_bkdr_write(.flash_ctrl_op (flash_ctrl_op),
                             .flash_mem_init(FlashMemInitRandomize));
      end
      FlashCtrlOpProgram: begin
        // Initialize the targeted mem region with all 1s. This is required because the flash
        // needs to be erased to all 1s between each successive programming.
        flash_mem_bkdr_write(.flash_ctrl_op (flash_ctrl_op),
                             .flash_mem_init(FlashMemInitSet));
      end
    endcase
  endfunction

endclass : flash_ctrl_rand_ops_vseq
