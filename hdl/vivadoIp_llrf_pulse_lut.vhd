--=================================================================
-- Paul Scherrer Institut <PSI> Villigen, Schweiz
-- Copyright (c), 2023, Benoit STEF, all rights reserved 
--=================================================================
-- Arbitryry waveform generator        
--=================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.psi_common_math_pkg.all;
use work.psi_common_array_pkg.all;
use work.psi_fix_pkg.all;

--@formatter:off
entity vivadoIp_llrf_pulse_lut is
  generic(datFmt_g     : PsiFixFmt_t := (1, 0, 15);    -- size of data vector, can't exceed 16 bits for now
          ram_width_g  : natural     := 2**16;         -- size of RAM, number of samples
          ram_freq_g   : real        := 100.0E3;       -- sampling rate for reading data
          ratio_g      : natural     := 25;            -- ratio up sampling at the output
          clk_freq_g   : real        := 250.0E6;       -- clock frequency, clock processing
          rst_pol_g    : std_logic   := '1';
          set_Round_g  : boolean     := true;          -- Output calculation
          set_pipe_g   : boolean     := true;          -- increase timing performance
          gainFmt_g    : PsiFixFmt_t := (1, 0, 15);    -- Gain fixed point format
          offsFmt_g    : PsiFixFmt_t := (1, 0, 15);    -- Offset fixed point format
          outFmt_g     : PsiFixFmt_t := (1, 0, 15);    -- Output format
          intFmt_g     : PsiFixFmt_t := (1, 0, 20));   -- Internal format
  port(clk_i           : in  std_logic;               -- system clock processing
       rst_i           : in  std_logic;               -- system processing
       --*** INPUTs & parameters ***
       trig_i          : in  std_logic;                                             -- trigger
       ena_i           : in  std_logic;                                             -- enable state machine
       cmd_i           : in  std_logic_vector(1 downto 0);                          -- cmd component behavior, "00" & "11" Default, "01" only Adjust, "10" direct from RAM 
       ilk_i           : in  std_logic;                                             -- alarm stop
       gain_i          : in  std_logic_vector(PsiFixSize(gainFmt_g) - 1 downto 0);  -- gain output
       offset_i        : in  std_logic_vector(PsiFixSize(offsFmt_g) - 1 downto 0);  -- offset output
       delay_i         : in  std_logic_vector(31 downto 0);                         -- delay input after triger to start reading data
       sample_i        : in  std_logic_vector(log2ceil(ram_width_g) - 1 downto 0);  -- number of sample within the ram to read
       --*** DPRAM buffer mem mode ***
       axi_mem_load_i  : in  std_logic;                                             -- AXI ctrl  readback to prove the memory has been prorperly fed
       axi_mem_clk_i   : in  std_logic;                                             -- AXI clock
       axi_mem_rst_i   : in  std_logic;                                             -- AXI reset
       axi_mem_addr_i  : in  std_logic_vector(log2ceil(ram_width_g) - 1 downto 0);  -- AXI to RAM address
       axi_mem_wr_i    : in  std_logic;                                             -- AXI to RAM write memory
       axi_mem_wr_be_i : in std_logic_vector(3 downto 0);                           -- AXI write byte enable
       axi_mem_data_i  : in  std_logic_vector(31 downto 0);                         -- AXI TO RAM data to write
       axi_mem_data1_o : out std_logic_vector(31 downto 0);                         -- RAM to AXI 1
       axi_mem_data2_o : out std_logic_vector(31 downto 0);                         -- RAM to AXI 2
       axi_mem_info_o  : out std_logic;                                             -- Current RAM played, '0' ram2 '1' ram1
       --*** OUTPUTs ***
       dat_o           : out std_logic_vector(PsiFixSize(datFmt_g) - 1 downto 0);   -- amplitude to multiply with dds output
       str_o           : out std_logic);                                            -- strobe output
end entity;
--@formatter:on

architecture struct of vivadoIp_llrf_pulse_lut is
  constant zero_c  : std_logic_vector(31 downto 0):= (others=>'0');
  constant one_c   : std_logic_vector(31 downto 0):= (others=>'1');
  --fsm type def
  type fsm_t is (IDLE, DELAY, READ);
  signal fsm_s          : fsm_t;
  --PARAM
  signal gain_s         : std_logic_vector(gain_i'range)                       := (others => '0');
  signal offset_s       : std_logic_vector(offset_i'range)                     := (others => '0');
  signal delay_s        : std_logic_vector(31 downto 0)                        := (others => '0');
  --DPRAM
  signal ram_rd_str_s   : std_logic                                            := '0';
  signal ram_addr1_s    : unsigned(axi_mem_addr_i'range)                       := (others => '0');
  --signal ram_addr2_s    : unsigned(axi_mem_addr_i'range)                       := (others => '0');
  signal switch_s       : std_logic                                            := '0';
  signal ram_dat_s      : std_logic_vector(31 downto 0)                        := (others => '0');
  signal ram_dat1_s     : std_logic_vector(31 downto 0)                        := (others => '0');
  signal ram_dat2_s     : std_logic_vector(31 downto 0)                        := (others => '0');
  signal sample_s       : std_logic_vector(log2ceil(ram_width_g) - 1 downto 0) := (others => '0');
  signal axi_mem_load_s : std_logic                                            := '0';
  signal ram_switch_s   : std_logic                                            := '0';
  signal axi_mem_wr1_s  : std_logic                                            := '0';
  signal axi_mem_wr2_s  : std_logic                                            := '0';
  signal str_s          : std_logic                                            := '0';
  signal dat_s          : std_logic_vector(PsiFixSize(outFmt_g) - 1 downto 0);
  signal axi_mem_addr_s : std_logic_vector(log2ceil(ram_width_g) - 1 downto 0);
  signal axi_mem_dat_s  : std_logic_vector(axi_mem_data_i'range);
  signal cic_dat_s      : std_logic_vector(PsiFixSize(outFmt_g) - 1 downto 0);
  signal cic_str_s      : std_logic;
  signal cmd_s          : std_logic_vector(1 downto 0);

  function sel_rnd_func(s : in boolean;
                        t : in PsiFixRnd_t;
                        f : in PsiFixRnd_t) return PsiFixRnd_t is
  begin
    if s then
      return t;
    else
      return f;
    end if;
  end function;

  constant round_c       : PsiFixRnd_t := sel_rnd_func(set_Round_g, PsiFixRound, PsiFixTrunc);
  signal axi_mem_wr_be_s : std_logic_vector(3 downto 0);
  signal ram_rd_str_dff_s : std_logic;
begin

  proc_read_ram : process(clk_i)
    variable counter_v : unsigned(delay_i'range);
  begin
    if rising_edge(clk_i) then

      case fsm_s is

        when IDLE =>
          if trig_i = '1' and ilk_i = '0' and ena_i = '1' then
            if delay_i /= to_uslv(0, delay_i'length) then
              fsm_s <= DELAY;
            else
              fsm_s <= READ;
            end if;
            gain_s   <= gain_i;
            offset_s <= offset_i;
            delay_s  <= delay_i;
            sample_s <= sample_i;
            cmd_s    <= cmd_i;
            switch_s <= ram_switch_s;
          else
            fsm_s <= IDLE;
          end if;
          counter_v   := (others => '0');
          --ram_addr2_s <= (others => '0');
          ram_addr1_s <= (others => '0');

        when DELAY =>
          if counter_v = unsigned(delay_s) - 1 then
            fsm_s     <= READ;
            counter_v := (others => '0');
          else
            fsm_s <= DELAY;
            if ram_rd_str_s = '1' then
              counter_v := counter_v + 1;
            end if;
          end if;

        when READ =>
          if ram_rd_str_s = '1' then
            ram_addr1_s <= ram_addr1_s + 1;
            if switch_s = '0' then
              --** use oly one man
              --ram_addr1_s <= ram_addr1_s + 1;
              --ram_addr2_s <= (others => '0');
              ram_dat_s   <= ram_dat1_s;
            else
              --ram_addr2_s <= ram_addr2_s + 1;
              --ram_addr1_s <= (others => '0');
              ram_dat_s   <= ram_dat2_s;
            end if;
            --
            if ram_addr1_s = unsigned(sample_s) then-- or ram_addr2_s = unsigned(sample_s) then
              fsm_s <= IDLE;
            else
              fsm_s <= READ;
            end if;
          end if;
      end case;

      if rst_i = rst_pol_g or ilk_i = '1' then
        fsm_s <= IDLE;
      end if;
      ram_rd_str_dff_s <= ram_rd_str_s;
    end if;
  end process;
  axi_mem_info_o <= ram_switch_s;
  --===================================================
  -- TAG axi switch between ram to write in
  --===================================================
  process(axi_mem_clk_i)
  begin
    if rising_edge(axi_mem_clk_i) then
      axi_mem_load_s  <= axi_mem_load_i;
      axi_mem_addr_s  <= axi_mem_addr_i;
      axi_mem_dat_s   <= axi_mem_data_i;
      axi_mem_wr_be_s <= axi_mem_wr_be_i;      
      axi_mem_wr1_s   <= not ram_switch_s and axi_mem_wr_i;
      axi_mem_wr2_s   <= ram_switch_s and axi_mem_wr_i;
      if axi_mem_rst_i = '1' then
        ram_switch_s <= '0';
      end if;
      if axi_mem_load_i = '1' and axi_mem_load_s = '0' then
        ram_switch_s <= not ram_switch_s;
      end if;
    end if;
  end process;
  --===================================================
  -- TAG Strobe generator inst 1.0us & 1.0ms
  --     generate TB Speed up simulation time
  --     use or not let see how it evolves
  --===================================================
  inst_ram_str : entity work.psi_common_strobe_generator
    generic map(freq_clock_g  => clk_freq_g,
                freq_strobe_g => ram_freq_g,
                rst_pol_g     => rst_pol_g)
    port map(clk_i  => clk_i,
             rst_i  => rst_i,
             sync_i => '0',
             vld_o => ram_rd_str_s);

  --================================================
  -- TAG DP ram double buffer react upon load signal
  --================================================
  --ram_addr1_std_s <=  std_logic_vector(ram_addr2_s);
--  inst_ram_1 : entity work.psi_common_tdp_ram_be
--   generic map(
--     Depth_g    => ram_width_g,
--     Width_g    => 32,
--      Behavior_g => "RBW")
--    port map(
      --*** TAG WRITE from AXI directly ***
      --    set mechanism to have double buffer
--      ClkA  => axi_mem_clk_i,
--      AddrA => axi_mem_addr_s,
--      BeA   => axi_mem_wr_be_s,
--      WrA   => axi_mem_wr1_s,
--      DinA  => axi_mem_dat_s,
--      DoutA => axi_mem_data1_o,
      -- *** READ ***
--      ClkB  => clk_i,
--      AddrB => std_logic_vector(ram_addr1_s),
--      BeB   => one_c(3 downto 0),
--      WrB   => zero_c(0),
--      DinB  => (others => '0'),
--      DoutB => ram_dat1_s);
      
  inst_test_ram1 : entity work.bytewrite_tdp_ram_rf
    generic map(
      SIZE       => ram_width_g,
      ADDR_WIDTH => log2ceil(ram_width_g),
      COL_WIDTH  => 8,
      NB_COL     => 4
    )
    port map(
      clka  => axi_mem_clk_i,
      ena   => axi_mem_wr1_s,
      wea   => axi_mem_wr_be_s,
      addra => axi_mem_addr_s,
      dia   => axi_mem_dat_s,
      doa   => axi_mem_data1_o,
      --*** READ ***
      clkb  => clk_i,
      enb   => ram_rd_str_dff_s,
      web   => zero_c(3 downto 0),
      addrb => std_logic_vector(ram_addr1_s),
      dib   => zero_c(31 downto 0),
      dob   => ram_dat1_s
    );
 
  --ram_addr2_std_s <=  std_logic_vector(ram_addr2_s);
 -- inst_ram_2 : entity work.psi_common_tdp_ram_be
 --   generic map(
 --     Depth_g    => ram_width_g,
 --   Width_g    => 32,
 --   Behavior_g => "RBW")
 -- port map(
 --   --*** TAG WRITE from AXI directly ***
 --   --    set mechanism to have double buffer
 --   ClkA  => axi_mem_clk_i,
 --   AddrA => axi_mem_addr_s,
 --   BeA   => axi_mem_wr_be_s,
 --   WrA   => axi_mem_wr2_s,
 --   DinA  => axi_mem_dat_s,
 --   DoutA => axi_mem_data2_o,
 --   -- *** READ ***
 --   ClkB  => clk_i,
 --   AddrB => std_logic_vector(ram_addr2_s),
 --   BeB   => one_c(3 downto 0),
 --   WrB   => zero_c(0),
 --   DinB  => (others => '0'),
 --   DoutB => ram_dat2_s);
 
 inst_test_ram2 : entity work.bytewrite_tdp_ram_rf
    generic map(
      SIZE       => ram_width_g,
      ADDR_WIDTH => log2ceil(ram_width_g),
      COL_WIDTH  => 8,
      NB_COL     => 4
    )
    port map(
      clka  => axi_mem_clk_i,
      ena   => axi_mem_wr2_s,
      wea   => axi_mem_wr_be_s,
      addra => axi_mem_addr_s,
      dia   => axi_mem_dat_s,
      doa   => axi_mem_data2_o,
      --*** READ ***
      clkb  => clk_i,
      enb   => ram_rd_str_dff_s,
      web   => zero_c(3 downto 0),
      addrb => std_logic_vector(ram_addr1_s),
      dib   => zero_c(31 downto 0),
      dob   => ram_dat2_s
    );
  -----------------------------------------------------------------------
  -->>>>>>>>>>>>>>>>>>>>  ADJUST GAIN OFFSET <<<<<<<<<<<<<<<<<<<<<<<<<<<
  -- TAG insert the Gain and offset from DDS vivadoIp
  -----------------------------------------------------------------------
  block_adjust : block
    constant RamFmt_c : PsiFixFmt_t := (1, 0, 15); -- fixed by design or not !
    constant AddFmt_c : PsiFixFmt_t := (RamFmt_c.S, intFmt_g.I + offsFmt_g.I + 1, offsFmt_g.F + intFmt_g.F);
    constant RndFmt_c : PsiFixFmt_t := (AddFmt_c.S, AddFmt_c.I + 1, outFmt_g.F);

    -- Two process method
    type two_process_r is record
      -- Registers always present
      vld      : std_logic_vector(0 to 5);
      mult     : std_logic_vector(PsiFixSize(intFmt_g) - 1 downto 0);
      add      : std_logic_vector(PsiFixSize(AddFmt_c) - 1 downto 0);
      res      : std_logic_vector(PsiFixSize(outFmt_g) - 1 downto 0);
      -- Additional registers for pipelined version
      in_dff   : std_logic_vector(PsiFixSize(datFmt_g) - 1 downto 0);
      mult_dff : std_logic_vector(PsiFixSize(intFmt_g) - 1 downto 0);
      rnd_dff  : std_logic_vector(PsiFixSize(RndFmt_c) - 1 downto 0);
    end record;

    signal r, r_next : two_process_r;

  begin
    proc_comb : process(r, ram_dat_s, gain_s, offset_s, ram_rd_str_s)
      variable v : two_process_r;
    begin
      --*** hold variable ***
      v := r;

      -- *** Vld Handling ***
      v.vld(0)      := ram_rd_str_s;
      v.vld(1 to 5) := r.vld(0 to 4);

      --*** pipeline active ***
      if set_pipe_g then
        v.in_dff   := ram_dat_s(PsiFixSize(datFmt_g) - 1 downto 0);
        v.mult_dff := r.mult;
      end if;
      --*** Gain ***
      v.mult := PsiFixMult(choose(set_pipe_g, r.in_dff, ram_dat_s(PsiFixSize(datFmt_g) - 1 downto 0)), datFmt_g,
                           gain_s(PsiFixSize(gainFmt_g) - 1 downto 0), gainFmt_g,
                           intFmt_g, PsiFixTrunc, PsiFixWrap);
      --*** Offset ***
      v.add  := PsiFixAdd(choose(set_pipe_g, r.mult_dff, r.mult), intFmt_g,
                          offset_s(PsiFixSize(offsFmt_g) - 1 downto 0), offsFmt_g,
                          AddFmt_c, PsiFixTrunc, PsiFixWrap);
      --*** Resize ***
      if set_pipe_g then
        v.rnd_dff := PsiFixResize(r.add, AddFmt_c, RndFmt_c, round_c, PsiFixWrap);
        v.res     := PsiFixResize(r.rnd_dff, RndFmt_c, outFmt_g, PsiFixTrunc, PsiFixSat);
      else
        v.res := PsiFixResize(r.add, AddFmt_c, outFmt_g, round_c, PsiFixSat);
      end if;
      r_next <= v;
    end process;

    -- *** Outputs ***
    gene_out_pl : if set_pipe_g generate
      str_s <= r.vld(5);

    end generate;
    gene_out_npl : if not set_pipe_g generate
      str_s <= r.vld(2);
    end generate;
    dat_s <= r.res;

    proc_reg : process(clk_i)
    begin
      if rising_edge(clk_i) then
        r <= r_next;
        if rst_i = rst_pol_g then
          r.vld <= (others => '0');
        end if;
      end if;
    end process;
  end block;

  -----------------------------------------------------------------------
  -->>>>>>>>>>>>>>> TAG CIC UP sampling if required <<<<<<<<<<<<<<<<<<<<<
  -----------------------------------------------------------------------
  inst_upsampling : entity work.psi_fix_cic_int_fix_1ch
    generic map(Order_g        => 3,
                ratio_g        => ratio_g,
                DiffDelay_g    => 1,
                InFmt_g        => datFmt_g,
                OutFmt_g       => datFmt_g,
                AutoGainCorr_g => True)
    port map(Clk     => clk_i,
             Rst     => rst_i,
             InData  => dat_s,
             InVld   => str_s,
             InRdy   => open,
             OutData => cic_dat_s,
             vld_o  => cic_str_s,
             OutRdy  => '1');

  -----------------------------------------------------------------------
  -->>>>>>>>>>>> TAG MUX output UP sampling if required <<<<<<<<<<<<<<<<<
  -----------------------------------------------------------------------
  proc_mux_out : process(clk_i)
  begin
    if rising_edge(clk_i) then
      --*** default Adjut + CIC ***
      if ilk_i = '1' then
        dat_o <= (others => '0');
        str_o <= '0';
      else
        if cmd_s = "00" then
          dat_o <= cic_dat_s;
          str_o <= cic_str_s;
        --*** only Adjust ***
        elsif cmd_s = "01" then
          dat_o <= dat_s;
          str_o <= str_s;
        elsif cmd_s = "10" then
          dat_o <= ram_dat_s(PsiFixSize(datFmt_g)-1 downto 0);
          str_o <= ram_rd_str_s;
        else
          dat_o <= cic_dat_s;
          str_o <= cic_str_s;
        end if;
      end if;
    end if;
  end process;

end architecture;
