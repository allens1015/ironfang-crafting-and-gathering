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

my ($gathering_potential,$crafting_potential);

# parsing arg input
foreach my $arg (@ARGV) {
	if($arg =~ /--g=(.*)/) { $gathering_potential = $1; }
  if($arg =~ /--c=(.*)/) { $crafting_potential = $1; }
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
  print "Intersect at:\n";
  print "Gathering $gathering_actual gp // $gathering_percent%\n";
  print "Crafting $crafting_actual gp // $crafting_percent%\n\n";
  for my $i (0..scalar @diff_arr-1) {
    if($i == 0 or $i % 100 == 0) {
      my $g_per_inter = (1000-$i)/10;
      my $c_per_inter = $i/10;
      my $g_actual_inter = $gathering_potential * ($g_per_inter/100);
      my $c_actual_inter = $crafting_potential * ($c_per_inter/100);
      print "G/C $g_per_inter/$c_per_inter: $g_actual_inter // $c_actual_inter\n";
    }
  }
}
else {
  #gathering
  my @npc_gather_output = &process_data($npc_gather_data,$earn_income_data,$gather_mod_limit);
  my @pc_gather_output = &process_data($pc_gather_data,$earn_income_data,$gather_mod_limit);
  my @pc_npc_gather_output = ();
  for my $i(0..$gather_mod_limit) {
    my $combined_val = $npc_gather_output[$i] + $pc_gather_output[$i];
    push(@pc_npc_gather_output,$combined_val);
  }

  #crafting
  my @npc_craft_output = &process_data($npc_craft_data,$earn_income_data,$craft_mod_limit);
  my @pc_craft_output = &process_data($pc_craft_data,$earn_income_data,$craft_mod_limit);
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
  my ($scalar_data,$scalar_earn_income_data,$output_length) = @_;
  my @data_arr = @{$scalar_data};
  my @earn_income_arr = @{$scalar_earn_income_data};
  my @output_money = ();

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
    push(@output_money,$total_money_generated);
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