from bs4 import BeautifulSoup


def correct_headings(html):
    soup = BeautifulSoup(html, "html.parser")
    headings = soup.find_all(["h1", "h2", "h3", "h4", "h5", "h6"])

    level_stack = []  # remember level

    for heading in headings:
        level = int(heading.name[1])

        if not level_stack:
            # start at h1
            level_stack.append(level)
            heading.name = "h1"
            continue

        prev_level = level_stack[-1]

        if level > prev_level:
            # Sublevel +1 in the hierarchy
            new_level = len(level_stack) + 1
            level_stack.append(level)
        elif level == prev_level:
            # same level → same relative level
            new_level = len(level_stack)
        else:
            # up in the hierarchy
            while level_stack and level_stack[-1] >= level:
                level_stack.pop()
            level_stack.append(level)
            new_level = len(level_stack)

        heading.name = f"h{new_level}"

    return soup


def unique_headings(soup):
    headings = soup.find_all(["h1", "h2", "h3", "h4", "h5", "h6"])

    # Count total occurrences of each heading title
    title_total = {}
    for heading in headings:
        title = heading.get_text()
        title_total[title] = title_total.get(title, 0) + 1

    # Append occurrence numbers to duplicate titles
    title_count = {}
    for heading in headings:
        title = heading.get_text()
        if title_total[title] > 1:
            title_count[title] = title_count.get(title, 0) + 1
            heading.string = f"{title} {title_count[title]}/{title_total[title]}"

    return soup


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        description="Correct heading levels in an HTML file."
    )
    parser.add_argument(
        "input_file",
        default=argparse.FileType("r"),
        help="Path to the input HTML file.",
    )
    parser.add_argument(
        "output_file",
        default=argparse.FileType("w"),
        help="Path to the output HTML file.",
    )
    parser.add_argument(
        "--deduplicate-headings",
        action="store_true",
        help="Make headings unique by appending occurrence numbers.",
    )
    args = parser.parse_args()
    with open(args.input_file, "r", encoding="utf-8") as infile:
        html_content = infile.read()

    corrected_html = correct_headings(html_content)
    if args.deduplicate_headings:
        corrected_html = unique_headings(corrected_html)

    with open(args.output_file, "w", encoding="utf-8") as outfile:
        outfile.write(str(corrected_html))
