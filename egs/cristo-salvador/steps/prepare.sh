#!/bin/bash
set -e;

# Directory where the prepare.sh script is placed.
SDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)";
[ "$(pwd)/steps" != "$SDIR" ] && \
    echo "Please, run this script from the experiment top directory!" && \
    exit 1;
[ ! -f "$(pwd)/utils/parse_options.inc.sh" ] && \
    echo "Missing $(pwd)/utils/parse_options.inc.sh file!" >&2 && exit 1;

overwrite=false;
height=64;
help_message="
Usage: ${0##*/} [options]

Options:
  --height     : (type = integer, default = $height)
                 Scale lines to have this height, keeping the aspect ratio
                 of the original image.
  --overwrite  : (type = boolean, default = $overwrite)
                 Overwrite previously created files.
";
source "$(pwd)/utils/parse_options.inc.sh" || exit 1;

[ -d data/corpus/Line-Level -a -s data/corpus/train_book.lst \
    -a -s data/corpus/test_book.lst ] || \
    ( echo "The CS database is not available!">&2 && exit 1; );

mkdir -p data/lang/chars data/lang/words;

for p in train test; do
    [ -f data/lang/words/$p.orig.txt -a \
      -f data/lang/words/$p.expanded.txt -a \
      -f data/lang/chars/$p.txt -a "$overwrite" = false ] && continue;
    # Convert from ISO-8859-1 to UTF-8 and put all transcripts in a single
    # file.
    for f in $(tail -n+2 data/corpus/${p}_book.lst); do
	echo -n "$f ";
	sed -r 's|[ \t]+| |g;s|^ ||g;s| $||g;s|_| |g' data/corpus/Line-Level/$f.txt;
    done | sort -V > data/lang/words/$p.orig.txt;
    # Write words fully expanded, without the expansion mark symbols:
    # S[eño]r -> Señor ; D[octo]r -> Doctor
    sed -r 's/(\[|\]|\<|\>)//g' data/lang/words/$p.orig.txt \
	> data/lang/words/$p.expanded.txt;
    # Write words as they are written in the text lines:
    # S[eño]r -> Sr. ; D[octo]r -> Dr.
    # <él>  -> ;
    # For the character-level transcripts, use @ as the whitespace symbol.
    sed -r 's/(\S*\[\S*\]\S*)/\1./g;s/\[\S*\]//g;s/<\S*>//g' \
	data/lang/words/$p.orig.txt | awk '{
      printf("%s", $1);
      for (i=2; i<=NF; ++i) {
        for(j=1;j<=length($i);++j) {
          printf(" %s", substr($i, j, 1));
        }
        if (i < NF) printf(" @");
      }
      printf("\n");
    }' > data/lang/chars/$p.txt;
done;

# Generate symbols table from training and valid characters.
# This table will be used to convert characters to integers by Kaldi and the
# CNN + RNN + CTC code.
[ -s data/lang/chars/symbs.txt -a $overwrite = false ] || (
    awk '{$1=""; print;}' data/lang/chars/train.txt | tr \  \\n | sort -uV | \
    awk 'BEGIN{N=1;}NF==1{ printf("%-10s %d\n", $1, N); N++; }' \
    > data/lang/chars/symbs.txt;
)

## Enhance images with Mauricio's tool, crop image white borders and resize
## to a fixed height.
mkdir -p data/imgs_proc;
TMPD="$(mktemp -d)";
bkg_pids=();
np="$(nproc)";
for f in $(awk '{print $1}' data/lang/chars/train.txt data/lang/chars/test.txt); do
    [ -f data/imgs_proc/$f.jpg -a $overwrite = false ] && continue;
    [ ! -f data/corpus/Line-Level/$f.png ] && \
	echo "Image data/corpus/Line-Level/$f.png is not available!">&2 && exit 1;
    (
	echo "File data/corpus/Line-Level/$f.png..." >&2;
	imgtxtenh -u mm -d 118.1102362205 data/corpus/Line-Level/$f.png data/imgs_proc/$f.jpg;
	slope="$(convert data/imgs_proc/$f.jpg +repage -flatten -deskew 40% \
            -print '%[deskew:angle]\n' +repage data/imgs_proc/$f.jpg)";
	slant="$(imageSlant -v 1 -g -i ${ff}_deslope.png -o ${ff}_deslant.png \
            2>&1 | sed -n '/Slant medio/{s|.*: ||;p;}')";
	trim="$(convert data/imgs_proc/$f.jpg -fuzz 5% -trim \
            -print '%@'+repage data/imgs_proc/$f.jpg)";
	convert data/imgs_proc/$f.jpg -resize "x$height" -strip \
	    data/imgs_proc/$f.jpg;
    ) > "$TMPD/${#bkg_pids[@]}.out" 2> "$TMPD/${#bkg_pids[@]}.err" &
    bkg_pids+=("$!");
    if [ "${#bkg_pids[@]}" -eq "$np" ]; then
	for n in $(seq 1 "${#bkg_pids[@]}"); do
	    wait "${bkg_pids[n-1]}" || (
                echo "Failed image processing step:" >&2 && \
                    cat "$TMPD/$[n-1].err" >&2 && exit 1;
	    );
	done;
	bkg_pids=();
    fi;
done;
rm -rf "$TMPD";

## Prepare test, train and valid files.
awk '{ print "data/imgs_proc/"$1".jpg"; }' data/lang/chars/test.txt > data/test.lst;
TMPF="$(mktemp)";
sort -R --random-source=data/lang/chars/train.txt data/lang/chars/train.txt | \
    awk '{ print "data/imgs_proc/"$1".jpg"; }' > "$TMPF";
head -n100  "$TMPF" | sort -V > data/valid.lst;
tail -n+101 "$TMPF" | sort -V > data/train.lst;
rm -f "$TMPF";

exit 0;