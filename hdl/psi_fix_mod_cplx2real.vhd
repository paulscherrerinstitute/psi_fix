------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Benoit Stef
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity is a simple modulator with complex input and real output. It
-- modulates the signal with a specific ratio given comared to its clock
-- it automatically computes sin(w) cos(w) where w=2pi/ratio.Fclk.t
-- and perform the following computation RF = I.sin(w)+Q.cos(w)
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.psi_common_math_pkg.all;
use work.psi_fix_pkg.all;
--@formatter:off
-- $$ processes=stim,check $$
entity psi_fix_mod_cplx2real is
  generic(rst_pol_g   : std_logic            := '1';           -- reset polarity $$ constant = '1' $$
          pl_stages_g : integer range 5 to 6 := 5;             -- select the pipelines stages required
          inp_fmt_g   : psi_fix_fmt_t        := (1, 1, 15);    -- input format FP $$ constant=(1,1,15) $$
          coef_fmt_g  : psi_fix_fmt_t        := (1, 1, 15);    -- coef format $$ constant=(1,1,15) $$
          int_fmt_g   : psi_fix_fmt_t        := (1, 1, 15);    -- internal format computation $$ constant=(1,1,15) $$
          out_fmt_g   : psi_fix_fmt_t        := (1, 1, 15);    -- output format FP $$ constant=(1,1,15) $$
          ratio_g    : natural              := 5              -- ratio for deciamtion $$ constant=5 $$
         );
  port(
    clk_i     : in  std_logic;                                         -- $$ type=clk; freq=100e6 $$
    rst_i     : in  std_logic;                                         -- $$ type=rst; clk=clk_i $$
    dat_inp_i : in  std_logic_vector(psi_fix_size(inp_fmt_g)-1 downto 0); -- in-phase    data
    dat_qua_i : in  std_logic_vector(psi_fix_size(inp_fmt_g)-1 downto 0); -- quadrature data
    vld_i     : in  std_logic;                                         -- valid input frequency sampling
    dat_o     : out std_logic_vector(psi_fix_size(out_fmt_g)-1 downto 0); -- data output IF/RF
    vld_o     : out std_logic                                          -- valid output frequency sampling
  );
end entity;
--@formatter:on
architecture rtl of psi_fix_mod_cplx2real is

  type coef_array_t is array (0 to ratio_g - 1) of std_logic_vector(psi_fix_size(coef_fmt_g) - 1 downto 0);
  constant coef_scale_c : real := 1.0 - 1.0 / 2.0**(real(coef_fmt_g.F)); -- prevent +/- 1.0 -
  ------------------------------------------------------------------------------
  --Sin coef function <=> Q coef n = (cos(nx2pi/Ratio))
  ------------------------------------------------------------------------------

  function coef_sin_array_func return coef_array_t is
    variable array_v : coef_array_t;
  begin
    for i in 0 to ratio_g - 1 loop
      array_v(i) := psi_fix_from_real(sin(2.0 * MATH_PI * real(i) / real(ratio_g)) * coef_scale_c, coef_fmt_g);
    end loop;
    return array_v;
  end function;

  ------------------------------------------------------------------------------
  --COS coef function <=> Q coef n = (cos(nx2pi/Ratio))
  ------------------------------------------------------------------------------
  function coef_cos_array_func return coef_array_t is
    variable array_v : coef_array_t;
  begin
    for i in 0 to ratio_g - 1 loop
      array_v(i) := psi_fix_from_real(cos(2.0 * MATH_PI * real(i) / real(ratio_g)) * coef_scale_c, coef_fmt_g);
    end loop;
    return array_v;
  end function;

  -------------------------------------------------------------------------------
  constant MultFmt_c                            : psi_fix_fmt_t  := (1, inp_fmt_g.I + coef_fmt_g.I + 1, coef_fmt_g.F + inp_fmt_g.F);
  constant AddFmt_c                             : psi_fix_fmt_t  := (1, int_fmt_g.I + 1, int_fmt_g.F);
  --Definitin within the above package
  constant table_sin                            : coef_array_t := coef_sin_array_func;
  constant table_cos                            : coef_array_t := coef_cos_array_func;
  -------------------------------------------------------------------------------
  signal sin_s                                  : std_logic_vector(psi_fix_size(coef_fmt_g) - 1 downto 0);
  signal sin1_s                                 : std_logic_vector(psi_fix_size(coef_fmt_g) - 1 downto 0);
  signal cos_s                                  : std_logic_vector(psi_fix_size(coef_fmt_g) - 1 downto 0);
  signal cos1_s                                 : std_logic_vector(psi_fix_size(coef_fmt_g) - 1 downto 0);
  signal mult_i_s                               : std_logic_vector(psi_fix_size(MultFmt_c) - 1 downto 0);
  signal mult_i_dff_s                           : std_logic_vector(psi_fix_size(int_fmt_g) - 1 downto 0);
  signal mult_q_s                               : std_logic_vector(psi_fix_size(MultFmt_c) - 1 downto 0);
  signal mult_q_dff_s                           : std_logic_vector(psi_fix_size(int_fmt_g) - 1 downto 0);
  signal sum_s                                  : std_logic_vector(psi_fix_size(AddFmt_c) - 1 downto 0);
  --xilinx constraint
  attribute rom_style                           : string;
  attribute rom_style of table_sin : constant is "block";
  attribute rom_style of table_cos : constant is "block";
  -------------------------------------------------------------------------------
  --signal cos_dff_s                      : std_logic_vector(psi_fix_size(coef_fmt_g) - 1 downto 0);
  --signal sin_dff_s                      : std_logic_vector(psi_fix_size(coef_fmt_g) - 1 downto 0);
  signal str1_s, str2_s, str3_s, str4_s, str5_s : std_logic;

  --uncomment for debugging
  --signal dbg_multi_s, dbg_multq_s       : real:=0.0;
  --signal dbg_cos_s, dbg_sin_s           : real:=0.0;
  signal datInp_s  : std_logic_vector(psi_fix_size(inp_fmt_g) - 1 downto 0);
  signal datInp1_s : std_logic_vector(psi_fix_size(inp_fmt_g) - 1 downto 0);
  signal datQua_s  : std_logic_vector(psi_fix_size(inp_fmt_g) - 1 downto 0);
  signal datQua1_s : std_logic_vector(psi_fix_size(inp_fmt_g) - 1 downto 0);

begin
  ------------------------------------------------
  --dbg_cos_s   <= psi_fix_to_real(cos_s, coef_fmt_g);
  --dbg_sin_s   <= psi_fix_to_real(sin_s, coef_fmt_g);
  ------------------------------------------------
  --dbg_multi_s <= psi_fix_to_real(mult_i_s, MultFmt_c);
  --dbg_multq_s <= psi_fix_to_real(mult_q_s, MultFmt_c);

  -------------------------------------------------------------------------------
  -- simple ROM pointer for both array
  -------------------------------------------------------------------------------
  proc_add_coef : process(clk_i)
    variable cpt_v : integer range 0 to ratio_g := 0;
  begin
    if rising_edge(clk_i) then
      if rst_i = rst_pol_g then
        cpt_v := 0;
      else
        if vld_i = '1' then
          if cpt_v < ratio_g - 1 then
            cpt_v := cpt_v + 1;
          else
            cpt_v := 0;
          end if;
        end if;
      end if;
    end if;
    sin_s <= table_sin(cpt_v);          --TODO perhaps add dff stage to help timing
    cos_s <= table_cos(cpt_v);          --TODO perhaps add dff stage to help timing
  end process;

  -------------------------------------------------------------------------------
  -- Multiplier and Adder process
  -------------------------------------------------------------------------------
  proc_dsp : process(clk_i)
  begin
    if rising_edge(clk_i) then

      if rst_i = rst_pol_g then
        vld_o <= '0';
        str1_s <= '0';
        str2_s <= '0';
        str3_s <= '0';
        str4_s <= '0';
        str5_s <= '0';
      else
        -- *** stage 1 ***
        str1_s   <= vld_i;
        datInp_s <= dat_inp_i;
        datQua_s <= dat_qua_i;

        -- *** stage 2 (optional) ***
        sin1_s    <= sin_s;
        cos1_s    <= cos_s;
        str2_s    <= str1_s;
        datInp1_s <= datInp_s;
        datQua1_s <= datQua_s;

        -- *** stage 3 ***
        if pl_stages_g > 5 then
          str3_s   <= str2_s;
          mult_i_s <= psi_fix_mult(sin1_s, coef_fmt_g,
                                 datInp1_s, inp_fmt_g,
                                 MultFmt_c, psi_fix_trunc, psi_fix_wrap);
          mult_q_s <= psi_fix_mult(cos1_s, coef_fmt_g,
                                 datQua1_s, inp_fmt_g,
                                 MultFmt_c, psi_fix_trunc, psi_fix_wrap);
        else
          str3_s   <= str1_s;
          mult_i_s <= psi_fix_mult(sin_s, coef_fmt_g,
                                 datInp_s, inp_fmt_g,
                                 MultFmt_c, psi_fix_trunc, psi_fix_wrap);
          mult_q_s <= psi_fix_mult(cos_s, coef_fmt_g,
                                 datQua_s, inp_fmt_g,
                                 MultFmt_c, psi_fix_trunc, psi_fix_wrap);
        end if;

        -- *** stage 4 ***
        str4_s       <= str3_s;
        mult_i_dff_s <= psi_fix_resize(mult_i_s, MultFmt_c, int_fmt_g, psi_fix_trunc, psi_fix_wrap);
        mult_q_dff_s <= psi_fix_resize(mult_q_s, MultFmt_c, int_fmt_g, psi_fix_trunc, psi_fix_wrap);

        -- *** stage 5 ***
        str5_s <= str4_s;
        sum_s  <= psi_fix_add(mult_i_dff_s, int_fmt_g,
                            mult_q_dff_s, int_fmt_g,
                            AddFmt_c, psi_fix_trunc, psi_fix_wrap);
        -- *** stage 6 ***
        dat_o <= psi_fix_resize(sum_s, AddFmt_c, out_fmt_g, psi_fix_round, psi_fix_sat);
        vld_o <= str5_s;
      end if;
    end if;
  end process;

end architecture;
