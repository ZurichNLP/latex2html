#!/bin/bash
set -e

# Check arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <file.tex>"
    exit 1
fi

# Check if Pandoc is installed
if ! command -v pandoc > /dev/null; then
    echo "Error: Pandoc is not installed"
    exit 1
fi

# Check if ImageMagick is installed
if ! command -v convert > /dev/null; then
    echo "Error: ImageMagick is not installed"
    exit 1
fi


# Temporary file
tmpfile="$(mktemp -p . -t tmp.XXXXXXXXXX.tex)"
trap 'rm -f "$tmpfile"' EXIT

cp "$1" "$tmpfile"

# Find all included graphics (includegraphics or fillimage)
files=$(grep -Eo '\\(includegraphics|fillimage)(\[[^]]*\])?\{[^}]+\}' "$tmpfile" | sed -E 's/.*\{([^}]+)\}/\1/')

# Loop over each found file
for file in $files; do
    # Only convert if the file is a PDF
    if [ -f "$file.pdf" ]; then
        input="$file.pdf"
        output="${file}.png"
        echo "Converting $input -> $output"

        # Convert first page of PDF to PNG
        convert -density 300 "$input"[0] -trim +repage -quality 90 "$output"

        # Replace in tex file: {file} or {file.pdf} -> {file.png}
        sed -i.bak -E "s#\{${file}\}#\{${output}\}#g" "$tmpfile"
        rm "$tmpfile.bak"
    elif [ -f "$file" ] && [[ "$file" == *.pdf ]]; then
        input="$file"
        output="${file%.pdf}.png"
        echo "Converting $input -> $output"

        convert -density 300 "$input"[0] -trim +repage -quality 90 "$output"
        sed -i.bak -E "s#\{${file}\}#\{${output}\}#g" "$tmpfile"
        rm "$tmpfile.bak"
    else
        echo "Skipping non-PDF file: $file"
    fi
done


# Convert Beamer features not supported by Pandoc
sed -e 's/\\begin\s*{frame}\s*{\([^}]*\)}\s*{\([^}]*\)}/\\begin{frame}\n\\frametitle{\1}\n\\framesubtitle{\2}/g' \
    -e 's/\\begin\s*{frame}\s*{\([^}]*\)}/\\begin{frame}\n\\frametitle{\1}/g' \
    -e 's/\\begin\s*{column}\s*\(\[[^]]*\]\s*\)\?{[^}]*}/\\begin{column}/g' \
    -e 's/\\fillimage\(\s*\[\([^]]*\)\]\)\?\s*{[^}]*}\s*{[^}]*}\s*{\([^}]*\)}/\\includegraphics[\2]{\3}/g' \
    -e 's/\\imagecard\s*{\([^}]*\)}\s*{\([^}]*\)}\s*{\([^}]*\)}/\\includegraphics[alt={\2}]{\1} \\\\ \\textbf{\2} \\\\ \3/g' \
    -e 's/\\bigbreak/\\par\n\n/g' \
    -e 's/\$\s*\\rightarrow\s*\$/→/g' \
    "$tmpfile" > "${tmpfile}.converted"

mv "${tmpfile}.converted" "$tmpfile"

# Convert to HTML
pandoc "$tmpfile" -f latex -t html --standalone --shift-heading-level-by=1 --wrap=none --embed-resources --mathjax --citeproc > "${1%.tex}.html"

# Remove uzh@blue spans and <em> tags
sed -E -i.bak \
  -e 's#<span style="[^"]*uzh@blue[^"]*">([^<]*)</span>#\1#g' \
  -e 's#<em>([^<]*)</em>#\1#g' \
  -e 's#<strong>([^<]*)</strong>#\1#g' \
  "${1%.tex}.html"
rm "${1%.tex}.html.bak"

python fix_headers.py --deduplicate-headings "${1%.tex}.html" "${1%.tex}.html"