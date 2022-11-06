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

#ok so what i want to see is table outputs-
#i want npc craft/gather, pc craft/gather, npc+pc craft+gather for terrain mods -2 to 6 for gathering and -2 to 2 for crafting
#so we need to get the level/teml aka row/col of earn income and tally up the totals for each member
#lets focus on one, npc gather

if($gathering_potential && $crafting_potential) {
  #midpoint
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
  my $gathering_percent = $correct_index/10;
  my $crafting_percent = 100-$gathering_percent;
  my $gathering_actual = $gathering_potential * ($gathering_percent/100);
  my $crafting_actual = $crafting_potential * ($crafting_percent/100);
  print "Intersect at:\n";
  print "Gathering $gathering_actual gp // $gathering_percent%\n";
  print "Crafting $crafting_actual gp // $crafting_percent%\n";
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
      my $level = int($1) + $i;
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