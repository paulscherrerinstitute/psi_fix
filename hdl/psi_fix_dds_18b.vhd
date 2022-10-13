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

library work;
use work.psi_common_array_pkg.all;
use work.psi_common_math_pkg.all;
use work.psi_fix_pkg.all;

------------------------------------------------------------------------------
-- Entity
------------------------------------------------------------------------------	
entity psi_fix_dds_18b is
  generic(
    PhaseFmt_g    : PsiFixFmt_t := (0, 0, 31);
    TdmChannels_g : positive    := 1;
    RamBehavior_g : string      := "RBW"
  );
  port(
    -- Control Signals
    Clk       : in  std_logic;
    Rst       : in  std_logic;
    -- Control Signals
    Restart   : in  std_logic := '0';
    PhaseStep : in  std_logic_vector(PsiFixSize(PhaseFmt_g) - 1 downto 0);
    PhaseOffs : in  std_logic_vector(PsiFixSize(PhaseFmt_g) - 1 downto 0);
    -- Input
    InVld     : in  std_logic := '1';
    -- Output
    OutVld    : out std_logic;
    OutSin    : out std_logic_vector(17 downto 0);
    OutCos    : out std_logic_vector(17 downto 0)
  );
end entity;

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
  p_assert : process(Clk)
  begin
    if rising_edge(Clk) then
      if Rst = '0' then
        assert SinVld = CosVld report "###ERROR###: psi_fix_dds_18b: SinVld / CosVld mismatch" severity error;
        assert SinVld = r.VldIn(9) report "###ERROR###: psi_fix_dds_18b: SinVld / Pipeline Vld mismatch" severity error;
      end if;
    end if;
  end process;

  --------------------------------------------------------------------------
  -- Combinatorial Process
  --------------------------------------------------------------------------
  p_comb : process(r, InVld, PhaseStep, PhaseOffs, Restart, SinData, CosData, PhaseAccu)
    variable v : two_process_r;
  begin
    -- hold variables stable
    v := r;

    -- *** Pipe Handling ***
    v.VldIn(v.VldIn'low + 1 to v.VldIn'high) := r.VldIn(r.VldIn'low to r.VldIn'high - 1);

    -- *** Stage 0 ***
    -- Input Registers
    v.VldIn(0)    := InVld;
    v.PhaseOffs_0 := PhaseOffs;

    -- Phase accu (count after sample to start at zero)
    if InVld = '1' then
      -- Phase zero must be output for the first sample after reset, this is achieved by r.FirstSplCnt_0
      if Restart = '1' or r.FirstSplCnt_0 /= 0 then
        v.PhaseAccu_0 := (others => '0');
      else
        v.PhaseAccu_0 := PsiFixAdd(PhaseAccu, PhaseFmt_g,
                                   PhaseStep, PhaseFmt_g,
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
    OutVld <= r.VldIn(9);
    OutSin <= SinData;
    OutCos <= CosData;

    -- Apply to record
    r_next <= v;

  end process;

  --------------------------------------------------------------------------
  -- Sequential Process
  --------------------------------------------------------------------------	
  p_seq : process(Clk)
  begin
    if rising_edge(Clk) then
      r <= r_next;
      if Rst = '1' then
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
      Clk      => Clk,
      Rst      => Rst,
      -- Input
      InVldA   => r.VldIn(2),
      InDataA  => r.PhaseSin_2,
      InVldB   => r.VldIn(2),
      InDataB  => r.PhaseCos_2,
      -- Output
      OutVldA  => SinVld,
      OutDataA => SinData,
      OutVldB  => CosVld,
      OutDataB => CosData
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
      Clk     => Clk,
      Rst     => Rst,
      InData  => PhaseAccu_Next,
      InVld   => InVld,
      OutData => PhaseAccu
    );

end architecture;
