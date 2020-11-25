#!/bin/bash

# ユーザ名と公開鍵を入力
if [ $# -eq 4 ]; then
	user=$1
	key="$2 $3 $4"
	echo -e "\e[32m[INFO]\e[m ユーザ名: \e[1m"$user"\e[m" >&2
	echo -e "\e[32m[INFO]\e[m 公開鍵: \e[1m"$key"\e[m" >&2
else
	read -p "ユーザ名: " user
	read -p "公開鍵: " key
fi

# ユーザ名と公開鍵の形式チェック
if ! `echo $user | grep -Eq "^[a-z_]([a-z0-9_-]{0,31}|[a-z0-9_-]{0,30}\$)$"`; then
	echo -e "\e[31m[ERROR]\e[m 入力されたユーザ名が正しくありません: \e[1m"$user"\e[m" >&2
	exit 1
fi
echo $key | ssh-keygen -lf /dev/stdin &> /dev/null
if [ $? -ne 0 ]; then
	echo -e "\e[31m[ERROR]\e[m 入力された公開鍵が正しくありません: \e[1m"$key"\e[m" >&2
	exit 1
fi

# ユーザ名の重複チェックと次のidを取得
max_id=2000
for conf in $(find ./conf.d/ -type f); do
	conf=`basename $conf`
	conf_id=`echo $conf | sed -r 's/^([0-9]{1,5})-.+\.conf$/\1/'`
	conf_user=`echo $conf | sed -r 's/^[0-9]{1,5}-(.+)\.conf$/\1/'`
	if [ $user = $conf_user ]; then
		echo -e "\e[31m[ERROR]\e[m 入力されたユーザ名のconfファイルは既に存在します: \e[1m"$conf"\e[m" >&2
		exit 1
	fi
	if [ $conf_id -gt $max_id ]; then
		max_id=$conf_id
	fi
done
next_id=$(($max_id+1))

# confファイルを作成
cat > ./conf.d/${next_id}-${user}.conf << EOS
[users.${user}]
id = ${next_id}
group_id = ${next_id}
shell = "/usr/bin/zsh"
keys = ["${key}"]

[groups.${user}]
id = ${next_id}
users = ["${user}"]
EOS
echo -e "\e[32m[INFO]\e[m confファイルを作成しました: \e[1m"./conf.d/${next_id}-${user}.conf"\e[m" >&2
