#!/bin/bash

# 设置分割大小为 5MB (20*1024*1024 bytes)
SPLIT_SIZE=20971520

# 分支选择函数
select_branch() {
    echo "请选择执行方式："
    echo "1) 在当前分支下执行"
    echo "2) 基于main分支创建新分支"
    read -p "请输入选项 (1/2): " choice

    case $choice in
        1)
            echo "将在当前分支下执行..."
            ;;
        2)
            read -p "请输入新分支名称: " new_branch
            echo "正在基于main分支创建新分支: $new_branch"
            
            # 保存当前分支名
            current_branch=$(git branch --show-current)
            
            # 检查是否有未提交的更改
            if [[ -n $(git status -s) ]]; then
                echo "检测到未提交的更改："
                git status -s
                
                read -p "是否要将这些更改带到新分支？(y/n): " carry_changes
                
                if [[ $carry_changes == "y" ]]; then
                    # 切换到main分支
                    git checkout main || { 
                        echo "切换到main分支失败"
                        exit 1
                    }
                    
                    # 拉取最新代码
                    git pull origin main || { 
                        echo "拉取main分支最新代码失败"
                        git checkout "$current_branch"
                        exit 1
                    }
                    
                    # 检查新分支是否已存在
                    if git show-ref --verify --quiet refs/heads/"$new_branch"; then
                        echo "分支 $new_branch 已存在，切换到该分支"
                        git checkout "$new_branch" || {
                            echo "切换到分支 $new_branch 失败"
                            git checkout "$current_branch"
                            exit 1
                        }
                    else
                        # 创建并切换到新分支
                        git checkout -b "$new_branch" || { 
                            echo "创建新分支失败"
                            git checkout "$current_branch"
                            exit 1
                        }
                    fi
                    
                    echo "已在新分支上继续更改"
                else
                    echo "请先处理未提交的更改后再试"
                    exit 1
                fi
            else
                # 切换到main分支
                git checkout main || { echo "切换到main分支失败"; exit 1; }
                
                # 拉取最新代码
                git pull origin main || { echo "拉取main分支最新代码失败"; exit 1; }
                
                # 创建并切换到新分支
                git checkout -b "$new_branch" || { 
                    echo "创建新分支失败"
                    git checkout "$current_branch"
                    exit 1
                }
            fi
            echo "已切换到新分支: $new_branch"
            ;;
        *)
            echo "无效的选项"
            exit 1
            ;;
    esac
}

# 执行分支选择
select_branch

# 查找当前目录下的所有 .ipa 文件
if find . -maxdepth 1 -name "*.ipa" | read; then
    # 清理已存在的 splitfile 文件
    if ls splitfile* 1> /dev/null 2>&1; then
        echo "检测到已存在的分片文件，正在清理..."
        rm splitfile*
        echo "已清理旧的分片文件"
    fi

    find . -maxdepth 1 -name "*.ipa" | while read ipa_file; do
        echo "处理文件: $ipa_file"
        
        # 重命名 ipa 文件为 Runner.ipa
        mv "$ipa_file" "Runner.ipa"
        echo "已将文件重命名为: Runner.ipa"
        
        # 创建 zip 文件
        zip_file="Runner.ipa.zip"
        echo "正在创建压缩包: $zip_file"
        zip "$zip_file" "Runner.ipa"
        
        # 获取 zip 文件大小（以字节为单位）
        file_size=$(stat -f%z "$zip_file")
        
        # 如果文件大于 20MB
        if [ $file_size -gt $SPLIT_SIZE ]; then
            echo "压缩包大小: $(($file_size/1024/1024))MB，需要分割"
            
            # 分割文件
            split -b ${SPLIT_SIZE} "$zip_file" "splitfile"
            
            # 删除原始 zip 文件和 ipa 文件
            rm "$zip_file"
            rm "Runner.ipa"
            
            echo "文件已分割完成，生成的分片文件："
            ls -lh splitfile*
        else
            echo "压缩包小于 5MB，无需分割"
            # 删除原始 ipa 文件
            rm "Runner.ipa"
        fi
    done
else
    echo "未找到 .ipa 文件"
fi

echo "处理完成！"
if [[ $choice == 2 ]]; then
    echo "注意：新文件已在分支 '$new_branch' 中生成"
    echo "请记得提交更改并推送到远程仓库"
fi