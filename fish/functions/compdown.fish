function compdown --wraps='docker compose down' --description 'alias compdown=docker compose down'
  docker compose down $argv
        
end
