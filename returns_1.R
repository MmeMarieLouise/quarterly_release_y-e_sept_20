install.packages("gitignore")
library(gitignore)
# print git ignore template
gi_fetch_templates("R")
#note: generate personal access token to push repo

install.packages("writexl")

# load tidyverse and it's libraries
library(tidyverse)
library(readxl)
library(dplyr)

library(tidyr)

library(writexl) 

# for data cleaning
library(janitor)

# check working directory
getwd()

# check the excel sheet names from excel file
readxl::excel_sheets("/Users/marie-louise/Documents/sites/quarterly_release_y:e_sept_20/returns-datasets-sep-2020.xlsx")

# dataframe_name <- readxl::read_excel(file_path)
# or - readxl::excel_sheets(file_path)

raw_data_1 <- readxl::read_excel("/Users/marie-louise/Documents/sites/quarterly_release_y:e_sept_20/returns-datasets-sep-2020.xlsx",
                                 sheet = "Data - Ret_D01")
# open file in viewer
View(raw_data_1)

# clean column names (use gsub on work laptop)
clean_raw_data <- janitor::clean_names(raw_data_1)

# open file in viewer
View(clean_raw_data)

# inspect data
# check column / field names
names(clean_raw_data)

# filter data
# %>% pipe operator, shortcut = Cmd + Shift + M, to chain sequences together   
filtered_data <- clean_raw_data %>%
  # select variables / column names
  select(quarter,
         return_type_group,
         return_type,
         number_of_returns) %>% 
  # filter on all the selected vars, check if any vars meet the condition, detect the pattern in a string
  filter_all(any_vars(str_detect(.,pattern = ('2010|2011|2012|2013|2014|2015|2016|2017|2018|2019|2020'))))

# View filtered data 
View(filtered_data)

# double check var names
names(filtered_data)

# Manual checking:
# for each column/ var except number_of_returns , use unique() to eliminate duplicate values
# use $ to access var name from inside the list (instead of [1])
unique(filtered_data$return_type_group)
unique(filtered_data$quarter)

unique(filtered_data$return_type)
# In return_type "Non-detained enforced removals" and "Non-detained Enforced removals"
# are similar except one has a capital E 

# use mutate(), case_when() vectorises multiple if else statements
# ~ is used to separate tow arguments in a function
mutated_data <- filtered_data %>% 
  mutate(return_type=case_when(return_type=="Non-detained enforced removals" ~ "Non-detained Enforced removals",
                               TRUE~ return_type))

# double check, there should be "Non-detained Enforced removals" with 7 other vars
unique(mutated_data$return_type)

dplyr::count(mutated_data, return_type[1], sort = TRUE)

dplyr::summarise(.data = mutated_data,
                 total_rows = sum(return_type, na.rm = TRUE))
# check names
names(mutated_data)

View(mutated_data)

# filter 1
filter_1 <- mutated_data %>% 
  select( quarter,return_type_group, number_of_returns) %>% 
  group_by(quarter,return_type_group) %>% 
summarise(Total = sum(number_of_returns))

View(filter_1)


# in the summary tables, two columns / vars have been merged together (return_type_group and return_type )
column_sums_1 <- mutated_data %>% 
  # group_by() to take existing table and group using the defined vars 
  group_by(quarter,return_type_group) %>% 
  # summarise() to group data created by group_by()
  summarise(values = sum(number_of_returns)) %>% 
  # Rename the label return_type_group to row_labels
  rename(row_labels = return_type_group)

View(column_sums_1)

# Find the sum of quarter,return_type
# return_type is a subset of return_type_group
column_sums_2 <- mutated_data %>% 
  group_by(quarter,return_type) %>% 
  summarise(values = sum(number_of_returns)) %>% 
  # Rename the label return_type to row_labels
  rename(row_labels= return_type)

View(column_sums_2)

# combine both data sets
new_data <- union(column_sums_1,column_sums_2)

View(new_data)

# spread() to reshape the data and convert the quarter row into a column
 formatted_data <- new_data %>% 
   spread(quarter, values)
 
 View(formatted_data)
 

# export the data
write_xlsx(formatted_data, "summary_data_R.xlsx") 









   