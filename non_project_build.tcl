#!/usr/bin/tclsh

# STEP#1: define the output directory area.
#
set outputDir $::env(OUTPUT)
# file delete -force -- $outputDir
file mkdir $outputDir

set topModule $::env(TOP)
set rtlDir $::env(RTL)
set xdcDir $::env(XDC)
set synthOnly $::env(SYNTHONLY)

# STEP#2: setup design sources and constraints
#
read_verilog [ glob $rtlDir/*.v ]
read_xdc [ glob $xdcDir/*.xdc ]

# STEP#3: run synthesis, write design checkpoint, report timing,
# and utilization estimates
#
set_param general.maxthreads 24
set device [get_parts xcvu9p-flga2104-2L-e]; # xcvu9p_CIV-flga2577-2-e; #
set_part $device
report_property $device -file $outputDir/pre_synth_dev_prop.rpt

synth_design -top $topModule -retiming
write_checkpoint -force $outputDir/post_synth.dcp
# Generated XDC file should be less than 1MB, otherwise too many constraints.
write_xdc -force -exclude_physical $outputDir/post_synth.xdc

# Check 1) slack, 2) requirement, 3) src and dst clocks, 4) datapath delay, 5) logic level, 6) skew and uncertainty.
report_timing_summary -report_unconstrained -warn_on_violation -file $outputDir/post_synth_timing_summary.rpt
# Check 1) endpoints without clock, 2) combo loop and 3) latch.
check_timing -override_defaults no_clock -file $outputDir/post_synth_check_timing.rpt
report_clock_networks -file $outputDir/post_synth_clock_networks.rpt; # Show unconstrained clocks
report_clock_interaction -delay_type min_max -significant_digits 3 -file $outputDir/post_synth_clock_interaction.rpt; # Pay attention to Clock pair Classification, Inter-CLock Constraints, Path Requirement (WNS)
report_high_fanout_nets -timing -load_type -max_nets 100 -file $outputDir/post_synth_fanout.rpt
report_exceptions -ignored -file $outputDir/post_synth_exceptions.rpt; # -ignored -ignored_objects -write_valid_exceptions -write_merged_exceptions

# 1 LUT + 1 net have delay 0.5ns, if cycle period is Tns, logic level is 2T at most
# report_design_analysis -timing -max_paths 100 -file $outputDir/post_synth_design_timing.rpt
report_design_analysis -setup -max_paths 100 -file $outputDir/post_synth_design_setup_timing.rpt
report_design_analysis -logic_level_dist_paths 100 -min_level 4 -max_level 20 -file $outputDir/post_synth_design_logic_level.rpt
report_design_analysis -logic_level_dist_paths 100 -logic_level_distribution -file $outputDir/post_synth_design_logic_level_dist.rpt
report_timing -of_objects [get_timing_paths -setup -to [get_clocks main_clock] -max_paths 100 -filter {LOGIC_LEVELS>=16 && LOGIC_LEVELS<=20}] -file $outputDir/post_synth_long_paths.rpt

report_datasheet -file $outputDir/post_synth_datasheet.rpt
xilinx::designutils::report_failfast -detailed_reports synth -file $outputDir/post_synth_failfast.rpt

report_drc -file $outputDir/post_synth_drc.rpt
report_drc -ruledeck methodology_checks -file $outputDir/post_synth_drc_methodology.rpt
report_drc -ruledeck timing_checks -file $outputDir/post_synth_drc_timing.rpt

# intra-clock skew < 300ps, inter-clock skew < 500ps

# Check 1) LUT on clock tree (TIMING-14), 2) hold constraints for multicycle path constraints (XDCH-1).
report_methodology -file $outputDir/post_synth_methodology.rpt
report_timing -max 100 -slack_less_than 0 -file $outputDir/post_synth_timing.rpt

report_compile_order -constraints -file $outputDir/post_synth_constraints.rpt; # Verify IP constraints included
report_utilization -file $outputDir/post_synth_util.rpt; # -cells -pblocks
report_cdc -file $outputDir/post_synth_cdc.rpt
report_clocks -file $outputDir/post_synth_clocks.rpt; # Verify clock settings

# Use IS_SEQUENTIAL for -from/-to
# Instantiate XPM_CDC modules
#write_xdc -force -exclude_physical -exclude_timing -constraints INVALID

report_qor_assessment -report_all_suggestions -csv_output_dir $outputDir -file $outputDir/post_synth_qor_assess.rpt
if { $synthOnly } {
    puts "synthOnly=$synthOnly"
    exit
}

# STEP#4: run logic optimization, placement and physical logic optimization,
# write design checkpoint, report utilization and timing estimates
#
opt_design -remap
power_opt_design
place_design
# Optionally run optimization if there are timing violations after placement
if {[get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -setup]] < 0} {
    puts "Found setup timing violations => running physical optimization"
    phys_opt_design
}
write_checkpoint -force $outputDir/post_place.dcp
write_xdc -force -exclude_physical $outputDir/post_place.xdc

report_clock_utilization -file $outputDir/post_place_clock_util.rpt
report_methodology -file $outputDir/post_place_methodology.rpt
report_timing_summary -report_unconstrained -warn_on_violation -file $outputDir/post_place_timing_summary.rpt
report_timing -max 100 -slack_less_than 0 -file $outputDir/post_place_timing.rpt
report_utilization -file $outputDir/post_place_util.rpt; # -cells -pblocks -slr

# STEP#5: run the router, write the post-route design checkpoint, report the routing
# status, report timing, power, and DRC, and finally save the Verilog netlist.
#
route_design

proc runPPO { {numIters 1} {enablePhysOpt 1} } {
    for {set idx 0} {$idx < $numIters} {incr idx} {
        place_design -post_place_opt; # Better to run after route
        if {$enablePhysOpt != 0} {
            phys_opt_design
        }
        route_design
        if {[get_property SLACK [get_timing_paths ]] >= 0} {
            break; # Stop if timing closure
        }
    }
}

runPPO 4 1; # numIters=4, enablePhysOpt=1

write_checkpoint -force $outputDir/post_route.dcp
write_xdc -force -exclude_physical $outputDir/post_route.xdc

report_route_status -file $outputDir/post_route_status.rpt
report_drc -file $outputDir/post_route_drc.rpt
report_drc -ruledeck methodology_checks -file $outputDir/post_route_drc_methodology.rpt
report_drc -ruledeck timing_checks -file $outputDir/post_route_drc_timing.rpt

report_methodology -file $outputDir/post_route_methodology.rpt
report_timing_summary -report_unconstrained -warn_on_violation -file $outputDir/post_route_timing_summary.rpt
report_timing -max 100 -slack_less_than 0 -file $outputDir/post_route_timing.rpt
report_power -file $outputDir/post_route_power.rpt
report_power_opt -file $outputDir/post_route_power_opt.rpt
report_utilization -file $outputDir/post_route_util.rpt
# Check unique control sets < 7.5% of total slices, at most 15%
report_control_sets -verbose -file $outputDir/post_route_control_sets.rpt

report_methodology -file $outputDir/post_route_methodology.rpt
report_ram_utilization -detail -file $outputDir/post_route_ram_utils.rpt
# Check fanout < 25K
report_high_fanout_nets -file $outputDir/post_route_fanout.rpt

report_design_analysis -hold -max_paths 100 -file $outputDir/post_route_design_hold_timing.rpt
# Check initial estimated router congestion level no more than 5, type (global, long, short) and top cells
report_design_analysis -congestion -file $outputDir/post_route_congestion.rpt
# Check difficult modules (>15K cells) with high Rent Exponent (complex logic cone) >= 0.65 and/or Avg. Fanout >= 4
report_design_analysis -complexity -file $outputDir/post_route_complexity.rpt; # -hierarchical_depth
# If congested, check problematic cells using report_utilization -cells
# If congested, try NetDelay* for UltraScale+, or try SpredLogic* for UltraScale in implementation strategy

xilinx::designutils::report_failfast -detailed_reports impl -file $outputDir/post_route_failfast.rpt
# xilinx::ultrafast::report_io_reg -file $outputDir/post_route_io_reg.rpt
report_io -file $outputDir/post_route_io.rpt
report_pipeline_analysis -file $outputDir/post_route_pipeline.rpt
report_qor_assessment -report_all_suggestions -csv_output_dir $outputDir -file $outputDir/post_route_qor_assess.rpt
report_qor_suggestions -report_all_suggestions -csv_output_dir $outputDir -file $outputDir/post_route_qor_suggest.rpt

write_verilog -force $outputDir/post_impl_netlist.v -mode timesim -sdf_anno true

# STEP#6: generate a bitstream
#
# write_bitstream -force $outputDir/top.bit
