# Polymarket-Analysis
Data analysis of Polymarket data (SJSU DATA 201)

Dataset & Contribution Tracking: https://drive.google.com/drive/folders/1XwKQmLknbV4oq6B5i1OtpTxKxPC5WEyP?usp=sharing 

(Contribution Note: Queries and "team" designations in contribution tracking are work done collaboratively)

Importing Data (Mac)

1. mysql -u your_username -p -e "CREATE DATABASE polymarket;"
2. gunzip -c polymarket_dump.sql.gz | mysql -u your_username -p polymarket

Importing Data (Windows)

1. tar -xzf polymarket_dump.sql.gz
2. mysql -u your_username -p -e "CREATE DATABASE polymarket;"
3. mysql -u your_username -p polymarket < polymarket_dump.sql
