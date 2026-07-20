# `/output/` Directory Structure

This directory contains all generated output files for tables and figures used in the paper. 

The outputs are organized in directories that match paper sections: main paper, appendix, and supplemental appendix.

```
📁output/
├── 📁 overleaf_figures/                        # Figures for the main paper
│   ├── 📄 *.pdf                                # PDF versions of figures
│   └── 📄 *.tex                                # LaTeX code for figures
│
├── 📁 overleaf_figures_appendix/               # Figures for the appendix
│   ├── 📄 *.pdf                                # PDF versions of figures
│   └── 📄 *.tex                                # LaTeX code for figures
│
├── 📁 overleaf_figures_supplementalappendix/   # Figures for the supplemental appendix
│   ├── 📄 *.pdf                                # PDF versions of figures
│   └── 📄 *.tex                                # LaTeX code for figures
│
├── 📁 overleaf_tables/                         # Tables for the main paper
│   └── 📄 *.tex                                # LaTeX code for tables
│
├── 📁 overleaf_tables_appendix/                # Tables for the appendix
│   └── 📄 *.tex                                # LaTeX code for tables
│
└── 📁 overleaf_tables_supplementalappendix/    # Tables for the supplemental appendix
│   └── 📄 *.tex                                # LaTeX code for tables
```

## File Types

* **TEX files**: LaTeX code for tables and figures that can be directly included in the paper.
* **PDF files**: PDF versions of figures, primarily for preview purposes.

## Organization

The directory structure mirrors the paper organization:
- Main paper materials: `overleaf_figures/` and `overleaf_tables/`
- Appendix materials: `overleaf_figures_appendix/` and `overleaf_tables_appendix/`
- Supplemental appendix: `overleaf_figures_supplementalappendix/` and `overleaf_tables_supplementalappendix/` 