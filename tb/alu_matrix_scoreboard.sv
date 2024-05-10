`ifndef ALU_MATRIX_SCOREBOARD
`define ALU_MATRIX_SCOREBOARD

import alu_matrix_pkg::*;

class alu_matrix_scoreboard;

  /* !!!----------------------------------------------------!!! */
  /* !!! DO NOT TOUCH CODE BELOW OR YOU MAY BE DISQUALIFIED !!! */
  /* !!!----------------------------------------------------!!! */

  int error_count;
  int check_count;

  /* !!!----------------------------------------------------!!! */
  /* !!! DO NOT TOUCH CODE ABOVE OR YOU MAY BE DISQUALIFIED !!! */
  /* !!!----------------------------------------------------!!! */

  // Registers of golden model
  alu_matrix_reg_model alu_matrix_regs;

  // Mailboxes' handlers
  mailbox rst2scrb;
  mailbox in2scrb;
  mailbox out2scrb;
  mailbox apb2scrb;
  mailbox irq2scrb;

  // Event that indicates first valid_ready
  // handshake on axis_in_if
  event first_hs;

  // Handlers for transactions collected from mailboxes
  rst_transaction        coll_rst_transaction;
  irq_transaction        coll_irq_transaction;
  axi_stream_transaction coll_in_transaction;
  axi_stream_transaction coll_out_transaction;
  apb_master_transaction coll_apb_transaction;

  // Your variables here...
  typedef logic signed [`AXI_DATA_W - 1:0] queue [$];
  typedef logic signed [15:0] long_queue [$];

  int unsigned alu_op;
  int unsigned matrix0v;
  int unsigned matrix0h;
  int unsigned matrix1v;
  int unsigned matrix1h;
  logic signed [`AXI_DATA_W - 1:0] matrix0 [$];
  logic signed [`AXI_DATA_W - 1:0] matrix1 [$];



  function new(alu_matrix_reg_model alu_matrix_regs, mailbox rst2scrb, in2scrb, out2scrb, apb2scrb, irq2scrb, event first_hs);
    this.alu_matrix_regs = alu_matrix_regs;

    this.rst2scrb        = rst2scrb;
    this.in2scrb         = in2scrb;
    this.out2scrb        = out2scrb;
    this.apb2scrb        = apb2scrb;
    this.irq2scrb        = irq2scrb;

    this.first_hs        = first_hs;

    /* !!!----------------------------------------------------!!! */
    /* !!! DO NOT TOUCH CODE BELOW OR YOU MAY BE DISQUALIFIED !!! */
    /* !!!----------------------------------------------------!!! */
    this.error_count     = 0;
    this.check_count     = 0;
    /* !!!----------------------------------------------------!!! */
    /* !!! DO NOT TOUCH CODE ABOVE OR YOU MAY BE DISQUALIFIED !!! */
    /* !!!----------------------------------------------------!!! */
  endfunction


  function void pre_main();
    // You can write your code here...
  endfunction

  task main();
    fork

      forever begin
        rst2scrb.get(coll_rst_transaction);
        alu_matrix_regs.reset();
      end

      forever begin
        apb_master_transaction coll_apb_transaction_clone;
        apb2scrb.get(coll_apb_transaction);
        coll_apb_transaction_clone = new coll_apb_transaction;
        alu_matrix_regs.update(coll_apb_transaction_clone);
        process_apb_transaction(coll_apb_transaction);
      end

      forever begin
        #10;
        alu_op = alu_matrix_regs.OPCODE;
        matrix0v = alu_matrix_regs.MATRIX0V;
        matrix0h = alu_matrix_regs.MATRIX0H;
        matrix1v = alu_matrix_regs.MATRIX1V;
        matrix1h = alu_matrix_regs.MATRIX1H;
      end
      // ...

    join_none
  endtask

  task run;
    pre_main();
    main();
  endtask

  function long_queue sum_matrix(queue matrix0, queue matrix1);
    long_queue temp_result;
    for (int i = 0; i < matrix0v; i++) begin
      for (int j = 0; j < matrix0h; j++) begin
        temp_result.push_back(matrix0.pop_front() + matrix1.pop_front());
      end
    end

    return temp_result;
  endfunction: sum_matrix

  function long_queue mult_matrix(logic signed [`AXI_DATA_W - 1:0] matrix0[$], logic signed [`AXI_DATA_W - 1:0] matrix1[$]);
    int temp_A [7:0][7:0];
    int temp_B [7:0][7:0];
    int temp_result [7:0][7:0];
    long_queue result;
    for (int i = 0; i < matrix0v; i++) begin
      for (int j = 0; j < matrix0h; j++) begin
        temp_A[i][j] = matrix0.pop_front();
      end
    end
    for (int i = 0; i < matrix1v; i++) begin
      for (int j = 0; j < matrix1h; j++) begin
        temp_B[i][j] = matrix1.pop_front();
      end
    end
    for (int i = 0; i < matrix0v; i++) begin
      for (int j = 0; j < matrix1h; j++) begin
        for (int k = 0; k < matrix0h; k++) begin
          temp_result[i][j] = temp_result[i][j] + temp_A[i][k] * temp_B[k][j];
        end
        result.push_back(temp_result[i][j]);
      end
    end
    return result;
  endfunction: mult_matrix

  function long_queue trans_matrix(queue matrix0);
    int temp_A [7:0][7:0];
    int temp_result [7:0][7:0];
    long_queue result;
    for (int i = 0; i < matrix0v; i++) begin
      for (int j = 0; j < matrix0h; j++) begin
        temp_A[i][j] = matrix0.pop_front();
      end
    end
    for (int i = 0; i < matrix0h; i++) begin
      for (int j = 0; j < matrix0v; j++) begin
        result.push_back(temp_A[j][i]);
      end
    end
    return result;
  endfunction: trans_matrix

  function int abs(int num);
    return (num > 0) ? num : -num;
  endfunction: abs

  function real det(queue matrix0);
    real temp_A [7:0][7:0];
    real result = 1;
    real mx;
    int idx;
    real temp;
    for (int i = 0; i < matrix0v; i++) begin
        for (int j = 0; j < matrix0v; j++) begin
            temp_A[i][j] = matrix0.pop_front();
        end
    end
    for (int i = 0; i < matrix0v; ++i) begin
        mx = abs(temp_A[i][i]);
        idx = i;
        if (mx == 0) begin
            for (int j = i + 1; j < matrix0v; ++j) begin
                if (temp_A[j][i] != 0) begin
                    idx = j;
                    for (int k = 0; k < matrix0v; ++k) begin
                        temp = temp_A[k][i];
                        temp_A[k][i] = temp_A[k][idx];
                        temp_A[k][idx] = temp;
                    end
                    result = -result;
                    break;
                end
            end
        end
        for (int k = i + 1; k < matrix0v; ++k) begin
            temp = temp_A[k][i]/temp_A[i][i];
            for (int j = i; j < matrix0v; ++j) begin
                temp_A[k][j] -= temp_A[i][j] * temp;
            end
        end
    end
    for (int i = 0; i < matrix0v; ++i) begin
        result = result * temp_A[i][i];
    end
    return result;
  endfunction : det

  function long_queue inv_matrix(queue matrix0);
    real temp_A [7:0][7:0];
    real temp_inv [7:0][7:0];
    real pivot, multiplier;
    long_queue result;
    for (int i = 0; i < matrix0v; i++) begin
        for (int j = 0; j < matrix0v; j++) begin
            temp_A[i][j] = matrix0.pop_front();
            temp_inv[i][j] = (i == j) ? 1 : 0;
        end
    end
    for (int i = 0; i < matrix0v; i++) begin
        pivot = temp_A[i][i];
        if (pivot == 0) begin
            $display("Zero on the diagonal, the matrix is not invertible");
            return result;
        end
        for (int j = 0; j < matrix0v; j++) begin
            temp_A[i][j] /= pivot;
            temp_inv[i][j] /= pivot;
        end
        for (int k = 0; k < matrix0v; k++) begin
            if (k != i) begin
                multiplier = temp_A[k][i];
                for (int j = 0; j < matrix0v; j++) begin
                    temp_A[k][j] -= multiplier * temp_A[i][j];
                    temp_inv[k][j] -= multiplier * temp_inv[i][j];
                end
            end
        end
    end
    for (int i = 0; i < matrix0v; i++) begin
        for (int j = 0; j < matrix0v; j++) begin
            result.push_back(temp_inv[i][j]);
        end
    end
    return result;
  endfunction : inv_matrix



endclass : alu_matrix_scoreboard



task automatic process_apb_transaction(apb_master_transaction coll_apb_transaction);
  // Your code here...

endtask

task automatic process_axis_in_transaction(axi_stream_transaction coll_in_transaction);
  // Your code here...
endtask

task automatic process_axis_out_transaction(axi_stream_transaction coll_out_transaction);
  // Your code here...
endtask

// ...

`endif //!ALU_MATRIX_SCOREBOARD
