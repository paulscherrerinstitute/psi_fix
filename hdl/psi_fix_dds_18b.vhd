------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.psi_common_array_pkg.all;
use work.psi_common_math_pkg.all;
use work.psi_fix_pkg.all;
-- @formatter:off
------------------------------------------------------------------------------
-- Entity
------------------------------------------------------------------------------	
entity psi_fix_dds_18b is
  generic(
    PhaseFmt_g    : PsiFixFmt_t := (0, 0, 31);
    TdmChannels_g : positive    := 1;
    RamBehavior_g : string      := "RBW";
    rst_pol_g     : std_logic   :='1'
  );
  port(
    -- Control Signals
    clk_i        : in  std_logic;
    rst_i        : in  std_logic;
    -- Control Signals
    restart_i    : in  std_logic := '0';
    phi_step_i   : in  std_logic_vector(PsiFixSize(PhaseFmt_g) - 1 downto 0);
    phi_offset_i : in  std_logic_vector(PsiFixSize(PhaseFmt_g) - 1 downto 0);
    -- Input
    vld_i        : in  std_logic := '1';
    -- Output
    vld_o        : out std_logic;
    dat_sin_o    : out std_logic_vector(17 downto 0);
    dat_cos_o    : out std_logic_vector(17 downto 0)
  );
end entity;
-- @formatter:on
------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture rtl of psi_fix_dds_18b is
  -- Constants
  constant SinOutFmt_c : PsiFixFmt_t                                           := (1, 0, 17);
  constant SinInFmt_c  : PsiFixFmt_t                                           := (0, 0, 20);
  constant CosOffs_c   : std_logic_vector(PsiFixSize(PhaseFmt_g) - 1 downto 0) := PsiFixFromReal(0.25, PhaseFmt_g);

  -- Two Process Method
  type two_process_r is record
    VldIn         : std_logic_vector(0 to 9);
    FirstSplCnt_0 : integer range 0 to TdmChannels_g;
    PhaseAccu_0   : std_logic_vector(PsiFixSize(PhaseFmt_g) - 1 downto 0);
    PhaseOffs_0   : std_logic_vector(PsiFixSize(PhaseFmt_g) - 1 downto 0);
    PhaseOffs_1   : std_logic_vector(PsiFixSize(PhaseFmt_g) - 1 downto 0);
    PhaseSin_2    : std_logic_vector(PsiFixSize(SinInFmt_c) - 1 downto 0);
    PhaseCos_2    : std_logic_vector(PsiFixSize(SinInFmt_c) - 1 downto 0);
  end record;
  signal r, r_next : two_process_r;

  -- Component Connection Signals
  signal SinVld, CosVld   : std_logic;
  signal SinData, CosData : std_logic_vector(PsiFixSize(SinOutFmt_c) - 1 downto 0);
  signal PhaseAccu        : std_logic_vector(PsiFixSize(PhaseFmt_g) - 1 downto 0);
  signal PhaseAccu_Next   : std_logic_vector(PsiFixSize(PhaseFmt_g) - 1 downto 0);

begin
  --------------------------------------------------------------------------
  -- Assertions
  --------------------------------------------------------------------------
  p_assert : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = '0' then
        assert SinVld = CosVld report "###ERROR###: psi_fix_dds_18b: SinVld / CosVld mismatch" severity error;
        assert SinVld = r.VldIn(9) report "###ERROR###: psi_fix_dds_18b: SinVld / Pipeline Vld mismatch" severity error;
      end if;
    end if;
  end process;

  --------------------------------------------------------------------------
  -- Combinatorial Process
  --------------------------------------------------------------------------
  p_comb : process(r, vld_i, phi_step_i, phi_offset_i, restart_i, SinData, CosData, PhaseAccu)
    variable v : two_process_r;
  begin
    -- hold variables stable
    v := r;

    -- *** Pipe Handling ***
    v.VldIn(v.VldIn'low + 1 to v.VldIn'high) := r.VldIn(r.VldIn'low to r.VldIn'high - 1);

    -- *** Stage 0 ***
    -- Input Registers
    v.VldIn(0)    := vld_i;
    v.PhaseOffs_0 := phi_offset_i;

    -- Phase accu (count after sample to start at zero)
    if vld_i = '1' then
      -- Phase zero must be output for the first sample after reset, this is achieved by r.FirstSplCnt_0
      if restart_i = '1' or r.FirstSplCnt_0 /= 0 then
        v.PhaseAccu_0 := (others => '0');
      else
        v.PhaseAccu_0 := PsiFixAdd(PhaseAccu, PhaseFmt_g,
                                   phi_step_i, PhaseFmt_g,
                                   PhaseFmt_g);
      end if;
      if r.FirstSplCnt_0 /= 0 then
        v.FirstSplCnt_0 := r.FirstSplCnt_0 - 1;
      end if;
    end if;
    PhaseAccu_Next <= v.PhaseAccu_0;

    -- *** Stage 1 ***
    -- Phase offset 
    v.PhaseOffs_1 := PsiFixAdd(r.PhaseAccu_0, PhaseFmt_g,
                               r.PhaseOffs_0, PhaseFmt_g,
                               PhaseFmt_g);

    -- *** Stage 2 ***
    -- Sine and cosine phase
    v.PhaseSin_2 := PsiFixResize(r.PhaseOffs_1, PhaseFmt_g, SinInFmt_c);
    v.PhaseCos_2 := PsiFixAdd(r.PhaseOffs_1, PhaseFmt_g,
                              CosOffs_c, PhaseFmt_g,
                              SinInFmt_c);

    -- *** Stages 3 - 8 ***
    -- Reserved for Linear approximation		

    -- *** Outputs ***
    vld_o     <= r.VldIn(9);
    dat_sin_o <= SinData;
    dat_cos_o <= CosData;

    -- Apply to record
    r_next <= v;

  end process;

  --------------------------------------------------------------------------
  -- Sequential Process
  --------------------------------------------------------------------------	
  p_seq : process(clk_i)
  begin
    if rising_edge(clk_i) then
      r <= r_next;
      if rst_i = rst_pol_g then
        r.PhaseAccu_0   <= (others => '0');
        r.VldIn         <= (others => '0');
        r.FirstSplCnt_0 <= TdmChannels_g;
      end if;
    end if;
  end process;

  --------------------------------------------------------------------------
  -- Component Instantiation
  --------------------------------------------------------------------------	
  i_sincos : entity work.psi_fix_lin_approx_sin18b_dual
    port map(
      -- Control Signals
      clk_i      => clk_i,
      rst_i      => rst_i,
      -- Input
      vld_a_i   => r.VldIn(2),
      dat_a_i  => r.PhaseSin_2,
      vld_b_i   => r.VldIn(2),
      dat_b_i  => r.PhaseCos_2,
      -- Output
      vld_a_o  => SinVld,
      dat_a_o => SinData,
      vld_b_o  => CosVld,
      dat_b_o => CosData
    );

  i_accu : entity work.psi_common_delay
    generic map(
      Width_g       => PsiFixSize(PhaseFmt_g),
      Delay_g       => TdmChannels_g,
      Resource_g    => "AUTO",
      RstState_g    => true,
      RamBehavior_g => RamBehavior_g
    )
    port map(
      Clk     => clk_i,
      Rst     => rst_i,
      InData  => PhaseAccu_Next,
      InVld   => vld_i,
      OutData => PhaseAccu
    );

end architecture;
