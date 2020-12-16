#!/bin/bash

info_msg() {
	echo -e "\e[32m[INFO]\e[m "$1 >&2
}

error() {
	echo -e "\e[31m[ERROR]\e[m "$1 >&2
	exit 1
}

# Googleフォームからダウンロードした最新のcsvファイルのパスを取得
csvfile=$(ls -t $(find `pwd` -name "csv.d" -type d)/*.csv | head -n 1)

# csvファイルを読み込んで各行ごとに処理
{
	# ヘッダーをスキップ
	read

	while read row || [ -n "${row}" ]; do
		if `echo $row | grep -Eq "^\".*$"`; then # 1行目
			IFS=',' read -ra values <<< "$row"
		else # 2行目以降
			IFS=',' read -ra elems <<< "$row"
			values[${#values[@]}-1]="${values[${#values[@]}-1]}\n${elems[0]}"
			unset elems[0]
			IFS=',' values+=(${elems[@]})
		fi
		if `echo $row | grep -Eq "^.*[^\\]\"$"`; then
			user="${values[2]}"
			shell="${values[3]}"
			key="$(echo -e "${values[5]}")"
			./useradd.sh -u $user -s $shell -k $key
		fi
	done
} < $csvfile
