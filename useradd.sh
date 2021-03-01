#!/bin/bash

info_msg() {
	echo -e "\e[32m[INFO]\e[m "$1 >&2
}

error() {
	echo -e "\e[31m[ERROR]\e[m "$1 >&2
	exit 1
}

join_by() {
	sep=$1
	shift
	list=("$@")
	res="$(printf "${sep}%s" "${list[@]}" )"
	res="${res:${#sep}}"
	echo $res
}

# オプション解析
while getopts :c:u:s:k:d: OPT; do
	case $OPT in
		c) confdir=$OPTARG ;;
		u) user=$OPTARG ;;
		s) shell=$OPTARG ;;
		k) key=$OPTARG ;;
		d) homedir=$OPTARG ;;
		:) error "オプション引数が指定されていません: \e[1m-"$OPTARG"\e[m" ;;
		*) error "指定されたオプションが正しくありません: \e[1m-"$OPTARG"\e[m" ;;
	esac
done

# 必要な情報が取得できているかチェック
if [ ! -v confdir ]; then
	error "confファイルの保存先ディレクトリが指定されていません: \e[1m-c\e[m"
elif [ ! -v user ]; then
	error "ユーザ名が指定されていません: \e[1m-u\e[m"
elif [ ! -v shell ]; then
	error "シェルが指定されていません: \e[1m-s\e[m"
elif [ ! -v key ]; then
	error "公開鍵が指定されていません: \e[1m-k\e[m"
fi

# confファイルの保存先ディレクトリ
mkdir -p $confdir

# ユーザ名の形式チェック
if ! `echo $user | grep -Eq "^[a-z_]([a-z0-9_-]{0,31}|[a-z0-9_-]{0,30}\$)$"`; then
	error "入力されたユーザ名が正しくありません: \e[1m"$user"\e[m"
fi

# シェルの形式チェック
if [ ! `echo $shell | grep '/'` ]; then
	shell=$(which $shell)
fi
if [ ! -f $shell ]; then
	error "入力されたシェルが存在しません: \e[1m"$shell"\e[m"
fi

# 公開鍵の形式チェック
keylist=()
IFS=$'\n'
for line in $key; do
	if [ -n "$line" ]; then
		echo $line | ssh-keygen -lf /dev/stdin &> /dev/null
		if [ $? -ne 0 ]; then
			error "入力された公開鍵が正しくありません: \e[1m"$line"\e[m"
		fi
		keylist+=( "\"$line\"" )
	fi
done
key=$(join_by ", " "${keylist[@]}")

# ホームディレクトリのパスを設定
if [ ! -v homedir ]; then
	homedir=""
fi

# ユーザ名の重複チェックと次のidを取得
exist_flag=0
max_id=2000
for conf in $(find $confdir -type f); do
	conf=`basename $conf`
	conf_id=`echo $conf | sed -r 's/^([0-9]{1,5})-.+\.conf$/\1/'`
	conf_user=`echo $conf | sed -r 's/^[0-9]{1,5}-(.+)\.conf$/\1/'`
	if [ $user = $conf_user ]; then
		exist_flag=1
		user_id=$conf_id
		break
	fi
	if [ $conf_id -gt $max_id ]; then
		max_id=$conf_id
	fi
done
if [ $exist_flag -eq 0 ]; then
	user_id=$(($max_id+1))
	password=""
else
	# ログインパスワードは引き継ぎ
	password=$(sed -n -r "s/^password = \"(.*)\"$/\1/p" $confdir/${user_id}-${user}.conf)
fi

# confファイルを作成
cat << EOS | sudo tee $confdir/${user_id}-${user}.conf > /dev/null
[users.${user}]
id = ${user_id}
group_id = ${user_id}
shell = "$shell"
keys = [$key]
password = "$password"
directory = "$homedir"

[groups.${user}]
id = ${user_id}
users = ["${user}"]
EOS

# confファイルの所有権変更
sudo chown ${user}:${user} $confdir/${user_id}-${user}.conf

if [ $exist_flag -eq 1 ]; then
	info_msg "既存のconfファイルを上書きしました: \e[1m"$confdir/${user_id}-${user}.conf"\e[m"
else
	info_msg "confファイルを作成しました: \e[1m"$confdir/${user_id}-${user}.conf"\e[m"
fi
