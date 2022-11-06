# ironfang-crafting-and-gathering
 Updated C+G tool for IF2022

So for when i forget how to use this:
The earn income json never changes
The four pc/npc json items do change, and their format is level:teml, t=0 e=1 m=2 l=3
So if someone levels up, bump it up. If they go T to E, bump it up. If they die, drop their level:teml entry from the array. The math all happens automatically

Input --g=# --c=# to find the percentage/actual intersect of gathering/crafting potentials. Uses a 1000-point curve where 0 is the closest value.