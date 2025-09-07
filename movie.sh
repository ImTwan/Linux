#!/bin/bash

echo "Download dataset" 
wget "https://raw.githubusercontent.com/yinghaoz1/tmdb-movie-dataset-analysis/master/tmdb-movies.csv"
echo "Download complete"


echo "DOWNLOAD CSVKIT"
sudo apt install csvkit

echo " DOWNLOAD DONE"
# clean data 
# make sure columns are aligned with the dataset using csvkit

csvclean tmdb-movies.csv
csvlook tmdb-movies_out.csv | less -S # check the columns after cleaning

# 1. Sắp xếp các bộ phim theo ngày phát hành giảm dần rồi lưu ra một file mới
echo "1. Sắp xếp các bộ phim theo ngày phát hành giảm dần rồi lưu ra một file mới: "
csvsort -c release_date -r tmdb-movies_out.csv | csvcut -c original_title,release_date > task1.csv
csvlook task1.csv | less -S

echo "1 DONE" 

# 2. Lọc ra các bộ phim có đánh giá trung bình trên 7.5 rồi lưu ra một file mới
echo "2. Lọc ra các bộ phim có đánh giá trung bình trên 7.5 rồi lưu ra một file mới"

csvsql --query 'SELECT * FROM tmdb_movies_out WHERE CAST(vote_average AS FLOAT) > 7.5' --tables tmdb_movies_out tmdb-movies_out.csv > task2.csv

csvlook task2.csv | less -S

echo "2 DONE"

#3.Tìm ra phim nào có doanh thu cao nhất và doanh thu thấp nhất
echo "3.  Tìm ra phim nào có doanh thu cao nhất và doanh thu thấp nhất"

echo "Phim doanh thu cao nhất: " 
csvsql --query 'SELECT original_title, revenue FROM tmdb_movies_out ORDER BY CAST(revenue AS INTEGER) DESC LIMIT 1' --tables tmdb_movies_out tmdb-movies_out.csv | tail -n +2

echo "Phim có doanh thu thấp nhất: "
csvsql --query 'SELECT original_title, revenue FROM tmdb_movies_out WHERE CAST(revenue AS INTEGER) > 0 ORDER BY CAST(revenue AS INTEGER) ASC LIMIT 1' --tables tmdb_movies_out tmdb-movies_out.csv | tail -n +2

echo "3 DONE" 

# 4. Tính tổng doanh thu tất cả các bộ phim
echo "# 4. Tính tổng doanh thu tất cả các bộ phim"

echo "Tổng doanh thu tất cả các bộ phim: "
csvsql --query 'SELECT SUM(CAST(revenue AS INTEGER)) FROM tmdb_movies_out' --tables tmdb_movies_out  tmdb-movies_out.csv | tail -n +2

echo " 4 DONE" 

#5. Top 10 bộ phim đem về lợi nhuận cao nhất
echo " 5. Top 10 bộ phim đem về lợi nhuận cao nhất: "

csvsql --query 'SELECT original_title, CAST(revenue AS INTEGER) - CAST(budget AS INTEGER) AS profit FROM tmdb_movies_out ORDER BY profit DESC LIMIT 10' --tables tmdb_movies_out tmdb-movies_out.csv | tail -n +2

echo "5 DONE" 

#6 Đạo diễn nào có nhiều bộ phim nhất và diễn viên nào đóng nhiều phim nhất
echo "6. Đạo diễn nào có nhiều bộ phim nhất và diễn viên nào đóng nhiều phim nhất"

csvcut -c director tmdb-movies_out.csv | tail -n +2 | tr '|' '\n' | sed '/^\s*$/d' | sort | uniq -c | awk 'BEGIN{max=0} {c=$1; $1=""; name=substr($0,2); if(c>max){max=c; top=name}} END{print "Đạo diễn nào có nhiều bộ phim nhất: ", top, "-", max, "movies"}'

echo "Diễn viên nào đóng nhiều phim nhất: "

csvcut -c cast tmdb-movies_out.csv | \
tail -n +2 | \
tr '|' '\n' | \
sed '/^\s*$/d' | \
grep -v '^""$' | \
sed 's/^"//; s/"$//' | \
sort | uniq -c | sort -nr | \
awk '{$1=""; sub(/^ +/, ""); print; exit}'

echo "6 DONE"

#7. Thống kê số lượng phim theo các thể loại. Ví dụ có bao nhiêu phim thuộc thể loại Action, bao nhiêu thuộc thể loại Family, ….
echo "7. Thống kê số lượng phim theo các thể loại. Ví dụ có bao nhiêu phim thuộc thể loại Action, bao nhiêu thuộc thể loại Family, …. "

csvcut -c genres tmdb-movies_out.csv | tail -n +2 | tr '|' '\n' | sed '/^\s*$/d' | sort | uniq -c

echo "7 DONE"

#8 Phân tích đạo diễn có điểm đánh giá trung bình cao nhất

echo "8. đạo diễn có điểm đánh giá trung bình cao nhất: "

csvcut -c director,vote_average tmdb-movies_out.csv | csvgrep -c director -r '.' | csvformat -T | tail -n +2 | awk -F'\t' '{a[$1]+=$2; c[$1]++} END {for (d in a) print a[d]/c[d], d}' | sort -nr | head -1

