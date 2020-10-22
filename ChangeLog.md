
# AH Formatter Analysis Utility 7.0.5

Corresponds to AH Formatter V7.0 MR5.

- Thumbnail errors in layers.
- Handling page numbers in formats that `xsl:number` understands.
- Also showing total page count in footer.
- Added `-show no` option to not launch PDF reader.
- Added Japanese translation in `README.md`.

# AH Formatter Analysis Utility 7.0.4

Corresponds to AH Formatter V7.0 MR4.

- `analyzer.sh` can now run 'report' result format.
- `analyzer.bat` now handling HTML source files.
- Add two-word 'character limit' message part.
- Calculate available width for second page in spreads.

# AH Formatter Analysis Utility 7.0.3

Corresponds to AH Formatter V7.0 MR3.

- Error callouts show error message as tool-tip.
- Callouts link back to message.
- Page thumbnails for pages without error show page number as tool-tip.
- `format-number()` for page number and error counts.
- Smarter `text-indent` values for error messages.
- Table border changes.
- Show absolute page number only if different from formatted page number.
- Log file for PDFs now `*.pdf.log`.
- More comparing file dates with date of `AHFCmd.exe` file.
- Working around `(86)` in `%AHF70_HOME%` value causing problems with DOS statements.
- Better handling of spaces in file and directory names.
- `ahf:l10n()` result as single string.

# AH Formatter Analysis Utility v7.0.2

Corresponds to AH Formatter V7.0 MR2.

- Summary table includes totals for each error type.
- Thumbnail hover text lists counts of error types instead of all error messages.
- Default 'report' stylesheet is 'compact-report.xsl'.
- 'compact' report typically six pages per report page.
- Added `-pdfver` option for PDF version of reports.
- Better handling hyphen errors where only one error has a message.
- Callouts only for errors with a message.
- Error message changes.
- Handling an Option Setting File with `(` and `)` in filename.
- Merging adjacent identical messages.
- Not showing AH Formatter version in report PDF.
- Better able to run Ant from a different directory.
- Consistent namespace for functions.
- Simplified XSLT stylesheet names.
- Updated l10n.
- More named templates.
- Deconstructing templates in main report stylesheet for easier reuse.
- Better generation of spaces in comments.

# AH Formatter Analysis Utility v7.0.1

Initial release.

Corresponds to AH Formatter V7.0 MR1.
