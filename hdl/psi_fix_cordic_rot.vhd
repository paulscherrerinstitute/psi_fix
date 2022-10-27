------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This component convertes polar coordinates to cartesian coordinates using
-- a vectoring CORDIC kernel. In pipelined mode it requires more logic but
-- can take one input sample every clock cycle. In serial mode it requires
-- N clock cycles but requires less logic.
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.psi_fix_pkg.all;
use work.psi_common_array_pkg.all;
use work.psi_common_math_pkg.all;
-- @formatter:off
-- $$ processes=stim, resp $$
entity psi_fix_cordic_rot is
  generic(
    in_abs_fmt_g    : psi_fix_fmt_t := (0, 0, 15);                              -- Must be unsigned		  $$ constant=(0,0,16) $$
    in_angle_fmt_g  : psi_fix_fmt_t := (0, 0, 15);                              -- Must be unsigned	    $$ constant=(0,0,15) $$
    out_fmt_g      : psi_fix_fmt_t := (1, 2, 16);                              -- Usually signed		    $$ constant=(1,2,16) $$
    internal_fmt_g : psi_fix_fmt_t := (1, 2, 22);                              -- Must be signed		    $$ constant=(1,2,22) $$
    angle_int_fmt_g : psi_fix_fmt_t := (1, -2, 18);                             -- Must be (1, -2, x)	  $$ constant=(1,-2,23) $$
    iterations_g  : natural     := 13;                                        -- iterative required	  $$ constant=21 $$
    gain_comp_g    : boolean     := False;                                     -- gain compensation    $$ export=true $$
    round_g       : psi_fix_rnd_t := psi_fix_trunc;                             -- round or trunc       $$ export=true $$
    sat_g         : psi_fix_sat_t := psi_fix_wrap;                              -- sat or wrap          $$ export=true $$
    mode_g        : string      := "SERIAL"                                   -- PIPELINED or SERIAL	$$ export=true $$
  );
  port(
    -- Control Signals
    clk_i      : in  std_logic;                                               -- clk system $$ type=clk; freq=100e6 $$
    rst_i      : in  std_logic;                                               -- rst system $$ type=rst; clk=Clk $$
    -- Input
    dat_abs_i  : in  std_logic_vector(psi_fix_size(in_abs_fmt_g) - 1 downto 0);   -- amplitude signal input
    dat_ang_i  : in  std_logic_vector(psi_fix_size(in_angle_fmt_g) - 1 downto 0); -- phase signal input
    vld_i      : in  std_logic;                                               -- valid input
    rdy_i      : out std_logic;                                               -- ready output signal $$ lowactive=true $$
    -- Output
    dat_inp_o   : out std_logic_vector(psi_fix_size(out_fmt_g) - 1 downto 0);    -- dat inphase out
    dat_qua_o   : out std_logic_vector(psi_fix_size(out_fmt_g) - 1 downto 0);    -- dat quadrature out    
    vld_o       : out std_logic                                               -- valid output
  );
end entity;
-- @formatter:on

architecture rtl of psi_fix_cordic_rot is

  -- *** Constants ***
  constant AngleTableReal_c : t_areal(0 to 31) := (0.125, 0.0737918088252, 0.0389895651887, 0.0197917120803,
                                                   0.00993426215277, 0.00497197391179, 0.00248659363948, 0.00124337269683,
                                                   0.000621695834357, 0.000310849102962, 0.000155424699705, 7.77123683806e-05,
                                                   3.88561865063e-05, 1.94280935426e-05, 9.71404680751e-06, 4.85702340828e-06,
                                                   2.4285117047e-06, 1.21425585242e-06, 6.0712792622e-07, 3.03563963111e-07,
                                                   1.51781981556e-07, 7.58909907779e-08, 3.7945495389e-08, 1.89727476945e-08,
                                                   9.48637384724e-09, 4.74318692362e-09, 2.37159346181e-09, 1.1857967309e-09,
                                                   5.92898365452e-10, 2.96449182726e-10, 1.48224591363e-10, 7.41122956816e-11);
  type AngleTable_t is array (0 to iterations_g - 1) of std_logic_vector(psi_fix_size(angle_int_fmt_g) - 1 downto 0);

  function AngleTableStdlv return AngleTable_t is
    variable Table : AngleTable_t;
  begin
    for i in 0 to iterations_g - 1 loop
      Table(i) := psi_fix_from_real(AngleTableReal_c(i), angle_int_fmt_g);
    end loop;
    return Table;
  end function;

  constant AngleTable_c : AngleTable_t := AngleTableStdlv;

  function CordicGain(iterations : integer) return real is
    variable g : real := 1.0;
  begin
    for i in 0 to iterations - 1 loop
      g := g * sqrt(1.0 + 2.0**(-2.0 * real(i)));
    end loop;
    return g;
  end function;

  constant GcFmt_c        : psi_fix_fmt_t                                        := (0, 0, 17);
  constant AngleIntExtFmt : psi_fix_fmt_t                                        := (angle_int_fmt_g.S, max(angle_int_fmt_g.I, 1), angle_int_fmt_g.F);
  constant GcCoef_c       : std_logic_vector(psi_fix_size(GcFmt_c) - 1 downto 0) := psi_fix_from_real(1.0 / CordicGain(iterations_g), GcFmt_c);
  constant QuadFmt_c      : psi_fix_fmt_t                                        := (0, 0, 2);

  -- *** Functions ***
  -- Cordic step for X
  function CordicStepX(xLast : std_logic_vector;
                       yLast : std_logic_vector;
                       zLast : std_logic_vector;
                       shift : integer) return std_logic_vector is
    constant yShifted : std_logic_vector := psi_fix_shift_right(yLast, internal_fmt_g, shift, iterations_g - 1, internal_fmt_g, psi_fix_trunc, psi_fix_wrap, true);
  begin

    if signed(zLast) > 0 then
      return psi_fix_sub(xLast, internal_fmt_g,
                       yShifted, internal_fmt_g,
                       internal_fmt_g, psi_fix_trunc, psi_fix_wrap);
    else
      return psi_fix_add(xLast, internal_fmt_g,
                       yShifted, internal_fmt_g,
                       internal_fmt_g, psi_fix_trunc, psi_fix_wrap);

    end if;
  end function;

  -- Cordic step for Y
  function CordicStepY(xLast : std_logic_vector;
                       yLast : std_logic_vector;
                       zLast : std_logic_vector;
                       shift : integer) return std_logic_vector is
    constant xShifted : std_logic_vector := psi_fix_shift_right(xLast, internal_fmt_g, shift, iterations_g - 1, internal_fmt_g, psi_fix_trunc, psi_fix_wrap, true);
  begin

    if signed(zLast) > 0 then
      return psi_fix_add(yLast, internal_fmt_g,
                       xShifted, internal_fmt_g,
                       internal_fmt_g, psi_fix_trunc, psi_fix_wrap);
    else
      return psi_fix_sub(yLast, internal_fmt_g,
                       xShifted, internal_fmt_g,
                       internal_fmt_g, psi_fix_trunc, psi_fix_wrap);
    end if;
  end function;

  -- Cordic step for Z
  function CordicStepZ(zLast     : std_logic_vector;
                       iteration : integer) return std_logic_vector is
    constant Atan_c : std_logic_vector(psi_fix_size(angle_int_fmt_g) - 1 downto 0) := AngleTable_c(iteration);
  begin
    if signed(zLast) > 0 then
      return psi_fix_sub(zLast, angle_int_fmt_g,
                       Atan_c, angle_int_fmt_g,
                       angle_int_fmt_g, psi_fix_trunc, psi_fix_wrap);
    else
      return psi_fix_add(zLast, angle_int_fmt_g,
                       Atan_c, angle_int_fmt_g,
                       angle_int_fmt_g, psi_fix_trunc, psi_fix_wrap);
    end if;
  end function;

  -- Types
  type IntArr_t is array (natural range <>) of std_logic_vector(psi_fix_size(internal_fmt_g) - 1 downto 0);
  type AngArr_t is array (natural range <>) of std_logic_vector(psi_fix_size(angle_int_fmt_g) - 1 downto 0);

begin
  --------------------------------------------
  -- Assertions
  --------------------------------------------
  assert in_angle_fmt_g.S /= 1 report "psi_fix_cordic_rot: in_angle_fmt_g must be unsigned" severity error;
  assert angle_int_fmt_g.S = 1 report "psi_fix_cordic_rot: angle_int_fmt_g must be signed" severity error;
  assert angle_int_fmt_g.I = -2 report "psi_fix_cordic_rot: angle_int_fmt_g must be (1,-2,x)" severity error;
  assert in_abs_fmt_g.S /= 1 report "psi_fix_cordic_rot: in_abs_fmt_g must be unsigned" severity error;
  assert internal_fmt_g.S = 1 report "psi_fix_cordic_rot: internal_fmt_g must be signed" severity error;
  assert mode_g = "PIPELINED" or mode_g = "SERIAL" report "psi_fix_cordic_rot: mode_g must be PIPELINED or SERIAL" severity error;
  assert internal_fmt_g.I > in_abs_fmt_g.I report "psi_fix_cordic_rot: internal_fmt_g must have at least one more bit than in_abs_fmt_g" severity error;

  --------------------------------------------
  -- Pipelined Implementation
  --------------------------------------------	
  g_pipelined : if mode_g = "PIPELINED" generate
    signal X, Y     : IntArr_t(0 to iterations_g);
    signal Z        : AngArr_t(0 to iterations_g);
    signal Vld      : std_logic_vector(0 to iterations_g);
    signal Quad     : t_aslv2(0 to iterations_g);
    signal yQc, xQc : std_logic_vector(psi_fix_size(internal_fmt_g) - 1 downto 0);
    signal QcVld    : std_logic;
  begin
    -- Pipelined implementation can take a sample every clock cycle
    rdy_i <= '1';

    -- Implementation
    p_cordic_pipelined : process(clk_i)
    begin
      if rising_edge(clk_i) then
        if rst_i = '1' then
          Vld    <= (others => '0');
          vld_o <= '0';
          QcVld  <= '0';
        else
          -- Initialization
          X(0)    <= psi_fix_resize(dat_abs_i, in_abs_fmt_g, internal_fmt_g, round_g, sat_g);
          Y(0)    <= (others => '0');
          Z(0)    <= psi_fix_resize(dat_ang_i, in_angle_fmt_g, angle_int_fmt_g, round_g, psi_fix_wrap);
          Quad(0) <= psi_fix_resize(dat_ang_i, in_angle_fmt_g, QuadFmt_c, psi_fix_trunc, psi_fix_wrap);
          Vld(0)  <= vld_i;

          -- Cordic iterations_g
          Vld(1 to Vld'high)   <= Vld(0 to Vld'high - 1);
          Quad(1 to Quad'high) <= Quad(0 to Quad'high - 1);
          for i in 0 to iterations_g - 1 loop
            X(i + 1) <= CordicStepX(X(i), Y(i), Z(i), i);
            Y(i + 1) <= CordicStepY(X(i), Y(i), Z(i), i);
            Z(i + 1) <= CordicStepZ(Z(i), i);
          end loop;

          -- Quadrant Correction
          QcVld <= Vld(iterations_g);
          if (Quad(iterations_g) = "00") or (Quad(iterations_g) = "11") then
            yQc <= Y(iterations_g);
            xQc <= X(iterations_g);
          else
            yQc <= psi_fix_neg(Y(iterations_g), internal_fmt_g, internal_fmt_g, round_g, sat_g);
            xQc <= psi_fix_neg(X(iterations_g), internal_fmt_g, internal_fmt_g, round_g, sat_g);
          end if;

          -- Output 
          vld_o <= QcVld;
          if gain_comp_g then
            dat_inp_o <= psi_fix_mult(xQc, internal_fmt_g, GcCoef_c, GcFmt_c, out_fmt_g, round_g, sat_g);
            dat_qua_o <= psi_fix_mult(yQc, internal_fmt_g, GcCoef_c, GcFmt_c, out_fmt_g, round_g, sat_g);
          else
            dat_inp_o <= psi_fix_resize(xQc, internal_fmt_g, out_fmt_g, round_g, sat_g);
            dat_qua_o <= psi_fix_resize(yQc, internal_fmt_g, out_fmt_g, round_g, sat_g);
          end if;
        end if;
      end if;
    end process;
  end generate;

  --------------------------------------------
  -- Serial Implementation
  --------------------------------------------
  g_serial : if mode_g = "SERIAL" generate
    signal Xin, Yin : std_logic_vector(psi_fix_size(internal_fmt_g) - 1 downto 0);
    signal Zin      : std_logic_vector(psi_fix_size(angle_int_fmt_g) - 1 downto 0);
    signal XinVld   : std_logic;
    signal Quadin   : std_logic_vector(1 downto 0);
    signal X, Y     : std_logic_vector(psi_fix_size(internal_fmt_g) - 1 downto 0);
    signal Z        : std_logic_vector(psi_fix_size(angle_int_fmt_g) - 1 downto 0);
    signal CordVld  : std_logic;
    signal IterCnt  : integer range 0 to iterations_g - 1;
    signal Quad     : std_logic_vector(1 downto 0);
    signal yQc, xQc : std_logic_vector(psi_fix_size(internal_fmt_g) - 1 downto 0);
    signal QcVld    : std_logic;
  begin
    rdy_i <= not XinVld;

    p_cordic_serial : process(clk_i)
    begin
      if rising_edge(clk_i) then
        if rst_i = '1' then
          XinVld  <= '0';
          IterCnt <= 0;
          vld_o  <= '0';
          CordVld <= '0';
        else
          -- Input latching
          if XinVld = '0' and vld_i = '1' then
            XinVld <= '1';
            Xin    <= psi_fix_resize(dat_abs_i, in_abs_fmt_g, internal_fmt_g, round_g, sat_g);
            Yin    <= (others => '0');
            Zin    <= psi_fix_resize(dat_ang_i, in_angle_fmt_g, angle_int_fmt_g, round_g, psi_fix_wrap);
            Quadin <= psi_fix_resize(dat_ang_i, in_angle_fmt_g, QuadFmt_c, psi_fix_trunc, psi_fix_wrap);
          end if;

          -- CORDIC loop
          CordVld <= '0';
          if IterCnt = 0 then
            -- start of calculation
            if XinVld = '1' then
              X       <= CordicStepX(Xin, Yin, Zin, 0);
              Y       <= CordicStepY(Xin, Yin, Zin, 0);
              Quad    <= Quadin;
              Z       <= CordicStepZ(Zin, 0);
              IterCnt <= IterCnt + 1;
              XinVld  <= '0';
            end if;
          else
            -- Normal Calculation Step
            X <= CordicStepX(X, Y, Z, IterCnt);
            Y <= CordicStepY(X, Y, Z, IterCnt);
            Z <= CordicStepZ(Z, IterCnt);

            if IterCnt = iterations_g - 1 then
              IterCnt <= 0;
              CordVld <= '1';
            else
              IterCnt <= IterCnt + 1;
            end if;
          end if;

          -- Quadrant Correction
          QcVld <= CordVld;
          if (Quad = "00") or (Quad = "11") then
            yQc <= Y;
            xQc <= X;
          else
            yQc <= psi_fix_neg(Y, internal_fmt_g, internal_fmt_g, round_g, sat_g);
            xQc <= psi_fix_neg(X, internal_fmt_g, internal_fmt_g, round_g, sat_g);
          end if;

          -- Output 
          vld_o <= QcVld;
          if gain_comp_g then
            dat_inp_o <= psi_fix_mult(xQc, internal_fmt_g, GcCoef_c, GcFmt_c, out_fmt_g, round_g, sat_g);
            dat_qua_o <= psi_fix_mult(yQc, internal_fmt_g, GcCoef_c, GcFmt_c, out_fmt_g, round_g, sat_g);
          else
            dat_inp_o <= psi_fix_resize(xQc, internal_fmt_g, out_fmt_g, round_g, sat_g);
            dat_qua_o <= psi_fix_resize(yQc, internal_fmt_g, out_fmt_g, round_g, sat_g);
          end if;

        end if;
      end if;
    end process;
  end generate;

end architecture;

