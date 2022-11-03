------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Benoit Stef
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- purpose  : smoothing block for pre-correction error
-- scalable generically (wd) / real coef parameter
--                    ____
--  ______  X  _ + ___|dff|___________
--               |    |___|       |
--               |_________ X ____|
--
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
-- @formatter:off
use work.psi_fix_pkg.all;
-- $$ processes=stimuli,check $$
entity psi_fix_lowpass_iir_order1 is
  generic(
    f_sample_hz_g     : real        := 10_000_000.0;                  -- $$constant=100.0e6$$
    f_cutoff_hz_g     : real        := 30_000.0;                      -- $$constant=1.0e6$$
    in_fmt_g         : psi_fix_fmt_t := (1, 0, 15);                  -- $$constant='(1, 0, 15)'$$
    out_fmt_g        : psi_fix_fmt_t := (1, 0, 15);                  -- $$constant='(1, 0, 14)'$$
    int_fmt_g        : psi_fix_fmt_t := (1, 0, 24);                  -- Number format for calculations, for details see documentation
    coef_fmt_g       : psi_fix_fmt_t := (1, 0, 17);                  -- coef format
    round_g         : psi_fix_rnd_t := psi_fix_round;                 -- round or trunc
    sat_g           : psi_fix_sat_t := psi_fix_sat;                   -- sat or wrap
    pipeline_g      : boolean     := True;                          -- True = Optimize for clock speed, False = Optimize for latency  $$ export=true $$
    reset_polarity_g : std_logic   := '1'                            -- reset polarity active high = '1'
  );
  port(
    clk_i : in  std_logic;                                          -- clock input                  $$ type=clk; freq=100e6 $$
    rst_i : in  std_logic;                                          -- sync. reset                  $$ type=rst; clk=clk_i $$
    dat_i : in  std_logic_vector(psi_fix_size(in_fmt_g) - 1 downto 0); -- data in
    vld_i : in  std_logic;                                          -- input valid signal
    dat_o : out std_logic_vector(psi_fix_size(out_fmt_g) - 1 downto 0);-- data out
    vld_o : out std_logic                                           -- output valid signal
  );
end entity;
-- @formatter:on
architecture rtl of psi_fix_lowpass_iir_order1 is
  --function declaration
  function coef_alpha_func(freq_sampling : real;
                           freq_cut_off  : real) return real is
    variable tau : real;
  begin
    tau := 1.0 / (2.0*MATH_PI*freq_cut_off);
    return exp(-(1.0/freq_sampling)/tau);
  end function;

  --constant computation at compilation process
  constant alpha_raw_c  : real                                                 := coef_alpha_func(f_sample_hz_g, f_cutoff_hz_g);
  constant alpha_c      : std_logic_vector(psi_fix_size(coef_fmt_g) - 1 downto 0) := psi_fix_from_real(alpha_raw_c, coef_fmt_g);
  constant beta_c       : std_logic_vector(psi_fix_size(coef_fmt_g) - 1 downto 0) := psi_fix_from_real(1.0 - alpha_raw_c, coef_fmt_g);
  --internal signals delaration
  signal mulIn, mulInFF : std_logic_vector(psi_fix_size(int_fmt_g) - 1 downto 0);
  signal add            : std_logic_vector(psi_fix_size(int_fmt_g) - 1 downto 0);
  signal fb, fbFF       : std_logic_vector(psi_fix_size(int_fmt_g) - 1 downto 0);
  signal res            : std_logic_vector(psi_fix_size(out_fmt_g) - 1 downto 0);
  signal strb           : std_logic_vector(0 to 3);

begin
  pipe_gene : if pipeline_g  generate
    p_filter : process(clk_i)
    begin
      if rising_edge(clk_i) then
        if rst_i = reset_polarity_g then
          fb   <= (others => '0');
          strb <= (others => '0');
        else
          -- stage 0
          strb(0)              <= vld_i;
          mulIn                <= psi_fix_mult(dat_i, in_fmt_g, beta_c, coef_fmt_g, int_fmt_g, round_g, sat_g);
          -- stage 1
          mulInFF              <= mulIn;
          -- stage 2
          add                  <= psi_fix_add(mulInFF, int_fmt_g, fbFF, int_fmt_g, int_fmt_g, psi_fix_trunc, sat_g);
          -- stage 3
          res                  <= psi_fix_resize(add, int_fmt_g, out_fmt_g, round_g, sat_g);
          if strb(2) = '1' then
            fb <= psi_fix_mult(add, int_fmt_g, alpha_c, coef_fmt_g, int_fmt_g, round_g, sat_g);
          end if;
          -- stage 4
          fbFF                 <= fb;
          -- strobe pipeline
          strb(1 to strb'high) <= strb(0 to strb'high - 1);
        end if;

      end if;
    end process p_filter;
    dat_o <= res;
    vld_o <= strb(3);
  end generate;

  nopipe_gene : if pipeline_g = false generate
    p_filter : process(clk_i)
    begin
      if rising_edge(clk_i) then
        if rst_i = reset_polarity_g then
          fb   <= (others => '0');
          strb <= (others => '0');
        else
          -- stage 0
          strb(0)              <= vld_i;
          mulIn                <= psi_fix_mult(dat_i, in_fmt_g, beta_c, coef_fmt_g, int_fmt_g, round_g, sat_g);
          -- stage 1
          add                  <= psi_fix_add(mulIn, int_fmt_g, fb, int_fmt_g, int_fmt_g, psi_fix_trunc, sat_g);
          -- stage 2
          res                  <= psi_fix_resize(add, int_fmt_g, out_fmt_g, round_g, sat_g);
          if strb(1) = '1' then
            fb <= psi_fix_mult(add, int_fmt_g, alpha_c, coef_fmt_g, int_fmt_g, round_g, sat_g);
          end if;
          -- strobe pipeline
          strb(1 to strb'high) <= strb(0 to strb'high - 1);
        end if;

      end if;
    end process p_filter;
    dat_o <= res;
    vld_o <= strb(2);
  end generate;

end architecture;
