#!/bin/bash
#
# Шаблон практического скрипта
# 
# Суть коротко: docker stats 2 cvs
# Суть развернуто: сбор статистики о трафике
#
# Version 1.0
#
# Алготиртм скрипта:
# 1. получаем с docker stats сообщение о трафике
# [ ] source -> 
# 2. извлекаем из сообщения ключи и поля для хэша
# [ ] source -> [ ] keys -> [ ] regexh -> [ ] parsf -> [ ] value -> [ ] dbh
# 3. записываем в db .cvs нужные поля
# [ ] source -> [ ] keys -> [ ] regexh -> [ ] parsf -> [ ] value -> [ ] dbh -> [ ] cvs
#
# Mihail Berezin 2024
# potrebitelberezin@gmail.com
# 2024/01/08
#

set -Eeo pipefail
# '-e' опция приведет к выходу скрипта bash сразу же при сбое команды. 
# Обычно это значительно улучшает поведение по умолчанию, когда сценарий просто игнорирует 
# сбойную команду и продолжает выполнять следующую строку. 
# Эта опция также достаточно умна, чтобы не реагировать на сбойные команды, 
# которые являются частью условных операторов. 

PROGRAM=${0##*/} 			# версия `basename` на языке bash
VERSION="$PROGRAM v1.0"
DEBUG="${DEBUG:-':'}"			# по умолчанию выключен


debug_flag="1"
help_flag="1"
my_doc=$( sudo docker stats --format "table {{.Name}}:\t {{.NetIO}}" --no-stream )
db="trafic.cvs"

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
# если скрипт записывает какой-то файл из той же директории, где лежит он сам, 
# он будет делать это так: `cat "$script_dir/my_file"`
# При этом скрипт не меняет рабочий каталог
path_out=$script_dir


function Get-Help {
    # Справка
	#
    cat <<-EoH
	Help $VERSION
	---------------------------------------------------------------
Утилита считывает значие трафика контейнера утилитой docker stats 

Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-d] [-V] -p /path_of_db.cvs

    Options:
        -d | --debug   = Include debug output, default is of
        -h | --help    = Show this help message and exit
        -p | --path    = Целевая папка
        -V | --version = Show the version and exit

Пример вызова:
    ./trafic.sh -p ~/dir
	---------------------------------------------------------------
	EoH
}   # Конец функции Get-Help


# getopts ищет один ключ в аргументах скрипта
# $OPTARGS - слово, следующее за ключом 
while getopts 'hdp:V' VAL ; do	
	case $VAL in
		h )
			help_flag="yes"
			Get-Help 
			exit 1
		;;
		d ) 
			DEBUG='cat' 
			debug_flag="0"
		;;
		p ) 
			path_out=$OPTARG                # 'hdp:V:' двоеточие между p и V указывает, 
                                            # что ключ p должен сопровождаться дополнительным
                                            # аргументом.
		;;
		V ) echo "$VERSION" && exit 0 ;;
		* ) echo "what is key mean?";;
	esac
done
shift $((OPTIND -1))	
# Для контроля последовательности анализа командной строки в пере-
# менной $OPTIND сохраняется индекс следующего рассматриваемого ар-
# гумента. Когда все аргументы будут проанализированы, getopts вернет 
# ложное значение — и цикл while завершится. После этого выполняется 
# команда shift $OPTIND -1, чтобы исключить из дальнейшего рассмотрения 
# все аргументы, связанные с ключами
# Независимо от того, каким образом вызывается сценарий, с помощью ли 
# myscript -a -o xout.txt -v file1 или просто myscript file1, после выпол-
# нения команды shift переменная $1 будет хранить значение file1, потому 
# что промежуточные ключи и их аргументы будут удалены. 

# Debug mode
if [ $debug_flag -eq 0 ] ;  then
    my_doc='NAME: NET I/O nginx-blnsr: 1.44MB / 1.44MB hugo-master: 353kB / 2.15MB hugo-rsrv: 1.37MB / 53.5MB'
fi

# [X] source -> [ ] keys -> [ ] regexh -> [ ] parsf -> [ ] value -> [ ] dbh -> [ ] cvs

###########################################################################
# 2. извлекаем из сообщения ключи и поля для хэша
###########################################################################


declare -a keys
keys=(
    [0]="nginx-blnsr"\
    [1]="hugo-master"\
    [2]='hugo-rsrv'\
)
# Ключи, по ним из источника извлекаются знанчения
# [X] source -> [X] keys -> [ ] regexh -> [ ] parsf -> [ ] value -> [ ] dbh -> [ ] cvs

declare -A regexh
regexh=(["nginx-blnsr"]='s/(.+)(nginx-blnsr:.+?\/\s+)(\d+\.*\d+)(\w\w)(.+)/\3\4/'            \
        ["hugo-master"]='s/(.+)(hugo-master:.+?\/\s+)(\d+\.*\d+)(\w\w)(.+)/\3\4/'          \
        ["hugo-rsrv"]='s/(.+)(hugo-rsrv:.+?\/\s+)(\d+\.*\d+)(\w\w)/\3\4/'                \
)
# Регулярные выражения, для каждого ключа - свое
# Регулярные выаражения тестировались на специализированном сайте https://regex101.com/
# [X] source -> [X] keys -> [X] regexh -> [ ] parsf -> [ ] value -> [ ] dbh -> [ ] cvs


# Другой способ заполнения хэша
# regexh["Station"]='s/(.+)((Station\s+:\s)(\w+))(.+)/\4/'
# regexh["Day"]='s/(.+)((Day\s+:\s)(\d+))(.+)/\4/'
# regexh["Time"]='s/(.+)((Time\s+:\s)(\d+:\d+))(.+)/\4/'
# regexh["Wind speed"]='s/(.+)((Wind speed\s+:\s)(\d?\s?\w+))(.+)/\4/'
# regexh["Wind gust"]='s/(.+)((Wind gust\s+:\s)(\d+\s+\w+))(.+)/\4/'
# regexh["Visibility"]='s/(.+)((Visibility\s+:\s)(\d+\s+\w+))(.+)/\4/'
# regexh["Temperature"]='s/(.+)((Temperature\s+:\s)([-|+||]\d+\s?\w+))(.+)/\4/'
# regexh["Dewpoint"]='s/(.+)((Dewpoint\s+:\s)([-|+||]\d+\s?\w+))(.+)/\4/'
# regexh["Pressure"]='s/(.+)((Pressure\s+:\s)(\d+\s?\w+))(.+)/\4/'
# regexh['Wind direction']='s/(.+)((Wind direction\s*:\s)(\d+\s?\(\w+\)))(.+)/\4/'

# Debug mode
if [ $debug_flag -eq 0 ] 
    then
cat <<-EoD
   Debug mode ----------------------------------
   Параметры вызова утилиты $VERSION
      -d | --debug   = $debug_flag
      -h | --help    = $help_flag
      -p | --path    = $path
      -V | --version = $VERSION
EoD
fi

# Debug mode
if [ $debug_flag -eq 0 ] 
    then
    echo "Debug >>"
    printf "Словарь синтаксического разбора, "
    printf "%s cтрок :\n" "${#keys[@]}"
    for key in "${keys[@]}"; do 
        printf '%16s : %s\n' "$key" "${regexh["$key"]}"
    done
    printf "<<\n"
fi
 
# Поиск в строке $1 подстроки по regex $2
# весь perl здесь
function parsf {
    substr=$( echo $1 | perl -pe "$2" )
    echo $substr                            # Результат Perl процесса выводится в STDOUT
    #
    # debug mode
    super_debug_flag="1"
    if [ $super_debug_flag -eq 0 ] 
        then
        echo "Debug mode. parsf : "
        
        printf '\t\$1: %s\n' "$1"
        printf '\t\$2: %s\n' "$2"'Wind direction'
        printf '\tsubstr: %s\n' "$substr"
    fi
}
# "Движок" регулярного выражения - Perl, вызывается как подроцесс, которому
# передается анализируемая строка и регулярное выражение
# результат выводится в STDOUT
# [X] source -> [X] keys -> [X] regexh -> [X] parsf -> [ ] value -> [ ] dbh -> [ ] cvs


#
    # образцы отлаженных выражений
    # см. сайт тестирования regex https://regex101.com/
    #
    # ( echo  $my_doc | perl -pe 's/(.+)((Day\s+:\s)(\d+))(.+)/\4/' )
    # ( echo  $my_doc | perl -pe "${regexh["Day"]}" )
    # echo ${regexh['Wind direction']}
    # ( echo  $my_doc | perl -pe "${regexh['Wind direction']}" )
    # ( echo  $my_doc | perl -pe 's/(.+)((Wind direction\s*:\s)(\d+\s?\(\w+\)))(.+)/\4/' )
    # ( echo  $my_doc | perl -pe "${regexh["Time"]}" ) 


# debug mode
if [ $debug_flag -eq 0 ] ; then
    echo "Debug >>"

    for k in "${keys[@]}"; do 
        var=$(                                  \
            parsf "$my_doc" "${regexh["$k"]}"   \
        )
        #echo "    $k : $var"
        printf '%18s : %s\n' "$k" "$var"
    done

    echo "<<"
fi



# Словарь для результатов 
declare -A my_hash

for k in "${keys[@]}"; do 
    var=$(                                  \
        parsf "$my_doc" "${regexh["$k"]}"   \
    )
    my_hash["$k"]=$var;
done
# Собственно анализ - перебираются ключи, для каждогого из них
# применяется соответствующее ему регулярное выражение
# создается хэш - ключ и значение
# [X] source -> [X] keys -> [X] regexh -> [X] parsf -> [X] value -> [X] dbh -> [ ] cvs


############################################################################
# 3. записываем в db .cvs нужные поля
############################################################################


( printf '%s#' "${my_hash[@]}"  ; printf '\n' ) >> "$path_out"'/'$db   # значения словаря
# запись в .cvs базу данных
# [X] source -> [X] keys -> [X] regexh -> [X] parsf -> [X] value -> [X] dbh -> [ ] cvs

printf '%16s' "${!my_hash[@]}" ; printf '\n'            # ключи словаря
printf '%16s' "${my_hash[@]}"  ; printf '\n'            # значения словаря


# пробелы и скобки закрыты слэшем
#echo -n "\${my_hash[@]} = "     ; printf "%q#"  "${my_hash[@]}" ; printf '\n'
#echo -n "\${!my_hash[@]} = "     ; printf "%q#"  "${!my_hash[@]}" ; printf '\n'

