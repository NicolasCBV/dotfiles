function nodetest --wraps='pnpm test' --description 'alias nodetest=pnpm test'
  pnpm test $argv
        
end
