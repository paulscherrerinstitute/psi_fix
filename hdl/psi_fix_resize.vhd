------------------------------------------------------------------------------
--  Copyright (c) 2020 by Oliver Bründler, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- Pipelined version of PsiFixResize

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.psi_fix_pkg.all;
-- @formatter:off
-- $$ processes=stim, resp $$
entity psi_fix_resize is
  generic(
    InFmt_g   : PsiFixFmt_t := (1, 0, 15);   -- Must be signed		$$ constant=(1,1,14) $$
    OutFmt_g  : PsiFixFmt_t := (0, 2, 16);   -- Must be unsigned		$$ constant=(0,0,8) $$
    Round_g   : PsiFixRnd_t := PsiFixRound;  --						$$ constant=true $$
    Sat_g     : PsiFixSat_t := PsiFixSat;     --						$$ constant=true $$		
    rst_pol_g : std_logic:='1'
  );
  port(
    clk_i : in  std_logic;              -- $$ type=clk; freq=100e6 $$
    rst_i : in  std_logic;              -- $$ type=rst; clk=clk_i $$
    vld_i : in  std_logic;
    rdy_o : out std_logic;              -- $$ lowactive=true $$
    dat_i : in  std_logic_vector(PsiFixSize(InFmt_g) - 1 downto 0);
    vld_o : out std_logic;
    rdy_i : in  std_logic := '1';
    dat_o : out std_logic_vector(PsiFixSize(OutFmt_g) - 1 downto 0)
  );
end entity;
-- @formatter:on
architecture rtl of psi_fix_resize is

  -- Constants
  constant RndFmt_c : PsiFixFmt_t := (InFmt_g.S, InFmt_g.I + 1, OutFmt_g.F); -- Additional bit for rounding up

  -- Two Process Method
  type two_process_r is record
    RndReg : std_logic_vector(PsiFixSize(RndFmt_c) - 1 downto 0);
    RndVld : std_logic;
    SatReg : std_logic_vector(PsiFixSize(OutFmt_g) - 1 downto 0);
    SatVld : std_logic;
  end record;
  signal r, r_next : two_process_r;

  signal SatRdy, RndRdy : std_logic;
begin

  --------------------------------------------------------------------------
  -- Combinatorial Process
  --------------------------------------------------------------------------
  p_comb : process(r, vld_i, dat_i, rdy_i, RndRdy, SatRdy)
    variable v         : two_process_r;
    variable Blocked_v : boolean;
  begin
    -- hold variables stable
    v := r;

    -- Rounding Stage
    RndRdy <= (not r.RndVld) or SatRdy;
    if RndRdy = '1' then
      v.RndVld := vld_i;
      v.RndReg := PsiFixResize(dat_i, InFmt_g, RndFmt_c, Round_g, PsiFixWrap);
    end if;

    -- Saturation Stage
    SatRdy <= not (r.SatVld) or rdy_i;
    if SatRdy = '1' then
      v.SatVld := r.RndVld;
      v.SatReg := PsiFixResize(r.RndReg, RndFmt_c, OutFmt_g, PsiFixTrunc, Sat_g);
    end if;

    -- Apply to signal
    r_next <= v;
    vld_o  <= r.SatVld;
    dat_o  <= r.SatReg;

  end process;

  rdy_o <= RndRdy;

  --------------------------------------------------------------------------
  -- Sequential Process
  --------------------------------------------------------------------------	
  p_seq : process(clk_i)
  begin
    if rising_edge(clk_i) then
      r <= r_next;
      if rst_i = rst_pol_g then
        r.RndVld <= '0';
        r.SatVld <= '0';
      end if;
    end if;
  end process;

end architecture;
