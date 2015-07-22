### SQL query-and-send
###
### Created: November 2014
###
### Author: Eric Rynerson
###
### The purpose of this script is to source and run a sql query and send
### the results (and the script itself) to an email address.
###
### The inspiration was a request was from an ops user who does not have
### access to database credentials and who wanted to run a query that was too
### computationally-intensive for Blazer.  This tool allowed the query to
### be run by the data science server (optionally as a cronjob of course).
###
### A more general use is for simple udpates one would like to receive on
### a regular basis, e.g. the picking time model errors, or order volume.
###
###########################################################################


library(sendmailR) # for emails from R

setwd("/app")
source("common/r/dbconnection_read_replica.R")
source("common/r/functions.R")

args <- commandArgs(trailingOnly = TRUE)  # Run with: Rscript sql_query_and_send.R path_relative_to_current_ds_release.sql where_to_send@domain.com
# TODO: add ability to send to multiple email addresses
# TODO: add name of query result set to arguments, OR just use the end of the path to name the .txt

# set the key variables
query_path <- args[1]
email_from <- Sys.getenv("MY_EMAIL_ADDRESS")
email_to <- as.character(args[2])
email_subject <- "Query and results"
email_body_text <- "Here are the results of the query:"


# source the query
sql <- readChar(query_path, file.info(query_path)$size)

# run the query on the read replica
results <- dbGetQuery2(con, sql)

print("number of rows:")
print(nrow(results))
print("result set size as data frame: ")
print(object.size(results))

# break and alert if the query results are simply too large for email
if (nrow(results) > 100000) {
  sendmail(from = email_from,
           to = email_to,
           subject = "Query results too large for email at >100k rows",
           msg=c("Query results too large for email at >100k rows", "\n", "\n",
                 "SQL query used:", "\n", "\n",
                 sql
           )
  )
  stop("Query results exceed max setting of 100,000 rows")
}

# email the results and attach the query itself as well
sendmail(from = email_from,
         to = email_to,
         subject = email_subject,
         msg=c(email_body_text, "\n", "\n",
               mime_part(results, "query results", sep = ",", row.names = FALSE), "\n",
               "\n", "SQL query that generated this result:", "\n", "\n",
               sql
         )
)

# close out the connection
dbDisconnect(con)
detach("package:RPostgreSQL", unload=TRUE)
