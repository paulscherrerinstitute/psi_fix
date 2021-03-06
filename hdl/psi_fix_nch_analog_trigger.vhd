------------------------------------------------------------------------------
-- Pkg for type definition
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.psi_common_math_pkg.all;
use work.psi_fix_pkg.all;

package psi_fix_nch_analog_trigger_pkg is

constant CH_NUMBER_MAX_c  : natural := 16;
constant SIGNAL_FMT_c     : PsiFixFmt_t:= (1,0,15);

type param_array_t is array (natural range <>) of std_logic_vector(2*PsiFixSize(SIGNAL_FMT_c)-1 downto 0);
type trig_cfg_t is record
  TrgMode   : std_logic_vector(0 downto 0);                     -- Trigger mode (0:Continuous,1:Single) configuration register
  TrgArm    : std_logic;                                        -- Arm/dis--arm the trigger, rising edge sensitive
end record;
constant trig_cfg_rst_c : trig_cfg_t :=((others=>'0'),'0');
  
type param_t is record
   mask_min_ena : std_logic_vector(CH_NUMBER_MAX_c-1 downto 0); --mask min results
   mask_max_ena : std_logic_vector(CH_NUMBER_MAX_c-1 downto 0); --mask max results
   thld         : param_array_t(0 to CH_NUMBER_MAX_c-1);        --thld to set Min/Max window
   trig         : trig_cfg_t;                                   --trigger configuration
  end record;
  constant pm_param_rst_c : param_t := ((others=>'0'),(others=>'0'),(others=>(others=>'0')),trig_cfg_rst_c);

end package;

------------------------------------------------------------------------------
-- Start of HDL Design file
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.psi_common_math_pkg.all;
use work.psi_fix_pkg.all;

-- use pkg def above in this file
use work.psi_fix_nch_analog_trigger_pkg.all;

--@formatter:off
entity psi_fix_nch_analog_trigger is
  generic(latency_g    : natural := 10;
          nb_channel_g : natural := 8;
          fix_fmt_g    : PsiFixFmt_t := SIGNAL_FMT_c);
  port(clk_i       : in  std_logic;                                           --processing clock
       rst_i       : in  std_logic;                                           --Reset  processing '1' <=> active high 
       -- in
       dat_i       : in  std_logic_vector(PsiFixSize(fix_fmt_g) - 1 downto 0);--TDM Data Input
       str_i       : in  std_logic;                                           --TDM Strobe Input
       ext_i       : in  std_logic;                                           --external trigger from ILK for instance
       clr_ext_i   : in  std_logic;                                           --clear from external EVT ILK trigger
       param_i     : in  param_t;                                             --Parameter input (Thd level/trig cfg/mask)
       int_tstp_i  : in std_logic_vector(63 downto 0);                        --Internal TIME STAMP
       cro_tstp_i  : in std_logic_vector(63 downto 0);                        --CROSS TIME STAMP from MGT
       cross_trig_i: in  std_logic;                                           --cross trigger from MGT
       -- out
       tstp_o      : out std_logic_vector(63 downto 0);                       --TIME STAMP out to MS DAQ
       cross_trig_o: out std_logic;                                           --cross trigger out to MGT
       dat_pipe_o  : out std_logic_vector(PsiFixSize(fix_fmt_g)-1 downto 0);  --data in pipelined   for recording
       str_pipe_o  : out std_logic;                                           --strobe in pipleined for recording
       trig_o      : out std_logic;                                           --trigger out
       is_arm_o    : out std_logic);                                          --trigger is armed
end entity;
--@formatter:on

architecture RTL of psi_fix_nch_analog_trigger is
  --*** internal delcaration ***
  constant length_c : integer := PsiFixSize(SIGNAL_FMT_c);
  --=================================================================
  -- TAG resolution function - perhaps add to Library smthg generic 
  function array_2_slv(signal data_i      : in param_array_t;
                       constant ch_number : natural) return std_logic_vector is
    constant width_c : natural := 2 * length_c;
    variable data_v  : std_logic_vector(ch_number * width_c - 1 downto 0);
  begin
    for i in 0 to ch_number - 1 loop
      data_v((i + 1) * width_c - 1 downto i * width_c) := data_i(i);
    end loop;
    return data_v;
  end function;
  
  --=================================================================
  signal param_slv2partdm_dat_s : std_logic_vector(nb_channel_g * 2 * length_c - 1 downto 0);
  signal param_slv2partdm_vld_s : std_logic;
  signal str_dff_s              : std_logic;
  signal param_tdm_thld_s       : std_logic_vector(2 * length_c - 1 downto 0);
  signal param_tdm_vld_s        : std_logic;
  signal data_dff0_s            : std_logic_vector(length_c - 1 downto 0);
  signal data_dff1_s            : std_logic_vector(length_c - 1 downto 0);
  --min max_out
  signal min_s, max_s, str_s    : std_logic;
  --mask ch
  signal min_vector_s           : std_logic_vector(nb_channel_g - 1 downto 0);
  signal min_str_s              : std_logic;
  signal max_vector_s           : std_logic_vector(nb_channel_g - 1 downto 0);
  signal max_str_s              : std_logic;
  signal max_trig_s             : std_logic_vector(nb_channel_g - 1 downto 0);
  signal min_trig_s             : std_logic_vector(nb_channel_g - 1 downto 0);
  signal trig_s                 : std_logic;
  signal ext_trig_s             : std_logic;
  signal cross_trig_s           : std_logic;
  signal trig_o_s : std_logic;
  --
begin

  --=================================================================
  -- TAG inst of cplx mult 
  --=================================================================
  proc_conv_array2slv : process(clk_i)
  begin
    if rising_edge(clk_i) then
      --*** create a big slv to be compatible to further block ***
      param_slv2partdm_dat_s <= array_2_slv(param_i.thld, nb_channel_g);
      --*** edge detect ***
      str_dff_s              <= str_i;
      if str_i = '1' and str_dff_s = '0' then
        param_slv2partdm_vld_s <= '1';
      else
        param_slv2partdm_vld_s <= '0';
      end if;
      --*** delay 2 stages ***
      data_dff0_s            <= dat_i;
      data_dff1_s            <= data_dff0_s;
    end if;
  end process;

  --=================================================================
  -- TAG inst of parallel to TDM for min/max
  -- 2 stages dff delay
  --=================================================================
  inst_par2tdm : entity work.psi_common_par_tdm
    generic map(ChannelCount_g => nb_channel_g,
                ChannelWidth_g => 2 * length_c)
    port map( -- @suppress 
             Clk         => clk_i,
             Rst         => rst_i,
             Parallel    => param_slv2partdm_dat_s,
             ParallelVld => param_slv2partdm_vld_s,
             Tdm         => param_tdm_thld_s,
             TdmVld      => param_tdm_vld_s);

  --=================================================================
  -- TAG inst of parallel to TDM for min/max
  -- 4 stages dff delay
  --=================================================================
  inst_min_max : entity work.psi_fix_comparator
    generic map(fmt_g     => SIGNAL_FMT_c,
                rst_pol_g => '1')
    port map(clk_i     => clk_i,
             rst_i     => rst_i,
             set_min_i => param_tdm_thld_s(length_c - 1 downto 0),
             set_max_i => param_tdm_thld_s(2 * length_c - 1 downto length_c),
             data_i    => data_dff1_s,
             str_i     => param_tdm_vld_s,
             str_o     => str_s,
             min_o     => min_s,
             max_o     => max_s);

  --=================================================================
  -- TAG MASK min and or max with a TDM to parallel for trig gene
  --=================================================================
  inst_tdm_par_min : entity work.psi_common_tdm_par  
    generic map(-- @suppress
                ChannelCount_g => nb_channel_g,
                ChannelWidth_g => 1)
    port map(-- @suppress
             Clk         => clk_i,
             Rst         => rst_i,
             Tdm(0)      => min_s,
             TdmVld      => str_s,
             Parallel    => min_vector_s,
             ParallelVld => min_str_s);

  inst_tdm_par_max : entity work.psi_common_tdm_par 
    generic map(-- @suppress
                ChannelCount_g => nb_channel_g,
                ChannelWidth_g => 1)
    port map(-- @suppress 
             Clk         => clk_i,
             Rst         => rst_i,
             Tdm(0)      => max_s,
             TdmVld      => str_s,
             Parallel    => max_vector_s,
             ParallelVld => max_str_s);

  proc_mask : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if max_str_s = '1' then
        for i in 0 to nb_channel_g - 1 loop
          max_trig_s(i) <= max_vector_s(i) and param_i.mask_max_ena(i);
        end loop;
      end if;

      if min_str_s = '1' then
        for i in 0 to nb_channel_g - 1 loop
          min_trig_s(i) <= min_vector_s(i) and param_i.mask_min_ena(i);
        end loop;
      end if;
      
      -- cross trigger
      if min_trig_s >= to_uslv(1,length_c) or
         max_trig_s >= to_uslv(1,length_c) or ext_trig_s = '1' then
        cross_trig_o <= '1';
      else
        cross_trig_o <= '0';
      end if;
      
      --tspt out
      if cross_trig_s = '1' then
        tstp_o <= cro_tstp_i;
      else
        tstp_o <= int_tstp_i;
      end if;
      
      -- internal trigger
      if min_trig_s >= to_uslv(1,length_c) or  max_trig_s >= to_uslv(1,length_c)  or
         ext_trig_s = '1' or cross_trig_s = '1' then
        trig_s <= '1';
      else
        trig_s <= '0';
      end if;
    end if; 
  end process;
  
  --=================================================================
  ext_trig : block
    signal ext_dff_s : std_logic;
    signal ext_flg_s : std_logic;
  begin
    proc_ext_trig_align : process(clk_i)
    begin
      if rising_edge(clk_i) then
        ext_dff_s <= ext_i;
        --rising_edge_detect
        if ext_dff_s = '0' and ext_i = '1' then
          ext_flg_s <= '1';
        elsif clr_ext_i = '1' then
          ext_flg_s <= '0';
        end if;
        --sync with str
        if max_str_s = '1' or min_str_s ='1' then
          ext_trig_s <= ext_flg_s;
        end if;
        --
        if rst_i = '1' then
          ext_dff_s <= '0';
          ext_flg_s <= '0';
        end if;
      end if;
    end process;
  end block;
  
  --=================================================================
  cross_trig : block
    signal cross_dff_s : std_logic;
    signal cross_flg_s : std_logic;
   

  begin
    proc_ext_trig_align : process(clk_i)
    begin
      if rising_edge(clk_i) then
        cross_dff_s <= cross_trig_i;
        --rising_edge_detect
        if cross_dff_s = '0' and cross_trig_i = '1' then
          cross_flg_s <= '1';
        elsif trig_o_s = '1' then
          cross_flg_s <= '0';
        end if;
        --sync with str
        if max_str_s = '1' or min_str_s ='1' then
         cross_trig_s <= cross_flg_s;
        end if;
        --              
        if rst_i = '1' then
          cross_dff_s <= '0';
          cross_flg_s <= '0';
        end if;
      end if;
    end process;
  end block;
  
  --=================================================================
  -- TAG -> trigger digital from library align data to trigger ^^
  inst_delay_data : entity work.psi_common_multi_pl_stage 
    generic map(Width_g  => length_c,
                UseRdy_g => false,
                Stages_g => latency_g)
    port map(-- @suppress 
             Clk     => clk_i,
             Rst     => rst_i,
             InVld   => str_i,
             InData  => dat_i,
             OutVld  => str_pipe_o,
             OutRdy  => '1',
             OutData => dat_pipe_o);
             
  --=================================================================
  --TAG digital trigger from psi common           
  inst_trig : entity work.psi_common_trigger_digital
   generic map(digital_input_number_g    => 1,
               rst_pol_g                 => '1')
   port map(   InClk                     => clk_i,
               InRst                     => rst_i,
               InTrgModeCfg              => param_i.trig.TrgMode,
               InTrgArmCfg               => param_i.trig.TrgArm,
               InTrgEdgeCfg              => "10",
               InTrgDigitalSourceCfg(0)  => '0',
               InDigitalTrg(0)           => trig_s,
               InExtDisarm               => '0',
               OutTrgIsArmed             => is_arm_o,
               OutTrigger                => trig_o_s);
               
  trig_o <= trig_o_s;
end architecture;
