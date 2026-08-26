------------------------------------------------------------------------------
--  Copyright (c) 2026 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Radoslaw Rybaniec
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- purpose  : smoothing block for pre-correction error
-- scalable generically (wd) / alpha coefficient configurable online
--                    ____
--  ______  X  _ + ___|dff|___________
--               |    |___|       |
--               |_________ X ____|
--
-- Same structure as psi_fix_lowpass_iir_order1 but the alpha coefficient is
-- provided as a runtime input (cfg_alpha_i) instead of being calculated from
-- f_sample_hz_g/f_cutoff_hz_g generics. The coefficient is calculated
-- externally (e.g. in software):
--   tau   = 1/(2*pi*f_cutoff)
--   alpha = exp(-(1/f_sample)/tau) = exp(-2*pi*f_cutoff/f_sample)
-- beta = 1 - alpha is derived internally (saturated, hence alpha = 0 results
-- in beta = 1 - 2^-F instead of exactly 1.0).
-- cfg_alpha_i is given in coef_fmt_g format, valid range [0, 1).
-- Only change cfg_alpha_i quasi-statically (e.g. while in reset or between
-- acquisitions) to avoid inconsistent alpha/beta pairs within the pipeline.
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- @formatter:off
use work.psi_fix_pkg.all;
-- $$ processes=stimuli,check $$
entity psi_fix_lowpass_iir_order1_conf is
  generic(
    in_fmt_g          : psi_fix_fmt_t := (1, 0, 15);                  -- $$constant='(1, 0, 15)'$$
    out_fmt_g         : psi_fix_fmt_t := (1, 0, 15);                  -- $$constant='(1, 0, 14)'$$
    int_fmt_g         : psi_fix_fmt_t := (1, 0, 24);                  -- Number format for calculations, for details see documentation
    coef_fmt_g        : psi_fix_fmt_t := (1, 0, 17);                  -- coef format, alpha valid range [0, 1)
    round_g           : psi_fix_rnd_t := psi_fix_round;               -- round or trunc
    sat_g             : psi_fix_sat_t := psi_fix_sat;                 -- sat or wrap
    pipeline_g        : boolean     := True;                          -- True = Optimize for clock speed, False = Optimize for latency  $$ export=true $$
    reset_polarity_g  : std_logic   := '1'                            -- reset polarity active high = '1'
  );
  port(
    clk_i       : in  std_logic;                                               -- clock input                  $$ type=clk; freq=100e6 $$
    rst_i       : in  std_logic;                                               -- sync. reset                  $$ type=rst; clk=clk_i $$
    cfg_alpha_i : in  std_logic_vector(psi_fix_size(coef_fmt_g) - 1 downto 0); -- alpha coefficient (online configurable), beta = 1 - alpha is derived internally
    dat_i       : in  std_logic_vector(psi_fix_size(in_fmt_g) - 1 downto 0);   -- data in
    vld_i       : in  std_logic;                                               -- input valid signal
    dat_o       : out std_logic_vector(psi_fix_size(out_fmt_g) - 1 downto 0);  -- data out
    vld_o       : out std_logic                                                -- output valid signal
  );
end entity;
-- @formatter:on
architecture rtl of psi_fix_lowpass_iir_order1_conf is
    --format able to represent 1.0 exactly (required for beta = 1 - alpha)
    constant one_fmt_c      : psi_fix_fmt_t                                          := (1, coef_fmt_g.I + 1, coef_fmt_g.F);
    constant one_c          : std_logic_vector(psi_fix_size(one_fmt_c) - 1 downto 0) := psi_fix_from_real(1.0, one_fmt_c);
    --registered configuration signals
    signal   alpha_r        : std_logic_vector(psi_fix_size(coef_fmt_g) - 1 downto 0);
    signal   beta_r         : std_logic_vector(psi_fix_size(coef_fmt_g) - 1 downto 0);
    signal   beta_rr        : std_logic_vector(psi_fix_size(coef_fmt_g) - 1 downto 0);
    --internal signals delaration
    signal   mulIn, mulInFF : std_logic_vector(psi_fix_size(int_fmt_g) - 1 downto 0);
    signal   add            : std_logic_vector(psi_fix_size(int_fmt_g) - 1 downto 0);
    signal   fb, fbFF       : std_logic_vector(psi_fix_size(int_fmt_g) - 1 downto 0);
    signal   res            : std_logic_vector(psi_fix_size(out_fmt_g) - 1 downto 0);
    signal   strb           : std_logic_vector(0 to 3);

begin
    -- register cfg_alpha_i, compute beta_r from registered alpha_r, and register again into beta_rr
    p_cfg_reg : process(clk_i)
    begin
        if rising_edge(clk_i) then
            -- stage 1: capture external input
            alpha_r <= cfg_alpha_i;
            -- stage 2: calculate beta from registered alpha and register output
            beta_r  <= psi_fix_sub(one_c, one_fmt_c, alpha_r, coef_fmt_g, coef_fmt_g, psi_fix_trunc, psi_fix_sat);
            beta_rr <= beta_r;
        end if;
    end process p_cfg_reg;

    pipe_gene : if pipeline_g generate
        p_filter : process(clk_i)
        begin
            if rising_edge(clk_i) then
                if rst_i = reset_polarity_g then
                    fb   <= (others => '0');
                    strb <= (others => '0');
                else
                    -- stage 0
                    strb(0)              <= vld_i;
                    mulIn                <= psi_fix_mult(dat_i, in_fmt_g, beta_rr, coef_fmt_g, int_fmt_g, round_g, sat_g);
                    -- stage 1
                    mulInFF              <= mulIn;
                    -- stage 2
                    add                  <= psi_fix_add(mulInFF, int_fmt_g, fbFF, int_fmt_g, int_fmt_g, psi_fix_trunc, sat_g);
                    -- stage 3
                    res                  <= psi_fix_resize(add, int_fmt_g, out_fmt_g, round_g, sat_g);
                    if strb(2) = '1' then
                        fb <= psi_fix_mult(add, int_fmt_g, alpha_r, coef_fmt_g, int_fmt_g, round_g, sat_g);
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
                    mulIn                <= psi_fix_mult(dat_i, in_fmt_g, beta_rr, coef_fmt_g, int_fmt_g, round_g, sat_g);
                    -- stage 1
                    add                  <= psi_fix_add(mulIn, int_fmt_g, fb, int_fmt_g, int_fmt_g, psi_fix_trunc, sat_g);
                    -- stage 2
                    res                  <= psi_fix_resize(add, int_fmt_g, out_fmt_g, round_g, sat_g);
                    if strb(1) = '1' then
                        fb <= psi_fix_mult(add, int_fmt_g, alpha_r, coef_fmt_g, int_fmt_g, round_g, sat_g);
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
