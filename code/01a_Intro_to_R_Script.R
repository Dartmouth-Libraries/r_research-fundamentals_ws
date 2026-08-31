#### Intro to R Script ####

# Learn basic R syntax and functions and get familiar with the RStudio interface.

# 9/2/2026
# Katie Owers Bonner

########################################################################################

#### R can do math! ####

5+3

5*3

5/3

# A style convention that helps with readability is to put a space between your elements:
5 ^ 2

# Note that anything following a hashtag is treated as a comment. The computer doesn't do anything with it, so
    # you can use it for notes to yourself and others

# R follows standard order of operations:
3 + 4 / 2

# You can use parentheses for grouping:
(3 + 4) / 2

# R can also test statements, such as 
5 > 3

3 * 8 >= 24 # >= means "greater than or equal to".

# Note that with the above, where the ">=" is a single operator, you can't put a space between them. Try 
3 * 8 > = 24


#### Assigning Objects ####

# To define an object, you use the "<-" "get" operator (which can't have a space between the arrow and dash)

x <- 5
# Note that x is now in the Environment (top right) panel of RStudio
# R doesn't print the value in the console, but you can view it by running the object's name
x

#Some general rules for object names in R:
  # Names should be short but informative
  # Names begin with letters (not numbers or other special characters)
  # Do not use spaces in names. Use underscores (i.e. "variable_name") instead. 
  # Do not use R's reserved words as names (i.e. "TRUE", "FALSE", "class", etc.)
  # Names are case sensitive, so "Age" is distinct from "age"

y <- 3

# you can also use strings (text) in R. Just place the text in quotation marks
animal <- "dog"

# Objects can also have multiple values

odd_nums <- c(1, 3, 5, 7, 9)
animals <- c("dog", "cat")

# You can do math with objects

x + y

odd_nums * 2

# but what about 
animal * 2 

# you can overwrite objects
high_temp <- 100
high_temp <- 105

# Objects can have multiple dimensions as well. The code below creates a data.frame, which is R's basic tabular data format.
fruit <- data.frame(
    Type = c("apple", "banana", "cherry"),
    Quantity = c(4, 3, 10)
  )
# Explore how this shows up in the Environment tab in the top right. 



#### Accessing data within objects   ####

# say you wanted to extract the 2nd element in odd_nums we created earlier 
  # Use the Environment panel to remember what odd_nums looks like!
odd_nums[2]

# Now let's explore various parts of the fruit object. 
fruit

fruit[2,1] # select the entry in the second row and first column
fruit[2,2] # select the entry in the second row and second column

fruit[2,] # select all columns of row 2
fruit[,2] # select all rows of column 2

fruit$Type # select the Type column by name

fruit[2,1:2] # Select the first and second elements in row 2


#### Functions  ####

# The format for using functions in R is function_name(arguments).
# we've already used two functions today - c() and data.frame().

# Here are some other examples:

sqrt(4)

mean(odd_nums)
sd(odd_nums) # standard deviation function

mean(fruit$Quantity)
nrow(fruit) # number of rows in the data.frame
ncol(fruit) # number of columns

####  Getting Help with functions ####

# Either of the below pulls up a specific function's help page in the Help tab of RStudio (bottom right)
help(c)
?c

# If you don't know a specific function name but have a search term 
  # (eg what's the function for standard deviation?), you can use:
help.search("deviation")
??deviation
# or Search in the Help pane (bottom right)
