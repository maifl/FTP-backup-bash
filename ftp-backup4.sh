#! /bin/bash








days_n="1"                  # Количество дней (файлы старше этого количества дней будут скачиваться/удаляться)

username="maif1L"            #  имя пользователя FTP
host="192.168.3.1488"         #  имя сервера или  ip адресс
password="boynextdor"         #  пароль к ftp серверу


dir="/1/2"                   # путь к папке на FTP сервере с файлами
backup_dir="/tmp"            # путь к папке бекапана (куда копировать файлы)
log_file="/tmp/ftp-log.txt"  # путь к папке где сохранять лог файл








# COLOR
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
NC=$(tput sgr0)       #  Stop color




date_today="$(date +%Y%m%d)"
date_today_Sek=`date -d "$date_today" +"%s"`
echo "date_today_Sek=$date_today_Sek"
past_day_today=$(($date_today_Sek/86400))





files=$(curl ftp://${host}${dir}/ --user ${username}:${password} | grep  ^'[0-9][0-9]-[0-9][0-9]-[0-9][0-9]' | grep -v '<DIR>')



IFS=$'\n'

for line in $files
do




name_file=$(echo "$line" | awk '{print $4}')


data_file=$(echo "$line" | awk '{print $1}' | awk -F"-" '{print "20"$3 $1 $2}')
date_file_Sek=`date -d "$data_file" +"%s"`
past_day_file=$(($date_file_Sek/86400))


live_file=$(($past_day_today-$past_day_file))
	
	
	



if [ "$live_file" -gt "$days_n" ];then
	echo -n $RED
	echo "File live $live_file days. (Older then $days_n)  : $name_file "
	echo -n $NC
	old_files=$old_files$line'\n'
else
	echo "File live $live_file days. (younger then $days_n): $name_file "
fi
done











echo "=================================="
echo "List of old Files:"
echo
echo -e $old_files | awk '{print $4}'
echo "=================================="
sleep 3


echo $GREEN
echo "               =================================="
echo "                       Downloading Files:"
echo "               =================================="$NC

echo "" >> $log_file
echo " ---------   $(date) -------" >> $log_file

IFS=$'\n'

for line in $(echo -e "$old_files")
do

echo; echo; echo 

	file=$(echo -e "$line" | awk '{print $4}')
	size=$(echo -e "$line" | awk '{print $3}')

	echo "Downloading...."
	echo "${dir}/${file}   ---to--->   $backup_dir/${file}"

ftp -p -n ${host} <<END_SCRIPT
quote USER $username
quote PASS $password
cd ${dir}/
get ${file} $backup_dir/${file}
quit
END_SCRIPT


	new_size=$(ls -l $backup_dir/${file} | awk '{print $5}')

	if [[ -f $backup_dir/${file} && "$new_size" == "$size" ]];then
		echo -n $GREEN
		echo "       File Downloaded! : $file" | tee -a $log_file
		echo -n $NC
	
# echo "Deleteing File"
ftp -p -n ${host} <<END_SCRIPT
quote USER $username
quote PASS $password
cd ${dir}/
delete ${file} 
quit
END_SCRIPT

	else
		echo -n $RED
		echo "Error Downloading File! : $file" | tee -a $log_file
		echo $NC
	fi
done



exit 0
