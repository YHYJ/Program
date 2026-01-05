#!/usr/bin/env bash

: <<!
Name: allbackup.sh
Author: YJ
Email: yj1516268@outlook.com
Created Time: 2026-01-04 09:50:58

Description: 多路径文件同步备份工具
              使用rsync进行高效同步，支持多个源路径

Attentions:
- 使用--delete选项会删除目标端源端不存在的文件
- 使用校验和(--checksum)会降低速度但提高可靠性
- 建议先使用--dry-run测试
- 文件大于1G时会询问是否备份

Depends:
- rsync
!

####################################################################
#+++++++++++++++++++++++++ Define Variable ++++++++++++++++++++++++#
####################################################################
#------------------------- Program Variable
NAME=$(basename "${0}")
readonly NAME
DESC="多路径文件同步备份工具"
readonly DESC
readonly MAJOR=2.0.0
readonly MINOR=20260104
readonly RELEASE=1

#------------------------- Backup Variable
# 脚本内部指定的多个备份源路径（请根据实际情况修改）
readonly SOURCE_PATHS=(
    "/home/yj/Desktop"
    "/home/yj/Documents"
    "/home/yj/Downloads"
    "/home/yj/Music"
    "/home/yj/Pictures"
    "/home/yj/Videos"
)

# 默认排除规则数组
readonly DEFAULT_EXCLUDES=(
    # ".*"           # 排除所有隐藏文件
    # ".*/"          # 排除所有隐藏文件夹
    "*.tmp"        # 临时文件
    "*.temp"       # 临时文件
    "*~"           # 备份文件
    ".DS_Store"    # macOS系统文件
    "Thumbs.db"    # Windows系统文件
    "desktop.ini"  # Windows系统文件
    "*~"
    ".*.swp"
    "*.log"
    "*.bak"
    "*.class"
    "*.pyc"
    "logs/"
    "__pycache__/"
    "node_modules/"
    "AppCache/"
    "Root/"
    "Repos"
    "WorkSpace/"
    "WPS\ Cloud\ Files/"
)

#------------------------- Status Variable
DESTINATION=""
USE_CHECKSUM=false
DRY_RUN=false
DISABLE_DEFAULTS=false
USER_EXCLUDES=()
TOTAL_SOURCES=0
SYNC_FAILED=0

#------------------------- Color Variable
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

#------------------------- Exit Code Variable
readonly NORMAL=0
readonly ERR_FILE=1
readonly ERR_PARAM=2
readonly ERR_NO_PROGRAM=127
readonly ERR_CTRL_C=130
readonly ERR_UNKNOWN=255

####################################################################
#+++++++++++++++++++++++++ Define Function ++++++++++++++++++++++++#
####################################################################
#------------------------- Info Function
function helpInfo() {
    echo -e ""
    echo -e "${BOLD}${NAME}${NC} ${CYAN}${DESC}${NC}"
    echo -e "--------------------------------------------------"
    echo -e "Usage:"
    echo -e ""
    echo -e "    ${NAME} [OPTIONS] DESTINATION"
    echo -e ""
    echo -e "Options:"
    echo -e "    -h, --help             显示帮助信息"
    echo -e "    -v, --version          显示版本信息"
    echo -e "    -c, --checksum         使用校验和检查"
    echo -e "    -n, --dry-run          试运行，不实际执行"
    echo -e "    -e, --exclude PATTERN  指定排除模式（可多次使用）"
    echo -e "    -d, --disable-defaults 禁用默认排除规则"
    echo -e "    -l, --list-excludes    列出默认排除规则"
    echo -e ""
    echo -e "Arguments:"
    echo -e "    DESTINATION            备份目标路径（必需）"
    echo -e ""
    echo -e "源路径:"
    for src in "${SOURCE_PATHS[@]}"; do
        echo -e "    ${src}"
    done
    echo -e ""
    echo -e "示例:"
    echo -e "    ${NAME} /backup/data"
    echo -e "    ${NAME} user@server:/backup/data -c"
    echo -e "    ${NAME} /backup/dest -e \"*.tmp\" -e \"logs/\" -n"
    echo -e "    ${NAME} --list-excludes"
    echo -e ""
}

function versionInfo() {
    echo -e ""
    echo -e "${BOLD}${NAME}${NC} version ${BOLD}${MAJOR}-${MINOR}.${RELEASE}${NC}"
    echo -e "多路径同步备份工具"
    echo -e ""
}

#------------------------- Display Function
function listExcludes() {
    echo -e ""
    echo -e "${BOLD}默认排除规则 (${#DEFAULT_EXCLUDES[@]} 条):${NC}"
    echo -e "----------------------------------------"

    for i in "${!DEFAULT_EXCLUDES[@]}"; do
        printf "  %3d. %s\n" "$((i+1))" "${DEFAULT_EXCLUDES[i]}"
    done

    echo -e "----------------------------------------"
    echo -e ""
    echo -e "${BOLD}排除规则示例:${NC}"
    echo -e "  ${YELLOW}*.tmp${NC}         - 排除所有 .tmp 文件"
    echo -e "  ${YELLOW}logs/${NC}         - 排除 logs 目录"
    echo -e "  ${YELLOW}.*${NC}           - 排除所有隐藏文件"
    echo -e "  ${YELLOW}.*/${NC}          - 排除所有隐藏文件夹"
    echo -e "  ${YELLOW}.git/${NC}        - 排除 .git 目录"
    echo -e ""
}

#------------------------- Check Function
function checkRequirements() {
    if ! command -v rsync &>/dev/null; then
        echo -e "${RED}错误: rsync 未安装${NC}"
        return ${ERR_NO_PROGRAM}
    fi
    return ${NORMAL}
}

function validatePaths() {
    local valid_count=0

    for src in "${SOURCE_PATHS[@]}"; do
        if [[ -n "${src}" ]] && [[ "${src}" != "#"* ]]; then
            if [[ -e "${src}" ]]; then
                valid_count=$((valid_count + 1))
            else
                echo -e "${YELLOW}警告: 源路径不存在 ${src}${NC}"
            fi
        fi
    done

    if [[ ${valid_count} -eq 0 ]]; then
        echo -e "${RED}错误: 所有源路径都无效${NC}"
        return ${ERR_FILE}
    fi

    TOTAL_SOURCES=${valid_count}
    return ${NORMAL}
}

#------------------------- Backup Function
function buildRsyncCmd() {
    local cmd="rsync -av --delete --ignore-errors"

    [[ "${USE_CHECKSUM}" == "true" ]] && cmd="${cmd} --checksum"
    [[ "${DRY_RUN}" == "true" ]] && cmd="${cmd} --dry-run"

    # 添加排除规则
    if [[ "${DISABLE_DEFAULTS}" != "true" ]]; then
        for exclude in "${DEFAULT_EXCLUDES[@]}"; do
            cmd="${cmd} --exclude='${exclude}'"
        done
    fi

    for exclude in "${USER_EXCLUDES[@]}"; do
        cmd="${cmd} --exclude='${exclude}'"
    done

    echo "${cmd}"
}

function syncSource() {
    local source_path="$1"
    local dest_path="$2"
    local cmd="$3"
    local base_name

    base_name=$(basename "${source_path}")

    # 确保目标路径不以斜杠结尾（除非是根目录）
    dest_path="${dest_path%/}"

    # 根据源路径类型处理目标路径
    if [[ -f "${source_path}" ]]; then
        # 如果是文件，直接在目标路径创建对应文件
        echo -e "${CYAN}[$((SYNC_FAILED+1))/${TOTAL_SOURCES}] 同步文件: ${source_path} -> ${dest_path}/${base_name}${NC}"
        local full_cmd="${cmd} '${source_path}' '${dest_path}/'"
    elif [[ -d "${source_path}" ]]; then
        # 如果是文件夹，在目标路径创建对应文件夹，同步文件夹内容
        echo -e "${CYAN}[$((SYNC_FAILED+1))/${TOTAL_SOURCES}] 同步文件夹: ${source_path} -> ${dest_path}/${base_name}${NC}"
        # 使用斜杠确保同步文件夹内容而不是文件夹本身
        local full_cmd="${cmd} '${source_path}/' '${dest_path}/${base_name}/'"
    else
        echo -e "${YELLOW}警告: 跳过不存在的路径 ${source_path}${NC}"
        return ${NORMAL}
    fi

    if eval "${full_cmd}"; then
        echo -e "${GREEN}✓ 同步成功${NC}"
        return ${NORMAL}
    else
        echo -e "${RED}✗ 同步失败${NC}"
        SYNC_FAILED=$((SYNC_FAILED + 1))
        return ${ERR_UNKNOWN}
    fi
}

function performBackup() {
    local rsync_cmd
    rsync_cmd=$(buildRsyncCmd)

    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}开始多路径同步${NC}"
    echo -e "目标路径: ${DESTINATION}"
    echo -e "总源路径: ${TOTAL_SOURCES}"
    echo -e "校验和: ${USE_CHECKSUM}"
    echo -e "试运行: ${DRY_RUN}"
    echo -e "${BLUE}========================================${NC}"

    local sync_count=0
    for src in "${SOURCE_PATHS[@]}"; do
        if [[ -n "${src}" ]] && [[ "${src}" != "#"* ]] && [[ -e "${src}" ]]; then
            syncSource "${src}" "${DESTINATION}" "${rsync_cmd}"
            sync_count=$((sync_count + 1))

            if [[ ${sync_count} -lt ${TOTAL_SOURCES} ]]; then
                echo -e "${BLUE}----------------------------------------${NC}"
            fi
        fi
    done

    echo -e "${BLUE}========================================${NC}"

    if [[ ${SYNC_FAILED} -eq 0 ]]; then
        echo -e "${GREEN}所有路径同步完成${NC}"
        return ${NORMAL}
    else
        echo -e "${RED}同步完成，但有 ${SYNC_FAILED} 个路径失败${NC}"
        return ${ERR_UNKNOWN}
    fi
}

####################################################################
#++++++++++++++++++++++++++++++ Main ++++++++++++++++++++++++++++++#
####################################################################
# 设置trap处理Ctrl+C
trap 'echo -e "\n${YELLOW}用户中断操作${NC}"; exit ${ERR_CTRL_C}' INT

# 解析命令行参数
ARGS=$(getopt --options "hvcnle:dl" --longoptions "help,version,checksum,dry-run,list-excludes,exclude:,disable-defaults" -n "${NAME}" -- "$@")
eval set -- "${ARGS}"

# 如果没有参数，显示帮助信息
if [[ $# -lt 2 ]]; then
    helpInfo
    exit ${NORMAL}
fi

while true; do
    case $1 in
        -h|--help)
            helpInfo
            exit ${NORMAL}
            ;;
        -v|--version)
            versionInfo
            exit ${NORMAL}
            ;;
        -c|--checksum)
            USE_CHECKSUM=true
            shift
            ;;
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -e|--exclude)
            USER_EXCLUDES+=("$2")
            shift 2
            ;;
        -d|--disable-defaults)
            DISABLE_DEFAULTS=true
            shift
            ;;
        -l|--list-excludes)
            listExcludes
            exit ${NORMAL}
            ;;
        --)
            shift
            break
            ;;
        *)
            helpInfo
            exit ${ERR_UNKNOWN}
            ;;
    esac
done

# 获取目标路径
if [[ $# -gt 0 ]]; then
    DESTINATION="$1"
else
    helpInfo
    exit ${ERR_PARAM}
fi

# 显示启动信息
echo -e ""
echo -e "${BOLD}${CYAN}${NAME}${NC}"

# 检查依赖
checkRequirements || exit $?

# 验证路径
validatePaths || exit $?

# 执行备份
performBackup
exit_code=$?

echo -e ""
echo -e "${CYAN}备份任务执行完毕${NC}"
exit ${exit_code}
