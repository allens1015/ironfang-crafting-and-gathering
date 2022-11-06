#!/usr/bin/perl

use JSON;
use Data::Dumper;

my $earn_income_data = &get_json("earn-income.json");
my $npc_gather_data = &get_json("camp-data-npc-gather.json");
my $npc_craft_data = &get_json("camp-data-npc-craft.json");
my $pc_gather_data = &get_json("camp-data-pc-gather.json");
my $pc_craft_data = &get_json("camp-data-pc-craft.json");

#ok so what i want to see is table outputs-
#i want npc craft/gather, pc craft/gather, npc+pc craft+gather for terrain mods -2 to 6 for gathering and -2 to 2 for crafting
#so we need to get the level/teml aka row/col of earn income and tally up the totals for each member
#lets focus on one, npc gather



foreach my $row (@{$earn_income_data}) {
  foreach my $col (@{$row}) {
    
  }
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