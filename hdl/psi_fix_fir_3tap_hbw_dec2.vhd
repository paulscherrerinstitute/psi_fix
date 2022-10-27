------------------------------------------------------------------------------
--  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Radoslaw Rybaniec
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This component is half bandwidth decimation filter
-- - The number of channels is configurable
-- - All channels are processed in parallel and their data must be synchronized
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.psi_fix_pkg.all;
use work.psi_common_math_pkg.all;
use work.psi_common_array_pkg.all;

-- $$ PROCESSES=Input,Output $$

entity psi_fix_fir_3tap_hbw_dec2 is
  generic(
    in_fmt_g    : psi_fix_fmt_t := (1, 0, 17);                                         -- input format FP
    out_fmt_g   : psi_fix_fmt_t := (1, 0, 17);                                         -- output format FP
    channels_g : natural     := 2;                                                    -- number of channels TDM $$ EXPORT=true $$
    separate_g : boolean     := true;                                                 -- $$ EXPORT=true $$
    rnd_g      : psi_fix_rnd_t := psi_fix_round;                                        -- Round or trunc
    sat_g      : psi_fix_sat_t := psi_fix_sat;                                          -- saturation or wrap
    rst_pol_g  : std_logic   := '1';                                                  -- reset polarity active high ='1'
    rst_sync_g : boolean     := true                                                  -- async reset or sync architecture
  );
  port(
    clk_i : in  std_logic;                                                            -- clk system $$ TYPE=CLK; FREQ=100e6; Proc=Input $$
    rst_i : in  std_logic;                                                            -- rst system $$ TYPE=RST; CLK=Clk $$   
    dat_i : in  std_logic_vector(psi_fix_size(in_fmt_g) * 2 * channels_g - 1 downto 0);  -- data input                     $$ PROC=Input $$
    vld_i : in  std_logic;                                                            -- valid input Frequency sampling $$ PROC=Input $$
    dat_o : out std_logic_vector(psi_fix_size(out_fmt_g) * channels_g - 1 downto 0);     -- data output  $$ PROC=Output $$    
    vld_o : out std_logic                                                             -- valid otuput $$ PROC=Output $$
  );
end entity;

architecture rtl of psi_fix_fir_3tap_hbw_dec2 is

  -- Constants
  constant Shifts_c : t_ainteger  := (2, 1, 2);
  constant IntFmt_c : psi_fix_fmt_t := (in_fmt_g.S, in_fmt_g.I, in_fmt_g.F + 2);

  -- types
  type InData_t is array (0 to 2 * channels_g - 1) of std_logic_vector(psi_fix_size(in_fmt_g) - 1 downto 0);
  type In3_t is array (0 to 3 * channels_g - 1) of std_logic_vector(psi_fix_size(in_fmt_g) - 1 downto 0);
  type Mult_t is array (0 to 3 * channels_g - 1) of std_logic_vector(psi_fix_size(IntFmt_c) - 1 downto 0);
  type Add_t is array (0 to 2 * channels_g - 1) of std_logic_vector(psi_fix_size(IntFmt_c) - 1 downto 0);
  type OutData_t is array (0 to channels_g - 1) of std_logic_vector(psi_fix_size(out_fmt_g) - 1 downto 0);

  -- Two process method
  type two_process_r is record
    Vld     : std_logic_vector(0 to 3);
    InData  : InData_t;
    In3Sig  : In3_t;
    MultSig : Mult_t;
    AddSig  : Add_t;
    AddSigZ : Add_t;
    OutSig  : OutData_t;
  end record;
  signal r, r_next : two_process_r;

  signal InDataS : InData_t;

begin
  --------------------------------------------
  -- Input Transformation
  --------------------------------------------
  process(dat_i) is
  begin
    for i in 0 to 2 * channels_g - 1 loop
      InDataS(i) <= dat_i(psi_fix_size(in_fmt_g) * (i + 1) - 1 downto psi_fix_size(in_fmt_g) * i);
    end loop;
  end process;

  --------------------------------------------
  -- Combinatorial Process
  --------------------------------------------
  p_comb : process(r, vld_i, InDataS)
    variable v : two_process_r;
  begin
    -- *** Hold variables stable ***
    v := r;

    -- *** Pipe Handling ***
    v.Vld(v.Vld'low + 1 to v.Vld'high) := r.Vld(r.Vld'low to r.Vld'high - 1);

    -- *** Stage 0 ***
    -- Input Registers
    v.Vld(0) := vld_i;

    if vld_i = '1' then
      v.InData := InDataS;
      if separate_g then
        for v_i in 0 to inDataS'high / 2 loop
          -- first input
          v.in3Sig(v_i)                  := r.InData(v_i * 2 + 1);
          -- second input
          v.in3Sig(v_i + 1 * channels_g) := InDataS(v_i * 2);
          -- third input
          v.in3Sig(v_i + 2 * channels_g) := InDataS(v_i * 2 + 1);
        end loop;
      else
        v.in3Sig(0) := r.InData(r.InData'high);
        for v_i in 1 to inDataS'high / 2 loop
          -- first input
          v.in3Sig(v_i) := InDataS(2 * v_i - 1);
        end loop;
        for v_i in 0 to inDataS'high / 2 loop
          -- second input
          v.in3Sig(v_i + 1 * channels_g) := InDataS(2 * v_i);
          -- third input
          v.in3Sig(v_i + 2 * channels_g) := InDataS(2 * v_i + 1);
        end loop;
      end if;
    end if;

    -- *** Stage 1 ***
    -- Multiply (shift)
    for v_i in r.MultSig'range loop
      v.MultSig(v_i) := psi_fix_shift_right(r.in3Sig(v_i), in_fmt_g, Shifts_c(v_i / channels_g), 2, IntFmt_c, rnd_g, sat_g);
    end loop;

    -- *** Stage 2 ***
    -- First Addition
    for v_i in 0 to channels_g - 1 loop
      v.AddSig(v_i)  := psi_fix_add(r.MultSig(v_i), IntFmt_c, r.MultSig(v_i + channels_g), IntFmt_c, IntFmt_c, rnd_g, sat_g);
      v.AddSigZ(v_i) := r.MultSig(v_i + 2 * channels_g);
    end loop;
    -- *** Stage 3 ***
    -- Second Addition
    for v_i in r.OutSig'range loop
      v.OutSig(v_i) := psi_fix_add(r.AddSig(v_i), IntFmt_c, r.AddSigZ(v_i), IntFmt_c, out_fmt_g, rnd_g, sat_g);
    end loop;

    -- *** Output Assignment ***
    for i in 0 to channels_g - 1 loop
      dat_o(psi_fix_size(out_fmt_g) * (i + 1) - 1 downto psi_fix_size(out_fmt_g) * i) <= r.OutSig(i);
    end loop;

    vld_o <= r.Vld(r.Vld'high);

    -- *** Assign to signal ***
    r_next <= v;
  end process;

  --------------------------------------------
  -- Sequential Process
  --------------------------------------------
  sync_rst_gene : if rst_sync_g generate
    begin
      p_seq : process(clk_i)
      begin
        if rising_edge(clk_i) then
          r <= r_next;
          if rst_i = rst_pol_g then
            r.Vld <= (others => '0');
          end if;
        end if;
      end process;
   end generate;

  async_rst_gene : if not rst_sync_g generate
    begin
      p_seq : process(clk_i, rst_i)
      begin
         if rst_i = rst_pol_g then
            r.Vld <= (others => '0'); 
        elsif rising_edge(clk_i) then
          r <= r_next;
        end if;
      end process;
   end generate;
   
end architecture;
