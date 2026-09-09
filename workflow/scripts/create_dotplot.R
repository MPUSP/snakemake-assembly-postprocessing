library(pafr, quietly=TRUE)
library(readr, quietly=TRUE)

paf_file <- snakemake@input[["query"]]
output_file <- snakemake@output[["pdf"]]
output_png <- snakemake@output[["png"]]
target_name <- snakemake@params[["target"]]
query_name <- snakemake@params[["query"]]

messages <- c()

alignments <- read_paf(paf_file)

# Create plot without printing to avoid Rplots.pdf
p <- dotplot(alignments, xlab = query_name, ylab = target_name) +
    theme_bw() +
    theme(
        axis.text.x = element_text(size = 12, face="bold"),
        axis.text.y = element_text(size = 12, face="bold"),
        axis.title.x = element_text(size = 14, face = "bold"),
        axis.title.y = element_text(size = 14, face = "bold")
    )

ggsave(
  p,
  filename = output_file,
  width = 8,
  height = 8
)

ggsave(
  p,
  filename = output_png,
  width = 8,
  height = 8
)

messages <- append(
  messages,
  "Generated dotplot for assembly-to-assembly comparison."
)

readr::write_lines(
  file = snakemake@log[["path"]],
  x = paste0("DOTPLOT: ", messages)
)