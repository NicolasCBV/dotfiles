function glog --wraps='git log --abbrev-commit --graph' --description 'alias glog=git log --abbrev-commit --graph'
  git log --abbrev-commit --graph $argv
        
end
