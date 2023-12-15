
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

use work.psi_tb_txt_util.all;
use work.psi_tb_activity_pkg.all;
use work.psi_tb_compare_pkg.all;
use work.psi_common_math_pkg.all;
use work.psi_fix_pkg.all;

entity psi_fix_mov_avg_var_tb is
  generic(clock_cycle_g : integer := 8;
          sample_g      : integer := clock_cycle_g/2;
          signed_data_g : boolean := true;
          data_length_g : natural := 16;
          display_g     : boolean := true
         );
end entity;

architecture tb of psi_fix_mov_avg_var_tb is
  --internals
  constant UNSIGNED_FORMAT_c                : psi_fix_fmt_t                        := (0, 1, 15);
  constant SIGNED_FORMAT_c                  : psi_fix_fmt_t                        := (1, 1, 14);
  
  constant freq_clk_c : real                                         := 100.0E6;
  constant period_c   : time                                         := (1 sec) / freq_clk_c;
  constant max_avg_g : positive := 512;
  constant rst_pol_g : std_logic  := '1';  
  signal clk_sti      : std_logic                                    := '0';
  signal rst_sti      : std_logic                                    := '0';
  signal tb_run_s       : boolean                                      := true;
  signal dat_sti      : std_logic_vector(data_length_g - 1 downto 0) := (others => '0');
  signal dat_o        : std_logic_vector(data_length_g - 1 downto 0) := (others => '0');
  signal sample_sti   : std_logic_vector(data_length_g - 1 downto 0) := to_uslv(integer(real(sample_g)),data_length_g);
  signal fract_sti    : std_logic_vector(data_length_g - 1 downto 0) := to_uslv(integer(2.0**(data_length_g-1)/real(sample_g)),data_length_g);
  signal str_obs      : std_logic;
  signal min_obs      : std_logic_vector(data_length_g - 1 downto 0);
  signal max_obs      : std_logic_vector(data_length_g - 1 downto 0);
  --helpers
  signal avrg_exp_s   : integer                                      := 0;
  signal avrg_s       : integer                                      := 0;
  signal sync_s       : std_logic                                    := '0';
  signal sync_dff_s   : std_logic;
  signal min_s        : std_logic_vector(data_length_g - 1 downto 0) := (others => '0');
  signal max_s        : std_logic_vector(data_length_g - 1 downto 0) := (others => '0');
  signal taps_i        : std_logic_vector(log2ceil(max_avg_g) - 1 downto 0) := (others => '0');
  signal taps_n       : natural range 0 to max_avg_g-1;
  signal counter_s    : integer :=0;
  signal vld_i : std_logic;
  signal sample_i : std_logic_vector(log2ceil(max_avg_g)-1 downto 0);
  signal sample_t : integer;
  signal gain_i : std_logic_vector(data_length_g - 1 downto 0);
  --signal dat_i : std_logic_vector(data_width_g - 1 downto 0);
  signal vld_o : std_logic;
  signal sum_o : std_logic_vector(data_length_g+log2ceil(max_avg_g) - 1 downto 0);
  signal avg_o : std_logic_vector(data_length_g - 1 downto 0);

begin
  assert data_length_g < 32 report "[ERROR]: for this test bench only data length less than 32 are authorized" severity failure;
  --*** Reset generation ***
  proc_rst : process
  begin
    rst_sti <= '1';
    wait for 3 * period_c;
    wait until rising_edge(clk_sti);
    wait until rising_edge(clk_sti);
    rst_sti <= '0';
    wait;
  end process;

  --*** strobe generation ***
  proc_irq : process
  begin
    while tb_run_s loop
      GenerateStrobe(freq_clock => freq_clk_c,
                     freq_str   => freq_clk_c / real(clock_cycle_g),
                     rst_pol_g  => '1',
                     rst        => rst_sti,
                     clk        => clk_sti,
                     str        => sync_s);
    end loop;
    wait;
  end process;

  --*** clock process ***
  proc_clk : process
    variable tStop_v : time;
  begin
    while tb_run_s or (now < tStop_v + 1 us) loop
      if tb_run_s then
        tStop_v := now;
      end if;
      wait for 0.5 * period_c;
      clk_sti <= not clk_sti;
      wait for 0.5 * period_c;
      clk_sti <= not clk_sti;
    end loop;
    wait;
  end process;

  --*** DUT ***
  inst_dut : entity work.psi_fix_mov_avg_var
    generic map(
      in_fmt_g   => SIGNED_FORMAT_c,
      max_taps_g => max_avg_g
    )
    port map(
      clk_i  => clk_sti,
      rst_i  => rst_sti,
      taps_i => taps_i,
      gain_i => gain_i,
      vld_i  => vld_i,
      dat_i  => dat_sti,
      vld_o  => vld_o,
      dat_o  => dat_o
    );
  

  process(clk_sti)
    variable seed1_v : positive := 1;
    variable seed2_v : positive := 3;
    variable rand_v  : real     := 0.0;
  begin
    if rising_edge(clk_sti) then
      gain_i <= std_logic_vector(to_unsigned(natural(65535/(taps_n + 1)), data_length_g));
      taps_i <= to_sslv(taps_n, 9);

      if rst_sti = '1' then
        counter_s <= -40;
      else
        vld_i <= sync_s;
        if sync_s = '1' then
          counter_s <= counter_s + 2;
        end if;
      end if;
    end if;
  end process;
  
  gene_sign : if signed_data_g generate
  dat_sti <= to_sslv(counter_s,data_length_g);
  end generate;

 gene_usign : if not signed_data_g generate
  dat_sti <= to_uslv(counter_s,data_length_g);
  end generate;

  proc_stim_kw : process
  begin
    wait for 3*period_c;
    sample_t <= 2;
    for i in 0 to sample_g - 1 loop
      wait until rising_edge(clk_sti);
      sample_t <= sample_t + 1;
    end loop;
  end process;
  
  --*** stim process ***
  proc_stim : process
    variable v_s : integer;
  begin
    ------------------------------------------------------------
    print(" *************************************************  ");
    print(" **       Paul Scherrer Institut                **  ");
    print(" **    psi_fix_mov_avg_var_tb TestBench         **  ");
    print(" *************************************************  ");
    ------------------------------------------------------------
    wait for 5*period_c;

    print("[INFO]: ************************************"); 
    print("[INFO]: ***       Test N=1               ***"); 
    taps_n <= 0;
    
    --for i in 0 to 9 loop
    while counter_s <= -20 loop
      wait until rising_edge(clk_sti);
      if vld_o = '1' then
        --sample_t <= std_logic_vector(to_uslv(i, sample_t'length));
        if display_g then
          if signed_data_g then
            IntCompare(from_sslv(dat_sti), from_sslv(dat_o), "Invalid output value");
          else
            IntCompare(from_uslv(dat_sti), from_uslv(dat_o), "Invalid output value");
          end if;
        end if;
      end if;
    end loop;

    print("[INFO]: ************************************"); 
    print("[INFO]: ***       Test N=2               ***"); 
    taps_n <= 1;
    while counter_s <= 10 loop
      wait until rising_edge(clk_sti);
      if vld_o = '1' then
        --sample_t <= std_logic_vector(to_uslv(i, sample_t'length));
        if display_g then
          if signed_data_g then
            v_s := from_sslv(dat_sti);
            if v_s > -8 then
              IntCompare(v_s-1, from_sslv(dat_o), "Invalid output value");
            end if;
          else
            v_s := from_uslv(dat_sti);
            if v_s > -8 then
              IntCompare(v_s-1, from_uslv(dat_o), "Invalid output value");
            end if;
          end if;
        end if;
      end if;
    end loop;

    print("[INFO]: ************************************"); 
    print("[INFO]: ***       Test N=4               ***"); 
    taps_n <= 3;
    
    while counter_s <= 20 loop
      wait until rising_edge(clk_sti);
      if vld_o = '1' then
        --sample_t <= std_logic_vector(to_uslv(i, sample_t'length));
        if display_g then
          if signed_data_g then
            v_s := from_sslv(dat_sti);
            IntCompare(v_s-3, from_sslv(dat_o), "Invalid output value");
          else
            v_s := from_uslv(dat_sti);
            if v_s > 82 then
              IntCompare(v_s-3, from_uslv(dat_o), "Invalid output value");
            end if;
          end if;
        end if;
      end if;
    end loop;

    print("[INFO]: ************************************"); 
    print("[INFO]: ***       End of simulation      ***"); 
    tb_run_s <= false;
    wait;
  end process;

end architecture;
