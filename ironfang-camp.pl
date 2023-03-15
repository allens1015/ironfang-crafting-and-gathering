#!/usr/bin/perl

use JSON;
use Data::Dumper;

my $earn_income_data = &get_json("earn-income.json");
my $npc_gather_data = &get_json("camp-data-npc-gather.json");
my $npc_craft_data = &get_json("camp-data-npc-craft.json");
my $pc_gather_data = &get_json("camp-data-pc-gather.json");
my $pc_craft_data = &get_json("camp-data-pc-craft.json");
my $gather_mod_limit = 8;
my $craft_mod_limit = 4;
my $fatigue_percent = 0;

# bonus: calculate the gp reqs for food and shelter
my ($gathering_hex_value, $crafting_hex_value) = 0;
my ($feeding_count, $sheltering_count) = 0;
my @food_costs = (0.2, 0.3, 0.5);
my @shelter_costs = (0.3, 0.5, 0.7);


my ($gathering_potential,$crafting_potential,$material_cost,$labor_cost);

# parsing arg input
foreach my $arg (@ARGV) {
  # gathering gp value
	if($arg =~ /--g=(.*)/) { $gathering_potential = $1; }
  # gathering hex value
  if($arg =~ /--gx=(.*)/) { $gathering_hex_value = $1; }
  # crafting gp value
  if($arg =~ /--c=(.*)/) { $crafting_potential = $1; }
  # crafting hex value
  if($arg =~ /--cx=(.*)/) { $crafting_hex_value = $1; }
  # material cost for project
  if($arg =~ /--m=(.*)/) { $material_cost = $1; }
  # labor cost for project
  if($arg =~ /--l=(.*)/) { $labor_cost = $1; }
  # number in party needing food
  if($arg =~ /--f=(.*)/) { $feeding_count = $1; }
  # number in party needing shelter
  if($arg =~ /--s=(.*)/) { $sheltering_count = $1; }
  # percentage to reduce totals for fatigue rating
  if($arg =~ /--p=(.*)/) { $fatigue_percent = $1; }
}

if($gathering_potential && $crafting_potential) {
  #midpoint
  #basically create a 1000-point bell curve that represents percentages to 0.1%- find the values of gathering and crafting at 100/0% of each, step one up by 0.1% and one down by 0.1%, get the values
  #then record the diffs between those values- the closest point to 0 will be the intersection
  my $step = 1;
  my @diff_arr = ();
  for(my $i = 1000; $i >= 0; $i -= $step) {
    my $g_per = $i*0.001;
    my $c_per = 1 - ($i*0.001);
    my $g_val = $g_per * $gathering_potential;
    my $c_val = $c_per * $crafting_potential;
    my $diff = $g_val - $c_val;
    # print "I: $i // DIFF: $diff -- gper: $g_per // cper: $c_per -- gval: $g_val // cval: $c_val\n";
    push(@diff_arr,$diff);
  }

  my $correct_index = 0;
  for my $i (0..scalar @diff_arr-1) {
    if($diff_arr[$i] < 0) {
      #for SOME reason, array ordering i think, the array here is backwards- i=715 is really i=286, array length-1 flipped kind of logic. real_i tracks this
      #get the 2 points above and below the 0 line, figure out which is closer, and that's our answer
      my $real_i = abs(1001-$i);
      my $below_zero = $diff_arr[$real_i];
      my $above_zero = $diff_add[$real_i-1];
      # print "result at i=$i  but its really at $real_i\n";
      $correct_index = $real_i-1;
      if(abs($below_zero) > abs($above_zero)) {
        $correct_index = $real_i;
      }
      last;
    }
  }
  #/10 because the percent is 3 sig figs instead of 2
  #math out and display the derived values

  my $gathering_percent = $correct_index/10;
  my $crafting_percent = 100-$gathering_percent;
  my $gathering_actual = $gathering_potential * ($gathering_percent/100);
  my $crafting_actual = $crafting_potential * ($crafting_percent/100);

  my $material_labor_ratio = 0;
  my $ml_actual_ratio = 0;
  my $ml_ratio_diff = 1;
  my $ml_ratio_correct_index = 0;
  my $ml_ratio_correct_m;
  my $ml_ratio_correct_l;
  if($material_cost && $labor_cost) {
    $material_labor_ratio = $material_cost/$labor_cost;
    $ml_ratio_correct_m = $material_cost;
    $ml_ratio_correct_l = $labor_cost;
  }
  
  print "Intersect at:\n";
  print "Gathering $gathering_actual gp // $gathering_percent%\n";
  print "Crafting $crafting_actual gp // $crafting_percent%\n\n";
  #for every entry in the array of diffs
  for my $i (0..scalar @diff_arr-1) {
    my $g_per_inter = (1000-$i)/10;
    my $c_per_inter = $i/10;
    #calc the actual vals
    my $g_actual_inter = $gathering_potential * ($g_per_inter/100);
    my $c_actual_inter = $crafting_potential * ($c_per_inter/100);
    #if you provided m/l
    if($material_labor_ratio > 0 && $c_actual_inter > 0) {
      #find the ratio of the current index of m/l
      $ml_actual_ratio = $g_actual_inter/$c_actual_inter;
    }
    my $ml_abs_diff = abs($material_labor_ratio - $ml_actual_ratio);
    # print "TEST: ml abs diff: $ml_abs_diff\n";
    # print "=======TEST: ratio diff: $ml_ratio_diff\n";
    if($ml_abs_diff < $ml_ratio_diff) {
      # print "=======SETTING ml_ratio_diff to $ml_abs_diff\n";
      $ml_ratio_diff = $ml_abs_diff;
      $ml_ratio_correct_index = $i;
      $ml_ratio_correct_m = $g_actual_inter;
      $ml_ratio_correct_l = $c_actual_inter;
    }

    if($i == 0 or $i % 100 == 0) {
      print "G/C $g_per_inter/$c_per_inter: $g_actual_inter // $c_actual_inter\n";
    }
  }
  if($ml_ratio_correct_m && $ml_ratio_correct_l) {
    # print "\nTesting ratios (M/L): $material_labor_ratio\n";
    print "\nOptimal ratio split for project: G/C: $ml_ratio_correct_m // $ml_ratio_correct_l\n";
    my $time_to_complete = $material_cost / $ml_ratio_correct_m;
    print "Time to complete: $time_to_complete days\n\n";
  }
}
elsif($feeding_count > 0 || $sheltering_count > 0) {
  my $selected_food_cost = $food_costs[0];
  if(int($gathering_hex_value) eq -1) { $selected_food_cost = ($food_costs[1]); }
  elsif(int($gathering_hex_value) < -1) { $selected_food_cost = ($food_costs[2]); }

  my $selected_shelter_cost = $shelter_costs[0];
  if(int($crafting_hex_value) eq -1) { $selected_shelter_cost = ($shelter_costs[1]); }
  elsif(int($crafting_hex_value) < -1) { $selected_shelter_cost = ($shelter_costs[2]); }

  my $total_food_cost = $feeding_count * $selected_food_cost;
  my $total_sheltering_cost = $sheltering_count * $selected_shelter_cost;

  print "totals:\nfood: $total_food_cost gp\n    $selected_food_cost gp per unit\nshelter: $total_sheltering_cost gp\n    $selected_shelter_cost gp per unit\n";
}
else {
  #gathering
  my @npc_gather_output = &process_data($npc_gather_data,$earn_income_data,$gather_mod_limit,$fatigue_percent);
  my @pc_gather_output = &process_data($pc_gather_data,$earn_income_data,$gather_mod_limit,$fatigue_percent);
  my @pc_npc_gather_output = ();
  for my $i(0..$gather_mod_limit) {
    my $combined_val = $npc_gather_output[$i] + $pc_gather_output[$i];
    push(@pc_npc_gather_output,$combined_val);
  }

  #crafting
  my @npc_craft_output = &process_data($npc_craft_data,$earn_income_data,$craft_mod_limit,$fatigue_percent);
  my @pc_craft_output = &process_data($pc_craft_data,$earn_income_data,$craft_mod_limit,$fatigue_percent);
  my @pc_npc_craft_output = ();
  for my $i(0..$craft_mod_limit) {
    my $combined_val = $npc_craft_output[$i] + $pc_craft_output[$i];
    push(@pc_npc_craft_output,$combined_val);
  }


  print "GATHERING:\n";
  &display("=====COM=====",@pc_npc_gather_output);
  &display("=====NPC=====",@npc_gather_output);
  &display("=====PC=====",@pc_gather_output);
  print "\n\n";
  print "CRAFTING:\n";
  &display("=====COM=====",@pc_npc_craft_output);
  &display("=====NPC=====",@npc_craft_output);
  &display("=====PC=====",@pc_craft_output);
}

sub display {
  my $header = shift;
  my (@arr) = @_;
  print "$header\n";
  for my $i (0..scalar @arr-1) {
    my $mod = $i-2;
    print "$mod = ".$arr[$i]."\n";
  }
}

# ----------
sub process_data {
  my ($scalar_data,$scalar_earn_income_data,$output_length,$fatigue_percent) = @_;
  my @data_arr = @{$scalar_data};
  my @earn_income_arr = @{$scalar_earn_income_data};
  my @output_money = ();
  my $fatigue_scale = 1-$fatigue_percent;

  #for every terrain level up to output length, which is 4 or 8
  for my $i (0..$output_length) {
    #mod is separate, i needs to be 0 for -2
    my $mod = $i-2;
    my $total_money_generated = 0;
    #for each npc
    foreach my $row (@data_arr) {
      #split the data formatting up into level/teml
      $row =~ /(\d+)\:(\d+)/;
      my $level = int($1) + $mod;
      if($level < 0) {
        $level = 0;
      }
      my $teml = int($2);
      #get the val and sum it to the running tally
      my $money_generated = $earn_income_arr[$level][$teml];
      $total_money_generated += $money_generated;
    }

    push(@output_money,($total_money_generated * $fatigue_scale));
  }

  return @output_money;
}

# ----------
sub get_json {
  my ($filename) = @_;
  my $file_data;
  open my $h, '<:encoding(UTF-8)', $filename;
    $file_data = <$h>;
  close $h;

  my $json_enc = decode_json($file_data);

  return $json_enc;
}