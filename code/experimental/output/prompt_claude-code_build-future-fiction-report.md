# Claude Code Prompt for Building Report on Futuristic Fiction Dataset

## Prompt 1: Develop Research Questions

```{prompt-1}
Review the data in data/post45_books/original. 

Identify some interesting and fun research questions that can be answered by analyzing this data. Evaluate the feasibility and difficulty of each option and identify some valuable and novel analysis that can be done. Take into account data wrangling options such as merging some of these datasets together.
```

## Prompt 2: Create a Quarto exploratory data analysis notebook and generate a report

```{prompt-2}
Write the code (as a qmd in R using tidyverse) to answer Question 2. The code should be modular and well-documented enough so that a relatively new R programmer can understand it. Any customization settings should be in one cell near the top. This first notebook should be exploratory

Then Step #2: write a script that produces a report with your results that answer this question. These results should include vivid, fun, interactive visualizations (made in the style of NYT graphics) that allow the user to explore the data. Where possible, visualizations should follow the principles of "Data Humanism" as espoused by Giorgia Lupi.
```

See the resulting Quarto notebook: [5a Futuristic Fiction Notebook](../05a_claude_futuristic-fiction_exploratory.qmd)

See the report: [Futuristic Fiction Report](futuristic-fiction-report.html)
