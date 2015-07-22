# SQL Query-and-Send command line tool
##### Send yourself (or someone else) the results of a sql query from a server
<br>
<i>New stuff!  Try sql_html.R (in the same directory) for emails including the query results in the body- one less step. <br> Additional documentation forthcoming.</i><br>
<br>
This script allows you, with a single line in a server terminal, to run a sql script and email yourself or someone else a tab-delimited text file with the results. In addition, the text of the query used will be included in the body of the email. As it is a single command, you could save it as an alias or in a cronjob.
<br>
<br>
To use it, follow these three steps:<br>

First, add your email address and the read-only db credentials to the environment that will be calling the script (so, for example, your .profile if you are running it from the ds terminal):
* export MY_EMAIL_ADDRESS="your@email.com"
* export READ_ONLY_DATABASE_URL="[read replica db credentials]"
<br><br>

Next, put the SQL you'd like to run in a .sql file (on the server).
<br>

Finally, run the script sql_query_and_send.R from the terminal as follows, with the path to your sql file being relative to the "current" directory on the server (which is a symlink to the latest release):

    Rscript path_to_the_R_script path_from_current_to/query.sql your@email.com

<br>
That's it!
<br>
<br>
<br>


Ideas:

* Once you have this working, there are a number of things you can do to take advantage of it. For example, I have an alias that runs a query I use often (I just type "check_ptm" and the results are sent to me):

        alias check_ptm="Rscript /app/data-science/current/people/eric/sql_query_and_send.R picking_time/check_ptm.sql your@email.com"

* Alternatively, if someone needs information that can be generated in a query but is too data- or computationally-intensive for Blazer you could run it on the server and have the results emailed directly to the person (in a cronjob, perhaps, if they want it frequently)

* Lastly, it can be a fast way to set up simple monitoring of something without going through creation of a report. For example I have the following in a cronjob to monitor the picking time model:

        Rscript /app/data-science/current/people/eric/sql_query_and_send.R people/eric/sql/ptm_performance.sql your@email.com
<br>

Note that it will not send you attachments over 100k rows or that violate gmails maximum attachment limits.
<br>
<br>
Please contact Eric with any questions or technical issues.
