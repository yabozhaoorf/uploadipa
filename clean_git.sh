#!/bin/bash

# 函数：删除不需要的本地分支
delete_unwanted_branches() {
    # 获取所有本地分支名
    local_branches=$(git branch | sed 's/* //')

    # 要保留的分支列表
    keep_branches=("main" "wing" "prrr" "topi" "ment" "mete" "menory" "fabo" "lave" "dial" "clip" "mait" "clab" "fove" "dart" "mask" "falo" "kmet" "sock" "moosk" "dove" "loop" "seya")

    for branch in $local_branches; do
        should_keep=false
        for keep in "${keep_branches[@]}"; do
            if [ "$branch" == "$keep" ]; then
                should_keep=true
                break
            fi
        done
        if [ "$should_keep" = false ]; then
            git branch -D "$branch"
        fi
    done
}

# 函数：执行基本的垃圾回收
basic_gc() {
    git gc
}

# 函数：强制立即清理
force_gc() {
    git gc --prune=now
}

# 函数：更彻底的清理
aggressive_gc() {
    git reflog expire --expire=now --all
    git gc --aggressive --prune=now
}

# 函数：查找并显示最大的 10 个文件
find_large_files() {
    echo "查找仓库中最大的 10 个文件:"
    git rev-list --objects --all | grep "$(git verify-pack -v .git/objects/pack/*.idx | sort -k 3 -n | tail -10 | awk '{print$1}')"
}

# 主程序
echo "开始删除不需要的本地分支..."
delete_unwanted_branches
echo "不需要的本地分支已删除。"

echo "执行基本的垃圾回收..."
basic_gc
echo "基本的垃圾回收完成。"

echo "执行强制立即清理..."
force_gc
echo "强制立即清理完成。"

echo "执行更彻底的清理..."
aggressive_gc
echo "更彻底的清理完成。"

find_large_files