------------------------------------------------------------------------------
--  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
--  for more generic block about generating PRBS data output one can use 
--  PSI_COMMON PRBS - seeds can be moved but also length of sequence without
--  FP format though
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.psi_common_array_pkg.all;
use work.psi_common_math_pkg.all;
use work.psi_common_logic_pkg.all;
use work.psi_fix_pkg.all;

entity psi_fix_noise_awgn is
  generic(
    OutFmt_g  : PsiFixFmt_t           := (1, 0, 19);
    Seed_g    : unsigned(31 downto 0) := X"A38E3C1D";
    rst_pol_g : std_logic             := '1'
  );
  port(
    -- Control Signals
    clk_i : in  std_logic;
    rst_i : in  std_logic;
    vld_i : in  std_logic := '1';
    vld_o : out std_logic;
    dat_o : out std_logic_vector(PsiFixSize(OutFmt_g) - 1 downto 0)
  );
end entity;

architecture rtl of psi_fix_noise_awgn is
  -- Constants
  constant OutBits_c : integer     := PsiFixSize(OutFmt_g);
  constant IntFmt_c  : PsiFixFmt_t := (1, 0, 19); -- given by Gaussify approximation
  constant RndFmt_c  : PsiFixFmt_t := (IntFmt_c.S, IntFmt_c.I + 1, OutFmt_g.F);

  -- Two Process Method
  type two_process_r is record
    RndData : std_logic_vector(PsiFixSize(RndFmt_c) - 1 downto 0);
    RndVld  : std_logic;
    OutData : std_logic_vector(PsiFixSize(OutFmt_g) - 1 downto 0);
    OutVld  : std_logic;
  end record;
  signal r, r_next : two_process_r;

  -- Instantiation Signals
  signal White_Data : std_logic_vector(PsiFixSize(IntFmt_c) - 1 downto 0);
  signal White_Vld  : std_logic;
  signal Norm_Data  : std_logic_vector(PsiFixSize(IntFmt_c) - 1 downto 0);
  signal Norm_Vld   : std_logic;

begin
  --------------------------------------------------------------------------
  -- Assertions
  --------------------------------------------------------------------------
  p_assert : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = '0' then
        assert OutFmt_g.S = 1 and OutFmt_g.I = 0 report "###ERROR###: psi_fix_noise_awgn: Output format must be in the form [1,0,x]" severity error;
        assert OutFmt_g.F <= 19 report "###ERROR###: psi_fix_noise_awgn: Maximum number of fractional bits is 19" severity error;
      end if;
    end if;
  end process;

  --------------------------------------------------------------------------
  -- Combinatorial Process
  --------------------------------------------------------------------------
  p_comb : process(r, Norm_Data, Norm_Vld)
    variable v : two_process_r;
  begin
    -- hold variables stable
    v := r;

    -- *** Round ***
    v.RndVld  := Norm_Vld;
    v.RndData := PsiFixResize(Norm_Data, IntFmt_c, RndFmt_c, PsiFixRound, PsiFixWrap); -- Cannot saturate by design

    -- *** Saturate ***
    v.OutVld  := r.RndVld;
    v.OutData := PsiFixResize(r.RndData, RndFmt_c, OutFmt_g, PsiFixTrunc, PsiFixSat); -- Only saturation, rounding already done

    -- Apply to record
    r_next <= v;

  end process;

  dat_o <= r.OutData;
  vld_o <= r.OutVld;

  --------------------------------------------------------------------------
  -- Sequential Process
  --------------------------------------------------------------------------	
  p_seq : process(clk_i)
  begin
    if rising_edge(clk_i) then
      r <= r_next;
      if rst_i = rst_pol_g then
        r.RndVld <= '0';
        r.OutVld <= '0';
      end if;
    end if;
  end process;

  --------------------------------------------------------------------------
  -- Component Instantiation
  --------------------------------------------------------------------------		
  i_white_noise : entity work.psi_fix_white_noise
    generic map(
      rst_pol_g => rst_pol_g,
      OutFmt_g  => IntFmt_c,
      Seed_g    => Seed_g
    )
    port map(
      clk_i => clk_i,
      rst_i => rst_i,
      vld_i => vld_i,
      vld_o => White_Vld,
      dat_o => White_Data
    );

  i_gaussify : entity work.psi_fix_lin_approx_gaussify20b
    generic map(rst_pol_g => rst_pol_g)
    port map(
      clk_i     => clk_i,
      rst_i     => rst_i,
      vld_i   => White_Vld,
      dat_i  => White_Data,
      vld_o  => Norm_Vld,
      dat_o => Norm_Data
    );

end architecture;
