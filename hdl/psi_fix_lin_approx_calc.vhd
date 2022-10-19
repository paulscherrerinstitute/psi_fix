------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This component calculateas a linear approximation. It should only be used
-- together with tables generated from python (there is a code generator).

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.psi_fix_pkg.all;
use work.psi_common_math_pkg.all;

entity psi_fix_lin_approx_calc is
  generic(
    InFmt_g     : PsiFixFmt_t := (1, 0, 17);
    OutFmt_g    : PsiFixFmt_t := (1, 0, 17);
    OffsFmt_g   : PsiFixFmt_t := (1, 0, 17);
    GradFmt_g   : PsiFixFmt_t := (1, 0, 17);
    TableSize_g : natural     := 1024;
    rst_pol_g   : std_logic   := '1'
  );
  port(
    -- Control Signals
    clk_i        : in  std_logic;
    rst_i        : in  std_logic;
    -- Input
    vld_i        : in  std_logic;
    dat_i        : in  std_logic_vector(PsiFixSize(InFmt_g) - 1 downto 0);
    -- Output
    vld_o        : out std_logic;
    dat_o        : out std_logic_vector(PsiFixSize(OutFmt_g) - 1 downto 0);
    -- Table Interface
    addr_table_o : out std_logic_vector(log2ceil(TableSize_g) - 1 downto 0);
    data_table_i : in  std_logic_vector(PsiFixSize(OffsFmt_g) + PsiFixSize(GradFmt_g) - 1 downto 0)
  );
end entity;

architecture rtl of psi_fix_lin_approx_calc is

  -- Constants
  constant IndexBits_c    : integer     := log2ceil(TableSize_g);
  constant OffsetBits_c   : integer     := PsiFixSize(InFmt_g) - IndexBits_c;
  constant RemFmt_c       : PsiFixFmt_t := (0, OffsetBits_c - InFmt_g.F, InFmt_g.F);
  constant RemFmtSigned_c : PsiFixFmt_t := (1, RemFmt_c.I - 1, RemFmt_c.F);
  constant IdxFmt_c       : PsiFixFmt_t := (0, InFmt_g.S + InFmt_g.I, InFmt_g.F - RemFmt_c.F - RemFmt_c.I);
  constant IntFmt_c       : PsiFixFmt_t := (1, RemFmt_c.I + GradFmt_g.I + 1, RemFmt_c.F + GradFmt_g.F);
  constant AddFmt_c       : PsiFixFmt_t := (max(IntFmt_c.S, OffsFmt_g.S), max(IntFmt_c.I, OffsFmt_g.I) + 1, max(IntFmt_c.F, OffsFmt_g.F));

  subtype OffsRng_c is natural range PsiFixSize(OffsFmt_g) - 1 downto 0;
  subtype GradRng_c is natural range PsiFixSize(GradFmt_g) + OffsRng_c'high downto OffsRng_c'high + 1;

  -- types
  type Rem_t is array (natural range <>) of std_logic_vector(PsiFixSize(RemFmt_c) - 1 downto 0);
  type Offs_t is array (natural range <>) of std_logic_vector(PsiFixSize(OffsFmt_g) - 1 downto 0);

  -- Two process method
  type two_process_r is record
    Vld       : std_logic_vector(0 to 6);
    In_0      : std_logic_vector(PsiFixSize(InFmt_g) - 1 downto 0);
    TblIdx_1  : std_logic_vector(PsiFixSize(IdxFmt_c) - 1 downto 0);
    Offs      : Offs_t(3 to 4);
    Grad_3    : std_logic_vector(PsiFixSize(GradFmt_g) - 1 downto 0);
    Reminder  : Rem_t(1 to 3);
    GradVal_4 : std_logic_vector(PsiFixSize(IntFmt_c) - 1 downto 0);
    Add_5     : std_logic_vector(PsiFixSize(AddFmt_c) - 1 downto 0);
    Out_6     : std_logic_vector(PsiFixSize(OutFmt_g) - 1 downto 0);
  end record;
  signal r, r_next : two_process_r;

begin
  --------------------------------------------
  -- Combinatorial Process
  --------------------------------------------
  p_comb : process(r, vld_i, dat_i, data_table_i)
    variable v : two_process_r;
  begin
    -- *** Hold variables stable ***
    v := r;

    -- *** Pipe Handling ***
    v.Vld(v.Vld'low + 1 to v.Vld'high)                := r.Vld(r.Vld'low to r.Vld'high - 1);
    v.Reminder(v.Reminder'low + 1 to v.Reminder'high) := r.Reminder(r.Reminder'low to r.Reminder'high - 1);
    v.Offs(v.Offs'low + 1 to v.Offs'high)             := r.Offs(r.Offs'low to r.Offs'high - 1);

    -- *** Stage 0 ***
    -- Input Registers
    v.Vld(0) := vld_i;
    v.In_0   := dat_i;

    -- *** Stage 1 ***
    -- Index Calculation
    v.TblIdx_1                        := PsiFixResize(r.In_0, InFmt_g, IdxFmt_c);
    v.Reminder(1)                     := PsiFixResize(r.In_0, InFmt_g, RemFmt_c);
    -- Inverts MSB to have a signed offset
    v.Reminder(1)(v.Reminder(1)'high) := not v.Reminder(1)(v.Reminder(1)'high);

    -- *** Stage 2 ***
    -- Reserved for Table output registers

    -- *** Stage 3 ***
    -- Registering of Table outputs
    v.Offs(3) := data_table_i(OffsRng_c);
    v.Grad_3  := data_table_i(GradRng_c);

    -- *** Stage 4 ***
    -- Multiplication
    v.GradVal_4 := PsiFixMult(r.Grad_3, GradFmt_g,
                              r.Reminder(3), RemFmtSigned_c, -- Reinterpret as signed, equal to python MSB inversion
                              IntFmt_c);

    -- *** Stage 5 ***
    -- Addition (at full precision and without round/sat to fit into DSP slie)
    v.Add_5 := PsiFixAdd(r.Offs(4), OffsFmt_g,
                         r.GradVal_4, IntFmt_c,
                         AddFmt_c, PsiFixTrunc, PsiFixWrap);

    -- *** Stage 6 ***
    -- Output rounding and saturation
    v.Out_6 := PsiFixResize(r.Add_5, AddFmt_c,
                            OutFmt_g, PsiFixRound, PsiFixSat);

    -- *** Outputs ***
    addr_table_o <= r.TblIdx_1;
    vld_o        <= r.Vld(6);
    dat_o        <= r.Out_6;

    -- *** Assign to signal ***
    r_next <= v;
  end process;

  --------------------------------------------
  -- Sequential Process
  --------------------------------------------
  p_seq : process(clk_i)
  begin
    if rising_edge(clk_i) then
      r <= r_next;
      if rst_i = rst_pol_g then
        r.Vld <= (others => '0');
      end if;
    end if;
  end process;

end architecture;

