#!/bin/fish

# git aliases
alias --save add="git add ."
alias --save gstat="git status"
alias --save glog="git log --abbrev-commit --graph" 
alias --save com="git commit"
alias --save puh="git_push"
alias --save pul="git_pull"
alias --save fac="fast_checkout"

# Node
alias --save nodei="pnpm install"
alias --save nodestart="pnpm start"
alias --save nodedev="pnpm dev"
alias --save nodetest="pnpm test"

# Java
alias --save javai="mvn install"
alias --save javatest="mvn clean test"
alias --save springdbg="spring_dbg"
alias --save spring_start="spring_start"

# Go
alias --save gor="go_run"

# Docker Compose & Docker
alias --save compup="docker compose up"
alias --save compupd="docker compose up -d"
alias --save compdown="docker compose down"
alias --save docdrop="docker_drop"
