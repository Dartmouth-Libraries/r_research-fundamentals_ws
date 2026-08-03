# Setup Verification Script
# This script checks that your R environment is properly configured
# for this course/workshop.
#
# Run this entire script after completing the setup instructions in SETUP.md
# If all checks pass, you're ready to start!

# Clear environment
rm(list = ls())

# Suppress startup messages for cleaner output
suppressPackageStartupMessages({
    
    cat("\n========================================\n")
    cat("  Course Setup Verification\n")
    cat("========================================\n\n")
    
    # Check R version ----
    cat("Checking R version...\n")
    r_version <- getRversion()
    min_version <- "4.0.0"
    
    if (r_version >= min_version) {
        cat("  ✓ R version", as.character(r_version), "detected\n")
    } else {
        cat("  ✗ R version", as.character(r_version), "is too old\n")
        cat("    Please install R", min_version, "or higher\n")
        cat("    Download from: https://cran.r-project.org/\n")
        stop("R version too old")
    }
    
    # Check RStudio (optional but recommended) ----
    cat("\nChecking RStudio...\n")
    if (Sys.getenv("RSTUDIO") == "1") {
        cat("  ✓ Running in RStudio\n")
        if (exists("RStudio.Version")) {
            tryCatch({
                rstudio_info <- RStudio.Version()
                rstudio_version <- as.character(rstudio_info$version)
                cat("    Version:", rstudio_version, "\n")
            }, error = function(e) {
                cat("    Version information not available\n")
            })
        }
    } else {
        cat("  ℹ Not running in RStudio (optional but recommended)\n")
    }
    
    # Check working directory / project ----
    cat("\nChecking project structure...\n")
    expected_folders <- c("resources", "setup")
    
    for (folder in expected_folders) {
        if (dir.exists(folder)) {
            cat("  ✓ Found folder:", folder, "\n")
        } else {
            cat("  ✗ Missing folder:", folder, "\n")
            cat("    Make sure you're running this from the project root directory\n")
        }
    }
    
    # Check for required files ----
    cat("\nChecking for recommended files...\n")
    expected_files <- c("README.md")
    
    for (f in expected_files) {
        if (file.exists(f)) {
            cat("  ✓ Found file:", f, "\n")
        } else {
            cat("  ✗ Missing file:", f, "\n")
            cat("    Make sure you're running this from the project root directory\n")
        }
    }
    
    # Check if running as RStudio project ----
    cat("\nConfirming R Project is set up...\n")
    rproj_files <- list.files(pattern = "\\.Rproj$")
    if (length(rproj_files) > 0 && file.exists(rproj_files[1])) {
        cat("  ✓ R Project file detected:", rproj_files[1], "\n")
    } else {
        cat("  ⚠ No .Rproj file found\n")
        cat("    Consider opening the project via the .Rproj file\n")
    }
    
    # Check renv ----
    cat("\nChecking renv package management...\n")
    if (requireNamespace("renv", quietly = TRUE)) {
        cat("  ✓ renv is installed\n")
        
        # Check if renv is activated
        renv_active <- tryCatch({
            renv::project()
            TRUE
        }, error = function(e) {
            FALSE
        })
        
        if (renv_active) {
            cat("  ✓ renv is activated for this project\n")
            
            # Check renv status
            tryCatch({
                status <- renv::status()
                cat("  ℹ Run renv::status() for detailed package status\n")
            }, error = function(e) {
                cat("  ⚠ Could not check renv status\n")
            })
        } else {
            cat("  ⚠ renv is installed but not activated for this project\n")
            cat("    Run: renv::restore() to set up project packages\n")
        }
    } else {
        cat("  ✗ renv is not installed\n")
        cat("    Install with: install.packages('renv')\n")
        cat("    Then run: renv::restore()\n")
    }
    
    # Define required packages ----
    cat("\nChecking required packages...\n")
    
    # Modify this list based on your course requirements
    required_packages <- c(
        "tidyverse",    # Data manipulation and visualization
        "rmarkdown",    # For rendering lessons
        "knitr",        # For document generation
        "here"          # For file path management
    )
    
    # Optional packages (nice to have but not critical)
    optional_packages <- c(
        "devtools",     # Development tools
        "usethis",      # Project setup helpers
        "testthat"      # Testing (for advanced courses)
    )
    
    missing_required <- character(0)
    missing_optional <- character(0)
    
    # Check required packages
    for (pkg in required_packages) {
        if (requireNamespace(pkg, quietly = TRUE)) {
            # Try to load the package
            loaded <- suppressWarnings(
                suppressPackageStartupMessages(
                    library(pkg, character.only = TRUE, logical.return = TRUE)
                )
            )
            if (loaded) {
                cat("  ✓", pkg, "\n")
            } else {
                cat("  ⚠", pkg, "is installed but couldn't load\n")
            }
        } else {
            cat("  ✗", pkg, "(REQUIRED)\n")
            missing_required <- c(missing_required, pkg)
        }
    }
    
    # Check optional packages
    if (length(optional_packages) > 0) {
        cat("\nChecking optional packages...\n")
        for (pkg in optional_packages) {
            if (requireNamespace(pkg, quietly = TRUE)) {
                cat("  ✓", pkg, "\n")
            } else {
                cat("  ○", pkg, "(optional)\n")
                missing_optional <- c(missing_optional, pkg)
            }
        }
    }
    
    # Test key functionality ----
    cat("\nTesting key functionality...\n")
    
    # Test data manipulation
    cat("  Testing data manipulation (dplyr)...\n")
    tryCatch({
        test_df <- data.frame(x = 1:5, y = 6:10)
        result <- dplyr::filter(test_df, x > 2)
        if (nrow(result) == 3) {
            cat("    ✓ dplyr works correctly\n")
        }
    }, error = function(e) {
        cat("    ✗ dplyr test failed:", as.character(e$message), "\n")
    })
    
    # Test plotting
    cat("  Testing plotting (ggplot2)...\n")
    tryCatch({
        p <- ggplot2::ggplot(mtcars, ggplot2::aes(x = mpg, y = wt)) +
            ggplot2::geom_point()
        cat("    ✓ ggplot2 works correctly\n")
    }, error = function(e) {
        cat("    ✗ ggplot2 test failed:", as.character(e$message), "\n")
    })
    
    # Test file paths with here
    cat("  Testing file path management (here)...\n")
    tryCatch({
        project_root <- here::here()
        cat("    ✓ here package works\n")
        cat("      Project root:", as.character(project_root), "\n")
    }, error = function(e) {
        cat("    ✗ here package test failed:", as.character(e$message), "\n")
    })
    
    # Test RMarkdown rendering capability
    cat("  Testing RMarkdown capability...\n")
    tryCatch({
        rmarkdown_available <- requireNamespace("rmarkdown", quietly = TRUE)
        knitr_available <- requireNamespace("knitr", quietly = TRUE)
        
        if (rmarkdown_available && knitr_available) {
            cat("    ✓ RMarkdown rendering should work\n")
        } else {
            cat("    ✗ RMarkdown components missing\n")
        }
    }, error = function(e) {
        cat("    ✗ RMarkdown test failed:", as.character(e$message), "\n")
    })
    
    # System information ----
    cat("\nSystem Information:\n")
    sys_info <- Sys.info()
    cat("  Operating System:", as.character(sys_info["sysname"]), 
        as.character(sys_info["release"]), "\n")
    cat("  R Version:", as.character(R.version.string), "\n")
    cat("  Platform:", as.character(R.version$platform), "\n")
    
    # Summary and recommendations ----
    cat("\n========================================\n")
    cat("  Summary\n")
    cat("========================================\n\n")
    
    if (length(missing_required) == 0) {
        cat("✓ All required packages are installed!\n\n")
        
        cat("You're ready to start the course!\n")
        cat("Next steps:\n")
        cat("  1. Review the README.md for course information\n")
        cat("  2. Check the course schedule\n")
        cat("  3. Start with lessons/lesson-01/\n\n")
        
        if (length(missing_optional) > 0) {
            cat("Optional: Install additional packages for enhanced functionality:\n")
            cat("  install.packages(c('", paste(missing_optional, collapse = "', '"), "'))\n\n")
        }
        
    } else {
        cat("✗ Setup incomplete - missing required packages\n\n")
        cat("Please install missing packages:\n")
        cat("  install.packages(c('", paste(missing_required, collapse = "', '"), "'))\n\n")
        cat("Or restore all packages using renv:\n")
        cat("  renv::restore()\n\n")
        cat("After installing packages, run this script again to verify.\n\n")
    }
    
    cat("If you encounter any issues:\n")
    cat("  1. See SETUP.md for detailed troubleshooting\n")
    cat("  2. Check the course discussion forum\n")
    cat("  3. Contact the instructor\n\n")
    
    cat("========================================\n\n")
    
})

# Optional: Create a simple test plot to verify graphics
cat("Creating a test plot...\n")
tryCatch({
    # Create figures directory if it doesn't exist
    if (!dir.exists("setup/figures")) {
        dir.create("setup/figures")
    }
    
    # Generate test plot
    png(filename = "setup/figures/setup-test-plot.png", width = 800, height = 600)
    plot(1:10, (1:10)^2, 
         main = "Setup Test Plot",
         xlab = "X values", 
         ylab = "Y values",
         pch = 19, 
         col = "steelblue",
         cex = 1.5)
    grid()
    dev.off()
    
    cat("  ✓ Test plot saved to: figures/setup-test-plot.png\n")
    cat("    Open this file to verify that graphics work correctly\n\n")
    
}, error = function(e) {
    cat("  ⚠ Could not create test plot:", as.character(e$message), "\n\n")
})

# Session info for debugging
cat("Detailed session information (for troubleshooting):\n")
cat("Run sessionInfo() to see full details\n\n")

# Optionally print session info (commented out to reduce clutter)
# print(sessionInfo())