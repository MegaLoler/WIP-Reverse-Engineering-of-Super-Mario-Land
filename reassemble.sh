wla-gb -o supermarioland.o supermarioland.asm
wlalink -s link supermarioland_again.gb
diff supermarioland.gb supermarioland_again.gb
