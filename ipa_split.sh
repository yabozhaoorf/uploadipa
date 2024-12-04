#!/bin/bash

# 设置分割大小为 20MB (20*1024*1024 bytes)
SPLIT_SIZE=20971520

# 查找当前目录下的所有 .ipa 文件
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
        echo "压缩包小于 20MB，无需分割"
        # 删除原始 ipa 文件
        rm "Runner.ipa"
    fi
done