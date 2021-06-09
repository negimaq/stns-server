#!/bin/bash

info_msg() {
	echo -e "\e[32m[INFO]\e[m "$1 >&2
}

error() {
	echo -e "\e[31m[ERROR]\e[m "$1 >&2
	exit 1
}

# ログインを許可するユーザリストの読み込み
allowed_path=$(cd $(dirname $0); pwd)/allowed.list
allowed_list=()
if [ -f $allowed_path ]; then
	while read line; do
		allowed_list=("${allowed_list[@]}" "$line")
	done < $allowed_path
fi

check_list() {
	local e
	for e in ${allowed_list[@]}; do
		if [[ ${e} = ${1} ]]; then
			return 0
		fi
	done
	return 1
}

# csvファイルの保存先ディレクトリを作成
csvdir=$(cd $(dirname $0); pwd)/csv.d
mkdir -p $csvdir

# URLが指定されている場合にはcsvファイルをダウンロード
if [ $# -eq 1 ]; then
	csvurl=$1
elif [ -f ./.env ]; then
	. ./.env
	if [ ! -z "$CSV_URL" ]; then
		csvurl=$CSV_URL
	fi
fi
if [ ! -z "$csvurl" ]; then
	if [ ! `curl -sL -o /dev/null -w '%{content_type}' "$csvurl" | grep 'csv'` ]; then
		error "csvファイルのURLではありません: \e[1m"$csvurl"\e[m"
	fi
	csvname="tluser_$(date '+%Y-%m-%d_%H:%M').csv"
	curl -sL -o $csvdir/$csvname "$csvurl"
	if [ $? -ne 0 ]; then
		error "csvファイルのダウンロードに失敗しました: \e[1m"$csvurl"\e[m"
	else
		info_msg "csvファイルをダウンロードしました: \e[1m"$csvname"\e[m"

	fi
else
	ls $csvdir/*.csv > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		error "csvファイルが存在しません: \e[1m"$csvdir"\e[m"
	fi
fi

# Googleフォームからダウンロードした最新のcsvファイルのパスを取得
csvfile=$(ls -t $csvdir/*.csv | head -n 1)
info_msg "csvファイルをロードします: \e[1m"$(basename $csvfile)"\e[m"

# csvファイルを読み込んでヘッダーを除く各行ごとに処理
first_line=1
tail -n +2 $csvfile | while read row || [ -n "${row}" ]; do
	if [ $first_line -eq 1 ]; then # 各ユーザの1行目
		IFS=',' read -ra values <<< "$row"
		first_line=0
	else # 各ユーザの2行目以降
		IFS=',' read -ra elems <<< "$row"
		values[${#values[@]}-1]="${values[${#values[@]}-1]}\n${elems[0]}"
		unset elems[0]
		IFS=',' values+=(${elems[@]})
	fi
	if [[ $row != *,\"* ]]; then # 各ユーザの最終行
		confdir="$(cd $(dirname $0); pwd)/vmlbastion-conf.d"
		user="${values[2]}"
		shell="rbash"
		if check_list "$user"; then
			key="$(echo -e "${values[5]}" | tr -d "\r" | sed 's/\"//')"
		else
			key=""
		fi
		homedir="/home/common"
		./useradd.sh -c $confdir -u $user -s $shell -d $homedir -k $key
		first_line=1
	fi
done
