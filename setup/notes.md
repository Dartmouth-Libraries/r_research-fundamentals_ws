# R-tutorial-template: [REPLACE WITH TITLE]

<!-- 
INSTRUCTIONS FOR INSTRUCTORS:
1. Click "Use this template" to create a new repository
2. Replace all [BRACKETED CONTENT] with your specific information
3. Delete this instruction block
4. Customize sections as needed for your course
5. See TEACHING-NOTES.md for setup instructions
-->

repository template for teaching materials in R, whether intended for use in a workshop or class, as asynchronous learning materials, or both.
[insert brief description here]

## [R / Github Best Practices]
* recommendations not requirements!*

1. use R Studio
2. follow project organization best practices (see below)
3. create a virtual environment (currently, the most widely used R tool for this is **renv**) that allows you to create a reproducible, transportable, and sustainable programming environment.
4. ...
5. ...
   
## [Project Folder Organization]

+ Follow a one project - one folder approach
+ within your project folder create a logical and simple structure of sub-folders that can be used consistently across similar projects. 
+ provide files with names that enable quick discovery when sorted in alphabetical order

File-naming convention for our teaching materials is posted on the Spark page [Teaching Material Metadata Standards](https://library.spark.dartmouth.edu/wiki/spaces/RF/pages/1068072984/Teaching+Material+Metadata+Standards). 

Recommended file structure:

```

repository_root_dir
  |-lesson-name {i.e. `01_r-setup` for a sequential workshop or `r-setup` for a non-sequential workshop of that name)
    |-archive (for older versions of material)
    |-code    (may include scripts or notebooks, can include additional sub-folders if they need to be separated)
    |-data      (for smaller practice datasets to be used with lessons; 
                it is recommended that larger datasets be disseminated in an alternative manner
                to prevent making the repository too large)
    |-exercises
    |-instructor notes
    |-lesson-resources
    |-other
    |-slides  
  |-02_lesson
    ...
  |-03_lesson
  |-lesson-nonsequential
  |-general-resources
  |-setup      (asynchronous tutorials for installing and setting up R and R Studio and creating your first project in R Studio)
  ...
  
 ```