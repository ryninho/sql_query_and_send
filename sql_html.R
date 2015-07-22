### SQL query-and-send
###
### Created: December 2014
###
### Author: Eric Rynerson
###
### The purpose of this script is to source and run a sql query and send
### the results (and the script itself) in the email body to an email address.
###
### A typical use for this would be simple udpates one would like to receive
### on a regular basis, e.g. the picking time model errors, or order volume.
###
###########################################################################


library(sendmailR) # for emails from R
library(xtable) # for HTML table formatting
library(pander) # for HTML email formatting

setwd("/app")
source("common/r/dbconnection_read_replica.R")
source("common/r/functions.R")

args <- commandArgs(trailingOnly = TRUE)  # Run with: Rscript sql_query_and_send.R path_relative_to_current_ds_release.sql where_to_send@domain.com
# TODO: add ability to send to multiple email addresses
# TODO: add name of query result set to arguments, OR just use the end of the path to name the .txt
# TODO: options to receive attachment, HTML formatted table, regular pander table(?)

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
if (nrow(results) > 1000) {
  sendmail(from = email_from,
           to = email_to,
           subject = "Query results too large for email at >1k rows",
           msg=c("Query results too large for email at >1k rows", "\n", "\n",
                 "SQL query used:", "\n", "\n",
                 sql
           )
  )
  stop("Query results exceed max setting of 100,000 rows")
}

# convert columns to string to preserve format (e.g. number of decimal places or date format)
results_string <- as.data.frame(lapply(results, as.character))

# format the results as a table using the pander package
panderOptions('table.split.table', Inf) # don't split the table along multiple lines... (show all columns together)

msg_content <- mime_part(paste('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0
Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <style>
    td {
        text-align: center;
        padding: 3px;
    }
  </style>
</head>
<body>', print(xtable(results_string), type = 'html'), '</body>
</html>'))

msg_content[["headers"]][["Content-Type"]] <- "text/html"

# send including the results table and also the sql
sendmail(from = email_from,
         to = email_to,
         subject = email_subject,
         msg=c(email_body_text, "\n", "\n",
               msg_content, "\n",
               "\n", "SQL query that generated this result:", "\n", "\n",
               sql
         )
)

# close out the connection
dbDisconnect(con)
detach("package:RPostgreSQL", unload=TRUE)
