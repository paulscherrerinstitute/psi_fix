------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.psi_fix_pkg.all;
use work.psi_common_math_pkg.all;

entity psi_fix_lin_approx_sqrt18b is
  port(
    clk_i : in  std_logic;                         -- system clock
    rst_i : in  std_logic;                         -- system reset
    dat_i : in  std_logic_vector(20 - 1 downto 0); -- data in Format (0, 0, 20)
    vld_i : in  std_logic;                         -- valid input
    dat_o : out std_logic_vector(17 - 1 downto 0); -- data output Format (0, 0, 17)
    vld_o : out std_logic                          -- valid output
  );
end entity;

------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of psi_fix_lin_approx_sqrt18b is

  -- Constants
  constant InFmt_c      : psi_fix_fmt_t := (0, 0, 20);
  constant OutFmt_c     : psi_fix_fmt_t := (0, 0, 17);
  constant OffsFmt_c    : psi_fix_fmt_t := (0, 0, 19);
  constant GradFmt_c    : psi_fix_fmt_t := (0, 0, 10);
  constant TableSize_c  : integer       := 512;
  constant TableWidth_c : integer       := 29;

  -- Table

  type Table_t is array (0 to TableSize_c - 1) of std_logic_vector(TableWidth_c - 1 downto 0);
  constant Table_c : Table_t := (
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(16384, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(28378, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(36636, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(43348, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(49152, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(54340, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(59073, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(63455, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(67553, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(71416, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(75081, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(78575, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(81920, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(85134, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(88231, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(91222, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(94119, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(96929, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(99660, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(102318, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(104909, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(107437, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(109907, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(112323, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(114688, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(117005, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(119277, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(121507, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(123696, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(125848, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(127963, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(130044, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(132092, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(134109, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(136096, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(138054, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(139985, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(141890, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(143769, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(145624, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(147456, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(149265, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(151053, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(152820, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(154566, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(156293, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(158002, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(159691, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(161364, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(163019, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(164657, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(166279, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(167886, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(169477, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(171054, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(172616, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(174164, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(175699, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(177220, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(178728, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(180224, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(181707, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(183179, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(184638, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(186086, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(187523, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(188950, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(190365, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(191770, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(193165, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(194549, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(195924, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(197289, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(198645, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(199992, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(201330, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(202659, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(203979, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(205291, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(206594, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(207890, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(209177, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(210456, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(211728, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(212992, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(214249, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(215498, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(216740, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(217975, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(219203, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(220424, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(221639, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(222846, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(224048, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(225243, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(226431, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(227614, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(228790, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(229960, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(231125, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(232283, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(233436, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(234583, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(235725, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(236861, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(237991, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(239117, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(240237, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(241351, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(242461, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(243566, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(244665, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(245760, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(246850, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(247935, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(249015, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(250091, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(251162, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(252228, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(253290, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(254348, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(255401, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(256450, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(257495, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(258535, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(259571, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(260603, 19)),
    std_logic_vector(to_unsigned(1023, 10) & to_unsigned(261631, 19)),
    std_logic_vector(to_unsigned(1022, 10) & to_unsigned(262656, 19)),
    std_logic_vector(to_unsigned(1018, 10) & to_unsigned(263676, 19)),
    std_logic_vector(to_unsigned(1014, 10) & to_unsigned(264692, 19)),
    std_logic_vector(to_unsigned(1010, 10) & to_unsigned(265704, 19)),
    std_logic_vector(to_unsigned(1006, 10) & to_unsigned(266712, 19)),
    std_logic_vector(to_unsigned(1003, 10) & to_unsigned(267717, 19)),
    std_logic_vector(to_unsigned(999, 10) & to_unsigned(268718, 19)),
    std_logic_vector(to_unsigned(995, 10) & to_unsigned(269715, 19)),
    std_logic_vector(to_unsigned(992, 10) & to_unsigned(270708, 19)),
    std_logic_vector(to_unsigned(988, 10) & to_unsigned(271698, 19)),
    std_logic_vector(to_unsigned(984, 10) & to_unsigned(272684, 19)),
    std_logic_vector(to_unsigned(981, 10) & to_unsigned(273667, 19)),
    std_logic_vector(to_unsigned(977, 10) & to_unsigned(274646, 19)),
    std_logic_vector(to_unsigned(974, 10) & to_unsigned(275622, 19)),
    std_logic_vector(to_unsigned(971, 10) & to_unsigned(276594, 19)),
    std_logic_vector(to_unsigned(967, 10) & to_unsigned(277563, 19)),
    std_logic_vector(to_unsigned(964, 10) & to_unsigned(278528, 19)),
    std_logic_vector(to_unsigned(960, 10) & to_unsigned(279490, 19)),
    std_logic_vector(to_unsigned(957, 10) & to_unsigned(280449, 19)),
    std_logic_vector(to_unsigned(954, 10) & to_unsigned(281404, 19)),
    std_logic_vector(to_unsigned(951, 10) & to_unsigned(282357, 19)),
    std_logic_vector(to_unsigned(948, 10) & to_unsigned(283306, 19)),
    std_logic_vector(to_unsigned(944, 10) & to_unsigned(284252, 19)),
    std_logic_vector(to_unsigned(941, 10) & to_unsigned(285195, 19)),
    std_logic_vector(to_unsigned(938, 10) & to_unsigned(286134, 19)),
    std_logic_vector(to_unsigned(935, 10) & to_unsigned(287071, 19)),
    std_logic_vector(to_unsigned(932, 10) & to_unsigned(288004, 19)),
    std_logic_vector(to_unsigned(929, 10) & to_unsigned(288935, 19)),
    std_logic_vector(to_unsigned(926, 10) & to_unsigned(289863, 19)),
    std_logic_vector(to_unsigned(923, 10) & to_unsigned(290787, 19)),
    std_logic_vector(to_unsigned(920, 10) & to_unsigned(291709, 19)),
    std_logic_vector(to_unsigned(917, 10) & to_unsigned(292628, 19)),
    std_logic_vector(to_unsigned(914, 10) & to_unsigned(293543, 19)),
    std_logic_vector(to_unsigned(912, 10) & to_unsigned(294457, 19)),
    std_logic_vector(to_unsigned(909, 10) & to_unsigned(295367, 19)),
    std_logic_vector(to_unsigned(906, 10) & to_unsigned(296274, 19)),
    std_logic_vector(to_unsigned(903, 10) & to_unsigned(297179, 19)),
    std_logic_vector(to_unsigned(901, 10) & to_unsigned(298081, 19)),
    std_logic_vector(to_unsigned(898, 10) & to_unsigned(298980, 19)),
    std_logic_vector(to_unsigned(895, 10) & to_unsigned(299876, 19)),
    std_logic_vector(to_unsigned(892, 10) & to_unsigned(300770, 19)),
    std_logic_vector(to_unsigned(890, 10) & to_unsigned(301661, 19)),
    std_logic_vector(to_unsigned(887, 10) & to_unsigned(302550, 19)),
    std_logic_vector(to_unsigned(885, 10) & to_unsigned(303436, 19)),
    std_logic_vector(to_unsigned(882, 10) & to_unsigned(304319, 19)),
    std_logic_vector(to_unsigned(880, 10) & to_unsigned(305200, 19)),
    std_logic_vector(to_unsigned(877, 10) & to_unsigned(306078, 19)),
    std_logic_vector(to_unsigned(875, 10) & to_unsigned(306954, 19)),
    std_logic_vector(to_unsigned(872, 10) & to_unsigned(307827, 19)),
    std_logic_vector(to_unsigned(870, 10) & to_unsigned(308698, 19)),
    std_logic_vector(to_unsigned(867, 10) & to_unsigned(309567, 19)),
    std_logic_vector(to_unsigned(865, 10) & to_unsigned(310432, 19)),
    std_logic_vector(to_unsigned(862, 10) & to_unsigned(311296, 19)),
    std_logic_vector(to_unsigned(860, 10) & to_unsigned(312157, 19)),
    std_logic_vector(to_unsigned(858, 10) & to_unsigned(313016, 19)),
    std_logic_vector(to_unsigned(855, 10) & to_unsigned(313872, 19)),
    std_logic_vector(to_unsigned(853, 10) & to_unsigned(314726, 19)),
    std_logic_vector(to_unsigned(851, 10) & to_unsigned(315578, 19)),
    std_logic_vector(to_unsigned(848, 10) & to_unsigned(316428, 19)),
    std_logic_vector(to_unsigned(846, 10) & to_unsigned(317275, 19)),
    std_logic_vector(to_unsigned(844, 10) & to_unsigned(318120, 19)),
    std_logic_vector(to_unsigned(842, 10) & to_unsigned(318962, 19)),
    std_logic_vector(to_unsigned(839, 10) & to_unsigned(319803, 19)),
    std_logic_vector(to_unsigned(837, 10) & to_unsigned(320641, 19)),
    std_logic_vector(to_unsigned(835, 10) & to_unsigned(321477, 19)),
    std_logic_vector(to_unsigned(833, 10) & to_unsigned(322311, 19)),
    std_logic_vector(to_unsigned(831, 10) & to_unsigned(323143, 19)),
    std_logic_vector(to_unsigned(829, 10) & to_unsigned(323973, 19)),
    std_logic_vector(to_unsigned(826, 10) & to_unsigned(324800, 19)),
    std_logic_vector(to_unsigned(824, 10) & to_unsigned(325626, 19)),
    std_logic_vector(to_unsigned(822, 10) & to_unsigned(326449, 19)),
    std_logic_vector(to_unsigned(820, 10) & to_unsigned(327270, 19)),
    std_logic_vector(to_unsigned(818, 10) & to_unsigned(328089, 19)),
    std_logic_vector(to_unsigned(816, 10) & to_unsigned(328907, 19)),
    std_logic_vector(to_unsigned(814, 10) & to_unsigned(329722, 19)),
    std_logic_vector(to_unsigned(812, 10) & to_unsigned(330535, 19)),
    std_logic_vector(to_unsigned(810, 10) & to_unsigned(331346, 19)),
    std_logic_vector(to_unsigned(808, 10) & to_unsigned(332155, 19)),
    std_logic_vector(to_unsigned(806, 10) & to_unsigned(332962, 19)),
    std_logic_vector(to_unsigned(804, 10) & to_unsigned(333767, 19)),
    std_logic_vector(to_unsigned(802, 10) & to_unsigned(334571, 19)),
    std_logic_vector(to_unsigned(800, 10) & to_unsigned(335372, 19)),
    std_logic_vector(to_unsigned(799, 10) & to_unsigned(336172, 19)),
    std_logic_vector(to_unsigned(797, 10) & to_unsigned(336969, 19)),
    std_logic_vector(to_unsigned(795, 10) & to_unsigned(337765, 19)),
    std_logic_vector(to_unsigned(793, 10) & to_unsigned(338559, 19)),
    std_logic_vector(to_unsigned(791, 10) & to_unsigned(339351, 19)),
    std_logic_vector(to_unsigned(789, 10) & to_unsigned(340141, 19)),
    std_logic_vector(to_unsigned(787, 10) & to_unsigned(340929, 19)),
    std_logic_vector(to_unsigned(786, 10) & to_unsigned(341715, 19)),
    std_logic_vector(to_unsigned(784, 10) & to_unsigned(342500, 19)),
    std_logic_vector(to_unsigned(782, 10) & to_unsigned(343283, 19)),
    std_logic_vector(to_unsigned(780, 10) & to_unsigned(344064, 19)),
    std_logic_vector(to_unsigned(778, 10) & to_unsigned(344843, 19)),
    std_logic_vector(to_unsigned(777, 10) & to_unsigned(345621, 19)),
    std_logic_vector(to_unsigned(775, 10) & to_unsigned(346397, 19)),
    std_logic_vector(to_unsigned(773, 10) & to_unsigned(347171, 19)),
    std_logic_vector(to_unsigned(771, 10) & to_unsigned(347943, 19)),
    std_logic_vector(to_unsigned(770, 10) & to_unsigned(348714, 19)),
    std_logic_vector(to_unsigned(768, 10) & to_unsigned(349483, 19)),
    std_logic_vector(to_unsigned(766, 10) & to_unsigned(350250, 19)),
    std_logic_vector(to_unsigned(765, 10) & to_unsigned(351015, 19)),
    std_logic_vector(to_unsigned(763, 10) & to_unsigned(351779, 19)),
    std_logic_vector(to_unsigned(761, 10) & to_unsigned(352542, 19)),
    std_logic_vector(to_unsigned(760, 10) & to_unsigned(353302, 19)),
    std_logic_vector(to_unsigned(758, 10) & to_unsigned(354061, 19)),
    std_logic_vector(to_unsigned(757, 10) & to_unsigned(354819, 19)),
    std_logic_vector(to_unsigned(755, 10) & to_unsigned(355574, 19)),
    std_logic_vector(to_unsigned(753, 10) & to_unsigned(356328, 19)),
    std_logic_vector(to_unsigned(752, 10) & to_unsigned(357081, 19)),
    std_logic_vector(to_unsigned(750, 10) & to_unsigned(357832, 19)),
    std_logic_vector(to_unsigned(749, 10) & to_unsigned(358581, 19)),
    std_logic_vector(to_unsigned(747, 10) & to_unsigned(359329, 19)),
    std_logic_vector(to_unsigned(745, 10) & to_unsigned(360075, 19)),
    std_logic_vector(to_unsigned(744, 10) & to_unsigned(360820, 19)),
    std_logic_vector(to_unsigned(742, 10) & to_unsigned(361563, 19)),
    std_logic_vector(to_unsigned(741, 10) & to_unsigned(362305, 19)),
    std_logic_vector(to_unsigned(739, 10) & to_unsigned(363045, 19)),
    std_logic_vector(to_unsigned(738, 10) & to_unsigned(363784, 19)),
    std_logic_vector(to_unsigned(736, 10) & to_unsigned(364521, 19)),
    std_logic_vector(to_unsigned(735, 10) & to_unsigned(365257, 19)),
    std_logic_vector(to_unsigned(733, 10) & to_unsigned(365991, 19)),
    std_logic_vector(to_unsigned(732, 10) & to_unsigned(366724, 19)),
    std_logic_vector(to_unsigned(731, 10) & to_unsigned(367455, 19)),
    std_logic_vector(to_unsigned(729, 10) & to_unsigned(368185, 19)),
    std_logic_vector(to_unsigned(728, 10) & to_unsigned(368913, 19)),
    std_logic_vector(to_unsigned(726, 10) & to_unsigned(369640, 19)),
    std_logic_vector(to_unsigned(725, 10) & to_unsigned(370365, 19)),
    std_logic_vector(to_unsigned(723, 10) & to_unsigned(371089, 19)),
    std_logic_vector(to_unsigned(722, 10) & to_unsigned(371812, 19)),
    std_logic_vector(to_unsigned(721, 10) & to_unsigned(372533, 19)),
    std_logic_vector(to_unsigned(719, 10) & to_unsigned(373253, 19)),
    std_logic_vector(to_unsigned(718, 10) & to_unsigned(373972, 19)),
    std_logic_vector(to_unsigned(716, 10) & to_unsigned(374689, 19)),
    std_logic_vector(to_unsigned(715, 10) & to_unsigned(375405, 19)),
    std_logic_vector(to_unsigned(714, 10) & to_unsigned(376119, 19)),
    std_logic_vector(to_unsigned(712, 10) & to_unsigned(376832, 19)),
    std_logic_vector(to_unsigned(711, 10) & to_unsigned(377544, 19)),
    std_logic_vector(to_unsigned(710, 10) & to_unsigned(378254, 19)),
    std_logic_vector(to_unsigned(708, 10) & to_unsigned(378963, 19)),
    std_logic_vector(to_unsigned(707, 10) & to_unsigned(379671, 19)),
    std_logic_vector(to_unsigned(706, 10) & to_unsigned(380377, 19)),
    std_logic_vector(to_unsigned(704, 10) & to_unsigned(381082, 19)),
    std_logic_vector(to_unsigned(703, 10) & to_unsigned(381786, 19)),
    std_logic_vector(to_unsigned(702, 10) & to_unsigned(382488, 19)),
    std_logic_vector(to_unsigned(701, 10) & to_unsigned(383190, 19)),
    std_logic_vector(to_unsigned(699, 10) & to_unsigned(383889, 19)),
    std_logic_vector(to_unsigned(698, 10) & to_unsigned(384588, 19)),
    std_logic_vector(to_unsigned(697, 10) & to_unsigned(385285, 19)),
    std_logic_vector(to_unsigned(695, 10) & to_unsigned(385981, 19)),
    std_logic_vector(to_unsigned(694, 10) & to_unsigned(386676, 19)),
    std_logic_vector(to_unsigned(693, 10) & to_unsigned(387370, 19)),
    std_logic_vector(to_unsigned(692, 10) & to_unsigned(388062, 19)),
    std_logic_vector(to_unsigned(691, 10) & to_unsigned(388753, 19)),
    std_logic_vector(to_unsigned(689, 10) & to_unsigned(389443, 19)),
    std_logic_vector(to_unsigned(688, 10) & to_unsigned(390132, 19)),
    std_logic_vector(to_unsigned(687, 10) & to_unsigned(390819, 19)),
    std_logic_vector(to_unsigned(686, 10) & to_unsigned(391506, 19)),
    std_logic_vector(to_unsigned(684, 10) & to_unsigned(392191, 19)),
    std_logic_vector(to_unsigned(683, 10) & to_unsigned(392875, 19)),
    std_logic_vector(to_unsigned(682, 10) & to_unsigned(393557, 19)),
    std_logic_vector(to_unsigned(681, 10) & to_unsigned(394239, 19)),
    std_logic_vector(to_unsigned(680, 10) & to_unsigned(394919, 19)),
    std_logic_vector(to_unsigned(679, 10) & to_unsigned(395598, 19)),
    std_logic_vector(to_unsigned(677, 10) & to_unsigned(396276, 19)),
    std_logic_vector(to_unsigned(676, 10) & to_unsigned(396953, 19)),
    std_logic_vector(to_unsigned(675, 10) & to_unsigned(397629, 19)),
    std_logic_vector(to_unsigned(674, 10) & to_unsigned(398303, 19)),
    std_logic_vector(to_unsigned(673, 10) & to_unsigned(398976, 19)),
    std_logic_vector(to_unsigned(672, 10) & to_unsigned(399649, 19)),
    std_logic_vector(to_unsigned(671, 10) & to_unsigned(400320, 19)),
    std_logic_vector(to_unsigned(669, 10) & to_unsigned(400990, 19)),
    std_logic_vector(to_unsigned(668, 10) & to_unsigned(401659, 19)),
    std_logic_vector(to_unsigned(667, 10) & to_unsigned(402326, 19)),
    std_logic_vector(to_unsigned(666, 10) & to_unsigned(402993, 19)),
    std_logic_vector(to_unsigned(665, 10) & to_unsigned(403659, 19)),
    std_logic_vector(to_unsigned(664, 10) & to_unsigned(404323, 19)),
    std_logic_vector(to_unsigned(663, 10) & to_unsigned(404986, 19)),
    std_logic_vector(to_unsigned(662, 10) & to_unsigned(405649, 19)),
    std_logic_vector(to_unsigned(661, 10) & to_unsigned(406310, 19)),
    std_logic_vector(to_unsigned(660, 10) & to_unsigned(406970, 19)),
    std_logic_vector(to_unsigned(659, 10) & to_unsigned(407629, 19)),
    std_logic_vector(to_unsigned(657, 10) & to_unsigned(408287, 19)),
    std_logic_vector(to_unsigned(656, 10) & to_unsigned(408944, 19)),
    std_logic_vector(to_unsigned(655, 10) & to_unsigned(409600, 19)),
    std_logic_vector(to_unsigned(654, 10) & to_unsigned(410255, 19)),
    std_logic_vector(to_unsigned(653, 10) & to_unsigned(410909, 19)),
    std_logic_vector(to_unsigned(652, 10) & to_unsigned(411561, 19)),
    std_logic_vector(to_unsigned(651, 10) & to_unsigned(412213, 19)),
    std_logic_vector(to_unsigned(650, 10) & to_unsigned(412864, 19)),
    std_logic_vector(to_unsigned(649, 10) & to_unsigned(413513, 19)),
    std_logic_vector(to_unsigned(648, 10) & to_unsigned(414162, 19)),
    std_logic_vector(to_unsigned(647, 10) & to_unsigned(414810, 19)),
    std_logic_vector(to_unsigned(646, 10) & to_unsigned(415456, 19)),
    std_logic_vector(to_unsigned(645, 10) & to_unsigned(416102, 19)),
    std_logic_vector(to_unsigned(644, 10) & to_unsigned(416747, 19)),
    std_logic_vector(to_unsigned(643, 10) & to_unsigned(417390, 19)),
    std_logic_vector(to_unsigned(642, 10) & to_unsigned(418033, 19)),
    std_logic_vector(to_unsigned(641, 10) & to_unsigned(418675, 19)),
    std_logic_vector(to_unsigned(640, 10) & to_unsigned(419315, 19)),
    std_logic_vector(to_unsigned(639, 10) & to_unsigned(419955, 19)),
    std_logic_vector(to_unsigned(638, 10) & to_unsigned(420594, 19)),
    std_logic_vector(to_unsigned(637, 10) & to_unsigned(421231, 19)),
    std_logic_vector(to_unsigned(636, 10) & to_unsigned(421868, 19)),
    std_logic_vector(to_unsigned(635, 10) & to_unsigned(422504, 19)),
    std_logic_vector(to_unsigned(634, 10) & to_unsigned(423139, 19)),
    std_logic_vector(to_unsigned(633, 10) & to_unsigned(423773, 19)),
    std_logic_vector(to_unsigned(632, 10) & to_unsigned(424406, 19)),
    std_logic_vector(to_unsigned(632, 10) & to_unsigned(425038, 19)),
    std_logic_vector(to_unsigned(631, 10) & to_unsigned(425669, 19)),
    std_logic_vector(to_unsigned(630, 10) & to_unsigned(426299, 19)),
    std_logic_vector(to_unsigned(629, 10) & to_unsigned(426928, 19)),
    std_logic_vector(to_unsigned(628, 10) & to_unsigned(427556, 19)),
    std_logic_vector(to_unsigned(627, 10) & to_unsigned(428184, 19)),
    std_logic_vector(to_unsigned(626, 10) & to_unsigned(428810, 19)),
    std_logic_vector(to_unsigned(625, 10) & to_unsigned(429436, 19)),
    std_logic_vector(to_unsigned(624, 10) & to_unsigned(430060, 19)),
    std_logic_vector(to_unsigned(623, 10) & to_unsigned(430684, 19)),
    std_logic_vector(to_unsigned(622, 10) & to_unsigned(431307, 19)),
    std_logic_vector(to_unsigned(621, 10) & to_unsigned(431929, 19)),
    std_logic_vector(to_unsigned(621, 10) & to_unsigned(432550, 19)),
    std_logic_vector(to_unsigned(620, 10) & to_unsigned(433170, 19)),
    std_logic_vector(to_unsigned(619, 10) & to_unsigned(433789, 19)),
    std_logic_vector(to_unsigned(618, 10) & to_unsigned(434408, 19)),
    std_logic_vector(to_unsigned(617, 10) & to_unsigned(435025, 19)),
    std_logic_vector(to_unsigned(616, 10) & to_unsigned(435642, 19)),
    std_logic_vector(to_unsigned(615, 10) & to_unsigned(436258, 19)),
    std_logic_vector(to_unsigned(614, 10) & to_unsigned(436873, 19)),
    std_logic_vector(to_unsigned(614, 10) & to_unsigned(437487, 19)),
    std_logic_vector(to_unsigned(613, 10) & to_unsigned(438100, 19)),
    std_logic_vector(to_unsigned(612, 10) & to_unsigned(438712, 19)),
    std_logic_vector(to_unsigned(611, 10) & to_unsigned(439323, 19)),
    std_logic_vector(to_unsigned(610, 10) & to_unsigned(439934, 19)),
    std_logic_vector(to_unsigned(609, 10) & to_unsigned(440544, 19)),
    std_logic_vector(to_unsigned(608, 10) & to_unsigned(441153, 19)),
    std_logic_vector(to_unsigned(608, 10) & to_unsigned(441761, 19)),
    std_logic_vector(to_unsigned(607, 10) & to_unsigned(442368, 19)),
    std_logic_vector(to_unsigned(606, 10) & to_unsigned(442974, 19)),
    std_logic_vector(to_unsigned(605, 10) & to_unsigned(443580, 19)),
    std_logic_vector(to_unsigned(604, 10) & to_unsigned(444185, 19)),
    std_logic_vector(to_unsigned(604, 10) & to_unsigned(444789, 19)),
    std_logic_vector(to_unsigned(603, 10) & to_unsigned(445392, 19)),
    std_logic_vector(to_unsigned(602, 10) & to_unsigned(445994, 19)),
    std_logic_vector(to_unsigned(601, 10) & to_unsigned(446596, 19)),
    std_logic_vector(to_unsigned(600, 10) & to_unsigned(447196, 19)),
    std_logic_vector(to_unsigned(599, 10) & to_unsigned(447796, 19)),
    std_logic_vector(to_unsigned(599, 10) & to_unsigned(448395, 19)),
    std_logic_vector(to_unsigned(598, 10) & to_unsigned(448993, 19)),
    std_logic_vector(to_unsigned(597, 10) & to_unsigned(449591, 19)),
    std_logic_vector(to_unsigned(596, 10) & to_unsigned(450187, 19)),
    std_logic_vector(to_unsigned(595, 10) & to_unsigned(450783, 19)),
    std_logic_vector(to_unsigned(595, 10) & to_unsigned(451378, 19)),
    std_logic_vector(to_unsigned(594, 10) & to_unsigned(451973, 19)),
    std_logic_vector(to_unsigned(593, 10) & to_unsigned(452566, 19)),
    std_logic_vector(to_unsigned(592, 10) & to_unsigned(453159, 19)),
    std_logic_vector(to_unsigned(592, 10) & to_unsigned(453751, 19)),
    std_logic_vector(to_unsigned(591, 10) & to_unsigned(454342, 19)),
    std_logic_vector(to_unsigned(590, 10) & to_unsigned(454933, 19)),
    std_logic_vector(to_unsigned(589, 10) & to_unsigned(455522, 19)),
    std_logic_vector(to_unsigned(589, 10) & to_unsigned(456111, 19)),
    std_logic_vector(to_unsigned(588, 10) & to_unsigned(456699, 19)),
    std_logic_vector(to_unsigned(587, 10) & to_unsigned(457287, 19)),
    std_logic_vector(to_unsigned(586, 10) & to_unsigned(457873, 19)),
    std_logic_vector(to_unsigned(586, 10) & to_unsigned(458459, 19)),
    std_logic_vector(to_unsigned(585, 10) & to_unsigned(459044, 19)),
    std_logic_vector(to_unsigned(584, 10) & to_unsigned(459629, 19)),
    std_logic_vector(to_unsigned(583, 10) & to_unsigned(460213, 19)),
    std_logic_vector(to_unsigned(583, 10) & to_unsigned(460795, 19)),
    std_logic_vector(to_unsigned(582, 10) & to_unsigned(461378, 19)),
    std_logic_vector(to_unsigned(581, 10) & to_unsigned(461959, 19)),
    std_logic_vector(to_unsigned(580, 10) & to_unsigned(462540, 19)),
    std_logic_vector(to_unsigned(580, 10) & to_unsigned(463120, 19)),
    std_logic_vector(to_unsigned(579, 10) & to_unsigned(463699, 19)),
    std_logic_vector(to_unsigned(578, 10) & to_unsigned(464278, 19)),
    std_logic_vector(to_unsigned(577, 10) & to_unsigned(464855, 19)),
    std_logic_vector(to_unsigned(577, 10) & to_unsigned(465433, 19)),
    std_logic_vector(to_unsigned(576, 10) & to_unsigned(466009, 19)),
    std_logic_vector(to_unsigned(575, 10) & to_unsigned(466585, 19)),
    std_logic_vector(to_unsigned(575, 10) & to_unsigned(467160, 19)),
    std_logic_vector(to_unsigned(574, 10) & to_unsigned(467734, 19)),
    std_logic_vector(to_unsigned(573, 10) & to_unsigned(468307, 19)),
    std_logic_vector(to_unsigned(573, 10) & to_unsigned(468880, 19)),
    std_logic_vector(to_unsigned(572, 10) & to_unsigned(469452, 19)),
    std_logic_vector(to_unsigned(571, 10) & to_unsigned(470024, 19)),
    std_logic_vector(to_unsigned(570, 10) & to_unsigned(470595, 19)),
    std_logic_vector(to_unsigned(570, 10) & to_unsigned(471165, 19)),
    std_logic_vector(to_unsigned(569, 10) & to_unsigned(471734, 19)),
    std_logic_vector(to_unsigned(568, 10) & to_unsigned(472303, 19)),
    std_logic_vector(to_unsigned(568, 10) & to_unsigned(472871, 19)),
    std_logic_vector(to_unsigned(567, 10) & to_unsigned(473438, 19)),
    std_logic_vector(to_unsigned(566, 10) & to_unsigned(474005, 19)),
    std_logic_vector(to_unsigned(566, 10) & to_unsigned(474571, 19)),
    std_logic_vector(to_unsigned(565, 10) & to_unsigned(475136, 19)),
    std_logic_vector(to_unsigned(564, 10) & to_unsigned(475701, 19)),
    std_logic_vector(to_unsigned(564, 10) & to_unsigned(476265, 19)),
    std_logic_vector(to_unsigned(563, 10) & to_unsigned(476828, 19)),
    std_logic_vector(to_unsigned(562, 10) & to_unsigned(477391, 19)),
    std_logic_vector(to_unsigned(562, 10) & to_unsigned(477952, 19)),
    std_logic_vector(to_unsigned(561, 10) & to_unsigned(478514, 19)),
    std_logic_vector(to_unsigned(560, 10) & to_unsigned(479074, 19)),
    std_logic_vector(to_unsigned(560, 10) & to_unsigned(479634, 19)),
    std_logic_vector(to_unsigned(559, 10) & to_unsigned(480194, 19)),
    std_logic_vector(to_unsigned(558, 10) & to_unsigned(480752, 19)),
    std_logic_vector(to_unsigned(558, 10) & to_unsigned(481311, 19)),
    std_logic_vector(to_unsigned(557, 10) & to_unsigned(481868, 19)),
    std_logic_vector(to_unsigned(556, 10) & to_unsigned(482425, 19)),
    std_logic_vector(to_unsigned(556, 10) & to_unsigned(482981, 19)),
    std_logic_vector(to_unsigned(555, 10) & to_unsigned(483536, 19)),
    std_logic_vector(to_unsigned(555, 10) & to_unsigned(484091, 19)),
    std_logic_vector(to_unsigned(554, 10) & to_unsigned(484645, 19)),
    std_logic_vector(to_unsigned(553, 10) & to_unsigned(485199, 19)),
    std_logic_vector(to_unsigned(553, 10) & to_unsigned(485752, 19)),
    std_logic_vector(to_unsigned(552, 10) & to_unsigned(486304, 19)),
    std_logic_vector(to_unsigned(551, 10) & to_unsigned(486856, 19)),
    std_logic_vector(to_unsigned(551, 10) & to_unsigned(487407, 19)),
    std_logic_vector(to_unsigned(550, 10) & to_unsigned(487957, 19)),
    std_logic_vector(to_unsigned(550, 10) & to_unsigned(488507, 19)),
    std_logic_vector(to_unsigned(549, 10) & to_unsigned(489056, 19)),
    std_logic_vector(to_unsigned(548, 10) & to_unsigned(489605, 19)),
    std_logic_vector(to_unsigned(548, 10) & to_unsigned(490153, 19)),
    std_logic_vector(to_unsigned(547, 10) & to_unsigned(490700, 19)),
    std_logic_vector(to_unsigned(546, 10) & to_unsigned(491247, 19)),
    std_logic_vector(to_unsigned(546, 10) & to_unsigned(491793, 19)),
    std_logic_vector(to_unsigned(545, 10) & to_unsigned(492339, 19)),
    std_logic_vector(to_unsigned(545, 10) & to_unsigned(492883, 19)),
    std_logic_vector(to_unsigned(544, 10) & to_unsigned(493428, 19)),
    std_logic_vector(to_unsigned(543, 10) & to_unsigned(493971, 19)),
    std_logic_vector(to_unsigned(543, 10) & to_unsigned(494515, 19)),
    std_logic_vector(to_unsigned(542, 10) & to_unsigned(495057, 19)),
    std_logic_vector(to_unsigned(542, 10) & to_unsigned(495599, 19)),
    std_logic_vector(to_unsigned(541, 10) & to_unsigned(496140, 19)),
    std_logic_vector(to_unsigned(540, 10) & to_unsigned(496681, 19)),
    std_logic_vector(to_unsigned(540, 10) & to_unsigned(497221, 19)),
    std_logic_vector(to_unsigned(539, 10) & to_unsigned(497761, 19)),
    std_logic_vector(to_unsigned(539, 10) & to_unsigned(498300, 19)),
    std_logic_vector(to_unsigned(538, 10) & to_unsigned(498838, 19)),
    std_logic_vector(to_unsigned(538, 10) & to_unsigned(499376, 19)),
    std_logic_vector(to_unsigned(537, 10) & to_unsigned(499913, 19)),
    std_logic_vector(to_unsigned(536, 10) & to_unsigned(500450, 19)),
    std_logic_vector(to_unsigned(536, 10) & to_unsigned(500986, 19)),
    std_logic_vector(to_unsigned(535, 10) & to_unsigned(501522, 19)),
    std_logic_vector(to_unsigned(535, 10) & to_unsigned(502057, 19)),
    std_logic_vector(to_unsigned(534, 10) & to_unsigned(502591, 19)),
    std_logic_vector(to_unsigned(534, 10) & to_unsigned(503125, 19)),
    std_logic_vector(to_unsigned(533, 10) & to_unsigned(503658, 19)),
    std_logic_vector(to_unsigned(532, 10) & to_unsigned(504191, 19)),
    std_logic_vector(to_unsigned(532, 10) & to_unsigned(504723, 19)),
    std_logic_vector(to_unsigned(531, 10) & to_unsigned(505255, 19)),
    std_logic_vector(to_unsigned(531, 10) & to_unsigned(505786, 19)),
    std_logic_vector(to_unsigned(530, 10) & to_unsigned(506316, 19)),
    std_logic_vector(to_unsigned(530, 10) & to_unsigned(506846, 19)),
    std_logic_vector(to_unsigned(529, 10) & to_unsigned(507375, 19)),
    std_logic_vector(to_unsigned(529, 10) & to_unsigned(507904, 19)),
    std_logic_vector(to_unsigned(528, 10) & to_unsigned(508432, 19)),
    std_logic_vector(to_unsigned(527, 10) & to_unsigned(508960, 19)),
    std_logic_vector(to_unsigned(527, 10) & to_unsigned(509487, 19)),
    std_logic_vector(to_unsigned(526, 10) & to_unsigned(510014, 19)),
    std_logic_vector(to_unsigned(526, 10) & to_unsigned(510540, 19)),
    std_logic_vector(to_unsigned(525, 10) & to_unsigned(511065, 19)),
    std_logic_vector(to_unsigned(525, 10) & to_unsigned(511590, 19)),
    std_logic_vector(to_unsigned(524, 10) & to_unsigned(512115, 19)),
    std_logic_vector(to_unsigned(524, 10) & to_unsigned(512639, 19)),
    std_logic_vector(to_unsigned(523, 10) & to_unsigned(513162, 19)),
    std_logic_vector(to_unsigned(523, 10) & to_unsigned(513685, 19)),
    std_logic_vector(to_unsigned(522, 10) & to_unsigned(514207, 19)),
    std_logic_vector(to_unsigned(522, 10) & to_unsigned(514729, 19)),
    std_logic_vector(to_unsigned(521, 10) & to_unsigned(515250, 19)),
    std_logic_vector(to_unsigned(520, 10) & to_unsigned(515771, 19)),
    std_logic_vector(to_unsigned(520, 10) & to_unsigned(516291, 19)),
    std_logic_vector(to_unsigned(519, 10) & to_unsigned(516811, 19)),
    std_logic_vector(to_unsigned(519, 10) & to_unsigned(517330, 19)),
    std_logic_vector(to_unsigned(518, 10) & to_unsigned(517848, 19)),
    std_logic_vector(to_unsigned(518, 10) & to_unsigned(518367, 19)),
    std_logic_vector(to_unsigned(517, 10) & to_unsigned(518884, 19)),
    std_logic_vector(to_unsigned(517, 10) & to_unsigned(519401, 19)),
    std_logic_vector(to_unsigned(516, 10) & to_unsigned(519918, 19)),
    std_logic_vector(to_unsigned(516, 10) & to_unsigned(520434, 19)),
    std_logic_vector(to_unsigned(515, 10) & to_unsigned(520949, 19)),
    std_logic_vector(to_unsigned(515, 10) & to_unsigned(521464, 19)),
    std_logic_vector(to_unsigned(514, 10) & to_unsigned(521979, 19)),
    std_logic_vector(to_unsigned(514, 10) & to_unsigned(522493, 19)),
    std_logic_vector(to_unsigned(513, 10) & to_unsigned(523006, 19)),
    std_logic_vector(to_unsigned(513, 10) & to_unsigned(523519, 19)),
    std_logic_vector(to_unsigned(512, 10) & to_unsigned(524032, 19))
  );

  -- Signals
  signal TableAddr : std_logic_vector(log2ceil(TableSize_c) - 1 downto 0);
  signal TableData : std_logic_vector(TableWidth_c - 1 downto 0);

begin

  -- *** Calculation Unit ***
  i_calc : entity work.psi_fix_lin_approx_calc
    generic map(
      InFmt_g     => InFmt_c,
      OutFmt_g    => OutFmt_c,
      OffsFmt_g   => OffsFmt_c,
      GradFmt_g   => GradFmt_c,
      TableSize_g => TableSize_c
    )
    port map(
      -- Control Signals
      clk_i        => clk_i,
      rst_i        => rst_i,
      -- Input
      vld_i        => vld_i,
      dat_i        => dat_i,
      -- Output
      vld_o        => vld_o,
      dat_o        => dat_o,
      -- Table Interface
      addr_table_o => TableAddr,
      data_table_i => TableData
    );

  -- *** Table ***
  p_table : process(clk_i)
  begin
    if rising_edge(clk_i) then
      TableData <= Table_c(to_integer(unsigned(TableAddr)));
    end if;
  end process;

end architecture;
