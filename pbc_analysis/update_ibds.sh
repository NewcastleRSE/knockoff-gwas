source ./set_dirs.sh

for f in "$DATA"/Nicola_ibd_chr*.txt; do
  head -n 2 "$f" > "$f.tmp" && mv "$f.tmp" "$f"
done

for f in "$DATA"/Nicola_ibd_chr*.txt; do
  echo "=== $f ==="
  head -n 3 "$f"
done

