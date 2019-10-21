#!/bin/sh
# whether the file exists
if [ ! -f "data.json" ]; then
	curl 'https://timetable.nctu.edu.tw/?r=main/get_cos_list' --data 'm_acy=107&m_sem=1&m_degree=3&m_dep_id=17&m_group=**&m_grade=**&m_class=**&m_option=**&m_crs name=**&m_teaname=**&m_cos_id=**&m_cos_code=**&m_crstime=**&m_crsoutline=**&m_costype=**' >> data.json
fi

# get cos_time
if [ ! -f "cos_time.txt" ]; then
	cat data.json | egrep -o '"cos_time":\"(|[_a-zA-Z0-9]|[,\(\)\-])*\"' >> cos_time.txt
fi

# remove "" and get time and classroom
if [ ! -f "timeAndClass.txt" ]; then
	cat cos_time.txt | sed 's/"//g' | sed 's/\:/ /g' | awk '{print $2}' >> timeAndClass.txt
fi

# add @ for no classroom days
if [ ! -f "timeAndClassAt.txt" ]; then
	cat timeAndClass.txt | sed '/\-$/ s/$/@/g' >> timeAndClassAt.txt
fi

# get time for each course
if [ ! -f "time.txt" ]; then
	cat timeAndClassAt.txt \
	| awk 'BEGIN{FS=","}
		{
			for(i=1;i<=NF;i++){
				sub(/\-.*/,"",$i); printf "%s ",$i;
			}
			printf "\n"
		}' \
	| sed 's/[ \t]$//g' \
	| sed 's/[0-9]/,&/g' \
	| sed 's/ //g' \
	| sed 's/^,//g' >> time.txt
fi

# get classroom for each course
if [ ! -f "class.txt" ]; then
	cat timeAndClassAt.txt \
		| awk 'BEGIN{FS=","}
			{
				for(i=1;i<=NF;i++){
					sub(/.*\-/,"",$i); printf "%s ",$i;
				}
				printf "\n"
			}' \
		| sed 's/ $//g' \
		| sed 's/ /,/g' >> class.txt
fi

# get cos_ename
if [ ! -f "cos_ename.txt" ]; then
cat data.json | sed -e 's/[,|{|}]/\
/g' | egrep -o '"cos_ename":".*"' >> cos_ename.txt
fi

# remove "" and get course name
if [ ! -f "name.txt" ]; then
	cat cos_ename.txt | sed 's/"//g' | awk 'BEGIN{FS=":"} {print $2}' | sed 's/ /_/g' >> name.txt

fi

# paste time class
if [ ! -f "timeclass_display.txt" ]; then
	paste -d" " time.txt class.txt >> timeclass_display.txt
fi

# paste time class name
if [ ! -f "timeclassname.txt" ]; then
	cat timeclass_display.txt \
	| paste -d"-" timeclass_display.txt name.txt \
	| sed 's/@//g' \
	| sed 's/ /_/g' >> timeclassname.txt
fi

if [ ! -f "menuNum.txt" ]; then
	cat timeclassname.txt \
	| awk '{print NR}' >> menuNum.txt
fi

if [ ! -f "menucontent.txt" ];then
	paste -d" " menuNum.txt timeclassname.txt >> menucontent.txt
fi

if [ -f "option.txt" ];then
    $choice=3
    $choice=`cat option.txt`
fi

create_days(){
    for i in `seq 1 7`;do
        if [ ! -f day${i}.txt ];then
            printf "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n" > day${i}.txt
        fi
    done
}
match_to_line(){
    if [ "$1" == "M" ];then
        check_line=1
    elif [ "$1" == "N" ];then
        check_line=2
    elif [ "$1" == "A" ];then
        check_line=3
    elif [ "$1" == "B" ];then
        check_line=4
    elif [ "$1" == "C" ];then
        check_line=5
    elif [ "$1" == "D" ];then
        check_line=6
    elif [ "$1" == "X" ];then
        check_line=7
    elif [ "$1" == "E" ];then
        check_line=8
    elif [ "$1" == "F" ];then
        check_line=9
    elif [ "$1" == "G" ];then
        check_line=10
    elif [ "$1" == "H" ];then
        check_line=11
    elif [ "$1" == "Y" ];then
        check_line=12
    elif [ "$1" == "I" ];then
        check_line=13
    elif [ "$1" == "J" ];then
        check_line=14
    elif [ "$1" == "K" ];then
        check_line=15
    fi
}

check_conflict(){
    conflicted=0
    cat time.txt | sed -n "${pick}p" | awk 'BEGIN{FS=","} {for(i=1;i<=NF;i++){
        print(substr($i,1,1))
        print(substr($i,2))
    }}' > handle.tmp
    exec < handle.tmp
    while read line;do
        #echo $line 
        #sleep 1
        if [ `echo $line | egrep "[0-9]" | wc -m` -gt 0 ]; then
            #day
            day=$line
        else 
            #time
            clock_count=`echo $line | wc -m`
            clock_count=$(($clock_count-1))
            printf "" > clock.tmp
            for i in `seq 1 $clock_count`;do 
                echo $line | cut -c $i >> clock.tmp
            done
            #EF->
            #E
            #F
            #check_line
            clock_line=`cat clock.tmp | wc -l`
            for c in `seq 1 $clock_line`;do
                _clock=`cat clock.tmp | sed -n "${c}p"`
                match_to_line "$_clock"
                if [ "`cat day${day}.txt | sed -n "${check_line}p" | wc -m`" -gt 1 ];then
                    conflicted=1
                    break
                fi
            done
            if [ $conflicted -eq 1 ];then
                break
            fi
        fi

    done
}

option(){
    opt="op3"
    dialog --title "Option" --menu "Option" 10 30 4 \
    "op1" "Show Classroom" \
    "op2" "Hide Extra Column" \
    "op3" "Normal Form" 2>option.txt
    if [ $? -eq 1 ];then
        display 
    fi # cancel
    opt=`cat option.txt`
    display
    #echo $opt
}

select_course(){
    course_name=`cat name.txt | sed -n "${1}p"`
    course_time=`cat time.txt | sed -n "${1}p"`
    course_place=`cat class.txt | sed -n "${1}p"`
    echo $course_time | awk 'BEGIN{FS=","} {for(i=1;i<=NF;i++){
        print(substr($i,1,1))
        print(substr($i,2))
    }}' > handle.tmp
    exec < handle.tmp

    while read line;do
         if [ `echo $line | egrep "[0-9]" | wc -m` -gt 0 ]; then
            #day
            day=$line
        else 
            #time
            clock_count=`echo $line | wc -m`
            clock_count=$(($clock_count-1))
            printf "" > clock.tmp
            for i in `seq 1 $clock_count`;do 
                echo $line | cut -c $i >> clock.tmp
            done
            #EF->
            #E
            #F
            #check_line
            clock_line=`cat clock.tmp | wc -l`
            for c in `seq 1 $clock_line`;do
                _clock=`cat clock.tmp | sed -n "${c}p"`
                match_to_line "$_clock"
                if [ opt = "op3" ]; then
                    echo "op3!"
                    cat day${day}.txt | awk -v line="$check_line" -v name="$course_name" '{if(NR==line){printf "%s\n",name}else{printf "%s\n",$0}}' > tmp.tmp
                    cat tmp.tmp > day${day}.txt
                elif [ opt = "op1" ]; then
                    echo "op1!"
                    cat day${day}.txt | awk -v line="$check_line" -v name="$course_name" -v place="$course_place" '{if(NR==line){printf "%s-%s\n",name,place}else{printf "%s\n",$0}}' > tmp.tmp
                    cat tmp.tmp | sed 's/@//g' > day${day}.txt
                else
                    cat day${day}.txt | awk -v line="$check_line" -v name="$course_name" '{if(NR==line){printf "%s\n",name}else{printf "%s\n",$0}}' > tmp.tmp
                    cat tmp.tmp > day${day}.txt
                fi
            done

        fi
    done
}

paste_all(){
    T="M...-N...-A...-B...-C...-D...-X...-E...-F...-G...-H...-Y...-I...-J...-K...-"
    len=`echo $T | wc -m`
    printf "" > tmp.tmp
    for i in `seq 1 $len`;do
        char=`echo $T | cut -c $i`
        printf "%s\n" $char >> tmp.tmp
    done

	for day in `seq 1 7`;do
		paste -d"|" tmp.tmp day${day}.display > tmppp.tmp
		cat tmppp.tmp > tmp.tmp
		#cat tmp.tmp
		#sleep 2
	done

    printf "\-\-......MON.....|......TUE.....|......WED.....|......THU.....|.....FRI......|.....SAT......|.....SUN......|\n" > schedule.txt
	cat tmp.tmp | sed 's/ $/&|/g' | sed 's/-$/&|/g' | sed '$d' >> schedule.txt

    # remove extra
    if [ $opt = "op2" ]; then
        #remove saturday sunday
        cut -c 1-77 schedule.txt > schedule.tmp
        #cat schedule.tmp > schedule.txt
        cat schedule.tmp | awk '{{if((NR >=12 && NR<=31) || NR == 1 || (NR>=37 && NR<=56) ||(NR>=62) )print $0}}' > schedule.txt
    fi
}


add_course(){
    # dialog menu
    create_days
    while [ 1 ];do
        dialog --title "Add class" --menu "Add class" 40 200 40 \
        `cat menucontent.txt` 2>pick.txt
        if [ $? -eq 1 ];then display; fi
        pick=`cat pick.txt`
        
        if [ -f course_${pick}.course ];then
            rm course_${pick}.course
            remove_course
            #echo "removed!"
            #sleep 1
            # dialog remove course
            dialog  --msgbox 'Removed!' 5 20
        else
            check_conflict
            if [ $conflicted -eq 1 ];then
                #display conflict
                #echo "yes"
                #sleep 1
                course_time=`cat time.txt | sed -n "${pick}p"`
                course_name=`cat name.txt | sed -n "${1}p"`
                dialog --msgbox "Collision: $course_time \n$course_name" 6 20
                break
            else
                touch "course_${pick}.course"
                select_course "${pick}"
                display
            fi
        fi
    done
    # back to add course
    add_course
}

display(){
    for day in `seq 1 7`;do
        printf "" > day${day}.display
        printf "" > day${day}.new
        for line in `seq 1 15`;do
            l=`cat "day${day}.txt" | sed -n "${line}p"`
            printf "%-52s\n" $l >> day${day}.new
        done
    done
    for day in `seq 1 7`;do
        for line in `seq 1 15`;do
            cat "day${day}.new" | sed -n "${line}p" | fold -w 13 | awk 'BEGIN{FS="&"}{printf "-%s\n",$0}END{print "--------------"}' >> day${day}.display
        done    
    done
	paste_all
    #    dialog --extra-button --extra-label "switch-display-type" --extra-button --extra-label "switch-display-type"  --title TESTING   --msgbox "`cat schedule.txt`"  2000 200

    dialog --no-collapse  --ok-label "Add Class" --extra-button --extra-label "option" --cancel-label "Exit" --title "User courses"  --yesno "`cat schedule.txt`" 1000 500
    #echo $?
    choice=$?
    echo $choice > option.txt
    
    case $choice in
        0)add_course;;
        1)exit;;
        3)option;;
    esac
}

display

remove_course(){
    course_time=`cat time.txt | sed -n "${pick}p"`
    echo $course_time | awk 'BEGIN{FS=","} {for(i=1;i<=NF;i++){
        print(substr($i,1,1))
        print(substr($i,2))
    }}' > handle.tmp
    exec < handle.tmp
    while read line;do
         if [ `echo $line | egrep "[0-9]" | wc -m` -gt 0 ]; then
            #day
            day=$line
        else 
            #time
            clock_count=`echo $line | wc -m`
            clock_count=$(($clock_count-1))
            printf "" > clock.tmp
            for i in `seq 1 $clock_count`;do 
                echo $line | cut -c $i >> clock.tmp
            done
            #EF->
            #E
            #F
            #check_line
            clock_line=`cat clock.tmp | wc -l`
            for c in `seq 1 $clock_line`;do
                _clock=`cat clock.tmp | sed -n "${c}p"`
                match_to_line "$_clock"
                cat day${day}.txt | awk -v line="$check_line" -v name="$course_name" '{if(NR==line){printf "\n"}else{printf "%s\n",$0}}' > tmp.tmp
                cat tmp.tmp > day${day}.txt
            done
        fi


    done

}

#memorize user option
#dialog --title TESTING --msgbox "`cat all_schedule.display`" 1000 500
#display user courses



