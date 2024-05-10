`ifndef ALU_MATRIX_TEST
`define ALU_MATRIX_TEST

class alu_matrix_test;

  /* !!!----------------------------------------------------!!! */
  /* !!! DO NOT TOUCH CODE BELOW OR YOU MAY BE DISQUALIFIED !!! */
  /* !!!----------------------------------------------------!!! */
  int timeout_us;
  int max_err_count;

  string testname;
  /* !!!----------------------------------------------------!!! */
  /* !!! DO NOT TOUCH CODE ABOVE OR YOU MAY BE DISQUALIFIED !!! */
  /* !!!----------------------------------------------------!!! */

  alu_matrix_env env;

  apb_master_transaction apb_transaction ;
  axi_stream_transaction axis_transaction;
  clk_transaction        clk_transaction ;
  rst_transaction        rst_transaction ;

  // Your variables here...
  typedef logic signed [`AXI_DATA_W - 1:0] queue [$];
  typedef logic signed [15:0] long_queue [$];
  logic signed [`AXI_DATA_W - 1:0] matrix [$]; // For BASIC_TEST

  int unsigned matrix0v;
  int unsigned matrix0h;
  int unsigned matrix1v;
  int unsigned matrix1h;
  logic signed [`AXI_DATA_W - 1:0] matrix0 [$];
  logic signed [`AXI_DATA_W - 1:0] matrix1 [$];

  long_queue predict;
  logic signed [7:0] value_b;
  logic signed [7:0] value_s;
  logic signed [15:0] value;
  logic signed [15:0] predict_element;
  int signed variables;

  function new(alu_matrix_env env);
    this.env = env;



    /* !!!----------------------------------------------------!!! */
    /* !!! DO NOT TOUCH CODE BELOW OR YOU MAY BE DISQUALIFIED !!! */
    /* !!!----------------------------------------------------!!! */
    if ($value$plusargs("testname=%s", testname)) begin
      $display("--- TESTNAME IS %0s ---", testname);
    end else begin
      $fatal(3, "TESTNAME WAS NOT SET! Exiting...");
    end
    /* !!!----------------------------------------------------!!! */
    /* !!! DO NOT TOUCH CODE ABOVE OR YOU MAY BE DISQUALIFIED !!! */
    /* !!!----------------------------------------------------!!! */
  endfunction


  task run();

    fork

      begin
        env.run();
      end

      begin
        case (testname)
          "TEST_BASIC" : begin
            basic_test();
          end
          // Your tests here...
          //
          //
          "TEST_SUM" : begin
            repeat(1000) begin
              sum_test();
            end
          end
          "TEST_MULTY" : begin
            repeat(1000) begin
              multy_test();
            end
          end
          "TEST_TRANS" : begin
            repeat(1000) begin
              transp_test();
            end
          end
          "TEST_DETERM" : begin
            repeat(1000) begin
              determ_test();
            end
          end
          "TEST_REVERSE" : begin
            repeat(1000) begin
              reverse_test();
            end
          end
          "TEST_SUM_ERROR" : begin
            repeat(1000) begin
              sum_error_test();
            end
          end
          "TEST_MULTY_ERROR" : begin
            repeat(1000) begin
              multy_error_test();
            end
          end
          "TEST_DET_ERROR" : begin
            repeat(1000) begin
              det_error_test();
            end
          end
          default : begin
            $fatal(2, "UNDEFINED TESTNAME WAS SET! Exiting...");
          end
        endcase

        /* !!!---------------------------------------------------!!! */
        /* !!! DO NOT TOUCH CODE BELOW OR YOU MAY BE DISQUALIFIED!!! */
        /* !!!---------------------------------------------------!!! */
        finish();
        /* !!!---------------------------------------------------!!! */
        /* !!! DO NOT TOUCH CODE ABOVE OR YOU MAY BE DISQUALIFIED!!! */
        /* !!!---------------------------------------------------!!! */
      end


      /* !!!---------------------------------------------------!!! */
      /* !!! DO NOT TOUCH CODE BELOW OR YOU MAY BE DISQUALIFIED!!! */
      /* !!!---------------------------------------------------!!! */
      begin
        if ($value$plusargs("timeout_us=%d", timeout_us)) begin
          $display("--- TEST TIMEOUT IS SET TO %0d us ---", timeout_us);
          #(timeout_us*1000);
          $fatal(2, "SIMULATION TIME EXCEEDED! Exiting...");
        end else begin
          $fatal(2, "TIMEOUT WAS NOT SET! Exiting...");
        end
      end

      begin
        if ($value$plusargs("max_err_count=%d", max_err_count)) begin
          $display("--- MAXIMUM ERROR COUNT IS SET TO %0d ---", max_err_count);
          wait (env.scrb.error_count >= max_err_count);
          $fatal(2, "MAXIMUM ERROR COUNT REACHED! Exiting...");
        end else begin
          $fatal(2, "MAXIMUM ERROR COUNT WAS NOT SET! Exiting...");
        end
      end
      /* !!!---------------------------------------------------!!! */
      /* !!! DO NOT TOUCH CODE ABOVE OR YOU MAY BE DISQUALIFIED!!! */
      /* !!!---------------------------------------------------!!! */

    join_none

  endtask


  // API
  task clk_transaction_put(int t_period);
    clk_transaction = new();
    clk_transaction.period = t_period;
    env.clk_agent.to_driver.put(clk_transaction);
  endtask

  task rst_transaction_put(int t_duration);
    rst_transaction = new();
    rst_transaction.duration = t_duration;
    env.rst_agent.to_driver.put(rst_transaction);
  endtask

  task apb_transaction_put(logic [`APB_ADDR_W -1:0] t_addr = 0, t_data = 0, logic t_is_write = 0);
    apb_transaction = new();
    apb_transaction.addr = t_addr;
    apb_transaction.is_write = t_is_write;
    apb_transaction.data = t_data;
    env.apb_master_agent.to_driver.put(apb_transaction);
  endtask

  task axis_transaction_put(logic signed [`AXI_DATA_W -1:0] t_data[$]);
    axis_transaction = new();
    axis_transaction.data = t_data;
    env.axis_master_agent.to_driver.put(axis_transaction);
  endtask

  task wait_apb_end_trans();
    @(posedge (env.vif.apb_if.pready && env.vif.apb_if.penable));
    @(posedge env.vif.clk_if.clk);
  endtask

  task wait_axis_in_end_trans();
    @(posedge (env.vif.axis_in_if.axis_last && env.vif.axis_in_if.axis_valid && env.vif.axis_in_if.axis_ready));
    @(posedge env.vif.clk_if.clk);
  endtask

  task wait_axis_out_end_trans();
    @(posedge (env.vif.axis_out_if.axis_last && env.vif.axis_out_if.axis_valid && env.vif.axis_out_if.axis_ready));
    repeat(2) @(posedge env.vif.clk_if.clk);
  endtask

  task assert_sum_results();
    predict = env.scrb.sum_matrix(matrix0, matrix1);
    for (int i = 0; i < matrix0h*matrix0v; i++) begin
      value_s = axis_transaction.data.pop_back();
      value_b = axis_transaction.data.pop_back();
      value = {value_b, value_s};
      predict_element = predict.pop_back();
      if (value != predict_element) begin
        env.scrb.error_count++;
        $error("Found error: value = %d : %b, predict = %d : %b", value, value, predict_element, predict_element);
      end
    end
  endtask

  task assert_multy_results();
    predict = env.scrb.mult_matrix(matrix0, matrix1);
    for (int i = 0; i < matrix0h*matrix0v; i++) begin
      value_s = axis_transaction.data.pop_back();
      value_b = axis_transaction.data.pop_back();
      value = {value_b, value_s};
      predict_element = predict.pop_back();
      if (value != predict_element) begin
        env.scrb.error_count++;
        $error("Found error: value = %d : %b, predict = %d : %b", value, value, predict_element, predict_element);
      end
    end
  endtask

  task assert_transp_results();
    predict = env.scrb.trans_matrix(matrix0);
    for (int i = 0; i < matrix0h*matrix0v; i++) begin
      value_s = axis_transaction.data.pop_back();
      value_b = axis_transaction.data.pop_back();
      value = {value_b, value_s};
      predict_element = predict.pop_back();
      if (value != predict_element) begin
        env.scrb.error_count++;
        $error("Found error: value = %d : %b, predict = %d : %b", value, value, predict_element, predict_element);
      end
    end
  endtask

  task assert_determ_results();
    predict_element = env.scrb.det(matrix0);
    value_s = axis_transaction.data.pop_back();
    value_b = axis_transaction.data.pop_back();
    value = {value_b, value_s};
    if (value != predict_element) begin
      env.scrb.error_count++;
      $error("Found error: value = %d : %b, predict = %d : %b", value, value, predict_element, predict_element);
    end
  endtask

  task assert_reverse_results();
    predict = env.scrb.inv_matrix(matrix0);
    for (int i = 0; i < matrix0v*matrix0v; i++) begin
      value_s = axis_transaction.data.pop_back();
      value_b = axis_transaction.data.pop_back();
      value = {value_b, value_s};
      predict_element = predict.pop_back();
      if (value != predict_element) begin
        env.scrb.error_count++;
        $error("Found error: value = %d : %b, predict = %d : %b", value, value, predict_element, predict_element);
      end
    end
  endtask

  // Example basic test
  task basic_test();
    // Start generating clock signal with period of 10 ns
    clk_transaction_put(10);
    // Wait for the first posedge clk
    @(posedge env.vif.clk_if.clk);
    // Drive active reset for 50 ns
    rst_transaction_put(50);
    // Set some values in registers using APB
    apb_transaction_put(32'h10, 3, 1);
    wait_apb_end_trans();
    apb_transaction_put(32'h14, 3, 1);
    wait_apb_end_trans();
    apb_transaction_put(32'h00, 3, 1);
    wait_apb_end_trans();
    // Drive matrix using AXI-stream
    matrix = {1,2,3,4,5,6,7,8,9};
    axis_transaction_put(matrix);
    wait_axis_in_end_trans();
    // Check ISR, write 1 to clear it
    // and then collect result or repeat
    // ...
  endtask

  // Sum test
  task sum_test();
    matrix0 = {};
    matrix1 = {};
    clk_transaction_put(10);
    @(posedge env.vif.clk_if.clk);
    rst_transaction_put(50);
    // Set random sizes
    if (!std::randomize(matrix0v) with {
      matrix0v inside {[1:5]};
    }) $error("ERROR matrix0v");
    if (!std::randomize(matrix0h) with {
      matrix0h inside {[1:5]};
    }) $error("ERROR matrix0h");
    // Set first matrix size
    apb_transaction_put(32'h10, matrix0v, 1);
    wait_apb_end_trans();
    apb_transaction_put(32'h14, matrix0h, 1);
    wait_apb_end_trans();
    // Set second matrix size
    apb_transaction_put(32'h18, matrix0v, 1);
    wait_apb_end_trans();
    apb_transaction_put(32'h1C, matrix0h, 1);
    wait_apb_end_trans();
    // Set operation sum
    apb_transaction_put(32'h00, 1, 1);
    wait_apb_end_trans();
    // Matrix random
    for (int i = 0; i < matrix0v*matrix0h; i++) begin
      matrix0.push_back($urandom_range(-128, 127));
    end
    for (int i = 0; i < matrix0v*matrix0h; i++) begin
      matrix1.push_back($urandom_range(-128, 127));
    end
    axis_transaction_put(matrix0);
    wait_axis_in_end_trans();
    axis_transaction_put(matrix1);
    wait_axis_in_end_trans();
    // ISR = 1
    #40;
    apb_transaction_put(32'h08, 2, 1);
    wait_apb_end_trans();
    // Get sum result
    axis_transaction = new();
    do begin
      @(posedge env.axis_slave_agent.monitor.vif.clk)
      if (env.axis_slave_agent.monitor.vif.axis_valid && env.axis_slave_agent.monitor.vif.axis_ready) begin
        axis_transaction.data.push_back(env.axis_slave_agent.monitor.vif.axis_data);
      end
    end
    while (!env.axis_slave_agent.monitor.vif.axis_last);
    // Assert results
    assert_sum_results();
    #40;
    env.scrb.check_count++;
    apb_transaction_put(32'h20, env.scrb.check_count, 1);
  endtask

  // Sum error test
  task sum_error_test();
    matrix0 = {};
    matrix1 = {};
    clk_transaction_put(10);
    @(posedge env.vif.clk_if.clk);
    rst_transaction_put(50);
    // Set random sizes
    if (!std::randomize(matrix0v) with {
      matrix0v inside {[1:3]};
    }) $error("ERROR matrix0v");
    if (!std::randomize(matrix0h) with {
      matrix0h inside {[1:3]};
    }) $error("ERROR matrix0h");
    if (!std::randomize(matrix1v) with {
      matrix1v inside {[4:6]};
    }) $error("ERROR matrix0v");
    if (!std::randomize(matrix1h) with {
      matrix1h inside {[4:6]};
    }) $error("ERROR matrix0h");
    // Set first matrix size
    apb_transaction_put(32'h10, matrix0v, 1);
    wait_apb_end_trans();
    apb_transaction_put(32'h14, matrix0h, 1);
    wait_apb_end_trans();
    // Set second matrix size
    apb_transaction_put(32'h18, matrix1v, 1);
    wait_apb_end_trans();
    apb_transaction_put(32'h1C, matrix1h, 1);
    wait_apb_end_trans();
    // Set operation sum
    apb_transaction_put(32'h00, 1, 1);
    wait_apb_end_trans();
    // Matrix random
    for (int i = 0; i < matrix0v*matrix0h; i++) begin
      matrix0.push_back($urandom_range(-128, 127));
    end
    for (int i = 0; i < matrix0v*matrix0h; i++) begin
      matrix1.push_back($urandom_range(-128, 127));
    end
    axis_transaction_put(matrix0);
    wait_axis_in_end_trans();
    axis_transaction_put(matrix1);
    wait_axis_in_end_trans();
    // ISR = 1
    #40;
    apb_transaction_put(32'h08, 1, 1);
    wait_apb_end_trans();
    #40;
    apb_transaction_put(32'h04, 1, 0);
    wait_apb_end_trans();
    if (apb_transaction.data != 1) begin
      env.scrb.error_count++;
      $error("IRQ is not set!");
    end
    env.scrb.check_count++;
    apb_transaction_put(32'h20, env.scrb.check_count, 1);
  endtask

  task multy_test();
    matrix0 = {};
    matrix1 = {};
    clk_transaction_put(10);
    @(posedge env.vif.clk_if.clk);
    rst_transaction_put(50);
    // Set random sizes
    if (!std::randomize(matrix0v) with {
      matrix0v inside {[1:5]};
    }) $error("ERROR matrix0v");
    if (!std::randomize(matrix0h) with {
      matrix0h inside {[1:5]};
    }) $error("ERROR matrix0h");
    // Set first matrix size
    apb_transaction_put(32'h10, matrix0v, 1);
    wait_apb_end_trans();
    apb_transaction_put(32'h14, matrix0h, 1);
    wait_apb_end_trans();
    // Set second matrix size
    apb_transaction_put(32'h18, matrix0h, 1);
    wait_apb_end_trans();
    apb_transaction_put(32'h1C, matrix0v, 1);
    wait_apb_end_trans();
    // Set operation mult
    apb_transaction_put(32'h00, 2, 1);
    wait_apb_end_trans();
    // Matrix random
    for (int i = 0; i < matrix0v*matrix0h; i++) begin
      matrix0.push_back($urandom_range(-128, 127));
    end
    for (int i = 0; i < matrix0v*matrix0h; i++) begin
      matrix1.push_back($urandom_range(-128, 127));
    end
    axis_transaction_put(matrix0);
    wait_axis_in_end_trans();
    axis_transaction_put(matrix1);
    wait_axis_in_end_trans();
    // ISR = 1
    #40;
    apb_transaction_put(32'h08, 2, 1);
    wait_apb_end_trans();
    // Get mult result
    axis_transaction = new();
    do begin
      @(posedge env.axis_slave_agent.monitor.vif.clk)
      if (env.axis_slave_agent.monitor.vif.axis_valid && env.axis_slave_agent.monitor.vif.axis_ready) begin
        axis_transaction.data.push_back(env.axis_slave_agent.monitor.vif.axis_data);
      end
    end
    while (!env.axis_slave_agent.monitor.vif.axis_last);
    // Assert results
    assert_multy_results();
    #40;
    env.scrb.check_count++;
    apb_transaction_put(32'h24, env.scrb.check_count, 1);
  endtask

  // Sum error test
  task multy_error_test();
    matrix0 = {};
    matrix1 = {};
    clk_transaction_put(10);
    @(posedge env.vif.clk_if.clk);
    rst_transaction_put(50);
    // Set random sizes
    if (!std::randomize(matrix0v) with {
      matrix0v inside {[1:3]};
    }) $error("ERROR matrix0v");
    if (!std::randomize(matrix0h) with {
      matrix0h inside {[1:3]};
    }) $error("ERROR matrix0h");
    if (!std::randomize(matrix1v) with {
      matrix1v inside {[4:6]};
    }) $error("ERROR matrix0v");
    if (!std::randomize(matrix1h) with {
      matrix1h inside {[4:6]};
    }) $error("ERROR matrix0h");
    // Set first matrix size
    apb_transaction_put(32'h10, matrix0v, 1);
    wait_apb_end_trans();
    apb_transaction_put(32'h14, matrix0h, 1);
    wait_apb_end_trans();
    // Set second matrix size
    apb_transaction_put(32'h18, matrix1v, 1);
    wait_apb_end_trans();
    apb_transaction_put(32'h1C, matrix1h, 1);
    wait_apb_end_trans();
    // Set operation sum
    apb_transaction_put(32'h00, 2, 1);
    wait_apb_end_trans();
    // Matrix random
    for (int i = 0; i < matrix0v*matrix0h; i++) begin
      matrix0.push_back($urandom_range(-128, 127));
    end
    for (int i = 0; i < matrix1v*matrix1h; i++) begin
      matrix1.push_back($urandom_range(-128, 127));
    end
    axis_transaction_put(matrix0);
    wait_axis_in_end_trans();
    axis_transaction_put(matrix1);
    wait_axis_in_end_trans();
    // ISR = 1
    #40;
    apb_transaction_put(32'h08, 1, 1);
    wait_apb_end_trans();
    #40;
    apb_transaction_put(32'h04, 1, 0);
    wait_apb_end_trans();
    if (apb_transaction.data != 1) begin
      env.scrb.error_count++;
      $error("IRQ is not set!");
    end
    env.scrb.check_count++;
    apb_transaction_put(32'h24, env.scrb.check_count, 1);
  endtask

  // Sum error test
  task det_error_test();
    matrix0 = {};
    clk_transaction_put(10);
    @(posedge env.vif.clk_if.clk);
    rst_transaction_put(50);
    // Set random sizes
    if (!std::randomize(matrix0v) with {
      matrix0v inside {[1:3]};
    }) $error("ERROR matrix0v");
    if (!std::randomize(matrix0h) with {
      matrix0h inside {[4:6]};
    }) $error("ERROR matrix0h");
    // Set first matrix size
    apb_transaction_put(32'h10, matrix0v, 1);
    wait_apb_end_trans();
    apb_transaction_put(32'h14, matrix0h, 1);
    wait_apb_end_trans();
    // Set operation sum
    apb_transaction_put(32'h00, 5, 1);
    wait_apb_end_trans();
    // Matrix random
    for (int i = 0; i < matrix0v*matrix0h; i++) begin
      matrix0.push_back($urandom_range(-128, 127));
    end
    axis_transaction_put(matrix0);
    wait_axis_in_end_trans();
    // ISR = 1
    #40;
    apb_transaction_put(32'h08, 1, 1);
    wait_apb_end_trans();
    #40;
    apb_transaction_put(32'h04, 1, 0);
    wait_apb_end_trans();
    if (apb_transaction.data != 1) begin
      env.scrb.error_count++;
      $error("IRQ is not set!");
    end
    env.scrb.check_count++;
    apb_transaction_put(32'h30, env.scrb.check_count, 1);
  endtask

  task transp_test();
    matrix0 = {};
    clk_transaction_put(10);
    @(posedge env.vif.clk_if.clk);
    rst_transaction_put(50);
    // Set random sizes
    if (!std::randomize(matrix0v) with {
      matrix0v inside {[1:5]};
    }) $error("ERROR matrix0v");
    if (!std::randomize(matrix0h) with {
      matrix0h inside {[1:5]};
    }) $error("ERROR matrix0h");
    // Set first matrix size
    apb_transaction_put(32'h10, matrix0v, 1);
    wait_apb_end_trans();
    apb_transaction_put(32'h14, matrix0h, 1);
    wait_apb_end_trans();
    // Set operation transp
    apb_transaction_put(32'h00, 3, 1);
    wait_apb_end_trans();
    // Matrix random
    for (int i = 0; i < matrix0v*matrix0h; i++) begin
      matrix0.push_back($urandom_range(-128, 127));
    end
    axis_transaction_put(matrix0);
    wait_axis_in_end_trans();
    // ISR = 1
    #40;
    apb_transaction_put(32'h08, 2, 1);
    wait_apb_end_trans();
    // Get transp result
    axis_transaction = new();
    do begin
      @(posedge env.axis_slave_agent.monitor.vif.clk)
      if (env.axis_slave_agent.monitor.vif.axis_valid && env.axis_slave_agent.monitor.vif.axis_ready) begin
        axis_transaction.data.push_back(env.axis_slave_agent.monitor.vif.axis_data);
      end
    end
    while (!env.axis_slave_agent.monitor.vif.axis_last);
    // Assert results
    assert_transp_results();
    #40;
    env.scrb.check_count++;
    apb_transaction_put(32'h28, env.scrb.check_count, 1);
  endtask

  task determ_test();
    matrix0 = {};
    clk_transaction_put(10);
    @(posedge env.vif.clk_if.clk);
    rst_transaction_put(50);
    // Set random sizes
    if (!std::randomize(matrix0v) with {
      matrix0v inside {[1:5]};
    }) $error("ERROR matrix0v");
    // Set first matrix size
    apb_transaction_put(32'h10, matrix0v, 1);
    wait_apb_end_trans();
    apb_transaction_put(32'h14, matrix0v, 1);
    wait_apb_end_trans();
    // Set operation transp
    apb_transaction_put(32'h00, 5, 1);
    wait_apb_end_trans();
    // Matrix random
    for (int i = 0; i < matrix0v*matrix0v; i++) begin
      matrix0.push_back($urandom_range(-128, 127));
    end
    axis_transaction_put(matrix0);
    wait_axis_in_end_trans();
    // ISR = 1
    #40;
    apb_transaction_put(32'h08, 2, 1);
    wait_apb_end_trans();
    // Get determ result
    axis_transaction = new();
    do begin
      @(posedge env.axis_slave_agent.monitor.vif.clk)
      if (env.axis_slave_agent.monitor.vif.axis_valid && env.axis_slave_agent.monitor.vif.axis_ready) begin
        axis_transaction.data.push_back(env.axis_slave_agent.monitor.vif.axis_data);
      end
    end
    while (!env.axis_slave_agent.monitor.vif.axis_last);
    // Assert results
    assert_determ_results();
    #40;
    env.scrb.check_count++;
    apb_transaction_put(32'h30, env.scrb.check_count, 1);
  endtask

  task reverse_test();
    matrix0 = {};
    clk_transaction_put(10);
    @(posedge env.vif.clk_if.clk);
    rst_transaction_put(50);
    // Set random sizes
    if (!std::randomize(matrix0v) with {
      matrix0v inside {[1:5]};
    }) $error("ERROR matrix0v");
    // Set first matrix size
    apb_transaction_put(32'h10, matrix0v, 1);
    wait_apb_end_trans();
    apb_transaction_put(32'h14, matrix0v, 1);
    wait_apb_end_trans();
    // Set operation transp
    apb_transaction_put(32'h00, 4, 1);
    wait_apb_end_trans();
    // Matrix random
    for (int i = 0; i < matrix0v*matrix0v; i++) begin
      matrix0.push_back($urandom_range(-128, 127));
    end
    axis_transaction_put(matrix0);
    wait_axis_in_end_trans();
    // ISR = 1
    #40;
    apb_transaction_put(32'h08, 2, 1);
    wait_apb_end_trans();
    // Get inversion result
    axis_transaction = new();
    do begin
      @(posedge env.axis_slave_agent.monitor.vif.clk)
      if (env.axis_slave_agent.monitor.vif.axis_valid && env.axis_slave_agent.monitor.vif.axis_ready) begin
        axis_transaction.data.push_back(env.axis_slave_agent.monitor.vif.axis_data);
      end
    end
    while (!env.axis_slave_agent.monitor.vif.axis_last);
    // Assert results
    assert_reverse_results();
    #40;
    env.scrb.check_count++;
    apb_transaction_put(32'h2C, env.scrb.check_count, 1);
  endtask

  /* !!!----------------------------------------------------!!! */
  /* !!! DO NOT TOUCH CODE BELOW OR YOU MAY BE DISQUALIFIED !!! */
  /* !!!----------------------------------------------------!!! */

  task finish();
    if (env.scrb.error_count == 0) begin
      $display("========== TEST PASSED ===========",);
      $display("Performed %0d result matrix checks", env.scrb.check_count);
    end else begin
      $display("========== TEST FAILED ===========",);
      $display("Performed %0d result matrix checks", env.scrb.check_count);
      $display("Collected %0d errors in total     ", env.scrb.error_count);
    end
    $finish();
  endtask

  /* !!!----------------------------------------------------!!! */
  /* !!! DO NOT TOUCH CODE ABOVE OR YOU MAY BE DISQUALIFIED !!! */
  /* !!!----------------------------------------------------!!! */

endclass

`endif //!ALU_MATRIX_TEST
