#!/bin/bash

# saka.sh - 压缩/解压工具脚本
# 用法:
#   saka u <路径>     - 解压文件到 <文件所在目录>/latest
#   saka i <文件...>  - 压缩文件到 <当前目录>/latest.metadata
#   saka c <文件路径> - 解压到临时目录，显示 metadata.sque，然后删除

set -e

# 显示使用帮助
show_help() {
    cat << EOF
用法:
  saka u <路径>      - 解压文件/目录到 <文件所在目录>/latest
  saka i <文件...>   - 压缩指定文件到 <当前目录>/latest.metadata
  saka c <文件路径>  - 解压到临时目录，显示 metadata.sque，然后删除

示例:
  saka u archive.zip
  saka u /path/to/folder
  saka u somefile.metadata  (自动识别为ZIP格式)
  saka i file1.txt file2.jpg file3.pdf
  saka c latest.metadata
EOF
}

# 检查命令是否存在
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "错误: 未找到命令 '$1'，请先安装。"
        exit 1
    fi
}

# 安全的解压ZIP（去除绝对路径）
safe_unzip() {
    local src="$1"
    local dest="$2"
    
    # 先列出ZIP内容，检查是否包含绝对路径
    if unzip -l "$src" 2>/dev/null | grep -q "^.*/:$"; then
        echo "警告: ZIP包含绝对路径，将跳过目录结构只提取文件..."
        # 提取所有文件到临时目录，然后移动到目标目录
        local temp_extract=$(mktemp -d)
        unzip -q "$src" -d "$temp_extract"
        # 只复制文件（不包括目录结构）
        find "$temp_extract" -type f -exec cp {} "$dest/" \;
        rm -rf "$temp_extract"
    else
        # 正常解压
        unzip -q "$src" -d "$dest"
    fi
}

# 检测文件真实类型并解压
unpack_with_type() {
    local src="$1"
    local dest="$2"
    local file_type=$(file -b --mime-type "$src")

    case "$file_type" in
        application/zip)
            echo "检测到 ZIP 格式，使用 unzip 解压..."
            check_command unzip
            safe_unzip "$src" "$dest"
            ;;
        application/x-gzip|application/gzip)
            echo "检测到 GZIP 格式..."
            check_command gunzip
            local filename=$(basename "$src" .gz 2>/dev/null || echo "extracted")
            gunzip -c "$src" > "$dest/$filename"
            ;;
        application/x-bzip2)
            echo "检测到 BZIP2 格式..."
            check_command bunzip2
            local filename=$(basename "$src" .bz2 2>/dev/null || echo "extracted")
            bunzip2 -c "$src" > "$dest/$filename"
            ;;
        application/x-tar)
            echo "检测到 TAR 格式..."
            check_command tar
            tar -xf "$src" -C "$dest" --strip-components=0
            ;;
        application/x-rar)
            echo "检测到 RAR 格式..."
            check_command unrar
            unrar x -y -op"$dest" "$src" > /dev/null
            ;;
        application/x-7z-compressed)
            echo "检测到 7Z 格式..."
            check_command 7z
            7z x "$src" -o"$dest" -y > /dev/null
            ;;
        *)
            return 1
            ;;
    esac
    return 0
}

# 根据文件扩展名解压
unpack_by_extension() {
    local src="$1"
    local dest="$2"

    case "$src" in
        *.tar.gz|*.tgz)
            check_command tar
            tar -xzf "$src" -C "$dest" --strip-components=0
            ;;
        *.tar.bz2|*.tbz2)
            check_command tar
            tar -xjf "$src" -C "$dest" --strip-components=0
            ;;
        *.tar.xz|*.txz)
            check_command tar
            tar -xJf "$src" -C "$dest" --strip-components=0
            ;;
        *.tar)
            check_command tar
            tar -xf "$src" -C "$dest" --strip-components=0
            ;;
        *.zip)
            check_command unzip
            safe_unzip "$src" "$dest"
            ;;
        *.7z)
            check_command 7z
            7z x "$src" -o"$dest" -y > /dev/null
            ;;
        *.rar)
            check_command unrar
            unrar x -y -op"$dest" "$src" > /dev/null
            ;;
        *.gz)
            check_command gunzip
            local filename=$(basename "$src" .gz)
            gunzip -c "$src" > "$dest/$filename"
            ;;
        *.bz2)
            check_command bunzip2
            local filename=$(basename "$src" .bz2)
            bunzip2 -c "$src" > "$dest/$filename"
            ;;
        *.metadata)
            echo "检测到 .metadata 文件，尝试作为 ZIP 格式解压..."
            check_command unzip
            safe_unzip "$src" "$dest"
            ;;
        *)
            # 对于没有扩展名的文件，尝试检测真实类型
            if [[ -f "$src" ]]; then
                echo "无扩展名文件，尝试自动检测类型..."
                if unpack_with_type "$src" "$dest"; then
                    return 0
                else
                    return 1
                fi
            fi
            return 1
            ;;
    esac
    return 0
}

# 解压函数（u命令）
do_unpack() {
    local src="$1"

    if [[ -z "$src" ]]; then
        echo "错误: 缺少路径参数"
        show_help
        exit 1
    fi

    if [[ ! -e "$src" ]]; then
        echo "错误: 路径 '$src' 不存在"
        exit 1
    fi

    # 获取文件所在目录
    local src_dir=$(cd "$(dirname "$src")" && pwd)
    local dest="$src_dir/latest"

    echo "源文件: $src"
    echo "目标目录: $dest"

    # 创建目标目录
    mkdir -p "$dest"

    echo "正在解压..."

    # 如果是目录，直接复制
    if [[ -d "$src" ]]; then
        echo "复制目录 '$src' 到 '$dest' ..."
        cp -r "$src"/* "$dest/" 2>/dev/null || cp -r "$src"/. "$dest/" 2>/dev/null || true
        echo "目录复制完成"
        echo "解压完成！内容已放入 '$dest'"
        return 0
    fi

    # 清空目标目录（可选，避免旧文件残留）
    # rm -rf "$dest"/*
    
    # 尝试解压文件
    if unpack_by_extension "$src" "$dest"; then
        echo "解压完成！内容已放入 '$dest'"
        # 显示解压后的内容
        echo "解压后的文件:"
        ls -la "$dest"
    else
        echo "错误: 不支持的文件格式 '$src'"
        echo "提示: 请确保文件是支持的压缩格式（zip, tar.gz, 7z, rar 等）"
        exit 1
    fi
}

# 压缩函数（i命令）
do_pack() {
    local files=("$@")
    
    if [[ ${#files[@]} -eq 0 ]]; then
        echo "错误: 请指定要压缩的文件"
        show_help
        exit 1
    fi

    # 获取当前目录（压缩文件所在目录）
    local current_dir=$(pwd)
    local output="$current_dir/latest.metadata"

    # 检查文件是否存在，并收集文件名（不含路径）
    local basenames=()
    local first_file_dir=""
    
    for file in "${files[@]}"; do
        if [[ ! -e "$file" ]]; then
            echo "错误: 文件 '$file' 不存在"
            exit 1
        fi
        # 只取文件名，不保留路径
        basenames+=("$(basename "$file")")
        if [[ -z "$first_file_dir" ]]; then
            first_file_dir=$(cd "$(dirname "$file")" && pwd)
        fi
    done

    echo "正在压缩以下文件到 '$output':"
    printf "  %s\n" "${basenames[@]}"
    
    # 检查所有文件是否在同一个目录
    local all_in_same_dir=1
    for file in "${files[@]}"; do
        local file_dir=$(cd "$(dirname "$file")" 2>/dev/null && pwd)
        if [[ "$file_dir" != "$first_file_dir" ]]; then
            all_in_same_dir=0
            break
        fi
    done

    # 检测可用的压缩工具
    if command -v zip &> /dev/null; then
        if [[ $all_in_same_dir -eq 1 ]]; then
            # 所有文件在同一目录，切换到该目录压缩
            cd "$first_file_dir"
            zip -q "$output" "${basenames[@]}"
            cd - > /dev/null
        else
            # 文件在不同目录，复制到临时目录再压缩
            local temp_dir=$(mktemp -d)
            echo "文件来自不同目录，复制到临时目录..."
            for file in "${files[@]}"; do
                cp "$file" "$temp_dir/"
            done
            cd "$temp_dir"
            zip -q "$output" *
            cd - > /dev/null
            rm -rf "$temp_dir"
        fi
        echo "已创建 zip 压缩包: $output"
    elif command -v tar &> /dev/null; then
        check_command gzip
        if [[ $all_in_same_dir -eq 1 ]]; then
            cd "$first_file_dir"
            tar -czf "$output" "${basenames[@]}"
            cd - > /dev/null
        else
            local temp_dir=$(mktemp -d)
            echo "文件来自不同目录，复制到临时目录..."
            for file in "${files[@]}"; do
                cp "$file" "$temp_dir/"
            done
            cd "$temp_dir"
            tar -czf "$output" *
            cd - > /dev/null
            rm -rf "$temp_dir"
        fi
        echo "已创建 tar.gz 压缩包: $output"
    else
        echo "错误: 未找到 zip 或 tar/gzip，请安装其中一个压缩工具"
        exit 1
    fi

    echo "压缩完成！"
}

# 查看 metadata.sque 命令（c命令）
do_cat() {
    local src="$1"

    if [[ -z "$src" ]]; then
        echo "错误: 缺少文件路径参数"
        show_help
        exit 1
    fi

    if [[ ! -f "$src" ]]; then
        echo "错误: 文件 '$src' 不存在"
        exit 1
    fi

    # 创建临时目录
    local temp_dir=$(mktemp -d)
    echo "创建临时目录: $temp_dir"

    # 解压文件到临时目录
    echo "正在解压 '$src' 到临时目录..."
    if unpack_by_extension "$src" "$temp_dir"; then
        echo "解压成功"
    else
        echo "错误: 解压失败"
        rm -rf "$temp_dir"
        exit 1
    fi

    # 查找并显示 metadata.sque 文件
    local sque_file=$(find "$temp_dir" -name "metadata.sque" -type f | head -n 1)
    
    if [[ -f "$sque_file" ]]; then
        echo ""
        echo "========== metadata.sque 内容 =========="
        cat "$sque_file"
        echo "========================================"
        echo ""
    else
        echo "警告: 在解压的文件中未找到 metadata.sque"
        echo "临时目录内容:"
        ls -la "$temp_dir"
    fi

    # 删除临时目录
    echo "正在删除临时目录..."
    rm -rf "$temp_dir"
    echo "清理完成"
}

# 主逻辑
case "$1" in
    u)
        shift
        do_unpack "$@"
        ;;
    i)
        shift
        do_pack "$@"
        ;;
    c)
        shift
        do_cat "$@"
        ;;
    -h|--help|help|"")
        show_help
        ;;
    *)
        echo "错误: 未知命令 '$1'"
        show_help
        exit 1
        ;;
esac