###
###
trim() {
    str=""

    if [ $# -gt 0 ]; then
        str="$1"
    fi
    echo "$str" | sed -e 's/^[ \t\r\n]*//g' | sed -e 's/[ \t\r\n]*$//g'
}

###
###
os() {
    os=$(trim $(cat /etc/os-release 2>/dev/null | grep ^ID= | awk -F= '{print $2}'))

    if [ "$os" = "" ]; then
        os=$(trim $(lsb_release -i 2>/dev/null | awk -F: '{print $2}'))
    fi
    if [ ! "$os" = "" ]; then
        os=$(echo $os | tr '[A-Z]' '[a-z]')
    fi

    echo $os
}

case "$(os)" in
    ubuntu)
        echo "ubuntu"
        sudo apt install libncurse*
        sudo apt install bison
        ;;
    centos)
        echo "centos"
        sudo yum -y install libncurse*
        sudo yum -y install bison
        ;;
    debain)
        echo "debain"
        sudo apt-get install libncurse*
        sudo apt-get install bison
        ;;
    *)
        echo unknow os $OS, exit!
        return
        ;;
esac
