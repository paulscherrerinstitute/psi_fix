------------------------------------------------------------------------------
--  Copyright (c) 2021 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Benoit Stef 
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This block allows generating triggers out of several input signals with fixed 
-- point format and external trigger capability

------------------------------------------------------------------------------
-- RTL HDL file
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.psi_common_math_pkg.all;
use work.psi_fix_pkg.all;
use work.psi_common_array_pkg.all;

--@formatter:off
entity psi_fix_nch_analog_trigger_tdm is
  generic(ch_nb_g       : natural      := 8;                                              --number of input/output channel
          trig_ext_nb_g : natural      := 1;                                              --number of input external trigger
          fix_fmt_g     : PsiFixFmt_t  := (1,0,15);                                       --FP format
          trig_nb_g     : natural      := 1);                                             --number of output trigger
  port(   clk_i       : in  std_logic;                                                    --processing clock
          rst_i       : in  std_logic;                                                    --Reset  processing '1' <=> active high 
          --*** signals ***
          dat_i       : in  std_logic_vector(PsiFixSize(fix_fmt_g)- 1 downto 0);          --// Data Input
          str_i       : in  std_logic;                                                    --TDM Strobe Input
          ext_i       : in  std_logic_vector(trig_ext_nb_g-1 downto 0);                   --external trigger input
          --*** paramters ***
          mask_min_i    : in std_logic_vector(trig_nb_g*ch_nb_g-1 downto 0);              --mask min results
          mask_max_i    : in std_logic_vector(trig_nb_g*ch_nb_g-1 downto 0);              --mask max results
          mask_ext_i    : in std_logic_vector(trig_nb_g*trig_ext_nb_g-1 downto 0);        --
          thld_min_i    : in std_logic_vector(ch_nb_g*PsiFixSize(fix_fmt_g)-1 downto 0);  --thld to set max window
          thld_max_i    : in std_logic_vector(ch_nb_g*PsiFixSize(fix_fmt_g)-1 downto 0);  --thld to set Min window
          trig_clr_ext_i: in std_logic_vector(trig_nb_g*trig_ext_nb_g-1 downto 0);                                    
          trig_mode_i   : in std_logic_vector(trig_nb_g-1 downto 0);                      -- Trigger mode (0:Continuous,1:Single) configuration register
          trig_arm_i    : in std_logic_vector(trig_nb_g-1   downto 0);                    -- Arm/dis--arm the trigger, rising edge sensitive
          --*** out ***
          dat_pipe_o  : out std_logic_vector(PsiFixSize(fix_fmt_g)-1 downto 0);           --data out pipelined   for recording
          str_pipe_o  : out std_logic;                                                    --strobe out pipelined for recording
          --*** status ***
          trig_o      : out std_logic_vector(trig_nb_g-1 downto 0);                       --trigger out
          is_arm_o    : out std_logic_vector(trig_nb_g-1 downto 0));                      --trigger is armed
end entity;
--@formatter:on

architecture RTL of psi_fix_nch_analog_trigger_tdm is  
  --internal herlpers 
  constant len_c : integer := PsiFixSize(fix_fmt_g);
  type array_thld_t is array (0 to ch_nb_g-1) of std_logic_vector(len_c-1 downto 0);
  signal thld_min_array_s : array_thld_t;
  signal thld_max_array_s : array_thld_t;
  
  type array_mask_t is array (0 to trig_nb_g-1) of std_logic_vector(ch_nb_g-1 downto 0);
  signal mask_min_array_s : array_mask_t;
  signal mask_max_array_s : array_mask_t;
  
  type array_ext_t is array (0 to trig_nb_g-1) of std_logic_vector(trig_ext_nb_g-1 downto 0);
  
  --=================================================================
  -- Comparator mngt signals
  --=================================================================
  signal param_slv2partdm_dat_s : std_logic_vector(ch_nb_g * 2 * len_c - 1 downto 0);
  signal param_slv2partdm_vld_s : std_logic;
  signal str_dff_s              : std_logic;
  signal param_tdm_thld_s       : std_logic_vector(2 * len_c - 1 downto 0);
  signal param_tdm_vld_s        : std_logic;
  signal data_dff0_s            : std_logic_vector(len_c - 1 downto 0);
  signal data_dff1_s            : std_logic_vector(len_c - 1 downto 0);
  signal min_s, max_s, str_s    : std_logic;
  signal min_vector_s           : std_logic_vector(ch_nb_g - 1 downto 0);
  signal max_vector_s           : std_logic_vector(ch_nb_g - 1 downto 0);
  signal comp_str_s             : std_logic;
  --=================================================================
  -- Trigger mngt signals
  --=================================================================
  signal max_trig_s             : array_mask_t;--std_logic_vector(ch_nb_g - 1 downto 0);
  signal min_trig_s             : array_mask_t;--std_logic_vector(ch_nb_g - 1 downto 0);
  signal trig_s                 : std_logic_vector(trig_nb_g-1 downto 0);
  --=================================================================
  -- External Trigger mngt signals
  --=================================================================
  signal trig_ext_array_s     : array_ext_t; -- external trigger input array
  signal trig_ext_array_dff_s : array_ext_t;
  signal ext_trig_array_s     : array_ext_t;
  signal ext_flg_array_s      : array_ext_t;
begin
  
  --*** helpers construc ***
  gene_mask_trigger_array: for i in 0 to trig_nb_g-1 generate
  begin
    mask_min_array_s(i) <= mask_min_i((i+1)*ch_nb_g-1 downto i*ch_nb_g);
    mask_max_array_s(i) <= mask_max_i((i+1)*ch_nb_g-1 downto i*ch_nb_g);
  end generate; 
  
  gene_thld_array: for i in 0 to ch_nb_g-1 generate
  begin
    thld_min_array_s(i) <= thld_min_i((i+1)*len_c-1 downto i*len_c);
    thld_max_array_s(i) <= thld_max_i((i+1)*len_c-1 downto i*len_c);
  end generate;
  
  --*** TAG process dff for input parameter thld ***
  proc_conv_array2slv : process(clk_i)
  begin
    if rising_edge(clk_i) then
      --*** create a big slv to be compatible to further block ***
      for i in 0 to ch_nb_g-1 loop
       param_slv2partdm_dat_s((i+1)*2*len_c -1 downto i*2*len_c) <= thld_max_array_s(i) & thld_min_array_s(i);
      end loop;
      --*** edge detect ***
      str_dff_s <= str_i;
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

  --*** TAG inst of parallel to TDM for min/max ***
  inst_par2tdm : entity work.psi_common_par_tdm
    generic map(ChannelCount_g => ch_nb_g,
                ChannelWidth_g => 2 * len_c)
    port map(-- @suppress 
             Clk         => clk_i,
             Rst         => rst_i,
             Parallel    => param_slv2partdm_dat_s,
             ParallelVld => param_slv2partdm_vld_s,
             Tdm         => param_tdm_thld_s,
             TdmVld      => param_tdm_vld_s);

  --*** TAG inst of parallel to TDM for min/max ***
  -- 4 stages dff delay
  inst_min_max : entity work.psi_fix_comparator
    generic map(fmt_g     => fix_fmt_g,
                rst_pol_g => '1')
    port map(clk_i     => clk_i,
             rst_i     => rst_i,
             set_min_i => param_tdm_thld_s(len_c - 1 downto 0),
             set_max_i => param_tdm_thld_s(2 * len_c - 1 downto len_c),
             data_i    => data_dff1_s,
             str_i     => param_tdm_vld_s,
             str_o     => str_s,
             min_o     => min_s,
             max_o     => max_s);

  --*** TAG MASK min with a TDM to parallel for trig gene ***
  inst_tdm_par_min : entity work.psi_common_tdm_par  
    generic map(--@suppress
                ChannelCount_g => ch_nb_g,
                ChannelWidth_g => 1)
    port map(--@suppress
             Clk         => clk_i,
             Rst         => rst_i,
             Tdm(0)      => min_s,
             TdmVld      => str_s,
             Parallel    => min_vector_s,
             ParallelVld => open);
  
  --*** TAG MASK max with a TDM to parallel for trig gene ***
  inst_tdm_par_max : entity work.psi_common_tdm_par 
    generic map(--@suppress
                ChannelCount_g => ch_nb_g,
                ChannelWidth_g => 1)
    port map(--@suppress 
             Clk         => clk_i,
             Rst         => rst_i,
             Tdm(0)      => max_s,
             TdmVld      => str_s,
             Parallel    => max_vector_s,
             ParallelVld => comp_str_s);
             
  --*** TAG -> trigger digital from library align data to trigger ***
  inst_delay_data : entity work.psi_common_multi_pl_stage 
    generic map(Width_g  => len_c,
                UseRdy_g => false,
                Stages_g => 10)
    port map(-- @suppress 
             Clk     => clk_i,
             Rst     => rst_i,
             InVld   => str_i,
             InData  => dat_i,
             OutVld  => str_pipe_o,
             OutRdy  => '1',
             OutData => dat_pipe_o);
             
  --============================================================================
  -->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> TRIGGER MNGT <<<<<<<<<<<<<<<<<<<<<<<<<<<<<
  --============================================================================
  --*** TAG -> MASK **
  proc_mask : process(clk_i)
  begin
    if rising_edge(clk_i) then
      for j in 0 to trig_nb_g -1 loop
        for i in 0 to ch_nb_g - 1 loop
          if comp_str_s = '1' then
            max_trig_s(j)(i) <= max_vector_s(i) and mask_max_array_s(j)(i);
            min_trig_s(j)(i) <= min_vector_s(i) and mask_min_array_s(j)(i);
          end if;
        end loop;
        -- internal trigger
        if min_trig_s(j) >= to_uslv(1,len_c) or  max_trig_s(j) >= to_uslv(1,len_c)  or  ext_trig_array_s(j) /= to_uslv(0,trig_ext_nb_g) then
          trig_s(j) <= '1';
        else
          trig_s(j) <= '0';
        end if;
       end loop;
      end if;
  end process;
  
  gene_ext_array : for i in 0 to trig_nb_g -1 generate
  begin
    trig_ext_array_s(i)<= ext_i;
  end generate;
  
  proc_ext_trig_align : process(clk_i)
   begin
     if rising_edge(clk_i) then
       trig_ext_array_dff_s <= trig_ext_array_s;
       
          if rst_i = '1' then
            trig_ext_array_dff_s <= (others=>(others=>'0'));
            ext_flg_array_s <= (others=>(others=>'0'));
          else
            for j in 0 to trig_nb_g -1 loop
              for k in 0 to trig_ext_nb_g-1 loop
                --*** rising_edge_detect
                if trig_ext_array_dff_s(j)(k) = '0' and trig_ext_array_s(j)(k) = '1' then
                  ext_flg_array_s(j)(k) <= '1';
                elsif  trig_clr_ext_i(k)= '1' then
                  ext_flg_array_s(j)(k) <= '0';
                end if;
                --*** sync with str
                if comp_str_s = '1' and mask_ext_i(k) = '1' then
                  ext_trig_array_s(j)(k) <= ext_flg_array_s(j)(k);
                else
                  ext_trig_array_s(j)(k) <= '0';
                end if;            
              end loop;
             end loop;
          end if;
      end if;
  end process;

  --*** TAG digital trigger from psi common - not the most ressource efficient ***
  gene_trigger_nb : for i in 0 to trig_nb_g-1 generate 
  begin
    inst_trig : entity work.psi_common_trigger_digital
     generic map(digital_input_number_g    => 1,
                 rst_pol_g                 => '1')
     port map(   InClk                     => clk_i,
                 InRst                     => rst_i,
                 InTrgModeCfg(0)           => trig_mode_i(i),
                 InTrgArmCfg               => trig_arm_i(i),
                 InTrgEdgeCfg              => "10",           --rising edge forced
                 InTrgDigitalSourceCfg(0)  => '0',            --don't care
                 InDigitalTrg(0)           => trig_s(i),
                 InExtDisarm               => '0',
                 OutTrgIsArmed             => is_arm_o(i),
                 OutTrigger                => trig_o(i));
                 
  end generate;
end architecture;
