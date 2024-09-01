function compup --wraps='docker compose up' --description 'alias compup=docker compose up'
  docker compose up $argv
        
end
