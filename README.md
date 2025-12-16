# latex2html

The UZH latex corporate design is distributed with a latex2html script (by Andreas Säuberli).
This repository includes additions to that script, implementing the following:

- [x] Heading hierarchy is fixed. Now only the title attribute is tagged as  `<h1>`. With `--shift-heading-level-by=1`, `pandoc` translates latex as follows:
  - \title --> h1
  - \section --> h2
  - \subsection --> h3
  - \frametitle --> h4
  - \subsubsection --> h4
  - \framesubtitle h5
  
  The python script `fix_headers.py` removes any skipped levels (e.g. if no subsections were used) and automatically detects and numbers duplicate headings.

- [x]  \bigbreak should be represented with `<p>`...`</p>` in the html. Solved: `sed -e 's/\\bigbreak/\\par\n\n/g'`
- [x] `<em>` causes problems. Removed, but what about `<strong>`?? Also see: https://www.w3.org/TR/2016/NOTE-WCAG20-TECHS-20161007/H49 
- [x] removed `<span style="color: uzh@blue">`. Mostly solved: sed command over html. requires --wrap=none setting in pandoc. fails when other html tag is nested in span.
- [x] replace `$\rightarrow$`. Solved: `sed -e 's/\$\s*\\rightarrow\s*\$/→/g'`
- [x] PDF images are converted to png before calling pandoc.
- [ ] Bibliography is not present in html
- [ ] Videos are not present in html


## Requirements
- ImageMagick
- Pandoc